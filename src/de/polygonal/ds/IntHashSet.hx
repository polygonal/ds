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
import flash.Memory;
#end

import de.polygonal.ds.tools.ArrayTools;
import de.polygonal.ds.tools.Assert.assert;
import de.polygonal.ds.tools.GrowthRate;
import de.polygonal.ds.tools.MathTools;

#if !alchemy
using de.polygonal.ds.tools.NativeArrayTools;
#end

/**
	An array hash set for storing integers
	
	Example:
		var o = new de.polygonal.ds.IntHashSet(16);
		for (i in 0...4) o.set(i);
		trace(o); //outputs:
		
		[ IntHashSet size=4 capacity=16 load=0.25
		  0
		  1
		  2
		  3
		]
**/
class IntHashSet implements Set<Int>
{
	/**
		Return code for a non-existing element.
	**/
	public static inline var VAL_ABSENT = MathTools.INT32_MIN;
	
	static inline var EMPTY_SLOT = -1;
	static inline var NULL_POINTER = -1;
	
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
		The load factor measure the "denseness" of a hash set and is proportional to the time cost to look up an entry.
		
		E.g. assuming that the elements are perfectly distributed, a load factor of 4.0 indicates that each slot stores 4 elements, which have to be sequentially searched in order to find an element.
		
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
	
	#if alchemy
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
	var mIterator:IntHashSetIterator;
	
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
		assert(MathTools.isPow2(slotCount), "slotCount is not a power of 2");
		
		if (initialCapacity == -1)
			initialCapacity = slotCount;
		
		initialCapacity = MathTools.max(2, initialCapacity);
		mMinCapacity = capacity = initialCapacity;
		
		this.slotCount = slotCount;
		mMask = slotCount - 1;
		
		#if alchemy
		mHash = new IntMemory(slotCount, "IntHashSet.mHash");
		mHash.setAll(EMPTY_SLOT);
		mData = new IntMemory(capacity << 1, "IntHashSet.mData");
		mNext = new IntMemory(capacity, "IntHashSet.mNext");
		#else
		mHash = NativeArrayTools.alloc(slotCount).init(EMPTY_SLOT);
		mData = NativeArrayTools.alloc(capacity << 1);
		mNext = NativeArrayTools.alloc(capacity);
		#end
		
		var j = 1, t = mData;
		for (i in 0...capacity)
		{
			t.set(j - 1, VAL_ABSENT);
			t.set(j, NULL_POINTER);
			j += 2;
		}
		
