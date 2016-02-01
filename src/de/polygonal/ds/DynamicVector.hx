/*
Copyright (c) 2014 Michael Baczynski, http://www.polygonal.de

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
import de.polygonal.ds.Container;

using de.polygonal.ds.tools.NativeArray;

/**
	A growable, dense vector whose length can change over time.
**/
#if generic
@:generic
#end
class DynamicVector<T> implements Collection<T>
{
	/**
		A unique identifier for this object.
		
		A hash table transforms this key into an index of an array element by using a hash function.
		
		<warn>This value should never be changed by the user.</warn>
	**/
	public var key(default, null):Int;
	
	/**
		The total number of elements stored in this vector.
	**/
	
	/**
		The capacity of the internal container.
		
		The capacity is usually a bit larger than `size` (_mild overallocation_).
	**/
	public var capacity(default, null):Int;
	
	/**
		If true, reuses the iterator object instead of allocating a new one when calling `iterator()`.
		
		The default is false.
		
		<warn>If true, nested iterations are likely to fail as only one iteration is allowed at a time.</warn>
	**/
	public var reuseIterator:Bool;
	
	var mData:Container<T>;
	var mSize:Int;
	var mCapacityIncrement:Int;
	var mShrinkSize:Int;
	var mIterator:DynamicVectorIterator<T>;
	
	var mAllowShrink:Bool;
	
	/**
		<assert>invalid `capacityIncrement`</assert>
		
		@param allowShrink if true, the internal container gets halved when `size` falls below ¼ of the current `capacity`.
		Default is false.
		
		@param capacityIncrement if defined, the vector's storage increases in chunks the size of `capacityIncrement`.
		If omitted, the vector uses a growth factor of 1.5 resulting in a mild overallocation.
		In either case, `capacity` is usually larger than `size` to minimize the amount of incremental reallocation.
	**/
	//TODO initialCapacity
	public function new(initalCapacity:Int = 16, ?capacityIncrement:Null<Int> = -1, ?source:Array<T>)
	{
		#if debug
		if (capacityIncrement != -1)
			assert(capacityIncrement >= 0);
		#end
		
		key = HashKey.next();
		reuseIterator = false;
		
		mCapacityIncrement = capacityIncrement;
		
		if (source != null)
		{
			//TODO use fromArrayCopy
			
			mSize = source.length;
			mData = NativeArray.init(mSize);
			
			#if (cpp || java || cs)
			NativeArray.blit(source, 0, mData, 0, mSize);
			#else
			for (i in 0...mSize) mData.set(i, source[i]);
			#end
			
			capacity = mSize;
		}
		else
		{
			mSize = 0;
			mData = NativeArray.init(16);
			capacity = 16;
		}
		
		mShrinkSize = capacity >> 2;
	}
	
	/**
		Returns the element stored at index `i`.
		
		<assert>`i` out of range</assert>
	**/
	inline public function get(i:Int):T
	{
		assert(i >= 0 && i < mSize, 'the index $i is out of range ${mSize - 1}');
		
		return mData.get(i);
	}
	
	/**
		Replaces the element at index `i` with the element `x`.
		
		<assert>`i` out of range</assert>
	**/
	inline public function set(i:Int, x:T)
	{
		assert(i >= 0 && i <= mSize, 'the index $i is out of range $mSize');
		
		if (i == capacity) grow();
		if (i >= mSize) mSize++;
		mData.set(i, x);
	}
	
	/**
		Adds `x` to the end of this vector and returns the new size.
	**/
	inline public function pushBack(x:T):Int
	{
		if (mSize == capacity) grow();
		mData[mSize++] = x;
		
		return mSize;
	}
	
	/**
		Removes the last element from this vector and returns that element.
	**/
	inline public function popBack():T
	{
		assert(mSize > 0);
		
		var val = mData[--mSize];
		if (mAllowShrink && mSize == mShrinkSize) shrink();
		
		return val;
	}
	
