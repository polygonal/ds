/*
Copyright (c) 2008-2016 Michael Baczynski, http://www.polygonal.de

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

import de.polygonal.ds.tools.Assert.assert;
import de.polygonal.ds.NativeArray;
import de.polygonal.ds.tools.GrowthRate;
import de.polygonal.ds.tools.M;

using de.polygonal.ds.tools.NativeArrayTools;

/**
	A growable, dense vector whose length can change over time.
**/
#if generic
@:generic
#end
class ArrayList<T> implements List<T>
{
	/**
		A unique identifier for this object.
		
		A hash table transforms this key into an index of an array element by using a hash function.
		
		<warn>This value should never be changed by the user.</warn>
	**/
	public var key(default, null):Int = HashKey.next();
	
	/**
		The capacity of the internal container.
		
		The capacity is usually a bit larger than `size` (_mild overallocation_).
	**/
	public var capacity(default, null):Int;
	
	/**
		The growth rate of the container.
		
		+  0: fixed size
		+ -1: grows at a rate of 1.125x plus a constant.
		+ -2: grows at a rate of 1.5x (default value).
		+ -3: grows at a rate of 2.0x.
		+ >0: grows at a constant rate: capacity += growthRate
	**/
	public var growthRate:Int = GrowthRate.NORMAL;
	
	/**
		If true, reuses the iterator object instead of allocating a new one when calling `iterator()`.
		
		The default is false.
		
		<warn>If true, nested iterations are likely to fail as only one iteration is allowed at a time.</warn>
	**/
	public var reuseIterator:Bool = false;
	
	var mData:NativeArray<T>;
	var mInitialCapacity:Int;
	var mSize:Int = 0;
	var mIterator:ArrayListIterator<T> = null;
	
	/**
		<assert>invalid `capacityIncrement`</assert>
		
		@param allowShrink if true, the internal container gets halved when `size` falls below ¼ of the current `capacity`.
		Default is false.
		
		@param capacityIncrement if defined, the vector's storage increases in chunks the size of `capacityIncrement`.
		If omitted, the vector uses a growth factor of 1.5 resulting in a mild overallocation.
		In either case, `capacity` is usually larger than `size` to minimize the amount of incremental reallocation.
	**/
	public function new(initalCapacity:Null<Int> = 2, ?source:Array<T>)
	{
		mInitialCapacity = M.max(2, initalCapacity);
		
		if (source != null && source.length > 0)
		{
			mSize = source.length;
			mData = source.ofArray();
			capacity = size;
		}
		else
		{
			capacity = mInitialCapacity;
			mData = NativeArrayTools.alloc(capacity);
		}
	}
	
	/**
		Returns the element stored at index `i`.
		
		<assert>`i` out of range</assert>
	**/
	public inline function get(i:Int):T
	{
		assert(i >= 0 && i < size, 'index $i out of range ${size - 1}');
		
		return mData.get(i);
	}
	
	/**
		Replaces the element at index `i` with the element `x`.
		
		<assert>`i` out of range</assert>
	**/
	public inline function set(i:Int, x:T)
	{
		assert(i >= 0 && i < size, 'index $i out of range $size');
		
		mData.set(i, x);
	}
	
	public function add(val:T)
	{
		pushBack(val);
	}
	
	/**
		Adds `x` to the end of this vector and returns the new size.
	**/
	public inline function pushBack(x:T):Int
	{
		if (size == capacity) grow();
		mData.set(mSize++, x);
		return size;
	}
	
	/**
		Faster than `pushBack()`, but skips boundary checking.
		
		The user is responsible for making sure that there is enough space available (e.g. by calling `reserve()`).
	**/
	public inline function unsafePushBack(x:T):Int
	{
		assert(mSize < capacity, "out of space");
		
		mData.set(mSize++, x);
		return size;
	}
	
	/**
		Removes the last element from this vector and returns that element.
	**/
	public inline function popBack():T
	{
		assert(size > 0);
		
		return mData.get(--mSize);
	}
	
