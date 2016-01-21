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
import flash.Memory;
#end

import de.polygonal.ds.error.Assert.assert;

/**
	An array hash set for storing integers
	
	<o>Amortized running time in Big O notation</o>
**/
class IntHashSet implements Set<Int>
{
	/**
		Return code for a non-existing element.
	**/
	inline public static var VAL_ABSENT = M.INT32_MIN;
	
	inline static var EMPTY_SLOT = -1;
	inline static var NULL_POINTER = -1;
	
	/**
		A unique identifier for this object.
		
		A hash table transforms this key into an index of an array element by using a hash function.
		
		<warn>This value should never be changed by the user.</warn>
	**/
	public var key:Int;
	
	/**
		The maximum allowed size of this hash set.
		
		Once the maximum size is reached, adding an element will fail with an error (debug only).
		
		A value of -1 indicates that the size is unbound.
		
		<warn>Always equals -1 in release mode.</warn>
	**/
	public var maxSize:Int;
	
	/**
		If true, reuses the iterator object instead of allocating a new one when calling ``iterator()``.
		
		The default is false.
		
		<warn>If true, nested iterations are likely to fail as only one iteration is allowed at a time.</warn>
	**/
	public var reuseIterator:Bool;
	
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
	var mSlotCount:Int;
	
	var mCapacity:Int;
	var mSize:Int;
	var mSizeLevel:Int;
	var mIsResizable:Bool;
	var mIterator:IntHashSetIterator;
	
	/**
		<assert>`slotCount` is not a power of two</assert>
		<assert>`capacity` is not a power of two</assert>
		<assert>`capacity` is < 2</assert>
		@param slotCount the total number of slots into which the hashed elements are distributed.
		This defines the space-time trade off of the set.
		Increasing the `slotCount` reduces the computation time (read/write/access) of the set at the cost of increased memory use.
		This value is fixed and can only be changed by calling ``rehash()``, which rebuilds the set (expensive).
		
		@param capacity the initial physical space for storing the elements at the time the set is created.
		This is also the minimum allowed size of the set and cannot be changed in the future.
		If omitted, the initial `capacity` equals `slotCount`.
		The `capacity` is automatically adjusted according to the storage requirements based on two rules:
		<ul>
		<li>If the set runs out of space, the `capacity` is doubled (if `isResizable` is true).</li>
		<li>If the ``size()`` falls below a quarter of the current `capacity`, the `capacity` is cut in half while the minimum `capacity` can't fall below `capacity`.</li>
		</ul>
		
		@param isResizable if false, the hash set is created with a fixed size.
		Thus adding an element when ``size()`` equals `capacity` throws an error.
		Otherwise the `capacity` is automatically adjusted.
		Default is true.
		
		@param maxSize the maximum allowed size of this hash set.
		The default value of -1 indicates that there is no upper limit.
	**/
	public function new(slotCount:Int, capacity = -1, isResizable = true, maxSize = -1)
	{
		if (slotCount == M.INT16_MIN) return;
		assert(slotCount > 0);
		
		assert(M.isPow2(slotCount), "slotCount is not a power of 2");
		
		mIsResizable = isResizable;
		
		if (capacity == -1)
			capacity = slotCount;
		else
		{
			assert(capacity >= 2, "minimum capacity is 2");
			assert(M.isPow2(slotCount), "capacity is not a power of 2");
		}
		
		mFree = 0;
		mCapacity = capacity;
		mSize = 0;
		mSlotCount = slotCount;
		mMask = slotCount - 1;
		
		mSizeLevel = 0;
		mIterator = null;
		
		#if debug
		this.maxSize = (maxSize == -1) ? M.INT32_MAX : maxSize;
		#else
		this.maxSize = -1;
		#end
		
		#if alchemy
		mHash = new IntMemory(slotCount, "IntHashSet.mHash");
		mHash.fill(EMPTY_SLOT);
		mData = new IntMemory(mCapacity << 1, "IntHashSet.mData");
		mNext = new IntMemory(mCapacity, "IntHashSet.mNext");
		#else
		mHash = new Vector<Int>(slotCount);
		for (i in 0...slotCount) mHash[i] = EMPTY_SLOT;
		mData = new Vector<Int>(mCapacity << 1);
		mNext = new Vector<Int>(mCapacity);
		#end
		
		var j = 1;
		for (i in 0...capacity)
		{
			setData(j - 1, VAL_ABSENT);
			setData(j, NULL_POINTER);
			j += 2;
		}
		
		for (i in 0...mCapacity - 1) setNext(i, i + 1);
		setNext(mCapacity - 1, NULL_POINTER);
		
		key = HashKey.next();
		reuseIterator = false;
	}
	
