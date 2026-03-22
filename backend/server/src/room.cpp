#include "landlords/ai/bot_strategy.h"
#include "landlords/core/logging.h"
#include "landlords/game/bid_strategy.h"
#include "landlords/game/room.h"

#include <algorithm>
#include <cstdlib>
#include <random>
#include <sstream>
#include <string_view>
#include <unordered_set>
#include <utility>

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

const char* ModelFailureStatus(std::string_view reason) {
  if (reason == "model_unavailable") {
    return "bot_strategy_unavailable";
  }
  if (reason == "model_empty") {
    return "bot_strategy_empty";
  }
  return "bot_strategy_invalid";
}

std::int64_t ModelRetryDelayMs() {
  return LoadDelayMs("LANDLORDS_BOT_MODEL_RETRY_DELAY_MS", 1500);
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

void FillRoomPlayer(const core::PlayerState& player,
                    int seat_index,
                    landlords::protocol::RoomPlayer* target) {
  target->set_player_id(player.player_id);
  target->set_display_name(player.display_name);
  target->set_is_bot(player.is_bot);
  target->set_role(player.is_landlord ? landlords::protocol::PLAYER_ROLE_LANDLORD
                                      : landlords::protocol::PLAYER_ROLE_FARMER);
  target->set_cards_left(static_cast<int>(player.hand.size()));
  target->set_round_score(player.round_score);
  target->set_seat_index(seat_index);
  target->set_ready(true);
  target->set_occupied(true);
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

  for (int index = 0; index < static_cast<int>(players_.size()); ++index) {
    FillRoomPlayer(players_[static_cast<std::size_t>(index)], index, snapshot.add_players());
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

  std::string failure_reason;
  const auto decision = ResolveModelMove(*player, &failure_reason);
  if (!decision.has_value()) {
    LANDLORDS_LOG(landlords::core::LogLevel::kWarn,
                  "room",
                  "room=" << room_id_ << " suggest player=" << player_id
                          << " difficulty=" << BotDifficultyName(bot_difficulty_)
                          << " source=model_failure reason=" << failure_reason);
    return std::nullopt;
  }

  LANDLORDS_LOG(landlords::core::LogLevel::kInfo,
                "room",
                "room=" << room_id_ << " suggest player=" << player_id
                        << " difficulty=" << BotDifficultyName(bot_difficulty_)
                        << " source=model cards=" << decision->size());
  return decision;
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
    std::string failure_reason;
    const auto decision = ResolveModelMove(*player, &failure_reason);
    if (!decision.has_value()) {
      LANDLORDS_LOG(landlords::core::LogLevel::kError,
                    "room",
                    "room=" << room_id_ << " auto play player=" << player->player_id
                            << " difficulty=" << BotDifficultyName(bot_difficulty_)
                            << " source=model_failure reason=" << failure_reason);
      status_text_ = ModelFailureStatus(failure_reason);
      turn_started_ms_ = now_ms;
      decision_ready_at_ms_ = now_ms + ModelRetryDelayMs();
    } else {
      error = decision->empty() ? Pass(player->player_id)
                                : PlayCards(player->player_id, *decision);
      if (error.has_value()) {
        LANDLORDS_LOG(landlords::core::LogLevel::kError,
                      "room",
                      "room=" << room_id_ << " auto play player=" << player->player_id
                              << " difficulty=" << BotDifficultyName(bot_difficulty_)
                              << " source=model_apply_failure error=" << *error);
        status_text_ = "bot_strategy_apply_failed";
        turn_started_ms_ = now_ms;
        decision_ready_at_ms_ = now_ms + ModelRetryDelayMs();
        error.reset();
      }
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

std::optional<std::vector<std::string>> Room::ResolveModelMove(
    const core::PlayerState& player,
    std::string* failure_reason) const {
  auto set_failure = [&](std::string reason) -> std::optional<std::vector<std::string>> {
    if (failure_reason != nullptr) {
      *failure_reason = std::move(reason);
    }
    return std::nullopt;
  };

  const auto strategy = ResolveBotStrategyForPlayer(player.player_id);
  if (strategy == nullptr) {
    return set_failure("model_unavailable");
  }

  const auto decision = strategy->ChooseMove(BuildSnapshotFor(player.player_id));
  if (!decision.has_value()) {
    return set_failure("model_empty");
  }

  if (decision->kind == ai::BotDecision::Kind::kPass) {
    if (IsLeadTurnFor(player.player_id)) {
      return set_failure("lead_player_cannot_pass");
    }
    return std::vector<std::string>{};
  }

  std::unordered_set<std::string> wanted(decision->card_ids.begin(), decision->card_ids.end());
  std::vector<core::Card> chosen;
  chosen.reserve(decision->card_ids.size());
  for (const auto& card : player.hand) {
    if (wanted.contains(card.id)) {
      chosen.push_back(card);
    }
  }
  if (chosen.size() != decision->card_ids.size()) {
    return set_failure("invalid_cards");
  }

  const auto pattern = core::EvaluatePattern(chosen);
  if (pattern.type == core::PatternType::kInvalid) {
    return set_failure("invalid_pattern");
  }
  if (!core::CanBeat(pattern, last_pattern_)) {
    return set_failure("cannot_beat_table");
  }

  return decision->card_ids;
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
      std::max(LoadDelayMs("LANDLORDS_PRESENTATION_TIMEOUT_MS", 15000),
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
