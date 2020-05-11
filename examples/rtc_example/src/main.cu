/******************************************************************************
 * main.cu is a host function that prepares data array and passes it to the CUDA kernel.
 * This main.cu would either be specified by a user or automatically generated from the model.xml.
 * Each of the API functions will have a 121 mapping with XML elements
 * The API is very similar to FLAME 2. The directory structure and general project is set out very similarly.

 * Single Agent model example

 ******************************************************************************
 * Author  Paul Richmond, Mozhgan Kabiri Chimeh
 * Date    Feb 2017
 *****************************************************************************/

#include "flamegpu/flame_api.h"


/* must be compiled separately using FLAME GPU builder
 * This will generate object files for different architecture targets as well as ptx info for each agent function (registers, memory use etc.)
 * http://stackoverflow.com/questions/12388207/interpreting-output-of-ptxas-options-v
 */

#define AGENT_COUNT 32
#define EXPECT_EQ(x, y) if (x != y) printf("%d not equal to %d", x, y)


const char* rtc_func = R"###(
FLAMEGPU_AGENT_FUNCTION(rtc_test_func, MsgNone, MsgNone) {
    int64_t a_out = FLAMEGPU->environment.get<int64_t>("a");
    int contains_a = FLAMEGPU->environment.contains("a");
    FLAMEGPU->setVariable<int64_t>("a_out", a_out);
    FLAMEGPU->setVariable<int>("contains_a", contains_a);
    return ALIVE;
}
)###";

/**
 * Test an RTC function to an agent function condition (where the condition is not compiled using RTC)
 */
int main() {

    ModelDescription model("model");
    AgentDescription &agent = model.newAgent("agent_name");
    EnvironmentDescription& env = model.Environment();
    env.add<int64_t>("a", 12);
    agent.newVariable<int64_t>("a_out");
    agent.newVariable<int>("contains_1");
    // add RTC agent function
    AgentFunctionDescription &func = agent.newRTCFunction("rtc_test_func", rtc_func);
    func.setAllowAgentDeath(false);
    model.newLayer().addAgentFunction(func);
    // Init pop
    AgentPopulation init_population(agent, 1);
    // Setup Model
    CUDAAgentModel cuda_model(model);
    cuda_model.setPopulationData(init_population);
    // Run 1 step to ensure agent function compiles and runs
    cuda_model.step();
}
