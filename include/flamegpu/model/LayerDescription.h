#ifndef INCLUDE_FLAMEGPU_MODEL_LAYERDESCRIPTION_H_
#define INCLUDE_FLAMEGPU_MODEL_LAYERDESCRIPTION_H_

#include "flamegpu/model/ModelDescription.h"
#include "AgentDescription.h"

struct ModelData;
struct LayerData;

class LayerDescription {
    friend struct LayerData;
    /**
    * Constructors
    */
    LayerDescription(std::weak_ptr<ModelData> _model, LayerData *const data);
    // Copy Construct
    LayerDescription(const LayerDescription &other_layer);
    // Move Construct
    LayerDescription(LayerDescription &&other_layer) noexcept;
    // Copy Assign
    LayerDescription& operator=(const LayerDescription &other_layer);
    // Move Assign
    LayerDescription& operator=(LayerDescription &&other_layer) noexcept;
 public:
    /**
     * Accessors
     */
    template<typename AgentFunction>
    void addAgentFunction(AgentFunction a = AgentFunction());
    void addAgentFunction(const AgentFunctionDescription &afd);
    void addAgentFunction(const std::string &name);
    void addHostFunction(FLAMEGPU_HOST_FUNCTION_POINTER func_p);
    
    /**
     * Const Accessors
     */
     ModelData::size_type getIndex() const;

 private:
    std::weak_ptr<ModelData> model;
    LayerData *const layer;
};


template<typename AgentFunction>
void LayerDescription::addAgentFunction(AgentFunction af) {
    AgentFunctionWrapper * func_compare = &agent_function_wrapper<AgentFunction>;
    // Unsure if implicit template instantion leads to two unique function ptrs
    // Logic dictates that it should work (else compiler would complain duplicate symbols)
    if (auto m = model.lock()) {
        for (auto a : m->agents) {
            for (auto f : a.second->functions) {
                if (f.second->func == func_compare) {
                    if (layer->agent_functions.emplace(f.second).second)
                        return;
                    THROW InvalidAgentFunc("Attempted to add same agent function to same layer twice, "
                        "in LayerDescription::addAgentFunction()\n");
                }
            }
        }
        THROW InvalidAgentFunc("Agent function was not found, "
            "in AgentFunctionDescription::addAgentFunction()\n");
    }
    THROW InvalidParent("Agent parent has expired, "
        "in AgentFunctionDescription::addAgentFunction()\n");
}

#endif  // INCLUDE_FLAMEGPU_MODEL_LAYERDESCRIPTION_H_