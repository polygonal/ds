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
 * <p>A dynamic arrayed stack.</p>
 * <p>A stack is a linear list for which all insertions and deletions (and usually all accesses) are made at one end of the list.</p>
 * <p>This is called a LIFO structure (Last In, First Out).</p>
 * <p><o>Worst-case running time in Big O notation</o></p>
 */
#if (flash && generic)
@:generic
#end
class ArrayedStack<T> implements Stack<T>
{
	/**
	 * A unique identifier for this object.<br/>
	 * A hash table transforms this key into an index of an array element by using a hash function.<br/>
	 * <warn>This value should never be changed by the user.</warn>
	 */
	public var key:Int;
	
	/**
	 * The maximum allowed size of this stack.<br/>
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
	
	var mData:Array<T>;
	var mTop:Int;
	var mIterator:ArrayedStackIterator<T>;
	
	#if debug
	var mOp0:Int;
	var mOp1:Int;
	#end
	
	/**
	 * @param reservedSize the initial capacity of the internal container. See <em>reserve()</em>.
	 * @param maxSize the maximum allowed size of this stack.<br/>
	 * The default value of -1 indicates that there is no upper limit.
	 * @throws de.polygonal.ds.error.AssertError reserved size is greater than allowed size (debug only).
	 */
	public function new(reservedSize = 0, maxSize = -1)
	{
		if (reservedSize > 0)
		{
			#if debug
			if (maxSize != -1)
				assert(reservedSize <= maxSize, "reserved size is greater than allowed size");
			#end
			mData = ArrayUtil.alloc(reservedSize);
		}
		else
			mData = new Array<T>();
		
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
	 * For performance reasons the stack does nothing to ensure that empty locations contain null.<br/>
	 * <em>pack()</em> therefore nullifies all obsolete references and shrinks the array to the actual size allowing the garbage collector to reclaim used memory.
	 * <o>n</o>
	 */
	public function pack()
	{
		if (mData.length == size()) return;
		
		var tmp = mData;
		mData = ArrayUtil.alloc(size());
		for (i in 0...size()) _set(i, tmp[i]);
		for (i in size()...tmp.length) tmp[i] = cast null;
	}
	
	/**
	 * Preallocates internal space for storing <code>x</code> elements.<br/>
	 * This is useful if the expected size is known in advance - many platforms can optimize memory usage if an exact size is specified.
	 * <o>n</o>
	 */
	public function reserve(x:Int)
	{
		if (size() == x) return;
		
		var tmp = mData;
		mData = ArrayUtil.alloc(x);
		
		if (size() < x)
		{
			for (i in 0...mTop)
				_set(i, tmp[i]);
		}
	}
	
	/**
	 * Returns the top element of this stack.<br/>
	 * This is the "newest" element.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError stack is empty (debug only).
	 */
	inline public function top():T
	{
		assert(mTop > 0, "stack is empty");
		
		return _get(mTop - 1);
	}
	
	/**
	 * Pushes the element <code>x</code> onto the stack.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError <em>size()</em> equals <em>maxSize</em> (debug only).
	 */
	inline public function push(x:T)
	{
		#if debug
		if (maxSize != -1)
			assert(size() < maxSize, 'size equals max size ($maxSize)');
		++mOp1;
		#end
		
		_set(mTop++, x);
	}
	
	/**
	 * Pops data off the stack.
	 * <o>1</o>
	 * @return the top element.
	 * @throws de.polygonal.ds.error.AssertError stack is empty (debug only).
	 */
	inline public function pop():T
	{
		assert(mTop > 0, "stack is empty");
		
		#if debug
		mOp0 = ++mOp1;
		#end
		
		return _get(--mTop);
	}
	
	inline public function popMany(n:Int):T
	{
		assert(mTop > 0, "stack is empty");
		
		#if debug
		mOp0 = ++mOp1;
		#end
		
		return _get(--mTop);
	}
	
	/**
	 * Pops the top element of the stack, and pushes it back twice, so that an additional copy of the former top item is now on top, with the original below it.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError stack is empty (debug only).
	 * @throws de.polygonal.ds.error.AssertError <em>size()</em> equals <em>maxSize</em> (debug only).
	 */
	inline public function dup()
	{
		assert(mTop > 0, "stack is empty");
		
		#if debug
		if (maxSize != -1)
			assert(size() < maxSize, 'size equals max size ($maxSize)');
		#end
		
		_set(mTop, _get(mTop - 1));
		mTop++;
	}
	
	/**
	 * Swaps the two topmost items on the stack.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError <em>size()</em> < 2 (debug only).
	 */
	inline public function exchange()
	{
		assert(mTop > 1, "size() < 2");
		
		var i = mTop - 1;
		var j = i - 1;
		var tmp = _get(i);
		_set(i, _get(j));
		_set(j, tmp);
	}
	
	/**
	 * Moves the <code>n</code> topmost elements on the stack in a rotating fashion.<br/>
	 * Example:
	 * <pre>
	 * top
	 * |3|               |0|
	 * |2|  rotate right |3|
	 * |1|      -->      |2|
	 * |0|               |1|</pre>
	 * <o>n</o>
	 * @throws de.polygonal.ds.error.AssertError <em>size()</em> >= <code>n</code> (debug only).
	 */
	public function rotRight(n:Int)
	{
		assert(mTop >= n, "size() < n");
		
		var i = mTop - n;
		var k = mTop - 1;
		var tmp = _get(i);
		while (i < k)
		{
			_set(i, _get(i + 1));
			i++;
		}
		_set(mTop - 1, tmp);
	}
	
	/**
	 * Moves the <code>n</code> topmost elements on the stack in a rotating fashion.<br/>
	 * Example:
	 * <pre>
	 * top
	 * |3|              |2|
	 * |2|  rotate left |1|
	 * |1|      -->     |0|
	 * |0|              |3|</pre>
	 * <o>n</o>
	 * @throws de.polygonal.ds.error.AssertError <em>size()</em> >= <code>n</code> (debug only).
	 */
	public function rotLeft(n:Int)
	{
		assert(mTop >= n, "size() < n");
		
		var i = mTop - 1;
		var k = mTop - n;
		var tmp = _get(i);
		while (i > k)
		{
			_set(i, _get(i - 1));
			i--;
		}
		_set(mTop - n, tmp);
	}
	
	/**
	 * Nullifies the last popped off element so it can be instantly garbage collected.<br/>
	 * <warn>Use only directly after <em>pop()</em>.</warn>
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError <em>pop()</em> wasn't directly called after <em>dequeue()</em>(debug only).
	 */
	inline public function dispose()
	{
		assert(mTop > 0, "stack is empty");
		assert(mOp0 == mOp1, "dispose() is only allowed directly after pop()");
		
		_set(mTop, cast null);
	}
	
	/**
	 * Returns the element stored at index <code>i</code>.<br/>
	 * An index of 0 indicates the bottommost element.<br/>
	 * An index of <em>size()</em> - 1 indicates the topmost element.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError stack is empty or index out of range (debug only).
	 */
	inline public function get(i:Int):T
	{
		assert(mTop > 0, "stack is empty");
		assert(i >= 0 && i < mTop, 'i index out of range ($i)');
		
		return _get(i);
	}
	
	/**
	 * Replaces the element at index <code>i</code> with the element <code>x</code>.<br/>
	 * An index of 0 indicates the bottommost element.<br/>
	 * An index of <em>size()</em> - 1 indicates the topmost element.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError stack is empty or index out of range (debug only).
	 */
	inline public function set(i:Int, x:T)
	{
		assert(mTop > 0, "stack is empty");
		assert(i >= 0 && i < mTop, 'i index out of range ($i)');
		
		_set(i, x);
	}
	
	/**
	 * Swaps the element stored at <code>i</code> with the element stored at index <code>j</code>.<br/>
	 * An index of 0 indicates the bottommost element.<br/>
	 * An index of <em>size()</em> - 1 indicates the topmost element.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError stack is empty. (debug only).
	 * @throws de.polygonal.ds.error.AssertError index out of range (debug only).
	 * @throws de.polygonal.ds.error.AssertError <code>i</code> equals <code>j</code> (debug only).
	 */
	inline public function swp(i:Int, j:Int)
	{
		assert(mTop > 0, "stack is empty");
		assert(i >= 0 && i < mTop, 'i index out of range ($i)');
		assert(j >= 0 && j < mTop, 'j index out of range ($j)');
		assert(i != j, 'i index equals j index ($i)');
		
		var t = _get(i);
		cpy(i, j);
		_set(j, t);
	}
	
	/**
	 * Overwrites the element at index <code>i</code> with the element from index <code>j</code>.<br/>
	 * An index of 0 indicates the bottommost element.<br/>
	 * An index of <em>size()</em> - 1 indicates the topmost element.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError stack is empty. (debug only).
	 * @throws de.polygonal.ds.error.AssertError index out of range (debug only).
	 * @throws de.polygonal.ds.error.AssertError <code>i</code> equals <code>j</code> (debug only).
	 */
	inline public function cpy(i:Int, j:Int)
	{
		assert(mTop > 0, "stack is empty");
		assert(i >= 0 && i < mTop, 'i index out of range ($i)');
		assert(j >= 0 && j < mTop, 'j index out of range ($j)');
		assert(i != j, 'i index equals j index ($i)');
		
		_set(i, _get(j));
	}
	
	/**
	 * Replaces up to <code>n</code> existing elements with objects of type <code>C</code>.
	 * <o>n</o>
	 * @param C the class to instantiate for each element.
	 * @param args passes additional constructor arguments to the class <code>C</code>.
	 * @param n the number of elements to replace. If 0, <code>n</code> is set to <em>size()</em>.
	 * @throws de.polygonal.ds.error.AssertError <code>n</code> out of range (debug only).
	 */
	public function assign(C:Class<T>, args:Array<Dynamic> = null, n = 0)
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
		for (i in 0...n) _set(i, Type.createInstance(C, args));
		
		mTop = n;
	}
	
