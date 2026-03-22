#include "landlords/ai/bot_strategy.h"
#include "landlords/ai/bot_strategy.h"
#include "landlords/game/bid_strategy.h"
#include "landlords/game/room.h"

#include <exception>
#include <iostream>
#include <map>
#include <stdexcept>
#include <string>
#include <string_view>
#include <vector>

namespace {

using landlords::core::GenerateId;
using landlords::core::NowMs;
using landlords::core::PlayerState;
using landlords::core::Card;
using landlords::game::Room;
using landlords::protocol::MATCH_MODE_VS_BOT;
using landlords::protocol::ROOM_PHASE_FINISHED;
using landlords::protocol::ROOM_PHASE_PLAYING;
using landlords::protocol::ROOM_PHASE_WAITING;

class StubSuggestionStrategy final : public landlords::ai::IBotStrategy {
 public:
  std::optional<landlords::ai::BotDecision> ChooseMove(
      const landlords::protocol::RoomSnapshot& snapshot) override {
    landlords::ai::BotDecision decision;
    decision.kind = landlords::ai::BotDecision::Kind::kPlay;
    if (snapshot.self_cards_size() >= 1) {
      decision.card_ids.push_back(snapshot.self_cards(0).id());
    }
    return decision;
  }
};

class EmptySuggestionStrategy final : public landlords::ai::IBotStrategy {
 public:
  std::optional<landlords::ai::BotDecision> ChooseMove(
      const landlords::protocol::RoomSnapshot& /*snapshot*/) override {
    return std::nullopt;
  }
};

class InvalidSuggestionStrategy final : public landlords::ai::IBotStrategy {
 public:
  std::optional<landlords::ai::BotDecision> ChooseMove(
      const landlords::protocol::RoomSnapshot& /*snapshot*/) override {
    landlords::ai::BotDecision decision;
    decision.kind = landlords::ai::BotDecision::Kind::kPlay;
    decision.card_ids = {"not-a-real-card"};
    return decision;
  }
};

bool StartsWith(std::string_view text, std::string_view prefix) {
  return text.substr(0, prefix.size()) == prefix;
}

bool IsSystemAction(const auto& action) {
  const std::string_view label = action.pattern();
  return label == "managed_on" || label == "managed_off" ||
         label == "bid_pass" || StartsWith(label, "bid_");
}

std::vector<Card> ProtoCardsToCore(const auto& cards) {
  std::vector<Card> converted;
  converted.reserve(cards.size());
  for (const auto& card : cards) {
    converted.push_back(Card{
        .id = card.id(),
        .rank = card.rank(),
        .suit = card.suit(),
        .value = card.value(),
    });
  }
  return converted;
}

std::optional<landlords::core::CardPattern> CurrentTablePattern(
    const landlords::protocol::RoomSnapshot& snapshot) {
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
    if (action.action_type() != landlords::protocol::ACTION_TYPE_PLAY ||
        action.cards_size() == 0) {
      continue;
    }
    if (trailing_passes >= 2) {
      return std::nullopt;
    }
    const auto pattern = landlords::core::EvaluatePattern(ProtoCardsToCore(action.cards()));
    return pattern.type == landlords::core::PatternType::kInvalid
               ? std::nullopt
               : std::optional<landlords::core::CardPattern>(pattern);
  }
  return std::nullopt;
}

std::optional<std::vector<std::string>> ChooseLegalCardIds(
    const landlords::protocol::RoomSnapshot& snapshot) {
  const auto self_cards = ProtoCardsToCore(snapshot.self_cards());
  const auto table = CurrentTablePattern(snapshot);
  for (const auto& candidate : landlords::core::BuildCandidates(self_cards)) {
    if (landlords::core::CanBeat(candidate, table)) {
      std::vector<std::string> ids;
      ids.reserve(candidate.cards.size());
      for (const auto& card : candidate.cards) {
        ids.push_back(card.id);
      }
      return ids;
    }
  }
  if (table.has_value()) {
    return std::vector<std::string>{};
  }
  return std::nullopt;
}

