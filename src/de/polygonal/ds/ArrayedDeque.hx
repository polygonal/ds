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

private typedef ArrayedDequeFriend<T> =
{
	private var _head:Int;
	private var _blockSize:Int;
	private var _blockSizeShift:Int;
	private var _blocks:Array<Array<T>>;
}

/**
 * <p>A deque ("double-ended queue") is a linear list for which all insertions and deletions (and usually all accesses) are made at ends of the list.</p>
 * <p><o>Worst-case running time in Big O notation</o></p>
 */
class ArrayedDeque<T> implements Deque<T>
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
	
	var _blockSize:Int;
	var _blockSizeMinusOne:Int;
	var _blockSizeShift:Int;
	var _head:Int;
	var _tail:Int;
	var _tailBlockIndex:Int;
	var _poolSize:Int;
	var _poolCapacity:Int;
	
	var _blocks:Array<Array<T>>;
	var _headBlock:Array<T>;
	var _tailBlock:Array<T>;
	var _headBlockNext:Array<T>;
	var _tailBlockPrev:Array<T>;
	var _blockPool:Array<Array<T>>;
	var _iterator:ArrayedDequeIterator<T>;
	
	/**
	 * @param blockSize a block represents a contiguous piece of memory; whenever the deque runs out of space an additional block with a capacity of <code>blockSize</code> elements is allocated and added to the existing blocks.<br/>
	 * The parameter affects the performance-memory trade-off: a large <code>blockSize</code> improves performances but wastes memory if the utilization is low; a small <code>blockSize</code> uses memory more efficiently but is slower due to frequent allocation of blocks.<br/>
	 * The default value is 64; the minimum value is 4.<br/>
	 * <warn><code>blockSize</code> has to be a power of two.</warn>
	 * @param blockPoolSize the total number of blocks to reuse when blocks are removed or relocated (from front to back or vice-versa). This improves performances but uses more memory.<br/>
	 * The default value is 4; a value of 0 disables block pooling.
	 * @param maxSize the maximum allowed size of this deque.<br/>
	 * The default value of -1 indicates that there is no upper limit.
	 * @throws de.polygonal.ds.error.AssertError invalid <code>blockSize</code> (debug only).
	 */
	public function new(blockSize = 64, blockPoolCapacity = 4, maxSize = -1)
	{
		#if debug
		assert(M.isPow2(blockSize), "blockSize is not a power of 2");
		assert(blockSize >= 4, "blockSize is too small");
		#end
		
		#if debug
		this.maxSize = (maxSize == -1) ? M.INT32_MAX : maxSize;
		#else
		this.maxSize = -1;
		#end
		
		_blockSize         = blockSize;
		_blockSizeMinusOne = blockSize - 1;
		_blockSizeShift    = Bits.ntz(blockSize);
		_head              = 0;
		_tail              = 1;
		_tailBlockIndex    = 0;
		_poolSize          = 0;
		_poolCapacity      = blockPoolCapacity;
		_blocks            = new Array();
		_blocks[0]         = ArrayUtil.alloc(blockSize);
		_headBlock         = _blocks[0];
		_tailBlock         = _headBlock;
		_headBlockNext     = null;
		_tailBlockPrev     = null;
		_blockPool         = new Array<Array<T>>();
		_iterator          = null;
		key                = HashKey.next();
		reuseIterator      = false;
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
		
		return (_head == _blockSizeMinusOne) ? _headBlockNext[0] : _headBlock[_head + 1];
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
		
		_headBlock[_head--] = x;
		if (_head == -1) _unshiftBlock();
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
		
		if (_head == _blockSizeMinusOne)
		{
			_shiftBlock();
			return _headBlock[0];
		}
		else
			return _headBlock[++_head];
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
		
		return (_tail == 0) ? (_tailBlockPrev[_blockSizeMinusOne]) : _tailBlock[_tail - 1];
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
		
		_tailBlock[_tail++] = x;
		if (_tail == _blockSize)
			_pushBlock();
	}
	
	/**
	 * Deletes the element at the end of the deque.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError deque is empty (debug only).
	 */
	public function popBack():T
	{
		#if debug
		assert(size() > 0, "deque is empty");
		#end
		
		if (_tail == 0)
		{
			_popBlock();
			return _tailBlock[_blockSizeMinusOne];
		}
		else
			return _tailBlock[--_tail];
	}
	
	/**
	 * Returns the element at index <code>i</code> relative to the front of this deque.<br/>
	 * The front element is at index [0], the back element is at index <b>&#091;<em>size()</em> - 1&#093;</b>.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError deque is empty (debug only).
	 * @throws de.polygonal.ds.error.AssertError index out of range (debug only).
	 */
	public function getFront(i:Int):T
	{
		#if debug
		assert(i < size(), 'index out of range ($i)');
		#end
		
		var c = (_head + 1) + i;
		var b = (c >> _blockSizeShift);
		return _blocks[b][c - (b << _blockSizeShift)];
	}
	
	/**
	 * Returns the index of the first occurence of the element <code>x</code> or -1 if <code>x</code> does not exist.
	 * The front element is at index [0], the back element is at index &#091;<em>size()</em> - 1&#093;.
	 * <o>n</o>
	 */
	public function indexOfFront(x:T):Int
	{
		for (i in 0...size())
		{
			var c = (_head + 1) + i;
			var b = (c >> _blockSizeShift);
			
			if (_blocks[b][c - (b << _blockSizeShift)] == x)
				return i;
		}
		return -1;
	}
	
	/**
	 * Returns the element at index <code>i</code> relative to the back of this deque.<br/>
	 * The back element is at index [0], the front element is at index &#091;<em>size()</em> - 1&#093;.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError deque is empty (debug only).
	 * @throws de.polygonal.ds.error.AssertError index out of range (debug only).
	 */
	public function getBack(i:Int):T
	{
		#if debug
		assert(i < size(), 'index out of range ($i)');
		#end
		
		var c = _tail - 1 - i;
		var b = c >> _blockSizeShift;
		return _blocks[_tailBlockIndex + b][M.abs(b << _blockSizeShift) + c];
	}
	
	/**
	 * Returns the index of the first occurence of the element <code>x</code> or -1 if <code>x</code> does not exist.
	 * The back element is at index [0], the front element is at index &#091;<em>size()</em> - 1&#093;.
	 * <o>n</o>
	 */
	public function indexOfBack(x:T):Int
	{
		for (i in 0...size())
		{
			var c = _tail - 1 - i;
			var b = c >> _blockSizeShift;
			if (_blocks[_tailBlockIndex + b][M.abs(b << _blockSizeShift) + c] == x)
				return i;
		}
		return -1;
	}
	
	
	/**
	 * Removes all superfluous blocks and overwrites elements stored in empty locations with null.
	 * <o>n</o>
	 */
	public function pack()
	{
		for (i in 0..._head + 1) _headBlock[i] = null;
		for (i in _tail..._blockSize) _tailBlock[i] = null;
		_poolSize = 0;
		_blockPool = new Array<Array<T>>();
	}
	
	/**
	 * Replaces up to <code>n</code> existing elements with objects of type <code>C</code>.<br/>
	 * If size() &lt; <code>n</code>, additional elements are added to the back of this deque.
	 * <o>n</o>
	 * @param C the class to instantiate for each element.
	 * @param args passes additional constructor arguments to the class <code>C</code>.
	 * @param n the number of elements to replace. If 0, <code>n</code> is set to <em>size()</em>.
	 * @throws de.polygonal.ds.error.AssertError <code>n</code> &gt; <em>maxSize</em> (debug only).
	 */
	public function assign(C:Class<T>, args:Array<Dynamic> = null, n = 0)
	{
		if (n == 0) n = size();
		if (n == 0) return;
		if (args == null) args = [];
		if (n >= size())
		{
			#if debug
			if (maxSize != -1)
				assert(n < maxSize, 'n > max size ($maxSize)');
			#end
			
			var i = _head + 1;
			while (i < _blockSize)
				_headBlock[i++] = Type.createInstance(C, args);
			
			var fullBlocks = _tailBlockIndex - 1;
			for (i in 1...1 + fullBlocks)
			{
				var block = _blocks[i];
				for (j in 0..._blockSize)
					block[j] = Type.createInstance(C, args);
			}
			
			i = 0;
			while (i < _tail)
				_tailBlock[i++] = Type.createInstance(C, args);
			
			for (i in 0...n - size())
			{
				_tailBlock[_tail++] = Type.createInstance(C, args);
				if (_tail == _blockSize)
					_pushBlock();
			}
		}
		else
		{
			var c = M.min(n, _blockSize - (_head + 1));
			var i = _head + 1;
			for (j in i...i + c)
				_headBlock[j] = Type.createInstance(C, args);
			n -= c;
			
			if (n == 0) return;
			
			var b = 1;
			c = n >> _blockSizeShift;
			for (i in 0...n >> _blockSizeShift)
			{
				var block = _blocks[i + 1];
				for (j in 0..._blockSize)
					block[j] = Type.createInstance(C, args);
				b++;
			}
			n -= c << _blockSizeShift;
			
			var block = _blocks[b];
			for (i in 0...n) block[i] = Type.createInstance(C, args);
		}
	}
	
	/**
	 * Replaces up to <code>n</code> existing elements with the instance of <code>x</code>.<br/>
	 * If size() &lt; <code>n</code>, additional elements are added to the back of this deque.
	 * <o>n</o>
	 * @param n the number of elements to replace. If 0, <code>n</code> is set to <em>size()</em>.
	 */
	public function fill(x:T, n = 0):ArrayedDeque<T>
	{
		if (n == 0) n = size();
		if (n == 0) return this;
		if (n >= size())
		{
			#if debug
			if (maxSize != -1)
				assert(n < maxSize, 'n > max size ($maxSize)');
			#end
			
			var i = _head + 1;
			while (i < _blockSize)
				_headBlock[i++] = x;
			
			var fullBlocks = _tailBlockIndex - 1;
			for (i in 1...1 + fullBlocks)
			{
				var block = _blocks[i];
				for (j in 0..._blockSize)
					block[j] = x;
			}
			
			i = 0;
			while (i < _tail)
				_tailBlock[i++] = x;
			
			for (i in 0...n - size())
			{
				_tailBlock[_tail++] = x;
				if (_tail == _blockSize)
					_pushBlock();
			}
		}
		else
		{
			var c = M.min(n, _blockSize - (_head + 1));
			var i = _head + 1;
			for (j in i...i + c)
				_headBlock[j] = x;
			n -= c;
			
			if (n == 0) return this;
			
			var b = 1;
			c = n >> _blockSizeShift;
			for (i in 0...n >> _blockSizeShift)
			{
				var block = _blocks[i + 1];
				for (j in 0..._blockSize)
					block[j] = x;
				b++;
			}
			n -= c << _blockSizeShift;
			
			var block = _blocks[b];
			for (i in 0...n) block[i] = x;
		}
		
		return this;
	}
	
	/**
	 * Returns a string representing the current object.<br/>
	 * Example:<br/>
	 * <pre class="prettyprint">
	 * var deque = new de.polygonal.ds.ArrayedDeque&lt;Int&gt;();
	 * for (i in 0...4) {
	 *     deque.pushFront(i);
	 * }
	 * trace(deque);</pre>
	 * <pre class="console">
	 * { ArrayedDeque size: 4 }
	 * [ front
	 *   0 -> 3
	 *   1 -> 2
	 *   2 -> 1
	 *   3 -> 0
	 * ]</pre>
	 */
	public function toString():String
	{
		var s = '{ ArrayedDeque size: ${size()} }';
		if (isEmpty()) return s;
		s += "\n[ front\n";
		
		var i = 0;
		if (_tailBlockIndex == 0)
		{
			for (j in _head + 1..._tail)
				s += Printf.format("  %4d -> %s\n", [i++, Std.string(_headBlock[j])]);
		}
		else
		if (_tailBlockIndex == 1)
		{
			for (j in _head + 1..._blockSize)
				s += Printf.format("  %4d -> %s\n", [i++, Std.string(_headBlock[j])]);
			for (j in 0..._tail)
				s += Printf.format("  %4d -> %s\n", [i++, Std.string(_tailBlock[j])]);
		}
		else
		{
			for (j in _head + 1..._blockSize)
				s += Printf.format("  %4d -> %s\n", [i++, Std.string(_headBlock[j])]);
			
			for (j in 1..._tailBlockIndex)
			{
				var block = _blocks[j];
				for (k in 0..._blockSize)
					s += Printf.format("  %4d -> %s\n", [i++, Std.string(block[k])]);
			}
			
			for (j in 0..._tail)
				s += Printf.format("  %4d -> %s\n", [i++, Std.string(_tailBlock[j])]);
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
		for (i in 0..._tailBlockIndex + 1)
		{
			var block = _blocks[i];
			for (j in 0..._blockSize) block[j] = null;
			_blocks[i] = null;
		}
		_blocks        = null;
		_headBlock     = null;
		_headBlockNext = null;
		_tailBlock     = null;
		_tailBlockPrev = null;
		_iterator      = null;
	}
	
	/**
	 * Returns true if this deque contains the element <code>x</code>. 
	 * <o>n</o>
	 */
	public function contains(x:T):Bool
	{
		var i = 0;
		if (_tailBlockIndex == 0)
		{
			for (j in _head + 1..._tail)
				if (_headBlock[j] == x) return true;
		}
		else
		if (_tailBlockIndex == 1)
		{
			for (j in _head + 1..._blockSize)
				if (_headBlock[j] == x) return true;
			for (j in 0..._tail)
				if (_tailBlock[j] == x) return true;
		}
		else
		{
			for (j in _head + 1..._blockSize)
				if (_headBlock[j] == x) return true;
			
			for (j in 1..._tailBlockIndex)
			{
				var block = _blocks[j];
				for (k in 0..._blockSize)
					if (block[k] == x) return true;
			}
			
			for (j in 0..._tail)
				if (_tailBlock[j] == x) return true;
		}
		
		return false;
	}
	
	/**
	 * Removes and nullifies all occurrences of the element <code>x</code>.
	 * <o>n</o>
	 * @return true if at least one occurrence of <code>x</code> was removed.
	 */
	public function remove(x:T):Bool
	{
		var found = false;
		while (true)
		{
			var i =-1;
			var b = 0;
			
			if (_tailBlockIndex == 0)
			{
				for (j in _head + 1..._tail)
				{
					if (_headBlock[j] == x)
					{
						i = j;
						break;
					}
				}
			}
			else
			if (_tailBlockIndex == 1)
			{
				for (j in _head + 1..._blockSize)
				{
					if (_headBlock[j] == x)
					{
						i = j;
						break;
					}
				}
				
				if (i == -1)
				{
					for (j in 0..._tail)
					{
						if (_tailBlock[j] == x)
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
				for (j in _head + 1..._blockSize)
				{
					if (_headBlock[j] == x)
					{
						i = j;
						break;
					}
				}
				
				if (i == -1)
				{
					for (j in 1..._tailBlockIndex)
					{
						var block = _blocks[j];
						for (k in 0..._blockSize)
						{
							if (block[k] == x)
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
					for (j in 0..._tail)
					{
						if (_tailBlock[j] == x)
						{
							i = j;
							b = _tailBlockIndex;
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
				if (i == _head + 1)
					_head++;
				else
				if (i == _tail - 1)
					_tail--;
				else
				{
					var block = _blocks[b];
					while (i > _head + 1)
					{
						block[i] = block[i - 1];
						i--;
					}
					_head++;
				}
			}
			else
			if (b == _tailBlockIndex)
			{
				while (i < _tail)
				{
					_tailBlock[i] = _tailBlock[i + 1];
					i++;
				}
				_tail--;
			}
			else
			{
				if (b <= _tailBlockIndex - b)
				{
					var block = _blocks[b];
					while (i > 0)
					{
						block[i] = block[i - 1];
						i--;
					}
					
					while (b > 1)
					{
						var prevBlock = _blocks[b - 1];
						block[0] = prevBlock[_blockSizeMinusOne];
						block = prevBlock;
						
						i = _blockSizeMinusOne;
						while (i > 0)
						{
							block[i] = block[i - 1];
							i--;
						}
						
						b--;
					}
					
					block[0] = _headBlock[_blockSizeMinusOne];
					i = _blockSizeMinusOne;
					var j = _head + 1;
					while (i > j)
					{
						_headBlock[i] = _headBlock[i - 1];
						i--;
					}
					if (++_head == _blockSize) _shiftBlock();
				}
				else
				{
					var block = _blocks[b];
					
					while (i < _blockSize - 1)
					{
						block[i] = block[i + 1];
						i++;
					}
					
					var j = _tailBlockIndex - 1;
					while (b < j)
					{
						var nextBlock = _blocks[b + 1];
						block[_blockSizeMinusOne] = nextBlock[0];
						block = nextBlock;
						
						i = 0;
						while (i < _blockSizeMinusOne)
						{
							block[i] = block[i + 1];
							i++;
						}
						
						b++;
					}
					
					block[_blockSizeMinusOne] = _tailBlock[0];
					i = 0;
					var j = _tail - 1;
					while (i < j)
					{
						_tailBlock[i] = _tailBlock[i + 1];
						i++;
					}
					if (--_tail < 0) _popBlock();
				}
			}
		}
		
		return found;
	}
	
	/**
	 * Removes all elements.
	 * <o>1 or n if <code>purge</code> is true</o>
	 * @param purge if true, elements are nullified upon removal. This also removes all superfluous blocks and clears the pool.
	 */
	public function clear(purge = false)
	{
		if (purge)
		{
			for (i in 0..._tailBlockIndex + 1)
			{
				var block = _blocks[i];
				for (j in 0..._blockSize) block[j] = null;
				_blocks[i] = null;
			}
			_blocks    = new Array();
			_blocks[0] = ArrayUtil.alloc(_blockSize);
			_headBlock = _blocks[0];
			
			for (i in 0..._blockPool.length)
				_blockPool[i] = null;
			_blockPool = new Array<Array<T>>();
			_poolSize = 0;
		}
		
		_head           = 0;
		_tail           = 1;
		_tailBlockIndex = 0;
		_tailBlock      = _headBlock;
		_headBlockNext  = null;
		_tailBlockPrev  = null;
	}
	
	/**
	 * Returns a new <em>ArrayedDequeIterator</em> object to iterate over all elements contained in this deque.<br/>
	 * Preserves the natural order of a deque.
	 * @see <a href="http://haxe.org/ref/iterators" target="_blank">http://haxe.org/ref/iterators</a>
	 */
	public function iterator():Itr<T>
	{
		if (reuseIterator)
		{
			if (_iterator == null)
				_iterator = new ArrayedDequeIterator<T>(this);
			else
				_iterator.reset();
			return _iterator;
		}
		else
			return new ArrayedDequeIterator<T>(this);
	}
	
	/**
	 * Returns true if this deque is empty.
	 * <o>1</o>
	 */
	inline public function isEmpty():Bool
	{
		if (_tailBlockIndex == 0)
			return (_tail - _head) == 1;
		else
			return _head == _blockSizeMinusOne && _tail == 0;
	}
	
	/**
	 * The total number of elements. 
	 * <o>1</o>
	 */
	inline public function size():Int
	{
		return (_blockSize - (_head + 1)) + ((_tailBlockIndex - 1) << _blockSizeShift) + _tail;
	}
	
	/**
	 * Returns an array containing all elements in this deque in the natural order.
	 */
	public function toArray():Array<T>
	{
		var a:Array<T> = ArrayUtil.alloc(size());
		var i = 0;
		if (_tailBlockIndex == 0)
		{
			for (j in _head + 1..._tail) a[i++] = _headBlock[j];
		}
		else
		if (_tailBlockIndex == 1)
		{
			for (j in _head + 1..._blockSize) a[i++] = _headBlock[j];
			for (j in 0..._tail) a[i++] = _tailBlock[j];
		}
		else
		{
			for (j in _head + 1..._blockSize) a[i++] = _headBlock[j];
			for (j in 1..._tailBlockIndex)
			{
				var block = _blocks[j];
				for (k in 0..._blockSize) a[i++] = block[k];
			}
			for (j in 0..._tail) a[i++] = _tailBlock[j];
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
		if (_tailBlockIndex == 0)
		{
			for (j in _head + 1..._tail) a[i++] = _headBlock[j];
		}
		else
		if (_tailBlockIndex == 1)
		{
			for (j in _head + 1..._blockSize) a[i++] = _headBlock[j];
			for (j in 0..._tail) a[i++] = _tailBlock[j];
		}
		else
		{
			for (j in _head + 1..._blockSize) a[i++] = _headBlock[j];
			for (j in 1..._tailBlockIndex)
			{
				var block = _blocks[j];
				for (k in 0..._blockSize) a[i++] = block[k];
			}
			for (j in 0..._tail) a[i++] = _tailBlock[j];
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
		var copy = Type.createEmptyInstance(ArrayedDeque);
		copy._blockSize         = _blockSize;
		copy._blockSizeMinusOne = _blockSizeMinusOne;
		copy._head              = _head;
		copy._tail              = _tail;
		copy._tailBlockIndex    = _tailBlockIndex;
		copy._blockSizeShift    = _blockSizeShift;
		copy._poolSize          = 0;
		copy._poolCapacity      = 0;
		copy.key                = HashKey.next();
		copy.maxSize            = M.INT32_MAX;
		
		var blocks = copy._blocks = ArrayUtil.alloc(_tailBlockIndex + 1);
		for (i in 0..._tailBlockIndex + 1)
			blocks[i] = ArrayUtil.alloc(_blockSize);
		copy._headBlock = blocks[0];
		copy._tailBlock = blocks[_tailBlockIndex];
		if (_tailBlockIndex > 0)
		{
			copy._headBlockNext = blocks[1];
			copy._tailBlockPrev = blocks[_tailBlockIndex - 1];
		}
		
		if (assign)
		{
			if (_tailBlockIndex == 0)
				_copy(_headBlock, copy._headBlock, _head + 1, _tail);
			else
			if (_tailBlockIndex == 1)
			{
				_copy(_headBlock, copy._headBlock, _head + 1, _blockSize);
				_copy(_tailBlock, copy._tailBlock, 0, _tail);
			}
			else
			{
				_copy(_headBlock, copy._headBlock, _head + 1, _blockSize);
				for (j in 1..._tailBlockIndex)
					_copy(_blocks[j], blocks[j], 0, _blockSize);
				_copy(_tailBlock, copy._tailBlock, 0, _tail);
			}
		}
		else
		{
			if (copier != null)
			{
				if (_tailBlockIndex == 0)
					_copyCopier(copier, _headBlock, copy._headBlock, _head + 1, _tail);
				else
				if (_tailBlockIndex == 1)
				{
					_copyCopier(copier,_headBlock, copy._headBlock, _head + 1, _blockSize);
					_copyCopier(copier,_tailBlock, copy._tailBlock, 0, _tail);
				}
				else
				{
					_copyCopier(copier,_headBlock, copy._headBlock, _head + 1, _blockSize);
					for (j in 1..._tailBlockIndex)
						_copyCopier(copier,_blocks[j], blocks[j], 0, _blockSize);
					_copyCopier(copier, _tailBlock, copy._tailBlock, 0, _tail);
				}
			}
			else
			{
				if (_tailBlockIndex == 0)
					_copyCloneable(_headBlock, copy._headBlock, _head + 1, _tail);
				else
				if (_tailBlockIndex == 1)
				{
					_copyCloneable(_headBlock, copy._headBlock, _head + 1, _blockSize);
					_copyCloneable(_tailBlock, copy._tailBlock, 0, _tail);
				}
				else
				{
					_copyCloneable(_headBlock, copy._headBlock, _head + 1, _blockSize);
					for (j in 1..._tailBlockIndex)
						_copyCloneable(_blocks[j], blocks[j], 0, _blockSize);
					_copyCloneable(_tailBlock, copy._tailBlock, 0, _tail);
				}
			}
		}
		
		return copy;
	}
	
	function _shiftBlock()
	{
		_putBlock(_blocks[0]);
		_blocks.shift();
		_head      = 0;
		_headBlock = _headBlockNext;
		_tailBlock = _blocks[--_tailBlockIndex];
		if (_tailBlockIndex > 0)
		{
			_headBlockNext = _blocks[1];
			_tailBlockPrev = _blocks[_tailBlockIndex - 1];
		}
		else
		{
			_headBlockNext = null;
			_tailBlockPrev = null;
		}
	}
	
	function _unshiftBlock()
	{
		_blocks.unshift(_getBlock());
		_head          = _blockSizeMinusOne;
		_headBlock     = _blocks[0];
		_headBlockNext = _blocks[1];
		_tailBlockPrev = _blocks[_tailBlockIndex++];
		_tailBlock     = _blocks[_tailBlockIndex];
	}
	
	function _popBlock()
	{
		_putBlock(_blocks.pop());
		_tailBlockIndex--;
		_tailBlock = _tailBlockPrev;
		_tail      = _blockSizeMinusOne;
		if (_tailBlockIndex > 0)
			_tailBlockPrev = _blocks[_tailBlockIndex - 1];
		else
		{
			_headBlockNext = null;
			_tailBlockPrev = null;
		}
	}
	
	function _pushBlock()
	{
		_blocks.push(_getBlock());
		_tail          = 0;
		_tailBlockPrev = _tailBlock;
		_tailBlock     = _blocks[++_tailBlockIndex];
		if (_tailBlockIndex == 1)
			_headBlockNext = _blocks[1];
	}
	
	inline function _getBlock():Array<T>
	{
		if (_poolSize > 0)
			return _blockPool[--_poolSize];
		else
			return ArrayUtil.alloc(_blockSize);
	}
	
	inline function _putBlock(x:Array<T>)
	{
		if (_poolSize < _poolCapacity)
			_blockPool[_poolSize++] = x;
	}
	
	inline function _copy(src:Array<T>, dst:Array<T>, min:Int, max:Int)
	{
		for (j in min...max)
			dst[j] = src[j];
	}
	
	inline function _copyCloneable(src:Array<T>, dst:Array<T>, min:Int, max:Int)
	{
		for (j in min...max)
		{
			#if debug
			assert(Std.is(src[j], Cloneable), 'element is not of type Cloneable (${src[j]})');
			#end
			
			dst[j] = src[j];
		}
	}
	
	inline function _copyCopier(copier:T->T, src:Array<T>, dst:Array<T>, min:Int, max:Int)
	{
		for (j in min...max)
			dst[j] = copier(src[j]);
	}
}

#if doc
private
#end
class ArrayedDequeIterator<T> implements de.polygonal.ds.Itr<T>
{
	var _f:ArrayedDeque<T>;
	var _blocks:Array<Array<T>>;
	var _block:Array<T>;
	var _i:Int;
	var _s:Int;
	var _b:Int;
	var _blockSize:Int;
	
	public function new(f:ArrayedDeque<T>)
	{
		_f = f;
		reset();
	}
	
	inline public function reset():Itr<T>
	{
		_blockSize = __blockSize(_f);
		_blocks    = __blocks(_f);
		_i         = __head(_f) + 1;
		_b         = _i >> __blockSizeShift(_f);
		_s         = _f.size();
		_block     = _blocks[_b];
 		_i        -= (_b << __blockSizeShift(_f));
		return this;
	}
	
	inline public function hasNext():Bool
	{
		return _s-- > 0;
	}
	
	inline public function next():T
	{
		var x = _block[_i++];
		if (_i == _blockSize)
		{
			_i = 0;
			_block = _blocks[++_b];
		}
		
		return x;
	}
	
	inline public function remove()
	{
		throw "unsupported operation";
	}
	
	inline function __head<T>(f:ArrayedDequeFriend<T>)
	{
		return f._head;
	}
	inline function __blockSize<T>(f:ArrayedDequeFriend<T>)
	{
		return f._blockSize;
	}
	inline function __blockSizeShift<T>(f:ArrayedDequeFriend<T>)
	{
		return f._blockSizeShift;
	}
	inline function __blocks<T>(f:ArrayedDequeFriend<T>)
	{
		return f._blocks;
	}
}