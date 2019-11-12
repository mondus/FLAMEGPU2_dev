#ifndef INCLUDE_FLAMEGPU_RUNTIME_FLAMEGPU_HOST_AGENT_API_H_
#define INCLUDE_FLAMEGPU_RUNTIME_FLAMEGPU_HOST_AGENT_API_H_
#ifdef _MSC_VER
#pragma warning(push, 3)
#include <cub/cub.cuh>
#pragma warning(pop)
#else
#include <cub/cub.cuh>
#endif
#include <algorithm>
#include <string>
#include <vector>


#include "flamegpu/gpu/CUDAAgent.h"
#include "flamegpu/model/AgentDescription.h"
#include "flamegpu/runtime/flamegpu_host_api.h"
#include "flamegpu/gpu/CUDAErrorChecking.h"

#define FLAMEGPU_CUSTOM_REDUCTION(funcName, a, b) \
struct funcName ## _impl { \
    template <typename T> \
    __device__ __forceinline__ T operator()(const T &, const T &) const;\
}; \
funcName ## _impl funcName; \
template <typename T> \
__device__ __forceinline__ T funcName ## _impl::operator()(const T & a, const T & b) const

class FLAMEGPU_HOST_AGENT_API {
 public:
    FLAMEGPU_HOST_AGENT_API(FLAMEGPU_HOST_API &_api, const CUDAAgent &_agent, const std::string &_stateName = "default")
        :api(_api),
        agent(_agent),
        hasState(true),
        stateName(_stateName) {
    }
    /*FLAMEGPU_HOST_AGENT_API(const CUDAAgent &_agent)
        :agent(_agent),
        hasState(false),
        stateName("") {

    }*/
    /**
     * Wraps cub::DeviceReduce::Sum()
     * @param variable The agent variable to perform the sum reduction across
     */
    template<typename T>
    T sum(const std::string &variable) const;
    /**
     * Wraps cub::DeviceReduce::Min()
     * @param variable The agent variable to perform the min reduction across
     */
    template<typename T>
    T min(const std::string &variable) const;
    /**
     * Wraps cub::DeviceReduce::Max()
     * @param variable The agent variable to perform the max reduction across
     */
    template<typename T>
    T max(const std::string &variable) const;
    /**
     * Wraps cub::DeviceReduce::Reduce(), to perform a reduction with a custom operator
     * @param variable The agent variable to perform the reduction across
     * @param reductionOperator The custom reduction function
     * @param init Initial value of the reduction
     */
    template<typename T, typename reductionOperatorT>
    T reduce(const std::string &variable, reductionOperatorT reductionOperator, const T&init) const;
    /**
     * Wraps cub::DeviceHistogram::HistogramEven()
     * @param variable The agent variable to perform the reduction across
     * @param histogramBins The number of bins the histogram should have
     * @param lowerBound The lower sample value boundary of lowest bin
     * @param upperBound The upper sample value boundary of upper bin
     */
    template<typename T>
    std::vector<int> histogramEven(const std::string &variable, const unsigned int &histogramBins, const T &lowerBound, const T &upperBound) const;

 private:
    FLAMEGPU_HOST_API &api;
    const CUDAAgent &agent;
    bool hasState;
    const std::string stateName;
};

//
// Implementation
//