std::optional<landlords::ai::BotDecision> BuildDecisionFromIds(
    const std::optional<std::vector<std::string>>& ids) {
  if (!ids.has_value()) {
    return std::nullopt;
  }
  landlords::ai::BotDecision decision;
  decision.kind = ids->empty() ? landlords::ai::BotDecision::Kind::kPass
                               : landlords::ai::BotDecision::Kind::kPlay;
  decision.card_ids = *ids;
  return decision;
}

class GreedyLegalStrategy final : public landlords::ai::IBotStrategy {
 public:
  std::optional<landlords::ai::BotDecision> ChooseMove(
      const landlords::protocol::RoomSnapshot& snapshot) override {
    return BuildDecisionFromIds(ChooseLegalCardIds(snapshot));
  }
};

class InstrumentedLegalStrategy final : public landlords::ai::IBotStrategy {
 public:
  explicit InstrumentedLegalStrategy(int* choose_calls)
      : choose_calls_(choose_calls) {}

  std::optional<landlords::ai::BotDecision> ChooseMove(
      const landlords::protocol::RoomSnapshot& snapshot) override {
    if (choose_calls_ != nullptr) {
      ++(*choose_calls_);
    }
    return BuildDecisionFromIds(ChooseLegalCardIds(snapshot));
  }

 private:
  int* choose_calls_ = nullptr;
};

PlayerState MakePlayer(const std::string& name, bool bot) {
  return PlayerState{
      .player_id = GenerateId(bot ? "bot" : "user"),
      .display_name = name,
      .is_bot = bot,
  };
}

void Require(bool condition, const std::string& message) {
  if (!condition) {
    throw std::runtime_error(message);
  }
}

void VerifyFinishedRoom(const Room& room, const std::string& observer_id) {
  const auto snapshot = room.BuildSnapshotFor(observer_id);
  Require(snapshot.phase() == ROOM_PHASE_FINISHED, "room did not finish");
  Require(snapshot.players_size() == 3, "room does not contain three players");

  int score_sum = 0;
  int empty_hands = 0;
  int landlord_count = 0;
  const PlayerState* winner = nullptr;
  const PlayerState* landlord = nullptr;
  int farmer_positive_score = -1;

  for (const auto& player : room.players()) {
    score_sum += player.round_score;
    if (player.hand.empty()) {
      ++empty_hands;
      winner = &player;
    }
    if (player.is_landlord) {
      ++landlord_count;
      landlord = &player;
    } else {
      if (player.round_score > 0) {
        if (farmer_positive_score == -1) {
          farmer_positive_score = player.round_score;
        } else {
          Require(player.round_score == farmer_positive_score,
                  "farmer scores must match when farmers win");
        }
      }
    }
  }

  Require(score_sum == 0, "round scores do not sum to zero");
  Require(empty_hands == 1, "expected exactly one winner");
  Require(landlord_count == 1, "expected exactly one landlord");
  Require(winner != nullptr, "winner not found");
  Require(landlord != nullptr, "landlord not found");

  if (winner->is_landlord) {
    for (const auto& player : room.players()) {
      if (!player.is_landlord) {
        Require(player.round_score < 0, "farmers must lose when landlord wins");
      }
    }
  } else {
    Require(landlord->round_score < 0, "landlord must lose when farmers win");
    Require(farmer_positive_score > 0, "farmers should receive a positive score when they win");
    Require(landlord->round_score == -2 * farmer_positive_score,
            "landlord score must be double the farmer score when farmers win");
  }
}

void RunAutomatedRoomSimulation(int rounds) {
  auto strategy = std::make_shared<GreedyLegalStrategy>();
  for (int index = 0; index < rounds; ++index) {
    std::vector<PlayerState> players;
    players.push_back(MakePlayer("Bot Alpha", true));
    players.push_back(MakePlayer("Bot Bravo", true));
    players.push_back(MakePlayer("Bot Charlie", true));

    Room room(GenerateId("room"),
              MATCH_MODE_VS_BOT,
              players,
              landlords::protocol::BOT_DIFFICULTY_NORMAL,
              strategy);
    std::int64_t now_ms = NowMs();
    int guard = 0;
    while (!room.finished() && guard < 600) {
      now_ms += 5000;
      room.TickManaged(now_ms, 25000);
      ++guard;
    }

    Require(guard < 600, "automated room hit turn guard");
    VerifyFinishedRoom(room, room.players().front().player_id);
  }
}

