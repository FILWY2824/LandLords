#include "landlords/services/game_service.h"

#include <algorithm>
#include <array>
#include <cctype>
#include <cstdlib>
#include <functional>
#include <random>
#include <sstream>
#include <stdexcept>
#include <string_view>
#include <thread>
#include <unordered_set>

#include "landlords/core/logging.h"

namespace landlords::services {

namespace {

constexpr std::string_view kCancelMatchCommand = "match:cancel";
constexpr std::int64_t kInvitationTimeoutMs = 30'000;
constexpr std::size_t kMaxNicknameCodePoints = 10U;

std::string DisplayNameFor(const core::UserRecord& user) {
  return user.nickname.empty() ? user.account : user.nickname;
}

std::size_t Utf8CodePointCount(const std::string& text) {
  std::size_t count = 0;
  for (unsigned char ch : text) {
    if ((ch & 0xC0U) != 0x80U) {
      ++count;
    }
  }
  return count;
}

std::string HashPassword(const std::string& password) {
  return std::to_string(std::hash<std::string>{}(password));
}

const char* PayloadName(const landlords::protocol::ClientMessage& message) {
  switch (message.payload_case()) {
    case landlords::protocol::ClientMessage::kRegisterRequest:
      return "register";
    case landlords::protocol::ClientMessage::kLoginRequest:
      return "login";
    case landlords::protocol::ClientMessage::kResetPasswordRequest:
      return "reset_password";
    case landlords::protocol::ClientMessage::kUpdateNicknameRequest:
      return "update_nickname";
    case landlords::protocol::ClientMessage::kMatchRequest:
      return "match";
    case landlords::protocol::ClientMessage::kCreateRoomRequest:
      return "create_room";
    case landlords::protocol::ClientMessage::kJoinRoomRequest:
      return "join_room";
    case landlords::protocol::ClientMessage::kLeaveRoomRequest:
      return "leave_room";
    case landlords::protocol::ClientMessage::kListFriendsRequest:
      return "list_friends";
    case landlords::protocol::ClientMessage::kAddFriendRequest:
      return "add_friend";
    case landlords::protocol::ClientMessage::kRespondFriendRequestRequest:
      return "respond_friend_request";
    case landlords::protocol::ClientMessage::kDeleteFriendRequest:
      return "delete_friend";
    case landlords::protocol::ClientMessage::kInvitePlayerRequest:
      return "invite_player";
    case landlords::protocol::ClientMessage::kRespondRoomInvitationRequest:
      return "respond_room_invitation";
    case landlords::protocol::ClientMessage::kRoomReadyRequest:
      return "room_ready";
    case landlords::protocol::ClientMessage::kAddBotRequest:
      return "add_bot";
    case landlords::protocol::ClientMessage::kRemovePlayerRequest:
      return "remove_player";
    case landlords::protocol::ClientMessage::kPlayCardsRequest:
      return "play_cards";
    case landlords::protocol::ClientMessage::kPassRequest:
      return "pass";
    case landlords::protocol::ClientMessage::kReconnectRequest:
      return "reconnect";
    case landlords::protocol::ClientMessage::kHeartbeatRequest:
      return "heartbeat";
    case landlords::protocol::ClientMessage::PAYLOAD_NOT_SET:
      return "unset";
  }
  return "unknown";
}

int LoadRoomTickIntervalMs() {
  const char* raw = std::getenv("LANDLORDS_ROOM_TICK_INTERVAL_MS");
  if (raw == nullptr || *raw == '\0') {
    return 100;
  }
  return std::max(10, std::atoi(raw));
}

void FillProfile(const core::UserRecord& user, landlords::protocol::UserProfile* profile) {
  profile->set_user_id(user.user_id);
  profile->set_account(user.account);
  profile->set_nickname(user.nickname);
  profile->set_total_score(user.total_score);
  profile->set_landlord_wins(user.landlord_wins);
  profile->set_landlord_games(user.landlord_games);
  profile->set_farmer_wins(user.farmer_wins);
  profile->set_farmer_games(user.farmer_games);
}

std::string GenerateRoomCode() {
  static std::mt19937 rng{std::random_device{}()};
  static constexpr std::array<char, 10> digits = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'};
  std::uniform_int_distribution<int> pick(0, static_cast<int>(digits.size()) - 1);
  std::string code;
  code.reserve(6);
  for (int index = 0; index < 6; ++index) {
    code.push_back(digits[static_cast<std::size_t>(pick(rng))]);
  }
  return code;
}

std::string BotDisplayName(landlords::protocol::BotDifficulty difficulty) {
  static_cast<void>(difficulty);
  return "\xE6\x9C\xBA\xE5\x99\xA8\xE4\xBA\xBA";
}

std::shared_ptr<ai::IBotStrategy> RequireBotStrategy(
    std::shared_ptr<ai::IBotStrategy> strategy,
    std::string_view difficulty_name) {
  if (strategy == nullptr) {
    throw std::runtime_error(
        "DouZero ONNX strategy is required but failed to initialize for difficulty " +
        std::string(difficulty_name));
  }
  return strategy;
}

bool MatchesFriendRequestPair(const core::FriendRequestRecord& request,
                              const std::string& left_user_id,
                              const std::string& right_user_id) {
  return (request.requester_user_id == left_user_id &&
          request.receiver_user_id == right_user_id) ||
         (request.requester_user_id == right_user_id &&
          request.receiver_user_id == left_user_id);
}
}  // namespace

GameService::GameService(
    std::shared_ptr<persistence::IUserRepository> user_repository,
    std::shared_ptr<persistence::IFriendRequestRepository> friend_request_repository)
    : user_repository_(std::move(user_repository)),
      friend_request_repository_(std::move(friend_request_repository)),
      easy_bot_strategy_(RequireBotStrategy(
          ai::CreateBotStrategyForDifficulty(
              landlords::protocol::BOT_DIFFICULTY_EASY),
          "easy")),
      standard_bot_strategy_(RequireBotStrategy(
          ai::CreateBotStrategyForDifficulty(
              landlords::protocol::BOT_DIFFICULTY_NORMAL),
          "normal")),
      hard_bot_strategy_(RequireBotStrategy(
          ai::CreateBotStrategyForDifficulty(
              landlords::protocol::BOT_DIFFICULTY_HARD),
          "hard")),
      tick_thread_([this] { TickRoomsLoop(); }) {}

GameService::~GameService() {
  running_ = false;
  if (tick_thread_.joinable()) {
    tick_thread_.join();
  }
}

void GameService::HandleMessage(const std::shared_ptr<network::IConnection>& connection,
                                const landlords::protocol::ClientMessage& message) {
  LANDLORDS_LOG(landlords::core::LogLevel::kDebug,
                "game_service",
                "recv request_id=" << message.request_id()
                                   << " session=" << (message.session_token().empty() ? "-" : message.session_token())
                                   << " payload=" << PayloadName(message));
  switch (message.payload_case()) {
    case landlords::protocol::ClientMessage::kRegisterRequest:
      HandleRegister(connection, message);
      break;
    case landlords::protocol::ClientMessage::kLoginRequest:
      HandleLogin(connection, message);
      break;
    case landlords::protocol::ClientMessage::kResetPasswordRequest:
      HandleResetPassword(connection, message);
      break;
    case landlords::protocol::ClientMessage::kUpdateNicknameRequest:
      HandleUpdateNickname(connection, message);
      break;
    case landlords::protocol::ClientMessage::kMatchRequest:
      HandleMatch(connection, message);
      break;
    case landlords::protocol::ClientMessage::kCreateRoomRequest:
      HandleCreateRoom(connection, message);
      break;
    case landlords::protocol::ClientMessage::kJoinRoomRequest:
      HandleJoinRoom(connection, message);
      break;
    case landlords::protocol::ClientMessage::kLeaveRoomRequest:
      HandleLeaveRoom(connection, message);
      break;
    case landlords::protocol::ClientMessage::kListFriendsRequest:
      HandleListFriends(connection, message);
      break;
    case landlords::protocol::ClientMessage::kAddFriendRequest:
      HandleAddFriend(connection, message);
      break;
    case landlords::protocol::ClientMessage::kRespondFriendRequestRequest:
      HandleRespondFriendRequest(connection, message);
      break;
    case landlords::protocol::ClientMessage::kDeleteFriendRequest:
      HandleDeleteFriend(connection, message);
      break;
    case landlords::protocol::ClientMessage::kInvitePlayerRequest:
      HandleInvitePlayer(connection, message);
      break;
    case landlords::protocol::ClientMessage::kRespondRoomInvitationRequest:
      HandleRespondRoomInvitation(connection, message);
      break;
    case landlords::protocol::ClientMessage::kRoomReadyRequest:
      HandleRoomReady(connection, message);
      break;
    case landlords::protocol::ClientMessage::kAddBotRequest:
      HandleAddBot(connection, message);
      break;
    case landlords::protocol::ClientMessage::kRemovePlayerRequest:
      HandleRemovePlayer(connection, message);
      break;
    case landlords::protocol::ClientMessage::kPlayCardsRequest:
      HandlePlay(connection, message);
      break;
    case landlords::protocol::ClientMessage::kPassRequest:
      HandlePass(connection, message);
      break;
    case landlords::protocol::ClientMessage::kReconnectRequest:
      HandleReconnect(connection, message);
      break;
    case landlords::protocol::ClientMessage::kHeartbeatRequest:
      HandleHeartbeat(connection, message);
      break;
    case landlords::protocol::ClientMessage::PAYLOAD_NOT_SET:
      SendError(connection,
                message.request_id(),
                landlords::protocol::ERROR_CODE_INVALID_REQUEST,
                "payload is required");
      break;
  }
}

std::optional<GameService::SessionState*> GameService::RequireSession(const std::string& session_token) {
  auto iterator = sessions_by_token_.find(session_token);
  if (iterator == sessions_by_token_.end()) {
    return std::nullopt;
  }
  return &iterator->second;
}

std::optional<GameService::SessionState*> GameService::RequireSessionForConnection(
    const std::shared_ptr<network::IConnection>& connection,
    const std::string& session_token) {
  const auto session = RequireSession(session_token);
  if (!session.has_value()) {
    return std::nullopt;
  }
  BindSessionConnection(**session, connection);
  return session;
}

std::optional<GameService::SessionState*> GameService::FindSessionByUserId(
    const std::string& user_id) {
  for (auto& [token, session] : sessions_by_token_) {
    if (session.user.user_id != user_id) {
      continue;
    }
    if (session.connection.expired()) {
      continue;
    }
    return &session;
  }
  return std::nullopt;
}

std::vector<GameService::SessionState*> GameService::FindSessionsByUserId(
    const std::string& user_id) {
  std::vector<SessionState*> sessions;
  for (auto& [token, session] : sessions_by_token_) {
    if (session.user.user_id != user_id || session.connection.expired()) {
      continue;
    }
    sessions.push_back(&session);
  }
  return sessions;
}

std::optional<GameService::PendingRoom*> GameService::FindPendingRoom(const std::string& room_id) {
  auto iterator = pending_rooms_by_id_.find(room_id);
  if (iterator == pending_rooms_by_id_.end()) {
    return std::nullopt;
  }
  return &iterator->second;
}

std::optional<const GameService::PendingRoom*> GameService::FindPendingRoom(
    const std::string& room_id) const {
  auto iterator = pending_rooms_by_id_.find(room_id);
  if (iterator == pending_rooms_by_id_.end()) {
    return std::nullopt;
  }
  return &iterator->second;
}

bool GameService::EnsureSessionRoomAvailable(const SessionState& session) {
  if (session.room_id.empty()) {
    return true;
  }
  if (pending_rooms_by_id_.contains(session.room_id)) {
    return false;
  }
  auto active_room = rooms_by_id_.find(session.room_id);
  if (active_room == rooms_by_id_.end()) {
    return true;
  }
  return active_room->second->finished();
}

void GameService::ReleaseTransientBotRoom(SessionState& session) {
  if (session.room_id.empty()) {
    return;
  }
  auto active_room = rooms_by_id_.find(session.room_id);
  if (active_room == rooms_by_id_.end()) {
    return;
  }
  if (active_room->second->finished() ||
      active_room->second->mode() == landlords::protocol::MATCH_MODE_VS_BOT) {
    rooms_by_id_.erase(active_room);
    session.room_id.clear();
  }
}

bool GameService::SessionCanJoinPendingRoom(const SessionState& session,
                                            const std::string& target_room_id) const {
  if (session.room_id.empty() || session.room_id == target_room_id) {
    return true;
  }
  if (pending_rooms_by_id_.contains(session.room_id)) {
    return true;
  }
  auto active_room = rooms_by_id_.find(session.room_id);
  if (active_room == rooms_by_id_.end()) {
    return true;
  }
  return active_room->second->finished();
}

landlords::protocol::RoomSnapshot GameService::BuildPendingRoomSnapshot(
    const PendingRoom& room,
    const std::string& audience_player_id) const {
  static_cast<void>(audience_player_id);

  landlords::protocol::RoomSnapshot snapshot;
  snapshot.set_room_id(room.room_id);
  snapshot.set_room_code(room.room_code);
  snapshot.set_owner_player_id(room.owner_player_id);
  snapshot.set_phase(landlords::protocol::ROOM_PHASE_PREPARING);
  snapshot.set_mode(landlords::protocol::MATCH_MODE_PVP);
  snapshot.set_base_score(1);
  snapshot.set_multiplier(1);
  snapshot.set_current_round_score(0);
  snapshot.set_turn_serial(0);

  int occupied_count = 0;
  int ready_count = 0;
  for (const auto& seat : room.seats) {
    if (seat.player_id.empty()) {
      continue;
    }
    ++occupied_count;
    if (seat.ready) {
      ++ready_count;
    }
  }
  if (occupied_count < 3) {
    snapshot.set_status_text("waiting_for_players");
  } else if (ready_count < 3) {
    snapshot.set_status_text("waiting_for_ready");
  } else {
    snapshot.set_status_text("ready_to_start");
  }

  for (int index = 0; index < 3; ++index) {
    auto* target = snapshot.add_players();
    target->set_seat_index(index);
    if (index < static_cast<int>(room.seats.size()) &&
        !room.seats[static_cast<std::size_t>(index)].player_id.empty()) {
      const auto& seat = room.seats[static_cast<std::size_t>(index)];
      target->set_player_id(seat.player_id);
      target->set_display_name(seat.display_name);
      target->set_is_bot(seat.is_bot);
      target->set_role(landlords::protocol::PLAYER_ROLE_FARMER);
      target->set_ready(seat.ready);
      target->set_occupied(true);
    } else {
      target->set_player_id("");
      target->set_display_name("绌轰綅");
      target->set_is_bot(false);
      target->set_role(landlords::protocol::PLAYER_ROLE_UNSPECIFIED);
      target->set_ready(false);
      target->set_occupied(false);
    }
    target->set_cards_left(0);
    target->set_round_score(0);
  }

  return snapshot;
}

landlords::protocol::OnlineUser GameService::BuildOnlineUser(
    const core::UserRecord& user) {
  landlords::protocol::OnlineUser payload;
  payload.set_user_id(user.user_id);
  payload.set_account(user.account);
  payload.set_nickname(user.nickname);
  payload.set_online(!FindSessionsByUserId(user.user_id).empty());
  return payload;
}

void GameService::SendPendingSnapshotToRoom(const PendingRoom& room) {
  for (const auto& seat : room.seats) {
    if (seat.player_id.empty() || seat.is_bot) {
      continue;
    }
    for (auto& [token, session] : sessions_by_token_) {
      if (session.user.user_id != seat.player_id) {
        continue;
      }
      if (const auto connection = session.connection.lock()) {
        landlords::protocol::ServerMessage push;
        *push.mutable_room_snapshot() = BuildPendingRoomSnapshot(room, seat.player_id);
        connection->Send(push);
      }
    }
  }
}

void GameService::RemoveSessionFromPendingRoom(SessionState& session,
                                               const std::string& room_id) {
  auto pending_room = FindPendingRoom(room_id);
  if (!pending_room.has_value()) {
    session.room_id.clear();
    return;
  }

  bool removed = false;
  for (auto& seat : (*pending_room)->seats) {
    if (seat.player_id != session.user.user_id) {
      continue;
    }
    seat = PendingSeat{};
    removed = true;
    break;
  }

  session.room_id.clear();
  if (!removed) {
    return;
  }

  if ((*pending_room)->owner_player_id == session.user.user_id) {
    (*pending_room)->owner_player_id.clear();
    for (const auto& seat : (*pending_room)->seats) {
      if (!seat.player_id.empty() && !seat.is_bot) {
        (*pending_room)->owner_player_id = seat.player_id;
        break;
      }
    }
  }

  bool has_any_player = false;
  for (const auto& seat : (*pending_room)->seats) {
    if (!seat.player_id.empty()) {
      has_any_player = true;
      break;
    }
  }

  if (!has_any_player) {
    ExpireInvitationsForRoom(room_id, "room closed");
    pending_room_id_by_code_.erase((*pending_room)->room_code);
    pending_rooms_by_id_.erase(room_id);
    return;
  }

  ExpireInvitationsForRoom(room_id, "room seats changed");
  SendPendingSnapshotToRoom(**pending_room);
}

void GameService::StartPreparedRoom(PendingRoom room) {
  ExpireInvitationsForRoom(room.room_id, "room started");

  std::vector<core::PlayerState> players;
  players.reserve(room.seats.size());
  std::unordered_map<std::string, std::shared_ptr<ai::IBotStrategy>> bot_strategies;
  for (const auto& seat : room.seats) {
    if (seat.player_id.empty()) {
      continue;
    }
    players.push_back(core::PlayerState{
        .player_id = seat.player_id,
        .display_name = seat.display_name,
        .is_bot = seat.is_bot,
    });
    if (seat.is_bot) {
      bot_strategies[seat.player_id] = ResolveBotStrategy(seat.bot_difficulty);
    }
  }

  auto room_instance = std::make_shared<game::Room>(
      room.room_id,
      landlords::protocol::MATCH_MODE_PVP,
      players,
      landlords::protocol::BOT_DIFFICULTY_NORMAL,
      standard_bot_strategy_,
      std::move(bot_strategies));
  rooms_by_id_[room.room_id] = room_instance;
  pending_room_id_by_code_.erase(room.room_code);
  pending_rooms_by_id_.erase(room.room_id);
  SendSnapshotToRoom(*room_instance);
}

void GameService::HandleRegister(const std::shared_ptr<network::IConnection>& connection,
                                 const landlords::protocol::ClientMessage& message) {
  const auto& request = message.register_request();
  landlords::protocol::ServerMessage response;
  response.set_request_id(message.request_id());
  auto* payload = response.mutable_register_response();

  if (request.account().empty() || request.nickname().empty() || request.password().empty()) {
    payload->set_success(false);
    payload->set_message("account, nickname and password are required");
    connection->Send(response);
    return;
  }

  if (Utf8CodePointCount(request.nickname()) > kMaxNicknameCodePoints) {
    payload->set_success(false);
    payload->set_message("nickname must be within 10 characters");
    connection->Send(response);
    return;
  }

  if (user_repository_->FindByAccount(request.account()).has_value()) {
    payload->set_success(false);
    payload->set_message("account already exists");
    connection->Send(response);
    return;
  }

  const auto user = user_repository_->SaveNewUser(
      request.account(), request.nickname(), HashPassword(request.password()));
  payload->set_success(true);
  payload->set_message("register success");
  FillProfile(user, payload->mutable_profile());
  connection->Send(response);
}

void GameService::HandleLogin(const std::shared_ptr<network::IConnection>& connection,
                              const landlords::protocol::ClientMessage& message) {
  const auto& request = message.login_request();
  landlords::protocol::ServerMessage response;
  response.set_request_id(message.request_id());
  auto* payload = response.mutable_login_response();

  const auto user = user_repository_->FindByAccount(request.account());
  if (!user.has_value() || user->password_hash != HashPassword(request.password())) {
    payload->set_success(false);
    payload->set_message("invalid account or password");
    connection->Send(response);
    return;
  }

  std::lock_guard lock(mutex_);
  SessionState session{
      .session_token = core::GenerateId("session"),
      .user = *user,
      .connection = connection,
      .room_id = "",
  };
  sessions_by_token_[session.session_token] = session;

  payload->set_success(true);
  payload->set_message("login success");
  payload->set_session_token(session.session_token);
  FillProfile(*user, payload->mutable_profile());
  connection->Send(response);

  std::vector<std::string> affected_users = user->friend_user_ids;
  affected_users.push_back(user->user_id);
  PushFriendCenterUpdateToUsers(affected_users);
}

void GameService::HandleResetPassword(
    const std::shared_ptr<network::IConnection>& connection,
    const landlords::protocol::ClientMessage& message) {
  const auto& request = message.reset_password_request();
  landlords::protocol::ServerMessage response;
  response.set_request_id(message.request_id());
  auto* payload = response.mutable_reset_password_response();

  if (request.account().empty() || request.new_password().empty()) {
    payload->set_success(false);
    payload->set_message("account and new password are required");
    connection->Send(response);
    return;
  }

  std::lock_guard lock(mutex_);
  auto user = user_repository_->FindByAccount(request.account());
  if (!user.has_value()) {
    payload->set_success(false);
    payload->set_message("account not found");
    connection->Send(response);
    return;
  }

  user->password_hash = HashPassword(request.new_password());
  user_repository_->UpdateUser(*user);
  for (auto& [token, session] : sessions_by_token_) {
    if (session.user.user_id == user->user_id) {
      session.user = *user;
    }
  }

  payload->set_success(true);
  payload->set_message("password updated");
  connection->Send(response);
}

void GameService::HandleUpdateNickname(
    const std::shared_ptr<network::IConnection>& connection,
    const landlords::protocol::ClientMessage& message) {
  const auto& request = message.update_nickname_request();
  landlords::protocol::ServerMessage response;
  response.set_request_id(message.request_id());
  auto* payload = response.mutable_update_nickname_response();

  if (request.nickname().empty()) {
    payload->set_success(false);
    payload->set_message("nickname is required");
    connection->Send(response);
    return;
  }

  if (Utf8CodePointCount(request.nickname()) > kMaxNicknameCodePoints) {
    payload->set_success(false);
    payload->set_message("nickname must be within 10 characters");
    connection->Send(response);
    return;
  }

  std::lock_guard lock(mutex_);
  const auto session = RequireSessionForConnection(connection, message.session_token());
  if (!session.has_value()) {
    payload->set_success(false);
    payload->set_message("login required");
    connection->Send(response);
    return;
  }

  auto user = user_repository_->FindByUserId((*session)->user.user_id);
  if (!user.has_value()) {
    payload->set_success(false);
    payload->set_message("user not found");
    connection->Send(response);
    return;
  }

  user->nickname = request.nickname();
  user_repository_->UpdateUser(*user);
  RefreshSessionsForUser(*user);

  payload->set_success(true);
  payload->set_message("nickname updated");
  FillProfile(*user, payload->mutable_profile());
  connection->Send(response);
  std::vector<std::string> affected_users = user->friend_user_ids;
  affected_users.push_back(user->user_id);
  PushFriendCenterUpdateToUsers(affected_users);
}

void GameService::HandleMatch(const std::shared_ptr<network::IConnection>& connection,
                              const landlords::protocol::ClientMessage& message) {
  landlords::protocol::ServerMessage response;
  response.set_request_id(message.request_id());
  auto* payload = response.mutable_match_response();

  std::lock_guard lock(mutex_);
  const auto session = RequireSessionForConnection(connection, message.session_token());
  if (!session.has_value()) {
    payload->set_accepted(false);
    payload->set_message("please login first");
    connection->Send(response);
    return;
  }

  ReleaseTransientBotRoom(**session);
  if (!(*session)->room_id.empty()) {
    auto existing_pending = pending_rooms_by_id_.find((*session)->room_id);
    auto existing_room = rooms_by_id_.find((*session)->room_id);
    if (existing_pending != pending_rooms_by_id_.end()) {
      payload->set_accepted(false);
      payload->set_message("already in room");
      connection->Send(response);
      return;
    }
    if (existing_room != rooms_by_id_.end() && existing_room->second->finished()) {
      (*session)->room_id.clear();
    } else {
      payload->set_accepted(false);
      payload->set_message("already in room");
      connection->Send(response);
      return;
    }
  }

  payload->set_accepted(true);
  payload->set_message("match request accepted");
  connection->Send(response);

  if (message.match_request().mode() == landlords::protocol::MATCH_MODE_VS_BOT) {
    const auto difficulty =
        NormalizeBotDifficulty(message.match_request().bot_difficulty());
    LANDLORDS_LOG(landlords::core::LogLevel::kInfo,
                  "game_service",
                  "match accepted user=" << (*session)->user.user_id
                                         << " mode=vs_bot difficulty="
                                         << static_cast<int>(difficulty));
    CreateBotRoom(**session, difficulty);
  } else {
    LANDLORDS_LOG(landlords::core::LogLevel::kInfo,
                  "game_service",
                  "match accepted user=" << (*session)->user.user_id << " mode=pvp");
    if (std::find(pvp_waiting_tokens_.begin(),
                  pvp_waiting_tokens_.end(),
                  (*session)->session_token) == pvp_waiting_tokens_.end()) {
      pvp_waiting_tokens_.push_back((*session)->session_token);
    }
    MaybeCreatePvpRoom();
  }
}

void GameService::HandleCreateRoom(const std::shared_ptr<network::IConnection>& connection,
                                   const landlords::protocol::ClientMessage& message) {
  std::lock_guard lock(mutex_);
  const auto session = RequireSessionForConnection(connection, message.session_token());
  if (!session.has_value()) {
    SendError(connection, message.request_id(), landlords::protocol::ERROR_CODE_AUTH_FAILED, "login required");
    return;
  }

  ReleaseTransientBotRoom(**session);
  if (!EnsureSessionRoomAvailable(**session)) {
    SendError(connection, message.request_id(), landlords::protocol::ERROR_CODE_MATCH_STATE_INVALID, "already in room");
    return;
  }
  if (!(*session)->room_id.empty()) {
    (*session)->room_id.clear();
  }

  PendingRoom room;
  room.room_id = core::GenerateId("room");
  do {
    room.room_code = GenerateRoomCode();
  } while (pending_room_id_by_code_.contains(room.room_code));
  room.owner_player_id = (*session)->user.user_id;
  room.seats.resize(3);
  room.seats[0] = PendingSeat{
      .player_id = (*session)->user.user_id,
      .display_name = DisplayNameFor((*session)->user),
      .is_bot = false,
      .ready = false,
      .bot_difficulty = landlords::protocol::BOT_DIFFICULTY_NORMAL,
  };

  (*session)->room_id = room.room_id;
  pending_room_id_by_code_[room.room_code] = room.room_id;
  pending_rooms_by_id_[room.room_id] = room;

  landlords::protocol::ServerMessage response;
  response.set_request_id(message.request_id());
  auto* operation = response.mutable_operation_response();
  operation->set_success(true);
  operation->set_message("room_created");
  *operation->mutable_snapshot() = BuildPendingRoomSnapshot(room, (*session)->user.user_id);
  connection->Send(response);
}

void GameService::HandleJoinRoom(const std::shared_ptr<network::IConnection>& connection,
                                 const landlords::protocol::ClientMessage& message) {
  std::lock_guard lock(mutex_);
  const auto session = RequireSessionForConnection(connection, message.session_token());
  if (!session.has_value()) {
    SendError(connection, message.request_id(), landlords::protocol::ERROR_CODE_AUTH_FAILED, "login required");
    return;
  }

  ReleaseTransientBotRoom(**session);
  if (!EnsureSessionRoomAvailable(**session)) {
    SendError(connection, message.request_id(), landlords::protocol::ERROR_CODE_MATCH_STATE_INVALID, "already in room");
    return;
  }
  if (!(*session)->room_id.empty()) {
    (*session)->room_id.clear();
  }

  auto room_id_iterator = pending_room_id_by_code_.find(message.join_room_request().room_code());
  if (room_id_iterator == pending_room_id_by_code_.end()) {
    SendError(connection, message.request_id(), landlords::protocol::ERROR_CODE_NOT_FOUND, "room not found");
    return;
  }
  auto pending_room = FindPendingRoom(room_id_iterator->second);
  if (!pending_room.has_value()) {
    pending_room_id_by_code_.erase(room_id_iterator);
    SendError(connection, message.request_id(), landlords::protocol::ERROR_CODE_NOT_FOUND, "room not found");
    return;
  }

  int empty_index = -1;
  for (int index = 0; index < static_cast<int>((*pending_room)->seats.size()); ++index) {
    const auto& seat = (*pending_room)->seats[static_cast<std::size_t>(index)];
    if (seat.player_id == (*session)->user.user_id) {
      empty_index = index;
      break;
    }
    if (empty_index == -1 && seat.player_id.empty()) {
      empty_index = index;
    }
  }
  if (empty_index == -1) {
    SendError(connection, message.request_id(), landlords::protocol::ERROR_CODE_MATCH_STATE_INVALID, "room is full");
    return;
  }

  auto& seat = (*pending_room)->seats[static_cast<std::size_t>(empty_index)];
  seat.player_id = (*session)->user.user_id;
  seat.display_name = DisplayNameFor((*session)->user);
  seat.is_bot = false;
  seat.ready = false;
  seat.bot_difficulty = landlords::protocol::BOT_DIFFICULTY_NORMAL;
  (*session)->room_id = (*pending_room)->room_id;

  landlords::protocol::ServerMessage response;
  response.set_request_id(message.request_id());
  auto* operation = response.mutable_operation_response();
  operation->set_success(true);
  operation->set_message("room_joined");
  *operation->mutable_snapshot() =
      BuildPendingRoomSnapshot(**pending_room, (*session)->user.user_id);
  connection->Send(response);
  SendPendingSnapshotToRoom(**pending_room);

  const bool room_full = std::none_of(
      (*pending_room)->seats.begin(),
      (*pending_room)->seats.end(),
      [](const PendingSeat& seat) { return seat.player_id.empty(); });
  if (room_full) {
    ExpireInvitationsForRoom((*pending_room)->room_id, "room is full");
  }
}

void GameService::HandleLeaveRoom(const std::shared_ptr<network::IConnection>& connection,
                                  const landlords::protocol::ClientMessage& message) {
  std::lock_guard lock(mutex_);
  const auto session = RequireSessionForConnection(connection, message.session_token());
  if (!session.has_value()) {
    SendError(connection,
              message.request_id(),
              landlords::protocol::ERROR_CODE_AUTH_FAILED,
              "login required");
    return;
  }

  const auto& room_id = message.leave_room_request().room_id();
  if (room_id.empty()) {
    SendError(connection,
              message.request_id(),
              landlords::protocol::ERROR_CODE_INVALID_REQUEST,
              "room_id is required");
    return;
  }
  if (pending_rooms_by_id_.contains(room_id)) {
    RemoveSessionFromPendingRoom(**session, room_id);

    landlords::protocol::ServerMessage response;
    response.set_request_id(message.request_id());
    auto* operation = response.mutable_operation_response();
    operation->set_success(true);
    operation->set_message("room_left");
    connection->Send(response);
    return;
  }

  auto active_room = rooms_by_id_.find(room_id);
  if (active_room == rooms_by_id_.end()) {
    SendError(connection,
              message.request_id(),
              landlords::protocol::ERROR_CODE_NOT_FOUND,
              "room not found");
    return;
  }
  if ((*session)->room_id != room_id) {
    SendError(connection,
              message.request_id(),
              landlords::protocol::ERROR_CODE_AUTH_FAILED,
              "player not in room");
    return;
  }
  if (active_room->second->mode() != landlords::protocol::MATCH_MODE_VS_BOT) {
    SendError(connection,
              message.request_id(),
              landlords::protocol::ERROR_CODE_MATCH_STATE_INVALID,
              "room already started");
    return;
  }

  rooms_by_id_.erase(active_room);
  (*session)->room_id.clear();

  landlords::protocol::ServerMessage response;
  response.set_request_id(message.request_id());
  auto* operation = response.mutable_operation_response();
  operation->set_success(true);
  operation->set_message("room_left");
  connection->Send(response);
}

void GameService::HandleListFriends(
    const std::shared_ptr<network::IConnection>& connection,
    const landlords::protocol::ClientMessage& message) {
  std::lock_guard lock(mutex_);
  const auto session = RequireSessionForConnection(connection, message.session_token());
  if (!session.has_value()) {
    SendError(
        connection, message.request_id(), landlords::protocol::ERROR_CODE_AUTH_FAILED, "login required");
    return;
  }

  landlords::protocol::ServerMessage response;
  response.set_request_id(message.request_id());
  auto* payload = response.mutable_list_friends_response();
  const auto snapshot = BuildFriendCenterSnapshot(**session);
  for (const auto& user : snapshot.friends()) {
    *payload->add_users() = user;
  }
  *payload->mutable_snapshot() = snapshot;
  connection->Send(response);
}

void GameService::HandleAddFriend(const std::shared_ptr<network::IConnection>& connection,
                                  const landlords::protocol::ClientMessage& message) {
  std::lock_guard lock(mutex_);
  const auto session = RequireSessionForConnection(connection, message.session_token());
  if (!session.has_value()) {
    SendError(
        connection, message.request_id(), landlords::protocol::ERROR_CODE_AUTH_FAILED, "login required");
    return;
  }

  landlords::protocol::ServerMessage response;
  response.set_request_id(message.request_id());
  auto* payload = response.mutable_add_friend_response();
  RefreshSessionUser(**session);

  const auto account = message.add_friend_request().account();
  if (account.empty()) {
    payload->set_success(false);
    payload->set_message("account is required");
    connection->Send(response);
    return;
  }

  auto target_user = user_repository_->FindByAccount(account);
  if (!target_user.has_value()) {
    payload->set_success(false);
    payload->set_message("account not found");
    connection->Send(response);
    return;
  }
  if (target_user->user_id == (*session)->user.user_id) {
    payload->set_success(false);
    payload->set_message("cannot add yourself");
    connection->Send(response);
    return;
  }
  if (AreFriends((*session)->user, target_user->user_id)) {
    payload->set_success(false);
    payload->set_message("friend already exists");
    connection->Send(response);
    return;
  }

  const auto existing_request = friend_request_repository_->FindPendingBetween(
      (*session)->user.user_id, target_user->user_id);
  if (existing_request.has_value()) {
    payload->set_success(false);
    payload->set_message(existing_request->requester_user_id == (*session)->user.user_id
                             ? "friend request already sent"
                             : "target already sent you a request");
    *payload->mutable_snapshot() = BuildFriendCenterSnapshot(**session);
    connection->Send(response);
    return;
  }

  const auto request_record = friend_request_repository_->SaveNewRequest(
      (*session)->user.user_id, target_user->user_id, core::NowMs());
  payload->set_success(true);
  payload->set_message("friend_request_sent");
  *payload->mutable_request() = BuildFriendRequestEntry(request_record);
  *payload->mutable_snapshot() = BuildFriendCenterSnapshot(**session);
  connection->Send(response);

  PushFriendCenterUpdateToUsers(
      {(*session)->user.user_id, target_user->user_id});
}

void GameService::HandleRespondFriendRequest(
    const std::shared_ptr<network::IConnection>& connection,
    const landlords::protocol::ClientMessage& message) {
  std::lock_guard lock(mutex_);
  const auto session = RequireSessionForConnection(connection, message.session_token());
  if (!session.has_value()) {
    SendError(
        connection, message.request_id(), landlords::protocol::ERROR_CODE_AUTH_FAILED, "login required");
    return;
  }

  landlords::protocol::ServerMessage response;
  response.set_request_id(message.request_id());
  auto* payload = response.mutable_respond_friend_request_response();
  RefreshSessionUser(**session);

  const auto request_id =
      message.respond_friend_request_request().request_id();
  if (request_id.empty()) {
    payload->set_success(false);
    payload->set_message("request_id is required");
    connection->Send(response);
    return;
  }

  auto request_record = friend_request_repository_->FindById(request_id);
  if (!request_record.has_value() ||
      request_record->receiver_user_id != (*session)->user.user_id) {
    payload->set_success(false);
    payload->set_message("friend request not found");
    connection->Send(response);
    return;
  }
  if (request_record->status != landlords::protocol::FRIEND_REQUEST_STATUS_PENDING) {
    payload->set_success(false);
    payload->set_message("friend request already handled");
    *payload->mutable_snapshot() = BuildFriendCenterSnapshot(**session);
    connection->Send(response);
    return;
  }

  const bool accept = message.respond_friend_request_request().accept();
  const auto related_requests =
      friend_request_repository_->ListForUser((*session)->user.user_id);
  const auto handled_at_ms = core::NowMs();
  if (accept) {
    auto requester = user_repository_->FindByUserId(request_record->requester_user_id);
    auto receiver = user_repository_->FindByUserId(request_record->receiver_user_id);
    if (!requester.has_value() || !receiver.has_value()) {
      payload->set_success(false);
      payload->set_message("player not found");
      connection->Send(response);
      return;
    }
    LinkFriends(*requester, *receiver);
    user_repository_->UpdateUser(*requester);
    user_repository_->UpdateUser(*receiver);
    RefreshSessionsForUser(*requester);
    RefreshSessionsForUser(*receiver);
  }

  request_record->status = accept
                               ? landlords::protocol::FRIEND_REQUEST_STATUS_ACCEPTED
                               : landlords::protocol::FRIEND_REQUEST_STATUS_REJECTED;
  request_record->updated_at_ms = handled_at_ms;
  friend_request_repository_->Update(*request_record);
  for (auto related_request : related_requests) {
    if (related_request.request_id == request_record->request_id ||
        related_request.status != landlords::protocol::FRIEND_REQUEST_STATUS_PENDING ||
        !MatchesFriendRequestPair(related_request,
                                  request_record->requester_user_id,
                                  request_record->receiver_user_id)) {
      continue;
    }
    // Any sibling pending requests between the same two players become
    // historical "handled" records after one explicit decision.
    related_request.status = landlords::protocol::FRIEND_REQUEST_STATUS_UNSPECIFIED;
    related_request.updated_at_ms = handled_at_ms;
    friend_request_repository_->Update(related_request);
  }

  payload->set_success(true);
  payload->set_message(
      request_record->status ==
              landlords::protocol::FRIEND_REQUEST_STATUS_ACCEPTED
          ? "friend request accepted"
          : "friend request rejected");
  *payload->mutable_request() = BuildFriendRequestEntry(*request_record);
  *payload->mutable_snapshot() = BuildFriendCenterSnapshot(**session);
  connection->Send(response);

  PushFriendCenterUpdateToUsers(
      {request_record->requester_user_id, request_record->receiver_user_id});
}

void GameService::HandleDeleteFriend(
    const std::shared_ptr<network::IConnection>& connection,
    const landlords::protocol::ClientMessage& message) {
  std::lock_guard lock(mutex_);
  const auto session = RequireSessionForConnection(connection, message.session_token());
  if (!session.has_value()) {
    SendError(
        connection, message.request_id(), landlords::protocol::ERROR_CODE_AUTH_FAILED, "login required");
    return;
  }

  landlords::protocol::ServerMessage response;
  response.set_request_id(message.request_id());
  auto* payload = response.mutable_delete_friend_response();
  RefreshSessionUser(**session);

  const auto friend_user_id = message.delete_friend_request().friend_user_id();
  if (friend_user_id.empty()) {
    payload->set_success(false);
    payload->set_message("friend_user_id is required");
    connection->Send(response);
    return;
  }
  if (!AreFriends((*session)->user, friend_user_id)) {
    payload->set_success(false);
    payload->set_message("friend not found");
    *payload->mutable_snapshot() = BuildFriendCenterSnapshot(**session);
    connection->Send(response);
    return;
  }

  auto latest_self = user_repository_->FindByUserId((*session)->user.user_id);
  auto target_user = user_repository_->FindByUserId(friend_user_id);
  if (!latest_self.has_value() || !target_user.has_value()) {
    payload->set_success(false);
    payload->set_message("friend not found");
    connection->Send(response);
    return;
  }

  UnlinkFriends(*latest_self, *target_user);
  user_repository_->UpdateUser(*latest_self);
  user_repository_->UpdateUser(*target_user);
  RefreshSessionsForUser(*latest_self);
  RefreshSessionsForUser(*target_user);

  payload->set_success(true);
  payload->set_message("friend deleted");
  *payload->mutable_snapshot() = BuildFriendCenterSnapshot(**session);
  connection->Send(response);

  PushFriendCenterUpdateToUsers(
      {latest_self->user_id, target_user->user_id});
}

void GameService::HandleInvitePlayer(
    const std::shared_ptr<network::IConnection>& connection,
    const landlords::protocol::ClientMessage& message) {
  std::lock_guard lock(mutex_);
  const auto session = RequireSessionForConnection(connection, message.session_token());
  if (!session.has_value()) {
    SendError(
        connection, message.request_id(), landlords::protocol::ERROR_CODE_AUTH_FAILED, "login required");
    return;
  }

  landlords::protocol::ServerMessage response;
  response.set_request_id(message.request_id());
  auto* payload = response.mutable_invite_player_response();

  auto pending_room = FindPendingRoom(message.invite_player_request().room_id());
  if (!pending_room.has_value()) {
    payload->set_accepted(false);
    payload->set_message("room not found");
    connection->Send(response);
    return;
  }
  if ((*pending_room)->owner_player_id != (*session)->user.user_id) {
    payload->set_accepted(false);
    payload->set_message("only host can invite players");
    connection->Send(response);
    return;
  }

  const auto target_account = message.invite_player_request().invitee_account();
  const auto seat_index = message.invite_player_request().seat_index();
  if (target_account.empty() || target_account == (*session)->user.account) {
    payload->set_accepted(false);
    payload->set_message("invalid invite target");
    connection->Send(response);
    return;
  }
  if (seat_index < 0 || seat_index >= static_cast<int>((*pending_room)->seats.size())) {
    payload->set_accepted(false);
    payload->set_message("invalid seat");
    connection->Send(response);
    return;
  }

  const auto target_user = user_repository_->FindByAccount(target_account);
  if (!target_user.has_value()) {
    payload->set_accepted(false);
    payload->set_message("player not found");
    connection->Send(response);
    return;
  }

  bool has_empty_seat = false;
  bool already_in_room = false;
  for (const auto& seat : (*pending_room)->seats) {
    if (seat.player_id.empty()) {
      has_empty_seat = true;
    }
    if (seat.player_id == target_user->user_id) {
      already_in_room = true;
    }
  }
  if (!has_empty_seat) {
    payload->set_accepted(false);
    payload->set_message("room is full");
    connection->Send(response);
    return;
  }
  if (already_in_room) {
    payload->set_accepted(false);
    payload->set_message("player already in room");
    connection->Send(response);
    return;
  }
  if (!(*pending_room)->seats[static_cast<std::size_t>(seat_index)].player_id.empty()) {
    payload->set_accepted(false);
    payload->set_message("seat is occupied");
    connection->Send(response);
    return;
  }
  if (invitation_id_by_invitee_.contains(target_user->user_id)) {
    payload->set_accepted(false);
    payload->set_message("player is handling another invitation");
    connection->Send(response);
    return;
  }

  const auto invitee_sessions = FindSessionsByUserId(target_user->user_id);
  if (invitee_sessions.empty()) {
    payload->set_accepted(false);
    payload->set_message("player is offline");
    connection->Send(response);
    return;
  }
  SessionState* invitee_session = nullptr;
  for (auto* candidate : invitee_sessions) {
    if (SessionCanJoinPendingRoom(*candidate, (*pending_room)->room_id)) {
      invitee_session = candidate;
      break;
    }
  }
  if (invitee_session == nullptr) {
    payload->set_accepted(false);
    payload->set_message("player is not available");
    connection->Send(response);
    return;
  }

  PendingInvitation invitation{
      .invitation_id = core::GenerateId("invite"),
      .room_id = (*pending_room)->room_id,
      .room_code = (*pending_room)->room_code,
      .inviter_player_id = (*session)->user.user_id,
      .inviter_account = (*session)->user.account,
      .inviter_nickname = (*session)->user.nickname,
      .invitee_player_id = invitee_session->user.user_id,
      .invitee_account = invitee_session->user.account,
      .invitee_nickname = invitee_session->user.nickname,
      .seat_index = seat_index,
      .created_at_ms = core::NowMs(),
  };
  invitations_by_id_[invitation.invitation_id] = invitation;
  invitation_id_by_invitee_[invitation.invitee_player_id] = invitation.invitation_id;

  payload->set_accepted(true);
  payload->set_message("invitation_sent");
  connection->Send(response);
  SendInvitationReceived(invitation);
}

void GameService::HandleRespondRoomInvitation(
    const std::shared_ptr<network::IConnection>& connection,
    const landlords::protocol::ClientMessage& message) {
  std::lock_guard lock(mutex_);
  const auto session = RequireSessionForConnection(connection, message.session_token());
  if (!session.has_value()) {
    SendError(
        connection, message.request_id(), landlords::protocol::ERROR_CODE_AUTH_FAILED, "login required");
    return;
  }

  landlords::protocol::ServerMessage response;
  response.set_request_id(message.request_id());
  auto* payload = response.mutable_respond_room_invitation_response();

  auto invitation_iterator =
      invitations_by_id_.find(message.respond_room_invitation_request().invitation_id());
  if (invitation_iterator == invitations_by_id_.end() ||
      invitation_iterator->second.invitee_player_id != (*session)->user.user_id) {
    payload->set_success(false);
    payload->set_message("invitation expired");
    connection->Send(response);
    return;
  }

  const PendingInvitation invitation = invitation_iterator->second;
  if (!message.respond_room_invitation_request().accept()) {
    payload->set_success(true);
    payload->set_message("invitation rejected");
    connection->Send(response);
    SendInvitationResult(
        invitation,
        landlords::protocol::INVITATION_RESULT_REJECTED,
        "player rejected the invitation");
    ClearInvitation(invitation.invitation_id);
    return;
  }

  auto pending_room = FindPendingRoom(invitation.room_id);
  if (!pending_room.has_value()) {
    payload->set_success(false);
    payload->set_message("room is no longer available");
    connection->Send(response);
    SendInvitationResult(
        invitation,
        landlords::protocol::INVITATION_RESULT_EXPIRED,
        "room is no longer available");
    ClearInvitation(invitation.invitation_id);
    return;
  }
  if (!SessionCanJoinPendingRoom(**session, invitation.room_id)) {
    payload->set_success(false);
    payload->set_message("player is currently in another room");
    connection->Send(response);
    SendInvitationResult(
        invitation,
        landlords::protocol::INVITATION_RESULT_FAILED,
        "player is currently in another room");
    ClearInvitation(invitation.invitation_id);
    return;
  }

  int seat_index = invitation.seat_index;
  if (seat_index < 0 || seat_index >= static_cast<int>((*pending_room)->seats.size())) {
    seat_index = -1;
  }
  if (seat_index == -1) {
    for (int index = 0; index < static_cast<int>((*pending_room)->seats.size()); ++index) {
      const auto& seat = (*pending_room)->seats[static_cast<std::size_t>(index)];
      if (seat.player_id == (*session)->user.user_id) {
        seat_index = index;
        break;
      }
      if (seat_index == -1 && seat.player_id.empty()) {
        seat_index = index;
      }
    }
  } else if (!(*pending_room)->seats[static_cast<std::size_t>(seat_index)].player_id.empty() &&
             (*pending_room)->seats[static_cast<std::size_t>(seat_index)].player_id !=
                 (*session)->user.user_id) {
    seat_index = -1;
  }
  if (seat_index == -1) {
    payload->set_success(false);
    payload->set_message("room is full");
    connection->Send(response);
    SendInvitationResult(
        invitation, landlords::protocol::INVITATION_RESULT_EXPIRED, "room is full");
    ClearInvitation(invitation.invitation_id);
    return;
  }

  if (!(*session)->room_id.empty() && (*session)->room_id != invitation.room_id) {
    const std::string previous_room_id = (*session)->room_id;
    if (pending_rooms_by_id_.contains(previous_room_id)) {
      RemoveSessionFromPendingRoom(**session, previous_room_id);
      pending_room = FindPendingRoom(invitation.room_id);
      if (!pending_room.has_value()) {
        payload->set_success(false);
        payload->set_message("room is no longer available");
        connection->Send(response);
        SendInvitationResult(
            invitation,
            landlords::protocol::INVITATION_RESULT_EXPIRED,
            "room is no longer available");
        ClearInvitation(invitation.invitation_id);
        return;
      }
    } else {
      (*session)->room_id.clear();
    }
  }

  auto& seat = (*pending_room)->seats[static_cast<std::size_t>(seat_index)];
  seat.player_id = (*session)->user.user_id;
  seat.display_name = DisplayNameFor((*session)->user);
  seat.is_bot = false;
  seat.ready = false;
  seat.bot_difficulty = landlords::protocol::BOT_DIFFICULTY_NORMAL;
  (*session)->room_id = invitation.room_id;

  payload->set_success(true);
  payload->set_message("room_joined");
  *payload->mutable_snapshot() =
      BuildPendingRoomSnapshot(**pending_room, (*session)->user.user_id);
  connection->Send(response);

  SendInvitationResult(
      invitation,
      landlords::protocol::INVITATION_RESULT_ACCEPTED,
      "player joined the room");
  ClearInvitation(invitation.invitation_id);
  SendPendingSnapshotToRoom(**pending_room);

  const bool room_full = std::none_of(
      (*pending_room)->seats.begin(),
      (*pending_room)->seats.end(),
      [](const PendingSeat& candidate) { return candidate.player_id.empty(); });
  if (room_full) {
    ExpireInvitationsForRoom(invitation.room_id, "room is full");
  }
}

void GameService::HandleRoomReady(const std::shared_ptr<network::IConnection>& connection,
                                  const landlords::protocol::ClientMessage& message) {
  std::lock_guard lock(mutex_);
  const auto session = RequireSessionForConnection(connection, message.session_token());
  if (!session.has_value()) {
    SendError(connection, message.request_id(), landlords::protocol::ERROR_CODE_AUTH_FAILED, "login required");
    return;
  }

  auto pending_room = FindPendingRoom(message.room_ready_request().room_id());
  if (!pending_room.has_value()) {
    SendError(connection, message.request_id(), landlords::protocol::ERROR_CODE_MATCH_STATE_INVALID, "room already started");
    return;
  }

  bool found_seat = false;
  for (auto& seat : (*pending_room)->seats) {
    if (seat.player_id != (*session)->user.user_id) {
      continue;
    }
    seat.ready = message.room_ready_request().ready();
    found_seat = true;
    break;
  }
  if (!found_seat) {
    SendError(connection, message.request_id(), landlords::protocol::ERROR_CODE_AUTH_FAILED, "player not in room");
    return;
  }

  bool full = true;
  bool ready = true;
  for (const auto& seat : (*pending_room)->seats) {
    if (seat.player_id.empty()) {
      full = false;
      ready = false;
      break;
    }
    if (!seat.ready) {
      ready = false;
    }
  }

  landlords::protocol::ServerMessage response;
  response.set_request_id(message.request_id());
  auto* operation = response.mutable_operation_response();
  operation->set_success(true);

  if (full && ready) {
    const auto room_id = (*pending_room)->room_id;
    PendingRoom room_to_start = **pending_room;
    operation->set_message("room_started");
    StartPreparedRoom(room_to_start);
    auto started_room = rooms_by_id_.find(room_id);
    if (started_room != rooms_by_id_.end()) {
      *operation->mutable_snapshot() =
          started_room->second->BuildSnapshotFor((*session)->user.user_id);
    }
    connection->Send(response);
    return;
  }

  operation->set_message("ready_updated");
  *operation->mutable_snapshot() =
      BuildPendingRoomSnapshot(**pending_room, (*session)->user.user_id);
  connection->Send(response);
  SendPendingSnapshotToRoom(**pending_room);
}

void GameService::HandleAddBot(const std::shared_ptr<network::IConnection>& connection,
                               const landlords::protocol::ClientMessage& message) {
  std::lock_guard lock(mutex_);
  const auto session = RequireSessionForConnection(connection, message.session_token());
  if (!session.has_value()) {
    SendError(connection, message.request_id(), landlords::protocol::ERROR_CODE_AUTH_FAILED, "login required");
    return;
  }

  auto pending_room = FindPendingRoom(message.add_bot_request().room_id());
  if (!pending_room.has_value()) {
    SendError(connection, message.request_id(), landlords::protocol::ERROR_CODE_NOT_FOUND, "room not found");
    return;
  }
  if ((*pending_room)->owner_player_id != (*session)->user.user_id) {
    SendError(connection, message.request_id(), landlords::protocol::ERROR_CODE_AUTH_FAILED, "only host can add bot");
    return;
  }

  int seat_index = message.add_bot_request().seat_index();
  if (seat_index < 0 || seat_index >= static_cast<int>((*pending_room)->seats.size())) {
    SendError(connection,
              message.request_id(),
              landlords::protocol::ERROR_CODE_INVALID_REQUEST,
              "invalid seat");
    return;
  }
  if (!(*pending_room)->seats[static_cast<std::size_t>(seat_index)].player_id.empty()) {
    SendError(connection, message.request_id(), landlords::protocol::ERROR_CODE_MATCH_STATE_INVALID, "room is full");
    return;
  }

  const auto difficulty = NormalizeBotDifficulty(message.add_bot_request().bot_difficulty());
  (*pending_room)->seats[static_cast<std::size_t>(seat_index)] = PendingSeat{
      .player_id = core::GenerateId("bot"),
      .display_name = BotDisplayName(difficulty),
      .is_bot = true,
      .ready = true,
      .bot_difficulty = difficulty,
  };

  landlords::protocol::ServerMessage response;
  response.set_request_id(message.request_id());
  auto* operation = response.mutable_operation_response();
  operation->set_success(true);

  bool full = true;
  bool ready = true;
  for (const auto& seat : (*pending_room)->seats) {
    if (seat.player_id.empty()) {
      full = false;
      ready = false;
      break;
    }
    if (!seat.ready) {
      ready = false;
    }
  }

  if (full && ready) {
    const auto room_id = (*pending_room)->room_id;
    PendingRoom room_to_start = **pending_room;
    operation->set_message("room_started");
    StartPreparedRoom(room_to_start);
    auto started_room = rooms_by_id_.find(room_id);
    if (started_room != rooms_by_id_.end()) {
      *operation->mutable_snapshot() =
          started_room->second->BuildSnapshotFor((*session)->user.user_id);
    }
    connection->Send(response);
    return;
  }

  operation->set_message("bot_added");
  *operation->mutable_snapshot() =
      BuildPendingRoomSnapshot(**pending_room, (*session)->user.user_id);
  connection->Send(response);
  SendPendingSnapshotToRoom(**pending_room);

  const bool room_full = std::none_of(
      (*pending_room)->seats.begin(),
      (*pending_room)->seats.end(),
      [](const PendingSeat& seat) { return seat.player_id.empty(); });
  if (room_full) {
    ExpireInvitationsForRoom((*pending_room)->room_id, "room is full");
  }
}

void GameService::HandleRemovePlayer(const std::shared_ptr<network::IConnection>& connection,
                                     const landlords::protocol::ClientMessage& message) {
  std::lock_guard lock(mutex_);
  const auto session = RequireSessionForConnection(connection, message.session_token());
  if (!session.has_value()) {
    SendError(connection, message.request_id(), landlords::protocol::ERROR_CODE_AUTH_FAILED, "login required");
    return;
  }

  auto pending_room = FindPendingRoom(message.remove_player_request().room_id());
  if (!pending_room.has_value()) {
    SendError(connection, message.request_id(), landlords::protocol::ERROR_CODE_NOT_FOUND, "room not found");
    return;
  }
  if ((*pending_room)->owner_player_id != (*session)->user.user_id) {
    SendError(connection, message.request_id(), landlords::protocol::ERROR_CODE_AUTH_FAILED, "only host can remove players");
    return;
  }
  if (message.remove_player_request().player_id() == (*session)->user.user_id) {
    SendError(connection,
              message.request_id(),
              landlords::protocol::ERROR_CODE_MATCH_STATE_INVALID,
              "cannot remove yourself");
    return;
  }

  bool removed = false;
  bool removed_bot = false;
  std::string removed_player_id;
  for (auto& seat : (*pending_room)->seats) {
    if (seat.player_id != message.remove_player_request().player_id()) {
      continue;
    }
    removed_bot = seat.is_bot;
    removed_player_id = seat.player_id;
    seat = PendingSeat{};
    removed = true;
    break;
  }
  if (!removed) {
    SendError(connection, message.request_id(), landlords::protocol::ERROR_CODE_NOT_FOUND, "player not found");
    return;
  }

  landlords::protocol::ServerMessage response;
  response.set_request_id(message.request_id());
  auto* operation = response.mutable_operation_response();
  operation->set_success(true);
  operation->set_message("player_removed");
  *operation->mutable_snapshot() =
      BuildPendingRoomSnapshot(**pending_room, (*session)->user.user_id);
  connection->Send(response);

  if (!removed_bot) {
    const auto removed_sessions = FindSessionsByUserId(removed_player_id);
    for (auto* removed_session : removed_sessions) {
      if (removed_session == nullptr) {
        continue;
      }
      removed_session->room_id.clear();
      if (const auto removed_connection = removed_session->connection.lock()) {
        landlords::protocol::ServerMessage push;
        *push.mutable_room_snapshot() =
            BuildPendingRoomSnapshot(**pending_room, removed_player_id);
        removed_connection->Send(push);
      }
    }
  }

  ExpireInvitationsForRoom((*pending_room)->room_id, "room seats changed");
  SendPendingSnapshotToRoom(**pending_room);
}

void GameService::HandlePlay(const std::shared_ptr<network::IConnection>& connection,
                             const landlords::protocol::ClientMessage& message) {
  std::lock_guard lock(mutex_);
  const auto session = RequireSessionForConnection(connection, message.session_token());
  if (!session.has_value()) {
    SendError(connection, message.request_id(), landlords::protocol::ERROR_CODE_AUTH_FAILED, "login required");
    return;
  }

  std::vector<std::string> card_ids(message.play_cards_request().card_ids().begin(),
                                    message.play_cards_request().card_ids().end());
  const bool cancel_match_request =
      card_ids.size() == 1U && card_ids.front() == kCancelMatchCommand;
  const bool suggestion_request =
      card_ids.size() == 1U && card_ids.front() == "__hint__";
  const bool presentation_ack_request =
      card_ids.size() == 1U && card_ids.front().rfind("__presented__:", 0) == 0U;
  const bool managed_toggle =
      card_ids.size() == 1U &&
      (card_ids.front() == "auto:on" || card_ids.front() == "auto:off");
  if (cancel_match_request) {
    landlords::protocol::ServerMessage response;
    response.set_request_id(message.request_id());
    auto* operation = response.mutable_operation_response();
    operation->set_success(RemoveWaitingToken((*session)->session_token));
    operation->set_message(operation->success() ? "match cancelled" : "match not pending");
    connection->Send(response);
    LANDLORDS_LOG(landlords::core::LogLevel::kInfo,
                  "game_service",
                  "cancel match user=" << (*session)->user.user_id
                                       << " removed=" << (operation->success() ? "true" : "false"));
    return;
  }

  auto room_iterator = rooms_by_id_.find(message.play_cards_request().room_id());
  if (room_iterator == rooms_by_id_.end()) {
    if (pending_rooms_by_id_.contains(message.play_cards_request().room_id())) {
      SendError(connection,
                message.request_id(),
                landlords::protocol::ERROR_CODE_MATCH_STATE_INVALID,
                "room_not_started");
      return;
    }
    SendError(connection, message.request_id(), landlords::protocol::ERROR_CODE_NOT_FOUND, "room not found");
    return;
  }

  if (suggestion_request) {
    const auto suggestion =
        room_iterator->second->SuggestCardIds((*session)->user.user_id);
    if (!suggestion.has_value()) {
      SendError(connection,
                message.request_id(),
                landlords::protocol::ERROR_CODE_GAME_STATE_INVALID,
                "hint_not_available");
      return;
    }

    landlords::protocol::ServerMessage response;
    response.set_request_id(message.request_id());
    auto* operation = response.mutable_operation_response();
    operation->set_success(true);
    operation->set_message("suggest:");
    if (!suggestion->empty()) {
      std::string payload;
      for (std::size_t index = 0; index < suggestion->size(); ++index) {
        if (index > 0) {
          payload.append(",");
        }
        payload.append((*suggestion)[index]);
      }
      operation->set_message("suggest:" + payload);
    }
    *operation->mutable_snapshot() =
        room_iterator->second->BuildSnapshotFor((*session)->user.user_id);
    connection->Send(response);
    LANDLORDS_LOG(landlords::core::LogLevel::kInfo,
                  "game_service",
                  "hint handled room=" << room_iterator->second->id()
                                       << " user=" << (*session)->user.user_id
                                       << " cards=" << suggestion->size());
    return;
  }

  std::optional<std::string> error;
  if (presentation_ack_request) {
    error = room_iterator->second->AcknowledgePresentation(
        (*session)->user.user_id, card_ids.front().substr(std::string("__presented__:").size()));
  } else if (card_ids.size() == 1U && card_ids.front().rfind("bid:", 0) == 0U) {
    const int score = std::stoi(card_ids.front().substr(4));
    error = room_iterator->second->CallScore((*session)->user.user_id, score);
  } else if (card_ids.size() == 1U && card_ids.front() == "auto:on") {
    error = room_iterator->second->SetManaged((*session)->user.user_id, true);
  } else if (card_ids.size() == 1U && card_ids.front() == "auto:off") {
    error = room_iterator->second->SetManaged((*session)->user.user_id, false);
  } else {
    error = room_iterator->second->PlayCards((*session)->user.user_id, card_ids);
  }
  if (error.has_value()) {
    SendError(connection, message.request_id(), landlords::protocol::ERROR_CODE_GAME_STATE_INVALID, *error);
    return;
  }

  LANDLORDS_LOG(landlords::core::LogLevel::kInfo,
                "game_service",
                "play handled room=" << room_iterator->second->id()
                                     << " user=" << (*session)->user.user_id
                                     << " cards=" << card_ids.size()
                                     << (presentation_ack_request ? " ack=presentation" : ""));

  PersistFinishedRoomScores(*room_iterator->second);
  landlords::protocol::ServerMessage response;
  response.set_request_id(message.request_id());
  auto* operation = response.mutable_operation_response();
  operation->set_success(true);
  operation->set_message(presentation_ack_request ? "presentation ack" : "play success");
  *operation->mutable_snapshot() = room_iterator->second->BuildSnapshotFor((*session)->user.user_id);
  connection->Send(response);
  SendSnapshotToRoom(*room_iterator->second);
}

void GameService::HandlePass(const std::shared_ptr<network::IConnection>& connection,
                             const landlords::protocol::ClientMessage& message) {
  std::lock_guard lock(mutex_);
  const auto session = RequireSessionForConnection(connection, message.session_token());
  if (!session.has_value()) {
    SendError(connection, message.request_id(), landlords::protocol::ERROR_CODE_AUTH_FAILED, "login required");
    return;
  }

  auto room_iterator = rooms_by_id_.find(message.pass_request().room_id());
  if (room_iterator == rooms_by_id_.end()) {
    if (pending_rooms_by_id_.contains(message.pass_request().room_id())) {
      SendError(connection,
                message.request_id(),
                landlords::protocol::ERROR_CODE_MATCH_STATE_INVALID,
                "room_not_started");
      return;
    }
    SendError(connection, message.request_id(), landlords::protocol::ERROR_CODE_NOT_FOUND, "room not found");
    return;
  }

  auto error = room_iterator->second->BuildSnapshotFor((*session)->user.user_id).phase() ==
                       landlords::protocol::ROOM_PHASE_WAITING
                   ? room_iterator->second->CallScore((*session)->user.user_id, 0)
                   : room_iterator->second->Pass((*session)->user.user_id);
  if (error.has_value()) {
    SendError(connection, message.request_id(), landlords::protocol::ERROR_CODE_GAME_STATE_INVALID, *error);
    return;
  }

  LANDLORDS_LOG(landlords::core::LogLevel::kInfo,
                "game_service",
                "pass handled room=" << room_iterator->second->id()
                                     << " user=" << (*session)->user.user_id);

  PersistFinishedRoomScores(*room_iterator->second);
  landlords::protocol::ServerMessage response;
  response.set_request_id(message.request_id());
  auto* operation = response.mutable_operation_response();
  operation->set_success(true);
  operation->set_message("pass success");
  *operation->mutable_snapshot() = room_iterator->second->BuildSnapshotFor((*session)->user.user_id);
  connection->Send(response);
  SendSnapshotToRoom(*room_iterator->second);
}

void GameService::HandleReconnect(const std::shared_ptr<network::IConnection>& connection,
                                  const landlords::protocol::ClientMessage& message) {
  std::lock_guard lock(mutex_);
  const auto session = RequireSessionForConnection(connection, message.session_token());
  if (!session.has_value()) {
    SendError(connection, message.request_id(), landlords::protocol::ERROR_CODE_AUTH_FAILED, "login required");
    return;
  }

  const std::string room_id = message.reconnect_request().room_id().empty()
                                  ? (*session)->room_id
                                  : message.reconnect_request().room_id();
  if (room_id.empty() || (*session)->room_id != room_id) {
    SendError(connection, message.request_id(), landlords::protocol::ERROR_CODE_NOT_FOUND, "room not found");
    return;
  }
  if (auto pending_room = FindPendingRoom(room_id); pending_room.has_value()) {
    const bool player_in_pending_room = std::any_of(
        (*pending_room)->seats.begin(),
        (*pending_room)->seats.end(),
        [&](const PendingSeat& seat) { return seat.player_id == (*session)->user.user_id; });
    if (!player_in_pending_room) {
      (*session)->room_id.clear();
      SendError(connection,
                message.request_id(),
                landlords::protocol::ERROR_CODE_NOT_FOUND,
                "room not found");
      return;
    }
    (*session)->room_id = room_id;
    landlords::protocol::ServerMessage response;
    response.set_request_id(message.request_id());
    *response.mutable_room_snapshot() =
        BuildPendingRoomSnapshot(**pending_room, (*session)->user.user_id);
    connection->Send(response);
    return;
  }
  auto room_iterator = rooms_by_id_.find(room_id);
  if (room_iterator == rooms_by_id_.end()) {
    SendError(connection, message.request_id(), landlords::protocol::ERROR_CODE_NOT_FOUND, "room not found");
    return;
  }

  (*session)->room_id = room_id;
  landlords::protocol::ServerMessage response;
  response.set_request_id(message.request_id());
  *response.mutable_room_snapshot() = room_iterator->second->BuildSnapshotFor((*session)->user.user_id);
  connection->Send(response);
}

void GameService::HandleHeartbeat(const std::shared_ptr<network::IConnection>& connection,
                                  const landlords::protocol::ClientMessage& message) {
  if (!message.session_token().empty()) {
    std::lock_guard lock(mutex_);
    if (const auto session = RequireSession(message.session_token()); session.has_value()) {
      BindSessionConnection(**session, connection);
    }
  }
  landlords::protocol::ServerMessage response;
  response.set_request_id(message.request_id());
  response.mutable_heartbeat_response()->set_server_time_ms(core::NowMs());
  connection->Send(response);
}

void GameService::SendError(const std::shared_ptr<network::IConnection>& connection,
                            const std::string& request_id,
                            landlords::protocol::ErrorCode code,
                            const std::string& message) {
  LANDLORDS_LOG(landlords::core::LogLevel::kWarn,
                "game_service",
                "send error request_id=" << request_id << " code=" << static_cast<int>(code)
                                         << " message=" << message);
  landlords::protocol::ServerMessage response;
  response.set_request_id(request_id);
  auto* payload = response.mutable_error_response();
  payload->set_code(code);
  payload->set_message(message);
  connection->Send(response);
}

void GameService::BindSessionConnection(
    SessionState& session,
    const std::shared_ptr<network::IConnection>& connection) {
  if (const auto existing = session.connection.lock();
      existing != nullptr && existing->connection_id() == connection->connection_id()) {
    return;
  }
  session.connection = connection;
}

void GameService::RefreshSessionUser(SessionState& session) {
  const auto latest = user_repository_->FindByUserId(session.user.user_id);
  if (latest.has_value()) {
    session.user = *latest;
  }
}

void GameService::RefreshSessionsForUser(const core::UserRecord& user) {
  for (auto& [token, session] : sessions_by_token_) {
    static_cast<void>(token);
    if (session.user.user_id == user.user_id) {
      session.user = user;
    }
  }
}

landlords::protocol::FriendRequestEntry GameService::BuildFriendRequestEntry(
    const core::FriendRequestRecord& request) const {
  landlords::protocol::FriendRequestEntry entry;
  entry.set_request_id(request.request_id);
  entry.set_requester_user_id(request.requester_user_id);
  entry.set_receiver_user_id(request.receiver_user_id);
  entry.set_status(request.status);
  entry.set_created_at_ms(request.created_at_ms);
  entry.set_updated_at_ms(request.updated_at_ms);

  if (const auto requester = user_repository_->FindByUserId(request.requester_user_id);
      requester.has_value()) {
    entry.set_requester_account(requester->account);
    entry.set_requester_nickname(requester->nickname);
  }
  if (const auto receiver = user_repository_->FindByUserId(request.receiver_user_id);
      receiver.has_value()) {
    entry.set_receiver_account(receiver->account);
    entry.set_receiver_nickname(receiver->nickname);
  }
  return entry;
}

landlords::protocol::FriendCenterSnapshot GameService::BuildFriendCenterSnapshot(
    SessionState& session) {
  RefreshSessionUser(session);

  landlords::protocol::FriendCenterSnapshot snapshot;
  const auto friends = user_repository_->ListUsersByIds(session.user.friend_user_ids);
  std::vector<landlords::protocol::OnlineUser> payload_users;
  payload_users.reserve(friends.size());
  for (const auto& user : friends) {
    payload_users.push_back(BuildOnlineUser(user));
  }
  std::sort(payload_users.begin(),
            payload_users.end(),
            [](const landlords::protocol::OnlineUser& left,
               const landlords::protocol::OnlineUser& right) {
              if (left.online() != right.online()) {
                return left.online() && !right.online();
              }
              const auto left_name = left.nickname().empty() ? left.account() : left.nickname();
              const auto right_name = right.nickname().empty() ? right.account() : right.nickname();
              if (left_name == right_name) {
                return left.account() < right.account();
              }
              return left_name < right_name;
            });
  for (const auto& user : payload_users) {
    *snapshot.add_friends() = user;
  }

  auto requests = friend_request_repository_->ListForUser(session.user.user_id);
  std::sort(requests.begin(),
            requests.end(),
            [](const core::FriendRequestRecord& left,
               const core::FriendRequestRecord& right) {
              if (left.updated_at_ms != right.updated_at_ms) {
                return left.updated_at_ms > right.updated_at_ms;
              }
              return left.created_at_ms > right.created_at_ms;
            });

  std::int32_t pending_request_count = 0;
  for (const auto& request : requests) {
    const bool incoming = request.receiver_user_id == session.user.user_id;
    const bool pending =
        request.status == landlords::protocol::FRIEND_REQUEST_STATUS_PENDING;
    const auto entry = BuildFriendRequestEntry(request);
    if (incoming && pending) {
      *snapshot.add_pending_requests() = entry;
      ++pending_request_count;
      continue;
    }
    *snapshot.add_history_requests() = entry;
  }
  snapshot.set_pending_request_count(pending_request_count);
  return snapshot;
}

void GameService::PushFriendCenterUpdateToUser(const std::string& user_id) {
  const auto sessions = FindSessionsByUserId(user_id);
  for (auto* session : sessions) {
    if (session == nullptr) {
      continue;
    }
    if (const auto connection = session->connection.lock()) {
      landlords::protocol::ServerMessage push;
      *push.mutable_friend_center_push()->mutable_snapshot() =
          BuildFriendCenterSnapshot(*session);
      connection->Send(push);
    }
  }
}

void GameService::PushFriendCenterUpdateToUsers(
    const std::vector<std::string>& user_ids) {
  std::unordered_set<std::string> dedup(user_ids.begin(), user_ids.end());
  for (const auto& user_id : dedup) {
    if (!user_id.empty()) {
      PushFriendCenterUpdateToUser(user_id);
    }
  }
}

bool GameService::AreFriends(const core::UserRecord& user,
                             const std::string& friend_user_id) const {
  return std::find(user.friend_user_ids.begin(),
                   user.friend_user_ids.end(),
                   friend_user_id) != user.friend_user_ids.end();
}

void GameService::LinkFriends(core::UserRecord& left, core::UserRecord& right) {
  if (!AreFriends(left, right.user_id)) {
    left.friend_user_ids.push_back(right.user_id);
  }
  if (!AreFriends(right, left.user_id)) {
    right.friend_user_ids.push_back(left.user_id);
  }
}

void GameService::UnlinkFriends(core::UserRecord& left, core::UserRecord& right) {
  left.friend_user_ids.erase(
      std::remove(left.friend_user_ids.begin(),
                  left.friend_user_ids.end(),
                  right.user_id),
      left.friend_user_ids.end());
  right.friend_user_ids.erase(
      std::remove(right.friend_user_ids.begin(),
                  right.friend_user_ids.end(),
                  left.user_id),
      right.friend_user_ids.end());
}

void GameService::PersistFinishedRoomScores(const game::Room& room) {
  if (!room.finished()) {
    return;
  }
  for (const auto& player : room.players()) {
    if (player.is_bot) {
      continue;
    }
    auto record = user_repository_->FindByUserId(player.player_id);
    if (!record.has_value()) {
      continue;
    }
    record->total_score += player.round_score;
    const bool won = player.round_score > 0;
    if (player.is_landlord) {
      record->landlord_games += 1;
      if (won) {
        record->landlord_wins += 1;
      }
    } else {
      record->farmer_games += 1;
      if (won) {
        record->farmer_wins += 1;
      }
    }
    user_repository_->UpdateUser(*record);
    for (auto& [token, session] : sessions_by_token_) {
      if (session.user.user_id == player.player_id) {
        session.user = *record;
      }
    }
  }
}

void GameService::SendSnapshotToRoom(const game::Room& room) {
  for (const auto& player : room.players()) {
    for (auto& [token, session] : sessions_by_token_) {
      if (session.user.user_id != player.player_id) {
        continue;
      }
      if (const auto connection = session.connection.lock()) {
        landlords::protocol::ServerMessage push;
        *push.mutable_room_snapshot() = room.BuildSnapshotFor(player.player_id);
        connection->Send(push);
      }
    }
  }
}

void GameService::SendInvitationReceived(const PendingInvitation& invitation) {
  const auto invitee_sessions = FindSessionsByUserId(invitation.invitee_player_id);
  if (invitee_sessions.empty()) {
    return;
  }
  for (const auto* invitee_session : invitee_sessions) {
    if (invitee_session == nullptr) {
      continue;
    }
    if (const auto connection = invitee_session->connection.lock()) {
      landlords::protocol::ServerMessage push;
      auto* payload = push.mutable_room_invitation_push();
      payload->set_invitation_id(invitation.invitation_id);
      payload->set_room_id(invitation.room_id);
      payload->set_room_code(invitation.room_code);
      payload->set_inviter_user_id(invitation.inviter_player_id);
      payload->set_inviter_account(invitation.inviter_account);
      payload->set_inviter_nickname(invitation.inviter_nickname);
      payload->set_seat_index(invitation.seat_index);
      connection->Send(push);
    }
  }
}

void GameService::SendInvitationResult(const PendingInvitation& invitation,
                                       landlords::protocol::InvitationResult result,
                                       const std::string& detail) {
  const auto inviter_sessions = FindSessionsByUserId(invitation.inviter_player_id);
  if (inviter_sessions.empty()) {
    return;
  }
  for (const auto* inviter_session : inviter_sessions) {
    if (inviter_session == nullptr) {
      continue;
    }
    if (const auto connection = inviter_session->connection.lock()) {
      landlords::protocol::ServerMessage push;
      auto* payload = push.mutable_room_invitation_result_push();
      payload->set_invitation_id(invitation.invitation_id);
      payload->set_result(result);
      payload->set_invitee_user_id(invitation.invitee_player_id);
      payload->set_invitee_account(invitation.invitee_account);
      payload->set_invitee_nickname(invitation.invitee_nickname);
      payload->set_message(detail);
      connection->Send(push);
    }
  }
}

void GameService::ClearInvitation(const std::string& invitation_id) {
  auto iterator = invitations_by_id_.find(invitation_id);
  if (iterator == invitations_by_id_.end()) {
    return;
  }
  invitation_id_by_invitee_.erase(iterator->second.invitee_player_id);
  invitations_by_id_.erase(iterator);
}

void GameService::ExpireInvitationsForRoom(const std::string& room_id,
                                           const std::string& detail) {
  std::vector<std::string> invitation_ids;
  invitation_ids.reserve(invitations_by_id_.size());
  for (const auto& [invitation_id, invitation] : invitations_by_id_) {
    if (invitation.room_id == room_id) {
      invitation_ids.push_back(invitation_id);
    }
  }

  for (const auto& invitation_id : invitation_ids) {
    auto iterator = invitations_by_id_.find(invitation_id);
    if (iterator == invitations_by_id_.end()) {
      continue;
    }
    SendInvitationResult(
        iterator->second, landlords::protocol::INVITATION_RESULT_EXPIRED, detail);
    ClearInvitation(invitation_id);
  }
}

void GameService::ExpireStaleInvitations(std::int64_t now_ms) {
  std::vector<std::string> expired_invitation_ids;
  expired_invitation_ids.reserve(invitations_by_id_.size());
  for (const auto& [invitation_id, invitation] : invitations_by_id_) {
    if (now_ms - invitation.created_at_ms >= kInvitationTimeoutMs) {
      expired_invitation_ids.push_back(invitation_id);
    }
  }

  for (const auto& invitation_id : expired_invitation_ids) {
    auto iterator = invitations_by_id_.find(invitation_id);
    if (iterator == invitations_by_id_.end()) {
      continue;
    }
    SendInvitationResult(iterator->second,
                         landlords::protocol::INVITATION_RESULT_EXPIRED,
                         "invitation timed out");
    ClearInvitation(invitation_id);
  }
}

std::shared_ptr<ai::IBotStrategy> GameService::ResolveBotStrategy(
    landlords::protocol::BotDifficulty difficulty) const {
  switch (NormalizeBotDifficulty(difficulty)) {
    case landlords::protocol::BOT_DIFFICULTY_EASY:
      return easy_bot_strategy_ != nullptr ? easy_bot_strategy_ : standard_bot_strategy_;
    case landlords::protocol::BOT_DIFFICULTY_HARD:
      return hard_bot_strategy_ != nullptr ? hard_bot_strategy_ : standard_bot_strategy_;
    case landlords::protocol::BOT_DIFFICULTY_NORMAL:
    case landlords::protocol::BOT_DIFFICULTY_UNSPECIFIED:
      return standard_bot_strategy_;
  }
  return standard_bot_strategy_;
}

landlords::protocol::BotDifficulty GameService::NormalizeBotDifficulty(
    landlords::protocol::BotDifficulty difficulty) const {
  switch (difficulty) {
    case landlords::protocol::BOT_DIFFICULTY_EASY:
    case landlords::protocol::BOT_DIFFICULTY_NORMAL:
    case landlords::protocol::BOT_DIFFICULTY_HARD:
      return difficulty;
    case landlords::protocol::BOT_DIFFICULTY_UNSPECIFIED:
      return landlords::protocol::BOT_DIFFICULTY_NORMAL;
  }
  return landlords::protocol::BOT_DIFFICULTY_NORMAL;
}

void GameService::CreateBotRoom(SessionState& session,
                                landlords::protocol::BotDifficulty difficulty) {
  difficulty = NormalizeBotDifficulty(difficulty);
  std::vector<core::PlayerState> players;
  players.push_back(core::PlayerState{
      .player_id = session.user.user_id,
      .display_name = DisplayNameFor(session.user),
      .is_bot = false,
  });
  players.push_back(core::PlayerState{
      .player_id = core::GenerateId("bot"),
      .display_name = BotDisplayName(difficulty),
      .is_bot = true,
  });
  players.push_back(core::PlayerState{
      .player_id = core::GenerateId("bot"),
      .display_name = BotDisplayName(difficulty),
      .is_bot = true,
  });

  const std::string room_id = core::GenerateId("room");
  auto room = std::make_shared<game::Room>(
      room_id,
      landlords::protocol::MATCH_MODE_VS_BOT,
      players,
      difficulty,
      ResolveBotStrategy(difficulty));
  session.room_id = room_id;
  rooms_by_id_[room_id] = room;
  LANDLORDS_LOG(landlords::core::LogLevel::kInfo,
                "game_service",
                "created bot room room=" << room_id
                                         << " user=" << session.user.user_id
                                         << " difficulty="
                                         << static_cast<int>(difficulty));

  if (const auto connection = session.connection.lock()) {
    landlords::protocol::ServerMessage found;
    auto* push = found.mutable_match_found_push();
    push->set_room_id(room_id);
    push->set_mode(landlords::protocol::MATCH_MODE_VS_BOT);
    for (const auto& player : room->players()) {
      auto* target = push->add_players();
      target->set_player_id(player.player_id);
      target->set_display_name(player.display_name);
      target->set_is_bot(player.is_bot);
    }
    connection->Send(found);

    landlords::protocol::ServerMessage snapshot;
    *snapshot.mutable_room_snapshot() = room->BuildSnapshotFor(session.user.user_id);
    connection->Send(snapshot);
  }
}

void GameService::MaybeCreatePvpRoom() {
  if (pvp_waiting_tokens_.size() < 3U) {
    return;
  }

  std::vector<std::string> selected_tokens(pvp_waiting_tokens_.begin(), pvp_waiting_tokens_.begin() + 3);
  pvp_waiting_tokens_.erase(pvp_waiting_tokens_.begin(), pvp_waiting_tokens_.begin() + 3);

  std::vector<core::PlayerState> players;
  players.reserve(selected_tokens.size());
  LANDLORDS_LOG(landlords::core::LogLevel::kInfo,
                "game_service",
                "created free-match room players=" << selected_tokens.size());

  for (std::size_t index = 0; index < selected_tokens.size(); ++index) {
    auto iterator = sessions_by_token_.find(selected_tokens[index]);
    if (iterator == sessions_by_token_.end()) {
      return;
    }
    players.push_back(core::PlayerState{
        .player_id = iterator->second.user.user_id,
        .display_name = DisplayNameFor(iterator->second.user),
        .is_bot = false,
    });
  }

  const std::string room_id = core::GenerateId("room");
  auto room = std::make_shared<game::Room>(
      room_id,
      landlords::protocol::MATCH_MODE_PVP,
      players,
      landlords::protocol::BOT_DIFFICULTY_NORMAL,
      standard_bot_strategy_);
  rooms_by_id_[room_id] = room;

  for (const auto& token : selected_tokens) {
    auto& session = sessions_by_token_.at(token);
    session.room_id = room_id;
    if (const auto connection = session.connection.lock()) {
      landlords::protocol::ServerMessage found;
      auto* push = found.mutable_match_found_push();
      push->set_room_id(room_id);
      push->set_mode(landlords::protocol::MATCH_MODE_PVP);
      for (std::size_t index = 0; index < players.size(); ++index) {
        auto* target = push->add_players();
        target->set_player_id(players[index].player_id);
        target->set_display_name(players[index].display_name);
        target->set_is_bot(players[index].is_bot);
        target->set_seat_index(static_cast<int>(index));
        target->set_ready(true);
        target->set_occupied(true);
      }
      connection->Send(found);

      landlords::protocol::ServerMessage snapshot;
      *snapshot.mutable_room_snapshot() = room->BuildSnapshotFor(session.user.user_id);
      connection->Send(snapshot);
    }
  }
}

bool GameService::RemoveWaitingToken(const std::string& session_token) {
  const auto original_size = pvp_waiting_tokens_.size();
  pvp_waiting_tokens_.erase(
      std::remove(pvp_waiting_tokens_.begin(), pvp_waiting_tokens_.end(), session_token),
      pvp_waiting_tokens_.end());
  return pvp_waiting_tokens_.size() != original_size;
}

void GameService::TickRoomsLoop() {
  while (running_) {
    {
      std::lock_guard lock(mutex_);
      const auto now_ms = core::NowMs();
      ExpireStaleInvitations(now_ms);
      for (auto& [room_id, room] : rooms_by_id_) {
        if (room->TickManaged(now_ms, 25000)) {
          PersistFinishedRoomScores(*room);
          SendSnapshotToRoom(*room);
        }
      }
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(LoadRoomTickIntervalMs()));
  }
}

}  // namespace landlords::services
