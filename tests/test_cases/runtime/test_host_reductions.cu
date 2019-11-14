#ifndef TESTS_TEST_CASES_RUNTIME_TEST_HOST_REDUCTIONS_H_
#define TESTS_TEST_CASES_RUNTIME_TEST_HOST_REDUCTIONS_H_

#include <array>
#include <random>
#include <numeric>
#include <algorithm>

#include "gtest/gtest.h"

#include "flamegpu/flame_api.h"
#include "flamegpu/runtime/flamegpu_api.h"

namespace {
const unsigned int TEST_LEN = 256;
float float_out = 0;
double double_out = 0;
char char_out = 0;
unsigned char uchar_out = 0;
uint16_t uint16_t_out = 0;
int16_t int16_t_out = 0;
uint32_t uint32_t_out = 0;
int32_t int32_t_out = 0;
uint64_t uint64_t_out = 0;
int64_t int64_t_out = 0;
FLAMEGPU_STEP_FUNCTION(step_minfloat) {
    float_out = FLAMEGPU->agent("agent").min<float>("float");
}
FLAMEGPU_STEP_FUNCTION(step_maxfloat) {
    float_out = FLAMEGPU->agent("agent").max<float>("float");
}
FLAMEGPU_STEP_FUNCTION(step_sumfloat) {
    float_out = FLAMEGPU->agent("agent").sum<float>("float");
}
FLAMEGPU_STEP_FUNCTION(step_mindouble) {
    double_out = FLAMEGPU->agent("agent").min<double>("double");
}
FLAMEGPU_STEP_FUNCTION(step_maxdouble) {
    double_out = FLAMEGPU->agent("agent").max<double>("double");
}
FLAMEGPU_STEP_FUNCTION(step_sumdouble) {
    double_out = FLAMEGPU->agent("agent").sum<double>("double");
}
FLAMEGPU_STEP_FUNCTION(step_minuchar) {
    uchar_out = FLAMEGPU->agent("agent").min<unsigned char>("uchar");
}
FLAMEGPU_STEP_FUNCTION(step_maxuchar) {
    uchar_out = FLAMEGPU->agent("agent").max<unsigned char>("uchar");
}
FLAMEGPU_STEP_FUNCTION(step_sumuchar) {
    uchar_out = FLAMEGPU->agent("agent").sum<unsigned char>("uchar");
    uint64_t_out = FLAMEGPU->agent("agent").sum<unsigned char, int64_t>("uchar");
}
FLAMEGPU_STEP_FUNCTION(step_minchar) {
    char_out = FLAMEGPU->agent("agent").min<char>("char");
}
FLAMEGPU_STEP_FUNCTION(step_maxchar) {
    char_out = FLAMEGPU->agent("agent").max<char>("char");
}
FLAMEGPU_STEP_FUNCTION(step_sumchar) {
    char_out = FLAMEGPU->agent("agent").sum<char>("char");
    int64_t_out = FLAMEGPU->agent("agent").sum<char, int64_t>("char");
}
FLAMEGPU_STEP_FUNCTION(step_minuint16_t) {
    uint16_t_out = FLAMEGPU->agent("agent").min<uint16_t>("uint16_t");
}
FLAMEGPU_STEP_FUNCTION(step_maxuint16_t) {
    uint16_t_out = FLAMEGPU->agent("agent").max<uint16_t>("uint16_t");
}
FLAMEGPU_STEP_FUNCTION(step_sumuint16_t) {
    uint16_t_out = FLAMEGPU->agent("agent").sum<uint16_t>("uint16_t");
    uint64_t_out = FLAMEGPU->agent("agent").sum<uint16_t, int64_t>("uint16_t");
}
FLAMEGPU_STEP_FUNCTION(step_minint16_t) {
    int16_t_out = FLAMEGPU->agent("agent").min<int16_t>("int16_t");
}
FLAMEGPU_STEP_FUNCTION(step_maxint16_t) {
    int16_t_out = FLAMEGPU->agent("agent").max<int16_t>("int16_t");
}
FLAMEGPU_STEP_FUNCTION(step_sumint16_t) {
    int16_t_out = FLAMEGPU->agent("agent").sum<int16_t>("int16_t");
    int64_t_out = FLAMEGPU->agent("agent").sum<int16_t, int64_t>("int16_t");
}
FLAMEGPU_STEP_FUNCTION(step_minuint32_t) {
    uint32_t_out = FLAMEGPU->agent("agent").min<uint32_t>("uint32_t");
}
FLAMEGPU_STEP_FUNCTION(step_maxuint32_t) {
    uint32_t_out = FLAMEGPU->agent("agent").max<uint32_t>("uint32_t");
}
FLAMEGPU_STEP_FUNCTION(step_sumuint32_t) {
    uint32_t_out = FLAMEGPU->agent("agent").sum<uint32_t>("uint32_t");
    uint64_t_out = FLAMEGPU->agent("agent").sum<uint32_t, int64_t>("uint32_t");
}
FLAMEGPU_STEP_FUNCTION(step_minint32_t) {
    int32_t_out = FLAMEGPU->agent("agent").min<int32_t>("int32_t");
}
FLAMEGPU_STEP_FUNCTION(step_maxint32_t) {
    int32_t_out = FLAMEGPU->agent("agent").max<int32_t>("int32_t");
}
FLAMEGPU_STEP_FUNCTION(step_sumint32_t) {
    int32_t_out = FLAMEGPU->agent("agent").sum<int32_t>("int32_t");
    int64_t_out = FLAMEGPU->agent("agent").sum<int32_t, int64_t>("int32_t");
}
FLAMEGPU_STEP_FUNCTION(step_minuint64_t) {
    uint64_t_out = FLAMEGPU->agent("agent").min<uint64_t>("uint64_t");
}
FLAMEGPU_STEP_FUNCTION(step_maxuint64_t) {
    uint64_t_out = FLAMEGPU->agent("agent").max<uint64_t>("uint64_t");
}
FLAMEGPU_STEP_FUNCTION(step_sumuint64_t) {
    uint64_t_out = FLAMEGPU->agent("agent").sum<uint64_t>("uint64_t");
}
FLAMEGPU_STEP_FUNCTION(step_minint64_t) {
    int64_t_out = FLAMEGPU->agent("agent").min<int64_t>("int64_t");
}
FLAMEGPU_STEP_FUNCTION(step_maxint64_t) {
    int64_t_out = FLAMEGPU->agent("agent").max<int64_t>("int64_t");
}
FLAMEGPU_STEP_FUNCTION(step_sumint64_t) {
    int64_t_out = FLAMEGPU->agent("agent").sum<int64_t>("int64_t");
}

FLAMEGPU_CUSTOM_REDUCTION(customMax, a, b) {
    return a > b ? a : b;
}
FLAMEGPU_STEP_FUNCTION(step_reducefloat) {
    float_out = FLAMEGPU->agent("agent").reduce<float>("float", customMax, 0);
}
FLAMEGPU_STEP_FUNCTION(step_reducedouble) {
    double_out = FLAMEGPU->agent("agent").reduce<double>("double", customMax, 0);
}
FLAMEGPU_STEP_FUNCTION(step_reduceuchar) {
    uchar_out = FLAMEGPU->agent("agent").reduce<unsigned char>("uchar", customMax, 0);
}
FLAMEGPU_STEP_FUNCTION(step_reducechar) {
    char_out = FLAMEGPU->agent("agent").reduce<char>("char", customMax, 0);
}
FLAMEGPU_STEP_FUNCTION(step_reduceuint16_t) {
    uint16_t_out = FLAMEGPU->agent("agent").reduce<uint16_t>("uint16_t", customMax, 0);
}
FLAMEGPU_STEP_FUNCTION(step_reduceint16_t) {
    int16_t_out = FLAMEGPU->agent("agent").reduce<int16_t>("int16_t", customMax, 0);
}
FLAMEGPU_STEP_FUNCTION(step_reduceuint32_t) {
    uint32_t_out = FLAMEGPU->agent("agent").reduce<uint32_t>("uint32_t", customMax, 0);
}
FLAMEGPU_STEP_FUNCTION(step_reduceint32_t) {
    int32_t_out = FLAMEGPU->agent("agent").reduce<int32_t>("int32_t", customMax, 0);
}
FLAMEGPU_STEP_FUNCTION(step_reduceuint64_t) {
    uint64_t_out = FLAMEGPU->agent("agent").reduce<uint64_t>("uint64_t", customMax, 0);
}
FLAMEGPU_STEP_FUNCTION(step_reduceint64_t) {
    int64_t_out = FLAMEGPU->agent("agent").reduce<int64_t>("int64_t", customMax, 0);
}

std::vector<unsigned int> uint_vec;
std::vector<int> int_vec;
FLAMEGPU_STEP_FUNCTION(step_histogramEvenfloat) {
    uint_vec = FLAMEGPU->agent("agent").histogramEven<float, unsigned int>("float", 10, 0.0f, 20.0f);
}
FLAMEGPU_STEP_FUNCTION(step_histogramEvendouble) {
    int_vec = FLAMEGPU->agent("agent").histogramEven<double, int>("double", 10, 0.0, 20.0);
}
FLAMEGPU_STEP_FUNCTION(step_histogramEvenchar) {
    uint_vec = FLAMEGPU->agent("agent").histogramEven<char, unsigned int>("char", 10, 0, 20);
}
FLAMEGPU_STEP_FUNCTION(step_histogramEvenuchar) {
    int_vec = FLAMEGPU->agent("agent").histogramEven<unsigned char, int>("uchar", 10, 0, 20);
}
FLAMEGPU_STEP_FUNCTION(step_histogramEvenint16_t) {
    uint_vec = FLAMEGPU->agent("agent").histogramEven<int16_t, unsigned int>("int16_t", 10, 0, 20);
}
FLAMEGPU_STEP_FUNCTION(step_histogramEvenuint16_t) {
    int_vec = FLAMEGPU->agent("agent").histogramEven<uint16_t, int>("uint16_t", 10, 0, 20);
}
FLAMEGPU_STEP_FUNCTION(step_histogramEvenint32_t) {
    uint_vec = FLAMEGPU->agent("agent").histogramEven<int32_t, unsigned int>("int32_t", 10, 0, 20);
}
FLAMEGPU_STEP_FUNCTION(step_histogramEvenuint32_t) {
    int_vec = FLAMEGPU->agent("agent").histogramEven<uint32_t, int>("uint32_t", 10, 0, 20);
}
FLAMEGPU_STEP_FUNCTION(step_histogramEvenint64_t) {
    uint_vec = FLAMEGPU->agent("agent").histogramEven<int64_t, unsigned int>("int64_t", 10, 0, 20);
}
FLAMEGPU_STEP_FUNCTION(step_histogramEvenuint64_t) {
    int_vec = FLAMEGPU->agent("agent").histogramEven<uint64_t, int>("uint64_t", 10, 0, 20);
}

FLAMEGPU_STEP_FUNCTION(step_sumException) {
    EXPECT_THROW(FLAMEGPU->agent("agedddnt"), InvalidCudaAgent);
    EXPECT_THROW(FLAMEGPU->agent("agent").sum<unsigned char>("float"), InvalidVarType);
    EXPECT_THROW(FLAMEGPU->agent("agent").sum<int64_t>("uint64_t"), InvalidVarType);
    EXPECT_THROW(FLAMEGPU->agent("agent").sum<double>("intsssssssss16_t"), InvalidAgentVar);
    EXPECT_THROW(FLAMEGPU->agent("agent").sum<uint64_t>("isssssssssssnt"), InvalidAgentVar);
}
FLAMEGPU_STEP_FUNCTION(step_minException) {
    EXPECT_THROW(FLAMEGPU->agent("agsssedddnt"), InvalidCudaAgent);
    EXPECT_THROW(FLAMEGPU->agent("agent").min<uint64_t>("char"), InvalidVarType);
    EXPECT_THROW(FLAMEGPU->agent("agent").min<int64_t>("uint64_t"), InvalidVarType);
    EXPECT_THROW(FLAMEGPU->agent("agent").min<double>("intssssssssssssss16_t"), InvalidAgentVar);
    EXPECT_THROW(FLAMEGPU->agent("agent").min<uint64_t>("issssssssssssnt"), InvalidAgentVar);
}
FLAMEGPU_STEP_FUNCTION(step_maxException) {
    EXPECT_THROW(FLAMEGPU->agent("ageaadddnt"), InvalidCudaAgent);
    EXPECT_THROW(FLAMEGPU->agent("agent").max<double>("float"), InvalidVarType);
    EXPECT_THROW(FLAMEGPU->agent("agent").max<float>("uint64_t"), InvalidVarType);
    EXPECT_THROW(FLAMEGPU->agent("agent").max<double>("intsssssssssss16_t"), InvalidAgentVar);
    EXPECT_THROW(FLAMEGPU->agent("agent").max<uint64_t>("ssssssssssssssint"), InvalidAgentVar);
}
FLAMEGPU_STEP_FUNCTION(step_customReductionException) {
    EXPECT_THROW(FLAMEGPU->agent("ageaadddnt"), InvalidCudaAgent);
    EXPECT_THROW(FLAMEGPU->agent("agent").reduce<double>("float", customMax, 0), InvalidVarType);
    EXPECT_THROW(FLAMEGPU->agent("agent").reduce<float>("uint64_t", customMax, 0), InvalidVarType);
    EXPECT_THROW(FLAMEGPU->agent("agent").reduce<double>("intsssssssssss16_t", customMax, 0), InvalidAgentVar);
    EXPECT_THROW(FLAMEGPU->agent("agent").reduce<uint64_t>("ssssssssssssssint", customMax, 0), InvalidAgentVar);
}
FLAMEGPU_STEP_FUNCTION(step_histogramEvenException) {
    EXPECT_THROW(FLAMEGPU->agent("ageaadddnt"), InvalidCudaAgent);
    EXPECT_THROW(FLAMEGPU->agent("agent").histogramEven<double>("float", 10, 0, 10), InvalidVarType);
    EXPECT_THROW(FLAMEGPU->agent("agent").histogramEven<float>("uint64_t", 10, 0, 10), InvalidVarType);
    EXPECT_THROW(FLAMEGPU->agent("agent").histogramEven<double>("intsssssssssss16_t", 10, 0, 10), InvalidAgentVar);
    EXPECT_THROW(FLAMEGPU->agent("agent").histogramEven<uint64_t>("ssssssssssssssint", 10, 0, 10), InvalidAgentVar);
    EXPECT_THROW(FLAMEGPU->agent("agent").histogramEven<int>("int", 10, 0, 0), InvalidArgument);
    EXPECT_THROW(FLAMEGPU->agent("agent").histogramEven<double>("double", 10, 11, 10), InvalidArgument);
}

class MiniSim {
 public:
    MiniSim() :
      model("model"),
      agent("agent"),
      simulation(model),
      population(nullptr) {
        agent.addAgentVariable<float>("float");
        agent.addAgentVariable<double>("double");
        agent.addAgentVariable<char>("char");
        agent.addAgentVariable<unsigned char>("uchar");
        agent.addAgentVariable<uint16_t>("uint16_t");
        agent.addAgentVariable<int16_t>("int16_t");
        agent.addAgentVariable<uint32_t>("uint32_t");
        agent.addAgentVariable<int32_t>("int32_t");
        agent.addAgentVariable<uint64_t>("uint64_t");
        agent.addAgentVariable<int64_t>("int64_t");
        population = new AgentPopulation(agent, TEST_LEN);
        simulation.setSimulationSteps(1);
    }
    void run() {
        model.addAgent(agent);
        // CudaModel must be declared here
        // As the initial call to constructor fixes the agent population
        // This means if we haven't called model.addAgent(agent) first
        CUDAAgentModel cuda_model(model);
        // This fails as agentMap is empty
        cuda_model.setInitialPopulationData(*population);
        ASSERT_NO_THROW(cuda_model.simulate(simulation));
        // The negative of this, is that cuda_model is inaccessible within the test!
        // So copy across population data here
        ASSERT_NO_THROW(cuda_model.getPopulationData(*population));
    }
    ModelDescription model;
    AgentDescription agent;
    Simulation simulation;
    AgentPopulation *population;
};
/**
* This defines a common fixture used as a base for all test cases in the file
* @see https://github.com/google/googletest/blob/master/googletest/samples/sample5_unittest.cc
*/
class HostReductionTest : public testing::Test {
 protected:
    void SetUp() override {
        ms = new MiniSim();
        uint_vec.clear();
        int_vec.clear();
    }

