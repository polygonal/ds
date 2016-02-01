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

using de.polygonal.ds.tools.NativeArray;

/**
	A dynamic arrayed stack
	
	A stack is a linear list for which all insertions and deletions (and usually all accesses) are made at one end of the list.
	
	This is called a LIFO structure (Last In, First Out).
	
	_<o>Worst-case running time in Big O notation</o>_
**/
#if generic
@:generic
#end
class ArrayedStack<T> implements Stack<T>
{
	/**
		A unique identifier for this object.
		
		A hash table transforms this key into an index of an array element by using a hash function.
		
		<warn>This value should never be changed by the user.</warn>
	**/
	public var key:Int;
	
	/**
		The maximum allowed size of this stack.
		
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
	
	public var capacity(default, null):Int;
	
	
	var mData:Container<T>;
	var mInitialCapacity:Int;
	
	
	var mCapacityIncrement:Int;
	
	var mShrinkSize:Int;
	var mShrinkCapacity:Int;
	var mTop:Int;
	var mIterator:ArrayedStackIterator<T>;
	
	#if debug
	var mOp0:Int;
	var mOp1:Int;
	#end
	
	/**
		<assert>`initialCapacity` is greater than allowed size</assert>
		<assert>`initialCapacity` is below minimum capacity of 16</assert>
		@param initialCapacity the initial capacity of the internal container. This is also the minimum internal stack size. See ``reserve()``.
		@param maxSize the maximum allowed size of this stack.
		The default value of -1 indicates that there is no upper limit.
	**/
	public function new(initialCapacity:Int = 64, capacityIncrement:Int = -1, maxSize = -1)
	{
		#if debug
		if (maxSize != -1) assert(maxSize > 0, "invalid maxSize");
		#end
		//assert(initialCapacity >= 16, "initial capacity below minimum capacity (16)");
		
		capacity = mInitialCapacity = initialCapacity;
		mShrinkCapacity = capacity >> 2;
		mCapacityIncrement = capacityIncrement;
		
		mData = NativeArray.init(capacity);
		
		mTop = 0;
		mIterator = null;
		key = HashKey.next();
		reuseIterator = false;
		
		#if debug
		this.maxSize = (maxSize == -1) ? M.INT32_MAX : maxSize;
		#else
		this.maxSize = -1;
		#end
		
		#if debug
		mOp0 = 0;
		mOp1 = 0;
		#end
	}
	
	/**
		For performance reasons the stack does nothing to ensure that empty locations contain null;
		``pack()`` therefore nullifies all obsolete references and shrinks the array to the actual size allowing the garbage collector to reclaim used memory.
		<o>n</o>
	**/
	public function pack()
	{
		//if (mData.length == size()) return;
		//
		//trace('pack()!');
		//
		//trace('capacity $mCapacity initialCapacity $mInitialCapacity');
		//
		//while (mCapacity >> 1 > mTop)
		//{
			//trace('shrink to from $mCapacity to ${mCapacity >> 1}');
			//mCapacity >>= 1;
		//}
		//
		//trace(mCapacity);
		
		//var tmp = VectorUtil.alloc(mCapacity);
		//VectorUtil.blit(mData, 0, tmp, 0, mCapacity);
		//mData = tmp;
		//throw 1;
	}
	/**
		Nullifies the last popped off element so it can be instantly garbage collected.
		
		<warn>Use only directly after ``pop()``.</warn>
		<o>1</o>
		<assert>`pop()` wasn't directly called after ``dequeue()``</assert>
	**/
	inline public function dispose()
	{
		assert(mTop > 0, "stack is empty");
		assert(mOp0 == mOp1, "dispose() is only allowed directly after pop()");
		
		mData.set(mTop, cast null);
	}
	
	/**
		Preallocates internal space for storing `x` elements.
		
		This is useful if the expected size is known in advance.
		<o>n</o>
	**/
	public function reserve(x:Int):ArrayedStack<T>
	{
		if (size() == x) return this;
		
		var tmp = NativeArray.init(x);
		NativeArray.blit(mData, 0, tmp, 0, capacity);
		mData = tmp;
		
		capacity = x;
		mShrinkCapacity = capacity >> 2;
		
		return this;
	}
	
