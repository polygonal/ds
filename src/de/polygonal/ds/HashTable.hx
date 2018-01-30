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
	An array hash table for mapping Hashable keys to generic elements
	
	The implementation is based on `IntIntHashTable`.
	
	Example:
		class Element extends de.polygonal.ds.HashableItem {
		    var i:Int;
		    public function new(i:Int) {
		        super();
		        this.i = i;
		    }
		    public function toString():String {
		        return "Element" + i;
		    }
		}
		
		...
		
		var o = new de.polygonal.ds.HashTable<Element, String>(16);
		o.set(new Element(1), "a");
		o.set(new Element(2), "b");
		o.set(new Element(3), "c");
		trace(o); //outputs:
		
		[ HashTable size=4 capacity=16 load=0.25
		  Element1 -> a
		  Element2 -> b
		  Element3 -> c
		]
**/
#if generic
@:generic
#end
class HashTable<K:Hashable, T> implements Map<K, T>
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
	
	/**
		If true, reuses the iterator object instead of allocating a new one when calling `this.iterator()`.
		
		The default is false.
		
		_If this value is true, nested iterations will fail as only one iteration is allowed at a time._
	**/
	public var reuseIterator:Bool = false;
	
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
	
	var mH:IntIntHashTable;
	var mKeys:NativeArray<K>;
	var mVals:NativeArray<T>;
	#if alchemy
	var mNext:IntMemory;
	#else
	var mNext:NativeArray<Int>;
	#end
	
	var mFree:Int = 0;
	var mSize:Int = 0;
	var mMinCapacity:Int;
	var mIterator:HashTableValIterator<K, T> = null;
	var mTmpIntBuffer:Array<Int> = [];
	var mTmpKeyBuffer:Array<K> = [];
	
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
		mKeys = NativeArrayTools.alloc(capacity);
		mVals = NativeArrayTools.alloc(capacity);
		
		#if alchemy
		mNext = new IntMemory(capacity, "HashTable.mNext");
		#else
		mNext = NativeArrayTools.alloc(capacity);
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
	public inline function getFront(key:K):T
	{
		var i = mH.getFront(key.key);
		if (i == IntIntHashTable.KEY_ABSENT)
			return null;
		else
			return mVals.get(i);
	}
	
	/**
		Maps `val` to `key` in this map, but only if `key` does not exist yet.
		@return true if `key` was mapped to `val` for the first time.
	**/
	public inline function setIfAbsent(key:K, val:T):Bool
	{
		assert(key != null);
		
		if (size == capacity) grow();
		
		var i = mFree;
		if (mH.setIfAbsent(key.key, i))
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
	public function rehash(slotCount:Int):HashTable<K, T>
	{
		mH.rehash(slotCount);
		return this;
	}
	
	/**
		Remaps the first occurrence of `key` to a new value `val`.
		@return true if `val` was successfully remapped to `key`.
	**/
	public inline function remap(key:K, val:T):Bool
	{
		assert(key != null);
		
		var i = mH.get(key.key);
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
	public function toKeyArray():Array<K>
	{
		if (isEmpty()) return [];
		
		var out = ArrayTools.alloc(size);
		var j = 0, keys = mKeys, k;
		for (i in 0...capacity)
		{
			k = keys.get(i);
			if (k != null) out[j++] = k;
		}
		return out;
	}
	
	/**
		Free up resources by reducing the capacity of the internal container to the initial capacity.
	**/
	public function pack():HashTable<K, T>
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
		var dstKeys = NativeArrayTools.alloc(capacity);
		
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
		
		mKeys = dstKeys;
		mVals = dstVals;
		for (i in 0...size) mH.remap(dstKeys.get(i).key, i);
		return this;
	}
	
	/**
		Calls `f` on all {K,T} pairs in random order.
	**/
	@:access(de.polygonal.ds.IntIntHashTable)
	public inline function iter(f:K->T->Void):HashTable<K, T>
	{
		assert(f != null);
		var d = mH.mData, vals = mVals, keys = mKeys, v;
		for (i in 0...mH.capacity)
		{
			v = d.get(i * 3 + 1);
			if (v != IntIntHashTable.VAL_ABSENT) f(keys.get(v), vals.get(v));
		}
		return this;
	}
	
	/**
		Prints out all elements.
	**/
	#if !no_tostring
	public function toString():String
	{
		var b = new StringBuf();
		b.add(Printf.format('[ HashTable size=$size capacity=$capacity load=%.2f', [loadFactor]));
		if (isEmpty())
		{
			b.add(" ]");
			return b.toString();
		}
		b.add("\n");
		var l = 0;
		for (key in keys()) l = MathTools.max(l, Std.string(key).length);
		var args = new Array<Dynamic>();
		var fmt = '  %- ${l}s -> %s\n';
		
		var keys = [for (key in keys()) key];
		keys.sort(function(u, v) return u.key - v.key);
		var i = 1;
		var k = keys.length;
		var j = 0;
		var c = 1;
		inline function print(key:K)
		{
			args[0] = key;
			if (c > 1)
			{
				var tmp = [];
				getAll(key, tmp);
				args[1] = tmp.join(",");
			}
			else
				args[1] = Std.string(get(key));
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
		mVals.blit(0, v, 0, oldCapacity);
		mVals = v;
		
		var k = NativeArrayTools.alloc(capacity);
		mKeys.blit(0, k, 0, oldCapacity);
		mKeys = k;
	}
	
	/* INTERFACE Map */
	
	/**
		Returns true if this map contains a mapping for the value `val`.
	**/
	public function has(val:T):Bool
	{
		var k = mKeys, v = mVals;
		for (i in 0...capacity)
		{
			if (k.get(i) == null) continue;
			if (v.get(i) == val) return true;
		}
		return false;
	}
	
	/**
		Returns true if this map contains `key`.
	**/
	public inline function hasKey(key:K):Bool
	{
		assert(key != null);
		
		return mH.hasKey(key.key);
	}
	
	/**
		Returns the value that is mapped to `key` or null if `key` does not exist.
	**/
	public inline function get(key:K):T
	{
		assert(key != null);
		
		var i = mH.get(key.key);
		return i == IntIntHashTable.KEY_ABSENT ? null : mVals.get(i);
	}
	
	/**
		Stores all values that are mapped to `key` in `out` or returns 0 if `key` does not exist.
		@return the total number of values mapped to `key`.
	**/
	public function getAll(key:K, out:Array<T>):Int
	{
		var i = mH.get(key.key);
		if (i == IntIntHashTable.KEY_ABSENT)
			return 0;
		else
		{
			var b = mTmpIntBuffer;
			var c = mH.getAll(key.key, b);
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
	public function set(key:K, val:T):Bool
	{
		assert(key != null);
		
		if (size == capacity) grow();
		
		var i = mFree;
		var first = mH.set(key.key, i);
		mVals.set(i, val);
		mKeys.set(i, key);
		mFree = mNext.get(i);
		mSize++;
		return first;
	}
	
	/**
		Removes and nullifies the first occurrence of `key`.
		
		Only the key is nullified, to nullify the value call `this.pack()`.
		@return true if `key` is successfully removed.
	**/
	public function unset(key:K):Bool
	{
		var i = mH.get(key.key);
		if (i == IntIntHashTable.KEY_ABSENT) return false;
		mKeys.set(i, null);
		mNext.set(i, mFree);
		mFree = i;
		mH.unset(key.key);
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
			if (k.get(i) != null)
				s.set(v.get(i));
		return s;
	}
	
	/**
		Creates a `ListSet` object of the keys in this map.
	**/
	public function toKeySet():Set<K>
	{
		var s = new ListSet<K>(), t = mKeys, k;
		for (i in 0...capacity)
		{
			k = t.get(i);
			if (k != null) s.set(k);
		}
		return s;
	}
	
	/**
		Returns a new *HashTableKeyIterator* object to iterate over all keys stored in this map.
		
		The keys are visited in a random order.
		
		@see http://haxe.org/ref/iterators
	**/
	public function keys():Itr<K>
	{
		return new HashTableKeyIterator(this);
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
		
		mKeys.nullify();
		mKeys = null;
		
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
		mTmpIntBuffer = null;
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
		var found = false;
		var b = mTmpKeyBuffer;
		var k = mKeys, v = mVals, j;
		var c = 0;
		
		for (i in 0...capacity)
		{
			j = k.get(i);
			if (j == null) continue;
			if (v.get(i) == val)
			{
				b[c++] = j;
				found = true;
			}
		}
		
		for (i in 0...c)
		{
			unset(b[i]);
			b[i] = null;
		}
		return c > 0;
	}
	
	/**
		Removes all key/value pairs.
		
		The `gc` parameter has no effect.
	**/
	public function clear(gc:Bool = false)
	{
		mH.clear(gc);
		
		mKeys.init(null, 0, capacity);
		mVals.init(null, 0, capacity);
		
		var t = mNext;
		for (i in 0...capacity - 1) t.set(i, i + 1);
		t.set(capacity - 1, IntIntHashTable.NULL_POINTER);
		mFree = 0;
		mSize = 0;
	}
	
	/**
		Returns a new *HashTableValIterator* object to iterate over all values contained in this hash table.
		
		The values are visited in a random order.
		
		@see http://haxe.org/ref/iterators
	**/
	public function iterator():Itr<T>
	{
		if (reuseIterator)
		{
			if (mIterator == null)
				mIterator = new HashTableValIterator<K, T>(this);
			else
				mIterator.reset();
			return mIterator;
		}
		else
			return new HashTableValIterator<K, T>(this);
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
		if (isEmpty()) return [];
		
		var out = ArrayTools.alloc(size);
		var j = 0, keys = mKeys, vals = mVals;
		for (i in 0...capacity)
			if (keys.get(i) != null)
				out[j++] = vals.get(i);
		return out;
	}
	
	/**
		Creates and returns a shallow copy (structure only - default) or deep copy (structure & elements) of this hash table.
		
		If `byRef` is true, primitive elements are copied by value whereas objects are copied by reference.
		
		If `byRef` is false, the `copier` function is used for copying elements. If omitted, `clone()` is called on each element assuming all elements implement `Cloneable`.
	**/
	public function clone(byRef:Bool = true, copier:T->T = null):Collection<T>
	{
		var c = new HashTable<K, T>(slotCount, size);
		c.mH = cast mH.clone();
		c.mSize = size;
		c.mFree = mFree;
		
		var srcVals = mVals;
		var dstVals = c.mVals;
		
		var srcKeys = mKeys;
		var dstKeys = c.mKeys;
		
		srcKeys.blit(0, dstKeys, 0, size);
		
		if (byRef)
			srcVals.blit(0, dstVals, 0, size);
		else
		{
			if (copier != null)
			{
				for (i in 0...size)
				{
					if (srcKeys.get(i) != null)
						dstVals.set(i, copier(srcVals.get(i)));
					else
						dstVals.set(i, null);
				}
			}
			else
			{
				for (i in 0...size)
				{
					if (srcKeys.get(i) != null)
					{
						assert(Std.is(srcVals.get(i), Cloneable), "element is not of type Cloneable");
						
						dstVals.set(i, cast(srcVals.get(i), Cloneable<Dynamic>).clone());
					}
					else
						dstVals.set(i, null);
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
@:access(de.polygonal.ds.HashTable)
@:dox(hide)
class HashTableKeyIterator<K:Hashable, T> implements de.polygonal.ds.Itr<K>
{
	var mObject:HashTable<K, T>;
	var mKeys:NativeArray<K>;
	var mI:Int;
	var mS:Int;
	
	public function new(x:HashTable<K, T>)
	{
		mObject = x;
		reset();
	}
	
	public function free()
	{
		mObject = null;
		mKeys = null;
	}
	
	public function reset():Itr<K>
	{
		mKeys = mObject.mKeys;
		mS = mObject.mH.capacity;
		mI = 0;
		while (mI < mS && mKeys.get(mI) == null) mI++;
		return this;
	}
	
	public inline function hasNext():Bool
	{
		return mI < mS;
	}

	public inline function next():K
	{
		var v = mKeys.get(mI);
		while (++mI < mS && mKeys.get(mI) == null) {}
		return v;
	}
	
	public function remove()
	{
		throw "unsupported operation";
	}
}

#if generic
@:generic
#end
@:access(de.polygonal.ds.HashTable)
@:dox(hide)
class HashTableValIterator<K:Hashable, T> implements de.polygonal.ds.Itr<T>
{
	var mObject:HashTable<K, T>;
	var mKeys:NativeArray<K>;
	var mVals:NativeArray<T>;
	var mI:Int;
	var mS:Int;
	
	public function new(x:HashTable<K, T>)
	{
		mObject = x;
		reset();
	}
	
	public function free()
	{
		mObject = null;
		mKeys = null;
		mVals = null;
	}
	
	public function reset():Itr<T>
	{
		mVals = mObject.mVals;
		mKeys = mObject.mKeys;
		mS = mObject.mH.capacity;
		mI = 0;
		while (mI < mS && mKeys.get(mI) == null) mI++;
		return this;
	}
	
	public inline function hasNext():Bool
	{
		return mI < mS;
	}
	
	public inline function next():T
	{
		var v = mVals.get(mI);
		while (++mI < mS && mKeys.get(mI) == null) {}
		return v;
	}
	
	public function remove()
	{
		throw "unsupported operation";
	}
}