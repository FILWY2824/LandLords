#include "landlords/ai/onnx_bot_strategy.h"
#include "landlords/game/room.h"

#include <cstdlib>
#include <iostream>
#include <map>
#include <stdexcept>
#include <string>
#include <unordered_set>
#include <vector>

#include "landlords/core/models.h"
#include "landlords.pb.h"

namespace {

landlords::protocol::Card MakeCard(const std::string& id,
                                   const std::string& rank,
                                   const std::string& suit,
                                   int value) {
  landlords::protocol::Card card;
  card.set_id(id);
  card.set_rank(rank);
  card.set_suit(suit);
  card.set_value(value);
  return card;
}

void Require(bool condition, const std::string& message) {
  if (!condition) {
    throw std::runtime_error(message);
  }
}

landlords::core::PlayerState MakePlayer(const std::string& name, bool bot) {
  return landlords::core::PlayerState{
      .player_id = landlords::core::GenerateId(bot ? "bot" : "user"),
      .display_name = name,
      .is_bot = bot,
  };
}

landlords::protocol::RoomSnapshot BuildSmokeSnapshot() {
  landlords::protocol::RoomSnapshot snapshot;
  snapshot.set_room_id("onnx_smoke_room");
  snapshot.set_phase(landlords::protocol::ROOM_PHASE_PLAYING);
  snapshot.set_mode(landlords::protocol::MATCH_MODE_VS_BOT);
  snapshot.set_current_turn_player_id("bot_landlord");

  auto* landlord = snapshot.add_players();
  landlord->set_player_id("bot_landlord");
  landlord->set_display_name("Bot Landlord");
  landlord->set_is_bot(true);
  landlord->set_role(landlords::protocol::PLAYER_ROLE_LANDLORD);
  landlord->set_cards_left(20);

  auto* down = snapshot.add_players();
  down->set_player_id("human_down");
  down->set_display_name("Human Down");
  down->set_is_bot(false);
  down->set_role(landlords::protocol::PLAYER_ROLE_FARMER);
  down->set_cards_left(17);

  auto* up = snapshot.add_players();
  up->set_player_id("bot_up");
  up->set_display_name("Bot Up");
  up->set_is_bot(true);
  up->set_role(landlords::protocol::PLAYER_ROLE_FARMER);
  up->set_cards_left(17);

  const struct {
    const char* id;
    const char* rank;
    const char* suit;
    int value;
  } hand[] = {
      {"c1", "3", "S", 3},   {"c2", "3", "H", 3},   {"c3", "4", "S", 4},
      {"c4", "4", "H", 4},   {"c5", "5", "S", 5},   {"c6", "5", "H", 5},
      {"c7", "6", "S", 6},   {"c8", "6", "H", 6},   {"c9", "7", "S", 7},
      {"c10", "7", "H", 7},  {"c11", "8", "S", 8},  {"c12", "8", "H", 8},
      {"c13", "9", "S", 9},  {"c14", "9", "H", 9},  {"c15", "10", "S", 10},
      {"c16", "J", "S", 11}, {"c17", "Q", "S", 12}, {"c18", "K", "S", 13},
      {"c19", "A", "S", 14}, {"c20", "2", "S", 15},
  };
  for (const auto& item : hand) {
    *snapshot.add_self_cards() = MakeCard(item.id, item.rank, item.suit, item.value);
  }

  *snapshot.add_landlord_cards() = MakeCard("l1", "Q", "H", 12);
  *snapshot.add_landlord_cards() = MakeCard("l2", "K", "H", 13);
  *snapshot.add_landlord_cards() = MakeCard("l3", "A", "H", 14);
  return snapshot;
}

void ConfigureOnnxDir() {
#ifdef _WIN32
  _putenv_s("LANDLORDS_DOUZERO_ONNX_DIR_EASY",
            "F:/CodeXProject/LandLords/backend/ai_models/onnx/douzero_ADP");
  _putenv_s("LANDLORDS_DOUZERO_ONNX_DIR_NORMAL",
            "F:/CodeXProject/LandLords/backend/ai_models/onnx/sl");
  _putenv_s("LANDLORDS_DOUZERO_ONNX_DIR_HARD",
            "F:/CodeXProject/LandLords/backend/ai_models/onnx/douzero_WP");
  _putenv_s("LANDLORDS_DOUZERO_ONNX_DIR",
            "F:/CodeXProject/LandLords/backend/ai_models/onnx/sl");
  _putenv_s("LANDLORDS_BOT_BACKEND", "onnx");
#else
  setenv("LANDLORDS_DOUZERO_ONNX_DIR_EASY",
         "F:/CodeXProject/LandLords/backend/ai_models/onnx/douzero_ADP",
         1);
  setenv("LANDLORDS_DOUZERO_ONNX_DIR_NORMAL",
         "F:/CodeXProject/LandLords/backend/ai_models/onnx/sl",
         1);
  setenv("LANDLORDS_DOUZERO_ONNX_DIR_HARD",
         "F:/CodeXProject/LandLords/backend/ai_models/onnx/douzero_WP",
         1);
  setenv("LANDLORDS_DOUZERO_ONNX_DIR",
         "F:/CodeXProject/LandLords/backend/ai_models/onnx/sl",
         1);
  setenv("LANDLORDS_BOT_BACKEND", "onnx", 1);
#endif
}

void VerifyFinishedRoom(const landlords::game::Room& room, const std::string& observer_id) {
  const auto snapshot = room.BuildSnapshotFor(observer_id);
  Require(snapshot.phase() == landlords::protocol::ROOM_PHASE_FINISHED,
          "onnx room did not finish");
  Require(snapshot.players_size() == 3, "onnx room does not contain three players");

  int score_sum = 0;
  int empty_hands = 0;
  int landlord_count = 0;
  const landlords::core::PlayerState* winner = nullptr;
  const landlords::core::PlayerState* landlord = nullptr;
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
    } else if (player.round_score > 0) {
      if (farmer_positive_score == -1) {
        farmer_positive_score = player.round_score;
      } else {
        Require(player.round_score == farmer_positive_score,
                "onnx farmer scores must match when farmers win");
      }
    }
  }

  Require(score_sum == 0, "onnx round scores do not sum to zero");
  Require(empty_hands == 1, "onnx expected exactly one winner");
  Require(landlord_count == 1, "onnx expected exactly one landlord");
  Require(winner != nullptr, "onnx winner not found");
  Require(landlord != nullptr, "onnx landlord not found");

  if (winner->is_landlord) {
    for (const auto& player : room.players()) {
      if (!player.is_landlord) {
        Require(player.round_score < 0, "onnx farmers must lose when landlord wins");
      }
    }
  } else {
    Require(landlord->round_score < 0, "onnx landlord must lose when farmers win");
    Require(farmer_positive_score > 0, "onnx farmers should receive positive score");
    Require(landlord->round_score == -2 * farmer_positive_score,
            "onnx landlord score must be double the farmer score");
  }
}

