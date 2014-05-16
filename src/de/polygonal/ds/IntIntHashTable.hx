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

#if (flash && alchemy)
import de.polygonal.ds.mem.IntMemory;
import flash.Memory;
#end

/**
 * <p>An array hash table for storing integer key/value pairs.</p>
 * <ul>
 * <li>The hash table can store duplicate keys, and multiple keys can map the same value. If duplicate keys exist, the order is FIFO.</li>
 * <li>The hash table is open: in the case of a "hash collision", a single slot stores multiple entries, which are searched sequentially.</li>
 * <li>The hash table is dynamic: the <em>capacity</em> is automatically increased and decreased.</li>
 * <li>The hash table is never rehashed automatically, because this operation is time-consuming. Instead the user can decide if rehashing is necessary by checking the load factor.
 * It's recommended to initialize big hash tables upfront with a large slot count which allows the entries to be inserted more efficiently.</li>
 * <li>The value 0x80000000 is reserved and cannot be associated with a key.</li>
 * </ul>
 * <p><o>Amortized running time in Big O notation</o></p>
 */
class IntIntHashTable implements Map<Int, Int>
{
	/**
	 * Return code for a non-existing key.
	 */
	inline public static var KEY_ABSENT = M.INT32_MIN;
	
	/**
	 * Return code for a non-existing value.
	 */
	inline public static var VAL_ABSENT = M.INT32_MIN;
	
	/**
	 * Used internally.
	 */
	inline public static var EMPTY_SLOT = -1;
	
	/**
	 * Used internally.
	 */
	inline public static var NULL_POINTER = -1;
	
	/**
	 * A unique identifier for this object.<br/>
	 * A hash table transforms this key into an index of an array element by using a hash function.<br/>
	 * <warn>This value should never be changed by the user.</warn>
	 */
	public var key:Int;
	
	/**
	 * The maximum allowed size of this hash table.<br/>
	 * Once the maximum size is reached, adding an element will fail with an error (debug only).<br/>
	 * A value of -1 indicates that the size is unbound.<br/>
	 * <warn>Always equals -1 in release mode.</warn>
	 */
	public var maxSize:Int;
	
	/**
	 * If true, reuses the iterator object instead of allocating a new one when calling <code>iterator()</code>.<br/>
	 * The default is false.<br/>
	 * <warn>If true, nested iterations are likely to fail as only one iteration is allowed at a time.</warn>
	 */
	public var reuseIterator:Bool;
	
	var mIsResizable:Bool;
	
	#if alchemy
	var mHash:IntMemory;
	var mData:IntMemory;
	var mNext:IntMemory;
	#else
	var mHash:Vector<Int>;
	var mData:Vector<Int>;
	var mNext:Vector<Int>;
	#end
	
	var mMask:Int;
	var mFree:Int;
	
	var mCapacity:Int;
	var mSize:Int;
	var mSizeLevel:Int;
	var mIterator:IntIntHashTableValIterator;
	
	/**
	 * @param slotCount the total number of slots into which the hashed keys are distributed.
	 * This defines the space-time trade off of the hash table.
	 * Increasing the <code>slotCount</code> reduces the computation time (read/write/access) of the hash table at the cost of increased memory use.
	 * This value is fixed and can only be changed by calling <em>rehash()</em>, which rebuilds the hash table (expensive).
	 *
	 * @param capacity the initial physical space for storing the key/value pairs at the time the hash table is created.
	 * This is also the minimum allowed size of the hash table and cannot be changed in the future. If omitted, the initial <em>capacity</em> equals <code>slotCount</code>.
	 * The <em>capacity</em> is automatically adjusted according to the storage requirements based on two rules:
	 * <ol>
	 * <li>If the hash table runs out of space, the <em>capacity</em> is doubled (if <code>isResizable</code> is true).</li>
	 * <li>If the size falls below a quarter of the current <em>capacity</em>, the <em>capacity</em> is cut in half while the minimum <em>capacity</em> can't fall below <code>capacity</code>.</li>
	 * </ol>
	 *
	 * @param isResizable if false, the hash table is treated as fixed size table.
	 * Thus adding a value when <em>size()</em> equals <em>capacity</em> throws an error.
	 * Otherwise the <em>capacity</em> is automatically adjusted.
	 * Default is true.
	 *
	 * @param maxSize the maximum allowed size of the stack.
	 * The default value of -1 indicates that there is no upper limit.
	 *
	 * @throws de.polygonal.ds.error.AssertError <code>slotCount</code> is not a power of two (debug only).
	 * @throws de.polygonal.ds.error.AssertError <code>capacity</code> is not a power of two (debug only).
	 * @throws de.polygonal.ds.error.AssertError <code>capacity</code> is &lt; 2 (debug only).
	 */
	public function new(slotCount:Int, capacity = -1, isResizable = true, maxSize = -1)
	{
		if (slotCount == M.INT16_MIN) return;
		assert(slotCount > 0);
		
		#if debug
		assert(M.isPow2(slotCount), "slotCount is not a power of 2");
		#end
		
		if (capacity == -1)
			capacity = slotCount;
		else
		{
			#if debug
			assert(capacity >= 2, "minimum capacity is 2");
			assert(M.isPow2(slotCount), "capacity is not a power of 2");
			#end
		}
		
		mIsResizable = isResizable;
		mFree = 0;
		mCapacity = capacity;
		mSize = 0;
		mMask = slotCount - 1;
		mSizeLevel = 0;
		mIterator = null;
		
		#if debug
		this.maxSize = (maxSize == -1) ? M.INT32_MAX : maxSize;
		#else
		this.maxSize = -1;
		#end
		
		#if alchemy
		mHash = new IntMemory(slotCount, "IntIntHashTable.mHash");
		mHash.fill(EMPTY_SLOT);
		mData = new IntMemory(mCapacity * 3, "IntIntHashTable.mData");
		mNext = new IntMemory(mCapacity, "IntIntHashTable.mNext");
		#else
		mHash = new Vector<Int>(slotCount);
		for (i in 0...slotCount) mHash[i] = EMPTY_SLOT;
		mData = new Vector<Int>(mCapacity * 3);
		mNext = new Vector<Int>(mCapacity);
		#end
		
		var j = 2;
		for (i in 0...capacity)
		{
			setData(j - 1, VAL_ABSENT);
			setData(j, NULL_POINTER);
			j += 3;
		}
		
		for (i in 0...mCapacity - 1) setNext(i, i + 1);
		setNext(mCapacity - 1, NULL_POINTER);
		
		key = HashKey.next();
		reuseIterator = false;
	}
	
