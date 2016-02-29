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
import flash.Memory;
#end

import de.polygonal.ds.tools.ArrayTools;
import de.polygonal.ds.tools.Assert.assert;
import de.polygonal.ds.tools.GrowthRate;
import de.polygonal.ds.tools.M;

using de.polygonal.ds.tools.NativeArrayTools;

/**
	An array hash set for storing integers
	
**/
class IntHashSet implements Set<Int>
{
	/**
		Return code for a non-existing element.
	**/
	public static inline var VAL_ABSENT = M.INT32_MIN;
	
	static inline var EMPTY_SLOT = -1;
	static inline var NULL_POINTER = -1;
	
	/**
		A unique identifier for this object.
		
		A hash table transforms this key into an index of an array element by using a hash function.
		
		<warn>This value should never be changed by the user.</warn>
	**/
	public var key(default, null):Int = HashKey.next();
	
	/**
		The size of the allocated storage space for the elements.
		
		If more space is required to accomodate new elements, ``getCapacity()`` is doubled every time ``size`` grows beyond capacity and split in half when ``size`` is a quarter of capacity.
		
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
	public var growthRate:Int = GrowthRate.DOUBLE;
	
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
		<assert>`slotCount` is not a power of two</assert>
		<assert>`capacity` is not a power of two</assert>
		<assert>`capacity` is < 2</assert>
		@param slotCount the total number of slots into which the hashed elements are distributed.
		This defines the space-time trade off of the set.
		Increasing the `slotCount` reduces the computation time (read/write/access) of the set at the cost of increased memory use.
		This value is fixed and can only be changed by calling ``rehash()``, which rebuilds the set (expensive).
		
		@param initialCapacity the initial physical space for storing the elements at the time the set is created.
		This is also the minimum allowed size of the set and cannot be changed in the future.
		If omitted, the initial `capacity` equals `slotCount`.
		The `initialCapacity` is automatically adjusted according to the storage requirements based on two rules:
		<ul>
		<li>If the set runs out of space, the `capacity` is doubled.</li>
		<li>If the ``size`` falls below a quarter of the current `capacity`, the `capacity` is cut in half while the minimum `capacity` can't fall below `capacity`.</li>
		</ul>
	**/
	public function new(slotCount:Int, initialCapacity:Int = -1)
	{
		assert(slotCount > 0);
		assert(M.isPow2(slotCount), "slotCount is not a power of 2");
		
		if (initialCapacity == -1)
			initialCapacity = slotCount;
		
		initialCapacity = M.max(2, initialCapacity);
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
		Returns true if this set contains the element `x`.
		
		Uses move-to-front-on-access which reduces access time when similar elements are frequently queried.
		<assert>value 0x80000000 is reserved</assert>
	**/
	public inline function hasFront(x:Int):Bool
	{
		assert(x != VAL_ABSENT, "value 0x80000000 is reserved");
		
		var h = mHash;
		var b = hashCode(x);
		var i = h.get(b);
		if (i == EMPTY_SLOT)
			return false;
		else
		{
			var d = mData;
			#if (flash && alchemy)
			var o = d.getAddr(i);
			if (Memory.getI32(o) == x)
				return true;
			#else
			if (d.get(i) == x)
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
					if (Memory.getI32(o) == x)
					#else
					if (d.get(i) == x)
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
		<assert>`slotCount` is not a power of two</assert>
	**/
	public function rehash(slotCount:Int)
	{
		assert(M.isPow2(slotCount), "slotCount is not a power of 2");
		
		if (this.slotCount == slotCount) return;
		
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
	}
	
	public function pack():IntHashSet
	{
		if (capacity == mMinCapacity) return this;
		
		var oldCapacity = capacity;
		capacity = M.max(size, mMinCapacity);
		
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
		Returns a string representing the current object.
		
		Example:
		<pre class="prettyprint">
		var set = new de.polygonal.ds.IntHashSet(16);
		for (i in 0...4) {
		    set.set(i);
		}
		trace(set);</pre>
		<pre class="console">
		{ IntHashSet size/capacity: 4/16, load factor: 0.25 }
		[
		  0
		  1
		  2
		  3
		]</pre>
	**/
	public function toString():String
	{
		var b = new StringBuf();
		b.add(Printf.format("{ IntHashSet size/capacity: %d/%d, load factor: %.2f }", [size, capacity, loadFactor]));
		if (isEmpty()) return b.toString();
		b.add("\n[\n");
		for (x in this) b.add('  $x\n');
		b.add("]");
		return b.toString();
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
		
		var j = oldCapacity << 1, t = mData;
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
		Returns true if this set contains the element `x`.
		<assert>value 0x80000000 is reserved</assert>
	**/
	public inline function has(x:Int):Bool
	{
		assert(x != VAL_ABSENT, "value 0x80000000 is reserved");
		
		var i = mHash.get(hashCode(x));
		if (i == EMPTY_SLOT)
			return false;
		else
		{
			var d = mData;
			#if (flash && alchemy)
			var o = d.getAddr(i);
			if (Memory.getI32(o) == x)
				return true;
			#else
			if (d.get(i) == x)
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
					if (Memory.getI32(o) == x)
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
					if (d.get(i) == x)
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
		Adds the element `x` to this set if possible.
		<assert>value 0x80000000 is reserved</assert>
		<assert>hash set is full (if not resizable)</assert>
		@return true if `x` was added to this set, false if `x` already exists.
	**/
	public inline function set(x:Int):Bool
	{
		assert(x != VAL_ABSENT, "value 0x80000000 is reserved");
		
		var b = hashCode(x), d = mData;
		
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
			
			d.set(j, x);
			mSize++;
			return true;
		}
		else
		{
			#if (flash && alchemy)
			o = d.getAddr(j);
			if (Memory.getI32(o) == x) return false;
			#else
			if (d.get(j) == x) return false;
			#end
			else
			{
				#if (flash && alchemy)
				var p = Memory.getI32(o + 4);
				while (p != NULL_POINTER)
				{
					o = d.getAddr(p);
					if (Memory.getI32(o) == x)
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
					if (d.get(p) == x)
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
					d.set(p, x);
					d.set(j + 1, p);
					mSize++;
					return true;
				}
			}
		}
	}
	
	/**
		Removes the element `x` from this set if possible.
		@return true if `x` was removed from this set, false if `x` does not exist.
	**/
	public inline function unset(x:Int):Bool
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
		Same as ``has()``.
	**/
	public inline function contains(x:Int):Bool
	{
		return has(x);
	}
	
	/**
		Removes the element `x`.
		@return true if `x` was successfully removed, false if `x` does not exist.
	**/
	public inline function remove(x:Int):Bool
	{
		var b = hashCode(x);
		var i = mHash.get(b);
		if (i == EMPTY_SLOT)
			return false;
		else
		{
			var d = mData;
			#if (flash && alchemy)
			var o = d.getAddr(i);
			if (x == Memory.getI32(o))
			#else
			if (x == d.get(i))
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
					if (Memory.getI32(o) == x)
					{
						exists = true;
						break;
					}
					i0 = i;
					i = Memory.getI32(o + 4);
					#else
					if (d.get(i) == x)
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
		Returns a new `IntHashSetIterator` object to iterate over all elements contained in this hash set.
		
		The elements are visited in a random order.
		
		See <a href="http://haxe.org/ref/iterators" target="mBlank">http://haxe.org/ref/iterators</a>
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
		Returns true if the set is empty.
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
		Duplicates this hash set by creating a deep copy.
		
		The `assign` and `copier` parameters are ignored.
	**/
	public function clone(assign:Bool = true, copier:Int->Int = null):Collection<Int>
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