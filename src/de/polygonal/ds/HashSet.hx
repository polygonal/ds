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

#if alchemy
import de.polygonal.ds.mem.IntMemory;
#end

import de.polygonal.ds.error.Assert.assert;

/**
	An array hash set for storing Hashable objects
	
	_<o>Worst-case running time in Big O notation</o>_
**/
#if generic
@:generic
#end
class HashSet<T:Hashable> implements Set<T>
{
	/**
		A unique identifier for this object.
		
		A hash table transforms this key into an index of an array element by using a hash function.
		
		<warn>This value should never be changed by the user.</warn>
	**/
	public var key:Int;
	
	/**
		The maximum allowed size of this hash set.
		
		Once the maximum size is reached, adding an element to a array will fail with an error (debug only).
		
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
	
	var mH:IntIntHashTable;
	
	var mVals:Vector<T>;
	
	#if alchemy
	var mNext:IntMemory;
	#else
	var mNext:Vector<Int>;
	#end
	
	var mFree:Int;
	var mSizeLevel:Int;
	var mIsResizable:Bool;
	var mIterator:HashSetIterator<T>;
	
	/**
		<assert>`slotCount` is not a power of two</assert>
		<assert>`capacity` is not a power of two</assert>
		<assert>`capacity` is < 2</assert>
		@param slotCount the total number of slots into which the hashed values are distributed.
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
		
		if (capacity == -1) capacity = slotCount;
		
		mIsResizable = isResizable;
		
		mH = new IntIntHashTable(slotCount, capacity, mIsResizable, maxSize);
		mVals = new Vector<T>(capacity);
		
		#if debug
		this.maxSize = (maxSize == -1) ? M.INT32_MAX : maxSize;
		#else
		this.maxSize = -1;
		#end
		
		#if alchemy
		mNext = new IntMemory(capacity, "HashSet.mNext");
		#else
		mNext = new Vector<Int>(capacity);
		#end
		
		for (i in 0...capacity - 1) setNext(i, i + 1);
		setNext(capacity - 1, IntIntHashTable.NULL_POINTER);
		mFree = 0;
		mSizeLevel = 0;
		mIterator = null;
		
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
		return mH.getLoadFactor();
	}
	
	/**
		The current slot count.
	**/
	inline public function getSlotCount():Int
	{
		return mH.getSlotCount();
	}
	
