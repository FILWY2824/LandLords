#include "landlords/ai/onnx_bot_strategy.h"

#include <algorithm>
#include <array>
#include <chrono>
#include <filesystem>
#include <map>
#include <memory>
#include <mutex>
#include <numeric>
#include <optional>
#include <stdexcept>
#include <string>
#include <string_view>
#include <unordered_map>
#include <utility>
#include <vector>

#include "landlords/core/logging.h"
#include "landlords/core/models.h"

#ifdef LANDLORDS_WITH_ONNXRUNTIME
#include <onnxruntime_cxx_api.h>
#endif

namespace landlords::ai {

namespace {

#ifdef LANDLORDS_WITH_ONNXRUNTIME

using Move = std::vector<int>;

constexpr int kActionFeatureWidth = 54;
constexpr int kHistoryRows = 5;
constexpr int kHistoryCols = 162;
constexpr int kHistoryMoves = 15;

const std::array<int, 15> kFullDeck = [] {
  std::array<int, 15> filler{};
  return filler;
}();

std::vector<int> FullDeckValues() {
  std::vector<int> deck;
  deck.reserve(54);
  for (int value = 3; value <= 14; ++value) {
    for (int count = 0; count < 4; ++count) {
      deck.push_back(value);
    }
  }
  for (int count = 0; count < 4; ++count) {
    deck.push_back(17);
  }
  deck.push_back(20);
  deck.push_back(30);
  return deck;
}

std::string PatternCardsText(const core::CardPattern& pattern) {
  if (pattern.cards.empty()) {
    return "-";
  }
  std::string text;
  for (std::size_t index = 0; index < pattern.cards.size(); ++index) {
    if (index > 0) {
      text.append(",");
    }
    text.append(pattern.cards[index].rank);
  }
  return text;
}

bool StartsWith(std::string_view text, std::string_view prefix) {
  return text.substr(0, prefix.size()) == prefix;
}

template <typename TAction>
bool IsSystemAction(const TAction& action) {
  const std::string_view label = action.pattern();
  return label == "managed_on" || label == "managed_off" ||
         label == "bid_pass" || StartsWith(label, "bid_");
}

int RankToEnvValue(std::string_view rank) {
  static const std::unordered_map<std::string, int> mapping = {
      {"3", 3},   {"4", 4},   {"5", 5},   {"6", 6},   {"7", 7},   {"8", 8},
      {"9", 9},   {"10", 10}, {"J", 11},  {"Q", 12},  {"K", 13},  {"A", 14},
      {"2", 17},  {"SJ", 20}, {"BJ", 30},
  };
  return mapping.at(std::string(rank));
}

struct SnapshotSeats {
  std::unordered_map<std::string, std::string> position_by_player;
  std::unordered_map<std::string, int> cards_left_by_position;
};

struct HistoryFeatures {
  std::vector<Move> action_seq;
  std::unordered_map<std::string, Move> last_move_by_position;
  std::unordered_map<std::string, Move> played_cards_by_position;
  int bomb_num = 0;
};

struct EncodedBatch {
  std::vector<core::CardPattern> legal_patterns;
  std::vector<float> z_batch;
  std::vector<float> x_batch;
  std::size_t batch_size = 0;
  int x_width = 0;
};

std::vector<core::Card> ProtoCardsToCore(const auto& cards) {
  std::vector<core::Card> converted;
  converted.reserve(cards.size());
  for (const auto& card : cards) {
    converted.push_back(core::Card{
        .id = card.id(),
        .rank = card.rank(),
        .suit = card.suit(),
        .value = card.value(),
    });
  }
  return converted;
}

Move ProtoCardsToEnvMove(const auto& cards) {
  Move move;
  move.reserve(cards.size());
  for (const auto& card : cards) {
    move.push_back(RankToEnvValue(card.rank()));
  }
  std::sort(move.begin(), move.end());
  return move;
}

Move PatternToEnvMove(const core::CardPattern& pattern) {
  Move move;
  move.reserve(pattern.cards.size());
  for (const auto& card : pattern.cards) {
    move.push_back(RankToEnvValue(card.rank));
  }
  std::sort(move.begin(), move.end());
  return move;
}

bool IsBombMove(const Move& move) {
  if (move.size() == 2 && move[0] == 20 && move[1] == 30) {
    return true;
  }
  return move.size() == 4 && std::adjacent_find(move.begin(), move.end(), std::not_equal_to<>()) == move.end();
}

SnapshotSeats BuildSeats(const landlords::protocol::RoomSnapshot& snapshot) {
  int landlord_index = -1;
  for (int index = 0; index < snapshot.players_size(); ++index) {
    if (snapshot.players(index).role() == landlords::protocol::PLAYER_ROLE_LANDLORD) {
      landlord_index = index;
      break;
    }
  }
  if (landlord_index < 0 || snapshot.players_size() != 3) {
    throw std::runtime_error("invalid room seats for ONNX strategy");
  }

  SnapshotSeats seats;
  const auto& landlord = snapshot.players(landlord_index);
  const auto& landlord_down = snapshot.players((landlord_index + 1) % snapshot.players_size());
  const auto& landlord_up = snapshot.players((landlord_index + 2) % snapshot.players_size());

  seats.position_by_player.emplace(landlord.player_id(), "landlord");
  seats.position_by_player.emplace(landlord_down.player_id(), "landlord_down");
  seats.position_by_player.emplace(landlord_up.player_id(), "landlord_up");
  seats.cards_left_by_position.emplace("landlord", landlord.cards_left());
  seats.cards_left_by_position.emplace("landlord_down", landlord_down.cards_left());
  seats.cards_left_by_position.emplace("landlord_up", landlord_up.cards_left());
  return seats;
}

HistoryFeatures BuildHistory(const landlords::protocol::RoomSnapshot& snapshot,
                             const SnapshotSeats& seats) {
  HistoryFeatures history;
  history.last_move_by_position = {
      {"landlord", {}},
      {"landlord_down", {}},
      {"landlord_up", {}},
  };
  history.played_cards_by_position = {
      {"landlord", {}},
      {"landlord_down", {}},
      {"landlord_up", {}},
  };

  for (const auto& action : snapshot.recent_actions()) {
    if (IsSystemAction(action)) {
      continue;
    }

    const auto found = seats.position_by_player.find(action.player_id());
    if (found == seats.position_by_player.end()) {
      continue;
    }

    Move move;
    if (action.action_type() == landlords::protocol::ACTION_TYPE_PASS) {
      move = {};
    } else if (action.action_type() == landlords::protocol::ACTION_TYPE_PLAY && action.cards_size() > 0) {
      move = ProtoCardsToEnvMove(action.cards());
    } else {
      continue;
    }

    history.action_seq.push_back(move);
    history.last_move_by_position[found->second] = move;
    if (!move.empty()) {
      auto& played = history.played_cards_by_position[found->second];
      played.insert(played.end(), move.begin(), move.end());
      if (IsBombMove(move)) {
        ++history.bomb_num;
      }
    }
  }
  return history;
}

Move CurrentLeadMove(const std::vector<Move>& action_seq) {
  int trailing_passes = 0;
  for (auto it = action_seq.rbegin(); it != action_seq.rend(); ++it) {
    if (it->empty()) {
      ++trailing_passes;
      continue;
    }
    if (trailing_passes >= 2) {
      return {};
    }
    if (!it->empty()) {
      return *it;
    }
  }
  return {};
}

std::array<Move, 2> LastTwoMoves(const std::vector<Move>& action_seq) {
  std::array<Move, 2> result;
  result[0] = {};
  result[1] = {};
  if (action_seq.empty()) {
    return result;
  }
  if (action_seq.size() == 1) {
    result[1] = action_seq.back();
    return result;
  }
  result[0] = action_seq[action_seq.size() - 2];
  result[1] = action_seq.back();
  return result;
}

std::optional<core::CardPattern> CurrentTablePattern(const landlords::protocol::RoomSnapshot& snapshot) {
  int trailing_passes = 0;
  for (int index = snapshot.recent_actions_size() - 1; index >= 0; --index) {
    const auto& action = snapshot.recent_actions(index);
    if (IsSystemAction(action)) {
      continue;
    }
    if (action.action_type() == landlords::protocol::ACTION_TYPE_PASS) {
      ++trailing_passes;
      continue;
    }
    if (action.action_type() != landlords::protocol::ACTION_TYPE_PLAY || action.cards_size() == 0) {
      continue;
    }
    if (trailing_passes >= 2) {
      return std::nullopt;
    }
    const auto pattern = core::EvaluatePattern(ProtoCardsToCore(action.cards()));
    return pattern.type == core::PatternType::kInvalid ? std::nullopt
                                                       : std::optional<core::CardPattern>(pattern);
  }
  return std::nullopt;
}

std::array<float, kActionFeatureWidth> CardsToArray(const Move& move) {
  std::array<float, kActionFeatureWidth> features{};
  if (move.empty()) {
    return features;
  }

  std::map<int, int> counts;
  for (const auto value : move) {
    ++counts[value];
  }

  auto set_column = [&](int column, int count) {
    for (int row = 0; row < std::min(count, 4); ++row) {
      features[static_cast<std::size_t>(column * 4 + row)] = 1.0F;
    }
  };

  for (const auto& [value, count] : counts) {
    if (value >= 3 && value <= 14) {
      set_column(value - 3, count);
    } else if (value == 17) {
      set_column(12, count);
    } else if (value == 20) {
      features[52] = 1.0F;
    } else if (value == 30) {
      features[53] = 1.0F;
    }
  }
  return features;
}

std::vector<float> OneHotCardsLeft(int cards_left, int max_cards) {
  std::vector<float> one_hot(static_cast<std::size_t>(max_cards), 0.0F);
  const int index = std::clamp(cards_left, 1, max_cards) - 1;
  one_hot[static_cast<std::size_t>(index)] = 1.0F;
  return one_hot;
}

std::vector<float> BombOneHot(int bomb_num) {
  std::vector<float> one_hot(15, 0.0F);
  one_hot[static_cast<std::size_t>(std::clamp(bomb_num, 0, 14))] = 1.0F;
  return one_hot;
}

void AppendFloats(std::vector<float>& target, const auto& source) {
  target.insert(target.end(), source.begin(), source.end());
}

std::vector<Move> PadActionSeq(std::vector<Move> sequence) {
  if (sequence.size() > static_cast<std::size_t>(kHistoryMoves)) {
    sequence.erase(sequence.begin(),
                   sequence.begin() + static_cast<long>(sequence.size() - kHistoryMoves));
  }
  if (sequence.size() < static_cast<std::size_t>(kHistoryMoves)) {
    std::vector<Move> padded(static_cast<std::size_t>(kHistoryMoves) - sequence.size());
    padded.insert(padded.end(), sequence.begin(), sequence.end());
    sequence = std::move(padded);
  }
  return sequence;
}

std::vector<float> EncodeHistory(const std::vector<Move>& action_seq) {
  const auto padded = PadActionSeq(action_seq);
  std::vector<float> z(static_cast<std::size_t>(kHistoryRows * kHistoryCols), 0.0F);
  for (int index = 0; index < kHistoryMoves; ++index) {
    const auto encoded = CardsToArray(padded[static_cast<std::size_t>(index)]);
    const int row = index / 3;
    const int col_offset = (index % 3) * kActionFeatureWidth;
    for (int offset = 0; offset < kActionFeatureWidth; ++offset) {
      z[static_cast<std::size_t>(row * kHistoryCols + col_offset + offset)] = encoded[static_cast<std::size_t>(offset)];
    }
  }
  return z;
}

Move BuildOtherHandCards(const landlords::protocol::RoomSnapshot& snapshot) {
  std::map<int, int> counts;
  for (const auto value : FullDeckValues()) {
    ++counts[value];
  }
  for (const auto value : ProtoCardsToEnvMove(snapshot.self_cards())) {
    --counts[value];
  }
  for (const auto& action : snapshot.recent_actions()) {
    if (action.action_type() != landlords::protocol::ACTION_TYPE_PLAY || action.cards_size() == 0) {
      continue;
    }
    for (const auto value : ProtoCardsToEnvMove(action.cards())) {
      --counts[value];
    }
  }

  Move cards;
  for (const auto& [value, count] : counts) {
    for (int index = 0; index < std::max(count, 0); ++index) {
      cards.push_back(value);
    }
  }
  return cards;
}

std::vector<core::CardPattern> BuildLegalPatterns(const landlords::protocol::RoomSnapshot& snapshot) {
  const auto self_cards = ProtoCardsToCore(snapshot.self_cards());
  const auto current_pattern = CurrentTablePattern(snapshot);
  std::vector<core::CardPattern> legal;
  for (const auto& candidate : core::BuildCandidates(self_cards)) {
    if (core::CanBeat(candidate, current_pattern)) {
      legal.push_back(candidate);
    }
  }
  if (current_pattern.has_value()) {
    legal.push_back(core::CardPattern{
        .type = core::PatternType::kInvalid,
        .cards = {},
        .weight = 0,
        .length = 0,
        .label = "pass",
    });
  }
  return legal;
}

EncodedBatch EncodeSnapshot(const landlords::protocol::RoomSnapshot& snapshot) {
  const auto seats = BuildSeats(snapshot);
  const auto current_it = seats.position_by_player.find(snapshot.current_turn_player_id());
  if (current_it == seats.position_by_player.end()) {
    throw std::runtime_error("missing acting player position");
  }
  const std::string& position = current_it->second;
  const auto history = BuildHistory(snapshot, seats);
  const auto legal_patterns = BuildLegalPatterns(snapshot);
  if (legal_patterns.empty()) {
    throw std::runtime_error("no legal patterns for ONNX strategy");
  }

  const auto my_handcards = CardsToArray(ProtoCardsToEnvMove(snapshot.self_cards()));
  const auto other_handcards = CardsToArray(BuildOtherHandCards(snapshot));
  const auto last_action = CardsToArray(CurrentLeadMove(history.action_seq));
  const auto bomb_num = BombOneHot(history.bomb_num);
  const auto z = EncodeHistory(history.action_seq);

  std::vector<float> x_batch;
  const int x_width = position == "landlord" ? 373 : 484;
  x_batch.reserve(legal_patterns.size() * static_cast<std::size_t>(x_width));

  for (const auto& pattern : legal_patterns) {
    const auto my_action = CardsToArray(PatternToEnvMove(pattern));
    if (position == "landlord") {
      const auto landlord_up_played = CardsToArray(history.played_cards_by_position.at("landlord_up"));
      const auto landlord_down_played = CardsToArray(history.played_cards_by_position.at("landlord_down"));
      const auto landlord_up_left = OneHotCardsLeft(seats.cards_left_by_position.at("landlord_up"), 17);
      const auto landlord_down_left = OneHotCardsLeft(seats.cards_left_by_position.at("landlord_down"), 17);
      AppendFloats(x_batch, my_handcards);
      AppendFloats(x_batch, other_handcards);
      AppendFloats(x_batch, last_action);
      AppendFloats(x_batch, landlord_up_played);
      AppendFloats(x_batch, landlord_down_played);
      AppendFloats(x_batch, landlord_up_left);
      AppendFloats(x_batch, landlord_down_left);
      AppendFloats(x_batch, bomb_num);
      AppendFloats(x_batch, my_action);
    } else {
      const std::string teammate = position == "landlord_up" ? "landlord_down" : "landlord_up";
      const auto landlord_played = CardsToArray(history.played_cards_by_position.at("landlord"));
      const auto teammate_played = CardsToArray(history.played_cards_by_position.at(teammate));
      const auto last_landlord_action = CardsToArray(history.last_move_by_position.at("landlord"));
      const auto last_teammate_action = CardsToArray(history.last_move_by_position.at(teammate));
      const auto landlord_left = OneHotCardsLeft(seats.cards_left_by_position.at("landlord"), 20);
      const auto teammate_left = OneHotCardsLeft(seats.cards_left_by_position.at(teammate), 17);
      AppendFloats(x_batch, my_handcards);
      AppendFloats(x_batch, other_handcards);
      AppendFloats(x_batch, landlord_played);
      AppendFloats(x_batch, teammate_played);
      AppendFloats(x_batch, last_action);
      AppendFloats(x_batch, last_landlord_action);
      AppendFloats(x_batch, last_teammate_action);
      AppendFloats(x_batch, landlord_left);
      AppendFloats(x_batch, teammate_left);
      AppendFloats(x_batch, bomb_num);
      AppendFloats(x_batch, my_action);
    }
  }

  std::vector<float> z_batch;
  z_batch.reserve(legal_patterns.size() * z.size());
  for (std::size_t index = 0; index < legal_patterns.size(); ++index) {
    AppendFloats(z_batch, z);
  }

  return EncodedBatch{
      .legal_patterns = legal_patterns,
      .z_batch = std::move(z_batch),
      .x_batch = std::move(x_batch),
      .batch_size = legal_patterns.size(),
      .x_width = x_width,
  };
}

const char* DifficultySuffix(landlords::protocol::BotDifficulty difficulty) {
  switch (difficulty) {
    case landlords::protocol::BOT_DIFFICULTY_EASY:
      return "EASY";
    case landlords::protocol::BOT_DIFFICULTY_HARD:
      return "HARD";
    case landlords::protocol::BOT_DIFFICULTY_NORMAL:
    case landlords::protocol::BOT_DIFFICULTY_UNSPECIFIED:
      return "NORMAL";
  }
  return "NORMAL";
}

std::filesystem::path FindProjectRoot() {
  std::error_code error;
  auto current = std::filesystem::current_path(error);
  if (error) {
    return {};
  }
  while (!current.empty()) {
    if (std::filesystem::exists(current / "pubspec.yaml", error) &&
        std::filesystem::exists(current / "backend" / "server" / "CMakeLists.txt",
                                error)) {
      return current;
    }
    const auto parent = current.parent_path();
    if (parent == current) {
      break;
    }
    current = parent;
  }
  return {};
}

std::filesystem::path ResolveProjectRelativePath(
    const std::filesystem::path& path) {
  if (path.is_absolute()) {
    return path.lexically_normal();
  }
  if (const auto project_root = FindProjectRoot(); !project_root.empty()) {
    return (project_root / path).lexically_normal();
  }
  std::error_code error;
  const auto current = std::filesystem::current_path(error);
  if (error) {
    return path.lexically_normal();
  }
  return (current / path).lexically_normal();
}

std::filesystem::path LoadOnnxDirForDifficulty(
    landlords::protocol::BotDifficulty difficulty) {
  const std::string env_name =
      "LANDLORDS_DOUZERO_ONNX_DIR_" + std::string(DifficultySuffix(difficulty));
  if (const char* scoped = std::getenv(env_name.c_str());
      scoped != nullptr && *scoped != '\0') {
    return ResolveProjectRelativePath(std::filesystem::path(scoped));
  }
  const char* raw = std::getenv("LANDLORDS_DOUZERO_ONNX_DIR");
  if (raw != nullptr && *raw != '\0') {
    return ResolveProjectRelativePath(std::filesystem::path(raw));
  }
  switch (difficulty) {
    case landlords::protocol::BOT_DIFFICULTY_EASY:
      return ResolveProjectRelativePath(
          std::filesystem::path("backend/ai_models/onnx/douzero_ADP"));
    case landlords::protocol::BOT_DIFFICULTY_HARD:
      return ResolveProjectRelativePath(
          std::filesystem::path("backend/ai_models/onnx/douzero_WP"));
    case landlords::protocol::BOT_DIFFICULTY_NORMAL:
    case landlords::protocol::BOT_DIFFICULTY_UNSPECIFIED:
      return ResolveProjectRelativePath(
          std::filesystem::path("backend/ai_models/onnx/sl"));
  }
  return ResolveProjectRelativePath(
      std::filesystem::path("backend/ai_models/onnx/sl"));
}

Ort::Env& OrtEnvironment() {
  static Ort::Env env(ORT_LOGGING_LEVEL_WARNING, "landlords_onnx");
  return env;
}

int LoadOnnxThreads() {
  const char* raw = std::getenv("LANDLORDS_ONNX_NUM_THREADS");
  if (raw == nullptr || *raw == '\0') {
    return 1;
  }
  return std::max(1, std::atoi(raw));
}

class OnnxRoleModel {
 public:
  OnnxRoleModel(const std::filesystem::path& model_path, int x_width)
      : x_width_(x_width) {
    Ort::SessionOptions options;
    options.SetGraphOptimizationLevel(GraphOptimizationLevel::ORT_ENABLE_EXTENDED);
    options.SetIntraOpNumThreads(LoadOnnxThreads());
    session_ = Ort::Session(OrtEnvironment(), model_path.c_str(), options);
  }

