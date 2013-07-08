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

private typedef SLLNodeFriend<T> =
{
	private function _insertAfter(node:SLLNode<T>):Void;
	private var _list:SLL<T>;
}

/**
 * <p>A singly linked list.</p>
 * <p>See <a href="http://lab.polygonal.de/?p=206" target="_blank">http://lab.polygonal.de/?p=206</a></p>
 * <p><o>Worst-case running time in Big O notation</o></p>
 */
#if generic
@:generic
#end
class SLL<T> implements Collection<T>
{
	/**
	 * A unique identifier for this object.<br/>
	 * A hash table transforms this key into an index of an array element by using a hash function.<br/>
	 * <warn>This value should never be changed by the user.</warn>
	 */
	public var key:Int;
	
	/**
	 * The head of this list or null if this list is empty. 
	 */
	public var head:SLLNode<T>;
	
	/**
	 * The tail of this list or null if this list is empty. 
	 */
	public var tail:SLLNode<T>;
	
	/**
	 * The maximum allowed size of this list.<br/>
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
	
	var _size:Int;
	var _reservedSize:Int;
	var _poolSize:Int;
	
	var _headPool:SLLNode<T>;
	var _tailPool:SLLNode<T>;
	
	var _circular:Bool;
	var _iterator:Itr<T>;
	
	/**
	 * @param reservedSize if &gt; 0, this list maintains an object pool of node objects.<br/>
	 * Prevents frequent node allocation and thus increases performance at the cost of using more memory.
	 * @param maxSize the maximum allowed size of this list.<br/>
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
		_circular     = false;
		_iterator     = null;    
		
		if (reservedSize > 0)
		{
			_headPool = _tailPool = new SLLNode<T>(cast null, this);
		}
		
		head = tail = null;
		
		key = HashKey.next();
		reuseIterator = false;
	}
	
	/**
	 * Returns true if this list is circular.<br/>
	 * A list is circular if the tail points to the head.
	 * <o>1</o>
	 */
	public function isCircular():Bool
	{
		return _circular;
	}
	
	/**
	 * Makes this list circular by connecting the tail to the head.<br/>
	 * Silently fails if this list is already closed.
	 * <o>1</o>
	 */
	public function close()
	{
		if (_circular) return;
		_circular = true;
		if (_valid(head))
			tail.next = head;
	}
	
	/**
	 * Makes this list non-circular by disconnecting the tail from the head and vice versa.<br/>
	 * Silently fails if this list is already non-circular.
	 * <o>1</o>
	 */
	public function open()
	{
		if (!_circular) return;
		_circular = false;
		if (_valid(head))
			tail.next = null;
	}
	
	/**
	 * Creates and returns a new <code>SLLNode</code> object storing the value <code>x</code> and pointing to this list.
	 * <o>1</o>
	 */
	inline public function createNode(x:T):SLLNode<T>
	{
		return new SLLNode<T>(x, this);
	}
	
	/**
	 * Appends the element <code>x</code> to the tail of this list by creating a <em>SLLNode</em> object storing <code>x</code>.
	 * <o>1</o>
	 * @return the appended node storing <code>x</code>.
	 * @throws de.polygonal.ds.error.AssertError <em>size()</em> equals <em>maxSize</em> (debug only).
	 */
	inline public function append(x:T):SLLNode<T>
	{
		#if debug
		if (maxSize != -1)
			assert(size() < maxSize, 'size equals max size ($maxSize)');
		#end
		
		var node = _getNode(x);
		if (_valid(tail))
			tail.next = node;
		else
			head = node;
		tail = node;
		
		if (_circular)
			tail.next = head;
		
		_size++;
		return node;
	}
	
	/**
	 * Appends the node <code>x</code> to this list.
	 * <o>1</o>
	 */
	inline public function appendNode(x:SLLNode<T>)
	{
		#if debug
		assert(x.getList() == this, "node is not managed by this list");
		#end
		
		if (_valid(tail))
			tail.next = x;
		else
			head = x;
		tail = x;
		
		if (_circular)
			tail.next = head;
		
		_size++;
	}
	
