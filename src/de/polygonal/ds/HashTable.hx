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

#if (flash && alchemy)
import de.polygonal.ds.mem.IntMemory;
#end

import de.polygonal.ds.tools.ArrayTools;
import de.polygonal.ds.tools.Assert.assert;
import de.polygonal.ds.tools.GrowthRate;
import de.polygonal.ds.tools.M;

using de.polygonal.ds.tools.NativeArrayTools;

/**
	An array hash table for mapping Hashable keys to generic elements
	
	The implementation is based on `IntIntHashTable`.
**/
#if generic
@:generic
#end
class HashTable<K:Hashable, T> implements Map<K, T>
{
	/**
		A unique identifier for this object.
		
		A hash table transforms this key into an index of an array element by using a hash function.
		
		<warn>This value should never be changed by the user.</warn>
	**/
	public var key(default, null):Int = HashKey.next();
	
	/**
		The size of the allocated storage space for the key/value pairs.
		
		If more space is required to accomodate new elements, ``capacity`` is doubled every time ``size`` grows beyond capacity, and split in half when ``size`` is a quarter of capacity.
		
		The capacity never falls below the initial size defined in the constructor.
	**/
	public var capacity(default, null):Int;
	
	/**
		The load factor measure the "denseness" of a hash table and is proportional to the time cost to look up an entry.
		
		E.g. assuming that the keys are perfectly distributed, a load factor of 4.0 indicates that each slot stores 4 keys, which have to be sequentially searched in order to find a value.
		
		A high load factor thus indicates poor performance.
		
		If the load factor gets too high, additional slots can be allocated by calling ``rehash()``.
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
		If true, reuses the iterator object instead of allocating a new one when calling ``iterator()``.
		
		The default is false.
		
		<warn>If true, nested iterations are likely to fail as only one iteration is allowed at a time.</warn>
	**/
	public var reuseIterator:Bool = false;
	
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
		<assert>`slotCount` is not a power of two</assert>
		<assert>`capacity` is not a power of two</assert>
		<assert>`capacity` is < 2</assert>
		@param slotCount the total number of slots into which the hashed keys are distributed.
		This defines the space-time trade off of the hash table.
		Increasing the `slotCount` reduces the computation time (read/write/access) of the hash table at the cost of increased memory use.
		This value is fixed and can only be changed by calling ``rehash()``, which rebuilds the hash table (expensive).
		
