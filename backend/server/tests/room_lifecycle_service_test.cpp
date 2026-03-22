#include "landlords/persistence/friend_request_repository.h"
#include "landlords/persistence/user_repository.h"
#include "landlords/services/game_service.h"

#include <filesystem>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <string>
#include <string_view>
#include <vector>

namespace {

using landlords::network::IConnection;
using landlords::persistence::FileFriendRequestRepository;
using landlords::persistence::FileUserRepository;
using landlords::protocol::ClientMessage;
using landlords::protocol::ServerMessage;
using landlords::services::GameService;

class FakeConnection final : public IConnection {
 public:
  explicit FakeConnection(std::string id) : id_(std::move(id)) {}

  const std::string& connection_id() const override { return id_; }

  void Send(const ServerMessage& message) override { messages.push_back(message); }

  std::vector<ServerMessage> messages;

 private:
  std::string id_;
};

void Require(bool condition, const std::string& message) {
  if (!condition) {
    throw std::runtime_error(message);
  }
}

const ServerMessage& RequireResponse(
    const FakeConnection& connection,
    std::string_view request_id) {
  for (auto it = connection.messages.rbegin(); it != connection.messages.rend(); ++it) {
    if (it->request_id() == request_id) {
      return *it;
    }
  }
  throw std::runtime_error("missing response for request " + std::string(request_id));
}

const landlords::protocol::RoomSnapshot& RequireLatestRoomSnapshot(
    const FakeConnection& connection) {
  for (auto it = connection.messages.rbegin(); it != connection.messages.rend(); ++it) {
    if (it->has_room_snapshot()) {
      return it->room_snapshot();
    }
  }
  throw std::runtime_error("missing room snapshot push");
}

const ServerMessage& RequireLatestInvitationPush(const FakeConnection& connection) {
  for (auto it = connection.messages.rbegin(); it != connection.messages.rend(); ++it) {
    if (it->has_room_invitation_push()) {
      return *it;
    }
  }
  throw std::runtime_error("missing room invitation push");
}

const ServerMessage& RequireLatestInvitationResultPush(
    const FakeConnection& connection) {
  for (auto it = connection.messages.rbegin(); it != connection.messages.rend(); ++it) {
    if (it->has_room_invitation_result_push()) {
      return *it;
    }
  }
  throw std::runtime_error("missing room invitation result push");
}

const ServerMessage& RequireErrorResponse(
    const FakeConnection& connection,
    std::string_view request_id) {
  const auto& response = RequireResponse(connection, request_id);
  if (!response.has_error_response()) {
    throw std::runtime_error("missing error response for request " + std::string(request_id));
  }
  return response;
}

ClientMessage MakeRegister(
    std::string request_id,
    std::string account,
    std::string nickname,
    std::string password) {
  ClientMessage message;
  message.set_request_id(std::move(request_id));
  auto* payload = message.mutable_register_request();
  payload->set_account(std::move(account));
  payload->set_nickname(std::move(nickname));
  payload->set_password(std::move(password));
  return message;
}

ClientMessage MakeLogin(
    std::string request_id,
    std::string account,
    std::string password) {
  ClientMessage message;
  message.set_request_id(std::move(request_id));
  auto* payload = message.mutable_login_request();
  payload->set_account(std::move(account));
  payload->set_password(std::move(password));
  return message;
}

ClientMessage MakeCreateRoom(std::string request_id, std::string session_token) {
  ClientMessage message;
  message.set_request_id(std::move(request_id));
  message.set_session_token(std::move(session_token));
  message.mutable_create_room_request();
  return message;
}

ClientMessage MakeJoinRoom(
    std::string request_id,
    std::string session_token,
    std::string room_code) {
  ClientMessage message;
  message.set_request_id(std::move(request_id));
  message.set_session_token(std::move(session_token));
  message.mutable_join_room_request()->set_room_code(std::move(room_code));
  return message;
}

ClientMessage MakeLeaveRoom(
    std::string request_id,
    std::string session_token,
    std::string room_id) {
  ClientMessage message;
  message.set_request_id(std::move(request_id));
  message.set_session_token(std::move(session_token));
  message.mutable_leave_room_request()->set_room_id(std::move(room_id));
  return message;
}

ClientMessage MakeRoomReady(
    std::string request_id,
    std::string session_token,
    std::string room_id,
    bool ready) {
  ClientMessage message;
  message.set_request_id(std::move(request_id));
  message.set_session_token(std::move(session_token));
  auto* payload = message.mutable_room_ready_request();
  payload->set_room_id(std::move(room_id));
  payload->set_ready(ready);
  return message;
}

ClientMessage MakeRemovePlayer(
    std::string request_id,
    std::string session_token,
    std::string room_id,
    std::string player_id) {
  ClientMessage message;
  message.set_request_id(std::move(request_id));
  message.set_session_token(std::move(session_token));
  auto* payload = message.mutable_remove_player_request();
  payload->set_room_id(std::move(room_id));
  payload->set_player_id(std::move(player_id));
  return message;
}

ClientMessage MakeBotMatch(std::string request_id, std::string session_token) {
  ClientMessage message;
  message.set_request_id(std::move(request_id));
  message.set_session_token(std::move(session_token));
  auto* payload = message.mutable_match_request();
  payload->set_mode(landlords::protocol::MATCH_MODE_VS_BOT);
  payload->set_bot_difficulty(landlords::protocol::BOT_DIFFICULTY_NORMAL);
  return message;
}

ClientMessage MakeInvitePlayer(
    std::string request_id,
    std::string session_token,
    std::string room_id,
    std::string invitee_account,
    int seat_index) {
  ClientMessage message;
  message.set_request_id(std::move(request_id));
  message.set_session_token(std::move(session_token));
  auto* payload = message.mutable_invite_player_request();
  payload->set_room_id(std::move(room_id));
  payload->set_invitee_account(std::move(invitee_account));
  payload->set_seat_index(seat_index);
  return message;
}

ClientMessage MakeRespondInvitation(
    std::string request_id,
    std::string session_token,
    std::string invitation_id,
    bool accept) {
  ClientMessage message;
  message.set_request_id(std::move(request_id));
  message.set_session_token(std::move(session_token));
  auto* payload = message.mutable_respond_room_invitation_request();
  payload->set_invitation_id(std::move(invitation_id));
  payload->set_accept(accept);
  return message;
}

ClientMessage MakeReconnect(
    std::string request_id,
    std::string session_token,
    std::string room_id) {
  ClientMessage message;
  message.set_request_id(std::move(request_id));
  message.set_session_token(std::move(session_token));
  message.mutable_reconnect_request()->set_room_id(std::move(room_id));
  return message;
}

int OccupiedCount(const landlords::protocol::RoomSnapshot& snapshot) {
  int occupied = 0;
  for (const auto& player : snapshot.players()) {
    if (player.occupied()) {
      ++occupied;
    }
  }
  return occupied;
}

void RunRoomLifecycleServiceTest() {
  const auto runtime_dir =
      std::filesystem::path("runtime") / "room-lifecycle-service-test";
  std::filesystem::remove_all(runtime_dir);

  auto user_repository = std::make_shared<FileUserRepository>(runtime_dir);
  auto friend_request_repository =
      std::make_shared<FileFriendRequestRepository>(runtime_dir);

  GameService service(user_repository, friend_request_repository);
  auto connection = std::make_shared<FakeConnection>("owner");

  service.HandleMessage(
      connection,
      MakeRegister("register-owner", "owner_acc", "房主", "pass123"));
  service.HandleMessage(
      connection,
      MakeLogin("login-owner", "owner_acc", "pass123"));

  const auto& login = RequireResponse(*connection, "login-owner");
  Require(login.login_response().success(), "owner login failed");
  const std::string owner_token = login.login_response().session_token();

  service.HandleMessage(
      connection,
      MakeCreateRoom("create-room", owner_token));

  const auto& create_room = RequireResponse(*connection, "create-room");
  Require(create_room.operation_response().success(), "create room failed");
  const auto& pending_snapshot = create_room.operation_response().snapshot();
  Require(pending_snapshot.phase() == landlords::protocol::ROOM_PHASE_PREPARING,
          "create room should remain in preparing phase");
  Require(pending_snapshot.status_text() == "waiting_for_players",
          "solo room should wait for players");
  Require(OccupiedCount(pending_snapshot) == 1,
          "newly created room should only contain the owner");

  service.HandleMessage(
      connection,
      MakeRoomReady(
          "owner-ready",
          owner_token,
          pending_snapshot.room_id(),
          true));

  const auto& ready_response = RequireResponse(*connection, "owner-ready");
  Require(ready_response.operation_response().success(),
          "ready toggle failed");
  Require(ready_response.operation_response().message() == "ready_updated",
          "room should not start before all three seats are occupied");
  Require(ready_response.operation_response().snapshot().phase() ==
              landlords::protocol::ROOM_PHASE_PREPARING,
          "room must stay in preparing phase when only one player is seated");

  service.HandleMessage(
      connection,
      MakeLeaveRoom(
          "leave-pending",
          owner_token,
          pending_snapshot.room_id()));

  const auto& leave_pending = RequireResponse(*connection, "leave-pending");
  Require(leave_pending.operation_response().success(), "leaving pending room failed");

  service.HandleMessage(
      connection,
      MakeBotMatch("bot-match", owner_token));

  const auto& bot_match = RequireResponse(*connection, "bot-match");
  Require(bot_match.match_response().accepted(), "vs bot match request was rejected");
  const auto& bot_snapshot = RequireLatestRoomSnapshot(*connection);
  Require(bot_snapshot.mode() == landlords::protocol::MATCH_MODE_VS_BOT,
          "vs bot room snapshot missing");

  service.HandleMessage(
      connection,
      MakeLeaveRoom("leave-bot", owner_token, bot_snapshot.room_id()));

  const auto& leave_bot = RequireResponse(*connection, "leave-bot");
  Require(leave_bot.operation_response().success(), "leaving vs bot room failed");

  service.HandleMessage(
      connection,
      MakeCreateRoom("create-after-bot", owner_token));

  const auto& create_after_bot =
      RequireResponse(*connection, "create-after-bot");
  Require(create_after_bot.operation_response().success(),
          "create room should work after leaving a vs bot game");
  Require(create_after_bot.operation_response().snapshot().phase() ==
              landlords::protocol::ROOM_PHASE_PREPARING,
          "recreated room should still be preparing");
}

void RunInvitationRoomSwitchServiceTest() {
  const auto runtime_dir =
      std::filesystem::path("runtime") / "invitation-room-switch-service-test";
  std::filesystem::remove_all(runtime_dir);

  auto user_repository = std::make_shared<FileUserRepository>(runtime_dir);
  auto friend_request_repository =
      std::make_shared<FileFriendRequestRepository>(runtime_dir);

  GameService service(user_repository, friend_request_repository);
  auto inviter_connection = std::make_shared<FakeConnection>("inviter");
  auto invitee_connection = std::make_shared<FakeConnection>("invitee");
  auto roommate_connection = std::make_shared<FakeConnection>("roommate");

  service.HandleMessage(
      inviter_connection,
      MakeRegister("register-inviter", "inviter_acc", "inviter", "pass123"));
  service.HandleMessage(
      invitee_connection,
      MakeRegister("register-invitee", "invitee_acc", "invitee", "pass123"));
  service.HandleMessage(
      roommate_connection,
      MakeRegister("register-roommate", "roommate_acc", "roommate", "pass123"));

  service.HandleMessage(
      inviter_connection,
      MakeLogin("login-inviter", "inviter_acc", "pass123"));
  service.HandleMessage(
      invitee_connection,
      MakeLogin("login-invitee", "invitee_acc", "pass123"));
  service.HandleMessage(
      roommate_connection,
      MakeLogin("login-roommate", "roommate_acc", "pass123"));

  const auto& inviter_login = RequireResponse(*inviter_connection, "login-inviter");
  const auto& invitee_login = RequireResponse(*invitee_connection, "login-invitee");
  const auto& roommate_login = RequireResponse(*roommate_connection, "login-roommate");
  Require(inviter_login.login_response().success(), "inviter login failed");
  Require(invitee_login.login_response().success(), "invitee login failed");
  Require(roommate_login.login_response().success(), "roommate login failed");

  const std::string inviter_token = inviter_login.login_response().session_token();
  const std::string invitee_token = invitee_login.login_response().session_token();
  const std::string roommate_token = roommate_login.login_response().session_token();
  const std::string invitee_user_id = invitee_login.login_response().profile().user_id();
  const std::string roommate_user_id = roommate_login.login_response().profile().user_id();

  service.HandleMessage(
      invitee_connection,
      MakeCreateRoom("create-room-a", invitee_token));
  const auto& room_a_create = RequireResponse(*invitee_connection, "create-room-a");
  Require(room_a_create.operation_response().success(), "invitee room creation failed");
  const auto& room_a_snapshot = room_a_create.operation_response().snapshot();

  service.HandleMessage(
      roommate_connection,
      MakeJoinRoom("join-room-a", roommate_token, room_a_snapshot.room_code()));
  const auto& room_a_join = RequireResponse(*roommate_connection, "join-room-a");
  Require(room_a_join.operation_response().success(), "roommate join failed");
  Require(OccupiedCount(room_a_join.operation_response().snapshot()) == 2,
          "room a should have two seated players before invite switching");

  service.HandleMessage(
      inviter_connection,
      MakeCreateRoom("create-room-b", inviter_token));
  const auto& room_b_create = RequireResponse(*inviter_connection, "create-room-b");
  Require(room_b_create.operation_response().success(), "inviter room creation failed");
  const auto& room_b_snapshot = room_b_create.operation_response().snapshot();

  service.HandleMessage(
      inviter_connection,
      MakeInvitePlayer(
          "invite-reject", inviter_token, room_b_snapshot.room_id(), "invitee_acc", 1));
  const auto& invite_reject = RequireResponse(*inviter_connection, "invite-reject");
  Require(invite_reject.invite_player_response().accepted(),
          "first invitation should be accepted for delivery");
  const auto& reject_push = RequireLatestInvitationPush(*invitee_connection);

  service.HandleMessage(
      invitee_connection,
      MakeRespondInvitation("reject-invitation",
                            invitee_token,
                            reject_push.room_invitation_push().invitation_id(),
                            false));
  const auto& reject_response =
      RequireResponse(*invitee_connection, "reject-invitation");
  Require(reject_response.respond_room_invitation_response().success(),
          "reject invitation should succeed while staying in current room");

  const auto& reject_feedback =
      RequireLatestInvitationResultPush(*inviter_connection);
  Require(reject_feedback.room_invitation_result_push().result() ==
              landlords::protocol::INVITATION_RESULT_REJECTED,
          "inviter should receive rejected feedback");

  service.HandleMessage(
      invitee_connection,
      MakeReconnect("invitee-reconnect-after-reject", invitee_token, ""));
  const auto& invitee_after_reject =
      RequireResponse(*invitee_connection, "invitee-reconnect-after-reject");
  Require(invitee_after_reject.has_room_snapshot(),
          "invitee reconnect after reject should return room snapshot");
  Require(invitee_after_reject.room_snapshot().room_id() == room_a_snapshot.room_id(),
          "reject should keep invitee in original room");
  Require(invitee_after_reject.room_snapshot().owner_player_id() == invitee_user_id,
          "reject should keep invitee as room owner");

  service.HandleMessage(
      inviter_connection,
      MakeInvitePlayer(
          "invite-accept", inviter_token, room_b_snapshot.room_id(), "invitee_acc", 1));
  const auto& invite_accept = RequireResponse(*inviter_connection, "invite-accept");
  Require(invite_accept.invite_player_response().accepted(),
          "second invitation should be accepted for delivery");
  const auto& accept_push = RequireLatestInvitationPush(*invitee_connection);

  service.HandleMessage(
      invitee_connection,
      MakeRespondInvitation("accept-invitation",
                            invitee_token,
                            accept_push.room_invitation_push().invitation_id(),
                            true));
  const auto& accept_response =
      RequireResponse(*invitee_connection, "accept-invitation");
  Require(accept_response.respond_room_invitation_response().success(),
          "accept invitation should move invitee to inviter room");
  Require(accept_response.respond_room_invitation_response().snapshot().room_id() ==
              room_b_snapshot.room_id(),
          "accept should join inviter room");
  Require(OccupiedCount(accept_response.respond_room_invitation_response().snapshot()) == 2,
          "inviter room should contain inviter and invitee after accept");

  const auto& accept_feedback =
      RequireLatestInvitationResultPush(*inviter_connection);
  Require(accept_feedback.room_invitation_result_push().result() ==
              landlords::protocol::INVITATION_RESULT_ACCEPTED,
          "inviter should receive accepted feedback");

  service.HandleMessage(
      invitee_connection,
      MakeReconnect("invitee-reconnect-after-accept", invitee_token, ""));
  const auto& invitee_after_accept =
      RequireResponse(*invitee_connection, "invitee-reconnect-after-accept");
  Require(invitee_after_accept.has_room_snapshot(),
          "invitee reconnect after accept should return room snapshot");
  Require(invitee_after_accept.room_snapshot().room_id() == room_b_snapshot.room_id(),
          "invitee should now be in inviter room");

  service.HandleMessage(
      roommate_connection,
      MakeReconnect("roommate-reconnect-after-transfer", roommate_token, ""));
  const auto& roommate_after_transfer =
      RequireResponse(*roommate_connection, "roommate-reconnect-after-transfer");
  Require(roommate_after_transfer.has_room_snapshot(),
          "roommate reconnect should return transferred room snapshot");
  Require(roommate_after_transfer.room_snapshot().room_id() == room_a_snapshot.room_id(),
          "roommate should remain in original room");
  Require(roommate_after_transfer.room_snapshot().owner_player_id() == roommate_user_id,
          "room ownership should transfer to the next seated player");
  Require(OccupiedCount(roommate_after_transfer.room_snapshot()) == 1,
          "original room should only contain the roommate after invitee switches rooms");

  std::filesystem::remove_all(runtime_dir);
}

void RunHostRemovePlayerServiceTest() {
  const auto runtime_dir =
      std::filesystem::path("runtime") / "host-remove-player-service-test";
  std::filesystem::remove_all(runtime_dir);

  auto user_repository = std::make_shared<FileUserRepository>(runtime_dir);
  auto friend_request_repository =
      std::make_shared<FileFriendRequestRepository>(runtime_dir);

  GameService service(user_repository, friend_request_repository);
  auto owner_connection = std::make_shared<FakeConnection>("owner");
  auto guest_connection = std::make_shared<FakeConnection>("guest");

  service.HandleMessage(
      owner_connection,
      MakeRegister("register-owner-remove", "owner_remove_acc", "owner", "pass123"));
  service.HandleMessage(
      guest_connection,
      MakeRegister("register-guest-remove", "guest_remove_acc", "guest", "pass123"));

  service.HandleMessage(
      owner_connection,
      MakeLogin("login-owner-remove", "owner_remove_acc", "pass123"));
  service.HandleMessage(
      guest_connection,
      MakeLogin("login-guest-remove", "guest_remove_acc", "pass123"));

  const auto& owner_login = RequireResponse(*owner_connection, "login-owner-remove");
  const auto& guest_login = RequireResponse(*guest_connection, "login-guest-remove");
  Require(owner_login.login_response().success(), "owner login for remove test failed");
  Require(guest_login.login_response().success(), "guest login for remove test failed");

  const std::string owner_token = owner_login.login_response().session_token();
  const std::string guest_token = guest_login.login_response().session_token();
  const std::string guest_user_id = guest_login.login_response().profile().user_id();

  service.HandleMessage(
      owner_connection,
      MakeCreateRoom("create-room-remove", owner_token));
  const auto& create_room = RequireResponse(*owner_connection, "create-room-remove");
  Require(create_room.operation_response().success(), "host remove test room creation failed");
  const auto& created_snapshot = create_room.operation_response().snapshot();

  service.HandleMessage(
      guest_connection,
      MakeJoinRoom(
          "join-room-remove",
          guest_token,
          created_snapshot.room_code()));
  const auto& join_room = RequireResponse(*guest_connection, "join-room-remove");
  Require(join_room.operation_response().success(), "guest join for remove test failed");
  Require(OccupiedCount(join_room.operation_response().snapshot()) == 2,
          "remove test room should contain two players before removal");

  service.HandleMessage(
      owner_connection,
      MakeRemovePlayer(
          "remove-guest",
          owner_token,
          created_snapshot.room_id(),
          guest_user_id));
  const auto& remove_response = RequireResponse(*owner_connection, "remove-guest");
  Require(remove_response.has_operation_response(), "remove player should return operation response");
  Require(remove_response.operation_response().success(), "host remove player should succeed");
  Require(remove_response.operation_response().message() == "player_removed",
          "remove player should use the unified removal message");
  Require(OccupiedCount(remove_response.operation_response().snapshot()) == 1,
          "room should only keep the host after removing the guest");

  const auto& guest_push = RequireLatestRoomSnapshot(*guest_connection);
  Require(OccupiedCount(guest_push) == 1,
          "removed guest should receive the updated pending snapshot");
  bool guest_still_present = false;
  for (const auto& player : guest_push.players()) {
    if (player.player_id() == guest_user_id) {
      guest_still_present = true;
      break;
    }
  }
  Require(!guest_still_present, "removed guest should no longer appear in the room snapshot");

  service.HandleMessage(
      guest_connection,
      MakeReconnect("guest-reconnect-after-remove", guest_token, created_snapshot.room_id()));
  const auto& reconnect_error =
      RequireErrorResponse(*guest_connection, "guest-reconnect-after-remove");
  Require(reconnect_error.error_response().message() == "room not found",
          "removed guest should not be able to reconnect into the old room");

  std::filesystem::remove_all(runtime_dir);
}

}  // namespace

int main() {
  try {
    RunRoomLifecycleServiceTest();
    RunInvitationRoomSwitchServiceTest();
    RunHostRemovePlayerServiceTest();
    std::cout << "room lifecycle service test passed\n";
    return 0;
  } catch (const std::exception& error) {
    std::cerr << "room lifecycle service test failed: " << error.what() << '\n';
    return 1;
  }
}
