/*
Copyright (c) 2008-2018 Michael Baczynski, http://www.polygonal.de

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
import de.polygonal.ds.tools.MathTools;
import de.polygonal.ds.tools.Shuffle;

/**
	A doubly linked list
	
	Example:
		var o = new de.polygonal.ds.Dll<Int>();
		for (i in 0...4) o.append(i);
		trace(o); //outputs:
		
		[ Dll size=4
		  head
		  0 -> 0
		  1 -> 1
		  2 -> 2
		  3 -> 3
		]
**/
#if generic
@:generic
#end
@:access(de.polygonal.ds.DllNode)
class Dll<T> implements List<T>
{
	/**
		A unique identifier for this object.
		
		A hash table transforms this key into an index of an array element by using a hash function.
	**/
	public var key(default, null):Int = HashKey.next();
	
	/**
		The head of this list or null if this list is empty.
	**/
	public var head(default, null):DllNode<T>;
	
	/**
		The tail of this list or null if this list is empty.
	**/
	public var tail(default, null):DllNode<T>;
	
	/**
		If true, reuses the iterator object instead of allocating a new one when calling `this.iterator()`.
		
		The default is false.
		
		_If this value is true, nested iterations will fail as only one iteration is allowed at a time._
	**/
	public var reuseIterator:Bool = false;
	
	/**
		True if this list is circular.
		
		A list is circular if the tail points to the head and vice versa.
	**/
	public var isCircular(default, null):Bool = false;
	
	var mSize:Int = 0;
	var mReservedSize:Int;
	var mPoolSize:Int = 0;
	
	var mHeadPool:DllNode<T>;
	var mTailPool:DllNode<T>;
	
	var mIterator:DllIterator<T> = null;
	
	/**
		@param reservedSize if > 0, this list maintains an object pool of node objects.
		Prevents frequent node allocation and thus increases performance at the cost of using more memory.
	**/
	public function new(reservedSize:Null<Int> = 0, ?source:Array<T>)
	{
		mReservedSize = reservedSize;
		
		if (reservedSize > 0)
			mHeadPool = mTailPool = new DllNode<T>(cast null, this);
		
		if (source != null && source.length > 0)
		{
			mSize = source.length;
			head = tail = getNode(source[0]);
			var node;
			for (i in 1...mSize)
			{
				node = getNode(source[i]);
				tail.next = node;
				node.prev = tail;
				tail = node;
			}
		}
		else
			head = tail = null;
	}
	
	/**
		Makes this list circular by connecting the tail to the head and vice versa.
		
		Silently fails if this list is already closed.
	**/
	public function close():Dll<T>
	{
		if (isCircular) return this;
		isCircular = true;
		if (valid(head))
		{
			tail.next = head;
			head.prev = tail;
		}
		return this;
	}
	
	/**
		Makes this list non-circular by disconnecting the tail from the head and vice versa.
		
		Silently fails if this list is already non-circular.
	**/
	public function open():Dll<T>
	{
		if (!isCircular) return this;
		isCircular = false;
		if (valid(head))
		{
			tail.next = null;
			head.prev = null;
		}
		return this;
	}
	
	/**
		Creates and returns a new `DllNode` object storing the value `val` and pointing to this list.
	**/
	public function createNode(val:T):DllNode<T>
	{
		return new DllNode<T>(val, this);
	}
	
	/**
		Appends `val` to the tail of this list by creating a `DllNode` object storing `val`.
		@return the appended node storing `val`.
	**/
	public function append(val:T):DllNode<T>
	{
		var node = getNode(val);
		if (valid(tail))
		{
			tail.next = node;
			node.prev = tail;
		}
		else
			head = node;
		tail = node;
		
		if (isCircular)
		{
			tail.next = head;
			head.prev = tail;
		}
		
		mSize++;
		return node;
	}
	
	/**
		Appends `node` to this list.
	**/
	public function appendNode(node:DllNode<T>)
	{
		assert(node.getList() == this, "node is not managed by this list");
		
		if (valid(tail))
		{
			tail.next = node;
			node.prev = tail;
		}
		else
			head = node;
		tail = node;
		
		if (isCircular)
		{
			tail.next = head;
			head.prev = tail;
		}
		
		mSize++;
	}
	