	/**
		Returns the top element of this stack.
		
		This is the "newest" element.
		<o>1</o>
		<assert>stack is empty</assert>
	**/
	inline public function top():T
	{
		assert(mTop > 0, "stack is empty");
		
		return mData.get(mTop - 1);
	}
	
	/**
		Pushes the element `x` onto the stack.
		<o>1</o>
		<assert>``size()`` equals ``maxSize``</assert>
	**/
	inline public function push(x:T)
	{
		#if debug
		if (maxSize != -1)
			assert(size() < maxSize, 'size equals max size ($maxSize)');
		++mOp1;
		#end
		
		if (size() == capacity) grow();
		mData.set(mTop++, x);
	}
	
	/**
		Pops data off the stack.
		<o>1</o>
		<assert>stack is empty</assert>
		@return the top element.
	**/
	inline public function pop():T
	{
		assert(mTop > 0, "stack is empty");
		
		#if debug
		mOp0 = ++mOp1;
		#end
		
		return mData.get(--mTop);
	}
	
	/**
		Pops the top element of the stack, and pushes it back twice, so that an additional copy of the former top item is now on top, with the original below it.
		<o>1</o>
		<assert>stack is empty</assert>
		<assert>``size()`` equals ``maxSize``</assert>
	**/
	inline public function dup()
	{
		assert(mTop > 0, "stack is empty");
		
		#if debug
		if (maxSize != -1)
			assert(size() < maxSize, 'size equals max size ($maxSize)');
		#end
		
		if (size() == capacity) grow();
		var d = mData;
		d.set(mTop, d.get(mTop - 1));
		mTop++;
	}
	
	/**
		Swaps the two topmost items on the stack.
		<o>1</o>
		<assert>``size()`` < 2</assert>
	**/
	inline public function exchange()
	{
		assert(mTop > 1, "size() < 2");
		
		var i = mTop - 1;
		var j = i - 1;
		var d = mData;
		var tmp = d.get(i);
		d.set(i, d.get(j));
		d.set(j, tmp);
	}
	
	/**
		Moves the `n` topmost elements on the stack in a rotating fashion.
		
		Example:
		<pre>
		top
		|3|               |0|
		|2|  rotate right |3|
		|1|      -->      |2|
		|0|               |1|</pre>
		<o>n</o>
		<assert>``size()`` >= `n`</assert>
	**/
	public function rotRight(n:Int)
	{
		assert(mTop >= n, "size() < n");
		
		var i = mTop - n;
		var k = mTop - 1;
		var d = mData;
		var tmp = d.get(i);
		while (i < k)
		{
			d.set(i, d.get(i + 1));
			i++;
		}
		d.set(mTop - 1, tmp);
	}
	
	/**
		Moves the `n` topmost elements on the stack in a rotating fashion.
		
		Example:
		<pre>
		top
		|3|              |2|
		|2|  rotate left |1|
		|1|      -->     |0|
		|0|              |3|</pre>
		<o>n</o>
		<assert>``size()`` >= `n`</assert>
	**/
	public function rotLeft(n:Int)
	{
		assert(mTop >= n, "size() < n");
		
		var i = mTop - 1;
		var k = mTop - n;
		var d = mData;
		var tmp = d.get(i);
		while (i > k)
		{
			d.set(i, d.get(i - 1));
			i--;
		}
		d.set(mTop - n, tmp);
	}
	
	/**
		Returns the element stored at index `i`.
		
		An index of 0 indicates the bottommost element.
		
		An index of ``size()`` - 1 indicates the topmost element.
		<o>1</o>
		<assert>stack is empty or `i` out of range</assert>
	**/
	inline public function get(i:Int):T
	{
		assert(mTop > 0, "stack is empty");
		assert(i >= 0 && i < mTop, 'i index out of range ($i)');
		
		return mData.get(i);
	}
	
