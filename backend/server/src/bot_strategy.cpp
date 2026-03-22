#include "landlords/ai/bot_strategy.h"

#include <memory>

#include "landlords/ai/onnx_bot_strategy.h"
#include "landlords/core/logging.h"

namespace landlords::ai {

namespace {

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

}  // namespace

std::shared_ptr<IBotStrategy> CreateBotStrategyForDifficulty(
    landlords::protocol::BotDifficulty difficulty) {
  if (!OnnxRuntimeAvailable()) {
    LANDLORDS_LOG(landlords::core::LogLevel::kError,
                  "bot_strategy",
                  "DouZero ONNX runtime is unavailable for difficulty="
                      << DifficultyName(difficulty)
                      << "; autoplay and hint both require the ONNX backend");
    return nullptr;
  }

  const auto strategy = CreateOnnxBotStrategyForDifficulty(difficulty);
  if (strategy == nullptr) {
    LANDLORDS_LOG(landlords::core::LogLevel::kError,
                  "bot_strategy",
                  "failed to initialize DouZero ONNX strategy for difficulty="
                      << DifficultyName(difficulty));
    return nullptr;
  }

  LANDLORDS_LOG(landlords::core::LogLevel::kInfo,
                "bot_strategy",
                "bot backend=douzero_onnx difficulty=" << DifficultyName(difficulty));
  return strategy;
}

}  // namespace landlords::ai