	/**
		Prepends `val` to the head of this list by creating a `DllNode` object storing `val`.
		@return the prepended node storing `val`.
	**/
	public function prepend(val:T):DllNode<T>
	{
		var node = getNode(val);
		node.next = head;
		if (valid(head))
			head.prev = node;
		else
			tail = node;
		head = node;
		
		if (isCircular)
		{
			tail.next = head;
			head.prev = tail;
		}
		
		mSize++;
		return node;
	}
	
	/**
		Prepends `node` to this list.
	**/
	public function prependNode(node:DllNode<T>)
	{
		assert(node.getList() == this, "node is not managed by this list");
		
		node.next = head;
		if (valid(head))
			head.prev = node;
		else
			tail = node;
		head = node;
		
		if (isCircular)
		{
			tail.next = head;
			head.prev = tail;
		}
		
		mSize++;
	}
	
	/**
		Inserts `val` after `node` by creating a `DllNode` object storing `val`.
		@return the inserted node storing `val`.
	**/
	public function insertAfter(node:DllNode<T>, val:T):DllNode<T>
	{
		assert(valid(node), "node is null");
		assert(node.getList() == this, "node is not managed by this list");
		
		var t = getNode(val);
		node.insertAfter(t);
		if (node == tail)
		{
			tail = t;
			if (isCircular)
				tail.next = head;
		}
		
		mSize++;
		return t;
	}
	
	/**
		Inserts `val` before `node` by creating a `DllNode` object storing `val`.
		@return the inserted node storing `val`.
	**/
	public function insertBefore(node:DllNode<T>, val:T):DllNode<T>
	{
		assert(valid(node), "node is null");
		assert(node.getList() == this, "node is not managed by this list");
		
		var t = getNode(val);
		node.insertBefore(t);
		if (node == head)
		{
			head = t;
			if (isCircular)
				head.prev = tail;
		}
		
		mSize++;
		return t;
	}
	
	/**
		Unlinks `node` from this list and returns `node.next`.
	**/
	public function unlink(node:DllNode<T>):DllNode<T>
	{
		assert(valid(node), "node is null");
		assert(node.getList() == this, "node is not managed by this list");
		assert(size > 0, "list is empty");
		
		var hook = node.next;
		if (node == head)
		{
			head = head.next;
			if (isCircular)
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
			if (isCircular)
				head.prev = tail;
				
			if (tail == null) head = null;
		}
		
		unlinkNode(node);
		putNode(node);
		mSize--;
		return hook;
	}
	
	/**
		Returns the node at "index" `i`.
		
		The index is measured relative to the head node (0=head).
	**/
	public function getNodeAt(i:Int):DllNode<T>
	{
		assert(size > 0, "list is empty");
		assert(i >= 0 || i < size, 'i index out of range ($i)');
		
		var node = head;
		for (j in 0...i) node = node.next;
		return node;
	}
	
