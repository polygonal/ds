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
package de.polygonal.ds;

import de.polygonal.ds.tools.ArrayTools;
import de.polygonal.ds.tools.Assert.assert;
import de.polygonal.ds.tools.GrowthRate;
import de.polygonal.ds.tools.MathTools;
import de.polygonal.ds.tools.Shuffle;

using de.polygonal.ds.tools.NativeArrayTools;

/**
	An arrayed queue based on an arrayed circular queue
	
	A queue is a linear list for which all insertions are made at one end of the list; all deletions (and usually all accesses) are made at the other end.
	
	This is called a FIFO structure (First In, First Out).
	
	Example:
		var o = new de.polygonal.ds.ArrayedQueue<Int>(4);
		for (i in 0...o.capacity) o.enqueue(i);
		trace(o); //outputs:
		
		[ ArrayedQueue size=4 capacity=4
		  front
		  0 -> 0
		  1 -> 1
		  2 -> 2
		  3 -> 3
		]
**/
#if generic
@:generic
#end
class ArrayedQueue<T> implements Queue<T>
{
	/**
		A unique identifier for this object.
		
		A hash table transforms this key into an index of an array element by using a hash function.
	**/
	public var key(default, null):Int = HashKey.next();
	
	/**
		The size of the allocated storage space for the elements.
		If more space is required to accommodate new elements, `capacity` grows according to `this.growthRate`.
		The capacity never falls below the initial size defined in the constructor and is usually a bit larger than `this.size` (_mild overallocation_).
	**/
	public var capacity(default, null):Int;
	
	/**
		The growth rate of the container.
		@see `GrowthRate`
	**/
	public var growthRate:Int = GrowthRate.NORMAL;
	
	/**
		If true, reuses the iterator object instead of allocating a new one when calling `this.iterator()`.
		
		The default is false.
		
		_If this value is true, nested iterations will fail as only one iteration is allowed at a time._
	**/
	public var reuseIterator:Bool = false;
	
	var mData:NativeArray<T>;
	var mInitialCapacity:Int;
	var mSize:Int = 0;
	var mFront:Int = 0;
	var mIterator:ArrayedQueueIterator<T> = null;
	
	/**
		@param initialCapacity the initial physical space for storing values.
		<br/>Useful before inserting a large number of elements as this reduces the amount of incremental reallocation.
		@param source copies all values from `source` in the range [0, `source.length` - 1] to this collection.
		@param fixed If true, growthRate is set to FIXED
	**/
	public function new(initialCapacity:Null<Int> = 16, ?source:Array<T>, ?fixed:Bool)
	{
		mInitialCapacity = MathTools.max(1, initialCapacity);
		capacity = mInitialCapacity;
		
		if (source != null)
		{
			mSize = source.length;
			capacity = MathTools.max(mSize, capacity);
		}
		
		mData = NativeArrayTools.alloc(capacity);
		
		if (source != null)
		{
			var d = mData;
			for (i in 0...mSize) d.set(i, source[i]);
		}
		
		if (fixed) growthRate = GrowthRate.FIXED;
	}
	
	/**
		Returns the front element. This is the "oldest" element.
	**/
	public inline function peek():T
	{
		assert(size > 0, "queue is empty");
		
		return mData.get(mFront);
	}
	
	/**
		Returns the rear element.
		
		This is the "newest" element.
	**/
	public inline function back():T
	{
		assert(size > 0, "queue is empty");
		
		return mData.get(((size - 1) + mFront) % capacity);
	}
	
	/**
		Enqueues `val`.
	**/
	public inline function enqueue(val:T)
	{
		if (capacity == size) grow();
		mData.set((mSize++ + mFront) % capacity, val);
	}
	
	/**
		Faster than `this.enqueue()` by skipping boundary checking.
		
		The user is responsible for making sure that there is enough space available (e.g. by calling `this.reserve()`).
	**/
	public inline function unsafeEnqueue(val:T):ArrayedQueue<T>
	{
		assert(mSize < capacity, "out of space");
		
		mData.set((mSize++ + mFront) % capacity, val);
		return this;
	}
	
	/**
		Dequeues and returns the front element.
	**/
	public inline function dequeue():T
	{
		assert(size > 0, "queue is empty");
		
		var x = mData.get(mFront++);
		if (mFront == capacity) mFront = 0;
		mSize--;
		return x;
	}
	
