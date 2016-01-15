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

import de.polygonal.ds.error.Assert.assert;

/**
	Various utility functions for working with arrays
**/
class ArrayUtil
{
	/**
		Allocates an array with a length of `x`.
		<assert>`x` < 0</assert>
	**/
	public static function alloc<T>(x:Int):Array<T>
	{
		assert(x >= 0);
		
		var a:Array<T>;
		#if (flash || js)
		a = untyped __new__(Array, x);
		#elseif cpp
		a = new Array<T>();
		a[x - 1] = cast null;
		#else
		a = new Array<T>();
		for (i in 0...x) a[i] = cast null;
		#end
		return a;
	}
	
	/**
		Shrinks the array `a` to the size `x` and returns the modified array.
	**/
	inline public static function shrink<T>(a:Array<T>, x:Int):Array<T>
	{
		#if (flash || js)
		if (a.length > x)
			untyped a.length = x;
		return a;
		#elseif cpp
			#if no_inline
			var t = new Array<T>();
			for (i in 0...x) t[i] = a[i];
			return t;
			#else
			untyped a.length = x;
			return a;
			#end
		#else
		var t = new Array<T>();
		for (i in 0...x) t[i] = a[i];
		return t;
		#end
	}
	
	/**
		Copies elements in the range [`min`, `max`] from `source` to `destination`.
		<assert>`source` is null</assert>
		<assert>`destination` is null</assert>
		<assert>`min`/`max` out of range</assert>
	**/
	public static function copy<T>(source:Array<T>, destination:Array<T>, min = 0, max = -1):Array<T>
	{
		if (max == -1) max = source.length;
		
		assert(source != null);
		assert(destination != null);
		assert(min >= 0);
		assert(max <= source.length);
		assert(min < max);
		
		var j = 0;
		for (i in min...max) destination[j++] = source[i];
		return destination;
	}
	
	/**
		Sets up to `k` elements in `destination` to the instance `x`.
		@param k the number of elements to put into `destination`.
		If omitted `k` is set to `destination`::length;
	**/
	public static function fill<T>(destination:Array<T>, x:T, k = -1)
	{
		if (k == -1) k = destination.length;
		for (i in 0...k) destination[i] = x;
	}
	
	/**
		Sets up to `k` elements in `destination` to the object of type `cl`.
		@param k the number of elements to put into `destination`.
		If omitted `k` is set to `destination`::length;
	**/
	public static function assign<T>(destination:Array<T>, cl:Class<T>, args:Array<Dynamic> = null, k = -1)
	{
		if (k == -1) k = destination.length;
		if (args == null) args = [];
		for (i in 0...k) destination[i] = Type.createInstance(cl, args);
	}
	
	/**
		Copies `n` elements inside `a` from the location pointed by the index `source` to the location pointed by the index `destination`.
		
		Copying takes place as if an intermediate buffer is used, allowing the destination and source to overlap.
		
		See <a href="ttp://www.cplusplus.com/reference/clibrary/cstring/memmove/" target="mBlank">ttp://www.cplusplus.com/reference/clibrary/cstring/memmove/</a>
		<assert>invalid `destination`, `source` or `n` value</assert>
	**/
	public static function memmove<T>(a:Array<T>, destination:Int, source:Int, n:Int)
	{
		assert(destination >= 0 && source >= 0 && n >= 0);
		assert(source < a.length);
		assert(destination + n <= a.length);
		assert(n <= a.length);
		
		if (source == destination)
			return;
		else
		if (source <= destination)
		{
			var i = source + n;
			var j = destination + n;
			for (k in 0...n)
			{
				i--;
				j--;
				a[j] = a[i];
			}
		}
		else
		{
			var i = source;
			var j = destination;
			for (k in 0...n)
			{
				a[j] = a[i];
				i++;
				j++;
			}
		}
	}
	
	/**
		Searches the sorted array `a` for the element `x` in the range (`min`, `max`] using the binary search algorithm.
		
		<warn>The insertion point is only valid for `min`=0 and `max`=a.length-1.</warn>
		<assert>`a`/`comparator` is null</assert>
		<assert>invalid `min`/`max` search boundaries</assert>
		@return the index of the element `x` or the bitwise complement (~) of the index where `x` would be inserted (guaranteed to be a negative number).
	**/
	public static function bsearchComparator<T>(a:Array<T>, x:T, min:Int, max:Int, comparator:T->T->Int):Int
	{
		assert(a != null);
		assert(comparator != null);
		assert(min >= 0 && min < a.length);
		assert(max < a.length);
		
		var l = min, m, h = max + 1;
		while (l < h)
		{
			m = l + ((h - l) >> 1);
			if (comparator(a[m], x) < 0)
				l = m + 1;
			else
				h = m;
		}
		
		if ((l <= max) && comparator(a[l], x) == 0)
			return l;
		else
			return ~l;
	}
	
	/**
		Searches the sorted array `a` for the element `x` in the range [`min`, `max`) using the binary search algorithm.
		
		<warn>The insertion point is only valid for `min`=0 and `max`=`a`::length-1.</warn>
		<assert>`a` is null</assert>
		<assert>invalid `min`/`max` search boundaries</assert>
		@return the index of the element `x` or the bitwise complement (~) of the index where `x` would be inserted (guaranteed to be a negative number).
	**/
	public static function bsearchInt(a:Array<Int>, x:Int, min:Int, max:Int):Int
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
	
	/**
		Searches the sorted array `a` for the element `x` in the range [`min`, `max`) using the binary search algorithm.
		
		<warn>The insertion point is only valid for `min`=0 and `max`=`a`::length-1.</warn>
		<assert>`a` is null</assert>
		<assert>invalid `min`/`max` search boundaries</assert>
		@return the index of the element `x` or the bitwise complement (~) of the index where `x` would be inserted (guaranteed to be a negative number).
	**/
	public static function bsearchFloat(a:Array<Float>, x:Float, min:Int, max:Int):Int
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
	
