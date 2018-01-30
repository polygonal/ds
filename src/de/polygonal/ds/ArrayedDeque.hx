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
import de.polygonal.ds.tools.Bits;
import de.polygonal.ds.tools.MathTools;

using de.polygonal.ds.tools.NativeArrayTools;

/**
	A deque is a "double-ended queue"
	
	This is a linear list for which all insertions and deletions (and usually all accesses) are made at ends of the list.
	
	Example:
		var o = new de.polygonal.ds.ArrayedDeque<Int>();
		for (i in 0...4) o.pushFront(i);
		trace(o); //outputs:
		
		[ ArrayedDeque size=4
		  front
		  0 -> 3
		  1 -> 2
		  2 -> 1
		  3 -> 0
		]
**/
#if generic
@:generic
#end
class ArrayedDeque<T> implements Deque<T>
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
	
	var mBlockSize:Int;
	var mBlockSizeMinusOne:Int;
	var mBlockSizeShift:Int;
	var mHead:Int = 0;
	var mTail:Int = 1;
	var mTailBlockIndex:Int = 0;
	
	var mBlocks:NativeArray<NativeArray<T>>;
	var mNumBlocks:Int = 0;
	var mMaxBlocks:Int = 16;
	
	var mHeadBlock:NativeArray<T>;
	var mTailBlock:NativeArray<T>;
	var mHeadBlockNext:NativeArray<T> = null;
	var mTailBlockPrev:NativeArray<T> = null;
	
	var mBlockPool:NativeArray<NativeArray<T>>;
	var mPoolSize:Int = 0;
	var mPoolCapacity:Int;
	
	var mIterator:ArrayedDequeIterator<T> = null;
	
	/**
		@param blockSize a block represents a contiguous piece of memory; whenever the deque runs out of space an additional block with a capacity of `blockSize` elements is allocated and added to the list of existing blocks.
		The parameter affects the performance-memory trade-off: a large `blockSize` improves performances but wastes memory if the utilization is low; a small `blockSize` uses memory more efficiently but is slower due to frequent allocation of blocks.
		The default value is 64; the minimum value is 4.
		_`blockSize` has to be a power of two._
		@param blockPoolCapacity the total number of blocks to reuse when blocks are removed or relocated (from front to back or vice-versa). This improves performances but uses more memory.
		The default value is 4; a value of 0 disables block pooling.
		@param source copies all values from `source` in the range [0, `source.length` - 1] to this collection.
	**/
	public function new(blockSize:Null<Int> = 64, blockPoolCapacity:Null<Int> = 4, ?source:Array<T>)
	{
		assert(blockSize > 0);
		assert(MathTools.isPow2(blockSize), "blockSize is not a power of 2");
		assert(blockSize >= 4, "blockSize is too small");
		
		mBlockSize = blockSize;
		mBlockSizeMinusOne = blockSize - 1;
		mBlockSizeShift = Bits.ntz(blockSize);
		mPoolCapacity = blockPoolCapacity;
		mBlocks = NativeArrayTools.alloc(mMaxBlocks);
		mBlocks.set(mNumBlocks++, NativeArrayTools.alloc(blockSize));
		mHeadBlock = mBlocks.get(0);
		mTailBlock = mHeadBlock;
		mBlockPool = NativeArrayTools.alloc(mPoolCapacity);
		
		if (source != null)
			for (i in 0...source.length)
				pushBack(source[i]);
	}
	
	/**
		Returns the first element of this deque (index 0).
	**/
	public inline function front():T
	{
		assert(size > 0, "deque is empty");
		
		return (mHead == mBlockSizeMinusOne) ? mHeadBlockNext.get(0) : mHeadBlock.get(mHead + 1);
	}
	
	/**
		Inserts `val` at the front of this deque.
	**/
	public inline function pushFront(val:T)
	{
		mHeadBlock.set(mHead--, val);
		if (mHead == -1) unshiftBlock();
	}
	
	/**
		Removes and returns the element at the beginning of this deque.
	**/
	public inline function popFront():T
	{
		assert(size > 0, "deque is empty");
		
		if (mHead == mBlockSizeMinusOne)
		{
			shiftBlock();
			return mHeadBlock.get(0);
		}
		else
			return mHeadBlock.get(++mHead);
	}
	
	/**
		Returns the last element of the deque (index `this.size` - 1).
	**/
	public inline function back():T
	{
		assert(size > 0, "deque is empty");
		
		return (mTail == 0) ? (mTailBlockPrev.get(mBlockSizeMinusOne)) : mTailBlock.get(mTail - 1);
	}
	
	/**
		Inserts `val` at the back of the deque.
	**/
	public inline function pushBack(val:T)
	{
		mTailBlock.set(mTail++, val);
		if (mTail == mBlockSize)
			pushBlock();
	}
	
	/**
		Deletes the element at the end of the deque.
	**/
	public function popBack():T
	{
		assert(size > 0, "deque is empty");
		
		if (mTail == 0)
		{
			popBlock();
			return mTailBlock.get(mBlockSizeMinusOne);
		}
		else
			return mTailBlock.get(--mTail);
	}
	
	/**
		Returns the element at index `i` relative to the front of this deque.
		
		The front element is at index [0], the back element is at index [`this.size` - 1].
	**/
	public function getFront(i:Int):T
	{
		assert(i < size, 'index out of range ($i)');
		
		var c = (mHead + 1) + i;
		var b = (c >> mBlockSizeShift);
		return mBlocks.get(b).get(c - (b << mBlockSizeShift));
	}
	
	/**
		Returns the index of the first occurence of `val` or -1 if `val` does not exist.
		
		The front element is at index [0], the back element is at index [`this.size` - 1].
	**/
	public function indexOfFront(val:T):Int
	{
		for (i in 0...size)
		{
			var c = (mHead + 1) + i;
			var b = (c >> mBlockSizeShift);
			if (mBlocks.get(b).get(c - (b << mBlockSizeShift)) == val)
				return i;
		}
		return -1;
	}
	
	/**
		Returns the element at index `i` relative to the back of this deque.
		
		The back element is at index [0], the front element is at index [`this.size` - 1].
	**/
	public function getBack(i:Int):T
	{
		assert(i < size, 'index out of range ($i)');
		
		var c = mTail - 1 - i;
		var b = c >> mBlockSizeShift;
		return mBlocks.get(mTailBlockIndex + b).get(MathTools.abs(b << mBlockSizeShift) + c);
	}
	
	/**
		Returns the index of the first occurence of `val` or -1 if `val` does not exist.
		
		The back element is at index [0], the front element is at index [`this.size` - 1].
	**/
	public function indexOfBack(val:T):Int
	{
		for (i in 0...size)
		{
			var c = mTail - 1 - i;
			var b = c >> mBlockSizeShift;
			if (mBlocks.get(mTailBlockIndex + b).get(MathTools.abs(b << mBlockSizeShift) + c) == val)
				return i;
		}
		return -1;
	}
	
	/**
		Removes all superfluous blocks and overwrites elements stored in empty locations with null.
		
		An application can use this operation to free up memory by unlocking resources for the garbage collector.
	**/
	public function pack():ArrayedDeque<T>
	{
		for (i in 0...mHead + 1) mHeadBlock.set(i, cast null);
		for (i in mTail...mBlockSize) mTailBlock.set(i, cast null);
		mPoolSize = 0;
		mBlockPool.nullify();
		mBlockPool = NativeArrayTools.alloc(mPoolCapacity);
		return this;
	}
	
	/**
		Calls `f` on all elements.
		
		The function signature is: `f(input, index):output`
		
		- input: current element
		- index: position relative to the front(=0)
		- output: element to be stored at given index
	**/
	public function forEach(f:T->Int->T):ArrayedDeque<T>
	{
		var s = size;
		var i = mHead + 1;
		var j = i >> mBlockSizeShift;
		var k = 0;
		var b = mBlocks.get(j), bs = mBlockSize, blocks = mBlocks;
		i -= j << mBlockSizeShift;
		while (s > 0)
		{
			b.set(i, f(b.get(i), k++));
			if (++i == bs)
			{
				i = 0;
				b = blocks.get(++j);
			}
			s--;
		}
		return this;
	}
	
	/**
		Calls 'f` on all elements in order.
	**/
	public function iter(f:T->Void):ArrayedDeque<T>
	{
		assert(f != null);
		var i = mHead + 1;
		var s = size;
		var b = i >> mBlockSizeShift;
		i -= b << mBlockSizeShift;
		var a = mBlocks.get(b);
		while (s > 0)
		{
			f(a.get(i++));
			if (i == mBlockSize)
			{
				i = 0;
				a = mBlocks.get(++b);
			}
			s--;
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
		b.add('\n[ ArrayedDeque size=$size');
		if (isEmpty())
		{
			b.add(" ]");
			return b.toString();
		}
		b.add("\n  front\n");
		var args = new Array<Dynamic>();
		var i = 0;
		var fmt = '  %${MathTools.numDigits(size)}d -> %s\n';
		if (mTailBlockIndex == 0)
		{
			for (j in mHead + 1...mTail)
			{
				args[0] = i++;
				args[1] = Std.string(mHeadBlock.get(j));
				b.add(Printf.format(fmt, args));
			}
		}
		else
		if (mTailBlockIndex == 1)
		{
			for (j in mHead + 1...mBlockSize)
			{
				args[0] = i++;
				args[1] = Std.string(mHeadBlock.get(j));
				b.add(Printf.format(fmt, args));
			}
			
			for (j in 0...mTail)
			{
				args[0] = i++;
				args[1] = Std.string(mTailBlock.get(j));
				b.add(Printf.format(fmt, args));
			}
		}
		else
		{
			for (j in mHead + 1...mBlockSize)
			{
				args[0] = i++;
				args[1] = Std.string(mHeadBlock.get(j));
				b.add(Printf.format(fmt, args));
			}
			
			for (j in 1...mTailBlockIndex)
			{
				var block = mBlocks.get(j);
				for (k in 0...mBlockSize)
				{
					args[0] = i++;
					args[1] = Std.string(block.get(k));
					b.add(Printf.format(fmt, args));
				}
			}
			
			for (j in 0...mTail)
			{
				args[0] = i++;
				args[1] = Std.string(mTailBlock.get(j));
				b.add(Printf.format(fmt, args));
			}
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
	function get_size():Int
	{
		return (mBlockSize - (mHead + 1)) + ((mTailBlockIndex - 1) << mBlockSizeShift) + mTail;
	}
	
	/**
		Destroys this object by explicitly nullifying all elements for GC'ing used resources.
		
		Improves GC efficiency/performance (optional).
	**/
	@:access(de.polygonal.ds.BlockList)
	public function free()
	{
		for (i in 0...mTailBlockIndex + 1)
			mBlocks.get(i).nullify();
		mBlocks.nullify();
		mBlocks = null;
		mHeadBlock = null;
		mHeadBlockNext = null;
		mTailBlock = null;
		mTailBlockPrev = null;
		if (mIterator != null)
		{
			mIterator.free();
			mIterator = null;
		}
	}
	
	/**
		Returns true if this deque contains `val`.
	**/
	public function contains(val:T):Bool
	{
		if (mTailBlockIndex == 0)
		{
			for (j in mHead + 1...mTail)
				if (mHeadBlock.get(j) == val) return true;
		}
		else
		if (mTailBlockIndex == 1)
		{
			for (j in mHead + 1...mBlockSize)
				if (mHeadBlock.get(j) == val) return true;
			for (j in 0...mTail)
				if (mTailBlock.get(j) == val) return true;
		}
		else
		{
			for (j in mHead + 1...mBlockSize)
				if (mHeadBlock.get(j) == val) return true;
			
			for (j in 1...mTailBlockIndex)
			{
				var block = mBlocks.get(j);
				for (k in 0...mBlockSize)
					if (block.get(k) == val) return true;
			}
			
			for (j in 0...mTail)
				if (mTailBlock.get(j) == val) return true;
		}
		return false;
	}
	
	/**
		Removes and nullifies all occurrences of `val`.
		@return true if at least one occurrence of `val` was removed.
	**/
	public function remove(val:T):Bool
	{
		var found = false;
		while (true)
		{
			var i =-1;
			var b = 0;
			
			if (mTailBlockIndex == 0)
			{
				for (j in mHead + 1...mTail)
				{
					if (mHeadBlock.get(j) == val)
					{
						i = j;
						break;
					}
				}
			}
			else
			if (mTailBlockIndex == 1)
			{
				for (j in mHead + 1...mBlockSize)
				{
					if (mHeadBlock.get(j) == val)
					{
						i = j;
						break;
					}
				}
				
				if (i == -1)
				{
					for (j in 0...mTail)
					{
						if (mTailBlock.get(j) == val)
						{
							i = j;
							b = 1;
							break;
						}
					}
				}
			}
			else
			{
				for (j in mHead + 1...mBlockSize)
				{
					if (mHeadBlock.get(j) == val)
					{
						i = j;
						break;
					}
				}
				
				if (i == -1)
				{
					for (j in 1...mTailBlockIndex)
					{
						var block = mBlocks.get(j);
						for (k in 0...mBlockSize)
						{
							if (block.get(k) == val)
							{
								i = k;
								b = j;
								break;
							}
						}
						if (i != -1) break;
					}
				}
				
				if (i == -1)
				{
					for (j in 0...mTail)
					{
						if (mTailBlock.get(j) == val)
						{
							i = j;
							b = mTailBlockIndex;
							break;
						}
					}
				}
			}
			
			if (i == -1)
			{
				found = true;
				break;
			}
			
			if (b == 0)
			{
				if (i == mHead + 1)
					mHead++;
				else
				if (i == mTail - 1)
					mTail--;
				else
				{
					var block = mBlocks.get(b);
					while (i > mHead + 1)
					{
						block.set(i, block.get(i - 1));
						i--;
					}
					mHead++;
				}
			}
			else
			if (b == mTailBlockIndex)
			{
				while (i < mTail)
				{
					mTailBlock.set(i, mTailBlock.get(i + 1));
					i++;
				}
				mTail--;
			}
			else
			{
				if (b <= mTailBlockIndex - b)
				{
					var block = mBlocks.get(b);
					while (i > 0)
					{
						block.set(i, block.get(i - 1));
						i--;
					}
					
					while (b > 1)
					{
						var prevBlock = mBlocks.get(b - 1);
						block.set(0, prevBlock.get(mBlockSizeMinusOne));
						block = prevBlock;
						
						i = mBlockSizeMinusOne;
						while (i > 0)
						{
							block.set(i, block.get(i - 1));
							i--;
						}
						
						b--;
					}
					
					block.set(0, mHeadBlock.get(mBlockSizeMinusOne));
					i = mBlockSizeMinusOne;
					var j = mHead + 1;
					while (i > j)
					{
						mHeadBlock.set(i, mHeadBlock.get(i - 1));
						i--;
					}
					if (++mHead == mBlockSize) shiftBlock();
				}
				else
				{
					var block = mBlocks.get(b);
					
					while (i < mBlockSize - 1)
					{
						block.set(i, block.get(i + 1));
						i++;
					}
					
					var j = mTailBlockIndex - 1;
					while (b < j)
					{
						var nextBlock = mBlocks.get(b + 1);
						block.set(mBlockSizeMinusOne, nextBlock.get(0));
						block = nextBlock;
						
						i = 0;
						while (i < mBlockSizeMinusOne)
						{
							block.set(i, block.get(i + 1));
							i++;
						}
						
						b++;
					}
					
					block.set(mBlockSizeMinusOne, mTailBlock.get(0));
					i = 0;
					j = mTail - 1;
					while (i < j)
					{
						mTailBlock.set(i, mTailBlock.get(i + 1));
						i++;
					}
					if (--mTail < 0) popBlock();
				}
			}
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
			for (i in 0...mTailBlockIndex + 1)
			{
				var block = mBlocks.get(i);
				for (j in 0...mBlockSize) block.set(j, cast null);
				mBlocks.set(i, null);
			}
			
			mNumBlocks = 0;
			mBlocks.nullify();
			mBlocks = NativeArrayTools.alloc(mMaxBlocks);
			mBlocks.set(mNumBlocks++, NativeArrayTools.alloc(mBlockSize));
			mHeadBlock = mBlocks.get(0);
			mBlockPool.nullify();
			mPoolSize = 0;
		}
		
		mHead = 0;
		mTail = 1;
		mTailBlockIndex = 0;
		mTailBlock = mHeadBlock;
		mHeadBlockNext = null;
		mTailBlockPrev = null;
	}
	
	/**
		Returns a new *ArrayedDequeIterator* object to iterate over all elements contained in this deque.
		
		Preserves the natural order of a deque.
		
		@see http://haxe.org/ref/iterators
	**/
	public function iterator():Itr<T>
	{
		if (reuseIterator)
		{
			if (mIterator == null)
				mIterator = new ArrayedDequeIterator<T>(this);
			else
				mIterator.reset();
			return mIterator;
		}
		else
			return new ArrayedDequeIterator<T>(this);
	}
	
	/**
		Returns true only if `this.size` is 0.
	**/
	public inline function isEmpty():Bool
	{
		if (mTailBlockIndex == 0)
			return (mTail - mHead) == 1;
		else
			return mHead == mBlockSizeMinusOne && mTail == 0;
	}
	
	/**
		Returns an array containing all elements in this deque in the natural order.
	**/
	public function toArray():Array<T>
	{
		if (isEmpty()) return [];
		
		var out = ArrayTools.alloc(size);
		var i = 0;
		if (mTailBlockIndex == 0)
		{
			for (j in mHead + 1...mTail) out[i++] = mHeadBlock.get(j);
		}
		else
		if (mTailBlockIndex == 1)
		{
			for (j in mHead + 1...mBlockSize) out[i++] = mHeadBlock.get(j);
			for (j in 0...mTail) out[i++] = mTailBlock.get(j);
		}
		else
		{
			for (j in mHead + 1...mBlockSize) out[i++] = mHeadBlock.get(j);
			for (j in 1...mTailBlockIndex)
			{
				var block = mBlocks.get(j);
				for (k in 0...mBlockSize) out[i++] = block.get(k);
			}
			for (j in 0...mTail) out[i++] = mTailBlock.get(j);
		}
		return out;
	}
	
	/**
		Creates and returns a shallow copy (structure only - default) or deep copy (structure & elements) of this deque.
		
		If `byRef` is true, primitive elements are copied by value whereas objects are copied by reference.
		
		If `byRef` is false, the `copier` function is used for copying elements. If omitted, `clone()` is called on each element assuming all elements implement `Cloneable`.
	**/
	public function clone(byRef:Bool = true, copier:T->T = null):Collection<T>
	{
		var c = new ArrayedDeque<T>(mBlockSize, 0);
		
		c.mHead = mHead;
		c.mTail = mTail;
		c.mTailBlockIndex = mTailBlockIndex;
		
		c.mNumBlocks = 0;
		c.mMaxBlocks = mTailBlockIndex + 1;
		c.mBlocks = NativeArrayTools.alloc(mTailBlockIndex + 1);
		for (i in 0...mTailBlockIndex + 1)
			c.mBlocks.set(c.mNumBlocks++, NativeArrayTools.alloc(mBlockSize));
		c.mHeadBlock = c.mBlocks.get(0);
		c.mTailBlock = c.mBlocks.get(mTailBlockIndex);
		if (mTailBlockIndex > 0)
		{
			c.mHeadBlockNext = c.mBlocks.get(1);
			c.mTailBlockPrev = c.mBlocks.get(mTailBlockIndex - 1);
		}
		
		if (byRef)
		{
			inline function copy(src:NativeArray<T>, dst:NativeArray<T>, min:Int, max:Int)
				src.blit(min, dst, min, max - min);
			
			if (mTailBlockIndex == 0)
				copy(mHeadBlock, c.mHeadBlock, mHead + 1, mTail);
			else
			if (mTailBlockIndex == 1)
			{
				copy(mHeadBlock, c.mHeadBlock, mHead + 1, mBlockSize);
				copy(mTailBlock, c.mTailBlock, 0, mTail);
			}
			else
			{
				copy(mHeadBlock, c.mHeadBlock, mHead + 1, mBlockSize);
				for (j in 1...mTailBlockIndex) copy(mBlocks.get(j), c.mBlocks.get(j), 0, mBlockSize);
				copy(mTailBlock, c.mTailBlock, 0, mTail);
			}
		}
		else
		{
			if (copier != null)
			{
				inline function copy(f:T->T, src:NativeArray<T>, dst:NativeArray<T>, min:Int, max:Int)
					for (j in min...max) dst.set(j, f(src.get(j)));
				
				if (mTailBlockIndex == 0)
					copy(copier, mHeadBlock, c.mHeadBlock, mHead + 1, mTail);
				else
				if (mTailBlockIndex == 1)
				{
					copy(copier, mHeadBlock, c.mHeadBlock, mHead + 1, mBlockSize);
					copy(copier, mTailBlock, c.mTailBlock, 0, mTail);
				}
				else
				{
					copy(copier, mHeadBlock, c.mHeadBlock, mHead + 1, mBlockSize);
					for (j in 1...mTailBlockIndex) copy(copier, mBlocks.get(j), c.mBlocks.get(j), 0, mBlockSize);
					copy(copier, mTailBlock, c.mTailBlock, 0, mTail);
				}
			}
			else
			{
				var e:Cloneable<Dynamic>;
				
				inline function copy(src:NativeArray<T>, dst:NativeArray<T>, min:Int, max:Int)
					for (j in min...max)
					{
						e = cast(src.get(j), Cloneable<Dynamic>);
						dst.set(j, e.clone());
					}
				
				if (mTailBlockIndex == 0)
					copy(mHeadBlock, c.mHeadBlock, mHead + 1, mTail);
				else
				if (mTailBlockIndex == 1)
				{
					copy(mHeadBlock, c.mHeadBlock, mHead + 1, mBlockSize);
					copy(mTailBlock, c.mTailBlock, 0, mTail);
				}
				else
				{
					copy(mHeadBlock, c.mHeadBlock, mHead + 1, mBlockSize);
					for (j in 1...mTailBlockIndex) copy(mBlocks.get(j), c.mBlocks.get(j), 0, mBlockSize);
					copy(mTailBlock, c.mTailBlock, 0, mTail);
				}
			}
		}
		return c;
	}
	
	function shiftBlock()
	{
		{
			putBlock(mBlocks.get(0));
			mBlocks.blit(1, mBlocks, 0, --mNumBlocks);
		}
		
		mHead = 0;
		mHeadBlock = mHeadBlockNext;
		mTailBlock = mBlocks.get(--mTailBlockIndex);
		if (mTailBlockIndex > 0)
		{
			mHeadBlockNext = mBlocks.get(1);
			mTailBlockPrev = mBlocks.get(mTailBlockIndex - 1);
		}
		else
		{
			mHeadBlockNext = null;
			mTailBlockPrev = null;
		}
	}
	
	function unshiftBlock()
	{
		{
			if (mNumBlocks == mMaxBlocks)
			{
				mMaxBlocks *= 2;
				var t = NativeArrayTools.alloc(mMaxBlocks);
				mBlocks.blit(0, t, 1, mNumBlocks++);
				mBlocks = t;
			}
			else
				mBlocks.blit(0, mBlocks, 1, mNumBlocks++);
			mBlocks.set(0, getBlock());
		}
		
		mHead = mBlockSizeMinusOne;
		mHeadBlock = mBlocks.get(0);
		mHeadBlockNext = mBlocks.get(1);
		mTailBlockPrev = mBlocks.get(mTailBlockIndex++);
		mTailBlock = mBlocks.get(mTailBlockIndex);
	}
	
	function popBlock()
	{
		{
			putBlock(mBlocks.get(--mNumBlocks));
		}
		
		mTailBlockIndex--;
		mTailBlock = mTailBlockPrev;
		mTail = mBlockSizeMinusOne;
		if (mTailBlockIndex > 0)
			mTailBlockPrev = mBlocks.get(mTailBlockIndex - 1);
		else
		{
			mHeadBlockNext = null;
			mTailBlockPrev = null;
		}
	}
	
	function pushBlock()
	{
		{
			if (mNumBlocks == mMaxBlocks)
			{
				mMaxBlocks *= 2;
				var t = NativeArrayTools.alloc(mMaxBlocks);
				mBlocks.blit(0, t, 0, mNumBlocks);
				mBlocks = t;
			}
			mBlocks.set(mNumBlocks++, getBlock());
		}
		
		mTail = 0;
		mTailBlockPrev = mTailBlock;
		mTailBlock = mBlocks.get(++mTailBlockIndex);
		if (mTailBlockIndex == 1)
			mHeadBlockNext = mBlocks.get(1);
	}
	
	function getBlock():NativeArray<T>
	{
		if (mPoolSize > 0)
			return mBlockPool.get(--mPoolSize);
		else
			return NativeArrayTools.alloc(mBlockSize);
	}
	
	function putBlock(x:NativeArray<T>)
	{
		if (mPoolSize < mPoolCapacity)
			mBlockPool.set(mPoolSize++, x);
	}
}

#if generic
@:generic
#end
@:access(de.polygonal.ds.ArrayedDeque)
@:dox(hide)
class ArrayedDequeIterator<T> implements de.polygonal.ds.Itr<T>
{
	var mObject:ArrayedDeque<T>;
	var mBlocks:NativeArray<NativeArray<T>>;
	var mBlock:NativeArray<T>;
	var mI:Int;
	var mS:Int;
	var mB:Int;
	var mBlockSize:Int;
	
	public function new(x:ArrayedDeque<T>)
	{
		mObject = x;
		reset();
	}
	
	public function free()
	{
		mObject = null;
		mBlocks = null;
		mBlock = null;
	}
	
	public function reset():Itr<T>
	{
		mBlockSize = mObject.mBlockSize;
		mBlocks = mObject.mBlocks;
		mI = mObject.mHead + 1;
		mB = mI >> mObject.mBlockSizeShift;
		mS = mObject.size;
		mBlock = mBlocks.get(mB);
		mI -= mB << mObject.mBlockSizeShift;
		return this;
	}
	
	public inline function hasNext():Bool
	{
		return mS > 0;
	}
	
	public inline function next():T
	{
		var x = mBlock.get(mI++);
		if (mI == mBlockSize)
		{
			mI = 0;
			mBlock = mBlocks.get(++mB);
		}
		mS--;
		return x;
	}
	
	public function remove()
	{
		throw "unsupported operation";
	}
}