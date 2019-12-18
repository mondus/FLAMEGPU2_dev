#ifndef INCLUDE_FLAMEGPU_MODEL_AGENTFUNCTIONDESCRIPTION_H_
#define INCLUDE_FLAMEGPU_MODEL_AGENTFUNCTIONDESCRIPTION_H_

#include <string>
#include <memory>

#include "flamegpu/model/ModelDescription.h"
#include "flamegpu/model/AgentDescription.h"
#include "flamegpu/runtime/AgentFunction.h"
#include "flamegpu/model/LayerDescription.h"

class MessageDescription;
struct ModelData;
struct AgentFunctionData;

class AgentFunctionDescription {
    friend struct AgentFunctionData;
    friend void LayerDescription::addAgentFunction(const AgentFunctionDescription &);
    /**
     * Constructors
     */
    AgentFunctionDescription(ModelData *const model, AgentFunctionData *const data);
    // Copy Construct
    AgentFunctionDescription(const AgentFunctionDescription &other_function) = delete;
    // Move Construct
    AgentFunctionDescription(AgentFunctionDescription &&other_function) noexcept = delete;
    // Copy Assign
    AgentFunctionDescription& operator=(const AgentFunctionDescription &other_function) = delete;
    // Move Assign
    AgentFunctionDescription& operator=(AgentFunctionDescription &&other_function) noexcept = delete;

 public:
     bool operator==(const AgentFunctionDescription& rhs) const;
     bool operator!=(const AgentFunctionDescription& rhs) const;

    /**
     * Accessors
     */
    void setInitialState(const std::string &initial_state);
    void setEndState(const std::string &end_state);
    void setMessageInput(const std::string &message_name);
    void setMessageInput(MessageDescription &message);
    void setMessageOutput(const std::string &message_name);
    void setMessageOutput(MessageDescription &message);
    void setMessageOutputOptional(const bool &output_is_optional);
    void setAgentOutput(const std::string &agent_name);
    void setAgentOutput(AgentDescription &agent);
    void setAllowAgentDeath(const bool &has_death);

    MessageDescription &MessageInput();
    MessageDescription &MessageOutput();
    AgentDescription &AgentOutput();
    bool &MessageOutputOptional();
    bool &AllowAgentDeath();

    /**
     * Const Accessors
     */
    std::string getName() const;
    std::string getInitialState() const;
    std::string getEndState() const;
    const MessageDescription &getMessageInput() const;
    const MessageDescription &getMessageOutput() const;
    bool getMessageOutputOptional() const;
    const AgentDescription &getAgentOutput() const;
    bool getAllowAgentDeath() const;

    bool hasMessageInput() const;
    bool hasMessageOutput() const;
    bool hasAgentOutput() const;

    AgentFunctionWrapper *getFunctionPtr() const;

 private:
    ModelData *const model;
    AgentFunctionData *const function;
};

template<typename AgentFunction>
AgentFunctionDescription &AgentDescription::newFunction(const std::string &function_name, AgentFunction) {
    if (agent->functions.find(function_name) == agent->functions.end()) {
        AgentFunctionWrapper *f = &agent_function_wrapper<AgentFunction>;
        auto rtn = std::shared_ptr<AgentFunctionData>(new AgentFunctionData(this->agent->shared_from_this(), function_name, f));
        agent->functions.emplace(function_name, rtn);
        return *rtn->description;
    }
    THROW InvalidAgentFunc("Agent ('%s') already contains function '%s', "
        "in AgentDescription::newFunction().",
        agent->name.c_str(), function_name.c_str());
}
#endif  // INCLUDE_FLAMEGPU_MODEL_AGENTFUNCTIONDESCRIPTION_H_
