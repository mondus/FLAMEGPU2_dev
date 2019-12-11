#include "flamegpu/model/ModelDescription.h"

#include "flamegpu/model/AgentDescription.h"
#include "flamegpu/model/MessageDescription.h"
#include "flamegpu/model/LayerDescription.h"
#include "flamegpu/exception/FGPUException.h"

/**
* Constructors
*/
ModelDescription::ModelDescription(const std::string &model_name)
    : model(new ModelData(model_name)) { }
// Copy Construct
ModelDescription::ModelDescription(const ModelDescription &other_model) {
    // TODO
}
// Move Construct
ModelDescription::ModelDescription(ModelDescription &&other_model)
    : model(move(other_model.model)) {
    // TODO
}
// Copy Assign
ModelDescription& ModelDescription::operator=(const ModelDescription &other_model) {
    // TODO
    return *this;
}
// Move Assign
ModelDescription& ModelDescription::operator=(ModelDescription &&other_model) {
    // TODO
    return *this;
}

/**
* Accessors
*/
AgentDescription& ModelDescription::newAgent(const std::string &agent_name) {
    if(!hasAgent(agent_name)) {
        auto rtn = std::shared_ptr<AgentData>(new AgentData(model, agent_name));
        model->agents.emplace(agent_name, rtn);
        return *rtn->description;
    }
    THROW InvalidAgentName("Agent with name '%s' already exists, "
        "in ModelDescription::newAgent().",
        agent_name.c_str());
}
AgentDescription& ModelDescription::Agent(const std::string &agent_name) {
    auto rtn = model->agents.find(agent_name);
    if (rtn != model->agents.end())
        return *rtn->second->description;
    THROW InvalidAgentName("Agent ('%s') was not found, "
        "in ModelDescription::getAgent().",
        agent_name.c_str());
}
AgentDescription& ModelDescription::cloneAgent(const AgentDescription &agent) {
    // TODO
    return *((*model->agents.begin()).second->description);
}

MessageDescription& ModelDescription::newMessage(const std::string &message_name) {
    if (!hasMessage(message_name)) {
        auto rtn = std::shared_ptr<MessageData>(new MessageData(model, message_name));
        model->messages.emplace(message_name, rtn);
        return *rtn->description;
    }
    THROW InvalidMessageName("Message with name '%s' already exists, "
        "in ModelDescription::newAgent().",
        message_name.c_str());
}
MessageDescription& ModelDescription::Message(const std::string &message_name) {
    auto rtn = model->messages.find(message_name);
    if (rtn != model->messages.end())
        return *rtn->second->description;
    THROW InvalidMessageName("Message ('%s') was not found, "
        "in ModelDescription::Message().",
        message_name.c_str());
}
MessageDescription& ModelDescription::cloneMessage(const MessageDescription &message) {
    // TODO
    return *((*model->messages.begin()).second->description);
}

LayerDescription& ModelDescription::newLayer(const std::string &name) {
    // Ensure name is unique
    if (!name.empty()) {
        for (auto it = model->layers.begin(); it != model->layers.end(); ++it) {
            if ((*it)->name == name) {
                THROW InvalidFuncLayerIndx("Layer ('%s') already exists, "
                    "in ModelDescription::newLayer().",
                    name.c_str());
            }
        }
    }
    auto rtn = std::shared_ptr<LayerData>(new LayerData(model, name, static_cast<unsigned int>(model->layers.size())));
    model->layers.push_back(rtn);
    return *rtn->description;
}
LayerDescription& ModelDescription::Layer(const ModelData::size_type &layer_index) {
    if(model->layers.size()>layer_index) {
        auto it = model->layers.begin();
        for (auto i = 0u; i < layer_index; ++i)
            ++it;
        return *(*it)->description;
    }
    THROW OutOfBoundsException("Layer %d is out of bounds, "
        "in ModelDescription::Layer().",
        layer_index);
}
LayerDescription& ModelDescription::Layer(const std::string &name) {
    if (!name.empty()) { // Can't search for no name, multiple layers might be nameless
            for (auto it = model->layers.begin(); it != model->layers.end(); ++it) {
                if ((*it)->name == name)
                    return *(*it)->description;
            }
    }
    THROW InvalidFuncLayerIndx("Layer '%s' was not found, "
        "in ModelDescription::Layer().",
        name.c_str());
}