	/**
		Removes and returns the first element.
		
		To fill the gap, any subsequent elements are shifted to the left (indices - 1).
		<assert>vector is empty</assert>
	**/
	public function popFront():T
	{
		assert(size > 0, 'vector is empty');
		
		var d = mData;
		var x = d.get(0);
		if (--mSize == 0) return x;
		
		#if (neko || java || cs || cpp)
		d.blit(1, d, 0, size);
		#else
		for (i in 0...size) d.set(i, d.get(i + 1));
		#end
		return x;
	}
	
	/**
		Prepends the element `x` to the first element und returns the new size
		
		Shifts the first element (if any) and any subsequent elements to the right (indices + 1).
	**/
	public function pushFront(x:T):Int
	{
		if (size == 0)
		{
			mData.set(0, x);
			return ++mSize;
		}
		
		if (size == capacity) grow();
		
		#if (neko || java || cs || cpp)
		mData.blit(0, mData, 1, size);
		mData.set(0, x);
		#else
		var d = mData;
		var i = size;
		while (i > 0)
		{
			d.set(i, d.get(i - 1));
			i--;
		}
		d.set(0, x);
		#end
		return ++mSize;
	}
	
	/**
		Returns the first element.
		
		This is the element at index 0.
		<assert>vector is empty</assert>
	**/
	public inline function front():T
	{
		assert(size > 0, "vector is empty");
		
		return mData.get(0);
	}
	
	/**
		Returns the last element.
		
		This is the element at index `size` - 1.
		<assert>vector is empty</assert>
	**/
	public inline function back():T
	{
		assert(size > 0, "vector is empty");
		
		return mData.get(size - 1);
	}
	
	/**
		Swaps the element stored at index `i` with the element stored at index `j`.
		<assert>`i`/`j` out of range or `i` equals `j`</assert>
	**/
	#if !cpp inline #end //TODO fixme
	public function swap(i:Int, j:Int):ArrayList<T>
	{
		assert(i != j, 'index i equals index j ($i)');
		assert(i >= 0 && i <= size, 'index i=$i out of range $size');
		assert(j >= 0 && j <= size, 'index j=$j out of range $size');
		
		var d = mData;
		var t = d.get(i);
		d.set(i, d.get(j));
		d.set(j, t);
		return this;
	}
	
	/**
		Replaces the element at index `dst` with the element stored at index `src`.
		<assert>`i`/`j` out of range or `i` == `j`</assert>
	**/
	#if !cpp inline #end //TODO fixme
	public function copy(src:Int, dst:Int):ArrayList<T>
	{
		assert(src != dst, 'src index equals dst index ($src)');
		assert(src >= 0 && src <= size, 'index src=$src out of range $size');
		assert(dst >= 0 && dst <= size, 'index dst=$dst out of range $size');
		
		var d = mData;
		d.set(dst, d.get(src));
		return this;
	}
	
	/**
		Returns true if the index `i` is valid for reading a value.
	**/
	public inline function inRange(i:Int):Bool
	{
		return i >= 0 && i < size;
	}
	
	/**
		Inserts `x` at the specified index `i`.
		
		Shifts the element currently at that position (if any) and any subsequent elements to the right (indices + 1).
		<assert>`i` out of range</assert>
	**/
	public function insert(i:Int, x:T)
	{
		assert(i >= 0 && i <= size, 'index $i out of range $size');
		
		if (size == capacity) grow();
		#if (neko || java || cs || cpp)
		var srcPos = i;
		var dstPos = i + 1;
		mData.blit(srcPos, mData, dstPos, size - i);
		mData.set(i, x);
		#else
		var d = mData;
		var p = size;
		while (p > i) d.set(p--, d.get(p));
		d.set(i, x);
		#end
		mSize++;
	}
	
	/**
		Removes the element at the specified index `i`.
		Shifts any subsequent elements to the left (indices - 1).
		<assert>`i` out of range</assert>
	**/
	public function removeAt(i:Int):T
	{
		assert(i >= 0 && i < size, 'index $i out of range ${size - 1}');
		
		var d = mData;
		var x = d.get(i);
		#if (neko || java || cs || cpp)
		d.blit(i + 1, d, i, --mSize - i);
		#else
		var k = --mSize;
		var p = i;
		while (p < k) d.set(p++, d.get(p));
		#end
		return x;
	}
	
