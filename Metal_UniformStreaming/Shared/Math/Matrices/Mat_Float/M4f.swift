//------------------------------------------------------------------------------
// Copyright (c) 2015 Jim Wrenholt. All rights reserved.
//------------------------------------------------------------------------------
import Foundation

let _a11:Int = 0; let _a12:Int = 4; let _a13:Int = 8; let _a14:Int = 12
let _a21:Int = 1; let _a22:Int = 5; let _a23:Int = 9; let _a24:Int = 13
let _a31:Int = 2; let _a32:Int = 6; let _a33:Int = 10; let _a34:Int = 14
let _a41:Int = 3; let _a42:Int = 7; let _a43:Int = 11; let _a44:Int = 15

//------------------------------------------------------------------------------
struct M4f : CustomStringConvertible, CustomDebugStringConvertible
{
    var col0 = V4f(1.0, 0.0, 0.0, 0.0)
    var col1 = V4f(0.0, 1.0, 0.0, 0.0)
    var col2 = V4f(0.0, 0.0, 1.0, 0.0)
    var col3 = V4f(0.0, 0.0, 0.0, 1.0)
    //--------------------------------------------------------------------------
    init()
    {
        col0 = V4f(1.0, 0.0, 0.0, 0.0)
        col1 = V4f(0.0, 1.0, 0.0, 0.0)
        col2 = V4f(0.0, 0.0, 1.0, 0.0)
        col3 = V4f(0.0, 0.0, 0.0, 1.0)
    }
    //--------------------------------------------------------------------------
    init(_ P:V4f, _ Q:V4f, _ R:V4f, _ S:V4f)
    {
        col0 = P
        col1 = Q
        col2 = R
        col3 = S
    }
    //--------------------------------------------------------------------------
    init(data:[Float])
    {
        assert(data.count == 16)
        col0 = V4f(data[0], data[1], data[2], data[3])
        col1 = V4f(data[4], data[5], data[6], data[7])
        col2 = V4f(data[8], data[9], data[10], data[11])
        col3 = V4f(data[12], data[13], data[14], data[15])
    }
    //--------------------------------------------------------------------------
    func GetArray() -> [Float]
    {
        let mat:[Float] = [
            col0[0], col0[1], col0[2], col0[3],
            col1[0], col1[1], col1[2], col1[3],
            col2[0], col2[1], col2[2], col2[3],
            col3[0], col3[1], col3[2], col3[3] ]
        return mat
    }
    //--------------------------------------------------------------------------
    subscript(index:Int) -> Float
    {
        get
        {
            assert((index >= 0) && (index < 16))
            if (index < 4)
            {
                return col0[index]
            }
            else if (index < 8)
            {
                return col1[index - 4]
            }
            else if (index < 12)
            {
                return col2[index - 8]
            }
            else
            {
                return col3[index - 12]
            }
        }
        set
        {
            assert((index >= 0) && (index < 16))
            if (index < 4)
            {
                 col0[index] = newValue
            }
            else if (index < 8)
            {
                 col1[index - 4] = newValue
            }
            else if (index < 12)
            {
                 col2[index - 8] = newValue
            }
            else
            {
                 col3[index - 12] = newValue
            }
        }
    }
    //--------------------------------------------------------------------------
    subscript(row:Int, col:Int) -> Float
    {
        get
        {
            let index:Int = (row * 4) + col
            assert((index >= 0) && (index < 16))
            return self[index]
        }
        set
        {
            let index:Int = (row * 4) + col
            assert((index >= 0) && (index < 16))
            self[index] = newValue
        }
    }
    //--------------------------------------------------------------------------
    var description: String
        {
        get
        {
            var desc:String = "[\n"
            let pt_f = ".3"
            for (var c:Int = 0; c < 4; ++c)
            {
                desc += "   "
                for (var r:Int = 0; r < 4; ++r)
                {
                    let elem = "\(self[r, c].format(pt_f))"
                    desc += elem
                    if (r != 3)
                    {
                        desc += ", "
                    }
                }
                if (c == 3)
                {
                    desc += " ]"
                }
                desc += "\n"
            }
            return desc
        }
    }
    //--------------------------------------------------------------------------
    var debugDescription: String
        {
        get
        {
            var desc:String = "[\n"
            let pt_f = ".3"
            for (var r:Int = 0; r < 4; ++r)
            {
                desc += "   "
                for (var c:Int = 0; c < 4; ++c)
                {
                    let elem = "\(self[r, c].format(pt_f))"
                    desc += elem
                    if (c != 3)
                    {
                        desc += ", "
                    }
                }
                if (r == 3)
                {
                    desc += " ]"
                }
                desc += "\n"
            }
            return desc
        }
    }
    //--------------------------------------------------------------------------
    // static creation
    //--------------------------------------------------------------------------
    static func TranslationMatrix(v:V3f) -> M4f
    {
        // create the translation matrix
        return M4f(data:[1.0, 0.0, 0.0, 0.0,        // column major
                        0.0, 1.0, 0.0, 0.0,
                        0.0, 0.0, 1.0, 0.0,
                        v[0], v[1], v[2], 1.0])
    }
}
//------------------------------------------------------------------------------
// operator overloading.
//------------------------------------------------------------------------------
func * (left: M4f, right: M4f) -> M4f
{
    // multiply left * right
    var data = [Float](count:16, repeatedValue:0.0)
    for (var i:Int = 0; i < 16; ++i)
    {
        let r_idx:Int = (i / 4) * 4
        let r_rem:Int = i - r_idx
        var sub_tot:Float = 0.0
        for (var j:Int = 0; j < 4; ++j)
        {
            let j_idx:Int = j + r_idx
            let k_idx:Int = 4 * j + r_rem
            sub_tot += left[k_idx] * right[j_idx]
        }
        data[i] = sub_tot
    }
    return M4f(data:data)
}
//------------------------------------------------------------------------------