	/**
		Shuffles the elements of the array `a` by using the Fisher-Yates algorithm.
		<assert>insufficient random values</assert>
		@param rval a list of random double values in the range between [0,1) defining the new positions of the elements.
		If omitted, random values are generated on-the-fly by calling `Math::random()`.
	**/
	public static function shuffle<T>(a:Array<T>, rval:Array<Float> = null)
	{
		assert(a != null);
		
		var s = a.length;
		if (rval == null)
		{
			var m = Math;
			while (--s > 1)
			{
				var i = Std.int(m.random() * s);
				var t = a[s];
				a[s] = a[i];
				a[i] = t;
			}
		}
		else
		{
			assert(rval.length >= a.length, "insufficient random values");
			
			var j = 0;
			while (--s > 1)
			{
				var i = Std.int(rval[j++] * s);
				var t = a[s];
				a[s] = a[i];
				a[i] = t;
			}
		}
	}
	
	/**
		Sorts the elements of the array `a` by using the quick sort algorithm.
		<assert>`first` or `count` out of bound</assert>
		@param compare a comparison function.
		@param useInsertionSort if true, the array is sorted using the insertion sort algorithm. This is faster for nearly sorted lists.
		@param first sort start index. The default value is 0.
		@param count the number of elements to sort (range: [`first`, `first` + `count`]).
		If omitted, `count` is set to ``size()``.
	**/
	public static function sortRange(a:Array<Float>, compare:Float->Float->Int, useInsertionSort:Bool, first:Int, count:Int)
	{
		var k = a.length;
		if (k > 1)
		{
			assert(first >= 0 && first <= k - 1 && first + count <= k, "first out of bound");
			assert(count >= 0 && count <= k, "count out of bound");
			
			if (useInsertionSort)
				_insertionSort(a, first, count, compare);
			else
				_quickSort(a, first, count, compare);
		}
	}
	
	/**
		A quick counting permutation algorithm.
		
		See <a href="http://www.freewebs.com/permute/quickperm.html" target="mBlank">http://www.freewebs.com/permute/quickperm.html</a>
		@param n number of elements to permute.
	**/
	public static function quickPerm(n:Int):Array<Array<Int>>
	{
		var results = [];
		
		var a:Array<Int> = [];
		var p:Array<Int> = [];
		
		var i:Int, j:Int, tmp:Int;
		
		for (i in 0...n)
		{
			a[i] = i + 1;
			p[i] = 0;
		}
		
		results.push(a.copy());
		
		i = 1;
		while(i < n)
		{
			if (p[i] < i)
			{
				j = i % 2 * p[i];
				tmp = a[j];
				a[j] = a[i];
				a[i] = tmp;
				results.push(a.copy());
				p[i]++;
				i = 1;
			}
			else
			{
				p[i] = 0;
				i++;
			}
		}
		
		return results;
	}

	/**
		Compares `a` and `b` by comparing their elements using ==.
	**/
	public static function equals<T>(a:Array<T>, b:Array<T>):Bool
	{
		if (a.length != b.length) return false;
		for (i in 0...a.length)
			if (a[i] != b[i])
				return false;
		return true;
	}
	
	/**
		Splits the input array `a` storing `n` elements into smaller chunks, each containing k elements.
		<assert>`n` is not a multiple of `k`</assert>
	**/
	public static function split<T>(a:Array<T>, n:Int, k:Int):Array<Array<T>>
	{
		assert(n % k == 0, "n is not a multiple of k");
		
		var output = new Array<Array<T>>();
		var b:Array<T> = null;
		for (i in 0...n)
		{
			if (i % k == 0)
				output[Std.int(i / k)] = b = [];
			b.push(a[i]);
		}
		return output;
	}
	
	static function _insertionSort(a:Array<Float>, first:Int, k:Int, cmp:Float->Float->Int)
	{
		for (i in first + 1...first + k)
		{
			var x = a[i];
			var j = i;
			while (j > first)
			{
				var y = a[j - 1];
				if (cmp(y, x) > 0)
				{
					a[j] = y;
					j--;
				}
				else
					break;
			}
			
			a[j] = x;
		}
	}
	
	static function _quickSort(a:Array<Float>, first:Int, k:Int, cmp:Float->Float->Int)
	{
		var last = first + k - 1;
		var lo = first;
		var hi = last;
		if (k > 1)
		{
			var i0 = first;
			var i1 = i0 + (k >> 1);
			var i2 = i0 + k - 1;
			var t0 = a[i0];
			var t1 = a[i1];
			var t2 = a[i2];
			var mid:Int;
			var t = cmp(t0, t2);
			if (t < 0 && cmp(t0, t1) < 0)
				mid = cmp(t1, t2) < 0 ? i1 : i2;
			else
			{
				if (cmp(t1, t0) < 0 && cmp(t1, t2) < 0)
					mid = t < 0 ? i0 : i2;
				else
					mid = cmp(t2, t0) < 0 ? i1 : i0;
			}
			
			var pivot = a[mid];
			a[mid] = a[first];
			
			while (lo < hi)
			{
				while (cmp(pivot, a[hi]) < 0 && lo < hi) hi--;
				if (hi != lo)
				{
					a[lo] = a[hi];
					lo++;
				}
				while (cmp(pivot, a[lo]) > 0 && lo < hi) lo++;
				if (hi != lo)
				{
					a[hi] = a[lo];
					hi--;
				}
			}
			
			a[lo] = pivot;
			_quickSort(a, first, lo - first, cmp);
			_quickSort(a, lo + 1, last - lo, cmp);
		}
	}
}