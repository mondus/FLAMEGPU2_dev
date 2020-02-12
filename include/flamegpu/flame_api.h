/*
* flame_api.h
*
*  Created on: 19 Feb 2014
*      Author: paul
*/

#ifndef INCLUDE_FLAMEGPU_FLAME_API_H_
#define INCLUDE_FLAMEGPU_FLAME_API_H_

// include all host API classes (top level header from each module)
#include "flamegpu/model/ModelDescription.h"
#include "flamegpu/model/AgentDescription.h"
#include "flamegpu/model/AgentFunctionDescription.h"
#include "flamegpu/model/MessageDescription.h"
#include "flamegpu/model/EnvironmentDescription.h"
#include "flamegpu/model/LayerDescription.h"
#include "flamegpu/pop/AgentPopulation.h"
#include "flamegpu/gpu/CUDAAgentModel.h"
#include "flamegpu/runtime/flamegpu_api.h"
#include "flamegpu/runtime/messaging.h"

#endif  // INCLUDE_FLAMEGPU_FLAME_API_H_
