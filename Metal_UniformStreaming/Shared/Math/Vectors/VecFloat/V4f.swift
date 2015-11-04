//------------------------------------------------------------------------------
// Copyright (c) 2015 Jim Wrenholt. All rights reserved.
//------------------------------------------------------------------------------
import Foundation

//------------------------------------------------------------------------------
struct V4f : CustomStringConvertible, CustomDebugStringConvertible
{
    var x:Float = 0.0
    var y:Float = 0.0
    var z:Float = 0.0
    var w:Float = 0.0

    //-------------------------------------------------------------------------
    init()
    {
        self.x = 0
        self.y = 0
        self.z = 0
        self.w = 0
    }
    //-------------------------------------------------------------------------
    init(_ x:Float, _ y:Float, _ z:Float, _ w:Float)
    {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }
    //-------------------------------------------------------------------------
    subscript(index:Int) -> Float
    {
        get
        {
            assert((index >= 0) && (index < 4))
            switch (index)
            {
            case 0: return x
            case 1: return y
            case 2: return z
            case 3: return w
            default: return 0
            }
        }
        set
        {
            assert((index >= 0) && (index < 4))
            switch (index)
            {
            case 0: x = newValue
            case 1: y = newValue
            case 2: z = newValue
            case 3: w = newValue
            default: w = newValue
            }
        }
    }
    //-------------------------------------------------------------------------
    var description: String
        {
        get
        {
            let pt_f = ".3"
            return "(\(x.format(pt_f)), \(y.format(pt_f)), \(z.format(pt_f)), \(w.format(pt_f)))"
        }
    }
    //-------------------------------------------------------------------------
    var debugDescription: String
        {
        get
        {
            let pt_f = ".3"
            return "V2f(x: \(x.format(pt_f)), y: \(y.format(pt_f)), \(z.format(pt_f)), \(w.format(pt_f)))"
        }
    }
    //-------------------------------------------------------------------------
}
//------------------------------------------------------------------------------