	/**
	 * Prepends the element <code>x</code> to the head of this list by creating a <em>SLLNode</em> object storing <code>x</code>.
	 * <o>1</o>
	 * @return the prepended node storing <code>x</code>.
	 * @throws de.polygonal.ds.error.AssertError <em>size()</em> equals <em>maxSize</em> (debug only).
	 */
	inline public function prepend(x:T):SLLNode<T>
	{
		#if debug
		if (maxSize != -1)
			assert(size() < maxSize, 'size equals max size ($maxSize)');
		#end
		
		var node = _getNode(x);
		if (_valid(tail))
			node.next = head;
		else
			tail = node;
		head = node;
		
		if (_circular)
			tail.next = head;
		
		_size++;
		return node;
	}
	
	/**
	 * Prepends the node <code>x</code> to this list.
	 * <o>1</o>
	 */
	public function prependNode(x:SLLNode<T>)
	{
		#if debug
		assert(x.getList() == this, "node is not managed by this list");
		#end
		
		if (_valid(tail))
			x.next = head;
		else
			tail = x;
		head = x;
		
		if (_circular)
			tail.next = head;
		
		_size++;
	}
	
	/**
	 * Inserts the element <code>x</code> after <code>node</code> by creating a <em>SLLNode</em> object storing <code>x</code>.
	 * <o>1</o>
	 * @return the inserted node storing <code>x</code>.
	 * @throws de.polygonal.ds.error.AssertError <code>node</code> is null or not managed by this list (debug only).
	 */
	inline public function insertAfter(node:SLLNode<T>, x:T):SLLNode<T>
	{
		#if debug
		if (maxSize != -1)
			assert(size() < maxSize, 'size equals max size ($maxSize)');
		assert(_valid(node), "node is null");
		assert(node.getList() == this, "node is not managed by this list");
		#end
		
		var t = _getNode(x);
		__insertAfter(node, t);
		
		if (node == tail)
		{
			tail = t;
			if (_circular)
				tail.next = head;
		}
		_size++;
		return t;
	}
	
	/**
	 * Inserts the element <code>x</code> before <code>node</code> by creating a <em>SLLNode</em> object storing <code>x</code>.
	 * <o>1</o>
	 * @return the inserted node storing <code>x</code>.
	 * @throws de.polygonal.ds.error.AssertError <code>node</code> is null or not managed by this list (debug only).
	 */
	inline public function insertBefore(node:SLLNode<T>, x:T):SLLNode<T>
	{
		#if debug
		if (maxSize != -1)
			assert(size() < maxSize, 'size equals max size ($maxSize)');
		assert(_valid(node), "node is null");
		assert(node.getList() == this, "node is not managed by this list");
		#end
		
		var t = _getNode(x);
		if (node == head)
		{
			t.next = head;
			head = t;
			
			if (_circular)
				tail.next = head;
		}
		else
			__insertAfter(_getNodeBefore(node), t);
		
		_size++;
		return t;
	}
	
	/**
	 * Unlinks <code>node</code> from this list and returns <code>node</code>.<em>next</em>;.
	 * <o>n</o>
	 * @throws de.polygonal.ds.error.AssertError list is empty (debug only).
	 * @throws de.polygonal.ds.error.AssertError <code>node</code> is null or not managed by this list (debug only).
	 */
	inline public function unlink(node:SLLNode<T>):SLLNode<T>
	{
		#if debug
		assert(_valid(node), "node is null");
		assert(node.getList() == this, "node is not managed by this list");
		assert(_size > 0, "list is empty");
		#end
		
		var hook = node.next;
		
		if (node == head)
			removeHead();
		else
		{
			var t = _getNodeBefore(node);
			if (t.next == tail)
			{
				if (_circular)
				{
					tail = t;
					t.next = head;
				}
				else
				{
					tail = t;
					t.next = null;
				}
			}
			else
				t.next = hook;
			
			node.next = null;
			_putNode(node);
			_size--;
		}
		
		return hook;
	}
	
