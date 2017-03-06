#include <cuda_runtime.h>

#include "../flame_functions_api.h"

#include "../tests/test_func_pointer.h"


__global__ void agent_function_wrapper(FLAMEGPU_AGENT_FUNCTION_POINTER func)
{

    //create a new device FLAME_GPU instance
    FLAMEGPU_API *api = new FLAMEGPU_API();
    printf("hello from wrapper %d\n",threadIdx.x);

//printf("funct pointer address is %08X\n", func);
//printf("output_func pointer address is %08X\n", output_func);

    //call the user specified device function
    func(api);


    /*FLAME_GPU_AGENT_STATUS flag = func(api);
        if (flag == 1){
        // delete the agent
        printf("Agent DEAD!\n");
        }
        else{
        printf("Agent ALIVE!\n");
        }
    */

    //do something with the return value to set a flag for deletion
}
