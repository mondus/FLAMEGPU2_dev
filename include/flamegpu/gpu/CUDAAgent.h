/**
* @file CUDAAgent.h
* @authors Paul
* @date 5 Mar 2014
* @brief
*
* @see
* @warning
*/

#ifndef INCLUDE_FLAMEGPU_GPU_CUDAAGENT_H_
#define INCLUDE_FLAMEGPU_GPU_CUDAAGENT_H_

#include <memory>
#include <map>
#include <utility>
#include <string>

// include sub classes
#include "flamegpu/gpu/CUDAAgentStateList.h"
#include "flamegpu/sim/AgentInterface.h"

// forward declare classes from other modules
struct AgentData;
struct AgentFunctionData;
class AgentPopulation;
class Curve;

typedef std::map<const std::string, std::unique_ptr<CUDAAgentStateList>> CUDAStateMap;  // map of state name to CUDAAgentStateList which allocates memory on the device
typedef std::pair<const std::string, std::unique_ptr<CUDAAgentStateList>> CUDAStateMapPair;

/** \brief CUDAAgent class is used as a container for storing the GPU data of all variables in all states
 * The CUDAAgent contains a hash index which maps a variable name to a unique index. Each CUDAAgentStateList
 * will use this hash index to map variable names to unique pointers in GPU memory space. This is required so
 * that at runtime a variable name can be related to a unique array of data on the device. It works like a traditional hashmap however the same hashing is used for all states that an agent can be in (as agents have the same variables regardless of state).
 */
class CUDAAgent : public AgentInterface {
 public:
    explicit CUDAAgent(const AgentData& description);
    virtual ~CUDAAgent(void);

    const AgentData& getAgentDescription() const override;

    /* Can be used to override the current population data without reallocating */
    void setPopulationData(const AgentPopulation& population);

    void getPopulationData(AgentPopulation& population);

    unsigned int getMaximumListSize() const;

    /** @brief Uses the cuRVE runtime to map the variables used by the agent function to the cuRVE library so that can be accessed by name within a n agent function
    */
    void mapRuntimeVariables(const AgentFunctionData& func) const;

    /**
     * @brief    Uses the cuRVE runtime to unmap the variables used by the agent function to the cuRVE
     *             library so that they are unavailable to be accessed by name within an agent function.
     *
     * @param    func    The function.
     */

    void unmapRuntimeVariables(const AgentFunctionData& func) const;

    const std::unique_ptr<CUDAAgentStateList> &getAgentStateList(const std::string &state_name) const;

    void *getStateVariablePtr(const std::string &state_name, const std::string &variable_name) override;
    ModelData::size_type getStateSize(const std::string &state_name) const override;

    void process_death(const AgentFunctionData& func, const unsigned int &streamId);

 protected:
    /** @brief    Zero all state variable data. */
    void zeroAllStateVariableData();

 private:
    const AgentData& agent_description;

    CUDAStateMap state_map;

    unsigned int max_list_size;  // The maximum length of the agent variable arrays based on the maximum population size passed to setPopulationData
    /**
     * The number of messages CUB temp has been allocated for
     */
    unsigned int cub_temp_size_max_list_size;
    /**
     * The size of current cub temp allocation
     */
    size_t cub_temp_size;
    /**
     * Pointer to cub memory
     */
    void * d_cub_temp;

    Curve &curve;
};

#endif  // INCLUDE_FLAMEGPU_GPU_CUDAAGENT_H_