	/**
	 * The load factor measure the "denseness" of a hash table and is proportional to the time cost to look up an entry.<br/>
	 * E.g. assuming that the keys are perfectly distributed, a load factor of 4.0 indicates that each slot stores 4 keys, which have to be sequentially searched in order to find a value.<br/>
	 * A high load factor thus indicates poor performance.
	 * If the load factor gets too high, additional slots can be allocated by calling <em>rehash()</em>.
	 */
	inline public function getLoadFactor():Float
	{
		return size() / getSlotCount();
	}
	
	/**
	 * The total number of allocated slots.
	 */
	inline public function getSlotCount():Int
	{
		return mMask + 1;
	}
	
	/**
	 * The size of the allocated storage space for the key/value pairs.<br/>
	 * If more space is required to accomodate new elements, the <em>capacity</em> is doubled every time <em>size()</em> grows beyond <em>capacity</em>, and split in half when <em>size()</em> is a quarter of <em>capacity</em>.
	 * The <em>capacity</em> never falls below the initial size defined in the constructor.
	 */
	inline public function getCapacity():Int
	{
		return mCapacity;
	}
	
	/**
	 * Counts the total number of collisions.<br/>
	 * A collision occurs when two distinct keys are hashed into the same slot.
	 * <o>n</o>
	 */
	public function getCollisionCount():Int
	{
		var c = 0, j;
		for (i in 0...getSlotCount())
		{
			j = getHash(i);
			if (j == EMPTY_SLOT) continue;
			j = getData(j + 2);
			while (j != NULL_POINTER)
			{
				j = getData(j + 2);
				c++;
			}
		}
		return c;
	}
	
	/**
	 * Returns the value that is mapped to <code>key</code> or <em>IntIntHashTable.KEY_ABSENT</em> if <code>key</code> does not exist.<br/>
	 * Uses move-to-front-on-access which reduces access time when similar keys are frequently queried.
	 * <o>1</o>
	 */
	inline public function getFront(key:Int):Int
	{
		var b = hashCode(key);
		var i = getHash(b);
		if (i == EMPTY_SLOT)
			return KEY_ABSENT;
		else
		{
			#if (flash && alchemy)
			var o = mData.getAddr(i);
			if (Memory.getI32(o) == key)
				return Memory.getI32(o + 4);
			#else
			if (getData(i) == key)
				return getData(i + 1);
			#end
			else
			{
				var v = KEY_ABSENT;
				
				var first = i, i0 = first;
				
				#if (flash && alchemy)
				i = Memory.getI32(o + 8);
				#else
				i = getData(i + 2);
				#end
				
				while (i != NULL_POINTER)
				{
					#if (flash && alchemy)
					o = mData.getAddr(i);
					if (Memory.getI32(o) == key)
					#else
					if (getData(i) == key)
					#end
					{
						#if (flash && alchemy)
						v = Memory.getI32(o + 4);
						
						var o1 = mData.getAddr(i0 + 2);
						Memory.setI32(o1, Memory.getI32(o + 8));
						Memory.setI32(o + 8, first);
						
						setHash(b, i);
						#else
						v = getData(i + 1);
						setData(i0 + 2, getData(i + 2));
						setData(i + 2, first);
						setHash(b, i);
						#end
						break;
					}
					i = getData((i0 = i) + 2);
				}
				return v;
			}
		}
	}
	
