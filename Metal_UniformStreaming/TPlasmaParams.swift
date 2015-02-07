//------------------------------------------------------------------------------
//  derived from Apple's WWDC example "MetalUniformStreaming"
//  Created by Jim Wrenholt on 12/6/14.
//------------------------------------------------------------------------------
import Foundation

 //-----------------------------------------------------------------------------
class TPlasmaParams
{
    var m_Time:ParamBlock!
    var m_Scale:ParamBlock!
    
    //------------------------------------------------------
    init(rTime:ParamBlock, rScale:ParamBlock)
    {
        m_Time = rTime
        m_Scale = rScale
    }
    //------------------------------------------------------
    func update() -> V2f
    {
        var v = V2f()
            v.x = ParamBlockUpdate(&m_Time!)
            v.y = ParamBlockUpdate(&m_Scale!)
        return v
    }
    //------------------------------------------------------
}
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
class ParamBlock
{
    var mValue:Float = 0
    var mDelta:Float = 0
    var mMin:Float = 0
    var mMax:Float = 0
    var mSgn:Float = 0
    
    //------------------------------------------------------
    init(_ _Value:Float, _ _Delta:Float,
            _ _Min:Float, _ _Max:Float, _ _Sgn:Float)
    {
        mValue = _Value
        mDelta = _Delta
        mMin = _Min
        mMax = _Max
        mSgn = _Sgn
    }
    //------------------------------------------------------
    init(rParams:ParamBlock)
    {
        mValue = rParams.mValue
        mDelta = rParams.mDelta
        mMin = rParams.mMin
        mMax = rParams.mMax
        mSgn = rParams.mSgn
    }
    //------------------------------------------------------
}
 //-----------------------------------------------------------------------------
func ParamBlockUpdate(inout rParamBlock:ParamBlock) -> Float
{
    rParamBlock.mValue += (rParamBlock.mSgn * rParamBlock.mDelta);

    if ( rParamBlock.mValue >= rParamBlock.mMax )
    {
        rParamBlock.mSgn = -1.0;
    }
    else if ( rParamBlock.mValue <= rParamBlock.mMin )
    {
        rParamBlock.mSgn = 1.0;
    }
    return rParamBlock.mValue;
}
 //-----------------------------------------------------------------------------
var kTime = ParamBlock(0.0, 0.08, 0.0, 12.0 * Float(M_PI), 1.0)
var kScale = ParamBlock(1.0, 0.125, 1.0, 32.0, 1.0)
 //-----------------------------------------------------------------------------
 //-----------------------------------------------------------------------------

