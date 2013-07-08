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

#if flash10
#if alchemy
import de.polygonal.ds.mem.IntMemory;
import flash.Memory;
#else
import flash.Vector;
#end
#else
using de.polygonal.ds.ArrayUtil;
#end

import de.polygonal.ds.error.Assert.assert;

private typedef IntHashSetFriend =
{
	#if flash10
	#if alchemy
	private var _hash:IntMemory;
	private var _data:IntMemory;
	#else
	private var _hash:Vector<Int>;
	private var _data:Vector<Int>;
	#end
	#else
	private var _hash:Array<Int>;
	private var _data:Array<Int>;
	#end
	
	private var _mask:Int;
	private var _capacity:Int;
}

/**
 * <p>An array hash set for storing integers.</p>
 * <p><o>Amortized running time in Big O notation</o></p>
 */
class IntHashSet implements Set<Int>
{
	/**
	 * Return code for a non-existing element. 
	 */
	inline public static var VAL_ABSENT = M.INT32_MIN;
	
	inline static var EMPTY_SLOT        = -1;
	inline static var NULL_POINTER      = -1;
	
	/**
	 * A unique identifier for this object.<br/>
	 * A hash table transforms this key into an index of an array element by using a hash function.<br/>
	 * <warn>This value should never be changed by the user.</warn>
	 */
	public var key:Int;
	
	/**
	 * The maximum allowed size of this hash set.<br/>
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
	
	#if flash10
	#if alchemy
	var _hash:IntMemory;
	var _data:IntMemory;
	var _next:IntMemory;
	#else
	var _hash:Vector<Int>;
	var _data:Vector<Int>;
	var _next:Vector<Int>;
	#end
	#else
	var _hash:Array<Int>;
	var _data:Array<Int>;
	var _next:Array<Int>;
	#end
	
	var _mask:Int;
	var _free:Int;
	
	var _capacity:Int;
	var _size:Int;
	var _sizeLevel:Int;
	var _isResizable:Bool;
	var _iterator:IntHashSetIterator;
	
	/**
	 * @param slotCount the total number of slots into which the hashed elements are distributed.
	 * This defines the space-time trade off of the set.
	 * Increasing the <code>slotCount</code> reduces the computation time (read/write/access) of the set at the cost of increased memory use.
	 * This value is fixed and can only be changed by calling <em>rehash()</em>, which rebuilds the set (expensive).
	 * 
	 * @param capacity the initial physical space for storing the elements at the time the set is created.
	 * This is also the minimum allowed size of the set and cannot be changed in the future.
	 * If omitted, the initial <em>capacity</em> equals <code>slotCount</code>.
	 * The <em>capacity</em> is automatically adjusted according to the storage requirements based on two rules:
	 * <ol>
	 * <li>If the set runs out of space, the <em>capacity</em> is doubled (if <code>isResizable</code> is true).</li>
	 * <li>If the <em>size()</em> falls below a quarter of the current <em>capacity</em>, the <em>capacity</em> is cut in half while the minimum <em>capacity</em> can't fall below <code>capacity</code>.</li>
	 * </ol>
	 *
	 * @param isResizable if false, the hash set is created with a fixed size.
	 * Thus adding an element when <em>size()</em> equals <em>capacity</em> throws an error.
	 * Otherwise the <em>capacity</em> is automatically adjusted.
	 * Default is true.
	 * 
	 * @param maxSize the maximum allowed size of this hash set.
	 * The default value of -1 indicates that there is no upper limit.
	 * 
	 * @throws de.polygonal.ds.error.AssertError <code>slotCount</code> is not a power of two (debug only).
	 * @throws de.polygonal.ds.error.AssertError <code>capacity</code> is not a power of two (debug only).
	 * @throws de.polygonal.ds.error.AssertError <code>capacity</code> is &lt; 2 (debug only).
	 */
	public function new(slotCount:Int, capacity = -1, isResizable = true, maxSize = -1)
	{
		#if debug
		assert(M.isPow2(slotCount), "slotCount is not a power of 2");
		#end
		
		_isResizable = isResizable;
		
		if (capacity == -1)
			capacity = slotCount;
		else
		{
			#if debug
			assert(capacity >= 2, "minimum capacity is 2");
			assert(M.isPow2(slotCount), "capacity is not a power of 2");
			#end
		}
		
		_free      = 0;
		_capacity  = capacity;
		_size      = 0;
		_mask      = slotCount - 1;
		_sizeLevel = 0;
		_iterator  = null;
		
		#if debug
		this.maxSize = (maxSize == -1) ? M.INT32_MAX : maxSize;
		#else
		this.maxSize = -1;
		#end
		
		#if flash10
		#if alchemy
		_hash = new IntMemory(slotCount, "IntHashSet._hash");
		_hash.fill(EMPTY_SLOT);
		_data = new IntMemory(_capacity << 1, "IntHashSet._data");
		_next = new IntMemory(_capacity, "IntHashSet._next");
		#else
		_hash = new Vector<Int>(slotCount);
		for (i in 0...slotCount) _hash[i] = EMPTY_SLOT;
		_data = new Vector<Int>(_capacity << 1);
		_next = new Vector<Int>(_capacity);
		#end
		#else
		_hash = ArrayUtil.alloc(slotCount);
		_hash.fill(EMPTY_SLOT, slotCount);
		_data = ArrayUtil.alloc(_capacity << 1);
		_next = ArrayUtil.alloc(_capacity);
		#end
		
		var j = 1;
		for (i in 0...capacity)
		{
			__setData(j - 1, VAL_ABSENT);
			__setData(j, NULL_POINTER);
			j += 2;
		}
		
		for (i in 0..._capacity - 1) __setNext(i, i + 1);
		__setNext(_capacity - 1, NULL_POINTER);
		
		key = HashKey.next();
		reuseIterator = false;
	}
	
