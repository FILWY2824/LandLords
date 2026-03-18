#include <filesystem>
#include <memory>

#include "landlords/core/config.h"
#include "landlords/core/logging.h"
#include "landlords/network/tcp_server.h"
#include "landlords/persistence/user_repository.h"
#include "landlords/services/game_service.h"

int main() {
  landlords::core::ServerConfig config;
  config.host = "0.0.0.0";
  config.port = 23001;
  config.websocket_port = 23002;
  config.data_dir = std::filesystem::path("runtime");

  const auto user_repository = std::make_shared<landlords::persistence::FileUserRepository>(
      config.data_dir / "users.db");
  auto service = std::make_shared<landlords::services::GameService>(user_repository);

  landlords::network::TcpServer server(
      config,
      [service](const std::shared_ptr<landlords::network::IConnection>& connection,
                const landlords::protocol::ClientMessage& message) {
        service->HandleMessage(connection, message);
      });

  if (!server.Start()) {
    LANDLORDS_LOG(landlords::core::LogLevel::kError,
                  "main",
                  "failed to start landlords server: " << server.last_error());
    return 1;
  }

  LANDLORDS_LOG(
      landlords::core::LogLevel::kInfo, "main", "landlords tcp listening on " << config.host << ":" << config.port);
  LANDLORDS_LOG(landlords::core::LogLevel::kInfo,
                "main",
                "landlords websocket listening on " << config.host << ":" << config.websocket_port
                                                    << " path /ws");
  server.Run();
  return 0;
}
