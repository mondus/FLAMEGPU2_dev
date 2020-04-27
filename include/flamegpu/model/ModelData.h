#ifndef INCLUDE_FLAMEGPU_MODEL_MODELDATA_H_
#define INCLUDE_FLAMEGPU_MODEL_MODELDATA_H_

#include <unordered_map>
#include <list>
#include <memory>
#include <typeindex>
#include <set>
#include <string>

#include "flamegpu/model/EnvironmentDescription.h"
#include "flamegpu/runtime/flamegpu_host_api_macros.h"  // Todo replace with std/cub style fns (see AgentFunction.h)
#include "flamegpu/runtime/messaging/BruteForce.h"

class EnvironmentDescription;
struct AgentData;
struct LayerData;

/**
 * This is the internal data store for ModelDescription
 * Users should only access that data stored within via an instance of ModelDescription
 */
struct ModelData : std::enable_shared_from_this<ModelData>{
    virtual ~ModelData();
    /**
     * Default state, all agents and agent functions begin in/with this state
     */
    static const char *DEFAULT_STATE;  // "default"
    /**
     * Description needs full access
     */
    friend class ModelDescription;
    /**
     * Common size type used in the definition of models
     */
    typedef unsigned int size_type;
    /**
     * Map of name:agent definition
     * map<string, AgentData>
     */
    typedef std::unordered_map<std::string, std::shared_ptr<AgentData>> AgentMap;
    /**
     * Map of name:message definition
     * map<string, MessageData>
     */
    typedef std::unordered_map<std::string, std::shared_ptr<MsgBruteForce::Data>> MessageMap;
    /**
     * List of layer definitions
     * list<LayerData>
     */
    typedef std::list<std::shared_ptr<LayerData>> LayerList;
    /**
     * Set of Init function pointers
     * set<FLAMEGPU_INIT_FUNCTION_POINTER>
     */
    typedef std::set<FLAMEGPU_INIT_FUNCTION_POINTER> InitFunctionSet;
    /**
     * Set of Step function pointers
     * set<FLAMEGPU_STEP_FUNCTION_POINTER>
     */
    typedef std::set<FLAMEGPU_STEP_FUNCTION_POINTER> StepFunctionSet;
    /**
     * Set of Exit function pointers
     * set<FLAMEGPU_EXIT_FUNCTION_POINTER>
     */
    typedef std::set<FLAMEGPU_EXIT_FUNCTION_POINTER> ExitFunctionSet;
    /**
     * Set of Exit condition pointers
     * set<FLAMEGPU_EXIT_CONDITION_POINTER>
     */
    typedef std::set<FLAMEGPU_EXIT_CONDITION_POINTER> ExitConditionSet;

    /**
     * Holds all of the model's agent definitions
     */
    AgentMap agents;
    /**
     * Holds all of the model's message definitions
     */
    MessageMap messages;
    /**
     * Holds all of the model's layer definitions
     */
    LayerList layers;
    /**
     * Holds pointers to all of the init functions used by the model
     */
    InitFunctionSet initFunctions;
    /**
     * Holds pointers to all of the step functions used by the model
     */
    StepFunctionSet stepFunctions;
    /**
     * Holds pointers to all of the exit functions used by the model
     */
    ExitFunctionSet exitFunctions;
    /**
     * Holds pointers to all of the exit conditions used by the model
     */
    ExitConditionSet exitConditions;
    /**
     * Holds all of the model's environment property definitions
     */
    std::unique_ptr<EnvironmentDescription> environment;  // TODO: Move this to same Data:Description format
    /**
     * The name of the model
     * This must be unique among Simulation (e.g. CUDAAgentModel) instances
     */
    std::string name;
    /**
     * Creates a copy of the entire model definition hierarchy
     * This is called when a ModelDescription is passed to a Simulation (e.g. CUDAAgentModel)
     */
    std::shared_ptr<ModelData> clone() const;
    /**
     * Equality operator, checks whether ModelData hierarchies are functionally the same
     * @returns True when models are the same
     * @note Instead compare pointers if you wish to check that they are the same instance
     */
    bool operator==(const ModelData& rhs) const;
    /**
     * Equality operator, checks whether ModelData hierarchies are functionally different
     * @returns True when models are not the same
     * @note Instead compare pointers if you wish to check that they are not the same instance
     */
    bool operator!=(const ModelData& rhs) const;

 protected:
    /**
     * Copy constructor
     * This should only be called via clone();
     */
    explicit ModelData(const ModelData &other);
    /**
     * Normal constructor
     * This should only be called by ModelDescription
     */
    explicit ModelData(const std::string &model_name);
};

#endif  // INCLUDE_FLAMEGPU_MODEL_MODELDATA_H_
