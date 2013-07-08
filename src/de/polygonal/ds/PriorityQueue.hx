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

private typedef PriorityQueueFriend<T> =
{
	private var _a:Array<T>;
	private var _size:Int;
}

/**
 * <p>A priority queue is heap data structure with a simplified API for managing prioritized data.</p>
 * Adds additional methods for removing and re-prioritizing elements.</p>
 * <p><o>Worst-case running time in Big O notation</o></p>
 */
class PriorityQueue<T:(Prioritizable)> implements Queue<T>
{
	/**
	 * A unique identifier for this object.<br/>
	 * A hash table transforms this key into an index of an array element by using a hash function.<br/>
	 * <warn>This value should never be changed by the user.</warn>
	 */
	public var key:Int;
	
	/**
	 * The maximum allowed size of this priority queue.<br/>
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
	var _size:Int;
	var _inverse:Bool;
	var _iterator:PriorityQueueIterator<T>;
	
	#if (debug && flash)
	var _map:HashMap<T, Bool>;
	#end
	
	/**
	 * @param inverse if true, the lower the number, the higher the priority.
	 * By default a higher number means a higher priority.
	 * @param reservedSize the initial capacity of the internal container. See <em>reserve()</em>.
	 * @param maxSize the maximum allowed size of the priority queue.<br/>
	 * The default value of -1 indicates that there is no upper limit.
	 */
	public function new(inverse = false, reservedSize = 0, maxSize = -1)
	{
		#if debug
		this.maxSize = (maxSize == -1) ? M.INT32_MAX : maxSize;
		#else
		this.maxSize = -1;
		#end
		
		_inverse = inverse;
		_iterator = null;
		
		if (reservedSize > 0)
		{
			#if debug
			if (this.maxSize != -1)
				assert(reservedSize <= this.maxSize, "reserved size is greater than allowed size");
			#end
			
			_a = ArrayUtil.alloc(reservedSize + 1);
		}
		else
			_a = new Array<T>();
		
		__set(0, cast null);
		_size = 0;
		
		#if (debug && flash)
		_map = new HashMap<T, Bool>();
		#end
		
		key = HashKey.next();
		reuseIterator = false;
	}
	
	/**
	 * For performance reasons the priority queue does nothing to ensure that empty locations contain null.<br/>
	 * <em>pack()</em> therefore nullifies all obsolete references and shrinks the container to the actual size allowing the garbage collector to reclaim used memory.
	 * <o>n</o>
	 */
	public function pack()
	{
		if (_a.length - 1 == size()) return;
		
		var tmp = _a;
		_a = ArrayUtil.alloc(size() + 1);
		__set(0, cast null);
		for (i in 1...size() + 1) __set(i, tmp[i]);
		for (i in size() + 1...tmp.length) tmp[i] = null;
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
		
		_a = ArrayUtil.alloc(x + 1);
		
		__set(0, cast null);
		if (size() < x)
		{
			for (i in 1...size() + 1)
				__set(i, tmp[i]);
		}
	}
	
	/**
	 * Returns the front element.<br/>
	 * This is the element with the highest priority.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError priority queue is empty (debug only).
	 */
	inline public function peek():T
	{
		#if debug
		assert(size() > 0, "priority queue is empty");
		#end
		
		return __get(1);
	}
	
	/**
	 * Returns the rear element.<br/>
	 * This is the element with the lowest priority.
	 * <o>n</o>
	 * @throws de.polygonal.ds.error.AssertError priority queue is empty (debug only).
	 */
	public function back():T
	{
		#if debug
		assert(size() > 0, "priority queue is empty");
		#end
		
		if (_size == 1) return __get(1);
		var a = __get(1), b;
		if (_inverse)
		{
			for (i in 2..._size + 1)
			{
				b = __get(i);
				if (a.priority < b.priority) a = b;
			}
		}
		else
		{
			for (i in 2..._size + 1)
			{
				b = __get(i);
				if (a.priority > b.priority) a = b;
			}
		}
		return a;
	}
	