	/**
		Reduces the capacity of the internal container to the initial capacity.
		
		May cause a reallocation, but has no effect on `this.size` and its elements.
		An application can use this operation to free up memory by unlocking resources for the garbage collector.
	**/
	public function pack():ArrayedQueue<T>
	{
		if (capacity > mInitialCapacity)
		{
			var oldCapacity = capacity;
			capacity = MathTools.max(size, mInitialCapacity);
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
		return this;
	}
	
	/**
		Preallocates storage for `n` elements.
		
		May cause a reallocation, but has no effect on `this.size` and its elements.
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
		
		The index is measured relative to the index of the front element (=0).
	**/
	public inline function get(i:Int):T
	{
		assert(size > 0, "queue is empty");
		assert(i < size, 'i index out of range ($i)');
		
		return mData.get((i + mFront) % capacity);
	}
	
	/**
		Replaces the element at index `i` with `val`.
		
		The index is measured relative to the index of the front element (=0).
	**/
	public inline function set(i:Int, val:T):ArrayedQueue<T>
	{
		assert(size > 0, "queue is empty");
		assert(i < size, 'i index out of range ($i)');
		
		mData.set((i + mFront) % capacity, val);
		return this;
	}
	
	/**
		Swaps the element at index `i` with the element at index `j`.
		
		The index is measured relative to the index of the front element (=0).
	**/
	public inline function swap(i:Int, j:Int):ArrayedQueue<T>
	{
		assert(size > 0, "queue is empty");
		assert(i < size, 'i index out of range ($i)');
		assert(j < size, 'j index out of range ($j)');
		assert(i != j, 'i index equals j index ($i)');
		
		var t = get(i);
		copy(i, j);
		set(j, t);
		return this;
	}
	
	/**
		Replaces the element at index `i` with the element from index `j`.
		
		The index is measured relative to the index of the front element (=0).
	**/
	public inline function copy(i:Int, j:Int):ArrayedQueue<T>
	{
		assert(size > 0, "queue is empty");
		assert(i < size, 'i index out of range ($i)');
		assert(j < size, 'j index out of range ($j)');
		assert(i != j, 'i index equals j index ($i)');
		
		set(i, get(j));
		return this;
	}
	
	/**
		Calls `f` on all elements.
		
		The function signature is: `f(input, index):output`
		
		- input: current element
		- index: position relative to the front(=0) of the queue
		- output: element to be stored at given index
	**/
	public inline function forEach(f:T->Int->T):ArrayedQueue<T>
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
		Calls 'f` on all elements in order.
	**/
	public inline function iter(f:T->Void):ArrayedQueue<T>
	{
		assert(f != null);
		var front = mFront, d = mData;
		for (i in 0...size) f(d.get((i + front) % capacity));
		return this;
	}
	
	/**
		Shuffles the elements of this collection by using the Fisher-Yates algorithm.
		@param rvals a list of random double values in the interval [0, 1) defining the new positions of the elements.
		If omitted, random values are generated on-the-fly by calling `Shuffle.frand()`.
	**/
	public function shuffle(rvals:Array<Float> = null):ArrayedQueue<T>
	{
		var s = size, d = mData;
		if (rvals == null)
		{
			var i, t;
			while (s > 1)
			{
				s--;
				i = (Std.int(Shuffle.frand() * s) + mFront) % capacity;
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
		return this;
	}
	
	/**
		Prints out all elements.
	**/
	#if !no_tostring
	public function toString():String
	{
		var b = new StringBuf();
		b.add('[ ArrayedQueue size=$size capacity=$capacity');
		if (isEmpty())
		{
			b.add(" ]");
			return b.toString();
		}
		b.add("\n  front\n");
		var fmt = '  %${MathTools.numDigits(size)}d -> %s\n';
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
	#end
	
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
		Returns true if this queue contains `val`.
	**/
	public function contains(val:T):Bool
	{
		var d = mData;
		for (i in 0...size)
		{
			if (d.get((i + mFront) % capacity) == val)
				return true;
		}
		return false;
	}
	
	/**
		Removes and nullifies all occurrences of `val`.
		@return true if at least one occurrence of `val` was removed.
	**/
	public function remove(val:T):Bool
	{
		if (isEmpty()) return false;
		
		var s = size, success = true, d = mData;
		while (s > 0 && success)
		{
			success = false;
			for (i in 0...s)
			{
				if (d.get((i + mFront) % capacity) == val)
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
		if (gc) mData.nullify();
		mFront = mSize = 0;
	}
	
	/**
		Returns a new *ArrayedQueueIterator* object to iterate over all elements contained in this queue.
		
		Preserves the natural order of a queue (First-In-First-Out).
		
		@see http://haxe.org/ref/iterators
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
		var n = MathTools.min(capacity, mFront + size) - mFront;
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
		Creates and returns a shallow copy (structure only - default) or deep copy (structure & elements) of this queue.
		
		If `byRef` is true, primitive elements are copied by value whereas objects are copied by reference.
		
		If `byRef` is false, the `copier` function is used for copying elements. If omitted, `clone()` is called on each element assuming all elements implement `Cloneable`.
	**/
	public function clone(byRef:Bool = true, copier:T->T = null):Collection<T>
	{
		var copy = new ArrayedQueue<T>(capacity);
		if (isEmpty()) return copy;
		
		var src = mData;
		var dst = copy.mData;
		if (byRef)
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