	/**
		Fast removal of the element at index `i` if the order of the elements doesn't matter.
		@return the element at index `i` prior removal.
		<assert>`i` out of range</assert>
	**/
	#if !cpp inline #end //TODO fixme
	public function swapPop(i:Int):T
	{
		assert(i >= 0 && i < size, 'index $i out of range ${size}');
		
		var d = mData;
		var x = d.get(i);
		d.set(i, d.get(--mSize));
		return x;
	}
	
	/**
		Calls the `f` function on all elements.
		
		The function signature is: `f(element, index):element`
		<assert>`f` is null</assert>
	**/
	public function forEach(f:T->Int->T):ArrayList<T>
	{
		assert(f != null);
		
		var d = mData;
		for (i in 0...size) d.set(i, f(d.get(0), i));
		return this;
	}
	
	/**
		Cuts of `size` - `n` elements.
		
		This only modifies the value of `size` and does not perform reallocation.
		<assert>`n` > `size`</assert>
	**/
	public function trim(n:Int):ArrayList<T>
	{
		assert(n <= size, 'new size ($n) > current size ($size)');
		
		mSize = n;
		return this;
	}
	
	/**
		Converts the data in this dense array to strings, inserts `sep` between the elements, concatenates them, and returns the resulting string.
	**/
	public function join(sep:String):String
	{
		if (size == 0) return "";
		
		#if (flash || cpp)
		var t = NativeArrayTools.alloc(size);
		mData.blit(0, t, 0, size);
		return t.join(sep);
		#else
		var k = size;
		if (k == 0) return "";
		if (k == 1) return Std.string(front());
		var b = new StringBuf(), d = mData;
		b.add(Std.string(front()) + sep);
		for (i in 1...k - 1)
		{
			b.add(Std.string(d.get(i)));
			b.add(sep);
		}
		b.add(Std.string(d.get(k - 1)));
		return b.toString();
		#end
	}
	
	/**
		Finds the first occurrence of the element `x` by using the binary search algorithm assuming elements are sorted.
		<assert>`from` out of range</assert>
		@param from the index to start from. The default value is 0.
		@param cmp a comparison function for the binary search. If omitted, the method assumes that all elements implement `Comparable`.
		@return the index storing the element `x` or the bitwise complement (~) of the index where the `x` would be inserted (guaranteed to be a negative number).
		<warn>The insertion point is only valid if `from`=0.</warn>
	**/
	public function binarySearch(x:T, from:Int, ?cmp:T->T->Int):Int
	{
		assert(from >= 0 && from <= size, 'from index out of range ($from)');
		
		if (size == 0) return -1;
		
		if (cmp != null) return mData.binarySearchCmp(x, from, size - 1, cmp);
		
		assert(Std.is(x, Comparable), "element is not of type Comparable");
		
		var k = size;
		var l = from, m, h = k, d = mData;
		while (l < h)
		{
			m = l + ((h - l) >> 1);
			
			assert(Std.is(d.get(m), Comparable), "element is not of type Comparable");
			
			if (cast(d.get(m), Comparable<Dynamic>).compare(x) < 0)
				l = m + 1;
			else
				h = m;
		}
		
		assert(Std.is(d.get(l), Comparable), "element is not of type Comparable");
		
		return ((l <= k) && (cast(d.get(l), Comparable<Dynamic>).compare(x)) == 0) ? l : -l;
	}
	
	/**
		Finds the first occurrence of the element `x` (by incrementing indices - from left to right).
		<assert>`from` out of range</assert>
		@return the index storing the element `x` or -1 if `x` was not found.
	**/
	@:access(de.polygonal.ds.ArrayList)
	public function indexOf(x:T):Int
	{
		if (size == 0) return -1;
		var i = 0, j = -1, k = size - 1, d = mData;
		do
		{
			if (d.get(i) == x)
			{
				j = i;
				break;
			}
		}
		while (i++ < k);
		return j;
	}
	
	/**
		Finds the first occurrence of `x` (by decrementing indices - from right to left) and returns the index storing the element `x` or -1 if `x` was not found.
		<assert>`from` out of range</assert>
		@param from the index to start from. By default, the method starts from the last element in this dense array.
	**/
	public function lastIndexOf(x:T, from:Int = -1):Int
	{
		if (size == 0) return -1;
		
		if (from < 0) from = size + from;
		
		assert(from >= 0 && from < size, 'from index out of range ($from)');
		
		var j = -1;
		var i = from;
		var d = mData;
		do
		{
			if (d.get(i) == x)
			{
				j = i;
				break;
			}
		}
		while (i-- > 0);
		return j;
	}
	