	/**
		Removes the head node and returns the element stored in this node.
	**/
	public function removeHead():T
	{
		assert(size > 0, "list is empty");
		
		var node = head;
		if (head == tail)
			head = tail = null;
		else
		{
			head = head.next;
			node.next = null;
			
			if (isCircular)
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
	**/
	public function removeTail():T
	{
		assert(size > 0, "list is empty");
		
		var node = tail;
		if (head == tail)
			head = tail = null;
		else
		{
			tail = tail.prev;
			node.prev = null;
			
			if (isCircular)
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
	**/
	public function headToTail():Dll<T>
	{
		assert(size > 0, "list is empty");
		
		if (size > 1)
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
			
			if (isCircular)
			{
				tail.next = head;
				head.prev = tail;
			}
		}
		return this;
	}
	
	/**
		Unlinks the tail node and prepends it to the head.
	**/
	public function tailToHead():Dll<T>
	{
		assert(size > 0, "list is empty");
		
		if (size > 1)
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
			
			if (isCircular)
			{
				tail.next = head;
				head.prev = tail;
			}
		}
		return this;
	}
	
	/**
		Searches for `val` in this list from head to tail starting at node `from`.
		
		If `from` is null, the search starts at the head of this list.
		@return the node containing `val` or null if such a node does not exist.
	**/
	public function nodeOf(val:T, from:DllNode<T> = null):DllNode<T>
	{
		#if debug
		if (valid(from))
			assert(from.getList() == this, "node is not managed by this list");
		#end
		
		var node = (from == null) ? head : from;
		if (isCircular)
		{
			while (node != tail)
			{
				if (node.val == val) return node;
				node = node.next;
			}
			if (node.val == val) return node;
		}
		else
		{
			while (valid(node))
			{
				if (node.val == val) return node;
				node = node.next;
			}
		}
		return null;
	}
	
	/**
		Searches for `val` in this list from tail to head starting at node `from`.
		
		If `from` is null, the search starts at the tail of this list.
		@return the node containing `val` or null if such a node does not exist.
	**/
	public function lastNodeOf(val:T, from:DllNode<T> = null):DllNode<T>
	{
		#if debug
		if (valid(from))
			assert(from.getList() == this, "node is not managed by this list");
		#end
		
		var node = (from == null) ? tail : from;
		if (isCircular)
		{
			while (node != head)
			{
				if (node.val == val) return node;
				node = node.prev;
			}
			if (node.val == val) return node;
		}
		else
		{
			while (valid(node))
			{
				if (node.val == val) return node;
				node = node.prev;
			}
		}
		return null;
	}
	
	/**
		Sorts the elements of this list using the merge sort algorithm.
		@param cmp a comparison function.
		<br/>If null, the elements are compared using `element.compare()`.
		<br/>_In this case all elements have to implement `Comparable`._
		@param useInsertionSort if true, the linked list is sorted using the insertion sort algorithm.
		This is faster for nearly sorted lists.
	**/
	public function sort(?cmp:T->T->Int, useInsertionSort:Bool = false):Dll<T>
	{
		if (size > 1)
		{
			if (isCircular)
			{
				tail.next = null;
				head.prev = null;
			}
			
			if (cmp == null)
				head = useInsertionSort ? insertionSortComparable(head) : mergeSortComparable(head);
			else
				head = useInsertionSort ? insertionSort(head, cmp) : mergeSort(head, cmp);
			
			if (isCircular)
			{
				tail.next = head;
				head.prev = tail;
			}
		}
		return this;
	}
	
	/**
		Merges this list with `list` by linking both lists together.
		
		_The merge operation destroys `list` so it should be discarded._
	**/
	public function merge(list:Dll<T>):Dll<T>
	{
		assert(list != this, "list equals this list");
		assert(list != null, "list is null");
		
		if (valid(list.head))
		{
			var node = list.head;
			for (i in 0...list.size)
			{
				node.mList = this;
				node = node.next;
			}
				
			if (valid(head))
			{
				tail.next = list.head;
				list.head.prev = tail;
				tail = list.tail;
			}
			else
			{
				head = list.head;
				tail = list.tail;
			}
			
			mSize += list.size;
			
			if (isCircular)
			{
				tail.next = head;
				head.prev = tail;
			}
		}
		return this;
	}
	
	/**
		Concatenates this list with `list` by appending all elements of `list` to this list.
		
		This list and `list` are left untouched.
		@return a new list containing the elements of both lists.
	**/
	public function concat(list:Dll<T>):Dll<T>
	{
		assert(list != null, "list is null");
		assert(list != this, "list equals this list");
		
		var c = new Dll<T>();
		var k = list.size;
		if (k > 0)
		{
			var node = list.tail;
			var t = c.tail = new DllNode<T>(node.val, c);
			node = node.prev;
			var i = k - 1;
			while (i-- > 0)
			{
				var copy = new DllNode<T>(node.val, c);
				copy.next = t;
				t.prev = copy;
				t = copy;
				node = node.prev;
			}
			
			c.head = t;
			c.mSize = k;
			
			if (size > 0)
			{
				node = tail;
				i = size;
				while (i-- > 0)
				{
					var copy = new DllNode<T>(node.val, c);
					copy.next = t;
					t.prev = copy;
					t = copy;
					node = node.prev;
				}
				c.head = t;
				c.mSize += size;
			}
		}
		else
		if (size > 0)
		{
			var node = tail;
			var t = c.tail = new DllNode<T>(node.val, this);
			node = node.prev;
			var i = size - 1;
			while (i-- > 0)
			{
				var copy = new DllNode<T>(node.val, this);
				copy.next = t;
				t.prev = copy;
				t = copy;
				node = node.prev;
			}
			
			c.head = t;
			c.mSize = size;
		}
		return c;
	}
	
	/**
		Reverses the linked list in place.
	**/
	public function reverse():Dll<T>
	{
		if (size <= 1)
			return this;
		else
		if (size <= 3)
		{
			var t = head.val;
			head.val = tail.val;
			tail.val = t;
		}
		else
		{
			var head = head;
			var tail = tail;
			for (i in 0...size >> 1)
			{
				var t = head.val;
				head.val = tail.val;
				tail.val = t;
				
				head = head.next;
				tail = tail.prev;
			}
		}
		return this;
	}
	
	/**
		Converts the data in the linked list to strings, inserts `sep` between the elements, concatenates them, and returns the resulting string.
	**/
	public function join(sep:String):String
	{
		if (isEmpty()) return "";
		
		var b = new StringBuf();
		var node = head;
		for (i in 0...size - 1)
		{
			b.add(Std.string(node.val) + sep);
			node = node.next;
		}
		b.add(Std.string(node.val));
		return b.toString();
	}
	
	/**
		Calls `f` on all elements.
		
		The function signature is: `f(input, index):output`
		
		- input: current element
		- index: the index number of the given element (0=head)
		- output: element to be stored at given index
	**/
	public inline function forEach(f:T->Int->T):Dll<T>
	{
		var node = head;
		for (i in 0...size)
		{
			node.val = f(node.val, i);
			node = node.next;
		}
		return this;
	}
	
	/**
		Calls 'f` on all elements in order.
	**/
	public inline function iter(f:T->Void):Dll<T>
	{
		assert(f != null);
		var node = head;
		while (node != null)
		{
			f(node.val);
			node = node.next;
		}
		return this;
	}
	
	/**
		Shuffles the elements of this collection by using the Fisher-Yates algorithm.
		@param rvals a list of random double values in the interval [0, 1) defining the new positions of the elements.
		If omitted, random values are generated on-the-fly by calling `Shuffle.frand()`.
	**/
	public function shuffle(rvals:Array<Float> = null):Dll<T>
	{
		var s = size;
		if (rvals == null)
		{
			while (s > 1)
			{
				s--;
				var i = Std.int(Shuffle.frand() * s);
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
			assert(rvals.length >= size, "insufficient random values");
			
			var j = 0;
			while (s > 1)
			{
				s--;
				var i = Std.int(rvals[j++] * s);
				var node1 = head;
				for (k in 0...s) node1 = node1.next;
				
				var t = node1.val;
				
				var node2 = head;
				for (l in 0...i) node2 = node2.next;
				
				node1.val = node2.val;
				node2.val = t;
			}
		}
		
		if (isCircular)
		{
			tail.next = head;
			head.prev = tail;
		}
		return this;
	}
	
	/**
		Prints out all elements.
	**/
	#if !no_tostring
	public function toString():String
	{
		var b = new StringBuf();
		b.add('[ Dll size=$size' + (isCircular ? " circular" : ""));
		if (isEmpty())
		{
			b.add(" ]");
			return b.toString();
		}
		b.add("\n  head\n");
		var node = head;
		var args = new Array<Dynamic>();
		var fmt = '  %${MathTools.numDigits(size)}d -> %s\n';
		for (i in 0...size)
		{
			args[0] = i;
			args[1] = Std.string(node.val);
			b.add(Printf.format(fmt, args));
			node = node.next;
		}
		b.add("]");
		return b.toString();
	}
	#end
	
	/* INTERFACE List */
	
	/**
		Same as `this.append()`.
	**/
	public function add(val:T)
	{
		append(val);
	}
	
	/**
		Returns the value at the given `index` (0=head).
	**/
	public function get(index:Int):T
	{
		assert(index >= 0 && index < size, "index out of range");
		
		return getNodeAt(index).val;
	}
	
	/**
		Overwrites the value at the given `index` with `val` (0=head).
	**/
	public function set(index:Int, val:T)
	{
		assert(index >= 0 && index < size, "index out of range");
		
		getNodeAt(index).val = val;
	}
	
	/**
		Inserts `val` before the element at `index` (0=head).
		
		If `index` equals `this.size`, `val` gets appended to the end of the list.
	**/
	public function insert(index:Int, val:T)
	{
		assert(index >= 0 && index <= size, "index out of range");
		
		if (size == 0 || index == size)
		{
			append(val);
			return;
		}
		
		insertBefore(getNodeAt(index), val);
	}
	
	/**
		Returns the index of `val` (0=head).
	**/
	public function indexOf(val:T):Int
	{
		var i = 0;
		var node = head;
		while (valid(node))
		{
			if (node.val == val) return i;
			i++;
			node = node.next;
		}
		return -1;
	}
	
	/**
		Removes and returns the element at `index` (0=head).
	**/
	public function removeAt(index:Int):T
	{
		var node = getNodeAt(index);
		node.unlink();
		return node.val;
	}
	
	/**
		Returns a `Dll` object storing elements in the range [`fromIndex`, `toIndex`).
		If `toIndex` is negative, the value represents the number of elements.
	**/
	public function getRange(fromIndex:Int, toIndex:Int):List<T>
	{
		assert(fromIndex >= 0 && fromIndex < size, "fromIndex out of range");
		#if debug
		if (toIndex >= 0)
		{
			assert(toIndex >= 0 && toIndex < size, "toIndex out of range");
			assert(fromIndex <= toIndex);
		}
		else
			assert(fromIndex - toIndex <= size, "toIndex out of range");
		#end
		
		var n = toIndex > 0 ? (toIndex - fromIndex) : ((fromIndex - toIndex) - fromIndex);
		
		var out = new Dll<T>();
		if (n == 0) return out;
		out.mSize = n;
		
		var src = getNodeAt(fromIndex), t;
		out.head = out.tail = out.getNode(src.val);
		src = src.next;
		for (i in 0...n - 1)
		{
			t = out.getNode(src.val);
			out.tail.next = t;
			t.prev = out.tail;
			out.tail = t;
			src = src.next;
		}
		
		return out;
	}
	
	/* INTERFACE Collection */
	
	/**
		The total number of elements.
	**/
	public var size(get, never):Int;
	inline function get_size():Int
	{
		return mSize;
	}
	
	/**
		Destroys this object by explicitly nullifying all nodes, pointers and data for GC'ing used resources.
		
		Improves GC efficiency/performance (optional).
	**/
	public function free()
	{
		var node = head, next;
		for (i in 0...size)
		{
			next = node.next;
			node.free();
			node = next;
		}
		head = tail = null;
		
		node = mHeadPool;
		while (valid(node))
		{
			next = node.next;
			node.free();
			node = next;
		}
		
		mHeadPool = mTailPool = null;
		if (mIterator != null)
		{
			mIterator.free();
			mIterator = null;
		}
	}
	
	/**
		Returns true if this list contains a node storing `val`.
	**/
	public function contains(val:T):Bool
	{
		var node = head;
		for (i in 0...size)
		{
			if (node.val == val)
				return true;
			node = node.next;
		}
		return false;
	}
	
	/**
		Removes all nodes storing `val`.
		@return true if at least one occurrence of `val` was removed.
	**/
	public function remove(val:T):Bool
	{
		var s = size;
		if (s == 0) return false;
		
		var node = head;
		while (valid(node))
		{
			if (node.val == val)
				node = unlink(node);
			else
				node = node.next;
		}
		return size < s;
	}
	
	/**
		Removes all elements.
		
		@param gc if true, nodes, pointers and elements are nullified upon removal so the garbage collector can reclaim used memory.
	**/
	public function clear(gc:Bool = false)
	{
		if (gc || mReservedSize > 0)
		{
			var node = head;
			for (i in 0...size)
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
		Returns a new *DllIterator* object to iterate over all elements contained in this doubly linked list.
		
		Returns a *CircularDllIterator* iterator object if `circular` is true.
		
		The elements are visited from head to tail.
		
		If performance is crucial, use the following loop instead:
			//open list:
			var node = myDll.head;
			while (node != null)
			{
			    var element = node.val;
			    node = node.next;
			}
			//circular list:
			var node = myDll.head;
			for (i in 0...list.size)
			{
			    var element = node.val;
			    node = node.next;
			}
		@see http://haxe.org/ref/iterators
	**/
	public function iterator():Itr<T>
	{
		if (reuseIterator)
		{
			if (mIterator == null)
			{
				if (isCircular)
					return new CircularDllIterator<T>(this);
				else
					return new DllIterator<T>(this);
			}
			else
				mIterator.reset();
			return mIterator;
		}
		else
		{
			if (isCircular)
				return new CircularDllIterator<T>(this);
			else
				return new DllIterator<T>(this);
		}
	}
	
	/**
		Returns true only if `this.size` is 0.
	**/
	public inline function isEmpty():Bool
	{
		return size == 0;
	}
	
	/**
		Returns an array containing all elements in this doubly linked list.
		
		Preserves the natural order of this linked list.
	**/
	public function toArray():Array<T>
	{
		if (isEmpty()) return [];
		
		var out = ArrayTools.alloc(size);
		var node = head;
		for (i in 0...size)
		{
			out[i] = node.val;
			node = node.next;
		}
		return out;
	}
	
	/**
		Creates and returns a shallow copy (structure only - default) or deep copy (structure & elements) of this list.
		
		If `byRef` is true, primitive elements are copied by value whereas objects are copied by reference.
		
		If `byRef` is false, the `copier` function is used for copying elements. If omitted, `clone()` is called on each element assuming all elements implement `Cloneable`.
	**/
	public function clone(byRef:Bool = true, copier:T->T = null):Collection<T>
	{
		if (size == 0)
		{
			var copy = new Dll<T>(mReservedSize);
			if (isCircular) copy.isCircular = true;
			return copy;
		}
		
		var copy = new Dll<T>();
		copy.mSize = size;
		
		if (byRef)
		{
			var srcNode = head;
			var dstNode = copy.head = new DllNode<T>(head.val, copy);
			
			if (size == 1)
			{
				copy.tail = copy.head;
				if (isCircular) copy.tail.next = copy.head;
				return copy;
			}
			
			var dstNode0;
			srcNode = srcNode.next;
			for (i in 1...size - 1)
			{
				dstNode0 = dstNode;
				var srcNode0 = srcNode;
				
				dstNode = dstNode.next = new DllNode<T>(srcNode.val, copy);
				dstNode.prev = dstNode0;
				
				srcNode0 = srcNode;
				srcNode = srcNode0.next;
			}
			
			dstNode0 = dstNode;
			copy.tail = dstNode.next = new DllNode<T>(srcNode.val, copy);
			copy.tail.prev = dstNode0;
		}
		else
		if (copier == null)
		{
			var srcNode = head;
			
			assert(Std.is(head.val, Cloneable), "element is not of type Cloneable");
			
			var e = cast(head.val, Cloneable<Dynamic>);
			var dstNode = copy.head = new DllNode<T>(e.clone(), copy);
			if (size == 1)
			{
				copy.tail = copy.head;
				if (isCircular) copy.tail.next = copy.head;
				return copy;
			}
			
			var dstNode0;
			srcNode = srcNode.next;
			for (i in 1...size - 1)
			{
				dstNode0 = dstNode;
				var srcNode0 = srcNode;
				
				assert(Std.is(srcNode.val, Cloneable), "element is not of type Cloneable");
				
				e = cast(srcNode.val, Cloneable<Dynamic>);
				dstNode = dstNode.next = new DllNode<T>(e.clone(), copy);
				dstNode.prev = dstNode0;
				
				srcNode0 = srcNode;
				srcNode = srcNode0.next;
			}
			
			dstNode0 = dstNode;
			
			assert(Std.is(srcNode.val, Cloneable), "element is not of type Cloneable");
			
			e = cast(srcNode.val, Cloneable<Dynamic>);
			copy.tail = dstNode.next = new DllNode<T>(e.clone(), copy);
			copy.tail.prev = dstNode0;
		}
		else
		{
			var srcNode = head;
			var dstNode = copy.head = new DllNode<T>(copier(head.val), copy);
			
			if (size == 1)
			{
				copy.tail = copy.head;
				if (isCircular) copy.tail.next = copy.head;
				return copy;
			}
			
			var dstNode0;
			srcNode = srcNode.next;
			for (i in 1...size - 1)
			{
				dstNode0 = dstNode;
				var srcNode0 = srcNode;
				
				dstNode = dstNode.next = new DllNode<T>(copier(srcNode.val), copy);
				dstNode.prev = dstNode0;
				
				srcNode0 = srcNode;
				srcNode = srcNode0.next;
			}
			
			dstNode0 = dstNode;
			copy.tail = dstNode.next = new DllNode<T>(copier(srcNode.val), copy);
			copy.tail.prev = dstNode0;
		}
		
		if (isCircular) copy.tail.next = copy.head;
		return copy;
	}
	
	function mergeSortComparable(node:DllNode<T>):DllNode<T>
	{
		var h = node;
		var p, q, e, tail = null;
		var insize = 1;
		var nmerges, psize, qsize;
		
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
						assert(Std.is(p.val, Comparable), "element is not of type Comparable");
						
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
	
	function mergeSort(node:DllNode<T>, cmp:T->T->Int):DllNode<T>
	{
		var h = node;
		var p, q, e, tail = null;
		var insize = 1;
		var nmerges, psize, qsize;
		
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
	
	function insertionSortComparable(node:DllNode<T>):DllNode<T>
	{
		var h = node;
		var n = h.next;
		while (valid(n))
		{
			var m = n.next;
			var p = n.prev;
			var v = n.val;
			
			assert(Std.is(p.val, Comparable), "element is not of type Comparable");
			
			if (cast(p.val, Comparable<Dynamic>).compare(v) < 0)
			{
				var i = p;
				
				while (i.hasPrev())
				{
					assert(Std.is(i.prev.val, Comparable), "element is not of type Comparable");
					
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
	
	function insertionSort(node:DllNode<T>, cmp:T->T->Int):DllNode<T>
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
	
	inline function valid(node:DllNode<T>):Bool
	{
		return node != null;
	}
	
	inline function getNode(x:T)
	{
		if (mReservedSize == 0 || mPoolSize == 0)
			return new DllNode<T>(x, this);
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
	
	inline function putNode(x:DllNode<T>):T
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
	
	inline function unlinkNode(x:DllNode<T>):DllNode<T>
	{
		var t = x.next;
		if (x.hasPrev()) x.prev.next = x.next;
		if (x.hasNext()) x.next.prev = x.prev;
		x.next = x.prev = null;
		return t;
	}
}

#if generic
@:generic
#end
@:dox(hide)
class DllIterator<T> implements de.polygonal.ds.Itr<T>
{
	var mObject:Dll<T>;
	var mWalker:DllNode<T>;
	var mHook:DllNode<T>;
	
	public function new(x:Dll<T>)
	{
		mObject = x;
		reset();
	}
	
	public function free()
	{
		mObject = null;
		mWalker = null;
		mHook = null;
	}
	
	public inline function reset():Itr<T>
	{
		mWalker = mObject.head;
		mHook = null;
		return this;
	}
	
	public inline function hasNext():Bool
	{
		return mWalker != null;
	}

	public inline function next():T
	{
		var x = mWalker.val;
		mHook = mWalker;
		mWalker = mWalker.next;
		return x;
	}
	
	public function remove()
	{
		assert(mHook != null, "call next() before removing an element");
		
		mObject.unlink(mHook);
	}
}

#if generic
@:generic
#end
@:dox(hide)
class CircularDllIterator<T> implements de.polygonal.ds.Itr<T>
{
	var mObject:Dll<T>;
	var mWalker:DllNode<T>;
	var mHook:DllNode<T>;
	var mI:Int;
	var mS:Int;
	
	public function new(x:Dll<T>)
	{
		mObject = x;
		reset();
	}
	
	public inline function reset():Itr<T>
	{
		mWalker = mObject.head;
		mS = mObject.size;
		mI = 0;
		mHook = null;
		return this;
	}
	
	public inline function hasNext():Bool
	{
		return mI < mS;
	}

	public inline function next():T
	{
		var x = mWalker.val;
		mHook = mWalker;
		mWalker = mWalker.next;
		mI++;
		return x;
	}
	
	public function remove()
	{
		assert(mI > 0, "call next() before removing an element");
		
		mObject.unlink(mHook);
		mI--;
		mS--;
	}
}