	/**
	 * Enqueues the element <code>x</code>.
	 * <o>log n</o>
	 * @throws de.polygonal.ds.error.AssertError <em>size()</em> equals <em>maxSize</em> (debug only).
	 * @throws de.polygonal.ds.error.AssertError <code>x</code> is null or <code>x</code> already exists (debug only).
	 */
	inline public function enqueue(x:T)
	{
		#if debug
		if (maxSize != -1)
			assert(size() <= maxSize, 'size equals max size ($maxSize)');
		assert(x != null, "element is null");
		#end
		
		#if (debug && flash)
		assert(!_map.hasKey(x), "element already exists");
		_map.set(x, true);
		#end
		
		__set(++_size, x);
		x.position = _size;
		_upheap(_size);
	}
	
	/**
	 * Dequeues the front element.
	 * <o>log n</o>
	 * @throws de.polygonal.ds.error.AssertError priority queue is empty (debug only).
	 */
	inline public function dequeue():T
	{
		#if debug
		assert(size() > 0, "priority queue is empty");
		#end
		
		var x = __get(1);
		x.position = -1;
		__set(1, __get(_size));
		_downheap(1);
		
		#if (debug && flash)
		_map.clr(x);
		#end
		
		_size--;
		return x;
	}
	
	/**
	 * Reprioritizes the element <code>x</code>.
	 * <o>log n</o>
	 * @param x the element to re-prioritize.
	 * @param priority the new priority.
	 * @throws de.polygonal.ds.error.AssertError priority queue is empty or <code>x</code> does not exist (debug only).
	 */
	public function reprioritize(x:T, priority:Float)
	{
		#if debug
		assert(size() > 0, "priority queue is empty");
		#end
		
		#if (debug && flash)
		assert(_map.hasKey(x), "unknown element");
		#end
		
		var oldPriority = x.priority;
		if (oldPriority != priority)
		{
			x.priority = priority;
			var pos = x.position;
			
			if (_inverse)
			{
				if (priority < oldPriority)
					_upheap(pos);
				else
				{
					_downheap(pos);
					_upheap(_size);
				}
			}
			else
			{
				if (priority > oldPriority)
					_upheap(pos);
				else
				{
					_downheap(pos);
					_upheap(_size);
				}
			}
		}
	}
	
	/**
	 * Returns a string representing the current object.<br/>
	 * Example:<br/>
	 * <pre class="prettyprint">
	 * class Foo implements de.polygonal.ds.Prioritizable
	 * {
	 *     public var priority:Int;
	 *     public var position:Int;
	 *     
	 *     public function new(priority:Int) {
	 *       this.priority = priority;
	 *     }
	 *     
	 *     public function toString():String {
	 *       return Std.string(priority);
	 *     }
	 * } 
	 * 
	 * class Main
	 * {
	 *     static function main() {
	 *         var pq = new de.polygonal.ds.PriorityQueue&lt;Foo&gt;(4);
	 *         pq.enqueue(new Foo(5));
	 *         pq.enqueue(new Foo(3));
	 *         pq.enqueue(new Foo(0));
	 *         trace(pq);
	 *     }
	 * }</pre>
	 * <pre class="console">
	 * { PriorityQueue size: 3 }
	 * [ front
	 *    0 -> 5
	 *    1 -> 3
	 *    2 -> 0
	 * ]
	 * </pre>
	 */
	public function toString():String
	{
		var s = '{ PriorityQueue size: ${size()} }';
		if (isEmpty()) return s;
		var tmp = new PriorityQueue<PQElementWrapper<T>>();
		tmp._inverse = _inverse;
		for (i in 1..._size + 1)
		{
			var w = new PQElementWrapper<T>(__get(i));
			tmp.__set(i, w);
		}
		tmp._size = _size;
		s += "\n[ front\n";
		var i = 0;
		while (tmp.size() > 0)
			s += Printf.format("  %4d -> %s\n", [i++, Std.string(tmp.dequeue())]);
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
		
		if (_iterator != null)
		{
			_iterator.free();
			_iterator = null;
		}
		
		#if (debug && flash)
		_map.free();
		_map = null;
		#end
	}
	
