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

private typedef LinkedDequeFriend<T> =
{
	private var _head:LinkedDequeNode<T>;
	private function _removeNode(x:LinkedDequeNode<T>):Void;
}

/**
 * <p>A deque ("double-ended queue") is a linear list for which all insertions and deletions (and usually all accesses) are made at the ends of the list.</p>
 * <p><o>Worst-case running time in Big O notation</o></p>
 */
#if generic
@:generic
#end
class LinkedDeque<T> implements Deque<T>
{
	/**
	 * A unique identifier for this object.<br/>
	 * A hash table transforms this key into an index of an array element by using a hash function.<br/>
	 * <warn>This value should never be changed by the user.</warn>
	 */
	public var key:Int;
	
	/**
	 * The maximum allowed size of this deque.<br/>
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
	
	var _head:LinkedDequeNode<T>;
	var _tail:LinkedDequeNode<T>;
	
	var _headPool:LinkedDequeNode<T>;
	var _tailPool:LinkedDequeNode<T>;
	
	var _size:Int;
	var _reservedSize:Int;
	var _poolSize:Int;
	var _iterator:LinkedDequeIterator<T>;
	
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
		
		_poolSize     = 0;
		_reservedSize = reservedSize;
		_size         = 0;
		_head         = null;
		_tail         = null;
		_iterator     = null;
		_headPool = _tailPool = new LinkedDequeNode<T>(cast null);
		reuseIterator = false;
	}
	
	/**
	 * Returns the first element of this deque.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError deque is empty (debug only).
	 */
	inline public function front():T
	{
		#if debug
		assert(size() > 0, "deque is empty");
		#end
		
		return _head.val;
	}
	
	/**
	 * Inserts the element <code>x</code> at the front of this deque.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError <em>size()</em> equals <em>maxSize</em> (debug only).
	 */
	inline public function pushFront(x:T)
	{
		#if debug
		if (maxSize != -1)
			assert(size() < maxSize, 'size equals max size ($maxSize)');
		#end
		
		var node = _getNode(x);
		node.next = _head;
		if (_head != null) _head.prev = node;
		_head = node;
		
		if (_size++ == 0) _tail = _head;
	}
	
	/**
	 * Removes and returns the element at the beginning of this deque.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError deque is empty (debug only).
	 */
	inline public function popFront():T
	{
		#if debug
		assert(size() > 0, "deque is empty");
		#end
		
		var node = _head;
		_head = _head.next;
		if (_head != null) _head.prev = null;
		node.next = null;
		if (--_size == 0) _tail = null;
		
		return _putNode(node, true);
	}
	
	/**
	 * Returns the last element of the deque.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError deque is empty (debug only).
	 */
	inline public function back():T
	{
		#if debug
		assert(size() > 0, "deque is empty");
		#end
		
		return _tail.val;
	}
	
	/**
	 * Inserts the element <code>x</code> at the back of the deque.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError <em>size()</em> equals <em>maxSize</em> (debug only).
	 */
	inline public function pushBack(x:T)
	{
		#if debug
		if (maxSize != -1)
			assert(size() < maxSize, 'size equals max size ($maxSize)');
		#end
		
		var node = _getNode(x);
		node.prev = _tail;
		if (_tail != null) _tail.next = node;
		_tail = node;
		
		if (_size++ == 0) _head = _tail;
	}
	
	/**
	 * Deletes the element at the end of the deque.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError deque is empty (debug only).
	 */
	inline public function popBack():T
	{
		#if debug
		assert(size() > 0, "deque is empty");
		#end
		
		var node = _tail;
		_tail = _tail.prev;
		node.prev = null;
		if (_tail != null) _tail.next = null;
		if (--_size == 0) _head = null;
		
		return _putNode(node, true);
	}
	
	/**
	 * Returns the element at index <code>i</code> relative to the front of this deque.<br/>
	 * The front element is at index [0], the back element is at index <b>&#091;<em>size()</em> - 1&#093;</b>.
	 * <o>n</o>
	 * @throws de.polygonal.ds.error.AssertError deque is empty (debug only).
	 * @throws de.polygonal.ds.error.AssertError index out of range (debug only).
	 */
	public function getFront(i:Int):T
	{
		#if debug
		assert(i < size(), 'index out of range ($i)');
		#end
		
		var node = _head;
		for (j in 0...i) node = node.next;
		return node.val;
	}
	
