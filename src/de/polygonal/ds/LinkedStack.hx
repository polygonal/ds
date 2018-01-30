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
	A stack based on a linked list
	
	A stack is a linear list for which all insertions and deletions (and usually all accesses) are made at one end of the list.
	
	This is called a FIFO structure (First In, First Out).
	
	Example:
		var o = new de.polygonal.ds.LinkedStack<Int>();
		for (i in 0...4) o.push(i);
		trace(o); //outputs:
		
		[ LinkedStack size=4
		  top
		  3 -> 3
		  2 -> 2
		  1 -> 1
		  0 -> 0
		]
**/
#if generic
@:generic
#end
class LinkedStack<T> implements Stack<T>
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
	
	var mHead:LinkedStackNode<T> = null;
	
	var mTop:Int = 0;
	var mReservedSize:Int;
	var mPoolSize:Int = 0;
	
	var mHeadPool:LinkedStackNode<T>;
	var mTailPool:LinkedStackNode<T>;
	
	var mIterator:LinkedStackIterator<T> = null;
	
	/**
		@param reservedSize if > 0, this stack maintains an object pool of node objects.
		Prevents frequent node allocation and thus increases performance at the cost of using more memory.
	**/
	public function new(reservedSize:Null<Int> = 0, ?source:Array<T>)
	{
		mReservedSize = reservedSize;
		
		if (reservedSize > 0)
		{
			mHeadPool = mTailPool = new LinkedStackNode<T>(cast null);
		}
		else
		{
			mHeadPool = null;
			mTailPool = null;
		}
		
		if (source != null)
		{
			var node;
			mTop = source.length;
			for (i in 0...mTop)
			{
				node = getNode(source[i]);
				node.next = mHead;
				mHead = node;
			}
		}
	}
	
	/**
		Returns the top element of this stack.
		
		This is the "newest" element.
	**/
	public inline function top():T
	{
		assert(mTop > 0, "stack is empty");
		
		return mHead.val;
	}
	
	/**
		Pushes `val` onto the stack.
	**/
	public inline function push(val:T)
	{
		var node = getNode(val);
		node.next = mHead;
		mHead = node;
		mTop++;
	}
	
	/**
		Pops data off the stack.
		@return the top element.
	**/
	public inline function pop():T
	{
		assert(mTop > 0, "stack is empty");
		
		mTop--;
		var node = mHead;
		mHead = mHead.next;
		return putNode(node);
	}
	
	/**
		Pops the top element of the stack, and pushes it back twice, so that an additional copy of the former top item is now on top, with the original below it.
	**/
	public inline function dup():LinkedStack<T>
	{
		assert(mTop > 0, "stack is empty");
		
		var node = getNode(mHead.val);
		node.next = mHead;
		mHead = node;
		mTop++;
		return this;
	}
	
	/**
		Swaps the two topmost items on the stack.
	**/
	public inline function exchange():LinkedStack<T>
	{
		assert(mTop > 1, "size < 2");
		
		var t = mHead.val;
		mHead.val = mHead.next.val;
		mHead.next.val = t;
		return this;
	}
	
	/**
		Moves the `n` topmost elements on the stack in a rotating fashion.
		
		Example:
			top
			|3|               |0|
			|2|  rotate right |3|
			|1|      -->      |2|
			|0|               |1|
	**/
	public function rotRight(n:Int):LinkedStack<T>
	{
		assert(mTop >= n, "size < n");
		
		var node = mHead;
		for (i in 0...n - 2)
			node = node.next;
		
		var bot = node.next;
		node.next = bot.next;
		
		bot.next = mHead;
		mHead = bot;
		return this;
	}
	
	/**
		Moves the `n` topmost elements on the stack in a rotating fashion.
		
		Example:
			top
			|3|              |2|
			|2|  rotate left |1|
			|1|      -->     |0|
			|0|              |3|
	**/
	public function rotLeft(n:Int):LinkedStack<T>
	{
		assert(mTop >= n, "size < n");
		
		var top = mHead;
		mHead = mHead.next;
		
		var node = mHead;
		for (i in 0...n - 2)
			node = node.next;
		
		top.next = node.next;
		node.next = top;
		return this;
	}
	
	/**
		Returns the element stored at index `i`.
		
		An index of 0 indicates the bottommost element.
		
		An index of `this.size` - 1 indicates the topmost element.
	**/
	public function get(i:Int):T
	{
		assert(mTop > 0, "stack is empty");
		assert(i >= 0 && i < mTop, 'i index out of range ($i)');
		
		var node = mHead;
		i = size - i;
		while (--i > 0) node = node.next;
		return node.val;
	}
	
	/**
		Replaces the element at index `i` with `val`.
		
		An index of 0 indicates the bottommost element.
		
		An index of `this.size` - 1 indicates the topmost element.
	**/
	public function set(i:Int, val:T):LinkedStack<T>
	{
		assert(mTop > 0, "stack is empty");
		assert(i >= 0 && i < mTop, 'i index out of range ($i)');
		
		var node = mHead;
		i = size - i;
		while (--i > 0) node = node.next;
		node.val = val;
		return this;
	}
	
	/**
		Swaps the element stored at `i` with the element stored at index `j`.
		
		An index of 0 indicates the bottommost element.
		
		An index of `this.size` - 1 indicates the topmost element.
	**/
	public function swap(i:Int, j:Int):LinkedStack<T>
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
		var t = a.val;
		a.val = node.val;
		node.val = t;
		return this;
	}
	
	/**
		Overwrites the element at index `i` with the element from index `j`.
		
		An index of 0 indicates the bottommost element.
		
		An index of `this.size` - 1 indicates the topmost element.
	**/
	public function copy(i:Int, j:Int):LinkedStack<T>
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
		return this;
	}
	
	/**
		Calls `f` on all elements.
		
		The function signature is: `f(input, index):output`
		
		- input: current element
		- index: position relative to the bottom(=0) of the stack
		- output: element to be stored at given index
	**/
	public inline function forEach(f:T->Int->T):LinkedStack<T>
	{
		var node = mHead;
		var i = size;
		while (--i > -1)
		{
			node.val = f(node.val, i);
			node = node.next;
		}
		return this;
	}
	
	/**
		Calls 'f` on all elements in order.
	**/
	public inline function iter(f:T->Void):LinkedStack<T>
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
	public function shuffle(rvals:Array<Float> = null):LinkedStack<T>
	{
		var s = mTop;
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
			
			var k = 0;
			while (s > 1)
			{
				s--;
				var i = Std.int(rvals[k++] * s);
				var node1 = mHead;
				for (j in 0...s) node1 = node1.next;
				
				var t = node1.val;
				
				var node2 = mHead;
				for (j in 0...i) node2 = node2.next;
				
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
		b.add('[ LinkedStack size=$size');
		if (isEmpty())
		{
			b.add(" ]");
			return b.toString();
		}
		b.add("\n  top\n");
		var node = mHead, i = mTop - 1;
		var args = new Array<Dynamic>();
		var fmt = '  %${MathTools.numDigits(size)}d -> %s\n';
		while (i >= 0)
		{
			args[0] = i;
			args[1] = Std.string(node.val);
			b.add(Printf.format(fmt, args));
			i--;
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
		return mTop;
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
		
		mHead = null;
		
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
		Returns true if this stack contains `val`.
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
		
		while (node1 != null)
		{
			if (node1.val == val)
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
		
		if (mHead.val == val)
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
		@param gc if true, elements are nullified upon removal so the garbage collector can reclaim used memory.
	**/
	public function clear(gc:Bool = false)
	{
		if (mTop == 0) return;
		
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
		mHead.next = null;
		mHead.val = cast null;
		mTop = 0;
	}
	
	/**
		Returns a new *LinkedStackIterator* object to iterate over all elements contained in this stack.
		
		Preserves the natural order of the stack (First-In-Last-Out).
		
		@see http://haxe.org/ref/iterators
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
		Returns true only if `this.size` is 0.
	**/
	public inline function isEmpty():Bool
	{
		return mTop == 0;
	}
	
	/**
		Returns an array containing all elements in this stack.
		
		Preserves the natural order of this stack (First-In-Last-Out).
	**/
	public function toArray():Array<T>
	{
		if (isEmpty()) return [];
		
		var out = ArrayTools.alloc(size);
		var node = mHead;
		for (i in 0...mTop)
		{
			out[mTop - i - 1] = node.val;
			node = node.next;
		}
		return out;
	}
	
	/**
		Creates and returns a shallow copy (structure only - default) or deep copy (structure & elements) of this stack.
		
		If `byRef` is true, primitive elements are copied by value whereas objects are copied by reference.
		
		If `byRef` is false, the `copier` function is used for copying elements. If omitted, `clone()` is called on each element assuming all elements implement `Cloneable`.
	**/
	public function clone(byRef:Bool = true, copier:T->T = null):Collection<T>
	{
		var copy = new LinkedStack<T>(mReservedSize);
		if (mTop == 0) return copy;
		
		copy = new LinkedStack<T>(mReservedSize);
		copy.mTop = mTop;
		
		if (byRef)
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
			
			assert(Std.is(srcNode.val, Cloneable), "element is not of type Cloneable");
			
			var dstNode = copy.mHead = new LinkedStackNode<T>(cast(srcNode.val, Cloneable<Dynamic>).clone());
			
			srcNode = srcNode.next;
			while (srcNode != null)
			{
				assert(Std.is(srcNode.val, Cloneable), "element is not of type Cloneable");
				
				dstNode = dstNode.next = new LinkedStackNode<T>(cast(srcNode.val, Cloneable<Dynamic>).clone());
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
	var mObject:LinkedStack<T>;
	var mWalker:LinkedStackNode<T>;
	var mHook:LinkedStackNode<T>;
	
	public function new(x:LinkedStack<T>)
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