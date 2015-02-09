//------------------------------------------------------------------------------
//  derived from Apple's WWDC example "MetalUniformStreaming"
//  Created by Jim Wrenholt on 12/6/14.
//------------------------------------------------------------------------------
// Plasma shader uniforms encapsulated utility class.
//------------------------------------------------------------------------------
import UIKit
import Metal
import QuartzCore

let kCntVertUniformBuffer:UInt32 = 2
let kCntFragUniformBuffer:UInt32 = 2

let kSzVertUniformBuffer = UInt(kCntVertUniformBuffer * kSzVertUniforms)
let kSzFragUniformBuffer = UInt(kCntFragUniformBuffer * kSzFragUniforms)
let kMaxBufferBytesPerFrame = Int(kSzVertUniformBuffer + kSzFragUniformBuffer)

let kMaxEncodes:Int = 2

let kFOVY:Float = 65.0
let kRotationDelta:Float = 2.0

let kEye = V3f(0.0, 0.0, 0.0)
let kCenter = V3f(0.0, 0.0, 1.0)
let kUp = V3f(0.0, 1.0, 1.0)

var zeroRect:CGRect = CGRectMake(0, 0, 0, 0)

//-----------------------------------------------------------------------------
class TPlasmaUniforms
{
    var m_Plasma_Params = [TPlasmaParams]()
    var m_VertUniforms = [Vertex]()
    var m_FragUniforms = [Fragment]()
    var m_Orientation = [UIInterfaceOrientation]()

    var m_Transforms = Transforms(
                mnAspect: Float(0.0),
                mnFOVY: 0.0,
                mnRotation:Float(0.0),
                m_Projection: M4f(),
                m_View: M4f(),
                m_Model: M4f(),
                m_ModelView: M4f() )

    var mpUniformBuffer = [MTLBuffer]()
   
    var mnCapacity: Int = 0
    var renderFrameCycle: Int = 0
    var mnEncodeIndex: Int = 0

    private var _bounds = zeroRect

