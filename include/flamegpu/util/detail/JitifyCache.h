#ifndef INCLUDE_FLAMEGPU_UTIL_DETAIL_JITIFYCACHE_H_
#define INCLUDE_FLAMEGPU_UTIL_DETAIL_JITIFYCACHE_H_

#include <map>
#include <mutex>
#include <memory>
#include <string>
#include <vector>

#ifdef _MSC_VER
#pragma warning(push, 2)
#include "jitify/jitify.hpp"
#pragma warning(pop)
#else
#include "jitify/jitify.hpp"
#endif

using jitify::experimental::KernelInstantiation;

namespace flamegpu {
namespace util {
namespace detail {

/**
 * Load RTC kernels from in-memory or on-disk cache if an appropriate copy already exists
 * If not, compile and add to both caches
 * Loading an RTC kernel from cache is significantly faster than compiling.
 *
 * This class should sit between FLAMEGPU and Jitify
 */
class JitifyCache {
    /**
     * This structure acts as a key to ensure the cached version is
     * built for the right flamegpu/cuda/kernel
     */
    struct CachedProgram {
        // dynamic header concatenated to kernel
        // We check this is an exact match before loading from cache
        std::string long_reference;
        std::string serialised_kernelinst;
    };

 public:
    /**
     * Returns a unique instance of the passed kernel
     * If this is not found in the in-memory or disk cache it will be compiled which is much slower
     * @param func_name The name of the function (This is only used for error reporting)
     * @param template_args A vector of template arguments for instantiating the kernel.
     * In the case of FLAME GPU 2, these args are likely to be the user defined function_impl and the message i/o types.
     * @param kernel_src Source code for the user defined agent function/condition
     * @param dynamic_header Dynamic header source generated by curve rtc
     * @return A jitify RTC kernel instance of the provided kernel sources
     */
    std::unique_ptr<KernelInstantiation> loadKernel(
        const std::string &func_name,
        const std::vector<std::string> &template_args,
        const std::string &kernel_src,
        const std::string &dynamic_header);
    /**
     * Used to configure whether the in-memory cache is used
     * Defaults to true
     */
    void useMemoryCache(bool yesno);
    /**
     * Returns whether use of the in-memory cache is currently enabled
     */
    bool useMemoryCache() const;
    /**
     * Clears the in-memory cache
     * All kernels loaded after this will need to come from the on-disk cache or be compiled
     */
    void clearMemoryCache();
    /**
     * Used to configure whether the on-disk cache is used
     * Defaults to true
     * @note If disk cache is disabled both importing and exporting cache files to disk will be disabled
     */
    void useDiskCache(bool yesno);
    /**
     * Returns whether use of the on-disk cache is currently enabled
     * @note If disk cache is disabled both importing and exporting cache files to disk will be disabled
     */
    bool useDiskCache() const;
    /**
     * Clears the in-memory cache
     * All kernels loaded after this will need to come from the on-disk cache or be compiled
     * @note Will only clear the cache files used by the current build (debug or release)
     */
    static void clearDiskCache();

 private:
    /**
     * Performs the compilation of a user provided RTC kernel if it has not been found in the cache
     * @param func_name The name of the function (This is only used for error reporting)
     * @param template_args A vector of template arguments for instantiating the kernel.
     * In the case of FLAME GPU 2, these args are likely to be the user defined function_impl and the message i/o types.
     * @param kernel_src Source code for the user defined agent function/condition
     * @param dynamic_header Dynamic header source generated by curve rtc
     * @return A jitify RTC kernel instance of the provided kernel sources
     */
    static std::unique_ptr<KernelInstantiation> compileKernel(
    const std::string &func_name,
    const std::vector<std::string> &template_args,
    const std::string &kernel_src,
    const std::string &dynamic_header);
    /**
     * Fill the provided vector with the list of headers we expect to be loaded
     * This enables Jitify to find all the required headers with less NVRTC calls
     *
     * @param headers The vector to fill.
     *
     * @note At current this method has a static list of headers, which is somewhat fragile to changes to our header hierarchy.
     *       In future, Jitify is planning to rework how it processes headers, so this may be unnecessary.
     * @note Libraries such as GLM, which use relative includes internally cannot easily be optimised in this way
     */
    static void getKnownHeaders(std::vector<std::string> &headers);

    /**
     * In-memory map of cached RTC kernels
     * map<short_reference, program>
     */
    std::map<std::string, CachedProgram> cache{};
    /**
     * Mutex protecting multi-threaded accesses to cache
     */
    mutable std::mutex cache_mutex;

    bool use_memory_cache;
    bool use_disk_cache;

    /**
     * Remainder of class is singleton pattern
     */
    JitifyCache();
    static std::mutex instance_mutex;

 public:
    /**
     * Returns the EnvironmentManager singleton instance
     */
    static JitifyCache& getInstance();
    // Public deleted creates better compiler errors
    JitifyCache(JitifyCache const&) = delete;
    void operator=(JitifyCache const&) = delete;
};

}  // namespace detail
}  // namespace util
}  // namespace flamegpu

#endif  // INCLUDE_FLAMEGPU_UTIL_DETAIL_JITIFYCACHE_H_