template<typename T>
T FLAMEGPU_HOST_AGENT_API::sum(const std::string &variable) const {
    const auto &agentDesc = agent.getAgentDescription();
    if (typeid(T) != agentDesc.getVariableType(variable))
        throw InvalidVarType("variable type does not match type of sum()");
    const auto &stateAgent = agent.getAgentStateList(stateName);
    void *var_ptr = stateAgent->getAgentListVariablePointer(variable);
    const auto agentCount = stateAgent->getCUDAStateListSize();
    // Check if we need to resize cub storage
    FLAMEGPU_HOST_API::CUB_Config cc = { FLAMEGPU_HOST_API::SUM, typeid(T).hash_code() };
    if (api.tempStorageRequiresResize(cc, agentCount)) {
        // Resize cub storage
        size_t tempByte = 0;
        cub::DeviceReduce::Sum(nullptr, tempByte, reinterpret_cast<T*>(var_ptr), reinterpret_cast<T*>(api.d_output_space), static_cast<int>(agentCount));
        api.resizeTempStorage(cc, agentCount, tempByte);
    }
    // Resize output storage
    api.resizeOutputSpace<T>();
    cub::DeviceReduce::Sum(api.d_cub_temp, api.d_cub_temp_size, reinterpret_cast<T*>(var_ptr), reinterpret_cast<T*>(api.d_output_space), static_cast<int>(agentCount));
    gpuErrchkLaunch();
    T rtn;
    gpuErrchk(cudaMemcpy(&rtn, api.d_output_space, sizeof(T), cudaMemcpyDeviceToHost));
    return rtn;
}
template<typename T>
T FLAMEGPU_HOST_AGENT_API::min(const std::string &variable) const {
    const auto &agentDesc = agent.getAgentDescription();
    if (typeid(T) != agentDesc.getVariableType(variable))
        throw InvalidVarType("variable type does not match type of min()");
    const auto &stateAgent = agent.getAgentStateList(stateName);
    void *var_ptr = stateAgent->getAgentListVariablePointer(variable);
    const auto agentCount = stateAgent->getCUDAStateListSize();
    // Check if we need to resize cub storage
    FLAMEGPU_HOST_API::CUB_Config cc = { FLAMEGPU_HOST_API::MIN, typeid(T).hash_code() };
    if (api.tempStorageRequiresResize(cc, agentCount)) {
        // Resize cub storage
        size_t tempByte = 0;
        cub::DeviceReduce::Min(nullptr, tempByte, reinterpret_cast<T*>(var_ptr), reinterpret_cast<T*>(api.d_output_space), static_cast<int>(agentCount));
        gpuErrchkLaunch();
        api.resizeTempStorage(cc, agentCount, tempByte);
    }
    // Resize output storage
    api.resizeOutputSpace<T>();
    cub::DeviceReduce::Min(api.d_cub_temp, api.d_cub_temp_size, reinterpret_cast<T*>(var_ptr), reinterpret_cast<T*>(api.d_output_space), static_cast<int>(agentCount));
    gpuErrchkLaunch();
    T rtn;
    gpuErrchk(cudaMemcpy(&rtn, api.d_output_space, sizeof(T), cudaMemcpyDeviceToHost));
    return rtn;
}
template<typename T>
T FLAMEGPU_HOST_AGENT_API::max(const std::string &variable) const {
    const auto &agentDesc = agent.getAgentDescription();
    if (typeid(T) != agentDesc.getVariableType(variable))
        throw InvalidVarType("variable type does not match type of max()");
    const auto &stateAgent = agent.getAgentStateList(stateName);
    void *var_ptr = stateAgent->getAgentListVariablePointer(variable);
    const auto agentCount = stateAgent->getCUDAStateListSize();
    // Check if we need to resize cub storage
    FLAMEGPU_HOST_API::CUB_Config cc = { FLAMEGPU_HOST_API::MAX, typeid(T).hash_code() };
    if (api.tempStorageRequiresResize(cc, agentCount)) {
        // Resize cub storage
        size_t tempByte = 0;
        cub::DeviceReduce::Max(nullptr, tempByte, reinterpret_cast<T*>(var_ptr), reinterpret_cast<T*>(api.d_output_space), static_cast<int>(agentCount));
        gpuErrchkLaunch();
        api.resizeTempStorage(cc, agentCount, tempByte);
    }
    // Resize output storage
    api.resizeOutputSpace<T>();
    cub::DeviceReduce::Max(api.d_cub_temp, api.d_cub_temp_size, reinterpret_cast<T*>(var_ptr), reinterpret_cast<T*>(api.d_output_space), static_cast<int>(agentCount));
    gpuErrchkLaunch();
    T rtn;
    gpuErrchk(cudaMemcpy(&rtn, api.d_output_space, sizeof(T), cudaMemcpyDeviceToHost));
    return rtn;
}
template<typename T, typename reductionOperatorT>
T FLAMEGPU_HOST_AGENT_API::reduce(const std::string &variable, reductionOperatorT reductionOperator, const T &init) const {
    const auto &agentDesc = agent.getAgentDescription();
    if (typeid(T) != agentDesc.getVariableType(variable))
        throw InvalidVarType("variable type does not match type of reduce()");
    const auto &stateAgent = agent.getAgentStateList(stateName);
    void *var_ptr = stateAgent->getAgentListVariablePointer(variable);
    const auto agentCount = stateAgent->getCUDAStateListSize();
    // Check if we need to resize cub storage
    FLAMEGPU_HOST_API::CUB_Config cc = { FLAMEGPU_HOST_API::CUSTOM_REDUCE, typeid(T).hash_code() };
    if (api.tempStorageRequiresResize(cc, agentCount)) {
        // Resize cub storage
        size_t tempByte = 0;
        cub::DeviceReduce::Reduce(nullptr, tempByte, reinterpret_cast<T*>(var_ptr), reinterpret_cast<T*>(api.d_output_space), static_cast<int>(agentCount), reductionOperator, init);
        gpuErrchkLaunch();
        api.resizeTempStorage(cc, agentCount, tempByte);
    }
    // Resize output storage
    api.resizeOutputSpace<T>();
    cub::DeviceReduce::Reduce(api.d_cub_temp, api.d_cub_temp_size, reinterpret_cast<T*>(var_ptr), reinterpret_cast<T*>(api.d_output_space), static_cast<int>(agentCount), reductionOperator, init);
    gpuErrchkLaunch();
    T rtn;
    gpuErrchk(cudaMemcpy(&rtn, api.d_output_space, sizeof(T), cudaMemcpyDeviceToHost));
    return rtn;
}
template<typename T>
std::vector<int> FLAMEGPU_HOST_AGENT_API::histogramEven(const std::string &variable, const unsigned int &histogramBins, const T &lowerBound, const T &upperBound) const {
    assert(lowerBound < upperBound);
    const auto &agentDesc = agent.getAgentDescription();
    if (typeid(T) != agentDesc.getVariableType(variable))
        throw InvalidVarType("variable type does not match type of histogramEven()");
    const auto &stateAgent = agent.getAgentStateList(stateName);
    void *var_ptr = stateAgent->getAgentListVariablePointer(variable);
    const auto agentCount = stateAgent->getCUDAStateListSize();
    // Check if we need to resize cub storage
    FLAMEGPU_HOST_API::CUB_Config cc = { FLAMEGPU_HOST_API::HISTOGRAM_EVEN, histogramBins };
    if (api.tempStorageRequiresResize(cc, agentCount)) {
        // Resize cub storage
        size_t tempByte = 0;
        cub::DeviceHistogram::HistogramEven(nullptr, tempByte,
            reinterpret_cast<T*>(var_ptr), reinterpret_cast<int*>(api.d_output_space), histogramBins + 1, lowerBound, upperBound, static_cast<int>(agentCount));
        gpuErrchkLaunch();
        api.resizeTempStorage(cc, agentCount, tempByte);
    }
    // Resize output storage
    api.resizeOutputSpace<int>(histogramBins);
    cub::DeviceHistogram::HistogramEven(api.d_cub_temp, api.d_cub_temp_size,
        reinterpret_cast<T*>(var_ptr), reinterpret_cast<int*>(api.d_output_space), histogramBins + 1, lowerBound, upperBound, static_cast<int>(agentCount));
    gpuErrchkLaunch();
    std::vector<int> rtn(histogramBins);
    gpuErrchk(cudaMemcpy(rtn.data(), api.d_output_space, histogramBins * sizeof(int), cudaMemcpyDeviceToHost));
    return rtn;
}
#endif  // INCLUDE_FLAMEGPU_RUNTIME_FLAMEGPU_HOST_AGENT_API_H_