	/**
	 * Returns the node at "index" <code>i</code>.<br/>
	 * The index is measured relative to the head node (= index 0).
	 * <o>n</o>
	 * @throws de.polygonal.ds.error.AssertError list is empty (debug only).
	 * @throws de.polygonal.ds.error.AssertError index out of range (debug only).
	 */
	inline public function getNodeAt(i:Int):SLLNode<T>
	{
		#if debug
		assert(_size > 0, "list is empty");
		assert(i >= 0 || i < _size, 'i index out of range ($i)');
		#end
		
		var node = head;
		for (j in 0...i) node = node.next;
		return node;
	}
	
	/**
	 * Removes the head node and returns the element stored in this node.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError list is empty (debug only).
	 */
	inline public function removeHead():T
	{
		#if debug
		assert(_size > 0, "list is empty");
		#end
		
		var node = head;
		if (_size > 1)
		{
			head = head.next;
			
			if (_circular)
				tail.next = head;
		}
		else
			head = tail = null;
		
		_size--;
		
		node.next = null;
		return _putNode(node);
	}
	
	/**
	 * Removes the tail node and returns the element stored in this node.
	 * <o>n</o>
	 * @throws de.polygonal.ds.error.AssertError list is empty (debug only).
	 */
	inline public function removeTail():T
	{
		#if debug
		assert(_size > 0, "list is empty");
		#end
		
		var node = tail;
		if (_size > 1)
		{
			var t = _getNodeBefore(tail);
			tail = t;
			
			if (_circular)
				t.next = head;
			else
				t.next = null;
			_size--;
		}
		else
		{
			head = tail = null;
			_size = 0;
		}
		
		node.next = null;
		return _putNode(node);
	}
	
	/**
	 * Unlinks the head node and appends it to the tail.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError list is empty (debug only).
	 */
	inline public function shiftUp()
	{
		#if debug
		assert(_size > 0, "list is empty");
		#end
		
		if (_size > 1)
		{
			var t = head;
			if (head.next == tail)
			{
				head = tail;
				tail = t;
				t.next = _circular ? head : null;
				head.next = tail;
			}
			else
			{
				head = head.next;
				tail.next = t;
				t.next = _circular ? head : null;
				tail = t;
			}
		}
	}
	
	/**
	 * Unlinks the tail node and prepends it to the head.
	 * <o>n</o>
	 * @throws de.polygonal.ds.error.AssertError list is empty (debug only).
	 */
	inline public function popDown()
	{
		#if debug
		assert(_size > 0, "list is empty");
		#end
		
		if (_size > 1)
		{
			var t = tail;
			if (head.next == tail)
			{
				tail = head;
				head = t;
				t.next = _circular ? head : null;
				head.next = tail;
			}
			else
			{
				var node = head;
				while (node.next != tail)
					node = node.next;
				tail = node;
				tail.next = _circular ? t : null;
				t.next = head;
				head = t;
			}
		}
	}
	
	/**
	 * Searches for the element <code>x</code> in this list from head to tail starting at node <code>from</code>.
	 * <o>n</o>
	 * @return the node containing <code>x</code> or null if such a node does not exist.<br/>
	 * If <code>from</code> is null, the search starts at the head of this list.
	 * @throws de.polygonal.ds.error.AssertError <code>from</code> is not managed by this list (debug only).
	 */
	public function nodeOf(x:T, from:SLLNode<T> = null):SLLNode<T>
	{
		#if debug
		if (_valid(from))
			assert(from.getList() == this, "node is not managed by this list");
		#end
		
		var node = (from == null) ? head : from;
		while (_valid(node))
		{
			if (node.val == x) break;
			node = node.next;
		}
		return node;
	}
	
	/**
	 * Sorts the elements of this list using the merge sort algorithm.
	 * <o>n log n for merge sort and n&sup2; for insertion sort</o>
	 * @param compare a comparison function.<br/>
	 * If null, the elements are compared using element.<em>compare()</em>.<br/>
	 * <warn>In this case all elements have to implement <em>Comparable</em>.</warn>
	 * @param useInsertionSort if true, the linked list is sorted using the insertion sort algorithm.
	 * This is faster for nearly sorted lists.
	 * @throws de.polygonal.ds.error.AssertError element does not implement <em>Comparable</em> (debug only).
	 */
	public function sort(compare:T->T->Int, useInsertionSort = false)
	{
		if (_size > 1)
		{
			if (_circular) tail.next = null;
			
			if (compare == null)
			{
				head = useInsertionSort ? _insertionSortComparable(head) : _mergeSortComparable(head);
			}
			else
			{
				head = useInsertionSort ? _insertionSort(head, compare) : _mergeSort(head, compare);
			}
			
			if (_circular) tail.next = head;
		}
	}
	