	/**
	 * The load factor measure the "denseness" of a hash set and is proportional to the time cost to look up an entry.<br/>
	 * E.g. assuming that the elements are perfectly distributed, a load factor of 4.0 indicates that each slot stores 4 elements, which have to be sequentially searched in order to find an element.<br/>
	 * A high load factor thus indicates poor performance.
	 * If the load factor gets too high, additional slots can be allocated by calling <em>rehash()</em>.
	 */
	inline public function getLoadFactor():Float
	{
		return size() / getSlotCount();
	}
	
	/**
	 * The total number of allocated slots. 
	 */
	inline public function getSlotCount():Int
	{
		return _mask + 1;
	}
	
	/**
	 * The size of the allocated storage space for the elements.<br/>
	 * If more space is required to accomodate new elements, the <em>capacity</em> is doubled every time <em>size()</em> grows beyond <em>capacity</em>, and split in half when <em>size()</em> is a quarter of <em>capacity</em>.
	 * The <em>capacity</em> never falls below the initial size defined in the constructor.
	 */
	inline public function getCapacity():Int
	{
		return _capacity;
	}
	
	/**
	 * Counts the total number of collisions.<br/>
	 * A collision occurs when two distinct elements are hashed into the same slot.
	 * <o>n</o>
	 */
	public function getCollisionCount():Int
	{
		var c = 0, j;
		for (i in 0...getSlotCount())
		{
			j = __getHash(i);
			if (j == EMPTY_SLOT) continue;
			j = __getData(j + 1);
			while (j != NULL_POINTER)
			{
				j = __getData(j + 1);
				c++;
			}
		}
		return c;
	}
	
	/**
	 * Returns true if this set contains the element <code>x</code>.<br/>
	 * Uses move-to-front-on-access which reduces access time when similar elements are frequently queried.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError value 0x80000000 is reserved (debug only).
	 */
	inline public function hasFront(x:Int):Bool
	{
		#if debug
		assert(x != VAL_ABSENT, "value 0x80000000 is reserved");
		#end
		
		var b = _hashCode(x);
		var i = __getHash(b);
		if (i == EMPTY_SLOT)
			return false;
		else
		{
			#if (flash10 && alchemy)
			var o = _data.getAddr(i);
			if (Memory.getI32(o) == x)
				return true;
			#else
			if (__getData(i) == x)
				return true;
			#end
			else
			{
				var exists = false;
				
				var first = i, i0 = first;
				
				#if (flash10 && alchemy)
				i = Memory.getI32(o + 4);
				#else
				i = __getData(i + 1);
				#end
				
				while (i != NULL_POINTER)
				{
					#if (flash10 && alchemy)
					o = _data.getAddr(i);
					if (Memory.getI32(o) == x)
					#else
					if (__getData(i) == x)
					#end
					{
						#if (flash10 && alchemy)
						var o1 = _data.getAddr(i0 + 1);
						Memory.setI32(o1, Memory.getI32(o + 4));
						Memory.setI32(o + 4, first);
						__setHash(b, i);
						#else
						__setData(i0 + 1, __getData(i + 1));
						__setData(i + 1, first);
						__setHash(b, i);
						#end
						
						exists = true;
						break;
					}
					i = __getData((i0 = i) + 1);
				}
				return exists;
			}
		}
	}
	
