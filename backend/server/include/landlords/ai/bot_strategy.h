#pragma once

#include <memory>
#include <optional>
#include <string>
#include <vector>

#include "landlords.pb.h"

namespace landlords::ai {

struct BotDecision {
  enum class Kind {
    kPlay,
    kPass,
  };

  Kind kind = Kind::kPass;
  std::vector<std::string> card_ids;
};

class IBotStrategy {
 public:
  virtual ~IBotStrategy() = default;

  virtual std::optional<BotDecision> ChooseMove(
      const landlords::protocol::RoomSnapshot& snapshot) = 0;
};

std::shared_ptr<IBotStrategy> CreateBotStrategyFromEnv();
std::shared_ptr<IBotStrategy> CreateBotStrategyForDifficulty(
    landlords::protocol::BotDifficulty difficulty);

}  // namespace landlords::ai