	/**
	 * Returns true if this priority queue contains the element <code>x</code>.
	 * @throws de.polygonal.ds.error.AssertError <code>x</code> is invalid.
	 * <o>1</o>
	 */
	inline public function contains(x:T):Bool
	{
		#if debug
		assert(x != null, "x is null");
		#end
		
		var position = x.position;
		return (position > 0 && position <= _size) && (__get(position) == x);
	}
	
	/**
	 * Removes the element <code>x</code>.
	 * <o>n</o>
	 * @return true if <code>x</code> was removed.
	 * @throws de.polygonal.ds.error.AssertError <code>x</code> is invalid or does not exist (debug only).
	 */
	public function remove(x:T):Bool
	{
		if (isEmpty())
			return false;
		else
		{
			#if debug
			assert(x != null, "x is null");
			#end
			
			#if (debug && flash)
			assert(_map.hasKey(x), "x does not exist");
			_map.clr(x);
			#end
			
			if (x.position == 1)
				dequeue();
			else
			{
				var p = x.position;
				__set(p, __get(_size));
				_downheap(p);
				_upheap(p);
				_size--;
			}
			return true;
		}
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
			for (i in 1..._a.length) __set(i, cast null);
		}
		
		#if (debug && flash)
		_map.clear(true);
		#end
		
		_size = 0;
	}
	
	/**
	 * Returns a new <em>PriorityQueueIterator</em> object to iterate over all elements contained in this priority queue.<br/>
	 * The values are visited in an unsorted order.
	 * @see <a href="http://haxe.org/ref/iterators" target="_blank">http://haxe.org/ref/iterators</a>
	 */
	public function iterator():Itr<T>
	{
		if (reuseIterator)
		{
			if (_iterator == null)
				return new PriorityQueueIterator<T>(this);
			else
				_iterator.reset();
			return _iterator;
		}
		else
			return new PriorityQueueIterator<T>(this);
	}
	
	/**
	 * The total number of elements.
	 * <o>1</o>
	 */
	inline public function size():Int
	{
		return _size;
	}
	
	/**
	 * Returns true if this priority queue is empty.
	 * <o>1</o>
	 */
	inline public function isEmpty():Bool
	{
		return _size == 0;
	}
	
	/**
	 * Returns an unordered array containing all elements in this priority queue.
	 */
	public function toArray():Array<T>
	{
		var a:Array<T> = ArrayUtil.alloc(size());
		for (i in 1...size() + 1) a[i - 1] = __get(i);
		return a;
	}
	
	#if flash10
	/**
	 * Returns a Vector.&lt;T&gt; object containing all elements in this priority queue.
	 */
	public function toVector():flash.Vector<Dynamic>
	{
		var a = new flash.Vector<Dynamic>(size());
		for (i in 1..._size + 1) a[i - 1] = __get(i);
		return a;
	}
	#end
	
	/**
	 * Duplicates this priority queue. Supports shallow (structure only) and deep copies (structure & elements).
	 * @param assign if true, the <code>copier</code> parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.<br/>
	 * If false, the <em>clone()</em> method is called on each element. <warn>In this case all elements have to implement <em>Cloneable</em>.</warn>
	 * @param copier a custom function for copying elements. Replaces element.<em>clone()</em> if <code>assign</code> is false.
	 * @throws de.polygonal.ds.error.AssertError element is not of type <em>Cloneable</em> (debug only).
	 * <warn>If <code>assign</code> is true, only the copied version should be used from now on.</warn>
	 */
	public function clone(assign = true, copier:T->T = null):Collection<T>
	{
		var copy = new PriorityQueue<T>(_inverse, size(), maxSize);
		if (_size == 0) return copy;
		if (assign)
		{
			for (i in 1..._size + 1)
			{
				copy.__set(i, __get(i));
				
				#if (debug && flash)
				copy._map.set(__get(i), true);
				#end
			}
		}
		else
		if (copier == null)
		{
			for (i in 1..._size + 1)
			{
				var e = __get(i);
				
				#if debug
				assert(Std.is(e, Cloneable), 'element is not of type Cloneable ($e)');
				#end
				
				var c = untyped e.clone();
				c.position = e.position;
				c.priority = e.priority;
				copy.__set(i, untyped c);
				
				#if (debug && flash)
				copy._map.set(untyped c, true);
				#end
			}
		}
		else
		{
			for (i in 1..._size + 1)
			{
				var e = __get(i);
				var c = copier(e);
				c.position = e.position;
				c.priority = e.priority;
				copy.__set(i, c);
				
				#if (debug && flash)
				copy._map.set(e, true);
				#end
			}
		}
		
		copy._size = _size;
		return copy;
	}
	
	inline function _upheap(index:Int)
	{
		var parent = index >> 1;
		var tmp = __get(index);
		var p = tmp.priority;
		
		if (_inverse)
		{
			while (parent > 0)
			{
				var parentVal = __get(parent);
				if (p - parentVal.priority < 0)
				{
					__set(index, parentVal);
					parentVal.position = index;
					
					index = parent;
					parent >>= 1;
				}
				else break;
			}
		}
		else
		{
			while (parent > 0)
			{
				var parentVal = __get(parent);
				if (p - parentVal.priority > 0)
				{
					__set(index, parentVal);
					parentVal.position = index;
					
					index = parent;
					parent >>= 1;
				}
				else break;
			}
		}
		
		__set(index, tmp);
		tmp.position = index;
	}
	
	inline function _downheap(index:Int)
	{
		var child = index << 1;
		var childVal:T;
		
		var tmp = __get(index);
		var p = tmp.priority;
		
		if (_inverse)
		{
			while (child < _size)
			{
				if (child < _size - 1)
					if (__get(child).priority - __get(child + 1).priority > 0)
						child++;
				
				childVal = __get(child);
				if (p - childVal.priority > 0)
				{
					__set(index, childVal);
					childVal.position = index;
					tmp.position = child;
					index = child;
					child <<= 1;
				}
				else break;
			}
		}
		else
		{
			while (child < _size)
			{
				if (child < _size - 1)
					if (__get(child).priority - __get(child + 1).priority < 0)
						child++;
				
				childVal = __get(child);
				if (p - childVal.priority < 0)
				{
					__set(index, childVal);
					childVal.position = index;
					tmp.position = child;
					index = child;
					child <<= 1;
				}
				else break;
			}
		}
		
		__set(index, tmp);
		tmp.position = index;
	}
	
	inline function __get(i:Int)
	{
		return _a[i];
	}
	inline function __set(i:Int, x:T)
	{
		_a[i] = x;
	}
}

