#include "landlords/network/tcp_server.h"

#include <cstring>
#include <memory>
#include <string>
#include <vector>

#ifdef _WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#else
#include <arpa/inet.h>
#endif

#include "event2/buffer.h"
#include "event2/bufferevent.h"
#include "event2/http.h"
#include "event2/listener.h"
#include "event2/util.h"
#include "event2/ws.h"
#include "landlords/core/logging.h"

namespace landlords::network {

class TcpServer::Connection final : public IConnection {
 public:
  Connection(bufferevent* bev, MessageHandler handler)
      : bev_(bev), handler_(std::move(handler)), connection_id_(core::GenerateId("conn")) {}

  ~Connection() override {
    if (bev_ != nullptr) {
      bufferevent_free(bev_);
      bev_ = nullptr;
    }
  }

  const std::string& connection_id() const override { return connection_id_; }

  void Send(const landlords::protocol::ServerMessage& message) override {
    std::string payload;
    message.SerializeToString(&payload);
    const std::uint32_t size = htonl(static_cast<std::uint32_t>(payload.size()));
    bufferevent_write(bev_, &size, sizeof(size));
    bufferevent_write(bev_, payload.data(), payload.size());
  }

  void HandleRead(const std::shared_ptr<Connection>& self) {
    evbuffer* input = bufferevent_get_input(bev_);
    while (evbuffer_get_length(input) >= sizeof(std::uint32_t)) {
      std::uint32_t frame_size = 0;
      evbuffer_copyout(input, &frame_size, sizeof(frame_size));
      frame_size = ntohl(frame_size);
      if (evbuffer_get_length(input) < sizeof(std::uint32_t) + frame_size) {
        return;
      }

      evbuffer_drain(input, sizeof(std::uint32_t));
      std::vector<char> buffer(frame_size);
      evbuffer_remove(input, buffer.data(), static_cast<int>(buffer.size()));

      landlords::protocol::ClientMessage message;
      if (!message.ParseFromArray(buffer.data(), static_cast<int>(buffer.size()))) {
        LANDLORDS_LOG(landlords::core::LogLevel::kWarn,
                      "tcp_server",
                      "failed to parse tcp client frame");
        continue;
      }
      handler_(self, message);
    }
  }

  static void ReadCallback(bufferevent* bev, void* ctx) {
    (void)bev;
    auto* holder = static_cast<std::shared_ptr<Connection>*>(ctx);
    (*holder)->HandleRead(*holder);
  }

  static void EventCallback(bufferevent* bev, short events, void* ctx) {
    auto* holder = static_cast<std::shared_ptr<Connection>*>(ctx);
    if ((events & (BEV_EVENT_EOF | BEV_EVENT_ERROR)) != 0) {
      LANDLORDS_LOG(landlords::core::LogLevel::kDebug,
                    "tcp_server",
                    "tcp connection closed events=" << events);
      delete holder;
      return;
    }
    if ((events & BEV_EVENT_CONNECTED) != 0) {
      bufferevent_enable(bev, EV_READ | EV_WRITE);
    }
  }

 private:
  bufferevent* bev_ = nullptr;
  MessageHandler handler_;
  std::string connection_id_;
};

class TcpServer::WsConnection final : public IConnection {
 public:
  WsConnection(evws_connection* ws, MessageHandler handler)
      : ws_(ws), handler_(std::move(handler)), connection_id_(core::GenerateId("ws")) {}

  const std::string& connection_id() const override { return connection_id_; }

  void Send(const landlords::protocol::ServerMessage& message) override {
    std::string payload;
    message.SerializeToString(&payload);
    evws_send_binary(ws_, payload.data(), payload.size());
  }

  void HandleMessage(const std::shared_ptr<WsConnection>& self,
                     int type,
                     const unsigned char* data,
                     size_t length) {
    if (type != WS_BINARY_FRAME) {
      LANDLORDS_LOG(landlords::core::LogLevel::kDebug,
                    "tcp_server",
                    "ignoring non-binary websocket frame type=" << type);
      return;
    }

    landlords::protocol::ClientMessage message;
    if (!message.ParseFromArray(data, static_cast<int>(length))) {
      LANDLORDS_LOG(landlords::core::LogLevel::kWarn,
                    "tcp_server",
                    "failed to parse websocket client frame");
      return;
    }
    handler_(self, message);
  }

  static void MessageCallback(evws_connection* ws,
                              int type,
                              const unsigned char* data,
                              size_t length,
                              void* arg) {
    (void)ws;
    auto* holder = static_cast<std::shared_ptr<WsConnection>*>(arg);
    (*holder)->HandleMessage(*holder, type, data, length);
  }

  static void CloseCallback(evws_connection* ws, void* arg) {
    (void)ws;
    auto* holder = static_cast<std::shared_ptr<WsConnection>*>(arg);
    delete holder;
  }