    void TearDown() override {
        delete ms;
    }

    MiniSim *ms = nullptr;
};

/**
 * Poor attempt to mimic cub::histogram::histogramEven()
 * Doesn't work great with odd boundaries and ranges near integer limits
 */
template<typename InT, typename OutT>
std::vector<OutT> histogramEven(const std::array<InT, TEST_LEN> &variables, const unsigned int &histogramBins, const InT &lowerBound, const InT &upperBound) {
    assert(upperBound > lowerBound);
    std::vector<OutT> rtn(histogramBins);
    for (auto &i : rtn)
        i = static_cast<OutT>(0);
    const InT diff = upperBound - lowerBound;
    const double diffP = diff / static_cast<double>(histogramBins);
    for (auto &i : variables) {
        if (i >= lowerBound && i < upperBound) {
            ++rtn[static_cast<int>(i/ diffP)];
        }
    }
    return rtn;
}
}  // namespace

/**
 * Float
 */
TEST_F(HostReductionTest, MinFloat) {
    ms->simulation.addStepFunction(&step_minfloat);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_real_distribution <float> dist(FLT_MIN, FLT_MAX);
    std::array<float, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = dist(rd);
        instance.setVariable<float>("float", in[i]);
    }
    ms->run();
    EXPECT_EQ(float_out, *std::min_element(in.begin(), in.end()));
}
TEST_F(HostReductionTest, MaxFloat) {
    ms->simulation.addStepFunction(&step_maxfloat);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_real_distribution <float> dist(FLT_MIN, FLT_MAX);
    std::array<float, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = dist(rd);
        instance.setVariable<float>("float", in[i]);
    }
    ms->run();
    EXPECT_EQ(float_out, *std::max_element(in.begin(), in.end()));
}
TEST_F(HostReductionTest, SumFloat) {
    ms->simulation.addStepFunction(&step_sumfloat);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_real_distribution <float> dist(FLT_MIN, FLT_MAX);
    std::array<float, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = dist(rd);
        instance.setVariable<float>("float", in[i]);
    }
    ms->run();
    EXPECT_EQ(float_out, std::accumulate(in.begin(), in.end(), 0.0f));
}
TEST_F(HostReductionTest, CustomReduceFloat) {
    ms->simulation.addStepFunction(&step_reducefloat);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_real_distribution <float> dist(FLT_MIN, FLT_MAX);
    std::array<float, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = dist(rd);
        instance.setVariable<float>("float", in[i]);
    }
    ms->run();
    EXPECT_EQ(float_out, *std::max_element(in.begin(), in.end()));
}
TEST_F(HostReductionTest, HistogramEvenFloat) {
    ms->simulation.addStepFunction(&step_histogramEvenfloat);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_real_distribution <float> dist(0, 20);
    std::array<float, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = dist(rd);
        instance.setVariable<float>("float", in[i]);
    }
    ms->run();
    auto check = histogramEven<float, unsigned int>(in, 10, 0, 20);
    for (unsigned int i = 0; i < uint_vec.size(); ++i) {
        EXPECT_EQ(uint_vec[i], check[i]);
    }
}

