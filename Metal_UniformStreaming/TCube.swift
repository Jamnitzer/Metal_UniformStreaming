//------------------------------------------------------------------------------
//  derived from Apple's WWDC example "MetalUniformStreaming"
//  Created by Jim Wrenholt on 12/6/14.
//------------------------------------------------------------------------------
//    3d cube vertices, normals, texture coordinates, and indices.
//------------------------------------------------------------------------------
import UIKit
import Metal
import QuartzCore

let kCntVertices:UInt32 = 24
let kSzVertices:UInt32 = kCntVertices  * UInt32(sizeof(V3f))

let kCntNormals:UInt32 = kCntVertices
let kSzNormals:UInt32 = kCntNormals * UInt32(sizeof(V3f))

let kCntTexCoords:UInt32 = kCntVertices
let kSzTexCoords:UInt32 = kCntTexCoords * UInt32(sizeof(V2f))

//------------------------------------------------------------------------------
class TCube
{
    // buffer indices
    private var _mVertexIndex:Int = 0
    private var _mNormalIndex:Int = 1
    private var _mTexCoordIndex:Int = 2
    private var _mIndexCount:Int = 0
    
    // Dimensions
    private var _mLength:Float = 1.0
    private var _mSize = V3f(1.0, 1.0, 1.0)
    
    var mVertexBuffer:MTLBuffer?
    var mNormalBuffer:MTLBuffer?
    var mTexCoordBuffer:MTLBuffer?
    var mIndexBuffer:MTLBuffer?
    
