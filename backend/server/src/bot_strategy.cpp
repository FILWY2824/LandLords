#include "landlords/ai/bot_strategy.h"
#include "landlords/ai/onnx_bot_strategy.h"

#include <algorithm>
#include <cstdlib>
#include <cstring>
#include <memory>
#include <string>
#include <vector>

#include <event2/buffer.h>
#include <event2/event.h>
#include <event2/http.h>
#include <event2/http_struct.h>

#include "landlords/core/logging.h"

namespace landlords::ai {

namespace {

std::string LoadBackendMode() {
  const char* raw = std::getenv("LANDLORDS_BOT_BACKEND");
  return raw == nullptr ? "auto" : std::string(raw);
}

int LoadTimeoutSeconds() {
  const char* raw = std::getenv("LANDLORDS_BOT_TIMEOUT_SECONDS");
  if (raw == nullptr || std::strlen(raw) == 0) {
    return 20;
  }
  return std::max(1, std::atoi(raw));
}

const char* DifficultyName(landlords::protocol::BotDifficulty difficulty) {
  switch (difficulty) {
    case landlords::protocol::BOT_DIFFICULTY_EASY:
      return "easy";
    case landlords::protocol::BOT_DIFFICULTY_HARD:
      return "hard";
    case landlords::protocol::BOT_DIFFICULTY_NORMAL:
    case landlords::protocol::BOT_DIFFICULTY_UNSPECIFIED:
      return "normal";
  }
  return "normal";
}

class HttpBotStrategy final : public IBotStrategy {
 public:
  explicit HttpBotStrategy(std::string endpoint) : endpoint_(std::move(endpoint)) {}

  std::optional<BotDecision> ChooseMove(
      const landlords::protocol::RoomSnapshot& snapshot) override {
    LANDLORDS_LOG(landlords::core::LogLevel::kDebug,
                  "bot_strategy",
                  "request room=" << snapshot.room_id()
                                   << " turn=" << snapshot.current_turn_player_id()
                                   << " endpoint=" << endpoint_);

    auto* base = event_base_new();
    if (base == nullptr) {
      LANDLORDS_LOG(landlords::core::LogLevel::kError,
                    "bot_strategy",
                    "request failed: event_base_new returned null");
      return std::nullopt;
    }

    auto* uri = evhttp_uri_parse(endpoint_.c_str());
    if (uri == nullptr) {
      LANDLORDS_LOG(landlords::core::LogLevel::kError,
                    "bot_strategy",
                    "request failed: invalid endpoint uri");
      event_base_free(base);
      return std::nullopt;
    }

    const char* host = evhttp_uri_get_host(uri);
    if (host == nullptr) {
      LANDLORDS_LOG(landlords::core::LogLevel::kError,
                    "bot_strategy",
                    "request failed: endpoint host missing");
      evhttp_uri_free(uri);
      event_base_free(base);
      return std::nullopt;
    }

    const int port = evhttp_uri_get_port(uri) > 0 ? evhttp_uri_get_port(uri) : 80;
    const char* raw_path = evhttp_uri_get_path(uri);
    const char* path = (raw_path == nullptr || std::strlen(raw_path) == 0) ? "/" : raw_path;

    auto* connection = evhttp_connection_base_new(base, nullptr, host, port);
    if (connection == nullptr) {
      LANDLORDS_LOG(landlords::core::LogLevel::kWarn,
                    "bot_strategy",
                    "request failed: connection creation failed");
      evhttp_uri_free(uri);
      event_base_free(base);
      return std::nullopt;
    }
    evhttp_connection_set_timeout(connection, LoadTimeoutSeconds());

    struct RequestContext {
      event_base* base = nullptr;
      int status_code = 0;
      std::string body;
      bool completed = false;
    } context{
        .base = base,
    };

    auto* request = evhttp_request_new(
        [](evhttp_request* response, void* arg) {
          auto& context = *static_cast<RequestContext*>(arg);
          if (response != nullptr) {
            context.status_code = evhttp_request_get_response_code(response);
            if (auto* buffer = evhttp_request_get_input_buffer(response); buffer != nullptr) {
              const std::size_t length = evbuffer_get_length(buffer);
              context.body.resize(length);
              if (length > 0) {
                evbuffer_remove(buffer, context.body.data(), length);
              }
            }
          }
          context.completed = true;
          event_base_loopexit(context.base, nullptr);
        },
        &context);
    if (request == nullptr) {
      LANDLORDS_LOG(landlords::core::LogLevel::kWarn,
                    "bot_strategy",
                    "request failed: request creation failed");
      evhttp_connection_free(connection);
      evhttp_uri_free(uri);
      event_base_free(base);
      return std::nullopt;
    }

    auto* headers = evhttp_request_get_output_headers(request);
    evhttp_add_header(headers, "Host", host);
    evhttp_add_header(headers, "Content-Type", "application/x-protobuf");
    evhttp_add_header(headers, "Accept", "application/x-protobuf");

    const std::string payload = snapshot.SerializeAsString();
    evbuffer_add(evhttp_request_get_output_buffer(request), payload.data(), payload.size());

    const int request_result = evhttp_make_request(connection, request, EVHTTP_REQ_POST, path);
    if (request_result != 0) {
      LANDLORDS_LOG(landlords::core::LogLevel::kWarn,
                    "bot_strategy",
                    "request failed: evhttp_make_request returned " << request_result);
      evhttp_request_free(request);
      evhttp_connection_free(connection);
      evhttp_uri_free(uri);
      event_base_free(base);
      return std::nullopt;
    }

    event_base_dispatch(base);

    evhttp_connection_free(connection);
    evhttp_uri_free(uri);
    event_base_free(base);

    if (!context.completed || context.status_code != 200 || context.body.empty()) {
      LANDLORDS_LOG(landlords::core::LogLevel::kWarn,
                    "bot_strategy",
                    "request failed: completed=" << context.completed
                                                  << " status=" << context.status_code
                                                  << " body_bytes=" << context.body.size());
      return std::nullopt;
    }

    landlords::protocol::PlayCardsRequest response;
    if (!response.ParseFromString(context.body)) {
      LANDLORDS_LOG(landlords::core::LogLevel::kWarn,
                    "bot_strategy",
                    "request failed: protobuf parse error");
      return std::nullopt;
    }

    BotDecision decision;
    decision.kind = response.card_ids_size() == 0 ? BotDecision::Kind::kPass
                                                  : BotDecision::Kind::kPlay;
    decision.card_ids.assign(response.card_ids().begin(), response.card_ids().end());
    LANDLORDS_LOG(landlords::core::LogLevel::kDebug,
                  "bot_strategy",
                  "response room=" << snapshot.room_id()
                                   << " turn=" << snapshot.current_turn_player_id()
                                   << " decision="
                                   << (decision.kind == BotDecision::Kind::kPass ? "pass" : "play")
                                   << " cards=" << decision.card_ids.size());
    return decision;
  }