	/**
	 * Merges this list with the list <code>x</code> by linking both lists together.<br/>
	 * <warn>The merge operation destroys x so it should be discarded.</warn>
	 * <o>n</o>
	 * @throws de.polygonal.ds.error.AssertError <code>x</code> is null or this list equals <code>x</code> (debug only).
	 */
	public function merge(x:SLL<T>)
	{
		#if debug
		if (maxSize != -1)
			assert(size() + x.size() <= maxSize, 'size equals max size ($maxSize)');
		assert(x != this, "x equals this list");
		assert(x != null, "x is null");
		#end
		
		if (_valid(x.head))
		{
			var node = x.head;
			for (i in 0...x.size())
			{
				__list(node, this);
				node = node.next;
			}
			
			if (_valid(head))
			{
				tail.next = x.head;
				tail = x.tail;
			}
			else
			{
				head = x.head;
				tail = x.tail;
			}
			
			_size += x.size();
			
			if (_circular)
				tail.next = head;
		}
	}
	
	/**
	 * Concatenates this list with the list <code>x</code> by appending all elements of <code>x</code> to this list.<br/>
	 * This list and <code>x</code> are untouched.
	 * <o>n</o>
	 * @return a new list containing the elements of both lists.
	 * @throws de.polygonal.ds.error.AssertError <code>x</code> is null or this equals <code>x</code> (debug only).
	 */
	public function concat(x:SLL<T>):SLL<T>
	{
		#if debug
		assert(x != null, "x is null");
		assert(x != this, "x equals this list");
		#end
		
		var c = new SLL<T>();
		var node = head;
		for (i in 0..._size)
		{
			c.append(node.val);
			node = node.next;
		}
		node = x.head;
		for (i in 0...x._size)
		{
			c.append(node.val);
			node = node.next;
		}
		
		return c;
	}
	
	/**
	 * Reverses the linked list in place.
	 * <o>n</o>
	 */
	public function reverse()
	{
		if (_size > 1)
		{
			var v = new Array<T>();
			var node = head;
			for (i in 0..._size)
			{
				v[i] = node.val;
				node = node.next;
			}
			
			v.reverse();
			
			var node = head;
			for (i in 0..._size)
			{
				node.val = v[i];
				node = node.next;
			}
		}
	}
	
	/**
	 * Converts the data in the linked list to strings, inserts <code>x</code> between the elements, concatenates them, and returns the resulting string.
	 * <o>n</o>
	 */
	public function join(x:String):String
	{
		var s = "";
		if (_size > 0)
		{
			var node = head;
			for (i in 0..._size - 1)
			{
				s += Std.string(node.val) + x;
				node = node.next;
			}
			s += Std.string(node.val);
		}
		return s;
	}
	
	/**
	 * Replaces up to <code>n</code> existing elements with objects of type <code>C</code>.
	 * <o>n</o>
	 * @param C the class to instantiate for each element.
	 * @param args passes additional constructor arguments to <code>C</code>.
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
				assert(n <= size(), 'n out of range ($n)');
			#end
		}
		else
			n = size();
		
		if (args == null) args = [];
		var node = head;
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
	public function fill(x:T, args:Array<Dynamic> = null, n = 0):SLL<T>
	{
		#if debug
		assert(n >= 0, "n >= 0");
		#end
		
		if (n > 0)
		{
			#if debug
			if (maxSize != -1)
				assert(n <= size(), 'n out of range ($n)');
			#end
		}
		else
			n = size();
		
		var node = head;
		for (i in 0...n)
		{
			node.val = x;
			node = node.next;
		}
		
		return this;
	}
	
	/**
	 * Shuffles the elements of this collection by using the Fisher-Yates algorithm.<br/>
	 * <o>n</o>
	 * @param rval a list of random double values in the range between 0 (inclusive) to 1 (exclusive) defining the new positions of the elements.
	 * If omitted, random values are generated on-the-fly by calling <em>Math.random()</em>.
	 * @throws de.polygonal.ds.error.AssertError insufficient random values (debug only).
	 */
	public function shuffle(rval:DA<Float> = null)
	{
		var s = _size;
		
		if (s == 1) return;
		
		if (_circular) tail.next = null;
		
		if (rval == null)
		{
			var m = Math;
			while (s > 1)
			{
				s--;
				var i = Std.int(m.random() * s);
				var node1 = head;
				for (j in 0...s) node1 = node1.next;
				
				var t = node1.val;
				
				var node2 = head;
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
				var node1 = head;
				for (j in 0...s) node1 = node1.next;
				
				var t = node1.val;
				
				var node2 = head;
				for (j in 0...i) node2 = node2.next;
				
				node1.val = node2.val;
				node2.val = t;
			}
		}
		
		if (_circular) tail.next = head;
	}
	
