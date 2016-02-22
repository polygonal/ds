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

import de.polygonal.ds.tools.ArrayTools;
import de.polygonal.ds.tools.Assert.assert;
import de.polygonal.ds.tools.M;

using de.polygonal.ds.tools.NativeArrayTools;

/**
	A deque is a "double-ended queue"
	
	This is a linear list for which all insertions and deletions (and usually all accesses) are made at ends of the list.
**/
#if generic
@:generic
#end
class LinkedDeque<T> implements Deque<T>
{
	/**
		A unique identifier for this object.
		
		A hash table transforms this key into an index of an array element by using a hash function.
		
		<warn>This value should never be changed by the user.</warn>
	**/
	public var key(default, null):Int = HashKey.next();
	
	/**
		If true, reuses the iterator object instead of allocating a new one when calling ``iterator()``.
		
		The default is false.
		
		<warn>If true, nested iterations are likely to fail as only one iteration is allowed at a time.</warn>
	**/
	public var reuseIterator:Bool = false;
	
	var mHead:LinkedDequeNode<T> = null;
	var mTail:LinkedDequeNode<T> = null;
	
	var mHeadPool:LinkedDequeNode<T>;
	var mTailPool:LinkedDequeNode<T>;
	
	var mSize:Int = 0;
	var mReservedSize:Int;
	var mPoolSize:Int = 0;
	var mIterator:LinkedDequeIterator<T> = null;
	
	/**
		<assert>reserved size is greater than allowed size</assert>
		@param reservedSize if > 0, this queue maintains an object pool of node objects.
		Prevents frequent node allocation and thus increases performance at the cost of using more memory.
	**/
	public function new(reservedSize:Null<Int> = 0, ?source:Array<T>)
	{
		mReservedSize = reservedSize;
		mHeadPool = mTailPool = new LinkedDequeNode<T>(cast null);
		
		if (source != null)
		{
			if (source.length == 0) return;
			
			mSize = source.length;
			
			var node = getNode(source[0]);
			mHead = mTail = node;
			for (i in 1...mSize)
			{
				var node = getNode(source[i]);
				node.next = mHead;
				mHead.prev = node;
				mHead = node;
			}
		}
	}
	
	/**
		Returns the first element of this deque.
		<assert>deque is empty</assert>
	**/
	public inline function front():T
	{
		assert(size > 0, "deque is empty");
		
		return mHead.val;
	}
	
	/**
		Inserts the element `x` at the front of this deque.
	**/
	public inline function pushFront(x:T)
	{
		var node = getNode(x);
		node.next = mHead;
		if (mHead != null) mHead.prev = node;
		mHead = node;
		
		if (mSize++ == 0) mTail = mHead;
	}
	
	/**
		Removes and returns the element at the beginning of this deque.
		<assert>deque is empty</assert>
	**/
	public inline function popFront():T
	{
		assert(size > 0, "deque is empty");
		
		var node = mHead;
		mHead = mHead.next;
		if (mHead != null) mHead.prev = null;
		node.next = null;
		if (--mSize == 0) mTail = null;
		return putNode(node, true);
	}
	
	/**
		Returns the last element of the deque.
		<assert>deque is empty</assert>
	**/
	public inline function back():T
	{
		assert(size > 0, "deque is empty");
		
		return mTail.val;
	}
	
	/**
		Inserts the element `x` at the back of the deque.
	**/
	public inline function pushBack(x:T)
	{
		var node = getNode(x);
		node.prev = mTail;
		if (mTail != null) mTail.next = node;
		mTail = node;
		
		if (mSize++ == 0) mHead = mTail;
	}
	
	/**
		Deletes the element at the end of the deque.
		<assert>deque is empty</assert>
	**/
	public inline function popBack():T
	{
		assert(size > 0, "deque is empty");
		
		var node = mTail;
		mTail = mTail.prev;
		node.prev = null;
		if (mTail != null) mTail.next = null;
		if (--mSize == 0) mHead = null;
		return putNode(node, true);
	}
	
