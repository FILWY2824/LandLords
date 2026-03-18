#pragma once

#include <filesystem>
#include <memory>

#include "landlords/ai/bot_strategy.h"

namespace landlords::ai {

bool OnnxRuntimeAvailable();
std::shared_ptr<IBotStrategy> CreateOnnxBotStrategyFromEnv();
std::shared_ptr<IBotStrategy> CreateOnnxBotStrategyForDifficulty(
    landlords::protocol::BotDifficulty difficulty);
std::shared_ptr<IBotStrategy> CreateOnnxBotStrategyFromDir(
    const std::filesystem::path& model_dir);

}  // namespace landlords::ai