void RunOnnxRoomSimulation(int rounds) {
  auto strategy = landlords::ai::CreateOnnxBotStrategyFromEnv();
  Require(strategy != nullptr, "failed to create onnx strategy for room simulation");

  for (int index = 0; index < rounds; ++index) {
    std::vector<landlords::core::PlayerState> players;
    players.push_back(MakePlayer("Onnx Bot Alpha", true));
    players.push_back(MakePlayer("Onnx Bot Bravo", true));
    players.push_back(MakePlayer("Onnx Bot Charlie", true));

    landlords::game::Room room(
        landlords::core::GenerateId("room"),
        landlords::protocol::MATCH_MODE_VS_BOT,
        players,
        landlords::protocol::BOT_DIFFICULTY_HARD,
        strategy);
    std::int64_t now_ms = landlords::core::NowMs();
    int guard = 0;
    while (!room.finished() && guard < 600) {
      now_ms += 5000;
      room.TickManaged(now_ms, 25000);
      ++guard;
    }

    Require(guard < 600, "onnx room simulation hit turn guard");
    VerifyFinishedRoom(room, room.players().front().player_id);
  }
}

}  // namespace

int main() {
  try {
    Require(landlords::ai::OnnxRuntimeAvailable(), "onnx runtime is not enabled");
    ConfigureOnnxDir();

    const auto snapshot = BuildSmokeSnapshot();
    std::unordered_set<std::string> ids;
    for (const auto& card : snapshot.self_cards()) {
      ids.insert(card.id());
    }
    for (const auto difficulty : {
             landlords::protocol::BOT_DIFFICULTY_EASY,
             landlords::protocol::BOT_DIFFICULTY_NORMAL,
             landlords::protocol::BOT_DIFFICULTY_HARD,
         }) {
      auto strategy = landlords::ai::CreateOnnxBotStrategyForDifficulty(difficulty);
      Require(strategy != nullptr, "failed to create onnx strategy for one difficulty");
      const auto decision = strategy->ChooseMove(snapshot);
      Require(decision.has_value(), "onnx strategy returned no decision");
      Require(!decision->card_ids.empty(), "onnx strategy returned an empty move");
      for (const auto& id : decision->card_ids) {
        Require(ids.contains(id), "onnx strategy returned an unknown card id");
      }
    }

    RunOnnxRoomSimulation(24);

    std::cout << "onnx strategy smoke test passed" << std::endl;
    return 0;
  } catch (const std::exception& exception) {
    std::cerr << "onnx strategy smoke test failed: " << exception.what() << std::endl;
    return 1;
  }
}
