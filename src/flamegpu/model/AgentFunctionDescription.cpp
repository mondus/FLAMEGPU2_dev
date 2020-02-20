#include "flamegpu/model/AgentFunctionDescription.h"
#include "flamegpu/model/MessageDescription.h"

/**
 * Constructors
 */

#include <nvrtc.h>
#include <cuda.h>
#include <iostream>

AgentFunctionDescription::AgentFunctionDescription(ModelData *const _model, AgentFunctionData *const description)
    : model(_model)
    , function(description) { }

bool AgentFunctionDescription::operator==(const AgentFunctionDescription& rhs) const {
    return *this->function == *rhs.function;  // Compare content is functionally the same
}
bool AgentFunctionDescription::operator!=(const AgentFunctionDescription& rhs) const {
    return !(*this == rhs);
}

/**
 * Accessors
 */
void AgentFunctionDescription::setInitialState(const std::string &init_state) {
    if (auto p = function->parent.lock()) {
        if (p->description->hasState(init_state)) {
            this->function->initial_state = init_state;
        } else {
            THROW InvalidStateName("Agent ('%s') does not contain state '%s', "
                "in AgentFunctionDescription::setInitialState()\n",
                p->name.c_str(), init_state.c_str());
        }
    } else {
        THROW InvalidParent("Agent parent has expired, "
            "in AgentFunctionDescription::setInitialState()\n");
    }
}
void AgentFunctionDescription::setEndState(const std::string &exit_state) {
    if (auto p = function->parent.lock()) {
        if (p->description->hasState(exit_state)) {
            this->function->end_state = exit_state;
        } else {
            THROW InvalidStateName("Agent ('%s') does not contain state '%s', "
                "in AgentFunctionDescription::setEndState()\n",
                p->name.c_str(), exit_state.c_str());
        }
    } else {
        THROW InvalidParent("Agent parent has expired, "
            "in AgentFunctionDescription::setEndState()\n");
    }
}
void AgentFunctionDescription::setMessageInput(const std::string &message_name) {
    if (auto other = function->message_output.lock()) {
        if (message_name == other->name) {
            THROW InvalidMessageName("Message '%s' is already bound as message output in agent function %s, "
                "the same message cannot be input and output by the same function, "
                "in AgentFunctionDescription::setMessageInput()\n",
                message_name.c_str(), function->name.c_str());
        }
    }
    auto a = model->messages.find(message_name);
    if (a != model->messages.end()) {
        this->function->message_input = a->second;
    } else {
        THROW InvalidMessageName("Model ('%s') does not contain message '%s', "
            "in AgentFunctionDescription::setMessageInput()\n",
            model->name.c_str(), message_name.c_str());
    }
}
void AgentFunctionDescription::setMessageInput(MessageDescription &message) {
    if (message.model != function->description->model) {
        THROW DifferentModel("Attempted to use agent description from a different model, "
            "in AgentFunctionDescription::setAgentOutput()\n");
    }
    if (auto other = function->message_output.lock()) {
        if (message.getName() == other->name) {
            THROW InvalidMessageName("Message '%s' is already bound as message output in agent function %s, "
                "the same message cannot be input and output by the same function, "
                "in AgentFunctionDescription::setMessageInput()\n",
                message.getName().c_str(), function->name.c_str());
        }
    }
    auto a = model->messages.find(message.getName());
    if (a != model->messages.end()) {
        if (a->second->description.get() == &message) {
            this->function->message_input = a->second;
        } else {
            THROW InvalidMessage("Message '%s' is not from Model '%s', "
                "in AgentFunctionDescription::setMessageInput()\n",
                message.getName().c_str(), model->name.c_str());
        }
    } else {
        THROW InvalidMessageName("Model ('%s') does not contain message '%s', "
            "in AgentFunctionDescription::setMessageInput()\n",
            model->name.c_str(), message.getName().c_str());
    }
}
void AgentFunctionDescription::setMessageOutput(const std::string &message_name) {
    if (auto other = function->message_input.lock()) {
        if (message_name == other->name) {
            THROW InvalidMessageName("Message '%s' is already bound as message input in agent function %s, "
                "the same message cannot be input and output by the same function, "
                "in AgentFunctionDescription::setMessageOutput()\n",
                message_name.c_str(), function->name.c_str());
        }
    }
    // Clear old value
    if (this->function->message_output_optional) {
        if (auto b = this->function->message_output.lock()) {
            b->optional_outputs--;
        }
    }
    auto a = model->messages.find(message_name);
    if (a != model->messages.end()) {
        this->function->message_output = a->second;
        if (this->function->message_output_optional) {
            a->second->optional_outputs++;
        }
    } else {
        THROW InvalidMessageName("Model ('%s') does not contain message '%s', "
            "in AgentFunctionDescription::setMessageOutput()\n",
            model->name.c_str(), message_name.c_str());
    }
}
void AgentFunctionDescription::setMessageOutput(MessageDescription &message) {
    if (message.model != function->description->model) {
        THROW DifferentModel("Attempted to use agent description from a different model, "
            "in AgentFunctionDescription::setAgentOutput()\n");
    }
    if (auto other = function->message_input.lock()) {
        if (message.getName() == other->name) {
            THROW InvalidMessageName("Message '%s' is already bound as message input in agent function %s, "
                "the same message cannot be input and output by the same function, "
                "in AgentFunctionDescription::setMessageOutput()\n",
                message.getName().c_str(), function->name.c_str());
        }
    }
    // Clear old value
    if (this->function->message_output_optional) {
        if (auto b = this->function->message_output.lock()) {
            b->optional_outputs--;
        }
    }
    auto a = model->messages.find(message.getName());
    if (a != model->messages.end()) {
        if (a->second->description.get() == &message) {
            this->function->message_output = a->second;
            if (this->function->message_output_optional) {
                a->second->optional_outputs++;
            }
        } else {
            THROW InvalidMessage("Message '%s' is not from Model '%s', "
                "in AgentFunctionDescription::setMessageOutput()\n",
                message.getName().c_str(), model->name.c_str());
        }
    } else {
        THROW InvalidMessageName("Model ('%s') does not contain message '%s', "
            "in AgentFunctionDescription::setMessageOutput()\n",
            model->name.c_str(), message.getName().c_str());
    }
}
void AgentFunctionDescription::setMessageOutputOptional(const bool &output_is_optional) {
    if (output_is_optional != this->function->message_output_optional) {
        this->function->message_output_optional = output_is_optional;
        if (auto b = this->function->message_output.lock()) {
            if (output_is_optional)
                b->optional_outputs++;
            else
                b->optional_outputs--;
        }
    }
}
void AgentFunctionDescription::setAgentOutput(const std::string &agent_name) {
    // Clear old value
    if (auto b = this->function->agent_output.lock()) {
        b->agent_outputs--;
    }
    // Set new
    auto a = model->agents.find(agent_name);
    if (a != model->agents.end()) {
        this->function->agent_output = a->second;
        a->second->agent_outputs++;  // Mark inside agent that we are using it as an output
    } else {
        THROW InvalidAgentName("Model ('%s') does not contain agent '%s', "
            "in AgentFunctionDescription::setAgentOutput()\n",
            model->name.c_str(), agent_name.c_str());
    }
}
void AgentFunctionDescription::setAgentOutput(AgentDescription &agent) {
    if (agent.model != function->description->model) {
        THROW DifferentModel("Attempted to use agent description from a different model, "
            "in AgentFunctionDescription::setAgentOutput()\n");
    }
    // Clear old value
    if (auto b = this->function->agent_output.lock()) {
        b->agent_outputs--;
    }
    // Set new
    auto a = model->agents.find(agent.getName());
    if (a != model->agents.end()) {
        if (a->second->description.get() == &agent) {
            this->function->agent_output = a->second;
            a->second->agent_outputs++;  // Mark inside agent that we are using it as an output
        } else {
            THROW InvalidMessage("Agent '%s' is not from Model '%s', "
                "in AgentFunctionDescription::setAgentOutput()\n",
                agent.getName().c_str(), model->name.c_str());
        }
    } else {
        THROW InvalidMessageName("Model ('%s') does not contain agent '%s', "
            "in AgentFunctionDescription::setAgentOutput()\n",
            model->name.c_str(), agent.getName().c_str());
    }
}
void AgentFunctionDescription::setAllowAgentDeath(const bool &has_death) {
    function->has_agent_death = has_death;
}