	/**
	 * Returns a string representing the current object.<br/>
	 * Example:<br/>
	 * <pre class="prettyprint">
	 * var list = new de.polygonal.ds.SLL&lt;Int&gt;();
	 * for (i in 0...4) {
	 *     list.append(i);
	 * }
	 * trace(list);</pre>
	 * <pre class="console">
	 * { SLL size: 4 }
 	 * [ head 
	 *   0
	 *   1
	 *   2
	 *   3
	 * tail ]</pre>
	 */
	public function toString():String
	{
		var s = '{ SLL size: ${size()}, circular: ${isCircular()} }';
		if (isEmpty()) return s;
		s += "\n[ head \n";
		var node = head;
		for (i in 0..._size)
		{
			s += '  ${Std.string(node.val)}\n';
			node = node.next;
		}
		s += "] tail";
		return s;
	}
	
	/*///////////////////////////////////////////////////////
	// collection
	///////////////////////////////////////////////////////*/
	
	/**
	 * Destroys this object by explicitly nullifying all nodes, pointers and data for GC'ing used resources.<br/>
	 * Improves GC efficiency/performance (optional).
	 * <o>n</o>
	 */
	public function free()
	{
		var node = head;
		for (i in 0..._size)
		{
			var next = node.next;
			node.free();
			node = next;
		}
		head = tail = null;
		
		var node = _headPool;
		while (_valid(node))
		{
			var next = node.next;
			node.free();
			node = next;
		}
		
		_headPool = _tailPool = null;
		_iterator = null;
	}
	
	/**
	 * Returns true if this list contains a node storing the element <code>x</code>.
	 * <o>n</o>
	 */
	public function contains(x:T):Bool
	{
		var node = head;
		for (i in 0..._size)
		{
			if (node.val == x) return true;
			node = node.next;
		}
		return false;
	}
	
