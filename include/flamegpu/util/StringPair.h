#ifndef INCLUDE_FLAMEGPU_UTIL_STRINGPAIR_H_
#define INCLUDE_FLAMEGPU_UTIL_STRINGPAIR_H_

#include <string>
#include <utility>
#include <map>
#include <unordered_map>

namespace flamegpu {
namespace util {
/**
 * Pair of strings
 */
typedef std::pair<std::string, std::string> StringPair;

/**
 * Compare function so that StringPair can be used in a map
 */
struct StringPairCompare {
    bool operator() (const std::pair<std::string, std::string>& lhs, const std::pair<std::string, std::string>& rhs) const {
        if (lhs.first == rhs.first)
            return lhs.second < rhs.second;
        return lhs.first < rhs.first;
    }
};
/**
 * Hash function so that StringPair can be used as a key in an unordered map
 */
struct StringPairHash {
    size_t operator()(const std::pair<std::string, std::string>& k) const {
        return std::hash<std::string>()(k.first) ^
            (std::hash<std::string>()(k.second) << 1);
    }
};

/**
 * Ordered map with StringPair as the key type
 */
template<typename T>
using StringPairMap = std::map<StringPair, T, StringPairCompare>;

/**
 * Unordered map with StringPair as the key type
 */
template<typename T>
using StringPairUnorderedMap = std::unordered_map<StringPair, T, StringPairHash>;

}  // namespace util
}  // namespace flamegpu

#endif  // INCLUDE_FLAMEGPU_UTIL_STRINGPAIR_H_
