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

private typedef LinkedQueueFriend<T> =
{
	private var _head:LinkedQueueNode<T>;
	private function _removeNode(x:LinkedQueueNode<T>):Void;
}

/**
 * <p>A queue based on a linked list.</p>
 * <p>A queue is a linear list for which all insertions are made at one end of the list; all deletions (and usually all accesses) are made at the other end.</p>
 * <p>This is called a FIFO structure (First In, First Out).</p>
 * <p>See <a href="http://lab.polygonal.de/2007/05/23/data-structures-example-the-queue-class/" target="_blank">http://lab.polygonal.de/2007/05/23/data-structures-example-the-queue-class/</a></p>
 * <p><o>Worst-case running time in Big O notation</o></p>
 */
#if generic
@:generic
#end
class LinkedQueue<T> implements Queue<T>
{
	/**
	 * A unique identifier for this object.<br/>
	 * A hash table transforms this key into an index of an array element by using a hash function.<br/>
	 * <warn>This value should never be changed by the user.</warn>
	 */
	public var key:Int;
	
	/**
	 * The maximum allowed size of this queque.<br/>
	 * Once the maximum size is reached, adding an element will fail with an error (debug only).
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
	
	var _head:LinkedQueueNode<T>;
	var _tail:LinkedQueueNode<T>;
	
	var _size:Int;
	var _reservedSize:Int;
	var _poolSize:Int;
	
	var _headPool:LinkedQueueNode<T>;
	var _tailPool:LinkedQueueNode<T>;
	
	var _iterator:LinkedQueueIterator<T>;
	
	/**
	 * @param reservedSize if &gt; 0, this queue maintains an object pool of node objects.<br/>
	 * Prevents frequent node allocation and thus increases performance at the cost of using more memory.
	 * @param maxSize the maximum allowed size of this queue.<br/>
	 * The default value of -1 indicates that there is no upper limit.
	 * @throws de.polygonal.ds.error.AssertError reserved size is greater than allowed size (debug only).
	 */
	public function new(reservedSize = 0, maxSize = -1)
	{
		#if debug
		if (reservedSize > 0)
		{
			if (maxSize != -1)
				assert(reservedSize <= maxSize, "reserved size is greater than allowed size");
		}
		this.maxSize = (maxSize == -1) ? M.INT32_MAX : maxSize;
		#else
		this.maxSize = -1;
		#end
		
		_reservedSize = reservedSize;
		_size         = 0;
		_poolSize     = 0;
		_iterator     = null;
		_head         = null;
		_tail         = null;
		
		if (reservedSize > 0)
		{
			_headPool = _tailPool = new LinkedQueueNode<T>(cast null);
		}
		else
		{
			_headPool = null;
			_tailPool = null;
		}
		
		key = HashKey.next();
		reuseIterator = false;
	}
	
	/**
	 * Returns the front element.<br/>
	 * This is the "oldest" element.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError queue is empty (debug only).
	 */
	inline public function peek():T
	{
		#if debug
		assert(_head != null, "queue is empty");
		#end
		return _head.val;
	}
	
	/**
	 * Returns the rear element.<br/>
	 * This is the "newest" element.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError queue is empty (debug only).
	 */
	inline public function back():T
	{
		#if debug
		assert(_tail != null, "queue is empty");
		#end
		return _tail.val;
	}
	
	/**
	 * Enqueues the element <code>x</code>.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError <em>size()</em> equals <em>maxSize</em> (debug only).
 	 */
	inline public function enqueue(x:T)
	{
		#if debug
		if (maxSize != -1)
			assert(size() < maxSize, 'size equals max size ($maxSize)');
		#end
		
		_size++;
		
		var node = _getNode(x);
		if (_head == null)
		{
			_head = _tail = node;
			_head.next = null;
		}
		else
		{
			_tail.next = node;
			_tail = node;
		}
	}
	
	/**
	 * Dequeues and returns the front element.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError queue is empty (debug only).
	 */
	inline public function dequeue():T
	{
		#if debug
		assert(_head != null, "queue is empty");
		#end
		
		_size--;
		
		var node = _head;
		if (_head == _tail)
		{
			_head = null;
			_tail = null;
		}
		else
			_head = _head.next;
		
		return _putNode(node);
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
		var node = _head;
		for (i in 0...n)
		{
			node.val = Type.createInstance(C, args);
			node = node.next;
		}
	}
	
	/**
	 * Replaces up to <code>n</code> existing elements with the instance of <code>x</code>.
	 * <o>n</o>
	 * @param n the number of elements to replace. If 0, <code>n</code> is set to <em>size()</em>.
	 * @throws de.polygonal.ds.error.AssertError <code>n</code> out of range (debug only).
	 */
	public function fill(x:T, n = 0):LinkedQueue<T>
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
		
		var node = _head;
		for (i in 0...n)
		{
			node.val = x;
			node = node.next;
		}
		
