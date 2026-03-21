#pragma once

#include <atomic>
#include <cstdint>
#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <thread>
#include <unordered_map>
#include <vector>

#include "landlords/ai/bot_strategy.h"
#include "landlords/game/room.h"
#include "landlords/network/tcp_server.h"
#include "landlords/persistence/user_repository.h"

namespace landlords::services {

class GameService {
 public:
  explicit GameService(std::shared_ptr<persistence::IUserRepository> user_repository);
  ~GameService();

  void HandleMessage(const std::shared_ptr<network::IConnection>& connection,
                     const landlords::protocol::ClientMessage& message);

 private:
  struct SessionState {
    std::string session_token;
    core::UserRecord user;
    std::weak_ptr<network::IConnection> connection;
    std::string room_id;
  };

  struct PendingSeat {
    std::string player_id;
    std::string display_name;
    bool is_bot = false;
    bool ready = false;
    landlords::protocol::BotDifficulty bot_difficulty =
        landlords::protocol::BOT_DIFFICULTY_NORMAL;
  };

  struct PendingRoom {
    std::string room_id;
    std::string room_code;
    std::string owner_player_id;
    std::vector<PendingSeat> seats;
  };

  struct PendingInvitation {
    std::string invitation_id;
    std::string room_id;
    std::string room_code;
    std::string inviter_player_id;
    std::string inviter_account;
    std::string inviter_nickname;
    std::string invitee_player_id;
    std::string invitee_account;
    std::string invitee_nickname;
    int seat_index = -1;
    std::int64_t created_at_ms = 0;
  };

  std::optional<SessionState*> RequireSession(const std::string& session_token);
  std::optional<SessionState*> FindSessionByUserId(const std::string& user_id);
  std::vector<SessionState*> FindSessionsByUserId(const std::string& user_id);
  void HandleRegister(const std::shared_ptr<network::IConnection>& connection,
                      const landlords::protocol::ClientMessage& message);
  void HandleLogin(const std::shared_ptr<network::IConnection>& connection,
                   const landlords::protocol::ClientMessage& message);
  void HandleResetPassword(const std::shared_ptr<network::IConnection>& connection,
                           const landlords::protocol::ClientMessage& message);
  void HandleUpdateNickname(const std::shared_ptr<network::IConnection>& connection,
                            const landlords::protocol::ClientMessage& message);
  void HandleMatch(const std::shared_ptr<network::IConnection>& connection,
                   const landlords::protocol::ClientMessage& message);
  void HandleCreateRoom(const std::shared_ptr<network::IConnection>& connection,
                        const landlords::protocol::ClientMessage& message);
  void HandleJoinRoom(const std::shared_ptr<network::IConnection>& connection,
                      const landlords::protocol::ClientMessage& message);
  void HandleLeaveRoom(const std::shared_ptr<network::IConnection>& connection,
                       const landlords::protocol::ClientMessage& message);
  void HandleListFriends(const std::shared_ptr<network::IConnection>& connection,
                         const landlords::protocol::ClientMessage& message);
  void HandleAddFriend(const std::shared_ptr<network::IConnection>& connection,
                       const landlords::protocol::ClientMessage& message);
  void HandleInvitePlayer(const std::shared_ptr<network::IConnection>& connection,
                          const landlords::protocol::ClientMessage& message);
  void HandleRespondRoomInvitation(const std::shared_ptr<network::IConnection>& connection,
                                   const landlords::protocol::ClientMessage& message);
  void HandleRoomReady(const std::shared_ptr<network::IConnection>& connection,
                       const landlords::protocol::ClientMessage& message);
  void HandleAddBot(const std::shared_ptr<network::IConnection>& connection,
                    const landlords::protocol::ClientMessage& message);
  void HandleRemovePlayer(const std::shared_ptr<network::IConnection>& connection,
                          const landlords::protocol::ClientMessage& message);
  void HandlePlay(const std::shared_ptr<network::IConnection>& connection,
                  const landlords::protocol::ClientMessage& message);
  void HandlePass(const std::shared_ptr<network::IConnection>& connection,
                  const landlords::protocol::ClientMessage& message);
  void HandleReconnect(const std::shared_ptr<network::IConnection>& connection,
                       const landlords::protocol::ClientMessage& message);
  void HandleHeartbeat(const std::shared_ptr<network::IConnection>& connection,
                       const landlords::protocol::ClientMessage& message);
  void TickRoomsLoop();

  void SendError(const std::shared_ptr<network::IConnection>& connection,
                 const std::string& request_id,
                 landlords::protocol::ErrorCode code,
                 const std::string& message);
  void PersistFinishedRoomScores(const game::Room& room);
  void SendSnapshotToRoom(const game::Room& room);
  landlords::protocol::RoomSnapshot BuildPendingRoomSnapshot(
      const PendingRoom& room,
      const std::string& audience_player_id) const;
  landlords::protocol::OnlineUser BuildOnlineUser(const core::UserRecord& user);
  void SendPendingSnapshotToRoom(const PendingRoom& room);
  bool EnsureSessionRoomAvailable(const SessionState& session);
  bool SessionCanJoinPendingRoom(const SessionState& session,
                                 const std::string& target_room_id) const;
  std::optional<PendingRoom*> FindPendingRoom(const std::string& room_id);
  std::optional<const PendingRoom*> FindPendingRoom(const std::string& room_id) const;
  void RemoveSessionFromPendingRoom(SessionState& session,
                                    const std::string& room_id);
  void SendInvitationReceived(const PendingInvitation& invitation);
  void SendInvitationResult(const PendingInvitation& invitation,
                            landlords::protocol::InvitationResult result,
                            const std::string& detail);
  void ClearInvitation(const std::string& invitation_id);
  void ExpireInvitationsForRoom(const std::string& room_id,
                                const std::string& detail);
  void ExpireStaleInvitations(std::int64_t now_ms);
  void StartPreparedRoom(PendingRoom room);
  void CreateBotRoom(SessionState& session,
                     landlords::protocol::BotDifficulty difficulty);
  void MaybeCreatePvpRoom();
  bool RemoveWaitingToken(const std::string& session_token);
  std::shared_ptr<ai::IBotStrategy> ResolveBotStrategy(
      landlords::protocol::BotDifficulty difficulty) const;
  landlords::protocol::BotDifficulty NormalizeBotDifficulty(
      landlords::protocol::BotDifficulty difficulty) const;

  std::shared_ptr<persistence::IUserRepository> user_repository_;
  std::unordered_map<std::string, SessionState> sessions_by_token_;
  std::unordered_map<std::string, std::shared_ptr<game::Room>> rooms_by_id_;
  std::unordered_map<std::string, PendingRoom> pending_rooms_by_id_;
  std::unordered_map<std::string, std::string> pending_room_id_by_code_;
  std::unordered_map<std::string, PendingInvitation> invitations_by_id_;
  std::unordered_map<std::string, std::string> invitation_id_by_invitee_;
  std::vector<std::string> pvp_waiting_tokens_;
  std::mutex mutex_;
  std::atomic_bool running_{true};
  std::thread tick_thread_;
  std::shared_ptr<ai::IBotStrategy> easy_bot_strategy_;
  std::shared_ptr<ai::IBotStrategy> standard_bot_strategy_;
  std::shared_ptr<ai::IBotStrategy> hard_bot_strategy_;
};

}  // namespace landlords::services