	/**
		The load factor measure the "denseness" of a hash set and is proportional to the time cost to look up an entry.
		
		E.g. assuming that the elements are perfectly distributed, a load factor of 4.0 indicates that each slot stores 4 elements, which have to be sequentially searched in order to find an element.
		
		A high load factor thus indicates poor performance.
		
		If the load factor gets too high, additional slots can be allocated by calling ``rehash()``.
	**/
	inline public function getLoadFactor():Float
	{
		return size() / getSlotCount();
	}
	
	/**
		The total number of allocated slots.
	**/
	inline public function getSlotCount():Int
	{
		return mSlotCount;
	}
	
	/**
		The size of the allocated storage space for the elements.
		
		If more space is required to accomodate new elements, ``getCapacity()`` is doubled every time ``size()`` grows beyond capacity and split in half when ``size()`` is a quarter of capacity.
		
		The capacity never falls below the initial size defined in the constructor.
	**/
	inline public function getCapacity():Int
	{
		return mCapacity;
	}
	
	/**
		Counts the total number of collisions.
		
		A collision occurs when two distinct elements are hashed into the same slot.
		<o>n</o>
	**/
	public function getCollisionCount():Int
	{
		var c = 0, j;
		for (i in 0...getSlotCount())
		{
			j = getHash(i);
			if (j == EMPTY_SLOT) continue;
			j = getData(j + 1);
			while (j != NULL_POINTER)
			{
				j = getData(j + 1);
				c++;
			}
		}
		return c;
	}
	
	/**
		Returns true if this set contains the element `x`.
		
		Uses move-to-front-on-access which reduces access time when similar elements are frequently queried.
		<o>1</o>
		<assert>value 0x80000000 is reserved</assert>
	**/
	inline public function hasFront(x:Int):Bool
	{
		assert(x != VAL_ABSENT, "value 0x80000000 is reserved");
		
		var b = hashCode(x);
		var i = getHash(b);
		if (i == EMPTY_SLOT)
			return false;
		else
		{
			#if (flash && alchemy)
			var o = mData.getAddr(i);
			if (Memory.getI32(o) == x)
				return true;
			#else
			if (getData(i) == x)
				return true;
			#end
			else
			{
				var exists = false;
				
				var first = i, i0 = first;
				
				#if (flash && alchemy)
				i = Memory.getI32(o + 4);
				#else
				i = getData(i + 1);
				#end
				
				while (i != NULL_POINTER)
				{
					#if (flash && alchemy)
					o = mData.getAddr(i);
					if (Memory.getI32(o) == x)
					#else
					if (getData(i) == x)
					#end
					{
						#if (flash && alchemy)
						var o1 = mData.getAddr(i0 + 1);
						Memory.setI32(o1, Memory.getI32(o + 4));
						Memory.setI32(o + 4, first);
						setHash(b, i);
						#else
						setData(i0 + 1, getData(i + 1));
						setData(i + 1, first);
						setHash(b, i);
						#end
						
						exists = true;
						break;
					}
					i = getData((i0 = i) + 1);
				}
				return exists;
			}
		}
	}
	
