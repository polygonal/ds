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
	A queue based on a linked list
	
	A queue is a linear list for which all insertions are made at one end of the list; all deletions (and usually all accesses) are made at the other end.
	
	This is called a FIFO structure (First In, First Out).
	
	Example:
		var o = new de.polygonal.ds.LinkedQueue<Int>();
		for (i in 0...4) o.enqueue(i);
		trace(o); //outputs:
		
		[ LinkedQueue size=4
		  front
		  0 -> 0
		  1 -> 1
		  2 -> 2
		  3 -> 3
		]
**/
#if generic
@:generic
#end
class LinkedQueue<T> implements Queue<T>
{
	/**
		A unique identifier for this object.
		
		A hash table transforms this key into an index of an array element by using a hash function.
	**/
	public var key(default, null):Int = HashKey.next();
	
	/**
		If true, reuses the iterator object instead of allocating a new one when calling `this.iterator()`.
		
		The default is false.
		
		_If this value is true, nested iterations will fail as only one iteration is allowed at a time._
	**/
	public var reuseIterator:Bool = false;
	
	var mHead:LinkedQueueNode<T>;
	var mTail:LinkedQueueNode<T>;
	
	var mSize:Int = 0;
	var mReservedSize:Int;
	var mPoolSize:Int = 0;
	
	var mHeadPool:LinkedQueueNode<T>;
	var mTailPool:LinkedQueueNode<T>;
	
	var mIterator:LinkedQueueIterator<T> = null;
	
	/**
		@param reservedSize if > 0, this queue maintains an object pool of node objects.
		Prevents frequent node allocation and thus increases performance at the cost of using more memory.
	**/
	public function new(reservedSize:Null<Int> = 0, ?source:Array<T>)
	{
		mReservedSize = reservedSize;
		if (reservedSize > 0)
		{
			mHeadPool = mTailPool = new LinkedQueueNode<T>(cast null);
		}
		else
		{
			mHeadPool = null;
			mTailPool = null;
		}
		
		if (source != null && source.length > 0)
		{
			mSize = source.length;
			mHead = mTail = getNode(source[0]);
			for (i in 1...size)
				mTail = mTail.next = getNode(source[i]);
		}
		else
			mHead = mTail = null;
	}
	
	/**
		Returns the front element.
		
		This is the "oldest" element.
	**/
	public inline function peek():T
	{
		assert(mHead != null, "queue is empty");
		
		return mHead.val;
	}
	
	/**
		Returns the rear element.
		
		This is the "newest" element.
	**/
	public inline function back():T
	{
		assert(mTail != null, "queue is empty");
		
		return mTail.val;
	}
	
	/**
		Enqueues `val`.
	**/
	public inline function enqueue(val:T)
	{
		mSize++;
		
		var node = getNode(val);
		if (mHead == null)
		{
			mHead = mTail = node;
			mHead.next = null;
		}
		else
		{
			mTail.next = node;
			mTail = node;
		}
	}
	
	/**
		Dequeues and returns the front element.
	**/
	public inline function dequeue():T
	{
		assert(mHead != null, "queue is empty");
		
		mSize--;
		
		var node = mHead;
		if (mHead == mTail)
		{
			mHead = null;
			mTail = null;
		}
		else
			mHead = mHead.next;
		return putNode(node);
	}
	
