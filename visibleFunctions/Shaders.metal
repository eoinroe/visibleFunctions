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

[[visible]]
float4 yellow_gradient(float2 st)
{
    return float4(st.x, st.y, 0.0, 1.0);
}

[[visible]]
float test(float r, unsigned int depth)
{
    if (depth <= 0) {
        return r;
    }
    
    return 0.5 * test(r, depth - 1);
}

using GradientFunction = float4(float2);
using RecursiveFunction = float(float, unsigned int);

struct Colors {
    device float3 *vertexColors;
};

kernel void visible(constant unsigned int &index [[buffer(0)]],
                    visible_function_table<GradientFunction> gradient_functions [[buffer(1)]],
                    visible_function_table<RecursiveFunction> recursive_functions [[buffer(2)]],
                    device void *resources [[buffer(3)]],
                    device float3 *cols [[buffer(4)]],
                    texture2d<float, access::write> tex0,
                    uint2 tid [[thread_position_in_grid]])
{
    device Colors & colors = *(device Colors *)((device char *)resources);
    
    float4 col = float4(colors.vertexColors[0], 1);
    tex0.write(col, tid);
    
    // float2 uv = (float2)tid / float2(tex0.get_width(), tex0.get_height());
    // tex0.write(gradient_functions[index](uv), tid);
    
    // Expecting dark gray color...
    // float r = recursive_functions[0](1.0f, 3);
    // tex0.write(float4(float3(r), 1.0), tid);
}