	/**
		Redistributes all elements over `slotCount`.
		
		This is an expensive operations as the set is rebuild from scratch.
		<o>n</o>
		<assert>`slotCount` is not a power of two</assert>
	**/
	public function rehash(slotCount:Int)
	{
		assert(M.isPow2(slotCount), "slotCount is not a power of 2");
		
		if (slotCount == getSlotCount()) return;
		
		var tmp = new IntHashSet(slotCount, mCapacity);
		
		#if (flash && alchemy)
		var o = mData.getAddr(0);
		for (i in 0...mCapacity)
		{
			var v = Memory.getI32(o);
			if (v != VAL_ABSENT) tmp.set(v);
			o += 8;
		}
		#else
		for (i in 0...mCapacity)
		{
			var v = getData(i << 1);
			if (v != VAL_ABSENT) tmp.set(v);
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
		
		mSlotCount = slotCount;
		mMask = tmp.mMask;
		mFree = tmp.mFree;
		mSizeLevel = tmp.mSizeLevel;
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
		var s = Printf.format("{ IntHashSet size/capacity: %d/%d, load factor: %.2f }", [size(), mCapacity, getLoadFactor()]);
		if (isEmpty()) return s;
		s += "\n[\n";
		for (x in this)
		{
			s += '  $x\n';
		}
		s += "]";
		return s;
	}
	
	/*///////////////////////////////////////////////////////
	// set
	///////////////////////////////////////////////////////*/
	
	/**
		Returns true if this set contains the element `x`.
		<o>1</o>
		<assert>value 0x80000000 is reserved</assert>
	**/
	inline public function has(x:Int):Bool
	{
		assert(x != VAL_ABSENT, "value 0x80000000 is reserved");
		
		var i = getHash(hashCode(x));
		if (i == EMPTY_SLOT)
			return false;
		else
		{
			#if (flash && alchemy)
			var o = mData.getAddr(i);
			if (Memory.getI32(o) == x)
				return true;
			#else
			if (getData(i) == x)
				return true;
			#end
			else
			{
				var exists = false;
				#if (flash && alchemy)
				i = Memory.getI32(o + 4);
				while (i != NULL_POINTER)
				{
					o = mData.getAddr(i);
					if (Memory.getI32(o) == x)
					{
						exists = true;
						break;
					}
					i = Memory.getI32(o + 4);
				}
				#else
				i = getData(i + 1);
				while (i != NULL_POINTER)
				{
					if (getData(i) == x)
					{
						exists = true;
						break;
					}
					i = getData(i + 1);
				}
				#end
				return exists;
			}
		}
	}
	
	/**
		Adds the element `x` to this set if possible.
		<o>1</o>
		<assert>value 0x80000000 is reserved</assert>
		<assert>``size()`` equals ``maxSize``</assert>
		<assert>hash set is full (if not resizable)</assert>
		@return true if `x` was added to this set, false if `x` already exists.
	**/
	public function set(x:Int):Bool
	{
		assert(x != VAL_ABSENT, "value 0x80000000 is reserved");
		assert(size() < maxSize, 'size equals max size ($maxSize)');
		
		var b = hashCode(x);
		
		#if (flash && alchemy)
		var o = mHash.getAddr(b);
		var j = Memory.getI32(o);
		#else
		var j = getHash(b);
		#end
		if (j == EMPTY_SLOT)
		{
			if (mSize == mCapacity)
			{
				#if debug
				if (!mIsResizable)
					assert(false, 'hash set is full ($mCapacity)');
				#end
				
				expand();
			}
			
			var i = mFree << 1;
			mFree = getNext(mFree);
			
			#if (flash && alchemy)
			Memory.setI32(o, i);
			#else
			setHash(b, i);
			#end
			
			setData(i, x);
			
			mSize++;
			return true;
		}
		else
		{
			#if (flash && alchemy)
			o = mData.getAddr(j);
			if (Memory.getI32(o) == x)
				return false;
			#else
			if (getData(j) == x)
				return false;
			#end
			else
			{
				#if (flash && alchemy)
				var t = Memory.getI32(o + 4);
				while (t != NULL_POINTER)
				{
					o = mData.getAddr(t);
					if (Memory.getI32(o) == x)
					{
						j = -1;
						break;
					}
					
					j = t;
					t = Memory.getI32(o + 4);
				}
				#else
				var t = getData(j + 1);
				while (t != NULL_POINTER)
				{
					if (getData(t) == x)
					{
						j = -1;
						break;
					}
					
					j = t;
					t = getData(t + 1);
				}
				#end
				
				if (j == -1)
					return false;
				else
				{
					if (mSize == mCapacity)
					{
						if (!mIsResizable)
							throw 'hash set is full ($mCapacity)';
						expand();
					}
					var i = mFree << 1;
					mFree = getNext(mFree);
					setData(i, x);
					
					setData(j + 1, i);
					mSize++;
					return true;
				}
			}
		}
	}
	
	/*///////////////////////////////////////////////////////
	// collection
	///////////////////////////////////////////////////////*/
	
	/**
		Destroys this object by explicitly nullifying all elements.
		
		Improves GC efficiency/performance (optional).
		<o>n</o>
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
		mIterator = null;
	}
	
	/**
		Same as ``has()``.
		<o>1</o>
	**/
	inline public function contains(x:Int):Bool
	{
		return has(x);
	}
	
	/**
		Removes the element `x`.
		<o>1</o>
		@return true if `x` was successfully removed, false if `x` does not exist.
	**/
	inline public function remove(x:Int):Bool
	{
		var b = hashCode(x);
		var i = getHash(b);
		if (i == EMPTY_SLOT)
			return false;
		else
		{
			#if (flash && alchemy)
			var o = mData.getAddr(i);
			if (x == Memory.getI32(o))
			#else
			if (x == getData(i))
			#end
			{
				#if (flash && alchemy)
				if (Memory.getI32(o + 4) == NULL_POINTER)
				#else
				if (getData(i + 1) == NULL_POINTER)
				#end
					setHash(b, EMPTY_SLOT);
				else
					setHash(b, getData(i + 1));
				
				var j = i >> 1;
				setNext(j, mFree);
				mFree = j;
				
				#if (flash && alchemy)
				Memory.setI32(o    , VAL_ABSENT);
				Memory.setI32(o + 4, NULL_POINTER);
				#else
				setData(i    , VAL_ABSENT);
				setData(i + 1, NULL_POINTER);
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
				i = Memory.getI32(o + 4);
				#else
				i = getData(i + 1);
				#end
				
				while (i != NULL_POINTER)
				{
					#if (flash && alchemy)
					o = mData.getAddr(i);
					if (Memory.getI32(o) == x)
					{
						exists = true;
						break;
					}
					i0 = i;
					i = Memory.getI32(o + 4);
					#else
					if (getData(i) == x)
					{
						exists = true;
						break;
					}
					i = getData((i0 = i) + 1);
					#end
				}
				
				if (exists)
				{
					setData(i0 + 1, getData(i + 1));
					
					var j = i >> 1;
					setNext(j, mFree);
					mFree = j;
					
					#if (flash && alchemy)
					o = mData.getAddr(i);
					Memory.setI32(o    , VAL_ABSENT);
					Memory.setI32(o + 4, NULL_POINTER);
					#else
					setData(i    , VAL_ABSENT);
					setData(i + 1, NULL_POINTER);
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
		The total number of elements.
		<o>1</o>
	**/
	inline public function size():Int
	{
		return mSize;
	}
	
	/**
		Removes all elements.
		<o>n</o>
		@param purge If true, the hash set shrinks to the initial capacity defined in the constructor.
	**/
	public function clear(purge = false)
	{
		if (purge && mSizeLevel > 0)
		{
			mCapacity >>= mSizeLevel;
			mSizeLevel = 0;
			
			#if alchemy
			mData.resize(mCapacity << 1);
			mNext.resize(mCapacity);
			#else
			mData = new Vector<Int>(mCapacity << 1);
			mNext = new Vector<Int>(mCapacity);
			#end
		}
		
		#if alchemy
		mHash.fill(EMPTY_SLOT);
		#else
		for (i in 0...getSlotCount()) mHash[i] = EMPTY_SLOT;
		#end
		
		var j = 1;
		for (i in 0...mCapacity)
		{
			setData(j - 1, VAL_ABSENT);
			setData(j, NULL_POINTER);
			j += 2;
		}
		for (i in 0...mCapacity - 1) setNext(i, i + 1);
		setNext(mCapacity - 1, NULL_POINTER);
		
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
		<o>1</o>
	**/
	inline public function isEmpty():Bool
	{
		return mSize == 0;
	}
	
	/**
		Returns an unordered array containing all elements in this set.
	**/
	public function toArray():Array<Int>
	{
		var a:Array<Int> = ArrayUtil.alloc(size());
		var j = 0;
		for (i in 0...mCapacity)
		{
			var v = getData(i << 1);
			if (v != VAL_ABSENT) a[j++] = v;
		}
		return a;
	}
	
	/**
		Returns an unordered `Vector<T>` object containing all elements in this set.
	**/
	public function toVector():Vector<Int>
	{
		var v = new Vector<Int>(size());
		var j = 0;
		for (i in 0...mCapacity)
		{
			var val = getData(i << 1);
			if (val != VAL_ABSENT) v[j++] = val;
		}
		return v;
	}
	
	/**
		Duplicates this hash set by creating a deep copy.
		
		The `assign` and `copier` parameters are ignored.
	**/
	public function clone(assign = true, copier:Int->Int = null):Collection<Int>
	{
		var c = new IntHashSet(M.INT16_MIN);
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
		c.mSlotCount = mSlotCount;
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
		mData.resize(newSize << 1);
		#else
		var copy = new Vector<Int>(newSize);
		for (i in 0...oldSize) copy[i] = mNext[i];
		mNext = copy;
		var copy = new Vector<Int>(newSize << 1);
		for (i in 0...oldSize << 1) copy[i] = mData[i];
		mData = copy;
		#end
		
		for (i in oldSize - 1...newSize - 1) setNext(i, i + 1);
		setNext(newSize - 1, NULL_POINTER);
		mFree = oldSize;
		
		var j = (oldSize << 1) + 1;
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
			
			j += 2;
		}
	}
	
	function shrink()
	{
		mSizeLevel--;
		
		var oldSize = mCapacity;
		var newSize = oldSize >> 1;
		mCapacity = newSize;
		
		#if (flash && alchemy)
		mData.resize((oldSize + (newSize >> 1)) << 1);
		
		var offset = oldSize << 1;
		var e = offset;
		
		var dst, src;
		dst = mData.getAddr(e);
		
		for (i in 0...getSlotCount())
		{
			var j = getHash(i);
			if (j == EMPTY_SLOT) continue;
			
			setHash(i, e - offset);
			
			flash.Memory.setI32(dst    , getData(j));
			flash.Memory.setI32(dst + 4, NULL_POINTER);
			dst += 8;
			
			e += 2;
			j = getData(j + 1);
			while (j != NULL_POINTER)
			{
				flash.Memory.setI32(dst - 4, e - offset);
				flash.Memory.setI32(dst    , getData(j));
				flash.Memory.setI32(dst + 4, NULL_POINTER);
				dst += 8;
				
				e += 2;
				j = getData(j + 1);
			}
		}
		
		var k = (newSize >> 1) << 1;
		
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
		k = mData.getAddr(newSize << 1);
		while (dst < k)
		{
			flash.Memory.setI32(dst    , VAL_ABSENT);
			flash.Memory.setI32(dst + 4, NULL_POINTER);
			dst += 8;
		}
		
		mData.resize(newSize << 1);
		mNext.resize(newSize);
		#else
		var k = newSize << 1;
		var tmp = new Vector<Int>(k);
		mNext = new Vector<Int>(newSize);
		
		var e = 0;
		for (i in 0...getSlotCount())
		{
			var j = getHash(i);
			if (j == EMPTY_SLOT) continue;
			
			setHash(i, e);
			
			tmp[e++] = getData(j);
			tmp[e++] = NULL_POINTER;
			
			j = getData(j + 1);
			while (j != NULL_POINTER)
			{
				tmp[e - 1] = e;
				tmp[e++] = getData(j    );
				tmp[e++] = NULL_POINTER;
				j = getData(j + 1);
			}
		}
		var i = k >> 1;
		while (i < k)
		{
			tmp[i++] = VAL_ABSENT;
			tmp[i++] = NULL_POINTER;
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
		#else
		return mHash[i];
		#end
	}
	inline function setHash(i:Int, x:Int)
	{
		#if (flash && alchemy)
		mHash.set(i, x);
		#else
		mHash[i] = x;
		#end
	}
	
	inline function getNext(i:Int)
	{
		#if (flash && alchemy)
		return mNext.get(i);
		#else
		return mNext[i];
		#end
	}
	inline function setNext(i:Int, x:Int)
	{
		#if (flash && alchemy)
		mNext.set(i, x);
		#else
		mNext[i] = x;
		#end
	}
	
	inline function getData(i:Int)
	{
		#if (flash && alchemy)
		return mData.get(i);
		#else
		return mData[i];
		#end
	}
	inline function setData(i:Int, x:Int)
	{
		#if (flash && alchemy)
		mData.set(i, x);
		#else
		mData[i] = x;
		#end
	}
}

@:access(de.polygonal.ds.IntHashSet)
@:dox(hide)
class IntHashSetIterator implements de.polygonal.ds.Itr<Int>
{
	var mF:IntHashSet;
	var mI:Int;
	var mS:Int;
	
	#if alchemy
	var mData:IntMemory;
	#else
	var mData:Vector<Int>;
	#end
	
	public function new(hash:IntHashSet)
	{
		mF = hash;
		mData = mF.mData;
		mI = 0;
		mS = mF.mCapacity;
		scan();
	}
	
	public function reset():Itr<Int>
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
		var x = getData((mI++ << 1));
		scan();
		return x;
	}
	
	inline public function remove()
	{
		throw "unsupported operation";
	}
	
	inline function scan()
	{
		while ((mI < mS) && (getData((mI << 1)) == IntHashSet.VAL_ABSENT)) mI++;
	}
	
	inline function getData(i:Int)
	{
		#if (flash && alchemy)
		return mData.get(i);
		#else
		return mData[i];
		#end
	}
}