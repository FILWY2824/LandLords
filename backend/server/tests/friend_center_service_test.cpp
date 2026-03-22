#include "landlords/persistence/friend_request_repository.h"
#include "landlords/persistence/user_repository.h"
#include "landlords/services/game_service.h"

#include <filesystem>
#include <iostream>
#include <memory>
#include <optional>
#include <stdexcept>
#include <string>
#include <string_view>
#include <vector>

namespace {

using landlords::network::IConnection;
using landlords::persistence::FileFriendRequestRepository;
using landlords::persistence::FileUserRepository;
using landlords::protocol::ClientMessage;
using landlords::protocol::ListFriendsRequest;
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

bool HasFriendCenterPushSince(
    const FakeConnection& connection,
    std::size_t start_index,
    int expected_pending,
    int expected_friends) {
  for (std::size_t index = start_index; index < connection.messages.size(); ++index) {
    const auto& message = connection.messages[index];
    if (!message.has_friend_center_push()) {
      continue;
    }
    const auto& snapshot = message.friend_center_push().snapshot();
    if (snapshot.pending_requests_size() == expected_pending &&
        snapshot.friends_size() == expected_friends) {
      return true;
    }
  }
  return false;
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

ClientMessage MakeResetPassword(
    std::string request_id,
    std::string account,
    std::string password) {
  ClientMessage message;
  message.set_request_id(std::move(request_id));
  auto* payload = message.mutable_reset_password_request();
  payload->set_account(std::move(account));
  payload->set_new_password(std::move(password));
  return message;
}

ClientMessage MakeChangePassword(
    std::string request_id,
    std::string session_token,
    std::string current_password,
    std::string new_password) {
  ClientMessage message;
  message.set_request_id(std::move(request_id));
  message.set_session_token(std::move(session_token));
  auto* payload = message.mutable_change_password_request();
  payload->set_current_password(std::move(current_password));
  payload->set_new_password(std::move(new_password));
  return message;
}

ClientMessage MakeListFriends(std::string request_id, std::string session_token) {
  ClientMessage message;
  message.set_request_id(std::move(request_id));
  message.set_session_token(std::move(session_token));
  message.mutable_list_friends_request();
  return message;
}

ClientMessage MakeAddFriend(
    std::string request_id,
    std::string session_token,
    std::string account) {
  ClientMessage message;
  message.set_request_id(std::move(request_id));
  message.set_session_token(std::move(session_token));
  message.mutable_add_friend_request()->set_account(std::move(account));
  return message;
}

ClientMessage MakeRespondFriendRequest(
    std::string request_id,
    std::string session_token,
    std::string friend_request_id,
    bool accept) {
  ClientMessage message;
  message.set_request_id(std::move(request_id));
  message.set_session_token(std::move(session_token));
  auto* payload = message.mutable_respond_friend_request_request();
  payload->set_request_id(std::move(friend_request_id));
  payload->set_accept(accept);
  return message;
}

ClientMessage MakeDeleteFriend(
    std::string request_id,
    std::string session_token,
    std::string friend_user_id) {
  ClientMessage message;
  message.set_request_id(std::move(request_id));
  message.set_session_token(std::move(session_token));
  message.mutable_delete_friend_request()->set_friend_user_id(
      std::move(friend_user_id));
  return message;
}

void RunFriendCenterServiceTest() {
  const auto runtime_dir =
      std::filesystem::path("runtime") / "friend-center-service-test";
  std::filesystem::remove_all(runtime_dir);

  auto user_repository = std::make_shared<FileUserRepository>(runtime_dir);
  auto friend_request_repository =
      std::make_shared<FileFriendRequestRepository>(runtime_dir);

  GameService service(user_repository, friend_request_repository);
  auto owner_connection = std::make_shared<FakeConnection>("owner");
  auto guest_connection = std::make_shared<FakeConnection>("guest");

  service.HandleMessage(
      owner_connection,
      MakeRegister("register-owner", "owner_acc", "房主", "pass123"));
  service.HandleMessage(
      guest_connection,
      MakeRegister("register-guest", "guest_acc", "好友", "pass123"));

  const auto& owner_register = RequireResponse(*owner_connection, "register-owner");
  const auto& guest_register = RequireResponse(*guest_connection, "register-guest");
  Require(owner_register.register_response().success(), "owner register failed");
  Require(guest_register.register_response().success(), "guest register failed");

  service.HandleMessage(
      owner_connection,
      MakeLogin("login-owner", "owner_acc", "pass123"));
  service.HandleMessage(
      guest_connection,
      MakeLogin("login-guest", "guest_acc", "pass123"));

  const auto& owner_login = RequireResponse(*owner_connection, "login-owner");
  const auto& guest_login = RequireResponse(*guest_connection, "login-guest");
  Require(owner_login.login_response().success(), "owner login failed");
  Require(guest_login.login_response().success(), "guest login failed");

  const std::string owner_token = owner_login.login_response().session_token();
  const std::string guest_token = guest_login.login_response().session_token();

  const std::size_t guest_before_add = guest_connection->messages.size();
  service.HandleMessage(
      owner_connection,
      MakeAddFriend("add-friend", owner_token, "guest_acc"));

  const auto& add_friend = RequireResponse(*owner_connection, "add-friend");
  Require(add_friend.add_friend_response().success(), "send friend request failed");
  Require(add_friend.add_friend_response().snapshot().history_requests_size() == 1,
          "outgoing friend request should enter history immediately");
  Require(add_friend.add_friend_response().snapshot().pending_requests_size() == 0,
          "owner should not see outgoing request in pending list");
  Require(HasFriendCenterPushSince(*guest_connection, guest_before_add, 1, 0),
          "guest should receive a pending friend request push");

  service.HandleMessage(
      guest_connection,
      MakeListFriends("list-guest-pending", guest_token));
  const auto& guest_pending = RequireResponse(*guest_connection, "list-guest-pending");
  Require(guest_pending.list_friends_response().snapshot().pending_requests_size() == 1,
          "guest pending requests missing");
  const auto& pending_request =
      guest_pending.list_friends_response().snapshot().pending_requests(0);

  const std::size_t owner_before_accept = owner_connection->messages.size();
  service.HandleMessage(
      guest_connection,
      MakeRespondFriendRequest(
          "accept-friend",
          guest_token,
          pending_request.request_id(),
          true));

  const auto& accept_friend = RequireResponse(*guest_connection, "accept-friend");
  Require(accept_friend.respond_friend_request_response().success(),
          "accept friend request failed");
  Require(accept_friend.respond_friend_request_response().snapshot().friends_size() == 1,
          "guest should see accepted friend immediately");
  Require(HasFriendCenterPushSince(*owner_connection, owner_before_accept, 0, 1),
          "owner should receive online friend update after acceptance");

  service.HandleMessage(
      owner_connection,
      MakeListFriends("list-owner-after-accept", owner_token));
  const auto& owner_after_accept =
      RequireResponse(*owner_connection, "list-owner-after-accept");
  const auto& owner_snapshot =
      owner_after_accept.list_friends_response().snapshot();
  Require(owner_snapshot.friends_size() == 1, "owner friend list missing accepted friend");
  Require(owner_snapshot.friends(0).online(), "accepted friend should be reported online");
  Require(owner_snapshot.history_requests_size() >= 1,
          "owner history should preserve accepted request");
  Require(owner_snapshot.history_requests(0).status() ==
              landlords::protocol::FRIEND_REQUEST_STATUS_ACCEPTED,
          "owner history should record accepted status");

  const std::string friend_user_id = owner_snapshot.friends(0).user_id();
  service.HandleMessage(
      owner_connection,
      MakeDeleteFriend("delete-friend", owner_token, friend_user_id));

  const auto& delete_friend = RequireResponse(*owner_connection, "delete-friend");
  Require(delete_friend.delete_friend_response().success(), "delete friend failed");
  Require(delete_friend.delete_friend_response().snapshot().friends_size() == 0,
          "friend delete should clear owner friend list");
  Require(delete_friend.delete_friend_response().snapshot().history_requests_size() >= 1,
          "friend history should remain after delete");

  service.HandleMessage(
      guest_connection,
      MakeListFriends("list-guest-after-delete", guest_token));
  const auto& guest_after_delete =
      RequireResponse(*guest_connection, "list-guest-after-delete");
  Require(guest_after_delete.list_friends_response().snapshot().friends_size() == 0,
          "friend delete should clear guest friend list");
  Require(
      guest_after_delete.list_friends_response().snapshot().history_requests_size() >= 1,
      "guest history should remain after delete");

  std::filesystem::remove_all(runtime_dir);
}

void RunFriendCenterReconnectServiceTest() {
  const auto runtime_dir =
      std::filesystem::path("runtime") / "friend-center-reconnect-service-test";
  std::filesystem::remove_all(runtime_dir);

  auto user_repository = std::make_shared<FileUserRepository>(runtime_dir);
  auto friend_request_repository =
      std::make_shared<FileFriendRequestRepository>(runtime_dir);

  GameService service(user_repository, friend_request_repository);
  auto owner_connection = std::make_shared<FakeConnection>("owner");
  auto guest_connection = std::make_shared<FakeConnection>("guest-old");

  service.HandleMessage(
      owner_connection,
      MakeRegister("register-owner-rebind", "owner_rebind", "owner", "pass123"));
  service.HandleMessage(
      guest_connection,
      MakeRegister("register-guest-rebind", "guest_rebind", "guest", "pass123"));
  service.HandleMessage(
      owner_connection,
      MakeLogin("login-owner-rebind", "owner_rebind", "pass123"));
  service.HandleMessage(
      guest_connection,
      MakeLogin("login-guest-rebind", "guest_rebind", "pass123"));

  const auto& owner_login = RequireResponse(*owner_connection, "login-owner-rebind");
  const auto& guest_login = RequireResponse(*guest_connection, "login-guest-rebind");
  Require(owner_login.login_response().success(), "owner reconnect login failed");
  Require(guest_login.login_response().success(), "guest reconnect login failed");
  const std::string owner_token = owner_login.login_response().session_token();
  const std::string guest_token = guest_login.login_response().session_token();

  service.HandleMessage(
      owner_connection,
      MakeAddFriend("add-friend-rebind", owner_token, "guest_rebind"));
  service.HandleMessage(
      guest_connection,
      MakeListFriends("guest-pending-rebind", guest_token));
  const auto& guest_pending = RequireResponse(*guest_connection, "guest-pending-rebind");
  Require(guest_pending.list_friends_response().snapshot().pending_requests_size() == 1,
          "guest pending request missing for reconnect test");

  service.HandleMessage(
      guest_connection,
      MakeRespondFriendRequest("accept-rebind",
                               guest_token,
                               guest_pending.list_friends_response().snapshot().pending_requests(0).request_id(),
                               true));
  const auto& accept_rebind = RequireResponse(*guest_connection, "accept-rebind");
  Require(accept_rebind.respond_friend_request_response().success(),
          "friend accept failed in reconnect test");

  guest_connection.reset();

  service.HandleMessage(
      owner_connection,
      MakeListFriends("owner-sees-offline-after-drop", owner_token));
  const auto& owner_after_drop =
      RequireResponse(*owner_connection, "owner-sees-offline-after-drop");
  Require(owner_after_drop.list_friends_response().snapshot().friends_size() == 1,
          "owner friend missing after drop");
  Require(!owner_after_drop.list_friends_response().snapshot().friends(0).online(),
          "friend should appear offline after old connection expires");

  auto guest_reconnected = std::make_shared<FakeConnection>("guest-new");
  service.HandleMessage(
      guest_reconnected,
      MakeListFriends("guest-rebind-list", guest_token));
  const auto& guest_rebind =
      RequireResponse(*guest_reconnected, "guest-rebind-list");
  Require(guest_rebind.list_friends_response().snapshot().friends_size() == 1,
          "guest reconnect list should succeed");

  service.HandleMessage(
      owner_connection,
      MakeListFriends("owner-sees-online-after-rebind", owner_token));
  const auto& owner_after_rebind =
      RequireResponse(*owner_connection, "owner-sees-online-after-rebind");
  Require(owner_after_rebind.list_friends_response().snapshot().friends_size() == 1,
          "owner friend missing after rebind");
  Require(owner_after_rebind.list_friends_response().snapshot().friends(0).online(),
          "friend should appear online after authenticated rebind");

  service.HandleMessage(
      owner_connection,
      MakeDeleteFriend("delete-friend-after-rebind",
                       owner_token,
                       owner_after_rebind.list_friends_response().snapshot().friends(0).user_id()));
  const auto& delete_after_rebind =
      RequireResponse(*owner_connection, "delete-friend-after-rebind");
  Require(delete_after_rebind.delete_friend_response().success(),
          "delete friend should still succeed after session rebind");
  Require(delete_after_rebind.delete_friend_response().snapshot().friends_size() == 0,
          "owner friend list should be empty after delete");

  service.HandleMessage(
      guest_reconnected,
      MakeListFriends("guest-after-delete-rebind", guest_token));
  const auto& guest_after_delete =
      RequireResponse(*guest_reconnected, "guest-after-delete-rebind");
  Require(guest_after_delete.list_friends_response().snapshot().friends_size() == 0,
          "guest friend list should be empty after delete on rebound session");

  std::filesystem::remove_all(runtime_dir);
}

void RunFriendRequestBatchHandlingServiceTest() {
  const auto runtime_dir =
      std::filesystem::path("runtime") / "friend-request-batch-service-test";
  std::filesystem::remove_all(runtime_dir);

  auto user_repository = std::make_shared<FileUserRepository>(runtime_dir);
  auto friend_request_repository =
      std::make_shared<FileFriendRequestRepository>(runtime_dir);

  GameService service(user_repository, friend_request_repository);
  auto owner_connection = std::make_shared<FakeConnection>("owner-batch");
  auto guest_connection = std::make_shared<FakeConnection>("guest-batch");

  service.HandleMessage(
      owner_connection,
      MakeRegister("register-owner-batch", "owner_batch", "owner", "pass123"));
  service.HandleMessage(
      guest_connection,
      MakeRegister("register-guest-batch", "guest_batch", "guest", "pass123"));
  service.HandleMessage(
      owner_connection,
      MakeLogin("login-owner-batch", "owner_batch", "pass123"));
  service.HandleMessage(
      guest_connection,
      MakeLogin("login-guest-batch", "guest_batch", "pass123"));

  const auto& owner_login = RequireResponse(*owner_connection, "login-owner-batch");
  const auto& guest_login = RequireResponse(*guest_connection, "login-guest-batch");
  Require(owner_login.login_response().success(), "owner batch login failed");
  Require(guest_login.login_response().success(), "guest batch login failed");
  const std::string owner_token = owner_login.login_response().session_token();
  const std::string guest_token = guest_login.login_response().session_token();
  const std::string owner_user_id = owner_login.login_response().profile().user_id();
  const std::string guest_user_id = guest_login.login_response().profile().user_id();

  service.HandleMessage(
      owner_connection,
      MakeAddFriend("send-batch-request", owner_token, "guest_batch"));
  service.HandleMessage(
      guest_connection,
      MakeListFriends("guest-batch-pending", guest_token));
  const auto& guest_pending = RequireResponse(*guest_connection, "guest-batch-pending");
  Require(guest_pending.list_friends_response().snapshot().pending_requests_size() == 1,
          "guest should see the original pending request");
  const auto request_id =
      guest_pending.list_friends_response().snapshot().pending_requests(0).request_id();

  friend_request_repository->SaveNewRequest(owner_user_id, guest_user_id, 1001);
  friend_request_repository->SaveNewRequest(guest_user_id, owner_user_id, 1002);

  service.HandleMessage(
      guest_connection,
      MakeRespondFriendRequest("accept-batch-request", guest_token, request_id, true));
  const auto& accept_batch =
      RequireResponse(*guest_connection, "accept-batch-request");
  Require(accept_batch.respond_friend_request_response().success(),
          "batch accept should succeed");

  service.HandleMessage(
      owner_connection,
      MakeListFriends("owner-batch-after-accept", owner_token));
  service.HandleMessage(
      guest_connection,
      MakeListFriends("guest-batch-after-accept", guest_token));
  const auto& owner_after_accept =
      RequireResponse(*owner_connection, "owner-batch-after-accept");
  const auto& guest_after_accept =
      RequireResponse(*guest_connection, "guest-batch-after-accept");

  Require(owner_after_accept.list_friends_response().snapshot().friends_size() == 1,
          "owner should become friends after batch accept");
  Require(guest_after_accept.list_friends_response().snapshot().friends_size() == 1,
          "guest should become friends after batch accept");
  Require(owner_after_accept.list_friends_response().snapshot().pending_requests_size() == 0,
          "owner should not keep pending requests after batch accept");
  Require(guest_after_accept.list_friends_response().snapshot().pending_requests_size() == 0,
          "guest should not keep pending requests after batch accept");

  int accepted_count = 0;
  int handled_count = 0;
  for (const auto& item :
       owner_after_accept.list_friends_response().snapshot().history_requests()) {
    if (item.status() == landlords::protocol::FRIEND_REQUEST_STATUS_ACCEPTED) {
      ++accepted_count;
    }
    if (item.status() == landlords::protocol::FRIEND_REQUEST_STATUS_UNSPECIFIED) {
      ++handled_count;
    }
  }
  Require(accepted_count == 1, "batch accept should keep exactly one accepted history item");
  Require(handled_count >= 2, "batch accept should mark extra pending requests as handled");

  std::filesystem::remove_all(runtime_dir);
}

void RunFriendRequestBatchRejectServiceTest() {
  const auto runtime_dir =
      std::filesystem::path("runtime") / "friend-request-batch-reject-service-test";
  std::filesystem::remove_all(runtime_dir);

  auto user_repository = std::make_shared<FileUserRepository>(runtime_dir);
  auto friend_request_repository =
      std::make_shared<FileFriendRequestRepository>(runtime_dir);

  GameService service(user_repository, friend_request_repository);
  auto owner_connection = std::make_shared<FakeConnection>("owner-batch-reject");
  auto guest_connection = std::make_shared<FakeConnection>("guest-batch-reject");

  service.HandleMessage(
      owner_connection,
      MakeRegister("register-owner-batch-reject", "owner_batch_reject", "owner", "pass123"));
  service.HandleMessage(
      guest_connection,
      MakeRegister("register-guest-batch-reject", "guest_batch_reject", "guest", "pass123"));
  service.HandleMessage(
      owner_connection,
      MakeLogin("login-owner-batch-reject", "owner_batch_reject", "pass123"));
  service.HandleMessage(
      guest_connection,
      MakeLogin("login-guest-batch-reject", "guest_batch_reject", "pass123"));

  const auto& owner_login =
      RequireResponse(*owner_connection, "login-owner-batch-reject");
  const auto& guest_login =
      RequireResponse(*guest_connection, "login-guest-batch-reject");
  Require(owner_login.login_response().success(), "owner batch reject login failed");
  Require(guest_login.login_response().success(), "guest batch reject login failed");
  const std::string owner_token = owner_login.login_response().session_token();
  const std::string guest_token = guest_login.login_response().session_token();
  const std::string owner_user_id = owner_login.login_response().profile().user_id();
  const std::string guest_user_id = guest_login.login_response().profile().user_id();

  service.HandleMessage(
      owner_connection,
      MakeAddFriend("send-batch-reject-request", owner_token, "guest_batch_reject"));
  service.HandleMessage(
      guest_connection,
      MakeListFriends("guest-batch-reject-pending", guest_token));
  const auto& guest_pending =
      RequireResponse(*guest_connection, "guest-batch-reject-pending");
  Require(guest_pending.list_friends_response().snapshot().pending_requests_size() == 1,
          "guest should see the original pending request before reject");
  const auto request_id =
      guest_pending.list_friends_response().snapshot().pending_requests(0).request_id();

  friend_request_repository->SaveNewRequest(owner_user_id, guest_user_id, 2001);
  friend_request_repository->SaveNewRequest(guest_user_id, owner_user_id, 2002);

  service.HandleMessage(
      guest_connection,
      MakeRespondFriendRequest("reject-batch-request", guest_token, request_id, false));
  const auto& reject_batch =
      RequireResponse(*guest_connection, "reject-batch-request");
  Require(reject_batch.respond_friend_request_response().success(),
          "batch reject should succeed");

  service.HandleMessage(
      owner_connection,
      MakeListFriends("owner-batch-after-reject", owner_token));
  service.HandleMessage(
      guest_connection,
      MakeListFriends("guest-batch-after-reject", guest_token));
  const auto& owner_after_reject =
      RequireResponse(*owner_connection, "owner-batch-after-reject");
  const auto& guest_after_reject =
      RequireResponse(*guest_connection, "guest-batch-after-reject");

  Require(owner_after_reject.list_friends_response().snapshot().friends_size() == 0,
          "reject should not create friendships");
  Require(guest_after_reject.list_friends_response().snapshot().friends_size() == 0,
          "reject should not create friendships for guest");
  Require(owner_after_reject.list_friends_response().snapshot().pending_requests_size() == 0,
          "owner should not keep pending requests after batch reject");
  Require(guest_after_reject.list_friends_response().snapshot().pending_requests_size() == 0,
          "guest should not keep pending requests after batch reject");

  int rejected_count = 0;
  int handled_count = 0;
  for (const auto& item :
       owner_after_reject.list_friends_response().snapshot().history_requests()) {
    if (item.status() == landlords::protocol::FRIEND_REQUEST_STATUS_REJECTED) {
      ++rejected_count;
    }
    if (item.status() == landlords::protocol::FRIEND_REQUEST_STATUS_UNSPECIFIED) {
      ++handled_count;
    }
  }
  Require(rejected_count == 1, "batch reject should keep exactly one rejected history item");
  Require(handled_count >= 2, "batch reject should mark extra pending requests as handled");

  std::filesystem::remove_all(runtime_dir);
}

void RunExistingRuntimeFriendCenterRegressionTest() {
  const auto runtime_dir = std::filesystem::path("runtime");
  auto user_repository = std::make_shared<FileUserRepository>(runtime_dir);
  auto friend_request_repository =
      std::make_shared<FileFriendRequestRepository>(runtime_dir);

  GameService service(user_repository, friend_request_repository);
  auto connection = std::make_shared<FakeConnection>("runtime-regression");

  for (const auto& account : std::vector<std::string>{"player1", "admin"}) {
    const auto reset_request_id = "reset-" + account;
    const auto login_request_id = "login-" + account;
    const auto list_request_id = "list-" + account;

    service.HandleMessage(
        connection,
        MakeResetPassword(reset_request_id, account, "pass123"));
    const auto& reset_response = RequireResponse(*connection, reset_request_id);
    Require(reset_response.reset_password_response().success(),
            "reset password failed for runtime account " + account);

    service.HandleMessage(
        connection,
        MakeLogin(login_request_id, account, "pass123"));
    const auto& login_response = RequireResponse(*connection, login_request_id);
    Require(login_response.login_response().success(),
            "login failed for runtime account " + account);

    service.HandleMessage(
        connection,
        MakeListFriends(list_request_id, login_response.login_response().session_token()));
    const auto& list_response = RequireResponse(*connection, list_request_id);
    Require(list_response.has_list_friends_response(),
            "list friends response missing for runtime account " + account);
  }
}

void RunChangePasswordServiceTest() {
  const auto runtime_dir =
      std::filesystem::path("runtime") / "change-password-service-test";
  std::filesystem::remove_all(runtime_dir);

  auto user_repository = std::make_shared<FileUserRepository>(runtime_dir);
  auto friend_request_repository =
      std::make_shared<FileFriendRequestRepository>(runtime_dir);

  GameService service(user_repository, friend_request_repository);
  auto connection = std::make_shared<FakeConnection>("change-password");

  service.HandleMessage(
      connection,
      MakeRegister("register-change-password", "owner_acc", "owner", "pass123"));
  const auto& register_response =
      RequireResponse(*connection, "register-change-password");
  Require(register_response.register_response().success(), "register failed");

  service.HandleMessage(
      connection,
      MakeLogin("login-before-change", "owner_acc", "pass123"));
  const auto& login_before_change =
      RequireResponse(*connection, "login-before-change");
  Require(login_before_change.login_response().success(), "login before change failed");
  const auto session_token = login_before_change.login_response().session_token();

  service.HandleMessage(
      connection,
      MakeChangePassword(
          "change-password-invalid-current",
          session_token,
          "wrong-pass",
          "pass456"));
  const auto& invalid_change_response =
      RequireResponse(*connection, "change-password-invalid-current");
  Require(!invalid_change_response.change_password_response().success(),
          "change password should fail when current password is incorrect");

  service.HandleMessage(
      connection,
      MakeChangePassword(
          "change-password-success",
          session_token,
          "pass123",
          "pass456"));
  const auto& successful_change_response =
      RequireResponse(*connection, "change-password-success");
  Require(successful_change_response.change_password_response().success(),
          "change password should succeed with correct current password");

  service.HandleMessage(
      connection,
      MakeLogin("login-old-password", "owner_acc", "pass123"));
  const auto& old_password_login =
      RequireResponse(*connection, "login-old-password");
  Require(!old_password_login.login_response().success(),
          "old password should no longer be valid after change");

  service.HandleMessage(
      connection,
      MakeLogin("login-new-password", "owner_acc", "pass456"));
  const auto& new_password_login =
      RequireResponse(*connection, "login-new-password");
  Require(new_password_login.login_response().success(),
          "new password should be accepted after change");

  std::filesystem::remove_all(runtime_dir);
}

void RunStructuredPersistenceLayoutTest() {
  const auto runtime_dir =
      std::filesystem::path("runtime") / "structured-persistence-layout-test";
  std::filesystem::remove_all(runtime_dir);

  auto user_repository = std::make_shared<FileUserRepository>(runtime_dir);
  auto friend_request_repository =
      std::make_shared<FileFriendRequestRepository>(runtime_dir);

  auto owner = user_repository->SaveNewUser("owner_struct", "owner", "hash1");
  auto guest = user_repository->SaveNewUser("guest_struct", "guest", "hash2");
  owner.friend_user_ids.push_back(guest.user_id);
  user_repository->UpdateUser(owner);

  const auto request = friend_request_repository->SaveNewRequest(
      owner.user_id, guest.user_id, 123456);

  Require(std::filesystem::exists(runtime_dir / "users" / owner.user_id / "profile.v2"),
          "owner profile file should exist under per-user directory");
  Require(std::filesystem::exists(runtime_dir / "users" / guest.user_id / "profile.v2"),
          "guest profile file should exist under per-user directory");
  Require(std::filesystem::exists(runtime_dir / "index" / "users_by_account.v1"),
          "account index should exist");
  Require(std::filesystem::exists(runtime_dir / "social" / "friend_requests" /
                                  (request.request_id + ".v1")),
          "friend request record should exist under social table");
  Require(std::filesystem::exists(runtime_dir / "social" / "inboxes" /
                                  (owner.user_id + ".v1")),
          "owner social inbox index should exist");
  Require(std::filesystem::exists(runtime_dir / "social" / "inboxes" /
                                  (guest.user_id + ".v1")),
          "guest social inbox index should exist");

  auto reloaded_users = std::make_shared<FileUserRepository>(runtime_dir);
  auto reloaded_requests =
      std::make_shared<FileFriendRequestRepository>(runtime_dir);
  const auto owner_after_reload = reloaded_users->FindByAccount("owner_struct");
  const auto request_after_reload = reloaded_requests->FindById(request.request_id);
  Require(owner_after_reload.has_value(), "reloaded user should be found by account");
  Require(owner_after_reload->friend_user_ids.size() == 1 &&
              owner_after_reload->friend_user_ids.front() == guest.user_id,
          "reloaded user should preserve friend ids");
  Require(request_after_reload.has_value(),
          "reloaded friend request should be found by id");

  std::filesystem::remove_all(runtime_dir);
}

}  // namespace

int main() {
  try {
    RunFriendCenterServiceTest();
    RunFriendCenterReconnectServiceTest();
    RunFriendRequestBatchHandlingServiceTest();
    RunFriendRequestBatchRejectServiceTest();
    RunExistingRuntimeFriendCenterRegressionTest();
    RunChangePasswordServiceTest();
    RunStructuredPersistenceLayoutTest();
    std::cout << "friend center service tests passed" << std::endl;
    return 0;
  } catch (const std::exception& exception) {
    std::cerr << "friend center service tests failed: " << exception.what()
              << std::endl;
    return 1;
  }
}