	/**
	 * Returns the index of the first occurence of the element <code>x</code> or -1 if <code>x</code> does not exist.
	 * The front element is at index [0], the back element is at index &#091;<em>size()</em> - 1&#093;.
	 * <o>n</o>
	 */
	public function indexOfFront(x:T):Int
	{
		var node = _head;
		for (i in 0..._size)
		{
			if (node.val == x) return i;
			node = node.next;
		}
		return -1;
	}
	
	/**
	 * Returns the element at index <code>i</code> relative to the back of this deque.<br/>
	 * The back element is at index [0], the front element is at index &#091;<em>size()</em> - 1&#093;.
	 * <o>n</o>
	 * @throws de.polygonal.ds.error.AssertError deque is empty (debug only).
	 * @throws de.polygonal.ds.error.AssertError index out of range (debug only).
	 */
	public function getBack(i:Int):T
	{
		#if debug
		assert(i < size(), 'index out of range ($i)');
		#end
		
		var node = _tail;
		for (j in 0...i) node = node.prev;
		return node.val;
	}
	
	/**
	 * Returns the index of the first occurence of the element <code>x</code> or -1 if <code>x</code> does not exist.
	 * The back element is at index [0], the front element is at index &#091;<em>size()</em> - 1&#093;.
	 * <o>n</o>
	 */
	public function indexOfBack(x:T):Int
	{
		var node = _tail;
		for (i in 0..._size)
		{
			if (node.val == x) return i;
			node = node.prev;
		}
		return -1;
	}
	
	/**
	 * Replaces up to <code>n</code> existing elements with objects of type <code>C</code>.
	 * <o>n</o>
	 * @param C the class to instantiate for each element.
	 * @param args passes additional constructor arguments to the class <code>C</code>.
	 * @param n the number of elements to replace. If 0, <code>n</code> is set to <em>size()</em>.
	 */
	public function assign(C:Class<T>, args:Array<Dynamic> = null, n = 0)
	{
		if (n == 0) n = size();
		if (n == 0) return;
		
		if (args == null) args = [];
		var k = M.min(_size, n);
		var node = _head;
		for (i in 0...k)
		{
			node.val = Type.createInstance(C, args);
			node = node.next;
		}
		
		n -= k;
		for (i in 0...n)
		{
			node = _getNode(Type.createInstance(C, args));
			node.prev = _tail;
			if (_tail != null) _tail.next = node;
			_tail = node;
			if (_size++ == 0) _head = _tail;
		}
	}
	
	/**
	 * Replaces up to <code>n</code> existing elements with the instance of <code>x</code>.<br/>
	 * If size() &lt; <code>n</code>, additional elements are added to the back of this deque.
	 * <o>n</o>
	 * @param n the number of elements to replace. If 0, <code>n</code> is set to <em>size()</em>.
	 */
	public function fill(x:T, n = 0):LinkedDeque<T>
	{
		if (n == 0) n = size();
		if (n == 0) return this;
		
		var k = M.min(_size, n);
		var node = _head;
		for (i in 0...k)
		{
			node.val = x;
			node = node.next;
		}
		
		n -= k;
		for (i in 0...n)
		{
			node = _getNode(x);
			node.prev = _tail;
			if (_tail != null) _tail.next = node;
			_tail = node;
			if (_size++ == 0) _head = _tail;
		}
		
		return this;
	}
	
