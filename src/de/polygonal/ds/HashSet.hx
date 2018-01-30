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

#if alchemy
import de.polygonal.ds.tools.mem.IntMemory;
#end

import de.polygonal.ds.tools.ArrayTools;
import de.polygonal.ds.tools.Assert.assert;
import de.polygonal.ds.tools.GrowthRate;
import de.polygonal.ds.tools.MathTools;

using de.polygonal.ds.tools.NativeArrayTools;

/**
	An array hash set for storing Hashable objects
	
	Example:
		class Element extends de.polygonal.ds.HashableItem {
		    var val:String;
		    public function new(val:String) {
		        super();
		        this.val = val;
		    }
		    public function toString():String {
		        return val;
		    }
		}
		
		...
		
		var o = new de.polygonal.ds.HashSet<Element>(16);
		var a = new Element("a");
		var b = new Element("b");
		var c = new Element("c");
		o.set(a);
		o.set(a);
		o.set(b);
		o.set(c);
		o.set(c);
		trace(o); //outputs:
		
		[ HashSet size=3 capacity=16 load=0.19
		  a
		  b
		  c
		]
**/
#if generic
@:generic
#end
class HashSet<T:Hashable> implements Set<T>
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
		If true, reuses the iterator object instead of allocating a new one when calling `this.iterator()`.
		
		The default is false.
		
		_If this value is true, nested iterations will fail as only one iteration is allowed at a time._
	**/
	public var reuseIterator:Bool = false;
	
	/**
		The load factor measure the "denseness" of a hash set and is proportional to the time cost to look up an entry.
		
		E.g. assuming that the elements are perfectly distributed, a load factor of 4.0 indicates that each slot stores 4 elements, which have to be sequentially searched in order to find an element.
		
		A high load factor thus indicates poor performance.
		
		If the load factor gets too high, additional slots can be allocated by calling `this.rehash()`.
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
		@param slotCount the total number of slots into which the hashed values are distributed.
		This defines the space-time trade off of this set.
		A high `slotCount` value leads to better performance but requires more memory.
		This value can only be changed later on by calling `this.rehash()`, which in turn rebuilds the entire hash table (expensive).
		
		@param capacity the initial physical space for storing the elements at the time this set is initialized.
		This also defines the minimum allowed size.
		If omitted, the initial `capacity` is set to `slotCount`.
		If more space is required to accommodate new elements, `capacity` grows according to `this.growthRate`.
	**/
	public function new(slotCount:Int, initialCapacity:Int = -1)
	{
		assert(slotCount > 0);
		
		if (initialCapacity == -1) initialCapacity = slotCount;
		initialCapacity = MathTools.max(2, initialCapacity);
		
		mMinCapacity = capacity = initialCapacity;
		
		mH = new IntIntHashTable(slotCount, capacity);
		mVals = NativeArrayTools.alloc(capacity);
		mVals.nullify(0, capacity);
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
		Returns true if this set contains `val`.
		
		Uses move-to-front-on-access which reduces access time when similar elements are frequently queried.
	**/
	public inline function hasFront(val:T):Bool
	{
		assert(val != null);
		
		return mH.getFront(val.key) != IntIntHashTable.KEY_ABSENT;
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
	**/
	public function rehash(slotCount:Int):HashSet<T>
	{
		mH.rehash(slotCount);
		return this;
	}
	
	/**
		Free up resources by reducing the capacity of the internal container to the initial capacity.
	**/
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
	
	/**
		Calls `f` on all values in random order.
	**/
	@:access(de.polygonal.ds.IntIntHashTable)
	public inline function iter(f:T->Void):HashSet<T>
	{
		assert(f != null);
		var d = mH.mData, vals = mVals, v;
		for (i in 0...mH.capacity)
		{
			v = d.get(i * 3 + 1);
			if (v != IntIntHashTable.VAL_ABSENT) f(vals.get(v));
		}
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
		
		var v = NativeArrayTools.alloc(capacity);
		v.nullify();
		mVals.blit(0, v, 0, oldCapacity);
		mVals = v;
	}
	
	/**
		Prints out all elements.
	**/
	#if !no_tostring
	public function toString():String
	{
		var b = new StringBuf();
		b.add(Printf.format('[ HashSet size=$size capacity=$capacity load=%.2f', [loadFactor]));
		if (isEmpty())
		{
			b.add(" ]");
			return b.toString();
		}
		b.add("\n");
		for (x in this)
		{
			b.add("  ");
			b.add(Std.string(x));
			b.add("\n");
		}
		b.add("]");
		return b.toString();
	}
	#end
	
	/* INTERFACE Set */
	
	/**
		Returns true if this set contains `val` or null if `val` does not exist.
	**/
	public inline function has(val:T):Bool
	{
		return mH.get(val.key) != IntIntHashTable.KEY_ABSENT;
	}
	
	/**
		Adds `val` to this set if possible.
		@return true if `val` was added to this set, false if `val` already exists.
	**/
	public inline function set(val:T):Bool
	{
		assert(val != null);
		
		if (size == capacity) grow();
		
		var i = mFree;
		if (mH.setIfAbsent(val.key, i))
		{
			mSize++;
			mVals.set(i, val);
			mFree = mNext.get(i);
			return true;
		}
		else
			return false;
	}
	
	/**
		Removes `val` from this set if possible.
		@return true if `val` was removed from this set, false if `val` does not exist.
	**/
	public inline function unset(val:T):Bool
	{
		return remove(val);
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
		Same as `this.has()`.
	**/
	public function contains(val:T):Bool
	{
		return has(val);
	}
	
	/**
		Removes `val`.
		@return true if `val` was successfully removed, false if `val` does not exist.
	**/
	public function remove(val:T):Bool
	{
		assert(val != null);
		
		var i = mH.get(val.key);
		if (i == IntIntHashTable.KEY_ABSENT)
			return false;
		else
		{
			mVals.set(i, null); //required for iterator
			mNext.set(i, mFree);
			mFree = i;
			mSize--;
			mH.unset(val.key);
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
		Returns a new *HashSetIterator* object to iterate over all elements contained in this hash set.
		
		The elements are visited in a random order.
		
		@see http://haxe.org/ref/iterators
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
		Returns true only if `this.size` is 0.
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
		Creates and returns a shallow copy (structure only - default) or deep copy (structure & elements) of this set.
		
		If `byRef` is true, primitive elements are copied by value whereas objects are copied by reference.
		
		If `byRef` is false, the `copier` function is used for copying elements. If omitted, `clone()` is called on each element assuming all elements implement `Cloneable`.
	**/
	public function clone(byRef:Bool = true, copier:T->T = null):Collection<T>
	{
		var c = new HashSet<T>(slotCount, size);
		c.mH = cast mH.clone();
		c.mSize = size;
		c.mFree = mFree;
		
		var src = mVals;
		var dst = c.mVals;
		
		if (byRef)
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