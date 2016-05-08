package de.polygonal.ds.tools;

import de.polygonal.ds.tools.ArrayTools;
import de.polygonal.ds.tools.Assert.assert;

class NativeArrayTools
{
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
		return untyped __new__(Array, len);
		#elseif cs
		return new cs.NativeArray(len);
		#elseif java
		return new java.NativeArray(len);
		#elseif cpp
		var a = new Array<T>();
		cpp.NativeArray.setSize(a, len);
		return a;
		#elseif python
		return python.Syntax.pythonCode("[{0}]*{1}", null, len);
		#else
		var a = [];
		untyped a.length = len;
		return a;
		#end
	}
	
	#if !(assert == "extra")
	inline
	#end
	public static function get<T>(src:NativeArray<T>, i:Int):T
	{
		#if (assert == "extra")
		assert(i >= 0 && i < size(src), 'index $i out of range ${size(src)}');
		#end
		
		return
		#if (cpp && generic)
		cpp.NativeArray.unsafeGet(src, i);
		#elseif python
		python.internal.ArrayImpl.unsafeGet(src, i);
		#else
		src[i];
		#end
	}
	
	#if !(assert == "extra")
	inline
	#end
	public static function set<T>(dst:NativeArray<T>, i:Int, val:T)
	{
		#if (assert == "extra")
		assert(i >= 0 && i < size(dst), 'index $i out of range ${size(dst)}');
		#end
		
		#if (cpp && generic)
		cpp.NativeArray.unsafeSet(dst, i, val);
		#elseif python
		python.internal.ArrayImpl.unsafeSet(dst, i, val);
		#else
		dst[i] = val;
		#end
	}
	
	public static inline function size<T>(src:NativeArray<T>):Int
	{
		return
		#if neko
		untyped __dollar__asize(src);
		#elseif cs
		src.Length;
		#elseif java
		src.length;
		#elseif python
		src.length;
		#elseif cpp
		src.length;
		#else
		src.length;
		#end
	}
	
	#if java inline #end
	public static function toArray<T>(src:NativeArray<T>, first:Int, count:Int):Array<T>
	{
		assert(first >= 0 && first < size(src), "first index out of range");
		assert(count >= 0 && first + count <= size(src), "count out of range");
		
		#if (cpp || python)
		if (first == 0 && count == size(src)) return src.copy();
		#end
		
		if (count == 0) return [];
		var out = ArrayTools.alloc(count);
		if (first == 0)
		{
			for (i in 0...count) out[i] = get(src, i);
		}
		else
		{
			var j;
			for (i in first...first + count) out[i - first] = get(src, i);
		}
		
		return out;
	}
	
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
		//#elseif java
		//return cast (java.Lib.nativeArray(src, false));
		#elseif cs
		//return cast (cs.Lib.nativeArray(src, false));
		#elseif js
		return src.slice(0, src.length);
		#else
		var out = alloc(src.length);
		for (i in 0...src.length) set(out, i, src[i]);
		return out;
		#end
	}
	
	#if (cs || java || neko || cpp)
	inline
	#end
	public static function blit<T>(src:NativeArray<T>, srcPos:Int, dst:NativeArray<T>, dstPos:Int, len:Int)
	{
		if (len > 0)
		{
			assert(srcPos < size(src), "srcPos out of range");
			assert(dstPos < size(dst), "dstPos out of range");
			assert(srcPos + len <= size(src) && dstPos + len <= size(dst), "len out of range");
			
			#if neko
			untyped __dollar__ablit(dst, dstPos, src, srcPos, len);
			#elseif java
			java.lang.System.arraycopy(src, srcPos, dst, dstPos, len);
			#elseif cs
			cs.system.Array.Copy(cast src, srcPos, cast dst, dstPos, len);
			#elseif cpp
			cpp.NativeArray.blit(dst, dstPos, src, srcPos, len);
			#else
			if (src == dst)
			{
				if (srcPos < dstPos)
				{
					var i = srcPos + len;
					var j = dstPos + len;
					for (k in 0...len)
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
					for (k in 0...len)
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
					for (i in 0...len) dst[i] = src[i];
				}
				else
				if (srcPos == 0)
				{
					for (i in 0...len) dst[dstPos + i] = src[i];
				}
				else
				if (dstPos == 0)
				{
					for (i in 0...len) dst[i] = src[srcPos + i];
				}
				else
				{
					for (i in 0...len) dst[dstPos + i] = src[srcPos + i];
				}
			}
			#end
		}
	}
	
	#if java inline #end
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
	
	#if (flash || java)
	inline
	#end
	public static function zero<T:Float>(dst:NativeArray<T>, first:Int, len:Int):NativeArray<T>
	{
		#if cpp
		untyped dst.zero(first, len);
		#else
		var val:Int = 0;
		for (i in first...first + len) dst[i] = cast val;
		#end
		return dst;
	};
	
	/**
		Sets up to `k` elements in `dst` to `val`.
		@param k the number of elements to put into `dst`.
		If omitted `k` is set to `dst.length`;
	**/
	#if java inline #end
	public static function init<T>(dst:NativeArray<T>, val:T, first:Int = 0, ?k:Null<Int>):NativeArray<T>
	{
		if (k == null) k = size(dst);
		for (i in first...first + k) set(dst, i, val);
		return dst;
	}
	
	/**
		Nullifies all elements in `dst`.
	**/
	#if java inline #end
	public static function nullify<T>(dst:NativeArray<T>, count:Int = 0)
	{
		assert(count <= size(dst), "count out of range");
		
		if (count == 0) count = size(dst);
		
		#if cpp
		cpp.NativeArray.zero(dst, 0, count);
		#else
		for (i in 0...count) set(dst, i, cast null);
		#end
	}
	
	/**
		Searches the sorted array `src` for `val` in the range (`min`, `max`] using the binary search algorithm.
		@return the index of `val` or the bitwise complement (~) of the index where `val` would be inserted (guaranteed to be a negative number).
		<warn>The insertion point is only valid for `min=0` and `max=a.length-1`.</warn>
	**/
	#if java inline #end
	public static function binarySearchCmp<T>(src:NativeArray<T>, val:T, min:Int, max:Int, cmp:T->T->Int):Int
	{
		assert(src != null);
		assert(cmp != null);
		assert(min >= 0 && min < size(src));
		assert(max < size(src));
		
		var l = min, m, h = max + 1;
		while (l < h)
		{
			m = l + ((h - l) >> 1);
			if (cmp(get(src, m), val) < 0)
				l = m + 1;
			else
				h = m;
		}
		
		if ((l <= max) && cmp(get(src, l), val) == 0)
			return l;
		else
			return ~l;
	}
	
	public static function binarySearchf(src:NativeArray<Float>, val:Float, min:Int, max:Int):Int
	{
		assert(src != null);
		assert(min >= 0 && min < size(src));
		assert(max < size(src));
		
		var l = min, m, h = max + 1;
		while (l < h)
		{
			m = l + ((h - l) >> 1);
			if (get(src, m) < val)
				l = m + 1;
			else
				h = m;
		}
		
		if ((l <= max) && (get(src, l) == val))
			return l;
		else
			return ~l;
	}
	
	public static function binarySearchi(src:NativeArray<Int>, val:Int, min:Int, max:Int):Int
	{
		assert(src != null);
		assert(min >= 0 && min < size(src));
		assert(max < size(src));
		
		var l = min, m, h = max + 1;
		while (l < h)
		{
			m = l + ((h - l) >> 1);
			if (get(src, m) < val)
				l = m + 1;
			else
				h = m;
		}
		
		if ((l <= max) && (get(src, l) == val))
			return l;
		else
			return ~l;
	}
}