		return this;
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
		var s = _size;
		if (rval == null)
		{
			var m = Math;
			while (s > 1)
			{
				s--;
				var i = Std.int(m.random() * s);
				var node1 = _head;
				for (j in 0...s) node1 = node1.next;
				
				var t = node1.val;
				
				var node2 = _head;
				for (j in 0...i) node2 = node2.next;
				
				node1.val = node2.val;
				node2.val = t;
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
				s--;
				var i = Std.int(rval.get(j++) * s);
				var node1 = _head;
				for (j in 0...s) node1 = node1.next;
				
				var t = node1.val;
				
				var node2 = _head;
				for (j in 0...i) node2 = node2.next;
				
				node1.val = node2.val;
				node2.val = t;
			}
		}
	}
	
	/**
	 * Returns a string representing the current object.<br/>
	 * Example:<br/>
	 * <pre class="prettyprint">
	 * var lq = new de.polygonal.ds.LinkedQueue&lt;Int&gt;();
	 * lq.enqueue(0);
	 * lq.enqueue(1);
	 * lq.enqueue(2);
	 * trace(lq);</pre>
	 * <pre class="console">
	 * { LinkedQueue size: 3 }
	 * [
	 *   0 -> 0
	 *   1 -> 1
	 *   2 -> 2
	 * ]</pre>
	 */
	public function toString():String
	{
		var s = '{ LinkedQueue size: ${size()} }';
		if (isEmpty()) return s;
		s += "\n[\n";
		var node = _head;
		var i = 0;
		while (node != null)
		{
			s += Printf.format("  %4d -> %s\n", [i++, Std.string(node.val)]);
			node = node.next;
		}
		s += "]";
		return s;
	}
	
	/*///////////////////////////////////////////////////////
	// collection
	///////////////////////////////////////////////////////*/
	
	/**
	 * Destroys this object by explicitly nullifying all nodes, pointers and elements.<br/>
	 * Improves GC efficiency/performance (optional).
	 * <o>n</o>
	 */
	public function free()
	{
		var node = _head;
		while (node != null)
		{
			var next = node.next;
			node.next = null;
			node.val = cast null;
			node = next;
		}
		
		_head = _tail = null;
		
		var node = _headPool;
		while (node != null)
		{
			var next = node.next;
			node.next = null;
			node.val = cast null;
			node = next;
		}
		
		_headPool = _tailPool = null;
		_iterator = null;
	}
	
	/**
	 * Returns true if this queue contains the element <code>x</code>.
	 * <o>n</o>
	 */
	public function contains(x:T):Bool
	{
		var node = _head;
		while (node != null)
		{
			if (node.val == x)
				return true;
			node = node.next;
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
		var node0 = _head;
		var node1 = _head.next;
		
		if (_head == _tail)
		{
			if (_head.val == x)
			{
				_size = 0;
				_putNode(_head);
				_head = null;
				_tail = null;
				return true;
			}
			
			return false;
		}
		
		while (node1 != null)
		{
			if (node1.val == x)
			{
				found = true;
				if (node1 == _tail) _tail = node0;
				var node2 = node1.next;
				node0.next = node2;
				_putNode(node1);
				node1 = node2;
				_size--;
			}
			else
			{
				node0 = node1;
				node1 = node1.next;
			}
		}
		
		if (_head.val == x)
		{
			found = true;
			var head1 = _head.next;
			_putNode(_head);
			_head = head1;
			if (_head == null) _tail = null;
			_size--;
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
		if (purge || _reservedSize > 0)
		{
			var node = _head;
			while (node != null)
			{
				var next = node.next;
				_putNode(node);
				node = node.next;
			}
		}
		
		_head = _tail = null;
		_size = 0;
	}
	
	/**
	 * Returns a new <em>LinkedQueue</em> object to iterate over all elements contained in this queue.<br/>
	 * Preserves the natural order of a queue (First-In-First-Out).
	 * @see <a href="http://haxe.org/ref/iterators" target="_blank">http://haxe.org/ref/iterators</a>
	 */
	public function iterator():Itr<T>
	{
		if (reuseIterator)
		{
			if (_iterator == null)
				return new LinkedQueueIterator<T>(this);
			else
				_iterator.reset();
			return _iterator;
		}
		else
			return new LinkedQueueIterator<T>(this);
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
	 * Returns true if this queue is empty.
	 * <o>1</o>
	 */
	inline public function isEmpty():Bool
	{
		return _size == 0;
	}
	
	/**
	 * Returns an array containing all elements in this queue.<br/>
	 * Preserves the natural order of this queue (First-In-First-Out).
	 */
	public function toArray():Array<T>
	{
		var a:Array<T> = ArrayUtil.alloc(size());
		var i = 0;
		var node = _head;
		while (node != null)
		{
			a[i++] = node.val;
			node = node.next;
		}
		return a;
	}
	
	#if flash10
	/**
	 * Returns a Vector.&lt;T&gt; object containing all elements in this queue.<br/>
	 * Preserves the natural order of this queue (First-In-First-Out).
	 */
	public function toVector():flash.Vector<Dynamic>
	{
		var a = new flash.Vector<Dynamic>(size());
		var i = 0;
		var node = _head;
		while (node != null)
		{
			a[i++] = node.val;
			node = node.next;
		}
		return a;
	}
	#end
	
	/**
	 * Duplicates this queue. Supports shallow (structure only) and deep copies (structure & elements).
	 * @param assign if true, the <code>copier</code> parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.<br/>
	 * If false, the <em>clone()</em> method is called on each element. <warn>In this case all elements have to implement <em>Cloneable</em>.</warn>
	 * @param copier a custom function for copying elements. Replaces element.<em>clone()</em> if <code>assign</code> is false.
	 * @throws de.polygonal.ds.error.AssertError element is not of type <em>Cloneable</em> (debug only).
	 */
	public function clone(assign = true, copier:T->T = null):Collection<T>
	{
		var copy = new LinkedQueue<T>(_reservedSize, maxSize);
		if (_size == 0) return copy;
		
		if (assign)
		{
			var node = _head;
			if (node != null)
			{
				copy._head = copy._tail = new LinkedQueueNode<T>(node.val);
				copy._head.next = copy._tail;
			}
			
			if (_size > 1)
			{
				node = node.next;
				while (node != null)
				{
					var t = new LinkedQueueNode<T>(node.val);
					copy._tail = copy._tail.next = t;
					node = node.next;
				}
			}
		}
		else
		if (copier == null)
		{
			var node = _head;
			if (node != null)
			{
				#if debug
				assert(Std.is(node.val, Cloneable), 'element is not of type Cloneable (${node.val})');
				#end
				var c = cast(node.val, Cloneable<Dynamic>);
				copy._head = copy._tail = new LinkedQueueNode<T>(c.clone());
				copy._head.next = copy._tail;
			}
			
			if (_size > 1)
			{
				node = node.next;
				while (node != null)
				{
					#if debug
					assert(Std.is(node.val, Cloneable), 'element is not of type Cloneable (${node.val})');
					#end
					var c = cast(node.val, Cloneable<Dynamic>);
					var t = new LinkedQueueNode<T>(c.clone());
					copy._tail = copy._tail.next = t;
					node = node.next;
				}
			}
		}
		else
		{
			var node = _head;
			if (node != null)
			{
				copy._head = copy._tail = new LinkedQueueNode<T>(copier(node.val));
				copy._head.next = copy._tail;
			}
			if (_size > 1)
			{
				node = node.next;
				while (node != null)
				{
					var t = new LinkedQueueNode<T>(copier(node.val));
					copy._tail = copy._tail.next = t;
					node = node.next;
				}
			}
		}
		
		copy._size = _size;
		return copy;
	}
	
	inline function _getNode(x:T)
	{
		if (_reservedSize == 0 || _poolSize == 0)
			return new LinkedQueueNode<T>(x);
		else
		{
			var n = _headPool;
			_headPool = _headPool.next;
			_poolSize--;
			
			n.val = x;
			return n;
		}
	}
	
	inline function _putNode(x:LinkedQueueNode<T>):T
	{
		var val = x.val;
		
		if (_reservedSize > 0 && _poolSize < _reservedSize)
		{
			_tailPool = _tailPool.next = x;
			x.val = cast null;
			x.next = null;
			_poolSize++;
		}
		return val;
	}
	
	inline function _removeNode(x:LinkedQueueNode<T>)
	{
		var n = _head;
		if (x == n)
		{
			_head = x.next;
			if (x == _tail)
				_tail = null;
		}
		else
		{
			while (n.next != x) n = n.next;
			if (x == _tail)
				_tail = null;
			n.next = x.next;
		}
		_putNode(x);
		_size--;
	}
}

#if generic
@:generic
#end
#if doc
private
#end
class LinkedQueueNode<T>
{
	public var val:T;
	public var next:LinkedQueueNode<T>;
	
	public function new(x:T)
	{
		val = x;
	}
	
	public function toString():String
	{
		return "" + val;
	}
}

#if generic
@:generic
#end
#if doc
private
#end
class LinkedQueueIterator<T> implements de.polygonal.ds.Itr<T>
{
	var _f:LinkedQueue<T>;
	var _walker:LinkedQueueNode<T>;
	var _hook:LinkedQueueNode<T>;
	
	public function new(f:LinkedQueue<T>)
	{
		_f = f;
		reset();
	}
	
	inline public function reset():Itr<T>
	{
		_walker = __head(_f);
		_hook = null;
		return this;
	}
	
	inline public function hasNext():Bool
	{
		return _walker != null;
	}
	
	inline public function next():T
	{
		var x = _walker.val;
		_hook = _walker;
		_walker = _walker.next;
		return x;
	}
	
	inline public function remove()
	{
		#if debug
		assert(_hook != null, "call next() before removing an element");
		#end
		
		#if flash
		__remove(_f, _hook);
		#else
		var f:LinkedQueueFriend<T> = _f;
		f._removeNode(_hook);
		#end
	}
	
	inline function __head(f:LinkedQueueFriend<T>)
	{
		return f._head;
	}
	
	#if flash
	inline function __remove(f:LinkedQueueFriend<T>, x:LinkedQueueNode<T>)
	{
		return f._removeNode(x);
	}
	#end
}