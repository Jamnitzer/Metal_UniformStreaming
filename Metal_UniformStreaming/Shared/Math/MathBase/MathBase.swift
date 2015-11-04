//------------------------------------------------------------------------------
// Copyright (c) 2015 Jim Wrenholt. All rights reserved.
//------------------------------------------------------------------------------
import Foundation
import QuartzCore

//------------------------------------------------------------------------------
extension Int
{
    func format(f: String) -> String
    {
        return String(format: "%\(f)d", self)
    }
}
//------------------------------------------------------------------------------
extension UInt
{
    func format(f: String) -> String
    {
        return String(format: "%\(f)u", self)
    }
}
//------------------------------------------------------------------------------
extension Float
{
    func format(f: String) -> String
    {
        if (self < 0.0)
        {
            return String(format: "%\(f)f", self)
        }
        else
        {
            return String(format: " %\(f)f", self)
        }
    }
}
//------------------------------------------------------------------------------
extension Double
{
    func format(f: String) -> String
    {
        if (self < 0.0)
        {
            return String(format: "%\(f)f", self)
        }
        else
        {
            return String(format: " %\(f)f", self)
        }
    }
}
//------------------------------------------------------------------------------
func IsZero(v:Float, epsilon:Float) -> Bool
{
    if (abs(v) < epsilon)
    {
        return true
    }
    return false
}
//------------------------------------------------------------------------------
func IsZero(v:Float) -> Bool
{
    return IsZero(v, epsilon: FLT_EPSILON)
}
//------------------------------------------------------------------------------
func IsNotZero(v:Float) -> Bool
{
    return !IsZero(v, epsilon: FLT_EPSILON)
}
//------------------------------------------------------------------------------
func IsNotZero(v:Float, epsilon:Float) -> Bool
{
    return !IsZero(v, epsilon: epsilon)
}
//------------------------------------------------------------------------------
func IsEqual(a:Float, b:Float) -> Bool
{
    return IsZero(a - b, epsilon: FLT_EPSILON)
}
//------------------------------------------------------------------------------
func IsEqual(a:Float, b:Float, epsilon:Float) -> Bool
{
    return IsZero(a - b, epsilon: epsilon)
}
//------------------------------------------------------------------------------
func IsNotEqual(a:Float, b:Float) -> Bool
{
    return !IsZero(a - b, epsilon: FLT_EPSILON)
}
//------------------------------------------------------------------------------
func IsNotEqual(a:Float, b:Float, epsilon:Float) -> Bool
{
    return !IsZero(a - b, epsilon: epsilon)
}
//------------------------------------------------------------------------------