MessageDescription &AgentFunctionDescription::MessageInput() {
    if (auto m = function->message_input.lock())
        return *m->description;
    THROW OutOfBoundsException("Message input has not been set, "
        "in AgentFunctionDescription::MessageInput()\n");
}
MessageDescription &AgentFunctionDescription::MessageOutput() {
    if (auto m = function->message_output.lock())
        return *m->description;
    THROW OutOfBoundsException("Message output has not been set, "
        "in AgentFunctionDescription::MessageOutput()\n");
}
AgentDescription &AgentFunctionDescription::AgentOutput() {
    if (auto a = function->agent_output.lock())
        return *a->description;
    THROW OutOfBoundsException("Agent output has not been set, "
        "in AgentFunctionDescription::AgentOutput()\n");
}
bool &AgentFunctionDescription::MessageOutputOptional() {
    return function->message_output_optional;
}
bool &AgentFunctionDescription::AllowAgentDeath() {
    return function->has_agent_death;
}

/**
 * Const Accessors
 */
std::string AgentFunctionDescription::getName() const {
    return function->name;
}
std::string AgentFunctionDescription::getInitialState() const {
    return function->initial_state;
}
std::string AgentFunctionDescription::getEndState() const {
    return function->end_state;
}
const MessageDescription &AgentFunctionDescription::getMessageInput() const {
    if (auto m = function->message_input.lock())
        return *m->description;
    THROW OutOfBoundsException("Message input has not been set, "
        "in AgentFunctionDescription::getMessageInput()\n");
}
const MessageDescription &AgentFunctionDescription::getMessageOutput() const {
    if (auto m = function->message_output.lock())
        return *m->description;
    THROW OutOfBoundsException("Message output has not been set, "
        "in AgentFunctionDescription::getMessageOutput()\n");
}
bool AgentFunctionDescription::getMessageOutputOptional() const {
    return this->function->message_output_optional;
}
const AgentDescription &AgentFunctionDescription::getAgentOutput() const {
    if (auto a = function->agent_output.lock())
        return *a->description;
    THROW OutOfBoundsException("Agent output has not been set, "
        "in AgentFunctionDescription::getAgentOutput()\n");
}
bool AgentFunctionDescription::getAllowAgentDeath() const {
    return function->has_agent_death;
}