Card TakeByRank(std::map<std::string, std::vector<Card>>& deck_by_rank,
                const std::string& rank) {
  auto& bucket = deck_by_rank[rank];
  Require(!bucket.empty(), "missing rank in test deck: " + rank);
  const auto card = bucket.back();
  bucket.pop_back();
  return card;
}

std::vector<Card> MakeHand(std::initializer_list<const char*> ranks) {
  std::map<std::string, std::vector<Card>> deck_by_rank;
  for (const auto& card : landlords::core::BuildDeck()) {
    deck_by_rank[card.rank].push_back(card);
  }

  std::vector<Card> hand;
  hand.reserve(ranks.size());
  for (const char* rank : ranks) {
    hand.push_back(TakeByRank(deck_by_rank, rank));
  }
  return hand;
}

void RunBidStrategyTests() {
  const auto strong = MakeHand({
      "BJ", "SJ", "2", "2", "A", "A", "K", "K", "Q", "Q",
      "J", "J", "10", "10", "9", "9", "8",
  });
  const auto medium = MakeHand({
      "2", "A", "A", "K", "K", "Q", "Q", "J", "J", "10",
      "10", "9", "8", "7", "6", "5", "4",
  });
  const auto weak = MakeHand({
      "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q",
      "K", "A", "3", "5", "7", "9", "J",
  });

  Require(landlords::game::SuggestBidLevel(strong) == 3, "strong hand should bid 3");
  Require(landlords::game::SuggestBidLevel(medium) >= 1, "medium hand should bid at least 1");
  Require(landlords::game::ChooseBidAction(medium, 1) >= 2,
          "medium hand should compete above an existing 1-point bid");
  Require(landlords::game::SuggestBidLevel(weak) == 0, "weak hand should pass bidding");
}

void RunManualTurnSimulation(int rounds) {
  for (int index = 0; index < rounds; ++index) {
    std::vector<PlayerState> players;
    players.push_back(MakePlayer("Bot One", true));
    players.push_back(MakePlayer("Bot Two", true));
    players.push_back(MakePlayer("Bot Three", true));

    Room room(GenerateId("room"), MATCH_MODE_VS_BOT, players);
    const std::string observer_id = room.players().front().player_id;

    int highest_bid = 0;
    int guard = 0;
    std::int64_t now_ms = NowMs();
    while (!room.finished() && guard < 600) {
      const auto snapshot = room.BuildSnapshotFor(observer_id);
      if (snapshot.current_turn_player_id().empty()) {
        now_ms += 5000;
        room.TickManaged(now_ms, 25000);
        ++guard;
        continue;
      }
      const std::string turn_id = snapshot.current_turn_player_id();
      const auto turn_snapshot = room.BuildSnapshotFor(turn_id);
      const auto* player = [&]() -> const PlayerState* {
        for (const auto& item : room.players()) {
          if (item.player_id == turn_id) {
            return &item;
          }
        }
        return nullptr;
      }();
      Require(player != nullptr, "turn player not found");

      if (snapshot.phase() == ROOM_PHASE_WAITING) {
        const int bid = landlords::game::ChooseBidAction(player->hand, highest_bid);
        if (bid > 0) {
          highest_bid = bid;
        }
        const auto error = room.CallScore(turn_id, bid);
        Require(!error.has_value(), "manual simulation bid failed: " + error.value_or(""));
      } else if (snapshot.phase() == ROOM_PHASE_PLAYING) {
        const auto suggestion = ChooseLegalCardIds(turn_snapshot);
        Require(suggestion.has_value(), "manual simulation could not find a legal move");
        if (suggestion->empty()) {
          const auto error = room.Pass(turn_id);
          Require(!error.has_value(), "manual simulation pass failed: " + error.value_or(""));
        } else {
          const auto error = room.PlayCards(turn_id, *suggestion);
          Require(!error.has_value(), "manual simulation play failed: " + error.value_or(""));
        }
      }
      ++guard;
    }

    Require(guard < 600, "manual simulation hit turn guard");
    VerifyFinishedRoom(room, observer_id);
  }
}