	/**
		Concatenates this array with `x` by appending all elements of `x` to this array.
		<assert>`x` is null</assert>
		<assert>`x` equals this if `copy`=false</assert>
		@param copy if true, returns a new array instead of modifying this array.
	**/
	public function concat(x:ArrayList<T>, copy:Bool = false):ArrayList<T>
	{
		assert(x != null);
		
		if (copy)
		{
			var sum = size + x.size;
			var out = new ArrayList<T>(sum);
			out.mSize = sum;
			mData.blit(0, out.mData, 0, size);
			x.mData.blit(0, out.mData, size, x.size);
			return out;
		}
		else
		{
			assert(x != this, "x equals this");
			
			var sum = size + x.size;
			reserve(sum);
			x.mData.blit(0, mData, size, x.size);
			mSize = sum;
			return this;
		}
	}
	
	/**
		Reverses this vector in place in the range [`first, `last`] (the first element becomes the last and the last becomes the first).
		
		<assert>`first` >= `last`</assert>
		<assert>`first`/`last` out of range</assert>
	**/
	public function reverse(first:Int = -1, last:Int = -1)
	{
		if (first == -1 || last == -1)
		{
			first = 0;
			last = size;
		}
		
		assert(last - first > 0);
		
		var k = last - first;
		if (k <= 1) return;
		
		var t, u, v, d = mData;
		for (i in 0...k >> 1)
		{
			u = first + i;
			v = last - i - 1;
			t = d.get(u);
			d.set(u, d.get(v));
			d.set(v, t);
		}
	}
	
	/**
		Copies `n` elements from the location pointed by the index `source` to the location pointed by the index `destination`.
		
		Copying takes place as if an intermediate buffer was used, allowing the destination and source to overlap.
		
		See <a href="http://www.cplusplus.com/reference/clibrary/cstring/memmove/" target="mBlank">http://www.cplusplus.com/reference/clibrary/cstring/memmove/</a>
		<assert>invalid `destination`, `source` or `n` value</assert>
	**/
	public function memmove(destination:Int, source:Int, n:Int)
	{
		assert(destination >= 0 && source >= 0 && n >= 0);
		assert(source < size);
		assert(destination + n <= size);
		assert(n <= size);
		
		mData.blit(source, mData, destination, n);
	}
	
	/**
		Sorts the elements of this dense array using the quick sort algorithm.
		<assert>element does not implement `Comparable`</assert>
		<assert>`first` or `count` out of range</assert>
		@param cmp a comparison function.If null, the elements are compared using `element::compare()`.
		<warn>In this case all elements have to implement `Comparable`.</warn>
		@param useInsertionSort if true, the dense array is sorted using the insertion sort algorithm. This is faster for nearly sorted lists.
		@param first sort start index. The default value is 0.
		@param count the number of elements to sort (range: [`first`, `first` + `count`]).
		If omitted, `count` is set to the remaining elements (`size` - `first`).
	**/
	public function sort(?cmp:T->T->Int, useInsertionSort:Bool = false, first:Int = 0, count:Int = -1)
	{
		if (size > 1)
		{
			if (count == -1) count = size - first;
			
			assert(first >= 0 && first <= size - 1 && first + count <= size, "first index out of range");
			assert(count >= 0 && count <= size, "count out of range");
			
			if (cmp == null)
				useInsertionSort ? insertionSortComparable(first, count) : quickSortComparable(first, count);
			else
			{
				if (useInsertionSort)
					insertionSort(first, count, cmp);
				else
					quickSort(first, count, cmp);
			}
		}
	}
	
	public function shuffle(?rvals:Array<Float>)
	{
		var s = size, d = mData;
		
		if (rvals == null)
		{
			var m = Math;
			while (--s > 1)
			{
				var i = Std.int(m.random() * s);
				var t = d.get(s);
				d.set(s, d.get(i));
				d.set(i, t);
			}
		}
		else
		{
			assert(rvals.length >= size, "insufficient random values");
			
			var j = 0;
			while (--s > 1)
			{
				var i = Std.int(rvals[j++] * s);
				var t = d.get(s);
				d.set(s, d.get(i));
				d.set(i, t);
			}
		}
	}
	
