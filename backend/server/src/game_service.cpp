#include "landlords/services/game_service.h"

#include <algorithm>
#include <cstdlib>
#include <functional>
#include <string_view>
#include <thread>

#include "landlords/core/logging.h"

namespace landlords::services {

namespace {

constexpr std::string_view kCancelMatchCommand = "match:cancel";

std::string HashPassword(const std::string& password) {
  return std::to_string(std::hash<std::string>{}(password));
}

const char* PayloadName(const landlords::protocol::ClientMessage& message) {
  switch (message.payload_case()) {
    case landlords::protocol::ClientMessage::kRegisterRequest:
      return "register";
    case landlords::protocol::ClientMessage::kLoginRequest:
      return "login";
    case landlords::protocol::ClientMessage::kMatchRequest:
      return "match";
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
  profile->set_username(user.username);
  profile->set_total_score(user.total_score);
}

}  // namespace

GameService::GameService(std::shared_ptr<persistence::IUserRepository> user_repository)
    : user_repository_(std::move(user_repository)),
      easy_bot_strategy_(
          ai::CreateBotStrategyForDifficulty(landlords::protocol::BOT_DIFFICULTY_EASY)),
      standard_bot_strategy_(
          ai::CreateBotStrategyForDifficulty(landlords::protocol::BOT_DIFFICULTY_NORMAL)),
      hard_bot_strategy_(
          ai::CreateBotStrategyForDifficulty(landlords::protocol::BOT_DIFFICULTY_HARD)),
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
    case landlords::protocol::ClientMessage::kMatchRequest:
      HandleMatch(connection, message);
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

void GameService::HandleRegister(const std::shared_ptr<network::IConnection>& connection,
                                 const landlords::protocol::ClientMessage& message) {
  const auto& request = message.register_request();
  landlords::protocol::ServerMessage response;
  response.set_request_id(message.request_id());
  auto* payload = response.mutable_register_response();

  if (request.username().empty() || request.password().empty()) {
    payload->set_success(false);
    payload->set_message("username and password are required");
    connection->Send(response);
    return;
  }

  if (user_repository_->FindByUsername(request.username()).has_value()) {
    payload->set_success(false);
    payload->set_message("username already exists");
    connection->Send(response);
    return;
  }

  const auto user = user_repository_->SaveNewUser(request.username(), HashPassword(request.password()));
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

  const auto user = user_repository_->FindByUsername(request.username());
  if (!user.has_value() || user->password_hash != HashPassword(request.password())) {
    payload->set_success(false);
    payload->set_message("invalid username or password");
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
}

void GameService::HandleMatch(const std::shared_ptr<network::IConnection>& connection,
                              const landlords::protocol::ClientMessage& message) {
  landlords::protocol::ServerMessage response;
  response.set_request_id(message.request_id());
  auto* payload = response.mutable_match_response();

  std::lock_guard lock(mutex_);
  const auto session = RequireSession(message.session_token());
  if (!session.has_value()) {
    payload->set_accepted(false);
    payload->set_message("please login first");
    connection->Send(response);
    return;
  }

  if (!(*session)->room_id.empty()) {
    auto existing_room = rooms_by_id_.find((*session)->room_id);
    if (existing_room != rooms_by_id_.end() && existing_room->second->finished()) {
      (*session)->room_id.clear();
    } else if (message.match_request().mode() == landlords::protocol::MATCH_MODE_VS_BOT) {
      rooms_by_id_.erase((*session)->room_id);
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

void GameService::HandlePlay(const std::shared_ptr<network::IConnection>& connection,
                             const landlords::protocol::ClientMessage& message) {
  std::lock_guard lock(mutex_);
  const auto session = RequireSession(message.session_token());
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
  const auto session = RequireSession(message.session_token());
  if (!session.has_value()) {
    SendError(connection, message.request_id(), landlords::protocol::ERROR_CODE_AUTH_FAILED, "login required");
    return;
  }

  auto room_iterator = rooms_by_id_.find(message.pass_request().room_id());
  if (room_iterator == rooms_by_id_.end()) {
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
  const auto session = RequireSession(message.session_token());
  if (!session.has_value()) {
    SendError(connection, message.request_id(), landlords::protocol::ERROR_CODE_AUTH_FAILED, "login required");
    return;
  }

  (*session)->connection = connection;
  const std::string room_id = message.reconnect_request().room_id().empty()
                                  ? (*session)->room_id
                                  : message.reconnect_request().room_id();
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
      .display_name = session.user.username,
      .is_bot = false,
  });
  players.push_back(core::PlayerState{
      .player_id = core::GenerateId("bot"),
      .display_name = "Robot A",
      .is_bot = true,
  });
  players.push_back(core::PlayerState{
      .player_id = core::GenerateId("bot"),
      .display_name = "Robot B",
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
  for (const auto& token : selected_tokens) {
    auto iterator = sessions_by_token_.find(token);
    if (iterator == sessions_by_token_.end()) {
      return;
    }
    players.push_back(core::PlayerState{
        .player_id = iterator->second.user.user_id,
        .display_name = iterator->second.user.username,
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
  LANDLORDS_LOG(landlords::core::LogLevel::kInfo,
                "game_service",
                "created pvp room room=" << room_id << " players=" << players.size());

  for (const auto& token : selected_tokens) {
    auto& session = sessions_by_token_.at(token);
    session.room_id = room_id;
    if (const auto connection = session.connection.lock()) {
      landlords::protocol::ServerMessage found;
      auto* push = found.mutable_match_found_push();
      push->set_room_id(room_id);
      push->set_mode(landlords::protocol::MATCH_MODE_PVP);
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
