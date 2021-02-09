/*
Copyright (c) 2008-2019 Michael Baczynski, http://www.polygonal.de

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
package ds.tools;

import ds.tools.ArrayTools;
import ds.tools.Assert.assert;

/**
	Utility class for modifying `NativeArray` objects
**/
class NativeArrayTools
{
	/**
		Allocates an array with length `len`.
	**/
	public static inline function alloc<T>(len:Int):NativeArray<T>
	{
		#if flash10
			#if (generic && !no_inline)
			return new flash.Vector<T>(len, true);
			#else
			var a = new Array<T>();
			untyped a.length = len;
			return a;
			#end
		#elseif neko
		return untyped __dollar__amake(len);
		#elseif js
			#if (haxe_ver >= 4.000)
				return js.Syntax.construct(Array, len);
			#else
				return untyped __new__(Array, len);
			#end
		#elseif cs
		return cs.Lib.arrayAlloc(len);
		#elseif java
		return untyped Array.alloc(len);
		#elseif cpp
		return cpp.NativeArray.create(len);
		#elseif python
		return python.Syntax.code("[{0}]*{1}", null, len);
		#elseif eval
		return new eval.Vector<T>(len);
		#else
		var a = [];
		untyped a.length = len;
		return a;
		#end
	}
	
	/**
		Returns the value in `src` at `index`.
	**/
	#if !(assert == "extra")
	inline
	#end
	public static function get<T>(src:NativeArray<T>, index:Int):T
	{
		#if (assert == "extra")
		assert(index >= 0 && index < size(src), 'index $index out of range ${size(src)}');
		#end
		
		return
		#if (cpp && generic)
		cpp.NativeArray.unsafeGet(src, index);
		#elseif python
		python.internal.ArrayImpl.unsafeGet(src, index);
		#else
		src[index];
		#end
	}
	
	/**
		Sets the value in `src` at `index` to `val`.
	**/
	#if !(assert == "extra")
	inline
	#end
	public static function set<T>(dst:NativeArray<T>, index:Int, val:T)
	{
		#if (assert == "extra")
		assert(index >= 0 && index < size(dst), 'index $index out of range ${size(dst)}');
		#end
		
		#if (cpp && generic)
		cpp.NativeArray.unsafeSet(dst, index, val);
		#elseif python
		python.internal.ArrayImpl.unsafeSet(dst, index, val);
		#else
		dst[index] = val;
		#end
	}
	
	/**
		Returns the number of values in `a`.
	**/
	public static inline function size<T>(a:NativeArray<T>):Int
	{
		return
		#if neko
		untyped __dollar__asize(a);
		#elseif cs
		a.length;
		#elseif java
		a.length;
		#elseif python
		a.length;
		#elseif cpp
		a.length;
		#else
		a.length;
		#end
	}
	
	/**
		Copies `n` elements from `src` beginning at `first` to `dst` and returns `dst`.
	**/
	public static function toArray<T>(src:NativeArray<T>, first:Int, len:Int, dst:Array<T>):Array<T>
	{
		assert(first >= 0 && first < size(src), "first index out of range");
		assert(len >= 0 && first + len <= size(src), "len out of range");
		
		#if (cpp || python)
		if (first == 0 && len == size(src)) return src.copy();
		#elseif eval
		if (first == 0 && len == size(src)) return src.toArray();
		#end
		
		if (len == 0) return [];
		var out = ArrayTools.alloc(len);
		if (first == 0)
		{
			for (i in 0...len) out[i] = get(src, i);
		}
		else
		{
			for (i in first...first + len) out[i - first] = get(src, i);
		}
		return out;
	}
	
	/**
		Returns a `NativeArray` object from the values stored in `src`.
	**/
	public static inline function ofArray<T>(src:Array<T>):NativeArray<T>
	{
		#if (python || cs)
		return cast src.copy();
		#elseif flash10
			return
			#if (generic && !no_inline)
			flash.Vector.ofArray(src);
			#else
			src.copy();
			#end
		#elseif js
		return src.slice(0, src.length);
		#else
		var out = alloc(src.length);
		for (i in 0...src.length) set(out, i, src[i]);
		return out;
		#end
	}
	
