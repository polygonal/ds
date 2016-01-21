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
	A dense, dynamic array
	
	_<o>Worst-case running time in Big O notation</o>_
**/
#if generic
@:generic
#end
class Da<T> implements Collection<T>
{
	/**
		A unique identifier for this object.
		
		A hash table transforms this key into an index of an array element by using a hash function.
		
		<warn>This value should never be changed by the user.</warn>
	**/
	public var key:Int;
	
	/**
		The maximum allowed size of this dense array.
		
		Once the maximum size is reached, adding an element will fail with an error (debug only).
		
		A value of -1 indicates that the size is unbound.
		
		<warn>Only effective when compiled with -debug.</warn>
	**/
	public var maxSize:Int;
	
	/**
		If true, reuses the iterator object instead of allocating a new one when calling ``iterator()``.
		
		The default is false.
		
		<warn>If true, nested iterations are likely to fail as only one iteration is allowed at a time.</warn>
	**/
	public var reuseIterator:Bool;
	
	var mData:DynamicVector<T>;
	var mSize:Int;
	var mIterator:DaIterator<T>;
	
	/**
		@param reservedSize the initial capacity of the internal container. Preallocates internal space for storing `reservedSize` elements.
	**/
	public function new(reservedSize:Int = 0)
	{
		mSize = 0;
		mIterator = null;
		mData = new DynamicVector<T>();
		
		if (reservedSize > mData.capacity) mData.reserve(reservedSize);
		
		key = HashKey.next();
		reuseIterator = false;
		
		maxSize =
		#if debug
		M.INT32_MAX;
		#else
		-1;
		#end
	}
	
	/**
		For performance reasons the dense array does nothing to ensure that empty locations contain null;
		``shrinkToFit()`` therefore nullifies all obsolete references and shrinks the container to the actual size allowing the garbage collector to reclaim used memory.
		<o>n</o>
	**/
	public function shrinkToFit()
	{
		mData.shrinkToFit();
	}
	
	/**
		Trims the dense array by cutting of ``size()`` - `n` elements.
		
		<warn>This only modifies the value of ``size()``; to enable garbage collection of all cut off elements and to shrink the internal array to the new size, call ``pack()`` afterwards.</warn>
		<o>1</o>
		<assert>new size > current ``size()``</assert>
		@param n the new size of this dense array.
	**/
	inline public function trim(n:Int)
	{
		assert(n <= size(), 'new size ($n) > current size (${size()})');
		
		mData.trim(n);
		
		mSize = n;
	}
	
	/**
		Returns the element stored at index `i`.
		<o>1</o>
		<assert>`i` out of range</assert>
	**/
	inline public function get(i:Int):T
	{
		return _get(i);
	}
	
	/**
		Replaces the element at index `i` with the element `x`.
		<o>1</o>
		<assert>`i` out of range or maximum size reached</assert>
	**/
	inline public function set(i:Int, x:T)
	{
		assert(i < maxSize, 'size equals max size ($maxSize)');
		
		_set(i, x);
		if (i >= mSize) mSize++;
	}
	
	/**
		Swaps the element stored at index `i` with the element stored at index `j`.
		<o>1</o>
		<assert>`i`/`j` out of range or `i` equals `j`</assert>
	**/
	inline public function swap(i:Int, j:Int)
	{
		assert(i != j, 'i index equals j index ($i)');
		
		var tmp = get(i);
		copy(i, j);
		set(j, tmp);
	}
	
	/**
		Replaces the element at index `i` with the element from index `j`.
		<o>1</o>
		<assert>`i`/`j` out of range or `i` equals `j`</assert>
	**/
	inline public function copy(i:Int, j:Int)
	{
		assert(i != j, 'i index equals j index ($i)');
		
		set(i, get(j));
	}
	
	/**
		Returns the first element.
		
		This is the element at index 0.
		<o>1</o>
		<assert>vector is empty</assert>
	**/
	inline public function front():T
	{
		return get(0);
	}
	
	/**
		Returns the last element.
		
		This is the element at index ``size()`` - 1.
		<o>1</o>
		<assert>vector is empty</assert>
	**/
	inline public function back():T
	{
		return get(mSize - 1);
	}
	
