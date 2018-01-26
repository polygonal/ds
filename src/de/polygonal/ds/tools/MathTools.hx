/*
Copyright (c) 2008-2018 Michael Baczynski, http://www.polygonal.de

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
package de.polygonal.ds.tools;

@:dox(hide)
extern class MathTools
{
	/**
		Min value, signed integer.
	**/
	public static inline var INT32_MIN =
	#if cpp
	//warning: this decimal constant is unsigned only in ISO C90
	-MathTools.INT32_MAX;
	#else
	0x80000000;
	#end
	
	/**
		Max value, signed integer.
	**/
	public static inline var INT32_MAX = 0x7FFFFFFF;
	
	/**
		Min value, signed short.
	**/
	public static inline var INT16_MIN =-0x8000;
	
	/**
		Max value, signed short.
	**/
	public static inline var INT16_MAX = 0x7FFF;
	
	/**
		Max value, unsigned short.
	**/
	public static inline var UINT16_MAX = 0xFFFF;
	
	/**
		Returns true if `x` is a power of two.
	**/
	public static inline function isPow2(x:Int):Bool return x > 0 && (x & (x - 1)) == 0;
	
	/**
		Returns min(`x`, `y`).
	**/
	public static inline function min(x:Int, y:Int):Int return x < y ? x : y;
	
	/**
		Returns max(`x`, `y`).
	**/
	public static inline function max(x:Int, y:Int):Int return x > y ? x : y;
	
	/**
		Returns the absolute value of `x`.
	**/
	public static inline function abs(x:Int):Int return x < 0 ? -x : x;
	
	/**
		Calculates the next highest power of 2 of `x`.
		
		`x` must be in the range 0...(2^30)
		
		Returns `x` if already a power of 2.
	**/
	public static inline function nextPow2(x:Int):Int
	{
		var t = x - 1;
		t |= (t >> 1);
		t |= (t >> 2);
		t |= (t >> 4);
		t |= (t >> 8);
		t |= (t >> 16);
		return t + 1;
	}
	
	/**
		Counts the number of digits in `x`, e.g. 1237.34 has 4 digits.
	**/
	public static inline function numDigits(x:Float):Int
	{
		return Std.int((x == 0) ? 1 : (Math.log(x) / Math.log(10)) + 1);
	}
}