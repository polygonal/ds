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

#if (flash && alchemy)
import de.polygonal.ds.mem.IntMemory;
#end

import de.polygonal.ds.error.Assert.assert;

using de.polygonal.ds.tools.NativeArray;

/**
	An array hash table for mapping Hashable keys to generic elements
	
	The implementation is based on `IntIntHashTable`.
	
	_<o>Worst-case running time in Big O notation</o>_
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
	public var key(default, null):Int;
	
	/**
		If true, reuses the iterator object instead of allocating a new one when calling ``iterator()``.
		
		The default is false.
		
		<warn>If true, nested iterations are likely to fail as only one iteration is allowed at a time.</warn>
	**/
	public var reuseIterator:Bool;
	
	/**
		The size of the allocated storage space for the key/value pairs.
		
		If more space is required to accomodate new elements, ``capacity`` is doubled every time ``size()`` grows beyond capacity, and split in half when ``size()`` is a quarter of capacity.
		
		The capacity never falls below the initial size defined in the constructor.
	**/
	public var capacity(get, never):Int;
	inline function get_capacity():Int
	{
		return mH.capacity;
	}
	
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
	
	var mH:IntIntHashTable;
	var mKeys:Container<K>;
	var mVals:Container<T>;
	
	#if alchemy
	var mNext:IntMemory;
	#else
	var mNext:Container<Int>;
	#end
	
	var mFree:Int;
	var mMinCapacity:Int;
	var mIterator:HashTableValIterator<K, T>;
	var mTmpArr:Array<Int>;
	
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
	public function new(slotCount:Int, capacity = -1)
	{
		if (slotCount == M.INT16_MIN) return;
		assert(slotCount > 0);
		
		if (capacity == -1) capacity = slotCount;
		
		mMinCapacity = capacity;
		
		mH = new IntIntHashTable(slotCount, capacity);
		mKeys = NativeArray.init(capacity);
		mVals = NativeArray.init(capacity);
		
		#if alchemy
		mNext = new IntMemory(capacity, "HashTable.mNext");
		#else
		mNext = NativeArray.init(capacity);
		#end
		
		for (i in 0...capacity - 1) setNext(i, i + 1);
		setNext(capacity - 1, IntIntHashTable.NULL_POINTER);
		mFree = 0;
		mIterator = null;
		mTmpArr = [];
		
		key = HashKey.next();
		reuseIterator = false;
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
		<o>n</o>
		<assert>`key` is null</assert>
	**/
	inline public function getFront(key:K):T
	{
		var i = mH.getFront(_key(key));
		if (i == IntIntHashTable.KEY_ABSENT)
			return null;
		else
			return mVals[i];
	}
	
	/**
		Maps `val` to `key` in this map, but only if `key` does not exist yet.
		<o>n</o>
		<assert>out of space - hash table is full but not resizable</assert>
		<assert>`key` is null</assert>
		@return true if `key` was mapped to `val` for the first time.
	**/
	inline public function setIfAbsent(key:K, val:T):Bool
	{
		if ((size() == capacity))
		{
			if (mH.setIfAbsent(_key(key), size()))
			{
				grow(capacity >> 1);
				
				mVals[mFree] = val;
				mKeys[mFree] = key;
				mFree = getNext(mFree);
				return true;
			}
			else
				return false;
		}
		else
		{
			if (mH.setIfAbsent(_key(key), mFree))
			{
				mVals[mFree] = val;
				mKeys[mFree] = key;
				mFree = getNext(mFree);
				return true;
			}
			else
				return false;
		}
	}
	
	/**
		Redistributes all keys over `slotCount`.
		
		This is an expensive operations as the hash table is rebuild from scratch.
		<o>n</o>
		<assert>`slotCount` is not a power of two</assert>
	**/
	public function rehash(slotCount:Int)
	{
		mH.rehash(slotCount);
	}
	
	/**
		Remaps the first occurrence of `key` to a new value `val`.
		<o>n</o>
		<assert>`key` is null</assert>
		@return true if `val` was successfully remapped to `key`.
	**/
	inline public function remap(key:K, val:T):Bool
	{
		var i = mH.get(_key(key));
		if (i != IntIntHashTable.KEY_ABSENT)
		{
			mVals[i] = val;
			return true;
		}
		else
			return false;
	}
	
	/**
		Creates and returns an unordered array of all keys.
		<o>n</o>
	**/
	public function toKeyArray():Array<K>
	{
		if (isEmpty()) return [];
		
		var out = ArrayUtil.alloc(size());
		var j = 0, keys = mKeys, k;
		for (i in 0...capacity)
		{
			k = keys.get(i);
			if (k != null) out[j++] = k;
		}
		return out;
	}
	
	/**
		Creates and returns an unordered vector of all keys.
		<o>n</o>
	**/
	public function toKeyVector():Container<K>
	{
		var src = mKeys;
		var a = NativeArray.init(size());
		var j = 0;
		for (i in 0...capacity)
		{
			if (src.get(i) != null)
				a.set(j++, mKeys.get(i));
		}
		return a;
	}
	
	/**
		For performance reasons the hash table does nothing to ensure that empty locations contain null;
		``pack()`` therefore nullifies all obsolete references.
		<o>n</o>
	**/
	public function pack()
	{
		for (i in 0...capacity)
			if (mKeys[i] != null) mVals[i] = cast null;
	}
	
	/**
		Returns a string representing the current object.
		
		Example:
		<pre class="prettyprint">
		class Foo extends de.polygonal.ds.HashableItem
		{
		    var value:Int;
		    public function new(value:Int) {
		        super();
		        this.value = value;
		    }
		    public function toString():String {
		        return "{ Foo value: " + value + " }";
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
		  {Foo value: 0} -> foo0
		  {Foo value: 1} -> foo1
		  {Foo value: 2} -> foo2
		  {Foo value: 3} -> foo3
		]</pre>
	**/
	public function toString():String
	{
		var s = Printf.format("{ HashTable size/capacity: %d/%d, load factor: %.2f }", [size(), capacity, loadFactor]);
		if (isEmpty()) return s;
		s += "\n[\n";
		
		var max = 0;
		for (key in keys()) max = M.max(max, Std.string(key).length);
		
		for (key in keys())
			s += Printf.format("  %- " + max + "s -> %s\n", [key, Std.string(get(key))]);
		
		s += "]";
		return s;
	}
	
	/*///////////////////////////////////////////////////////
	// map
	///////////////////////////////////////////////////////*/
	
	/**
		Returns true if this map contains a mapping for the value `val`.
		<o>n</o>
	**/
	public function has(val:T):Bool
	{
		var exists = false;
		for (i in 0...capacity)
		{
			if (mKeys[i] != null)
			{
				if (mVals[i] == val)
				{
					exists = true;
					break;
				}
			}
		}
		return exists;
	}
	
	/**
		Returns true if this map contains `key`.
		<o>n</o>
		<assert>`key` is null</assert>
	**/
	inline public function hasKey(key:K):Bool
	{
		return mH.hasKey(_key(key));
	}
	
	/**
		Returns the value that is mapped to `key` or null if `key` does not exist.
		<o>n</o>
		<assert>`key` is null</assert>
	**/
	inline public function get(key:K):T
	{
		assert(key != null);
		
		var i = mH.get(_key(key));
		if (i == IntIntHashTable.KEY_ABSENT)
			return null;
		else
			return mVals[i];
	}
	
	/**
		Stores all values that are mapped to `key` in `output` or returns 0 if `key` does not exist.
		@return the total number of values mapped to `key`.
	**/
	public function getAll(key:K, output:Array<T>):Int
	{
		var i = mH.get(_key(key));
		if (i == IntIntHashTable.KEY_ABSENT)
			return 0;
		else
		{
			var c = mH.getAll(_key(key), mTmpArr);
			for (i in 0...c) output[i] = mVals[mTmpArr[i]];
			return c;
		}
	}
	
	/**
		Maps the value `val` to `key`.
		
		The method allows duplicate keys.
		
		<warn>To ensure unique keys either use ``hasKey()`` before ``set()`` or ``setIfAbsent()``</warn>
		<o>n</o>
		<assert> out of space - hash table is full but not resizable</assert>
		<assert>`key` is null</assert>
		@return true if `key` was added for the first time, false if another instance of `key` was inserted.
	**/
	inline public function set(key:K, val:T):Bool
	{
		if (size() == capacity)
			grow(capacity);
		
		var first = mH.set(_key(key), mFree);
		mVals[mFree] = val;
		mKeys[mFree] = key;
		
		mFree = getNext(mFree);
		return first;
	}
	
	/**
		Removes and nullifies the first occurrence of `key`.
		
		Only the key is nullified, to nullifiy the value call ``pack()``.
		<o>n</o>
		<assert>`key` is null</assert>
		@return true if `key` is successfully removed.
	**/
	inline public function clr(key:K):Bool
	{
		var i = mH.get(_key(key));
		if (i == IntIntHashTable.KEY_ABSENT)
			return false;
		else
		{
			mKeys[i] = null;
			setNext(i, mFree);
			mFree = i;
			
			var doShrink = false;
			
			if (size() - 1 == (capacity >> 2) && capacity > mMinCapacity)
				doShrink = true;
			
			mH.clr(_key(key));
			
			if (doShrink) shrink();
			
			return true;
		}
	}
	
	/**
		Creates a `ListSet` object of the values in this map.
		<o>n</o>
	**/
	public function toValSet():Set<T>
	{
		var s = new ListSet<T>();
		for (i in 0...capacity)
		{
			if (mKeys[i] != null)
				s.set(mVals[i]);
		}
		
		return s;
	}
	
	/**
		Creates a `ListSet` object of the keys in this map.
		<o>n</o>
	**/
	public function toKeySet():Set<K>
	{
		var s = new ListSet<K>();
		for (i in 0...capacity)
		{
			if (mKeys[i] != null)
				s.set(mKeys[i]);
		}
		
		return s;
	}
	
	/**
		Returns a new `HashTableKeyIterator` object to iterate over all keys stored in this map.
		
		The keys are visited in a random order.
		
		See <a href="http://haxe.org/ref/iterators" target="mBlank">http://haxe.org/ref/iterators</a>
		<o>n</o>
	**/
	public function keys():Itr<K>
	{
		return new HashTableKeyIterator(this);
	}
	
	/*///////////////////////////////////////////////////////
	// collection
	///////////////////////////////////////////////////////*/
	
	/**
		Destroys this object by explicitly nullifying all key/values.
		
		<warn>If "alchemy memory" is used, always call this method when the life cycle of this object ends to prevent a memory leak.</warn>
		<o>n</o>
	**/
	public function free()
	{
		for (i in 0...size())
		{
			mVals[i] = cast null;
			mKeys[i] = null;
		}
		mVals = null;
		mKeys = null;
		
		#if alchemy
		mNext.free();
		#end
		mNext = null;
		
		mH.free();
		mH = null;
		mIterator = null;
		mTmpArr = null;
	}
	
	/**
		Same as ``has()``.
		<o>n</o>
	**/
	public function contains(val:T):Bool
	{
		return has(val);
	}
	
	/**
		Removes all occurrences of the value `val`.
		<o>n</o>
		@return true if `val` was removed, false if `val` does not exist.
	**/
	public function remove(val:T):Bool
	{
		var found = false;
		var tmp = new Array<K>();
		for (i in 0...capacity)
		{
			if (mKeys[i] != null)
			{
				if (mVals[i] == val)
				{
					tmp.push(mKeys[i]);
					found = true;
				}
			}
		}
		
		if (found)
		{
			for (key in tmp) clr(key);
			return true;
		}
		else
			return false;
	}
	
	/**
		Removes all key/value pairs.
		<o>n</o>
		@param purge if true, nullifies all keys and values and shrinks the hash table to the initial capacity defined in the constructor.
	**/
	public function clear(purge = false)
	{
		mH.clear(purge);
		for (i in 0...capacity) mKeys[i] = null;
		
		if (purge)
		{
			for (i in 0...capacity)
			{
				mVals[i] = cast null;
				mKeys[i] = null;
			}
			
			while (capacity > mMinCapacity) shrink();
		}
		
		for (i in 0...capacity - 1) setNext(i, i + 1);
		setNext(capacity - 1, IntIntHashTable.NULL_POINTER);
		mFree = 0;
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
		<o>1</o>
	**/
	inline public function isEmpty():Bool
	{
		return mH.isEmpty();
	}
	
	/**
		The total number of key/value pairs.
		<o>1</o>
	**/
	inline public function size():Int
	{
		return mH.size();
	}
	
	/**
		Returns an unordered array containing all values in this hash table.
	**/
	public function toArray():Array<T>
	{
		if (isEmpty()) return [];
		
		var out = ArrayUtil.alloc(size());
		var j = 0, keys = mKeys, vals = mVals, k;
		for (i in 0...capacity)
			if (keys.get(i) != null)
				out[j++] = vals.get(i);
		return out;
	}
	
	/**
		Returns a `Vector<T>` object containing all values in this hash table.
	**/
	public function toVector():Container<T>
	{
		var v = NativeArray.init(size());
		var j = 0;
		var keys = mKeys;
		var vals = mVals;
		for (i in 0...capacity)
		{
			if (keys[i] != null)
				v.set(j++, vals[i]);
		}
		return v;
	}
	
	/**
		Duplicates this hash table. Supports shallow (structure only) and deep copies (structure & elements).
		<assert>element is not of type `Cloneable`</assert>
		@param assign if true, the `copier` parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.
		If false, the ``clone()`` method is called on each element. <warn>In this case all elements have to implement `Cloneable`.</warn>
		@param copier a custom function for copying elements. Replaces ``element::clone()`` if `assign` is false.
	**/
	public function clone(assign = true, copier:T->T = null):Collection<T>
	{
		var c = new HashTable<K, T>(M.INT16_MIN);
		c.key = HashKey.next();
		c.mH = cast mH.clone();
		
		var capacity = capacity;
		
		if (assign)
		{
			c.mVals = NativeArray.init(capacity);
			for (i in 0...capacity) c.mVals[i] = mVals[i];
		}
		else
		{
			var tmp = NativeArray.init(capacity);
			if (copier != null)
			{
				for (i in 0...capacity)
				{
					if (mKeys.get(i) != null)
						tmp.set(i, copier(mVals.get(i)));
				}
			}
			else
			{
				var c:Cloneable<T> = null;
				for (i in 0...capacity)
				{
					if (mKeys.get(i) != null)
					{
						assert(Std.is(mVals.get(i), Cloneable), 'element is not of type Cloneable (${mVals.get(i)})');
						
						c = cast mVals.get(i);
						tmp.set(i, c.clone());
					}
				}
			}
			c.mVals = tmp;
		}
		
		c.mFree = mFree;
		
		#if alchemy
		c.mNext = mNext.clone();
		#else
		c.mNext = NativeArray.copy(mNext);
		//c.mNext = NativeArray.init(mNext.length);
		//for (i in 0...Std.int(mNext.length)) c.mNext[i] = mNext[i];
		#end
		c.mKeys = NativeArray.copy(mKeys);
		//c.mKeys = NativeArray.init(capacity);
		//for (i in 0...capacity) c.mKeys[i] = mKeys[i];
		return c;
	}
	
	inline function grow(oldSize:Int)
	{
		var newSize = oldSize << 1;
		
		#if alchemy
		mNext.resize(newSize);
		#else
		var tmp = NativeArray.init(newSize);
		for (i in 0...oldSize) tmp[i] = mNext[i];
		mNext = tmp;
		#end
		
		var tmp = NativeArray.init(newSize);
		for (i in 0...oldSize) tmp[i] = mKeys[i];
		mKeys = tmp;
		
		for (i in oldSize - 1...newSize - 1) setNext(i, i + 1);
		setNext(newSize - 1, IntIntHashTable.NULL_POINTER);
		mFree = oldSize;
		
		var tmp = NativeArray.init(newSize);
		for (i in 0...oldSize) tmp[i] = mVals[i];
		mVals = tmp;
	}
	
	inline function shrink()
	{
		var oldSize = capacity << 1;
		var newSize = capacity;
		
		#if alchemy
		mNext.resize(newSize);
		#else
		mNext = NativeArray.init(newSize);
		#end
		
		for (i in 0...newSize - 1) setNext(i, i + 1);
		setNext(newSize - 1, IntIntHashTable.NULL_POINTER);
		mFree = 0;
		
		var tmpKeys = NativeArray.init(newSize);
		var tmpVals = NativeArray.init(newSize);
		
		for (i in mH)
		{
			tmpKeys[mFree] = mKeys[i];
			tmpVals[mFree] = mVals[i];
			mFree = getNext(mFree);
		}
		
		mKeys = tmpKeys;
		mVals = tmpVals;
		
		for (i in 0...mFree)
			mH.remap(_key(mKeys[i]), i);
	}
	
	inline function getNext(i:Int) return mNext.get(i);
	inline function setNext(i:Int, x:Int) mNext.set(i, x);
	
	inline function _key(x:Hashable)
	{
		assert(x != null, "key is null");
		
		return x.key;
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
	var mKeys:Container<K>;
	var mI:Int;
	var mS:Int;
	
	public function new(x:HashTable<K, T>)
	{
		mObject = x;
		reset();
	}
	
	public function reset():Itr<K>
	{
		mKeys = mObject.mKeys;
		mS = mObject.mH.capacity;
		mI = 0;
		while (mI < mS && mKeys.get(mI) == null) mI++;
		return this;
	}
	
	inline public function hasNext():Bool
	{
		return mI < mS;
	}

	inline public function next():K
	{
		var v = mKeys.get(mI);
		while (++mI < mS && mKeys.get(mI) == null) {}
		return v;
	}
	
	inline public function remove()
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
	var mKeys:Container<K>;
	var mVals:Container<T>;
	var mI:Int;
	var mS:Int;
	
	public function new(x:HashTable<K, T>)
	{
		mObject = x;
		reset();
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
	
	inline public function hasNext():Bool
	{
		return mI < mS;
	}
	
	inline public function next():T
	{
		var v = mVals.get(mI);
		while (++mI < mS && mKeys.get(mI) == null) {}
		return v;
	}
	
	inline public function remove()
	{
		throw "unsupported operation";
	}
}