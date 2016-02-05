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
import haxe.ds.ObjectMap;

using de.polygonal.ds.tools.NativeArray;

/**
	A priority queue is heap but with a simplified API for managing prioritized data
	
	Adds additional methods for removing and re-prioritizing elements.
	
	_<o>Worst-case running time in Big O notation</o>_
**/
@:allow(de.polygonal.ds.Heap)
class PriorityQueue<T:(Prioritizable)> implements Queue<T>
{
	/**
		A unique identifier for this object.
		
		A hash table transforms this key into an index of an array element by using a hash function.
		
		<warn>This value should never be changed by the user.</warn>
	**/
	public var key(default, null):Int;
	
	/**
		If true, reuses the iterator object instead of allocating a new one when calling ``iterator()``.
		
		The default is false.
		
		<warn>If true, nested iterations are likely to fail as only one iteration is allowed at a time.</warn>
	**/
	public var reuseIterator:Bool;
	
	public var capacity:Int;
	
	var mCapacityIncrement:Int;
	var mShrinkSize:Int;
	
	var mData:Container<T>;
	var mSize:Int;
	var mInverse:Bool;
	var mIterator:PriorityQueueIterator<T>;
	
	#if debug
	var mMap:haxe.ds.ObjectMap<T, Bool>;
	#end
	
	/**
		@param inverse if true, the lower the number, the higher the priority.
		By default a higher number means a higher priority.
		@param reservedSize the initial capacity of the internal container. See `reserve()`.
	**/
	public function new(initialCapacity:Null<Int> = 16, capacityIncrement:Null<Int> = -1, inverse = false)
	{
		capacity = initialCapacity;
		mCapacityIncrement = capacityIncrement;
		
		mInverse = inverse;
		
		#if debug
		mMap = new haxe.ds.ObjectMap<T, Bool>();
		#end
		
		mData = NativeArray.init(capacity + 1);
		mData.set(0, cast null); //reserved
		mSize = 0;
		mIterator = null;
		
		key = HashKey.next();
		reuseIterator = false;
	}
	
	/**
		For performance reasons the priority queue does nothing to ensure that empty locations contain null;
		`pack()` therefore nullifies all obsolete references and shrinks the container to the actual size allowing the garbage collector to reclaim used memory.
		<o>n</o>
	**/
	public function pack()
	{
		/*if (mData.length - 1 == size()) return;
		
		var tmp = mData;
		mData = ArrayUtil.alloc(size() + 1);
		
		mData.set(0, cast null);
		
		for (i in 1...size() + 1) mData.set(i, tmp.get(i));
		for (i in size() + 1...tmp.length) tmp.set(i, null);*/
	}
	
	/**
		Preallocates storage for `n` elements.
		
		Useful before inserting a large number of elements as this reduces the amount of incremental reallocation.
	**/
	public function reserve(n:Int):PriorityQueue<T>
	{
		if (n <= capacity) return this;
		
		capacity = n;
		mShrinkSize = n >> 2;
		resize(n);
		
		return this;
	}
	
	/**
		Returns the front element.
		
		This is the element with the highest priority.
		<o>1</o>
		<assert>priority queue is empty</assert>
	**/
	inline public function peek():T
	{
		assert(size() > 0, "priority queue is empty");
		
		return mData.get(1);
	}
	
	/**
		Returns the rear element.
		
		This is the element with the lowest priority.
		<o>n</o>
		<assert>priority queue is empty</assert>
	**/
	public function back():T
	{
		assert(size() > 0, "priority queue is empty");
		
		if (mSize == 1) return mData.get(1);
		
		var d = mData;
		var a = d.get(1), b;
		if (mInverse)
		{
			for (i in 2...mSize + 1)
			{
				b = d.get(i);
				if (a.priority < b.priority) a = b;
			}
		}
		else
		{
			for (i in 2...mSize + 1)
			{
				b = d.get(i);
				if (a.priority > b.priority) a = b;
			}
		}
		return a;
	}
	
