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
	<h3>A doubly linked list.</h3>
	
	See <a href="http://lab.polygonal.de/?p=206" target="mBlank">http://lab.polygonal.de/?p=206</a>
	
	_<o>Worst-case running time in Big O notation</o>_
**/
#if (flash && generic)
@:generic
#end
@:access(de.polygonal.ds.DLLNode)
class DLL<T> implements Collection<T>
{
	/**
		A unique identifier for this object.
		
		A hash table transforms this key into an index of an array element by using a hash function.
		
		<warn>This value should never be changed by the user.</warn>
	**/
	public var key:Int;
	
	/**
		The head of this list or null if this list is empty.
	**/
	public var head(default, null):DLLNode<T>;
	
	/**
		The tail of this list or null if this list is empty.
	**/
	public var tail(default, null):DLLNode<T>;
	
	/**
		The maximum allowed size of this list.
		
		Once the maximum size is reached, adding an element will fail with an error (debug only).
		
		A value of -1 indicates that the size is unbound.
		
		<warn>Always equals -1 in release mode.</warn>
	**/
	public var maxSize:Int;
	
	/**
		If true, reuses the iterator object instead of allocating a new one when calling `iterator()`.
		
		The default is false.
		
		<warn>If true, nested iterations are likely to fail as only one iteration is allowed at a time.</warn>
	**/
	public var reuseIterator:Bool;
	
	var mSize:Int;
	var mReservedSize:Int;
	var mPoolSize:Int;
	
	var mHeadPool:DLLNode<T>;
	var mTailPool:DLLNode<T>;
	
	var mCircular:Bool;
	var mIterator:Itr<T>;
	
	/**
		@param reservedSize if > 0, this list maintains an object pool of node objects.
		Prevents frequent node allocation and thus increases performance at the cost of using more memory.
		@param maxSize the maximum allowed size of this list.
		The default value of -1 indicates that there is no upper limit.
		@throws de.polygonal.ds.error.AssertError reserved size is greater than allowed size (debug only).
	**/
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
		
		mReservedSize = reservedSize;
		mSize = 0;
		mPoolSize = 0;
		mCircular = false;
		mIterator = null;
		
		if (reservedSize > 0)
		{
			mHeadPool = mTailPool = new DLLNode<T>(cast null, this);
		}
		