/**
 * Double
 */
TEST_F(HostReductionTest, MinDouble) {
    ms->simulation.addStepFunction(&step_mindouble);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_real_distribution <double> dist(DBL_MIN, DBL_MAX);
    std::array<double, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = dist(rd);
        instance.setVariable<double>("double", in[i]);
    }
    ms->run();
    EXPECT_EQ(double_out, *std::min_element(in.begin(), in.end()));
}
TEST_F(HostReductionTest, MaxDouble) {
    ms->simulation.addStepFunction(&step_maxdouble);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_real_distribution <double> dist(DBL_MIN, DBL_MAX);
    std::array<double, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = dist(rd);
        instance.setVariable<double>("double", in[i]);
    }
    ms->run();
    EXPECT_EQ(double_out, *std::max_element(in.begin(), in.end()));
}
TEST_F(HostReductionTest, SumDouble) {
    ms->simulation.addStepFunction(&step_sumdouble);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_real_distribution <double> dist(DBL_MIN, DBL_MAX);
    std::array<double, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = dist(rd);
        instance.setVariable<double>("double", in[i]);
    }
    ms->run();
    EXPECT_EQ(double_out, std::accumulate(in.begin(), in.end(), 0.0));
}
TEST_F(HostReductionTest, CustomReduceDouble) {
    ms->simulation.addStepFunction(&step_reducedouble);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_real_distribution <double> dist(DBL_MIN, DBL_MAX);
    std::array<double, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = dist(rd);
        instance.setVariable<double>("double", in[i]);
    }
    ms->run();
    EXPECT_EQ(double_out, *std::max_element(in.begin(), in.end()));
}
TEST_F(HostReductionTest, HistogramEvenDouble) {
    ms->simulation.addStepFunction(&step_histogramEvendouble);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_real_distribution <double> dist(0, 20);
    std::array<double, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = dist(rd);
        instance.setVariable<double>("double", in[i]);
    }
    ms->run();
    auto check = histogramEven<double, int>(in, 10, 0, 20);
    for (unsigned int i = 0; i < int_vec.size(); ++i) {
        EXPECT_EQ(int_vec[i], check[i]);
    }
}