	/**
		Enqueues the element `x`.
		<o>log n</o>
		<assert>`x` is null or `x` already exists</assert>
	**/
	public function enqueue(x:T)
	{
		#if debug
		assert(x != null, "element is null");
		assert(!mMap.exists(x), "element already exists");
		mMap.set(x, true);
		#end
		
		if (mSize == capacity) grow();
		mData.set(++mSize, x);
		x.position = mSize;
		upheap(mSize);
	}
	
	/**
		Dequeues the front element.
		<o>log n</o>
		<assert>priority queue is empty</assert>
	**/
	public function dequeue():T
	{
		assert(size() > 0, "priority queue is empty");
		
		var d = mData;
		var x = d.get(1), d = mData;
		x.position = -1;
		d.set(1, d.get(mSize));
		downheap(1);
		
		#if debug
		mMap.remove(x);
		#end
		
		mSize--;
		return x;
	}
	
	/**
		Reprioritizes the element `x`.
		<o>log n</o>
		<assert>priority queue is empty or `x` does not exist</assert>
		@param x the element to re-prioritize.
		@param priority the new priority.
	**/
	public function reprioritize(x:T, priority:Float)
	{
		assert(size() > 0, "priority queue is empty");
		
		#if debug
		var exists = mMap.exists(x);
		assert(exists, "unknown element");
		#end
		
		var oldPriority = x.priority;
		if (oldPriority == priority) return;
		
		x.priority = priority;
		var pos = x.position;
		
		if (mInverse)
		{
			if (priority < oldPriority)
				upheap(pos);
			else
			{
				downheap(pos);
				upheap(mSize);
			}
		}
		else
		{
			if (priority > oldPriority)
				upheap(pos);
			else
			{
				downheap(pos);
				upheap(mSize);
			}
		}
	}
	
	/**
		Returns a sorted array of all elements.
		<o>n log n</o>
	**/
	public function sort():Array<T>
	{
		if (isEmpty()) return [];
		
		var out = ArrayUtil.alloc(mSize);
		var tmp = NativeArray.copy(mData);
		var k = mSize;
		var j = 0, i, c, v, s, u;
		
		if (mInverse)
		{
			while (k > 0)
			{
				out[j++] = tmp.get(1);
				tmp.set(1, tmp.get(k));
				i = 1;
				c = i << 1;
				v = tmp.get(i);
				s = k - 1;
				while (c < k)
				{
					if (c < s)
						if (tmp.get(c).priority - tmp.get(c + 1).priority > 0)
							c++;
					
					u = tmp.get(c);
					if (v.priority - u.priority > 0)
					{
						tmp.set(i, u);
						i = c;
						c <<= 1;
					}
					else break;
				}
				tmp.set(i, v);
				k--;
			}
		}
		else
		{
			while (k > 0)
			{
				out[j++] = tmp.get(1);
				tmp.set(1, tmp.get(k));
				i = 1;
				c = i << 1;
				v = tmp.get(i);
				s = k - 1;
				while (c < k)
				{
					if (c < s)
						if (tmp.get(c).priority - tmp.get(c + 1).priority < 0)
							c++;
					
					u = tmp.get(c);
					if (v.priority - u.priority < 0)
					{
						tmp.set(i, u);
						i = c;
						c <<= 1;
					}
					else break;
				}
				tmp.set(i, v);
				k--;
			}
		}
		return out;
	}
	