void RunTrusteeTimeoutSimulation() {
  std::vector<PlayerState> players;
  players.push_back(MakePlayer("Human", false));
  players.push_back(MakePlayer("Bot Left", true));
  players.push_back(MakePlayer("Bot Right", true));

  auto strategy = std::make_shared<GreedyLegalStrategy>();
  Room room(GenerateId("room"),
            MATCH_MODE_VS_BOT,
            players,
            landlords::protocol::BOT_DIFFICULTY_NORMAL,
            strategy);
  std::int64_t now_ms = NowMs();
  int guard = 0;
  while (guard < 40) {
    const auto snapshot = room.BuildSnapshotFor(players.front().player_id);
    if (snapshot.phase() == ROOM_PHASE_WAITING || snapshot.phase() == ROOM_PHASE_PLAYING) {
      if (snapshot.current_turn_player_id().empty()) {
        now_ms += 5000;
        room.TickManaged(now_ms, 25000);
        ++guard;
        continue;
      }
      const auto* current = [&]() -> const PlayerState* {
        for (const auto& item : room.players()) {
          if (item.player_id == snapshot.current_turn_player_id()) {
            return &item;
          }
        }
        return nullptr;
      }();
      Require(current != nullptr, "timeout simulation missing current player");
      if (!current->is_bot) {
        now_ms += 26000;
        const bool changed = room.TickManaged(now_ms, 25000);
        Require(changed, "timeout simulation did not trigger trustee");
        const auto* human = [&]() -> const PlayerState* {
          for (const auto& item : room.players()) {
            if (!item.is_bot) {
              return &item;
            }
          }
          return nullptr;
        }();
        Require(human != nullptr && human->is_managed, "human was not switched to trustee");
        return;
      }
    }
    now_ms += 5000;
    room.TickManaged(now_ms, 25000);
    ++guard;
  }

  throw std::runtime_error("timeout simulation never reached a human turn");
}

void RunManagedSingleStepSimulation() {
  std::vector<PlayerState> players;
  players.push_back(MakePlayer("Human", false));
  players.push_back(MakePlayer("Bot Left", true));
  players.push_back(MakePlayer("Bot Right", true));

  auto strategy = std::make_shared<GreedyLegalStrategy>();
  Room room(GenerateId("room"),
            MATCH_MODE_VS_BOT,
            players,
            landlords::protocol::BOT_DIFFICULTY_NORMAL,
            strategy);
  const std::string human_id = players.front().player_id;
  std::int64_t now_ms = NowMs();
  int guard = 0;
  while (guard < 40) {
    const auto snapshot = room.BuildSnapshotFor(human_id);
    if (snapshot.phase() == ROOM_PHASE_PLAYING &&
        snapshot.current_turn_player_id() == human_id) {
      const int previous_turn = snapshot.turn_serial();
      const int previous_actions = snapshot.recent_actions_size();
      const auto error = room.SetManaged(human_id, true);
      Require(!error.has_value(), "managed single-step simulation failed to enable trustee");

      const auto after = room.BuildSnapshotFor(human_id);
      Require(after.phase() != ROOM_PHASE_FINISHED,
              "managed single-step should not finish the room immediately");
      Require(after.turn_serial() <= previous_turn + 1,
              "managed single-step advanced too many turns at once");
      Require(after.recent_actions_size() <= previous_actions + 2,
              "managed single-step appended too many actions");
      return;
    }
    now_ms += 5000;
    room.TickManaged(now_ms, 25000);
    ++guard;
  }

  throw std::runtime_error("managed single-step simulation never reached a human playing turn");
}