	/**
	 * Maps <code>val</code> to <code>key</code> in this map, but only if <code>key</code> does not exist yet.<br/>
	 * <o>1</o>
	 * @return true if <code>key</code> was mapped to <code>val</code> for the first time.
	 * @throws de.polygonal.ds.error.AssertError out of space - hash table is full but not resizable.
	 * @throws de.polygonal.ds.error.AssertError <em>size()</em> equals <em>maxSize</em> (debug only).
	 */
	inline public function setIfAbsent(key:Int, val:Int):Bool
	{
		#if debug
		assert(val != KEY_ABSENT, "val 0x80000000 is reserved");
		#end
		
		var b = hashCode(key);
		
		#if (flash && alchemy)
		var	o = mHash.getAddr(b);
		var j = Memory.getI32(o);
		#else
		var j = getHash(b);
		#end
		if (j == EMPTY_SLOT)
		{
			#if debug
			assert(size() < maxSize, 'size equals max size ($maxSize)');
			#end
			
			if (mSize == mCapacity)
			{
				#if debug
				if (!mIsResizable)
					assert(false, 'out of space (${getCapacity()})');
				#end
				
				if (mIsResizable)
					expand();
			}
			
			var i = mFree * 3;
			mFree = getNext(mFree);
			
			#if (flash && alchemy)
			Memory.setI32(o, i);
			o = mData.getAddr(i);
			Memory.setI32(o    , key);
			Memory.setI32(o + 4, val);
			#else
			setHash(b, i);
			setData(i    , key);
			setData(i + 1, val);
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
			if (getData(j) == key)
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
				var t = getData(j + 2);
				while (t != NULL_POINTER)
				{
					if (getData(t) == key)
					{
						j = -1;
						break;
					}
					
					t = getData((j = t) + 2);
				}
				#end
				
				if (j == -1)
					return false;
				else
				{
					if (mSize == mCapacity)
					{
						#if debug
						if (!mIsResizable)
							assert(false, 'out of space (${getCapacity()})');
						#end
						
						if (mIsResizable)
							expand();
					}
					
					var i = mFree * 3;
					mFree = getNext(mFree);
					
					setData(j + 2, i);
					
					#if (flash && alchemy)
					o = mData.getAddr(i);
					Memory.setI32(o    , key);
					Memory.setI32(o + 4, val);
					#else
					setData(i    , key);
					setData(i + 1, val);
					#end
					
					mSize++;
					return true;
				}
			}
		}
	}
	
	/**
	 * Redistributes all keys over <code>slotCount</code>.<br/>
	 * This is an expensive operations as the hash table is rebuild from scratch.
	 * <o>n</o>
	 * @throws de.polygonal.ds.error.AssertError <code>slotCount</code> is not a power of two (debug only).
	 */
	public function rehash(slotCount:Int)
	{
		#if debug
		assert(M.isPow2(slotCount), "slotCount is not a power of 2");
		#end
		
		if (slotCount == getSlotCount()) return;
		
		var tmp = new IntIntHashTable(slotCount, mCapacity);
		
		#if (flash && alchemy)
		var o = mData.getAddr(0);
		for (i in 0...mCapacity)
		{
			var v = Memory.getI32(o + 4);
			if (v != VAL_ABSENT) tmp.set(Memory.getI32(o), v);
			o += 12;
		}
		#else
		for (i in 0...mCapacity)
		{
			var v = getData((i * 3) + 1);
			if (v != VAL_ABSENT) tmp.set(getData(i * 3), v);
		}
		#end
		
		#if (flash && alchemy)
		mHash.free();
		mData.free();
		mNext.free();
		#end
		mHash = tmp.mHash;
		mData = tmp.mData;
		mNext = tmp.mNext;
		
		mMask = tmp.mMask;
		mFree = tmp.mFree;
		mSizeLevel = tmp.mSizeLevel;
	}
	
	/**
	 * Remaps the first occurrence of <code>key</code> to a new value <code>val</code>.
	 * <o>1</o>
	 * @return true if <code>val</code> was successfully remapped to <code>key</code>.
	 */
	inline public function remap(key:Int, val:Int):Bool
	{
		var i = getHash(hashCode(key));
		if (i == EMPTY_SLOT)
			return false;
		else
		{
			#if (flash && alchemy)
			var o = mData.getAddr(i);
			if (Memory.getI32(o) == key)
			{
				Memory.setI32(o + 4, val);
				return true;
			}
			#else
			if (getData(i) == key)
			{
				setData(i + 1, val);
				return true;
			}
			#end
			else
			{
				#if (flash && alchemy)
				i = Memory.getI32(o + 8);
				while (i != NULL_POINTER)
				{
					o = mData.getAddr(i);
					if (Memory.getI32(o) == key)
					{
						Memory.setI32(o + 4, val);
						break;
					}
					i = Memory.getI32(o + 8);
				}
				#else
				i = getData(i + 2);
				while (i != NULL_POINTER)
				{
					if (getData(i) == key)
					{
						setData(i + 1, val);
						break;
					}
					i = getData(i + 2);
				}
				#end
				return i != NULL_POINTER;
			}
		}
	}
	
	/**
	 * Removes the first occurrence of <code>key</code> and returns the value mapped to it.
	 * <o>1</o>
	 * @return the value mapped to key or <em>IntIntHashTable.KEY_ABSENT</em> if <code>key</code> does not exist.
	 */
	inline public function extract(key:Int):Int
	{
		var b = hashCode(key);
		var i = getHash(b);
		if (i == EMPTY_SLOT)
			return IntIntHashTable.KEY_ABSENT;
		else
		{
			#if (flash && alchemy)
			var o = mData.getAddr(i);
			if (key == Memory.getI32(o))
			{
				var val = Memory.getI32(o + 4);
			#else
			if (key == getData(i))
			{
				var val = getData(i + 1);
			#end
				#if (flash && alchemy)
				if (Memory.getI32(o + 8) == NULL_POINTER)
				#else
				if (getData(i + 2) == NULL_POINTER)
				#end
					setHash(b, EMPTY_SLOT);
				else
					setHash(b, getData(i + 2));
				
				var j = Std.int(i / 3);
				setNext(j, mFree);
				mFree = j;
				
				#if (flash && alchemy)
				Memory.setI32(o + 4, VAL_ABSENT);
				Memory.setI32(o + 8, NULL_POINTER);
				#else
				setData(i + 1, VAL_ABSENT);
				setData(i + 2, NULL_POINTER);
				#end
				
				mSize--;
				
				if (mSizeLevel > 0)
					if (mSize == (mCapacity >> 2))
						if (mIsResizable)
							shrink();
				
				return val;
			}
			else
			{
				var i0 = i;
				#if (flash && alchemy)
				i = Memory.getI32(o + 8);
				#else
				i = getData(i + 2);
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
					if (getData(i) == key)
					{
						val = getData(i + 1);
						break;
					}
					i = getData((i0 = i) + 2);
					#end
				}
				
				if (val != IntIntHashTable.KEY_ABSENT)
				{
					setData(i0 + 2, getData(i + 2));
					
					var j = Std.int(i / 3);
					setNext(j, mFree);
					mFree = j;
					
					#if (flash && alchemy)
					o = mData.getAddr(i + 1);
					Memory.setI32(o    , VAL_ABSENT);
					Memory.setI32(o + 4, NULL_POINTER);
					#else
					setData(i + 1, VAL_ABSENT);
					setData(i + 2, NULL_POINTER);
					#end
					
					--mSize;
					
					if (mSizeLevel > 0)
						if (mSize == (mCapacity >> 2))
							if (mIsResizable)
								shrink();
					
					return val;
				}
				else
					return IntIntHashTable.KEY_ABSENT;
			}
		}
	}
	
	/**
	 * Creates and returns an unordered array of all keys.
	 */
	public function toKeyArray():Array<Int>
	{
		if (size() == 0) return new Array<Int>();
		
		var a:Array<Int> = ArrayUtil.alloc(size());
		var j = 0;
		for (i in 0...mCapacity)
		{
			#if (flash && alchemy)
			var o = mData.getAddr(i * 3);
			if (Memory.getI32(o + 4) != VAL_ABSENT)
				a[j++] = Memory.getI32(o);
			#else
			if (getData((i * 3) + 1) != VAL_ABSENT)
				a[j++] = getData(i * 3);
			#end
		}
		return a;
	}
	
	/**
	 * Creates and returns an unordered vector of all keys or null if there are no keys.
	 */
	public function toKeyVector():Vector<Int>
	{
		if (isEmpty()) return null;
		
		var a = new Vector<Int>(size());
		var j = 0;
		for (i in 0...mCapacity)
		{
			#if (flash && alchemy)
			var o = mData.getAddr(i * 3);
			if (Memory.getI32(o + 4) != VAL_ABSENT)
				a[j++] = Memory.getI32(o);
			#else
			if (getData((i * 3) + 1) != VAL_ABSENT)
				a[j++] = getData(i * 3);
			#end
		}
		return a;
	}
	
	/**
	 * Creates and returns an unordered dense array of all keys.
	 */
	public function toKeyDA():DA<Int>
	{
		var a = new DA<Int>(size());
		for (i in 0...mCapacity)
		{
			#if (flash && alchemy)
			var o = mData.getAddr(i * 3);
			if (Memory.getI32(o + 4) != VAL_ABSENT)
				a.pushBack(Memory.getI32(o));
			#else
			if (getData((i * 3) + 1) != VAL_ABSENT)
				a.pushBack(getData(i * 3));
			#end
		}
		return a;
	}
	
	/**
	 * Returns a string representing the current object.<br/>
	 * Example:<br/>
	 * <pre class="prettyprint">
	 * var hash = new de.polygonal.ds.IntIntHashTable(16);
	 * for (i in 0...4) {
	 *     hash.set(i, i);
	 * }
	 * trace(hash);</pre>
	 * <pre class="console">
	 * { IntIntHashTable size: 4, load factor: 0.25 }
	 * [
	 *   0 -> 0
	 *   1 -> 1
	 *   2 -> 2
	 *   3 -> 3
	 * ]</pre>
	 */
	public function toString():String
	{
		var s = Printf.format("[ IntIntHashTable size/capacity: %d/%d, load factor: %.2f }", [size(), getCapacity(), getLoadFactor()]);
		if (isEmpty()) return s;
		s += "\n[\n";
		
		var max = 0.;
		for (key in keys()) max = Math.max(max, key);
		var i = 1;
		while (max != 0)
		{
			i++;
			max = Std.int(max / 10);
		}
		
		for (key in keys())
			s += Printf.format("  %- " + i + "d -> %d\n", [key, get(key)]);
		
		s += "]";
		return s;
	}
	
	/*///////////////////////////////////////////////////////
	// map
	///////////////////////////////////////////////////////*/
	
	/**
	 * Returns true if this map contains a mapping for the value <code>val</code>.
	 * @throws de.polygonal.ds.error.AssertError value 0x80000000 is reserved (debug only).
	 */
	public function has(val:Int):Bool
	{
		#if debug
		assert(val != VAL_ABSENT, "val 0x80000000 is reserved");
		#end
		
		var exists = false;
		for (i in 0...getCapacity())
		{
			var v = getData((i * 3) + 1);
			if (v == val)
			{
				exists = true;
				break;
			}
		}
		return exists;
	}
	
	/**
	 * Returns true if this map contains <code>key</code>.
	 */
	inline public function hasKey(key:Int):Bool
	{
		var i = getHash(hashCode(key));
		if (i == EMPTY_SLOT)
			return false;
		else
		{
			#if (flash && alchemy)
			var o = mData.getAddr(i);
			if (Memory.getI32(o) == key)
				return true;
			#else
			if (getData(i) == key)
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
				i = getData(i + 2);
				while (i != NULL_POINTER)
				{
					if (getData(i) == key)
					{
						exists = true;
						break;
					}
					i = getData(i + 2);
				}
				#end
				return exists;
			}
		}
	}
	
	/**
	 * Counts the number of mappings for <code>key</code>.
	 */
	public function count(key:Int):Int
	{
		var c = 0;
		var i = getHash(hashCode(key));
		if (i == EMPTY_SLOT)
			return c;
		else
		{
			#if (flash && alchemy)
			while (i != NULL_POINTER)
			{
				var o = mData.getAddr(i);
				if (Memory.getI32(o) == key) c++;
				i = Memory.getI32(o + 8);
			}
			#else
			while (i != NULL_POINTER)
			{
				if (getData(i) == key) c++;
				i = getData(i + 2);
			}
			#end
			return c;
		}
	}
	
	/**
	 * Returns the first value that is mapped to <code>key</code> or <em>IntIntHashTable.KEY_ABSENT</em> if <code>key</code> does not exist.
	 */
	inline public function get(key:Int):Int
	{
		var i = getHash(hashCode(key));
		if (i == EMPTY_SLOT)
			return KEY_ABSENT;
		else
		{
			#if (flash && alchemy)
			var o = mData.getAddr(i);
			if (Memory.getI32(o) == key)
				return Memory.getI32(o + 4);
			#else
			if (getData(i) == key)
				return getData(i + 1);
			#end
			else
			{
				var v = KEY_ABSENT;
				#if (flash && alchemy)
				i = Memory.getI32(o + 8);
				while (i != NULL_POINTER)
				{
					o = mData.getAddr(i);
					if (Memory.getI32(o) == key)
					{
						v = Memory.getI32(o + 4);
						break;
					}
					i = Memory.getI32(o + 8);
				}
				#else
				i = getData(i + 2);
				while (i != NULL_POINTER)
				{
					if (getData(i) == key)
					{
						v = getData(i + 1);
						break;
					}
					i = getData(i + 2);
				}
				#end
				return v;
			}
		}
	}
	
	/**
	 * Stores all values that are mapped to <code>key</code> in <code>values</code> or returns 0 if <code>key</code> does not exist.
	 * @return the total number of values mapped to <code>key</code>.
	 */
	public function getAll(key:Int, values:Array<Int>):Int
	{
		var i = getHash(hashCode(key));
		if (i == EMPTY_SLOT)
			return 0;
		else
		{
			var c = 0;
			#if (flash && alchemy)
			var o = mData.getAddr(i);
			if (Memory.getI32(o) == key)
				values[c++] = Memory.getI32(o + 4);
			i = Memory.getI32(o + 8);
			while (i != NULL_POINTER)
			{
				o = mData.getAddr(i);
				if (Memory.getI32(o) == key)
					values[c++] = Memory.getI32(o + 4);
				i = Memory.getI32(o + 8);
			}
			#else
			if (getData(i) == key)
				values[c++] = getData(i + 1);
			i = getData(i + 2);
			while (i != NULL_POINTER)
			{
				if (getData(i) == key)
					values[c++] = getData(i + 1);
				i = getData(i + 2);
			}
			#end
			return c;
		}
	}
	
	/**
	 * Returns true if this map contains a mapping from <code>key</code> to <code>val</code>.
	 * @throws de.polygonal.ds.error.AssertError value 0x80000000 is reserved (debug only).
	 */
	public function hasPair(key:Int, val:Int):Bool
	{
		#if debug
		assert(val != KEY_ABSENT, "val 0x80000000 is reserved");
		#end
		
		var i = getHash(hashCode(key));
		if (i == EMPTY_SLOT)
			return false;
		else
		{
			#if (flash && alchemy)
			var o = mData.getAddr(i);
			if (Memory.getI32(o) == key)
				if (Memory.getI32(o + 4) == val)
					return true;
			
			i = Memory.getI32(o + 8);
			while (i != NULL_POINTER)
			{
				o = mData.getAddr(i);
				if (Memory.getI32(o) == key)
					if (Memory.getI32(o + 4) == val)
						return true;
				i = Memory.getI32(o + 8);
			}
			#else
			if (getData(i) == key)
				if (getData(i + 1) == val)
					return true;
			
			i = getData(i + 2);
			while (i != NULL_POINTER)
			{
				if (getData(i) == key)
					if (getData(i + 1) == val)
						return true;
				i = getData(i + 2);
			}
			#end
			return false;
		}
	}
	
	/**
	 * Maps the value <code>val</code> to <code>key</code>.<br/>
	 * The method allows duplicate keys.<br/>
	 * <warn>To ensure unique keys either use <em>hasKey()</em> before <em>set()</em> or <em>setIfAbsent()</em></warn>
	 * @return true if <code>key</code> was added for the first time, false if another instance of <code>key</code> was inserted.
	 * @throws de.polygonal.ds.error.AssertError out of space - hash table is full but not resizable.
	 * @throws de.polygonal.ds.error.AssertError key/value 0x80000000 is reserved (debug only).
	 * @throws de.polygonal.ds.error.AssertError <em>size()</em> equals <em>maxSize</em> (debug only).
	 */
	inline public function set(key:Int, val:Int):Bool
	{
		#if debug
		assert(val != KEY_ABSENT, "val 0x80000000 is reserved");
		assert(size() < maxSize, 'size equals max size ($maxSize)');
		#end
		
		if (mSize == mCapacity)
		{
			#if debug
			if (!mIsResizable)
				assert(false, 'out of space (${getCapacity()})');
			#end
			
			if (mIsResizable)
				expand();
		}
		
		var i = mFree * 3;
		mFree = getNext(mFree);
		
		#if (flash && alchemy)
		var o = mData.getAddr(i);
		Memory.setI32(o    , key);
		Memory.setI32(o + 4, val);
		#else
		setData(i    , key);
		setData(i + 1, val);
		#end
		
		var b = hashCode(key);
		
		#if (flash && alchemy)
		o = mHash.getAddr(b);
		var j = Memory.getI32(o);
		if (j == EMPTY_SLOT)
		{
			Memory.setI32(o, i);
			mSize++;
			return true;
		}
		#else
		var j = getHash(b);
		if (j == EMPTY_SLOT)
		{
			setHash(b, i);
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
			var first = getData(j) != key;
			var t = getData(j + 2);
			#end
			
			while (t != NULL_POINTER)
			{
				#if (flash && alchemy)
				o = mData.getAddr(t);
				if (flash.Memory.getI32(o) == key) first = false;
				j = t;
				t = flash.Memory.getI32(o + 8);
				#else
				if (getData(t) == key) first = false;
				j = t;
				t = getData(t + 2);
				#end
			}
			
			#if (flash && alchemy)
			flash.Memory.setI32(o + 8, i);
			#else
			setData(j + 2, i);
			#end
			
			mSize++;
			return first;
		}
	}
	
	/**
	 * Removes the first occurrence of <code>key</code>.
	 * @return true if <code>key</code> is successfully removed.
	 */
	inline public function clr(key:Int):Bool
	{
		//TODO make sure all values are removed from key
		var b = hashCode(key);
		var i = getHash(b);
		if (i == EMPTY_SLOT)
			return false;
		else
		{
			#if (flash && alchemy)
			var o = mData.getAddr(i);
			if (key == Memory.getI32(o))
			#else
			if (key == getData(i))
			#end
			{
				#if (flash && alchemy)
				if (Memory.getI32(o + 8) == NULL_POINTER)
				#else
				if (getData(i + 2) == NULL_POINTER)
				#end
					setHash(b, EMPTY_SLOT);
				else
					setHash(b, getData(i + 2));
				
				var j = Std.int(i / 3);
				setNext(j, mFree);
				mFree = j;
				
				#if (flash && alchemy)
				Memory.setI32(o + 4, VAL_ABSENT);
				Memory.setI32(o + 8, NULL_POINTER);
				#else
				setData(i + 1, VAL_ABSENT);
				setData(i + 2, NULL_POINTER);
				#end
				
				mSize--;
				
				if (mSizeLevel > 0)
					if (mSize == (mCapacity >> 2))
						if (mIsResizable)
							shrink();
				
				return true;
			}
			else
			{
				var exists = false;
				
				var i0 = i;
				#if (flash && alchemy)
				i = Memory.getI32(o + 8);
				#else
				i = getData(i + 2);
				#end
				
				while (i != NULL_POINTER)
				{
					#if (flash && alchemy)
					o = mData.getAddr(i);
					if (Memory.getI32(o) == key)
					{
						exists = true;
						break;
					}
					i0 = i;
					i = Memory.getI32(o + 8);
					#else
					if (getData(i) == key)
					{
						exists = true;
						break;
					}
					i = getData((i0 = i) + 2);
					#end
				}
				
				if (exists)
				{
					setData(i0 + 2, getData(i + 2));
					
					var j = Std.int(i / 3);
					setNext(j, mFree);
					mFree = j;
					
					#if (flash && alchemy)
					o = mData.getAddr(i + 1);
					Memory.setI32(o    , VAL_ABSENT);
					Memory.setI32(o + 4, NULL_POINTER);
					#else
					setData(i + 1, VAL_ABSENT);
					setData(i + 2, NULL_POINTER);
					#end
					
					--mSize;
					
					if (mSizeLevel > 0)
						if (mSize == (mCapacity >> 2))
							if (mIsResizable)
								shrink();
					
					return true;
				}
				else
					return false;
			}
		}
	}
	
	/**
	 * Creates an <em>IntHashSet</em> object of the values in this map.
	 */
	public function toValSet():Set<Int>
	{
		var s = new IntHashSet(getCapacity());
		for (i in 0...mCapacity)
		{
			var v = getData((i * 3) + 1);
			if (v != VAL_ABSENT) s.set(v);
		}
		
		return s;
	}
	
	/**
	 * Creates an <em>IntHashSet</em> object of the keys in this map.
	 */
	public function toKeySet():Set<Int>
	{
		var s = new IntHashSet(getCapacity());
		for (i in 0...mCapacity)
		{
			var v = getData((i * 3) + 1);
			if (v != VAL_ABSENT)
			{
				s.set(getData(i * 3));
			}
		}
		
		return s;
	}
	
	/**
	 * Returns a new <em>IntIntHashTableKeyIterator</em> object to iterate over all keys stored in this map.
	 * The keys are visited in a random order.
	 * @see <a href="http://haxe.org/ref/iterators" target="mBlank">http://haxe.org/ref/iterators</a>
	 */
	public function keys():Itr<Int>
	{
		return new IntIntHashTableKeyIterator(this);
	}
	
	/*///////////////////////////////////////////////////////
	// collection
	///////////////////////////////////////////////////////*/
	
	/**
	 * Destroys this object by explicitly nullifying all key/values.<br/>
	 * <warn>If "alchemy memory" is used, always call this method when the life cycle of this object ends to prevent a memory leak.</warn>
	 */
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
		mIterator = null;
	}
	
	/**
	 * Same as <em>has()</em>.
	 */
	inline public function contains(val:Int):Bool
	{
		return has(val);
	}
	
	/**
	 * Removes all occurrences of the value <code>val</code>.
	 * @return true if <code>val</code> was removed, false if <code>val</code> does not exist.
	 * @throws de.polygonal.ds.error.AssertError value 0x80000000 is reserved (debug only).
	 */
	public function remove(val:Int):Bool
	{
		#if debug
		assert(val != KEY_ABSENT, "val 0x80000000 is reserved");
		#end
		
		var c = 0;
		var keys = new Array<Int>();
		for (i in 0...mCapacity)
		{
			#if (flash && alchemy)
			var o = mData.getAddr(i * 3);
			if (Memory.getI32(o + 4) == val)
				keys[c++] = Memory.getI32(o);
			#else
			var j = i * 3;
			if (getData(j + 1) == val)
				keys[c++] = getData(j);
			#end
		}
		
		if (c > 0)
		{
			for (key in keys) clr(key);
			return true;
		}
		else
			return false;
	}
	
	/**
	 * The total number of key/value pairs.
	 */
	inline public function size():Int
	{
		return mSize;
	}
	
	/**
	 * Removes all key/value pairs.<br/>
	 * @param purge If true, the hash table shrinks to the initial capacity defined in the constructor.
	 */
	public function clear(purge = false)
	{
		if (purge && mSizeLevel > 0)
		{
			mCapacity >>= mSizeLevel;
			mSizeLevel = 0;
			
			#if alchemy
			mData.resize(mCapacity * 3);
			mNext.resize(mCapacity);
			#else
			mData = new Vector<Int>(mCapacity * 3);
			mNext = new Vector<Int>(mCapacity);
			#end
		}
		
		#if alchemy
		mHash.fill(EMPTY_SLOT);
		#else
		for (i in 0...getSlotCount()) mHash[i] = EMPTY_SLOT;
		#end
		
		var j = 2;
		for (i in 0...mCapacity)
		{
			setData(j - 1, VAL_ABSENT);
			setData(j, NULL_POINTER);
			j += 3;
		}
		for (i in 0...mCapacity - 1) setNext(i, i + 1);
		setNext(mCapacity - 1, NULL_POINTER);
		
		mFree = 0;
		mSize = 0;
	}
	
	/**
	 * Returns a new <em>IntIntHashTableValIterator</em> object to iterate over all values contained in this hash table.<br/>
	 * The values are visited in a random order.
	 * @see <a href="http://haxe.org/ref/iterators" target="mBlank">http://haxe.org/ref/iterators</a>
	 */
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
	 * Returns true if this hash table is empty.
	 */
	inline public function isEmpty():Bool
	{
		return mSize == 0;
	}
	
	/**
	 * Returns an unordered array containing all values in this hash table.
	 */
	public function toArray():Array<Int>
	{
		var a:Array<Int> = ArrayUtil.alloc(size());
		var j = 0;
		for (i in 0...mCapacity)
		{
			var v = getData((i * 3) + 1);
				if (v != VAL_ABSENT) a[j++] = v;
		}
		return a;
	}
	
	/**
	 * Returns an unordered Vector.&lt;T&gt; object containing all values in this hash table.
	 */
	public function toVector():Vector<Int>
	{
		var v = new Vector<Int>(size());
		var j = 0, val;
		for (i in 0...mCapacity)
		{
			val = getData((i * 3) + 1);
			if (val != VAL_ABSENT) v[j++] = val;
		}
		return v;
	}
	
	/**
	 * Duplicates this hash table by creating a deep copy.<br/>
	 * The <code>assign</code> and <code>copier</code> parameters are ignored.
	 */
	public function clone(assign:Bool = true, copier:Int->Int = null):Collection<Int>
	{
		var c = new IntIntHashTable(M.INT16_MIN);
		c.key = HashKey.next();
		c.maxSize = maxSize;
		
		#if alchemy
		c.mHash = mHash.clone();
		c.mData = mData.clone();
		c.mNext = mNext.clone();
		#else
		c.mHash = new Vector<Int>(mHash.length);
		c.mData = new Vector<Int>(mData.length);
		c.mNext = new Vector<Int>(mNext.length);
		for (i in 0...Std.int(mHash.length)) c.mHash[i] = mHash[i];
		for (i in 0...Std.int(mData.length)) c.mData[i] = mData[i];
		for (i in 0...Std.int(mNext.length)) c.mNext[i] = mNext[i];
		#end
		
		c.mMask = mMask;
		c.mCapacity = mCapacity;
		c.mFree = mFree;
		c.mSize = mSize;
		c.mSizeLevel = mSizeLevel;
		
		return c;
	}
	
	inline function hashCode(x:Int):Int
	{
		return (x * 73856093) & mMask;
	}
	
	function expand()
	{
		mSizeLevel++;
		
		var oldSize = mCapacity;
		var newSize = oldSize << 1;
		mCapacity = newSize;
		
		#if alchemy
		mNext.resize(newSize);
		mData.resize(newSize * 3);
		#else
		var copy = new Vector<Int>(newSize);
		for (i in 0...oldSize) copy[i] = mNext[i];
		mNext = copy;
		var copy = new Vector<Int>(newSize  * 3);
		for (i in 0...oldSize * 3) copy[i] = mData[i];
		mData = copy;
		#end
		
		for (i in oldSize - 1...newSize - 1) setNext(i, i + 1);
		setNext(newSize - 1, NULL_POINTER);
		mFree = oldSize;
		
		var j = (oldSize * 3) + 2;
		for (i in 0...oldSize)
		{
			#if (flash && alchemy)
			var o = mData.getAddr(j - 1);
			Memory.setI32(o    , VAL_ABSENT);
			Memory.setI32(o + 4, NULL_POINTER);
			#else
			setData(j - 1, VAL_ABSENT);
			setData(j    , NULL_POINTER);
			#end
			
			j += 3;
		}
	}
	
	function shrink()
	{
		mSizeLevel--;
		
		var oldSize = mCapacity;
		var newSize = oldSize >> 1;
		mCapacity = newSize;
		
		#if (flash && alchemy)
		mData.resize((oldSize + (newSize >> 1)) * 3);
		var offset = oldSize * 3;
		var e = offset;
		
		var dst, src;
		dst = mData.getAddr(e);
		
		for (i in 0...getSlotCount())
		{
			var j = getHash(i);
			if (j == EMPTY_SLOT) continue;
			
			setHash(i, e - offset);
			
			src = mData.getAddr(j);
			flash.Memory.setI32(dst    , flash.Memory.getI32(src    ));
			flash.Memory.setI32(dst + 4, flash.Memory.getI32(src + 4));
			flash.Memory.setI32(dst + 8, NULL_POINTER);
			dst += 12;
			
			e += 3;
			j = getData(j + 2);
			while (j != NULL_POINTER)
			{
				src = mData.getAddr(j);
				flash.Memory.setI32(dst - 4, e - offset);
				flash.Memory.setI32(dst    , flash.Memory.getI32(src));
				flash.Memory.setI32(dst + 4, flash.Memory.getI32(src + 4));
				flash.Memory.setI32(dst + 8, NULL_POINTER);
				dst += 12;
				
				e += 3;
				j = getData(j + 2);
			}
		}
		
		var k = (newSize >> 1) * 3;
		
		dst = mData.getAddr(0);
		src = mData.getAddr(offset);
		var i = 0;
		var j = k << 2;
		while (i < j)
		{
			flash.Memory.setI32(dst + i, flash.Memory.getI32(src + i));
			i += 4;
		}
		
		dst = mData.getAddr(k);
		k = mData.getAddr(newSize * 3);
		while (dst < k)
		{
			flash.Memory.setI32(dst + 4, VAL_ABSENT);
			flash.Memory.setI32(dst + 8, NULL_POINTER);
			dst += 12;
		}
		
		mData.resize(newSize * 3);
		mNext.resize(newSize);
		#else
		var k = newSize * 3;
		var tmp = new Vector<Int>(k);
		mNext = new Vector<Int>(newSize);
		
		var e = 0;
		for (i in 0...getSlotCount())
		{
			var j = getHash(i);
			if (j == EMPTY_SLOT) continue;
			
			setHash(i, e);
			
			tmp[e    ] = getData(j    );
			tmp[e + 1] = getData(j + 1);
			tmp[e + 2] = NULL_POINTER;
			
			e += 3;
			j = getData(j + 2);
			while (j != NULL_POINTER)
			{
				tmp[e - 1] = e;
				tmp[e    ] = getData(j    );
				tmp[e + 1] = getData(j + 1);
				tmp[e + 2] = NULL_POINTER;
				
				e += 3;
				j = getData(j + 2);
			}
		}
		var i = k >> 1;
		while (i < k)
		{
			tmp[i + 1] = VAL_ABSENT;
			tmp[i + 2] = NULL_POINTER;
			i += 3;
		}
		mData = tmp;
		#end
		
		for (i in 0...newSize - 1) setNext(i, i + 1);
		setNext(newSize - 1, NULL_POINTER);
		mFree = newSize >> 1;
	}
	
	inline function getHash(i:Int)
	{
		#if (flash && alchemy)
		return mHash.get(i);
		//#elseif cpp
		//return untyped mHash._unsafemGet(i);
		#else
		return mHash[i];
		#end
	}
	inline function setHash(i:Int, x:Int)
	{
		#if (flash && alchemy)
		mHash.set(i, x);
		//#elseif cpp
		//untyped mHash._unsafemSet(i, x);
		#else
		mHash[i] = x;
		#end
	}
	
	inline function getNext(i:Int)
	{
		#if (flash && alchemy)
		return mNext.get(i);
		//#elseif cpp
		//return untyped mNext._unsafemGet(i);
		#else
		return mNext[i];
		#end
	}
	inline function setNext(i:Int, x:Int)
	{
		#if (flash && alchemy)
		mNext.set(i, x);
		//#elseif cpp
		//untyped mNext._unsafemSet(i, x);
		#else
		mNext[i] = x;
		#end
	}
	
	inline function getData(i:Int)
	{
		#if (flash && alchemy)
		return mData.get(i);
		//#elseif cpp
		//return untyped mData._unsafemGet(i);
		#else
		return mData[i];
		#end
	}
	inline function setData(i:Int, x:Int)
	{
		#if (flash && alchemy)
		mData.set(i, x);
		//#elseif cpp
		//untyped mData._unsafemSet(i, x);
		#else
		mData[i] = x;
		#end
	}
}

