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

#if cpp
using cpp.NativeArray;
#end

/**
	Utility class for working with Arrays.
**/
class ArrayTools
{
	/**
		Allocates an array with length `len`.
	**/
	public static inline function alloc<T>(len:Int):Array<T>
	{
		assert(len >= 0);
		
		var a:Array<T>;
		#if flash
		a = untyped __new__(Array, len);
		return a;
		#elseif js
			#if (haxe_ver >= 4.000)
			a = js.Syntax.construct(Array, len);
			#else
			a = untyped __new__(Array, len);
			#end
		return a;
		#elseif cpp
		a = new Array<T>();
		a.setSize(len);
		return a;
		#elseif java
		return untyped Array.alloc(len);
		#elseif cs
		return cs.Lib.arrayAlloc(len);
		#else
		a = new Array<T>();
		#if neko
		a[len - 1] = cast null;
		#end
		for (i in 0...len) a[i] = cast null;
		return a;
		#end
	}
	
	/**
		Shrinks `a` to length `len` and returns `a`.
	**/
	public static inline function trim<T>(a:Array<T>, len:Int):Array<T>
	{
		if (a.length > len)
		{
			#if (flash || js)
			untyped a.length = len;
			return a;
			#elseif cpp
			a.setSize(len);
			return a;
			#else
			return a.slice(0, len);
			#end
		}
		else
			return a;
	}
	
	/**
		Swaps the elements of `array` at indices `a` and `b`.
	**/
	public static inline function swap<T>(array:Array<T>, a:Int, b:Int)
	{
		assert(array != null);
		assert(0 <= a && a < array.length);
		assert(0 <= b && b < array.length);
		
		if (a != b)
		{
			var x = array[a];
			array[a] = array[b];
			array[b] = x;
		}
	}
	
	/**
		Gets the element at index `index`, then exchanges it with element at the
		front of `array` (i.e. at index 0).  Used to facilitate fast lookups of
		array elements that are frequently used.
	**/
	public static inline function getFront<T>(array:Array<T>, index:Int):T
	{
		assert(array != null);
		assert(0 <= index && index < array.length);
		
		swap(array, index, 0);
		return array[0];
	}
	
	/**
		Sets `n` elements in `a` to `val` starting at index `first` and returns `a`.
		If `n` is zero, `n` is set to the length of `a`.
	**/
	public static function init<T>(a:Array<T>, val:T, first:Int = 0, n:Int = 0):Array<T>
	{
		var min = first;
		var max = n <= 0 ? a.length : min + n;
		
		assert(min >= 0 && min < a.length);
		assert(max <= a.length);
		
		while (min < max) a[min++] = val;
		return a;
	}
	
	/**
		Copies `n` elements from `src`, beginning at `srcPos` to `dst`, beginning at `dstPos`.
		
		Copying takes place as if an intermediate buffer was used, allowing the destination and source to overlap.
	**/
	public static function blit<T>(src:Array<T>, srcPos:Int, dst:Array<T>, dstPos:Int, n:Int)
	{
		if (n > 0)
		{
			assert(srcPos < src.length, "srcPos out of range");
			assert(dstPos < dst.length, "dstPos out of range");
			assert(srcPos + n <= src.length && dstPos + n <= dst.length, "n out of range");
			
			#if cpp
			cpp.NativeArray.blit(dst, dstPos, src, srcPos, n);
			#else
			if (src == dst)
			{
				if (srcPos < dstPos)
				{
					var i = srcPos + n;
					var j = dstPos + n;
					for (k in 0...n)
					{
						i--;
						j--;
						src[j] = src[i];
					}
				}
				else
				if (srcPos > dstPos)
				{
					var i = srcPos;
					var j = dstPos;
					for (k in 0...n)
					{
						src[j] = src[i];
						i++;
						j++;
					}
				}
			}
			else
			{
				if (srcPos == 0 && dstPos == 0)
				{
					for (i in 0...n) dst[i] = src[i];
				}
				else
				if (srcPos == 0)
				{
					for (i in 0...n) dst[dstPos + i] = src[i];
				}
				else
				if (dstPos == 0)
				{
					for (i in 0...n) dst[i] = src[srcPos + i];
				}
				else
				{
					for (i in 0...n) dst[dstPos + i] = src[srcPos + i];
				}
			}
			#end
		}
	}
	
	/**
		Calls 'f` on all elements in the interval [0, `n`) in order.
		If `n` is omitted, `n` is set to `src`.length.
	**/
	public static inline function iter<T>(src:Array<T>, f:T->Void, n:Int = 0)
	{
		if (n == 0) n = src.length;
		for (i in 0...n) f(src[i]);
	}
	
	/**
		Calls `f` on all elements.
		
		The function signature is: `f(input, index):output`
		
		- input: current element
		- index: element index [0, src.length)
		- output: element to be stored at given index
	**/
	public static inline function forEach<T>(src:Array<T>, f:T->Int->T)
	{
		var n = src.length;
		for (i in 0...n) src[i] = f(src[i], i);
	}
	
	/**
		Searches the sorted array `src` for `val` in the range [`min`, `max`] using the binary search algorithm.
		
		@return the array index storing `val` or the bitwise complement (~) of the index where `val` would be inserted (guaranteed to be a negative number).
		<br/>The insertion point is only valid for `min` = 0 and `max` = `src.length` - 1.
	**/
	public static function binarySearchCmp<T>(a:Array<T>, x:T, min:Int, max:Int, comparator:T->T->Int):Int
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
		Searches the sorted array `src` for `val` in the range [`min`, `max`] using the binary search algorithm.
		
