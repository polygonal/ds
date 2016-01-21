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
	An arrayed queue based on an arrayed circular queue
	
	A queue is a linear list for which all insertions are made at one end of the list; all deletions (and usually all accesses) are made at the other end.
	
	This is called a FIFO structure (First In, First Out).
	
	See <a href="http://lab.polygonal.de/?p=189" target="mBlank">http://lab.polygonal.de/?p=189</a>
	
	_<o>Worst-case running time in Big O notation</o>_
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
	public var key:Int;
	
	/**
		The maximum allowed size of this queque.
		
		Once the maximum size is reached, adding an element will fail with an error (debug only).
		
		A value of -1 indicates that the size is unbound.
		
		<warn>Always equals -1 in release mode.</warn>
	**/
	public var maxSize:Int;
	
	/**
		If true, reuses the iterator object instead of allocating a new one when calling ``iterator()``.
		
		The default is false.
		
		<warn>If true, nested iterations are likely to fail as only one iteration is allowed at a time.</warn>
	**/
	public var reuseIterator:Bool;
	
	var mData:Vector<T>;
	
	var mSize:Int;
	var mSizeLevel:Int;
	var mFront:Int;
	var mCapacity:Int;
	var mIsResizable:Bool;
	var mIterator:ArrayedQueueIterator<T>;
	
	#if debug
	var mOp0:Int;
	var mOp1:Int;
	#end
	
	/**
		<assert>reserved size is greater than allowed size</assert>
		@param capacity the initial physical space for storing the elements at the time the queue is created.
		This is also the minimum size of this queue.
		The `capacity` is automatically adjusted according to the storage requirements based on three rules:
		<ul>
		<li>If this queue runs out of space, the `capacity` is doubled (if `isResizable` is true)</li>
		<li>If the ``size()`` falls below a quarter of the current `capacity`, the `capacity` is cut in half</li>
		<li>The minimum `capacity` equals `capacity`</li>
		</ul>
		@param isResizable if true, the `capacity` is automatically adjusted.
		Otherwise `capacity` defines both the minimum and maximum allowed `capacity`.
		Default is true.
		@param maxSize the maximum allowed size of this queue.
		The default value of -1 indicates that there is no upper limit.
	**/
	public function new(capacity:Int, isResizable = true, maxSize = -1)
	{
		#if debug
		mOp0 = mOp1 = 0;
		this.maxSize = (maxSize == -1) ? M.INT32_MAX : maxSize;
		#else
		this.maxSize = -1;
		#end
		
		#if debug
		mOp0 = 0;
		mOp1 = 0;
		#end
		
		mCapacity = capacity;
		mIsResizable = isResizable;
		mSizeLevel = 0;
		mSize = mFront = 0;
		mData = new Vector<T>(mCapacity);
		mIterator = null;
		key = HashKey.next();
		reuseIterator = false;
	}
	
	/**
		Returns the front element. This is the "oldest" element.
		<o>1</o>
		<assert>queue is empty</assert>
	**/
	inline public function peek():T
	{
		assert(mSize > 0, "queue is empty");
		
		return _get(mFront);
	}
	
	/**
		Returns the rear element.
		
		This is the "newest" element.
		<o>1</o>
		<assert>queue is empty</assert>
	**/
	inline public function back():T
	{
		assert(mSize > 0, "queue is empty");
		
		return _get((mSize - 1 + mFront) % mCapacity);
	}
	
	/**
		Enqueues the element `x`.
		<o>1</o>
		<assert>``size()`` equals ``maxSize``</assert>
		<assert>out of space - queue is full but not resizable</assert>
	**/
	public function enqueue(x:T)
	{
		#if debug
		if (maxSize != -1)
			assert(mSize < maxSize, 'size equals max size ($maxSize)');
		++mOp1;
		#end
		
		if (mCapacity == mSize)
		{
			#if debug
			if (!mIsResizable)
				assert(false, 'out of space ($mCapacity)');
			#end
			
			if (mIsResizable)
			{
				mSizeLevel++;
				_pack(mCapacity << 1);
				mFront = 0;
				mCapacity <<= 1;
			}
		}
		
		_set((mSize++ + mFront) % mCapacity, x);
	}
	
	/**
		Dequeues and returns the front element.
		
		To allow instant garbage collection of the dequeued element call ``dequeue()`` followed by ``dispose()``.
		<o>1</o>
		<assert>queue is empty</assert>
	**/
	public function dequeue():T
	{
		assert(mSize > 0, "queue is empty");
		
		#if debug
		mOp0 = ++mOp1;
		#end
		
		var x = _get(mFront++);
		if (mFront == mCapacity) mFront = 0;
		mSize--;
		
		if (mIsResizable && mSizeLevel > 0)
		{
			if (mSize == mCapacity >> 2)
			{
				mSizeLevel--;
				_pack(mCapacity >> 2);
				mFront = 0;
				mCapacity >>= 2;
			}
		}
		
		return x;
	}
	
	/**
		Nullifies the last dequeued element so it can be garbage collected.
		
		<warn>Use only directly after ``dequeue()``.</warn>
		<o>1</o>
		<assert>``dispose()`` wasn't directly called after ``dequeue()``</assert>
	**/
	inline public function dispose()
	{
		assert(mOp0 == mOp1, "dispose() is only allowed directly after dequeue()");
		
		_set((mFront == 0 ? mCapacity : mFront) - 1, cast null);
	}
	
	/**
		For performance reasons the queue does nothing to ensure that empty locations contain null;
		``pack()`` therefore nullifies all obsolete references.
		<o>n</o>
	**/
	public function pack()
	{
		var i = mFront + mSize;
		for (j in 0...mCapacity - mSize)
			_set((j + i) % mCapacity, cast null);
	}
	
	/**
		Returns the element at index `i`.
		
		The index is measured relative to the index of the front element (= 0).
		<o>1</o>
		<assert>queue is empty</assert>
		<assert>`i` out of range</assert>
	**/
	inline public function get(i:Int):T
	{
		assert(mSize > 0, "queue is empty");
		assert(i < mSize, 'i index out of range ($i)');
		
		return _get((i + mFront) % mCapacity);
	}
	
	/**
		Replaces the element at index `i` with the element `x`.
		
		The index is measured relative to the index of the front element (= 0).
		<o>1</o>
		<assert>queue is empty</assert>
		<assert>`i` out of range</assert>
	**/
	inline public function set(i:Int, x:T)
	{
		assert(mSize > 0, "queue is empty");
		assert(i < mSize, 'i index out of range ($i)');
		
		_set((i + mFront) % mCapacity, x);
	}
	
	/**
		Swaps the element at index `i` with the element at index `j`.
		
		The index is measured relative to the index of the front element (= 0).
		<o>1</o>
		<assert>queue is empty</assert>
		<assert>`i`/`j` out of range</assert>
		<assert>`i` equals `j`</assert>
	**/
	inline public function swp(i:Int, j:Int)
	{
		assert(mSize > 0, "queue is empty");
		assert(i < mSize, 'i index out of range ($i)');
		assert(j < mSize, 'j index out of range ($j)');
		assert(i != j, 'i index equals j index ($i)');
		
		var t = get(i);
		cpy(i, j);
		set(j, t);
	}
	
	/**
		Replaces the element at index `i` with the element from index `j`.
		
		The index is measured relative to the index of the front element (= 0).
		<o>1</o>
		<assert>queue is empty</assert>
		<assert>`i`/`j` out of range</assert>
		<assert>`i` equals `j`</assert>
	**/
	inline public function cpy(i:Int, j:Int)
	{
		assert(mSize > 0, "queue is empty");
		assert(i < mSize, 'i index out of range ($i)');
		assert(j < mSize, 'j index out of range ($j)');
		assert(i != j, 'i index equals j index ($i)');
		
		set(i, get(j));
	}
	
	/**
		Replaces up to `n` existing elements with objects of type `cl`.
		<o>n</o>
		<assert>`n` out of range</assert>
		@param cl the class to instantiate for each element.
		@param args passes additional constructor arguments to the class `cl`.
		@param n the number of elements to replace. If 0, `n` is set to ``getCapacity()``.
	**/
	public function assign(cl:Class<T>, args:Array<Dynamic> = null, n = 0)
	{
		assert(n >= 0);
		
		var k = n > 0 ? n : mCapacity;
		
		assert(k <= mCapacity, 'n out of range ($n)');
		
		if (args == null) args = [];
		for (i in 0...k)
			_set((i + mFront) % mCapacity, Type.createInstance(cl, args));
		
		mSize = k;
	}
	
	/**
		Replaces up to `n` existing elements with the instance `x`.
		<o>n</o>
		<assert>`n` out of range</assert>
		@param n the number of elements to replace. If 0, `n` is set to ``getCapacity()``.
	**/
	public function fill(x:T, n = 0):ArrayedQueue<T>
	{
		assert(n >= 0);
		
		var k = n > 0 ? n : mCapacity;
		
		assert(k <= mCapacity, 'n out of range ($n)');
		
		for (i in 0...k)
			_set((i + mFront) % mCapacity, x);
		
		mSize = k;
		return this;
	}
	
	/**
		Invokes the `process` function for each element.
		
		The function signature is: ``process(oldValue, index):newValue``
		<o>n</o>
	**/
	public function iter(process:T->Int->T)
	{
		for (i in 0...mCapacity)
		{
			var j = (i + mFront) % mCapacity;
			_set(j, process(_get(j), i));
		}
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
		var s = mSize;
		if (rval == null)
		{
			var m = Math;
			while (s > 1)
			{
				s--;
				var i = (Std.int(m.random() * s) + mFront) % mCapacity;
				var t = _get(s);
				_set(s, _get(i));
				_set(i, t);
			}
		}
		else
		{
			assert(rval.length >= mSize, "insufficient random values");
			
			var j = 0;
			while (s > 1)
			{
				s--;
				var i = (Std.int(rval[j++] * s) + mFront) % mCapacity;
				var t = _get(s);
				_set(s, _get(i));
				_set(i, t);
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
		var s = '{ ArrayedQueue size/capacity: $mSize/$mCapacity }';
		if (isEmpty()) return s;
		s += "\n[ front\n";
		for (i in 0...mSize)
			s += Printf.format("  %4d -> %s\n", [i, Std.string(get(i))]);
		s += "]";
		return s;
	}
	
	/**
		The size of the allocated storage space for the elements.
		
		If more space is required to accomodate new elements, the capacity is doubled every time ``size()`` grows beyond capacity, and split in half when ``size()`` is a quarter of capacity.
		The capacity never falls below the initial size defined in the constructor.
		<o>1</o>
	**/
	inline public function getCapacity():Int
	{
		return mCapacity;
	}
	
	/**
		Returns true if this queue is full.
		<o>1</o>
	**/
	inline public function isFull():Bool
	{
		return mSize == mCapacity;
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
		for (i in 0...mCapacity) mData[i] = cast null;
		mData = null;
		mIterator = null;
	}
	
	/**
		Returns true if this queue contains the element `x`.
		<o>n</o>
	**/
	public function contains(x:T):Bool
	{
		for (i in 0...mSize)
		{
			if (_get((i + mFront) % mCapacity) == x)
				return true;
		}
		return false;
	}
	
	/**
		Removes and nullifies all occurrences of the element `x`.
		<o>n</o>
		@return true if at least one occurrence of `x` was removed.
	**/
	public function remove(x:T):Bool
	{
		if (isEmpty()) return false;
		
		var s = mSize;
		var found = false;
		while (mSize > 0)
		{
			found = false;
			for (i in 0...mSize)
			{
				if (_get((i + mFront) % mCapacity) == x)
				{
					found = true;
					_set((i + mFront) % mCapacity, cast null);
					
					if (i == 0)
					{
						if (++mFront == mCapacity) mFront = 0;
						mSize--;
					}
					else
					if (i == mSize - 1)
						mSize--;
					else
					{
						var i0 = (mFront + i);
						var i1 = (mFront + mSize - 1);
						
						for (j in i0...i1)
							_set(j % mCapacity, _get((j + 1) % mCapacity));
						_set(i1 % mCapacity, cast null);
						
						mSize--;
					}
					break;
				}
			}
			
			if (!found) break;
		}
		
		if (mIsResizable && mSize < s)
		{
			if (mSizeLevel > 0 && mCapacity > 2)
			{
				var s = mCapacity;
				while (mSize <= s >> 2)
				{
					s >>= 2;
					mSizeLevel--;
				}
				
				_pack(s);
				mFront = 0;
				mCapacity = s;
			}
		}
		
		return mSize < s;
	}
	
	/**
		Removes all elements.
		<o>1 or n if `purge` is true</o>
		@param purge if true, elements are nullified upon removal and ``getCapacity()`` is set to the initial capacity defined in the constructor.
	**/
	public function clear(purge = false)
	{
		if (purge)
		{
			var i = mFront;
			for (j in 0...mSize) _set(i++ % mCapacity, cast null);
			
			if (mIsResizable && mSizeLevel > 0)
			{
				mCapacity >>= mSizeLevel;
				mSizeLevel = 0;
				mData = new Vector<T>(mCapacity);
			}
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
		The total number of elements.
		<o>1</o>
	**/
	inline public function size():Int
	{
		return mSize;
	}
	
	/**
		Returns true if this queue is empty.
		<o>1</o>
	**/
	inline public function isEmpty():Bool
	{
		return mSize == 0;
	}
	
	/**
		Returns an array containing all elements in this queue.
		
		Preserves the natural order of this queue (First-In-First-Out).
	**/
	public function toArray():Array<T>
	{
		var a:Array<T> = ArrayUtil.alloc(mSize);
		for (i in 0...mSize) a[i] = _get((i + mFront) % mCapacity);
		return a;
	}
	
	/**
		Returns a `Vector<T>` object containing all elements in this queue.
		
		Preserves the natural order of this queue (First-In-First-Out).
	**/
	public function toVector():Vector<T>
	{
		var v = new Vector<T>(mSize);
		for (i in 0...mSize) v[i] = _get((i + mFront) % mCapacity);
		return v;
	}
	
	/**
		Duplicates this queue. Supports shallow (structure only) and deep copies (structure & elements).
		<assert>element is not of type `Cloneable`</assert>
		@param assign if true, the `copier` parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.
		If false, the ``clone()`` method is called on each element. <warn>In this case all elements have to implement `Cloneable`.</warn>
		@param copier a custom function for copying elements. Replaces ``element::clone()`` if `assign` is false.
	**/
	public function clone(assign = true, copier:T->T = null):Collection<T>
	{
		var copy = new ArrayedQueue<T>(mCapacity, mIsResizable, maxSize);
		copy.mSizeLevel = mSizeLevel;
		if (mCapacity == 0) return copy;
		
		var t = copy.mData;
		if (assign)
		{
			for (i in 0...mSize)
				t[i] = _get(i);
		}
		else
		if (copier == null)
		{
			var c:Cloneable<Dynamic> = null;
			for (i in 0...mSize)
			{
				assert(Std.is(_get(i), Cloneable), 'element is not of type Cloneable (${_get(i)})');
				
				c = cast(_get(i), Cloneable<Dynamic>);
				t[i] = c.clone();
			}
		}
		else
		{
			for (i in 0...mSize)
				t[i] = copier(_get(i));
		}
		
		copy.mFront = mFront;
		copy.mSize = mSize;
		return copy;
	}
	
	inline function _pack(newSize:Int)
	{
		var tmp = new Vector<T>(newSize);
		for (i in 0...mSize)
		{
			tmp[i] = _get(mFront++);
			if (mFront == mCapacity) mFront = 0;
		}
		mData = tmp;
	}
	
	inline function _get(i:Int) return mData[i];
	
	inline function _set(i:Int, x:T) mData[i] = x;
}

#if generic
@:generic
#end
@:access(de.polygonal.ds.ArrayedQueue)
@:dox(hide)
class ArrayedQueueIterator<T> implements de.polygonal.ds.Itr<T>
{
	var mF:ArrayedQueue<T>;
	
	var mData:Vector<T>;
	var mFront:Int;
	var mCapacity:Int;
	var mSize:Int;
	var mI:Int;
	
	public function new(f:ArrayedQueue<T>)
	{
		mF = f;
		reset();
	}
	
	public function reset():Itr<T>
	{
		mFront = mF.mFront;
		mCapacity = mF.mCapacity;
		mSize = mF.mSize;
		mI = 0;
		
		var tmp = mF.mData;
		mData = new Vector<T>(mCapacity);
		for (i in 0...mCapacity) mData[i] = tmp[i];
		return this;
	}
	
	inline public function hasNext():Bool
	{
		return mI < mSize;
	}
	
	inline public function next():T
	{
		return mData[(mI++ + mFront) % mCapacity];
	}
	
	inline public function remove()
	{
		assert(mI > 0, "call next() before removing an element");
		
		mF.remove(mData[((mI - 1) + mFront) % mCapacity]);
	}
}