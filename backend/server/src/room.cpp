#include "landlords/ai/bot_strategy.h"
#include "landlords/core/logging.h"
#include "landlords/game/bid_strategy.h"
#include "landlords/game/room.h"

#include <algorithm>
#include <array>
#include <cstdlib>
#include <map>
#include <random>
#include <sstream>
#include <string_view>
#include <unordered_set>

namespace landlords::game {

namespace {

std::mt19937& Rng() {
  static std::mt19937 engine{std::random_device{}()};
  return engine;
}

int LoadDelayMs(const char* env_name, int fallback_ms) {
  const char* raw = std::getenv(env_name);
  if (raw == nullptr || *raw == '\0') {
    return fallback_ms;
  }
  return std::max(0, std::atoi(raw));
}

std::int64_t RandomDelayMs(int min_ms, int max_ms) {
  if (max_ms <= min_ms) {
    return min_ms;
  }
  std::uniform_int_distribution<int> jitter(min_ms, max_ms);
  return jitter(Rng());
}

bool StartsWith(std::string_view text, std::string_view prefix) {
  return text.substr(0, prefix.size()) == prefix;
}

const char* ActionTypeName(landlords::protocol::ActionType action_type) {
  switch (action_type) {
    case landlords::protocol::ACTION_TYPE_PLAY:
      return "play";
    case landlords::protocol::ACTION_TYPE_PASS:
      return "pass";
  }
  return "unknown";
}

const char* BotDifficultyName(landlords::protocol::BotDifficulty difficulty) {
  switch (difficulty) {
    case landlords::protocol::BOT_DIFFICULTY_EASY:
      return "easy";
    case landlords::protocol::BOT_DIFFICULTY_HARD:
      return "hard";
    case landlords::protocol::BOT_DIFFICULTY_NORMAL:
    case landlords::protocol::BOT_DIFFICULTY_UNSPECIFIED:
      return "normal";
  }
  return "normal";
}

std::string CardsText(const std::vector<core::Card>& cards) {
  if (cards.empty()) {
    return "-";
  }
  std::ostringstream stream;
  for (std::size_t index = 0; index < cards.size(); ++index) {
    if (index > 0) {
      stream << ",";
    }
    stream << cards[index].rank;
  }
  return stream.str();
}

void FillRoomPlayer(const core::PlayerState& player, landlords::protocol::RoomPlayer* target) {
  target->set_player_id(player.player_id);
  target->set_display_name(player.display_name);
  target->set_is_bot(player.is_bot);
  target->set_role(player.is_landlord ? landlords::protocol::PLAYER_ROLE_LANDLORD
                                      : landlords::protocol::PLAYER_ROLE_FARMER);
  target->set_cards_left(static_cast<int>(player.hand.size()));
  target->set_round_score(player.round_score);
}

bool SameSide(const core::PlayerState& left, const core::PlayerState& right) {
  return left.is_landlord == right.is_landlord;
}

std::vector<core::Card> RemoveCardsById(const std::vector<core::Card>& hand,
                                        const std::vector<core::Card>& chosen) {
  std::unordered_set<std::string> ids;
  ids.reserve(chosen.size());
  for (const auto& card : chosen) {
    ids.insert(card.id);
  }

  std::vector<core::Card> remaining;
  remaining.reserve(hand.size());
  for (const auto& card : hand) {
    if (!ids.contains(card.id)) {
      remaining.push_back(card);
    }
  }
  return remaining;
}

std::map<int, int> CountByValue(const std::vector<core::Card>& hand) {
  std::map<int, int> counts;
  for (const auto& card : hand) {
    ++counts[card.value];
  }
  return counts;
}

int ConsecutiveBonus(const std::map<int, int>& counts, int min_count, int min_length) {
  std::vector<int> values;
  values.reserve(counts.size());
  for (const auto& [value, count] : counts) {
    if (count >= min_count && value < 15) {
      values.push_back(value);
    }
  }

  int bonus = 0;
  for (std::size_t start = 0; start < values.size();) {
    std::size_t end = start;
    while (end + 1 < values.size() && values[end + 1] == values[end] + 1) {
      ++end;
    }
    const int run_length = static_cast<int>(end - start + 1);
    if (run_length >= min_length) {
      bonus += run_length - min_length + 1;
    }
    start = end + 1;
  }
  return bonus;
}

int EstimateHandBurden(const std::vector<core::Card>& hand) {
  const auto counts = CountByValue(hand);
  int burden = 0;
  for (const auto& [value, count] : counts) {
    if (count == 1) {
      burden += value >= 15 ? 6 : 3;
    } else if (count == 2) {
      burden += 2;
    } else if (count == 3) {
      burden += 1;
    } else if (count == 4) {
      burden += 4;
    }
  }

  burden -= ConsecutiveBonus(counts, 1, 5) * 4;
  burden -= ConsecutiveBonus(counts, 2, 3) * 4;
  burden -= ConsecutiveBonus(counts, 3, 2) * 5;
  return std::max(burden, 0);
}

int HighCardPenalty(const std::vector<core::Card>& cards) {
  int penalty = 0;
  for (const auto& card : cards) {
    if (card.value >= 16) {
      penalty += 16;
    } else if (card.value == 15) {
      penalty += 9;
    } else if (card.value == 14) {
      penalty += 4;
    }
  }
  return penalty;
}

int PatternPenalty(core::PatternType type, bool leading) {
  switch (type) {
    case core::PatternType::kStraight:
    case core::PatternType::kStraightPair:
    case core::PatternType::kAirplane:
    case core::PatternType::kAirplaneWithSingle:
    case core::PatternType::kAirplaneWithPair:
      return leading ? -12 : -4;
    case core::PatternType::kTripleWithSingle:
    case core::PatternType::kTripleWithPair:
      return leading ? -6 : 4;
    case core::PatternType::kTriple:
      return leading ? -2 : 8;
    case core::PatternType::kSingle:
      return leading ? 18 : 11;
    case core::PatternType::kPair:
      return leading ? 13 : 7;
    case core::PatternType::kFourWithTwoSingles:
    case core::PatternType::kFourWithTwoPairs:
      return 24;
    case core::PatternType::kBomb:
      return 90;
    case core::PatternType::kRocket:
      return 120;
    case core::PatternType::kInvalid:
      return 999;
  }
  return 0;
}

int AnnouncementDelayMs(const core::RoomAction& action) {
  if (action.pattern_label == "managed_on" || action.pattern_label == "managed_off") {
    return LoadDelayMs("LANDLORDS_MANAGED_NOTICE_DELAY_MS", 2300);
  }
  if (action.pattern_label == "bid_pass") {
    return LoadDelayMs("LANDLORDS_BID_PASS_NOTICE_DELAY_MS", 1700);
  }
  if (StartsWith(action.pattern_label, "bid_")) {
    return LoadDelayMs("LANDLORDS_BID_NOTICE_DELAY_MS", 2200);
  }
  if (action.action_type == landlords::protocol::ACTION_TYPE_PASS) {
    return LoadDelayMs("LANDLORDS_PASS_NOTICE_DELAY_MS", 1800);
  }
  if (action.pattern_label == "single" ||
      action.pattern_label == "pair" ||
      action.pattern_label == "triple") {
    return LoadDelayMs("LANDLORDS_SIMPLE_PLAY_NOTICE_DELAY_MS", 2200);
  }
  if (action.pattern_label == "straight" ||
      action.pattern_label == "straight_pair" ||
      action.pattern_label == "airplane" ||
      action.pattern_label == "airplane_with_single" ||
      action.pattern_label == "airplane_with_pair" ||
      action.pattern_label == "triple_with_single" ||
      action.pattern_label == "triple_with_pair" ||
      action.pattern_label == "four_with_two_singles" ||
      action.pattern_label == "four_with_two_pairs") {
    return LoadDelayMs("LANDLORDS_COMPLEX_PLAY_NOTICE_DELAY_MS", 3000);
  }
  if (action.pattern_label == "bomb") {
    return LoadDelayMs("LANDLORDS_BOMB_NOTICE_DELAY_MS", 3400);
  }
  if (action.pattern_label == "rocket") {
    return LoadDelayMs("LANDLORDS_ROCKET_NOTICE_DELAY_MS", 3800);
  }
  return LoadDelayMs("LANDLORDS_DEFAULT_NOTICE_DELAY_MS", 2200);
}

bool CanFinishWithMove(const core::PlayerState& player, const core::CardPattern& candidate) {
  return candidate.cards.size() == player.hand.size();
}

bool IsWeakPattern(const std::optional<core::CardPattern>& pattern) {
  if (!pattern.has_value()) {
    return true;
  }

  switch (pattern->type) {
    case core::PatternType::kSingle:
      return pattern->weight <= 10;
    case core::PatternType::kPair:
      return pattern->weight <= 9;
    case core::PatternType::kTriple:
    case core::PatternType::kTripleWithSingle:
    case core::PatternType::kTripleWithPair:
      return pattern->weight <= 8;
    case core::PatternType::kStraight:
    case core::PatternType::kStraightPair:
      return pattern->length <= 6;
    case core::PatternType::kAirplane:
    case core::PatternType::kAirplaneWithSingle:
    case core::PatternType::kAirplaneWithPair:
      return false;
    case core::PatternType::kBomb:
    case core::PatternType::kRocket:
      return false;
    case core::PatternType::kFourWithTwoSingles:
    case core::PatternType::kFourWithTwoPairs:
      return false;
    case core::PatternType::kInvalid:
      return true;
  }
  return true;
}

int ScoreMove(const core::PlayerState& player,
              const core::CardPattern& candidate,
              bool leading,
              bool opponent_threat,
              bool teammate_takeover,
              bool must_protect_control) {
  const auto remaining = RemoveCardsById(player.hand, candidate.cards);
  if (remaining.empty()) {
    return -100000;
  }

  int score = EstimateHandBurden(remaining) * 12;
  score += PatternPenalty(candidate.type, leading);
  score += leading ? candidate.weight : candidate.weight * 2;

  if (opponent_threat || must_protect_control) {
    score -= candidate.weight * 2;
  } else {
    score += HighCardPenalty(candidate.cards);
  }

  if (player.hand.size() <= 6U) {
    score -= candidate.length * 6;
  } else if (leading &&
             (candidate.type == core::PatternType::kSingle ||
              candidate.type == core::PatternType::kPair)) {
    score += 8;
  }

  if (candidate.type == core::PatternType::kBomb || candidate.type == core::PatternType::kRocket) {
    score += opponent_threat ? 10 : 60;
  }

  if (teammate_takeover) {
    score += must_protect_control ? 10 : 48;
  }

  return score;
}

std::int64_t NextDecisionDelayMs(const core::PlayerState& player,
                                 landlords::protocol::RoomPhase phase,
                                 const core::RoomAction* last_action) {
  int think_delay_ms = 0;
  if (!player.is_bot) {
    think_delay_ms = RandomDelayMs(LoadDelayMs("LANDLORDS_MANAGED_DELAY_MIN_MS", 380),
                                   LoadDelayMs("LANDLORDS_MANAGED_DELAY_MAX_MS", 680));
  } else if (phase == landlords::protocol::ROOM_PHASE_WAITING) {
    think_delay_ms = RandomDelayMs(LoadDelayMs("LANDLORDS_BOT_BID_DELAY_MIN_MS", 260),
                                   LoadDelayMs("LANDLORDS_BOT_BID_DELAY_MAX_MS", 460));
  } else {
    think_delay_ms = RandomDelayMs(LoadDelayMs("LANDLORDS_BOT_PLAY_DELAY_MIN_MS", 320),
                                   LoadDelayMs("LANDLORDS_BOT_PLAY_DELAY_MAX_MS", 520));
  }

  static_cast<void>(last_action);
  return think_delay_ms;
}

}  // namespace

Room::Room(std::string room_id,
           landlords::protocol::MatchMode mode,
           std::vector<core::PlayerState> players,
           landlords::protocol::BotDifficulty bot_difficulty,
           std::shared_ptr<ai::IBotStrategy> bot_strategy,
           std::unordered_map<std::string, std::shared_ptr<ai::IBotStrategy>> bot_strategies_by_player)
    : room_id_(std::move(room_id)),
      mode_(mode),
      players_(std::move(players)),
      bot_difficulty_(bot_difficulty),
      bot_strategy_(std::move(bot_strategy)),
      bot_strategies_by_player_(std::move(bot_strategies_by_player)) {
  StartGame();
}

bool Room::HasPlayer(const std::string& player_id) const {
  return FindPlayer(player_id) != nullptr;
}

landlords::protocol::RoomSnapshot Room::BuildSnapshotFor(const std::string& player_id) const {
  landlords::protocol::RoomSnapshot snapshot;
  snapshot.set_room_id(room_id_);
  snapshot.set_phase(phase_);
  snapshot.set_mode(mode_);
  snapshot.set_current_turn_player_id(current_turn_player_id_);
  snapshot.set_status_text(status_text_);
  snapshot.set_base_score(base_score_);
  snapshot.set_multiplier(multiplier_);
  snapshot.set_current_round_score(base_score_ * multiplier_);
  snapshot.set_spring_triggered(spring_triggered_);
  snapshot.set_turn_serial(turn_serial_);

  for (const auto& player : players_) {
    FillRoomPlayer(player, snapshot.add_players());
  }
  for (const auto& card : landlord_cards_) {
    core::FillProtoCard(card, snapshot.add_landlord_cards());
  }
  for (const auto& action : actions_) {
    auto* target = snapshot.add_recent_actions();
    target->set_action_id(action.action_id);
    target->set_player_id(action.player_id);
    target->set_action_type(action.action_type);
    target->set_pattern(action.pattern_label);
    target->set_timestamp_ms(action.timestamp_ms);
    target->set_pattern_type(core::ToProtoPatternType(core::EvaluatePattern(action.cards).type));
    for (const auto& card : action.cards) {
      core::FillProtoCard(card, target->add_cards());
    }
  }

  if (const auto* self = FindPlayer(player_id); self != nullptr) {
    for (const auto& card : self->hand) {
      core::FillProtoCard(card, snapshot.add_self_cards());
    }

    std::unordered_map<std::string, int> rank_counter;
    for (const auto& card : core::BuildDeck()) {
      ++rank_counter[card.rank];
    }
    for (const auto& card : self->hand) {
      --rank_counter[card.rank];
    }
    if (phase_ != landlords::protocol::ROOM_PHASE_WAITING) {
      for (const auto& card : landlord_cards_) {
        --rank_counter[card.rank];
      }
    }
    for (const auto& action : actions_) {
      for (const auto& card : action.cards) {
        --rank_counter[card.rank];
      }
    }
    for (const auto& [rank, remaining] : rank_counter) {
      auto* entry = snapshot.add_card_counter();
      entry->set_rank(rank);
      entry->set_remaining(std::max(remaining, 0));
    }
  }

  return snapshot;
}

std::optional<core::CardPattern> Room::FindSuggestion(const std::string& player_id) const {
  if (phase_ != landlords::protocol::ROOM_PHASE_PLAYING) {
    return std::nullopt;
  }
  const auto* player = FindPlayer(player_id);
  if (player == nullptr) {
    return std::nullopt;
  }
  return FindPlayablePattern(*player);
}

std::optional<std::vector<std::string>> Room::SuggestCardIds(const std::string& player_id) const {
  if (phase_ != landlords::protocol::ROOM_PHASE_PLAYING) {
    return std::nullopt;
  }
  if (current_turn_player_id_ != player_id) {
    return std::nullopt;
  }

  const auto* player = FindPlayer(player_id);
  if (player == nullptr) {
    return std::nullopt;
  }

  const auto strategy = ResolveBotStrategyForPlayer(player_id);
  if (strategy == nullptr) {
    LANDLORDS_LOG(landlords::core::LogLevel::kWarn,
                  "room",
                  "room=" << room_id_ << " suggest player=" << player_id
                          << " difficulty=" << BotDifficultyName(bot_difficulty_)
                          << " source=model_unavailable");
    return std::nullopt;
  }

  const auto decision = strategy->ChooseMove(BuildSnapshotFor(player_id));
  if (!decision.has_value()) {
    LANDLORDS_LOG(landlords::core::LogLevel::kWarn,
                  "room",
                  "room=" << room_id_ << " suggest player=" << player_id
                          << " difficulty=" << BotDifficultyName(bot_difficulty_)
                          << " source=model_empty");
    return std::nullopt;
  }

  if (decision->kind == ai::BotDecision::Kind::kPass) {
    if (IsLeadTurnFor(player_id)) {
      LANDLORDS_LOG(landlords::core::LogLevel::kWarn,
                    "room",
                    "room=" << room_id_ << " suggest player=" << player_id
                            << " difficulty=" << BotDifficultyName(bot_difficulty_)
                            << " source=model_invalid reason=lead_player_cannot_pass");
      return std::nullopt;
    }
    LANDLORDS_LOG(landlords::core::LogLevel::kInfo,
                  "room",
                  "room=" << room_id_ << " suggest player=" << player_id
                          << " difficulty=" << BotDifficultyName(bot_difficulty_)
                          << " source=model cards=0");
    return std::vector<std::string>{};
  }

  std::unordered_set<std::string> wanted(decision->card_ids.begin(), decision->card_ids.end());
  std::vector<core::Card> chosen;
  chosen.reserve(decision->card_ids.size());
  for (const auto& card : player->hand) {
    if (wanted.contains(card.id)) {
      chosen.push_back(card);
    }
  }
  if (chosen.size() != decision->card_ids.size()) {
    LANDLORDS_LOG(landlords::core::LogLevel::kWarn,
                  "room",
                  "room=" << room_id_ << " suggest player=" << player_id
                          << " difficulty=" << BotDifficultyName(bot_difficulty_)
                          << " source=model_invalid reason=invalid_cards");
    return std::nullopt;
  }

  const auto pattern = core::EvaluatePattern(chosen);
  if (pattern.type == core::PatternType::kInvalid) {
    LANDLORDS_LOG(landlords::core::LogLevel::kWarn,
                  "room",
                  "room=" << room_id_ << " suggest player=" << player_id
                          << " difficulty=" << BotDifficultyName(bot_difficulty_)
                          << " source=model_invalid reason=invalid_pattern");
    return std::nullopt;
  }
  if (!core::CanBeat(pattern, last_pattern_)) {
    LANDLORDS_LOG(landlords::core::LogLevel::kWarn,
                  "room",
                  "room=" << room_id_ << " suggest player=" << player_id
                          << " difficulty=" << BotDifficultyName(bot_difficulty_)
                          << " source=model_invalid reason=cannot_beat_table");
    return std::nullopt;
  }

  LANDLORDS_LOG(landlords::core::LogLevel::kInfo,
                "room",
                "room=" << room_id_ << " suggest player=" << player_id
                        << " difficulty=" << BotDifficultyName(bot_difficulty_)
                        << " source=model cards=" << decision->card_ids.size());
  return decision->card_ids;
}

std::optional<std::string> Room::CallScore(const std::string& player_id, int score) {
  if (phase_ != landlords::protocol::ROOM_PHASE_WAITING) {
    return "bidding_closed";
  }
  if (player_id != current_turn_player_id_) {
    return "not_your_bidding_turn";
  }
  if (score < 0 || score > 3) {
    return "invalid_bid_score";
  }
  if (score > 0 && score < highest_bid_) {
    return "bid_lower_than_current";
  }

  auto* player = FindPlayer(player_id);
  if (player == nullptr) {
    return "player_not_found";
  }

  if (!auto_playing_) {
    player->is_managed = false;
  }
  AppendAction(player_id,
               score == 0 ? landlords::protocol::ACTION_TYPE_PASS : landlords::protocol::ACTION_TYPE_PLAY,
               {},
               score == 0 ? "bid_pass" : "bid_" + std::to_string(score));
  status_text_ = score == 0 ? "bidding_pass" : "bidding_called";

  if (score > 0) {
    highest_bid_ = score;
    highest_bid_player_id_ = player_id;
  }

  ++bid_turns_taken_;
  if (highest_bid_ >= 3 || bid_turns_taken_ >= static_cast<int>(players_.size())) {
    FinalizeBidding();
    return std::nullopt;
  }

  AdvanceBidTurn();
  return std::nullopt;
}

std::optional<std::string> Room::SetManaged(const std::string& player_id, bool managed) {
  if (finished()) {
    return "round_finished";
  }
  if (!pending_winner_player_id_.empty()) {
    return "round_finishing";
  }

  auto* player = FindPlayer(player_id);
  if (player == nullptr || player->is_bot) {
    return "player_not_found";
  }

  player->is_managed = managed;
  AppendAction(player_id,
               landlords::protocol::ACTION_TYPE_PLAY,
               {},
               managed ? "managed_on" : "managed_off");
  status_text_ = managed ? "managed_enabled" : "managed_disabled";

  if (player_id == current_turn_player_id_) {
    turn_started_ms_ = core::NowMs();
    if (managed) {
      const auto* last_action = actions_.empty() ? nullptr : &actions_.back();
      decision_ready_at_ms_ = turn_started_ms_ + NextDecisionDelayMs(*player, phase_, last_action);
    } else {
      decision_ready_at_ms_ = 0;
    }
  }
  return std::nullopt;
}

std::optional<std::string> Room::PlayCards(const std::string& player_id,
                                           const std::vector<std::string>& card_ids) {
  if (phase_ != landlords::protocol::ROOM_PHASE_PLAYING) {
    return "room_not_playing";
  }
  if (!pending_winner_player_id_.empty()) {
    return "round_finishing";
  }
  if (player_id != current_turn_player_id_) {
    return "not_your_turn";
  }

  auto* player = FindPlayer(player_id);
  if (player == nullptr) {
    return "player_not_found";
  }
  if (!auto_playing_) {
    player->is_managed = false;
  }

  std::unordered_set<std::string> wanted(card_ids.begin(), card_ids.end());
  std::vector<core::Card> chosen;
  chosen.reserve(card_ids.size());
  for (const auto& card : player->hand) {
    if (wanted.contains(card.id)) {
      chosen.push_back(card);
    }
  }
  if (chosen.size() != card_ids.size()) {
    return "invalid_cards";
  }

  const auto pattern = core::EvaluatePattern(chosen);
  if (pattern.type == core::PatternType::kInvalid) {
    return "invalid_pattern";
  }
  if (!core::CanBeat(pattern, last_pattern_)) {
    return "cannot_beat_table";
  }

  player->hand.erase(std::remove_if(player->hand.begin(),
                                    player->hand.end(),
                                    [&](const core::Card& card) { return wanted.contains(card.id); }),
                     player->hand.end());

  if (player->is_landlord) {
    ++landlord_play_count_;
  } else {
    ++farmer_play_count_;
  }
  if (pattern.type == core::PatternType::kBomb || pattern.type == core::PatternType::kRocket) {
    multiplier_ *= 2;
  }

  AppendAction(player_id, landlords::protocol::ACTION_TYPE_PLAY, pattern.cards, pattern.label);
  last_pattern_ = pattern;
  last_action_player_id_ = player_id;
  pass_count_ = 0;
  status_text_ = "cards_played";

  if (player->hand.empty()) {
    ScheduleRoundFinish(*player, actions_.empty() ? nullptr : &actions_.back());
  } else {
    AdvanceTurn();
  }
  RefreshScores();
  return std::nullopt;
}

std::optional<std::string> Room::Pass(const std::string& player_id) {
  if (phase_ != landlords::protocol::ROOM_PHASE_PLAYING) {
    return "room_not_playing";
  }
  if (!pending_winner_player_id_.empty()) {
    return "round_finishing";
  }
  if (player_id != current_turn_player_id_) {
    return "not_your_turn";
  }
  if (IsLeadTurnFor(player_id)) {
    return "lead_player_cannot_pass";
  }

  auto* player = FindPlayer(player_id);
  if (player == nullptr) {
    return "player_not_found";
  }
  if (!auto_playing_) {
    player->is_managed = false;
  }

  AppendAction(player_id, landlords::protocol::ACTION_TYPE_PASS, {}, "pass");
  ++pass_count_;
  if (pass_count_ >= 2) {
    current_turn_player_id_ = last_action_player_id_;
    last_action_player_id_.clear();
    last_pattern_.reset();
    pass_count_ = 0;
    status_text_ = "new_trick";
    ++turn_serial_;
    turn_started_ms_ = core::NowMs();
    decision_ready_at_ms_ = 0;
    ScheduleNextDecision(FindPlayer(current_turn_player_id_),
                         actions_.empty() ? nullptr : &actions_.back());
  } else {
    status_text_ = "player_passed";
    AdvanceTurn();
  }
  return std::nullopt;
}

void Room::DriveBots() {
  if (finished()) {
    return;
  }
  if (!pending_winner_player_id_.empty()) {
    return;
  }

  auto* player = FindPlayer(current_turn_player_id_);
  if (player == nullptr || (!player->is_bot && !player->is_managed)) {
    return;
  }

  const auto now_ms = core::NowMs();
  if (decision_ready_at_ms_ != 0 && now_ms < decision_ready_at_ms_) {
    return;
  }

  std::optional<std::string> error;
  auto_playing_ = true;
  if (phase_ == landlords::protocol::ROOM_PHASE_WAITING) {
    const int bid = ChooseBidAction(player->hand, highest_bid_, bot_difficulty_);
    LANDLORDS_LOG(landlords::core::LogLevel::kDebug,
                  "room",
                  "room=" << room_id_ << " auto bid player=" << player->player_id
                          << " bid=" << bid);
    error = CallScore(player->player_id, bid);
  } else if (phase_ == landlords::protocol::ROOM_PHASE_PLAYING) {
    auto try_heuristic = [&]() {
      const auto suggestion = FindPlayablePattern(*player);
      if (suggestion.has_value()) {
        std::vector<std::string> ids;
        ids.reserve(suggestion->cards.size());
        for (const auto& card : suggestion->cards) {
          ids.push_back(card.id);
        }
        return PlayCards(player->player_id, ids);
      }
      return Pass(player->player_id);
    };

    if ((player->is_bot || player->is_managed)) {
      const auto strategy = ResolveBotStrategyForPlayer(player->player_id);
      const auto remote =
          strategy != nullptr ? strategy->ChooseMove(BuildSnapshotFor(player->player_id))
                              : std::optional<ai::BotDecision>{};
      if (remote.has_value()) {
        error = remote->kind == ai::BotDecision::Kind::kPass
                    ? Pass(player->player_id)
                    : PlayCards(player->player_id, remote->card_ids);
        if (error.has_value()) {
          LANDLORDS_LOG(landlords::core::LogLevel::kWarn,
                        "room",
                        "remote strategy produced invalid move for player=" << player->player_id
                                                                            << " error=" << *error
                                                                            << "; falling back to heuristic");
          error = try_heuristic();
        }
      } else {
        LANDLORDS_LOG(landlords::core::LogLevel::kWarn,
                      "room",
                      "remote strategy unavailable for player=" << player->player_id
                                                                << "; falling back to heuristic");
        error = try_heuristic();
      }
    } else {
      error = try_heuristic();
    }
  }
  auto_playing_ = false;

  if (error.has_value()) {
    status_text_ = *error;
  }
}

void Room::StartGame() {
  auto deck = core::BuildDeck();
  std::shuffle(deck.begin(), deck.end(), Rng());

  actions_.clear();
  landlord_cards_.clear();
  last_pattern_.reset();
  last_action_player_id_.clear();
  current_turn_player_id_.clear();
  base_score_ = 1;
  multiplier_ = 1;
  pass_count_ = 0;
  turn_serial_ = 1;
  spring_triggered_ = false;
  landlord_play_count_ = 0;
  farmer_play_count_ = 0;
  bid_turns_taken_ = 0;
  highest_bid_ = 0;
  highest_bid_player_id_.clear();
  decision_ready_at_ms_ = 0;
  finish_ready_at_ms_ = 0;
  presentation_timeout_at_ms_ = 0;
  pending_winner_player_id_.clear();
  pending_presentation_action_id_.clear();
  presentation_wait_player_id_.clear();

  for (auto& player : players_) {
    player.hand.clear();
    player.is_landlord = false;
    player.is_managed = false;
    player.round_score = 0;
  }

  for (int index = 0; index < 51; ++index) {
    players_[index % 3].hand.push_back(deck[index]);
  }
  landlord_cards_ = {deck.begin() + 51, deck.end()};

  for (auto& player : players_) {
    std::sort(player.hand.begin(), player.hand.end(), [](const core::Card& left, const core::Card& right) {
      return core::CompareCards(left, right) < 0;
    });
  }

  if (mode_ == landlords::protocol::MATCH_MODE_VS_BOT) {
    bid_start_index_ = 0;
    for (std::size_t index = 0; index < players_.size(); ++index) {
      if (!players_[index].is_bot) {
        bid_start_index_ = static_cast<int>(index);
        break;
      }
    }
  } else {
    std::uniform_int_distribution<int> bid_distribution(0, static_cast<int>(players_.size()) - 1);
    bid_start_index_ = bid_distribution(Rng());
  }
  current_turn_player_id_ = players_[bid_start_index_].player_id;
  phase_ = landlords::protocol::ROOM_PHASE_WAITING;
  status_text_ = "waiting_for_bid";
  turn_started_ms_ = core::NowMs();
  ScheduleNextDecision(FindPlayer(current_turn_player_id_));
  LANDLORDS_LOG(landlords::core::LogLevel::kInfo,
                "room",
                "room=" << room_id_ << " start mode="
                        << (mode_ == landlords::protocol::MATCH_MODE_VS_BOT ? "vs_bot" : "pvp")
                        << " difficulty=" << BotDifficultyName(bot_difficulty_)
                        << " first_bid_turn=" << current_turn_player_id_);
  RefreshScores();
}

void Room::AppendAction(const std::string& player_id,
                        landlords::protocol::ActionType action_type,
                        const std::vector<core::Card>& cards,
                        const std::string& pattern_label) {
  actions_.push_back(core::RoomAction{
      .action_id = core::GenerateId("action"),
      .player_id = player_id,
      .action_type = action_type,
      .cards = cards,
      .pattern_label = pattern_label,
      .timestamp_ms = core::NowMs(),
  });
  ArmPresentationGate(actions_.back());
  if (actions_.size() > 24U) {
    actions_.erase(actions_.begin(), actions_.begin() + static_cast<long>(actions_.size() - 24U));
  }
  LANDLORDS_LOG(landlords::core::LogLevel::kInfo,
                "room_action",
                "room=" << room_id_
                        << " phase=" << static_cast<int>(phase_)
                        << " turn=" << turn_serial_
                        << " player=" << player_id
                        << " action=" << ActionTypeName(action_type)
                        << " label=" << pattern_label
                        << " cards=" << CardsText(cards));
}

std::optional<std::string> Room::AcknowledgePresentation(const std::string& player_id,
                                                         const std::string& action_id) {
  if (mode_ != landlords::protocol::MATCH_MODE_VS_BOT ||
      pending_presentation_action_id_.empty()) {
    return std::nullopt;
  }
  if (player_id != presentation_wait_player_id_) {
    return "presentation_not_expected";
  }
  if (action_id != pending_presentation_action_id_) {
    return "presentation_ack_mismatch";
  }
  LANDLORDS_LOG(landlords::core::LogLevel::kDebug,
                "room",
                "room=" << room_id_ << " presentation ack action=" << action_id
                        << " by=" << player_id);
  ClearPresentationGate();
  return std::nullopt;
}

std::optional<core::CardPattern> Room::FindPlayablePattern(const core::PlayerState& player) const {
  const auto candidates = core::BuildCandidates(player.hand);
  if (candidates.empty()) {
    return std::nullopt;
  }

  const bool leading = !last_pattern_.has_value();
  const auto* last_player =
      last_action_player_id_.empty() ? nullptr : FindPlayer(last_action_player_id_);
  const auto* current_player = FindPlayer(player.player_id);
  if (current_player == nullptr) {
    return std::nullopt;
  }

  const auto* next_player = [&]() -> const core::PlayerState* {
    const int index = FindPlayerIndex(player.player_id);
    if (index < 0) {
      return nullptr;
    }
    return &players_[NextPlayerIndex(index)];
  }();

  const bool opponent_threat = std::any_of(players_.begin(), players_.end(), [&](const auto& other) {
    return other.player_id != player.player_id && !SameSide(other, player) && other.hand.size() <= 2U;
  });
  const bool next_player_is_opponent = next_player != nullptr && !SameSide(*next_player, *current_player);
  const bool next_player_critical =
      next_player_is_opponent && next_player->hand.size() <= 4U;
  const bool teammate_led =
      !leading && last_player != nullptr && last_player->player_id != player.player_id &&
      SameSide(*last_player, player);

  std::vector<core::CardPattern> valid;
  valid.reserve(candidates.size());
  for (const auto& candidate : candidates) {
    if (core::CanBeat(candidate, last_pattern_)) {
      valid.push_back(candidate);
    }
  }
  if (valid.empty()) {
    return std::nullopt;
  }

  if (teammate_led) {
    for (const auto& candidate : valid) {
      if (CanFinishWithMove(player, candidate)) {
        return candidate;
      }
    }

    const bool teammate_closing = last_player->hand.size() <= 2U;
    const bool weak_table = IsWeakPattern(last_pattern_);
    if ((teammate_closing && !next_player_critical) || (!weak_table && !opponent_threat && !next_player_critical)) {
      return std::nullopt;
    }
  }

  if (!opponent_threat && !next_player_critical) {
    std::vector<core::CardPattern> conservative;
    for (const auto& candidate : valid) {
      if (candidate.type != core::PatternType::kBomb &&
          candidate.type != core::PatternType::kRocket) {
        conservative.push_back(candidate);
      }
    }
    if (!conservative.empty()) {
      valid = std::move(conservative);
    }
  }

  std::sort(valid.begin(), valid.end(), [&](const auto& left, const auto& right) {
    const int left_score = ScoreMove(player,
                                     left,
                                     leading,
                                     opponent_threat,
                                     teammate_led,
                                     next_player_critical);
    const int right_score = ScoreMove(player,
                                      right,
                                      leading,
                                      opponent_threat,
                                      teammate_led,
                                      next_player_critical);
    if (left_score != right_score) {
      return left_score < right_score;
    }
    if (left.length != right.length) {
      return left.length > right.length;
    }
    return left.weight < right.weight;
  });
  return valid.front();
}

int Room::NextPlayerIndex(int current_index) const {
  return (current_index + 1) % static_cast<int>(players_.size());
}

int Room::FindPlayerIndex(const std::string& player_id) const {
  for (std::size_t index = 0; index < players_.size(); ++index) {
    if (players_[index].player_id == player_id) {
      return static_cast<int>(index);
    }
  }
  return -1;
}

void Room::AdvanceBidTurn() {
  const int current_index = FindPlayerIndex(current_turn_player_id_);
  if (current_index < 0) {
    return;
  }
  current_turn_player_id_ = players_[NextPlayerIndex(current_index)].player_id;
  ++turn_serial_;
  turn_started_ms_ = core::NowMs();
  decision_ready_at_ms_ = 0;
  ScheduleNextDecision(FindPlayer(current_turn_player_id_),
                       actions_.empty() ? nullptr : &actions_.back());
}

void Room::FinalizeBidding() {
  int landlord_index = highest_bid_player_id_.empty() ? bid_start_index_ : FindPlayerIndex(highest_bid_player_id_);
  if (landlord_index < 0) {
    landlord_index = bid_start_index_;
  }

  if (highest_bid_ == 0) {
    highest_bid_ = 1;
  }
  base_score_ = highest_bid_;

  players_[landlord_index].is_landlord = true;
  players_[landlord_index].hand.insert(players_[landlord_index].hand.end(),
                                       landlord_cards_.begin(),
                                       landlord_cards_.end());
  std::sort(players_[landlord_index].hand.begin(),
            players_[landlord_index].hand.end(),
            [](const core::Card& left, const core::Card& right) {
              return core::CompareCards(left, right) < 0;
            });

  current_turn_player_id_ = players_[landlord_index].player_id;
  phase_ = landlords::protocol::ROOM_PHASE_PLAYING;
  status_text_ = "landlord_decided";
  ++turn_serial_;
  turn_started_ms_ = core::NowMs();
  decision_ready_at_ms_ = 0;
  ScheduleNextDecision(FindPlayer(current_turn_player_id_),
                       actions_.empty() ? nullptr : &actions_.back());
  LANDLORDS_LOG(landlords::core::LogLevel::kInfo,
                "room",
                "room=" << room_id_
                        << " bidding finished landlord=" << current_turn_player_id_
                        << " base_score=" << base_score_);
  RefreshScores();
}

core::PlayerState* Room::FindPlayer(const std::string& player_id) {
  for (auto& player : players_) {
    if (player.player_id == player_id) {
      return &player;
    }
  }
  return nullptr;
}

const core::PlayerState* Room::FindPlayer(const std::string& player_id) const {
  for (const auto& player : players_) {
    if (player.player_id == player_id) {
      return &player;
    }
  }
  return nullptr;
}

std::optional<core::CardPattern> Room::CurrentPattern() const {
  return last_pattern_;
}

bool Room::IsLeadTurnFor(const std::string& player_id) const {
  return !last_pattern_.has_value() || last_action_player_id_ == player_id;
}

void Room::AdvanceTurn() {
  const int current_index = FindPlayerIndex(current_turn_player_id_);
  if (current_index < 0) {
    return;
  }
  current_turn_player_id_ = players_[NextPlayerIndex(current_index)].player_id;
  ++turn_serial_;
  turn_started_ms_ = core::NowMs();
  decision_ready_at_ms_ = 0;
  ScheduleNextDecision(FindPlayer(current_turn_player_id_),
                       actions_.empty() ? nullptr : &actions_.back());
}

void Room::ScheduleNextDecision(const core::PlayerState* current,
                                const core::RoomAction* last_action) {
  decision_ready_at_ms_ = 0;
  if (current == nullptr || (!current->is_bot && !current->is_managed)) {
    return;
  }
  const auto delay_ms = NextDecisionDelayMs(*current, phase_, last_action);
  decision_ready_at_ms_ = turn_started_ms_ + delay_ms;
  LANDLORDS_LOG(landlords::core::LogLevel::kDebug,
                "room",
                "room=" << room_id_
                        << " scheduled auto turn player=" << current->player_id
                        << " phase=" << static_cast<int>(phase_)
                        << " delay_ms=" << delay_ms
                        << " reason=" << (last_action == nullptr ? "turn_start"
                                                                  : last_action->pattern_label));
}

std::shared_ptr<ai::IBotStrategy> Room::ResolveBotStrategyForPlayer(
    const std::string& player_id) const {
  if (const auto found = bot_strategies_by_player_.find(player_id);
      found != bot_strategies_by_player_.end()) {
    return found->second;
  }
  return bot_strategy_;
}

void Room::ArmPresentationGate(const core::RoomAction& action) {
  ClearPresentationGate();
  if (mode_ != landlords::protocol::MATCH_MODE_VS_BOT) {
    return;
  }
  const auto audience_player_id = PresentationAudiencePlayerId();
  if (audience_player_id.empty()) {
    return;
  }
  pending_presentation_action_id_ = action.action_id;
  presentation_wait_player_id_ = audience_player_id;
  presentation_timeout_at_ms_ =
      action.timestamp_ms +
      std::max(LoadDelayMs("LANDLORDS_PRESENTATION_TIMEOUT_MS", 9000),
               AnnouncementDelayMs(action) + 2500);
  LANDLORDS_LOG(landlords::core::LogLevel::kDebug,
                "room",
                "room=" << room_id_ << " presentation gate action=" << action.action_id
                        << " wait_player=" << presentation_wait_player_id_
                        << " timeout_ms="
                        << (presentation_timeout_at_ms_ - action.timestamp_ms));
}

void Room::ClearPresentationGate() {
  pending_presentation_action_id_.clear();
  presentation_wait_player_id_.clear();
  presentation_timeout_at_ms_ = 0;
}

bool Room::PresentationGateOpen(std::int64_t now_ms) const {
  if (pending_presentation_action_id_.empty()) {
    return false;
  }
  return presentation_timeout_at_ms_ == 0 || now_ms < presentation_timeout_at_ms_;
}

std::string Room::PresentationAudiencePlayerId() const {
  for (const auto& player : players_) {
    if (!player.is_bot) {
      return player.player_id;
    }
  }
  return {};
}

bool Room::TickManaged(std::int64_t now_ms, std::int64_t timeout_ms) {
  if (!pending_presentation_action_id_.empty() &&
      presentation_timeout_at_ms_ != 0 &&
      now_ms >= presentation_timeout_at_ms_) {
    LANDLORDS_LOG(landlords::core::LogLevel::kWarn,
                  "room",
                  "room=" << room_id_ << " presentation ack timed out action="
                          << pending_presentation_action_id_);
    ClearPresentationGate();
  }

  if (!pending_winner_player_id_.empty()) {
    if (PresentationGateOpen(now_ms)) {
      return false;
    }
    if (finish_ready_at_ms_ != 0 && now_ms >= finish_ready_at_ms_) {
      CompletePendingFinish();
      return true;
    }
    return false;
  }

  if (finished() || current_turn_player_id_.empty()) {
    return false;
  }

  auto* player = FindPlayer(current_turn_player_id_);
  if (player == nullptr) {
    return false;
  }

  if ((player->is_bot || player->is_managed) &&
      decision_ready_at_ms_ != 0 &&
      now_ms >= decision_ready_at_ms_) {
    if (PresentationGateOpen(now_ms)) {
      return false;
    }
    decision_ready_at_ms_ = 0;
    LANDLORDS_LOG(landlords::core::LogLevel::kDebug,
                  "room",
                  "room=" << room_id_ << " auto turn ready player=" << player->player_id
                          << " phase=" << static_cast<int>(phase_));
    DriveBots();
    return true;
  }

  if (!player->is_bot && !player->is_managed && now_ms - turn_started_ms_ >= timeout_ms) {
    player->is_managed = true;
    AppendAction(player->player_id, landlords::protocol::ACTION_TYPE_PLAY, {}, "managed_on");
    status_text_ = "managed_enabled";
    turn_started_ms_ = now_ms;
    decision_ready_at_ms_ = now_ms + NextDecisionDelayMs(*player, phase_, &actions_.back());
    LANDLORDS_LOG(landlords::core::LogLevel::kWarn,
                  "room",
                  "room=" << room_id_ << " player=" << player->player_id
                          << " entered trustee after timeout_ms=" << timeout_ms);
    return true;
  }

  return false;
}

void Room::ScheduleRoundFinish(const core::PlayerState& winner,
                               const core::RoomAction* last_action) {
  pending_winner_player_id_ = winner.player_id;
  current_turn_player_id_.clear();
  decision_ready_at_ms_ = 0;
  turn_started_ms_ = core::NowMs();
  static_cast<void>(last_action);
  finish_ready_at_ms_ = turn_started_ms_ + LoadDelayMs("LANDLORDS_FINISH_DELAY_MS", 520);
  status_text_ = "round_finishing";
  LANDLORDS_LOG(landlords::core::LogLevel::kDebug,
                "room",
                "room=" << room_id_ << " finish scheduled winner=" << winner.player_id
                        << " delay_ms=" << (finish_ready_at_ms_ - turn_started_ms_));
}

void Room::CompletePendingFinish() {
  if (pending_winner_player_id_.empty()) {
    return;
  }
  auto* winner = FindPlayer(pending_winner_player_id_);
  pending_winner_player_id_.clear();
  finish_ready_at_ms_ = 0;
  if (winner != nullptr) {
    FinishIfNeeded(*winner);
  }
}

void Room::FinishIfNeeded(core::PlayerState& player) {
  if (!player.hand.empty()) {
    return;
  }

  phase_ = landlords::protocol::ROOM_PHASE_FINISHED;
  spring_triggered_ = (player.is_landlord && farmer_play_count_ == 0) ||
                      (!player.is_landlord && landlord_play_count_ <= 1);
  if (spring_triggered_) {
    multiplier_ *= 2;
  }
  status_text_ = "round_finished";
  decision_ready_at_ms_ = 0;

  for (auto& item : players_) {
    if (player.is_landlord) {
      item.round_score = item.is_landlord
                             ? 2 * base_score_ * multiplier_
                             : -base_score_ * multiplier_;
    } else {
      item.round_score = item.is_landlord
                             ? -2 * base_score_ * multiplier_
                             : base_score_ * multiplier_;
    }
  }
  LANDLORDS_LOG(landlords::core::LogLevel::kInfo,
                "room",
                "room=" << room_id_ << " finished winner=" << player.player_id
                        << " landlord=" << (player.is_landlord ? "true" : "false")
                        << " spring=" << (spring_triggered_ ? "true" : "false")
                        << " multiplier=" << multiplier_);
}

void Room::RefreshScores() {
  if (finished()) {
    return;
  }
  for (auto& player : players_) {
    player.round_score = 0;
  }
}

}  // namespace landlords::game
