//
//  Shaders.metal
//  visibleFunctions
//
//  Created by Eoin Roe on 08/09/2020.
//

#include <metal_stdlib>
using namespace metal;

[[visible]]
float4 purple_gradient(float2 st)
{
    return float4(st.x, 0.0, st.y, 1.0);
}

[[visible]]
float4 turquoise_gradient(float2 st)
{
    return float4(0.0, st.x, st.y, 1.0);
}

using GradientFunction = float4(float2);

kernel void visible(constant unsigned int &index [[buffer(0)]],
                    visible_function_table<GradientFunction> functions [[buffer(1)]],
                    texture2d<float, access::write> tex0,
                    uint2 tid [[thread_position_in_grid]])
{
    float2 uv = (float2)tid / float2(tex0.get_width(), tex0.get_height());
    
    tex0.write(functions[index](uv), tid);
}
