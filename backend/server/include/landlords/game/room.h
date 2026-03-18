#pragma once

#include <optional>
#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

#include "landlords/core/models.h"

namespace landlords::ai {
class IBotStrategy;
}

namespace landlords::game {

class Room {
 public:
  Room(std::string room_id,
       landlords::protocol::MatchMode mode,
       std::vector<core::PlayerState> players,
       landlords::protocol::BotDifficulty bot_difficulty = landlords::protocol::BOT_DIFFICULTY_NORMAL,
       std::shared_ptr<ai::IBotStrategy> bot_strategy = nullptr,
       std::unordered_map<std::string, std::shared_ptr<ai::IBotStrategy>> bot_strategies_by_player = {});

  const std::string& id() const { return room_id_; }
  landlords::protocol::MatchMode mode() const { return mode_; }

  bool HasPlayer(const std::string& player_id) const;
  landlords::protocol::RoomSnapshot BuildSnapshotFor(const std::string& player_id) const;
  std::optional<core::CardPattern> FindSuggestion(const std::string& player_id) const;
  std::optional<std::vector<std::string>> SuggestCardIds(const std::string& player_id) const;

  std::optional<std::string> CallScore(const std::string& player_id, int score);
  std::optional<std::string> AcknowledgePresentation(const std::string& player_id,
                                                     const std::string& action_id);
  std::optional<std::string> SetManaged(const std::string& player_id, bool managed);
  std::optional<std::string> PlayCards(const std::string& player_id, const std::vector<std::string>& card_ids);
  std::optional<std::string> Pass(const std::string& player_id);
  void DriveBots();
  bool TickManaged(std::int64_t now_ms, std::int64_t timeout_ms);

  bool finished() const { return phase_ == landlords::protocol::ROOM_PHASE_FINISHED; }
  const std::vector<core::PlayerState>& players() const { return players_; }

 private:
  void StartGame();
  void AppendAction(const std::string& player_id,
                    landlords::protocol::ActionType action_type,
                    const std::vector<core::Card>& cards,
                    const std::string& pattern_label);
  std::optional<core::CardPattern> FindPlayablePattern(const core::PlayerState& player) const;
  int NextPlayerIndex(int current_index) const;
  int FindPlayerIndex(const std::string& player_id) const;
  void AdvanceBidTurn();
  void FinalizeBidding();
  core::PlayerState* FindPlayer(const std::string& player_id);
  const core::PlayerState* FindPlayer(const std::string& player_id) const;
  std::optional<core::CardPattern> CurrentPattern() const;
  bool IsLeadTurnFor(const std::string& player_id) const;
  void AdvanceTurn();
  void ScheduleNextDecision(const core::PlayerState* current, const core::RoomAction* last_action = nullptr);
  std::shared_ptr<ai::IBotStrategy> ResolveBotStrategyForPlayer(const std::string& player_id) const;
  void ArmPresentationGate(const core::RoomAction& action);
  void ClearPresentationGate();
  bool PresentationGateOpen(std::int64_t now_ms) const;
  std::string PresentationAudiencePlayerId() const;
  void ScheduleRoundFinish(const core::PlayerState& winner, const core::RoomAction* last_action);
  void CompletePendingFinish();
  void FinishIfNeeded(core::PlayerState& player);
  void RefreshScores();

  std::string room_id_;
  landlords::protocol::MatchMode mode_;
  landlords::protocol::RoomPhase phase_ = landlords::protocol::ROOM_PHASE_WAITING;
  std::vector<core::PlayerState> players_;
  std::vector<core::Card> landlord_cards_;
  std::vector<core::RoomAction> actions_;
  std::optional<core::CardPattern> last_pattern_;
  std::string last_action_player_id_;
  std::string current_turn_player_id_;
  int base_score_ = 1;
  int multiplier_ = 1;
  int pass_count_ = 0;
  int turn_serial_ = 0;
  bool spring_triggered_ = false;
  std::string status_text_;
  int landlord_play_count_ = 0;
  int farmer_play_count_ = 0;
  int bid_turns_taken_ = 0;
  int bid_start_index_ = 0;
  int highest_bid_ = 0;
  std::string highest_bid_player_id_;
  landlords::protocol::BotDifficulty bot_difficulty_ =
      landlords::protocol::BOT_DIFFICULTY_NORMAL;
  std::int64_t turn_started_ms_ = 0;
  std::int64_t decision_ready_at_ms_ = 0;
  std::int64_t finish_ready_at_ms_ = 0;
  std::int64_t presentation_timeout_at_ms_ = 0;
  bool auto_playing_ = false;
  std::string pending_winner_player_id_;
  std::string pending_presentation_action_id_;
  std::string presentation_wait_player_id_;
  std::shared_ptr<ai::IBotStrategy> bot_strategy_;
  std::unordered_map<std::string, std::shared_ptr<ai::IBotStrategy>> bot_strategies_by_player_;
};

}  // namespace landlords::game