/**
 * Char
 */
TEST_F(HostReductionTest, MinChar) {
    ms->simulation.addStepFunction(&step_minchar);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_int_distribution <int16_t> dist(CHAR_MIN, CHAR_MAX);
    std::array<char, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = static_cast<char>(dist(rd));
        instance.setVariable<char>("char", in[i]);
    }
    ms->run();
    EXPECT_EQ(char_out, *std::min_element(in.begin(), in.end()));
}
TEST_F(HostReductionTest, MaxChar) {
    ms->simulation.addStepFunction(&step_maxchar);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_int_distribution <int16_t> dist(CHAR_MIN, CHAR_MAX);
    std::array<char, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        if (i < 256) {
            in[i] = static_cast<char>(dist(rd));
        } else {
            in[i] = 0;
        }
        instance.setVariable<char>("char", in[i]);
    }
    ms->run();
    EXPECT_EQ(char_out, *std::max_element(in.begin(), in.end()));
}
TEST_F(HostReductionTest, SumChar) {
    ms->simulation.addStepFunction(&step_sumchar);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_int_distribution <int16_t> dist(CHAR_MIN, CHAR_MAX);
    std::array<char, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        if (i < 256) {
            in[i] = static_cast<char>(dist(rd));
        } else {
            in[i] = 0;
        }
        instance.setVariable<char>("char", in[i]);
    }
    ms->run();
    EXPECT_EQ(char_out, std::accumulate(in.begin(), in.end(), static_cast<char>(0)));
    EXPECT_EQ(int64_t_out, std::accumulate(in.begin(), in.end(), static_cast<int64_t>(0)));
}
TEST_F(HostReductionTest, CustomReduceChar) {
    ms->simulation.addStepFunction(&step_reducechar);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_int_distribution <int16_t> dist(CHAR_MIN, CHAR_MAX);
    std::array<char, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        if (i < 256) {
            in[i] = static_cast<char>(dist(rd));
        } else {
            in[i] = 0;
        }
        instance.setVariable<char>("char", in[i]);
    }
    ms->run();
    EXPECT_EQ(char_out, *std::max_element(in.begin(), in.end()));
}
TEST_F(HostReductionTest, HistogramEvenChar) {
    ms->simulation.addStepFunction(&step_histogramEvenchar);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_int_distribution <int16_t> dist(0, 19);
    std::array<char, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        if (i < 256) {
            in[i] = static_cast<char>(dist(rd));
        } else {
            in[i] = 0;
        }
        instance.setVariable<char>("char", in[i]);
    }
    ms->run();
    auto check = histogramEven<char, unsigned int>(in, 10, 0, 20);
    for (unsigned int i = 0; i < uint_vec.size(); ++i) {
        EXPECT_EQ(uint_vec[i], check[i]);
    }
}

