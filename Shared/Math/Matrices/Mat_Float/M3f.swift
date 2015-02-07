//------------------------------------------------------------------------------
// Copyright (c) 2015 Jim Wrenholt. All rights reserved.
//------------------------------------------------------------------------------
import Foundation

let _b11:Int = 0;   let _b12:Int = 3;   let _b13:Int = 6
let _b21:Int = 1;   let _b22:Int = 4;   let _b23:Int = 7
let _b31:Int = 2;   let _b32:Int = 5;   let _b33:Int = 8

//------------------------------------------------------------------------------
struct M3f : Printable, DebugPrintable
{
    var col0 = V3f(1.0, 0.0, 0.0)
    var col1 = V3f(0.0, 1.0, 0.0)
    var col2 = V3f(0.0, 0.0, 1.0)
    //-------------------------------------------------------------------------
    init()
    {
        col0 = V3f(1.0, 0.0, 0.0)
        col1 = V3f(0.0, 1.0, 0.0)
        col2 = V3f(0.0, 0.0, 1.0)
    }
    //-------------------------------------------------------------------------
    init(data:[Float])
    {
        assert(data.count == 9)
        col0 = V3f(data[0], data[1], data[2])
        col1 = V3f(data[3], data[4], data[5])
        col2 = V3f(data[6], data[7], data[8])
    }
    //-------------------------------------------------------------------------
    subscript(index:Int) -> Float
    {
        get
        {
            assert((index >= 0) && (index < 9))
            if (index < 3)
            {
                return col0[index]
            }
            else if (index < 6)
            {
                return col1[index - 3]
            }
            else
            {
                return col2[index - 6]
            }
        }
        set
        {
            assert((index >= 0) && (index < 9))
            if (index < 3)
            {
                col0[index] = newValue
            }
            else if (index < 6)
            {
                col1[index - 3] = newValue
            }
            else
            {
                col2[index - 6] = newValue
            }
        }
    }
    //-------------------------------------------------------------------------
    subscript(row:Int, col:Int) -> Float
        {
        get
        {
            let index:Int = (row * 3) + col
            assert((index >= 0) && (index < 9))
            return self[index]
        }
        set
        {
            let index:Int = (row * 3) + col
            assert((index >= 0) && (index < 9))
            self[index] = newValue
        }
    }
    //-------------------------------------------------------------------------
    var description: String
        {
        get
        {
            var desc:String = "[\n"
            let pt_f = ".3"
            for (var c:Int = 0; c < 3; ++c)
            {
                desc += "   "
                for (var r:Int = 0; r < 3; ++r)
                {
                    let elem = "\(self[r, c].format(pt_f))"
                    desc += elem
                    if (r != 2)
                    {
                        desc += ", "
                    }
                }
                if (c == 2)
                {
                    desc += " ]"
                }
                desc += "\n"
            }
            return desc
        }
    }
    //-------------------------------------------------------------------------
    var debugDescription: String
        {
        get
        {
            var desc:String = "[\n"
            let pt_f = ".3"
            for (var r:Int = 0; r < 3; ++r)
            {
                desc += "   "
                for (var c:Int = 0; c < 3; ++c)
                {
                    let elem = "\(self[r, c].format(pt_f))"
                    desc += elem
                    if (c != 2)
                    {
                        desc += ", "
                    }
                }
                if (r == 2)
                {
                    desc += " ]"
                }
                desc += "\n"
            }
            return desc
        }
    }
    //-------------------------------------------------------------------------
    // matrix operations
    //-------------------------------------------------------------------------
    func Determinant() -> Float
    {
        // quicker to unwrap it here.
        let f0:Float = self[_b11]*self[_b22]*self[_b33] + self[_b12]*self[_b23]*self[_b31]
        let f1:Float = self[_b13]*self[_b21]*self[_b32] - self[_b11]*self[_b23]*self[_b32]
        let f2:Float = self[_b12]*self[_b21]*self[_b33] - self[_b13]*self[_b22]*self[_b31]

        let det:Float = f0 + f1 - f2

        return det;
    }
    //-------------------------------------------------------------------------
}
//------------------------------------------------------------------------------
func * (left: M3f, right: V3f) -> V3f
{
    // multiply left * right
    var ret = V3f()
    ret[0] = left[_b11] * right[0] + left[_b12] * right[1] + left[_b13] * right[2];
    ret[1] = left[_b21] * right[0] + left[_b22] * right[1] + left[_b23] * right[2];
    ret[2] = left[_b31] * right[0] + left[_b32] * right[1] + left[_b33] * right[2];
    return ret;
}
//------------------------------------------------------------------------------

