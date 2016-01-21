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

/**
	A simple set using an array
	
	_<o>Worst-case running time in Big O notation</o>_
**/
class ListSet<T> implements Set<T>
{
	/**
		A unique identifier for this object.
		
		A hash table transforms this key into an index of an array element by using a hash function.
		
		<warn>This value should never be changed by the user.</warn>
	**/
	public var key:Int;
	
	/**
		If true, reuses the iterator object instead of allocating a new one when calling ``iterator()``.
		
		The default is false.
		
		<warn>If true, nested iterations are likely to fail as only one iteration is allowed at a time.</warn>
	**/
	public var reuseIterator:Bool;
	
	var mData:Array<T>;
	var mSize:Int;
	var mIterator:ListSetIterator<T>;
	
	public function new()
	{
		mData = new Array<T>();
		mSize = 0;
		key = HashKey.next();
		reuseIterator = false;
	}
	
	/**
		Returns a string representing the current object.
		
		Example:
		<pre class="prettyprint">
		var set = new de.polygonal.ds.ListSet<String>();
		set.set("val1");
		set.set("val2");
		trace(set);</pre>
		<pre class="console">
		{ ListSet size: 2 }
		[
		  val1
		  val2
		]</pre>
	**/
	public function toString():String
	{
		var s = '{ ListSet size: ${size()} }';
		if (isEmpty()) return s;
		s += "\n[\n";
		for (i in 0...size())
			s += '  ${Std.string(mData[i])}\n';
		s += "]";
		return s;
	}
	
	/*///////////////////////////////////////////////////////
	// set
	///////////////////////////////////////////////////////*/
	
	/**
		Returns true if this set contains the element `x`.
		<o>n</o>
	**/
	public function has(x:T):Bool
	{
		if (mSize == 0) return false;
		for (i in mData) if (i == x) return true;
		
		return false;
	}
	
	/**
		Adds the element `x` to this set if possible.
		<o>n</o>
		@return true if `x` was added to this set, false if `x` already exists.
	**/
	public function set(x:T):Bool
	{
		for (i in 0...mSize) if (mData[i] == x) return false;
		
		mData.push(x);
		mSize++;
		
		return true;
	}
	
	/**
		Adds all elements of the set `x` to this set.
		<o>n</o>
		<assert>element is not of type `Cloneable`</assert>
		@param assign if true, the `copier` parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.
		If false, the ``clone()`` method is called on each element. <warn>In this case all elements have to implement `Cloneable`.</warn>
		@param copier a custom function for copying elements. Replaces ``element::clone()`` if `assign` is false.
	**/
	public function merge(x:Set<T>, ?assign:Bool, copier:T->T = null)
	{
		if (assign)
		{
			for (val in x) set(val);
		}
		else
		{
			if (copier != null)
			{
				for (val in x)
					set(copier(val));
			}
			else
			{
				for (val in x)
				{
					assert(Std.is(val, Cloneable), 'element is not of type Cloneable ($val)');
					
					var c:Cloneable<T> = cast val;
					set(c.clone());
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
		for (i in 0...mData.length) mData[i] = null;
		mIterator = null;
		mData = null;
	}
	
	/**
		Same as ``has()``.
		<o>n</o>
	**/
	public function contains(x:T):Bool
	{
		for (i in 0...mSize) if (mData[i] == x) return true;
		
		return false;
	}
	
	/**
		Removes the element `x`.
		<o>n</o>
		@return true if `x` was successfully removed.
	**/
	public function remove(x:T):Bool
	{
		for (i in 0...mSize)
		{
			if (mData[i] == x)
			{
				mData[i] = mData[--mSize];
				return true;
			}
		}
		
		return false;
	}
	
	/**
		Removes all elements.
		<o>1 or n if `purge` is true</o>
		@param purge if true, nullifies references upon removal.
	**/
	public function clear(purge = false)
	{
		mSize = 0;
		if (purge) mData = [];
	}
	
	/**
		Iterates over all elements contained in this set.
		
		The elements are visited in a random order.
		
		See <a href="http://haxe.org/ref/iterators" target="mBlank">http://haxe.org/ref/iterators</a>
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
		Returns true if this set is empty.
		<o>1</o>
	**/
	public function isEmpty():Bool
	{
		return mSize == 0;
	}
	
	/**
		The total number of elements.
		<o>1</o>
	**/
	public function size():Int
	{
		return mSize;
	}
	
	/**
		Returns an unordered array containing all elements in this set.
	**/
	public function toArray():Array<T>
	{
		var output = [];
		var t = mData;
		for (i in 0...mSize) output[i] = t[i];
		
		return output;
	}
	
	/**
		Returns a `Vector<T>` object containing all elements in this set.
	**/
	public function toVector():Vector<T>
	{
		var output = new Vector<T>(mSize);
		var t = mData;
		for (i in 0...mSize) output[i] = t[i];
		
		return output;
	}
	
	/**
		Duplicates this set. Supports shallow (structure only) and deep copies (structure & elements).
		<assert>element is not of type `Cloneable`</assert>
		@param assign if true, the `copier` parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.
		If false, the ``clone()`` method is called on each element. <warn>In this case all elements have to implement `Cloneable`.</warn>
		@param copier a custom function for copying elements. Replaces ``element::clone()`` if `assign` is false.
	**/
	public function clone(assign = true, copier:T->T = null):Collection<T>
	{
		var copy = new ListSet<T>();
		copy.mSize = mSize;
		if (assign)
		{
			for (i in 0...mSize)
			{
				copy.mData[i] = mData[i];
			}
		}
		else
		if (copier == null)
		{
			var c:Cloneable<Dynamic> = null;
			for (i in 0...mSize)
			{
				assert(Std.is(mData[i], Cloneable), 'element is not of type Cloneable (${mData[i]})');
				
				copy.mData[i] = cast(mData[i], Cloneable<Dynamic>).clone();
			}
		}
		else
		{
			for (i in 0...mSize)
				copy.mData[i] = copier(mData[i]);
		}
		
		return copy;
	}
}

@:access(de.polygonal.ds.ListSet)
#if generic
@:generic
#end
@:dox(hide)
class ListSetIterator<T> implements de.polygonal.ds.Itr<T>
{
	var mF:ListSet<T>;
	var mData:Array<T>;
	var mI:Int;
	var mS:Int;
	
	public function new(f:ListSet<T>)
	{
		mF = f;
		reset();
	}
	
	inline public function reset():Itr<T>
	{
		mData = mF.mData;
		mS = mF.mSize;
		mI = 0;
		return this;
	}
	
	inline public function hasNext():Bool
	{
		return mI < mS;
	}
	
	inline public function next():T
	{
		return mData[mI++];
	}
	
	inline public function remove()
	{
		assert(mI > 0, "call next() before removing an element");
		
		mData[mI] = mData[--mS];
	}
}