 private:
  evws_connection* ws_ = nullptr;
  MessageHandler handler_;
  std::string connection_id_;
};

TcpServer::TcpServer(core::ServerConfig config, MessageHandler handler)
    : config_(std::move(config)), handler_(std::move(handler)) {}

TcpServer::~TcpServer() {
  if (listener_ != nullptr) {
    evconnlistener_free(listener_);
  }
  if (http_ != nullptr) {
    evhttp_free(http_);
  }
  if (base_ != nullptr) {
    event_base_free(base_);
  }
#ifdef _WIN32
  WSACleanup();
#endif
}

bool TcpServer::Start() {
  last_error_.clear();
#ifdef _WIN32
  WSADATA wsa_data;
  const int wsa_result = WSAStartup(MAKEWORD(2, 2), &wsa_data);
  if (wsa_result != 0) {
    last_error_ = "WSAStartup failed with code " + std::to_string(wsa_result);
    return false;
  }
#endif
  base_ = event_base_new();
  if (base_ == nullptr) {
    last_error_ = "event_base_new failed";
    return false;
  }

  sockaddr_in address{};
  address.sin_family = AF_INET;
  address.sin_port = htons(config_.port);
  inet_pton(AF_INET, config_.host.c_str(), &address.sin_addr);

  listener_ = evconnlistener_new_bind(base_,
                                      &TcpServer::OnAccept,
                                      this,
                                      LEV_OPT_CLOSE_ON_FREE | LEV_OPT_REUSEABLE,
                                      -1,
                                      reinterpret_cast<sockaddr*>(&address),
                                      sizeof(address));
  if (listener_ == nullptr) {
    last_error_ = "failed to bind TCP "
                  + config_.host + ":" + std::to_string(config_.port)
                  + " - " + evutil_socket_error_to_string(EVUTIL_SOCKET_ERROR());
    return false;
  }

  http_ = evhttp_new(base_);
  if (http_ == nullptr) {
    last_error_ = "evhttp_new failed";
    return false;
  }
  evhttp_set_gencb(http_, &TcpServer::OnHttpRequest, this);
  if (evhttp_bind_socket(http_, config_.host.c_str(), config_.websocket_port) != 0) {
    last_error_ = "failed to bind WebSocket "
                  + config_.host + ":" + std::to_string(config_.websocket_port)
                  + " - " + evutil_socket_error_to_string(EVUTIL_SOCKET_ERROR());
    return false;
  }

  return true;
}

void TcpServer::Run() {
  if (base_ != nullptr) {
    event_base_dispatch(base_);
  }
}

void TcpServer::OnAccept(evconnlistener* listener,
                         evutil_socket_t fd,
                         sockaddr* address,
                         int socklen,
                         void* ctx) {
  (void)listener;
  (void)address;
  (void)socklen;
  auto* server = static_cast<TcpServer*>(ctx);
  bufferevent* bev = bufferevent_socket_new(server->base_, fd, BEV_OPT_CLOSE_ON_FREE);
  LANDLORDS_LOG(landlords::core::LogLevel::kDebug, "tcp_server", "accepted tcp connection fd=" << fd);
  auto connection = std::make_shared<Connection>(bev, server->handler_);
  auto* holder = new std::shared_ptr<Connection>(std::move(connection));
  bufferevent_setcb(bev, &Connection::ReadCallback, nullptr, &Connection::EventCallback, holder);
  bufferevent_enable(bev, EV_READ | EV_WRITE);
}

void TcpServer::OnHttpRequest(evhttp_request* request, void* ctx) {
  auto* server = static_cast<TcpServer*>(ctx);
  const char* uri_text = evhttp_request_get_uri(request);
  std::string path = uri_text == nullptr ? "/" : uri_text;
  if (auto* parsed = evhttp_uri_parse(uri_text == nullptr ? "/" : uri_text); parsed != nullptr) {
    if (const char* parsed_path = evhttp_uri_get_path(parsed); parsed_path != nullptr && std::strlen(parsed_path) > 0) {
      path = parsed_path;
    }
    evhttp_uri_free(parsed);
  }

  if (path != "/ws") {
    LANDLORDS_LOG(landlords::core::LogLevel::kDebug, "tcp_server", "http request path=" << path);
    auto* output = evbuffer_new();
    evbuffer_add_printf(output, "landlords websocket endpoint: /ws\n");
    evhttp_send_reply(request, 200, "OK", output);
    evbuffer_free(output);
    return;
  }

  auto* holder = new std::shared_ptr<WsConnection>();
  auto ws_connection = evws_new_session(request, &WsConnection::MessageCallback, holder, 0);
  if (ws_connection == nullptr) {
    delete holder;
    LANDLORDS_LOG(landlords::core::LogLevel::kWarn,
                  "tcp_server",
                  "websocket upgrade failed for path=" << path);
    evhttp_send_error(request, HTTP_BADREQUEST, "websocket upgrade failed");
    return;
  }

  LANDLORDS_LOG(landlords::core::LogLevel::kDebug, "tcp_server", "websocket session established");
  *holder = std::make_shared<WsConnection>(ws_connection, server->handler_);
  evws_connection_set_closecb(ws_connection, &WsConnection::CloseCallback, holder);
}

}  // namespace landlords::network
