# Metal_UniformStreaming

A conversion to Swift of WWDC's example MetalUniformStreaming.

Metal creates data buffer resources that can be read and written to on the CPU and GPU asynchronously. This example demonstrates using a data buffer to set uniforms for the vertex and fragment shaders.

***
This example creates 3 different uniform buffers
and uses renderFrameCycle to cycle [0, 1, 2] through them.

In the class TPlasmaUniforms an array of buffers is declared..

    var mpUniformBuffer = [MTLBuffer]()
    
    init(device:MTLDevice, capacity:Int)
    {
        for (var i:Int = 0; i < capacity; ++i)
        {
            if let buffer = device.newBufferWithLength(kMaxBufferBytesPerFrame, options: nil)
            {
                buffer.label = "PlasmaConstantBuffer\(i)"
                mpUniformBuffer.append(buffer)
            }
        }
    }
        
In the update we use renderFrameCycle to get the correct uniform buffer for this pass.
And then copy our data into it.

    func upload() -> Bool
    {
        //--------------------------------------------
        // Get the constant buffer at index
        //--------------------------------------------
        var buffer:MTLBuffer? = mpUniformBuffer[renderFrameCycle]

        //--------------------------------------------
        // Get the base address of the constant buffer
        //--------------------------------------------
        var pBufferPointer = buffer!.contents()
        
        memcpy(pBufferPointer, uniformData, kSzVertUniformBuffer)
  }

And at render time we use the same renderFrameCycle to set the current uniformBuffer

    func encode(renderEncoder:MTLRenderCommandEncoder, offset:(x:Int, y:Int))
    {
        renderEncoder.setVertexBuffer(mpUniformBuffer[renderFrameCycle],
            offset:offset.x, atIndex:3 )
        
        renderEncoder.setFragmentBuffer(mpUniformBuffer[renderFrameCycle],
            offset:Int(kSzVertUniformBuffer) + offset.y, atIndex:0 )
    }

This is little more involved because in each of these 3 buffers 
there are four sets of uniform data.

The first is cubeA vertexUniforms and then the cubeA fragmentUniforms
The third is cubeB vertexUniforms and finally the cubeB fragmentUniforms

This is handled with mnEncodeIndex which just toggles [0, 1]
When mnEncodeIndex == 0 we encode the cubeA uniforms
When mnEncodeIndex == 1 we encode the cubeB uniforms

The shader is notified by the offsets where to look for the data.

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

note: I renamed this variable to renderFrameCycle.
The original program calls this variable mnMemBarrierIndex.  

![](https://raw.githubusercontent.com/Jamnitzer/Metal_UniformStreaming/master/screen.png)