void RunHumanStartsBiddingTest() {
  std::vector<PlayerState> players;
  players.push_back(MakePlayer("Bot Left", true));
  players.push_back(MakePlayer("Human", false));
  players.push_back(MakePlayer("Bot Right", true));

  Room room(GenerateId("room"), MATCH_MODE_VS_BOT, players);
  const std::string human_id = players[1].player_id;

  const auto opening = room.BuildSnapshotFor(human_id);
  Require(opening.phase() == ROOM_PHASE_WAITING, "bot match should start in bidding phase");
  Require(opening.current_turn_player_id() == human_id,
          "human player should receive the first bidding turn in bot matches");

  room.DriveBots();

  const auto after_drive = room.BuildSnapshotFor(human_id);
  Require(after_drive.current_turn_player_id() == human_id,
          "bots should not consume the human bidding turn on room start");
  Require(after_drive.recent_actions_size() == 0,
          "bot room should not append actions before the human chooses a bid");
}

void RunSuggestionUsesBotStrategyTest() {
  std::vector<PlayerState> players;
  players.push_back(MakePlayer("Human", false));
  players.push_back(MakePlayer("Bot Left", true));
  players.push_back(MakePlayer("Bot Right", true));

  auto strategy = std::make_shared<GreedyLegalStrategy>();
  Room room(GenerateId("room"),
            MATCH_MODE_VS_BOT,
            players,
            landlords::protocol::BOT_DIFFICULTY_HARD,
            strategy);
  const std::string human_id = players.front().player_id;

  const auto opening = room.BuildSnapshotFor(human_id);
  Require(opening.phase() == ROOM_PHASE_WAITING, "suggestion test should start in bidding phase");
  Require(opening.current_turn_player_id() == human_id,
          "suggestion test expects human to bid first");

  const auto bid_error = room.CallScore(human_id, 3);
  Require(!bid_error.has_value(), "suggestion test failed to bid 3");

  const auto playing = room.BuildSnapshotFor(human_id);
  Require(playing.phase() == ROOM_PHASE_PLAYING, "suggestion test should enter playing phase");
  Require(playing.current_turn_player_id() == human_id,
          "suggestion test expects human to lead after winning the bid");

  const auto suggested = room.SuggestCardIds(human_id);
  Require(suggested.has_value(), "suggestion test did not return a suggestion");
  Require(suggested->size() == 1, "suggestion test should return the stubbed single card");
  Require((*suggested)[0] == playing.self_cards(0).id(),
          "suggestion test card does not come from the bot strategy");
}

void RunSuggestionRequiresModelTest() {
  std::vector<PlayerState> players;
  players.push_back(MakePlayer("Human", false));
  players.push_back(MakePlayer("Bot Left", true));
  players.push_back(MakePlayer("Bot Right", true));

  Room room(GenerateId("room"),
            MATCH_MODE_VS_BOT,
            players,
            landlords::protocol::BOT_DIFFICULTY_HARD,
            nullptr);
  const std::string human_id = players.front().player_id;

  const auto bid_error = room.CallScore(human_id, 3);
  Require(!bid_error.has_value(), "model required test failed to bid 3");
  const auto suggested = room.SuggestCardIds(human_id);
  Require(!suggested.has_value(), "suggestion should fail when no model strategy is available");
}

void RunSuggestionRejectsInvalidModelMoveTest() {
  std::vector<PlayerState> players;
  players.push_back(MakePlayer("Human", false));
  players.push_back(MakePlayer("Bot Left", true));
  players.push_back(MakePlayer("Bot Right", true));

  auto strategy = std::make_shared<InvalidSuggestionStrategy>();
  Room room(GenerateId("room"),
            MATCH_MODE_VS_BOT,
            players,
            landlords::protocol::BOT_DIFFICULTY_HARD,
            strategy);
  const std::string human_id = players.front().player_id;

  const auto bid_error = room.CallScore(human_id, 3);
  Require(!bid_error.has_value(), "invalid model move test failed to bid 3");
  const auto suggested = room.SuggestCardIds(human_id);
  Require(!suggested.has_value(), "invalid model move should not be converted into a heuristic hint");
}