#if doc
private
#end
@:access(de.polygonal.ds.IntIntHashTable)
class IntIntHashTableValIterator implements de.polygonal.ds.Itr<Int>
{
	var mF:IntIntHashTable;
	var mI:Int;
	var mS:Int;
	
	#if alchemy
	var mData:IntMemory;
	#else
	var mData:Vector<Int>;
	#end
	
	public function new(hash:IntIntHashTable)
	{
		mF = hash;
		mData = mF.mData;
		mI = 0;
		mS = mF.mCapacity;
		scan();
	}
	
	inline public function reset():Itr<Int>
	{
		mData = mF.mData;
		mI = 0;
		mS = mF.mCapacity;
		scan();
		return this;
	}
	
	inline public function hasNext():Bool
	{
		return mI < mS;
	}
	
	inline public function next():Int
	{
		var val = getData((mI++ * 3) + 1);
		scan();
		return val;
	}
	
	inline public function remove()
	{
		throw "unsupported operation";
	}
	
	inline function scan()
	{
		while ((mI < mS) && (getData((mI * 3) + 1) == IntIntHashTable.VAL_ABSENT)) mI++;
	}
	
	inline function getData(i:Int)
	{
		#if (flash && alchemy)
		return mData.get(i);
		//#elseif cpp
		//return untyped mData._unsafemGet(i);
		#else
		return mData[i];
		#end
	}
}

