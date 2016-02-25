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

import de.polygonal.ds.Sll.SllIterator;
import de.polygonal.ds.tools.ArrayTools;
import de.polygonal.ds.tools.Assert.assert;
import de.polygonal.ds.tools.M;

using de.polygonal.ds.tools.NativeArrayTools;

/**
	A singly linked list
	
	See <a href="http://lab.polygonal.de/?p=206" target="mBlank">http://lab.polygonal.de/?p=206</a>
**/
#if generic
@:generic
#end
@:access(de.polygonal.ds.SllNode)
class Sll<T> implements List<T>
{
	/**
		A unique identifier for this object.
		
		A hash table transforms this key into an index of an array element by using a hash function.
		
		<warn>This value should never be changed by the user.</warn>
	**/
	public var key(default, null):Int = HashKey.next();
	
	/**
		The head of this list or null if this list is empty.
	**/
	public var head:SllNode<T>;
	
	/**
		The tail of this list or null if this list is empty.
	**/
	public var tail:SllNode<T>;
	
	/**
		If true, reuses the iterator object instead of allocating a new one when calling ``iterator()``.
		
		The default is false.
		
		<warn>If true, nested iterations are likely to fail as only one iteration is allowed at a time.</warn>
	**/
	public var reuseIterator:Bool = false;
	
	var mSize:Int = 0;
	var mReservedSize:Int;
	var mPoolSize:Int = 0;
	
	var mHeadPool:SllNode<T>;
	var mTailPool:SllNode<T>;
	
	var mCircular:Bool = false;
	var mIterator:SllIterator<T> = null;
	
	/**
		@param reservedSize if > 0, this list maintains an object pool of node objects.
		Prevents frequent node allocation and thus increases performance at the cost of using more memory.
	**/
	public function new(reservedSize:Null<Int> = 0, ?source:Array<T>)
	{
		mReservedSize = reservedSize;
		
		if (reservedSize > 0)
			mHeadPool = mTailPool = new SllNode<T>(cast null, this);
		
		if (source != null && source.length > 0)
		{
			mSize = source.length;
			head = tail = getNode(source[0]);
			for (i in 1...mSize)
				tail = tail.next = getNode(source[i]);
		}
		else
			head = tail = null;
	}
	
	/**
		Returns true if this list is circular.
		
		A list is circular if the tail points to the head.
	**/
	public function isCircular():Bool
	{
		return mCircular;
	}
	
	/**
		Makes this list circular by connecting the tail to the head.
		
		Silently fails if this list is already closed.
	**/
	public function close()
	{
		if (mCircular) return;
		mCircular = true;
		if (valid(head))
			tail.next = head;
	}
	
	/**
		Makes this list non-circular by disconnecting the tail from the head and vice versa.
		
		Silently fails if this list is already non-circular.
	**/
	public function open()
	{
		if (!mCircular) return;
		mCircular = false;
		if (valid(head))
			tail.next = null;
	}
	
	/**
		Creates and returns a new ``SllNode`` object storing the value `x` and pointing to this list.
	**/
	public inline function createNode(x:T):SllNode<T>
	{
		return new SllNode<T>(x, this);
	}
	
	/**
		Appends the element `x` to the tail of this list by creating a ``SllNode`` object storing `x`.
		@return the appended node storing `x`.
	**/
	public inline function append(x:T):SllNode<T>
	{
		var node = getNode(x);
		if (valid(tail))
			tail.next = node;
		else
			head = node;
		tail = node;
		
		if (mCircular)
			tail.next = head;
		
		mSize++;
		return node;
	}
	
	/**
		Appends the node `x` to this list.
	**/
	public inline function appendNode(x:SllNode<T>)
	{
		assert(x.getList() == this, "node is not managed by this list");
		
		if (valid(tail))
			tail.next = x;
		else
			head = x;
		tail = x;
		
		if (mCircular)
			tail.next = head;
		
		mSize++;
	}
	
