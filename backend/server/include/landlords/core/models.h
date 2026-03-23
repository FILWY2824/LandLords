#pragma once

#include <chrono>
#include <cstdint>
#include <optional>
#include <random>
#include <string>
#include <unordered_map>
#include <vector>

#include "landlords.pb.h"

namespace landlords::core {

enum class PatternType {
  kInvalid = 0,
  kSingle,
  kPair,
  kTriple,
  kTripleWithSingle,
  kTripleWithPair,
  kStraight,
  kStraightPair,
  kAirplane,
  kAirplaneWithSingle,
  kAirplaneWithPair,
  kBomb,
  kFourWithTwoSingles,
  kFourWithTwoPairs,
  kRocket,
};

struct Card {
  std::string id;
  std::string rank;
  std::string suit;
  int value = 0;
};

struct CardPattern {
  PatternType type = PatternType::kInvalid;
  std::vector<Card> cards;
  int weight = 0;
  int length = 0;
  std::string label;
};

struct UserRecord {
  std::string user_id;
  std::string account;
  std::string nickname;
  std::string password_hash;
  int total_score = 0;
  int landlord_wins = 0;
  int landlord_games = 0;
  int farmer_wins = 0;
  int farmer_games = 0;
  int online_landlord_wins = 0;
  int online_landlord_games = 0;
  int online_farmer_wins = 0;
  int online_farmer_games = 0;
  int bot_landlord_wins = 0;
  int bot_landlord_games = 0;
  int bot_farmer_wins = 0;
  int bot_farmer_games = 0;
  std::vector<std::string> friend_user_ids;
};

struct FriendRequestRecord {
  std::string request_id;
  std::string requester_user_id;
  std::string receiver_user_id;
  landlords::protocol::FriendRequestStatus status =
      landlords::protocol::FRIEND_REQUEST_STATUS_PENDING;
  std::int64_t created_at_ms = 0;
  std::int64_t updated_at_ms = 0;
};

struct SystemRecord {
  int support_like_count = 0;
};

struct PlayerState {
  std::string player_id;
  std::string display_name;
  bool is_bot = false;
  bool is_managed = false;
  bool is_landlord = false;
  int round_score = 0;
  std::vector<Card> hand;
};

struct RoomAction {
  std::string action_id;
  std::string player_id;
  landlords::protocol::ActionType action_type = landlords::protocol::ACTION_TYPE_UNSPECIFIED;
  std::vector<Card> cards;
  std::string pattern_label;
  std::int64_t timestamp_ms = 0;
};

inline std::int64_t NowMs() {
  using namespace std::chrono;
  return duration_cast<milliseconds>(system_clock::now().time_since_epoch()).count();
}

inline std::string RoleLabel(bool is_landlord) {
  return is_landlord ? "landlord" : "farmer";
}

std::vector<Card> BuildDeck();
int CompareCards(const Card& left, const Card& right);
CardPattern EvaluatePattern(std::vector<Card> cards);
std::vector<CardPattern> BuildCandidates(const std::vector<Card>& hand);
bool CanBeat(const CardPattern& candidate, const std::optional<CardPattern>& last_pattern);
std::string GenerateId(const std::string& prefix);
void FillProtoCard(const Card& source, landlords::protocol::Card* target);
landlords::protocol::PatternType ToProtoPatternType(PatternType type);

}  // namespace landlords::core
