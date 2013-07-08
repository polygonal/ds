/*
 *                            _/                                                    _/
 *       _/_/_/      _/_/    _/  _/    _/    _/_/_/    _/_/    _/_/_/      _/_/_/  _/
 *      _/    _/  _/    _/  _/  _/    _/  _/    _/  _/    _/  _/    _/  _/    _/  _/
 *     _/    _/  _/    _/  _/  _/    _/  _/    _/  _/    _/  _/    _/  _/    _/  _/
 *    _/_/_/      _/_/    _/    _/_/_/    _/_/_/    _/_/    _/    _/    _/_/_/  _/
 *   _/                            _/        _/
 *  _/                        _/_/      _/_/
 *
 * POLYGONAL - A HAXE LIBRARY FOR GAME DEVELOPERS
 * Copyright (c) 2009 Michael Baczynski, http://www.polygonal.de
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */
package de.polygonal.ds;

import de.polygonal.ds.error.Assert.assert;

/**
 * <p>Various utility functions for working with arrays.</p>
 */
class ArrayUtil 
{
	/**
	 * Allocates an array with a length of <code>x</code>.
	 * @throws de.polygonal.ds.error.AssertError <code>x</code> &lt; 0 (debug only).
	 */
	inline public static function alloc<T>(x:Int):Array<T>
	{
		#if debug
		assert(x >= 0, "x >= 0");
		#end
		
		var a:Array<T>;
		#if (flash || js)
		a = untyped __new__(Array, x);
		#elseif cpp
		a = new Array<T>();
		a[x - 1] = cast null;
		#else
		a = new Array<T>();
		for (i in 0...x) a[i] = null;
		#end
		return a;
	}
	
	/**
	 * Shrinks the array to the size <code>x</code> and returns the modified array.
	 */
	inline public static function shrink<T>(a:Array<T>, x:Int):Array<T>
	{
		#if (flash || js)
		if (a.length > x)
			untyped a.length = x;
		return a;
		#elseif cpp
		untyped a.length = x;
		return a;
		#else
		var b = new Array<T>();
		for (i in 0...x) b[i] = a[i];
		return b;
		#end
	}
	
	/**
	 * Copies elements in the range &#091;<code>min</code>, <code>max</code>&#093; from <code>src</code> to <code>dst</code>.
	 * @throws de.polygonal.ds.error.AssertError <code>src</code> is null (debug only).
	 * @throws de.polygonal.ds.error.AssertError <code>dst</code> is null (debug only).
	 * @throws de.polygonal.ds.error.AssertError index out of range (debug only).
	 */
	inline public static function copy<T>(src:Array<T>, dst:Array<T>, min = 0, max = -1):Array<T>
	{
		if (max == -1) max = src.length;
		
		#if debug
		assert(src != null, "src != null");
		assert(dst != null, "dst != null");
		assert(min >= 0, "min >= 0");
		assert(max <= src.length, "max <= src.length");
		assert(min < max, "min < max");
		#end
		
		var j = 0;
		for (i in min...max) dst[j++] = src[i];
		return dst;
	}
	
	/**
	 * Sets up to <code>k</code> elements in <code>dst</code> to the instance <code>x</code>.
	 * @param k the number of elements to put into <code>dst</code>.
	 * If omitted <code>k</code> is set to <code>dst</code>.length;
	 */
	inline public static function fill<T>(dst:Array<T>, x:T, k = -1)
	{
		if (k == -1) k = dst.length;
		for (i in 0...k) dst[i] = x;
	}
	
	/**
	 * Sets up to <code>k</code> elements in <code>dst</code> to the object of type <code>C</code>.<br/>
	 * @param k the number of elements to put into <code>dst</code>.
	 * If omitted <code>k</code> is set to <code>dst</code>.length;
	 */
	inline public static function assign<T>(dst:Array<T>, C:Class<T>, args:Array<Dynamic> = null, k = -1)
	{
		if (k == -1) k = dst.length;
		if (args == null) args = [];
		for (i in 0...k) dst[i] = Type.createInstance(C, args);
	}
	