void RunSuggestionRejectsEmptyModelResponseTest() {
  std::vector<PlayerState> players;
  players.push_back(MakePlayer("Human", false));
  players.push_back(MakePlayer("Bot Left", true));
  players.push_back(MakePlayer("Bot Right", true));

  auto strategy = std::make_shared<EmptySuggestionStrategy>();
  Room room(GenerateId("room"),
            MATCH_MODE_VS_BOT,
            players,
            landlords::protocol::BOT_DIFFICULTY_HARD,
            strategy);
  const std::string human_id = players.front().player_id;

  const auto bid_error = room.CallScore(human_id, 3);
  Require(!bid_error.has_value(), "empty model response test failed to bid 3");
  const auto suggested = room.SuggestCardIds(human_id);
  Require(!suggested.has_value(), "empty model response should not fall back to heuristic");
}

void RunManagedAutoplayUsesBotStrategyTest() {
  std::vector<PlayerState> players;
  players.push_back(MakePlayer("Human", false));
  players.push_back(MakePlayer("Bot Left", true));
  players.push_back(MakePlayer("Bot Right", true));

  int choose_calls = 0;
  auto strategy = std::make_shared<InstrumentedLegalStrategy>(&choose_calls);
  Room room(GenerateId("room"),
            MATCH_MODE_VS_BOT,
            players,
            landlords::protocol::BOT_DIFFICULTY_HARD,
            strategy);
  const std::string human_id = players.front().player_id;

  const auto bid_error = room.CallScore(human_id, 3);
  Require(!bid_error.has_value(), "managed autoplay test failed to bid 3");

  const auto managed_error = room.SetManaged(human_id, true);
  Require(!managed_error.has_value(), "managed autoplay test failed to enable trustee");

  const auto managed_snapshot = room.BuildSnapshotFor(human_id);
  const auto managed_action_id =
      managed_snapshot.recent_actions(managed_snapshot.recent_actions_size() - 1).action_id();
  const auto ack_error = room.AcknowledgePresentation(human_id, managed_action_id);
  Require(!ack_error.has_value(), "managed autoplay test failed to acknowledge trustee notice");

  const bool advanced = room.TickManaged(NowMs() + 7000, 25000);
  Require(advanced, "managed autoplay test did not advance after trustee tick");
  Require(choose_calls > 0, "managed autoplay did not call the bot strategy");

  const auto snapshot = room.BuildSnapshotFor(human_id);
  Require(snapshot.recent_actions_size() >= 2,
          "managed autoplay should append trustee action and model move");
  const auto& last_action =
      snapshot.recent_actions(snapshot.recent_actions_size() - 1);
  Require(last_action.player_id() == human_id,
          "managed autoplay should act for the managed human");
  Require(last_action.pattern() != "managed_on",
          "managed autoplay should produce a model move after entering trustee");
}

void RunManagedRejectsInvalidModelMoveTest() {
  std::vector<PlayerState> players;
  players.push_back(MakePlayer("Human", false));
  players.push_back(MakePlayer("Bot Left", true));
  players.push_back(MakePlayer("Bot Right", true));

  auto strategy = std::make_shared<InvalidSuggestionStrategy>();
  Room room(GenerateId("room"),
            MATCH_MODE_VS_BOT,
            players,
            landlords::protocol::BOT_DIFFICULTY_HARD,
            strategy);
  const std::string human_id = players.front().player_id;

  const auto bid_error = room.CallScore(human_id, 3);
  Require(!bid_error.has_value(), "managed invalid model test failed to bid 3");
  const auto managed_error = room.SetManaged(human_id, true);
  Require(!managed_error.has_value(), "managed invalid model test failed to enable trustee");

  const auto managed_snapshot = room.BuildSnapshotFor(human_id);
  const auto managed_action_id =
      managed_snapshot.recent_actions(managed_snapshot.recent_actions_size() - 1).action_id();
  const auto ack_error = room.AcknowledgePresentation(human_id, managed_action_id);
  Require(!ack_error.has_value(), "managed invalid model test failed to acknowledge trustee notice");

  const auto before = room.BuildSnapshotFor(human_id);
  room.TickManaged(NowMs() + 7000, 25000);
  const auto after = room.BuildSnapshotFor(human_id);

  Require(after.recent_actions_size() == before.recent_actions_size(),
          "invalid model move should not fall back to a heuristic trustee action");
  Require(after.current_turn_player_id() == human_id,
          "invalid model move should keep the turn on the acting player");
  Require(after.status_text() == "bot_strategy_invalid",
          "invalid model move should surface the model failure status");
}