#if doc
private
#end
@:access(de.polygonal.ds.IntIntHashTable)
class IntIntHashTableKeyIterator implements de.polygonal.ds.Itr<Int>
{
	var mF:IntIntHashTable;
	var mI:Int;
	var mS:Int;
	
	#if alchemy
	var mData:IntMemory;
	#else
	var mData:Vector<Int>;
	#end
	
	public function new(hash:IntIntHashTable)
	{
		mF = hash;
		mData = mF.mData;
		mI = 0;
		mS = mF.mCapacity;
		scan();
	}
	
	inline public function reset():Itr<Int>
	{
		mData = mF.mData;
		mI = 0;
		mS = mF.mCapacity;
		scan();
		return this;
	}
	
	inline public function hasNext():Bool
	{
		return mI < mS;
	}
	
	inline public function next():Int
	{
		var key = getData((mI++ * 3));
		scan();
		return key;
	}
	
	inline public function remove()
	{
		throw "unsupported operation";
	}
	
	inline function scan()
	{
		while ((mI < mS) && (getData((mI * 3) + 1) == IntIntHashTable.VAL_ABSENT)) mI++;
	}
	
	inline function getData(i:Int)
	{
		#if (flash && alchemy)
		return mData.get(i);
		//#elseif cpp
		//return untyped mData._unsafemGet(i);
		#else
		return mData[i];
		#end
	}
}