/**
 * Unsigned Char
 */
TEST_F(HostReductionTest, MinUnsignedChar) {
    ms->simulation.addStepFunction(&step_minuchar);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_int_distribution <uint16_t> dist(0, UCHAR_MAX);
    std::array<unsigned char, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = static_cast<unsigned char>(dist(rd));
        instance.setVariable<unsigned char>("uchar", in[i]);
    }
    ms->run();
    EXPECT_EQ(uchar_out, *std::min_element(in.begin(), in.end()));
}
TEST_F(HostReductionTest, MaxUnsignedChar) {
    ms->simulation.addStepFunction(&step_maxuchar);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_int_distribution <uint16_t> dist(0, UCHAR_MAX);
    std::array<unsigned char, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = static_cast<unsigned char>(dist(rd));
        instance.setVariable<unsigned char>("uchar", in[i]);
    }
    ms->run();
    EXPECT_EQ(uchar_out, *std::max_element(in.begin(), in.end()));
}
TEST_F(HostReductionTest, SumUnsignedChar) {
    ms->simulation.addStepFunction(&step_sumuchar);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_int_distribution <uint16_t> dist(0, UCHAR_MAX);
    std::array<unsigned char, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = static_cast<unsigned char>(dist(rd));
        instance.setVariable<unsigned char>("uchar", in[i]);
    }
    ms->run();
    EXPECT_EQ(uchar_out, std::accumulate(in.begin(), in.end(), static_cast<unsigned char>(0)));
    EXPECT_EQ(uint64_t_out, std::accumulate(in.begin(), in.end(), static_cast<uint64_t>(0)));
}
TEST_F(HostReductionTest, CustomReduceUnsignedChar) {
    ms->simulation.addStepFunction(&step_reduceuchar);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_int_distribution <uint16_t> dist(0, UCHAR_MAX);
    std::array<unsigned char, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = static_cast<unsigned char>(dist(rd));
        instance.setVariable<unsigned char>("uchar", in[i]);
    }
    ms->run();
    EXPECT_EQ(uchar_out, *std::max_element(in.begin(), in.end()));
}
TEST_F(HostReductionTest, HistogramEvenUnsignedChar) {
    ms->simulation.addStepFunction(&step_histogramEvenuchar);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_int_distribution <uint16_t> dist(0, 19);
    std::array<unsigned char, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = static_cast<unsigned char>(dist(rd));
        instance.setVariable<unsigned char>("uchar", in[i]);
    }
    ms->run();
    auto check = histogramEven<unsigned char, int>(in, 10, 0, 20);
    for (unsigned int i = 0; i < int_vec.size(); ++i) {
        EXPECT_EQ(int_vec[i], check[i]);
    }
}

