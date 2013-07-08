/*
 *                            _/                                                    _/
 *       _/_/_/      _/_/    _/  _/    _/    _/_/_/    _/_/    _/_/_/      _/_/_/  _/
 *      _/    _/  _/    _/  _/  _/    _/  _/    _/  _/    _/  _/    _/  _/    _/  _/
 *     _/    _/  _/    _/  _/  _/    _/  _/    _/  _/    _/  _/    _/  _/    _/  _/
 *    _/_/_/      _/_/    _/    _/_/_/    _/_/_/    _/_/    _/    _/    _/_/_/  _/
 *   _/                            _/        _/
 *  _/                        _/_/      _/_/
 *
 * POLYGONAL - A HAXE LIBRARY FOR GAME DEVELOPERS
 * Copyright (c) 2009 Michael Baczynski, http://www.polygonal.de
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */
package de.polygonal.ds;

import de.polygonal.ds.error.Assert.assert;

private typedef ArrayedStackFriend<T> =
{
	private var _a:Array<T>;
	private var _top:Int;
}

/**
 * <p>A dynamic arrayed stack.</p>
 * <p>A stack is a linear list for which all insertions and deletions (and usually all accesses) are made at one end of the list.</p>
 * <p>This is called a LIFO structure (Last In, First Out).</p>
 * <p><o>Worst-case running time in Big O notation</o></p>
 */
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
	
	var _a:Array<T>;
	var _top:Int;
	var _iterator:ArrayedStackIterator<T>;
	
	#if debug
	var _t0:Int;
	var _t1:Int;
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
			_a = ArrayUtil.alloc(reservedSize);
		}
		else
			_a = new Array<T>();
		
		_top = 0;
		_iterator = null;
		key = HashKey.next();
		reuseIterator = false;
		
		#if debug
		this.maxSize = (maxSize == -1) ? M.INT32_MAX : maxSize;
		#else
		this.maxSize = -1;
		#end
		
		#if debug
		_t0 = 0;
		_t1 = 0;
		#end
	}
	
	/**
	 * For performance reasons the stack does nothing to ensure that empty locations contain null.<br/>
	 * <em>pack()</em> therefore nullifies all obsolete references and shrinks the array to the actual size allowing the garbage collector to reclaim used memory.
	 * <o>n</o>
	 */
	public function pack()
	{
		if (_a.length == size()) return;
		
		var tmp = _a;
		_a = ArrayUtil.alloc(size());
		for (i in 0...size()) __set(i, tmp[i]);
		for (i in size()...tmp.length) tmp[i] = null;
	}
	
	/**
	 * Preallocates internal space for storing <code>x</code> elements.<br/>
	 * This is useful if the expected size is known in advance - many platforms can optimize memory usage if an exact size is specified.
	 * <o>n</o>
	 */
	public function reserve(x:Int)
	{
		if (size() == x) return;
		
		var tmp = _a;
		_a = ArrayUtil.alloc(x);
		
		if (size() < x)
		{
			for (i in 0..._top)
				__set(i, tmp[i]);
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
		#if debug
		assert(_top > 0, "stack is empty");
		#end
		
		return __get(_top - 1);
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
		++_t1;
		#end
		
		__set(_top++, x);
	}
	
	/**
	 * Pops data off the stack.
	 * <o>1</o>
	 * @return the top element.
	 * @throws de.polygonal.ds.error.AssertError stack is empty (debug only).
	 */
	inline public function pop():T
	{
		#if debug
		assert(_top > 0, "stack is empty");
		#end
		
		#if debug
		_t0 = ++_t1;
		#end
		
		return __get(--_top);
	}
	
	/**
	 * Pops the top element of the stack, and pushes it back twice, so that an additional copy of the former top item is now on top, with the original below it.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError stack is empty (debug only).
	 * @throws de.polygonal.ds.error.AssertError <em>size()</em> equals <em>maxSize</em> (debug only).
	 */
	inline public function dup()
	{
		#if debug
		assert(_top > 0, "stack is empty");
		#end
		
		#if debug
		if (maxSize != -1)
			assert(size() < maxSize, 'size equals max size ($maxSize)');
		#end
		
		__set(_top, __get(_top - 1));
		_top++;
	}
	
	/**
	 * Swaps the two topmost items on the stack.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError <em>size()</em> < 2 (debug only).
	 */
	inline public function exchange()
	{
		#if debug
		assert(_top > 1, "size() < 2");
		#end
		
		var i = _top - 1;
		var j = i - 1;
		var tmp = __get(i);
		__set(i, __get(j));
		__set(j, tmp);
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
	inline public function rotRight(n:Int)
	{
		#if debug
		assert(_top >= n, "size() < n");
		#end
		
		var i = _top - n;
		var k = _top - 1;
		var tmp = __get(i);
		while (i < k)
		{
			__set(i, __get(i + 1));
			i++;
		}
		__set(_top - 1, tmp);
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
	inline public function rotLeft(n:Int)
	{
		#if debug
		assert(_top >= n, "size() < n");
		#end
		
		var i = _top - 1;
		var k = _top - n;
		var tmp = __get(i);
		while (i > k)
		{
			__set(i, __get(i - 1));
			i--;
		}
		__set(_top - n, tmp);
	}
	
	/**
	 * Nullifies the last popped off element so it can be instantly garbage collected.<br/>
	 * <warn>Use only directly after <em>pop()</em>.</warn>
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError <em>pop()</em> wasn't directly called after <em>dequeue()</em>(debug only).
	 */
	inline public function dispose()
	{
		#if debug
		assert(_top > 0, "stack is empty");
		assert(_t0 == _t1, "dispose() is only allowed directly after pop()");
		#end
		
		__set(_top, cast null);
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
		#if debug
		assert(_top > 0, "stack is empty");
		assert(i >= 0 && i < _top, 'i index out of range ($i)');
		#end
		
		return __get(i);
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
		#if debug
		assert(_top > 0, "stack is empty");
		assert(i >= 0 && i < _top, 'i index out of range ($i)');
		#end
		
		__set(i, x);
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
		#if debug
		assert(_top > 0, "stack is empty");
		assert(i >= 0 && i < _top, 'i index out of range ($i)');
		assert(j >= 0 && j < _top, 'j index out of range ($j)');
		assert(i != j, 'i index equals j index ($i)');
		#end
		
		var t = __get(i);
		cpy(i, j);
		__set(j, t);
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
		#if debug
		assert(_top > 0, "stack is empty");
		assert(i >= 0 && i < _top, 'i index out of range ($i)');
		assert(j >= 0 && j < _top, 'j index out of range ($j)');
		assert(i != j, 'i index equals j index ($i)');
		#end
		
		__set(i, __get(j));
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
		#if debug
		assert(n >= 0, "n >= 0");
		#end
		
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
		for (i in 0...n) __set(i, Type.createInstance(C, args));
		
		_top = n;
	}
	
	/**
	 * Replaces up to <code>n</code> existing elements with the instance of <code>x</code>.
	 * <o>n</o>
	 * @param n the number of elements to replace. If 0, <code>n</code> is set to <em>size()</em>.
	 * @throws de.polygonal.ds.error.AssertError <code>n</code> out of range (debug only).
	 */
	public function fill(x:T, n = 0):ArrayedStack<T>
	{
		#if debug
		assert(n >= 0, "n >= 0");
		#end
		
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
			__set(i, x);
		
		_top = n;
		return this;
	}
	
	/**
	 * Invokes the <code>process</code> function for each element.<br/>
	 * The function signature is: <em>process(oldValue, index):newValue</em>
	 * <o>n</o>
	 */
	public function walk(process:T->Int->T)
	{
		for (i in 0..._top)
			__set(i, process(__get(i), i));
	}
	
	/**
	 * Shuffles the elements of this collection by using the Fisher-Yates algorithm.
	 * <o>n</o>
	 * @param rval a list of random double values in the range between 0 (inclusive) to 1 (exclusive) defining the new positions of the elements.
	 * If omitted, random values are generated on-the-fly by calling <em>Math.random()</em>.
	 * @throws de.polygonal.ds.error.AssertError insufficient random values (debug only).
	 */
	public function shuffle(rval:DA<Float> = null)
	{
		var s = _top;
		if (rval == null)
		{
			var m = Math;
			while (s > 1)
			{
				var i = Std.int(m.random() * (--s));
				var t = __get(s);
				__set(s, __get(i));
				__set(i, t);
			}
		}
		else
		{
			#if debug
			assert(rval.size() >= size(), "insufficient random values");
			#end
			
			var j = 0;
			while (s > 1)
			{
				var i = Std.int(rval.get(j++) * (--s));
				var t = __get(s);
				__set(s, __get(i));
				__set(i, t);
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
		var i = _top - 1;
		var j = _top - 1;
		while (i >= 0)
			s += Printf.format("  %4d -> %s\n", [j--, Std.string(__get(i--))]);
			
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
		for (i in 0..._a.length) __set(i, cast null);
		_a = null;
		_iterator = null;
	}
	
	/**
	 * Returns true if this stack contains the element <code>x</code>.
	 * <o>n</o>
	 */
	public function contains(x:T):Bool
	{
		for (i in 0..._top)
		{
			if (__get(i) == x)
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
		while (_top > 0)
		{
			found = false;
			for (i in 0..._top)
			{
				if (__get(i) == x)
				{
					var t = _top - 1;
					var p = i;
					while (p < t)
					{
						#if cpp
						__cpy(p, p + 1); p++;
						#else
						__cpy(p++, p);
						#end
					}
					__set(--_top, cast null);
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
	inline public function clear(purge = false)
	{
		if (purge)
		{
			for (i in 0..._a.length) __set(i, cast null);
		}
		_top = 0;
	}
	
	/**
	 * Returns a new <em>ArrayedStackIterator</em> object to iterate over all elements contained in this stack.<br/>
	 * Preserves the natural order of a stack (First-In-Last-Out).
	 * @see <a href="http://haxe.org/ref/iterators" target="_blank">http://haxe.org/ref/iterators</a>
	 */
	public function iterator():Itr<T>
	{
		if (reuseIterator)
		{
			if (_iterator == null)
				_iterator = new ArrayedStackIterator<T>(this);
			else
				_iterator.reset();
			return _iterator;
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
		return _top == 0;
	}
	
	/**
	 * The total number of elements.
	 * <o>1</o>
	 */
	inline public function size():Int
	{
		return _top;
	}
	
	/**
	 * Returns an array containing all elements in this stack.<br/>
	 * Preserves the natural order of this stack (First-In-Last-Out).
	 */
	public function toArray():Array<T>
	{
		var a:Array<T> = ArrayUtil.alloc(size());
		var i = _top, j = 0;
		while (i > 0) a[j++] = __get(--i);
		return a;
	}
	
	#if flash10
	/**
	 * Returns a Vector.&lt;T&gt; object containing all elements in this stack.<br/>
	 * Preserves the natural order of this stack (First-In-Last-Out).
	 */
	public function toVector():flash.Vector<Dynamic>
	{
		var a = new flash.Vector<Dynamic>(size());
		var i = _top, j = 0;
		while (i > 0) a[j++] = __get(--i);
		return a;
	}
	#end

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
		if (_top == 0) return copy;
		var t = copy._a;
		if (assign)
		{
			for (i in 0..._top)
				t[i] = __get(i);
		}
		else
		if (copier == null)
		{
			var c:Cloneable<T> = null;
			for (i in 0..._top)
			{
				#if debug
				assert(Std.is(__get(i), Cloneable), 'element is not of type Cloneable (${__get(i)})');
				#end
				
				c = untyped __get(i);
				t[i] = c.clone();
			}
		}
		else
		{
			for (i in 0..._top)
				t[i] = copier(__get(i));
		}
		copy._top = _top;
		return copy;
	}
	
	inline function __get(i:Int)
	{
		return _a[i];
	}
	inline function __set(i:Int, x:T)
	{
		_a[i] = x;
	}
	inline function __cpy(i:Int, j:Int)
	{
		_a[i] = _a[j];
	}
}

#if doc
private
#end
class ArrayedStackIterator<T> implements de.polygonal.ds.Itr<T>
{
	var _f:ArrayedStack<T>;
	var _a:Array<T>;
	var _i:Int;
	
	public function new(f:ArrayedStack<T>)
	{
		_f = f;
		reset();
	}
	
	inline public function reset():Itr<T>
	{
		_a = __a(_f);
		_i = __getTop(_f) - 1;
		return this;
	}
	
	inline public function hasNext():Bool
	{
		return _i >= 0;
	}
	
	inline public function next():T
	{
		return _a[_i--];
	}
	
	inline public function remove()
	{
		#if debug
		assert(_i != (__getTop(_f) - 1), "call next() before removing an element");
		#end
		
		var i = _i + 1;
		var top = __getTop(_f) - 1;
		if (i == top)
			__setTop(_f, top);
		else
		{
			while (i < top)
			{
				#if cpp
				_a[i] = _a[i + 1]; i++;
				#else
				_a[i++] = _a[i];
				#end
			}
			__setTop(_f, top);
		}
	}
	
	inline function __a<T>(f:ArrayedStackFriend<T>)
	{
		return f._a;
	}
	inline function __getTop<T>(f:ArrayedStackFriend<T>)
	{
		return f._top;
	}
	inline function __setTop<T>(f:ArrayedStackFriend<T>, x:Int)
	{
		return f._top = x;
	}
}