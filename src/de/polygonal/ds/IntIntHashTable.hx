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

#if (flash && alchemy)
import de.polygonal.ds.tools.mem.IntMemory;
import flash.Memory;
#end

/**
	An array hash table for storing integer key/value pairs
	
	- The hash table can store duplicate keys, and multiple keys can map the same value. If duplicate keys exist, the order is FIFO.
	- The hash table is open: in the case of a "hash collision", a single slot stores multiple entries, which are searched sequentially.
	- The hash table is dynamic: the capacity is automatically increased and decreased.
	- The hash table is never rehashed automatically, because this operation is time-consuming. Instead the user can decide if rehashing is necessary by checking the load factor.
	- The value 0x80000000 is reserved and cannot be associated with a key.
	
	Example:
		var o = new de.polygonal.ds.IntIntHashTable(16);
		for (i in 0...4) o.set(i, i);
		trace(o); //outputs:
		
		[ IntIntHashTable size=4 capacity=16 load=0.25
		   0 -> 0
		   1 -> 1
		   2 -> 2
		   3 -> 3
		]
**/
class IntIntHashTable implements Map<Int, Int>
{
	/**
		Return code for a non-existing key.
	**/
	public static inline var KEY_ABSENT = MathTools.INT32_MIN;
	
	/**
		Return code for a non-existing value.
	**/
	public static inline var VAL_ABSENT = MathTools.INT32_MIN;
	
	/**
		Used internally.
	**/
	public static inline var EMPTY_SLOT = -1;
	