	/**
		Copies `n` elements from `src`, beginning at `srcPos` to `dst`, beginning at `dstPos`.
		
		Copying takes place as if an intermediate buffer was used, allowing the destination and source to overlap.
	**/
	#if (cs || java || neko || cpp)
	inline
	#end
	public static function blit<T>(src:NativeArray<T>, srcPos:Int, dst:NativeArray<T>, dstPos:Int, n:Int)
	{
		if (n > 0)
		{
			assert(srcPos < size(src), "srcPos out of range");
			assert(dstPos < size(dst), "dstPos out of range");
			assert(srcPos + n <= size(src) && dstPos + n <= size(dst), "n out of range");
			
			#if neko
			untyped __dollar__ablit(dst, dstPos, src, srcPos, n);
			#elseif cpp
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
						set(src, j, get(src, i));
					}
				}
				else
				if (srcPos > dstPos)
				{
					var i = srcPos;
					var j = dstPos;
					for (k in 0...n)
					{
						set(src, j, get(src, i));
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
		Returns a shallow copy of `src`.
	**/
	inline public static function copy<T>(src:NativeArray<T>):NativeArray<T>
	{
		#if (neko || cpp)
		var len = size(src);
		var out = alloc(len);
		blit(src, 0, out, 0, len);
		return out;
		#elseif flash
		return src.slice(0);
		#elseif js
		return src.slice(0);
		#elseif python
		return src.copy();
		#else
		var len = size(src);
		var dst = alloc(len);
		for (i in 0...len) set(dst, i, get(src, i));
		return dst;
		#end
	}
	
	/**
		Sets `n` elements in `dst` to 0 starting at index `first` and returns `dst`.
		If `n` is 0, `n` is set to the length of `dst`.
	**/
	#if (flash || java)
	inline
	#end
	public static function zero<T>(dst:NativeArray<T>, first:Int = 0, n:Int = 0):NativeArray<T>
	{
		var min = first;
		var max = n <= 0 ? size(dst) : min + n;
		
		assert(min >= 0 && min < size(dst));
		assert(max <= size(dst));
		
		#if cpp
		cpp.NativeArray.zero(dst, min, max - min);
		#else
		var val:Int = 0;
		while (min < max) set(dst, min++, cast val);
		#end
		
		return dst;
	};
	
	/**
		Sets `n` elements in `a` to `val` starting at index `first` and returns `a`.
		If `n` is 0, `n` is set to the length of `a`.
	**/
	public static function init<T>(a:NativeArray<T>, val:T, first:Int = 0, n:Int = 0):NativeArray<T>
	{
		var min = first;
		var max = n <= 0 ? size(a) : min + n;
		
		assert(min >= 0 && min < size(a));
		assert(max <= size(a));
		
		while (min < max) set(a, min++, val);
		return a;
	}
	
	/**
		Nullifies `n` elements in `a` starting at index `first` and returns `a`.
		If `n` is 0, `n` is set to the length of `a`.
	**/
	public static function nullify<T>(a:NativeArray<T>, first:Int = 0, n:Int = 0):NativeArray<T>
	{
		var min = first;
		var max = n <= 0 ? size(a) : min + n;
		
		assert(min >= 0 && min < size(a));
		assert(max <= size(a));
		
		#if cpp
		cpp.NativeArray.zero(a, min, max - min);
		#else
		while (min < max) set(a, min++, cast null);
		#end
		
		return a;
	}
	
	/**
		Searches the sorted array `a` for `val` in the range [`min`, `max`] using the binary search algorithm.
		
		@return the array index storing `val` or the bitwise complement (~) of the index where `val` would be inserted (guaranteed to be a negative number).
		<br/>The insertion point is only valid for `min` = 0 and `max` = `a.length` - 1.
	**/
	public static function binarySearchCmp<T>(a:NativeArray<T>, val:T, min:Int, max:Int, cmp:T->T->Int):Int
	{
		assert(a != null);
		assert(cmp != null);
		assert(min >= 0 && min < size(a));
		assert(max < size(a));
		
		var l = min, m, h = max + 1;
		while (l < h)
		{
			m = l + ((h - l) >> 1);
			if (cmp(get(a, m), val) < 0)
				l = m + 1;
			else
				h = m;
		}
		
		if ((l <= max) && cmp(get(a, l), val) == 0)
			return l;
		else
			return ~l;
	}
	
	/**
		Searches the sorted array `a` for `val` in the range [`min`, `max`] using the binary search algorithm.
		@return the array index storing `val` or the bitwise complement (~) of the index where `val` would be inserted (guaranteed to be a negative number).
		<br/>The insertion point is only valid for `min` = 0 and `max` = `a.length` - 1.
	**/
	public static function binarySearchf(a:NativeArray<Float>, val:Float, min:Int, max:Int):Int
	{
		assert(a != null);
		assert(min >= 0 && min < size(a));
		assert(max < size(a));
		
		var l = min, m, h = max + 1;
		while (l < h)
		{
			m = l + ((h - l) >> 1);
			if (get(a, m) < val)
				l = m + 1;
			else
				h = m;
		}
		
		if ((l <= max) && (get(a, l) == val))
			return l;
		else
			return ~l;
	}
	
	/**
		Searches the sorted array `a` for `val` in the range [`min`, `max`] using the binary search algorithm.
		@return the array index storing `val` or the bitwise complement (~) of the index where `val` would be inserted (guaranteed to be a negative number).
		<br/>The insertion point is only valid for `min` = 0 and `max` = `a.length` - 1.
	**/
	public static function binarySearchi(a:NativeArray<Int>, val:Int, min:Int, max:Int):Int
	{
		assert(a != null);
		assert(min >= 0 && min < size(a));
		assert(max < size(a));
		
		var l = min, m, h = max + 1;
		while (l < h)
		{
			m = l + ((h - l) >> 1);
			if (get(a, m) < val)
				l = m + 1;
			else
				h = m;
		}
		
		if ((l <= max) && (get(a, l) == val))
			return l;
		else
			return ~l;
	}
}
