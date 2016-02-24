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
	A heap is a special kind of binary tree in which every node is greater than all of its children
	
	The implementation is based on an arrayed binary tree.
**/
#if generic
@:generic
#end
class Heap<T:(Heapable<T>)> implements Collection<T>
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
	var mIterator:HeapIterator<T> = null;
	
	#if debug
	var mMap:haxe.ds.ObjectMap<T, Bool>;
	#end
	
	public function new(initalCapacity:Null<Int> = 1, ?source:Array<T>)
	{
		mInitialCapacity = M.max(1, initalCapacity);
		capacity = initalCapacity;
		
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
		Returns the item on top of the heap without removing it from the heap.
		
		This is the smallest element (assuming ascending order).
		<assert>heap is empty</assert>
	**/
	public inline function top():T
	{
		assert(size > 0, "heap is empty");
		
		return mData.get(1);
	}
	
	/**
		Returns the item on the bottom of the heap without removing it from the heap.
		
		This is the largest element (assuming ascending order).
		<assert>heap is empty</assert>
	**/
	public function bottom():T
	{
		assert(size > 0, "heap is empty");
		
		if (size == 1) return mData.get(1);
		
		var d = mData;
		var a = d.get(1), b;
		for (i in 2...size + 1)
		{
			b = d.get(i);
			if (a.compare(b) > 0) a = b;
		}
		return a;
	}
	
	/**
		Adds the element `x`.
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
		
		if (size == capacity) grow();
		mData.set(++mSize, x);
		x.position = size;
		upheap(size);
	}
	
	/**
		Removes the element on top of the heap.
		
		This is the smallest element (assuming ascending order).
		<assert>heap is empty</assert>
	**/
	public function pop():T
	{
		assert(size > 0, "heap is empty");
		
		var d = mData;
		var x = d.get(1);
		
		#if debug
		mMap.remove(x);
		#end
		
		d.set(1, d.get(size));
		downheap(1);
		mSize--;
		return x;
	}
	
	/**
		Replaces the item at the top of the heap with a new element `x`.
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
			upheap(size);
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
					if (t.get(c).compare(t.get(c + 1)) < 0)
						c++;
				
				u = t.get(c);
				if (v.compare(u) < 0)
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
		return out;
	}
	
	/**
		Computes the height of the heap tree.
	**/
	public function height():Int
	{
		return 32 - Bits.nlz(size);
	}
	
	/**
		Preallocates storage for `n` elements.
		
		May cause a reallocation, but has no effect on the vector size and its elements.
		Useful before inserting a large number of elements as this reduces the amount of incremental reallocation.
	**/
	public function reserve(n:Int):Heap<T>
	{
		if (n > capacity)
		{
			capacity = n;
			resizeContainer(n);
		}
		return this;
	}
	
	/**
		For performance reasons the heap does nothing to ensure that empty locations contain null; ``pack()`` therefore
		nullifies all obsolete references and shrinks the container to the actual size allowing the garbage collector to reclaim used memory.
	**/
	/**
		Reduces the capacity of the internal container to the initial capacity.
		
		May cause a reallocation, but has no effect on the vector size and its elements.
		An application can use this operation to free up memory by GC'ing used resources.
	**/
	public function pack():Heap<T>
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
		Uses the Floyd algorithm (bottom-up) to repair the heap tree by restoring the heap property.
	**/
	public function repair():Heap<T>
	{
		var i = size >> 1;
		while (i >= 1)
		{
			heapify(i, size);
			i--;
		}
		return this;
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
		var b = new StringBuf();
		b.add('{ Heap size: ${size} }');
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
		var s = size - 1;
		
		while (c < size)
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
		Returns true if this heap contains the element `x`.
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
			d.set(p, d.get(size));
			downheap(p);
			upheap(p);
			mSize--;
		}
		return true;
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
		Returns true if this heap is empty.
	**/
	public inline function isEmpty():Bool
	{
		return size == 0;
	}
	
	/**
		Returns an unordered array containing all elements in this heap.
	**/
	public function toArray():Array<T>
	{
		return mData.toArray(1, size);
	}
	
	/**
		Duplicates this heap. Supports shallow (structure only) and deep copies (structure & elements).
		<assert>element is not of type `Cloneable`</assert>
		@param assign if true, the `copier` parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.
		If false, the ``clone()`` method is called on each element. <warn>In this case all elements have to implement `Cloneable`.</warn>
		@param copier a custom function for copying elements. Replaces ``element::clone()`` if `assign` is false.
		<warn>If `assign` is true, only the copied version should be used from now on.</warn>
	**/
	public function clone(assign:Bool = true, copier:T->T = null):Collection<T>
	{
		var copy = new Heap<T>(size);
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
				dst.set(i, cast c);
				
				#if debug
				copy.mMap.set(e, true);
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
				dst.set(i, c);
				
				#if debug
				copy.mMap.set(c, true);
				#end
			}
		}
		
		copy.mSize = size;
		return copy;
	}
}

#if generic
@:generic
#end
@:access(de.polygonal.ds.Heap)
@:dox(hide)
class HeapIterator<T:(Heapable<T>)> implements de.polygonal.ds.Itr<T>
{
	var mObject:Heap<T>;
	var mData:NativeArray<T>;
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
		mS = mObject.size;
		mI = 0;
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