	/**
		Calls `f` on all elements.
		
		The function signature is: `f(input, index):output`
		
		- input: current element
		- index: position relative to the front(=0) of the queue
		- output: element to be stored at given index
	**/
	public inline function forEach(f:T->Int->T):LinkedQueue<T>
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
		Calls 'f` on all elements in order.
	**/
	public inline function iter(f:T->Void):LinkedQueue<T>
	{
		assert(f != null);
		var node = mHead;
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
	public function shuffle(rvals:Array<Float> = null):LinkedQueue<T> 
	{
		var s = size;
		if (rvals == null)
		{
			while (s > 1)
			{
				s--;
				var i = Std.int(Shuffle.frand() * s);
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
			assert(rvals.length >= size, "insufficient random values");
			
			var j = 0;
			while (s > 1)
			{
				s--;
				var i = Std.int(rvals[j++] * s);
				var node1 = mHead;
				for (k in 0...s) node1 = node1.next;
				
				var t = node1.val;
				
				var node2 = mHead;
				for (l in 0...i) node2 = node2.next;
				
				node1.val = node2.val;
				node2.val = t;
			}
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
		b.add('[ LinkedQueue size=$size');
		if (isEmpty())
		{
			b.add(" ]");
			return b.toString();
		}
		b.add("\n  front\n");
		var node = mHead, i = 0, args = new Array<Dynamic>();
		var fmt = '  %${MathTools.numDigits(size)}d -> %s\n';
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
	#end
	
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
		Destroys this object by explicitly nullifying all nodes, pointers and elements.
		
		Improves GC efficiency/performance (optional).
	**/
	public function free()
	{
		var node = mHead, next;
		while (node != null)
		{
			next = node.next;
			node.next = null;
			node.val = cast null;
			node = next;
		}
		
		mHead = mTail = null;
		
		node = mHeadPool;
		while (node != null)
		{
			next = node.next;
			node.next = null;
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
		Returns true if this queue contains `val`.
	**/
	public function contains(val:T):Bool
	{
		var node = mHead;
		while (node != null)
		{
			if (node.val == val)
				return true;
			node = node.next;
		}
		return false;
	}
	
	/**
		Removes and nullifies all occurrences of `val`.
		@return true if at least one occurrence of `val` was removed.
	**/
	public function remove(val:T):Bool
	{
		if (isEmpty()) return false;
		
		var found = false;
		var node0 = mHead;
		var node1 = mHead.next;
		
		if (mHead == mTail)
		{
			if (mHead.val == val)
			{
				mSize = 0;
				putNode(mHead);
				mHead = null;
				mTail = null;
				return true;
			}
			return false;
		}
		
		while (node1 != null)
		{
			if (node1.val == val)
			{
				found = true;
				if (node1 == mTail) mTail = node0;
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
		
		if (mHead.val == val)
		{
			found = true;
			var head1 = mHead.next;
			putNode(mHead);
			mHead = head1;
			if (mHead == null) mTail = null;
			mSize--;
		}
		return found;
	}
	
	/**
		Removes all elements.
		@param gc if true, elements are nullified upon removal so the garbage collector can reclaim used memory.
	**/
	public function clear(gc:Bool = false)
	{
		if (gc || mReservedSize > 0)
		{
			var node = mHead;
			while (node != null)
			{
				var next = node.next;
				putNode(node);
				node = next;
			}
		}
		mHead = mTail = null;
		mSize = 0;
	}
	
	/**
		Returns a new `LinkedQueue` object to iterate over all elements contained in this queue.
		
		Preserves the natural order of a queue (First-In-First-Out).
		
		@see http://haxe.org/ref/iterators
	**/
	public function iterator():Itr<T>
	{
		if (reuseIterator)
		{
			if (mIterator == null)
				return new LinkedQueueIterator<T>(this);
			else
				mIterator.reset();
			return mIterator;
		}
		else
			return new LinkedQueueIterator<T>(this);
	}
	
	/**
		Returns true only if `this.size` is 0.
	**/
	public inline function isEmpty():Bool
	{
		return size == 0;
	}
	
	/**
		Returns an array containing all elements in this queue.
		
		Preserves the natural order of this queue (First-In-First-Out).
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
		Creates and returns a shallow copy (structure only - default) or deep copy (structure & elements) of this queue.
		
		If `byRef` is true, primitive elements are copied by value whereas objects are copied by reference.
		
		If `byRef` is false, the `copier` function is used for copying elements. If omitted, `clone()` is called on each element assuming all elements implement `Cloneable`.
	**/
	public function clone(byRef:Bool = true, copier:T->T = null):Collection<T>
	{
		var copy = new LinkedQueue<T>(mReservedSize);
		if (size == 0) return copy;
		
		if (byRef)
		{
			var node = mHead;
			if (node != null)
			{
				copy.mHead = copy.mTail = new LinkedQueueNode<T>(node.val);
				copy.mHead.next = copy.mTail;
			}
			
			if (size > 1)
			{
				node = node.next;
				while (node != null)
				{
					var t = new LinkedQueueNode<T>(node.val);
					copy.mTail = copy.mTail.next = t;
					node = node.next;
				}
			}
		}
		else
		if (copier == null)
		{
			var node = mHead;
			if (node != null)
			{
				assert(Std.is(node.val, Cloneable), "element is not of type Cloneable");
				
				copy.mHead = copy.mTail = new LinkedQueueNode<T>(cast(node.val, Cloneable<Dynamic>).clone());
				copy.mHead.next = copy.mTail;
			}
			
			if (size > 1)
			{
				node = node.next;
				var t;
				while (node != null)
				{
					assert(Std.is(node.val, Cloneable), "element is not of type Cloneable");
					
					t = new LinkedQueueNode<T>(cast(node.val, Cloneable<Dynamic>).clone());
					copy.mTail = copy.mTail.next = t;
					node = node.next;
				}
			}
		}
		else
		{
			var node = mHead;
			if (node != null)
			{
				copy.mHead = copy.mTail = new LinkedQueueNode<T>(copier(node.val));
				copy.mHead.next = copy.mTail;
			}
			if (size > 1)
			{
				node = node.next;
				while (node != null)
				{
					var t = new LinkedQueueNode<T>(copier(node.val));
					copy.mTail = copy.mTail.next = t;
					node = node.next;
				}
			}
		}
		
		copy.mSize = size;
		return copy;
	}
	
	inline function getNode(x:T)
	{
		if (mReservedSize == 0 || mPoolSize == 0)
			return new LinkedQueueNode<T>(x);
		else
		{
			var n = mHeadPool;
			mHeadPool = mHeadPool.next;
			mPoolSize--;
			
			n.val = x;
			return n;
		}
	}
	
	inline function putNode(x:LinkedQueueNode<T>):T
	{
		var val = x.val;
		
		if (mReservedSize > 0 && mPoolSize < mReservedSize)
		{
			mTailPool = mTailPool.next = x;
			x.val = cast null;
			x.next = null;
			mPoolSize++;
		}
		return val;
	}
	
	inline function removeNode(x:LinkedQueueNode<T>)
	{
		var n = mHead;
		if (x == n)
		{
			mHead = x.next;
			if (x == mTail)
				mTail = null;
		}
		else
		{
			while (n.next != x) n = n.next;
			if (x == mTail)
				mTail = null;
			n.next = x.next;
		}
		putNode(x);
		mSize--;
	}
}

#if generic
@:generic
#end
@:dox(hide)
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
@:access(de.polygonal.ds.LinkedQueue)
@:dox(hide)
class LinkedQueueIterator<T> implements de.polygonal.ds.Itr<T>
{
	var mObject:LinkedQueue<T>;
	var mWalker:LinkedQueueNode<T>;
	var mHook:LinkedQueueNode<T>;
	
	public function new(x:LinkedQueue<T>)
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
		var x = mWalker.val;
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