	/**
		Returns the element at index `i` relative to the front of this deque.
		
		The front element is at index [0], the back element is at index [``size`` - 1].
		<assert>deque is empty</assert>
		<assert>`i` out of range</assert>
	**/
	public function getFront(i:Int):T
	{
		assert(i < size, 'index out of range ($i)');
		
		var node = mHead;
		for (j in 0...i) node = node.next;
		return node.val;
	}
	
	/**
		Returns the index of the first occurence of the element `x` or -1 if `x` does not exist.
		
		The front element is at index [0], the back element is at index [``size`` - 1].
	**/
	public function indexOfFront(x:T):Int
	{
		var node = mHead;
		for (i in 0...size)
		{
			if (node.val == x) return i;
			node = node.next;
		}
		return -1;
	}
	
	/**
		Returns the element at index `i` relative to the back of this deque.
		
		The back element is at index [0], the front element is at index [``size`` - 1].
		<assert>deque is empty</assert>
		<assert>`i` out of range</assert>
	**/
	public function getBack(i:Int):T
	{
		assert(i < size, 'index out of range ($i)');
		
		var node = mTail;
		for (j in 0...i) node = node.prev;
		return node.val;
	}
	
	/**
		Returns the index of the first occurence of the element `x` or -1 if `x` does not exist.
		
		The back element is at index [0], the front element is at index [``size`` - 1].
	**/
	public function indexOfBack(x:T):Int
	{
		var node = mTail;
		for (i in 0...size)
		{
			if (node.val == x) return i;
			node = node.prev;
		}
		return -1;
	}
	
	public function forEach(f:T->Int->T):LinkedDeque<T>
	{
		var node = mHead;
		for (i in 0...size)
		{
			node.val = f(node.val, i);
			node = node.next;
		}
		return this;
	}
	
