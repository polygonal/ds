/*
Copyright (c) 2008-2014 Michael Baczynski, http://www.polygonal.de

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
package de.polygonal.ds;

import de.polygonal.core.util.Assert.assert;

class VectorUtil
{
	/**
		Wrapper for haxe.ds.Vector::blit().
	**/
	public static #if (cs || java || neko || cpp) inline #end function blit<T>(src:Vector<T>, srcPos:Int, dest:Vector<T>, destPos:Int, len:Int):Void
	{
		#if flash
		for (i in 0...len)
			dest[destPos + i] = src[srcPos + i];
		#else
		haxe.ds.Vector.blit(src, srcPos, dest, destPos, len);
		#end
	}
	
	/**
		Creates a Vector object with `length` capacity.
	**/
	inline public static function alloc<T>(length:Int):Vector<T>
	{
		#if flash
		return new Vector<T>(length, true);
		#else
		return new Vector<T>(length);
		#end
	}
	
	/**
		Sets up to `k` elements in `dst` to the instance `x`.
		@param k the number of elements to put into `dst`.
		If omitted `k` is set to `dst`::length;
	**/
	public static function fill<T>(dst:Vector<T>, x:T, k = -1)
	{
		if (k == -1) k = dst.length;
		for (i in 0...k) dst[i] = x;
	}
	
	
	public static function bsearchFloat(a:Vector<Float>, x:Float, min:Int, max:Int):Int
	{
		assert(a != null);
		assert(min >= 0 && min < a.length);
		assert(max < a.length);
		
		var l = min, m, h = max + 1;
		while (l < h)
		{
			m = l + ((h - l) >> 1);
			if (a[m] < x)
				l = m + 1;
			else
				h = m;
		}
		
		if ((l <= max) && (a[l] == x))
			return l;
		else
			return ~l;
	}
}