	/**
		Returns a string representing the current object.
		
		Example:
		<pre class="prettyprint">
		class Foo implements de.polygonal.ds.Prioritizable
		{
		    public var priority:Int;
		    public var position:Int;
		    public function new(priority:Int) {
		      this.priority = priority;
		    }
		    public function toString():String {
		      return Std.string(priority);
		    }
		}
		
		class Main
		{
		    static function main() {
		        var pq = new de.polygonal.ds.PriorityQueue<Foo>(4);
		        pq.enqueue(new Foo(5));
		        pq.enqueue(new Foo(3));
		        pq.enqueue(new Foo(0));
		        trace(pq);
		    }
		}</pre>
		<pre class="console">
		{ PriorityQueue size: 3 }
		[ front
		   0 -> 5
		   1 -> 3
		   2 -> 0
		]
		</pre>
	**/
	public function toString():String
	{
		var s = '{ PriorityQueue size: ${size()} }';
		if (isEmpty()) return s;
		
		var tmp = sort();
		s += "\n[ front\n";
		var i = 0;
		for (i in 0...size())
			s += Printf.format("  %4d -> %s\n", [i, Std.string(tmp[i])]);
		s += "]";
		return s;
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
		var d = mData;
		for (i in 0...mData.length) d.set(i, cast null);
		mData = null;
		
		if (mIterator != null)
		{
			mIterator.free();
			mIterator = null;
		}
		
		#if debug
		mMap = null;
		#end
	}
	
	/**
		Returns true if this priority queue contains the element `x`.
		<o>1</o>
		<assert>`x` is invalid</assert>
	**/
	inline public function contains(x:T):Bool
	{
		assert(x != null, "x is null");
		
		var position = x.position;
		return (position > 0 && position <= mSize) && (mData.get(position) == x);
	}
	
	/**
		Removes the element `x`.
		<o>n</o>
		<assert>`x` is invalid or does not exist</assert>
		@return true if `x` was removed.
	**/
	public function remove(x:T):Bool
	{
		if (isEmpty())
			return false;
		else
		{
			assert(x != null, "x is null");
			
			#if debug
			var exists = mMap.exists(x);
			assert(exists, "x does not exist");
			mMap.remove(x);
			#end
			
			if (x.position == 1)
				dequeue();
			else
			{
				var p = x.position, d = mData;
				d.set(p, d.get(mSize));
				downheap(p);
				upheap(p);
				mSize--;
			}
			return true;
		}
	}
	
	/**
		Removes all elements.
		<o>1 or n if `purge` is true</o>
		@param purge if true, elements are nullified upon removal.
	**/
	inline public function clear(purge = false)
	{
		if (purge)
		{
			for (i in 1...mData.length) mData.set(i, cast null);
		}
		
		#if debug
		mMap = new haxe.ds.ObjectMap<T, Bool>();
		#end
		
		mSize = 0;
	}
	
