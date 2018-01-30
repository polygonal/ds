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

#if (flash && alchemy)
import de.polygonal.ds.tools.mem.IntMemory;
#end

import de.polygonal.ds.tools.ArrayTools;
import de.polygonal.ds.tools.Assert.assert;
import de.polygonal.ds.tools.GrowthRate;
import de.polygonal.ds.tools.MathTools;

using de.polygonal.ds.tools.NativeArrayTools;

/**
	An array hash table for mapping integer keys to generic elements
	
	The implementation is based `IntIntHashTable`.
	
	Example:
		class Element extends de.polygonal.ds.HashableItem {
		    var val:Int;
		    public function new(val:Int) {
		        super();
		        this.val = val;
		    }
		    public function toString():String {
		        return "Element" + val;
		    }
		}
		
		...
		
		var o = new de.polygonal.ds.IntHashTable<Element>(16);
		for (i in 0...4) o.set(i, new Element(i));
		trace(o); //outputs:
		
		[ IntHashTable size=4 capacity=16 load=0.25
		   0 -> Element0
		   1 -> Element1
		   2 -> Element2
		   3 -> Element3
		]
**/
#if generic
@:generic
#end
class IntHashTable<T> implements Map<Int, T>
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
		The load factor measure the "denseness" of a hash table and is proportional to the time cost to look up an entry.
		
		E.g. assuming that the keys are perfectly distributed, a load factor of 4.0 indicates that each slot stores 4 keys, which have to be sequentially searched in order to find a value.
		
		A high load factor thus indicates poor performance.
		
		If the load factor gets too high, additional slots can be allocated by calling `this.rehash()`.
	**/
	public var loadFactor(get, never):Float;
	function get_loadFactor():Float
	{
		return mH.loadFactor;
	}
	
	/**
		The total number of allocated slots.
	**/
	public var slotCount(get, never):Int;
	inline function get_slotCount():Int
	{
		return mH.slotCount;
	}
	
	var mH:IntIntHashTable;
	var mVals:NativeArray<T>;
	#if alchemy
	var mKeys:IntMemory;
	var mNext:IntMemory;
	#else
	var mNext:NativeArray<Int>;
	var mKeys:NativeArray<Int>;
	#end
	
	var mFree:Int = 0;
	var mSize:Int = 0;
	var mMinCapacity:Int;
	var mShrinkSize:Int;
	var mIterator:IntHashTableIterator<T> = null;
	var mTmpKeyBuffer:Array<Int> = [];
	
	/**
		@param slotCount the total number of slots into which the hashed keys are distributed.
		This defines the space-time trade off of this hash table.
		A high `slotCount` value leads to better performance but requires more memory.
		This value can only be changed later on by calling `this.rehash()`, which in turn rebuilds the entire hash table (expensive).
		
		@param capacity the initial physical space for storing the elements at the time this hash table is initialized.
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
		
		#if alchemy
		mNext = new IntMemory(capacity, "IntHashTable.mNext");
		mKeys = new IntMemory(capacity, "IntHashTable.mKeys");
		mKeys.setAll(IntIntHashTable.KEY_ABSENT);
		#else
		mNext = NativeArrayTools.alloc(capacity);
		mKeys = NativeArrayTools.alloc(capacity).init(IntIntHashTable.KEY_ABSENT, 0, capacity);
		#end
		
		var t = mNext;
		for (i in 0...capacity - 1) t.set(i, i + 1);
		t.set(capacity - 1, IntIntHashTable.NULL_POINTER);
	}
	
	/**
		Counts the total number of collisions.
		
		A collision occurs when two distinct keys are hashed into the same slot.
	**/
	public function getCollisionCount():Int
	{
		return mH.getCollisionCount();
	}
	
	/**
		Returns the value that is mapped to `key` or null if `key` does not exist.
		
		Uses move-to-front-on-access which reduces access time when similar keys are frequently queried.
	**/
	public inline function getFront(key:Int):T
	{
		var i = mH.getFront(key);
		if (i == IntIntHashTable.KEY_ABSENT)
			return cast null;
		else
			return mVals.get(i);
	}
	
	/**
		Maps `val` to `key` in this map, but only if `key` does not exist yet.
		@return true if `key` was mapped to `val` for the first time.
	**/
	public inline function setIfAbsent(key:Int, val:T):Bool
	{
		assert(key != IntIntHashTable.KEY_ABSENT, "key 0x80000000 is reserved");
		
		if (size == capacity) grow();
		
		var i = mFree;
		if (mH.setIfAbsent(key, i))
		{
			mVals.set(i, val);
			mKeys.set(i, key);
			mFree = mNext.get(i);
			mSize++;
			return true;
		}
		else
			return false;
	}
	
	/**
		Redistributes all keys over `slotCount`.
		
		This is an expensive operations as the hash table is rebuild from scratch.
	**/
	public function rehash(slotCount:Int):IntHashTable<T>
	{
		mH.rehash(slotCount);
		return this;
	}
	
	/**
		Remaps the first occurrence of `key` to a new value `val`.
		@return true if `val` was successfully remapped to `key`.
	**/
	public inline function remap(key:Int, val:T):Bool
	{
		var i = mH.get(key);
		if (i != IntIntHashTable.KEY_ABSENT)
		{
			mVals.set(i, val);
			return true;
		}
		else
			return false;
	}
	
	/**
		Creates and returns an unordered array of all keys.
	**/
	public function toKeyArray():Array<Int>
	{
		return mH.toKeyArray();
	}
	
	/**
		Prints out all elements.
	**/
	#if !no_tostring
	public function toString():String
	{
		var b = new StringBuf();
		b.add(Printf.format('[ IntHashTable size=$size capacity=$capacity load=%.2f', [loadFactor]));
		if (isEmpty())
		{
			b.add(" ]");
			return b.toString();
		}
		b.add("\n");
		var max = 0.;
		for (key in keys()) max = Math.max(max, key);
		var i = 1;
		while (max != 0)
		{
			i++;
			max = Std.int(max / 10);
		}
		
		var args = new Array<Dynamic>();
		var fmt = '  %- ${i}d -> %s\n';
		
		var keys = [for (key in keys()) key];
		keys.sort(function(u, v) return u - v);
		i = 1;
		var k = keys.length;
		var j = 0;
		var c = 1;
		inline function print(key:Int)
		{
			args[0] = key;
			if (c > 1)
			{
				var tmp = [];
				getAll(key, tmp);
				args[1] = tmp.join(",");
			}
			else
				args[1] = Std.string(mVals[mH.get(key)]);
			b.add(Printf.format(fmt, args));
		}
		while (i < k)
		{
			if (keys[j] == keys[i])
				c++;
			else
			{
				print(keys[j]);
				j = i;
				c = 1;
			}
			i++;
		}
		print(keys[j]);
		
		b.add("]");
		return b.toString();
	}
	#end
	
	/* INTERFACE Map */
	
	/**
		Returns true if this map contains a mapping for the value `val`.
	**/
	public function has(val:T):Bool
	{
		var k = mKeys, v = mVals;
		for (i in 0...capacity)
		{
			if (k.get(i) == IntIntHashTable.KEY_ABSENT) continue;
			if (v.get(i) == val) return true;
		}
		return false;
	}
	
	/**
		Returns true if this map contains `key`.
	**/
	public inline function hasKey(key:Int):Bool
	{
		return mH.hasKey(key);
	}
	
	/**
		Counts the number of mappings for `key`.
	**/
	public function count(key:Int):Int
	{
		return mH.count(key);
	}
	
	/**
		Returns the first value that is mapped to `key` or null if `key` does not exist.
	**/
	public inline function get(key:Int):T
	{
		var i = mH.get(key);
		return i == IntIntHashTable.KEY_ABSENT ? cast null : mVals.get(i);
	}
	
	/**
		Stores all values that are mapped to `key` in `out` or returns 0 if `key` does not exist.
		@return the total number of values mapped to `key`.
	**/
	public function getAll(key:Int, out:Array<T>):Int
	{
		var i = mH.get(key);
		if (i == IntIntHashTable.KEY_ABSENT)
			return 0;
		else
		{
			var b = mTmpKeyBuffer;
			var c = mH.getAll(key, b);
			var v = mVals;
			for (j in 0...c) out[j] = v.get(b[j]);
			return c;
		}
	}
	
	/**
		Maps the value `val` to `key`.
		
		The method allows duplicate keys.
		<br/>To ensure unique keys either use `this.hasKey()` before `this.set()` or `this.setIfAbsent()`.
		@return true if `key` was added for the first time, false if another instance of `key` was inserted.
	**/
	public function set(key:Int, val:T):Bool
	{
		assert(key != IntIntHashTable.KEY_ABSENT, "key 0x80000000 is reserved");
		
		if (size == capacity) grow();
		
		var i = mFree;
		var first = mH.set(key, i);
		mVals.set(i, val);
		mKeys.set(i, key);
		mFree = mNext.get(i);
		mSize++;
		return first;
	}
	
	/**
		Removes the first occurrence of `key`.
		@return true if `key` is successfully removed.
	**/
	public function unset(key:Int):Bool
	{
		var i = mH.get(key);
		
		if (i == IntIntHashTable.KEY_ABSENT) return false;
		
		mVals.set(i, cast null);
		mKeys.set(i, IntIntHashTable.KEY_ABSENT);
		mNext.set(i, mFree);
		mFree = i;
		mH.unset(key);
		mSize--;
		return true;
	}
	
	/**
		Creates a `ListSet` object of the values in this map.
	**/
	public function toValSet():Set<T>
	{
		var s = new ListSet<T>(), k = mKeys, v = mVals;
		for (i in 0...capacity)
			if (k.get(i) != IntIntHashTable.KEY_ABSENT)
				s.set(v.get(i));
		return s;
	}
	
	/**
		Creates a `ListSet` object of the keys in this map.
	**/
	public function toKeySet():Set<Int>
	{
		return mH.toKeySet();
	}
	
	/**
		Returns a new *IntIntHashTableKeyIterator* object to iterate over all keys stored in this map.
		
		The keys are visited in a random order.
		
		@see http://haxe.org/ref/iterators
	**/
	public function keys():Itr<Int>
	{
		return mH.keys();
	}
	
	/**
		Free up resources by reducing the capacity of the internal container to the initial capacity.
	**/
	public function pack():IntHashTable<T>
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
		
		var srcKeys = mKeys;
		
		#if alchemy
		var dstKeys = new IntMemory(capacity, "IntHashTable.mKeys");
		#else
		var dstKeys = NativeArrayTools.alloc(capacity);
		#end
		
		var srcVals = mVals;
		var dstVals = NativeArrayTools.alloc(capacity);
		
		var j = mFree;
		for (i in mH)
		{
			dstKeys.set(j, srcKeys.get(i));
			dstVals.set(j, srcVals.get(i));
			j = mNext.get(j);
		}
		mFree = j;
		
		#if alchemy
		mKeys.free();
		#end
		
		mKeys = dstKeys;
		mVals = dstVals;
		for (i in 0...size) mH.remap(dstKeys.get(i), i);
		return this;
	}
	
	/**
		Calls `f` on all {Int,T} pairs in random order.
	**/
	public inline function iter(f:Int->T->Void):IntHashTable<T>
	{
		assert(f != null);
		var vals = mVals;
		mH.iter(function(k, v) f(k, vals.get(v)));
		return this;
	}
	
	function grow()
	{
		var oldCapacity = capacity;
		capacity = GrowthRate.compute(growthRate, capacity);
		
		var t;
		
		#if alchemy
		mNext.resize(capacity);
		mKeys.resize(capacity);
		#else
		t = NativeArrayTools.alloc(capacity);
		mNext.blit(0, t, 0, oldCapacity);
		mNext = t;
		t = NativeArrayTools.alloc(capacity);
		mKeys.blit(0, t, 0, oldCapacity);
		mKeys = t;
		#end
		
		t = mKeys;
		for (i in oldCapacity...capacity)
			t.set(i, IntIntHashTable.KEY_ABSENT);
		
		t = mNext;
		for (i in oldCapacity - 1...capacity - 1) t.set(i, i + 1);
		t.set(capacity - 1, IntIntHashTable.NULL_POINTER);
		mFree = oldCapacity;
		
		var v = NativeArrayTools.alloc(capacity);
		mVals.blit(0, v, 0, oldCapacity);
		mVals = v;
	}
	
	/* INTERFACE Collection */
	
	/**
		The total number of key/value pairs.
	**/
	public var size(get, never):Int;
	inline function get_size():Int
	{
		return mSize;
	}
	
	/**
		Destroys this object by explicitly nullifying all key/values.
		
		_If compiled with -D alchemy , always call this method when the life cycle of this object ends to prevent a memory leak._
	**/
	public function free()
	{
		mVals.nullify();
		mVals = null;
		
		#if (flash && alchemy)
		mNext.free();
		mKeys.free();
		#end
		
		mKeys = null;
		mNext = null;
		
		mH.free();
		mH = null;
		if (mIterator != null)
		{
			mIterator.free();
			mIterator = null;
		}
		mTmpKeyBuffer = null;
	}
	
	/**
		Same as `this.has()`.
	**/
	public function contains(val:T):Bool
	{
		return has(val);
	}

	/**
		Removes all occurrences of the value `val`.
		@return true if `val` was removed, false if `val` does not exist.
	**/
	public function remove(val:T):Bool
	{
		var b = mTmpKeyBuffer;
		var c = 0;
		var k = mKeys, v = mVals, j;
		for (i in 0...capacity)
		{
			j = k.get(i);
			if (j != IntIntHashTable.KEY_ABSENT)
				if (v.get(i) == val)
					b[c++] = j;
		}
		for (i in 0...c) unset(b[i]);
		return c > 0;
	}
	
	/**
		Removes all elements.
		
		The `gc` parameter has no effect.
	**/
	public function clear(gc:Bool = false)
	{
		mH.clear(gc);
		
		#if alchemy
		mKeys.setAll(IntIntHashTable.KEY_ABSENT);
		#else
		mKeys.init(IntIntHashTable.KEY_ABSENT, 0, capacity);
		#end
		
		var t = mNext;
		for (i in 0...capacity - 1) t.set(i, i + 1);
		t.set(capacity - 1, IntIntHashTable.NULL_POINTER);
		mFree = 0;
		mSize = 0;
	}

	/**
		Returns a new *IntHashTableIterator* object to iterate over all values contained in this hash table.
		
		The values are visited in a random order.
		
		@see http://haxe.org/ref/iterators
	**/
	public function iterator():Itr<T>
	{
		if (reuseIterator)
		{
			if (mIterator == null)
				mIterator = new IntHashTableIterator<T>(this);
			else
				mIterator.reset();
			return mIterator;
		}
		else
			return new IntHashTableIterator<T>(this);
	}
	
	/**
		Returns true only if `this.size` is 0.
	**/
	public inline function isEmpty():Bool
	{
		return mSize == 0;
	}
	
	/**
		Returns an unordered array containing all values in this hash table.
	**/
	public function toArray():Array<T>
	{
		if (size == 0) return [];
		
		var out = ArrayTools.alloc(size);
		var j = 0, k = mKeys, v = mVals;
		for (i in 0...capacity)
			if (k.get(i) != IntIntHashTable.KEY_ABSENT)
				out[j++] = v.get(i);
		return out;
	}
	
	/**
		Creates and returns a shallow copy (structure only - default) or deep copy (structure & elements) of this hash table.
		
		If `byRef` is true, primitive elements are copied by value whereas objects are copied by reference.
		
		If `byRef` is false, the `copier` function is used for copying elements. If omitted, `clone()` is called on each element assuming all elements implement `Cloneable`.
	**/
	public function clone(byRef:Bool = true, copier:T->T = null):Collection<T>
	{
		var c = new IntHashTable<T>(slotCount, size);
		c.mH = cast mH.clone(false);
		c.mSize = size;
		c.mFree = mFree;
		
		var src = mVals;
		var dst = c.mVals;
		
		if (byRef)
			src.blit(0, dst, 0, size);
		else
		{
			var k = mKeys;
			
			inline function hasKey(x) return k.get(x) != IntIntHashTable.KEY_ABSENT;
			
			if (copier != null)
			{
				for (i in 0...size)
					if (hasKey(i))
						dst.set(i, copier(src.get(i)));
			}
			else
			{
				for (i in 0...size)
				{
					if (hasKey(i))
					{
						assert(Std.is(src.get(i), Cloneable), "element is not of type Cloneable");
						
						dst.set(i, cast(src.get(i), Cloneable<Dynamic>).clone());
					}
				}
			}
		}
		
		#if alchemy
		IntMemory.blit(mKeys, 0, c.mKeys, 0, size);
		IntMemory.blit(mNext, 0, c.mNext, 0, size);
		#else
		mKeys.blit(0, c.mKeys, 0, size);
		mNext.blit(0, c.mNext, 0, size);
		#end
		return c;
	}
}

