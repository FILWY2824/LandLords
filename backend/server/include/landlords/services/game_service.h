#pragma once

#include <atomic>
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

  std::optional<SessionState*> RequireSession(const std::string& session_token);
  void HandleRegister(const std::shared_ptr<network::IConnection>& connection,
                      const landlords::protocol::ClientMessage& message);
  void HandleLogin(const std::shared_ptr<network::IConnection>& connection,
                   const landlords::protocol::ClientMessage& message);
  void HandleMatch(const std::shared_ptr<network::IConnection>& connection,
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
  std::vector<std::string> pvp_waiting_tokens_;
  std::mutex mutex_;
  std::atomic_bool running_{true};
  std::thread tick_thread_;
  std::shared_ptr<ai::IBotStrategy> easy_bot_strategy_;
  std::shared_ptr<ai::IBotStrategy> standard_bot_strategy_;
  std::shared_ptr<ai::IBotStrategy> hard_bot_strategy_;
};

}  // namespace landlords::services