	/**
		Removes and returns the first element.
		
		To fill the gap, any subsequent elements are shifted to the left (indices - 1).
		<o>n</o>
		<assert>vector is empty</assert>
	**/
	public function popFront():T
	{
		assert(mSize > 0, 'vector is empty');
		
		var d = mData;
		var x = d.get(0);
		
		if (--mSize == 0) return x;
		
		#if (neko || java || cs || cpp)
		NativeArray.blit(d, 1, d, 0, mSize);
		#else
		for (i in 0...mSize) d.set(i, d.get(i + 1));
		#end
		
		if (mAllowShrink && mSize == mShrinkSize) shrink();
		
		return x;
	}
	
	/**
		Prepends the element `x` to the first element und returns the new size
		
		Shifts the first element (if any) and any subsequent elements to the right (indices + 1).
		<o>n</o>
	**/
	public function pushFront(x:T):Int
	{
		var d = mData;
		
		if (mSize == 0)
		{
			d.set(0, x);
			return ++mSize;
		}
		
		if (mSize == capacity) grow();
		
		#if (neko || java || cs || cpp)
		NativeArray.blit(d, 0, d, 1, mSize);
		#else
		var i = mSize;
		while (i > -1)
		{
			d.set(i + 1, d.get(i));
			i--;
		}
		#end
		
		d.set(0, x);
		return ++mSize;
	}
	
	/**
		Returns the first element.
		
		This is the element at index 0.
		<o>1</o>
		<assert>vector is empty</assert>
	**/
	inline public function front():T
	{
		assert(mSize > 0, "vector is empty");
		
		return mData.get(0);
	}
	
	/**
		Returns the last element.
		
		This is the element at index `size` - 1.
		<o>1</o>
		<assert>vector is empty</assert>
	**/
	inline public function back():T
	{
		assert(mSize > 0, "vector is empty");
		
		return mData.get(mSize - 1);
	}
	
	/**
		Swaps the element stored at index `i` with the element stored at index `j`.
		<assert>`i`/`j` out of range or `i` equals `j`</assert>
	**/
	inline public function swap(i:Int, j:Int)
	{
		assert(i != j, 'index i equals index j ($i)');
		assert(i >= 0 && i <= mSize, 'the index i=$i is out of range $mSize');
		assert(j >= 0 && j <= mSize, 'the index j=$j is out of range $mSize');
		
		var d = mData;
		var t = d.get(i);
		d.set(i, d.get(j));
		d.set(j, t);
	}
	
	/**
		Replaces the element at index `dst` with the element stored at index `src`.
		<assert>`i`/`j` out of range or `i` == `j`</assert>
	**/
	inline public function copy(src:Int, dst:Int)
	{
		assert(src != dst, 'src index equals dst index ($src)');
		assert(src >= 0 && src <= mSize, 'the index src=$src is out of range $mSize');
		assert(dst >= 0 && dst <= mSize, 'the index dst=$dst is out of range $mSize');
		
		var d = mData;
		d.set(dst, d.get(src));
	}
	
	/**
		Inserts `x` at the specified index `i`.
		
		Shifts the element currently at that position (if any) and any subsequent elements to the right (indices + 1).
		<o>n</o>
		<assert>`i` out of range</assert>
	**/
	public function insertAt(i:Int, x:T)
	{
		assert(i >= 0 && i <= mSize, 'the index $i is out of range $mSize');
		
		if (mSize == capacity) grow();
		
		var d = mData;
		
		#if (neko || java || cs || cpp)
		var srcPos = i;
		var dstPos = i + 1;
		NativeArray.blit(d, srcPos, d, dstPos, mSize - i);
		#else
		var p = mSize;
		while (p > i) d.set(p--, d.get(p));
		#end
		
		d.set(i, x);
		
		mSize++;
	}
	
	/**
		Removes the element at the specified index `i`.
		
		Shifts any subsequent elements to the left (indices - 1).
		<o>n</o>
		<assert>`i` out of range</assert>
	**/
	public function removeAt(i:Int):T
	{
		assert(i >= 0 && i < mSize, 'the index $i is out of range ${mSize - 1}');
		
		var d = mData;
		var x = d.get(i);
		
		#if (neko || java || cs || cpp)
		NativeArray.blit(d, i + 1, d, i, mSize - i);
		--mSize;
		#else
		var k = --mSize;
		var p = i;
		while (p < k)
			d.set(p++, d.get(p));
		#end
		
		return x;
	}
	