	/**
		Removes and returns the last element.
		<o>1</o>
		<assert>array is empty</assert>
	**/
	inline public function popBack():T
	{
		var x = get(mSize - 1);
		mSize--;
		return x;
	}
	
	/**
		Appends the element `x` to the last element.
		<o>1</o>
		<assert>``size()`` equals ``maxSize``</assert>
	**/
	inline public function pushBack(x:T)
	{
		set(mSize, x);
	}
	
	/**
		Removes and returns the first element.
		
		To fill the gap, any subsequent elements are shifted to the left (indices - 1).
		<o>n</o>
		<assert>array is empty</assert>
	**/
	inline public function popFront():T
	{
		return removeAt(0);
	}
	
	/**
		Prepends the element `x` to the first element.
		
		Shifts the first element (if any) and any subsequent elements to the right (indices + 1).
		<o>n</o>
		<assert>``size()`` equals ``maxSize``</assert>
	**/
	inline public function pushFront(x:T)
	{
		#if debug
		if (maxSize != -1)
			assert(size() < maxSize, 'size equals max size ($maxSize)');
		#end
		
		insertAt(0, x);
	}
	
	/**
		Inserts `x` at the specified index `i`.
		
		Shifts the element currently at that position (if any) and any subsequent elements to the right (indices + 1).
		<o>n</o>
		<assert>`i` out of range</assert>
		<assert>``size()`` equals ``maxSize``</assert>
	**/
	public function insertAt(i:Int, x:T)
	{
		assert(size() < maxSize, 'size equals max size ($maxSize)');
		assert(i >= 0 && i <= size(), 'i index out of range ($i)');
		
		var p = mSize;
		while (p > i) _cpy(p--, p);
		
		_set(i, x);
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
		assert(i >= 0 && i < size(), 'the index $i is out of range ${size()}');
		
		var x = _get(i);
		var k = size() - 1;
		var p = i;
		while (p < k) _cpy(p++, p);
		mSize--;
		return x;
	}
	
	/**
		Fast removal of the element at index `i` if the order of the elements doesn't matter.
		<o>1</o>
		<assert>`i` out of range</assert>
	**/
	inline public function swapPop(i:Int)
	{
		assert(i >= 0 && i < size(), 'the index $i is out of range ${size()}');
		
		_set(i, _get(--mSize));
	}
	
	/**
		Removes `n` elements starting at the specified index `i` in the range [`i`, `i` + `n`).
		<o>n</o>
		<assert>`i` or `n` out of range</assert>
		@param output stores the removed elements. If omitted, the removed elements are lost.
		@return a dense array storing all removed elements or null if `output` is omitted.
	**/
	public function removeRange(i:Int, n:Int, output:Da<T> = null):Da<T>
	{
		assert(i >= 0 && i <= size(), 'i index out of range ($i)');
		assert(n > 0 && n <= size() && (i + n <= size()), 'n out of range ($n)');
		
		if (output == null)
		{
			var s = size();
			var p = i + n;
			while (p < s)
			{
				_set(p - n, _get(p));
				p++;
			}
		}
		else
		{
			var s = size();
			var p = i + n;
			var e:T, j;
			while (p < s)
			{
				j = p - n;
				e = _get(j);
				output.pushBack(e);
				_cpy(j, p++);
			}
		}
		
		mSize -= n;
		
		return output;
	}
	
	/**
		Concatenates this array with `x` by appending all elements of `x` to this array.
		<o>n</o>
		<assert>`x` is null</assert>
		<assert>`x` equals this if `copy`=false</assert>
		@param copy if true, returns a new array instead of modifying this array.
	**/
	public function concat(x:Da<T>, copy = false):Da<T>
	{
		assert(x != null, "x is null");
		
		if (copy)
		{
			var copy = new Da<T>();
			copy.mSize = size() + x.size();
			for (i in 0...size()) copy.set(i, _get(i));
			for (i in size()...size() + x.size()) copy.set(i, x.get(i - size()));
			return copy;
		}
		else
		{
			assert(x != this, "x equals this");
			
			var j = mSize;
			mSize += x.size();
			for (i in 0...x.size()) _set(j++, x.get(i));
			return this;
		}
	}
	
