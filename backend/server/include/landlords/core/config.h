#pragma once

#include <cstdint>
#include <filesystem>
#include <string>

namespace landlords::core {

struct ServerConfig {
  std::string host = "0.0.0.0";
  std::uint16_t port = 23001;
  std::uint16_t websocket_port = 23002;
  std::filesystem::path data_dir = "runtime";
};

}  // namespace landlords::core