  std::size_t ChooseIndex(const EncodedBatch& batch) {
    const auto started = std::chrono::steady_clock::now();
    Ort::MemoryInfo memory_info =
        Ort::MemoryInfo::CreateCpu(OrtArenaAllocator, OrtMemTypeDefault);

    const std::array<int64_t, 3> z_shape = {
        static_cast<int64_t>(batch.batch_size),
        kHistoryRows,
        kHistoryCols,
    };
    const std::array<int64_t, 2> x_shape = {
        static_cast<int64_t>(batch.batch_size),
        static_cast<int64_t>(x_width_),
    };

    auto z_tensor = Ort::Value::CreateTensor<float>(memory_info,
                                                    const_cast<float*>(batch.z_batch.data()),
                                                    batch.z_batch.size(),
                                                    z_shape.data(),
                                                    z_shape.size());
    auto x_tensor = Ort::Value::CreateTensor<float>(memory_info,
                                                    const_cast<float*>(batch.x_batch.data()),
                                                    batch.x_batch.size(),
                                                    x_shape.data(),
                                                    x_shape.size());

    std::array<Ort::Value, 2> inputs = {std::move(z_tensor), std::move(x_tensor)};
    constexpr std::array<const char*, 2> input_names = {"z_batch", "x_batch"};
    constexpr std::array<const char*, 1> output_names = {"values"};

    auto outputs = session_.Run(Ort::RunOptions{nullptr},
                                input_names.data(),
                                inputs.data(),
                                inputs.size(),
                                output_names.data(),
                                output_names.size());
    const float* values = outputs.front().GetTensorData<float>();
    const std::size_t value_count =
        outputs.front().GetTensorTypeAndShapeInfo().GetElementCount();

    std::size_t best_index = 0;
    float best_value = values[0];
    for (std::size_t index = 1; index < value_count; ++index) {
      if (values[index] > best_value) {
        best_value = values[index];
        best_index = index;
      }
    }
    const auto elapsed_ms =
        std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::steady_clock::now() - started)
            .count();
    LANDLORDS_LOG(landlords::core::LogLevel::kDebug,
                  "onnx_bot_strategy",
                  "session_run batch=" << batch.batch_size << " x_width=" << x_width_
                                       << " elapsed_ms=" << elapsed_ms);
    return best_index;
  }