		t = mNext;
		for (i in 0...capacity - 1) t.set(i, i + 1);
		t.set(capacity - 1, NULL_POINTER);
	}
	
	/**
		Counts the total number of collisions.
		
		A collision occurs when two distinct elements are hashed into the same slot.
	**/
	public function getCollisionCount():Int
	{
		var c = 0, j, d = mData, h = mHash;
		for (i in 0...slotCount)
		{
			j = h.get(i);
			if (j == EMPTY_SLOT) continue;
			j = d.get(j + 1);
			while (j != NULL_POINTER)
			{
				j = d.get(j + 1);
				c++;
			}
		}
		return c;
	}
	
	/**
		Returns true if this set contains `val`.
		
		Uses move-to-front-on-access which reduces access time when similar elements are frequently queried.
	**/
	public inline function hasFront(val:Int):Bool
	{
		assert(val != VAL_ABSENT, "value 0x80000000 is reserved");
		
		var h = mHash;
		var b = hashCode(val);
		var i = h.get(b);
		if (i == EMPTY_SLOT)
			return false;
		else
		{
			var d = mData;
			#if (flash && alchemy)
			var o = d.getAddr(i);
			if (Memory.getI32(o) == val)
				return true;
			#else
			if (d.get(i) == val)
				return true;
			#end
			else
			{
				var exists = false;
				
				var first = i, i0 = first;
				
				#if (flash && alchemy)
				i = Memory.getI32(o + 4);
				#else
				i = d.get(i + 1);
				#end
				
				while (i != NULL_POINTER)
				{
					#if (flash && alchemy)
					o = d.getAddr(i);
					if (Memory.getI32(o) == val)
					#else
					if (d.get(i) == val)
					#end
					{
						#if (flash && alchemy)
						var o1 = d.getAddr(i0 + 1);
						Memory.setI32(o1, Memory.getI32(o + 4));
						Memory.setI32(o + 4, first);
						h.set(b, i);
						#else
						d.set(i0 + 1, d.get(i + 1));
						d.set(i + 1, first);
						d.set(b, i);
						#end
						
						exists = true;
						break;
					}
					i = d.get((i0 = i) + 1);
				}
				return exists;
			}
		}
	}
	
	/**
		Redistributes all elements over `slotCount`.
		
		This is an expensive operations as the set is rebuild from scratch.
	**/
	public function rehash(slotCount:Int):IntHashSet
	{
		assert(MathTools.isPow2(slotCount), "slotCount is not a power of 2");
		
		if (this.slotCount == slotCount) return this;
		
		var t = new IntHashSet(slotCount, capacity);
		
		#if (flash && alchemy)
		var o = mData.getAddr(0);
		for (i in 0...capacity)
		{
			var v = Memory.getI32(o);
			if (v != VAL_ABSENT) t.set(v);
			o += 8;
		}
		#else
		var d = mData;
		for (i in 0...capacity)
		{
			var v = d.get(i << 1);
			if (v != VAL_ABSENT) t.set(v);
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
		Free up resources by reducing the capacity of the internal container to the initial capacity.
	**/
	public function pack():IntHashSet
	{
		if (capacity == mMinCapacity) return this;
		
		capacity = MathTools.max(size, mMinCapacity);
		
		var src = mData, dst;
		var e = 0, t = mHash, j;
		
		#if (flash && alchemy)
		dst = new IntMemory(capacity << 1, "IntHashSet.mData");
		var addr = dst.getAddr(e);
		for (i in 0...slotCount)
		{
			j = t.get(i);
			if (j == EMPTY_SLOT) continue;
			
			t.set(i, e);
			
			flash.Memory.setI32(addr    , src.get(j));
			flash.Memory.setI32(addr + 4, NULL_POINTER);
			addr += 8;
			e += 2;
			
			j = src.get(j + 1);
			while (j != NULL_POINTER)
			{
				flash.Memory.setI32(addr - 4, e);
				flash.Memory.setI32(addr    , src.get(j));
				flash.Memory.setI32(addr + 4, NULL_POINTER);
				addr += 8;
				e += 2;
				j = src.get(j + 1);
			}
		}
		mData.free();
		mData = dst;
		mNext.resize(capacity);
		#else
		dst = NativeArrayTools.alloc(capacity << 1);
		for (i in 0...slotCount)
		{
			j = t.get(i);
			if (j == EMPTY_SLOT) continue;
			
			t.set(i, e);
			dst.set(e++, src.get(j));
			dst.set(e++, NULL_POINTER);
			j = src.get(j + 1);
			while (j != NULL_POINTER)
			{
				dst.set(e - 1, e);
				dst.set(e++, src.get(j));
				dst.set(e++, NULL_POINTER);
				j = src.get(j + 1);
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
		Calls `f` on all values in random order.
	**/
	public inline function iter(f:Int->Void):IntHashSet
	{
		assert(f != null);
		var d = mData, j, v;
		for (i in 0...capacity)
		{
			j = i << 1;
			v = d.get(j);
			if (v != VAL_ABSENT) f(d.get(j));
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
		b.add(Printf.format('[ IntHashSet size=$size capacity=$capacity load=%.2f', [loadFactor]));
		if (isEmpty())
		{
			b.add(" ]");
			return b.toString();
		}
		b.add("\n");
		for (x in this) b.add('  $x\n');
		b.add("]");
		return b.toString();
	}
	#end
	
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
		mData.resize(capacity << 1);
		#else
		t = NativeArrayTools.alloc(capacity);
		mNext.blit(0, t, 0, oldCapacity);
		mNext = t;
		t = NativeArrayTools.alloc(capacity << 1);
		mData.blit(0, t, 0, oldCapacity << 1);
		mData = t;
		#end
		
		t = mNext;
		for (i in oldCapacity - 1...capacity - 1) t.set(i, i + 1);
		t.set(capacity - 1, NULL_POINTER);
		mFree = oldCapacity;
		
		var j = oldCapacity << 1;
		t = mData;
		for (i in 0...capacity - oldCapacity)
		{
			#if (flash && alchemy)
			var o = t.getAddr(j);
			Memory.setI32(o    , VAL_ABSENT);
			Memory.setI32(o + 4, NULL_POINTER);
			#else
			t.set(j    , VAL_ABSENT);
			t.set(j + 1, NULL_POINTER);
			#end
			j += 2;
		}
	}
	
	/* INTERFACE Set */
	
	/**
		Returns true if this set contains `val`.
	**/
	public inline function has(val:Int):Bool
	{
		assert(val != VAL_ABSENT, "value 0x80000000 is reserved");
		
		var i = mHash.get(hashCode(val));
		if (i == EMPTY_SLOT)
			return false;
		else
		{
			var d = mData;
			#if (flash && alchemy)
			var o = d.getAddr(i);
			if (Memory.getI32(o) == val)
				return true;
			#else
			if (d.get(i) == val)
				return true;
			#end
			else
			{
				var exists = false;
				#if (flash && alchemy)
				i = Memory.getI32(o + 4);
				while (i != NULL_POINTER)
				{
					o = d.getAddr(i);
					if (Memory.getI32(o) == val)
					{
						exists = true;
						break;
					}
					i = Memory.getI32(o + 4);
				}
				#else
				i = d.get(i + 1);
				while (i != NULL_POINTER)
				{
					if (d.get(i) == val)
					{
						exists = true;
						break;
					}
					i = d.get(i + 1);
				}
				#end
				return exists;
			}
		}
	}
	
	/**
		Adds `val` to this set if possible.
		@return true if `val` was added to this set, false if `val` already exists.
	**/
	public inline function set(val:Int):Bool
	{
		assert(val != VAL_ABSENT, "value 0x80000000 is reserved");
		
		var b = hashCode(val), d = mData;
		
		#if (flash && alchemy)
		var o = mHash.getAddr(b);
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
			
			j = mFree << 1;
			mFree = mNext.get(mFree);
			
			#if (flash && alchemy)
			Memory.setI32(o, j);
			#else
			mHash.set(b, j);
			#end
			
			d.set(j, val);
			mSize++;
			return true;
		}
		else
		{
			#if (flash && alchemy)
			o = d.getAddr(j);
			if (Memory.getI32(o) == val) return false;
			#else
			if (d.get(j) == val) return false;
			#end
			else
			{
				#if (flash && alchemy)
				var p = Memory.getI32(o + 4);
				while (p != NULL_POINTER)
				{
					o = d.getAddr(p);
					if (Memory.getI32(o) == val)
					{
						j = -1;
						break;
					}
					j = p;
					p = Memory.getI32(o + 4);
				}
				#else
				var p = d.get(j + 1);
				while (p != NULL_POINTER)
				{
					if (d.get(p) == val)
					{
						j = -1;
						break;
					}
					j = p;
					p = d.get(p + 1);
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
					p = mFree << 1;
					mFree = mNext.get(mFree);
					d.set(p, val);
					d.set(j + 1, p);
					mSize++;
					return true;
				}
			}
		}
	}
	
	/**
		Removes `val` from this set if possible.
		@return true if `val` was removed from this set, false if `val` does not exist.
	**/
	public inline function unset(val:Int):Bool
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
	}
	
	/**
		Same as `this.has()`.
	**/
	public inline function contains(val:Int):Bool
	{
		return has(val);
	}
	
	/**
		Removes `val`.
		@return true if `val` was successfully removed, false if `val` does not exist.
	**/
	public inline function remove(val:Int):Bool
	{
		var b = hashCode(val);
		var i = mHash.get(b);
		if (i == EMPTY_SLOT)
			return false;
		else
		{
			var d = mData;
			#if (flash && alchemy)
			var o = d.getAddr(i);
			if (val == Memory.getI32(o))
			#else
			if (val == d.get(i))
			#end
			{
				#if (flash && alchemy)
				if (Memory.getI32(o + 4) == NULL_POINTER)
				#else
				if (d.get(i + 1) == NULL_POINTER)
				#end
					mHash.set(b, EMPTY_SLOT);
				else
					mHash.set(b, d.get(i + 1));
				
				var j = i >> 1;
				mNext.set(j, mFree);
				mFree = j;
				
				#if (flash && alchemy)
				Memory.setI32(o    , VAL_ABSENT);
				Memory.setI32(o + 4, NULL_POINTER);
				#else
				d.set(i    , VAL_ABSENT);
				d.set(i + 1, NULL_POINTER);
				#end
				
				mSize--;
				return true;
			}
			else
			{
				var exists = false;
				
				var i0 = i;
				#if (flash && alchemy)
				i = Memory.getI32(o + 4);
				#else
				i = d.get(i + 1);
				#end
				
				while (i != NULL_POINTER)
				{
					#if (flash && alchemy)
					o = d.getAddr(i);
					if (Memory.getI32(o) == val)
					{
						exists = true;
						break;
					}
					i0 = i;
					i = Memory.getI32(o + 4);
					#else
					if (d.get(i) == val)
					{
						exists = true;
						break;
					}
					i = d.get((i0 = i) + 1);
					#end
				}
				
				if (exists)
				{
					d.set(i0 + 1, d.get(i + 1));
					
					var j = i >> 1;
					mNext.set(j, mFree);
					mFree = j;
					
					#if (flash && alchemy)
					o = d.getAddr(i);
					Memory.setI32(o    , VAL_ABSENT);
					Memory.setI32(o + 4, NULL_POINTER);
					#else
					d.set(i    , VAL_ABSENT);
					d.set(i + 1, NULL_POINTER);
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
		Removes all elements.
		
		The `gc` parameter has no effect.
	**/
	public function clear(gc:Bool = false)
	{
		#if alchemy
		mHash.setAll(EMPTY_SLOT);
		#else
		var h = mHash;
		for (i in 0...slotCount) h.set(i, EMPTY_SLOT);
		#end
		
		var j = 1, t = mData;
		for (i in 0...capacity)
		{
			t.set(j - 1, VAL_ABSENT);
			t.set(j    , NULL_POINTER);
			j += 2;
		}
		
		t = mNext;
		for (i in 0...capacity - 1) t.set(i, i + 1);
		t.set(capacity - 1, NULL_POINTER);
		
		mFree = 0;
		mSize = 0;
	}
	
	/**
		Returns a new *IntHashSetIterator* object to iterate over all elements contained in this hash set.
		
		The elements are visited in a random order.
		
		@see http://haxe.org/ref/iterators
	**/
	public function iterator():Itr<Int>
	{
		if (reuseIterator)
		{
			if (mIterator == null)
				mIterator = new IntHashSetIterator(this);
			else
				mIterator.reset();
			return mIterator;
		}
		else
			return new IntHashSetIterator(this);
	}
	
	/**
		Returns true only if `this.size` is 0.
	**/
	public inline function isEmpty():Bool
	{
		return size == 0;
	}
	
	/**
		Returns an unordered array containing all elements in this set.
	**/
	public function toArray():Array<Int>
	{
		if (isEmpty()) return [];
		
		var out = ArrayTools.alloc(size);
		var j = 0, v, d = mData;
		for (i in 0...capacity)
		{
			v = d.get(i << 1);
			if (v != VAL_ABSENT) out[j++] = v;
		}
		return out;
	}
	
	/**
		Duplicates this hash set by creating a deep copy (`byRef` and `copier` are ignored).
	**/
	public function clone(byRef:Bool = true, copier:Int->Int = null):Collection<Int>
	{
		var c = new IntHashSet(slotCount, size);
		
		#if alchemy
		IntMemory.blit(mHash, 0, c.mHash, 0, slotCount);
		IntMemory.blit(mData, 0, c.mData, 0, size << 1);
		IntMemory.blit(mNext, 0, c.mNext, 0, size);
		#else
		mHash.blit(0, c.mHash, 0, slotCount);
		mData.blit(0, c.mData, 0, size << 1);
		mNext.blit(0, c.mNext, 0, size);
		#end
		
		c.mMask = mMask;
		c.slotCount = slotCount;
		c.capacity = capacity;
		c.mFree = mFree;
		c.mSize = size;
		return c;
	}
}

@:access(de.polygonal.ds.IntHashSet)
@:dox(hide)
class IntHashSetIterator implements de.polygonal.ds.Itr<Int>
{
	var mObject:IntHashSet;
	var mI:Int;
	var mS:Int;
	
	#if alchemy
	var mData:IntMemory;
	#else
	var mData:NativeArray<Int>;
	#end
	
	public function new(x:IntHashSet)
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
		var x = mData.get((mI++ << 1));
		scan();
		return x;
	}
	
	public function remove()
	{
		throw "unsupported operation";
	}
	
	function scan()
	{
		while ((mI < mS) && (mData.get((mI << 1)) == IntHashSet.VAL_ABSENT)) mI++;
	}
}