bool AgentFunctionDescription::hasMessageInput() const {
    return function->message_input.lock() != nullptr;
}
bool AgentFunctionDescription::hasMessageOutput() const {
    return function->message_output.lock() != nullptr;
}
bool AgentFunctionDescription::hasAgentOutput() const {
    return function->agent_output.lock() != nullptr;
}
AgentFunctionWrapper *AgentFunctionDescription::getFunctionPtr() const {
    return function->func;
}

// TODO: Ditch the helper macros
#define NVRTC_SAFE_CALL(x) \
 do { \
     nvrtcResult result = x; \
     if (result != NVRTC_SUCCESS) { \
         std::cerr << "\nerror: " #x " failed with error " \
         << nvrtcGetErrorString(result) << '\n'; \
         exit(1); \
     } \
 } while(0)

#define CUDA_SAFE_CALL(x) \
 do { \
     CUresult result = x; \
     if (result != CUDA_SUCCESS) { \
         const char *msg; \
         cuGetErrorName(result, &msg); \
         std::cerr << "\nerror: " #x " failed with error " \
         << msg << '\n'; \
         exit(1); \
     } \
 } while(0)


AgentFunctionDescription& AgentDescription::newRTFunction(const std::string& function_name, const char* func_src) {
    if (agent->functions.find(function_name) == agent->functions.end()) {

        nvrtcProgram prog;
        NVRTC_SAFE_CALL(
            nvrtcCreateProgram(&prog, // prog
                func_src, // buffer
                "rt_functions.cu", // name
                0, // numHeaders
                NULL, // headers
                NULL)); // includeNames
                
        const char* opts[] = { "--gpu-architecture=compute_75" };
        nvrtcResult compileResult = nvrtcCompileProgram(prog, // prog
            1, // numOptions
            opts); // options
            


        if (compileResult != NVRTC_SUCCESS) {

            // Obtain compilation log from the program.
            size_t logSize;
            NVRTC_SAFE_CALL(nvrtcGetProgramLogSize(prog, &logSize));
            char* log = new char[logSize];
            NVRTC_SAFE_CALL(nvrtcGetProgramLog(prog, log));
            std::cout << log << '\n';
            delete[] log;

            THROW RTAgentFuncCompilationError("Runtime Agent function had compilation errors, "
                "in AgentDescription::newRTFunction()\n");
        }

        // Obtain PTX from the program.
        size_t ptxSize;
        NVRTC_SAFE_CALL(nvrtcGetPTXSize(prog, &ptxSize));
        char* ptx = new char[ptxSize];
        NVRTC_SAFE_CALL(nvrtcGetPTX(prog, ptx));

        // Destroy the program.
        NVRTC_SAFE_CALL(nvrtcDestroyProgram(&prog));

        // Load the generated PTX and get a handle to the agent wrapper kernel.
        CUdevice cuDevice;
        CUcontext context;
        CUmodule module;
        CUfunction kernel;

        cudaFree(0); // create runtime context if does not already exist
        //TODO: No mixing of compiletime and runtime functions
        //TODO: configuration must specify device id
        CUDA_SAFE_CALL(cuInit(0));
        
        CUDA_SAFE_CALL(cuDeviceGet(&cuDevice, 0));
        //CUDA_SAFE_CALL(cuCtxCreate(&context, 0, cuDevice));
        CUDA_SAFE_CALL(cuDevicePrimaryCtxRetain(&context, cuDevice));    //get context from runtime api
        CUDA_SAFE_CALL(cuModuleLoadDataEx(&module, ptx, 0, 0, 0));
        CUDA_SAFE_CALL(cuModuleGetFunction(&kernel, module, "simple_test"));    //TODO: This is assuming a simple kernel that does nothing and has no headers or wrapper

        auto rtn = std::shared_ptr<AgentFunctionData>(new AgentFunctionData(this->agent->shared_from_this(), function_name, kernel));
        agent->functions.emplace(function_name, rtn);
        return *rtn->description;
    }
    THROW InvalidAgentFunc("Agent ('%s') already contains function '%s', "
        "in AgentDescription::newFunction().",
        agent->name.c_str(), function_name.c_str());
}