 private:
  Ort::Session session_{nullptr};
  int x_width_ = 0;
};

class OnnxBotStrategy final : public IBotStrategy {
 public:
  explicit OnnxBotStrategy(std::filesystem::path model_dir)
      : model_dir_(std::move(model_dir)),
        landlord_(model_dir_ / "landlord.onnx", 373),
        landlord_up_(model_dir_ / "landlord_up.onnx", 484),
        landlord_down_(model_dir_ / "landlord_down.onnx", 484) {
    LANDLORDS_LOG(landlords::core::LogLevel::kInfo,
                  "onnx_bot_strategy",
                  "loaded ONNX models from " << model_dir_);
  }

  std::optional<BotDecision> ChooseMove(
      const landlords::protocol::RoomSnapshot& snapshot) override {
    try {
      const auto decision_started = std::chrono::steady_clock::now();
      const auto seats = BuildSeats(snapshot);
      const auto current = seats.position_by_player.find(snapshot.current_turn_player_id());
      if (current == seats.position_by_player.end()) {
        return std::nullopt;
      }
      auto player_id_for_position = [&](std::string_view position) -> std::string {
        for (const auto& [player_id, mapped_position] : seats.position_by_player) {
          if (mapped_position == position) {
            return player_id;
          }
        }
        return "-";
      };
      LANDLORDS_LOG(landlords::core::LogLevel::kDebug,
                    "onnx_bot_strategy",
                    "seat_map room=" << snapshot.room_id()
                                     << " landlord=" << player_id_for_position("landlord")
                                     << " landlord_down="
                                     << player_id_for_position("landlord_down")
                                     << " landlord_up="
                                     << player_id_for_position("landlord_up")
                                     << " acting=" << snapshot.current_turn_player_id()
                                     << " acting_role=" << current->second);

      const auto encode_started = std::chrono::steady_clock::now();
      const auto batch = EncodeSnapshot(snapshot);
      const auto encode_elapsed_ms =
          std::chrono::duration_cast<std::chrono::milliseconds>(
              std::chrono::steady_clock::now() - encode_started)
              .count();
      LANDLORDS_LOG(landlords::core::LogLevel::kDebug,
                    "onnx_bot_strategy",
                    "start room=" << snapshot.room_id()
                                  << " turn=" << snapshot.current_turn_player_id()
                                  << " role=" << current->second
                                  << " model=" << ModelNameForPosition(current->second)
                                  << " self_cards=" << snapshot.self_cards_size()
                                  << " legal_actions=" << batch.batch_size
                                  << " phase=" << static_cast<int>(snapshot.phase())
                                  << " encode_ms=" << encode_elapsed_ms);
      auto& model = ModelForPosition(current->second);
      const auto chosen_index = model.ChooseIndex(batch);
      const auto& chosen = batch.legal_patterns.at(chosen_index);

      BotDecision decision;
      decision.kind = chosen.cards.empty() ? BotDecision::Kind::kPass : BotDecision::Kind::kPlay;
      for (const auto& card : chosen.cards) {
        decision.card_ids.push_back(card.id);
      }
      const auto total_elapsed_ms =
          std::chrono::duration_cast<std::chrono::milliseconds>(
              std::chrono::steady_clock::now() - decision_started)
              .count();
      LANDLORDS_LOG(landlords::core::LogLevel::kDebug,
                    "onnx_bot_strategy",
                    "room=" << snapshot.room_id()
                            << " turn=" << snapshot.current_turn_player_id()
                            << " role=" << current->second
                            << " model=" << ModelNameForPosition(current->second)
                            << " legal_actions=" << batch.batch_size
                            << " chosen_index=" << chosen_index
                            << " label=" << chosen.label
                            << " cards=" << PatternCardsText(chosen)
                            << " total_ms=" << total_elapsed_ms);
      return decision;
    } catch (const std::exception& exception) {
      LANDLORDS_LOG(landlords::core::LogLevel::kWarn,
                    "onnx_bot_strategy",
                    "inference failed: " << exception.what());
      return std::nullopt;
    }
  }