	/**
		Returns a string representing the current object.
		
		Example:
		<pre class="prettyprint">
		var deque = new de.polygonal.ds.LinkedDeque<Int>();
		for (i in 0...4) {
		    deque.pushFront(i);
		}
		trace(deque);</pre>
		<pre class="console">
		{ LinkedDeque, size: 4 }
		[ front
		  0 -> 3
		  1 -> 2
		  2 -> 1
		  3 -> 0
		]</pre>
	**/
	public function toString():String
	{
		var b = new StringBuf();
		b.add('{ LinkedDeque size: ${size} }');
		if (isEmpty()) return b.toString();
		b.add("\n[ front\n");
		var node = mHead, i = 0, args = new Array<Dynamic>();
		var fmt = '  %${M.numDigits(size)}d: %s\n';
		while (node != null)
		{
			args[0] = i++;
			args[1] = Std.string(node.val);
			b.add(Printf.format(fmt, args));
			node = node.next;
		}
		b.add("]");
		return b.toString();
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
		Destroys this object by explicitly nullifying all elements for GC'ing used resources.
		
		Improves GC efficiency/performance (optional).
	**/
	public function free()
	{
		var node = mHead;
		while (node != null)
		{
			var next = node.next;
			node.next = node.prev = null;
			node.val = cast null;
			node = next;
		}
		
		mHead = mTail = null;
		
		var node = mHeadPool;
		while (node != null)
		{
			var next = node.next;
			node.next = node.prev = null;
			node.val = cast null;
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
		Returns true if this deque contains the element `x`.
	**/
	public function contains(x:T):Bool
	{
		var found = false;
		var node = mHead;
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
		Removes and nullifies all occurrences of the element `x`.
		@return true if at least one occurrence of `x` was removed.
	**/
	public function remove(x:T):Bool
	{
		var found = false;
		var node = mHead;
		while (node != null)
		{
			if (node.val == x)
			{
				found = true;
				
				var next = node.next;
				if (node.prev != null) node.prev.next = node.next;
				if (node.next != null) node.next.prev = node.prev;
				if (node == mHead) mHead = mHead.next;
				if (node == mTail) mTail = mTail.prev;
				putNode(node, true);
				
				mSize--;
				node = mHead;
			}
			else
				node = node.next;
		}
		return found;
	}
	
	/**
		Removes all elements.
		@param gc if true, elements are nullified upon removal so the garbage collector can reclaim used memory.
	**/
	public function clear(gc:Bool = false)
	{
		if (gc)
		{
			var node = mHead;
			while (node != null)
			{
				var next = node.next;
				putNode(node, true);
				node = next;
			}
			
			if (mReservedSize > 0)
			{
				var node = mHeadPool;
				while (node != null)
				{
					var next = node.next;
					node.next = node.prev = null;
					node.val = cast null;
					node = next;
				}
			}
		}
		
		mHead = mTail = null;
		mSize = 0;
	}
	
	/**
		Returns a new `LinkedDequeIterator` object to iterate over all elements contained in this deque.
		
		Preserves the natural order of a deque.
		
		See <a href="http://haxe.org/ref/iterators" target="mBlank">http://haxe.org/ref/iterators</a>
	**/
	public function iterator():Itr<T>
	{
		if (reuseIterator)
		{
			if (mIterator == null)
				return new LinkedDequeIterator<T>(this);
			else
				mIterator.reset();
			return mIterator;
		}
		else
			return new LinkedDequeIterator<T>(this);
	}
	
	/**
		Returns true if this deque is empty.
	**/
	public inline function isEmpty():Bool
	{
		return size == 0;
	}
	
	/**
		Returns an array containing all elements in this deque in the natural order.
	**/
	public function toArray():Array<T>
	{
		if (isEmpty()) return [];
		
		var out = ArrayTools.alloc(size);
		var i = 0;
		var node = mHead;
		while (node != null)
		{
			out[i++] = node.val;
			node = node.next;
		}
		return out;
	}
	
	/**
		Duplicates this deque. Supports shallow (structure only) and deep copies (structure & elements).
		<assert>element is not of type `Cloneable`</assert>
		@param assign if true, the `copier` parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.
		If false, the ``clone()`` method is called on each element. <warn>In this case all elements have to implement `Cloneable`.</warn>
		@param copier a custom function for copying elements. Replaces ``element::clone()`` if `assign` is false.
	**/
	public function clone(assign:Bool = true, copier:T->T = null):Collection<T>
	{
		if (size == 0) return new LinkedDeque<T>(mReservedSize);
		
		var copy = new LinkedDeque<T>(mReservedSize);
		copy.mSize = size;
		copy.mReservedSize = mReservedSize;
		copy.mPoolSize = mPoolSize;
		copy.mHeadPool = new LinkedDequeNode<T>(cast null);
		copy.mTailPool = new LinkedDequeNode<T>(cast null);
		
		if (assign)
		{
			var srcNode = mHead;
			var dstNode = copy.mHead = new LinkedDequeNode<T>(mHead.val);
			
			if (size == 1)
			{
				copy.mTail = copy.mHead;
				return copy;
			}
			
			var dstNode0, srcNode0;
			srcNode = srcNode.next;
			for (i in 1...size - 1)
			{
				dstNode0 = dstNode;
				srcNode0 = srcNode;
				
				dstNode = dstNode.next = new LinkedDequeNode<T>(srcNode.val);
				dstNode.prev = dstNode0;
				
				srcNode0 = srcNode;
				srcNode = srcNode0.next;
			}
			
			dstNode0 = dstNode;
			copy.mTail = dstNode.next = new LinkedDequeNode<T>(srcNode.val);
			copy.mTail.prev = dstNode0;
		}
		else
		if (copier == null)
		{
			var srcNode = mHead;
			
			assert(Std.is(mHead.val, Cloneable), "element is not of type Cloneable");
			
			var dstNode = copy.mHead = new LinkedDequeNode<T>(cast(mHead.val, Cloneable<Dynamic>).clone());
			
			if (size == 1)
			{
				copy.mTail = copy.mHead;
				return copy;
			}
			
			var dstNode0;
			srcNode = srcNode.next;
			for (i in 1...size - 1)
			{
				dstNode0 = dstNode;
				var srcNode0 = srcNode;
				
				assert(Std.is(srcNode.val, Cloneable), "element is not of type Cloneable");
				
				dstNode = dstNode.next = new LinkedDequeNode<T>(cast(srcNode.val, Cloneable<Dynamic>).clone());
				dstNode.prev = dstNode0;
				
				srcNode0 = srcNode;
				srcNode = srcNode0.next;
			}
			
			assert(Std.is(srcNode.val, Cloneable), "element is not of type Cloneable");
			
			dstNode0 = dstNode;
			copy.mTail = dstNode.next = new LinkedDequeNode<T>(cast(srcNode.val, Cloneable<Dynamic>).clone());
			copy.mTail.prev = dstNode0;
		}
		else
		{
			var srcNode = mHead;
			var dstNode = copy.mHead = new LinkedDequeNode<T>(copier(mHead.val));
			
			if (size == 1)
			{
				copy.mTail = copy.mHead;
				return copy;
			}
			
			var dstNode0;
			srcNode = srcNode.next;
			for (i in 1...size - 1)
			{
				dstNode0 = dstNode;
				var srcNode0 = srcNode;
				
				dstNode = dstNode.next = new LinkedDequeNode<T>(copier(srcNode.val));
				dstNode.prev = dstNode0;
				
				srcNode0 = srcNode;
				srcNode = srcNode0.next;
			}
			
			dstNode0 = dstNode;
			copy.mTail = dstNode.next = new LinkedDequeNode<T>(copier(srcNode.val));
			copy.mTail.prev = dstNode0;
		}
		return copy;
	}
	
	inline function getNode(x:T)
	{
		if (mReservedSize == 0 || mPoolSize == 0)
			return new LinkedDequeNode<T>(x);
		else
		{
			var node = mHeadPool;
			mHeadPool = mHeadPool.next;
			mPoolSize--;
			node.val = x;
			return node;
		}
	}
	
	inline function putNode(x:LinkedDequeNode<T>, nullify:Bool):T
	{
		var val = x.val;
		if (mReservedSize > 0)
		{
			if (mPoolSize < mReservedSize)
			{
				mTailPool = mTailPool.next = x;
				mPoolSize++;
				if (nullify)
				{
					x.prev = x.next = null;
					x.val = cast null;
				}
			}
		}
		return val;
	}
	
	inline function removeNode(x:LinkedDequeNode<T>)
	{
		var next = x.next;
		if (x.prev != null) x.prev.next = x.next;
		if (x.next != null) x.next.prev = x.prev;
		if (x == mHead) mHead = mHead.next;
		if (x == mTail) mTail = mTail.prev;
		putNode(x, true);
		mSize--;
	}
}

#if generic
@:generic
#end
@:dox(hide)
class LinkedDequeNode<T>
{
	public var val:T;
	public var prev:LinkedDequeNode<T>;
	public var next:LinkedDequeNode<T>;
	
	public function new(x:T)
	{
		val = x;
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
@:access(de.polygonal.ds.LinkedDeque)
@:dox(hide)
class LinkedDequeIterator<T> implements de.polygonal.ds.Itr<T>
{
	var mObject:LinkedDeque<T>;
	var mWalker:LinkedDequeNode<T>;
	var mHook:LinkedDequeNode<T>;
	
	public function new(x:LinkedDeque<T>)
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
		mWalker = mObject.mHead;
		mHook = null;
		return this;
	}
	
	public inline function hasNext():Bool
	{
		return mWalker != null;
	}
	
	public inline function next():T
	{
		var x:T = mWalker.val;
		mHook = mWalker;
		mWalker = mWalker.next;
		return x;
	}
	
	public function remove()
	{
		assert(mHook != null, "call next() before removing an element");
		
		mObject.removeNode(mHook);
	}
}