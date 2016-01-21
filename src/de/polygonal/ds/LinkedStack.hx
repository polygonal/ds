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
	A stack based on a linked list
	
	A stack is a linear list for which all insertions and deletions (and usually all accesses) are made at one end of the list.
	
	This is called a FIFO structure (First In, First Out).
	
	_<o>Worst-case running time in Big O notation</o>_
**/
#if generic
@:generic
#end
class LinkedStack<T> implements Stack<T>
{
	/**
		A unique identifier for this object.
		
		A hash table transforms this key into an index of an array element by using a hash function.
		
		<warn>This value should never be changed by the user.</warn>
	**/
	public var key:Int;
	
	/**
		The maximum allowed size of this stack.
		
		Once the maximum size is reached, adding an element will fail with an error (debug only).
		
		A value of -1 indicates that the size is unbound.
		
		<warn>Always equals -1 in release mode.</warn>
	**/
	public var maxSize:Int;
	
	/**
		If true, reuses the iterator object instead of allocating a new one when calling ``iterator()``.
		
		The default is false.
		
		<warn>If true, nested iterations are likely to fail as only one iteration is allowed at a time.</warn>
	**/
	public var reuseIterator:Bool;
	
	var mHead:LinkedStackNode<T>;
	
	var mTop:Int;
	var mReservedSize:Int;
	var mPoolSize:Int;
	
	var mHeadPool:LinkedStackNode<T>;
	var mTailPool:LinkedStackNode<T>;
	
	var mIterator:LinkedStackIterator<T>;
	
	/**
		<assert>reserved size is greater than allowed size</assert>
		@param reservedSize if > 0, this stack maintains an object pool of node objects.
		Prevents frequent node allocation and thus increases performance at the cost of using more memory.
		@param maxSize the maximum allowed size of the stack.
		The default value of -1 indicates that there is no upper limit.
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
		mTop = 0;
		mPoolSize = 0;
		mHead = null;
		mIterator = null;
		
		if (reservedSize > 0)
		{
			mHeadPool = mTailPool = new LinkedStackNode<T>(cast null);
		}
		else
		{
			mHeadPool = null;
			mTailPool = null;
		}
		
		key = HashKey.next();
		reuseIterator = false;
	}
	
	/**
		Returns the top element of this stack.
		
		This is the "newest" element.
		<o>1</o>
		<assert>stack is empty</assert>
	**/
	inline public function top():T
	{
		assert(mTop > 0, "stack is empty");

		return mHead.val;
	}
	
	/**
		Pushes the element `x` onto the stack.
		<o>1</o>
		<assert>``size()`` equals ``maxSize``</assert>
	**/
	inline public function push(x:T)
	{
		if (maxSize != -1)
			assert(size() < maxSize, 'size equals max size ($maxSize)');
		
		var node = getNode(x);
		node.next = mHead;
		mHead = node;
		mTop++;
	}
	
	/**
		Pops data off the stack.
		<o>1</o>
		@return the top element.
		<assert>stack is empty</assert>
	**/
	inline public function pop():T
	{
		assert(mTop > 0, "stack is empty");
		
		mTop--;
		var node = mHead;
		mHead = mHead.next;
		
		return putNode(node);
	}
	
	/**
		Pops the top element of the stack, and pushes it back twice, so that an additional copy of the former top item is now on top, with the original below it.
		<o>1</o>
		<assert>stack is empty</assert>
		<assert>``size()`` equals ``maxSize``</assert>
	**/
	inline public function dup()
	{
		assert(mTop > 0, "stack is empty");
		
		#if debug
		if (maxSize != -1)
			assert(size() < maxSize, 'size equals max size ($maxSize)');
		#end
		
		var node = getNode(mHead.val);
		node.next = mHead;
		mHead = node;
		mTop++;
	}
	
