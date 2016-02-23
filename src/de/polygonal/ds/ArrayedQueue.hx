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

import de.polygonal.ds.tools.ArrayTools;
import de.polygonal.ds.tools.Assert.assert;
import de.polygonal.ds.tools.GrowthRate;
import de.polygonal.ds.tools.M;

using de.polygonal.ds.tools.NativeArrayTools;

/**
	An arrayed queue based on an arrayed circular queue
	
	A queue is a linear list for which all insertions are made at one end of the list; all deletions (and usually all accesses) are made at the other end.
	
	This is called a FIFO structure (First In, First Out).
	
	See <a href="http://lab.polygonal.de/?p=189" target="mBlank">http://lab.polygonal.de/?p=189</a>
**/
#if generic
@:generic
#end
class ArrayedQueue<T> implements Queue<T>
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
		If true, reuses the iterator object instead of allocating a new one when calling ``iterator()``.
		
		The default is false.
		
		<warn>If true, nested iterations are likely to fail as only one iteration is allowed at a time.</warn>
	**/
	public var reuseIterator:Bool = false;
	
	var mData:NativeArray<T>;
	var mInitialCapacity:Int;
	var mSize:Int = 0;
	var mFront:Int = 0;
	var mIterator:ArrayedQueueIterator<T> = null;
	
	/**
		<assert>reserved size is greater than allowed size</assert>
		@param initialCapacity the initial physical space for storing the elements at the time the queue is created.
		This is also the minimum size of this queue.
		The `capacity` is automatically adjusted according to the storage requirements based on three rules:
		<ul>
		<li>If this queue runs out of space, `capacity` is doubled.</li>
		<li>If the ``size`` falls below a quarter of the current `capacity`, the `capacity` is cut in half</li>
		<li>The minimum `capacity` equals `capacity`</li>
		</ul>
	**/
	public function new(initialCapacity:Null<Int> = 16, ?source:Array<T>)
	{
		mInitialCapacity = M.max(1, initialCapacity);
		capacity = mInitialCapacity;
		
		if (source != null)
		{
			mSize = source.length;
			capacity = M.max(mSize, capacity);
		}
		
		mData = NativeArrayTools.alloc(capacity);
		
		if (source != null)
		{
			var d = mData;
			for (i in 0...mSize) mData.set(i, source[i]);
		}
	}
	
	/**
		Returns the front element. This is the "oldest" element.
		<assert>queue is empty</assert>
	**/
	public inline function peek():T
	{
		assert(size > 0, "queue is empty");
		
		return mData.get(mFront);
	}
	
	/**
		Returns the rear element.
		
		This is the "newest" element.
		<assert>queue is empty</assert>
	**/
	public inline function back():T
	{
		assert(size > 0, "queue is empty");
		
		return mData.get(((size - 1) + mFront) % capacity);
	}
	
	/**
		Enqueues the element `x`.
		<assert>out of space - queue is full but not resizable</assert>
	**/
	public function enqueue(x:T)
	{
		if (capacity == size) grow();
		mData.set((mSize++ + mFront) % capacity, x);
	}
	
	/**
		Dequeues and returns the front element.
		<assert>queue is empty</assert>
	**/
	public function dequeue():T
	{
		assert(size > 0, "queue is empty");
		
		var x = mData.get(mFront++);
		if (mFront == capacity) mFront = 0;
		mSize--;
		return x;
	}
	
	/**
		For performance reasons the queue does nothing to ensure that empty locations contain null;
		``pack()`` therefore nullifies all obsolete references.
	**/
	public function pack()
	{
		if (capacity > mInitialCapacity)
		{
			var oldCapacity = capacity;
			capacity = M.max(size, mInitialCapacity);
			resizeContainer(oldCapacity, capacity);
		}
		else
		{
			var i = (mFront + size) % capacity;
			var d = mData;
			for (j in 0...capacity - size)
			{
				d.set(i, cast null);
				i = (i + 1) % capacity;
			}
		}
	}
	
	/**
		Preallocates storage for `n` elements.
		
		May cause a reallocation, but has no effect on the vector size and its elements.
		Useful before inserting a large number of elements as this reduces the amount of incremental reallocation.
	**/
	public function reserve(n:Int):ArrayedQueue<T>
	{
		if (n > capacity)
		{
			var t = capacity;
			capacity = n;
			resizeContainer(t, n);
		}
		return this;
	}
	
	/**
		Returns the element at index `i`.
		
		The index is measured relative to the index of the front element (= 0).
		<assert>queue is empty</assert>
		<assert>`i` out of range</assert>
	**/
	public inline function get(i:Int):T
	{
		assert(size > 0, "queue is empty");
		assert(i < size, 'i index out of range ($i)');
		
		return mData.get((i + mFront) % capacity);
	}
	
	/**
		Replaces the element at index `i` with the element `x`.
		
		The index is measured relative to the index of the front element (= 0).
		<assert>queue is empty</assert>
		<assert>`i` out of range</assert>
	**/
	public inline function set(i:Int, x:T)
	{
		assert(size > 0, "queue is empty");
		assert(i < size, 'i index out of range ($i)');
		
		mData.set((i + mFront) % capacity, x);
	}
	
	/**
		Swaps the element at index `i` with the element at index `j`.
		
		The index is measured relative to the index of the front element (= 0).
		<assert>queue is empty</assert>
		<assert>`i`/`j` out of range</assert>
		<assert>`i` equals `j`</assert>
	**/
	public inline function swap(i:Int, j:Int)
	{
		assert(size > 0, "queue is empty");
		assert(i < size, 'i index out of range ($i)');
		assert(j < size, 'j index out of range ($j)');
		assert(i != j, 'i index equals j index ($i)');
		
		var t = get(i);
		copy(i, j);
		set(j, t);
	}
	
	/**
		Replaces the element at index `i` with the element from index `j`.
		
		The index is measured relative to the index of the front element (= 0).
		<assert>queue is empty</assert>
		<assert>`i`/`j` out of range</assert>
		<assert>`i` equals `j`</assert>
	**/
	public inline function copy(i:Int, j:Int)
	{
		assert(size > 0, "queue is empty");
		assert(i < size, 'i index out of range ($i)');
		assert(j < size, 'j index out of range ($j)');
		assert(i != j, 'i index equals j index ($i)');
		
		set(i, get(j));
	}
	
	/**
		Calls the `f` function on all elements.
		
		The function signature is: `f(element, index):element`
		<assert>`f` is null</assert>
	**/
	public function forEach(f:T->Int->T):ArrayedQueue<T>
	{
		var j, front = mFront, d = mData;
		for (i in 0...size)
		{
			j = (i + front) % capacity;
			d.set(j, f(d.get(j), i));
		}
		return this;
	}
	
	/**
		Shuffles the elements of this collection by using the Fisher-Yates algorithm.
		<assert>insufficient random values</assert>
		@param rvals a list of random double values in the range between 0 (inclusive) to 1 (exclusive) defining the new positions of the elements.
		If omitted, random values are generated on-the-fly by calling `Math::random()`.
	**/
	public function shuffle(rvals:Array<Float> = null)
	{
		var s = size, d = mData;
		if (rvals == null)
		{
			var m = Math, i, t;
			while (s > 1)
			{
				s--;
				i = (Std.int(m.random() * s) + mFront) % capacity;
				t = d.get(s);
				d.set(s, d.get(i));
				d.set(i, t);
			}
		}
		else
		{
			assert(rvals.length >= size, "insufficient random values");
			
			var j = 0, i, t;
			while (s > 1)
			{
				s--;
				i = (Std.int(rvals[j++] * s) + mFront) % capacity;
				t = d.get(s);
				d.set(s, d.get(i));
				d.set(i, t);
			}
		}
	}
	
	/**
		Returns a string representing the current object.
		
		Example:
		<pre class="prettyprint">
		var queue = new de.polygonal.ds.ArrayedQueue<Int>(4);
		for (i in 0...queue.capacity) {
		    queue.enqueue(i);
		}
		trace(queue);</pre>
		<pre class="console">
		{ ArrayedQueue size/capacity: 4/4 }
		[ front
		  0 -> 0
		  1 -> 1
		  2 -> 2
		  3 -> 3
		]</pre>
	**/
	public function toString():String
	{
		var b = new StringBuf();
		b.add('{ ArrayedQueue size/capacity: $size/$capacity }');
		if (isEmpty()) return b.toString();
		b.add("\n[ front\n");
		
		var fmt = '  %${M.numDigits(size)}d: %s\n';
		var args = new Array<Dynamic>();
		for (i in 0...size)
		{
			args[0] = i;
			args[1] = Std.string(get(i));
			b.add(Printf.format(fmt, args));
		}
		b.add("]");
		return b.toString();
	}
	
	/**
		The size of the allocated storage space for the elements.
		
		If more space is required to accomodate new elements, the capacity is doubled every time ``size`` grows beyond capacity, and split in half when ``size`` is a quarter of capacity.
		The capacity never falls below the initial size defined in the constructor.
	**/
	public inline function getCapacity():Int
	{
		return capacity;
	}
	
	/**
		Returns true if this queue is full.
	**/
	public inline function isFull():Bool
	{
		return size == capacity;
	}
	
	/* INTERFACE Collection */
	
	/**
		The total number of elements.
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
		Returns true if this queue contains the element `x`.
	**/
	public function contains(x:T):Bool
	{
		var d = mData;
		for (i in 0...size)
		{
			if (d.get((i + mFront) % capacity) == x)
				return true;
		}
		return false;
	}
	
	/**
		Removes and nullifies all occurrences of the element `x`.
		@return true if at least one occurrence of `x` was removed.
	**/
	public function remove(x:T):Bool
	{
		if (isEmpty()) return false;
		
		var s = size, success = true, d = mData;
		while (s > 0 && success)
		{
			success = false;
			for (i in 0...s)
			{
				if (d.get((i + mFront) % capacity) == x)
				{
					success = true;
					if (i == 0)
					{
						if (++mFront == capacity) mFront = 0;
						s--;
					}
					else
					if (i == s - 1)
						s--;
					else
					{
						var i0 = (mFront + i);
						var i1 = (mFront + s - 1);
						for (j in i0...i1) d.set(j % capacity, d.get((j + 1) % capacity));
						s--;
					}
					break;
				}
			}
		}
		mSize = s;
		return success;
	}
	
	/**
		Removes all elements.
		
		@param gc if true, elements are nullified upon removal so the garbage collector can reclaim used memory.
	**/
	public function clear(gc:Bool = false)
	{
		if (gc)
		{
			var i = mFront, d = mData;
			for (j in 0...size) d.set(i++ % capacity, cast null);
		}
		mFront = mSize = 0;
	}
	
	/**
		Returns a new `ArrayedQueueIterator` object to iterate over all elements contained in this queue.
		
		Preserves the natural order of a queue (First-In-First-Out).
		
		See <a href="http://haxe.org/ref/iterators" target="mBlank">http://haxe.org/ref/iterators</a>
	**/
	public function iterator():Itr<T>
	{
		if (reuseIterator)
		{
			if (mIterator == null)
				mIterator = new ArrayedQueueIterator<T>(this);
			else
				mIterator.reset();
			return mIterator;
		}
		else
			return new ArrayedQueueIterator<T>(this);
	}
	
	/**
		Returns true if this queue is empty.
	**/
	public inline function isEmpty():Bool
	{
		return size == 0;
	}
	
	/**
		Returns an array containing all elements in this queue.
		
		Preserves the natural order of this queue (First-In-First-Out).
	**/
	public function toArray():Array<T>
	{
		if (isEmpty()) return [];
		
		#if cpp
		var out = NativeArrayTools.alloc(size);
		var n = M.min(capacity, mFront + size) - mFront;
		mData.blit(mFront, out, 0, n);
		if (size - n > 0) mData.blit(0, out, n, size - n);
		return out;
		#else
		var d = mData;
		var out = ArrayTools.alloc(size);
		for (i in 0...size) out[i] = d.get((i + mFront) % capacity);
		return out;
		#end
	}
	
	/**
		Duplicates this queue. Supports shallow (structure only) and deep copies (structure & elements).
		<assert>element is not of type `Cloneable`</assert>
		@param assign if true, the `copier` parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.
		If false, the ``clone()`` method is called on each element. <warn>In this case all elements have to implement `Cloneable`.</warn>
		@param copier a custom function for copying elements. Replaces ``element::clone()`` if `assign` is false.
	**/
	public function clone(assign:Bool = true, copier:T->T = null):Collection<T>
	{
		var copy = new ArrayedQueue<T>(capacity);
		if (isEmpty()) return copy;
		
		var src = mData;
		var dst = copy.mData;
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
		
		copy.mFront = mFront;
		copy.mSize = size;
		return copy;
	}
	
	function grow()
	{
		var t = capacity;
		capacity = GrowthRate.compute(growthRate, capacity);
		resizeContainer(t, capacity);
	}
	
	function resizeContainer(oldSize:Int, newSize:Int)
	{
		var dst = NativeArrayTools.alloc(newSize);
		
		if (oldSize < newSize)
		{
			if (mFront + size > oldSize)
			{
				var n1 = oldSize - mFront;
				var n2 = oldSize - n1;
				mData.blit(mFront, dst, 0, n1);
				mData.blit(0, dst, n1, n2);
			}
			else
				mData.blit(mFront, dst, 0, size);
		}
		else
		{
			if (mFront + size > oldSize)
			{
				var n1 = oldSize - mFront;
				var n2 = size - mFront;
				mData.blit(mFront, dst, 0, n1);
				mData.blit(0, dst, mFront, n2);
			}
			else
				mData.blit(mFront, dst, 0, size);
		}
		
		mData = dst;
		mFront = 0;
	}
}

#if generic
@:generic
#end
@:access(de.polygonal.ds.ArrayedQueue)
@:dox(hide)
class ArrayedQueueIterator<T> implements de.polygonal.ds.Itr<T>
{
	var mObject:ArrayedQueue<T>;
	var mData:NativeArray<T>;
	var mFront:Int;
	var mCapacity:Int;
	var mSize:Int;
	var mI:Int;
	
	public function new(x:ArrayedQueue<T>)
	{
		mObject = x;
		reset();
	}
	
	public function free()
	{
		mObject = null;
		mData = null;
	}
	
	public function reset():Itr<T>
	{
		mFront = mObject.mFront;
		mCapacity = mObject.capacity;
		mSize = mObject.size;
		mI = 0;
		mData = mObject.mData.copy();
		return this;
	}
	
	public inline function hasNext():Bool
	{
		return mI < mSize;
	}
	
	public inline function next():T
	{
		return mData.get((mI++ + mFront) % mCapacity);
	}
	
	public function remove()
	{
		assert(mI > 0, "call next() before removing an element");
		
		mObject.remove(mData.get(((mI - 1) + mFront) % mCapacity));
	}
}