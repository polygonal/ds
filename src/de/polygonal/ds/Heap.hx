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

using de.polygonal.ds.tools.NativeArray;

/**
	A heap is a special kind of binary tree in which every node is greater than all of its children
	
	The implementation is based on an arrayed binary tree.
	
	_<o>Worst-case running time in Big O notation</o>_
**/
class Heap<T:(Heapable<T>)> implements Collection<T>
{
	/**
		A unique identifier for this object.
		
		A hash table transforms this key into an index of an array element by using a hash function.
		
		<warn>This value should never be changed by the user.</warn>
	**/
	public var key:Int;
	
	/**
		If true, reuses the iterator object instead of allocating a new one when calling ``iterator()``.
		
		The default is false.
		
		<warn>If true, nested iterations are likely to fail as only one iteration is allowed at a time.</warn>
	**/
	public var reuseIterator:Bool;
	
	public var capacity(default, null):Int;
	
	var mData:Container<T>;
	var mSize:Int;
	var mIterator:HeapIterator<T>;
	var mShrinkSize:Int;
	
	var mCapacityIncrement:Int;
	
	#if debug
	var mMap:haxe.ds.ObjectMap<T, Bool>;
	#end
	
	/**
		@param reservedSize the initial capacity of the internal container. See ``reserve()``.
	**/
	public function new(initialCapacity:Int = 16, capacityIncrement:Int = -1)
	{
		capacity = initialCapacity;
		mCapacityIncrement = capacityIncrement;
		
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
		For performance reasons the heap does nothing to ensure that empty locations contain null; ``pack()`` therefore
		nullifies all obsolete references and shrinks the container to the actual size allowing the garbage collector to reclaim used memory.
		<o>n</o>
	**/
	public function pack()
	{
		if (mData.length - 1 == size()) return;
		
		#if debug
		mMap = new haxe.ds.ObjectMap<T, Bool>();
		#end
		
		var tmp = mData;
		mData = NativeArray.init(size() + 1);
		
		var d = mData;
		
		d.set(0, cast null);
		for (i in 1...size() + 1)
		{
			d.set(i, tmp.get(i));
			
			#if debug
			mMap.set(tmp.get(i), true);
			#end
		}
		for (i in size() + 1...NativeArray.size(tmp)) tmp.set(i, cast null);
	}
	
	/**
		Preallocates storage for `n` elements.
		
		Useful before inserting a large number of elements as this reduces the amount of incremental reallocation.
	**/
	public function reserve(n:Int):Heap<T>
	{
		if (n <= capacity) return this;
		
		capacity = n;
		mShrinkSize = n >> 2;
		resize(n);
		
		return this;
	}
	
	/**
		Returns the item on top of the heap without removing it from the heap.
		
		This is the smallest element (assuming ascending order).
		<o>1</o>
		<assert>heap is empty</assert>
	**/
	inline public function top():T
	{
		assert(size() > 0, "heap is empty");
		
		return mData.get(1);
	}
	
	/**
		Returns the item on the bottom of the heap without removing it from the heap.
		
		This is the largest element (assuming ascending order).
		<o>n</o>
		<assert>heap is empty</assert>
	**/
	public function bottom():T
	{
		assert(size() > 0, "heap is empty");
		
		if (mSize == 1) return mData.get(1);
		
		var d = mData;
		var a = d.get(1), b;
		for (i in 2...mSize + 1)
		{
			b = d.get(i);
			if (a.compare(b) > 0) a = b;
		}
		
		return a;
	}
	
	/**
		Adds the element `x`.
		<o>log n</o>
		<assert>heap is full</assert>
		<assert>`x` is null or `x` already exists</assert>
	**/
	public function add(x:T)
	{
		#if debug
		assert(x != null, "x is null");
		assert(!mMap.exists(x), "x already exists");
		mMap.set(x, true);
		#end
		
		if (mSize == capacity) grow();
		mData.set(++mSize, x);
		x.position = mSize;
		upheap(mSize);
	}
	
	/**
		Removes the element on top of the heap.
		
		This is the smallest element (assuming ascending order).
		<o>log n</o>
		<assert>heap is empty</assert>
	**/
	public function pop():T
	{
		assert(size() > 0, "heap is empty");
		
		var d = mData;
		var x = d.get(1);
		
		#if debug
		mMap.remove(x);
		#end
		
		//TODO shrink
		
		d.set(1, d.get(mSize));
		downheap(1);
		mSize--;
		return x;
	}
	
	/**
		Replaces the item at the top of the heap with a new element `x`.
		<o>log n</o>
		<assert>`x` already exists</assert>
	**/
	public function replace(x:T)
	{
		#if debug
		assert(!mMap.exists(x), "x already exists");
		mMap.remove(mData.get(1));
		mMap.set(x, true);
		#end
		
		mData.set(1, x);
		downheap(1);
	}
	
	/**
		Rebuilds the heap in case an existing element was modified.
		
		This is faster than removing and readding an element.
		<o>log n</o>
		<assert>`x` does not exist</assert>
		@param hint a value >= 0 indicates that `x` is now smaller (ascending order) or bigger (descending order) and should be moved towards the root of the tree to rebuild the heap property.
		Likewise, a value < 0 indicates that `x` is now bigger (ascending order) or smaller (descending order) and should be moved towards the leaf nodes of the tree.
	**/
	public function change(x:T, hint:Int)
	{
		#if debug
		var exists = mMap.exists(x);
		assert(exists, "x does not exist");
		#end
		
		if (hint >= 0)
			upheap(x.position);
		else
		{
			downheap(x.position);
			upheap(mSize);
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
					if (tmp.get(c).compare(tmp.get(c + 1)) < 0)
						c++;
				
				u = tmp.get(c);
				if (v.compare(u) < 0)
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
		return out;
	}
	
	/**
		Computes the height of the heap tree.
		<o>1</o>
	**/
	public function height():Int
	{
		return 32 - Bits.nlz(mSize);
	}
	
	/**
		Returns a string representing the current object.
		Prints out all elements in a sorted order.
		
		Example:
		<pre class="prettyprint">
		class Foo implements de.polygonal.ds.Heapable<Foo>
		{
		    public var id:Int;
		    public var position:Int; //don't touch!
		    public function new(id:Int) {
		        this.id = id;
		    }
		    public function compare(other:Foo):Int {
		        return other.id - id;
		    }
		    public function toString():String {
		        return Std.string(id);
		    }
		}
		
		class Main
		{
		    static function main() {
		        var h = new de.polygonal.ds.Heap<Foo>();
		        h.add(new Foo(64));
		        h.add(new Foo(13));
		        h.add(new Foo(1));
		        h.add(new Foo(37));
		        trace(h);
		    }
		}</pre>
		<pre class="console">
		{ Heap size: 4 }
		[ front
		  0 -> 1
		  1 -> 13
		  2 -> 37
		  3 -> 64
		]</pre>
	**/
	public function toString():String
	{
		var s = '{ Heap size: ${size()} }';
		if (isEmpty()) return s;
		
		var tmp = sort();
		s += "\n[ front\n";
		var i = 0;
		for (i in 0...size())
			s += Printf.format("  %4d -> %s\n", [i, Std.string(tmp[i])]);
		s += "]";
		return s;
	}
	
	/**
		Uses the Floyd algorithm (bottom-up) to repair the heap tree by restoring the heap property.
		<o>n</o>
	**/
	public function repair():Heap<T>
	{
		var i = mSize >> 1;
		while (i >= 1)
		{
			heapify(i, mSize);
			i--;
		}
		return this;
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
		for (i in 0...NativeArray.size(d)) d.set(i, cast null);
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
		Returns true if this heap contains the element `x`.
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
		<o>2 * log n</o>
		<assert>`x` is invalid or does not exist</assert>
		@return true if `x` was removed.
	**/
	public function remove(x:T):Bool
	{
		if (isEmpty()) return false;

		assert(x != null, "x is null");
		
		#if debug
		var exists = mMap.exists(x);
		assert(exists, "x does not exist");
		mMap.remove(x);
		#end
		
		if (x.position == 1)
			pop();
		else
		{
			var p = x.position, d = mData;
			d.set(p, d.get(mSize));
			downheap(p);
			upheap(p);
			mSize--;
		}
		
		//TODO shrink
		
		return true;
	}
	
	/**
		Removes all elements.
		<o>1 or n if `purge` is true</o>
		@param purge if true, elements are nullified upon removal.
	**/
	inline public function clear(purge = false)
	{
		#if debug
		mMap = new haxe.ds.ObjectMap<T, Bool>();
		#end
		
		if (purge)
		{
			var d = mData;
			for (i in 1...NativeArray.size(mData)) d.set(i, cast null);
		}
		mSize = 0;
	}
	
	/**
		Returns a new `HeapIterator` object to iterate over all elements contained in this heap.
		
		The values are visited in an unsorted order.
		
		See <a href="http://haxe.org/ref/iterators" target="mBlank">http://haxe.org/ref/iterators</a>
	**/
	public function iterator():Itr<T>
	{
		if (reuseIterator)
		{
			if (mIterator == null)
				mIterator = new HeapIterator<T>(this);
			else
				mIterator.reset();
			return mIterator;
		}
		else
			return new HeapIterator<T>(this);
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
		Returns true if this heap is empty.
		<o>1</o>
	**/
	inline public function isEmpty():Bool
	{
		return mSize == 0;
	}
	
	/**
		Returns an unordered array containing all elements in this heap.
	**/
	public function toArray():Array<T>
	{
		return NativeArray.toArray(mData, 1, size());
	}
	
	/**
		Returns a `Vector<T>` object containing all elements in this heap.
	**/
	public function toVector():Container<T>
	{
		var v = NativeArray.init(size());
		var d = mData;
		for (i in 1...mSize + 1) v.set(i - 1, d.get(i));
		return v;
	}
	
	/**
		Duplicates this heap. Supports shallow (structure only) and deep copies (structure & elements).
		<assert>element is not of type `Cloneable`</assert>
		@param assign if true, the `copier` parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.
		If false, the ``clone()`` method is called on each element. <warn>In this case all elements have to implement `Cloneable`.</warn>
		@param copier a custom function for copying elements. Replaces ``element::clone()`` if `assign` is false.
		<warn>If `assign` is true, only the copied version should be used from now on.</warn>
	**/
	public function clone(assign = true, copier:T->T = null):Collection<T>
	{
		var copy = new Heap<T>(mSize);
		if (mSize == 0) return copy;
		if (assign)
		{
			//TODo optimize
			for (i in 1...mSize + 1)
			{
				copy.mData.set(i, mData.get(i));
				
				#if debug
				copy.mMap.set(mData.get(i), true);
				#end
			}
		}
		else
		if (copier == null)
		{
			for (i in 1...mSize + 1)
			{
				var e = mData.get(i);
				
				assert(Std.is(e, Cloneable), 'element is not of type Cloneable (${mData.get(i)})');
				
				var cl:Cloneable<T> = cast e;
				var c = cl.clone();
				c.position = e.position;
				copy.mData.set(i, cast c);
				
				#if debug
				copy.mMap.set(c, true);
				#end
			}
		}
		else
		{
			for (i in 1...mSize + 1)
			{
				var e = mData.get(i);
				var c = copier(e);
				c.position = e.position;
				copy.mData.set(i, c);
				
				#if debug
				copy.mMap.set(c, true);
				#end
			}
		}
		
		copy.mSize = mSize;
		return copy;
	}
	
	inline function upheap(i:Int)
	{
		var d = mData;
		var p = i >> 1;
		var a = d.get(i), b;
		
		while (p > 0)
		{
			b = d.get(p);
			if (a.compare(b) > 0)
			{
				d.set(i, b);
				b.position = i;
				i = p;
				p >>= 1;
			}
			else break;
		}
		a.position = i;
		d.set(i, a);
	}
	
	inline function downheap(i:Int)
	{
		var d = mData;
		var c = i << 1;
		var a = d.get(i);
		var s = mSize - 1;
		
		while (c < mSize)
		{
			if (c < s)
				if (d.get(c).compare(d.get(c + 1)) < 0)
					c++;
			
			var b = d.get(c);
			if (a.compare(b) < 0)
			{
				d.set(i, b);
				b.position = i;
				a.position = c;
				i = c;
				c <<= 1;
			}
			else break;
		}
		a.position = i;
		d.set(i, a);
	}
	
	function heapify(p:Int, s:Int)
	{
		var d = mData;
		var l = p << 1;
		var r = l + 1;
		var max = p;
		if (l <= s && d.get(l).compare(d.get(max)) > 0) max = l;
		if (l + 1 <= s && d.get(l + 1).compare(d.get(max)) > 0) max = r;
		
		if (max != p)
		{
			var a = d.get(max);
			var b = d.get(p);
			d.set(max, b);
			d.set(p, a);
			var tmp = a.position;
			a.position = b.position;
			b.position = tmp;
			
			heapify(max, s);
		}
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

@:access(de.polygonal.ds.Heap)
@:dox(hide)
class HeapIterator<T:(Heapable<T>)> implements de.polygonal.ds.Itr<T>
{
	var mObject:Heap<T>;
	var mData:Container<T>;
	var mI:Int;
	var mS:Int;
	
	public function new(x:Heap<T>)
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
		mS = mObject.size();
		mI = 0;
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