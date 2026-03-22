#include <filesystem>
#include <cstdlib>
#include <memory>
#include <string>

#include "landlords/core/config.h"
#include "landlords/core/logging.h"
#include "landlords/network/tcp_server.h"
#include "landlords/persistence/friend_request_repository.h"
#include "landlords/persistence/user_repository.h"
#include "landlords/services/game_service.h"

namespace {

std::string ReadStringEnv(const char* name, const std::string& fallback) {
  const char* raw = std::getenv(name);
  if (raw == nullptr || *raw == '\0') {
    return fallback;
  }
  return raw;
}

std::uint16_t ReadPortEnv(const char* name, std::uint16_t fallback) {
  const char* raw = std::getenv(name);
  if (raw == nullptr || *raw == '\0') {
    return fallback;
  }
  try {
    const auto parsed = std::stoi(raw);
    if (parsed <= 0 || parsed > 65535) {
      return fallback;
    }
    return static_cast<std::uint16_t>(parsed);
  } catch (...) {
    return fallback;
  }
}

std::filesystem::path ReadPathEnv(const char* name,
                                  const std::filesystem::path& fallback) {
  const char* raw = std::getenv(name);
  if (raw == nullptr || *raw == '\0') {
    return fallback;
  }
  return std::filesystem::path(raw);
}

std::filesystem::path FindProjectRoot() {
  std::error_code error;
  auto current = std::filesystem::current_path(error);
  if (error) {
    return {};
  }
  while (!current.empty()) {
    if (std::filesystem::exists(current / "pubspec.yaml", error) &&
        std::filesystem::exists(current / "backend" / "server" / "CMakeLists.txt",
                                error)) {
      return current;
    }
    const auto parent = current.parent_path();
    if (parent == current) {
      break;
    }
    current = parent;
  }
  return {};
}

std::filesystem::path ResolveProjectRelativePath(
    const std::filesystem::path& path) {
  if (path.is_absolute()) {
    return path.lexically_normal();
  }
  if (const auto project_root = FindProjectRoot(); !project_root.empty()) {
    return (project_root / path).lexically_normal();
  }
  std::error_code error;
  const auto current = std::filesystem::current_path(error);
  if (error) {
    return path.lexically_normal();
  }
  return (current / path).lexically_normal();
}

}  // namespace

int main() {
  landlords::core::ServerConfig config;
  config.host = ReadStringEnv("LANDLORDS_HOST", "0.0.0.0");
  config.port = ReadPortEnv("LANDLORDS_PORT", 23001);
  config.websocket_port = ReadPortEnv("LANDLORDS_WS_PORT", 23002);
  config.data_dir = ResolveProjectRelativePath(
      ReadPathEnv("LANDLORDS_DATA_DIR", std::filesystem::path("runtime")));

  const auto user_repository =
      std::make_shared<landlords::persistence::FileUserRepository>(
          config.data_dir);
  const auto friend_request_repository =
      std::make_shared<landlords::persistence::FileFriendRequestRepository>(
          config.data_dir);
  auto service = std::make_shared<landlords::services::GameService>(
      user_repository,
      friend_request_repository);

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