void RunPresentationAckGateTest() {
  std::vector<PlayerState> players;
  players.push_back(MakePlayer("Human", false));
  players.push_back(MakePlayer("Bot Left", true));
  players.push_back(MakePlayer("Bot Right", true));

  auto strategy = std::make_shared<GreedyLegalStrategy>();
  Room room(GenerateId("room"),
            MATCH_MODE_VS_BOT,
            players,
            landlords::protocol::BOT_DIFFICULTY_HARD,
            strategy);
  const std::string human_id = players.front().player_id;

  const auto bid_error = room.CallScore(human_id, 3);
  Require(!bid_error.has_value(), "presentation ack test failed to bid 3");

  auto snapshot = room.BuildSnapshotFor(human_id);
  Require(snapshot.phase() == ROOM_PHASE_PLAYING, "presentation ack test should enter playing phase");
  Require(snapshot.current_turn_player_id() == human_id,
          "presentation ack test expects human to lead");
  Require(snapshot.self_cards_size() >= 1, "presentation ack test needs at least one card");

  const auto play_error = room.PlayCards(human_id, {snapshot.self_cards(0).id()});
  Require(!play_error.has_value(), "presentation ack test failed to play human card");

  snapshot = room.BuildSnapshotFor(human_id);
  Require(snapshot.recent_actions_size() >= 1, "presentation ack test missing recent action");
  const auto action_id =
      snapshot.recent_actions(snapshot.recent_actions_size() - 1).action_id();

  const auto gate_check_ms = NowMs() + 3500;
  room.TickManaged(gate_check_ms, 25000);
  auto gated_snapshot = room.BuildSnapshotFor(human_id);
  Require(gated_snapshot.recent_actions(gated_snapshot.recent_actions_size() - 1).player_id() ==
              human_id,
          "bot should wait for presentation ack before acting");

  const auto ack_error = room.AcknowledgePresentation(human_id, action_id);
  Require(!ack_error.has_value(), "presentation ack test failed to acknowledge action");

  room.TickManaged(NowMs() + 7000, 25000);
  const auto after_ack = room.BuildSnapshotFor(human_id);
  Require(after_ack.recent_actions(after_ack.recent_actions_size() - 1).player_id() != human_id,
          "bot should act after presentation ack");
}

}  // namespace

int main() {
  try {
    RunAutomatedRoomSimulation(120);
    RunBidStrategyTests();
    RunManualTurnSimulation(120);
    RunTrusteeTimeoutSimulation();
    RunManagedSingleStepSimulation();
    RunHumanStartsBiddingTest();
    RunSuggestionUsesBotStrategyTest();
    RunSuggestionRequiresModelTest();
    RunSuggestionRejectsInvalidModelMoveTest();
    RunSuggestionRejectsEmptyModelResponseTest();
    RunManagedAutoplayUsesBotStrategyTest();
    RunManagedRejectsInvalidModelMoveTest();
    RunPresentationAckGateTest();
    std::cout << "room simulation tests passed" << std::endl;
    return 0;
  } catch (const std::exception& exception) {
    std::cerr << "room simulation tests failed: " << exception.what() << std::endl;
    return 1;
  }
}