		head = tail = null;
		key = HashKey.next();
		reuseIterator = false;
	}
	
	/**
		Returns true if this list is circular.
		
		A list is circular if the tail points to the head and vice versa.
		<o>1</o>
	**/
	public function isCircular():Bool
	{
		return mCircular;
	}
	
	/**
		Makes this list circular by connecting the tail to the head and vice versa.
		
		Silently fails if this list is already closed.
		<o>1</o>
	**/
	public function close()
	{
		if (mCircular) return;
		mCircular = true;
		if (valid(head))
		{
			tail.next = head;
			head.prev = tail;
		}
	}
	
	/**
		Makes this list non-circular by disconnecting the tail from the head and vice versa.
		
		Silently fails if this list is already non-circular.
		<o>1</o>
	**/
	public function open()
	{
		if (!mCircular) return;
		mCircular = false;
		if (valid(head))
		{
			tail.next = null;
			head.prev = null;
		}
	}
	
	/**
		Creates and returns a new `DLLNode` object storing the value `x` and pointing to this list.
		<o>1</o>
	**/
	public function createNode(x:T):DLLNode<T>
	{
		return new DLLNode<T>(x, this);
	}
	
	/**
		Appends the element `x` to the tail of this list by creating a `DLLNode` object storing `x`.
		<o>1</o>
		@return the appended node storing `x`.
		@throws de.polygonal.ds.error.AssertError `size()` equals `maxSize` (debug only).
	**/
	public function append(x:T):DLLNode<T>
	{
		#if debug
		if (maxSize != -1)
			assert(size() < maxSize, 'size equals max size ($maxSize)');
		#end
		
		var node = getNode(x);
		if (valid(tail))
		{
			tail.next = node;
			node.prev = tail;
		}
		else
			head = node;
		tail = node;
		
		if (mCircular)
		{
			tail.next = head;
			head.prev = tail;
		}
		
		mSize++;
		return node;
	}
	
	/**
		Appends the node `x` to this list.
		<o>1</o>
	**/
	public function appendNode(x:DLLNode<T>)
	{
		assert(x.getList() == this, "node is not managed by this list");
		
		if (valid(tail))
		{
			tail.next = x;
			x.prev = tail;
		}
		else
			head = x;
		tail = x;
		
		if (mCircular)
		{
			tail.next = head;
			head.prev = tail;
		}
		
		mSize++;
	}
	
	/**
		Prepends the element `x` to the head of this list by creating a `DLLNode` object storing `x`.
		<o>1</o>
		@return the prepended node storing `x`.
		@throws de.polygonal.ds.error.AssertError `size()` equals `maxSize` (debug only).
	**/
	public function prepend(x:T):DLLNode<T>
	{
		#if debug
		if (maxSize != -1)
			assert(size() < maxSize, 'size equals max size ($maxSize)');
		#end
		
		var node = getNode(x);
		node.next = head;
		if (valid(head))
			head.prev = node;
		else
			tail = node;
		head = node;
		
		if (mCircular)
		{
			tail.next = head;
			head.prev = tail;
		}
		
		mSize++;
		return node;
	}
	
	/**
		Prepends the node `x` to this list.
		<o>1</o>
	**/
	public function prependNode(x:DLLNode<T>)
	{
		assert(x.getList() == this, "node is not managed by this list");
		
		x.next = head;
		if (valid(head))
			head.prev = x;
		else
			tail = x;
		head = x;
		
		if (mCircular)
		{
			tail.next = head;
			head.prev = tail;
		}
		
		mSize++;
	}
	
	/**
		Inserts the element `x` after `node` by creating a `DLLNode` object storing `x`.
		<o>1</o>
		@return the inserted node storing `x`.
		@throws de.polygonal.ds.error.AssertError `node` is null or not managed by this list (debug only).
	**/
	public function insertAfter(node:DLLNode<T>, x:T):DLLNode<T>
	{
		#if debug
		if (maxSize != -1)
			assert(size() < maxSize, 'size equals max size ($maxSize)');
		#end
		
		assert(valid(node), "node is null");
		assert(node.getList() == this, "node is not managed by this list");
		
		var t = getNode(x);
		node.insertAfter(t);
		if (node == tail)
		{
			tail = t;
			if (mCircular)
				tail.next = head;
		}
		
		mSize++;
		return t;
	}
	
	/**
		Inserts the element `x` before `node` by creating a `DLLNode` object storing `x`.
		<o>1</o>
		@return the inserted node storing `x`.
		@throws de.polygonal.ds.error.AssertError `node` is null or not managed by this list (debug only).
	**/
	public function insertBefore(node:DLLNode<T>, x:T):DLLNode<T>
	{
		#if debug
		if (maxSize != -1)
			assert(size() < maxSize, 'size equals max size ($maxSize)');
		#end
		
		assert(valid(node), "node is null");
		assert(node.getList() == this, "node is not managed by this list");
		
		var t = getNode(x);
		node.insertBefore(t);
		if (node == head)
		{
			head = t;
			if (mCircular)
				head.prev = tail;
		}
		
		mSize++;
		return t;
	}
	
	/**
		Unlinks `node` from this list and returns `node`::`next`.
		<o>1</o>
		@throws de.polygonal.ds.error.AssertError list is empty (debug only).
		@throws de.polygonal.ds.error.AssertError `node` is null or not managed by this list (debug only).
	**/
	public function unlink(node:DLLNode<T>):DLLNode<T>
	{
		assert(valid(node), "node is null");
		assert(node.getList() == this, "node is not managed by this list");
		assert(mSize > 0, "list is empty");
		
		var hook = node.next;
		if (node == head)
		{
			head = head.next;
			if (mCircular)
			{
				if (head == tail)
					head = null;
				else
					tail.next = head;
			}
			
			if (head == null) tail = null;
		}
		else
		if (node == tail)
		{
			tail = tail.prev;
			if (mCircular)
				head.prev = tail;
				
			if (tail == null) head = null;
		}
		
		node._unlink();
		putNode(node);
		mSize--;
		
		return hook;
	}
	
	/**
		Returns the node at "index" `i`.
		
		The index is measured relative to the head node (= index 0).
		<o>n</o>
		@throws de.polygonal.ds.error.AssertError list is empty (debug only).
		@throws de.polygonal.ds.error.AssertError index out of range (debug only).
	**/
	public function getNodeAt(i:Int):DLLNode<T>
	{
		assert(mSize > 0, "list is empty");
		assert(i >= 0 || i < mSize, 'i index out of range ($i)');
		
		var node = head;
		for (j in 0...i) node = node.next;
		return node;
	}
	
	/**
		Removes the head node and returns the element stored in this node.
		<o>n</o>
		@throws de.polygonal.ds.error.AssertError list is empty (debug only).
	**/
	public function removeHead():T
	{
		assert(mSize > 0, "list is empty");
		
		var node = head;
		if (head == tail)
			head = tail = null;
		else
		{
			head = head.next;
			node.next = null;
			
			if (mCircular)
			{
				head.prev = tail;
				tail.next = head;
			}
			else
				head.prev = null;
		}
		mSize--;
		
		return putNode(node);
	}
	
	/**
		Removes the tail node and returns the element stored in this node.
		<o>1</o>
		@throws de.polygonal.ds.error.AssertError list is empty (debug only).
	**/
	public function removeTail():T
	{
		assert(mSize > 0, "list is empty");
		
		var node = tail;
		if (head == tail)
			head = tail = null;
		else
		{
			tail = tail.prev;
			node.prev = null;
			
			if (mCircular)
			{
				tail.next = head;
				head.prev = tail;
			}
			else
				tail.next = null;
		}
		
		mSize--;
		
		return putNode(node);
	}
	
	/**
		Unlinks the head node and appends it to the tail.
		<o>1</o>
		@throws de.polygonal.ds.error.AssertError list is empty (debug only).
	**/
	public function shiftUp()
	{
		assert(mSize > 0, "list is empty");
		
		if (mSize > 1)
		{
			var t = head;
			if (head.next == tail)
			{
				head = tail;
				head.prev = null;
				
				tail = t;
				tail.next = null;
				
				head.next = tail;
				tail.prev = head;
			}
			else
			{
				head = head.next;
				head.prev = null;
				
				tail.next = t;
				
				t.next = null;
				t.prev = tail;
				
				tail = t;
			}
			
			if (mCircular)
			{
				tail.next = head;
				head.prev = tail;
			}
		}
	}
	
	/**
		Unlinks the tail node and prepends it to the head.
		<o>1</o>
		@throws de.polygonal.ds.error.AssertError list is empty (debug only).
	**/
	public function popDown()
	{
		assert(mSize > 0, "list is empty");
		
		if (mSize > 1)
		{
			var t = tail;
			if (tail.prev == head)
			{
				tail = head;
				tail.next = null;
				
				head = t;
				head.prev = null;
				
				head.next = tail;
				tail.prev = head;
			}
			else
			{
				tail = tail.prev;
				tail.next = null;
				
				head.prev = t;
				
				t.prev = null;
				t.next = head;
				
				head = t;
			}
			
			if (mCircular)
			{
				tail.next = head;
				head.prev = tail;
			}
		}
	}
	
	/**
		Searches for the element `x` in this list from head to tail starting at node `from`.
		<o>n</o>
		@return the node containing `x` or null if such a node does not exist.
		If `from` is null, the search starts at the head of this list.
		@throws de.polygonal.ds.error.AssertError `from` is not managed by this list (debug only).
	**/
	public function nodeOf(x:T, from:DLLNode<T> = null):DLLNode<T>
	{
		#if debug
		if (valid(from))
			assert(from.getList() == this, "node is not managed by this list");
		#end
		
		var node = (from == null) ? head : from;
		if (mCircular)
		{
			while (node != tail)
			{
				if (node.val == x) return node;
				node = node.next;
			}
			if (node.val == x) return node;
		}
		else
		{
			while (valid(node))
			{
				if (node.val == x) return node;
				node = node.next;
			}
		}
		return null;
	}
	
	/**
		Searches for the element `x` in this list from tail to head starting at node `from`.
		<o>n</o>
		@return the node containing `x` or null if such a node does not exist.
		If `from` is null, the search starts at the tail of this list.
		@throws de.polygonal.ds.error.AssertError `from` is not managed by this list (debug only).
	**/
	public function lastNodeOf(x:T, from:DLLNode<T> = null):DLLNode<T>
	{
		#if debug
		if (valid(from))
			assert(from.getList() == this, "node is not managed by this list");
		#end
		
		var node = (from == null) ? tail : from;
		if (mCircular)
		{
			while (node != head)
			{
				if (node.val == x) return node;
				node = node.prev;
			}
			if (node.val == x) return node;
		}
		else
		{
			while (valid(node))
			{
				if (node.val == x) return node;
				node = node.prev;
			}
		}
		return null;
	}
	
	/**
		Sorts the elements of this list using the merge sort algorithm.
		<o>n log n for merge sort and n&sup2; for insertion sort</o>
		@param compare a comparison function.
		If null, the elements are compared using element.`compare()`.
		<warn>In this case all elements have to implement `Comparable`.</warn>
		@param useInsertionSort if true, the linked list is sorted using the insertion sort algorithm.
		This is faster for nearly sorted lists.
		@throws de.polygonal.ds.error.AssertError element does not implement `Comparable` (debug only).
	**/
	public function sort(compare:T->T->Int, useInsertionSort = false)
	{
		if (mSize > 1)
		{
			if (mCircular)
			{
				tail.next = null;
				head.prev = null;
			}
			
			if (compare == null)
			{
				head = useInsertionSort ? insertionSortComparable(head) : mergeSortComparable(head);
			}
			else
			{
				head = useInsertionSort ? insertionSort(head, compare) : mergeSort(head, compare);
			}
			
			if (mCircular)
			{
				tail.next = head;
				head.prev = tail;
			}
		}
	}
	
	/**
		Merges this list with the list `x` by linking both lists together.
		
		<warn>The merge operation destroys x so it should be discarded.</warn>
		<o>n</o>
		@throws de.polygonal.ds.error.AssertError `x` is null or this list equals `x` (debug only).
	**/
	public function merge(x:DLL<T>)
	{
		#if debug
		if (maxSize != -1)
			assert(size() + x.size() <= maxSize, 'size equals max size ($maxSize)');
		#end
		
		assert(x != this, "x equals this list");
		assert(x != null, "x is null");
		
		if (valid(x.head))
		{
			var node = x.head;
			for (i in 0...x.size())
			{
				node.mList = this;
				node = node.next;
			}
				
			if (valid(head))
			{
				tail.next = x.head;
				x.head.prev = tail;
				tail = x.tail;
			}
			else
			{
				head = x.head;
				tail = x.tail;
			}
			
			mSize += x.size();
			
			if (mCircular)
			{
				tail.next = head;
				head.prev = tail;
			}
		}
	}
	
	/**
		Concatenates this list with the list `x` by appending all elements of `x` to this list.
		
		This list and `x` are untouched.
		<o>n</o>
		@return a new list containing the elements of both lists.
		@throws de.polygonal.ds.error.AssertError `x` is null or this equals `x` (debug only).
	**/
	public function concat(x:DLL<T>):DLL<T>
	{
		assert(x != null, "x is null");
		assert(x != this, "x equals this list");
		
		var c = new DLL<T>();
		var k = x.size();
		if (k > 0)
		{
			var node = x.tail;
			var t = c.tail = new DLLNode<T>(node.val, c);
			node = node.prev;
			var i = k - 1;
			while (i-- > 0)
			{
				var copy = new DLLNode<T>(node.val, c);
				copy.next = t;
				t.prev = copy;
				t = copy;
				node = node.prev;
			}
			
			c.head = t;
			c.mSize = k;
			
			if (mSize > 0)
			{
				var node = tail;
				var i = mSize;
				while (i-- > 0)
				{
					var copy = new DLLNode<T>(node.val, c);
					copy.next = t;
					t.prev = copy;
					t = copy;
					node = node.prev;
				}
				c.head = t;
				c.mSize += mSize;
			}
		}
		else
		if (mSize > 0)
		{
			var node = tail;
			var t = c.tail = new DLLNode<T>(node.val, this);
			node = node.prev;
			var i = mSize - 1;
			while (i-- > 0)
			{
				var copy = new DLLNode<T>(node.val, this);
				copy.next = t;
				t.prev = copy;
				t = copy;
				node = node.prev;
			}
			
			c.head = t;
			c.mSize = mSize;
		}
		
		return c;
	}
	
	/**
		Reverses the linked list in place.
		<o>n</o>
	**/
	public function reverse()
	{
		if (mSize <= 1)
			return;
		else
		if (mSize <= 3)
		{
			var t = head.val;
			head.val = tail.val;
			tail.val = t;
		}
		else
		{
			var head = head;
			var tail = tail;
			for (i in 0...mSize >> 1)
			{
				var t = head.val;
				head.val = tail.val;
				tail.val = t;
				
				head = head.next;
				tail = tail.prev;
			}
		}
	}
	
	/**
		Converts the data in the linked list to strings, inserts `x` between the elements, concatenates them, and returns the resulting string.
		<o>n</o>
	**/
	public function join(x:String):String
	{
		var s = "";
		if (mSize > 0)
		{
			var node = head;
			for (i in 0...mSize - 1)
			{
				s += Std.string(node.val) + x;
				node = node.next;
			}
			s += Std.string(node.val);
		}
		return s;
	}
	
	/**
		Replaces up to `n` existing elements with objects of type `cl`.
		<o>n</o>
		@param cl the class to instantiate for each element.
		@param args passes additional constructor arguments to `cl`.
		@param n the number of elements to replace. If 0, `n` is set to `size()`.
		@throws de.polygonal.ds.error.AssertError `n` out of range (debug only).
	**/
	public function assign(cl:Class<T>, args:Array<Dynamic> = null, n = 0)
	{
		assert(n >= 0);
		
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
			node.val = Type.createInstance(cl, args);
			node = node.next;
		}
	}
	
	/**
		Replaces up to `n` existing elements with the instance `x`.
		<o>n</o>
		@param n the number of elements to replace. If 0, `n` is set to `size()`.
		@throws de.polygonal.ds.error.AssertError `n` out of range (debug only).
	**/
	public function fill(x:T, args:Array<Dynamic> = null, n = 0):DLL<T>
	{
		assert(n >= 0);
		
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
		Shuffles the elements of this collection by using the Fisher-Yates algorithm.
		<o>n</o>
		@param rval a list of random double values in the range between 0 (inclusive) to 1 (exclusive) defining the new positions of the elements.
		If omitted, random values are generated on-the-fly by calling `Math::random()`.
		@throws de.polygonal.ds.error.AssertError insufficient random values (debug only).
	**/
	public function shuffle(rval:Array<Float> = null)
	{
		var s = mSize;
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
			assert(rval.length >= size(), "insufficient random values");
			
			var j = 0;
			while (s > 1)
			{
				s--;
				var i = Std.int(rval[j++] * s);
				var node1 = head;
				for (j in 0...s) node1 = node1.next;
				
				var t = node1.val;
				
				var node2 = head;
				for (j in 0...i) node2 = node2.next;
				
				node1.val = node2.val;
				node2.val = t;
			}
		}
		
		if (mCircular)
		{
			tail.next = head;
			head.prev = tail;
		}
	}
	
	/**
		Returns a string representing the current object.
		
		Example:
		<pre class="prettyprint">
		var dll = new de.polygonal.ds.DLL<Int>();
		for (i in 0...4) {
		    dll.append(i);
		}
		trace(dll);</pre>
		<pre class="console">
		{ DLL size: 4, circular: false }
		[ head
		  0
		  1
		  2
		  3
		] tail</pre>
	**/
	public function toString():String
	{
		var s = '{ DLL size: ${size()}, circular: ${isCircular()} }';
		if (isEmpty()) return s;
		s += "\n[ head \n";
		var node = head;
		for (i in 0...mSize)
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
		Destroys this object by explicitly nullifying all nodes, pointers and data for GC'ing used resources.
		
		Improves GC efficiency/performance (optional).
		<o>n</o>
	**/
	public function free()
	{
		var node = head;
		for (i in 0...mSize)
		{
			var next = node.next;
			node.free();
			node = next;
		}
		head = tail = null;
		
		var node = mHeadPool;
		while (valid(node))
		{
			var next = node.next;
			node.free();
			node = next;
		}
		
		mHeadPool = mTailPool = null;
		mIterator = null;
	}
	
	/**
		Returns true if this list contains a node storing the element `x`.
		<o>n</o>
	**/
	public function contains(x:T):Bool
	{
		var node = head;
		for (i in 0...mSize)
		{
			if (node.val == x)
				return true;
			node = node.next;
		}
		return false;
	}
	
	/**
		Removes all nodes storing the element `x`.
		<o>n</o>
		@return true if at least one occurrence of `x` was removed.
	**/
	public function remove(x:T):Bool
	{
		var s = size();
		if (s == 0) return false;
		
		var node = head;
		while (valid(node))
		{
			if (node.val == x)
				node = unlink(node);
			else
				node = node.next;
		}
		
		return size() < s;
	}
	
	/**
		Removes all elements.
		<o>1 or n if `purge` is true</o>
		@param purge if true, nodes, pointers and elements are nullified upon removal.
	**/
	public function clear(purge = false)
	{
		if (purge || mReservedSize > 0)
		{
			var node = head;
			for (i in 0...mSize)
			{
				var next = node.next;
				node.prev = null;
				node.next = null;
				putNode(node);
				node = next;
			}
		}
		
		head = tail = null;
		mSize = 0;
	}
	
	/**
		Returns a new `DLLIterator` object to iterate over all elements contained in this doubly linked list.
		
		Uses a `CircularDLLIterator` iterator object if `circular` is true.
		
		The elements are visited from head to tail.
		
		If performance is crucial, use the following loop instead:
		<pre class="prettyprint">
		//open list:
		var node = myDLL.head;
		while (node != null)
		{
		    var element = node.val;
		    node = node.next;
		}
		
		//circular list:
		var node = myDLL.head;
		for (i in 0...list.size())
		{
		    var element = node.val;
		    node = node.next;
		}
		</pre>
		See <a href="http://haxe.org/ref/iterators" target="mBlank">http://haxe.org/ref/iterators</a>
		
	**/
	public function iterator():Itr<T>
	{
		if (reuseIterator)
		{
			if (mIterator == null)
			{
				if (mCircular)
					return new CircularDLLIterator<T>(this);
				else
					return new DLLIterator<T>(this);
			}
			else
				mIterator.reset();
			return mIterator;
		}
		else
		{
			if (mCircular)
				return new CircularDLLIterator<T>(this);
			else
				return new DLLIterator<T>(this);
		}
	}
	
	/**
		The total number of elements.
		<o>1</o>
	**/
	inline public function size():Int
	{
		return mSize;
	}
	
	/**
		Returns true if this list is empty.
		<o>1</o>
	**/
	inline public function isEmpty():Bool
	{
		return mSize == 0;
	}
	
	/**
		Returns an array containing all elements in this doubly linked list.
		
		Preserves the natural order of this linked list.
	**/
	public function toArray():Array<T>
	{
		var a:Array<T> = ArrayUtil.alloc(size());
		var node = head;
		for (i in 0...mSize)
		{
			a[i] = node.val;
			node = node.next;
		}
		return a;
	}
	
	/**
		Returns a `Vector<T>` object containing all elements in this doubly linked list.
		
		Preserves the natural order of this linked list.
	**/
	public function toVector():Vector<T>
	{
		var v = new Vector<T>(size());
		var node = head;
		for (i in 0...mSize)
		{
			v[i] = node.val;
			node = node.next;
		}
		return v;
	}
	
	/**
		Duplicates this linked list. Supports shallow (structure only) and deep copies (structure & elements).
		@param assign if true, the `copier` parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.
		If false, the `clone()` method is called on each element. <warn>In this case all elements have to implement `Cloneable`.</warn>
		@param copier a custom function for copying elements. Replaces element.`clone()` if `assign` is false.
		@throws de.polygonal.ds.error.AssertError element is not of type `Cloneable` (debug only).
	**/
	public function clone(assign = true, copier:T->T = null):Collection<T>
	{
		if (mSize == 0)
		{
			var copy = new DLL<T>(mReservedSize, maxSize);
			if (mCircular) copy.mCircular = true;
			return copy;
		}
		
		var copy = new DLL<T>();
		copy.mSize = mSize;
		
		if (assign)
		{
			var srcNode = head;
			var dstNode = copy.head = new DLLNode<T>(head.val, copy);
			
			if (mSize == 1)
			{
				copy.tail = copy.head;
				if (mCircular) copy.tail.next = copy.head;
				return copy;
			}
			
			var dstNode0;
			srcNode = srcNode.next;
			for (i in 1...mSize - 1)
			{
				dstNode0 = dstNode;
				var srcNode0 = srcNode;
				
				dstNode = dstNode.next = new DLLNode<T>(srcNode.val, copy);
				dstNode.prev = dstNode0;
				
				srcNode0 = srcNode;
				srcNode = srcNode0.next;
			}
			
			dstNode0 = dstNode;
			copy.tail = dstNode.next = new DLLNode<T>(srcNode.val, copy);
			copy.tail.prev = dstNode0;
		}
		else
		if (copier == null)
		{
			var srcNode = head;
			
			assert(Std.is(head.val, Cloneable), 'element is not of type Cloneable (${head.val})');
			
			var c = cast(head.val, Cloneable<Dynamic>);
			var dstNode = copy.head = new DLLNode<T>(c.clone(), copy);
			if (mSize == 1)
			{
				copy.tail = copy.head;
				if (mCircular) copy.tail.next = copy.head;
				return copy;
			}
			
			var dstNode0;
			srcNode = srcNode.next;
			for (i in 1...mSize - 1)
			{
				dstNode0 = dstNode;
				var srcNode0 = srcNode;
				
				assert(Std.is(srcNode.val, Cloneable), 'element is not of type Cloneable (${srcNode.val})');
				
				c = cast(srcNode.val, Cloneable<Dynamic>);
				
				dstNode = dstNode.next = new DLLNode<T>(c.clone(), copy);
				dstNode.prev = dstNode0;
				
				srcNode0 = srcNode;
				srcNode = srcNode0.next;
			}
			
			assert(Std.is(srcNode.val, Cloneable), 'element is not of type Cloneable (${srcNode.val})');
			
			c = cast(srcNode.val, Cloneable<Dynamic>);
			dstNode0 = dstNode;
			copy.tail = dstNode.next = new DLLNode<T>(c.clone(), copy);
			copy.tail.prev = dstNode0;
		}
		else
		{
			var srcNode = head;
			var dstNode = copy.head = new DLLNode<T>(copier(head.val), copy);
			
			if (mSize == 1)
			{
				copy.tail = copy.head;
				if (mCircular) copy.tail.next = copy.head;
				return copy;
			}
			
			var dstNode0;
			srcNode = srcNode.next;
			for (i in 1...mSize - 1)
			{
				dstNode0 = dstNode;
				var srcNode0 = srcNode;
				
				dstNode = dstNode.next = new DLLNode<T>(copier(srcNode.val), copy);
				dstNode.prev = dstNode0;
				
				srcNode0 = srcNode;
				srcNode = srcNode0.next;
			}
			
			dstNode0 = dstNode;
			copy.tail = dstNode.next = new DLLNode<T>(copier(srcNode.val), copy);
			copy.tail.prev = dstNode0;
		}
		
		if (mCircular) copy.tail.next = copy.head;
		return copy;
	}
	
	function mergeSortComparable(node:DLLNode<T>):DLLNode<T>
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
			
			while (valid(p))
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
				
				while (psize > 0 || (qsize > 0 && valid(q)))
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
						assert(Std.is(p.val, Comparable), 'element is not of type Comparable (${p.val})');
						
						if (cast(p.val, Comparable<Dynamic>).compare(q.val) >= 0)
						{
							e = p; p = p.next; psize--;
						}
						else
						{
							e = q; q = q.next; qsize--;
						}
					}
					
					if (valid(tail))
						tail.next = e;
					else
						h = e;
					
					e.prev = tail;
					tail = e;
				}
				p = q;
			}
			
			tail.next = null;
			if (nmerges <= 1) break;
			insize <<= 1;
		}
		
		h.prev = null;
		this.tail = tail;
		
		return h;
	}
	
	function mergeSort(node:DLLNode<T>, cmp:T->T->Int):DLLNode<T>
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
			
			while (valid(p))
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
				
				while (psize > 0 || (qsize > 0 && valid(q)))
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
					
					if (valid(tail))
						tail.next = e;
					else
						h = e;
					
					e.prev = tail;
					tail = e;
				}
				p = q;
			}
			
			tail.next = null;
			if (nmerges <= 1) break;
			insize <<= 1;
		}
		
		h.prev = null;
		this.tail = tail;
		
		return h;
	}
	
	function insertionSortComparable(node:DLLNode<T>):DLLNode<T>
	{
		var h = node;
		var n = h.next;
		while (valid(n))
		{
			var m = n.next;
			var p = n.prev;
			var v = n.val;
			
			assert(Std.is(p.val, Comparable), 'element is not of type Comparable (${p.val})');
			
			if (cast(p.val, Comparable<Dynamic>).compare(v) < 0)
			{
				var i = p;
				
				while (i.hasPrev())
				{
					assert(Std.is(i.prev.val, Comparable), 'element is not of type Comparable (${i.prev.val})');
					
					if (cast(i.prev.val, Comparable<Dynamic>).compare(v) < 0)
						i = i.prev;
					else
						break;
				}
				if (valid(m))
				{
					p.next = m;
					m.prev = p;
				}
				else
				{
					p.next = null;
					tail = p;
				}
				
				if (i == h)
				{
					n.prev = null;
					n.next = i;
					
					i.prev = n;
					h = n;
				}
				else
				{
					n.prev = i.prev;
					i.prev.next = n;
					
					n.next = i;
					i.prev = n;
				}
			}
			n = m;
		}
		
		return h;
	}
	
	function insertionSort(node:DLLNode<T>, cmp:T->T->Int):DLLNode<T>
	{
		var h = node;
		var n = h.next;
		while (valid(n))
		{
			var m = n.next;
			var p = n.prev;
			var v = n.val;
			
			if (cmp(v, p.val) < 0)
			{
				var i = p;
				
				while (i.hasPrev())
				{
					if (cmp(v, i.prev.val) < 0)
						i = i.prev;
					else
						break;
				}
				if (valid(m))
				{
					p.next = m;
					m.prev = p;
				}
				else
				{
					p.next = null;
					tail = p;
				}
				
				if (i == h)
				{
					n.prev = null;
					n.next = i;
					
					i.prev = n;
					h = n;
				}
				else
				{
					n.prev = i.prev;
					i.prev.next = n;
					
					n.next = i;
					i.prev = n;
				}
			}
			n = m;
		}
		
		return h;
	}
	
	inline function valid(node:DLLNode<T>):Bool
	{
		return node != null;
	}
	
	inline function getNode(x:T)
	{
		if (mReservedSize == 0 || mPoolSize == 0)
			return new DLLNode<T>(x, this);
		else
		{
			var n = mHeadPool;
			
			assert(n.prev == null, "node.prev == null");
			assert(valid(n.next), "node.next != null");
			
			mHeadPool = mHeadPool.next;
			mPoolSize--;
			
			n.next = null;
			n.val = x;
			return n;
		}
	}
	
	inline function putNode(x:DLLNode<T>):T
	{
		var val = x.val;
		if (mReservedSize > 0 && mPoolSize < mReservedSize)
		{
			mTailPool = mTailPool.next = x;
			x.val = cast null;
			
			assert(x.next == null);
			assert(x.prev == null);
			
			mPoolSize++;
		}
		else
			x.mList = null;
		
		return val;
	}
}