	/**
		Returns a string representing the current object.
		
		Example:
		<pre class="prettyprint">
		var dv = new de.polygonal.ds.ArrayList<Int>();
		for (i in 0...3) {
		    dv.set(i, i);
		}
		trace(dv);</pre>
		<pre class="console">
		{ Dv size/capacity: 3/16 }
		[
		  0 -> 0
		  1 -> 1
		  2 -> 2
		]</pre>
	**/
	public function toString():String
	{
		var b = new StringBuf();
		b.add('{ Dv size/capacity: $size/$capacity} }');
		if (isEmpty()) return b.toString();
		b.add("\n[\n");
		var d = mData, fmt = "  %4d -> %s\n", args = new Array<Dynamic>();
		for (i in 0...size)
		{
			args[0] = i;
			args[1] = Std.string(d.get(i));
			b.add(Printf.format(fmt, args));
		}
		b.add("]");
		return b.toString();
	}
	
	function quickSort(first:Int, k:Int, cmp:T->T->Int)
	{
		var last = first + k - 1, lo = first, hi = last, d = mData;
		
		var i0, i1, i2, mid, t;
		var t0, t1, t2, pivot;
		
		if (k > 1)
		{
			i0 = first;
			i1 = i0 + (k >> 1);
			i2 = i0 + k - 1;
			t0 = d.get(i0);
			t1 = d.get(i1);
			t2 = d.get(i2);
			t = cmp(t0, t2);
			if (t < 0 && cmp(t0, t1) < 0)
				mid = cmp(t1, t2) < 0 ? i1 : i2;
			else
			{
				if (cmp(t1, t0) < 0 && cmp(t1, t2) < 0)
					mid = t < 0 ? i0 : i2;
				else
					mid = cmp(t2, t0) < 0 ? i1 : i0;
			}
			
			pivot = d.get(mid);
			d.set(mid, d.get(first));
			
			while (lo < hi)
			{
				while (cmp(pivot, d.get(hi)) < 0 && lo < hi) hi--;
				if (hi != lo)
				{
					d.set(lo, d.get(hi));
					lo++;
				}
				while (cmp(pivot, d.get(lo)) > 0 && lo < hi) lo++;
				if (hi != lo)
				{
					d.set(hi, d.get(lo));
					hi--;
				}
			}
			
			d.set(lo, pivot);
			quickSort(first, lo - first, cmp);
			quickSort(lo + 1, last - lo, cmp);
		}
	}
	
	function quickSortComparable(first:Int, k:Int)
	{
		var d = mData;
		
		#if debug
		for (i in first...first + k)
			assert(Std.is(d.get(i), Comparable), "element is not of type Comparable");
		#end
		
		var last = first + k - 1, lo = first, hi = last, d = mData;
		
		var i0, i1, i2, mid, t;
		var t0, t1, t2, pivot;
		
		if (k > 1)
		{
			i0 = first;
			i1 = i0 + (k >> 1);
			i2 = i0 + k - 1;
			
			t0 = cast(d.get(i0), Comparable<Dynamic>);
			t1 = cast(d.get(i1), Comparable<Dynamic>);
			t2 = cast(d.get(i2), Comparable<Dynamic>);
			
			t = t0.compare(t2);
			if (t < 0 && t0.compare(t1) < 0)
				mid = t1.compare(t2) < 0 ? i1 : i2;
			else
			{
				if (t1.compare(t0) < 0 && t1.compare(t2) < 0)
					mid = t < 0 ? i0 : i2;
				else
					mid = t2.compare(t0) < 0 ? i1 : i0;
			}
			
			pivot = cast(d.get(mid), Comparable<Dynamic>);
			d.set(mid, d.get(first));
			
			while (lo < hi)
			{
				while (pivot.compare(cast d.get(hi)) < 0 && lo < hi) hi--;
				if (hi != lo)
				{
					d.set(lo, d.get(hi));
					lo++;
				}
				while (pivot.compare(cast d.get(lo)) > 0 && lo < hi) lo++;
				if (hi != lo)
				{
					d.set(hi, d.get(lo));
					hi--;
				}
			}
			
			#if cpp
			var t:Dynamic = cast pivot; //TODO fixme
			d.set(lo, t);
			#else
			d.set(lo, cast pivot);
			#end
			
			quickSortComparable(first, lo - first);
			quickSortComparable(lo + 1, last - lo);
		}
	}
	