	/**
	 * Redistributes all elements over <code>slotCount</code>.<br/>
	 * This is an expensive operations as the set is rebuild from scratch.
	 * <o>n</o>
	 * @throws de.polygonal.ds.error.AssertError <code>slotCount</code> is not a power of two (debug only).
	 */
	public function rehash(slotCount:Int)
	{
		#if debug
		assert(M.isPow2(slotCount), "slotCount is not a power of 2");
		#end
		
		if (slotCount == getSlotCount()) return;
		
		var tmp = new IntHashSet(slotCount, _capacity);
		
		#if (flash10 && alchemy)
		var o = _data.getAddr(0);
		for (i in 0..._capacity)
		{
			var v = Memory.getI32(o);
			if (v != VAL_ABSENT) tmp.set(v);
			o += 8;
		}
		#else
		for (i in 0..._capacity)
		{
			var v = __getData(i << 1);
			if (v != VAL_ABSENT) tmp.set(v);
		}
		#end
		
		#if (flash10 && alchemy)
		_hash.free();
		_data.free();
		_next.free();
		#end
		_hash = tmp._hash;
		_data = tmp._data;
		_next = tmp._next;
		
		_mask = tmp._mask;
		_free = tmp._free;
		_sizeLevel = tmp._sizeLevel;
	}
	
	/**
	 * Returns a string representing the current object.<br/>
	 * Example:<br/>
	 * <pre class="prettyprint">
	 * var set = new de.polygonal.ds.IntHashSet(16);
	 * for (i in 0...4) {
	 *     set.set(i);
	 * }
	 * trace(set);</pre>
	 * <pre class="console">
	 * { IntHashSet size/capacity: 4/16, load factor: 0.25 }
	 * [
	 *   0
	 *   1
	 *   2
	 *   3
	 * ]</pre>
	 */
	public function toString():String
	{
		var s = Printf.format("{ IntHashSet size/capacity: %d/%d, load factor: %.2f }", [size(), _capacity, getLoadFactor()]);
		if (isEmpty()) return s;
		s += "\n[\n";
		for (x in this)
		{
			s += '  $x\n';
		}
		s += "]";
		return s;
	}
	
	/*///////////////////////////////////////////////////////
	// set
	///////////////////////////////////////////////////////*/
	
	/**
	 * Returns true if this set contains the element <code>x</code>.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError value 0x80000000 is reserved (debug only).
	 */
	inline public function has(x:Int):Bool
	{
		#if debug
		assert(x != VAL_ABSENT, "value 0x80000000 is reserved");
		#end
		
		var i = __getHash(_hashCode(x));
		if (i == EMPTY_SLOT)
			return false;
		else
		{
			#if (flash10 && alchemy)
			var o = _data.getAddr(i);
			if (Memory.getI32(o) == x)
				return true;
			#else
			if (__getData(i) == x)
				return true;
			#end
			else
			{
				var exists = false;
				#if (flash10 && alchemy)
				i = Memory.getI32(o + 4);
				while (i != NULL_POINTER)
				{
					o = _data.getAddr(i);
					if (Memory.getI32(o) == x)
					{
						exists = true;
						break;
					}
					i = Memory.getI32(o + 4);
				}
				#else
				i = __getData(i + 1);
				while (i != NULL_POINTER)
				{
					if (__getData(i) == x)
					{
						exists = true;
						break;
					}
					i = __getData(i + 1);
				}
				#end
				return exists;
			}
		}
	}
	