#if (flash && generic)
@:generic
#end
@:dox(hide)
class DLLIterator<T> implements de.polygonal.ds.Itr<T>
{
	var mF:DLL<T>;
	var mWalker:DLLNode<T>;
	var mHook:DLLNode<T>;
	
	public function new(f:DLL<T>)
	{
		mF = f;
		reset();
	}
	
	inline public function reset():Itr<T>
	{
		mWalker = mF.head;
		mHook = null;
		return this;
	}
	
	inline public function hasNext():Bool
	{
		return mWalker != null;
	}

	inline public function next():T
	{
		var x = mWalker.val;
		mHook = mWalker;
		mWalker = mWalker.next;
		return x;
	}
	
	inline public function remove()
	{
		assert(mHook != null, "call next() before removing an element");
		
		mF.unlink(mHook);
	}
}

#if (flash && generic)
@:generic
#end
@:dox(hide)
class CircularDLLIterator<T> implements de.polygonal.ds.Itr<T>
{
	var mF:DLL<T>;
	var mWalker:DLLNode<T>;
	var mI:Int;
	var mS:Int;
	var mHook:DLLNode<T>;
	
	public function new(f:DLL<T>)
	{
		mF = f;
		reset();
	}
	
	inline public function reset():Itr<T>
	{
		mWalker = mF.head;
		mS = mF.size();
		mI = 0;
		mHook = null;
		return this;
	}
	
	inline public function hasNext():Bool
	{
		return mI < mS;
	}

	inline public function next():T
	{
		var x = mWalker.val;
		mHook = mWalker;
		mWalker = mWalker.next;
		mI++;
		return x;
	}
	
	inline public function remove()
	{
		assert(mI > 0, "call next() before removing an element");
		
		mF.unlink(mHook);
		mI--;
		mS--;
	}
}