/**
 * int16_t
 */
TEST_F(HostReductionTest, MinInt16) {
    ms->simulation.addStepFunction(&step_minint16_t);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_int_distribution <int16_t> dist(INT16_MIN, INT16_MAX);
    std::array<int16_t, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = dist(rd);
        instance.setVariable<int16_t>("int16_t", in[i]);
    }
    ms->run();
    EXPECT_EQ(int16_t_out, *std::min_element(in.begin(), in.end()));
}
TEST_F(HostReductionTest, MaxInt16) {
    ms->simulation.addStepFunction(&step_maxint16_t);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_int_distribution <int16_t> dist(INT16_MIN, INT16_MAX);
    std::array<int16_t, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = dist(rd);
        instance.setVariable<int16_t>("int16_t", in[i]);
    }
    ms->run();
    EXPECT_EQ(int16_t_out, *std::max_element(in.begin(), in.end()));
}
TEST_F(HostReductionTest, SumInt16) {
    ms->simulation.addStepFunction(&step_sumint16_t);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_int_distribution <int16_t> dist(INT16_MIN, INT16_MAX);
    std::array<int16_t, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = dist(rd);
        instance.setVariable<int16_t>("int16_t", in[i]);
    }
    ms->run();
    EXPECT_EQ(int16_t_out, std::accumulate(in.begin(), in.end(), static_cast<int16_t>(0)));
    EXPECT_EQ(int64_t_out, std::accumulate(in.begin(), in.end(), static_cast<int64_t>(0)));
}
TEST_F(HostReductionTest, CustomReduceInt16) {
    ms->simulation.addStepFunction(&step_reduceint16_t);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_int_distribution <int16_t> dist(INT16_MIN, INT16_MAX);
    std::array<int16_t, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = dist(rd);
        instance.setVariable<int16_t>("int16_t", in[i]);
    }
    ms->run();
    EXPECT_EQ(int16_t_out, *std::max_element(in.begin(), in.end()));
}
TEST_F(HostReductionTest, HistogramEvenInt16) {
    ms->simulation.addStepFunction(&step_histogramEvenint16_t);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_int_distribution <int16_t> dist(0, 19);
    std::array<int16_t, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = dist(rd);
        instance.setVariable<int16_t>("int16_t", in[i]);
    }
    ms->run();
    auto check = histogramEven<int16_t, unsigned int>(in, 10, 0, 20);
    for (unsigned int i = 0; i < uint_vec.size(); ++i) {
        EXPECT_EQ(uint_vec[i], check[i]);
    }
}

/**
 * uint16_t
 */
TEST_F(HostReductionTest, MinUnsignedInt16) {
    ms->simulation.addStepFunction(&step_minuint16_t);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_int_distribution <uint16_t> dist(0, UINT16_MAX);
    std::array<uint16_t, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = dist(rd);
        instance.setVariable<uint16_t>("uint16_t", in[i]);
    }
    ms->run();
    EXPECT_EQ(uint16_t_out, *std::min_element(in.begin(), in.end()));
}
TEST_F(HostReductionTest, MaxUnsignedInt16) {
    ms->simulation.addStepFunction(&step_maxuint16_t);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_int_distribution <uint16_t> dist(0, UINT16_MAX);
    std::array<uint16_t, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = dist(rd);
        instance.setVariable<uint16_t>("uint16_t", in[i]);
    }
    ms->run();
    EXPECT_EQ(uint16_t_out, *std::max_element(in.begin(), in.end()));
}
TEST_F(HostReductionTest, SumUnsignedInt16) {
    ms->simulation.addStepFunction(&step_sumuint16_t);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_int_distribution <uint16_t> dist(0, UINT16_MAX);
    std::array<uint16_t, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = dist(rd);
        instance.setVariable<uint16_t>("uint16_t", in[i]);
    }
    ms->run();
    EXPECT_EQ(uint16_t_out, std::accumulate(in.begin(), in.end(), static_cast<uint16_t>(0)));
    EXPECT_EQ(uint64_t_out, std::accumulate(in.begin(), in.end(), static_cast<uint64_t>(0)));
}
TEST_F(HostReductionTest, CustomReduceUnsignedInt16) {
    ms->simulation.addStepFunction(&step_reduceuint16_t);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_int_distribution <uint16_t> dist(0, UINT16_MAX);
    std::array<uint16_t, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = dist(rd);
        instance.setVariable<uint16_t>("uint16_t", in[i]);
    }
    ms->run();
    EXPECT_EQ(uint16_t_out, *std::max_element(in.begin(), in.end()));
}
TEST_F(HostReductionTest, HistogramEvenUnsignedInt16) {
    ms->simulation.addStepFunction(&step_histogramEvenuint16_t);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_int_distribution <uint16_t> dist(0, 19);
    std::array<uint16_t, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = dist(rd);
        instance.setVariable<uint16_t>("uint16_t", in[i]);
    }
    ms->run();
    auto check = histogramEven<uint16_t, int>(in, 10, 0, 20);
    for (unsigned int i = 0; i < int_vec.size(); ++i) {
        EXPECT_EQ(int_vec[i], check[i]);
    }
}

/**
 * int32_t
 */