	/**
	 * Adds the element <code>x</code> to this set if possible.
	 * <o>1</o>
	 * @return true if <code>x</code> was added to this set, false if <code>x</code> already exists.
	 * @throws de.polygonal.ds.error.AssertError value 0x80000000 is reserved (debug only).
	 * @throws de.polygonal.ds.error.AssertError <em>size()</em> equals <em>maxSize</em> (debug only).
	 * @throws de.polygonal.ds.error.AssertError hash set is full (if not resizable).
	 */
	inline public function set(x:Int):Bool
	{
		#if debug
		assert(x != VAL_ABSENT, "value 0x80000000 is reserved");
		assert(size() < maxSize, 'size equals max size ($maxSize)');
		#end
		
		var b = _hashCode(x);
		
		#if (flash10 && alchemy)
		var o = _hash.getAddr(b);
		var j = Memory.getI32(o);
		#else
		var j = __getHash(b);
		#end
		if (j == EMPTY_SLOT)
		{
			if (_size == _capacity)
			{
				#if debug
				if (!_isResizable)
					assert(false, 'hash set is full ($_capacity)');
				#end
				
				_expand();
			}
			
			var i = _free << 1;
			_free = __getNext(_free);
			
			#if (flash10 && alchemy)
			Memory.setI32(o, i);
			#else
			__setHash(b, i);
			#end
			
			__setData(i, x);
			
			_size++;
			return true;
		}
		else
		{
			#if (flash10 && alchemy)
			o = _data.getAddr(j);
			if (Memory.getI32(o) == x)
				return false;
			#else
			if (__getData(j) == x)
				return false;
			#end
			else
			{
				#if (flash10 && alchemy)
				var t = Memory.getI32(o + 4);
				while (t != NULL_POINTER)
				{
					o = _data.getAddr(t);
					if (Memory.getI32(o) == x)
					{
						j = -1;
						break;
					}
					
					j = t;
					t = Memory.getI32(o + 4);
				}
				#else
				var t = __getData(j + 1);
				while (t != NULL_POINTER)
				{
					if (__getData(t) == x)
					{
						j = -1;
						break;
					}
					
					j = t;
					t = __getData(t + 1);
				}
				#end
				
				if (j == -1)
					return false;
				else
				{
					if (_size == _capacity)
					{
						if (!_isResizable)
							throw 'hash set is full ($_capacity)';
						_expand();
					}
					var i = _free << 1;
					_free = __getNext(_free);
					__setData(i, x);
					
					__setData(j + 1, i);
					_size++;
					return true;
				}
			}
		}
	}
	
	/*///////////////////////////////////////////////////////
	// collection
	///////////////////////////////////////////////////////*/
	
	/**
	 * Destroys this object by explicitly nullifying all elements.<br/>
	 * Improves GC efficiency/performance (optional).
	 * <o>n</o>
	 */
	public function free()
	{
		#if (flash10 && alchemy)
		_hash.free();
		_data.free();
		_next.free();
		#end
		
		_hash = null;
		_data = null;
		_next = null;
		_iterator = null;
	}
	
	/**
	 * Same as <em>has()</em>.
	 * <o>1</o>
	 */
	inline public function contains(x:Int):Bool
	{
		return has(x);
	}
	