 private:
  std::string endpoint_;
};

}  // namespace

std::shared_ptr<IBotStrategy> CreateBotStrategyFromEnv() {
  return CreateBotStrategyForDifficulty(landlords::protocol::BOT_DIFFICULTY_NORMAL);
}

std::shared_ptr<IBotStrategy> CreateBotStrategyForDifficulty(
    landlords::protocol::BotDifficulty difficulty) {
  const std::string backend = LoadBackendMode();
  if (backend == "heuristic") {
    LANDLORDS_LOG(landlords::core::LogLevel::kInfo,
                  "bot_strategy",
                  "bot backend=heuristic difficulty=" << DifficultyName(difficulty)
                                                      << "; using local fallback only");
    return nullptr;
  }

  if (backend == "onnx") {
    return CreateOnnxBotStrategyForDifficulty(difficulty);
  }

  const char* endpoint = std::getenv("LANDLORDS_BOT_ENDPOINT");
  if (backend == "auto" && OnnxRuntimeAvailable()) {
    if (const auto onnx = CreateOnnxBotStrategyForDifficulty(difficulty);
        onnx != nullptr) {
      LANDLORDS_LOG(landlords::core::LogLevel::kInfo,
                    "bot_strategy",
                    "bot backend=auto selected in-process ONNX difficulty="
                        << DifficultyName(difficulty));
      return onnx;
    }
  }

  if (endpoint == nullptr || std::strlen(endpoint) == 0) {
    LANDLORDS_LOG(landlords::core::LogLevel::kInfo,
                  "bot_strategy",
                  "remote model disabled; using local heuristic fallback");
    return nullptr;
  }

  LANDLORDS_LOG(landlords::core::LogLevel::kInfo,
                "bot_strategy",
                "bot backend=http difficulty=" << DifficultyName(difficulty)
                                               << " endpoint=" << endpoint
                                               << " timeout=" << LoadTimeoutSeconds()
                                               << "s");
  return std::make_shared<HttpBotStrategy>(endpoint);
}

}  // namespace landlords::ai
