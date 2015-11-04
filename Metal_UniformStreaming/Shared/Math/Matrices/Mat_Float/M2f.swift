//------------------------------------------------------------------------------
// Copyright (c) 2015 Jim Wrenholt. All rights reserved.
//------------------------------------------------------------------------------
import Foundation

let a_11:Int = 0;  let a_12:Int = 2
let a_21:Int = 1;  let a_22:Int = 3

//------------------------------------------------------------------------------
struct M2f : CustomStringConvertible, CustomDebugStringConvertible
{
    var col0 = V2f(1.0, 0.0)
    var col1 = V2f(0.0, 1.0)

    //-------------------------------------------------------------------------
    init()
    {
        col0[0] = 1.0    // identity
        col0[1] = 0
        col1[0] = 0
        col1[1] = 1.0
    }
    //-------------------------------------------------------------------------
    init(data:[Float])
    {
        assert(data.count == 4)
        col0[0] = data[a_11]
        col0[1] = data[a_21]
        col1[0] = data[a_12]
        col1[1] = data[a_22]
    }
    //-------------------------------------------------------------------------
    subscript(index:Int) -> Float
    {
        get
        {
            assert((index >= 0) && (index < 4))
            if (index < 2)
            {
                return col0[index]
            }
            else
            {
                return col1[index - 2]
            }
        }
        set
        {
            assert((index >= 0) && (index < 4))
            if (index < 2)
            {
                col0[index] = newValue
            }
            else
            {
                col1[index - 2] = newValue
            }
        }
    }
    //-------------------------------------------------------------------------
    subscript(row:Int, col:Int) -> Float
    {
        get
        {
            let index:Int = (row * 2) + col
            assert((index >= 0) && (index < 4))
            return self[index]
        }
        set
        {
            let index:Int = (row * 2) + col
            assert((index >= 0) && (index < 4))
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
            for (var c:Int = 0; c < 2; ++c)
            {
                desc += "   "
                for (var r:Int = 0; r < 2; ++r)
                {
                    let elem = "\(self[r, c].format(pt_f))"
                    desc += elem
                    if (r != 1)
                    {
                        desc += ", "
                    }
                }
                if (c == 1)
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
            for (var r:Int = 0; r < 2; ++r)
            {
                desc += "   "
                for (var c:Int = 0; c < 2; ++c)
                {
                    let elem = "\(self[r, c].format(pt_f))"
                    desc += elem
                    if (c != 1)
                    {
                        desc += ", "
                    }
                }
                if (r == 1)
                {
                    desc += " ]"
                }
                desc += "\n"
            }
            return desc
        }
    }
    //-------------------------------------------------------------------------
    func Determinant() -> Float
    {
       let det:Float = col0[0] * col1[1]  - col0[1] * col1[0]
       return det
    }
    //-------------------------------------------------------------------------
}
//------------------------------------------------------------------------------
func * (left: M2f, v: V2f) -> V2f
{
    var r_vec = V2f()
    r_vec[0] = left[a_11] * v[0] + left[a_12]  * v[1]
    r_vec[1] = left[a_21] * v[0] + left[a_22] * v[1]
    return r_vec
}
//------------------------------------------------------------------------------
func * (left: M2f, right: M2f) -> M2f
{
    // multiply left * right
    var ret = M2f()
    ret[0] = left[a_11] * right[0] + left[a_12] * right[1]
    ret[2] = left[a_11] * right[2] + left[a_12] * right[3]
    ret[1] = left[a_21] * right[0] + left[a_22] * right[1]
    ret[3] = left[a_21] * right[2] + left[a_22] * right[3]
    return ret
}
//------------------------------------------------------------------------------

