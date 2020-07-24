#include <chrono>
#include <algorithm>

#include "gtest/gtest.h"

#include "flamegpu/flame_api.h"
#include "flamegpu/runtime/flamegpu_api.h"

namespace test_message_array_2d {
    const char *MODEL_NAME = "Model";
    const char *AGENT_NAME = "Agent";
    const char *MESSAGE_NAME = "Message";
    const char *IN_FUNCTION_NAME = "InFunction";
    const char *OUT_FUNCTION_NAME = "OutFunction";
    const char *IN_LAYER_NAME = "InLayer";
    const char *OUT_LAYER_NAME = "OutLayer";
    const unsigned int SQRT_AGENT_COUNT = 12;
    __device__ const unsigned int dSQRT_AGENT_COUNT = 12;
    const unsigned int AGENT_COUNT = SQRT_AGENT_COUNT * (SQRT_AGENT_COUNT + 1);
FLAMEGPU_AGENT_FUNCTION(OutFunction, MsgNone, MsgArray2D) {
    const unsigned int index = FLAMEGPU->getVariable<unsigned int>("message_write");
    FLAMEGPU->message_out.setVariable<unsigned int>("index_times_3", index * 3);
    const unsigned int index_x = index % dSQRT_AGENT_COUNT;
    const unsigned int index_y = index / dSQRT_AGENT_COUNT;
    FLAMEGPU->message_out.setIndex(index_x, index_y);
    return ALIVE;
}
FLAMEGPU_AGENT_FUNCTION(OutOptionalFunction, MsgNone, MsgArray2D) {
    const unsigned int index = FLAMEGPU->getVariable<unsigned int>("message_write");
    if (index % 2 == 0) {
        FLAMEGPU->message_out.setVariable<unsigned int>("index_times_3", index * 3);
        const unsigned int index_x = index % dSQRT_AGENT_COUNT;
        const unsigned int index_y = index / dSQRT_AGENT_COUNT;
        FLAMEGPU->message_out.setIndex(index_x, index_y);
    }
    return ALIVE;
}
FLAMEGPU_AGENT_FUNCTION(OutBad, MsgNone, MsgArray2D) {
    unsigned int index = FLAMEGPU->getVariable<unsigned int>("message_write");
    FLAMEGPU->message_out.setVariable<unsigned int>("index_times_3", index * 3);
    index = index == 13 ? 0 : index;
    const unsigned int index_x = index % dSQRT_AGENT_COUNT;
    const unsigned int index_y = index / dSQRT_AGENT_COUNT;
    FLAMEGPU->message_out.setIndex(index_x, index_y);
    return ALIVE;
}
FLAMEGPU_AGENT_FUNCTION(InFunction, MsgArray2D, MsgNone) {
    const unsigned int my_index = FLAMEGPU->getVariable<unsigned int>("index");
    const unsigned int index_x = my_index % dSQRT_AGENT_COUNT;
    const unsigned int index_y = my_index / dSQRT_AGENT_COUNT;
    const auto &message = FLAMEGPU->message_in.at(index_x, index_y);
    FLAMEGPU->setVariable("message_read", message.getVariable<unsigned int>("index_times_3"));
    return ALIVE;
}
TEST(TestMessage_Array2D, Mandatory) {
    ModelDescription m(MODEL_NAME);
    MsgArray2D::Description &msg = m.newMessage<MsgArray2D>(MESSAGE_NAME);
    msg.setDimensions(SQRT_AGENT_COUNT, SQRT_AGENT_COUNT + 1);
    msg.newVariable<unsigned int>("index_times_3");
    AgentDescription &a = m.newAgent(AGENT_NAME);
    a.newVariable<unsigned int>("index");
    a.newVariable<unsigned int>("message_read", UINT_MAX);
    a.newVariable<unsigned int>("message_write");
    AgentFunctionDescription &fo = a.newFunction(OUT_FUNCTION_NAME, OutFunction);
    fo.setMessageOutput(msg);
    AgentFunctionDescription &fi = a.newFunction(IN_FUNCTION_NAME, InFunction);
    fi.setMessageInput(msg);
    LayerDescription &lo = m.newLayer(OUT_LAYER_NAME);
    lo.addAgentFunction(fo);
    LayerDescription &li = m.newLayer(IN_LAYER_NAME);
    li.addAgentFunction(fi);
    // Create a list of numbers
    std::array<unsigned int, AGENT_COUNT> numbers;
    for (unsigned int i = 0; i < AGENT_COUNT; ++i) {
        numbers[i] = i;
    }
    // Shuffle the list of numbers
    const unsigned seed = static_cast<unsigned int>(std::chrono::system_clock::now().time_since_epoch().count());
    std::shuffle(numbers.begin(), numbers.end(), std::default_random_engine(seed));
    // Assign the numbers in shuffled order to agents
    AgentPopulation pop(a, AGENT_COUNT);
    for (unsigned int i = 0; i < AGENT_COUNT; ++i) {
        AgentInstance ai = pop.getNextInstance();
        ai.setVariable<unsigned int>("index", i);
        ai.setVariable<unsigned int>("message_read", UINT_MAX);
        ai.setVariable<unsigned int>("message_write", numbers[i]);
    }
    // Set pop in model
    CUDAAgentModel c(m);
    c.setPopulationData(pop);
    c.step();
    c.getPopulationData(pop);
    // Validate each agent has same result
    for (unsigned int i = 0; i < AGENT_COUNT; ++i) {
        AgentInstance ai = pop.getInstanceAt(i);
        const unsigned int index = ai.getVariable<unsigned int>("index");
        const unsigned int message_read = ai.getVariable<unsigned int>("message_read");
        EXPECT_EQ(index * 3, message_read);
    }
}
TEST(TestMessage_Array2D, Optional) {
    ModelDescription m(MODEL_NAME);
    MsgArray2D::Description &msg = m.newMessage<MsgArray2D>(MESSAGE_NAME);
    msg.setDimensions(SQRT_AGENT_COUNT, SQRT_AGENT_COUNT + 1);
    msg.newVariable<unsigned int>("index_times_3");
    AgentDescription &a = m.newAgent(AGENT_NAME);
    a.newVariable<unsigned int>("index");
    a.newVariable<unsigned int>("message_read", UINT_MAX);
    a.newVariable<unsigned int>("message_write");
    AgentFunctionDescription &fo = a.newFunction(OUT_FUNCTION_NAME, OutOptionalFunction);
    fo.setMessageOutput(msg);
    fo.setMessageOutputOptional(true);
    AgentFunctionDescription &fi = a.newFunction(IN_FUNCTION_NAME, InFunction);
    fi.setMessageInput(msg);
    LayerDescription &lo = m.newLayer(OUT_LAYER_NAME);
    lo.addAgentFunction(fo);
    LayerDescription &li = m.newLayer(IN_LAYER_NAME);
    li.addAgentFunction(fi);
    // Create a list of numbers
    std::array<unsigned int, AGENT_COUNT> numbers;
    for (unsigned int i = 0; i < AGENT_COUNT; ++i) {
        numbers[i] = i;
    }
    // Shuffle the list of numbers
    const unsigned seed = static_cast<unsigned int>(std::chrono::system_clock::now().time_since_epoch().count());
    std::shuffle(numbers.begin(), numbers.end(), std::default_random_engine(seed));
    // Assign the numbers in shuffled order to agents
    AgentPopulation pop(a, AGENT_COUNT);
    for (unsigned int i = 0; i < AGENT_COUNT; ++i) {
        AgentInstance ai = pop.getNextInstance();
        ai.setVariable<unsigned int>("index", i);
        ai.setVariable<unsigned int>("message_read", UINT_MAX);
        ai.setVariable<unsigned int>("message_write", numbers[i]);
    }
    // Set pop in model
    CUDAAgentModel c(m);
    c.setPopulationData(pop);
    c.step();
    c.getPopulationData(pop);
    // Validate each agent has same result
    // Validate each agent has same result
    for (unsigned int i = 0; i < AGENT_COUNT; ++i) {
        AgentInstance ai = pop.getInstanceAt(i);
        unsigned int index = ai.getVariable<unsigned int>("index");
        const unsigned int message_read = ai.getVariable<unsigned int>("message_read");
        index = index % 2 == 0 ? index : 0;
        EXPECT_EQ(index * 3, message_read);
    }
}

FLAMEGPU_AGENT_FUNCTION(OutSimple, MsgNone, MsgArray2D) {
    const unsigned int index = FLAMEGPU->getVariable<unsigned int>("index");
    const unsigned int index_x = index % dSQRT_AGENT_COUNT;
    const unsigned int index_y = index / dSQRT_AGENT_COUNT;
    FLAMEGPU->message_out.setIndex(index_x, index_y);
    return ALIVE;
}
FLAMEGPU_AGENT_FUNCTION(MooreTest1, MsgArray2D, MsgNone) {
    const unsigned int my_index = FLAMEGPU->getVariable<unsigned int>("index");
    const unsigned int index_x = my_index % dSQRT_AGENT_COUNT;
    const unsigned int index_y = my_index / dSQRT_AGENT_COUNT;

    // Iterate and check it aligns
    auto filter = FLAMEGPU->message_in(index_x, index_y);
    auto msg = filter.begin();
    unsigned int message_read = 0;
    for (int i = -1; i <= 1; ++i) {
        for (int j = -1; j <= 1; ++j) {
            // Skip ourself
            if (!(i == 0 && j == 0)) {
                // Wrap over boundaries
                const unsigned int their_x = (index_x + i + FLAMEGPU->message_in.getDimX()) % FLAMEGPU->message_in.getDimX();
                const unsigned int their_y = (index_y + j + FLAMEGPU->message_in.getDimY()) % FLAMEGPU->message_in.getDimY();
                if (msg->getX() == their_x && msg->getY() == their_y)
                    message_read++;
                ++msg;
            }
        }
    }
    if (msg == filter.end())
        message_read++;
    FLAMEGPU->setVariable<unsigned int>("message_read", message_read);
    return ALIVE;
}
FLAMEGPU_AGENT_FUNCTION(MooreTest2, MsgArray2D, MsgNone) {
    const unsigned int my_index = FLAMEGPU->getVariable<unsigned int>("index");
    const unsigned int index_x = my_index % dSQRT_AGENT_COUNT;
    const unsigned int index_y = my_index / dSQRT_AGENT_COUNT;

    // Iterate and check it aligns
    auto filter = FLAMEGPU->message_in(index_x, index_y, 2);
    auto msg = filter.begin();
    unsigned int message_read = 0;
    for (int i = -2; i <= 2; ++i) {
        for (int j = -2; j <= 2; ++j) {
            // Skip ourself
            if (!(i == 0 && j == 0)) {
                // Wrap over boundaries
                const unsigned int their_x = (index_x + i + FLAMEGPU->message_in.getDimX()) % FLAMEGPU->message_in.getDimX();
                const unsigned int their_y = (index_y + j + FLAMEGPU->message_in.getDimY()) % FLAMEGPU->message_in.getDimY();
                if (msg->getX() == their_x && msg->getY() == their_y)
                    message_read++;
                ++msg;
            }
        }
    }
    if (msg == filter.end())
        message_read++;
    FLAMEGPU->setVariable<unsigned int>("message_read", message_read);
    return ALIVE;
}
TEST(TestMessage_Array2D, Moore1) {
    ModelDescription m(MODEL_NAME);
    MsgArray2D::Description &msg = m.newMessage<MsgArray2D>(MESSAGE_NAME);
    msg.setDimensions(SQRT_AGENT_COUNT, SQRT_AGENT_COUNT + 1);
    AgentDescription &a = m.newAgent(AGENT_NAME);
    a.newVariable<unsigned int>("index");
    a.newVariable<unsigned int>("message_read", UINT_MAX);
    AgentFunctionDescription &fo = a.newFunction(OUT_FUNCTION_NAME, OutSimple);
    fo.setMessageOutput(msg);
    AgentFunctionDescription &fi = a.newFunction(IN_FUNCTION_NAME, MooreTest1);
    fi.setMessageInput(msg);
    LayerDescription &lo = m.newLayer(OUT_LAYER_NAME);
    lo.addAgentFunction(fo);
    LayerDescription &li = m.newLayer(IN_LAYER_NAME);
    li.addAgentFunction(fi);
    // Assign the numbers in shuffled order to agents
    AgentPopulation pop(a, AGENT_COUNT);
    for (unsigned int i = 0; i < AGENT_COUNT; ++i) {
        AgentInstance ai = pop.getNextInstance();
        ai.setVariable<unsigned int>("index", i);
        ai.setVariable<unsigned int>("message_read", UINT_MAX);
    }
    // Set pop in model
    CUDAAgentModel c(m);
    c.setPopulationData(pop);
    c.step();
    c.getPopulationData(pop);
    // Validate each agent has read 8 correct messages
    for (unsigned int i = 0; i < AGENT_COUNT; ++i) {
        AgentInstance ai = pop.getInstanceAt(i);
        const unsigned int message_read = ai.getVariable<unsigned int>("message_read");
        EXPECT_EQ(9u, message_read);
    }
}
TEST(TestMessage_Array2D, Moore2) {
    ModelDescription m(MODEL_NAME);
    MsgArray2D::Description &msg = m.newMessage<MsgArray2D>(MESSAGE_NAME);
    msg.setDimensions(SQRT_AGENT_COUNT, SQRT_AGENT_COUNT + 1);
    AgentDescription &a = m.newAgent(AGENT_NAME);
    a.newVariable<unsigned int>("index");
    a.newVariable<unsigned int>("message_read", UINT_MAX);
    AgentFunctionDescription &fo = a.newFunction(OUT_FUNCTION_NAME, OutSimple);
    fo.setMessageOutput(msg);
    AgentFunctionDescription &fi = a.newFunction(IN_FUNCTION_NAME, MooreTest2);
    fi.setMessageInput(msg);
    LayerDescription &lo = m.newLayer(OUT_LAYER_NAME);
    lo.addAgentFunction(fo);
    LayerDescription &li = m.newLayer(IN_LAYER_NAME);
    li.addAgentFunction(fi);
    // Assign the numbers in shuffled order to agents
    AgentPopulation pop(a, AGENT_COUNT);
    for (unsigned int i = 0; i < AGENT_COUNT; ++i) {
        AgentInstance ai = pop.getNextInstance();
        ai.setVariable<unsigned int>("index", i);
        ai.setVariable<unsigned int>("message_read", UINT_MAX);
    }
    // Set pop in model
    CUDAAgentModel c(m);
    c.setPopulationData(pop);
    c.step();
    c.getPopulationData(pop);
    // Validate each agent has read 8 correct messages
    for (unsigned int i = 0; i < AGENT_COUNT; ++i) {
        AgentInstance ai = pop.getInstanceAt(i);
        const unsigned int message_read = ai.getVariable<unsigned int>("message_read");
        EXPECT_EQ(25u, message_read);
    }
}

// Exception tests
#ifndef NO_SEATBELTS
TEST(TestMessage_Array2D, DuplicateOutputException) {
#else
TEST(TestMessage_Array2D, DISABLED_DuplicateOutputException) {
#endif
    ModelDescription m(MODEL_NAME);
    MsgArray2D::Description &msg = m.newMessage<MsgArray2D>(MESSAGE_NAME);
    msg.setDimensions(SQRT_AGENT_COUNT, SQRT_AGENT_COUNT + 1);
    msg.newVariable<unsigned int>("index_times_3");
    AgentDescription &a = m.newAgent(AGENT_NAME);
    a.newVariable<unsigned int>("index");
    a.newVariable<unsigned int>("message_read", UINT_MAX);
    a.newVariable<unsigned int>("message_write");
    AgentFunctionDescription &fo = a.newFunction(OUT_FUNCTION_NAME, OutBad);
    fo.setMessageOutput(msg);
    AgentFunctionDescription &fi = a.newFunction(IN_FUNCTION_NAME, InFunction);
    fi.setMessageInput(msg);
    LayerDescription &lo = m.newLayer(OUT_LAYER_NAME);
    lo.addAgentFunction(fo);
    LayerDescription &li = m.newLayer(IN_LAYER_NAME);
    li.addAgentFunction(fi);
    // Create a list of numbers
    std::array<unsigned int, AGENT_COUNT> numbers;
    for (unsigned int i = 0; i < AGENT_COUNT; ++i) {
        numbers[i] = i;
    }
    // Shuffle the list of numbers
    const unsigned seed = static_cast<unsigned int>(std::chrono::system_clock::now().time_since_epoch().count());
    std::shuffle(numbers.begin(), numbers.end(), std::default_random_engine(seed));
    // Assign the numbers in shuffled order to agents
    AgentPopulation pop(a, AGENT_COUNT);
    for (unsigned int i = 0; i < AGENT_COUNT; ++i) {
        AgentInstance ai = pop.getNextInstance();
        ai.setVariable<unsigned int>("index", i);
        ai.setVariable<unsigned int>("message_read", UINT_MAX);
        ai.setVariable<unsigned int>("message_write", numbers[i]);
    }
    // Set pop in model
    CUDAAgentModel c(m);
    c.setPopulationData(pop);
    EXPECT_THROW(c.step(), ArrayMessageWriteConflict);
}
TEST(TestMessage_Array2D, ArrayLenZeroException) {
    ModelDescription m(MODEL_NAME);
    MsgArray2D::Description &msg = m.newMessage<MsgArray2D>(MESSAGE_NAME);
    EXPECT_THROW(msg.setDimensions(0, SQRT_AGENT_COUNT), InvalidArgument);
    EXPECT_THROW(msg.setDimensions({ 0, SQRT_AGENT_COUNT }), InvalidArgument);
    EXPECT_THROW(msg.setDimensions(SQRT_AGENT_COUNT, 0), InvalidArgument);
    EXPECT_THROW(msg.setDimensions({ SQRT_AGENT_COUNT, 0 }), InvalidArgument);
}
TEST(TestMessage_Array2D, UnsetDimensions) {
    ModelDescription model(MODEL_NAME);
    model.newMessage<MsgArray2D>(MESSAGE_NAME);
    // message.setDimensions(5, 5);  // Intentionally commented out
    EXPECT_THROW(CUDAAgentModel m(model), InvalidMessage);
}
TEST(TestMessage_Array2D, reserved_name) {
    ModelDescription model(MODEL_NAME);
    MsgArray2D::Description &message = model.newMessage<MsgArray2D>(MESSAGE_NAME);
    EXPECT_THROW(message.newVariable<int>("_"), ReservedName);
}
FLAMEGPU_AGENT_FUNCTION(countArray2D, MsgArray2D, MsgNone) {
    unsigned int value = FLAMEGPU->message_in.at(0, 0).getVariable<unsigned int>("value");
    FLAMEGPU->setVariable<unsigned int>("value", value);
    return ALIVE;
}
TEST(TestMessage_Array2D, ReadEmpty) {
// What happens if we read a message list before it has been output?
    ModelDescription model("Model");
    {   // Location message
        MsgArray2D::Description &message = model.newMessage<MsgArray2D>("location");
        message.setDimensions(2, 2);
        message.newVariable<int>("id");  // unused by current test
        message.newVariable<unsigned int>("value");  // unused by current test
    }
    {   // Circle agent
        AgentDescription &agent = model.newAgent("agent");
        agent.newVariable<unsigned int>("value", 32323);  // Count the number of messages read
        agent.newFunction("in", countArray2D).setMessageInput("location");
    }
    {   // Layer #1
        LayerDescription &layer = model.newLayer();
        layer.addAgentFunction(countArray2D);
    }
    // Create 1 agent
    AgentPopulation pop_in(model.Agent("agent"), 1);
    pop_in.getNextInstance();
    CUDAAgentModel cuda_model(model);
    cuda_model.setPopulationData(pop_in);
    // Execute model
    EXPECT_NO_THROW(cuda_model.step());
    // Check result
    AgentPopulation pop_out(model.Agent("agent"), 1);
    pop_out.getNextInstance().setVariable<unsigned int>("value", 22221);
    cuda_model.getPopulationData(pop_out);
    EXPECT_EQ(pop_out.getCurrentListSize(), 1u);
    auto ai = pop_out.getInstanceAt(0);
    EXPECT_EQ(ai.getVariable<unsigned int>("value"), 0u);  // Unset array msgs should be 0
}

}  // namespace test_message_array_2d
