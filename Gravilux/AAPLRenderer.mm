/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation of a platform independent renderer class, which performs Metal setup and per frame rendering
*/

//@import simd;
 
//@import MetalKit;
#import "AAPLRenderer.h"
#ifndef OPENGL_ENABLED
#import "AAPLTriangle.h"
#import "AAPLShaderTypes.h"
#import "Gravilux.h"
#import "ofxMSAShape3D.h"
#import "defs.h"
#import "Parameters.h"
#import "Visualizer.h"
#import "Grain.h"
// Header shared between C code here, which executes Metal API commands, and .metal files, which
// uses these types as inputs to the shaders.
#import "AAPLShaderTypes.h"
//Gravilux *gGravilux;

// The maximum number of frames in flight.
static const NSUInteger MaxFramesInFlight = 3;

// Main class performing the rendering
@implementation AAPLRenderer
{
    dispatch_semaphore_t _inFlightSemaphore;

    // A series of buffers containing dynamically-updated vertices.
    id<MTLBuffer> _vertexBuffers[MaxFramesInFlight];

    // The index of the Metal buffer in _vertexBuffers to write to for the current frame.
    NSUInteger _currentBuffer;

    id<MTLDevice> _device;

    id<MTLCommandQueue> _commandQueue;

    id<MTLRenderPipelineState> _pipelineState;

    vector_uint2 _viewportSize;

    NSUInteger _totalVertexCount;
}

- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView
{
    self = [super init];
    if(self)
    {
        _device = mtkView.device; 
        _inFlightSemaphore = dispatch_semaphore_create(MaxFramesInFlight);
        
         // Load all the shader files with a metal file extension in the project.
         id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];

         // Load the vertex shader.
         id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"vertexShader"];

         // Load the fragment shader.
         id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"fragmentShader"];

         // Create a reusable pipeline state object.
         MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
         pipelineStateDescriptor.label = @"MyPipeline";
         pipelineStateDescriptor.sampleCount = mtkView.sampleCount;
         pipelineStateDescriptor.vertexFunction = vertexFunction;
         pipelineStateDescriptor.fragmentFunction = fragmentFunction;
         pipelineStateDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;
         pipelineStateDescriptor.vertexBuffers[AAPLVertexInputIndexVertices].mutability = MTLMutabilityImmutable;
        
        // Configure antialiasing for points.
        
        // glEnable(GL_BLEND)
        pipelineStateDescriptor.colorAttachments[0].blendingEnabled = true;

        // glBlendFuncSeparate(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA,GL_ONE,GL_ONE_MINUS_SRC_ALPHA)

        pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
        pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
        pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorOne;
        pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
        
         NSError *error = NULL;
         _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
         if (!_pipelineState)
         {
            NSLog(@"Failed to created pipeline state, error %@", error);
         }
         // Create the command queue.
         _commandQueue = [_device newCommandQueue];

         [self allocateVertexBuffers];
    }
    return self;

}

- (void)allocateVertexBuffers
{
   _totalVertexCount = gGravilux->nGrains();
   const NSUInteger vertexBufferSize = _totalVertexCount * sizeof(AAPLVertex);

     for(NSUInteger bufferIndex = 0; bufferIndex < MaxFramesInFlight; bufferIndex++)
     {
        _vertexBuffers[bufferIndex] = [_device newBufferWithLength:vertexBufferSize
                                                           options:MTLResourceStorageModeShared];
        _vertexBuffers[bufferIndex].label = [NSString stringWithFormat:@"Vertex Buffer #%lu", (unsigned long)bufferIndex];
     }
}

/// Updates the position of each triangle and also updates the vertices for each triangle in the current buffer.
- (void)updateState
{
    // Copy vertices from Gravilux
    NSUInteger nVertices = gGravilux->nGrains();
    
    if (nVertices > _totalVertexCount) {
        #warning are the old ones automatically freed?
        // reallocate vertext buffers
        [self allocateVertexBuffers];
    }
    
    AAPLVertex *currentVertices = (AAPLVertex *)_vertexBuffers[_currentBuffer].contents;
    
    // Update the vertices of the current vertex buffer with Gravilux points
    gGravilux->drawMetal(currentVertices);
}

  
#pragma mark - MetalKit View Delegate

 /// Handles view orientation or size changes.
 - (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
 {
     CGSize drawSize = gGravilux->screenSize();
     
     // Save the size of the drawable as you'll pass these
     // values to the vertex shader when you render.
     _viewportSize.x = drawSize.width;
     _viewportSize.y = drawSize.height;
     
//     ((UIScreen *)[[UIScreen screens] objectAtIndex:0]).bounds.size
 }


/// Called whenever the view needs to render a frame.
- (void)drawInMTKView:(nonnull MTKView *)view
{
  
    // Wait to ensure only `MaxFramesInFlight` number of frames are getting processed
    // by any stage in the Metal pipeline (CPU, GPU, Metal, Drivers, etc.).
    dispatch_semaphore_wait(_inFlightSemaphore, DISPATCH_TIME_FOREVER);

    // Iterate through the Metal buffers, and cycle back to the first when you've written to the last.
    _currentBuffer = (_currentBuffer + 1) % MaxFramesInFlight;

    // Update buffer data.
    [self updateState];
     

     // Create a new command buffer for each rendering pass to the current drawable.
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"MyCommandBuffer";

    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    if(renderPassDescriptor != nil)
    {
        // Create a render command encoder to encode the rendering pass.
        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        renderEncoder.label = @"MyRenderEncoder";

        // Set render command encoder state.
        [renderEncoder setRenderPipelineState:_pipelineState];

        // Set the current vertex buffer.
        [renderEncoder setVertexBuffer:_vertexBuffers[_currentBuffer]
                                offset:0
                               atIndex:AAPLVertexInputIndexVertices];

        // Set the viewport size.
        [renderEncoder setVertexBytes:&_viewportSize
                               length:sizeof(_viewportSize)
                              atIndex:AAPLVertexInputIndexViewportSize];

        // Draw the points.
        [renderEncoder drawPrimitives:MTLPrimitiveTypePoint
                          vertexStart:0
                          vertexCount:gGravilux->nGrains()];
         

        // Finalize encoding.
        [renderEncoder endEncoding];

        // Schedule a drawable's presentation after the rendering pass is complete.
        [commandBuffer presentDrawable:view.currentDrawable];
    
    }

    // Add a completion handler that signals `_inFlightSemaphore` when Metal and the GPU have fully
    // finished processing the commands that were encoded for this frame.
    // This completion indicates that the dynamic buffers that were written-to in this frame, are no
    // longer needed by Metal and the GPU; therefore, the CPU can overwrite the buffer contents
    // without corrupting any rendering operations.
    __block dispatch_semaphore_t block_semaphore = _inFlightSemaphore;
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer)
     {
         dispatch_semaphore_signal(block_semaphore);
     }];

    // Finalize CPU work and submit the command buffer to the GPU.
    [commandBuffer commit];
}

@end
#endif