#if doc
private
#end
class PriorityQueueIterator<T:(Prioritizable)> implements de.polygonal.ds.Itr<T>
{
	var _f:PriorityQueue<T>;
	var _a:Array<T>;
	var _i:Int;
	var _s:Int;
	
	public function new(f:PriorityQueue<T>)
	{
		_f = f;
		_a = new Array<T>();
		_a[0] = null;
		reset();
	}
	
	public function free()
	{
		_a = null;
	}
	
	inline public function reset():Itr<T>
	{
		_s = _f.size() + 1;
		_i = 1;
		var a = __a(_f);
		for (i in 1..._s) _a[i] = a[i];
		return this;
	}
	
	inline public function hasNext():Bool
	{
		return _i < _s;
	}
	
	inline public function next():T
	{
		return _a[_i++];
	}
	
	inline public function remove()
	{
		#if debug
		assert(_i > 0, "call next() before removing an element");
		#end
		
		_f.remove(_a[_i - 1]);
	}
	
	inline function __a(f:PriorityQueueFriend<T>)
	{
		return f._a;
	}
}

private class PQElementWrapper<T:(Prioritizable)> implements Prioritizable
{
	public var priority:Float;
	public var position:Int;
	public var e:T;
	
	public function new(e:T)
	{
		this.e = e;
		this.priority = e.priority;
		this.position = e.position;
	}
	
	public function toString():String
	{
		return Std.string(e);
	}
}