/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Metal vertex and fragment shaders.
*/

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

// Include header shared between this Metal shader code and the C code executing Metal API commands.
#import "AAPLShaderTypes.h"

// Vertex shader outputs and fragment shader inputs.
typedef struct
{
    // The [[position]] attribute qualifier of this member indicates this value is the clip space
    // position of the vertex when this structure is returned from the vertex shader.
    float4 position [[position]];
    
    // size of point
    float pointsize[[point_size]];

    // Since this member does not have a special attribute qualifier, the rasterizer interpolates
    // its value with values of other vertices making up the triangle and passes the interpolated
    // value to the fragment shader for each fragment in that triangle.
    float4 color;

} RasterizerData;

// Vertex shader.
vertex RasterizerData
vertexShader(const uint vertexID [[ vertex_id ]],
             const device AAPLVertex *vertices [[ buffer(AAPLVertexInputIndexVertices) ]],
             constant vector_uint2 *viewportSizePointer  [[ buffer(AAPLVertexInputIndexViewportSize) ]])
{
    RasterizerData out;

   
    // Get the viewport size and cast to float.
    vector_float2 viewportSize = vector_float2(*viewportSizePointer);

    // Index into the array of positions to get the current vertex.
    // Positions are specified in pixel dimensions (i.e. a value of 100 is 100 pixels from the origin).
    // transform to Gravilux coordinate system
    float2 pixelSpacePosition = float2(vertices[vertexID].position.x,
                                       viewportSize.y - vertices[vertexID].position.y);

    
    // To convert from positions in pixel space to positions in clip-space,
    // divide the pixel coordinates by half the size of the viewport.
    out.position = vector_float4(0.0, 0.0, 0.0, 1.0);
    
    // transform to Gravilux coordinate system
    out.position.xy = pixelSpacePosition / (viewportSize / 2.0) - float2(1,1);

    
    out.pointsize = vertices[vertexID].size;

    // Pass the input color straight to the output color.
    out.color = vertices[vertexID].color;

    return out;
}

// Fragment shader.
//fragment float4 fragmentShader(RasterizerData in [[stage_in]])
//{
//    // Return the color you just set in the vertex shader.
//    return in.color;
//}

// antialiased circular point
fragment float4 fragmentShader(RasterizerData in [[stage_in]],
                               float2 pointCoord [[point_coord]])
{
    
    float dist = length(pointCoord - float2(0.5));
    float4 out_color = in.color;
    out_color.a = 1.0 - smoothstep(0.4, 0.5, dist);
//    return half4(out_color);
    
    // Return the color you just set in the vertex shader.
    return out_color;
}
