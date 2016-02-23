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
import haxe.ds.ObjectMap;

using de.polygonal.ds.tools.NativeArrayTools;

/**
	A priority queue is heap but with a simplified API for managing prioritized data
	
	Adds additional methods for removing and re-prioritizing elements.
**/
#if generic
@:generic
#end
@:allow(de.polygonal.ds.Heap)
class PriorityQueue<T:(Prioritizable)> implements Queue<T>
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
	var mInverse:Bool;
	var mIterator:PriorityQueueIterator<T> = null;
	
	#if debug
	var mMap:haxe.ds.ObjectMap<T, Bool>;
	#end
	
	/**
		@param inverse if true, the lower the number, the higher the priority.
		By default a higher number means a higher priority.
		@param reservedSize the initial capacity of the internal container. See `reserve()`.
	**/
	public function new(initalCapacity:Null<Int> = 1, ?inverse:Null<Bool> = false, ?source:Array<T>)
	{
		mInitialCapacity = M.max(1, initalCapacity);
		capacity = initalCapacity;
		mInverse = inverse;
		
		if (source != null)
		{
			mSize = source.length;
			capacity = M.max(mSize, capacity);
		}
		
		mData = NativeArrayTools.alloc(capacity + 1);
		mData.set(0, cast null); //reserved
		
		#if debug
		mMap = new haxe.ds.ObjectMap<T, Bool>();
		#end
		
		if (source != null)
		{
			var d = mData;
			for (i in 1...mSize + 1) d.set(i, source[i - 1]);
			repair();
		}
	}
	
	/**
		For performance reasons the priority queue does nothing to ensure that empty locations contain null;
		`pack()` therefore nullifies all obsolete references and shrinks the container to the actual size allowing the garbage collector to reclaim used memory.
	**/
	public function pack()
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
	
	/**
		Preallocates storage for `n` elements.
		
		Useful before inserting a large number of elements as this reduces the amount of incremental reallocation.
	**/
	/*public function reserve(n:Int):PriorityQueue<T>
	{
		if (n <= capacity) return this;
		
		capacity = n;
		mShrinkSize = n >> 2;
		grow(n);
		
		return this;
	}*/
	
	/**
		Returns the front element.
		
		This is the element with the highest priority.
		<assert>priority queue is empty</assert>
	**/
	public inline function peek():T
	{
		assert(size > 0, "priority queue is empty");
		
		return mData.get(1);
	}
	
	/**
		Returns the rear element.
		
		This is the element with the lowest priority.
		<assert>priority queue is empty</assert>
	**/
	public function back():T
	{
		assert(size > 0, "priority queue is empty");
		
		if (size == 1) return mData.get(1);
		
		var d = mData;
		var a = d.get(1), b;
		if (mInverse)
		{
			for (i in 2...size + 1)
			{
				b = d.get(i);
				if (a.priority < b.priority) a = b;
			}
		}
		else
		{
			for (i in 2...size + 1)
			{
				b = d.get(i);
				if (a.priority > b.priority) a = b;
			}
		}
		return a;
	}
	
	/**
		Enqueues the element `x`.
		<assert>`x` is null or `x` already exists</assert>
	**/
	public function enqueue(x:T)
	{
		#if debug
		assert(x != null, "element is null");
		assert(!mMap.exists(x), "element already exists");
		mMap.set(x, true);
		#end
		
		if (size == capacity) grow();
		mData.set(++mSize, x);
		x.position = size;
		upheap(size);
	}
	
	/**
		Dequeues the front element.
		<assert>priority queue is empty</assert>
	**/
	public function dequeue():T
	{
		assert(size > 0, "priority queue is empty");
		
		var d = mData;
		var x = d.get(1), d = mData;
		x.position = -1;
		d.set(1, d.get(size));
		downheap(1);
		
		#if debug
		mMap.remove(x);
		#end
		
		mSize--;
		return x;
	}
	
	/**
		Reprioritizes the element `x`.
		<assert>priority queue is empty or `x` does not exist</assert>
		@param x the element to re-prioritize.
		@param priority the new priority.
	**/
	public function reprioritize(x:T, priority:Float)
	{
		assert(size > 0, "priority queue is empty");
		
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
				upheap(size);
			}
		}
		else
		{
			if (priority > oldPriority)
				upheap(pos);
			else
			{
				downheap(pos);
				upheap(size);
			}
		}
	}
	
	/**
		Returns a sorted array of all elements.
	**/
	public function sort():Array<T>
	{
		if (isEmpty()) return [];
		
		var out = ArrayTools.alloc(size);
		var t = mData.copy();
		var k = size;
		var j = 0, i, c, v, s, u;
		
		if (mInverse)
		{
			while (k > 0)
			{
				out[j++] = t.get(1);
				t.set(1, t.get(k));
				i = 1;
				c = i << 1;
				v = t.get(i);
				s = k - 1;
				while (c < k)
				{
					if (c < s)
						if (t.get(c).priority - t.get(c + 1).priority > 0)
							c++;
					
					u = t.get(c);
					if (v.priority - u.priority > 0)
					{
						t.set(i, u);
						i = c;
						c <<= 1;
					}
					else break;
				}
				t.set(i, v);
				k--;
			}
		}
		else
		{
			while (k > 0)
			{
				out[j++] = t.get(1);
				t.set(1, t.get(k));
				i = 1;
				c = i << 1;
				v = t.get(i);
				s = k - 1;
				while (c < k)
				{
					if (c < s)
						if (t.get(c).priority - t.get(c + 1).priority < 0)
							c++;
					
					u = t.get(c);
					if (v.priority - u.priority < 0)
					{
						t.set(i, u);
						i = c;
						c <<= 1;
					}
					else break;
				}
				t.set(i, v);
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
		var b = new StringBuf();
		b.add('{ PriorityQueue size: ${size} }');
		if (isEmpty()) return b.toString();
		var t = sort();
		b.add("\n[ front\n");
		var i = 0, args = new Array<Dynamic>();
		var fmt = '  %${M.numDigits(size)}d: %s\n';
		for (i in 0...size)
		{
			args[0] = i;
			args[1] = Std.string(t[i]);
			b.add(Printf.format(fmt, args));
		}
		b.add("]");
		return b.toString();
	}
	
	/**
		Preallocates storage for `n` elements.
		
		May cause a reallocation, but has no effect on the vector size and its elements.
		Useful before inserting a large number of elements as this reduces the amount of incremental reallocation.
	**/
	public function reserve(n:Int):PriorityQueue<T>
	{
		if (n > capacity)
		{
			capacity = n;
			resizeContainer(n);
		}
		return this;
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
		
		#if debug
		mMap = null;
		#end
	}
	
	/**
		Returns true if this priority queue contains the element `x`.
		<assert>`x` is invalid</assert>
	**/
	public inline function contains(x:T):Bool
	{
		assert(x != null, "x is null");
		
		var position = x.position;
		return (position > 0 && position <= size) && (mData.get(position) == x);
	}
	
	/**
		Removes the element `x`.
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
				d.set(p, d.get(size));
				downheap(p);
				upheap(p);
				mSize--;
			}
			return true;
		}
	}
	
	/**
		Removes all elements.
		@param gc if true, elements are nullified upon removal so the garbage collector can reclaim used memory.
	**/
	public function clear(gc:Bool = false)
	{
		#if debug
		mMap = new haxe.ds.ObjectMap<T, Bool>();
		#end
		
		if (gc) mData.nullify();
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
		Returns true if this priority queue is empty.
	**/
	public inline function isEmpty():Bool
	{
		return size == 0;
	}
	
	/**
		Returns an unordered array containing all elements in this priority queue.
	**/
	public function toArray():Array<T>
	{
		return mData.toArray(1, size);
	}
	
	/**
		Duplicates this priority queue. Supports shallow (structure only) and deep copies (structure & elements).
		<assert>element is not of type `Cloneable`</assert>
		@param assign if true, the `copier` parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.
		If false, the ``clone()`` method is called on each element. <warn>In this case all elements have to implement `Cloneable`.</warn>
		@param copier a custom function for copying elements. Replaces ``element::clone()`` if `assign` is false.
		<warn>If `assign` is true, only the copied version should be used from now on.</warn>
	**/
	public function clone(assign:Bool = true, copier:T->T = null):Collection<T>
	{
		var copy = new PriorityQueue<T>(capacity, mInverse);
		if (size == 0) return copy;
		
		var src = mData;
		var dst = copy.mData;
		if (assign)
		{
			src.blit(1, dst, 1, size + 1);
			
			#if debug
			for (i in 1...size + 1) copy.mMap.set(src.get(i), true);
			#end
		}
		else
		if (copier == null)
		{
			var e, c;
			for (i in 1...size + 1)
			{
				e = src.get(i);
				assert(Std.is(e, Cloneable), "element is not of type Cloneable");
				
				c = cast(e, Cloneable<Dynamic>).clone();
				c.position = e.position;
				c.priority = e.priority;
				dst.set(i, cast c);
				
				#if debug
				copy.mMap.set(cast c, true);
				#end
			}
		}
		else
		{
			var e, c;
			for (i in 1...size + 1)
			{
				e = src.get(i);
				c = copier(e);
				c.position = e.position;
				c.priority = e.priority;
				dst.set(i, c);
				
				#if debug
				copy.mMap.set(e, true);
				#end
			}
		}
		
		copy.mSize = size;
		return copy;
	}
	
	inline function upheap(index:Int)
	{
		var d = mData;
		var parent = index >> 1;
		var t = d.get(index);
		var p = t.priority;
		
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
		
		d.set(index, t);
		t.position = index;
	}
	
	inline function downheap(index:Int)
	{
		var d = mData;
		var child = index << 1;
		var childVal:T;
		var t = d.get(index);
		var p = t.priority;
		
		if (mInverse)
		{
			while (child < size)
			{
				if (child < size - 1)
					if (d.get(child).priority - d.get(child + 1).priority > 0)
						child++;
				
				childVal = d.get(child);
				if (p - childVal.priority > 0)
				{
					d.set(index, childVal);
					childVal.position = index;
					t.position = child;
					index = child;
					child <<= 1;
				}
				else break;
			}
		}
		else
		{
			while (child < size)
			{
				if (child < size - 1)
					if (d.get(child).priority - d.get(child + 1).priority < 0)
						child++;
				
				childVal = d.get(child);
				if (p - childVal.priority < 0)
				{
					d.set(index, childVal);
					childVal.position = index;
					t.position = child;
					index = child;
					child <<= 1;
				}
				else break;
			}
		}
		
		d.set(index, t);
		t.position = index;
	}
	
	function repair()
	{
		var i = size >> 1;
		while (i >= 1)
		{
			heapify(i, size);
			i--;
		}
	}
	
	function heapify(p:Int, s:Int)
	{
		var d = mData;
		var l = p << 1;
		var r = l + 1;
		var max = p;
		
		if (mInverse)
		{
			if (l <= s && (d.get(l).priority - d.get(max).priority) < 0) max = l;
			if (l + 1 <= s && (d.get(l + 1).priority - d.get(max).priority) < 0) max = r;
		}
		else
		{
			if (l <= s && (d.get(l).priority - d.get(max).priority) > 0) max = l;
			if (l + 1 <= s && (d.get(l + 1).priority - d.get(max).priority) > 0) max = r;
		}
		
		var a, b, t;
		if (max != p)
		{
			a = d.get(max);
			b = d.get(p);
			d.set(max, b);
			d.set(p, a);
			t = a.position;
			a.position = b.position;
			b.position = t;
			heapify(max, s);
		}
	}
	
	function grow()
	{
		capacity = GrowthRate.compute(growthRate, capacity);
		resizeContainer(capacity);
	}
	
	function resizeContainer(newSize:Int)
	{
		var t = NativeArrayTools.alloc(newSize + 1);
		mData.blit(0, t, 0, mSize + 1);
		mData = t;
	}
}

#if generic
@:generic
#end
@:access(de.polygonal.ds.PriorityQueue)
@:dox(hide)
class PriorityQueueIterator<T:(Prioritizable)> implements de.polygonal.ds.Itr<T>
{
	var mObject:PriorityQueue<T>;
	var mData:NativeArray<T>;
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
		mS = mObject.size;
		mData = NativeArrayTools.alloc(mS);
		mObject.mData.blit(1, mData, 0, mS);
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
		
		mObject.remove(mData.get(mI - 1));
	}
}