		@return the array index storing `val` or the bitwise complement (~) of the index where `val` would be inserted (guaranteed to be a negative number).
		<br/>The insertion point is only valid for `min` = 0 and `max` = `src.length` - 1.
	**/
	public static function binarySearchf(a:Array<Float>, x:Float, min:Int, max:Int):Int
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
		Searches the sorted array `src` for `val` in the range [`min`, `max`] using the binary search algorithm.
		
		@return the array index storing `val` or the bitwise complement (~) of the index where `val` would be inserted (guaranteed to be a negative number).
		<br/>The insertion point is only valid for `min` = 0 and `max` = `src.length` - 1.
	**/
	public static function binarySearchi(a:Array<Int>, x:Int, min:Int, max:Int):Int
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
		@param rvals a list of random double values in the range between [0, 1) defining the new positions of the elements.
		If omitted, random values are generated on-the-fly by calling `Shuffle.frand()`.
	**/
	public static function shuffle<T>(a:Array<T>, rvals:Array<Float> = null)
	{
		assert(a != null);
		
		var s = a.length;
		if (rvals == null)
		{
			while (--s > 1)
			{
				var i = Std.int(Shuffle.frand() * s);
				var t = a[s];
				a[s] = a[i];
				a[i] = t;
			}
		}
		else
		{
			assert(rvals.length >= a.length, "insufficient random values");
			
			var j = 0;
			while (--s > 1)
			{
				var i = Std.int(rvals[j++] * s);
				var t = a[s];
				a[s] = a[i];
				a[i] = t;
			}
		}
	}
	
	/**
		Sorts the elements of the array `a` by using the quick sort algorithm.
		@param cmp a comparison function.
		@param useInsertionSort if true, the array is sorted using the insertion sort algorithm. This is faster for nearly sorted lists.
		@param first sort start index. The default value is 0.
		@param n the number of elements to sort (range: [`first`, `first` + `n`]).
		If omitted, `n` is set to `a.length`.
	**/
	public static function sortRange(a:Array<Float>, cmp:Float->Float->Int, useInsertionSort:Bool, first:Int, n:Int)
	{
		var k = a.length;
		if (k > 1)
		{
			assert(first >= 0 && first <= k - 1 && first + n <= k, "first out of range");
			assert(n >= 0 && n <= k, "n out of range");
			
			if (useInsertionSort)
			{
				for (i in first + 1...first + n)
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
			else
				_quickSort(a, first, n, cmp);
		}
	}
	
	/**
		A quick counting permutation algorithm, where `n` is the number of elements to permute.
	**/
	public static function quickPerm(n:Int):Array<Array<Int>>
	{
		var results = [];
		
		var a = [];
		var p = [];
		
		var i:Int, j:Int, t:Int;
		
		i = 0;
		while (i < n)
		{
			a[i] = i + 1;
			p[i] = 0;
			i++;
		}
		
		results.push(a.copy());
		
		i = 1;
		while (i < n)
		{
			if (p[i] < i)
			{
				j = i % 2 * p[i];
				t = a[j];
				a[j] = a[i];
				a[i] = t;
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
		Compares the elements of `a` and `b` by using the equality operator (==).
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
		Splits the input array `a` storing `n` elements into smaller chunks, each containing `k` elements.
	**/
	public static function split<T>(a:Array<T>, n:Int, k:Int):Array<Array<T>>
	{
		assert(n % k == 0, "n is not a multiple of k");
		
		var out = new Array<Array<T>>();
		var b:Array<T> = null;
		for (i in 0...n)
		{
			if (i % k == 0)
				out[Std.int(i / k)] = b = [];
			b.push(a[i]);
		}
		return out;
	}
	
	/**
		Visits all elements in `input` as a pair by calling `visit`.
		
		The function signature is: `visit(currentPairIndex, firstPairElement, secondPairElement)`
		
		Example:
			var points = [1.1, 1.2, 2.1, 2.2]; //format: [x0, y0, x1, y1, xn, yn, ...]
			ArrayTools.pairwise(points, function(i, x, y) trace('point $i: x=$x, y=$y'));
	**/
	public static inline function pairwise<T>(input:Array<T>, visit:Int->T->T->Void)
	{
		var i = 0;
		var k = input.length;
		assert(k & 1 == 0);
		while (i < k)
		{
			visit(i, input[i], input[i + 1]);
			i += 2;
		}
	}
	
	/**
		Brute-force search (aka exhaustive search).
		Calls `visit` on all pairs in `input`.
		
		The function signature is: `visit(firstElementInPair, otherElementInPair)`
		
		Example:
			var elements = ["a", "b", "c"];
			ArrayTools.bruteforce(elements, function(a, b) trace('($a,$b)')); //outputs (a,b), (a,c), (b,c);
	**/
	public static inline function bruteforce<T>(input:Array<T>, visit:T->T->Void)
	{
		var i = 0, j, k = input.length, l = k - 1;
		while (i < l)
		{
			j = i + 1;
			while (j < k)
			{
				visit(input[i], input[j]);
				j++;
			}
			i++;
		}
	}
	
	static function _quickSort(a:Array<Float>, first:Int, n:Int, cmp:Float->Float->Int)
	{
		var last = first + n - 1;
		var lo = first;
		var hi = last;
		if (n > 1)
		{
			var i0 = first;
			var i1 = i0 + (n >> 1);
			var i2 = i0 + n - 1;
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