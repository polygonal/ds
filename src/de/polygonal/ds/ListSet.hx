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

import de.polygonal.ds.tools.Assert.assert;
import de.polygonal.ds.tools.GrowthRate;
import de.polygonal.ds.tools.M;

using de.polygonal.ds.tools.NativeArrayTools;

/**
	A simple set using an array
	
	Example:
		var o = new de.polygonal.ds.ListSet<String>();
		o.set("a");
		o.set("b");
		o.set("b");
		o.set("c");
		o.set("c");
		o.set("c");
		trace(o); //outputs:
		
		[ ListSet size=3
		  a
		  b
		  c
		]
**/
#if generic
@:generic
#end
class ListSet<T> implements Set<T>
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
	public var growthRate:Int = GrowthRate.NORMAL;
	
	/**
		If true, reuses the iterator object instead of allocating a new one when calling `this.iterator()`.
		
		The default is false.
		
		_If this value is true, nested iterations will fail as only one iteration is allowed at a time._
	**/
	public var reuseIterator:Bool = false;
	
	var mData:NativeArray<T>;
	var mInitialCapacity:Int;
	var mSize:Int = 0;
	var mIterator:ListSetIterator<T> = null;
	
	public function new(initialCapacity:Null<Int> = 16, ?source:Array<T>)
	{
		mInitialCapacity = M.max(1, initialCapacity);
		capacity = mInitialCapacity;
		if (source != null) capacity = source.length;
		mData = NativeArrayTools.alloc(capacity);
		if (source != null) for (i in source) set(i);
	}
	
	/**
		Preallocates storage for `n` elements.
		
		May cause a reallocation, but has no effect on `this.size` and its elements.
		Useful before inserting a large number of elements as this reduces the amount of incremental reallocation.
	**/
	public function reserve(n:Int):ListSet<T>
	{
		if (n > capacity)
		{
			capacity = n;
			resizeContainer(n);
		}
		return this;
	}
	
	/**
		Reduces the capacity of the internal container to the initial capacity.
		
		May cause a reallocation, but has no effect on `this.size` and its elements.
		An application can use this operation to free up memory by unlocking resources for the garbage collector.
	**/
	public function pack():ListSet<T>
	{
		if (capacity > mInitialCapacity)
		{
			capacity = M.max(mInitialCapacity, mSize);
			resizeContainer(capacity);
		}
		else
		{
			var d = mData;
			for (i in mSize...capacity) d.set(i, cast null);
		}
		return this;
	}
	
	/**
		Calls 'f` on all elements in random order.
	**/
	public inline function iter(f:T->Void):ListSet<T>
	{
		assert(f != null);
		var d = mData;
		for (i in 0...size) f(d[i]);
		return this;
	}
	
	/**
		Prints out all elements.
	**/
	public function toString():String
	{
		#if no_tostring
		return Std.string(this);
		#else
		var b = new StringBuf();
		b.add('[ ListSet size=$size');
		if (isEmpty())
		{
			b.add(" ]");
			return b.toString();
		}
		b.add("\n");
		for (i in 0...size)
		{
			b.add("  ");
			b.add(Std.string(mData[i]));
			b.add("\n");
		}
		b.add("]");
		return b.toString();
		#end
	}
	
	/* INTERFACE Set */
	
	/**
		Returns true if this set contains `val`.
	**/
	public function has(val:T):Bool
	{
		if (isEmpty()) return false;
		var d = mData;
		for (i in 0...size) if (d.get(i) == val) return true;
		return false;
	}
	
	/**
		Adds `val` to this set if possible.
		@return true if `val` was added to this set, false if `val` already exists.
	**/
	public function set(val:T):Bool
	{
		var d = mData;
		for (i in 0...size) if (d.get(i) == val) return false;
		if (size == capacity)
		{
			grow();
			d = mData;
		}
		d.set(mSize++, val);
		return true;
	}
	
	/**
		Removes `val` from this set if possible.
		@return true if `val` was removed from this set, false if `val` does not exist.
	**/
	public inline function unset(val:T):Bool
	{
		return remove(val);
	}
	
	/**
		Adds all elements of the set `other` to this set.
		@param assign if true, the `copier` parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.
		If false, the `this.clone()` method is called on each element.
		</br>_In this case all elements have to implement `Cloneable`._
		@param copier a custom function for copying elements. Replaces `element.clone()` if `assign` is false.
	**/
	public function merge(set:Set<T>, ?assign:Bool, copier:T->T = null)
	{
		if (assign)
		{
			for (val in set) this.set(val);
		}
		else
		{
			if (copier != null)
			{
				for (val in set)
					this.set(copier(val));
			}
			else
			{
				for (val in set)
				{
					assert(Std.is(val, Cloneable), "element is not of type Cloneable");
					
					this.set(cast(val, Cloneable<Dynamic>).clone());
				}
			}
		}
		
	}
	
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
		mData.nullify();
		mData = null;
		if (mIterator != null)
		{
			mIterator.free();
			mIterator = null;
		}
	}
	
	/**
		Same as `this.has()`.
	**/
	public function contains(val:T):Bool
	{
		return has(val);
	}
	
	/**
		Removes `val`.
		@return true if `val` was successfully removed.
	**/
	public function remove(val:T):Bool
	{
		var d = mData;
		for (i in 0...size)
			if (d.get(i) == val)
			{
				d.set(i, mData.get(--mSize));
				return true;
			}
		return false;
	}
	
	/**
		Removes all elements.
		@param gc if true, nullifies references upon removal so the garbage collector can reclaim used memory.
	**/
	public function clear(gc:Bool = false)
	{
		if (gc) mData.nullify();
		mSize = 0;
	}
	
	/**
		Iterates over all elements contained in this set.
		
		The elements are visited in a random order.
		
		@see http://haxe.org/ref/iterators
	**/
	public function iterator():Itr<T>
	{
		if (reuseIterator)
		{
			if (mIterator == null)
				mIterator = new ListSetIterator<T>(this);
			else
				mIterator.reset();
			return mIterator;
		}
		else
			return new ListSetIterator<T>(this);
	}
	
	/**
		Returns true only if `this.size` is 0.
	**/
	public function isEmpty():Bool
	{
		return size == 0;
	}
	
	/**
		Returns an unordered array containing all elements in this set.
	**/
	public function toArray():Array<T>
	{
		return mData.toArray(0, size, []);
	}
	
	/**
		Creates and returns a shallow copy (structure only - default) or deep copy (structure & elements) of this set.
		
		If `byRef` is true, primitive elements are copied by value whereas objects are copied by reference.
		
		If `byRef` is false, the `copier` function is used for copying elements. If omitted, `clone()` is called on each element assuming all elements implement `Cloneable`.
	**/
	public function clone(byRef:Bool = true, copier:T->T = null):Collection<T>
	{
		var out = new ListSet<T>();
		out.capacity = size;
		out.mSize = size;
		out.mData = NativeArrayTools.alloc(size);
		
		var src = mData;
		var dst = out.mData;
		
		if (byRef)
			src.blit(0, dst, 0, size);
		else
		if (copier == null)
		{
			for (i in 0...size)
			{
				assert(Std.is(src.get(i), Cloneable), "element is not of type Cloneable");
				
				dst.set(i, cast(src.get(i), Cloneable<Dynamic>).clone());
			}
		}
		else
		{
			for (i in 0...size)
				dst.set(i, copier(src.get(i)));
		}
		return cast out;
	}
	
	function grow()
	{
		capacity = GrowthRate.compute(growthRate, capacity);
		resizeContainer(capacity);
	}
	
	function resizeContainer(newSize:Int)
	{
		var t = NativeArrayTools.alloc(newSize);
		mData.blit(0, t, 0, mSize);
		mData = t;
	}
}

@:access(de.polygonal.ds.ListSet)
#if generic
@:generic
#end
@:dox(hide)
class ListSetIterator<T> implements de.polygonal.ds.Itr<T>
{
	var mObject:ListSet<T>;
	var mData:NativeArray<T>;
	var mI:Int;
	var mS:Int;
	
	public function new(x:ListSet<T>)
	{
		mObject = x;
		reset();
	}
	
	public function free()
	{
		mObject = null;
		mData = null;
	}
	
	public inline function reset():Itr<T>
	{
		mData = mObject.mData;
		mS = mObject.size;
		mI = 0;
		return this;
	}
	
	public inline function hasNext():Bool
	{
		return mI < mS;
	}
	
	public inline function next():T
	{
		return mData.get(mI++);
	}
	
	public function remove()
	{
		assert(mI > 0, "call next() before removing an element");
		
		mData.set(mI, mData.get(--mS));
	}
}