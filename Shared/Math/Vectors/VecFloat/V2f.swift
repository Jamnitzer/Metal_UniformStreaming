//------------------------------------------------------------------------------
// Copyright (c) 2015 Jim Wrenholt. All rights reserved.
//------------------------------------------------------------------------------
import Foundation

//------------------------------------------------------------------------------
struct V2f :  Printable, DebugPrintable
{
    var x:Float = 0.0
    var y:Float = 0.0

    //-------------------------------------------------------------------------
    init()
    {
        self.x = 0.0
        self.y = 0.0
    }
    //-------------------------------------------------------------------------
    init(x:Float, y:Float)
    {
        self.x = x
        self.y = y
    }
    //-------------------------------------------------------------------------
    init(_ x:Float, _ y:Float)
    {
        self.x = x
        self.y = y
    }
    //-------------------------------------------------------------------------
    init(data:[Float])
    {
        assert(data.count == 2)
        self.x = data[0]
        self.y = data[1]
    }
    //-------------------------------------------------------------------------
    subscript(index:Int) -> Float
        {
        get
        {
            assert((index >= 0) && (index < 2))
            if (index == 0)
            {
                return x
            }
            else
            {
                return y
            }
        }
        set
        {
            assert((index >= 0) && (index < 2))
            if (index == 0)
            {
                x = newValue
            }
            else
            {
                y = newValue
            }
        }
    }
    //-------------------------------------------------------------------------
    var description: String
        {
        get
        {
            let pt_f = ".2"
            return "(\(x.format(pt_f)),\(y.format(pt_f)))"
        }
    }
    //-------------------------------------------------------------------------
    var debugDescription: String
        {
        get
        {
            return "(\(x), \(y))"
        }
    }
    //-------------------------------------------------------------------------
}
//------------------------------------------------------------------------------