 private:
  const char* ModelNameForPosition(const std::string& position) const {
    if (position == "landlord") {
      return "landlord.onnx";
    }
    if (position == "landlord_up") {
      return "landlord_up.onnx";
    }
    return "landlord_down.onnx";
  }

  OnnxRoleModel& ModelForPosition(const std::string& position) {
    if (position == "landlord") {
      return landlord_;
    }
    if (position == "landlord_up") {
      return landlord_up_;
    }
    return landlord_down_;
  }

  std::filesystem::path model_dir_;
  OnnxRoleModel landlord_;
  OnnxRoleModel landlord_up_;
  OnnxRoleModel landlord_down_;
};

#endif

}  // namespace

bool OnnxRuntimeAvailable() {
#ifdef LANDLORDS_WITH_ONNXRUNTIME
  return true;
#else
  return false;
#endif
}

std::shared_ptr<IBotStrategy> CreateOnnxBotStrategyFromEnv() {
  return CreateOnnxBotStrategyForDifficulty(
      landlords::protocol::BOT_DIFFICULTY_NORMAL);
}

std::shared_ptr<IBotStrategy> CreateOnnxBotStrategyForDifficulty(
    landlords::protocol::BotDifficulty difficulty) {
  return CreateOnnxBotStrategyFromDir(LoadOnnxDirForDifficulty(difficulty));
}

