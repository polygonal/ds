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

#if alchemy
import de.polygonal.ds.mem.IntMemory;
#end

import de.polygonal.ds.tools.ArrayTools;
import de.polygonal.ds.tools.Assert.assert;
import de.polygonal.ds.tools.GrowthRate;
import de.polygonal.ds.tools.M;

using de.polygonal.ds.tools.NativeArrayTools;

/**
	An array hash set for storing Hashable objects
**/
#if generic
@:generic
#end
class HashSet<T:Hashable> implements Set<T>
{
	/**
		A unique identifier for this object.
		
		A hash table transforms this key into an index of an array element by using a hash function.
		
		<warn>This value should never be changed by the user.</warn>
	**/
	public var key(default, null):Int = HashKey.next();
	
	/**
		The size of the allocated storage space for the elements.
		
		If more space is required to accomodate new elements, ``capacity`` is doubled every time ``size`` grows beyond capacity, and split in half when ``size`` is a quarter of capacity.
		
		The capacity never falls below the initial size defined in the constructor.
	**/
	public var capacity(default, null):Int;
	
	/**
		The growth rate of the container.
		
		+  0: fixed size
		+ -1: grows at a rate of 1.125x plus a constant.
		+ -2: grows at a rate of 1.5x.
		+ -3: grows at a rate of 2.0x (default value).
		+ >0: grows at a constant rate: capacity += growthRate
	**/
	public var growthRate(get, set):Int;
	function get_growthRate():Int
	{
		return mH.growthRate;
	}
	function set_growthRate(value:Int):Int
	{
		return mH.growthRate = value;
	}
	
	/**
		If true, reuses the iterator object instead of allocating a new one when calling ``iterator()``.
		
		The default is false.
		
		<warn>If true, nested iterations are likely to fail as only one iteration is allowed at a time.</warn>
	**/
	public var reuseIterator:Bool = false;
	
	/**
		The load factor measure the "denseness" of a hash set and is proportional to the time cost to look up an entry.
		
		E.g. assuming that the elements are perfectly distributed, a load factor of 4.0 indicates that each slot stores 4 elements, which have to be sequentially searched in order to find an element.
		
		A high load factor thus indicates poor performance.
		
		If the load factor gets too high, additional slots can be allocated by calling ``rehash()``.
	**/
	public var loadFactor(get, never):Float;
	function get_loadFactor():Float
	{
		return mH.loadFactor;
	}
	
	/**
		The current slot count.
	**/
	public var slotCount(get, never):Int;
	inline function get_slotCount():Int
	{
		return mH.slotCount;
	}
	
	var mH:IntIntHashTable;
	var mVals:NativeArray<T>;
	#if alchemy
	var mNext:IntMemory;
	#else
	var mNext:NativeArray<Int>;
	#end
	var mFree:Int = 0;
	var mSize:Int = 0;
	var mMinCapacity:Int;
	var mIterator:HashSetIterator<T> = null;
	
	/**
		<assert>`slotCount` is not a power of two</assert>
		<assert>`capacity` is not a power of two</assert>
		<assert>`capacity` is < 2</assert>
		@param slotCount the total number of slots into which the hashed values are distributed.
		This defines the space-time trade off of the set.
		Increasing the `slotCount` reduces the computation time (read/write/access) of the set at the cost of increased memory use.
		This value is fixed and can only be changed by calling ``rehash()``, which rebuilds the set (expensive).
		
		@param capacity the initial physical space for storing the elements at the time the set is created.
		This is also the minimum allowed size of the set and cannot be changed in the future.
		If omitted, the initial `capacity` equals `slotCount`.
		The `capacity` is automatically adjusted according to the storage requirements based on two rules:
		<ul>
		<li>If the set runs out of space, the `capacity` is doubled.</li>
		<li>If the ``size`` falls below a quarter of the current `capacity`, the `capacity` is cut in half while the minimum `capacity` can't fall below `capacity`.</li>
		</ul>
	**/
	public function new(slotCount:Int, initialCapacity:Int = -1)
	{
		assert(slotCount > 0);
		
		if (initialCapacity == -1) initialCapacity = slotCount;
		initialCapacity = M.max(2, initialCapacity);
		
		mMinCapacity = capacity = initialCapacity;
		
		mH = new IntIntHashTable(slotCount, capacity);
		mVals = NativeArrayTools.alloc(capacity);
		mVals.nullify(capacity);
		#if alchemy
		mNext = new IntMemory(capacity, "HashSet.mNext");
		#else
		mNext = NativeArrayTools.alloc(capacity);
		#end
		
		var t = mNext;
		for (i in 0...capacity - 1) t.set(i, i + 1);
		t.set(capacity - 1, IntIntHashTable.NULL_POINTER);
	}
	
