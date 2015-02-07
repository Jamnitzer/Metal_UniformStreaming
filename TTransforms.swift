//------------------------------------------------------------------------------
//  derived from Apple's WWDC example "MetalUniformStreaming"
//  Created by Jim Wrenholt on 12/6/14.
//------------------------------------------------------------------------------
import UIKit
import Metal
import QuartzCore

let kPi_f:Float = Float(M_PI)
let k1Div180_f:Float = 1.0 / 180.0
let kRadians_f:Float = k1Div180_f * kPi_f

let zeroVector4 = V4f(0.0, 0.0, 0.0, 0.0)

//------------------------------------------------------------------------------
// mark Private - Utilities
//------------------------------------------------------------------------------
func radians(degrees:Float) -> Float
{
    return kRadians_f * degrees
}
//------------------------------------------------------------------------------
// mark Public - Transformations - Scale
//------------------------------------------------------------------------------
func scale(x:Float, y:Float, z:Float) -> V4f
{
    var scale4:V4f = V4f(x, y, z, 1.0)
    return scale4
}
//------------------------------------------------------------------------------
func scale(s:V3f) -> V4f
{
    var scale4:V4f = V4f(s.x, s.y, s.z, 1.0)
    return scale4
}
//------------------------------------------------------------------------------
// mark Public - Transformations - Translate
//------------------------------------------------------------------------------
func translate(t:V3f) -> M4f
{
    var translateM4 = M4f.TranslationMatrix(t)
    return translateM4
}
//------------------------------------------------------------------------------
func translate(x:Float, y:Float, z:Float) -> M4f
{
    return translate(V3f(x, y, z))
}
//------------------------------------------------------------------------------
// mark Public - Transformations - Rotate
//------------------------------------------------------------------------------
func RadiansOverPi(degrees:Float) -> Float
{
    return degrees * k1Div180_f
}
//------------------------------------------------------------------------------
func sinCosPI(angle:Float) -> (Float, Float)
{
    // Computes the sine and cosine of pi times angle (measured in radians)
    // faster and gives exact results for angle = 90, 180, 270, etc.
    var ang:Float = angle * Float(M_PI)
    var c:Float = cos(ang)
    var s:Float = sin(ang)
    return (c, s)
}
//------------------------------------------------------------------------------
func rotate(ang_degrees:Float, r:V3f) -> M4f
{
    // angle in degrees.....
    var a:Float = RadiansOverPi(ang_degrees)
    var c:Float = 0.0
    var s:Float = 0.0
    
    (c, s) = sinCosPI(a)
    
    var k:Float = 1.0 - c
    
    var u:V3f = r.Normalized()
    var v:V3f = s * u
    var w:V3f = k * u
    
    var P:V4f = zeroVector4
    var Q:V4f = zeroVector4
    var R:V4f = zeroVector4
    var S:V4f = zeroVector4
    
    P.x = w.x * u.x + c
    P.y = w.x * u.y + v.z
    P.z = w.x * u.z - v.y
    
    Q.x = w.x * u.y - v.z
    Q.y = w.y * u.y + c
    Q.z = w.y * u.z + v.x
    
    R.x = w.x * u.z + v.y
    R.y = w.y * u.z - v.x
    R.z = w.z * u.z + c
    
    S.w = 1.0
    
    return M4f(P, Q, R, S)
}
//------------------------------------------------------------------------------
func rotate(angle:Float, x:Float, y:Float, z:Float) -> M4f
{
    let r = V3f(x, y, z)
    return rotate(angle, r)
}
//------------------------------------------------------------------------------
// mark Public - Transformations - Perspective
//------------------------------------------------------------------------------
func perspective(width:Float, height:Float, near:Float, far:Float) -> M4f
{
    var zNear:Float = 2.0 * near
    var zFar:Float = far / (far - near)

    var P:V4f = zeroVector4
    var Q:V4f = zeroVector4
    var R:V4f = zeroVector4
    var S:V4f = zeroVector4

    P.x = zNear / width
    Q.y = zNear / height
    R.z = zFar
    R.w = 1.0
    S.z = -near * zFar
    return M4f(P, Q, R, S)
}
//------------------------------------------------------------------------------
// perspective
//------------------------------------------------------------------------------
func perspective_fov(fovy:Float, aspect:Float, near:Float, far:Float) -> M4f
{
    // fovy is in degrees..
    let angle:Float = radians(0.5 * fovy)
    let yScale:Float = 1.0 / tan(angle)
    let xScale:Float = yScale / aspect
    let zScale:Float = far / (far - near)
    
    var P:V4f = zeroVector4
    var Q:V4f = zeroVector4
    var R:V4f = zeroVector4
    var S:V4f = zeroVector4
    
    P.x = xScale
    Q.y = yScale
    R.z = zScale
    R.w = 1.0
    S.z = -near * zScale
    
    return M4f(P, Q, R, S)
}
//------------------------------------------------------------------------------
func perspective_fov(fovy:Float, width:Float, height:Float, near:Float, far:Float) -> M4f
{
    var aspect = width / height
   return perspective_fov(fovy, aspect, near, far)
}
//------------------------------------------------------------------------------
// mark Public - Transformations - LookAt
//------------------------------------------------------------------------------
func lookAt(eye:V3f, center:V3f, up:V3f) -> M4f
{
    var E:V3f = -eye
    var Na:V3f = center + E
    var N:V3f = Na.Normalized()
    var Ua = Cross(up, N)

    var U:V3f = Ua.Normalized()
    var Va = Cross(N, U)
    var V:V3f = Va.Normalized()

    var P:V4f = zeroVector4
    var Q:V4f = zeroVector4
    var R:V4f = zeroVector4
    var S:V4f = zeroVector4
    
        P.x = U.x; Q.x = U.y; R.x = U.z
        P.y = V.x; Q.y = V.y; R.y = V.z
        P.z = N.x; Q.z = N.y; R.z = N.z
    
        S.x = Dot(U, E)
        S.y = Dot(V, E)
        S.z = Dot(N, E)
        S.w = 1.0
    
        return M4f(P, Q, R, S)
}
//------------------------------------------------------------------------------
// mark Public - Transformations - Orthographic
//------------------------------------------------------------------------------
func ortho2d(left:Float, right:Float, bottom:Float, top:Float, near:Float, far:Float) -> M4f
{
    var sLength:Float = 1.0 / (right - left)
    var sHeight:Float = 1.0 / (top - bottom)
    var sDepth:Float = 1.0 / (far - near)
    
    var P:V4f = zeroVector4
    var Q:V4f = zeroVector4
    var R:V4f = zeroVector4
    var S:V4f = zeroVector4
    
    P.x = 2.0 * sLength
    Q.y = 2.0 * sHeight
    R.z = sDepth
    S.z = -near * sDepth
    S.w = 1.0
    
    return M4f(P, Q, R, S)
}
//------------------------------------------------------------------------------
func ortho2d(origin:V3f, size:V3f) -> M4f
{
    return ortho2d(origin.x, origin.y, origin.z, size.x, size.y, size.z)
}
//------------------------------------------------------------------------------
// mark Public - Transformations - Off-Center Orthographic
//------------------------------------------------------------------------------
func ortho2d_oc(left:Float, right:Float, bottom:Float, top:Float, near:Float, far:Float) -> M4f
{
    var sLength:Float = 1.0 / (right - left)
    var sHeight:Float = 1.0 / (top - bottom)
    var sDepth:Float = 1.0 / (far - near)
    var P:V4f = zeroVector4
    var Q:V4f = zeroVector4
    var R:V4f = zeroVector4
    var S:V4f = zeroVector4
    P.x = 2.0 * sLength
    Q.y = 2.0 * sHeight
    R.z = sDepth
    S.x = -sLength * (left + right)
    S.y = -sHeight * (top + bottom)
    S.z = -sDepth * near
    S.w = 1.0
    return M4f(P, Q, R, S)
}
//------------------------------------------------------------------------------
func ortho2d_oc(origin:V3f, size:V3f) -> M4f
{
    return ortho2d_oc(origin.x, origin.y, origin.z, size.x, size.y, size.z)
}
//------------------------------------------------------------------------------
// mark Public - Transformations - frustum
//------------------------------------------------------------------------------
func frustum(fovH:Float, fovV:Float, near:Float, far:Float) -> M4f
{
    var width:Float = 1.0 / tan(radians(0.5 * fovH))
    var height:Float = 1.0 / tan(radians(0.5 * fovV))
    var sDepth:Float = far / ( far - near )
    
    var P:V4f = zeroVector4
    var Q:V4f = zeroVector4
    var R:V4f = zeroVector4
    var S:V4f = zeroVector4
    
    P.x = width
    Q.y = height
    R.z = sDepth
    R.w = 1.0
    S.z = -sDepth * near
    
    return M4f(P, Q, R, S)
}
//------------------------------------------------------------------------------
func frustum(left:Float, right:Float, bottom:Float, top:Float, near:Float, far:Float) -> M4f
{
    var width:Float = right - left
    var height:Float = top - bottom
    var depth:Float = far - near
    var sDepth:Float = far / depth
    
    var P:V4f = zeroVector4
    var Q:V4f = zeroVector4
    var R:V4f = zeroVector4
    var S:V4f = zeroVector4
    
    P.x = width
    Q.y = height
    R.z = sDepth
    R.w = 1.0
    S.z = -sDepth * near
    
    return M4f(P, Q, R, S)
}
//------------------------------------------------------------------------------
func frustum_oc(left:Float, right:Float, bottom:Float, top:Float, near:Float, far:Float) -> M4f
{
    var sWidth:Float = 1.0 / (right - left)
    var sHeight:Float = 1.0 / (top - bottom)
    var sDepth:Float = far / (far - near)
    var dNear:Float = 2.0 * near
    
    var P:V4f = zeroVector4
    var Q:V4f = zeroVector4
    var R:V4f = zeroVector4
    var S:V4f = zeroVector4
    
    P.x = dNear * sWidth
    Q.y = dNear * sHeight
    R.x = -sWidth * (right + left)
    R.y = -sHeight * (top + bottom)
    R.z = sDepth
    R.w = 1.0
    S.z = -sDepth * near
    
    return M4f(P, Q, R, S)
}
//------------------------------------------------------------------------------