	/**
		Prepends the element `x` to the head of this list by creating a ``SllNode`` object storing `x`.
		@return the prepended node storing `x`.
	**/
	public inline function prepend(x:T):SllNode<T>
	{
		var node = getNode(x);
		if (valid(tail))
			node.next = head;
		else
			tail = node;
		head = node;
		
		if (mCircular)
			tail.next = head;
		
		mSize++;
		return node;
	}
	
	/**
		Prepends the node `x` to this list.
	**/
	public function prependNode(x:SllNode<T>)
	{
		assert(x.getList() == this, "node is not managed by this list");
		
		if (valid(tail))
			x.next = head;
		else
			tail = x;
		head = x;
		
		if (mCircular)
			tail.next = head;
		
		mSize++;
	}
	
	/**
		Inserts the element `x` after `node` by creating a ``SllNode`` object storing `x`.
		<assert>`node` is null or not managed by this list</assert>
		@return the inserted node storing `x`.
	**/
	public inline function insertAfter(node:SllNode<T>, x:T):SllNode<T>
	{
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
		Inserts the element `x` before `node` by creating a ``SllNode`` object storing `x`.
		<assert>`node` is null or not managed by this list</assert>
		@return the inserted node storing `x`.
	**/
	public inline function insertBefore(node:SllNode<T>, x:T):SllNode<T>
	{
		
		assert(valid(node), "node is null");
		assert(node.getList() == this, "node is not managed by this list");
		
		var t = getNode(x);
		if (node == head)
		{
			t.next = head;
			head = t;
			
			if (mCircular)
				tail.next = head;
		}
		else
			getNodeBefore(node).insertAfter(t);
		
		mSize++;
		return t;
	}
	
	/**
		Unlinks `node` from this list and returns `node`::next.
		<assert>list is empty</assert>
		<assert>`node` is null or not managed by this list</assert>
	**/
	public inline function unlink(node:SllNode<T>):SllNode<T>
	{
		assert(valid(node), "node is null");
		assert(node.getList() == this, "node is not managed by this list");
		assert(size > 0, "list is empty");
		
		var hook = node.next;
		
		if (node == head)
			removeHead();
		else
		{
			var t = getNodeBefore(node);
			if (t.next == tail)
			{
				if (mCircular)
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
			putNode(node);
			mSize--;
		}
		return hook;
	}
	
	/**
		Returns the node at "index" `i`.
		
		The index is measured relative to the head node (= index 0).
		<assert>list is empty</assert>
		<assert>`i` out of range</assert>
	**/
	public function getNodeAt(i:Int):SllNode<T>
	{
		assert(size > 0, "list is empty");
		assert(i >= 0 || i < size, 'i index out of range ($i)');
		
		var node = head;
		for (j in 0...i) node = node.next;
		return node;
	}
	
	/**
		Removes the head node and returns the element stored in this node.
		<assert>list is empty</assert>
	**/
	public inline function removeHead():T
	{
		assert(size > 0, "list is empty");
		
		var node = head;
		if (size > 1)
		{
			head = head.next;
			
			if (mCircular)
				tail.next = head;
		}
		else
			head = tail = null;
		
		mSize--;
		
		node.next = null;
		return putNode(node);
	}
	
	/**
		Removes the tail node and returns the element stored in this node.
		<assert>list is empty</assert>
	**/
	public inline function removeTail():T
	{
		assert(size > 0, "list is empty");
		
		var node = tail;
		if (size > 1)
		{
			var t = getNodeBefore(tail);
			tail = t;
			
			if (mCircular)
				t.next = head;
			else
				t.next = null;
			mSize--;
		}
		else
		{
			head = tail = null;
			mSize = 0;
		}
		
		node.next = null;
		return putNode(node);
	}
	
	/**
		Unlinks the head node and appends it to the tail.
		<assert>list is empty</assert>
	**/
	public inline function shiftUp()
	{
		assert(size > 0, "list is empty");
		
		if (size > 1)
		{
			var t = head;
			if (head.next == tail)
			{
				head = tail;
				tail = t;
				t.next = mCircular ? head : null;
				head.next = tail;
			}
			else
			{
				head = head.next;
				tail.next = t;
				t.next = mCircular ? head : null;
				tail = t;
			}
		}
	}
	
	/**
		Unlinks the tail node and prepends it to the head.
		<assert>list is empty</assert>
	**/
	public inline function popDown()
	{
		assert(size > 0, "list is empty");
		
		if (size > 1)
		{
			var t = tail;
			if (head.next == tail)
			{
				tail = head;
				head = t;
				t.next = mCircular ? head : null;
				head.next = tail;
			}
			else
			{
				var node = head;
				while (node.next != tail)
					node = node.next;
				tail = node;
				tail.next = mCircular ? t : null;
				t.next = head;
				head = t;
			}
		}
	}
	
	/**
		Searches for the element `x` in this list from head to tail starting at node `from`.
		<assert>`from` is not managed by this list</assert>
		@return the node containing `x` or null if such a node does not exist.
		If `from` is null, the search starts at the head of this list.
	**/
	public function nodeOf(x:T, from:SllNode<T> = null):SllNode<T>
	{
		#if debug
		if (valid(from))
			assert(from.getList() == this, "node is not managed by this list");
		#end
		
		var node = (from == null) ? head : from;
		while (valid(node))
		{
			if (node.val == x) break;
			node = node.next;
		}
		return node;
	}
	
	/**
		Sorts the elements of this list using the merge sort algorithm.
		<assert>element does not implement `Comparable`</assert>
		@param cmp a comparison function.
		If null, the elements are compared using ``element::compare()``.
		<warn>In this case all elements have to implement `Comparable`.</warn>
		@param useInsertionSort if true, the linked list is sorted using the insertion sort algorithm.
		This is faster for nearly sorted lists.
	**/
	public function sort(?cmp:T->T->Int, useInsertionSort:Bool = false)
	{
		if (size > 1)
		{
			if (mCircular) tail.next = null;
			
			if (cmp == null)
			{
				head = useInsertionSort ? insertionSortComparable(head) : mergeSortComparable(head);
			}
			else
			{
				head = useInsertionSort ? insertionSort(head, cmp) : mergeSort(head, cmp);
			}
			
			if (mCircular) tail.next = head;
		}
	}
	
	/**
		Merges this list with the list `x` by linking both lists together.
		
		<warn>The merge operation destroys x so it should be discarded.</warn>
		<assert>`x` is null or this list equals `x`</assert>
	**/
	public function merge(x:Sll<T>)
	{
		assert(x != this, "x equals this list");
		assert(x != null, "x is null");
		
		if (valid(x.head))
		{
			var node = x.head;
			for (i in 0...x.size)
			{
				node.mList = this;
				node = node.next;
			}
			
			if (valid(head))
			{
				tail.next = x.head;
				tail = x.tail;
			}
			else
			{
				head = x.head;
				tail = x.tail;
			}
			
			mSize += x.size;
			
			if (mCircular)
				tail.next = head;
		}
	}
	
	/**
		Concatenates this list with the list `x` by appending all elements of `x` to this list.
		
		This list and `x` are untouched.
		<assert>`x` is null or this equals `x`</assert>
		@return a new list containing the elements of both lists.
	**/
	public function concat(x:Sll<T>):Sll<T>
	{
		assert(x != null, "x is null");
		assert(x != this, "x equals this list");
		
		var c = new Sll<T>();
		var node = head;
		for (i in 0...size)
		{
			c.append(node.val);
			node = node.next;
		}
		node = x.head;
		for (i in 0...x.size)
		{
			c.append(node.val);
			node = node.next;
		}
		return c;
	}
	
	/**
		Reverses the linked list in place.
	**/
	public function reverse()
	{
		if (size > 1)
		{
			var t = new Array<T>();
			var node = head;
			for (i in 0...size)
			{
				t[i] = node.val;
				node = node.next;
			}
			
			t.reverse();
			
			var node = head;
			for (i in 0...size)
			{
				node.val = t[i];
				node = node.next;
			}
		}
	}
	
	/**
		Converts the data in the linked list to strings, inserts `x` between the elements, concatenates them, and returns the resulting string.
	**/
	public function join(x:String):String
	{
		if (isEmpty()) return "";
		
		var b = new StringBuf();
		var node = head;
		for (i in 0...size - 1)
		{
			b.add(Std.string(node.val) + x);
			node = node.next;
		}
		b.add(Std.string(node.val));
		return b.toString();
	}

	/**
		Calls the `f` function on all elements.
		
		The function signature is: `f(element, index):element`
		<assert>`f` is null</assert>
	**/
	public function forEach(f:T->Int->T)
	{
		var node = head;
		for (i in 0...size)
		{
			node.val = f(node.val, i);
			node = node.next;
		}
	}
	
	/**
		Shuffles the elements of this collection by using the Fisher-Yates algorithm.
		<assert>insufficient random values</assert>
		@param rvals a list of random double values in the range between 0 (inclusive) to 1 (exclusive) defining the new positions of the elements.
		If omitted, random values are generated on-the-fly by calling `Math::random()`.
	**/
	public function shuffle(rvals:Array<Float> = null)
	{
		var s = size;
		
		if (s == 1) return;
		
		if (mCircular) tail.next = null;
		
		if (rvals == null)
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
			assert(rvals.length >= size, "insufficient random values");
			
			var j = 0;
			while (s > 1)
			{
				s--;
				var i = Std.int(rvals[j++] * s);
				var node1 = head;
				for (j in 0...s) node1 = node1.next;
				
				var t = node1.val;
				
				var node2 = head;
				for (j in 0...i) node2 = node2.next;
				
				node1.val = node2.val;
				node2.val = t;
			}
		}
		
		if (mCircular) tail.next = head;
	}
	
	/**
		Returns a string representing the current object.
		
		Example:
		<pre class="prettyprint">
		var list = new de.polygonal.ds.Sll<Int>();
		for (i in 0...4) {
		    list.append(i);
		}
		trace(list);</pre>
		<pre class="console">
		{ Sll size: 4 }
		[ head
		  0
		  1
		  2
		  3
		tail ]</pre>
	**/
	public function toString():String
	{
		var b = new StringBuf();
		b.add('{ Sll size: ${size}, circular: ${isCircular()} }');
		if (isEmpty()) return b.toString();
		b.add("\n[ head \n");
		var node = head;
		var args = new Array<Dynamic>();
		var fmt = '  %${M.numDigits(size)}d: %s\n';
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
	
	/* INTERFACE List */
	
	public function add(x:T)
	{
		append(x);
	}
	
	public function get(index:Int):T
	{
		assert(index >= 0 && index < size, "index out of range");
		
		return getNodeAt(index).val;
	}
	
	public function set(index:Int, val:T)
	{
		assert(index >= 0 && index < size, "index out of range");
		
		getNodeAt(index).val = val;
	}
	
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
	
	public function indexOf(val:T)
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
	
	public function removeAt(index:Int):T
	{
		var node = getNodeAt(index);
		node.unlink();
		return node.val;
	}
	
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
		
		var out = new Sll<T>();
		if (n == 0) return out;
		out.mSize = n;
		
		var src = getNodeAt(fromIndex), t;
		out.head = out.tail = out.getNode(src.val);
		src = src.next;
		for (i in 0...n - 1)
		{
			t = out.getNode(src.val);
			out.tail = out.tail.next = t;
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
		var node = head;
		for (i in 0...size)
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
		if (mIterator != null)
		{
			mIterator.free();
			mIterator = null;
		}
	}
	
	/**
		Returns true if this list contains a node storing the element `x`.
	**/
	public function contains(x:T):Bool
	{
		var node = head;
		for (i in 0...size)
		{
			if (node.val == x) return true;
			node = node.next;
		}
		return false;
	}
	
	/**
		Removes all nodes storing the element `x`.
		@return true if at least one occurrence of `x` was removed.
	**/
	public function remove(x:T):Bool
	{
		var s = size;
		if (s == 0) return false;
		
		var node0 = head;
		var node1 = head.next;
		
		for (i in 1...size)
		{
			if (node1.val == x)
			{
				if (node1 == tail)
				{
					tail = node0;
					if (mCircular) tail.next = head;
				}
				var node2 = node1.next;
				node0.next = node2;
				putNode(node1);
				node1 = node2;
				mSize--;
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
			putNode(head);
			head = head1;
			if (head == null)
				tail = null;
			else
			{
				if (mCircular)
					tail.next = head;
			}
			
			mSize--;
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
				node.next = null;
				putNode(node);
				node = next;
			}
		}
		
		head = tail = null;
		mSize = 0;
	}
	
	/**
		Returns a new `SllIterator` object to iterate over all elements contained in this singly linked list.
		
		The elements are visited from head to tail.
		
		If performance is crucial, use the following loop instead:
		
		<pre class="prettyprint">
		var node = mySll.head;
		while (node != null)
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
					return new CircularSllIterator<T>(this);
				else
					return new SllIterator<T>(this);
			}
			else
				mIterator.reset();
			return mIterator;
		}
		else
		{
			if (mCircular)
				return new CircularSllIterator<T>(this);
			else
				return new SllIterator<T>(this);
		}
	}
	
	/**
		Returns true if this list is empty.
	**/
	public inline function isEmpty():Bool
	{
		return size == 0;
	}
	
	/**
		Returns an array containing all elements in this singly linked list.
		
		The elements are ordered head-to-tail.
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
		Duplicates this linked list. Supports shallow (structure only) and deep copies (structure & elements).
		<assert>element is not of type `Cloneable`</assert>
		@param assign if true, the `copier` parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.
		If false, the ``clone()`` method is called on each element. <warn>In this case all elements have to implement `Cloneable`.</warn>
		@param copier a custom function for copying elements. Replaces ``element::clone()`` if `assign` is false.
	**/
	public function clone(assign:Bool = true, copier:T->T = null):Collection<T>
	{
		if (size == 0)
		{
			var copy = new Sll<T>(mReservedSize);
			if (mCircular) copy.mCircular = true;
			return copy;
		}
		
		var copy = new Sll<T>();
		if (mCircular) copy.mCircular = true;
		copy.mSize = size;
		
		if (assign)
		{
			var srcNode = head;
			var dstNode = copy.head = new SllNode<T>(head.val, copy);
			if (size == 1)
			{
				copy.tail = copy.head;
				if (mCircular) copy.tail.next = copy.head;
				return copy;
			}
			srcNode = srcNode.next;
			for (i in 1...size - 1)
			{
				dstNode = dstNode.next = new SllNode<T>(srcNode.val, copy);
				srcNode = srcNode.next;
			}
			copy.tail = dstNode.next = new SllNode<T>(srcNode.val, copy);
		}
		else
		if (copier == null)
		{
			var srcNode = head;
			
			assert(Std.is(head.val, Cloneable), "element is not of type Cloneable");
			var e = cast(head.val, Cloneable<Dynamic>);
			var dstNode = copy.head = new SllNode<T>(e.clone(), copy);
			if (size == 1)
			{
				copy.tail = copy.head;
				if (mCircular) copy.tail.next = copy.head;
				return copy;
			}
			srcNode = srcNode.next;
			for (i in 1...size - 1)
			{
				assert(Std.is(srcNode.val, Cloneable), "element is not of type Cloneable");
				e = cast(srcNode.val, Cloneable<Dynamic>);
				dstNode = dstNode.next = new SllNode<T>(e.clone(), copy);
				srcNode = srcNode.next;
			}
			
			assert(Std.is(srcNode.val, Cloneable), "element is not of type Cloneable");
			e = cast(srcNode.val, Cloneable<Dynamic>);
			copy.tail = dstNode.next = new SllNode<T>(e.clone(), copy);
		}
		else
		{
			var srcNode = head;
			var dstNode = copy.head = new SllNode<T>(copier(head.val), copy);
			if (size == 1)
			{
				if (mCircular) copy.tail.next = copy.head;
				copy.tail = copy.head;
				return copy;
			}
			srcNode = srcNode.next;
			for (i in 1...size - 1)
			{
				dstNode = dstNode.next = new SllNode<T>(copier(srcNode.val), copy);
				srcNode = srcNode.next;
			}
			copy.tail = dstNode.next = new SllNode<T>(copier(srcNode.val), copy);
		}
		
		if (mCircular) copy.tail.next = copy.head;
		return copy;
	}
	
	function mergeSortComparable(node:SllNode<T>):SllNode<T>
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
	
	function mergeSort(node:SllNode<T>, cmp:T->T->Int):SllNode<T>
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
	
	function insertionSortComparable(node:SllNode<T>):SllNode<T>
	{
		var v = new Array<T>();
		var i = 0;
		var t = node;
		while (valid(t))
		{
			v[i++] = t.val;
			t = t.next;
		}
		
		var h = node;
		var j;
		var val;
		for (i in 1...size)
		{
			val = v[i];
			j = i;
			
			assert(Std.is(v[j - 1], Comparable), "element is not of type Comparable");
			
			while ((j > 0) && cast(v[j - 1], Comparable<Dynamic>).compare(val) < 0)
			{
				v[j] = v[j - 1];
				j--;
				
				#if debug
				if (j > 0)
					assert(Std.is(v[j - 1], Comparable), "element is not of type Comparable");
				#end
				
			}
			v[j] = val;
		}
		
		t = h;
		i = 0;
		while (valid(t))
		{
			t.val = v[i++];
			t = t.next;
		}
		return h;
	}
	
	function insertionSort(node:SllNode<T>, cmp:T->T->Int):SllNode<T>
	{
		var v = new Array<T>();
		var i = 0;
		var t = node;
		while (valid(t))
		{
			v[i++] = t.val;
			t = t.next;
		}
		
		var h = node;
		var j;
		var val;
		for (i in 1...size)
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
		while (valid(t))
		{
			t.val = v[i++];
			t = t.next;
		}
		return h;
	}
	
	inline function valid(node:SllNode<T>):Bool
	{
		return node != null;
	}
	
	inline function getNodeBefore(x:SllNode<T>):SllNode<T>
	{
		var node = head;
		while (node.next != x)
			node = node.next;
		return node;
	}
	
	inline function getNode(x:T)
	{
		if (mReservedSize == 0 || mPoolSize == 0)
			return new SllNode<T>(x, this);
		else
		{
			assert(valid(mHeadPool.next), "mHeadPool.next != null");
			
			var t = mHeadPool;
			mHeadPool = mHeadPool.next;
			mPoolSize--;
			t.val = x;
			t.next = null;
			return t;
		}
	}
	
	inline function putNode(x:SllNode<T>):T
	{
		var val = x.val;
		
		if (mReservedSize > 0 && mPoolSize < mReservedSize)
		{
			assert(x.next == null);
			
			mTailPool = mTailPool.next = x;
			x.val = cast null;
			x.next = null;
			mPoolSize++;
		}
		else
			x.mList = null;
		return val;
	}
}

#if generic
@:generic
#end
@:dox(hide)
class SllIterator<T> implements de.polygonal.ds.Itr<T>
{
	var mObject:Sll<T>;
	var mWalker:SllNode<T>;
	var mHook:SllNode<T>;
	
	public function new(x:Sll<T>)
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
class CircularSllIterator<T> implements de.polygonal.ds.Itr<T>
{
	var mObject:Sll<T>;
	var mWalker:SllNode<T>;
	var mI:Int;
	var mS:Int;
	var mHook:SllNode<T>;
	
	public function new(x:Sll<T>)
	{
		mObject = x;
		reset();
	}
	
	public inline function reset():Itr<T>
	{
		mWalker = mObject.head;
		mS = mObject.size;
		mHook = null;
		mI = 0;
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