	/**
		Fast removal of the element at index `i` if the order of the elements doesn't matter.
		@return the element at index `i` prior removal.
		<o>1</o>
		<assert>`i` out of range</assert>
	**/
	inline public function swapPop(i:Int):T
	{
		assert(i >= 0 && i < mSize, 'the index $i is out of range ${mSize}');
		
		var x = mData.get(i);
		mData.set(i, mData.get(--mSize));
		
		return x;
	}
	
	/**
		A reference to the inner vector storing all elements.
	**/
	inline public function getContainer():Container<T> //TODO return abstract with bounds checking
	{
		return mData;
	}
	
	/**
		Preallocates storage for `n` elements.
		
		May cause a reallocation, but has no effect on the vector size and its elements.
		Useful before inserting a large number of elements as this reduces the amount of incremental reallocation.
	**/
	public function reserve(n:Int):DynamicVector<T>
	{
		if (n <= capacity) return this;
		
		capacity = n;
		mShrinkSize = n >> 2;
		resize(n);
		
		return this;
	}
	
	/**
		Sets `n` elements starting at index `first` to the value `x`.
		Automatically reserves storage for `n` elements so an additional call to `reserve()` is not required.
		<assert>invalid element count</assert>
	**/
	public function alloc(n:Int = 0, x:T):DynamicVector<T>
	{
		assert(n >= 0, "invalid element count");
		
		reserve(n);
		
		var d = mData;
		for (i in 0...n) d.set(i, x);
		mSize = n;
		
		return this;
	}
	
	/**
		Sets `n` existing elements starting at `first` to the value `x`.
	**/
	public function init(first:Int, n:Int, x:T):DynamicVector<T>
	{
		assert(n <= mSize, "invalid element count");
		assert(first >= 0 && first <= mSize - n, 'the index first $first is out of range');
		
		var d = mData;
		for (i in first...first + n) d.set(i, x);
		
		return this;
	}
	
	public function iter(f:T->Int->T):DynamicVector<T>
	{
		var d = mData;
		for (i in 0...mSize) d.set(i, f(d.get(0), i));
		
		return this;
	}
	
	/**
		Cuts of `size` - `n` elements.
		
		This only modifies the value of `size` and does not perform reallocation.
		<assert>`n` > `size`</assert>
	**/
	public function trim(n:Int):DynamicVector<T>
	{
		assert(n <= mSize, 'new size ($n) > current size ($mSize)');
		
		mSize = n;
		return this;
	}
	
	/**
		Reduces the capacity of the internal container to `size`.
		
		May cause a reallocation, but has no effect on the vector size and its elements.
		
		An application can use this operation to free up memory by GC'ing used resources.
	**/
	public function pack():DynamicVector<T>
	{
		capacity = mSize;
		mShrinkSize = capacity >> 2;
		resize(mSize);
		
		return this;
	}
	
