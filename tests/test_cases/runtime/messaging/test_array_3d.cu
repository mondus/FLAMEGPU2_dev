#include <chrono>
#include <algorithm>

#include "flamegpu/flame_api.h"
#include "flamegpu/runtime/flamegpu_api.h"

#include "gtest/gtest.h"

namespace test_message_array_3d {
    const char *MODEL_NAME = "Model";
    const char *AGENT_NAME = "Agent";
    const char *MESSAGE_NAME = "Message";
    const char *IN_FUNCTION_NAME = "InFunction";
    const char *OUT_FUNCTION_NAME = "OutFunction";
    const char *IN_LAYER_NAME = "InLayer";
    const char *OUT_LAYER_NAME = "OutLayer";
    const unsigned int CBRT_AGENT_COUNT = 6;
    __device__ const unsigned int dCBRT_AGENT_COUNT = 6;
    const unsigned int AGENT_COUNT = CBRT_AGENT_COUNT * (CBRT_AGENT_COUNT + 2) * (CBRT_AGENT_COUNT+1);
FLAMEGPU_AGENT_FUNCTION(OutFunction, MsgNone, MsgArray3D) {
    const unsigned int index = FLAMEGPU->getVariable<unsigned int>("message_write");
    FLAMEGPU->message_out.setVariable<unsigned int>("index_times_3", index * 3);
    const unsigned int index_x = index % (dCBRT_AGENT_COUNT);
    const unsigned int index_y = (index / dCBRT_AGENT_COUNT) % (dCBRT_AGENT_COUNT + 1);
    const unsigned int index_z = index / ((dCBRT_AGENT_COUNT) * (dCBRT_AGENT_COUNT + 1));
    FLAMEGPU->message_out.setIndex(index_x, index_y, index_z);
    return ALIVE;
}
FLAMEGPU_AGENT_FUNCTION(OutOptionalFunction, MsgNone, MsgArray3D) {
    const unsigned int index = FLAMEGPU->getVariable<unsigned int>("message_write");
    if (index % 2 == 0) {
        FLAMEGPU->message_out.setVariable<unsigned int>("index_times_3", index * 3);
        const unsigned int index_x = index % (dCBRT_AGENT_COUNT);
        const unsigned int index_y = (index / dCBRT_AGENT_COUNT) % (dCBRT_AGENT_COUNT + 1);
        const unsigned int index_z = index / ((dCBRT_AGENT_COUNT) * (dCBRT_AGENT_COUNT + 1));
        FLAMEGPU->message_out.setIndex(index_x, index_y, index_z);
    }
    return ALIVE;
}
FLAMEGPU_AGENT_FUNCTION(OutOptionalNoneFunction, MsgNone, MsgArray3D) {
    return ALIVE;
}
FLAMEGPU_AGENT_FUNCTION(OutBad, MsgNone, MsgArray3D) {
    unsigned int index = FLAMEGPU->getVariable<unsigned int>("message_write");
    FLAMEGPU->message_out.setVariable<unsigned int>("index_times_3", index * 3);
    index = index == 13 ? 0 : index;
    const unsigned int index_x = index % (dCBRT_AGENT_COUNT);
    const unsigned int index_y = (index / dCBRT_AGENT_COUNT) % (dCBRT_AGENT_COUNT + 1);
    const unsigned int index_z = index / ((dCBRT_AGENT_COUNT) * (dCBRT_AGENT_COUNT + 1));
    FLAMEGPU->message_out.setIndex(index_x, index_y, index_z);
    return ALIVE;
}
FLAMEGPU_AGENT_FUNCTION(InFunction, MsgArray3D, MsgNone) {
    const unsigned int my_index = FLAMEGPU->getVariable<unsigned int>("index");
    const unsigned int index_x = my_index % (dCBRT_AGENT_COUNT);
    const unsigned int index_y = (my_index / dCBRT_AGENT_COUNT) % (dCBRT_AGENT_COUNT + 1);
    const unsigned int index_z = my_index / ((dCBRT_AGENT_COUNT) * (dCBRT_AGENT_COUNT + 1));
    const auto &message = FLAMEGPU->message_in.at(index_x, index_y, index_z);
    FLAMEGPU->setVariable("message_read", message.getVariable<unsigned int>("index_times_3"));
    return ALIVE;
}
TEST(TestMessage_Array3D, Mandatory) {
    ModelDescription m(MODEL_NAME);
    MsgArray3D::Description &msg = m.newMessage<MsgArray3D>(MESSAGE_NAME);
    msg.setDimensions(CBRT_AGENT_COUNT, CBRT_AGENT_COUNT + 1, CBRT_AGENT_COUNT + 2);
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
    AgentVector pop(a, AGENT_COUNT);
    for (unsigned int i = 0; i < AGENT_COUNT; ++i) {
        AgentVector::Agent ai = pop[i];
        ai.setVariable<unsigned int>("index", i);
        ai.setVariable<unsigned int>("message_read", UINT_MAX);
        ai.setVariable<unsigned int>("message_write", numbers[i]);
    }
    // Set pop in model
    CUDASimulation c(m);
    c.setPopulationData(pop);
    c.step();
    c.getPopulationData(pop);
    // Validate each agent has same result
    for (AgentVector::Agent ai : pop) {
        const unsigned int index = ai.getVariable<unsigned int>("index");
        const unsigned int message_read = ai.getVariable<unsigned int>("message_read");
        EXPECT_EQ(index * 3, message_read);
    }
}
TEST(TestMessage_Array3D, Optional) {
    ModelDescription m(MODEL_NAME);
    MsgArray3D::Description &msg = m.newMessage<MsgArray3D>(MESSAGE_NAME);
    msg.setDimensions(CBRT_AGENT_COUNT, CBRT_AGENT_COUNT + 1, CBRT_AGENT_COUNT + 2);
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
    AgentVector pop(a, AGENT_COUNT);
    for (unsigned int i = 0; i < AGENT_COUNT; ++i) {
        AgentVector::Agent ai = pop[i];
        ai.setVariable<unsigned int>("index", i);
        ai.setVariable<unsigned int>("message_read", UINT_MAX);
        ai.setVariable<unsigned int>("message_write", numbers[i]);
    }
    // Set pop in model
    CUDASimulation c(m);
    c.setPopulationData(pop);
    c.step();
    c.getPopulationData(pop);
    // Validate each agent has same result
    for (AgentVector::Agent ai : pop) {
        unsigned int index = ai.getVariable<unsigned int>("index");
        const unsigned int message_read = ai.getVariable<unsigned int>("message_read");
        index = index % 2 == 0 ? index : 0;
        EXPECT_EQ(index * 3, message_read);
    }
}
// Test optional message output, wehre no messages are output.
TEST(TestMessage_Array3D, OptionalNone) {
    ModelDescription m(MODEL_NAME);
    MsgArray3D::Description &msg = m.newMessage<MsgArray3D>(MESSAGE_NAME);
    msg.setDimensions(CBRT_AGENT_COUNT, CBRT_AGENT_COUNT + 1, CBRT_AGENT_COUNT + 2);
    msg.newVariable<unsigned int>("index_times_3");
    AgentDescription &a = m.newAgent(AGENT_NAME);
    a.newVariable<unsigned int>("index");
    a.newVariable<unsigned int>("message_read", UINT_MAX);
    a.newVariable<unsigned int>("message_write");
    AgentFunctionDescription &fo = a.newFunction(OUT_FUNCTION_NAME, OutOptionalNoneFunction);
    fo.setMessageOutput(msg);
    fo.setMessageOutputOptional(true);
    AgentFunctionDescription &fi = a.newFunction(IN_FUNCTION_NAME, InFunction);
    fi.setMessageInput(msg);
    LayerDescription &lo = m.newLayer(OUT_LAYER_NAME);
    lo.addAgentFunction(fo);
    LayerDescription &li = m.newLayer(IN_LAYER_NAME);
    li.addAgentFunction(fi);

    // Generate an arbitrary population.
    AgentVector pop(a, AGENT_COUNT);
    for (unsigned int i = 0; i < AGENT_COUNT; ++i) {
        AgentVector::Agent ai = pop[i];
        ai.setVariable<unsigned int>("index", i);
        ai.setVariable<unsigned int>("message_read", UINT_MAX);
    }
    // Set pop in model
    CUDASimulation c(m);
    c.setPopulationData(pop);
    c.step();
    c.getPopulationData(pop);
    // Validate each agent has same result
    for (AgentVector::Agent ai : pop) {
        const unsigned int message_read = ai.getVariable<unsigned int>("message_read");
        // no messages should have been read.
        EXPECT_EQ(0u, message_read);
    }
}

FLAMEGPU_AGENT_FUNCTION(OutSimple, MsgNone, MsgArray3D) {
    const unsigned int index = FLAMEGPU->getVariable<unsigned int>("index");
    const unsigned int index_x = index % (dCBRT_AGENT_COUNT);
    const unsigned int index_y = (index / dCBRT_AGENT_COUNT) % (dCBRT_AGENT_COUNT + 1);
    const unsigned int index_z = index / ((dCBRT_AGENT_COUNT) * (dCBRT_AGENT_COUNT + 1));
    FLAMEGPU->message_out.setIndex(index_x, index_y, index_z);
    return ALIVE;
}
FLAMEGPU_AGENT_FUNCTION(MooreTest1, MsgArray3D, MsgNone) {
    const unsigned int my_index = FLAMEGPU->getVariable<unsigned int>("index");
    const unsigned int index_x = my_index % (dCBRT_AGENT_COUNT);
    const unsigned int index_y = (my_index / dCBRT_AGENT_COUNT) % (dCBRT_AGENT_COUNT + 1);
    const unsigned int index_z = my_index / ((dCBRT_AGENT_COUNT) * (dCBRT_AGENT_COUNT + 1));

    // Iterate and check it aligns
    auto filter = FLAMEGPU->message_in(index_x, index_y, index_z);
    auto msg = filter.begin();
    unsigned int message_read = 0;
    for (int i = -1; i <= 1; ++i) {
        for (int j = -1; j <= 1; ++j) {
            for (int k = -1; k <= 1; ++k) {
                // Skip ourself
                if (!(i == 0 && j == 0 && k == 0)) {
                    // Wrap over boundaries
                    const unsigned int their_x = (index_x + i + FLAMEGPU->message_in.getDimX()) % FLAMEGPU->message_in.getDimX();
                    const unsigned int their_y = (index_y + j + FLAMEGPU->message_in.getDimY()) % FLAMEGPU->message_in.getDimY();
                    const unsigned int their_z = (index_z + k + FLAMEGPU->message_in.getDimZ()) % FLAMEGPU->message_in.getDimZ();
                    if (msg->getX() == their_x && msg->getY() == their_y && msg->getZ() == their_z)
                        message_read++;
                    ++msg;
                }
            }
        }
    }
    if (msg == filter.end())
        message_read++;
    FLAMEGPU->setVariable<unsigned int>("message_read", message_read);
    return ALIVE;
}
FLAMEGPU_AGENT_FUNCTION(MooreTest2, MsgArray3D, MsgNone) {
    const unsigned int my_index = FLAMEGPU->getVariable<unsigned int>("index");
    const unsigned int index_x = my_index % (dCBRT_AGENT_COUNT);
    const unsigned int index_y = (my_index / dCBRT_AGENT_COUNT) % (dCBRT_AGENT_COUNT + 1);
    const unsigned int index_z = my_index / ((dCBRT_AGENT_COUNT) * (dCBRT_AGENT_COUNT + 1));

    // Iterate and check it aligns
    auto filter = FLAMEGPU->message_in(index_x, index_y, index_z, 2);
    auto msg = filter.begin();
    unsigned int message_read = 0;
    for (int i = -2; i <= 2; ++i) {
        for (int j = -2; j <= 2; ++j) {
            for (int k = -2; k <= 2; ++k) {
                // Skip ourself
                if (!(i == 0 && j == 0 && k == 0)) {
                    // Wrap over boundaries
                    const unsigned int their_x = (index_x + i + FLAMEGPU->message_in.getDimX()) % FLAMEGPU->message_in.getDimX();
                    const unsigned int their_y = (index_y + j + FLAMEGPU->message_in.getDimY()) % FLAMEGPU->message_in.getDimY();
                    const unsigned int their_z = (index_z + k + FLAMEGPU->message_in.getDimZ()) % FLAMEGPU->message_in.getDimZ();
                    if (msg->getX() == their_x && msg->getY() == their_y && msg->getZ() == their_z)
                        message_read++;
                    ++msg;
                }
            }
        }
    }
    if (msg == filter.end())
        message_read++;
    FLAMEGPU->setVariable<unsigned int>("message_read", message_read);
    return ALIVE;
}
TEST(TestMessage_Array3D, Moore1) {
    ModelDescription m(MODEL_NAME);
    MsgArray3D::Description &msg = m.newMessage<MsgArray3D>(MESSAGE_NAME);
    msg.setDimensions(CBRT_AGENT_COUNT, CBRT_AGENT_COUNT + 1, CBRT_AGENT_COUNT + 2);
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
    AgentVector pop(a, AGENT_COUNT);
    for (unsigned int i = 0; i < AGENT_COUNT; ++i) {
        AgentVector::Agent ai = pop[i];
        ai.setVariable<unsigned int>("index", i);
        ai.setVariable<unsigned int>("message_read", UINT_MAX);
    }
    // Set pop in model
    CUDASimulation c(m);
    c.setPopulationData(pop);
    c.step();
    c.getPopulationData(pop);
    // Validate each agent has read 8 correct messages
    for (AgentVector::Agent ai : pop) {
        const unsigned int message_read = ai.getVariable<unsigned int>("message_read");
        EXPECT_EQ(27u, message_read);  // @todo This actually should be 26?
    }
}
TEST(TestMessage_Array3D, Moore2) {
    ModelDescription m(MODEL_NAME);
    MsgArray3D::Description &msg = m.newMessage<MsgArray3D>(MESSAGE_NAME);
    msg.setDimensions(CBRT_AGENT_COUNT, CBRT_AGENT_COUNT + 1, CBRT_AGENT_COUNT + 2);
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
    AgentVector pop(a, AGENT_COUNT);
    for (unsigned int i = 0; i < AGENT_COUNT; ++i) {
        AgentVector::Agent ai = pop[i];
        ai.setVariable<unsigned int>("index", i);
        ai.setVariable<unsigned int>("message_read", UINT_MAX);
    }
    // Set pop in model
    CUDASimulation c(m);
    c.setPopulationData(pop);
    c.step();
    c.getPopulationData(pop);
    // Validate each agent has read 8 correct messages
    for (AgentVector::Agent ai : pop) {
        const unsigned int message_read = ai.getVariable<unsigned int>("message_read");
        EXPECT_EQ(125u, message_read);  // @todo - 124?
    }
}

// Exception tests
#if !defined(SEATBELTS) || SEATBELTS
TEST(TestMessage_Array3D, DuplicateOutputException) {
#else
TEST(TestMessage_Array3D, DISABLED_DuplicateOutputException) {
#endif
    ModelDescription m(MODEL_NAME);
    MsgArray3D::Description &msg = m.newMessage<MsgArray3D>(MESSAGE_NAME);
    msg.setDimensions(CBRT_AGENT_COUNT, CBRT_AGENT_COUNT + 1, CBRT_AGENT_COUNT + 2);
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
    AgentVector pop(a, AGENT_COUNT);
    for (unsigned int i = 0; i < AGENT_COUNT; ++i) {
        AgentVector::Agent ai = pop[i];
        ai.setVariable<unsigned int>("index", i);
        ai.setVariable<unsigned int>("message_read", UINT_MAX);
        ai.setVariable<unsigned int>("message_write", numbers[i]);
    }
    // Set pop in model
    CUDASimulation c(m);
    c.setPopulationData(pop);
    EXPECT_THROW(c.step(), ArrayMessageWriteConflict);
}
TEST(TestMessage_Array3D, ArrayLenZeroException) {
    ModelDescription m(MODEL_NAME);
    MsgArray3D::Description &msg = m.newMessage<MsgArray3D>(MESSAGE_NAME);
    EXPECT_THROW(msg.setDimensions(0, 0, CBRT_AGENT_COUNT), InvalidArgument);
    EXPECT_THROW(msg.setDimensions({ 0, 0, CBRT_AGENT_COUNT }), InvalidArgument);
    EXPECT_THROW(msg.setDimensions(0, CBRT_AGENT_COUNT, 0), InvalidArgument);
    EXPECT_THROW(msg.setDimensions({ 0, CBRT_AGENT_COUNT, 0 }), InvalidArgument);
    EXPECT_THROW(msg.setDimensions(CBRT_AGENT_COUNT, 0, 0), InvalidArgument);
    EXPECT_THROW(msg.setDimensions({ CBRT_AGENT_COUNT, 0, 0 }), InvalidArgument);
}
TEST(TestMessage_Array3D, UnsetDimensions) {
    ModelDescription model(MODEL_NAME);
    model.newMessage<MsgArray3D>(MESSAGE_NAME);
    // message.setDimensions(5, 5, 5);  // Intentionally commented out
    EXPECT_THROW(CUDASimulation m(model), InvalidMessage);
}
TEST(TestMessage_Array3D, reserved_name) {
    ModelDescription model(MODEL_NAME);
    MsgArray3D::Description &message = model.newMessage<MsgArray3D>(MESSAGE_NAME);
    EXPECT_THROW(message.newVariable<int>("_"), ReservedName);
}
FLAMEGPU_AGENT_FUNCTION(countArray3D, MsgArray3D, MsgNone) {
    unsigned int value = FLAMEGPU->message_in.at(0, 0, 0).getVariable<unsigned int>("value");
    FLAMEGPU->setVariable<unsigned int>("value", value);
    return ALIVE;
}
TEST(TestMessage_Array3D, ReadEmpty) {
// What happens if we read a message list before it has been output?
    ModelDescription model("Model");
    {   // Location message
        MsgArray3D::Description &message = model.newMessage<MsgArray3D>("location");
        message.setDimensions(2, 2, 2);
        message.newVariable<int>("id");  // unused by current test
        message.newVariable<unsigned int>("value");  // unused by current test
    }
    {   // Circle agent
        AgentDescription &agent = model.newAgent("agent");
        agent.newVariable<unsigned int>("value", 32323);  // Count the number of messages read
        agent.newFunction("in", countArray3D).setMessageInput("location");
    }
    {   // Layer #1
        LayerDescription &layer = model.newLayer();
        layer.addAgentFunction(countArray3D);
    }
    // Create 1 agent
    AgentVector pop_in(model.Agent("agent"), 1);
    CUDASimulation cuda_model(model);
    cuda_model.setPopulationData(pop_in);
    // Execute model
    EXPECT_NO_THROW(cuda_model.step());
    // Check result
    AgentVector pop_out(model.Agent("agent"), 1);
    pop_out[0].setVariable<unsigned int>("value", 22221);
    cuda_model.getPopulationData(pop_out);
    EXPECT_EQ(pop_out.size(), 1u);
    auto ai = pop_out[0];
    EXPECT_EQ(ai.getVariable<unsigned int>("value"), 0u);  // Unset array msgs should be 0
}

/*
 * Test for fixed size grids with various com radii to check edge cases + expected cases.
 * 3x3x3 issue highlighted by see https://github.com/FLAMEGPU/FLAMEGPU2/issues/547
 */
FLAMEGPU_AGENT_FUNCTION(OutSimpleXYZ, MsgNone, MsgArray3D) {
    const unsigned int index = FLAMEGPU->getVariable<unsigned int>("index");
    const unsigned int x = FLAMEGPU->getVariable<unsigned int>("x");
    const unsigned int y = FLAMEGPU->getVariable<unsigned int>("y");
    const unsigned int z = FLAMEGPU->getVariable<unsigned int>("z");
    FLAMEGPU->message_out.setVariable("index", index);
    FLAMEGPU->message_out.setIndex(x, y, z);
    return ALIVE;
}
FLAMEGPU_AGENT_FUNCTION(MooreTestXYZC, MsgArray3D, MsgNone) {
    const unsigned int index = FLAMEGPU->getVariable<unsigned int>("index");
    const unsigned int x = FLAMEGPU->getVariable<unsigned int>("x");
    const unsigned int y = FLAMEGPU->getVariable<unsigned int>("y");
    const unsigned int z = FLAMEGPU->getVariable<unsigned int>("z");
    const unsigned int COMRADIUS = FLAMEGPU->environment.getProperty<unsigned int>("COMRADIUS");
    // Iterate message list counting how many messages were read.
    unsigned int count = 0;
    for (const auto &message : FLAMEGPU->message_in(x, y, z, COMRADIUS)) {
        // @todo - check its the correct messages?
        /* if(index == 0){
            printf("message from %u: %u %u %u\n", message.getVariable<unsigned int>("index"), message.getX(), message.getY(), message.getZ());
        } */
        count++;
    }
    FLAMEGPU->setVariable<unsigned int>("message_read", count);
    return ALIVE;
}

void test_mooore_comradius(
    const unsigned int GRID_WIDTH,
    const unsigned int GRID_HEIGHT,
    const unsigned int GRID_DEPTH,
    const unsigned int COMRADIUS
    ) {
    // Calc the population
    const unsigned int agentCount =  GRID_WIDTH * GRID_HEIGHT * GRID_DEPTH;
    // Some debug logging. @todo
    /* printf("GRID_WIDTH %u\n", GRID_WIDTH);
    printf("GRID_HEIGHT %u\n", GRID_HEIGHT);
    printf("GRID_DEPTH %u\n", GRID_DEPTH);
    printf("COMRADIUS %u\n", COMRADIUS);
    printf("agentCount %u\n", agentCount); */

    // Define the model
    ModelDescription model("MooreXYZC");

    // Use an env var for the communication radius to use, rather than a __device__ or a #define.
    EnvironmentDescription &env = model.Environment();
    env.newProperty<unsigned int>("COMRADIUS", COMRADIUS);

    // Define the message
    MsgArray3D::Description &message = model.newMessage<MsgArray3D>(MESSAGE_NAME);
    message.newVariable<unsigned int>("index");
    message.setDimensions(GRID_WIDTH, GRID_HEIGHT, GRID_DEPTH);
    AgentDescription &agent = model.newAgent(AGENT_NAME);
    agent.newVariable<unsigned int>("index");
    agent.newVariable<unsigned int>("x");
    agent.newVariable<unsigned int>("y");
    agent.newVariable<unsigned int>("z");
    agent.newVariable<unsigned int>("message_read", UINT_MAX);
    // Define the function and layers.
    AgentFunctionDescription &outputFunction = agent.newFunction("OutSimpleXYZ", OutSimpleXYZ);
    outputFunction.setMessageOutput(message);
    AgentFunctionDescription &inputFunction = agent.newFunction("MooreTestXYZC", MooreTestXYZC);
    inputFunction.setMessageInput(message);
    model.newLayer().addAgentFunction(outputFunction);
    LayerDescription &li = model.newLayer();
    li.addAgentFunction(inputFunction);
    // Assign the numbers in shuffled order to agents
    AgentVector population(agent, agentCount);
    for (unsigned int x = 0; x < GRID_WIDTH; x++) {
        for (unsigned int y = 0; y < GRID_HEIGHT; y++) {
            for (unsigned int z = 0; z < GRID_DEPTH; z++) {
                unsigned int idx = (x * GRID_HEIGHT * GRID_DEPTH) + (y * GRID_DEPTH) + z;
                AgentVector::Agent instance = population[idx];
                instance.setVariable<unsigned int>("index", idx);
                instance.setVariable<unsigned int>("x", x);
                instance.setVariable<unsigned int>("y", y);
                instance.setVariable<unsigned int>("z", z);
                instance.setVariable<unsigned int>("message_read", UINT_MAX);
            }
        }
    }
    // Set pop in model
    CUDASimulation simulation(model);
    simulation.setPopulationData(population);
    simulation.step();
    simulation.getPopulationData(population);
    // Validate each agent has read correct messages

    // Calc the expected number of messages. This depoends on the env dims and the comm radius.
    // Radius 0 is not supported, and currently the centre cell is not returned for other radii (so usually -1).
    // If one of the environemnt dimensions is too small, < 2 * radius + 1, then either fewer messages should be read, or messages will be re-read.
    // In this case, the centre cell may / is currently also read.

    // const unsigned int nowrapExpectedCount = pow((2 * COMRADIUS) + 1, 3) - 1;
    // If any dim is less than 2 * rad + 1, then there are fewere unique messages to be read, and the center will be re-read.
    const bool xFewerReads = (2 * COMRADIUS) + 1 > GRID_WIDTH;
    const bool yFewerReads = (2 * COMRADIUS) + 1 > GRID_HEIGHT;
    const bool zFewerReads = (2 * COMRADIUS) + 1 > GRID_DEPTH;
    const unsigned int xReadRange = !xFewerReads ? (2 * COMRADIUS) + 1 : GRID_WIDTH;
    const unsigned int yReadRange = !yFewerReads ? (2 * COMRADIUS) + 1 : GRID_HEIGHT;
    const unsigned int zReadRange = !zFewerReads ? (2 * COMRADIUS) + 1 : GRID_DEPTH;
    // @todo - verify if the self message should ever be returned, even when wrapped. Can always -1 if it should never be read.
    const unsigned int selfRead = xFewerReads || yFewerReads || zFewerReads ? 0 : 1;
    const unsigned int expected_count = (xReadRange * yReadRange * zReadRange) - selfRead;

    /*
    // @todo 
    printf("xFewerReads %d\n", xFewerReads);
    printf("yFewerReads %d\n", yFewerReads);
    printf("zFewerReads %d\n", zFewerReads);
    printf("xReadRange %u\n", xReadRange);
    printf("yReadRange %u\n", yReadRange);
    printf("zReadRange %u\n", zReadRange);
    printf("selfRead %u\n", selfRead);
    printf("expected_count %u\n", expected_count); */

    for (AgentVector::Agent instance : population) {
        const unsigned int message_read = instance.getVariable<unsigned int>("message_read");
        ASSERT_EQ(expected_count, message_read);
    }
}
// Test a range of environment sizes for comradius of 1, including small sizes which are an edge case.
// Also try non-uniform dimensions.
// @todo - decide if these should be one or many tests.
TEST(TestMessage_Array3D, MooreX1Y1Z1R1) {
    test_mooore_comradius(1, 1, 1, 1);
}
TEST(TestMessage_Array3D, MooreX2Y2Z2R1) {
    test_mooore_comradius(2, 2, 2, 1);
}
TEST(TestMessage_Array3D, MooreX3Y3Z3R1) {
    test_mooore_comradius(3, 3, 3, 1);
}
TEST(TestMessage_Array3D, MooreX4Y4Z4R1) {
    test_mooore_comradius(4, 4, 4, 1);
}
TEST(TestMessage_Array3D, MooreX2Y2Z1R1) {
    test_mooore_comradius(2, 2, 1, 1);
}
TEST(TestMessage_Array3D, MooreX3Y3Z1R1) {
    test_mooore_comradius(3, 3, 1, 1);
}
TEST(TestMessage_Array3D, MooreX4Y4Z1R1) {
    test_mooore_comradius(4, 4, 1, 1);
}
TEST(TestMessage_Array3D, MooreX2Y1Z1R1) {
    test_mooore_comradius(2, 1, 1, 1);
}
TEST(TestMessage_Array3D, MooreX3Y1Z1R1) {
    test_mooore_comradius(3, 1, 1, 1);
}
TEST(TestMessage_Array3D, MooreX4Y1Z1R1) {
    test_mooore_comradius(4, 1, 1, 1);
}
// Test a range of environment sizes for comradius of 2, including small sizes which are an edge case.
// Also try non-uniform dimensions.
// @todo - decide if these should be one or many tests.
TEST(TestMessage_Array3D, MooreXX1Y1Z1R2) {
    test_mooore_comradius(1, 1, 1, 2);
}
TEST(TestMessage_Array3D, MooreXX2Y2Z2R2) {
    test_mooore_comradius(2, 2, 2, 2);
}
TEST(TestMessage_Array3D, MooreXX3Y3Z3R2) {
    test_mooore_comradius(3, 3, 3, 2);
}
TEST(TestMessage_Array3D, MooreXX4Y4Z4R2) {
    test_mooore_comradius(4, 4, 4, 2);
}
TEST(TestMessage_Array3D, MooreXX5Y5Z5R2) {
    test_mooore_comradius(5, 5, 5, 2);
}
TEST(TestMessage_Array3D, MooreXX6Y6Z6R2) {
    test_mooore_comradius(6, 6, 6, 2);
}
TEST(TestMessage_Array3D, MooreXX2Y2Z1R2) {
    test_mooore_comradius(2, 2, 1, 2);
}
TEST(TestMessage_Array3D, MooreXX3Y3Z1R2) {
    test_mooore_comradius(3, 3, 1, 2);
}
TEST(TestMessage_Array3D, MooreXX4Y4Z1R2) {
    test_mooore_comradius(4, 4, 1, 2);
}
TEST(TestMessage_Array3D, MooreXX5Y5Z1R2) {
    test_mooore_comradius(5, 5, 1, 2);
}
TEST(TestMessage_Array3D, MooreXX6Y6Z1R2) {
    test_mooore_comradius(6, 6, 1, 2);
}
TEST(TestMessage_Array3D, MooreXX2Y1Z1R2) {
    test_mooore_comradius(2, 1, 1, 2);
}
TEST(TestMessage_Array3D, MooreXX3Y1Z1R2) {
    test_mooore_comradius(3, 1, 1, 2);
}
TEST(TestMessage_Array3D, MooreXX4Y1Z1R2) {
    test_mooore_comradius(4, 1, 1, 2);
}
TEST(TestMessage_Array3D, MooreXX5Y1Z1R2) {
    test_mooore_comradius(5, 1, 1, 2);
}
TEST(TestMessage_Array3D, MooreXX6Y1Z1R2) {
    test_mooore_comradius(6, 1, 1, 2);
}

}  // namespace test_message_array_3d