	/**
	 * Removes the element <code>x</code>.
	 * <o>1</o>
	 * @return true if <code>x</code> was successfully removed, false if <code>x</code> does not exist.
	 */
	inline public function remove(x:Int):Bool
	{
		var b = _hashCode(x);
		var i = __getHash(b);
		if (i == EMPTY_SLOT)
			return false;
		else
		{
			#if (flash10 && alchemy)
			var o = _data.getAddr(i);
			if (x == Memory.getI32(o))
			#else
			if (x == __getData(i))
			#end
			{
				#if (flash10 && alchemy)
				if (Memory.getI32(o + 4) == NULL_POINTER)
				#else
				if (__getData(i + 1) == NULL_POINTER)
				#end
					__setHash(b, EMPTY_SLOT);
				else
					__setHash(b, __getData(i + 1));
				
				var j = i >> 1;
				__setNext(j, _free);
				_free = j;
				
				#if (flash10 && alchemy)
				Memory.setI32(o    , VAL_ABSENT);
				Memory.setI32(o + 4, NULL_POINTER);
				#else
				__setData(i    , VAL_ABSENT);
				__setData(i + 1, NULL_POINTER);
				#end
				
				_size--;
				
				if (_sizeLevel > 0)
					if (_size == (_capacity >> 2))
						if (_isResizable)
							_shrink();
				
				return true;
			}
			else
			{
				var exists = false;
				
				var i0 = i;
				#if (flash10 && alchemy)
				i = Memory.getI32(o + 4);
				#else
				i = __getData(i + 1);
				#end
				
				while (i != NULL_POINTER)
				{
					#if (flash10 && alchemy)
					o = _data.getAddr(i);
					if (Memory.getI32(o) == x)
					{
						exists = true;
						break;
					}
					i0 = i;
					i = Memory.getI32(o + 4);
					#else
					if (__getData(i) == x)
					{
						exists = true;
						break;
					}
					i = __getData((i0 = i) + 1);
					#end
				}
				
				if (exists)
				{
					__setData(i0 + 1, __getData(i + 1));
					
					var j = i >> 1;
					__setNext(j, _free);
					_free = j;
					
					#if (flash10 && alchemy)
					o = _data.getAddr(i);
					Memory.setI32(o    , VAL_ABSENT);
					Memory.setI32(o + 4, NULL_POINTER);
					#else
					__setData(i    , VAL_ABSENT);
					__setData(i + 1, NULL_POINTER);
					#end
					
					--_size;
					
					if (_sizeLevel > 0)
						if (_size == (_capacity >> 2))
							if (_isResizable)
								_shrink();
					
					return true;
				}
				else
					return false;
			}
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
	 * Removes all elements.<br/>
	 * <o>n</o>
	 * @param purge If true, the hash set shrinks to the initial capacity defined in the constructor.
	 */
	public function clear(purge = false)
	{
		if (purge && _sizeLevel > 0)
		{
			_capacity >>= _sizeLevel;
			_sizeLevel = 0;
			
			#if flash10
			#if alchemy
			_data.resize(_capacity << 1);
			_next.resize(_capacity);
			#else
			_data = new Vector<Int>(_capacity << 1);
			_next = new Vector<Int>(_capacity);
			#end
			#else
			_data = ArrayUtil.alloc(_capacity << 1);
			_next = ArrayUtil.alloc(_capacity);
			#end
		}
		
		#if flash10
		#if alchemy
		_hash.fill(EMPTY_SLOT);
		#else
		for (i in 0...getSlotCount()) _hash[i] = EMPTY_SLOT;
		#end
		#else
		_hash.fill(EMPTY_SLOT, getSlotCount());
		#end
		
		var j = 1;
		for (i in 0..._capacity)
		{
			__setData(j - 1, VAL_ABSENT);
			__setData(j, NULL_POINTER);
			j += 2;
		}
		for (i in 0..._capacity - 1) __setNext(i, i + 1);
		__setNext(_capacity - 1, NULL_POINTER);
		
		_free = 0;
		_size = 0;
	}
	
	/**
	 * Returns a new <em>IntHashSetIterator</em> object to iterate over all elements contained in this hash set.<br/>
	 * The elements are visited in a random order.
	 * @see <a href="http://haxe.org/ref/iterators" target="_blank">http://haxe.org/ref/iterators</a>
	 */
	public function iterator():Itr<Int>
	{
		if (reuseIterator)
		{
			if (_iterator == null)
				_iterator = new IntHashSetIterator(this);
			else
				_iterator.reset();
			return _iterator;
		}
		else
			return new IntHashSetIterator(this);
	}
	
	/**
	 * Returns true if the set is empty.
	 * <o>1</o>
	 */
	inline public function isEmpty():Bool
	{
		return _size == 0;
	}
	
	/**
	 * Returns an unordered array containing all elements in this set.
	 */
	public function toArray():Array<Int>
	{
		var a:Array<Int> = ArrayUtil.alloc(size());
		var j = 0;
		for (i in 0..._capacity)
		{
			var v = __getData(i << 1);
			if (v != VAL_ABSENT) a[j++] = v;
		}
		return a;
	}
	
	#if flash10
	/**
	 * Returns an unordered Vector.&lt;T&gt; object containing all elements in this set.
	 */
	public function toVector():flash.Vector<Dynamic>
	{
		var a = new flash.Vector<Int>(size());
		var j = 0;
		for (i in 0..._capacity)
		{
			var v = __getData(i << 1);
			if (v != VAL_ABSENT) a[j++] = v;
		}
		return a;
	}
	#end
	
	/**
	 * Duplicates this hash set by creating a deep copy.<br/>
	 * The <code>assign</code> and <code>copier</code> parameters are ignored.
	 */
	public function clone(assign:Bool = true, copier:Int->Int = null):Collection<Int>
	{
		var c:IntHashSet = Type.createEmptyInstance(IntHashSet);
		c.key = HashKey.next();
		c.maxSize = maxSize;
		
		#if flash10
		#if alchemy
		c._hash = _hash.clone();
		c._data = _data.clone();
		c._next = _next.clone();
		#else
		c._hash = new Vector<Int>(_hash.length);
		c._data = new Vector<Int>(_data.length);
		c._next = new Vector<Int>(_next.length);
		for (i in 0...Std.int(_hash.length)) c._hash[i] = _hash[i];
		for (i in 0...Std.int(_data.length)) c._data[i] = _data[i];
		for (i in 0...Std.int(_next.length)) c._next[i] = _next[i];
		#end
		#else
		c._hash = new Array<Int>();
		ArrayUtil.copy(_hash, c._hash);
		c._data = new Array<Int>();
		ArrayUtil.copy(_data, c._data);
		c._next = new Array<Int>();
		ArrayUtil.copy(_next, c._next);
		#end
		
		c._mask      = _mask;
		c._capacity   = _capacity;
		c._free      = _free;
		c._size      = _size;
		c._sizeLevel = _sizeLevel;
		
		return c;
	}
	
	inline function _hashCode(x:Int):Int
	{
		return (x * 73856093) & _mask;
	}
	
	function _expand()
	{
		_sizeLevel++;
		
		var oldSize = _capacity;
		var newSize = oldSize << 1;
		_capacity = newSize;
		
		#if flash10
		#if alchemy
		_next.resize(newSize);
		_data.resize(newSize << 1);
		#else
		var copy = new Vector<Int>(newSize);
		for (i in 0...oldSize) copy[i] = _next[i];
		_next = copy;
		var copy = new Vector<Int>(newSize << 1);
		for (i in 0...oldSize << 1) copy[i] = _data[i];
		_data = copy;
		#end
		#else
		var copy:Array<Int> = ArrayUtil.alloc(newSize);
		ArrayUtil.copy(_next, copy, 0, oldSize);
		_next = copy;
		var copy:Array<Int> = ArrayUtil.alloc(newSize << 1);
		ArrayUtil.copy(_data, copy, 0, oldSize << 1);
		_data = copy;
		#end
		
		for (i in oldSize - 1...newSize - 1) __setNext(i, i + 1);
		__setNext(newSize - 1, NULL_POINTER);
		_free = oldSize;
		
		var j = (oldSize << 1) + 1;
		for (i in 0...oldSize)
		{
			#if (flash10 && alchemy)
			var o = _data.getAddr(j - 1);
			Memory.setI32(o    , VAL_ABSENT);
			Memory.setI32(o + 4, NULL_POINTER);
			#else
			__setData(j - 1, VAL_ABSENT);
			__setData(j    , NULL_POINTER);
			#end
			
			j += 2;
		}
	}
	
	function _shrink()
	{
		_sizeLevel--;
		
		var oldSize = _capacity;
		var newSize = oldSize >> 1; 
		_capacity = newSize;
		
		#if (flash10 && alchemy)
		_data.resize((oldSize + (newSize >> 1)) << 1);
		
		var offset = oldSize << 1;
		var e = offset;
		
		var dst, src;
		dst = _data.getAddr(e);
		
		for (i in 0...getSlotCount())
		{
			var j = __getHash(i);
			if (j == EMPTY_SLOT) continue;
			
			__setHash(i, e - offset);
			
			flash.Memory.setI32(dst    , __getData(j));
			flash.Memory.setI32(dst + 4, NULL_POINTER);
			dst += 8;
			
			e += 2;
			j = __getData(j + 1);
			while (j != NULL_POINTER)
			{
				flash.Memory.setI32(dst - 4, e - offset);
				flash.Memory.setI32(dst    , __getData(j));
				flash.Memory.setI32(dst + 4, NULL_POINTER);
				dst += 8;
				
				e += 2;
				j = __getData(j + 1);
			}
		}
		
		var k = (newSize >> 1) << 1;
		
		dst = _data.getAddr(0);
		src = _data.getAddr(offset);
		var i = 0;
		var j = k << 2;
		while (i < j)
		{
			flash.Memory.setI32(dst + i, flash.Memory.getI32(src + i));
			i += 4;
		}
		
		dst = _data.getAddr(k);
		k = _data.getAddr(newSize << 1);
		while (dst < k)
		{
			flash.Memory.setI32(dst    , VAL_ABSENT);
			flash.Memory.setI32(dst + 4, NULL_POINTER);
			dst += 8;
		}
		
		_data.resize(newSize << 1);
		_next.resize(newSize);
		#else
		var k = newSize << 1;
		#if flash10
		var tmp = new Vector<Int>(k);
		_next = new Vector<Int>(newSize);
		#else
		var tmp:Array<Int> = ArrayUtil.alloc(k);
		_next = ArrayUtil.alloc(newSize);
		#end
		
		var e = 0;
		for (i in 0...getSlotCount())
		{
			var j = __getHash(i);
			if (j == EMPTY_SLOT) continue;
			
			__setHash(i, e);
			
			tmp[e++] = __getData(j);
			tmp[e++] = NULL_POINTER;
			
			j = __getData(j + 1);
			while (j != NULL_POINTER)
			{
				tmp[e - 1] = e;
				tmp[e++]   = __getData(j    );
				tmp[e++]   = NULL_POINTER;
				j = __getData(j + 1);
			}
		}
		var i = k >> 1;
		while (i < k)
		{
			tmp[i++] = VAL_ABSENT;
			tmp[i++] = NULL_POINTER;
		}
		_data = tmp;
		#end
		
		for (i in 0...newSize - 1) __setNext(i, i + 1);
		__setNext(newSize - 1, NULL_POINTER);
		_free = newSize >> 1;
	}
	
	inline function __getHash(i:Int)
	{
		#if (flash10 && alchemy)
		return _hash.get(i);
		#else
		return _hash[i];
		#end
	}
	inline function __setHash(i:Int, x:Int)
	{
		#if (flash10 && alchemy)
		_hash.set(i, x);
		#else
		_hash[i] = x;
		#end
	}
	
	inline function __getNext(i:Int)
	{
		#if (flash10 && alchemy)
		return _next.get(i);
		#else
		return _next[i];
		#end
	}
	inline function __setNext(i:Int, x:Int)
	{
		#if (flash10 && alchemy)
		_next.set(i, x);
		#else
		_next[i] = x;
		#end
	}
	
	inline function __getData(i:Int)
	{
		#if (flash10 && alchemy)
		return _data.get(i);
		#else
		return _data[i];
		#end
	}
	inline function __setData(i:Int, x:Int)
	{
		#if (flash10 && alchemy)
		_data.set(i, x);
		#else
		_data[i] = x;
		#end
	}
}

#if doc
private
#end
class IntHashSetIterator implements de.polygonal.ds.Itr<Int>
{
	var _f:IntHashSetFriend;
	var _i:Int;
	var _s:Int;
	
	#if flash10
	#if alchemy
	var _data:IntMemory;
	#else
	var _data:Vector<Int>;
	#end
	#else
	var _data:Array<Int>;
	#end
	
	public function new(hash:IntHashSetFriend)
	{
		_f = hash;
		_data = _f._data;
		_i = 0;
		_s = _f._capacity;
		_scan();
	}
	
	inline public function reset():Itr<Int>
	{
		_data = _f._data;
		_i = 0;
		_s = _f._capacity;
		_scan();
		return this;
	}
	
	inline public function hasNext():Bool
	{
		return _i < _s;
	}
	
	inline public function next():Int
	{
		var x = __getData((_i++ << 1));
		_scan();
		return x;
	}
	
	inline public function remove()
	{
		throw "unsupported operation";
	}
	
	inline function _scan()
	{
		while ((_i < _s) && (__getData((_i << 1)) == IntHashSet.VAL_ABSENT)) _i++;
	}
	
	inline function __getData(i:Int)
	{
		#if (flash10 && alchemy)
		return _data.get(i);
		#else
		return _data[i];
		#end
	}
}