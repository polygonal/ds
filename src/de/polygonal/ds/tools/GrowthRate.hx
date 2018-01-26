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

import de.polygonal.ds.tools.Assert.assert;

class GrowthRate
{
	/**
		Fixed size; throws an error if additional space is requested.
	**/
	inline public static var FIXED = 0;
	
	/**
		Grows at a rate of 1.125x plus a constant.
	**/
	inline public static var MILD = -1;
	
	/**
		Grows at a rate of 1.5x (default value).
	**/
	inline public static var NORMAL = -2;
	
	/**
		Grows at a rate of 2.0x.
	**/
	inline public static var DOUBLE = -3;
	
	/**
		Computes a new capacity from the given growth `rate` constant and the current `capacity`.
		
		If `rate` > 0, `capacity` grows at a constant rate: `newCapacity = capacity + rate`
	**/
	public static function compute(rate:Int, capacity:Int):Int
	{
		assert(rate >= -3, "invalid growth rate");
		
		if (rate > 0)
			capacity += rate;
		else
		{
			switch (rate)
			{
				case FIXED: throw "out of space";
				
				case MILD:
					var newSize = capacity + 1;
					capacity = (newSize >> 3) + (newSize < 9 ? 3 : 6);
					capacity += newSize;
				
				case NORMAL: capacity = ((capacity * 3) >> 1) + 1;
				
				case DOUBLE: capacity <<= 1;
			}
		}
		return capacity;
	}
}