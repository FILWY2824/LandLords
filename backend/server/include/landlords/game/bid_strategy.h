#pragma once

#include <vector>

#include "landlords/core/models.h"

namespace landlords::game {

int SuggestBidLevel(const std::vector<core::Card>& hand);
int ChooseBidAction(const std::vector<core::Card>& hand,
                    int current_highest_bid,
                    landlords::protocol::BotDifficulty difficulty =
                        landlords::protocol::BOT_DIFFICULTY_NORMAL);

}  // namespace landlords::game
