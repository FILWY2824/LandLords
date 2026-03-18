#pragma once

#include <cstdint>
#include <functional>
#include <memory>
#include <string>

#include "event2/event.h"
#include "event2/http.h"
#include "event2/listener.h"
#include "landlords/core/config.h"
#include "landlords/core/models.h"
#include "landlords.pb.h"

namespace landlords::network {

class IConnection {
 public:
  virtual ~IConnection() = default;
  virtual const std::string& connection_id() const = 0;
  virtual void Send(const landlords::protocol::ServerMessage& message) = 0;
};

using MessageHandler =
    std::function<void(const std::shared_ptr<IConnection>&, const landlords::protocol::ClientMessage&)>;

class TcpServer {
 public:
  TcpServer(core::ServerConfig config, MessageHandler handler);
  ~TcpServer();

  bool Start();
  void Run();
  const std::string& last_error() const { return last_error_; }

 private:
  class Connection;
  class WsConnection;

  static void OnAccept(struct evconnlistener* listener,
                       evutil_socket_t fd,
                       struct sockaddr* address,
                       int socklen,
                       void* ctx);
  static void OnHttpRequest(struct evhttp_request* request, void* ctx);

  core::ServerConfig config_;
  MessageHandler handler_;
  event_base* base_ = nullptr;
  evconnlistener* listener_ = nullptr;
  evhttp* http_ = nullptr;
  std::string last_error_;
};

}  // namespace landlords::network