TEST_F(HostReductionTest, MinInt32) {
    ms->simulation.addStepFunction(&step_minint32_t);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_int_distribution <int32_t> dist(INT32_MIN, INT32_MAX);
    std::array<int32_t, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = dist(rd);
        instance.setVariable<int32_t>("int32_t", in[i]);
    }
    ms->run();
    EXPECT_EQ(int32_t_out, *std::min_element(in.begin(), in.end()));
}
TEST_F(HostReductionTest, MaxInt32) {
    ms->simulation.addStepFunction(&step_maxint32_t);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_int_distribution <int32_t> dist(INT32_MIN, INT32_MAX);
    std::array<int32_t, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = dist(rd);
        instance.setVariable<int32_t>("int32_t", in[i]);
    }
    ms->run();
    EXPECT_EQ(int32_t_out, *std::max_element(in.begin(), in.end()));
}
TEST_F(HostReductionTest, SumInt32) {
    ms->simulation.addStepFunction(&step_sumint32_t);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_int_distribution <int32_t> dist(INT32_MIN, INT32_MAX);
    std::array<int32_t, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = dist(rd);
        instance.setVariable<int32_t>("int32_t", in[i]);
    }
    ms->run();
    EXPECT_EQ(int32_t_out, std::accumulate(in.begin(), in.end(), static_cast<int32_t>(0)));
    EXPECT_EQ(int64_t_out, std::accumulate(in.begin(), in.end(), static_cast<int64_t>(0)));
}
TEST_F(HostReductionTest, CustomReduceInt32) {
    ms->simulation.addStepFunction(&step_reduceint32_t);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_int_distribution <int32_t> dist(INT32_MIN, INT32_MAX);
    std::array<int32_t, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = dist(rd);
        instance.setVariable<int32_t>("int32_t", in[i]);
    }
    ms->run();
    EXPECT_EQ(int32_t_out, *std::max_element(in.begin(), in.end()));
}
TEST_F(HostReductionTest, HistogramEvenInt32) {
    ms->simulation.addStepFunction(&step_histogramEvenint32_t);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_int_distribution <int32_t> dist(0, 19);
    std::array<int32_t, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = dist(rd);
        instance.setVariable<int32_t>("int32_t", in[i]);
    }
    ms->run();
    auto check = histogramEven<int32_t, unsigned int>(in, 10, 0, 20);
    for (unsigned int i = 0; i < uint_vec.size(); ++i) {
        EXPECT_EQ(uint_vec[i], check[i]);
    }
}

/**
 * uint32_t
 */
TEST_F(HostReductionTest, MinUnsignedInt32) {
    ms->simulation.addStepFunction(&step_minuint32_t);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_int_distribution <uint32_t> dist(0, UINT32_MAX);
    std::array<uint32_t, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = dist(rd);
        instance.setVariable<uint32_t>("uint32_t", in[i]);
    }
    ms->run();
    EXPECT_EQ(uint32_t_out, *std::min_element(in.begin(), in.end()));
}
TEST_F(HostReductionTest, MaxUnsignedInt32) {
    ms->simulation.addStepFunction(&step_maxuint32_t);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_int_distribution <uint32_t> dist(0, UINT32_MAX);
    std::array<uint32_t, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = dist(rd);
        instance.setVariable<uint32_t>("uint32_t", in[i]);
    }
    ms->run();
    EXPECT_EQ(uint32_t_out, *std::max_element(in.begin(), in.end()));
}
TEST_F(HostReductionTest, SumUnsignedInt32) {
    ms->simulation.addStepFunction(&step_sumuint32_t);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_int_distribution <uint32_t> dist(0, UINT32_MAX);
    std::array<uint32_t, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = dist(rd);
        instance.setVariable<uint32_t>("uint32_t", in[i]);
    }
    ms->run();
    EXPECT_EQ(uint32_t_out, std::accumulate(in.begin(), in.end(), static_cast<uint32_t>(0)));
    EXPECT_EQ(uint64_t_out, std::accumulate(in.begin(), in.end(), static_cast<uint64_t>(0)));
}
TEST_F(HostReductionTest, CustomReduceUnsignedInt32) {
    ms->simulation.addStepFunction(&step_reduceuint32_t);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_int_distribution <uint32_t> dist(0, UINT32_MAX);
    std::array<uint32_t, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = dist(rd);
        instance.setVariable<uint32_t>("uint32_t", in[i]);
    }
    ms->run();
    EXPECT_EQ(uint32_t_out, *std::max_element(in.begin(), in.end()));
}
TEST_F(HostReductionTest, HistogramEvenUnsignedInt32) {
    ms->simulation.addStepFunction(&step_histogramEvenuint32_t);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_int_distribution <uint32_t> dist(0, 19);
    std::array<uint32_t, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = dist(rd);
        instance.setVariable<uint32_t>("uint32_t", in[i]);
    }
    ms->run();
    auto check = histogramEven<uint32_t, int>(in, 10, 0, 20);
    for (unsigned int i = 0; i < int_vec.size(); ++i) {
        EXPECT_EQ(int_vec[i], check[i]);
    }
}

/**
 * int64_t
 */