void ModelDescription::addInitFunction(const FLAMEGPU_INIT_FUNCTION_POINTER *func_p) {
    if (!model->initFunctions.insert(*func_p).second) {
        THROW InvalidHostFunc("Attempted to add same init function twice,"
            "in ModelDescription::addInitFunction()");
    }
}
void ModelDescription::addStepFunction(const FLAMEGPU_STEP_FUNCTION_POINTER *func_p) {
    if (!model->stepFunctions.insert(*func_p).second) {
        THROW InvalidHostFunc("Attempted to add same step function twice,"
            "in ModelDescription::addStepFunction()");
    }
}
void ModelDescription::addExitFunction(const FLAMEGPU_EXIT_FUNCTION_POINTER *func_p) {
    if (!model->exitFunctions.insert(*func_p).second) {
        THROW InvalidHostFunc("Attempted to add same exit function twice,"
            "in ModelDescription::addExitFunction()");
    }
}
void ModelDescription::addExitCondition(const FLAMEGPU_EXIT_CONDITION_POINTER *func_p) {
    if (!model->exitConditions.insert(*func_p).second) {
        THROW InvalidHostFunc("Attempted to add same exit condition twice,"
            "in ModelDescription::addExitCondition()");
    }
}

EnvironmentDescription& ModelDescription::Environment() {
    return *model->environment;
}
EnvironmentDescription& ModelDescription::cloneEnvironment(const EnvironmentDescription &env) {
    // TODO
    return *this->model->environment;
}

/**
* Const Accessors
*/
std::string ModelDescription::getName() const {
    return model->name;
}

const AgentDescription& ModelDescription::getAgent(const std::string &agent_name) const {
    auto rtn = model->agents.find(agent_name);
    if (rtn != model->agents.end())
        return *rtn->second->description;
    THROW InvalidAgentVar("Agent ('%s') was not found, "
        "in ModelDescription::getAgent().",
        agent_name.c_str());
}
const MessageDescription& ModelDescription::getMessage(const std::string &message_name) const {
    auto rtn = model->messages.find(message_name);
    if (rtn != model->messages.end())
        return *rtn->second->description;
    THROW InvalidMessageVar("Message ('%s') was not found, "
        "in ModelDescription::getMessage().",
        message_name.c_str());
}
const EnvironmentDescription& ModelDescription::getEnvironment() const {
    return *model->environment;
}
const LayerDescription& ModelDescription::getLayer(const std::string &name) const {
    if (!name.empty()) { // Can't search for no name, multiple layers might be nameless
        for (auto it = model->layers.begin(); it != model->layers.end(); ++it) {
            if ((*it)->name == name)
                return *(*it)->description;
        }
    }
    THROW InvalidFuncLayerIndx("Layer ('%s') was not found, "
        "in ModelDescription::getAgent().",
        name.c_str());
}
const LayerDescription& ModelDescription::getLayer(const ModelData::size_type &layer_index) const {
    if (model->layers.size()>layer_index) {
        auto it = model->layers.begin();
        for (auto i = 0u; i < layer_index; ++i)
            ++it;
        return *(*it)->description;
    }
    THROW OutOfBoundsException("Layer %d is out of bounds, "
        "in ModelDescription::Layer().",
        layer_index);
}
bool ModelDescription::hasAgent(const std::string &agent_name) const {
    return model->agents.find(agent_name) != model->agents.end();
}
bool ModelDescription::hasMessage(const std::string &message_name) const {
    return model->messages.find(message_name) != model->messages.end();
}
bool ModelDescription::hasLayer(const std::string &name) const {
    if (!name.empty()) { // Can't search for no name, multiple layers might be nameless
        for (auto it = model->layers.begin(); it != model->layers.end(); ++it) {
            if ((*it)->name == name)
                return true;
        }
    }
    return false;
}
bool ModelDescription::hasLayer(const ModelData::size_type &layer_index) const {
    return model->layers.size() < layer_index;
}

ModelDescription ModelDescription::clone(const std::string &cloned_model_name) const {
    // TODO
    return ModelDescription(cloned_model_name);
}