	/**
	 * Returns a string representing the current object.<br/>
	 * Example:<br/>
	 * <pre class="prettyprint">
	 * var deque = new de.polygonal.ds.LinkedDeque&lt;Int&gt;();
	 * for (i in 0...4) {
	 *     deque.pushFront(i);
	 * }
	 * trace(deque);</pre>
	 * <pre class="console">
	 * { LinkedDeque, size: 4 }
	 * [ front
	 *   0 -> 3
	 *   1 -> 2
	 *   2 -> 1
	 *   3 -> 0
	 * ]</pre>
	 */
	public function toString():String
	{
		var s = '{ LinkedDeque size: ${size()} }';
		if (isEmpty()) return s;
		s += "\n[ front\n";
		var i = 0;
		var node = _head;
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
	 * Destroys this object by explicitly nullifying all elements for GC'ing used resources.<br/>
	 * Improves GC efficiency/performance (optional).
	 * <o>n</o>
	 */
	public function free()
	{
		var node = _head;
		while (node != null)
		{
			var next = node.next;
			node.next = node.prev = null;
			node.val = cast null;
			node = next;
		}
		
		_head = _tail = null;
		
		var node = _headPool;
		while (node != null)
		{
			var next = node.next;
			node.next = node.prev = null;
			node.val = cast null;
			node = next;
		}
		
		_headPool = _tailPool = null;
		_iterator = null;
	}
	
	/**
	 * Returns true if this deque contains the element <code>x</code>.
	 * <o>n</o>
	 */
	public function contains(x:T):Bool
	{
		var found = false;
		var node = _head;
		while (node != null)
		{
			if (node.val == x)
			{
				found = true;
				break;
			}
			node = node.next;
		}
		
		return found;
	}
	
	/**
	 * Removes and nullifies all occurrences of the element <code>x</code>.
	 * <o>n</o>
	 * @return true if at least one occurrence of <code>x</code> was removed.
	 */
	public function remove(x:T):Bool
	{
		var found = false;
		var node = _head;
		while (node != null)
		{
			if (node.val == x)
			{
				found = true;
				
				var next = node.next;
				if (node.prev != null) node.prev.next = node.next;
				if (node.next != null) node.next.prev = node.prev;
				if (node == _head) _head = _head.next;
				if (node == _tail) _tail = _tail.prev;
				_putNode(node, true);
				
				_size--;
				node = _head;
			}
			else
				node = node.next;
		}
		return found;
	}
	
	/**
	 * Removes all elements.
	 * <o>n</o>
	 * @param purge if true, elements are nullified upon removal and the node pool is cleared.
	 */
	public function clear(purge = false)
	{
		if (purge)
		{
			var node = _head;
			while (node != null)
			{
				var next = node.next;
				_putNode(node, true);
				node = next;
			}
			
			if (_reservedSize > 0)
			{
				var node = _headPool;
				while (node != null)
				{
					var next = node.next;
					node.next = node.prev = null;
					node.val = cast null;
					node = next;
				}
			}
		}
		
		_head = _tail = null;
		_size = 0;
	}
	
	/**
	 * Returns a new <em>LinkedDequeIterator</em> object to iterate over all elements contained in this deque.<br/>
	 * Preserves the natural order of a deque.
	 * @see <a href="http://haxe.org/ref/iterators" target="_blank">http://haxe.org/ref/iterators</a>
	 */
	public function iterator():Itr<T>
	{
		if (reuseIterator)
		{
			if (_iterator == null)
				return new LinkedDequeIterator<T>(this);
			else
				_iterator.reset();
			return _iterator;
		}
		else
			return new LinkedDequeIterator<T>(this);
	}
	
	/**
	 * Returns true if this deque is empty.
	 * <o>1</o>
	 */
	inline public function isEmpty():Bool
	{
		return _size == 0;
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
	 * Returns an array containing all elements in this deque in the natural order.
	 */
	public function toArray():Array<T>
	{
		var a = ArrayUtil.alloc(size());
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
	 * Returns a Vector.&lt;T&gt; object containing all elements in this deque in the natural order.
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
	 * Duplicates this deque. Supports shallow (structure only) and deep copies (structure & elements).
	 * @param assign if true, the <code>copier</code> parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.<br/>
	 * If false, the <em>clone()</em> method is called on each element. <warn>In this case all elements have to implement <em>Cloneable</em>.</warn>
	 * @param copier a custom function for copying elements. Replaces element.<em>clone()</em> if <code>assign</code> is false.
	 * @throws de.polygonal.ds.error.AssertError element is not of type <em>Cloneable</em> (debug only).
	 */
	public function clone(assign = true, copier:T->T = null):Collection<T>
	{
		if (_size == 0) return new LinkedDeque<T>(_reservedSize, maxSize);
		
		var copy           = new LinkedDeque<T>(_reservedSize, maxSize);
		copy.key           = HashKey.next();
		copy.maxSize       = maxSize;
		copy._size         = _size;
		copy._reservedSize = _reservedSize;
		copy._poolSize     = _poolSize;
		copy._headPool     = new LinkedDequeNode<T>(cast null);
		copy._tailPool     = new LinkedDequeNode<T>(cast null);
		
		if (assign)
		{
			var srcNode = _head;
			var dstNode = copy._head = new LinkedDequeNode<T>(_head.val);
			
			if (_size == 1)
			{
				copy._tail = copy._head;
				return copy;
			}
			
			var dstNode0, srcNode0;
			srcNode = srcNode.next;
			for (i in 1..._size - 1)
			{
				dstNode0 = dstNode;
				srcNode0 = srcNode;
				
				dstNode = dstNode.next = new LinkedDequeNode<T>(srcNode.val);
				dstNode.prev = dstNode0;
				
				srcNode0 = srcNode;
				srcNode = srcNode0.next;
			}
			
			dstNode0 = dstNode;
			copy._tail = dstNode.next = new LinkedDequeNode<T>(srcNode.val);
			copy._tail.prev = dstNode0;
		}
		else
		if (copier == null)
		{
			var srcNode = _head;
			
			#if debug
			assert(Std.is(_head.val, Cloneable), 'element is not of type Cloneable (${_head.val})');
			#end
			
			var c:Cloneable<T> = untyped _head.val;
			var dstNode = copy._head = new LinkedDequeNode<T>(c.clone());
			
			if (_size == 1)
			{
				copy._tail = copy._head;
				return copy;
			}
			
			var dstNode0;
			srcNode = srcNode.next;
			for (i in 1..._size - 1)
			{
				dstNode0 = dstNode;
				var srcNode0 = srcNode;
				
				#if debug
				assert(Std.is(srcNode.val, Cloneable), 'element is not of type Cloneable (${srcNode.val})');
				#end
				c = untyped srcNode.val;
				dstNode = dstNode.next = new LinkedDequeNode<T>(c.clone());
				dstNode.prev = dstNode0;
				
				srcNode0 = srcNode;
				srcNode = srcNode0.next;
			}
			
			#if debug
			assert(Std.is(srcNode.val, Cloneable), 'element is not of type Cloneable (${srcNode.val})');
			#end
			c = untyped srcNode.val;
			dstNode0 = dstNode;
			copy._tail = dstNode.next = new LinkedDequeNode<T>(c.clone());
			copy._tail.prev = dstNode0;
		}
		else
		{
			var srcNode = _head;
			var dstNode = copy._head = new LinkedDequeNode<T>(copier(_head.val));
			
			if (_size == 1)
			{
				copy._tail = copy._head;
				return copy;
			}
			
			var dstNode0;
			srcNode = srcNode.next;
			for (i in 1..._size - 1)
			{
				dstNode0 = dstNode;
				var srcNode0 = srcNode;
				
				dstNode = dstNode.next = new LinkedDequeNode<T>(copier(srcNode.val));
				dstNode.prev = dstNode0;
				
				srcNode0 = srcNode;
				srcNode = srcNode0.next;
			}
			
			dstNode0 = dstNode;
			copy._tail = dstNode.next = new LinkedDequeNode<T>(copier(srcNode.val));
			copy._tail.prev = dstNode0;
		}
		
		return copy;
	}
	
	inline function _getNode(x:T)
	{
		if (_reservedSize == 0 || _poolSize == 0)
			return new LinkedDequeNode<T>(x);
		else
		{
			var node = _headPool;
			_headPool = _headPool.next;
			_poolSize--;
			node.val = x;
			return node;
		}
	}
	
	inline function _putNode(x:LinkedDequeNode<T>, nullify:Bool):T
	{
		var val = x.val;
		if (_reservedSize > 0)
		{
			if (_poolSize < _reservedSize)
			{
				_tailPool = _tailPool.next = x;
				_poolSize++;
				if (nullify)
				{
					x.prev = x.next = null;
					x.val = cast null;
				}
			}
		}
		return val;
	}
	
	inline function _removeNode(x:LinkedDequeNode<T>)
	{
		var next = x.next;
		if (x.prev != null) x.prev.next = x.next;
		if (x.next != null) x.next.prev = x.prev;
		if (x == _head) _head = _head.next;
		if (x == _tail) _tail = _tail.prev;
		_putNode(x, true);
		_size--;
	}
}

#if generic
@:generic
#end
#if doc
private
#end
class LinkedDequeNode<T>
{
	public var val:T;
	public var prev:LinkedDequeNode<T>;
	public var next:LinkedDequeNode<T>;
	
	public function new(x:T)
	{
		val  = x;
		next = null;
		prev = null;
	}
	
	public function toString():String
	{
		return 'LinkedDequeNode{${Std.string(val)}}';
	}
}

#if generic
@:generic
#end
#if doc
private
#end
class LinkedDequeIterator<T> implements de.polygonal.ds.Itr<T>
{
	var _f:LinkedDeque<T>;
	var _walker:LinkedDequeNode<T>;
	var _hook:LinkedDequeNode<T>;
	
	public function new(f:LinkedDeque<T>)
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
		var x:T = _walker.val;
		_hook = _walker;
		_walker = _walker.next;
		return x;
	}
	
	inline public function remove()
	{
		#if debug
		assert(_hook != null, "call next() before removing an element");
		#end
		
		__removeNode(_f, _hook);
	}
	
	inline function __head(f:LinkedDequeFriend<T>)
	{
		return f._head;
	}
	inline function __removeNode(f:LinkedDequeFriend<T>, x:LinkedDequeNode<T>)
	{
		f._removeNode(x);
	}
}