	/**
		Returns true if this set contains the element `x`.
		
		Uses move-to-front-on-access which reduces access time when similar elements are frequently queried.
		<assert>`x` is null</assert>
	**/
	public inline function hasFront(x:T):Bool
	{
		assert(x != null);
		
		return mH.getFront(x.key) != IntIntHashTable.KEY_ABSENT;
	}
	
	/**
		Counts the total number of collisions.
		
		A collision occurs when two distinct elements are hashed into the same slot.
	**/
	public function getCollisionCount():Int
	{
		return mH.getCollisionCount();
	}
	
	/**
		Redistributes all elements over `slotCount`.
		
		This is an expensive operations as the set is rebuild from scratch.
		<assert>`slotCount` is not a power of two</assert>
	**/
	public function rehash(slotCount:Int)
	{
		mH.rehash(slotCount);
	}
	
	public function pack():HashSet<T>
	{
		mH.pack();
		
		if (mH.capacity == capacity) return this;
		
		capacity = mH.capacity;
		
		#if alchemy
		mNext.resize(capacity);
		#else
		mNext = NativeArrayTools.alloc(capacity);
		#end
		
		var t = mNext;
		for (i in 0...capacity - 1) t.set(i, i + 1);
		t.set(capacity - 1, IntIntHashTable.NULL_POINTER);
		mFree = 0;
		
		var src = mVals;
		var dst = NativeArrayTools.alloc(capacity);
		var j = mFree, v;
		for (i in mH)
		{
			v = src.get(i);
			if (v != null)
			{
				dst.set(j, v);
				j = t.get(j);
			}
		}
		mFree = j;
		mVals = dst;
		for (i in 0...size) mH.remap(dst.get(i).key, i);
		return this;
	}
	
	function grow()
	{
		var oldCapacity = capacity;
		capacity = GrowthRate.compute(growthRate, capacity);
		
		var t;
		
		#if alchemy
		mNext.resize(capacity);
		#else
		t = NativeArrayTools.alloc(capacity);
		mNext.blit(0, t, 0, oldCapacity);
		mNext = t;
		#end
		
		t = mNext;
		for (i in oldCapacity - 1...capacity - 1) t.set(i, i + 1);
		t.set(capacity - 1, IntIntHashTable.NULL_POINTER);
		mFree = oldCapacity;
		
		var t = NativeArrayTools.alloc(capacity);
		t.nullify();
		mVals.blit(0, t, 0, oldCapacity);
		mVals = t;
	}
	
	/**
		Returns a string representing the current object.
		
		Example:
		<pre class="prettyprint">
		class Foo extends de.polygonal.ds.HashableItem
		{
		    var val:Int;
		    public function new(val:Int) {
		        super();
		        this.val = val;
		    }
		    public function toString():String {
		        return "{ Foo val: " + val + " }";
		    }
		}
		
		class Main
		{
		    static function main()
		    {
		        var set = new de.polygonal.ds.HashSet<Foo>(16);
		        for (i in 0...4) set.set(new Foo(i));
		        trace(set);
		    }
		}</pre>
		<pre class="console">
		{ HashSet size/capacity: 4/16, load factor: 0.25 }
		[
		  { Foo val: 0 }
		  { Foo val: 1 }
		  { Foo val: 2 }
		  { Foo val: 3 }
		]</pre>
	**/
	public function toString():String
	{
		var b = new StringBuf();
		b.add(Printf.format("{ HashSet size/capacity: %d/%d, load factor: %.2f }", [size, capacity, loadFactor]));
		if (isEmpty()) return b.toString();
		b.add("\n[\n");
		for (x in this) b.add('  ${Std.string(x)}\n');
		b.add("]");
		return b.toString();
	}
	
	/* INTERFACE Set */
	
	/**
		Returns true if this set contains the element `x` or null if `x` does not exist.
		<assert>`x` is null</assert>
	**/
	public inline function has(x:T):Bool
	{
		return mH.get(x.key) != IntIntHashTable.KEY_ABSENT;
	}
	
	/**
		Adds the element `x` to this set if possible.
		<assert>`x` is null</assert>
		<assert>hash set is full (if not resizable)</assert>
		@return true if `x` was added to this set, false if `x` already exists.
	**/
	public inline function set(x:T):Bool
	{
		assert(x != null);
		
		if (size == capacity) grow();
		
		var i = mFree;
		if (mH.setIfAbsent(x.key, i))
		{
			mSize++;
			mVals.set(i, x);
			mFree = mNext.get(i);
			return true;
		}
		else
			return false;
	}
	