	function insertionSort(first:Int, k:Int, cmp:T->T->Int)
	{
		var j, a, b, d = mData;
		for (i in first + 1...first + k)
		{
			a = d.get(i);
			j = i;
			while (j > first)
			{
				b = d.get(j - 1);
				if (cmp(b, a) > 0)
				{
					d.set(j, b);
					j--;
				}
				else
					break;
			}
			d.set(j, a);
		}
	}
	
	function insertionSortComparable(first:Int, k:Int)
	{
		var d = mData;
		
		#if debug
		for (i in first...first + k)
			assert(Std.is(d.get(i), Comparable), "element is not of type Comparable");
		#end
		
		var j, a, b, u, v;
		for (i in first + 1...first + k)
		{
			a = d.get(i);
			u = cast(a, Comparable<Dynamic>);
			
			j = i;
			while (j > first)
			{
				b = d.get(j - 1);
				v = cast(b, Comparable<Dynamic>);
				
				if (u.compare(v) > 0)
				{
					d.set(j, b);
					j--;
				}
				else
					break;
			}
			d.set(j, a);
		}
	}
	
	/**
		Preallocates storage for `n` elements.
		
		May cause a reallocation, but has no effect on the vector size and its elements.
		Useful before inserting a large number of elements as this reduces the amount of incremental reallocation.
	**/
	public function reserve(n:Int):ArrayList<T>
	{
		if (n > capacity)
		{
			capacity = n;
			resizeContainer(n);
		}
		return this;
	}
	
	/**
		Sets `n` elements starting at index `first` to the value `x`.
		
		Automatically reserves storage for `n` elements so an additional call to `reserve()` is not required.
		<assert>invalid element count</assert>
	**/
	public function init(n:Int, x:T):ArrayList<T>
	{
		reserve(n);
		mSize = n;
		var d = mData;
		for (i in 0...n) d.set(i, x);
		return this;
	}
	
	/**
		Reduces the capacity of the internal container to the initial capacity.
		
		May cause a reallocation, but has no effect on the vector size and its elements.
		An application can use this operation to free up memory by GC'ing used resources.
	**/
	public function pack():ArrayList<T>
	{
		if (capacity > mInitialCapacity)
		{
			capacity = M.max(mInitialCapacity, mSize);
			resizeContainer(capacity);
		}
		else
		{
			var d = mData;
			for (i in mSize...capacity) d.set(i, cast null);
		}
		return this;
	}
	
	public function getRange(fromIndex:Int, toIndex:Int):List<T>
	{
		assert(fromIndex >= 0 && fromIndex < size, "fromIndex out of range");
		#if debug
		if (toIndex >= 0)
		{
			assert(toIndex >= 0 && toIndex < size, "toIndex out of range");
			assert(fromIndex <= toIndex);
		}
		else
			assert(fromIndex - toIndex <= size, "toIndex out of range");
		#end
		
		var n = toIndex > 0 ? (toIndex - fromIndex) : ((fromIndex - toIndex) - fromIndex);
		var out = new ArrayList<T>(n);
		if (n == 0) return out;
		out.mSize = n;
		mData.blit(fromIndex, out.mData, 0, n);
		return out;
	}
	
	public function getData():NativeArray<T>
	{
		return mData;
	}
	
	function grow()
	{
		capacity = GrowthRate.compute(growthRate, capacity);
		resizeContainer(capacity);
	}
	
	function resizeContainer(newSize:Int)
	{
		var t = NativeArrayTools.alloc(newSize);
		mData.blit(0, t, 0, mSize);
		mData = t;
	}
	
	/* INTERFACE Collection */
	
	/**
		The total number of elements stored in this vector.
	**/
	public var size(get, never):Int;
	inline function get_size():Int
	{
		return mSize;
	}
	