	/**
		Used internally.
	**/
	public static inline var NULL_POINTER = -1;
	
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
	public var growthRate:Int = GrowthRate.DOUBLE;
	
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
		return size / slotCount;
	}
	
	/**
		The total number of allocated slots.
	**/
	public var slotCount(default, null):Int;
	
	#if (flash && alchemy)
	var mHash:IntMemory;
	var mData:IntMemory;
	var mNext:IntMemory;
	#else
	var mHash:NativeArray<Int>;
	var mData:NativeArray<Int>;
	var mNext:NativeArray<Int>;
	#end
	
	var mMask:Int;
	var mFree:Int = 0;
	var mSize:Int = 0;
	var mMinCapacity:Int;
	var mIterator:IntIntHashTableValIterator;
	var mTmpBuffer:NativeArray<Int>;
	var mTmpBufferSize:Int = 16;
	
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
		assert(MathTools.isPow2(slotCount), "slotCount is not a power of 2");
		
		if (initialCapacity == -1)
			initialCapacity = slotCount;
		else
		{
			assert(initialCapacity >= 2, "minimum capacity is 2");
			assert(MathTools.isPow2(slotCount), "capacity is not a power of 2");
		}
		
		capacity = initialCapacity;
		mMinCapacity = initialCapacity;
		this.slotCount = slotCount;
		mMask = slotCount - 1;
		
		#if (flash && alchemy)
		mHash = new IntMemory(slotCount, "IntIntHashTable.mHash");
		mHash.setAll(EMPTY_SLOT);
		mData = new IntMemory(capacity * 3, "IntIntHashTable.mData");
		mNext = new IntMemory(capacity, "IntIntHashTable.mNext");
		#else
		mHash = NativeArrayTools.alloc(slotCount).init(EMPTY_SLOT);
		mData = NativeArrayTools.alloc(capacity * 3);
		mNext = NativeArrayTools.alloc(capacity);
		#end
		
		var j = 2, t = mData;
		for (i in 0...capacity)
		{
			t.set(j - 1, VAL_ABSENT);
			t.set(j, NULL_POINTER);
			j += 3;
		}
		
		t = mNext;
		for (i in 0...capacity - 1) t.set(i, i + 1);
		t.set(capacity - 1, NULL_POINTER);
		
		mTmpBuffer = NativeArrayTools.alloc(mTmpBufferSize);
	}
	
	/**
		Counts the total number of collisions.
		
		A collision occurs when two distinct keys are hashed into the same slot.
	**/
	public function getCollisionCount():Int
	{
		var c = 0, j, d = mData, h = mHash;
		for (i in 0...slotCount)
		{
			j = h.get(i);
			if (j == EMPTY_SLOT) continue;
			j = d.get(j + 2);
			while (j != NULL_POINTER)
			{
				j = d.get(j + 2);
				c++;
			}
		}
		return c;
	}
	
	/**
		Returns the value that is mapped to `key` or `IntIntHashTable.KEY_ABSENT` if `key` does not exist.
		
		Uses move-to-front-on-access which reduces access time when similar keys are frequently queried.
	**/
	public inline function getFront(key:Int):Int
	{
		var b = hashCode(key);
		var i = mHash.get(b);
		if (i == EMPTY_SLOT)
			return KEY_ABSENT;
		else
		{
			var d = mData;
			
			#if (flash && alchemy)
			var o = mData.getAddr(i);
			if (Memory.getI32(o) == key)
				return Memory.getI32(o + 4);
			#else
			if (d.get(i) == key)
				return d.get(i + 1);
			#end
			else
			{
				var v = KEY_ABSENT;
				var first = i, i0 = first;
				
				#if (flash && alchemy)
				i = Memory.getI32(o + 8);
				#else
				i = d.get(i + 2);
				#end
				
				while (i != NULL_POINTER)
				{
					#if (flash && alchemy)
					o = mData.getAddr(i);
					if (Memory.getI32(o) == key)
					#else
					if (d.get(i) == key)
					#end
					{
						#if (flash && alchemy)
						v = Memory.getI32(o + 4);
						
						var o1 = mData.getAddr(i0 + 2);
						Memory.setI32(o1, Memory.getI32(o + 8));
						Memory.setI32(o + 8, first);
						mHash.set(b, i);
						#else
						v = d.get(i + 1);
						d.set(i0 + 2, d.get(i + 2));
						d.set(i + 2, first);
						mHash.set(b, i);
						#end
						break;
					}
					i = d.get((i0 = i) + 2);
				}
				return v;
			}
		}
	}
	
	/**
		Maps `val` to `key` in this map, but only if `key` does not exist yet.
		@return true if `key` was mapped to `val` for the first time.
	**/
	public inline function setIfAbsent(key:Int, val:Int):Bool
	{
		assert(val != KEY_ABSENT, "val 0x80000000 is reserved");
		
		var b = hashCode(key), d = mData;
		
		#if (flash && alchemy)
		var	o = mHash.getAddr(b);
		var j = Memory.getI32(o);
		#else
		var j = mHash.get(b);
		#end
		if (j == EMPTY_SLOT)
		{
			if (size == capacity)
			{
				grow();
				d = mData;
			}
			
			var i = mFree * 3;
			mFree = mNext.get(mFree);
			
			#if (flash && alchemy)
			Memory.setI32(o, i);
			o = mData.getAddr(i);
			Memory.setI32(o    , key);
			Memory.setI32(o + 4, val);
			#else
			mHash.set(b, i);
			d.set(i    , key);
			d.set(i + 1, val);
			#end
			
			mSize++;
			return true;
		}
		else
		{
			#if (flash && alchemy)
			o = mData.getAddr(j);
			if (Memory.getI32(o) == key)
			#else
			if (d.get(j) == key)
			#end
				return false;
			else
			{
				#if (flash && alchemy)
				var t = Memory.getI32(o + 8);
				while (t != NULL_POINTER)
				{
					o = mData.getAddr(t);
					if (Memory.getI32(o) == key)
					{
						j = -1;
						break;
					}
					
					j = t;
					t = Memory.getI32(o + 8);
				}
				#else
				var t = d.get(j + 2);
				while (t != NULL_POINTER)
				{
					if (d.get(t) == key)
					{
						j = -1;
						break;
					}
					
					t = d.get((j = t) + 2);
				}
				#end
				
				if (j == -1)
					return false;
				else
				{
					if (size == capacity)
					{
						grow();
						d = mData;
					}
					
					var i = mFree * 3;
					mFree = mNext.get(mFree);
					
					d.set(j + 2, i);
					
					#if (flash && alchemy)
					o = mData.getAddr(i);
					Memory.setI32(o    , key);
					Memory.setI32(o + 4, val);
					#else
					d.set(i    , key);
					d.set(i + 1, val);
					#end
					
					mSize++;
					return true;
				}
			}
		}
	}
	
	/**
		Redistributes all keys over `slotCount`.
		
		This is an expensive operations as the hash table is rebuild from scratch.
	**/
	public function rehash(slotCount:Int):IntIntHashTable
	{
		assert(MathTools.isPow2(slotCount), "slotCount is not a power of 2");
		
		if (this.slotCount == slotCount) return this;
		
		var t = new IntIntHashTable(slotCount, capacity);
		
		#if (flash && alchemy)
		var o = mData.getAddr(0);
		for (i in 0...capacity)
		{
			var v = Memory.getI32(o + 4);
			if (v != VAL_ABSENT) t.set(Memory.getI32(o), v);
			o += 12;
		}
		#else
		var d = mData;
		for (i in 0...capacity)
		{
			var v = d.get((i * 3) + 1);
			if (v != VAL_ABSENT) t.set(d.get(i * 3), v);
		}
		#end
		
		#if (flash && alchemy)
		mHash.free();
		mData.free();
		mNext.free();
		#end
		mHash = t.mHash;
		mData = t.mData;
		mNext = t.mNext;
		
		this.slotCount = slotCount;
		mMask = t.mMask;
		mFree = t.mFree;
		return this;
	}
	
	/**
		Remaps the first occurrence of `key` to a new value `val`.
		@return true if `val` was successfully remapped to `key`.
	**/
	public inline function remap(key:Int, val:Int):Bool
	{
		var i = mHash.get(hashCode(key));
		if (i == EMPTY_SLOT)
			return false;
		else
		{
			var d = mData;
			
			#if (flash && alchemy)
			var o = d.getAddr(i);
			if (Memory.getI32(o) == key)
			{
				Memory.setI32(o + 4, val);
				return true;
			}
			#else
			if (d.get(i) == key)
			{
				d.set(i + 1, val);
				return true;
			}
			#end
			else
			{
				#if (flash && alchemy)
				i = Memory.getI32(o + 8);
				while (i != NULL_POINTER)
				{
					o = d.getAddr(i);
					if (Memory.getI32(o) == key)
					{
						Memory.setI32(o + 4, val);
						break;
					}
					i = Memory.getI32(o + 8);
				}
				#else
				i = d.get(i + 2);
				while (i != NULL_POINTER)
				{
					if (d.get(i) == key)
					{
						d.set(i + 1, val);
						break;
					}
					i = d.get(i + 2);
				}
				#end
				return i != NULL_POINTER;
			}
		}
	}
	
	/**
		Removes the first occurrence of `key` and returns the value mapped to it.
		@return the value mapped to key or `IntIntHashTable.KEY_ABSENT` if `key` does not exist.
	**/
	public inline function extract(key:Int):Int
	{
		var b = hashCode(key), h = mHash;
		var i = h.get(b);
		if (i == EMPTY_SLOT)
			return IntIntHashTable.KEY_ABSENT;
		else
		{
			var d = mData;
			#if (flash && alchemy)
			var o = d.getAddr(i);
			if (key == Memory.getI32(o))
			{
				var val = Memory.getI32(o + 4);
			#else
			if (key == d.get(i))
			{
				var val = d.get(i + 1);
			#end
				#if (flash && alchemy)
				if (Memory.getI32(o + 8) == NULL_POINTER)
				#else
				if (d.get(i + 2) == NULL_POINTER)
				#end
					h.set(b, EMPTY_SLOT);
				else
					h.set(b, d.get(i + 2));
				
				var j = Std.int(i / 3);
				mNext.set(j, mFree);
				mFree = j;
				
				#if (flash && alchemy)
				Memory.setI32(o + 4, VAL_ABSENT);
				Memory.setI32(o + 8, NULL_POINTER);
				#else
				d.set(i + 1, VAL_ABSENT);
				d.set(i + 2, NULL_POINTER);
				#end
				
				mSize--;
				return val;
			}
			else
			{
				var i0 = i;
				#if (flash && alchemy)
				i = Memory.getI32(o + 8);
				#else
				i = d.get(i + 2);
				#end
				
				var val = IntIntHashTable.KEY_ABSENT;
				
				while (i != NULL_POINTER)
				{
					#if (flash && alchemy)
					o = mData.getAddr(i);
					if (Memory.getI32(o) == key)
					{
						val = Memory.getI32(o + 4);
						break;
					}
					i0 = i;
					i = Memory.getI32(o + 8);
					#else
					if (d.get(i) == key)
					{
						val = d.get(i + 1);
						break;
					}
					i = d.get((i0 = i) + 2);
					#end
				}
				
				if (val != IntIntHashTable.KEY_ABSENT)
				{
					d.set(i0 + 2, d.get(i + 2));
					
					var j = Std.int(i / 3);
					mNext.set(j, mFree);
					mFree = j;
					
					#if (flash && alchemy)
					o = mData.getAddr(i + 1);
					Memory.setI32(o    , VAL_ABSENT);
					Memory.setI32(o + 4, NULL_POINTER);
					#else
					d.set(i + 1, VAL_ABSENT);
					d.set(i + 2, NULL_POINTER);
					#end
					
					mSize--;
					return val;
				}
				else
					return IntIntHashTable.KEY_ABSENT;
			}
		}
	}
	
	/**
		Creates and returns an unordered array of all keys.
	**/
	public function toKeyArray():Array<Int>
	{
		if (isEmpty()) return [];
		
		var out = ArrayTools.alloc(size);
		var j = 0, d = mData;
		for (i in 0...capacity)
		{
			#if (flash && alchemy)
			var o = d.getAddr(i * 3);
			if (Memory.getI32(o + 4) != VAL_ABSENT)
				out[j++] = Memory.getI32(o);
			#else
			if (d.get((i * 3) + 1) != VAL_ABSENT)
				out[j++] = d.get(i * 3);
			#end
		}
		return out;
	}
	
	/**
		Prints out all elements.
	**/
	#if !no_tostring
	public function toString():String
	{
		var b = new StringBuf();
		b.add(Printf.format('[ IntIntHashTable size=$size capacity=$capacity load=%.2f', [loadFactor]));
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
				args[1] = get(key);
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
	public function has(val:Int):Bool
	{
		assert(val != VAL_ABSENT, "val 0x80000000 is reserved");
		
		var exists = false, d = mData;
		for (i in 0...capacity)
		{
			var v = d.get((i * 3) + 1);
			if (v == val)
			{
				exists = true;
				break;
			}
		}
		return exists;
	}
	
	/**
		Returns true if this map contains `key`.
	**/
	public inline function hasKey(key:Int):Bool
	{
		var i = mHash.get(hashCode(key));
		if (i == EMPTY_SLOT)
			return false;
		else
		{
			var d = mData;
			
			#if (flash && alchemy)
			var o = d.getAddr(i);
			if (Memory.getI32(o) == key)
				return true;
			#else
			if (d.get(i) == key)
				return true;
			#end
			else
			{
				var exists = false;
				#if (flash && alchemy)
				i = Memory.getI32(o + 8);
				while (i != NULL_POINTER)
				{
					o = mData.getAddr(i);
					if (Memory.getI32(o) == key)
					{
						exists = true;
						break;
					}
					i = Memory.getI32(o + 8);
				}
				#else
				i = d.get(i + 2);
				while (i != NULL_POINTER)
				{
					if (d.get(i) == key)
					{
						exists = true;
						break;
					}
					i = d.get(i + 2);
				}
				#end
				return exists;
			}
		}
	}
	
	/**
		Counts the number of mappings for `key`.
	**/
	public function count(key:Int):Int
	{
		var c = 0;
		var i = mHash.get(hashCode(key));
		if (i == EMPTY_SLOT)
			return c;
		else
		{
			var d = mData;
			
			#if (flash && alchemy)
			while (i != NULL_POINTER)
			{
				var o = d.getAddr(i);
				if (Memory.getI32(o) == key) c++;
				i = Memory.getI32(o + 8);
			}
			#else
			while (i != NULL_POINTER)
			{
				if (d.get(i) == key) c++;
				i = d.get(i + 2);
			}
			#end
			return c;
		}
	}
	
	/**
		Returns the first value that is mapped to `key` or `IntIntHashTable.KEY_ABSENT` if `key` does not exist.
	**/
	public inline function get(key:Int):Int
	{
		var i = mHash.get(hashCode(key));
		if (i == EMPTY_SLOT)
			return KEY_ABSENT;
		else
		{
			var d = mData;
			#if (flash && alchemy)
			var o = d.getAddr(i);
			if (Memory.getI32(o) == key)
				return Memory.getI32(o + 4);
			#else
			if (d.get(i) == key)
				return d.get(i + 1);
			#end
			else
			{
				var v = KEY_ABSENT;
				#if (flash && alchemy)
				i = Memory.getI32(o + 8);
				while (i != NULL_POINTER)
				{
					o = d.getAddr(i);
					if (Memory.getI32(o) == key)
					{
						v = Memory.getI32(o + 4);
						break;
					}
					i = Memory.getI32(o + 8);
				}
				#else
				i = d.get(i + 2);
				while (i != NULL_POINTER)
				{
					if (d.get(i) == key)
					{
						v = d.get(i + 1);
						break;
					}
					i = d.get(i + 2);
				}
				#end
				return v;
			}
		}
	}
	
	/**
		Stores all values that are mapped to `key` in `out` or returns 0 if `key` does not exist.
		@return the total number of values mapped to `key`.
	**/
	public function getAll(key:Int, out:Array<Int>):Int
	{
		var i = mHash.get(hashCode(key));
		if (i == EMPTY_SLOT)
			return 0;
		else
		{
			var c = 0;
			var d = mData;
			#if (flash && alchemy)
			var o = d.getAddr(i);
			if (Memory.getI32(o) == key)
				out[c++] = Memory.getI32(o + 4);
			i = Memory.getI32(o + 8);
			while (i != NULL_POINTER)
			{
				o = d.getAddr(i);
				if (Memory.getI32(o) == key)
					out[c++] = Memory.getI32(o + 4);
				i = Memory.getI32(o + 8);
			}
			#else
			if (d.get(i) == key)
				out[c++] = d.get(i + 1);
			i = d.get(i + 2);
			while (i != NULL_POINTER)
			{
				if (d.get(i) == key)
					out[c++] = d.get(i + 1);
				i = d.get(i + 2);
			}
			#end
			return c;
		}
	}
	
	/**
		Returns true if this map contains a mapping from `key` to `val`.
	**/
	public function hasPair(key:Int, val:Int):Bool
	{
		assert(val != KEY_ABSENT, "val 0x80000000 is reserved");
		
		var i = mHash.get(hashCode(key));
		if (i == EMPTY_SLOT)
			return false;
		else
		{
			var d = mData;
			
			#if (flash && alchemy)
			var o = d.getAddr(i);
			if (Memory.getI32(o) == key)
				if (Memory.getI32(o + 4) == val)
					return true;
			
			i = Memory.getI32(o + 8);
			while (i != NULL_POINTER)
			{
				o = d.getAddr(i);
				if (Memory.getI32(o) == key)
					if (Memory.getI32(o + 4) == val)
						return true;
				i = Memory.getI32(o + 8);
			}
			#else
			if (d.get(i) == key)
				if (d.get(i + 1) == val)
					return true;
			
			i = d.get(i + 2);
			while (i != NULL_POINTER)
			{
				if (d.get(i) == key)
					if (d.get(i + 1) == val)
						return true;
				i = d.get(i + 2);
			}
			#end
			return false;
		}
	}
	
	/**
		Removes the first mapping from `key` to `val`.
		@return true if `key` is successfully removed.
	**/
	public function unsetPair(key:Int, val:Int):Bool
	{
		assert(val != KEY_ABSENT, "val 0x80000000 is reserved");
		
		var b = hashCode(key), h = mHash;
		var i = h.get(b);
		if (i == EMPTY_SLOT)
			return false;
		else
		{
			var d = mData;
			#if (flash && alchemy)
			var o = mData.getAddr(i);
			if (key == Memory.getI32(o) && val == Memory.getI32(o + 4))
			#else
			if (key == d.get(i) && val == d.get(i + 1))
			#end
			{
				#if (flash && alchemy)
				if (Memory.getI32(o + 8) == NULL_POINTER)
				#else
				if (d.get(i + 2) == NULL_POINTER)
				#end
					h.set(b, EMPTY_SLOT);
				else
					h.set(b, d.get(i + 2));
				
				var j = Std.int(i / 3);
				mNext.set(j, mFree);
				mFree = j;
				
				#if (flash && alchemy)
				Memory.setI32(o + 4, VAL_ABSENT);
				Memory.setI32(o + 8, NULL_POINTER);
				#else
				d.set(i + 1, VAL_ABSENT);
				d.set(i + 2, NULL_POINTER);
				#end
				
				mSize--;
				return true;
			}
			else
			{
				var exists = false;
				
				var i0 = i;
				#if (flash && alchemy)
				i = Memory.getI32(o + 8);
				#else
				i = d.get(i + 2);
				#end
				
				while (i != NULL_POINTER)
				{
					#if (flash && alchemy)
					o = mData.getAddr(i);
					if (Memory.getI32(o) == key && Memory.getI32(o + 4) == val)
					{
						exists = true;
						break;
					}
					i0 = i;
					i = Memory.getI32(o + 8);
					#else
					if (d.get(i) == key && d.get(i + 1) == val)
					{
						exists = true;
						break;
					}
					i = d.get((i0 = i) + 2);
					#end
				}
				
				if (exists)
				{
					d.set(i0 + 2, d.get(i + 2));
					
					var j = Std.int(i / 3);
					mNext.set(j, mFree);
					mFree = j;
					
					#if (flash && alchemy)
					o = mData.getAddr(i + 1);
					Memory.setI32(o    , VAL_ABSENT);
					Memory.setI32(o + 4, NULL_POINTER);
					#else
					d.set(i + 1, VAL_ABSENT);
					d.set(i + 2, NULL_POINTER);
					#end
					
					--mSize;
					return true;
				}
				else
					return false;
			}
		}
	}
	
	/**
		Maps the value `val` to `key`.
		
		The method allows duplicate keys.
		<br/>To ensure unique keys either use `this.hasKey()` before `this.set()` or `this.setIfAbsent()`.
		@return true if `key` was added for the first time, false if another instance of `key` was inserted.
	**/
	public inline function set(key:Int, val:Int):Bool
	{
		assert(val != KEY_ABSENT, "val 0x80000000 is reserved");
		
		if (size == capacity) grow();
		
		var d = mData, h = mHash;
		var i = mFree * 3;
		mFree = mNext.get(mFree);
		
		#if (flash && alchemy)
		var o = d.getAddr(i);
		Memory.setI32(o    , key);
		Memory.setI32(o + 4, val);
		#else
		d.set(i    , key);
		d.set(i + 1, val);
		#end
		
		var b = hashCode(key);
		
		#if (flash && alchemy)
		o = h.getAddr(b);
		var j = Memory.getI32(o);
		if (j == EMPTY_SLOT)
		{
			Memory.setI32(o, i);
			mSize++;
			return true;
		}
		#else
		var j = h.get(b);
		if (j == EMPTY_SLOT)
		{
			h.set(b, i);
			mSize++;
			return true;
		}
		#end
		else
		{
			#if (flash && alchemy)
			o = mData.getAddr(j);
			var first = flash.Memory.getI32(o) != key;
			var t = flash.Memory.getI32(o + 8);
			#else
			var first = d.get(j) != key;
			var t = d.get(j + 2);
			#end
			
			while (t != NULL_POINTER)
			{
				#if (flash && alchemy)
				o = mData.getAddr(t);
				if (flash.Memory.getI32(o) == key) first = false;
				j = t;
				t = flash.Memory.getI32(o + 8);
				#else
				if (d.get(t) == key) first = false;
				j = t;
				t = d.get(t + 2);
				#end
			}
			
			#if (flash && alchemy)
			flash.Memory.setI32(o + 8, i);
			#else
			d.set(j + 2, i);
			#end
			
			mSize++;
			return first;
		}
	}
	
	/**
		Removes the first occurrence of `key`.
		@return true if `key` is successfully removed.
	**/
	public inline function unset(key:Int):Bool
	{
		var b = hashCode(key), h = mHash;
		var i = h.get(b);
		if (i == EMPTY_SLOT)
			return false;
		else
		{
			var d = mData;
			
			#if (flash && alchemy)
			var o = d.getAddr(i);
			if (key == Memory.getI32(o))
			#else
			if (key == d.get(i))
			#end
			{
				#if (flash && alchemy)
				if (Memory.getI32(o + 8) == NULL_POINTER)
				#else
				if (d.get(i + 2) == NULL_POINTER)
				#end
					h.set(b, EMPTY_SLOT);
				else
					h.set(b, d.get(i + 2));
				
				var j = Std.int(i / 3);
				mNext.set(j, mFree);
				mFree = j;
				
				#if (flash && alchemy)
				Memory.setI32(o + 4, VAL_ABSENT);
				Memory.setI32(o + 8, NULL_POINTER);
				#else
				d.set(i + 1, VAL_ABSENT);
				d.set(i + 2, NULL_POINTER);
				#end
				
				mSize--;
				return true;
			}
			else
			{
				var exists = false;
				
				var i0 = i;
				#if (flash && alchemy)
				i = Memory.getI32(o + 8);
				#else
				i = d.get(i + 2);
				#end
				
				while (i != NULL_POINTER)
				{
					#if (flash && alchemy)
					o = d.getAddr(i);
					if (Memory.getI32(o) == key)
					{
						exists = true;
						break;
					}
					i0 = i;
					i = Memory.getI32(o + 8);
					#else
					if (d.get(i) == key)
					{
						exists = true;
						break;
					}
					i = d.get((i0 = i) + 2);
					#end
				}
				
				if (exists)
				{
					d.set(i0 + 2, d.get(i + 2));
					
					var j = Std.int(i / 3);
					mNext.set(j, mFree);
					mFree = j;
					
					#if (flash && alchemy)
					o = d.getAddr(i + 1);
					Memory.setI32(o    , VAL_ABSENT);
					Memory.setI32(o + 4, NULL_POINTER);
					#else
					d.set(i + 1, VAL_ABSENT);
					d.set(i + 2, NULL_POINTER);
					#end
					
					mSize--;
					return true;
				}
				else
					return false;
			}
		}
	}
	
	/**
		Creates an `IntHashSet` object of the values in this map.
	**/
	public function toValSet():Set<Int>
	{
		var s = new IntHashSet(capacity), d = mData;
		for (i in 0...capacity)
		{
			var v = d.get((i * 3) + 1);
			if (v != VAL_ABSENT) s.set(v);
		}
		return s;
	}
	
	/**
		Creates an `IntHashSet` object of the keys in this map.
	**/
	public function toKeySet():Set<Int>
	{
		var s = new IntHashSet(capacity), d = mData;
		for (i in 0...capacity)
		{
			var v = d.get((i * 3) + 1);
			if (v != VAL_ABSENT)
			{
				s.set(d.get(i * 3));
			}
		}
		return s;
	}
	
	/**
		Returns a new *IntIntHashTableKeyIterator* object to iterate over all keys stored in this map.
		
		The keys are visited in a random order.
		
		@see http://haxe.org/ref/iterators
	**/
	public function keys():Itr<Int>
	{
		return new IntIntHashTableKeyIterator(this);
	}
	
	/**
		Free up resources by reducing the capacity of the internal container to the initial capacity.
	**/
	public function pack():IntIntHashTable
	{
		if (capacity == mMinCapacity) return this;
		
		capacity = MathTools.max(size, mMinCapacity);
		
		var src = mData, dst;
		var e = 0, t = mHash;
		
		#if (flash && alchemy)
		dst = new IntMemory(capacity * 3, "IntIntHashTable.mData");
		#else
		dst = NativeArrayTools.alloc(capacity * 3);
		#end
		
		var j = 2;
		for (i in 0...capacity)
		{
			dst.set(j - 1, VAL_ABSENT);
			dst.set(j, NULL_POINTER);
			j += 3;
		}
		
		#if (flash && alchemy)
		var addr = dst.getAddr(e);
		for (i in 0...slotCount)
		{
			j = t.get(i);
			if (j == EMPTY_SLOT) continue;
			
			t.set(i, e);
			
			flash.Memory.setI32(addr    , src.get(j));
			flash.Memory.setI32(addr + 4, src.get(j + 1));
			flash.Memory.setI32(addr + 8, NULL_POINTER);
			addr += 12;
			e += 3;
			
			j = src.get(j + 2);
			while (j != NULL_POINTER)
			{
				flash.Memory.setI32(addr - 4, e);
				flash.Memory.setI32(addr    , src.get(j));
				flash.Memory.setI32(addr + 4, src.get(j + 1));
				flash.Memory.setI32(addr + 8, NULL_POINTER);
				addr += 12;
				e += 3;
				j = src.get(j + 2);
			}
		}
		mData.free();
		mData = dst;
		mNext.resize(capacity);
		#else
		for (i in 0...slotCount)
		{
			j = t.get(i);
			if (j == EMPTY_SLOT) continue;
			
			t.set(i, e);
			dst.set(e    , src.get(j));
			dst.set(e + 1, src.get(j + 1));
			dst.set(e + 2, NULL_POINTER);
			
			e += 3;
			j = src.get(j + 2);
			while (j != NULL_POINTER)
			{
				dst.set(e - 1, e);
				dst.set(e    , src.get(j));
				dst.set(e + 1, src.get(j + 1));
				dst.set(e + 2, NULL_POINTER);
				e += 3;
				j = src.get(j + 2);
			}
		}
		mData = dst;
		mNext = NativeArrayTools.alloc(capacity);
		#end
		
		var n = mNext;
		for (i in 0...capacity - 1) n.set(i, i + 1);
		n.set(capacity - 1, NULL_POINTER);
		mFree = -1;
		return this;
	}
	
	/**
		Calls `f` on all {Int,Int} pairs in random order.
	**/
	public inline function iter(f:Int->Int->Void):IntIntHashTable
	{
		assert(f != null);
		var d = mData, j, v;
		for (i in 0...capacity)
		{
			j = i * 3;
			v = d.get(j + 1);
			if (v != VAL_ABSENT) f(d.get(j), v);
		}
		return this;
	}
	
	inline function hashCode(x:Int):Int
	{
		return (x * 73856093) & mMask;
	}
	
	function grow()
	{
		var oldCapacity = capacity;
		capacity = GrowthRate.compute(growthRate, capacity);
		
		var t;
		
		#if alchemy
		mNext.resize(capacity);
		mData.resize(capacity * 3);
		#else
		t = NativeArrayTools.alloc(capacity);
		mNext.blit(0, t, 0, oldCapacity);
		mNext = t;
		t = NativeArrayTools.alloc(capacity * 3);
		mData.blit(0, t, 0, oldCapacity * 3);
		mData = t;
		#end
		
		t = mNext;
		for (i in oldCapacity - 1...capacity - 1) t.set(i, i + 1);
		t.set(capacity - 1, NULL_POINTER);
		mFree = oldCapacity;
		
		var j = oldCapacity * 3 + 2;
		t = mData;
		for (i in 0...capacity - oldCapacity)
		{
			#if (flash && alchemy)
			var o = t.getAddr(j - 1);
			Memory.setI32(o    , VAL_ABSENT);
			Memory.setI32(o + 4, NULL_POINTER);
			#else
			t.set(j - 1, VAL_ABSENT);
			t.set(j    , NULL_POINTER);
			#end
			j += 3;
		}
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
		#if (flash && alchemy)
		mHash.free();
		mData.free();
		mNext.free();
		#end
		
		mHash = null;
		mData = null;
		mNext = null;
		if (mIterator != null)
		{
			mIterator.free();
			mIterator = null;
		}
		mTmpBuffer = null;
	}
	
	/**
		Same as `this.has()`.
	**/
	public inline function contains(val:Int):Bool
	{
		return has(val);
	}
	
	/**
		Removes all occurrences of the value `val`.
		@return true if `val` was removed, false if `val` does not exist.
	**/
	public function remove(val:Int):Bool
	{
		assert(val != KEY_ABSENT, "val 0x80000000 is reserved");
		
		var c = 0;
		var keys = mTmpBuffer;
		var max = mTmpBufferSize;
		var d = mData, j;
		
		#if (flash && alchemy)
		j = d.getAddr(1);
		for (i in 0...capacity)
		{
			if (Memory.getI32(j) == val)
			{
				if (c == max)
				{
					max <<= 1;
					mTmpBufferSize = max;
					var t = NativeArrayTools.alloc(max);
					mTmpBuffer.blit(0, t, 0, c);
					mTmpBuffer = keys = t;
				}
				
				keys.set(c++, Memory.getI32(j - 4));
			}
			j += 12;
		}
		#else
		for (i in 0...capacity)
		{
			j = i * 3;
			if (d.get(j + 1) == val)
			{
				if (c == max)
				{
					max <<= 1;
					mTmpBufferSize = max;
					var t = NativeArrayTools.alloc(max);
					mTmpBuffer.blit(0, t, 0, c);
					mTmpBuffer = keys = t;
				}
				
				keys.set(c++, d.get(j));
			}
		}
		#end
		
		for (i in 0...c) unset(keys.get(i));
		return c > 0;
	}
	
	/**
		Removes all key/value pairs.
		
		The `gc` parameter has no effect.
	**/
	public function clear(gc:Bool = false)
	{
		#if (flash && alchemy)
		mHash.setAll(EMPTY_SLOT);
		#else
		var h = mHash;
		for (i in 0...slotCount) h.set(i, EMPTY_SLOT);
		#end
		
		var j = 2, t = mData;
		for (i in 0...capacity)
		{
			t.set(j - 1, VAL_ABSENT);
			t.set(j    , NULL_POINTER);
			j += 3;
		}
		
		t = mNext;
		for (i in 0...capacity - 1) t.set(i, i + 1);
		t.set(capacity - 1, NULL_POINTER);
		
		mFree = 0;
		mSize = 0;
	}
	
	/**
		Returns a new *IntIntHashTableValIterator* object to iterate over all values contained in this hash table.
		
		The values are visited in a random order.
		
		@see http://haxe.org/ref/iterators
	**/
	public function iterator():Itr<Int>
	{
		if (reuseIterator)
		{
			if (mIterator == null)
				mIterator = new IntIntHashTableValIterator(this);
			else
				mIterator.reset();
			return mIterator;
		}
		else
			return new IntIntHashTableValIterator(this);
	}
	
	/**
		Returns true only if `this.size` is 0.
	**/
	public inline function isEmpty():Bool
	{
		return size == 0;
	}
	
	/**
		Returns an unordered array containing all values in this hash table.
	**/
	public function toArray():Array<Int>
	{
		if (isEmpty()) return [];
		
		var out = ArrayTools.alloc(size);
		var j = 0, v, d = mData;
		for (i in 0...capacity)
		{
			v = d.get((i * 3) + 1);
			if (v != VAL_ABSENT) out[j++] = v;
		}
		return out;
	}
	
	/**
		Duplicates this hash set by creating a deep copy (`byRef` and `copier` are ignored).
	**/
	public function clone(byRef:Bool = true, copier:Int->Int = null):Collection<Int>
	{
		var c = new IntIntHashTable(slotCount, capacity);
		
		#if (flash && alchemy)
		IntMemory.blit(mHash, 0, c.mHash, 0, slotCount);
		IntMemory.blit(mData, 0, c.mData, 0, capacity * 3);
		IntMemory.blit(mNext, 0, c.mNext, 0, capacity);
		#else
		mHash.blit(0, c.mHash, 0, slotCount);
		mData.blit(0, c.mData, 0, capacity * 3);
		mNext.blit(0, c.mNext, 0, capacity);
		#end
		
		c.mMask = mMask;
		c.slotCount = slotCount;
		c.capacity = capacity;
		c.mFree = mFree;
		c.mSize = size;
		return c;
	}
}

@:access(de.polygonal.ds.IntIntHashTable)
@:dox(hide)
class IntIntHashTableValIterator implements de.polygonal.ds.Itr<Int>
{
	var mObject:IntIntHashTable;
	var mI:Int;
	var mS:Int;
	#if (flash && alchemy)
	var mData:IntMemory;
	#else
	var mData:NativeArray<Int>;
	#end
	
	public function new(x:IntIntHashTable)
	{
		mObject = x;
		mData = x.mData;
		mI = 0;
		mS = x.capacity;
		scan();
	}
	
	public function free()
	{
		mObject = null;
		mData = null;
	}
	
	public function reset():Itr<Int>
	{
		mData = mObject.mData;
		mI = 0;
		mS = mObject.capacity;
		scan();
		return this;
	}
	
	public inline function hasNext():Bool
	{
		return mI < mS;
	}
	
	public inline function next():Int
	{
		var val = mData.get((mI++ * 3) + 1);
		scan();
		return val;
	}
	
	public function remove()
	{
		throw "unsupported operation";
	}
	
	function scan()
	{
		while ((mI < mS) && (mData.get((mI * 3) + 1) == IntIntHashTable.VAL_ABSENT)) mI++;
	}
}

@:access(de.polygonal.ds.IntIntHashTable)
@:dox(hide)
class IntIntHashTableKeyIterator implements de.polygonal.ds.Itr<Int>
{
	var mObject:IntIntHashTable;
	var mI:Int;
	var mS:Int;
	
	#if (flash && alchemy)
	var mData:IntMemory;
	#else
	var mData:NativeArray<Int>;
	#end
	
	public function new(x:IntIntHashTable)
	{
		mObject = x;
		mData = x.mData;
		mI = 0;
		mS = x.capacity;
		scan();
	}
	
	public function free()
	{
		mObject = null;
		mData = null;
	}
	
	public function reset():Itr<Int>
	{
		mData = mObject.mData;
		mI = 0;
		mS = mObject.capacity;
		scan();
		return this;
	}
	
	public inline function hasNext():Bool
	{
		return mI < mS;
	}
	
	public inline function next():Int
	{
		var key = mData.get((mI++ * 3));
		scan();
		return key;
	}
	
	public function remove()
	{
		throw "unsupported operation";
	}
	
	function scan()
	{
		while ((mI < mS) && (mData.get((mI * 3) + 1) == IntIntHashTable.VAL_ABSENT)) mI++;
	}
}