std::shared_ptr<IBotStrategy> CreateOnnxBotStrategyFromDir(
    const std::filesystem::path& model_dir) {
#ifdef LANDLORDS_WITH_ONNXRUNTIME
  try {
    static std::mutex cache_mutex;
    static std::unordered_map<std::string, std::weak_ptr<IBotStrategy>> cache;
    const auto cache_key = model_dir.lexically_normal().string();
    {
      std::lock_guard lock(cache_mutex);
      if (const auto existing = cache[cache_key].lock(); existing != nullptr) {
        return existing;
      }
    }

    if (!std::filesystem::exists(model_dir / "landlord.onnx") ||
        !std::filesystem::exists(model_dir / "landlord_up.onnx") ||
        !std::filesystem::exists(model_dir / "landlord_down.onnx")) {
      LANDLORDS_LOG(landlords::core::LogLevel::kWarn,
                    "onnx_bot_strategy",
                    "ONNX model files not found under " << model_dir);
      return nullptr;
    }
    auto strategy = std::make_shared<OnnxBotStrategy>(model_dir);
    {
      std::lock_guard lock(cache_mutex);
      cache[cache_key] = strategy;
    }
    return strategy;
  } catch (const std::exception& exception) {
    LANDLORDS_LOG(landlords::core::LogLevel::kError,
                  "onnx_bot_strategy",
                  "failed to initialize ONNX strategy: " << exception.what());
    return nullptr;
  }
#else
  LANDLORDS_LOG(landlords::core::LogLevel::kWarn,
                "onnx_bot_strategy",
                "ONNX Runtime is not enabled in this build");
  return nullptr;
#endif
}

}  // namespace landlords::ai