	/**
		Returns a new `PriorityQueueIterator` object to iterate over all elements contained in this priority queue.
		
		The values are visited in an unsorted order.
		
		See <a href="http://haxe.org/ref/iterators" target="mBlank">http://haxe.org/ref/iterators</a>
	**/
	public function iterator():Itr<T>
	{
		if (reuseIterator)
		{
			if (mIterator == null)
				return new PriorityQueueIterator<T>(this);
			else
				mIterator.reset();
			return mIterator;
		}
		else
			return new PriorityQueueIterator<T>(this);
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
		Returns true if this priority queue is empty.
		<o>1</o>
	**/
	inline public function isEmpty():Bool
	{
		return mSize == 0;
	}
	
	/**
		Returns an unordered array containing all elements in this priority queue.
	**/
	public function toArray():Array<T>
	{
		return NativeArray.toArray(mData, 1, size());
	}
	
	/**
		Returns a `Vector<T>` object containing all elements in this priority queue.
	**/
	public function toVector():Container<T>
	{
		var d = mData;
		var v = NativeArray.init(size());
		for (i in 1...mSize + 1) v.set(i - 1, d.get(i));
		return v;
	}
	
	/**
		Duplicates this priority queue. Supports shallow (structure only) and deep copies (structure & elements).
		<assert>element is not of type `Cloneable`</assert>
		@param assign if true, the `copier` parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.
		If false, the ``clone()`` method is called on each element. <warn>In this case all elements have to implement `Cloneable`.</warn>
		@param copier a custom function for copying elements. Replaces ``element::clone()`` if `assign` is false.
		<warn>If `assign` is true, only the copied version should be used from now on.</warn>
	**/
	public function clone(assign = true, copier:T->T = null):Collection<T>
	{
		var copy = new PriorityQueue<T>(capacity, mCapacityIncrement, mInverse);
		
		var src = mData;
		if (mSize == 0) return copy;
		if (assign)
		{
			for (i in 1...mSize + 1)
			{
				copy.mData.set(i, src.get(i));
				
				#if debug
				copy.mMap.set(src.get(i), true);
				#end
			}
		}
		else
		if (copier == null)
		{
			for (i in 1...mSize + 1)
			{
				var e = src.get(i);
				
				assert(Std.is(e, Cloneable), 'element is not of type Cloneable ($e)');
				
				var cl:Cloneable<T> = cast e;
				var c = cl.clone();
				c.position = e.position;
				c.priority = e.priority;
				copy.mData.set(i, c);
				
				#if debug
				copy.mMap.set(c, true);
				#end
			}
		}
		else
		{
			for (i in 1...mSize + 1)
			{
				var e = src.get(i);
				var c = copier(e);
				c.position = e.position;
				c.priority = e.priority;
				copy.mData.set(i, c);
				
				#if debug
				copy.mMap.set(e, true);
				#end
			}
		}
		
		copy.mSize = mSize;
		return copy;
	}
	
	inline function upheap(index:Int)
	{
		var d = mData;
		var parent = index >> 1;
		var tmp = d.get(index);
		var p = tmp.priority;
		
		if (mInverse)
		{
			while (parent > 0)
			{
				var parentVal = d.get(parent);
				if (p - parentVal.priority < 0)
				{
					d.set(index, parentVal);
					parentVal.position = index;
					
					index = parent;
					parent >>= 1;
				}
				else break;
			}
		}
		else
		{
			while (parent > 0)
			{
				var parentVal = d.get(parent);
				if (p - parentVal.priority > 0)
				{
					d.set(index, parentVal);
					parentVal.position = index;
					
					index = parent;
					parent >>= 1;
				}
				else break;
			}
		}
		
		d.set(index, tmp);
		tmp.position = index;
	}
	
	inline function downheap(index:Int)
	{
		var d = mData;
		var child = index << 1;
		var childVal:T;
		var tmp = d.get(index);
		var p = tmp.priority;
		
		if (mInverse)
		{
			while (child < mSize)
			{
				if (child < mSize - 1)
					if (d.get(child).priority - d.get(child + 1).priority > 0)
						child++;
				
				childVal = d.get(child);
				if (p - childVal.priority > 0)
				{
					d.set(index, childVal);
					childVal.position = index;
					tmp.position = child;
					index = child;
					child <<= 1;
				}
				else break;
			}
		}
		else
		{
			while (child < mSize)
			{
				if (child < mSize - 1)
					if (d.get(child).priority - d.get(child + 1).priority < 0)
						child++;
				
				childVal = d.get(child);
				if (p - childVal.priority < 0)
				{
					d.set(index, childVal);
					childVal.position = index;
					tmp.position = child;
					index = child;
					child <<= 1;
				}
				else break;
			}
		}
		
		d.set(index, tmp);
		tmp.position = index;
	}
	
	function grow()
	{
		var tmp = capacity;
		
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
		
		//trace('heap resized from $tmp -> $capacity');
		//mShrinkSize = capacity >> 2;
		
		resize(capacity + 1);
	}
	
	function resize(newSize:Int)
	{
		var tmp = NativeArray.init(newSize + 1);
		NativeArray.blit(mData, 0, tmp, 0, mSize + 1);
		mData = tmp;
	}
}

@:access(de.polygonal.ds.PriorityQueue)
@:dox(hide)
class PriorityQueueIterator<T:(Prioritizable)> implements de.polygonal.ds.Itr<T>
{
	var mObject:PriorityQueue<T>;
	var mData:Container<T>;
	var mI:Int;
	var mS:Int;
	
	public function new(x:PriorityQueue<T>)
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
		mI = 0;
		mS = mObject.size();
		mData = NativeArray.init(mS);
		NativeArray.blit(mObject.mData, 1, mData, 0, mS);
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
		
		mObject.remove(mData.get(mI - 1));
	}
}