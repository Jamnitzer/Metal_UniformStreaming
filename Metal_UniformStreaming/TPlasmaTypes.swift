//------------------------------------------------------------------------------
//  derived from Apple's WWDC example "MetalUniformStreaming"
//  Created by Jim Wrenholt on 12/6/14.
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Structure type definitions for plasma uniforms.
//------------------------------------------------------------------------------
struct Vertex
{
    var m_ModelView:M4f
    var m_Projection:M4f
}
//------------------------------------------------------------------------------
struct Fragment
{
    var mnTime:Float
    var mnScale:Float
    var mnType:UInt32
}
//------------------------------------------------------------------------------
struct Transforms
{
    var mnAspect:Float
    var mnFOVY:Float
    var mnRotation:Float
    var m_Projection:M4f
    var m_View:M4f
    var m_Model:M4f
    var m_ModelView:M4f
}
//------------------------------------------------------------------------------
let kSzVertUniforms = UInt32(sizeof(Float) * 32)
let kSzFragUniforms = UInt32(sizeof(Float) * 2 + sizeof(UInt32))