	/**
		Replaces the element at index `i` with the element `x`.
		
		An index of 0 indicates the bottommost element.
		
		An index of ``size()`` - 1 indicates the topmost element.
		<o>1</o>
		<assert>stack is empty or `i` out of range</assert>
	**/
	inline public function set(i:Int, x:T)
	{
		assert(mTop > 0, "stack is empty");
		assert(i >= 0 && i < mTop, 'i index out of range ($i)');
		
		mData.set(i, x);
	}
	
	/**
		Swaps the element stored at `i` with the element stored at index `j`.
		
		An index of 0 indicates the bottommost element.
		
		An index of ``size()`` - 1 indicates the topmost element.
		<o>1</o>
		<assert>stack is empty</assert>
		<assert>`i`/`j` out of range</assert>
		<assert>`i` equals `j`</assert>
	**/
	inline public function swp(i:Int, j:Int)
	{
		assert(mTop > 0, "stack is empty");
		assert(i >= 0 && i < mTop, 'i index out of range ($i)');
		assert(j >= 0 && j < mTop, 'j index out of range ($j)');
		assert(i != j, 'i index equals j index ($i)');
		
		var d = mData;
		var t = d.get(i);
		d.set(i, d.get(j));
		d.set(j, t);
	}
	
	/**
		Overwrites the element at index `i` with the element from index `j`.
		
		An index of 0 indicates the bottommost element.
		
		An index of ``size()`` - 1 indicates the topmost element.
		<o>1</o>
		<assert>stack is empty</assert>
		<assert>`i`/`j` out of range</assert>
		<assert>`i` equals `j`</assert>
	**/
	inline public function cpy(i:Int, j:Int)
	{
		assert(mTop > 0, "stack is empty");
		assert(i >= 0 && i < mTop, 'i index out of range ($i)');
		assert(j >= 0 && j < mTop, 'j index out of range ($j)');
		assert(i != j, 'i index equals j index ($i)');
		
		var d = mData;
		d.set(i, d.get(j));
	}
	
	/**
		Replaces up to `n` existing elements with objects of type `cl`.
		<o>n</o>
		<assert>`n` out of range</assert>
		@param cl the class to instantiate for each element.
		@param args passes additional constructor arguments to the class `cl`.
		@param n the number of elements to replace. If 0, `n` is set to ``size()``.
	**/
	public function assign(cl:Class<T>, args:Array<Dynamic> = null, n = 0)
	{
		assert(n >= 0);
		
		if (n > 0)
		{
			#if debug
			if (maxSize != -1)
				assert(n <= maxSize, 'n out of range ($n)');
			#end
		}
		else
			n = size();
		
		if (args == null) args = [];
		for (i in 0...n) mData.set(i, Type.createInstance(cl, args));
		
		mTop = n;
	}
	
	/**
		Replaces up to `n` existing elements with the instance `x`.
		<o>n</o>
		<assert>`n` out of range</assert>
		@param n the number of elements to replace. If 0, `n` is set to ``size()``.
	**/
	public function fill(x:T, n = 0):ArrayedStack<T>
	{
		assert(n >= 0);
		
		if (n > 0)
		{
			#if debug
			if (maxSize != -1)
				assert(n <= maxSize, 'n out of range ($n)');
			#end
		}
		else
			n = size();
		
		for (i in 0...n)
			mData.set(i, x);
		
		mTop = n;
		return this;
	}
	
	/**
		Invokes the `process` function for each element.
		
		The function signature is: ``process(oldValue, index):newValue``
		<o>n</o>
	**/
	public function iter(process:T->Int->T)
	{
		var d = mData;
		for (i in 0...mTop) d.set(i, process(d.get(i), i));
	}
	
