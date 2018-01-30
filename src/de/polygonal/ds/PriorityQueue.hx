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

using de.polygonal.ds.tools.NativeArrayTools;

/**
	A priority queue is heap but with a simplified API for managing prioritized data
	
	Adds additional methods for removing and re-prioritizing elements.
	
	Example:
		class Element implements de.polygonal.ds.Prioritizable {
		    public var priority:Int;
		    public var position:Int;
		    public function new(priority:Int) {
		        this.priority = priority;
		    }
		    public function toString():String {
		        return "Element" + priority;
		    }
		}
		
		...
		
		var o = new de.polygonal.ds.PriorityQueue<Element>(4);
		o.enqueue(new Element(3));
		o.enqueue(new Element(0));
		o.enqueue(new Element(5));
		trace(o); //outputs:
		
		[ PriorityQueue size=3
		  front
		  0 -> Element5
		  1 -> Element3
		  2 -> Element0
		]
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
	var mInverse:Bool;
	var mIterator:PriorityQueueIterator<T> = null;
	
	#if debug
	var mMap:haxe.ds.ObjectMap<T, Bool>;
	#end
	
	/**
		@param initialCapacity the initial physical space for storing values.
		Useful before inserting a large number of elements as this reduces the amount of incremental reallocation.
		@param inverse if true, the lower the number, the higher the priority.
		By default a higher number means a higher priority.
		@param source copies all values from `source` in the range [0, `source.length` - 1] to this collection.
	**/
	public function new(initalCapacity:Null<Int> = 1, ?inverse:Null<Bool> = false, ?source:Array<T>)
	{
		mInitialCapacity = MathTools.max(1, initalCapacity);
		capacity = initalCapacity;
		mInverse = inverse;
		
		if (source != null)
		{
			mSize = source.length;
			capacity = MathTools.max(mSize, capacity);
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
		Reduces the capacity of the internal container to the initial capacity.
		
		May cause a reallocation, but has no effect on `this.size` and its elements.
		An application can use this operation to free up memory by unlocking resources for the garbage collector.
	**/
	public function pack():PriorityQueue<T>
	{
		if (capacity > mInitialCapacity)
		{
			capacity = MathTools.max(mInitialCapacity, mSize);
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
		Returns the front element.
		
		This is the element with the highest priority.
	**/
	public inline function peek():T
	{
		assert(size > 0, "priority queue is empty");
		
		return mData.get(1);
	}
	
	/**
		Returns the rear element.
		
		This is the element with the lowest priority.
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
		Enqueues `val`.
	**/
	public function enqueue(val:T)
	{
		#if debug
		assert(val != null, "element is null");
		assert(!mMap.exists(val), "element already exists");
		mMap.set(val, true);
		#end
		
		if (size == capacity) grow();
		mData.set(++mSize, val);
		val.position = size;
		upheap(size);
	}
	
	/**
		Dequeues the front element.
	**/
	public function dequeue():T
	{
		assert(size > 0, "priority queue is empty");
		
		var d = mData;
		var x = d.get(1);
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
		Re-prioritizes `val`.
		@param priority the new priority.
	**/
	public function reprioritize(val:T, priority:Float):PriorityQueue<T>
	{
		assert(size > 0, "priority queue is empty");
		
		#if debug
		var exists = mMap.exists(val);
		assert(exists, "unknown element");
		#end
		
		var oldPriority = val.priority;
		if (oldPriority == priority) return this;
		
		val.priority = priority;
		var pos = val.position;
		
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
		return this;
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
		Calls 'f` on all elements in unsorted order.
	**/
	public inline function iter(f:T->Void):PriorityQueue<T>
	{
		assert(f != null);
		var d = mData;
		var i = 1;
		while (i <= size) f(d[i++]);
		return this;
	}
	
	/**
		Prints out all elements.
	**/
	#if !no_tostring
	public function toString():String
	{
		var b = new StringBuf();
		b.add('[ PriorityQueue size=$size');
		if (isEmpty())
		{
			b.add(" ]");
			return b.toString();
		}
		var t = sort();
		b.add("\n  front\n");
		var args = new Array<Dynamic>();
		var fmt = '  %${MathTools.numDigits(size)}d -> %s\n';
		for (i in 0...size)
		{
			args[0] = i;
			args[1] = Std.string(t[i]);
			b.add(Printf.format(fmt, args));
		}
		b.add("]");
		return b.toString();
	}
	#end
	
	/**
		Preallocates storage for `n` elements.
		
		May cause a reallocation, but has no effect on `this.size` and its elements.
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
		Returns true if this priority queue contains `val`.
	**/
	public inline function contains(val:T):Bool
	{
		assert(val != null, "val is null");
		
		var position = val.position;
		return (position > 0 && position <= size) && (mData.get(position) == val);
	}
	
	/**
		Removes `val`.
		@return true if `val` was removed.
	**/
	public function remove(val:T):Bool
	{
		if (isEmpty())
			return false;
		else
		{
			assert(val != null, "val is null");
			
			#if debug
			var exists = mMap.exists(val);
			assert(exists, "val does not exist");
			mMap.remove(val);
			#end
			
			if (val.position == 1)
				dequeue();
			else
			{
				var p = val.position, d = mData;
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
		Returns a new *PriorityQueueIterator* object to iterate over all elements contained in this priority queue.
		
		The values are visited in an unsorted order.
		
		@see http://haxe.org/ref/iterators
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
		Returns true only if `this.size` is 0.
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
		return mData.toArray(1, size, []);
	}
	
	/**
		Creates and returns a shallow copy (structure only - default) or deep copy (structure & elements) of this priority queue.
		
		If `byRef` is true, primitive elements are copied by value whereas objects are copied by reference.
		
		If `byRef` is false, the `copier` function is used for copying elements. If omitted, `clone()` is called on each element assuming all elements implement `Cloneable`.
	**/
	public function clone(byRef:Bool = true, copier:T->T = null):Collection<T>
	{
		var copy = new PriorityQueue<T>(capacity, mInverse);
		if (size == 0) return copy;
		
		var src = mData;
		var dst = copy.mData;
		if (byRef)
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