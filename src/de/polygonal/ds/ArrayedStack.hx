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

import de.polygonal.ds.tools.ArrayTools;
import de.polygonal.ds.tools.Assert.assert;
import de.polygonal.ds.tools.GrowthRate;
import de.polygonal.ds.tools.M;

using de.polygonal.ds.tools.NativeArrayTools;

/**
	A dynamic arrayed stack
	
	A stack is a linear list for which all insertions and deletions (and usually all accesses) are made at one end of the list.
	
	This is called a LIFO structure (Last In, First Out).
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
	public var key(default, null):Int = HashKey.next();
	
	/**
		The capacity of the internal container.
		
		The capacity is usually a bit larger than `size` (_mild overallocation_).
	**/
	public var capacity(default, null):Int;
	
	/**
		The growth rate of the container.
		
		+  0: fixed size
		+ -1: grows at a rate of 1.125x plus a constant.
		+ -2: grows at a rate of 1.5x (default value).
		+ -3: grows at a rate of 2.0x.
		+ >0: grows at a constant rate: capacity += growthRate
	**/
	public var growthRate:Int = GrowthRate.NORMAL;
	
	/**
		If true, reuses the iterator object instead of allocating a new one when calling ``iterator()``.
		
		The default is false.
		
		<warn>If true, nested iterations are likely to fail as only one iteration is allowed at a time.</warn>
	**/
	public var reuseIterator:Bool = false;
	
	var mData:NativeArray<T>;
	var mInitialCapacity:Int;
	var mTop:Int = 0;
	var mIterator:ArrayedStackIterator<T> = null;
	
	/**
		<assert>`initialCapacity` is greater than allowed size</assert>
		<assert>`initialCapacity` is below minimum capacity of 16</assert>
		@param initialCapacity the initial capacity of the internal container. This is also the minimum internal stack size. See ``reserve()``.
	**/
	public function new(initialCapacity:Null<Int> = 16, ?source:Array<T>)
	{
		mInitialCapacity = M.max(1, initialCapacity);
		capacity = mInitialCapacity;
		
		if (source != null)
		{
			mTop = source.length;
			capacity = M.max(mTop, capacity);
		}
		
		mData = NativeArrayTools.alloc(capacity);
		
		if (source != null)
		{
			var d = mData;
			for (i in 0...mTop) d.set(i, source[i]);
		}
	}
	
	/**
		For performance reasons the stack does nothing to ensure that empty locations contain null;
		``pack()`` therefore nullifies all obsolete references and shrinks the array to the actual size allowing the garbage collector to reclaim used memory.
	**/
	public function pack()
	{
		if (capacity > mInitialCapacity)
		{
			capacity = M.max(size, mInitialCapacity);
			resizeContainer(capacity);
		}
		else
		{
			var d = mData;
			for (i in size...capacity) d.set(i, cast null);
		}
	}
	
	/**
		Preallocates storage for `n` elements.
		
		May cause a reallocation, but has no effect on the vector size and its elements.
		Useful before inserting a large number of elements as this reduces the amount of incremental reallocation.
	**/
	public function reserve(n:Int):ArrayedStack<T>
	{
		if (n > capacity)
		{
			capacity = n;
			resizeContainer(n);
		}
		return this;
	}
	
	/**
		Returns the top element of this stack.
		
		This is the "newest" element.
		<assert>stack is empty</assert>
	**/
	public inline function top():T
	{
		assert(mTop > 0, "stack is empty");
		
		return mData.get(mTop - 1);
	}
	
	/**
		Pushes the element `x` onto the stack.
	**/
	public inline function push(x:T)
	{
		if (size == capacity) grow();
		mData.set(mTop++, x);
	}
	
	/**
		Pops data off the stack.
		<assert>stack is empty</assert>
		@return the top element.
	**/
	public inline function pop():T
	{
		assert(mTop > 0, "stack is empty");
		
		return mData.get(--mTop);
	}
	
	/**
		Pops the top element of the stack, and pushes it back twice, so that an additional copy of the former top item is now on top, with the original below it.
		<assert>stack is empty</assert>
	**/
	#if (!cpp) inline #end //TODO inlining gives wrong results in cpp
	public function dup()
	{
		assert(mTop > 0, "stack is empty");
		
		if (size == capacity) grow();
		var d = mData;
		d.set(mTop, d.get(mTop - 1));
		mTop++;
	}
	
	/**
		Swaps the two topmost items on the stack.
		<assert>``size`` < 2</assert>
	**/
	#if (!cpp) inline #end //TODO fixme
	public function exchange()
	{
		assert(mTop > 1, "size < 2");
		
		var i = mTop - 1;
		var j = i - 1;
		var d = mData;
		var t = d.get(i);
		d.set(i, d.get(j));
		d.set(j, t);
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
		<assert>``size`` >= `n`</assert>
	**/
	public function rotRight(n:Int)
	{
		assert(mTop >= n, "size < n");
		
		var i = mTop - n;
		var k = mTop - 1;
		var d = mData;
		var t = d.get(i);
		while (i < k)
		{
			d.set(i, d.get(i + 1));
			i++;
		}
		d.set(mTop - 1, t);
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
		<assert>``size`` >= `n`</assert>
	**/
	public function rotLeft(n:Int)
	{
		assert(mTop >= n, "size < n");
		
		var i = mTop - 1;
		var k = mTop - n;
		var d = mData;
		var t = d.get(i);
		while (i > k)
		{
			d.set(i, d.get(i - 1));
			i--;
		}
		d.set(mTop - n, t);
	}
	
	/**
		Returns the element stored at index `i`.
		
		An index of 0 indicates the bottommost element.
		
		An index of ``size`` - 1 indicates the topmost element.
		<assert>stack is empty or `i` out of range</assert>
	**/
	public inline function get(i:Int):T
	{
		assert(mTop > 0, "stack is empty");
		assert(i >= 0 && i < mTop, 'i index out of range ($i)');
		
		return mData.get(i);
	}
	
	/**
		Replaces the element at index `i` with the element `x`.
		
		An index of 0 indicates the bottommost element.
		
		An index of ``size`` - 1 indicates the topmost element.
		<assert>stack is empty or `i` out of range</assert>
	**/
	public inline function set(i:Int, x:T)
	{
		assert(mTop > 0, "stack is empty");
		assert(i >= 0 && i < mTop, 'i index out of range ($i)');
		
		mData.set(i, x);
	}
	
	/**
		Swaps the element stored at `i` with the element stored at index `j`.
		
		An index of 0 indicates the bottommost element.
		
		An index of ``size`` - 1 indicates the topmost element.
		<assert>stack is empty</assert>
		<assert>`i`/`j` out of range</assert>
		<assert>`i` equals `j`</assert>
	**/
	#if (!cpp) inline #end //TODO inlining gives wrong results in cpp
	public function swap(i:Int, j:Int)
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
		
		An index of ``size`` - 1 indicates the topmost element.
		<assert>stack is empty</assert>
		<assert>`i`/`j` out of range</assert>
		<assert>`i` equals `j`</assert>
	**/
	#if (!cpp) inline #end //TODO inlining gives wrong results in cpp
	public function copy(i:Int, j:Int)
	{
		assert(mTop > 0, "stack is empty");
		assert(i >= 0 && i < mTop, 'i index out of range ($i)');
		assert(j >= 0 && j < mTop, 'j index out of range ($j)');
		assert(i != j, 'i index equals j index ($i)');
		
		var d = mData;
		d.set(i, d.get(j));
	}
	
	/**
		Calls the `f` function on all elements.
		
		The function signature is: `f(element, index):element`
		<assert>`f` is null</assert>
	**/
	public function forEach(f:T->Int->T):ArrayedStack<T>
	{
		var d = mData;
		for (i in 0...mTop) d.set(i, f(d.get(i), i));
		return this;
	}
	
	/**
		Shuffles the elements of this collection by using the Fisher-Yates algorithm.
		<assert>insufficient random values</assert>
		@param rvals a list of random double values in the range between 0 (inclusive) to 1 (exclusive) defining the new positions of the elements.
		If omitted, random values are generated on-the-fly by calling `Math::random()`.
	**/
	public function shuffle(rvals:Array<Float> = null)
	{
		var s = mTop, d = mData;
		if (rvals == null)
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
			assert(rvals.length >= size, "insufficient random values");
			
			var j = 0, i, t;
			while (s > 1)
			{
				i = Std.int(rvals[j++] * (--s));
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
		var b = new StringBuf();
		b.add('{ ArrayedStack size/capacity: ${size}/${capacity} }');
		if (isEmpty()) return b.toString();
		b.add("\n[ top\n");
		var i = mTop - 1;
		var j = mTop - 1;
		var d = mData, args = new Array<Dynamic>();
		var fmt = '  %${M.numDigits(size)}d: %s\n';
		while (i >= 0)
		{
			args[0] = j--;
			args[1] = Std.string(d.get(i--));
			b.add(Printf.format(fmt, args));
		}
		b.add("]");
		return b.toString();
	}
	
	/* INTERFACE Collection */
	
	/**
		The total number of elements.
	**/
	public var size(get, never):Int;
	inline function get_size():Int
	{
		return mTop;
	}
	
	/**
		Destroys this object by explicitly nullifying all elements for GC'ing used resources.
		
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
		Returns true if this stack contains the element `x`.
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
		
		@param gc if true, elements are nullified upon removal so the garbage collector can reclaim used memory.
	**/
	public function clear(gc:Bool = false)
	{
		if (gc) mData.nullify();
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
	**/
	public inline function isEmpty():Bool
	{
		return mTop == 0;
	}
	
	/**
		Returns an array containing all elements in this stack.
		
		Preserves the natural order of this stack (First-In-Last-Out).
	**/
	public function toArray():Array<T>
	{
		if (isEmpty()) return [];
		
		var out = ArrayTools.alloc(size);
		var i = mTop, j = 0, d = mData;
		while (i > 0) out[j++] = d.get(--i);
		return out;
	}

	/**
		Duplicates this stack. Supports shallow (structure only) and deep copies (structure & elements).
		<assert>element is not of type `Cloneable`</assert>
		@param assign if true, the `copier` parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.
		If false, the ``clone()`` method is called on each element. <warn>In this case all elements have to implement `Cloneable`.</warn>
		@param copier a custom function for copying elements. Replaces ``element::clone()`` if `assign` is false.
	**/
	public function clone(assign:Bool = true, copier:T->T = null):Collection<T>
	{
		var c = new ArrayedStack<T>(capacity);
		
		if (isEmpty()) return c;
		
		c.mTop = mTop;
		var src = mData;
		var dst = c.mData;
		if (assign)
			src.blit(0, dst, 0, size);
		else
		{
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
		}
		return c;
	}
	
	function grow()
	{
		capacity = GrowthRate.compute(growthRate, capacity);
		resizeContainer(capacity);
	}
	
	function resizeContainer(newSize:Int)
	{
		var t = NativeArrayTools.alloc(newSize);
		mData.blit(0, t, 0, size);
		mData = t;
	}
}

#if generic
@:generic
#end
@:access(de.polygonal.ds.ArrayedStack)
@:dox(hide)
class ArrayedStackIterator<T> implements de.polygonal.ds.Itr<T>
{
	var mObject:ArrayedStack<T>;
	var mData:NativeArray<T>;
	var mI:Int;
	
	public function new(x:ArrayedStack<T>)
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
		mI = mObject.mTop - 1;
		return this;
	}
	
	public inline function hasNext():Bool
	{
		return mI >= 0;
	}
	
	public inline function next():T
	{
		return mData.get(mI--);
	}
	
	public function remove()
	{
		assert(mI != (mObject.mTop - 1), "call next() before removing an element");
		
		var i = mI + 1;
		var top = mObject.mTop - 1;
		if (i == top)
			mObject.mTop = top;
		else
		{
			while (i < top) mData.set(i++, mData.get(i));
			mObject.mTop = top;
		}
	}
}