//------------------------------------------------------------------------------
// Copyright (c) 2015 Jim Wrenholt. All rights reserved.
//------------------------------------------------------------------------------
import Foundation

//------------------------------------------------------------------------------
struct V3f : CustomStringConvertible, CustomDebugStringConvertible
{
    var x:Float = 0.0
    var y:Float = 0.0
    var z:Float = 0.0

    //-------------------------------------------------------------------------
    init()
    {
        self.x = 0.0
        self.y = 0.0
        self.z = 0.0
    }
    //-------------------------------------------------------------------------
    init( _ x:Float, _ y:Float, _ z:Float)
    {
        self.x = x
        self.y = y
        self.z = z
    }
    //-------------------------------------------------------------------------
    subscript(index:Int) -> Float
        {
        get
        {
            assert((index >= 0) && (index < 3))
            switch (index)
            {
            case 0: return x
            case 1: return y
            case 2: return z
            default: return 0
            }
        }
        set
        {
            assert((index >= 0) && (index < 3))
            switch (index)
            {
            case 0: x = newValue
            case 1: y = newValue
            case 2: z = newValue
            default: z = newValue
            }
        }
    }
    //-------------------------------------------------------------------------
    var description: String
        {
        get
        {
            let pt_f = ".2"
            return "(\(x.format(pt_f)),\(y.format(pt_f)),\(z.format(pt_f)))"
        }
    }
    //-------------------------------------------------------------------------
    var debugDescription: String
        {
        get
        {
            let pt_f = ".3"
            return "V2f(x: \(x.format(pt_f)), y: \(y.format(pt_f)), \(z.format(pt_f)))"
        }
    }
    //-------------------------------------------------------------------------
    var Length : Float
    {
        return (sqrt(x*x + y*y + z*z))
    }
    //-------------------------------------------------------------------------
    func Normalized() -> V3f  // const
    {
        // return a normalized copy
        let len:Float = Length

        var xx = self.x
        var yy = self.y
        var zz = self.z

        if (IsNotZero(len))
        {
            xx = xx / len
            yy = yy / len
            zz = zz / len
        }

        let ret = V3f(xx, yy, zz)
        return ret
    }
    //-------------------------------------------------------------------------
}
//------------------------------------------------------------------------------
prefix func - (vector: V3f) -> V3f
{
    // negation.
    return V3f(-vector.x, -vector.y, -vector.z)
}
//------------------------------------------------------------------------------
func + (left: V3f, right: V3f) -> V3f
{
    return V3f(left.x + right.x, left.y + right.y, left.z + right.z)
}
//------------------------------------------------------------------------------
func * (scalar: Float, right: V3f) -> V3f
{
    return V3f(scalar * right.x, scalar * right.y, scalar * right.z)
}
//------------------------------------------------------------------------------
func Dot(a: V3f, b: V3f) -> Float
{
    return (a.x * b.x + a.y * b.y + a.z * b.z)
}
//------------------------------------------------------------------------------
func Cross(a: V3f, b: V3f) -> V3f
{
    // cross product (also, known as vector product).
    return V3f((a.y*b.z - a.z*b.y),
        (a.z*b.x - a.x*b.z),
        (a.x*b.y - a.y*b.x))
}
//------------------------------------------------------------------------------