TEST_F(HostReductionTest, MinInt64) {
    ms->simulation.addStepFunction(&step_minint64_t);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_int_distribution <int64_t> dist(INT64_MIN, INT64_MAX);
    std::array<int64_t, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = dist(rd);
        instance.setVariable<int64_t>("int64_t", in[i]);
    }
    ms->run();
    EXPECT_EQ(int64_t_out, *std::min_element(in.begin(), in.end()));
}
TEST_F(HostReductionTest, MaxInt64) {
    ms->simulation.addStepFunction(&step_maxint64_t);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_int_distribution <int64_t> dist(INT64_MIN, INT64_MAX);
    std::array<int64_t, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = dist(rd);
        instance.setVariable<int64_t>("int64_t", in[i]);
    }
    ms->run();
    EXPECT_EQ(int64_t_out, *std::max_element(in.begin(), in.end()));
}
TEST_F(HostReductionTest, SumInt64) {
    ms->simulation.addStepFunction(&step_sumint64_t);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_int_distribution <int64_t> dist(INT64_MIN, INT64_MAX);
    std::array<int64_t, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = dist(rd);
        instance.setVariable<int64_t>("int64_t", in[i]);
    }
    ms->run();
    EXPECT_EQ(int64_t_out, std::accumulate(in.begin(), in.end(), 0ll));
}
TEST_F(HostReductionTest, CustomReduceInt64) {
    ms->simulation.addStepFunction(&step_reduceint64_t);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_int_distribution <int64_t> dist(INT64_MIN, INT64_MAX);
    std::array<int64_t, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = dist(rd);
        instance.setVariable<int64_t>("int64_t", in[i]);
    }
    ms->run();
    EXPECT_EQ(int64_t_out, *std::max_element(in.begin(), in.end()));
}
TEST_F(HostReductionTest, HistogramEvenInt64) {
    ms->simulation.addStepFunction(&step_histogramEvenint64_t);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_int_distribution <int64_t> dist(0, 19);
    std::array<int64_t, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = dist(rd);
        instance.setVariable<int64_t>("int64_t", in[i]);
    }
    ms->run();
    auto check = histogramEven<int64_t, unsigned int>(in, 10, 0, 20);
    for (unsigned int i = 0; i < uint_vec.size(); ++i) {
        EXPECT_EQ(uint_vec[i], check[i]);
    }
}

/**
 * uint64_t
 */
TEST_F(HostReductionTest, MinUnsignedInt64) {
    ms->simulation.addStepFunction(&step_minuint64_t);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_int_distribution <uint64_t> dist(0, UINT64_MAX);
    std::array<uint64_t, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = dist(rd);
        instance.setVariable<uint64_t>("uint64_t", in[i]);
    }
    ms->run();
    EXPECT_EQ(uint64_t_out, *std::min_element(in.begin(), in.end()));
}
TEST_F(HostReductionTest, MaxUnsignedInt64) {
    ms->simulation.addStepFunction(&step_maxuint64_t);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_int_distribution <uint64_t> dist(0, UINT64_MAX);
    std::array<uint64_t, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = dist(rd);
        instance.setVariable<uint64_t>("uint64_t", in[i]);
    }
    ms->run();
    EXPECT_EQ(uint64_t_out, *std::max_element(in.begin(), in.end()));
}
TEST_F(HostReductionTest, SumUnsignedInt64) {
    ms->simulation.addStepFunction(&step_sumuint64_t);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_int_distribution <uint64_t> dist(0, UINT64_MAX);
    std::array<uint64_t, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = dist(rd);
        instance.setVariable<uint64_t>("uint64_t", in[i]);
    }
    ms->run();
    EXPECT_EQ(uint64_t_out, std::accumulate(in.begin(), in.end(), 0llu));
}
TEST_F(HostReductionTest, CustomReduceUnsignedInt64) {
    ms->simulation.addStepFunction(&step_reduceuint64_t);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_int_distribution <uint64_t> dist(0, UINT64_MAX);
    std::array<uint64_t, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = dist(rd);
        instance.setVariable<uint64_t>("uint64_t", in[i]);
    }
    ms->run();
    EXPECT_EQ(uint64_t_out, *std::max_element(in.begin(), in.end()));
}
TEST_F(HostReductionTest, HistogramEvenUnsignedInt64) {
    ms->simulation.addStepFunction(&step_histogramEvenuint64_t);
    std::mt19937 rd;  // Seed does not matter
    std::uniform_int_distribution <uint64_t> dist(0, 19);
    std::array<uint64_t, TEST_LEN> in;
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
        in[i] = dist(rd);
        instance.setVariable<uint64_t>("uint64_t", in[i]);
    }
    ms->run();
    auto check = histogramEven<uint64_t, int>(in, 10, 0, 20);
    for (unsigned int i = 0; i < int_vec.size(); ++i) {
        EXPECT_EQ(int_vec[i], check[i]);
    }
}

/**
 * Bad Types
 */
TEST_F(HostReductionTest, SumException) {
    ms->simulation.addStepFunction(&step_sumException);
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
    }
    ms->run();
}
TEST_F(HostReductionTest, MinException) {
    ms->simulation.addStepFunction(&step_minException);
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
    }
    ms->run();
}
TEST_F(HostReductionTest, MaxException) {
    ms->simulation.addStepFunction(&step_maxException);
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
    }
    ms->run();
}
TEST_F(HostReductionTest, CustomReductionException) {
    ms->simulation.addStepFunction(&step_customReductionException);
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
    }
    ms->run();
}
TEST_F(HostReductionTest, HistogramEvenException) {
    ms->simulation.addStepFunction(&step_histogramEvenException);
    for (unsigned int i = 0; i < TEST_LEN; i++) {
        AgentInstance instance = ms->population->getNextInstance();
    }
    ms->run();
}

#endif  // TESTS_TEST_CASES_RUNTIME_TEST_HOST_REDUCTIONS_H_