	/**
		Destroys this object by explicitly nullifying all elements for GC'ing used resources.
		
		Improves GC efficiency/performance (optional).
	**/
	public function free()
	{
		mData.nullify();
		mData = null;
		if (mIterator != null)
		{
			mIterator.free();
			mIterator = null;
		}
	}
	
	/**
		Returns true if this vector contains the element `x`.
	**/
	public function contains(x:T):Bool
	{
		var d = mData;
		for (i in 0...size)
		{
			if (d.get(i) == x)
				return true;
		}
		return false;
	}
	
	/**
		Removes all occurrences of `x`.
		Shifts any subsequent elements to the left (indices - 1).
		@return true if at least one occurrence of `x` was removed.
	**/
	public function remove(x:T):Bool
	{
		if (isEmpty()) return false;
		
		var i = 0;
		var s = size;
		var d = mData;
		while (i < s)
		{
			if (d.get(i) == x)
			{
				//TODO optimize
				//#if (neko || java || cs || cpp)
				//d.blit(i + 1, d, i, s - i);
				//s--;
				//#else
				s--;
				var p = i;
				while (p < s)
				{
					d.set(p, d.get(p + 1));
					++p;
				}
				//#end
				continue;
			}
			i++;
		}
		
		var found = (size - s) != 0;
		mSize = s;
		return found;
	}
	
	/**
		Clears this vector by nullifying all elements so the garbage collector can reclaim used memory.
	**/
	public function clear(gc:Bool = false)
	{
		if (gc) mData.nullify();
		mSize = 0;
	}
	
	/**
		Returns a new `Array2Iterator` object to iterate over all elements contained in this vector.
		
		Order: Row-major order (row-by-row).
		
		See <a href="http://haxe.org/ref/iterators" target="mBlank">http://haxe.org/ref/iterators</a>
	**/
	public function iterator():Itr<T>
	{
		if (reuseIterator)
		{
			if (mIterator == null)
				mIterator = new ArrayListIterator<T>(this);
			else
				mIterator.reset();
			return mIterator;
		}
		else
			return new ArrayListIterator<T>(this);
	}
	
	public function isEmpty():Bool
	{
		return size == 0;
	}
	
	/**
		Returns an array containing all elements in this vector.
		
		Preserves the natural order of this array.
	**/
	public function toArray():Array<T>
	{
		return mData.toArray(0, size);
	}
	
	/**
		Duplicates this dense array. Supports shallow (structure only) and deep copies (structure & elements).
		<assert>element is not of type `Cloneable`</assert>
		@param assign if true, the `copier` parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.
		If false, the `clone()` method is called on each element. <warn>In this case all elements have to implement `Cloneable`.</warn>
		@param copier a custom function for copying elements. Replaces `element::clone()` if `assign` is false.
	**/
	public function clone(assign:Bool = true, copier:T->T = null):Collection<T>
	{
		var out = new ArrayList<T>(capacity);
		out.mSize = size;
		var src = mData;
		var dst = out.mData;
		if (assign)
			src.blit(0, dst, 0, size);
		else
		if (copier == null)
		{
			for (i in 0...size)
			{
				assert(Std.is(src.get(i), Cloneable), "element is not of type Cloneable");
				
				dst.set(i, cast(src.get(i), Cloneable<Dynamic>).clone());
			}
		}
		else
		{
			for (i in 0...size)
				dst.set(i, copier(src.get(i)));
		}
		return cast out;
	}
}

#if generic
@:generic
#end
@:access(de.polygonal.ds.ArrayList)
@:dox(hide)
class ArrayListIterator<T> implements de.polygonal.ds.Itr<T>
{
	var mObject:ArrayList<T>;
	var mData:NativeArray<T>;
	var mI:Int;
	var mS:Int;
	
	public function new(x:ArrayList<T>)
	{
		mObject = x;
		reset();
	}
	
	public function free()
	{
		mObject = null;
		mData = null;
	}
	
	public inline function reset():Itr<T>
	{
		mData = mObject.mData;
		mS = mObject.size;
		mI = 0;
		return this;
	}
	
	public inline function hasNext():Bool
	{
		return mI < mS;
	}
	
	public inline function next():T
	{
		return mData.get(mI++);
	}
	
	public function remove()
	{
		assert(mI > 0, "call next() before removing an element");
		
		mObject.removeAt(--mI);
		mS--;
	}
}