	/**
		Removes the element `x` from this set if possible.
		@return true if `x` was removed from this set, false if `x` does not exist.
	**/
	public inline function unset(x:T):Bool
	{
		return remove(x);
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
		Destroys this object by explicitly nullifying all elements.
		
		Improves GC efficiency/performance (optional).
	**/
	public function free()
	{
		mVals.nullify();
		mVals = null;
		
		#if alchemy
		mNext.free();
		#end
		mNext = null;
		
		mH.free();
		mH = null;
		if (mIterator != null)
		{
			mIterator.free();
			mIterator = null;
		}
	}
	
	/**
		Same as ``has()``.
		<assert>`x` is null</assert>
	**/
	public function contains(x:T):Bool
	{
		return has(x);
	}
	
	/**
		Removes the element `x`.
		<assert>`x` is null</assert>
		@return true if `x` was successfully removed, false if `x` does not exist.
	**/
	public function remove(x:T):Bool
	{
		assert(x != null);
		
		var i = mH.get(x.key);
		if (i == IntIntHashTable.KEY_ABSENT)
			return false;
		else
		{
			mVals.set(i, null); //required for iterator
			mNext.set(i, mFree);
			mFree = i;
			mSize--;
			mH.unset(x.key);
			return true;
		}
	}
	
	/**
		Removes all elements.
		
		The `gc` parameter has no effect.
	**/
	public function clear(gc:Bool = false)
	{
		mH.clear(gc);
		
		mVals.nullify(); //required for iterator
		
		mSize = 0;
		
		var t = mNext;
		for (i in 0...capacity - 1) t.set(i, i + 1);
		t.set(capacity - 1, IntIntHashTable.NULL_POINTER);
		mFree = 0;
	}
	
	/**
		Returns a new `HashSetIterator` object to iterate over all elements contained in this hash set.
		
		The elements are visited in a random order.
		
		See <a href="http://haxe.org/ref/iterators" target="mBlank">http://haxe.org/ref/iterators</a>
	**/
	public function iterator():Itr<T>
	{
		if (reuseIterator)
		{
			if (mIterator == null)
				mIterator = new HashSetIterator(this);
			else
				mIterator.reset();
			return mIterator;
		}
		else
			return new HashSetIterator(this);
	}
	
	/**
		Returns true if the set is empty.
	**/
	public inline function isEmpty():Bool
	{
		return mH.isEmpty();
	}
	
	/**
		Returns an unordered array containing all elements in this set.
	**/
	public function toArray():Array<T>
	{
		if (isEmpty()) return [];
		
		var out = ArrayTools.alloc(size);
		var j = 0, vals = mVals, v;
		for (i in 0...capacity)
		{
			v = vals.get(i);
			if (v != null) out[j++] = v;
		}
		return out;
	}
	
	/**
		Duplicates this hash set. Supports shallow (structure only) and deep copies (structure & elements).
		@param assign if true, the `copier` parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.
		If false, the ``clone()`` method is called on each element. <warn>In this case all elements have to implement `Cloneable`.</warn>
		@param copier a custom function for copying elements. Replaces ``element::clone()`` if `assign` is false.
		<assert>element is not of type `Cloneable`</assert>
	**/
	public function clone(assign:Bool = true, copier:T->T = null):Collection<T>
	{
		var c = new HashSet<T>(slotCount, size);
		c.mH = cast mH.clone();
		c.mSize = size;
		c.mFree = mFree;
		
		var src = mVals;
		var dst = c.mVals;
		
		if (assign)
			src.blit(0, dst, 0, size);
		else
		{
			var v;
			if (copier != null)
			{
				for (i in 0...size)
				{
					v = src.get(i);
					dst.set(i, v != null ? copier(v) : null);
				}
			}
			else
			{
				for (i in 0...size)
				{
					v = src.get(i);
					
					if (v != null)
					{
						assert(Std.is(v, Cloneable), "element is not of type Cloneable");
						
						dst.set(i, cast(v, Cloneable<Dynamic>).clone());
					}
					else
						dst.set(i, null);
				}
			}
		}
		#if alchemy
		IntMemory.blit(mNext, 0, c.mNext, 0, size);
		#else
		mNext.blit(0, c.mNext, 0, size);
		#end
		return c;
	}
}

#if generic
@:generic
#end
@:access(de.polygonal.ds.HashSet)
@:dox(hide)
class HashSetIterator<T:Hashable> implements de.polygonal.ds.Itr<T>
{
	var mObject:HashSet<T>;
	var mVals:NativeArray<T>;
	var mI:Int;
	var mS:Int;
	
	public function new(x:HashSet<T>)
	{
		mObject = x;
		reset();
	}
	
	public function free()
	{
		mObject = null;
		mVals = null;
	}
	
	public function reset():Itr<T>
	{
		mVals = mObject.mVals;
		mS = mObject.mH.capacity;
		mI = 0;
		var t = mVals;
		while (mI < mS && t.get(mI) == null) mI++;
		return this;
	}
	
	public inline function hasNext():Bool
	{
		return mI < mS;
	}
	
	public inline function next():T
	{
		var t = mVals;
		var v = t.get(mI);
		while (++mI < mS && t.get(mI) == null) {}
		return v;
	}
	
	public function remove()
	{
		throw "unsupported operation";
	}
}