	/**
	 * Removes all nodes storing the element <code>x</code>.
	 * <o>n</o>
	 * @return true if at least one occurrence of <code>x</code> was removed.
	 */
	public function remove(x:T):Bool
	{
		var s = size();
		if (s == 0) return false;
		
		var node0 = head;
		var node1 = head.next;
		
		for (i in 1..._size)
		{
			if (node1.val == x)
			{
				if (node1 == tail)
				{
					tail = node0;
					if (_circular) tail.next = head;
				}
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
		
		if (head.val == x)
		{
			var head1 = head.next;
			_putNode(head);
			head = head1;
			if (head == null)
				tail = null;
			else
			{
				if (_circular)
					tail.next = head;
			}
			
			_size--;
		}
		
		return size() < s;
	}
	
	/**
	 * Removes all elements.
	 * <o>1 or n if <code>purge</code> is true</o>
	 * @param purge if true, nodes, pointers and elements are nullified upon removal.
	 */
	inline public function clear(purge = false)
	{
		if (purge || _reservedSize > 0)
		{
			var node = head;
			for (i in 0..._size)
			{
				var next = node.next;
				node.next = null;
				_putNode(node);
				node = next;
			}
		}
		
		head = tail = null;
		_size = 0;
	}
	
	/**
	 * Returns a new <em>SLLIterator</em> object to iterate over all elements contained in this singly linked list.<br/>
	 * The elements are visited from head to tail.<br/>
	 * If performance is crucial, use the following loop instead:<br/>
	 * <pre class="prettyprint">
	 * var node = mySLL.head;
	 * while (node != null)
	 * {
	 *     var element = node.val;
	 *     node = node.next;
	 * }
	 * </pre>
	 * @see <a href="http://haxe.org/ref/iterators" target="_blank">http://haxe.org/ref/iterators</a>
	 * 
	 */
	public function iterator():Itr<T>
	{
		if (reuseIterator)
		{
			if (_iterator == null)
			{
				if (_circular)
					return new CircularSLLIterator<T>(this);
				else
					return new SLLIterator<T>(this);
			}
			else
				_iterator.reset();
			return _iterator;
		}
		else
		{
			if (_circular)
				return new CircularSLLIterator<T>(this);
			else
				return new SLLIterator<T>(this);
		}
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
	 * Returns true if this list is empty.
	 * <o>1</o>
	 */
	inline public function isEmpty():Bool
	{
		return _size == 0;
	}
	
	/**
	 * Returns an array containing all elements in this singly linked list.<br/>
	 * The elements are ordered head-to-tail.
	 */
	public function toArray():Array<T>
	{
		var a:Array<T> = ArrayUtil.alloc(size());
		var node = head;
		for (i in 0..._size)
		{
			a[i] = node.val;
			node = node.next;
		}
		return a;
	}
	
	#if flash10
	/**
	 * Returns a vector.&lt;T&gt; objec containing all elements in this singly linked list.<br/>
	 * The elements are ordered head-to-tail.
	 */
	public function toVector():flash.Vector<Dynamic>
	{
		var a = new flash.Vector<Dynamic>(size());
		var node = head;
		for (i in 0..._size)
		{
			a[i] = node.val;
			node = node.next;
		}
		return a;
	}
	#end
	
	/**
	 * Duplicates this linked list. Supports shallow (structure only) and deep copies (structure & elements).
	 * @param assign if true, the <code>copier</code> parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.<br/>
	 * If false, the <em>clone()</em> method is called on each element. <warn>In this case all elements have to implement <em>Cloneable</em>.</warn>
	 * @param copier a custom function for copying elements. Replaces element.<em>clone()</em> if <code>assign</code> is false.
	 * @throws de.polygonal.ds.error.AssertError element is not of type <em>Cloneable</em> (debug only).
	 */
	public function clone(assign = true, copier:T->T = null):Collection<T>
	{
		if (_size == 0)
		{
			var copy = new SLL<T>(_reservedSize, maxSize);
			if (_circular) copy._circular = true;
			return copy;
		}
		
		var copy = new SLL<T>();
		if (_circular) copy._circular = true;
		copy._size = _size;
		
		if (assign)
		{
			var srcNode = head;
			var dstNode = copy.head = new SLLNode<T>(head.val, copy);
			if (_size == 1)
			{
				copy.tail = copy.head;
				if (_circular) copy.tail.next = copy.head;
				return copy;
			}
			srcNode = srcNode.next;
			for (i in 1..._size - 1)
			{
				dstNode = dstNode.next = new SLLNode<T>(srcNode.val, copy);
				srcNode = srcNode.next;
			}
			copy.tail = dstNode.next = new SLLNode<T>(srcNode.val, copy);
		}
		else
		if (copier == null)
		{
			var srcNode = head;
			
			#if debug
			assert(Std.is(head.val, Cloneable), 'element is not of type Cloneable (${head.val})');
			#end
			
			var c = cast(head.val, Cloneable<Dynamic>);
			var dstNode = copy.head = new SLLNode<T>(c.clone(), copy);
			if (_size == 1)
			{
				copy.tail = copy.head;
				if (_circular) copy.tail.next = copy.head;
				return copy;
			}
			srcNode = srcNode.next;
			for (i in 1..._size - 1)
			{
				#if debug
				assert(Std.is(srcNode.val, Cloneable), 'element is not of type Cloneable (${srcNode.val})');
				#end
				
				c = cast(srcNode.val, Cloneable<Dynamic>);
				
				dstNode = dstNode.next = new SLLNode<T>(c.clone(), copy);
				srcNode = srcNode.next;
			}
			
			#if debug
			assert(Std.is(srcNode.val, Cloneable), 'element is not of type Cloneable (${srcNode.val})');
			#end
			
			c = cast(srcNode.val, Cloneable<Dynamic>);
			copy.tail = dstNode.next = new SLLNode<T>(c.clone(), copy);
		}
		else
		{
			var srcNode = head;
			var dstNode = copy.head = new SLLNode<T>(copier(head.val), copy);
			if (_size == 1)
			{
				if (_circular) copy.tail.next = copy.head;
				copy.tail = copy.head;
				return copy;
			}
			srcNode = srcNode.next;
			for (i in 1..._size - 1)
			{
				dstNode = dstNode.next = new SLLNode<T>(copier(srcNode.val), copy);
				srcNode = srcNode.next;
			}
			copy.tail = dstNode.next = new SLLNode<T>(copier(srcNode.val), copy);
		}
		
		if (_circular) copy.tail.next = copy.head;
		return copy;
	}
	
	function _mergeSortComparable(node:SLLNode<T>):SLLNode<T>
	{
		var h = node;
		var p, q, e, tail = null;
		var insize = 1;
		var nmerges, psize, qsize, i;
		while (true)
		{
			p = h;
			h = tail = null;
			nmerges = 0;
			
			while (_valid(p))
			{
				nmerges++;
				
				psize = 0; q = p;
				for (i in 0...insize)
				{
					psize++;
					q = q.next;
					if (q == null) break;
				}
				
				qsize = insize;
				
				while (psize > 0 || (qsize > 0 && _valid(q)))
				{
					if (psize == 0)
					{
						e = q; q = q.next; qsize--;
					}
					else
					if (qsize == 0 || q == null)
					{
						e = p; p = p.next; psize--;
					}
					else
					{
						#if debug
						assert(Std.is(p.val, Comparable), 'element is not of type Comparable (${p.val})');
						#end
						
						if (cast(p.val, Comparable<Dynamic>).compare(q.val) >= 0)
						{
							e = p; p = p.next; psize--;
						}
						else
						{
							e = q; q = q.next; qsize--;
						}
					}
					
					if (_valid(tail))
						tail.next = e;
					else
						h = e;
					
					tail = e;
				}
				p = q;
			}
			
			tail.next = null;
			if (nmerges <= 1) break;
			insize <<= 1;
		}
		
		this.tail = tail;
		return h;
	}
	
	function _mergeSort(node:SLLNode<T>, cmp:T->T->Int):SLLNode<T>
	{
		var h = node;
		var p, q, e, tail = null;
		var insize = 1;
		var nmerges, psize, qsize, i;
		
		while (true)
		{
			p = h;
			h = tail = null;
			nmerges = 0;
			
			while (_valid(p))
			{
				nmerges++;
				
				psize = 0; q = p;
				for (i in 0...insize)
				{
					psize++;
					q = q.next;
					if (q == null) break;
				}
				
				qsize = insize;
				
				while (psize > 0 || (qsize > 0 && _valid(q)))
				{
					if (psize == 0)
					{
						e = q; q = q.next; qsize--;
					}
					else
					if (qsize == 0 || q == null)
					{
						e = p; p = p.next; psize--;
					}
					else
					if (cmp(q.val, p.val) >= 0)
					{
						e = p; p = p.next; psize--;
					}
					else
					{
						e = q; q = q.next; qsize--;
					}
					
					if (_valid(tail))
						tail.next = e;
					else
						h = e;
					
					tail = e;
				}
				p = q;
			}
			
			tail.next = null;
			if (nmerges <= 1) break;
			insize <<= 1;
		}
		
		this.tail = tail;
		return h;
	}
	
	function _insertionSortComparable(node:SLLNode<T>):SLLNode<T>
	{
		var v = new Array<T>();
		var i = 0;
		var t = node;
		while (_valid(t))
		{
			v[i++] = t.val;
			t = t.next;
		}
		
		var h = node;
		var j;
		var val;
		for (i in 1..._size)
		{
			val = v[i];
			j = i;
			
			#if debug
			assert(Std.is(v[j - 1], Comparable), 'element is not of type Comparable (${v[j - 1]})');
			#end
			
			while ((j > 0) && cast(v[j - 1], Comparable<Dynamic>).compare(val) < 0)
			{
				v[j] = v[j - 1];
				j--;
				
				#if debug
				if (j > 0)
					assert(Std.is(v[j - 1], Comparable), 'element is not of type Comparable (${v[j - 1]})');
				#end
				
			}
			v[j] = val;
		}
		
		t = h;
		i = 0;
		while (_valid(t))
		{
			t.val = v[i++];
			t = t.next;
		}
		return h;
	}
	
	function _insertionSort(node:SLLNode<T>, cmp:T->T->Int):SLLNode<T>
	{
		var v = new Array<T>();
		var i = 0;
		var t = node;
		while (_valid(t))
		{
			v[i++] = t.val;
			t = t.next;
		}
		
		var h = node;
		var j;
		var val;
		for (i in 1..._size)
		{
			val = v[i];
			j = i;
			while ((j > 0) && (cmp(val, v[j - 1]) < 0))
			{
				v[j] = v[j - 1];
				j--;
			}
			v[j] = val;
		}
		
		t = h;
		i = 0;
		while (_valid(t))
		{
			t.val = v[i++];
			t = t.next;
		}
		return h;
	}
	
	inline function _valid(node:SLLNode<T>):Bool
	{
		return node != null;
	}
	
	inline function _getNodeBefore(x:SLLNode<T>):SLLNode<T>
	{
		var node = head;
		while (node.next != x)
			node = node.next;
		return node;
	}
	
	inline function _getNode(x:T)
	{
		if (_reservedSize == 0 || _poolSize == 0)
			return new SLLNode<T>(x, this);
		else
		{
			#if debug
			assert(_valid(_headPool.next), "_headPool.next != null");
			#end
			
			var t = _headPool;
			_headPool = _headPool.next;
			_poolSize--;
			t.val = x;
			t.next = null;
			return t;
		}
	}
	
	inline function _putNode(x:SLLNode<T>):T
	{
		var val = x.val;
		
		if (_reservedSize > 0 && _poolSize < _reservedSize)
		{
			#if debug
			assert(x.next == null, "x.next == null");
			#end
			
			_tailPool = _tailPool.next = x;
			x.val = cast null;
			x.next = null;
			_poolSize++;
		}
		else
			__list(x, null);
		
		return val;
	}
	
	inline function __insertAfter(f:SLLNodeFriend<T>, x:SLLNode<T>)
	{
		f._insertAfter(x);
	}
	inline function __list(f:SLLNodeFriend<T>, x:SLL<T>)
	{
		f._list = x;
	}
}

#if generic
@:generic
#end
#if doc
private
#end
class SLLIterator<T> implements de.polygonal.ds.Itr<T>
{
	var _f:SLL<T>;
	var _walker:SLLNode<T>;
	var _hook:SLLNode<T>;
	
	public function new(f:SLL<T>)
	{
		_f = f;
		reset();
	}
	
	inline public function reset():Itr<T>
	{
		_walker = _f.head;
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
		
		_f.unlink(_hook);
	}
}

#if generic
@:generic
#end
#if doc
private
#end
class CircularSLLIterator<T> implements de.polygonal.ds.Itr<T>
{
	var _f:SLL<T>;
	var _walker:SLLNode<T>;
	var _i:Int;
	var _s:Int;
	var _hook:SLLNode<T>;
	
	public function new(f:SLL<T>)
	{
		_f = f;
		reset();
	}
	
	inline public function reset():Itr<T>
	{
		_walker = _f.head;
		_s = _f.size();
		_i = 0;
		_hook = null;
		return this;
	}
	
	inline public function hasNext():Bool
	{
		return _i < _s;
	}
	
	inline public function next():T
	{
		var x = _walker.val;
		_hook = _walker;
		_walker = _walker.next;
		_i++;
		return x;
	}
	
	inline public function remove()
	{
		#if debug
		assert(_i > 0, "call next() before removing an element");
		#end
		
		_f.unlink(_hook);
		_i--;
		_s--;
	}
}