#if generic
@:generic
#end
@:access(de.polygonal.ds.IntHashTable)
@:dox(hide)
class IntHashTableIterator<T> implements de.polygonal.ds.Itr<T>
{
	var mObject:IntHashTable<T>;
	var mVals:NativeArray<T>;
	
	#if alchemy
	var mKeys:IntMemory;
	#else
	var mKeys:NativeArray<Int>;
	#end
	
	var mI:Int;
	var mS:Int;
	
	public function new(x:IntHashTable<T>)
	{
		mObject = x;
		reset();
	}
	
	public function free()
	{
		mObject = null;
		mVals = null;
		mKeys = null;
	}
	
	public function reset():Itr<T>
	{
		mVals = mObject.mVals;
		mKeys = mObject.mKeys;
		mS = mObject.mH.capacity;
		mI = 0;
		
		#if (flash && alchemy)
		while (mI < mS && mKeys.get(mI) == IntIntHashTable.KEY_ABSENT) mI++;
		#else
		while (mI < mS && mKeys.get(mI) == IntIntHashTable.KEY_ABSENT) mI++;
		#end
		return this;
	}
	
	public inline function hasNext():Bool
	{
		return mI < mS;
	}
	
	public inline function next():T
	{
		#if (flash && alchemy)
		var v = mVals.get(mI);
		while (++mI < mS && mKeys.get(mI) == IntIntHashTable.KEY_ABSENT) {}
		#else
		var v = mVals.get(mI);
		while (++mI < mS && mKeys.get(mI) == IntIntHashTable.KEY_ABSENT) {}
		#end
		return v;
	}
	
	public function remove()
	{
		throw "unsupported operation";
	}
}