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
		The maximum allowed size of this heap.
		
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
	
	var mData:Array<T>;
	var mSize:Int;
	var mIterator:HeapIterator<T>;
	
	#if debug
	var mMap:haxe.ds.ObjectMap<T, Bool>;
	#end
	
	/**
		<assert>`reservedSize` > ``maxSize``</assert>
		@param reservedSize the initial capacity of the internal container. See ``reserve()``.
		@param maxSize the maximum allowed size of this heap.
		The default value of -1 indicates that there is no upper limit.
	**/
	public function new(reservedSize = 0, maxSize = -1)
	{
		#if debug
		this.maxSize = (maxSize == -1) ? M.INT32_MAX : maxSize;
		#else
		this.maxSize = -1;
		#end
		
		#if debug
		mMap = new haxe.ds.ObjectMap<T, Bool>();
		#end
		
		if (reservedSize > 0)
		{
			#if debug
			if (this.maxSize != -1)
				assert(reservedSize <= this.maxSize, "reserved size is greater than allowed size");
			#end
			mData = ArrayUtil.alloc(reservedSize + 1);
		}
		else
			mData = new Array<T>();
		
		set(0, cast null);
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
		mData = ArrayUtil.alloc(size() + 1);
		set(0, cast null);
		for (i in 1...size() + 1)
		{
			set(i, tmp[i]);
			
			#if debug
			mMap.set(tmp[i], true);
			#end
		}
		for (i in size() + 1...tmp.length) tmp[i] = cast null;
	}
	
	/**
		Preallocates internal space for storing `x` elements.
		
		This is useful if the expected size is known in advance - many platforms can optimize memory usage if an exact size is specified.
		<o>n</o>
	**/
	public function reserve(x:Int)
	{
		if (size() == x) return;
		
		var tmp = mData;
		mData = ArrayUtil.alloc(x + 1);
		
		set(0, cast null);
		if (size() < x)
		{
			for (i in 1...size() + 1)
				set(i, tmp[i]);
		}
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
		
		return get(1);
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
		
		if (mSize == 1) return get(1);
		var a = get(1), b;
		for (i in 2...mSize + 1)
		{
			b = get(i);
			if (a.compare(b) > 0) a = b;
		}
		
		return a;
	}
	
	/**
		Adds the element `x`.
		<o>log n</o>
		<assert>heap is full</assert>
		<assert>`x` is null or `x` already exists</assert>
		<assert>``size()`` equals ``maxSize``</assert>
	**/
	public function add(x:T)
	{
		assert(x != null, "x is null");
		
		#if debug
		if (maxSize != -1) assert(size() <= maxSize, 'size equals max size ($maxSize)');
		assert(!mMap.exists(x), "x already exists");
		mMap.set(x, true);
		#end
		
		set(++mSize, x);
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
		
		var x = get(1);
		
		#if debug
		mMap.remove(x);
		#end
		
		set(1, get(mSize));
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
		mMap.remove(get(1));
		mMap.set(x, true);
		#end
		
		set(1, x);
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
		if (isEmpty()) return new Array();
		
		var a = ArrayUtil.alloc(mSize);
		var h = ArrayUtil.alloc(mSize + 1);
		ArrayUtil.copy(mData, h, 0, mSize + 1);
		
		var k = mSize;
		var j = 0;
		while (k > 0)
		{
			a[j++] = h[1];
			h[1] = h[k];
			
			var i = 1;
			var c = i << 1;
			var v = h[i];
			var s = k - 1;
			
			while (c < k)
			{
				if (c < s)
					if (h[c].compare(h[c + 1]) < 0)
						c++;
				
				var u = h[c];
				if (v.compare(u) < 0)
				{
					h[i] = u;
					i = c;
					c <<= 1;
				}
				else break;
			}
			h[i] = v;
			k--;
		}
		
		return a;
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
		var tmp = new Heap<HeapElementWrapper<T>>();
		for (i in 1...mSize + 1)
		{
			var w = new HeapElementWrapper<T>(get(i));
			tmp.set(i, w);
		}
		tmp.mSize = mSize;
		s += "\n[ front\n";
		var i = 0;
		while (tmp.size() > 0)
			s += Printf.format("  %4d -> %s\n", [i++, Std.string(tmp.pop())]);
		s += "]";
		return s;
	}
	
	/**
		Uses the Floyd algorithm (bottom-up) to repair the heap tree by restoring the heap property.
		<o>n</o>
	**/
	public function repair()
	{
		var i = mSize >> 1;
		while (i >= 1)
		{
			heapify(i, mSize);
			i--;
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
		for (i in 0...mData.length) set(i, cast null);
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
		return (position > 0 && position <= mSize) && (get(position) == x);
	}
	
	/**
		Removes the element `x`.
		<o>2 * log n</o>
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
				pop();
			else
			{
				var p = x.position;
				set(p, get(mSize));
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
		#if debug
		mMap = new haxe.ds.ObjectMap<T, Bool>();
		#end
		
		if (purge)
		{
			for (i in 1...mData.length) set(i, cast null);
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
		var a:Array<T> = ArrayUtil.alloc(size());
		for (i in 1...mSize + 1) a[i - 1] = get(i);
		return a;
	}
	
	/**
		Returns a `Vector<T>` object containing all elements in this heap.
	**/
	public function toVector():Vector<T>
	{
		var v = new Vector<T>(size());
		for (i in 1...mSize + 1) v[i - 1] = get(i);
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
		var copy = new Heap<T>(mSize, maxSize);
		if (mSize == 0) return copy;
		if (assign)
		{
			for (i in 1...mSize + 1)
			{
				copy.set(i, get(i));
				
				#if debug
				copy.mMap.set(get(i), true);
				#end
			}
		}
		else
		if (copier == null)
		{
			for (i in 1...mSize + 1)
			{
				var e = get(i);
				
				assert(Std.is(e, Cloneable), 'element is not of type Cloneable (${get(i)})');
				
				var cl:Cloneable<T> = cast e;
				var c = cl.clone();
				c.position = e.position;
				copy.set(i, cast c);
				
				#if debug
				copy.mMap.set(c, true);
				#end
			}
		}
		else
		{
			for (i in 1...mSize + 1)
			{
				var e = get(i);
				var c = copier(e);
				c.position = e.position;
				copy.set(i, c);
				
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
		var p = i >> 1;
		var a = get(i), b;
		while (p > 0)
		{
			b = get(p);
			if (a.compare(b) > 0)
			{
				set(i, b);
				b.position = i;
				i = p;
				p >>= 1;
			}
			else break;
		}
		a.position = i;
		set(i, a);
	}
	
	inline function downheap(i:Int)
	{
		var c = i << 1;
		var a = get(i);
		var s = mSize - 1;
		
		while (c < mSize)
		{
			if (c < s)
				if (get(c).compare(get(c + 1)) < 0)
					c++;
			
			var b = get(c);
			if (a.compare(b) < 0)
			{
				set(i, b);
				b.position = i;
				a.position = c;
				i = c;
				c <<= 1;
			}
			else break;
		}
		a.position = i;
		set(i, a);
	}
	
	function heapify(p:Int, s:Int)
	{
		var l = p << 1;
		var r = l + 1;
		
		var max = p;
		
		if (l <= s && get(l).compare(get(max)) > 0) max = l;
		if (l + 1 <= s && get(l + 1).compare(get(max)) > 0) max = r;
		
		if (max != p)
		{
			var a = get(max);
			var b = get(p);
			set(max, b);
			set(p, a);
			var tmp = a.position;
			a.position = b.position;
			b.position = tmp;
			
			heapify(max, s);
		}
	}
	
	inline function get(i:Int)
	{
		return mData[i];
	}
	inline function set(i:Int, x:T)
	{
		mData[i] = x;
	}
}

@:access(de.polygonal.ds.Heap)
@:dox(hide)
class HeapIterator<T:(Heapable<T>)> implements de.polygonal.ds.Itr<T>
{
	var mF:Heap<T>;
	var mData:Array<T>;
	var mI:Int;
	var mS:Int;
	
	public function new(f:Heap<T>)
	{
		mF = f;
		mData = new Array<T>();
		mData[0] = null;
		reset();
	}
	
	public function free()
	{
		mData = null;
	}
	
	public function reset():Itr<T>
	{
		mS = mF.size() + 1;
		mI = 1;
		var a = mF.mData;
		for (i in 1...mS) mData[i] = a[i];
		return this;
	}
	
	inline public function hasNext():Bool
	{
		return mI < mS;
	}
	
	inline public function next():T
	{
		return mData[mI++];
	}
	
	inline public function remove()
	{
		assert(mI > 0, "call next() before removing an element");
		
		mF.remove(mData[mI - 1]);
	}
}

@:dox(hide)
private class HeapElementWrapper<T:(Heapable<T>)> implements Heapable<HeapElementWrapper<T>>
{
	public var position:Int;
	public var e:T;
	
	public function new(e:T)
	{
		this.e = e;
		this.position = e.position;
	}
	
	public function compare(other:HeapElementWrapper<T>):Int
	{
		return e.compare(other.e);
	}
	
	public function toString():String
	{
		return Std.string(e);
	}
}