	/**
	 * Replaces up to <code>n</code> existing elements with the instance of <code>x</code>.
	 * <o>n</o>
	 * @param n the number of elements to replace. If 0, <code>n</code> is set to <em>size()</em>.
	 * @throws de.polygonal.ds.error.AssertError <code>n</code> out of range (debug only).
	 */
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
			_set(i, x);
		
		mTop = n;
		return this;
	}
	
	/**
	 * Invokes the <code>process</code> function for each element.<br/>
	 * The function signature is: <em>process(oldValue, index):newValue</em>
	 * <o>n</o>
	 */
	public function walk(process:T->Int->T)
	{
		for (i in 0...mTop)
			_set(i, process(_get(i), i));
	}
	
	/**
	 * Shuffles the elements of this collection by using the Fisher-Yates algorithm.
	 * <o>n</o>
	 * @param rval a list of random double values in the range between 0 (inclusive) to 1 (exclusive) defining the new positions of the elements.
	 * If omitted, random values are generated on-the-fly by calling <em>Math.random()</em>.
	 * @throws de.polygonal.ds.error.AssertError insufficient random values (debug only).
	 */
	public function shuffle(rval:Array<Float> = null)
	{
		var s = mTop;
		if (rval == null)
		{
			var m = Math;
			while (s > 1)
			{
				var i = Std.int(m.random() * (--s));
				var t = _get(s);
				_set(s, _get(i));
				_set(i, t);
			}
		}
		else
		{
			assert(rval.length >= size(), "insufficient random values");
			
			var j = 0;
			while (s > 1)
			{
				var i = Std.int(rval[j++] * (--s));
				var t = _get(s);
				_set(s, _get(i));
				_set(i, t);
			}
		}
	}
	
	/**
	 * Returns a string representing the current object.<br/>
	 * Example:<br/>
	 * <pre class="prettyprint">
	 * var stack = new de.polygonal.ds.ArrayedStack&lt;Int&gt;(4);
	 * for (i in 0...4) {
	 *     stack.push(i);
	 * }
	 * trace(stack);</pre>
	 * <pre class="console">
	 * { ArrayedStack size/max: 4/4 }
	 * [ top
	 *   3 -> 3
	 *   2 -> 2
	 *   1 -> 1
	 *   0 -> 0
	 * ]</pre>
	 */
	public function toString():String
	{
		var s = '{ ArrayedStack size: ${size()} }';
		if (isEmpty()) return s;
		s += "\n[ top\n";
		var i = mTop - 1;
		var j = mTop - 1;
		while (i >= 0)
			s += Printf.format("  %4d -> %s\n", [j--, Std.string(_get(i--))]);
			
		s += "]";
		return s;
	}
	
	/*///////////////////////////////////////////////////////
	// collection
	///////////////////////////////////////////////////////*/
	
	/**
	 * Destroys this object by explicitly nullifying all elements for GC'ing used resources.<br/>
	 * Improves GC efficiency/performance (optional).
	 * <o>n</o>
	 */
	public function free()
	{
		for (i in 0...mData.length) _set(i, cast null);
		mData = null;
		mIterator = null;
	}
	
	/**
	 * Returns true if this stack contains the element <code>x</code>.
	 * <o>n</o>
	 */
	public function contains(x:T):Bool
	{
		for (i in 0...mTop)
		{
			if (_get(i) == x)
				return true;
		}
		return false;
	}
	
	/**
	 * Removes and nullifies all occurrences of the element <code>x</code>.
	 * <o>n</o>
	 * @return true if at least one occurrence of <code>x</code> was removed.
	 */
	public function remove(x:T):Bool
	{
		if (isEmpty()) return false;
		
		var found = false;
		while (mTop > 0)
		{
			found = false;
			for (i in 0...mTop)
			{
				if (_get(i) == x)
				{
					var t = mTop - 1;
					var p = i;
					while (p < t) _cpy(p++, p);
					_set(--mTop, cast null);
					found = true;
					break;
				}
			}
			
			if (!found) break;
		}
		
		return found;
	}
	
	/**
	 * Removes all elements.
	 * <o>1 or n if <code>purge</code> is true</o>
	 * @param purge if true, elements are nullified upon removal.
	 */
	public function clear(purge = false)
	{
		if (purge)
		{
			for (i in 0...mData.length) _set(i, cast null);
		}
		mTop = 0;
	}
	
	/**
	 * Returns a new <em>ArrayedStackIterator</em> object to iterate over all elements contained in this stack.<br/>
	 * Preserves the natural order of a stack (First-In-Last-Out).
	 * @see <a href="http://haxe.org/ref/iterators" target="mBlank">http://haxe.org/ref/iterators</a>
	 */
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
	 * Returns true if this stack is empty.
	 * <o>1</o>
	 */
	inline public function isEmpty():Bool
	{
		return mTop == 0;
	}
	
	/**
	 * The total number of elements.
	 * <o>1</o>
	 */
	inline public function size():Int
	{
		return mTop;
	}
	
	/**
	 * Returns an array containing all elements in this stack.<br/>
	 * Preserves the natural order of this stack (First-In-Last-Out).
	 */
	public function toArray():Array<T>
	{
		var a:Array<T> = ArrayUtil.alloc(size());
		var i = mTop, j = 0;
		while (i > 0) a[j++] = _get(--i);
		return a;
	}
	
	/**
	 * Returns a Vector.&lt;T&gt; object containing all elements in this stack.<br/>
	 * Preserves the natural order of this stack (First-In-Last-Out).
	 */
	public function toVector():Vector<T>
	{
		var v = new Vector<T>(size());
		var i = mTop, j = 0;
		while (i > 0) v[j++] = _get(--i);
		return v;
	}

	/**
	 * Duplicates this stack. Supports shallow (structure only) and deep copies (structure & elements).
	 * @param assign if true, the <code>copier</code> parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.<br/>
	 * If false, the <em>clone()</em> method is called on each element. <warn>In this case all elements have to implement <em>Cloneable</em>.</warn>
	 * @param copier a custom function for copying elements. Replaces element.<em>clone()</em> if <code>assign</code> is false.
	 * @throws de.polygonal.ds.error.AssertError element is not of type <em>Cloneable</em> (debug only).
	 */
	public function clone(assign = true, copier:T->T = null):Collection<T>
	{
		var copy = new ArrayedStack<T>(size(), maxSize);
		if (mTop == 0) return copy;
		var t = copy.mData;
		if (assign)
		{
			for (i in 0...mTop)
				t[i] = _get(i);
		}
		else
		if (copier == null)
		{
			var c:Cloneable<T> = null;
			for (i in 0...mTop)
			{
				assert(Std.is(_get(i), Cloneable), 'element is not of type Cloneable (${_get(i)})');
				
				c = untyped _get(i);
				t[i] = c.clone();
			}
		}
		else
		{
			for (i in 0...mTop)
				t[i] = copier(_get(i));
		}
		copy.mTop = mTop;
		return copy;
	}
	
	inline function _get(i:Int) return mData[i];
	
	inline function _set(i:Int, x:T) mData[i] = x;
	
	inline function _cpy(i:Int, j:Int) mData[i] = mData[j];
}

#if (flash && generic)
@:generic
#end
@:access(de.polygonal.ds.ArrayedStack)
#if doc
private
#end
class ArrayedStackIterator<T> implements de.polygonal.ds.Itr<T>
{
	var mF:ArrayedStack<T>;
	var mData:Array<T>;
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