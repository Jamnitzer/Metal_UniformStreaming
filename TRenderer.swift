//------------------------------------------------------------------------------
//  derived from Apple's WWDC example "MetalUniformStreaming"
//  Created by Jim Wrenholt on 12/6/14.
//------------------------------------------------------------------------------
import Foundation
import UIKit
import Metal
import QuartzCore

let kInFlightCommandBuffers = 3

//------------------------------------------------------------------------------
class TRenderer :  MetalViewProtocol, TViewControllerDelegate
{
    //------------------------------------------------------------
    // renderer will create a default device at init time.
    //------------------------------------------------------------
    var device:MTLDevice?
    var m_CommandQueue:MTLCommandQueue?
    var m_ShaderLibrary:MTLLibrary?

    let m_InflightSemaphore = dispatch_semaphore_create(kInFlightCommandBuffers)
    
    var m_PipelineState:MTLRenderPipelineState?
    var m_DepthState:MTLDepthStencilState?

    var depthPixelFormat:MTLPixelFormat?
    var stencilPixelFormat:MTLPixelFormat?
    
    var sampleCount:Int = 0
    
    var mpCube:TCube?
    var mpPlasmaUniforms:TPlasmaUniforms?
    
    //-------------------------------------------------------------------------
    func cleanup()
    {
        m_PipelineState  = nil
        m_DepthState     = nil
        m_ShaderLibrary  = nil
        m_CommandQueue   = nil
        mpPlasmaUniforms = nil
        mpCube           = nil
    }
    //-------------------------------------------------------------------------
    init()
    {
        // Set the default pixel sample count
        sampleCount = 4
        
        // Set the default pixel formats
        depthPixelFormat = MTLPixelFormat.Depth32Float
        stencilPixelFormat = MTLPixelFormat.Invalid
        
        //------------------------------------------------------------
        // find a usable Device
        //------------------------------------------------------------
        device = MTLCreateSystemDefaultDevice()
        
        // load offline compiled shaders
        m_ShaderLibrary = device!.newDefaultLibrary()
        if (m_ShaderLibrary == nil)
        {
            println(">> ERROR: Couldnt create a default shader library")
            //------------------------------------------------------------
            // assert here becuase if the shader libary isnt loading,
            // its good place to debug why shaders arent compiling
            //------------------------------------------------------------
            // assert(0)
        }
        m_InflightSemaphore = dispatch_semaphore_create(kInFlightCommandBuffers)
    }
    //-------------------------------------------------------------------------
    // mark RENDER VIEW DELEGATE METHODS
    //-------------------------------------------------------------------------
    func configure(view:TView)
    {
        //------------------------------------------------------------
        // load all assets before triggering rendering
        //------------------------------------------------------------
        view.depthPixelFormat   = depthPixelFormat!
        view.stencilPixelFormat = stencilPixelFormat!
        view.sampleCount        = sampleCount
        
        //------------------------------------------------------------
        // create a new command queue
        //------------------------------------------------------------
        m_CommandQueue = device!.newCommandQueue()

        if (!preparePipelineState())
        {
            println(">> ERROR: Failed creating a depth stencil state descriptor!")
        }
        if (!setupContent())
        {
            println(">> ERROR: Failed loading the assets!")
        }
    }
    //-------------------------------------------------------------------------
    func preparePipelineState() -> Bool
    {
        // load the vertex program into the library
        let vertexProgram = m_ShaderLibrary!.newFunctionWithName("plasmaVertex")

        // load the fragment program into the library
        let fragmentProgram = m_ShaderLibrary!.newFunctionWithName("plasmaFragment")

        if (vertexProgram == nil)
        {
            println(">> ERROR: Couldnt load vertex function from default library")
        }
        if (fragmentProgram == nil)
        {
            println(">> ERROR: Couldnt load fragment function from default library")
        }
        
        //------------------------------------------------------------
        //  create a reusable pipeline state
        //------------------------------------------------------------
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        
        pipelineStateDescriptor.label = "MyPipeline"
        pipelineStateDescriptor.depthAttachmentPixelFormat = depthPixelFormat!
        pipelineStateDescriptor.stencilAttachmentPixelFormat = stencilPixelFormat!
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .BGRA8Unorm
        
        pipelineStateDescriptor.sampleCount      = sampleCount
        pipelineStateDescriptor.vertexFunction   = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram

        var pipelineError : NSError?
        m_PipelineState = device!.newRenderPipelineStateWithDescriptor(
            pipelineStateDescriptor, error: &pipelineError)
        
        if (m_PipelineState == nil)
        {
            println(">> ERROR: Failed creating a new render pipeline state descriptor:")
        }
        return true

    }
    //-------------------------------------------------------------------------
        func setupContent() -> Bool
        {
        // Create 3d cube with fixed dimensions
        let size = V3f(0.75, 0.75, 0.75)
        
        mpCube = TCube(device: device!, cubeSize: size)
        if (mpCube == nil)
        {
            println(">> ERROR: Failed creating 3d cube!")
            return false
        }

        // allocate one region of memory for the constant buffer per max in
        // flight command buffers so that memory is properly syncronized.
        mpPlasmaUniforms = TPlasmaUniforms(device: device!, capacity:kInFlightCommandBuffers)
        if (mpPlasmaUniforms == nil)
        {
            println(">> ERROR: Failed creating plasma constants!")
            return false
        }
        
        if (!prepareDepthState())
        {
            println(">> ERROR: Failed creating a depth stencil!")
            return false
        }
        return true
    }
    //-------------------------------------------------------------------------
    func prepareDepthState() -> Bool
    {
        var pDepthStateDesc = MTLDepthStencilDescriptor()
        pDepthStateDesc.depthCompareFunction = MTLCompareFunction.Less
        pDepthStateDesc.depthWriteEnabled    = true
        
        m_DepthState = device!.newDepthStencilStateWithDescriptor(pDepthStateDesc)
        if (m_DepthState == nil)
        {
            return false
        }
        
        return true
    }
    //-------------------------------------------------------------------------
    func encode(renderEncoder:MTLRenderCommandEncoder)
    {
        // Set context state with the render encoder
        renderEncoder.pushDebugGroup("plasma cubes")
        renderEncoder.setDepthStencilState(m_DepthState!)
        renderEncoder.setRenderPipelineState(m_PipelineState!)
        
        // Encode a 3d cube into renderer
        mpCube!.encode(renderEncoder)
        
        // Encode into renderer the first set of vertex and fragment uniforms
        mpPlasmaUniforms!.encode(renderEncoder)
        
        // Tell the render context we want to draw our first set of primitives
        mpCube!.draw(renderEncoder)
        
        // Encode into renderer the second set of vertex and fragment uniforms
        mpPlasmaUniforms!.encode(renderEncoder)
        
        // Tell the render context we want to draw our second set of primitives
        mpCube!.draw(renderEncoder)
        
        // The encoding is now complete
        renderEncoder.endEncoding()
        renderEncoder.popDebugGroup()
    }
    //-------------------------------------------------------------------------
    func render(view:TView)
    {
        // Wait on semaphore
       dispatch_semaphore_wait(m_InflightSemaphore, DISPATCH_TIME_FOREVER)
        
        // Upload the uniforms into the structure bound to shaders
        mpPlasmaUniforms!.upload()
        
        // Acquire a command buffer
        let commandBuffer = m_CommandQueue!.commandBuffer()
        
        //------------------------------------------------------------
        // create a render command encoder so we can render into something
        //------------------------------------------------------------
        let renderPassDescriptor:MTLRenderPassDescriptor? = view.renderPassDescriptor()
        
        if (renderPassDescriptor != nil)
        {
            let renderEncoder:MTLRenderCommandEncoder? =
            commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor!)
            if (renderEncoder == nil)
            {
                println("NO renderEncoder")
            }
            // Encode into a renderer
            encode(renderEncoder!)
            
            //----------------------------------------------------------------
            // call the view's completion handler which is required by
            // the view since it will signal its semaphore and set up the next buffer
            //----------------------------------------------------------------
            commandBuffer.addCompletedHandler {
                [weak self] commandBuffer in
                if let strongSelf = self
                {
                   dispatch_semaphore_signal(strongSelf.m_InflightSemaphore)
                }
            }

            // schedule a present once the framebuffer is complete
            let view_drawable = view.currentDrawable()!
            let mtl_drawable = view_drawable as MTLDrawable
            
            commandBuffer.presentDrawable(mtl_drawable)
            
            // finalize rendering here. this will push the command buffer to the GPU
            commandBuffer.commit()
        }
        else
        {
            // release the semaphore to keep things synchronized even if we couldnt render
            dispatch_semaphore_signal(m_InflightSemaphore)
        }
    }
    //-------------------------------------------------------------------------
    func reshape(view:TView)
    {
        mpPlasmaUniforms!.bounds = view.bounds;
    }
    //-------------------------------------------------------------------------
    // mark VIEW CONTROLLER DELEGATE METHODS
    //-------------------------------------------------------------------------
    func update(controller:TViewController)
    {
        mpPlasmaUniforms!.update()
    }
    //-------------------------------------------------------------------------
    func viewController(controller:TViewController, willPause:Bool)
    {
        // timer is suspended/resumed
        // Can do any non-rendering related background work here when suspended
    }
    //-------------------------------------------------------------------------
}