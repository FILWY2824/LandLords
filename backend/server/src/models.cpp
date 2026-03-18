#include "landlords/core/models.h"

#include <algorithm>
#include <array>
#include <map>
#include <set>
#include <sstream>

namespace landlords::core {

namespace {

int RankValue(const std::string& rank) {
  static const std::unordered_map<std::string, int> values = {
      {"3", 3},   {"4", 4},   {"5", 5},   {"6", 6},   {"7", 7},
      {"8", 8},   {"9", 9},   {"10", 10}, {"J", 11},  {"Q", 12},
      {"K", 13},  {"A", 14},  {"2", 15},  {"SJ", 16}, {"BJ", 17},
  };
  return values.at(rank);
}

CardPattern MakePattern(PatternType type,
                        std::vector<Card> cards,
                        int weight,
                        const std::string& label) {
  const int length = static_cast<int>(cards.size());
  return CardPattern{
      .type = type,
      .cards = std::move(cards),
      .weight = weight,
      .length = length,
      .label = label,
  };
}

std::map<int, std::vector<Card>> GroupByValue(const std::vector<Card>& cards) {
  std::map<int, std::vector<Card>> groups;
  for (const auto& card : cards) {
    groups[card.value].push_back(card);
  }
  return groups;
}

bool IsConsecutive(const std::vector<int>& values) {
  if (values.empty()) {
    return false;
  }
  for (std::size_t index = 1; index < values.size(); ++index) {
    if (values[index] != values[index - 1] + 1) {
      return false;
    }
  }
  return true;
}

std::vector<int> ExtractValuesWithCount(const std::map<int, std::vector<Card>>& groups, std::size_t min_count) {
  std::vector<int> values;
  for (const auto& [value, cards] : groups) {
    if (cards.size() >= min_count) {
      values.push_back(value);
    }
  }
  return values;
}

std::vector<std::vector<int>> FindConsecutiveRuns(const std::vector<int>& values, std::size_t min_length) {
  std::vector<std::vector<int>> runs;
  for (std::size_t start = 0; start < values.size();) {
    std::size_t end = start;
    while (end + 1 < values.size() && values[end + 1] == values[end] + 1) {
      ++end;
    }
    const std::size_t run_length = end - start + 1;
    if (run_length >= min_length) {
      for (std::size_t length = min_length; length <= run_length; ++length) {
        for (std::size_t offset = start; offset + length - 1 <= end; ++offset) {
          runs.emplace_back(values.begin() + static_cast<long>(offset),
                            values.begin() + static_cast<long>(offset + length));
        }
      }
    }
    start = end + 1;
  }
  return runs;
}

std::vector<Card> TakeCards(const std::map<int, std::vector<Card>>& groups, const std::vector<int>& values, int count_each) {
  std::vector<Card> cards;
  for (const auto value : values) {
    const auto& bucket = groups.at(value);
    cards.insert(cards.end(), bucket.begin(), bucket.begin() + count_each);
  }
  return cards;
}

std::vector<Card> CollectSinglesExcluding(const std::map<int, std::vector<Card>>& groups, const std::set<int>& excluded) {
  std::vector<Card> cards;
  for (const auto& [value, bucket] : groups) {
    if (excluded.contains(value)) {
      continue;
    }
    cards.push_back(bucket.front());
  }
  return cards;
}

std::vector<std::vector<Card>> CollectPairsExcluding(const std::map<int, std::vector<Card>>& groups, const std::set<int>& excluded) {
  std::vector<std::vector<Card>> pairs;
  for (const auto& [value, bucket] : groups) {
    if (excluded.contains(value) || bucket.size() < 2) {
      continue;
    }
    pairs.push_back({bucket[0], bucket[1]});
  }
  return pairs;
}

std::vector<int> ValuesFromCounts(const std::map<int, std::vector<Card>>& groups, std::size_t exact_count) {
  std::vector<int> values;
  for (const auto& [value, bucket] : groups) {
    if (bucket.size() == exact_count) {
      values.push_back(value);
    }
  }
  return values;
}

}  // namespace

std::vector<Card> BuildDeck() {
  static const std::array<std::string, 4> suits = {"S", "H", "C", "D"};
  static const std::array<std::string, 13> ranks = {
      "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A", "2"};

  std::vector<Card> deck;
  int next_id = 0;
  for (const auto& rank : ranks) {
    for (const auto& suit : suits) {
      deck.push_back(Card{
          .id = "card_" + std::to_string(next_id++),
          .rank = rank,
          .suit = suit,
          .value = RankValue(rank),
      });
    }
  }

  deck.push_back(Card{.id = "joker_small", .rank = "SJ", .suit = "", .value = 16});
  deck.push_back(Card{.id = "joker_big", .rank = "BJ", .suit = "", .value = 17});
  return deck;
}

int CompareCards(const Card& left, const Card& right) {
  if (left.value != right.value) {
    return left.value < right.value ? -1 : 1;
  }
  if (left.suit == right.suit) {
    return 0;
  }
  return left.suit < right.suit ? -1 : 1;
}

CardPattern EvaluatePattern(std::vector<Card> cards) {
  std::sort(cards.begin(), cards.end(), [](const Card& left, const Card& right) {
    return CompareCards(left, right) < 0;
  });

  if (cards.empty()) {
    return MakePattern(PatternType::kInvalid, {}, 0, "invalid");
  }

  const auto groups = GroupByValue(cards);
  std::vector<int> values;
  std::vector<int> counts;
  for (const auto& [value, bucket] : groups) {
    values.push_back(value);
    counts.push_back(static_cast<int>(bucket.size()));
  }
  std::sort(counts.begin(), counts.end());

  if (cards.size() == 1) {
    return MakePattern(PatternType::kSingle, cards, cards.front().value, "single");
  }
  if (cards.size() == 2) {
    if (cards[0].value == 16 && cards[1].value == 17) {
      return MakePattern(PatternType::kRocket, cards, 100, "rocket");
    }
    if (groups.size() == 1U) {
      return MakePattern(PatternType::kPair, cards, cards.front().value, "pair");
    }
  }
  if (cards.size() == 3 && groups.size() == 1U) {
    return MakePattern(PatternType::kTriple, cards, cards.front().value, "triple");
  }
  if (cards.size() == 4) {
    if (groups.size() == 1U) {
      return MakePattern(PatternType::kBomb, cards, cards.front().value, "bomb");
    }
    if (counts == std::vector<int>({1, 3})) {
      const int triple_value = std::find_if(groups.begin(), groups.end(), [](const auto& item) {
                                 return item.second.size() == 3U;
                               })->first;
      return MakePattern(PatternType::kTripleWithSingle, cards, triple_value, "triple_with_single");
    }
  }
  if (cards.size() == 5) {
    if (counts == std::vector<int>({2, 3})) {
      const int triple_value = std::find_if(groups.begin(), groups.end(), [](const auto& item) {
                                 return item.second.size() == 3U;
                               })->first;
      return MakePattern(PatternType::kTripleWithPair, cards, triple_value, "triple_with_pair");
    }
  }
  if (cards.size() == 6 && counts == std::vector<int>({1, 1, 4})) {
    const int bomb_value = std::find_if(groups.begin(), groups.end(), [](const auto& item) {
                             return item.second.size() == 4U;
                           })->first;
    return MakePattern(PatternType::kFourWithTwoSingles, cards, bomb_value, "four_with_two_singles");
  }
  if (cards.size() == 8 && counts == std::vector<int>({2, 2, 4})) {
    const int bomb_value = std::find_if(groups.begin(), groups.end(), [](const auto& item) {
                             return item.second.size() == 4U;
                           })->first;
    return MakePattern(PatternType::kFourWithTwoPairs, cards, bomb_value, "four_with_two_pairs");
  }

  const bool singles_only = std::all_of(groups.begin(), groups.end(), [](const auto& item) {
    return item.second.size() == 1U;
  });
  if (singles_only && cards.size() >= 5 && values.back() < 15 && IsConsecutive(values)) {
    return MakePattern(PatternType::kStraight, cards, values.back(), "straight");
  }

  const bool pairs_only = std::all_of(groups.begin(), groups.end(), [](const auto& item) {
    return item.second.size() == 2U;
  });
  if (pairs_only && cards.size() >= 6 && cards.size() % 2 == 0 && values.back() < 15 && IsConsecutive(values)) {
    return MakePattern(PatternType::kStraightPair, cards, values.back(), "straight_pair");
  }

  std::vector<int> triple_values;
  for (const auto& [value, bucket] : groups) {
    if (bucket.size() >= 3U && value < 15) {
      triple_values.push_back(value);
    }
  }
  if (triple_values.size() >= 2U) {
    const auto runs = FindConsecutiveRuns(triple_values, 2);
    for (const auto& run : runs) {
      const int plane_size = static_cast<int>(run.size());
      if (cards.size() == plane_size * 3) {
        const auto plane_cards = TakeCards(groups, run, 3);
        if (plane_cards.size() == cards.size()) {
          return MakePattern(PatternType::kAirplane, cards, run.back(), "airplane");
        }
      }
      if (cards.size() == plane_size * 4) {
        int single_count = 0;
        bool valid = true;
        for (const auto& [value, bucket] : groups) {
          if (std::find(run.begin(), run.end(), value) != run.end()) {
            if (bucket.size() < 3U) {
              valid = false;
              break;
            }
            continue;
          }
          if (bucket.size() != 1U) {
            valid = false;
            break;
          }
          ++single_count;
        }
        if (valid && single_count == plane_size) {
          return MakePattern(PatternType::kAirplaneWithSingle, cards, run.back(), "airplane_with_single");
        }
      }
      if (cards.size() == plane_size * 5) {
        int pair_count = 0;
        bool valid = true;
        for (const auto& [value, bucket] : groups) {
          if (std::find(run.begin(), run.end(), value) != run.end()) {
            if (bucket.size() < 3U) {
              valid = false;
              break;
            }
            continue;
          }
          if (bucket.size() != 2U) {
            valid = false;
            break;
          }
          ++pair_count;
        }
        if (valid && pair_count == plane_size) {
          return MakePattern(PatternType::kAirplaneWithPair, cards, run.back(), "airplane_with_pair");
        }
      }
    }
  }

  return MakePattern(PatternType::kInvalid, cards, 0, "invalid");
}

std::vector<CardPattern> BuildCandidates(const std::vector<Card>& hand) {
  std::vector<Card> sorted_hand = hand;
  std::sort(sorted_hand.begin(), sorted_hand.end(), [](const Card& left, const Card& right) {
    return CompareCards(left, right) < 0;
  });

  const auto groups = GroupByValue(sorted_hand);
  std::vector<CardPattern> candidates;

  for (const auto& [value, bucket] : groups) {
    (void)value;
    candidates.push_back(EvaluatePattern({bucket[0]}));
    if (bucket.size() >= 2U) {
      candidates.push_back(EvaluatePattern({bucket[0], bucket[1]}));
    }
    if (bucket.size() >= 3U) {
      candidates.push_back(EvaluatePattern({bucket[0], bucket[1], bucket[2]}));
      auto singles = CollectSinglesExcluding(groups, {value});
      for (const auto& single : singles) {
        candidates.push_back(EvaluatePattern({bucket[0], bucket[1], bucket[2], single}));
      }
      auto pairs = CollectPairsExcluding(groups, {value});
      for (const auto& pair : pairs) {
        auto cards = std::vector<Card>{bucket[0], bucket[1], bucket[2]};
        cards.insert(cards.end(), pair.begin(), pair.end());
        candidates.push_back(EvaluatePattern(cards));
      }
    }
    if (bucket.size() == 4U) {
      candidates.push_back(EvaluatePattern(bucket));
      auto singles = CollectSinglesExcluding(groups, {value});
      if (singles.size() >= 2U) {
        for (std::size_t i = 0; i + 1 < singles.size(); ++i) {
          for (std::size_t j = i + 1; j < singles.size(); ++j) {
            auto cards = bucket;
            cards.push_back(singles[i]);
            cards.push_back(singles[j]);
            candidates.push_back(EvaluatePattern(cards));
          }
        }
      }
      auto pairs = CollectPairsExcluding(groups, {value});
      if (pairs.size() >= 2U) {
        for (std::size_t i = 0; i + 1 < pairs.size(); ++i) {
          for (std::size_t j = i + 1; j < pairs.size(); ++j) {
            auto cards = bucket;
            cards.insert(cards.end(), pairs[i].begin(), pairs[i].end());
            cards.insert(cards.end(), pairs[j].begin(), pairs[j].end());
            candidates.push_back(EvaluatePattern(cards));
          }
        }
      }
    }
  }

  if (groups.contains(16) && groups.contains(17)) {
    candidates.push_back(EvaluatePattern({groups.at(16)[0], groups.at(17)[0]}));
  }

  auto single_values = ExtractValuesWithCount(groups, 1);
  single_values.erase(std::remove_if(single_values.begin(), single_values.end(), [](int value) {
                        return value >= 15;
                      }),
                      single_values.end());
  for (const auto& run : FindConsecutiveRuns(single_values, 5)) {
    candidates.push_back(EvaluatePattern(TakeCards(groups, run, 1)));
  }

  auto pair_values = ExtractValuesWithCount(groups, 2);
  pair_values.erase(std::remove_if(pair_values.begin(), pair_values.end(), [](int value) {
                      return value >= 15;
                    }),
                    pair_values.end());
  for (const auto& run : FindConsecutiveRuns(pair_values, 3)) {
    candidates.push_back(EvaluatePattern(TakeCards(groups, run, 2)));
  }

  auto triple_values = ExtractValuesWithCount(groups, 3);
  triple_values.erase(std::remove_if(triple_values.begin(), triple_values.end(), [](int value) {
                        return value >= 15;
                      }),
                      triple_values.end());
  for (const auto& run : FindConsecutiveRuns(triple_values, 2)) {
    const auto triples = TakeCards(groups, run, 3);
    candidates.push_back(EvaluatePattern(triples));

    const std::set<int> excluded(run.begin(), run.end());
    auto singles = CollectSinglesExcluding(groups, excluded);
    if (singles.size() >= run.size()) {
      auto cards = triples;
      cards.insert(cards.end(), singles.begin(), singles.begin() + static_cast<long>(run.size()));
      candidates.push_back(EvaluatePattern(cards));
    }

    auto pairs = CollectPairsExcluding(groups, excluded);
    if (pairs.size() >= run.size()) {
      auto cards = triples;
      for (std::size_t index = 0; index < run.size(); ++index) {
        cards.insert(cards.end(), pairs[index].begin(), pairs[index].end());
      }
      candidates.push_back(EvaluatePattern(cards));
    }
  }

  std::vector<CardPattern> valid_candidates;
  for (const auto& candidate : candidates) {
    if (candidate.type != PatternType::kInvalid) {
      valid_candidates.push_back(candidate);
    }
  }

  std::sort(valid_candidates.begin(), valid_candidates.end(), [](const CardPattern& left, const CardPattern& right) {
    if (left.type != right.type) {
      return static_cast<int>(left.type) < static_cast<int>(right.type);
    }
    if (left.length != right.length) {
      return left.length < right.length;
    }
    return left.weight < right.weight;
  });
  valid_candidates.erase(std::unique(valid_candidates.begin(),
                                     valid_candidates.end(),
                                     [](const CardPattern& left, const CardPattern& right) {
                                       if (left.type != right.type || left.length != right.length ||
                                           left.weight != right.weight || left.cards.size() != right.cards.size()) {
                                         return false;
                                       }
                                       for (std::size_t i = 0; i < left.cards.size(); ++i) {
                                         if (left.cards[i].id != right.cards[i].id) {
                                           return false;
                                         }
                                       }
                                       return true;
                                     }),
                         valid_candidates.end());
  return valid_candidates;
}

bool CanBeat(const CardPattern& candidate, const std::optional<CardPattern>& last_pattern) {
  if (candidate.type == PatternType::kInvalid) {
    return false;
  }
  if (!last_pattern.has_value()) {
    return true;
  }

  const auto& last = *last_pattern;
  if (candidate.type == PatternType::kRocket) {
    return true;
  }
  if (last.type == PatternType::kRocket) {
    return false;
  }
  if (candidate.type == PatternType::kBomb &&
      last.type != PatternType::kBomb &&
      last.type != PatternType::kFourWithTwoSingles &&
      last.type != PatternType::kFourWithTwoPairs) {
    return true;
  }
  if (candidate.type != last.type) {
    return false;
  }
  if (candidate.length != last.length &&
      candidate.type != PatternType::kSingle &&
      candidate.type != PatternType::kPair &&
      candidate.type != PatternType::kTriple &&
      candidate.type != PatternType::kBomb) {
    return false;
  }
  return candidate.weight > last.weight;
}

std::string GenerateId(const std::string& prefix) {
  static std::mt19937_64 engine{std::random_device{}()};
  std::uniform_int_distribution<std::uint64_t> distribution;
  std::ostringstream stream;
  stream << prefix << "_" << std::hex << distribution(engine);
  return stream.str();
}

void FillProtoCard(const Card& source, landlords::protocol::Card* target) {
  target->set_id(source.id);
  target->set_rank(source.rank);
  target->set_suit(source.suit);
  target->set_value(source.value);
}

landlords::protocol::PatternType ToProtoPatternType(PatternType type) {
  switch (type) {
    case PatternType::kSingle:
      return landlords::protocol::PATTERN_TYPE_SINGLE;
    case PatternType::kPair:
      return landlords::protocol::PATTERN_TYPE_PAIR;
    case PatternType::kTriple:
      return landlords::protocol::PATTERN_TYPE_TRIPLE;
    case PatternType::kTripleWithSingle:
      return landlords::protocol::PATTERN_TYPE_TRIPLE_WITH_SINGLE;
    case PatternType::kTripleWithPair:
      return landlords::protocol::PATTERN_TYPE_TRIPLE_WITH_PAIR;
    case PatternType::kStraight:
      return landlords::protocol::PATTERN_TYPE_STRAIGHT;
    case PatternType::kStraightPair:
      return landlords::protocol::PATTERN_TYPE_STRAIGHT_PAIR;
    case PatternType::kAirplane:
      return landlords::protocol::PATTERN_TYPE_AIRPLANE;
    case PatternType::kAirplaneWithSingle:
      return landlords::protocol::PATTERN_TYPE_AIRPLANE_WITH_SINGLE;
    case PatternType::kAirplaneWithPair:
      return landlords::protocol::PATTERN_TYPE_AIRPLANE_WITH_PAIR;
    case PatternType::kBomb:
      return landlords::protocol::PATTERN_TYPE_BOMB;
    case PatternType::kFourWithTwoSingles:
      return landlords::protocol::PATTERN_TYPE_FOUR_WITH_TWO_SINGLES;
    case PatternType::kFourWithTwoPairs:
      return landlords::protocol::PATTERN_TYPE_FOUR_WITH_TWO_PAIRS;
    case PatternType::kRocket:
      return landlords::protocol::PATTERN_TYPE_ROCKET;
    case PatternType::kInvalid:
    default:
      return landlords::protocol::PATTERN_TYPE_UNSPECIFIED;
  }
}

}  // namespace landlords::core