	/**
		Converts the data in this dense array to strings, inserts `sep` between the elements, concatenates them, and returns the resulting string.
		<o>n</o>
	**/
	public function join(sep:String):String
	{
		#if (flash || cpp)
		var tmp = NativeArray.init(mSize);
		NativeArray.blit(mData, 0, tmp, 0, mSize);
		return tmp.join(sep);
		#else
		var k = mSize;
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
		Finds the first occurrence of the element `x` (by incrementing indices - from left to right).
		<o>n</o>
		<assert>`from` out of range</assert>
		@param from the index to start from. The default value is 0.
		@param binarySearch use the binary search algorithm. Requires that the elements are sorted.
		@param cmp a comparison function for the binary search. If omitted, the method assumes that all elements implement `Comparable`.
		@return the index storing the element `x` or -1 if `x` was not found.
		If `binarySearch` is true, returns the index of `x` or the bitwise complement (~) of the index where the `x` would be inserted (guaranteed to be a negative number).
		<warn>The insertion point is only valid if`from`=0.</warn>
	**/
	@:access(de.polygonal.ds.DynamicVector)
	public function indexOf(x:T, from = 0, binarySearch = false, ?cmp:T->T->Int):Int
	{
		if (mSize == 0)
			return -1;
		else
		{
			assert(from >= 0 && from < mSize, 'from index out of range ($from)');
			
			if (binarySearch)
			{
				if (cmp != null)
					return NativeArray.binarySearchCmp(mData, x, from, mSize - 1, cmp);
				else
				{
					assert(Std.is(x, Comparable), 'element is not of type Comparable ($x)');
					
					var k = mSize;
					var l = from, m, h = k, d = mData;
					while (l < h)
					{
						m = l + ((h - l) >> 1);
						
						assert(Std.is(d.get(m), Comparable), 'element is not of type Comparable (${d.get(m)})');
						
						if (cast(d.get(m), Comparable<Dynamic>).compare(x) < 0)
							l = m + 1;
						else
							h = m;
					}
					
					assert(Std.is(d.get(l), Comparable), 'element is not of type Comparable (${d.get(l)})');
					
					return ((l <= k) && (cast(d.get(l), Comparable<Dynamic>).compare(x)) == 0) ? l : -l;
				}
			}
			else
			{
				var i = from, j = -1, k = mSize - 1, d = mData;
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
		} return 0;
	}
	
	/**
		Finds the first occurrence of `x` (by decrementing indices - from right to left) and returns the index storing the element `x` or -1 if `x` was not found.
		<o>n</o>
		<assert>`from` out of range</assert>
		@param from the index to start from. By default, the method starts from the last element in this dense array.
	**/
	public function lastIndexOf(x:T, from = -1):Int
	{
		if (mSize == 0)
			return -1;
		else
		{
			if (from < 0) from = mSize + from;
			
			assert(from >= 0 && from < mSize, 'from index out of range ($from)');
			
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
	}
	
	/**
		Concatenates this array with `x` by appending all elements of `x` to this array.
		<o>n</o>
		<assert>`x` is null</assert>
		<assert>`x` equals this if `copy`=false</assert>
		@param copy if true, returns a new array instead of modifying this array.
	**/
	public function concat(x:DynamicVector<T>, copy = false):DynamicVector<T>
	{
		assert(x != null);
		
		if (copy)
		{
			#if (neko || java || cs || cpp)
			var sum = mSize + x.mSize;
			
			var d = NativeArray.init(sum);
			NativeArray.blit(mData, 0, d, 0, mSize);
			NativeArray.blit(x.mData, 0, d, mSize, x.mSize);
			
			var c2:DynamicVector<T> = Type.createEmptyInstance(DynamicVector);
			c2.key = HashKey.next();
			c2.reuseIterator = false;
			c2.mData = d;
			c2.mCapacityIncrement = -1;
			c2.capacity = sum;
			c2.mShrinkSize = sum >> 2;
			c2.mAllowShrink = false;
			c2.mSize = sum;
			
			return c2;
			
			#else
			var c = new DynamicVector<T>();
			var s = mSize;
			var sum = s + x.mSize;
			c.mSize = sum;
			c.reserve(sum);
			var dst = c.mData, src;
			src = mData;
			for (i in 0...s) dst.set(i, src.get(i));
			src = x.mData;
			for (i in s...sum) dst.set(i, src.get(i - s));
			
			return c;
			#end
		}
		else
		{
			assert(x != this, "x equals this");
			
			#if (neko || java || cs || cpp)
			var sum = mSize + x.mSize;
			reserve(sum);
			NativeArray.blit(x.mData, 0, mData, mSize, x.mSize);
			mSize = sum;
			
			return this;
			
			#else
			reserve(mSize + x.mSize);
			var j = mSize;
			mSize += x.mSize;
			var dst = mData;
			var src = x.mData;
			for (i in 0...x.mSize) dst.set(j++, src.get(i));
			return this;
			#end
		}
	}
	
	/**
		Reverses this vector in place (the first element becomes the last and the last becomes the first).
		
		<assert>`start` >= `end`</assert>
		<assert>`start`/`end` out of range</assert>
	**/
	public function reverse(start:Int = -1, end:Int = -1)
	{
		if (start == -1 || end == -1)
		{
			start = 0;
			end = mSize;
		}
		
		assert(end - start > 0);
		
		var k = end - start;
		if (k <= 1) return;
		
		var t, u, v, d = mData;
		for (i in 0...k >> 1)
		{
			u = start + i;
			v = end - i - 1;
			t = d[u];
			d[u] = d[v];
			d[v] = t;
		}
	}
	
	/**
		Copies `n` elements from the location pointed by the index `source` to the location pointed by the index `destination`.
		
		Copying takes place as if an intermediate buffer was used, allowing the destination and source to overlap.
		
		See <a href="http://www.cplusplus.com/reference/clibrary/cstring/memmove/" target="mBlank">http://www.cplusplus.com/reference/clibrary/cstring/memmove/</a>
		<o>n</o>
		<assert>invalid `destination`, `source` or `n` value</assert>
	**/
	public function memmove(destination:Int, source:Int, n:Int)
	{
		assert(destination >= 0 && source >= 0 && n >= 0);
		assert(source < mSize);
		assert(destination + n <= mSize);
		assert(n <= mSize);
		
		NativeArray.blit(mData, source, mData, destination, n);
	}
	
	/**
		Sorts the elements of this dense array using the quick sort algorithm.
		<o>n&sup2;</o>
		<assert>element does not implement `Comparable`</assert>
		<assert>`first` or `count` out of bound</assert>
		@param compare a comparison function.If null, the elements are compared using `element::compare()`.
		<warn>In this case all elements have to implement `Comparable`.</warn>
		@param useInsertionSort if true, the dense array is sorted using the insertion sort algorithm. This is faster for nearly sorted lists.
		@param first sort start index. The default value is 0.
		@param count the number of elements to sort (range: [`first`, `first` + `count`]).
		If omitted, `count` is set to the remaining elements (`size` - `first`).
	**/
	public function sort(compare:T->T->Int, useInsertionSort = false, first = 0, count = -1)
	{
		if (mSize > 1)
		{
			if (count == -1) count = mSize - first;
			
			assert(first >= 0 && first <= mSize - 1 && first + count <= mSize, "first index out of bound");
			assert(count >= 0 && count <= mSize, "count out of bound");
			
			if (compare == null)
				useInsertionSort ? insertionSortComparable(first, count) : quickSortComparable(first, count);
			else
			{
				if (useInsertionSort)
					insertionSort(first, count, compare);
				else
					quickSort(first, count, compare);
			}
		}
	}
	
	public function shuffle(?rvals:Array<Float>)
	{
		var s = mSize, d = mData;
		
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
			assert(rvals.length >= mSize, "insufficient random values");
			
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
		Returns true if the index `i` is valid for reading a value.
		<o>1</o>
	**/
	inline public function inRange(i:Int):Bool
	{
		return i >= 0 && i < mSize;
	}
	
	/**
		Returns a string representing the current object.
		
		Example:
		<pre class="prettyprint">
		var dv = new de.polygonal.ds.DynamicVector<Int>();
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
		var s = '{ Dv size/capacity: $mSize/$capacity} }';
		if (isEmpty()) return s;
		s += "\n[\n";
		var d = mData;
		for (i in 0...mSize)
			s += Printf.format("  %4d -> %s\n", [i, Std.string(d.get(i))]);
		s += "]";
		return s;
	}
	
	function shrink()
	{
		if (capacity <= 16) return;
		
		capacity >>= 1;
		mShrinkSize = capacity >> 2;
		resize(capacity);
	}
	
	function grow()
	{
		capacity =
		if (mCapacityIncrement == -1)
		{
			if (true)
				Std.int((capacity * 3) / 2 + 1); //1.5
			else
				capacity + ((capacity >> 3) + (capacity < 9 ? 3 : 6)); //1.125
		}
		else
			capacity + mCapacityIncrement;
		
		mShrinkSize = capacity >> 2;
		
		resize(capacity);
	}
	
	function resize(newSize:Int)
	{
		var tmp = NativeArray.init(newSize);
		NativeArray.blit(mData, 0, tmp, 0, mSize);
		mData = tmp;
	}
	
	function quickSort(first:Int, k:Int, cmp:T->T->Int)
	{
		var d = mData;
		var last = first + k - 1;
		var lo = first;
		var hi = last;
		if (k > 1)
		{
			var i0 = first;
			var i1 = i0 + (k >> 1);
			var i2 = i0 + k - 1;
			var t0 = d.get(i0);
			var t1 = d.get(i1);
			var t2 = d.get(i2);
			var mid;
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
			
			var pivot = d.get(mid);
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
			assert(Std.is(d.get(i), Comparable), 'element is not of type Comparable (${Std.string(d.get(i))})');
		#end
		
		var last = first + k - 1, lo = first, hi = last, d = mData;
		if (k > 1)
		{
			var i0 = first;
			var i1 = i0 + (k >> 1);
			var i2 = i0 + k - 1;
			
			var t0:Comparable<Dynamic> = cast d.get(i0);
			var t1:Comparable<Dynamic> = cast d.get(i1);
			var t2:Comparable<Dynamic> = cast d.get(i2);
			
			var mid;
			var t = t0.compare(t2);
			if (t < 0 && t0.compare(t1) < 0)
				mid = t1.compare(t2) < 0 ? i1 : i2;
			else
			{
				if (t0.compare(t1) < 0 && t1.compare(t2) < 0)
					mid = t < 0 ? i0 : i2;
				else
					mid = t2.compare(t0) < 0 ? i1 : i0;
			}
			
			var pivot:Comparable<Dynamic> = cast d.get(mid);
			
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
			
			d.set(lo, cast pivot);
			
			quickSortComparable(first, lo - first);
			quickSortComparable(lo + 1, last - lo);
		}
	}
	
	function insertionSort(first:Int, k:Int, cmp:T->T->Int)
	{
		var d = mData;
		for (i in first + 1...first + k)
		{
			var x = d.get(i);
			var j = i;
			while (j > first)
			{
				var y = d.get(j - 1);
				if (cmp(y, x) > 0)
				{
					d.set(j, y);
					j--;
				}
				else
					break;
			}
			d.set(j, x);
		}
	}
	
	function insertionSortComparable(first:Int, k:Int)
	{
		var d = mData;
		
		#if debug
		for (i in first...first + k)
			assert(Std.is(d.get(i), Comparable), 'element is not of type Comparable (${Std.string(d.get(i))})');
		#end
		
		for (i in first + 1...first + k)
		{
			var x = d.get(i);
			
			var xv:Dynamic = x;
			var xd:Comparable<Dynamic> = xv;
			
			var j = i;
			while (j > first)
			{
				var y = d.get(j - 1);
				
				var yv:Dynamic = y;
				
				var yd:Comparable<Dynamic> = yv;
				
				if (yd.compare(xd) > 0)
				{
					d.set(j, y);
					j--;
				}
				else
					break;
			}
			
			d.set(j, x);
		}
	}
	
	/*///////////////////////////////////////////////////////
	// collection
	///////////////////////////////////////////////////////*/
	
	/**
		Destroys this object by explicitly nullifying all elements for GC'ing used resources.
		
		Improves GC efficiency/performance (optional).
		<o>n</o>
	**/
	public function free()
	{
		#if cpp
		cpp.NativeArray.zero(mData);
		#else
		for (i in 0...capacity) mData.set(i, cast null);
		#end
		
		mData = null;
		mIterator = null;
	}
	
	/**
		Returns true if this vector contains the element `x`.
		<o>n</o>
	**/
	public function contains(x:T):Bool
	{
		var d = mData;
		for (i in 0...mSize)
		{
			if (d.get(i) == x)
				return true;
		}
		return false;
	}
	
	/**
		Removes all occurrences of `x`.
		Shifts any subsequent elements to the left (indices - 1).
		<o>n</o>
		@return true if at least one occurrence of `x` was removed.
	**/
	public function remove(x:T):Bool
	{
		if (isEmpty()) return false;
		
		var i = 0;
		var s = mSize;
		var d = mData;
		while (i < s)
		{
			if (d.get(i) == x)
			{
				//#if (neko || java || cs || cpp)
				//NativeArray.blit(d, i + 1, d, i, s - i);
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
		
		var found = (mSize - s) != 0;
		mSize = s;
		return found;
	}
	
	/**
		Clears this vector by nullifying all elements.
		
		The `purge` parameter has no effect.
		<o>1 or n if `purge` is true</o>
	**/
	public function clear(clean = false)
	{
		if (clean)
		{
			#if cpp
			cpp.NativeArray.zero(mData, 0, capacity);
			#else
			var d = mData;
			for (i in 0...mSize) d.set(i, cast null);
			#end
		}
		
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
				mIterator = new DynamicVectorIterator<T>(this);
			else
				mIterator.reset();
			return mIterator;
		}
		else
			return new DynamicVectorIterator<T>(this);
	}
	
	/**
		The number of elements in this vector.
		
		<o>1</o>
	**/
	inline public function size():Int
	{
		return mSize;
	}
	
	public function isEmpty():Bool
	{
		return mSize == 0;
	}
	
	/**
		Returns an array containing all elements in this vector.
		
		Preserves the natural order of this array.
	**/
	public function toArray():Array<T>
	{
		//TODO use blit for cpp
		var d = mData;
		var out = ArrayUtil.alloc(mSize);
		for (i in 0...mSize) out[i] = d.get(i);
		return out;
	}
	
	public function toVector():Container<T>
	{
		//TODO useful?
		//var v = new Vector<T>(size);
		//for (i in 0...size) v[i] = d.get(i);
		//return v;
		return null;
	}
	
	/**
		Duplicates this dense array. Supports shallow (structure only) and deep copies (structure & elements).
		<assert>element is not of type `Cloneable`</assert>
		@param assign if true, the `copier` parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.
		If false, the `clone()` method is called on each element. <warn>In this case all elements have to implement `Cloneable`.</warn>
		@param copier a custom function for copying elements. Replaces `element::clone()` if `assign` is false.
	**/
	public function clone(assign = true, copier:T->T = null):Collection<T>
	{
		var out = new DynamicVector<T>();
		out.capacity = capacity;
		out.mSize = mSize;
		mCapacityIncrement = -1;
		out.mData = NativeArray.init(mSize);
		out.mShrinkSize = mShrinkSize;
		out.mAllowShrink = mAllowShrink;
		
		var src = mData;
		var dst = out.mData;
		
		if (assign)
		{
			//NativeArray
			for (i in 0...mSize) dst.set(i, src.get(i));
		}
		else
		if (copier == null)
		{
			var c:Cloneable<Dynamic> = null;
			for (i in 0...mSize)
			{
				assert(Std.is(src.get(i), Cloneable), 'element is not of type Cloneable (${src.get(i)})');
				
				c = cast(src.get(i), Cloneable<Dynamic>);
				dst.set(i, c.clone());
			}
		}
		else
		{
			var src = mData;
			for (i in 0...mSize)
				dst.set(i, copier(src.get(i)));
		}
		
		return cast out;
	}
}

#if generic
@:generic
#end
@:dox(hide)
class DynamicVectorIterator<T> implements de.polygonal.ds.Itr<T>
{
	var mF:DynamicVector<T>;
	var mData:Container<T>;
	var mI:Int;
	var mS:Int;
	
	public function new(f:DynamicVector<T>)
	{
		mF = f;
		
		reset();
	}
	
	inline public function reset():Itr<T>
	{
		mData = mF.getContainer();
		mS = mF.size();
		mI = 0;
		return this;
	}
	
	inline public function hasNext():Bool
	{
		return mI < mS;
	}
	
	inline public function next():T
	{
		return mData.get(mI++);
	}
	
	inline public function remove()
	{
		assert(mI > 0, "call next() before removing an element");
		
		mF.removeAt(--mI);
		mS--;
	}
}