	/**
		Finds the first occurrence of the element `x` (by incrementing indices - from left to right).
		<o>n</o>
		<assert>`from` out of range</assert>
		@param from the index to start from. The default value is 0.
		@param binarySearch use the binary search algorithm. Requires that the elements are sorted.
		@param comparator a comparison function for the binary search. If omitted, the method assumes that all elements implement `Comparable`.
		@return the index storing the element `x` or -1 if `x` was not found.
		If `binarySearch` is true, returns the index of `x` or the bitwise complement (~) of the index where the `x` would be inserted (guaranteed to be a negative number).
		<warn>The insertion point is only valid if`from`=0.</warn>
	**/
	@:access(de.polygonal.ds.DynamicVector)
	public function indexOf(x:T, from = 0, binarySearch = false, comparator:T->T->Int = null):Int
	{
		if (size() == 0)
			return -1;
		else
		{
			assert(from >= 0 && from < size(), 'from index out of range ($from)');
			
			if (binarySearch)
			{
				if (comparator != null)
					return VectorUtil.bsearchComparator(mData.mData, x, from, size() - 1, comparator);
				else
				{
					assert(Std.is(x, Comparable), 'element is not of type Comparable ($x)');
					
					var k = size();
					var l = from, m, h = k;
					while (l < h)
					{
						m = l + ((h - l) >> 1);
						
						assert(Std.is(mData.get(m), Comparable), 'element is not of type Comparable (${mData.get(m)})');
						
						if (cast(mData.get(m), Comparable<Dynamic>).compare(x) < 0)
							l = m + 1;
						else
							h = m;
					}
					
					assert(Std.is(mData.get(l), Comparable), 'element is not of type Comparable (${mData.get(l)})');
					
					return ((l <= k) && (cast(mData.get(l), Comparable<Dynamic>).compare(x)) == 0) ? l : -l;
				}
			}
			else
			{
				var i = from;
				var j = -1;
				var k = size() - 1;
				do
				{
					if (_get(i) == x)
					{
						j = i;
						break;
					}
				}
				while (i++ < k);
				return j;
			}
		}
	}
	
