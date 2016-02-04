package de.polygonal.ds.tools;

import de.polygonal.ds.error.Assert.assert;

#if cpp
using cpp.NativeArray;
#end

class NativeArray
{
	inline public static function init<T>(len:Int):Container<T>
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
		return new Array<T>();
		#elseif cpp
		var a = new Array<T>();
		a.setSize(len);
		return a;
		#elseif python
		return python.Syntax.pythonCode("[{0}]*{1}", null, len);
		#else
		var a = [];
		untyped a.length = len;
		return a;
		#end
	}
	
	inline public static function get<T>(x:Container<T>, i:Int):T
	{
		return
		#if (cpp && generic)
		x.unsafeGet(i);
		#elseif python
		python.internal.ArrayImpl.unsafeGet(x, i);
		#else
		x[i];
		#end
	}
	
	inline public static function set<T>(x:Container<T>, i:Int, v:T)
	{
		#if (cpp && generic)
		x.unsafeSet(i, v);
		#elseif python
		python.internal.ArrayImpl.unsafeSet(x, i, v);
		#else
		x[i] = v;
		#end
	}
	
	inline public static function size<T>(x:Container<T>):Int
	{
		return
		#if neko
		untyped __dollar__asize(x);
		#elseif cs
		x.Length;
		#elseif java
		x.length;
		#elseif python
		x.length;
		#elseif cpp
		x.length;
		#else
		x.length;
		#end
	}
	
	public static function toArray<T>(x:Container<T>, first:Int = 0, len:Int = 0):Array<T>
	{
		assert(first < size(x), "first index is out of range");
		assert(first + len <= size(x), "len is out of range");
		
		if (first > 0 && len > 0)
		{
			var out = ArrayUtil.alloc(len);
			for (i in 0...len) out[i] = get(x, first + i);
			return out;
		}
		else
		if (first > 0)
		{
			var s = size(x) - first;
			var out = ArrayUtil.alloc(s);
			for (i in 0...s) out[i] = get(x, first + i);
			return out;
		}
		else
		if (len > 0)
		{
			var out = ArrayUtil.alloc(len);
			for (i in 0...len) out[i] = get(x, i);
			return out;
		}
		else
		{
			#if (cpp || python)
			return x.copy();
			#else
			var s = size(x);
			var out = ArrayUtil.alloc(s);
			for (i in 0...s) out[i] = get(x, i);
			return out;
			#end
		}
	}
	
	#if (cs || java || neko || cpp)
	inline
	#end
	public static function blit<T>(src:Container<T>, srcPos:Int, dst:Container<T>, dstPos:Int, len:Int)
	{
		assert(srcPos < size(src), "srcPos is out of range");
		assert(dstPos < size(dst), "dstPos is out of range");
		assert(srcPos + len <= size(src) && dstPos + len <= size(dst), "len is out of range");
		
		#if neko
		untyped __dollar__ablit(dst,dstPos,src,srcPos,len);
		//#elseif java
		//TODO java.lang.System.arraycopy(src, srcPos, dst, dstPos, len);
		#elseif cs
		cs.system.Array.Copy(cast src, srcPos, cast dst, dstPos, len);
		#elseif cpp
		dst.blit(dstPos, src, srcPos, len);
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
	
	public static function copy<T>(src:Container<T>):Container<T>
	{
		#if (neko || cpp)
		var len = size(src);
		var out = init(len);
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
		var dst = init(len);
		for (i in 0...len) set(dst, i, get(src, i));
		return dst;
		#end
	}
	
	static public inline function fromArrayCopy<T>(array:Array<T>):Container<T>
	{
		#if python
		return cast array.copy();
		#elseif flash10
			return
			#if (generic && !no_inline)
			flash.Vector.ofArray(array);
			#else
			array.copy();
			#end
		//#elseif java
		//#elseif java
		//return fromData(java.Lib.nativeArray(array, false));
		#elseif cs
		return fromData(cs.Lib.nativeArray(array, false));
		#elseif js
		return array.slice(0, array.length);
		#else
		var out = NativeArray.init(array.length);
		for (i in 0...array.length) out[i] = array[i];
		return out;
		#end
	}
	
	#if flash
	inline
	#end
	public static function zero<T:Float>(dst:Container<T>, first:Int, len:Int):Container<T>
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
		Sets up to `k` elements in `dst` to the instance `x`.
		@param k the number of elements to put into `dst`.
		If omitted `k` is set to `dst`::length;
	**/
	public static function assign<T>(dst:Container<T>, x:T, first:Int = 0, ?k:Null<Int>):Container<T>
	{
		if (k == null) k = size(dst);
		for (i in first...first + k) set(dst, i, x);
		return dst;
	}
	
	/**
		Searches the sorted vector `v` for the element `x` in the range (`min`, `max`] using the binary search algorithm.
		<assert>`a`/`comparator` is null</assert>
		<assert>invalid `min`/`max` search boundaries</assert>
		@return the index of the element `x` or the bitwise complement (~) of the index where `x` would be inserted (guaranteed to be a negative number).
		<warn>The insertion point is only valid for `min`=0 and `max`=a.length-1.</warn>
	**/
	public static function binarySearchCmp<T>(v:Container<T>, x:T, min:Int, max:Int, cmp:T->T->Int):Int
	{
		assert(v != null);
		assert(cmp != null);
		assert(min >= 0 && min < size(v));
		assert(max < size(v));
		
		var l = min, m, h = max + 1;
		while (l < h)
		{
			m = l + ((h - l) >> 1);
			if (cmp(get(v, m), x) < 0)
				l = m + 1;
			else
				h = m;
		}
		
		if ((l <= max) && cmp(get(v, l), x) == 0)
			return l;
		else
			return ~l;
	}
	
	public static function binarySearchf(v:Container<Float>, x:Float, min:Int, max:Int):Int
	{
		assert(v != null);
		assert(min >= 0 && min < size(v));
		assert(max < size(v));
		
		var l = min, m, h = max + 1;
		while (l < h)
		{
			m = l + ((h - l) >> 1);
			if (get(v, m) < x)
				l = m + 1;
			else
				h = m;
		}
		
		if ((l <= max) && (get(v, l) == x))
			return l;
		else
			return ~l;
	}
	
	public static function binarySearchi(v:Container<Int>, x:Int, min:Int, max:Int):Int
	{
		assert(v != null);
		assert(min >= 0 && min < size(v));
		assert(max < size(v));
		
		var l = min, m, h = max + 1;
		while (l < h)
		{
			m = l + ((h - l) >> 1);
			if (get(v, m) < x)
				l = m + 1;
			else
				h = m;
		}
		
		if ((l <= max) && (get(v, l) == x))
			return l;
		else
			return ~l;
	}
}