    //-------------------------------------------------------------------------
    deinit
    {
        mVertexBuffer   = nil
        mNormalBuffer   = nil
        mTexCoordBuffer = nil
        mIndexBuffer    = nil
    }
    //-------------------------------------------------------------------------
    convenience init(device:MTLDevice, length:Float)
    {
        let cubeSize = V3f(length, length, length)
        self.init (device: device, cubeSize: cubeSize)
    }
    //-------------------------------------------------------------------------
    init(device:MTLDevice, cubeSize:V3f)
    {
        // setup the vertex buffers
        mVertexBuffer = newVertexBuffer(cubeSize, device: device)
        if (mVertexBuffer == nil)
        {
            print(">> ERROR: Failed creating a vertex buffer!")
            return
        }
        mNormalBuffer = newNormalBuffer(device)
        if (mNormalBuffer == nil)
        {
            print(">> ERROR: Failed creating a normals buffer!")
            return
        }
        mTexCoordBuffer = newTexCoordBuffer(device)
        if (mTexCoordBuffer == nil)
        {
            print(">> ERROR: Failed creating a texture coordinate buffer!")
            return
        }
        mIndexBuffer = newIndexBuffer(device)
        if (mIndexBuffer == nil)
        {
            print(">> ERROR: Failed creating an index buffer!")
            return
        }
    } // initWithDevice
    //-------------------------------------------------------------------------
    func newVertexBuffer(cubeSize:V3f, device:MTLDevice) -> MTLBuffer
    {
        _mSize = cubeSize
        _mLength = cubeSize.x
        
        let kVertices:[V3f] = [
            V3f(-_mSize.x, -_mSize.y, -_mSize.z),   //0
            V3f(-_mSize.x, -_mSize.y, -_mSize.z),   //0
            V3f(-_mSize.x, -_mSize.y, -_mSize.z),   //0
            
            V3f(-_mSize.x, -_mSize.y, _mSize.z),    //3
            V3f(-_mSize.x, -_mSize.y, _mSize.z),    //3
            V3f(-_mSize.x, -_mSize.y, _mSize.z),    //3
            
            V3f(_mSize.x, -_mSize.y, -_mSize.z),    //6
            V3f(_mSize.x, -_mSize.y, -_mSize.z),    //6
            V3f(_mSize.x, -_mSize.y, -_mSize.z),    //6
            
            V3f(_mSize.x, -_mSize.y, _mSize.z),     //9
            V3f(_mSize.x, -_mSize.y, _mSize.z),     //9
            V3f(_mSize.x, -_mSize.y, _mSize.z),     //9
            
            V3f(_mSize.x, _mSize.y, -_mSize.z),     //12
            V3f(_mSize.x, _mSize.y, -_mSize.z),     //12
            
            V3f(_mSize.x, _mSize.y, _mSize.z),      //14
            V3f(_mSize.x, _mSize.y, _mSize.z),      //14
            
            V3f(-_mSize.x, _mSize.y, -_mSize.z),    //16
            V3f(-_mSize.x, _mSize.y, -_mSize.z),    //16
            
            V3f(-_mSize.x, _mSize.y, _mSize.z),     //18
            V3f(-_mSize.x, _mSize.y, _mSize.z),     //18
            
            V3f( _mSize.x, _mSize.y, -_mSize.z),
            V3f( _mSize.x, _mSize.y,  _mSize.z),
            V3f(-_mSize.x, _mSize.y, -_mSize.z),
            V3f(-_mSize.x, _mSize.y,  _mSize.z)
        ]
        //----------------------------------------------------------
        //let v_pointer3f = UnsafePointer<V3f>(kVertices)
        //for (var i:Int = 0; i < kVertices.count; ++i)
        //{
        //    let ff = v_pointer3f[i]
        //    print("v3 = \(ff) ")
        //    
        //}
        //----------------------------------------------------------
        // Set the default vertex buffer index (binding point)
        mVertexIndex = 0

        //print("kVertices.count = \(kVertices.count)")
        //print("kVertices.count * sizeof(V3f) = \(kVertices.count * sizeof(V3f))")
        //print("kSzVertices = \(kSzVertices)")
       
        let vertexBuffer = device.newBufferWithBytes(
            UnsafePointer<Void>(kVertices),
            length: Int(kSzVertices),
            options: MTLResourceOptions.OptionCPUCacheModeDefault)
        
        return vertexBuffer
        
    } // newVertexBuffer
    //-------------------------------------------------------------------------
    func newNormalBuffer(device:MTLDevice) -> MTLBuffer
    {
        let kNormals:[V3f] =
        [
            V3f(  0.0,  0.0, -1.0 ),
            V3f( -1.0,  0.0,  0.0 ),
            V3f(  0.0, -1.0,  0.0 ),
            
            V3f(  0.0,  0.0, 1.0 ),
            V3f( -1.0,  0.0, 0.0 ),
            V3f(  0.0, -1.0, 0.0 ),
            
            V3f( 0.0,  0.0, -1.0 ),
            V3f( 1.0,  0.0,  0.0 ),
            V3f( 0.0, -1.0,  0.0 ),
            
            V3f( 0.0,  0.0,  1.0 ),
            V3f( 1.0,  0.0,  0.0 ),
            V3f( 0.0, -1.0,  0.0 ),
            
            V3f( 1.0, 0.0,  0.0 ),
            V3f( 0.0, 1.0,  0.0 ),
            
            V3f( 1.0, 0.0,  0.0 ),
            V3f( 0.0, 1.0,  0.0 ),
            
            V3f( -1.0, 0.0,  0.0 ),
            V3f(  0.0, 1.0,  0.0 ),
            
            V3f( -1.0, 0.0,  0.0 ),
            V3f(  0.0, 1.0,  0.0 ),
            
            V3f( 0.0, 0.0, -1.0 ),
            V3f( 0.0, 0.0,  1.0 ),
            V3f( 0.0, 0.0, -1.0 ),
            V3f( 0.0, 0.0,  1.0 )
        ]
        //----------------------------------------------------------
//        let v_pointer3f = UnsafePointer<V3f>(kNormals)
//        for (var i:Int = 0; i < kNormals.count; ++i)
//        {
//            let ff = v_pointer3f[i]
//            print("n3 = \(ff) ")
//            
//        }
//        //----------------------------------------------------------
//        print("kNormals.count = \(kNormals.count)")
//        print("kNormals.count * sizeof(V3f) = \(kNormals.count * sizeof(V3f))")
//        print("kSzNormals = \(kSzNormals)")

        // Set the default normal buffer index (binding point)
        mNormalIndex = 1
        
        let normalBuffer = device.newBufferWithBytes(
            UnsafePointer<Void>(kNormals),
            length: Int(kSzNormals),
            options: MTLResourceOptions.OptionCPUCacheModeDefault)
            
        return normalBuffer
        
    } // newNormalBuffer
    //-------------------------------------------------------------------------
    func newTexCoordBuffer(device:MTLDevice) -> MTLBuffer
    {
        let kTexCoords:[V2f] = [
            V2f(0.0, 1.0),
            V2f(1.0, 0.0),
            V2f(0.0, 0.0),
            
            V2f(0.0, 0.0),
            V2f(1.0, 1.0),
            V2f(0.0, 1.0),
            
            V2f(1.0, 1.0),
            V2f(0.0, 0.0),
            V2f(1.0, 0.0),
            
            V2f(1.0, 0.0),
            V2f(0.0, 1.0),
            V2f(1.0, 1.0),
            
            V2f(1.0, 0.0),
            V2f(0.0, 0.0),
            
            V2f(1.0, 1.0),
            V2f(0.0, 1.0),
            
            V2f(0.0, 0.0),
            V2f(1.0, 0.0),
            
            V2f(0.0, 1.0),
            V2f(1.0, 1.0),
            
            V2f(1.0, 0.0),
            V2f(1.0, 1.0),
            V2f(0.0, 0.0),
            V2f(0.0, 1.0)
        ]
        //----------------------------------------------------------
//        let v_pointer2f = UnsafePointer<V2f>(kTexCoords)
//        for (var i:Int = 0; i < kTexCoords.count; ++i)
//        {
//            let ff = v_pointer2f[i]
//            print("t2 = \(ff) ")
//            
//        }
        //----------------------------------------------------------
        // Set the default texture coordinate buffer index (binding point)
        mTexCoordIndex = 2
  
//        print("kTexCoords = \(kTexCoords.count)")
//        print("kTexCoords.count * sizeof(V2f) = \(kTexCoords.count * sizeof(V2f))")
//        print("kSzTexCoords = \(kSzTexCoords)")
        
        let texCoordBuffer = device.newBufferWithBytes(
            UnsafePointer<Void>(kTexCoords),
            length: Int(kSzTexCoords),
            options: MTLResourceOptions.OptionCPUCacheModeDefault)
        
            return texCoordBuffer
        
    } // newTexCoordBuffer
    //-------------------------------------------------------------------------
    func newIndexBuffer(device:MTLDevice) -> MTLBuffer
    {
        let kIndices:[UInt32] = [
            11,  5,  2,
            8, 11,  2,
            14, 10,  7,
            12, 14,  7,
            19, 15, 13,
            17, 19, 13,
            4, 18, 16,
            1,  4, 16,
            21, 23,  3,
            3,  9, 21,
            6,  0, 22,
            20,  6, 22  ]
        
        //----------------------------------------------------------
//        let v_pointer = UnsafePointer<UInt32>(kIndices)
//        for (var i:Int = 0; i < kIndices.count; i += 3)
//        {
//            var ff = v_pointer[i + 0]
//            print("idx = \(ff) ", terminator: "")
//             ff = v_pointer[i + 1]
//            print(", \(ff) ", terminator: "")
//             ff = v_pointer[i + 2]
//            print(", = \(ff) ")
//        }
        //----------------------------------------------------------
        let kSzIndices = kIndices.count * sizeof(UInt32)
        
        self.mIndexCount = kIndices.count
        
       //  let kCntIndicies:UInt32 = 36;
       //  print("kCntIndicies = \(kCntIndicies)")
       //  print("kIndices.count = \(kIndices.count)")
       //  print("kIndices.count * sizeof(UInt32) = \(kIndices.count * sizeof(UInt32))")
       //  print("kSzIndices = \(kSzIndices)")
        
        let indexBuffer = device.newBufferWithBytes(
            UnsafePointer<Void>(kIndices),
            length: kSzIndices,
            options: MTLResourceOptions.OptionCPUCacheModeDefault)
        
       return indexBuffer
        
    } // newIndexBuffer
    //-------------------------------------------------------------------------
    var mNormalIndex:Int
        {
        get {
            return self._mNormalIndex
        }
        set {
            self._mNormalIndex = newValue
        }
    }
    //-------------------------------------------------------------------------
    var mIndexCount:Int
        {
        get {
            return self._mIndexCount
        }
        set {
            self._mIndexCount = newValue
        }
    }
    //-------------------------------------------------------------------------
    var mTexCoordIndex:Int
        {
        get {
            return self._mTexCoordIndex
        }
        set {
            self._mTexCoordIndex = newValue
        }
    }
    //-------------------------------------------------------------------------
    var mVertexIndex:Int
        {
        get {
            return self._mVertexIndex
        }
        set {
            self._mVertexIndex = newValue
        }
    }
    //-------------------------------------------------------------------------
    var mSize:V3f
    {
        get {
            return self._mSize
        }
        set {
            let bIsChanged = ((newValue.x != self._mSize.x) ||
                (newValue.y != self._mSize.y) ||
                (newValue.z != self._mSize.z) )
            
            self._mSize = newValue
            
           if (bIsChanged)
            {
                let kVertices:[V3f] = [
                    V3f(-_mSize.x, -_mSize.y, -_mSize.z),   // 0
                    V3f(-_mSize.x, -_mSize.y, -_mSize.z),   // 0
                    V3f(-_mSize.x, -_mSize.y, -_mSize.z),   // 0
                    
                    V3f(-_mSize.x, -_mSize.y, _mSize.z),    // 3
                    V3f(-_mSize.x, -_mSize.y, _mSize.z),    // 3
                    V3f(-_mSize.x, -_mSize.y, _mSize.z),    // 3
                    
                    V3f(_mSize.x, -_mSize.y, -_mSize.z),    // 6
                    V3f(_mSize.x, -_mSize.y, -_mSize.z),    // 6
                    V3f(_mSize.x, -_mSize.y, -_mSize.z),    // 6
                    
                    V3f(_mSize.x, -_mSize.y, _mSize.z),     // 9
                    V3f(_mSize.x, -_mSize.y, _mSize.z),     // 9
                    V3f(_mSize.x, -_mSize.y, _mSize.z),     // 9
                    
                    V3f(_mSize.x, _mSize.y, -_mSize.z),     // 12
                    V3f(_mSize.x, _mSize.y, -_mSize.z),     // 12
                    
                    V3f(_mSize.x, _mSize.y, _mSize.z),      // 14
                    V3f(_mSize.x, _mSize.y, _mSize.z),      // 14
                    
                    V3f(-_mSize.x, _mSize.y, -_mSize.z),    // 16
                    V3f(-_mSize.x, _mSize.y, -_mSize.z),    // 16
                    
                    V3f(-_mSize.x, _mSize.y, _mSize.z),     // 18
                    V3f(-_mSize.x, _mSize.y, _mSize.z),     // 18
                    
                    V3f( _mSize.x, _mSize.y, -_mSize.z),
                    V3f( _mSize.x, _mSize.y,  _mSize.z),
                    V3f(-_mSize.x, _mSize.y, -_mSize.z),
                    V3f(-_mSize.x, _mSize.y,  _mSize.z) ]
                
                // Get the base address of the constant buffer
                if let vertex_buffer = mVertexBuffer
                {
                   let bufferPointer =
                    UnsafeMutablePointer<V3f>(vertex_buffer.contents())

                    let kSzVertices = kVertices.count * sizeof(V3f)
                    memcpy(bufferPointer, kVertices, Int(kSzVertices))
                    
                    print("kSzVertices:  \(kSzVertices)")
                    print("_mSize:  \(_mSize)")
                }
                else
                {
                    print("FAIL:  let vertex_buffer = mVertexBuffer")
                    //assert(false, "FAIL")
                }
            }
        }
    }
    //-------------------------------------------------------------------------
    var mLength:Float
    {
        get {
            return self._mLength
        }
        set {
            self._mLength = newValue
            mSize = V3f(newValue, newValue, newValue)
        }
    }
    //-------------------------------------------------------------------------
    func encode(renderEncoder:MTLRenderCommandEncoder)
    {
        renderEncoder.setVertexBuffer(
            mVertexBuffer!,
            offset: Int(0),
            atIndex: Int(mVertexIndex) )
        
        renderEncoder.setVertexBuffer(
            mNormalBuffer!,
            offset: Int(0),
            atIndex: Int(mNormalIndex) )
        
        renderEncoder.setVertexBuffer(
            mTexCoordBuffer!,
            offset: Int(0),
            atIndex: Int(mTexCoordIndex) )
        
    } // encode
    //-------------------------------------------------------------------------
    func draw(renderEncoder:MTLRenderCommandEncoder)
    {
        // Tell the render context we want to draw our first set of primitives
        renderEncoder.drawIndexedPrimitives(MTLPrimitiveType.Triangle,
            indexCount: Int(_mIndexCount),
            indexType: MTLIndexType.UInt32,
            indexBuffer: mIndexBuffer!,
            indexBufferOffset: 0)
    } // draw
    //-------------------------------------------------------------------------
}