		@param capacity the initial physical space for storing the key/value pairs at the time the hash table is created.
		This is also the minimum allowed size of the hash table and cannot be changed in the future. If omitted, the initial `capacity` equals `slotCount`.
		The `capacity` is automatically adjusted according to the storage requirements based on two rules:
		<ul>
		<li>If the hash table runs out of space, the `capacity` is doubled.</li>
		<li>If the size falls below a quarter of the current `capacity`, the `capacity` is cut in half while the minimum `capacity` can't fall below `capacity`.</li>
		</ul>
	**/
	public function new(slotCount:Int, initialCapacity:Int = -1)
	{
		assert(slotCount > 0);
		
		if (initialCapacity == -1) initialCapacity = slotCount;
		initialCapacity = M.max(2, initialCapacity);
		
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
		<assert>`key` is null</assert>
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
		<assert>out of space - hash table is full but not resizable</assert>
		<assert>`key` is null</assert>
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
		<assert>`slotCount` is not a power of two</assert>
	**/
	public function rehash(slotCount:Int)
	{
		mH.rehash(slotCount);
	}
	
	/**
		Remaps the first occurrence of `key` to a new value `val`.
		<assert>`key` is null</assert>
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
	
	public function pack()
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
		    static function main() {
		        var hash = new de.polygonal.ds.HashTable<Foo, String>(16);
		        for (i in 0...4) hash.set(new Foo(i), "foo"  + i);
		        trace(hash);
		    }
		}</pre>
		<pre class="console">
		{ HashTable size/capacity: 4/16, load factor: 0.25 }
		[
		  {Foo val: 0} -> foo0
		  {Foo val: 1} -> foo1
		  {Foo val: 2} -> foo2
		  {Foo val: 3} -> foo3
		]</pre>
	**/
	public function toString():String
	{
		var b = new StringBuf();
		b.add(Printf.format("{ HashTable size/capacity: %d/%d, load factor: %.2f }", [size, capacity, loadFactor]));
		if (isEmpty()) return b.toString();
		b.add("\n[\n");
		
		var l = 0;
		for (key in keys()) l = M.max(l, Std.string(key).length);
		
		var args = new Array<Dynamic>();
		var fmt = '  %- ${l}s -> %s\n';
		for (key in keys())
		{
			args[0] = key;
			args[1] = Std.string(get(key));
			b.add(Printf.format(fmt, args));
		}
		b.add("]");
		return b.toString();
	}
	
	function grow()
	{
		var oldCapacity = capacity;
		capacity = GrowthRate.compute(growthRate, capacity);
		
		var t;
		#if alchemy
		mNext.resize(capacity);
		#else
		var t = NativeArrayTools.alloc(capacity);
		mNext.blit(0, t, 0, oldCapacity);
		mNext = t;
		#end
		
		t = mNext;
		for (i in oldCapacity - 1...capacity - 1) t.set(i, i + 1);
		t.set(capacity - 1, IntIntHashTable.NULL_POINTER);
		mFree = oldCapacity;
		
		var t = NativeArrayTools.alloc(capacity);
		mVals.blit(0, t, 0, oldCapacity);
		mVals = t;
		
		var t = NativeArrayTools.alloc(capacity);
		mKeys.blit(0, t, 0, oldCapacity);
		mKeys = t;
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
		<assert>`key` is null</assert>
	**/
	public inline function hasKey(key:K):Bool
	{
		assert(key != null);
		
		return mH.hasKey(key.key);
	}
	
	/**
		Returns the value that is mapped to `key` or null if `key` does not exist.
		<assert>`key` is null</assert>
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
			for (i in 0...c) out[i] = v.get(b[i]);
			return c;
		}
	}
	
	/**
		Maps the value `val` to `key`.
		
		The method allows duplicate keys.
		
		<warn>To ensure unique keys either use ``hasKey()`` before ``set()`` or ``setIfAbsent()``</warn>
		<assert> out of space - hash table is full but not resizable</assert>
		<assert>`key` is null</assert>
		@return true if `key` was added for the first time, false if another instance of `key` was inserted.
	**/
	public inline function set(key:K, val:T):Bool
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
		
		Only the key is nullified, to nullifiy the value call ``pack()``.
		<assert>`key` is null</assert>
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
		Returns a new `HashTableKeyIterator` object to iterate over all keys stored in this map.
		
		The keys are visited in a random order.
		
		See <a href="http://haxe.org/ref/iterators" target="mBlank">http://haxe.org/ref/iterators</a>
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
		
		<warn>If "alchemy memory" is used, always call this method when the life cycle of this object ends to prevent a memory leak.</warn>
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
		Same as ``has()``.
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
		Returns a new `HashTableValIterator` object to iterate over all values contained in this hash table.
		
		The values are visited in a random order.
		
		See <a href="http://haxe.org/ref/iterators" target="mBlank">http://haxe.org/ref/iterators</a>
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
		Returns true if this hash table is empty.
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
		var j = 0, keys = mKeys, vals = mVals, k;
		for (i in 0...capacity)
			if (keys.get(i) != null)
				out[j++] = vals.get(i);
		return out;
	}
	
	/**
		Duplicates this hash table. Supports shallow (structure only) and deep copies (structure & elements).
		<assert>element is not of type `Cloneable`</assert>
		@param assign if true, the `copier` parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.
		If false, the ``clone()`` method is called on each element. <warn>In this case all elements have to implement `Cloneable`.</warn>
		@param copier a custom function for copying elements. Replaces ``element::clone()`` if `assign` is false.
	**/
	public function clone(assign:Bool = true, copier:T->T = null):Collection<T>
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
		
		if (assign)
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