    //-------------------------------------------------------------------------
    init(device:MTLDevice, capacity:Int)
    {
        //--------------------------------------------
        // Set the total number of inflight buffers
        //--------------------------------------------
        mnCapacity = capacity
        println("capacity = \(capacity )")
        println("kCntVertUniformBuffer = \(kCntVertUniformBuffer )")
        println("kSzVertUniforms = \(kSzVertUniforms )")
        println("kSzVertUniformBuffer = \(kSzVertUniformBuffer )")
        println("kSzFragUniformBuffer = \(kSzFragUniformBuffer )")
        println("kMaxBufferBytesPerFrame = \(kMaxBufferBytesPerFrame )")
      
        //--------------------------------------------
        // allocate one region of memory for the constant buffer per max in
        // flight command buffers so that memory is properly syncronized.
        //--------------------------------------------
        var i:UInt32 = 0
        for (var i:Int = 0; i < mnCapacity; ++i)
        {
            //--------------------------------------------
            // Create a new constant buffer
            //--------------------------------------------
            if let buffer = device.newBufferWithLength(kMaxBufferBytesPerFrame, options: nil)
            {
                //--------------------------------------------
                // Set a label for the constant buffer
                //--------------------------------------------
                buffer.label = "PlasmaConstantBuffer\(i)"
                
                //--------------------------------------------
                // Add the constant buffer to the mutable array
                //--------------------------------------------
                mpUniformBuffer.append(buffer)
            }
            else
            {
                println(">> ERROR: Failed creating a new buffer!")
                break
            }
        }
        
        if mpUniformBuffer.count != mnCapacity
        {
            println(">> ERROR: Failed creating all the requested buffers!")
            return
        }
        
        //---------------------------------------------------------------------
        for (var I:Int = 0; i < 2; ++i)
        {
            let mv = M4f()
            let proj = M4f()
            let v = Vertex(m_ModelView:mv, m_Projection:proj)
            m_VertUniforms.append(v)
        
            let time = Float(0.0)
            let scale = Float(0.0)
            let type = UInt32(0)
            let f = Fragment(mnTime:time, mnScale:scale, mnType:type)
            m_FragUniforms.append(f)
        
            var rtime = ParamBlock(0.0, 0.08, 0.0, 12.0 * Float(M_PI), 1.0)
            var rscale = ParamBlock(1.0, 0.125, 1.0, 32.0, 1.0)
            let ps = TPlasmaParams(rTime:rtime, rScale:rscale)
            m_Plasma_Params.append(ps)
        
            m_Orientation.append(.Unknown)
            
        }
        //---------------------------------------------------------------------
        m_FragUniforms[0].mnType = 1
        m_FragUniforms[1].mnType = 2
        
        m_Transforms.mnAspect   = Float(0.0)
        m_Transforms.mnRotation = Float(0.0)
        m_Transforms.mnFOVY     = kFOVY
        m_Transforms.m_Projection = M4f()
        m_Transforms.m_View      = lookAt(kEye, kCenter, kUp)
        m_Transforms.m_Model     = translate(0.0, 0.0, 7.0)
        m_Transforms.m_ModelView = translate(0.0, 0.0, 1.5)
        
        renderFrameCycle = 0
        mnEncodeIndex     = 0

        println("## m_Transforms.mnAspect = \(m_Transforms.mnAspect)")
        println("## m_Transforms.m_Projection = \(m_Transforms.m_Projection) ")
        println()
   }
    //-------------------------------------------------------------------------
    deinit
    {
        // mpUniformBuffer = nil
    }
    //-------------------------------------------------------------------------
    func upload() -> Bool
    {
        //--------------------------------------------
        // Get the constant bufferm at index
        //--------------------------------------------
        var buffer:MTLBuffer? = mpUniformBuffer[renderFrameCycle]
        if (buffer == nil)
        {
            println(">> ERROR: Failed to get the constant buffer")
            return false
        }
        //--------------------------------------------
        // Get the base address of the constant buffer
        //--------------------------------------------
        var pBufferPointer = buffer!.contents()
        if (pBufferPointer == nil)  // uint8_t buffer.contents()
        {
            println(">> ERROR: Failed to get the constant buffer pointer!")
            return false
        }
        //--------------------------------------------
        var ff = [Float]()
        ff += m_VertUniforms[0].m_ModelView.GetArray()
        ff += m_VertUniforms[0].m_Projection.GetArray()
        ff += m_VertUniforms[1].m_ModelView.GetArray()
        ff += m_VertUniforms[1].m_Projection.GetArray()
        
        //--------------------------------------------
        // Copy the updated linear transformations for 
        // both cubes into the constant vertex buffer
        //--------------------------------------------
        memcpy(pBufferPointer, ff, kSzVertUniformBuffer)

        //--------------------------------------------
        // Increment the buffer pointer to where we 
        // can write fragment constant data
        //--------------------------------------------
        pBufferPointer += Int(kSzVertUniformBuffer)

        //--------------------------------------------
        // Copy scale and time factors for both cubes 
        // into the constant fragment buffer
        //--------------------------------------------
        memcpy(pBufferPointer, m_FragUniforms, kSzFragUniformBuffer)
        
        return true
    }
    //-------------------------------------------------------------------------
    func encode(renderEncoder:MTLRenderCommandEncoder, offset:(x:Int, y:Int))
    {
        renderEncoder.setVertexBuffer(mpUniformBuffer[renderFrameCycle],
            offset:offset.x, atIndex:3 )
        
        renderEncoder.setFragmentBuffer(mpUniformBuffer[mnMemBarrierIndex],
            offset:Int(kSzVertUniformBuffer) + offset.y, atIndex:0 )
    }
    //-------------------------------------------------------------------------
    func encode(renderEncoder:MTLRenderCommandEncoder)
    {
       var offset:(x:Int, y:Int) = (0, 0)
        
        if (mnEncodeIndex == 0)
        {
            encode(renderEncoder, offset:offset)
        }
        else if (mnEncodeIndex == 1)
        {
            offset.x = Int(kSzVertUniforms)
            offset.y = Int(kSzFragUniforms)
            
            encode(renderEncoder, offset:offset)

            // Increment the memory barrier index
            renderFrameCycle = (renderFrameCycle + 1) % mnCapacity
        }
        mnEncodeIndex = (mnEncodeIndex + 1) % kMaxEncodes
    }
    //-------------------------------------------------------------------------
    var bounds: CGRect
    {
        get {
            return self._bounds
        }
        set {
            self._bounds = newValue

            if (newValue.size.width == 0)
            {
                return
            }
            //----------------------------------------------------
            // To correctly compute the aspect ratio
            // determine the device interface orientation.
            //----------------------------------------------------
            m_Orientation[0] = UIApplication.sharedApplication().statusBarOrientation

            if (m_Orientation[0] != m_Orientation[1])
            {
                // Set the bounds
                self._bounds = newValue
                
                let w = self._bounds.size.width
                let h = self._bounds.size.height
                let r = w / h
                
                // Get the bounds for the current rendering layer
                m_Transforms.mnAspect     = Float(abs(r))
                m_Transforms.m_Projection = perspective_fov(
                    m_Transforms.mnFOVY, m_Transforms.mnAspect, 0.1, 100.0)
                
                m_VertUniforms[0].m_Projection = m_Transforms.m_Projection
                m_VertUniforms[1].m_Projection = m_Transforms.m_Projection
                
                m_Orientation[1] = m_Orientation[0]
                
                println("## m_Transforms.mnAspect = \(m_Transforms.mnAspect)")
                println("## m_Transforms.m_Projection = \(m_Transforms.m_Projection) ")
                println()
            }
        }
    }
    //-------------------------------------------------------------------------
    func update()
    {
        var rotateA:M4f = rotate(m_Transforms.mnRotation, 0.0, 1.0, 0.0)
        var model:M4f = m_Transforms.m_Model * rotateA
        var modelViewBase:M4f = m_Transforms.m_View * model
 
        rotateA = rotate(m_Transforms.mnRotation, 1.0, 1.0, 1.0)

        var modelView:M4f = m_Transforms.m_ModelView * rotateA
        modelView = modelViewBase * modelView

        //------------------------------------------------------------------
        // Set the mode-view matrix for the primary vertex constant buffer
        //------------------------------------------------------------------
        m_VertUniforms[0].m_ModelView = modelView
       
        modelView = M4f.TranslationMatrix(V3f(0.0, 0.0, -1.5))
        modelView = modelView * rotateA
        modelView = modelViewBase * modelView

        //------------------------------------------------------------------
        // Set the mode-view matrix for the second vertex constant buffer
        //------------------------------------------------------------------
        m_VertUniforms[1].m_ModelView = modelView
        
        //------------------------------------------------------------------
        // update rotation
        //------------------------------------------------------------------
        m_Transforms.mnRotation += kRotationDelta
        
        //------------------------------------------------------------------
        // Update the plasma animation
        //------------------------------------------------------------------
        var v:V2f = m_Plasma_Params[0].update()
        
        m_FragUniforms[0].mnTime  = v.x
        m_FragUniforms[0].mnScale = v.y
        
        var w:V2f = m_Plasma_Params[1].update()
        
        m_FragUniforms[1].mnTime  = w.x
        m_FragUniforms[1].mnScale = w.y
        
    }
    //-----------------------------------------------------------------------
}
//-----------------------------------------------------------------------------