	/**
		The size of the allocated storage space for the elements.
		
		If more space is required to accomodate new elements, ``getCapacity()`` is doubled every time ``size()`` grows beyond capacity, and split in half when ``size()`` is a quarter of capacity.
		
		The capacity never falls below the initial size defined in the constructor.
	**/
	inline public function getCapacity():Int
	{
		return mH.getCapacity();
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
		Returns true if this set contains the element `x`.
		
		Uses move-to-front-on-access which reduces access time when similar elements are frequently queried.
		<o>n</o>
		<assert>`x` is null</assert>
	**/
	inline public function hasFront(x:T):Bool
	{
		var i = mH.getFront(_key(x));
		return i != IntIntHashTable.KEY_ABSENT;
	}
	
	/**
		Redistributes all elements over `slotCount`.
		
		This is an expensive operations as the set is rebuild from scratch.
		<o>n</o>
		<assert>`slotCount` is not a power of two</assert>
	**/
	public function rehash(slotCount:Int)
	{
		mH.rehash(slotCount);
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
		    static function main()
		    {
		        var set = new de.polygonal.ds.HashSet<Foo>(16);
		        for (i in 0...4) set.set(new Foo(i));
		        trace(set);
		    }
		}</pre>
		<pre class="console">
		{ HashSet size/capacity: 4/16, load factor: 0.25 }
		[
		  { Foo value: 0 }
		  { Foo value: 1 }
		  { Foo value: 2 }
		  { Foo value: 3 }
		]</pre>
	**/
	public function toString():String
	{
		var s = Printf.format("{ HashSet size/capacity: %d/%d, load factor: %.2f }", [size(), getCapacity(), getLoadFactor()]);
		if (isEmpty()) return s;
		s += "\n[\n";
		for (x in this)
		{
			s += '  ${Std.string(x)}\n';
		}
		s += "]";
		return s;
	}
	
	/*///////////////////////////////////////////////////////
	// set
	///////////////////////////////////////////////////////*/
	
	/**
		Returns true if this set contains the element `x` or null if `x` does not exist.
		<o>n</o>
		<assert>`x` is null</assert>
	**/
	inline public function has(x:T):Bool
	{
		return mH.get(_key(x)) != IntIntHashTable.KEY_ABSENT;
	}
	
	/**
		Adds the element `x` to this set if possible.
		<o>n</o>
		<assert>`x` is null</assert>
		<assert>``size()`` equals ``maxSize``</assert>
		<assert>hash set is full (if not resizable)</assert>
		@return true if `x` was added to this set, false if `x` already exists.
	**/
	inline public function set(x:T):Bool
	{
		assert(size() != maxSize, 'size equals max size ($maxSize)');
		
		if ((size() == getCapacity()))
		{
			if (mH.setIfAbsent(_key(x), size()))
			{
				#if debug
				if (!mIsResizable)
					assert(false, 'hash set is full (${getCapacity()})');
				#end
				
				expand(getCapacity() >> 1);
				mVals[mFree] = x;
				mFree = getNext(mFree);
				return true;
			}
			else
				return false;
		}
		else
		{
			if (mH.setIfAbsent(_key(x), mFree))
			{
				mVals[mFree] = x;
				mFree = getNext(mFree);
				return true;
			}
			else
				return false;
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
		for (i in 0...size())
			mVals[i] = null;
		mVals = null;
		
		#if alchemy
		mNext.free();
		#end
		mNext = null;
		
		mH.free();
		mH = null;
		mIterator = null;
	}
	
	/**
		Same as ``has()``.
		<o>n</o>
		<assert>`x` is null</assert>
	**/
	public function contains(x:T):Bool
	{
		return has(x);
	}
	
	/**
		Removes the element `x`.
		<o>n</o>
		<assert>`x` is null</assert>
		@return true if `x` was successfully removed, false if `x` does not exist.
	**/
	public function remove(x:T):Bool
	{
		var i = mH.get(_key(x));
		if (i == IntIntHashTable.KEY_ABSENT)
			return false;
		else
		{
			mVals[i] = null;
			setNext(i, mFree);
			mFree = i;
			
			var doShrink = false;
			
			if (mSizeLevel > 0)
				if (size() - 1 == (getCapacity() >> 2))
					if (mIsResizable)
						doShrink = true;
			
			mH.clr(_key(x));
			
			if (doShrink) shrink();
			
			return true;
		}
	}
	
	/**
		The total number of elements.
		<o>1</o>
	**/
	public function size():Int
	{
		return mH.size();
	}
	
	/**
		Removes all elements.
		<o>n</o>
		@param purge if true, nullifies references upon removal and shrinks the hash set to the initial capacity defined in the constructor.
	**/
	public function clear(purge = false)
	{
		mH.clear(purge);
		for (i in 0...getCapacity()) mVals[i] = null;
		
		if (purge)
		{
			while (mSizeLevel > 0) shrink();
			
			for (i in 0...getCapacity())
				mVals[i] = null;
		}
		
		for (i in 0...getCapacity() - 1) setNext(i, i + 1);
		setNext(getCapacity() - 1, IntIntHashTable.NULL_POINTER);
		mFree = 0;
	}
	
	/**
		Returns a new `HashSetIterator` object to iterate over all elements contained in this hash set.
		
		The elements are visited in a random order.
		
		See <a href="http://haxe.org/ref/iterators" target="mBlank">http://haxe.org/ref/iterators</a>
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
		Returns true if the set is empty.
		<o>1</o>
	**/
	inline public function isEmpty():Bool
	{
		return mH.isEmpty();
	}
	
	/**
		Returns an unordered array containing all elements in this set.
	**/
	public function toArray():Array<T>
	{
		var a:Array<T> = ArrayUtil.alloc(size());
		var j = 0;
		for (i in 0...getCapacity())
		{
			var v = mVals[i];
			if (v != null) a[j++] = v;
		}
		return a;
	}
	
	/**
		Returns a `Vector<T>` object containing all elements in this set.
	**/
	public function toVector():Vector<T>
	{
		var v = new Vector<T>(size());
		var j = 0;
		var t = mVals;
		for (i in 0...getCapacity())
		{
			var val = t[i];
			if (val != null) v[j++] = val;
		}
		return v;
	}
	
	/**
		Duplicates this hash set. Supports shallow (structure only) and deep copies (structure & elements).
		@param assign if true, the `copier` parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.
		If false, the ``clone()`` method is called on each element. <warn>In this case all elements have to implement `Cloneable`.</warn>
		@param copier a custom function for copying elements. Replaces ``element::clone()`` if `assign` is false.
		<assert>element is not of type `Cloneable`</assert>
	**/
	public function clone(assign = true, copier:T->T = null):Collection<T>
	{
		var c = new HashSet<T>(M.INT16_MIN);
		
		c.mIsResizable = mIsResizable;
		c.maxSize = maxSize;
		c.key = HashKey.next();
		c.mH = cast mH.clone(false);
		
		var capacity = getCapacity();
		
		if (assign)
		{
			c.mVals = new Vector<T>(capacity);
			for (i in 0...capacity) c.mVals[i] = mVals[i];
		}
		else
		{
			var tmp = new Vector<T>(capacity);
			if (copier != null)
			{
				for (i in 0...getCapacity())
				{
					var v = mVals[i];
					if (v != null) tmp[i] = copier(v);
				}
			}
			else
			{
				var c:Cloneable<T> = null;
				for (i in 0...getCapacity())
				{
					var v = mVals[i];
					if (v != null)
					{
						assert(Std.is(v, Cloneable), 'element is not of type Cloneable ($v)');
						
						c = cast v;
						tmp[i] = c.clone();
					}
				}
			}
			c.mVals = tmp;
		}
		
		c.mSizeLevel = mSizeLevel;
		c.mFree = mFree;
		
		#if alchemy
		c.mNext = mNext.clone();
		#else
		c.mNext = new Vector<Int>(mNext.length);
		for (i in 0...Std.int(mNext.length)) c.mNext[i] = mNext[i];
		#end
		
		return c;
	}
	
	inline function expand(oldSize:Int)
	{
		var newSize = oldSize << 1;
		
		#if alchemy
		mNext.resize(newSize);
		#else
		var tmp = new Vector<Int>(newSize);
		for (i in 0...oldSize) tmp[i] = mNext[i];
		mNext = tmp;
		#end
		
		for (i in oldSize - 1...newSize - 1) setNext(i, i + 1);
		setNext(newSize - 1, IntIntHashTable.NULL_POINTER);
		mFree = oldSize;
		
		var tmp = new Vector<T>(newSize);
		for (i in 0...oldSize) tmp[i] = mVals[i];
		mVals = tmp;
		
		mSizeLevel++;
	}
	
	inline function shrink()
	{
		mSizeLevel--;
		
		var oldSize = getCapacity() << 1;
		var newSize = getCapacity();
		
		#if alchemy
		mNext.resize(newSize);
		#else
		mNext = new Vector<Int>(newSize);
		#end
		
		for (i in 0...newSize - 1) setNext(i, i + 1);
		setNext(newSize - 1, IntIntHashTable.NULL_POINTER);
		mFree = 0;
		
		var tmpVals = new Vector<T>(newSize);
		
		for (i in mH)
		{
			tmpVals[mFree] = mVals[i];
			mFree = getNext(mFree);
		}
		
		mVals = tmpVals;
		
		for (i in 0...mFree)
			mH.remap(_key(mVals[i]), i);
	}
	
	inline function getNext(i:Int)
	{
		#if alchemy
		return mNext.get(i);
		#else
		return mNext[i];
		#end
	}
	inline function setNext(i:Int, x:Int)
	{
		#if alchemy
		mNext.set(i, x);
		#else
		mNext[i] = x;
		#end
	}
	
	inline function _key(x:Hashable)
	{
		assert(x != null, "element is null");
		
		return x.key;
	}
}

#if generic
@:generic
#end
@:access(de.polygonal.ds.HashSet)
@:dox(hide)
class HashSetIterator<T:Hashable> implements de.polygonal.ds.Itr<T>
{
	var mF:HashSet<T>;
	var mVals:Vector<T>;
	var mI:Int;
	var mS:Int;
	
	public function new(f:HashSet<T>)
	{
		mF = f;
		reset();
	}
	
	public function reset():Itr<T>
	{
		mVals = mF.mVals;
		mI = 0;
		mS = mF.mH.getCapacity();
		while (mI < mS && mVals[mI] == null) mI++;
		
		return this;
	}
	
	inline public function hasNext():Bool
	{
		return mI < mS;
	}
	
	inline public function next():T
	{
		var v = mVals[mI];
		while (++mI < mS && mVals[mI] == null) {}
		
		return v;
	}
	
	inline public function remove()
	{
		throw "unsupported operation";
	}
}