	/**
		Finds the first occurrence of `x` (by decrementing indices - from right to left) and returns the index storing the element `x` or -1 if `x` was not found.
		<o>n</o>
		<assert>`from` out of range</assert>
		@param from the index to start from. By default, the method starts from the last element in this dense array.
	**/
	public function lastIndexOf(x:T, from = -1):Int
	{
		if (size() == 0)
			return -1;
		else
		{
			if (from < 0) from = size() + from;
			
			assert(from >= 0 && from < size(), 'from index out of range ($from)');
			
			var j = -1;
			var i = from;
			
			do
			{
				if (_get(i) == x)
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
		Reverses this dense array in place.
		<o>n</o>
	**/
	public function reverse()
	{
		mData.reverse(0, size());
	}
	
	/**
		Replaces up to `n` existing elements with objects of type `cl`.
		<o>n</o>
		<assert>`n` out of range</assert>
		@param cl the class to instantiate for each element.
		@param args passes additional constructor arguments to the class `cl`.
		@param n the number of elements to replace. If 0, `n` is set to ``size()``.
	**/
	public function assign(cl:Class<T>, args:Array<Dynamic> = null, n = 0)
	{
		assert(n >= 0);
		
		if (n > 0)
		{
			assert(n <= maxSize, 'n out of range ($n)');
			
			mSize = n;
		}
		else
			n = size();
		if (args == null) args = [];
		for (i in 0...n) _set(i, Type.createInstance(cl, args));
	}
	
	/**
		Replaces up to `n` existing elements with the instance `x`.
		<o>n</o>
		<assert>`n` out of range</assert>
		@param n the number of elements to replace. If 0, `n` is set to ``size()``.
	**/
	public function fill(x:T, n = 0):Da<T>
	{
		assert(n >= 0);
		
		if (n > 0)
		{
			assert(n <= maxSize, 'n out of range ($n)');
			
			mSize = n;
		}
		else
			n = size();
		
		for (i in 0...n)
			_set(i, x);
		
		return this;
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
		assert(source < size());
		assert(destination + n <= size());
		assert(n <= size());
		
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
				_set(j, _get(i));
			}
		}
		else
		{
			var i = source;
			var j = destination;
			for (k in 0...n)
			{
				_set(j, _get(i));
				i++;
				j++;
			}
		}
	}
	
	/**
		Converts the data in this dense array to strings, inserts `x` between the elements, concatenates them, and returns the resulting string.
		<o>n</o>
	**/
	public function join(x:String):String
	{
		if (size() == 0) return "";
		if (size() == 1) return Std.string(front());
		var s = Std.string(front()) + x;
		for (i in 1...size() - 1)
		{
			s += Std.string(get(i));
			s += x;
		}
		s += Std.string(back());
		return s;
	}
	
	/**
		Sorts the elements of this dense array using the quick sort algorithm.
		<o>n&sup2;</o>
		<assert>element does not implement `Comparable`</assert>
		<assert>`first` or `count` out of bound</assert>
		@param compare a comparison function.If null, the elements are compared using ``element::compare()``.
		<warn>In this case all elements have to implement `Comparable`.</warn>
		@param useInsertionSort if true, the dense array is sorted using the insertion sort algorithm. This is faster for nearly sorted lists.
		@param first sort start index. The default value is 0.
		@param count the number of elements to sort (range: [`first`, `first` + `count`]).
		If omitted, `count` is set to the remaining elements (``size()`` - `first`).
	**/
	public function sort(compare:T->T->Int, useInsertionSort = false, first = 0, count = -1)
	{
		if (size() > 1)
		{
			if (count == -1) count = size() - first;
			
			assert(first >= 0 && first <= size() - 1 && first + count <= size(), "first index out of bound");
			assert(count >= 0 && count <= size(), "count out of bound");
			
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
	
	/**
		Returns true if the index `i` is valid for reading a value.
		<o>1</o>
	**/
	inline public function inRange(i:Int):Bool
	{
		return i >= 0 && i < mSize;
	}
	
	/**
		Grants access to the internal vector storing the elements of this dense array.
		
		Useful for fast iteration or low-level operations.
		
		<warn>The length of the vector doesn't have to match ``size()``.</warn>
		<o>1</o>
	**/
	/*inline public function getVector():Vector<T>
	{
		return mData.getContainer();
	}*/
	
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
		for (i in 0...mData.size) _set(i, cast null);
		mData = null;
		mIterator = null;
	}
	
	/**
		Returns true if this object contains the element `x`.
		<o>n</o>
	**/
	public function contains(x:T):Bool
	{
		var found = false;
		for (i in 0...size())
		{
			if (_get(i) == x)
			{
				found = true;
				break;
			}
		}
		return found;
	}
	
	/**
		Removes and nullifies all occurrences of the element `x`.
		<o>n</o>
		@return true if at least one occurrence of `x` was removed.
	**/
	public function remove(x:T):Bool
	{
		if (isEmpty()) return false;
		
		var i = 0;
		var s = size();
		while (i < s)
		{
			if (_get(i) == x)
			{
				s--;
				var p = i;
				while (p < s)
				{
					_cpy(p, p + 1);
					++p;
				}
				continue;
			}
			i++;
		}
		
		var found = (size() - s) != 0;
		mSize = s;
		return found;
	}
	
	/**
		Removes all elements.
		<o>1 or n if `purge` is true</o>
		@param purge if true, elements are nullified upon removal.
	**/
	public function clear(purge = false)
	{
		if (purge)
			for (i in 0...mData.size)
				_set(i, cast null);
		mSize = 0;
	}
	
	/**
		Returns a new `DaIterator` object to iterate over all elements contained in this dense array.
		
		Preserves the natural order of an array.
		
		See <a href="http://haxe.org/ref/iterators" target="mBlank">http://haxe.org/ref/iterators</a>
	**/
	public function iterator():Itr<T>
	{
		if (reuseIterator)
		{
			if (mIterator == null)
				mIterator = new DaIterator<T>(this);
			else
				mIterator.reset();
			return mIterator;
		}
		else
			return new DaIterator<T>(this);
	}
	
	/**
		The total number of elements.
		<o>1</o>
	**/
	inline public function size():Int
	{
		return mSize;
	}
	
	/**
		Returns true if this dense array is empty.
		<o>1</o>
	**/
	inline public function isEmpty():Bool
	{
		return size() == 0;
	}
	
	/**
		Returns an array containing all elements in this dense array.
		
		Preserves the natural order of this array.
	**/
	public function toArray():Array<T>
	{
		var a:Array<T> = ArrayUtil.alloc(size());
		for (i in 0...size()) a[i] = _get(i);
		return a;
	}
	
	/**
		Returns a `Vector<T>` object containing all elements in this dense array.
		
		Preserves the natural order of this array.
	**/
	public function toVector():Vector<T>
	{
		var v = new Vector<T>(size());
		for (i in 0...size()) v[i] = _get(i);
		return v;
	}
	
	/**
		Duplicates this dense array. Supports shallow (structure only) and deep copies (structure & elements).
		<assert>element is not of type `Cloneable`</assert>
		@param assign if true, the `copier` parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.
		If false, the ``clone()`` method is called on each element. <warn>In this case all elements have to implement `Cloneable`.</warn>
		@param copier a custom function for copying elements. Replaces ``element::clone()`` if `assign` is false.
	**/
	public function clone(assign = true, copier:T->T = null):Collection<T>
	{
		var copy = new Da<T>();
		copy.maxSize = maxSize;
		copy.mSize = mSize;
		if (assign)
		{
			for (i in 0...size())
				copy._set(i, _get(i));
		}
		else
		if (copier == null)
		{
			var c:Cloneable<Dynamic> = null;
			for (i in 0...size())
			{
				assert(Std.is(_get(i), Cloneable), 'element is not of type Cloneable (${_get(i)})');
				
				c = cast(_get(i), Cloneable<Dynamic>);
				copy._set(i, c.clone());
			}
		}
		else
		{
			for (i in 0...size())
				copy._set(i, copier(_get(i)));
		}
		
		return copy;
	}
	
	/**
		Shuffles the elements of this collection by using the Fisher-Yates algorithm.
		<o>n</o>
		<assert>insufficient random values</assert>
		@param rval a list of random double values in the range between 0 (inclusive) to 1 (exclusive) defining the new positions of the elements.
		If omitted, random values are generated on-the-fly by calling `Math::random()`.
	**/
	public function shuffle(rval:Array<Float> = null)
	{
		var s = size();
		if (rval == null)
		{
			var m = Math;
			while (--s > 1)
			{
				var i = Std.int(m.random() * s);
				var t = _get(s);
				_cpy(s, i);
				_set(i, t);
			}
		}
		else
		{
			assert(rval.length >= size(), "insufficient random values");
			
			var j = 0;
			while (--s > 1)
			{
				var i = Std.int(rval[j++] * s);
				var t = _get(s);
				_cpy(s, i);
				_set(i, t);
			}
		}
	}
	
	/**
		Returns a string representing the current object.
		
		Example:
		<pre class="prettyprint">
		var da = new de.polygonal.ds.Da<Int>(10);
		for (i in 0...3) {
		    da.set(i, i);
		}
		trace(da);</pre>
		<pre class="console">
		{ Da size/max: 3/10 }
		[
		  0 -> 0
		  1 -> 1
		  2 -> 2
		]</pre>
	**/
	public function toString():String
	{
		var s = '{ Da size: ${size()} }';
		if (isEmpty()) return s;
		s += "\n[\n";
		for (i in 0...size())
			s += Printf.format("  %4d -> %s\n", [i, Std.string(_get(i))]);
		s += "]";
		return s;
	}
	
	function quickSort(first:Int, k:Int, cmp:T->T->Int)
	{
		var last = first + k - 1;
		var lo = first;
		var hi = last;
		if (k > 1)
		{
			var i0 = first;
			var i1 = i0 + (k >> 1);
			var i2 = i0 + k - 1;
			var t0 = _get(i0);
			var t1 = _get(i1);
			var t2 = _get(i2);
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
			
			var pivot = _get(mid);
			_cpy(mid, first);
			
			while (lo < hi)
			{
				while (cmp(pivot, _get(hi)) < 0 && lo < hi) hi--;
				if (hi != lo)
				{
					_cpy(lo, hi);
					lo++;
				}
				while (cmp(pivot, _get(lo)) > 0 && lo < hi) lo++;
				if (hi != lo)
				{
					_cpy(hi, lo);
					hi--;
				}
			}
			_set(lo, pivot);
			quickSort(first, lo - first, cmp);
			quickSort(lo + 1, last - lo, cmp);
		}
	}
	
	function quickSortComparable(first:Int, k:Int)
	{
		var last = first + k - 1;
		var lo = first;
		var hi = last;
		if (k > 1)
		{
			var i0 = first;
			var i1 = i0 + (k >> 1);
			var i2 = i0 + k - 1;
			
			assert(Std.is(_get(i0), Comparable), 'element is not of type Comparable (${Std.string(_get(i0))})');
			assert(Std.is(_get(i1), Comparable), 'element is not of type Comparable (${Std.string(_get(i1))})');
			assert(Std.is(_get(i2), Comparable), 'element is not of type Comparable (${Std.string(_get(i2))})');
			
			var t0:Dynamic = cast(_get(i0), Comparable<Dynamic>);
			var t1:Dynamic = cast(_get(i1), Comparable<Dynamic>);
			var t2:Dynamic = cast(_get(i2), Comparable<Dynamic>);
			
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
			
			assert(Std.is(_get(mid), Comparable), 'element is not of type Comparable (${Std.string(_get(mid))})');
			
			var pivot:Dynamic = cast(_get(mid), Comparable<Dynamic>);
			
			_cpy(mid, first);
			
			while (lo < hi)
			{
				assert(Std.is(_get(lo), Comparable), 'element is not of type Comparable (${Std.string(_get(lo))})');
				assert(Std.is(_get(hi), Comparable), 'element is not of type Comparable (${Std.string(_get(hi))})');
				
				while (pivot.compare(cast(_get(hi), Comparable<Dynamic>)) < 0 && lo < hi) hi--;
				if (hi != lo)
				{
					_cpy(lo, hi);
					lo++;
				}
				while (pivot.compare(cast(_get(lo), Comparable<Dynamic>)) > 0 && lo < hi) lo++;
				if (hi != lo)
				{
					_cpy(hi, lo);
					hi--;
				}
			}
			_set(lo, cast pivot);
			quickSortComparable(first, lo - first);
			quickSortComparable(lo + 1, last - lo);
		}
	}
	
	function insertionSort(first:Int, k:Int, cmp:T->T->Int)
	{
		for (i in first + 1...first + k)
		{
			var x = _get(i);
			var j = i;
			while (j > first)
			{
				var y = _get(j - 1);
				if (cmp(y, x) > 0)
				{
					_set(j, y);
					j--;
				}
				else
					break;
			}
			_set(j, x);
		}
	}
	
	function insertionSortComparable(first:Int, k:Int)
	{
		for (i in first + 1...first + k)
		{
			var x = _get(i);
			
			assert(Std.is(x, Comparable), "element is not of type Comparable");
			
			var j = i;
			while (j > first)
			{
				var y = _get(j - 1);
				
				assert(Std.is(y, Comparable), "element is not of type Comparable");
				
				if (cast(y, Comparable<Dynamic>).compare(x) > 0)
				{
					_set(j, y);
					j--;
				}
				else
					break;
			}
			_set(j, x);
		}
	}
	
	inline function _get(i:Int) return mData.get(i);
	
	inline function _set(i:Int, x:T) mData.set(i, x);
	
	inline function _cpy(i:Int, j:Int) mData.set(i, mData.get(j));
}

@:access(de.polygonal.ds.Da)
#if generic
@:generic
#end
@:dox(hide)
class DaIterator<T> implements de.polygonal.ds.Itr<T>
{
	var mF:Da<T>;
	var mData:DynamicVector<T>;
	var mI:Int;
	var mS:Int;
	
	public function new(f:Da<T>)
	{
		mF = f;
		reset();
	}
	
	inline public function reset():Itr<T>
	{
		mData = mF.mData;
		mS = mF.mSize;
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