	/**
		Shuffles the elements of this collection by using the Fisher-Yates algorithm.
		<o>n</o>
		<assert>insufficient random values</assert>
		@param rval a list of random double values in the range between 0 (inclusive) to 1 (exclusive) defining the new positions of the elements.
		If omitted, random values are generated on-the-fly by calling `Math::random()`.
	**/
	public function shuffle(rval:Array<Float> = null)
	{
		var s = mTop, d = mData;
		if (rval == null)
		{
			var m = Math, i, t;
			while (s > 1)
			{
				i = Std.int(m.random() * (--s));
				t = d.get(s);
				d.set(s, d.get(i));
				d.set(i, t);
			}
		}
		else
		{
			assert(rval.length >= size(), "insufficient random values");
			
			var j = 0, i, t;
			while (s > 1)
			{
				i = Std.int(rval[j++] * (--s));
				t = d.get(s);
				d.set(s, d.get(i));
				d.set(i, t);
			}
		}
	}
	
	/**
		Returns a string representing the current object.
		
		Example:
		<pre class="prettyprint">
		var stack = new de.polygonal.ds.ArrayedStack<Int>(4);
		for (i in 0...4) {
		    stack.push(i);
		}
		trace(stack);</pre>
		<pre class="console">
		{ ArrayedStack size/max: 4/4 }
		[ top
		  3 -> 3
		  2 -> 2
		  1 -> 1
		  0 -> 0
		]</pre>
	**/
	public function toString():String
	{
		var s = '{ ArrayedStack size: ${size()} }';
		if (isEmpty()) return s;
		s += "\n[ top\n";
		var i = mTop - 1;
		var j = mTop - 1;
		var d = mData;
		while (i >= 0) s += Printf.format("  %4d -> %s\n", [j--, Std.string(d.get(i--))]);
		s += "]";
		return s;
	}
	
	/*///////////////////////////////////////////////////////
	// collection
	///////////////////////////////////////////////////////*/
	
	/**
		Destroys this object by explicitly nullifying all elements for GC'ing used resources.
		
		Improves GC efficiency/performance (optional).
		<o>n</o>
	**/
	public function free()
	{
		//for (i in 0...mData.length) d.set(i, cast null);
		mData = null;
		mIterator = null;
	}
	
	/**
		Returns true if this stack contains the element `x`.
		<o>n</o>
	**/
	public function contains(x:T):Bool
	{
		var d = mData;
		for (i in 0...mTop)
		{
			if (d.get(i) == x)
				return true;
		}
		return false;
	}
	
	/**
		Removes and nullifies all occurrences of the element `x`.
		<o>n</o>
		@return true if at least one occurrence of `x` was removed.
	**/
	public function remove(x:T):Bool
	{
		if (isEmpty()) return false;
		
		var found = false, t = mTop, d = mData;
		while (t > 0)
		{
			found = false;
			for (i in 0...t)
			{
				if (d.get(i) == x)
				{
					var j = t - 1;
					var p = i;
					while (p < j) d.set(p++, d.get(p));
					d.set(--t, cast null);
					found = true;
					break;
				}
			}
			
			if (!found) break;
		}
		
		mTop = t;
		
		return found;
	}
	
	/**
		Removes all elements.
		<o>1 or n if `purge` is true</o>
		@param purge if true, elements are nullified upon removal.
	**/
	public function clear(purge = false)
	{
		if (purge)
		{
			var d = mData;
			for (i in 0...NativeArray.size(mData))
				d.set(i, cast null);
		}
		mTop = 0;
	}
	
	/**
		Returns a new `ArrayedStackIterator` object to iterate over all elements contained in this stack.
		
		Preserves the natural order of a stack (First-In-Last-Out).
		
		See <a href="http://haxe.org/ref/iterators" target="mBlank">http://haxe.org/ref/iterators</a>
	**/
	public function iterator():Itr<T>
	{
		if (reuseIterator)
		{
			if (mIterator == null)
				mIterator = new ArrayedStackIterator<T>(this);
			else
				mIterator.reset();
			return mIterator;
		}
		else
			return new ArrayedStackIterator<T>(this);
	}
	
	/**
		Returns true if this stack is empty.
		<o>1</o>
	**/
	inline public function isEmpty():Bool
	{
		return mTop == 0;
	}
	