	/**
		Swaps the two topmost items on the stack.
		<o>1</o>
		<assert>``size()`` < 2</assert>
	**/
	inline public function exchange()
	{
		assert(mTop > 1, "size() < 2");
		
		var tmp = mHead.val;
		mHead.val = mHead.next.val;
		mHead.next.val = tmp;
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
		<o>n</o>
		<assert>``size()`` >= `n`</assert>
	**/
	inline public function rotRight(n:Int)
	{
		assert(mTop >= n, "size() < n");
		
		var node = mHead;
		for (i in 0...n - 2)
			node = node.next;
		
		var bot = node.next;
		node.next = bot.next;
		
		bot.next = mHead;
		mHead = bot;
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
		<o>n</o>
		<assert>``size()`` >= `n`</assert>
	**/
	inline public function rotLeft(n:Int)
	{
		assert(mTop >= n, "size() < n");
		
		var top = mHead;
		mHead = mHead.next;
		
		var node = mHead;
		for (i in 0...n - 2)
			node = node.next;
		
		top.next = node.next;
		node.next = top;
	}
	
	/**
		Returns the element stored at index `i`.
		
		An index of 0 indicates the bottommost element.
		
		An index of ``size()`` - 1 indicates the topmost element.
		<o>n</o>
		<assert>stack is empty or `i` out of range</assert>
	**/
	inline public function get(i:Int):T
	{
		assert(mTop > 0, "stack is empty");
		assert(i >= 0 && i < mTop, 'i index out of range ($i)');
		
		var node = mHead;
		i = size() - i;
		while (--i > 0) node = node.next;
		return node.val;
	}
	
	/**
		Replaces the element at index `i` with the element `x`.
		
		An index of 0 indicates the bottommost element.
		
		An index of ``size()`` - 1 indicates the topmost element.
		<o>n</o>
		<assert>stack is empty or `i` out of range</assert>
	**/
	inline public function set(i:Int, x:T)
	{
		assert(mTop > 0, "stack is empty");
		assert(i >= 0 && i < mTop, 'i index out of range ($i)');
		
		var node = mHead;
		i = size() - i;
		while (--i > 0) node = node.next;
		node.val = x;
	}
	
	/**
		Swaps the element stored at `i` with the element stored at index `j`.
		
		An index of 0 indicates the bottommost element.
		
		An index of ``size()`` - 1 indicates the topmost element.
		<o>n</o>
		<assert>stack is empty</assert>
		<assert>`i`/`j` out of range</assert>
		<assert>`i` equals `j`</assert>
	**/
	inline public function swp(i:Int, j:Int)
	{
		assert(mTop > 0, "stack is empty");
		assert(i >= 0 && i < mTop, 'i index out of range ($i)');
		assert(j >= 0 && j < mTop, 'j index out of range ($j)');
		assert(i != j, 'i index equals j index ($i)');
		
		var node = mHead;
		
		if (i < j)
		{
			i ^= j;
			j ^= i;
			i ^= j;
		}
		
		var k = mTop - 1;
		while (k > i)
		{
			node = node.next;
			k--;
		}
		var a = node;
		while (k > j)
		{
			node = node.next;
			k--;
		}
		var tmp = a.val;
		a.val = node.val;
		node.val = tmp;
	}
	
	/**
		Overwrites the element at index `i` with the element from index `j`.
		
		An index of 0 indicates the bottommost element.
		
		An index of ``size()`` - 1 indicates the topmost element.
		<o>n</o>
		<assert>stack is empty</assert>
		<assert>`i`/`j` out of range</assert>
		<assert>`i` equals `j`</assert>
	**/
	inline public function cpy(i:Int, j:Int)
	{
		assert(mTop > 0, "stack is empty");
		assert(i >= 0 && i < mTop, 'i index out of range ($i)');
		assert(j >= 0 && j < mTop, 'j index out of range ($j)');
		assert(i != j, 'i index equals j index ($i)');
		
		var node = mHead;
		
		if (i < j)
		{
			i ^= j;
			j ^= i;
			i ^= j;
		}
		
		var k = mTop - 1;
		while (k > i)
		{
			node = node.next;
			k--;
		}
		var val = node.val;
		while (k > j)
		{
			node = node.next;
			k--;
		}
		node.val = val;
	}
	
	/**
		Replaces up to `n` existing elements with objects of type `cl`.
		<o>n</o>
		<assert>`n` out of range</assert>
		@param cl the class to instantiate for each element.
		@param args passes additional constructor arguments to the class `cl`.
		@param n the number of elements to replace. If 0, `n` is set to ``size()``.
	**/
	public function assign(cl:Class<T>, args:Array<Dynamic> = null, n = 0)
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
		var node = mHead;
		for (i in 0...n)
		{
			node.val = Type.createInstance(cl, args);
			node = node.next;
		}
	}
	
	/**
		Replaces up to `n` existing elements with the instance `x`.
		<o>n</o>
		<assert>`n` out of range</assert>
		@param n the number of elements to replace. If 0, `n` is set to ``size()``.
	**/
	public function fill(x:T, n = 0):LinkedStack<T>
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
		
		var node = mHead;
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
		<assert>insufficient random values</assert>
		@param rval a list of random double values in the range between 0 (inclusive) to 1 (exclusive) defining the new positions of the elements.
		If omitted, random values are generated on-the-fly by calling `Math::random()`.
	**/
	public function shuffle(rval:Array<Float> = null)
	{
		var s = mTop;
		
		if (rval == null)
		{
			var m = Math;
			while (s > 1)
			{
				s--;
				var i = Std.int(m.random() * s);
				var node1 = mHead;
				for (j in 0...s) node1 = node1.next;
				
				var t = node1.val;
				
				var node2 = mHead;
				for (j in 0...i) node2 = node2.next;
				
				node1.val = node2.val;
				node2.val = t;
			}
		}
		else
		{
			assert(rval.length >= size(), "insufficient random values");
			
			var k = 0;
			while (s > 1)
			{
				s--;
				var i = Std.int(rval[k++] * s);
				var node1 = mHead;
				for (j in 0...s) node1 = node1.next;
				
				var t = node1.val;
				
				var node2 = mHead;
				for (j in 0...i) node2 = node2.next;
				
				node1.val = node2.val;
				node2.val = t;
			}
		}
	}
	
	/**
		Returns a string representing the current object.
		
		Example:
		<pre class="prettyprint">
		var ls = new de.polygonal.ds.LinkedStack<Int>();
		ls.push(0);
		ls.push(1);
		ls.push(2);
		trace(ls);</pre>
		<pre class="console">
		{LinkedStack size: 3}
		[ top
		    0 -> 2
		    1 -> 1
		    2 -> 0
		]</pre>
	**/
	public function toString():String
	{
		var s = '{ LinkedStack size: ${size()} }';
		if (isEmpty()) return s;
		s += "\n[ top\n";
		var node = mHead;
		var i = mTop - 1;
		while (i >= 0)
		{
			s += '  $i -> ${Std.string(node.val)}\n';
			i--;
			node = node.next;
		}
		s += "]";
		return s;
	}
	
	/*///////////////////////////////////////////////////////
	// collection
	///////////////////////////////////////////////////////*/
	
	/**
		Destroys this object by explicitly nullifying all nodes, pointers and elements.
		
		Improves GC efficiency/performance (optional).
		<o>n</o>
	**/
	public function free()
	{
		var node = mHead;
		while (node != null)
		{
			var next = node.next;
			node.next = null;
			node.val = cast null;
			node = next;
		}
		
		mHead = null;
		
		var node = mHeadPool;
		while (node != null)
		{
			var next = node.next;
			node.next = null;
			node.val = cast null;
			node = next;
		}
		
		mHeadPool = mTailPool = null;
		mIterator = null;
	}
	
	/**
		Returns true if this stack contains the element `x`.
		<o>n</o>
	**/
	public function contains(x:T):Bool
	{
		var node = mHead;
		while (node != null)
		{
			if (node.val == x)
				return true;
			node = node.next;
		}
		return false;
	}
	
	/**
		Removes and nullifies all occurrences of the element `x`.
		<o>n</o>
		@return true if at least one occurrence of `x` was removed.
	**/
	public function remove(x:T):Bool
	{
		if (isEmpty()) return false;
		
		var found = false;
		var node0 = mHead;
		var node1 = mHead.next;
		
		while (node1 != null)
		{
			if (node1.val == x)
			{
				found = true;
				var node2 = node1.next;
				node0.next = node2;
				putNode(node1);
				node1 = node2;
				mTop--;
			}
			else
			{
				node0 = node1;
				node1 = node1.next;
			}
		}
		
		if (mHead.val == x)
		{
			found = true;
			var head1 = mHead.next;
			putNode(mHead);
			mHead = head1;
			mTop--;
		}
		
		return found;
	}
	
	/**
		Removes all elements.
		<o>1 or n if `purge` is true</o>
		@param purge if true, elements are nullified upon removal.
	**/
	public function clear(purge = false)
	{
		if (mTop == 0) return;
		
		if (purge || mReservedSize > 0)
		{
			var node = mHead;
			while (node != null)
			{
				var next = node.next;
				putNode(node);
				node = next;
			}
		}
		
		mHead.next = null;
		mHead.val = cast null;
		mTop = 0;
	}
	
	/**
		Returns a new `LinkedStackIterator` object to iterate over all elements contained in this stack.
		
		Preserves the natural order of the stack (First-In-Last-Out).
		
		See <a href="http://haxe.org/ref/iterators" target="mBlank">http://haxe.org/ref/iterators</a>
	**/
	public function iterator():Itr<T>
	{
		if (reuseIterator)
		{
			if (mIterator == null)
				return new LinkedStackIterator<T>(this);
			else
				mIterator.reset();
			return mIterator;
		}
		else
			return new LinkedStackIterator<T>(this);
	}
	
	/**
		Returns true if this stack is empty.
		<o>1</o>
	**/
	inline public function isEmpty():Bool
	{
		return mTop == 0;
	}
	
	/**
		The total number of elements.
		<o>1</o>
	**/
	inline public function size():Int
	{
		return mTop;
	}
	
	/**
		Returns an array containing all elements in this stack.
		
		Preserves the natural order of this stack (First-In-Last-Out).
	**/
	public function toArray():Array<T>
	{
		var a:Array<T> = ArrayUtil.alloc(size());
		ArrayUtil.fill(a, cast null, size());
		var node = mHead;
		for (i in 0...mTop)
		{
			a[mTop - i - 1] = node.val;
			node = node.next;
		}
		return a;
	}
	
	/**
		Returns a `Vector<T>` object containing all elements in this stack.
		
		Preserves the natural order of this stack (First-In-Last-Out).
	**/
	public function toVector():Vector<T>
	{
		var v = new Vector<T>(size());
		var node = mHead;
		for (i in 0...mTop)
		{
			v[mTop - i - 1] = node.val;
			node = node.next;
		}
		return v;
	}
	
	/**
		Duplicates this stack. Supports shallow (structure only) and deep copies (structure & elements).
		<assert>element is not of type `Cloneable`</assert>
		@param assign if true, the `copier` parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.
		If false, the ``clone()`` method is called on each element. <warn>In this case all elements have to implement `Cloneable`.</warn>
		@param copier a custom function for copying elements. Replaces ``element::clone()`` if `assign` is false.
	**/
	public function clone(assign = true, copier:T->T = null):Collection<T>
	{
		var copy = new LinkedStack<T>(mReservedSize, maxSize);
		if (mTop == 0) return copy;
		
		var copy = new LinkedStack<T>(mReservedSize, maxSize);
		copy.mTop = mTop;
		
		if (assign)
		{
			var srcNode = mHead;
			var dstNode = copy.mHead = new LinkedStackNode<T>(srcNode.val);
			
			srcNode = srcNode.next;
			while (srcNode != null)
			{
				dstNode = dstNode.next = new LinkedStackNode<T>(srcNode.val);
				srcNode = srcNode.next;
			}
		}
		else
		if (copier == null)
		{
			var srcNode = mHead;
			
			assert(Std.is(srcNode.val, Cloneable), 'element is not of type Cloneable (${srcNode.val})');
			
			var c = cast(srcNode.val, Cloneable<Dynamic>);
			var dstNode = copy.mHead = new LinkedStackNode<T>(c.clone());
			
			srcNode = srcNode.next;
			while (srcNode != null)
			{
				assert(Std.is(srcNode.val, Cloneable), 'element is not of type Cloneable (${srcNode.val})');
				
				c = cast(srcNode.val, Cloneable<Dynamic>);
				
				dstNode = dstNode.next = new LinkedStackNode<T>(c.clone());
				srcNode = srcNode.next;
			}
		}
		else
		{
			var srcNode = mHead;
			var dstNode = copy.mHead = new LinkedStackNode<T>(copier(srcNode.val));
			
			srcNode = srcNode.next;
			while (srcNode != null)
			{
				dstNode = dstNode.next = new LinkedStackNode<T>(copier(srcNode.val));
				srcNode = srcNode.next;
			}
		}
		
		return copy;
	}
	
	inline function getNode(x:T)
	{
		if (mReservedSize == 0 || mPoolSize == 0)
			return new LinkedStackNode<T>(x);
		else
		{
			var n = mHeadPool;
			mHeadPool = mHeadPool.next;
			mPoolSize--;
			
			n.val = x;
			return n;
		}
	}
	
	inline function putNode(x:LinkedStackNode<T>):T
	{
		var val = x.val;
		
		if (mReservedSize > 0 && mPoolSize < mReservedSize)
		{
			mTailPool = mTailPool.next = x;
			x.next = null;
			x.val = cast null;
			mPoolSize++;
		}
		return val;
	}
	
	inline function removeNode(x:LinkedStackNode<T>)
	{
		var n = mHead;
		if (x == n)
			mHead = x.next;
		else
		{
			while (n.next != x) n = n.next;
			n.next = x.next;
		}
		
		putNode(x);
		mTop--;
	}
}

#if generic
@:generic
#end
@:dox(hide)
class LinkedStackNode<T>
{
	public var val:T;
	public var next:LinkedStackNode<T>;
	
	public function new(x:T)
	{
		val = x;
	}
	
	public function toString():String
	{
		return Std.string(val);
	}
}

#if generic
@:generic
#end
@:access(de.polygonal.ds.LinkedStack)
@:dox(hide)
class LinkedStackIterator<T> implements de.polygonal.ds.Itr<T>
{
	var mF:LinkedStack<T>;
	var mWalker:LinkedStackNode<T>;
	var mHook:LinkedStackNode<T>;
	
	public function new(f:LinkedStack<T>)
	{
		mF = f;
		reset();
	}
	
	inline public function reset():Itr<T>
	{
		mWalker = mF.mHead;
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
		
		mF.removeNode(mHook);
	}
}