	/**
	 * Copies <code>n</code> elements inside <code>a</code> from the location pointed by the index <code>source</code> to the location pointed by the index <code>destination</code>.<br/>
	 * Copying takes place as if an intermediate buffer is used, allowing the destination and source to overlap.
	 * @throws de.polygonal.ds.error.AssertError invalid <code>destination</code>, <code>source</code> or <code>n</code> value (debug only).
	 * @see <a href="ttp://www.cplusplus.com/reference/clibrary/cstring/memmove/" target="_blank">ttp://www.cplusplus.com/reference/clibrary/cstring/memmove/</a>
	 */
	inline public static function memmove<T>(a:Array<T>, destination:Int, source:Int, n:Int)
	{
		#if debug
		assert(destination >= 0 && source >= 0 && n >= 0, "destination >= 0 && source >= 0 && n >= 0");
		assert(source < a.length, "source < a.length");
		assert(destination + n <= a.length, "destination + n <= a.length");
		assert(n <= a.length, "n <= a.length");
		#end
		
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
	 * Searches the sorted array <code>a</code> for the element <code>x</code> in the range <arg>(<code>min</code>, <code>max</code>&#093;</arg> using the binary search algorithm.
	 * @return the index of the element <code>x</code> or the bitwise complement (~) of the index where <code>x</code> would be inserted (guaranteed to be a negative number).
	 * <warn>The insertion point is only valid for <code>min</code>=0 and <code>max</code>=a.length-1.</warn>
	 * @throws de.polygonal.ds.error.AssertError <code>a</code>/<code>comparator</code> is null (debug only).
	 * @throws de.polygonal.ds.error.AssertError invalid min/max search boundaries (debug only).
	 */
	public static function bsearchComparator<T>(a:Array<T>, x:T, min:Int, max:Int, comparator:T->T->Int):Int
	{
		#if debug
		assert(a != null, "a != null");
		assert(comparator != null, "comparator != null");
		assert(min >= 0 && min < a.length, "min >= 0 && min < a.length");
		assert(max < a.length, "max < a.length");
		#end
		
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
	 * Searches the sorted array <code>a</code> for the element <code>x</code> in the range <arg>(<code>min</code>, <code>max</code>&#093;</arg> using the binary search algorithm.
	 * @return the index of the element <code>x</code> or the bitwise complement (~) of the index where <code>x</code> would be inserted (guaranteed to be a negative number).<br/>
	 * <warn>The insertion point is only valid for <code>min</code>=0 and <code>max</code>=a.length-1.</warn>
	 * @throws de.polygonal.ds.error.AssertError <code>a</code> is null (debug only).
	 * @throws de.polygonal.ds.error.AssertError invalid min/max search boundaries (debug only).
	 */
	inline public static function bsearchInt(a:Array<Int>, x:Int, min:Int, max:Int):Int
	{
		#if debug
		assert(a != null, "a != null");
		assert(min >= 0 && min < a.length, "min >= 0 && min < a.length");
		assert(max < a.length, "max < a.length");
		#end
		
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
	 * Searches the sorted array <code>a</code> for the element <code>x</code> in the range <arg>(<code>min</code>, <code>max</code>&#093;</arg> using the binary search algorithm.
	 * @return the index of the element <code>x</code> or the bitwise complement (~) of the index where <code>x</code> would be inserted (guaranteed to be a negative number).
	 * <warn>The insertion point is only valid for <code>min</code>=0 and <code>max</code>=a.length-1.</warn>
	 * @throws de.polygonal.ds.error.AssertError <code>a</code> is null (debug only).
	 * @throws de.polygonal.ds.error.AssertError invalid min/max search boundaries (debug only).
	 */
	inline public static function bsearchFloat(a:Array<Float>, x:Float, min:Int, max:Int):Int
	{
		#if debug
		assert(a != null, "a != null");
		assert(min >= 0 && min < a.length, "min >= 0 && min < a.length");
		assert(max < a.length, "max < a.length");
		#end
		
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
	 * Shuffles the elements of the array <code>a</code> by using the Fisher-Yates algorithm.<br/>
	 * @param rval a list of random double values in the range between 0 (inclusive) to 1 (exclusive) defining the new positions of the elements.
	 * If omitted, random values are generated on-the-fly by calling <em>Math.random()</em>.
	 * @throws de.polygonal.ds.error.AssertError insufficient random values (debug only).
	 */
	public static function shuffle<T>(a:Array<T>, rval:Array<Float> = null)
	{
		#if debug
		assert(a != null, "a != null");
		#end
		
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
			#if debug
			assert(rval.length >= a.length, "insufficient random values");
			#end
			
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
	 * Sorts the elements of the array <code>a</code> by using the quick sort algorithm.
	 * @param compare a comparison function.
	 * @param useInsertionSort if true, the array is sorted using the insertion sort algorithm. This is faster for nearly sorted lists.
	 * @param first sort start index. The default value is 0.
	 * @param count the number of elements to sort (range: <arg>&#091;<code>first</code>, <code>first</code> + <code>count</code>&#093;</arg>).<br/>
	 * If omitted, <code>count</code> is set to <code>size()</code>.
	 * @throws de.polygonal.ds.error.AssertError <code>first</code> or <code>count</code> out of bound (debug only).
	 */
	public static function sortRange(a:Array<Float>, compare:Float->Float->Int, useInsertionSort:Bool, first:Int, count:Int)
	{
		var k = a.length;
		if (k > 1)
		{
			#if debug
			assert(first >= 0 && first <= k - 1 && first + count <= k, "first out of bound");
			assert(count >= 0 && count <= k, "count out of bound");
			#end
			
			if (useInsertionSort)
				_insertionSort(a, first, count, compare);
			else
				_quickSort(a, first, count, compare);
		}
	}
	
	/**
	 * A counting quick permutation algorithm.
	 * @see <a href="http://www.freewebs.com/permute/quickperm.html" target="_blank">http://www.freewebs.com/permute/quickperm.html</a>
	 * @param n number of elements to permute.
	 */
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
	
	public static function equals<T>(a:Array<T>, b:Array<T>):Bool
	{
		if (a.length != b.length) return false;
		for (i in 0...a.length)
			if (a[i] != b[i])
				return false;
		return true;
	}
	
	/**
	 * Splits the input array <code>a</code> storing <code>n</code> elements into smaller chunks, each containing k elements.
	 * @throws de.polygonal.AssertError <code>n</code> is not a multiple of <code>k</code> (debug only).
	 */
	public static function split<T>(a:Array<T>, n:Int, k:Int):Array<Array<T>>
	{
		#if debug
		assert(n % k == 0, "n is not a multiple of k");
		#end
		
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