	/**
		The total number of elements.
		<o>1</o>
	**/
	inline public function size():Int
	{
		return mTop;
	}
	
	/**
		Returns an array containing all elements in this stack.
		
		Preserves the natural order of this stack (First-In-Last-Out).
	**/
	public function toArray():Array<T>
	{
		var a:Array<T> = ArrayUtil.alloc(size());
		var i = mTop, j = 0, d = mData;
		while (i > 0) a[j++] = d.get(--i);
		return a;
	}
	
	/**
		Returns a `Vector<T>` object containing all elements in this stack.
		
		Preserves the natural order of this stack (First-In-Last-Out).
	**/
	public function toVector():Container<T>
	{
		var v = NativeArray.init(size());
		var i = mTop, j = 0, d = mData;
		while (i > 0) v[j++] = d.get(--i);
		return v;
	}

	/**
		Duplicates this stack. Supports shallow (structure only) and deep copies (structure & elements).
		<assert>element is not of type `Cloneable`</assert>
		@param assign if true, the `copier` parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.
		If false, the ``clone()`` method is called on each element. <warn>In this case all elements have to implement `Cloneable`.</warn>
		@param copier a custom function for copying elements. Replaces ``element::clone()`` if `assign` is false.
	**/
	public function clone(assign = true, copier:T->T = null):Collection<T>
	{
		var c = new ArrayedStack<T>(capacity, mCapacityIncrement, maxSize);
		
		if (isEmpty()) return c;
		
		c.mTop = mTop;
		
		if (assign)
			mData.blit(0, c.mData, 0, size());
		else
		{
			var src = mData;
			var dst = c.mData;
			
			if (copier == null)
			{
				var e:Cloneable<Dynamic> = null;
				var d:Dynamic; //required for -cpp
				
				for (i in 0...size())
				{
					assert(Std.is(src.get(i), Cloneable), 'element is not of type Cloneable (${src.get(i)})');
					
					d = src.get(i);
					e = cast d;
					dst.set(i, e.clone());
				}
			}
			else
			{
				for (i in 0...size())
					dst.set(i, copier(src.get(i)));
			}
		}
		
		return c;
	}
	
	function shrink()
	{
		if (capacity <= 16) return;
		
		capacity >>= 1;
		mShrinkSize = capacity >> 2;
		resize(capacity);
	}
	
	function grow()
	{
		var tmp = capacity;
		
		capacity =
		if (mCapacityIncrement == -1)
		{
			if (true)
				Std.int((capacity * 3) / 2 + 1); //1.5
			else
				capacity + ((capacity >> 3) + (capacity < 9 ? 3 : 6)); //1.125
		}
		else
			capacity + mCapacityIncrement;
		
		mShrinkSize = capacity >> 2;
		
		resize(capacity);
	}
	
	function resize(newSize:Int)
	{
		var tmp = NativeArray.init(newSize);
		NativeArray.blit(mData, 0, tmp, 0, size());
		mData = tmp;
	}
}

#if generic
@:generic
#end
@:access(de.polygonal.ds.ArrayedStack)
@:dox(hide)
class ArrayedStackIterator<T> implements de.polygonal.ds.Itr<T>
{
	var mF:ArrayedStack<T>;
	var mData:Container<T>;
	var mI:Int;
	
	public function new(f:ArrayedStack<T>)
	{
		mF = f;
		reset();
	}
	
	inline public function reset():Itr<T>
	{
		mData = mF.mData;
		mI = mF.mTop - 1;
		return this;
	}
	
	inline public function hasNext():Bool
	{
		return mI >= 0;
	}
	
	inline public function next():T
	{
		return mData[mI--];
	}
	
	inline public function remove()
	{
		assert(mI != (mF.mTop - 1), "call next() before removing an element");
		
		var i = mI + 1;
		var top = mF.mTop - 1;
		if (i == top)
			mF.mTop = top;
		else
		{
			while (i < top)
				mData[i++] = mData[i];
			mF.mTop = top;
		}
	}
}