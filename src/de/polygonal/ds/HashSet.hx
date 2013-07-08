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
#else
import flash.Vector;
#end
#end

import de.polygonal.ds.error.Assert.assert;

private typedef HashSetFriend<T> =
{
	private var _h:IntIntHashTable;
	private var _vals:Array<T>;
}

/**
 * <p>An array hash set for storing <em>Hashable</em> objects.</p>
 * <p><o>Worst-case running time in Big O notation</o></p>
 */
class HashSet<T:Hashable> implements Set<T>
{
	/**
	 * A unique identifier for this object.<br/>
	 * A hash table transforms this key into an index of an array element by using a hash function.<br/>
	 * <warn>This value should never be changed by the user.</warn>
	 */
	public var key:Int;
	
	/**
	 * The maximum allowed size of this hash set.<br/>
	 * Once the maximum size is reached, adding an element to a array will fail with an error (debug only).
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
	
	var _h:IntIntHashTable;
	
	var _vals:Array<T>;
	
	#if flash10
	#if alchemy
	var _next:IntMemory;
	#else
	var _next:Vector<Int>;
	#end
	#else
	var _next:Array<Int>;
	#end
	
	var _free:Int;
	var _sizeLevel:Int;
	var _isResizable:Bool;
	var _iterator:HashSetIterator<T>;
	
	/**
	 * @param slotCount the total number of slots into which the hashed values are distributed.
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
		if (capacity == -1) capacity = slotCount;
		
		_isResizable = isResizable;
		
		_h = new IntIntHashTable(slotCount, capacity, _isResizable, maxSize);
		_vals = ArrayUtil.alloc(capacity);
		
		#if debug
		this.maxSize = (maxSize == -1) ? M.INT32_MAX : maxSize;
		#else
		this.maxSize = -1;
		#end
		
		#if flash10
		#if alchemy
		_next = new IntMemory(capacity, "HashSet._next");
		#else
		_next = new Vector<Int>(capacity);
		#end
		#else
		_next = ArrayUtil.alloc(capacity);
		#end
		
		for (i in 0...capacity - 1) __setNext(i, i + 1);
		__setNext(capacity - 1, IntIntHashTable.NULL_POINTER);
		_free = 0;
		_sizeLevel = 0;
		_iterator = null;
		
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
		return _h.getLoadFactor();
	}
	
	/**
	 * The current slot count.
	 */
	inline public function getSlotCount():Int
	{
		return _h.getSlotCount();
	}
	
	/**
	 * The size of the allocated storage space for the elements.<br/>
	 * If more space is required to accomodate new elements, the <em>capacity</em> is doubled every time <em>size()</em> grows beyond <em>capacity</em>, and split in half when <em>size()</em> is a quarter of <em>capacity</em>.
	 * The <em>capacity</em> never falls below the initial size defined in the constructor.
	 */
	inline public function getCapacity():Int
	{
		return _h.getCapacity();
	}
	
	/**
	 * Counts the total number of collisions.<br/>
	 * A collision occurs when two distinct elements are hashed into the same slot.
	 */
	public function getCollisionCount():Int
	{
		return _h.getCollisionCount();
	}
	
	/**
	 * Returns true if this set contains the element <code>x</code>.<br/>
	 * Uses move-to-front-on-access which reduces access time when similar elements are frequently queried.
	 * <o>n</o>
	 * @throws de.polygonal.ds.error.AssertError <code>x</code> is null (debug only).
	 */
	inline public function hasFront(x:T):Bool
	{
		var i = _h.getFront(__key(x));
		return i != IntIntHashTable.KEY_ABSENT;
	}
	
	/**
	 * Redistributes all elements over <code>slotCount</code>.<br/>
	 * This is an expensive operations as the set is rebuild from scratch.
	 * <o>n</o>
	 * @throws de.polygonal.ds.error.AssertError <code>slotCount</code> is not a power of two (debug only).
	 */
	public function rehash(slotCount:Int)
	{
		_h.rehash(slotCount);
	}
	
	/**
	 * Returns a string representing the current object.<br/>
	 * Example:<br/>
	 * <pre class="prettyprint">
	 * class Foo extends de.polygonal.ds.HashableItem
	 * {
	 *     var value:Int;
	 *     public function new(value:Int) {
	 *         super();
	 *         this.value = value;
	 *     }
	 *     
	 *     public function toString():String {
	 *         return "{ Foo value: " + value + " }";
	 *     }
	 * }
	 * 
	 * class Main
	 * {
	 *     static function main()
	 *     {
	 *         var set = new de.polygonal.ds.HashSet&lt;Foo&gt;(16);
	 *         for (i in 0...4) set.set(new Foo(i));
	 *         trace(set);
	 *     }
	 * }</pre>
	 * <pre class="console">
	 * { HashSet size/capacity: 4/16, load factor: 0.25 }
	 * [
	 *   { Foo value: 0 }
	 *   { Foo value: 1 }
	 *   { Foo value: 2 }
	 *   { Foo value: 3 }
	 * ]</pre>
	 */
	public function toString():String
	{
		var s = Printf.format("{ HashSet size/capacity: %d/%d, load factor: %.2f }", [size(), getCapacity(), getLoadFactor()]);
		if (isEmpty()) return s;
		s += "\n[\n";
		for (x in this)
		{
			s += '  ${Std.string(x)}\n';
		}
		s += "]";
		return s;
	}
	
	/*///////////////////////////////////////////////////////
	// set
	///////////////////////////////////////////////////////*/
	
	/**
	 * Returns true if this set contains the element <code>x</code> or null if <code>x</code> does not exist.
	 * <o>n</o>
	 * @throws de.polygonal.ds.error.AssertError <code>x</code> is null (debug only).
	 */
	inline public function has(x:T):Bool
	{
		return _h.get(__key(x)) != IntIntHashTable.KEY_ABSENT;
	}
	
	/**
	 * Adds the element <code>x</code> to this set if possible.
	 * <o>n</o>
	 * @return true if <code>x</code> was added to this set, false if <code>x</code> already exists.
	 * @throws de.polygonal.ds.error.AssertError <code>x</code> is null (debug only).
	 * @throws de.polygonal.ds.error.AssertError <em>size()</em> equals <em>maxSize</em> (debug only).
	 * @throws de.polygonal.ds.error.AssertError hash set is full (if not resizable).
	 */
	inline public function set(x:T):Bool
	{
		#if debug
		assert(size() != maxSize, 'size equals max size ($maxSize)');
		#end
		
		if ((size() == getCapacity()))
		{
			if (_h.setIfAbsent(__key(x), size()))
			{
				#if debug
				if (!_isResizable)
					assert(false, 'hash set is full (${getCapacity()})');
				#end
				
				_expand(getCapacity() >> 1);
				_vals[_free] = x;
				_free = __getNext(_free);
				return true;
			}
			else
				return false;
		}
		else
		{
			if (_h.setIfAbsent(__key(x), _free))
			{
				_vals[_free] = x;
				_free = __getNext(_free);
				return true;
			}
			else
				return false;
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
		for (i in 0...size())
			_vals[i] = null;
		_vals = null;
		
		#if (flash10 && alchemy)
		_next.free();
		#end
		_next = null;
		
		_h.free();
		_h = null;
		_iterator = null;
	}
	
	/**
	 * Same as <em>has()</em>. 
	 * <o>n</o>
	 * @throws de.polygonal.ds.error.AssertError <code>x</code> is null (debug only).
	 */
	public function contains(x:T):Bool
	{
		return has(x);
	}
	
	/**
	 * Removes the element <code>x</code>.
	 * <o>n</o>
	 * @return true if <code>x</code> was successfully removed, false if <code>x</code> does not exist.
	 * @throws de.polygonal.ds.error.AssertError <code>x</code> is null (debug only).
	 */
	inline public function remove(x:T):Bool
	{
		var i = _h.get(__key(x));
		if (i == IntIntHashTable.KEY_ABSENT)
			return false;
		else
		{
			_vals[i] = null;
			__setNext(i, _free);
			_free = i;
			
			var shrink = false;
			
			if (_sizeLevel > 0)
				if (size() - 1 == (getCapacity() >> 2))
					if (_isResizable)
						shrink = true;
			
			_h.clr(__key(x));
			
			if (shrink) _shrink();
			
			return true;
		}
	}
	
	/**
	 * The total number of elements. 
	 * <o>1</o>
	 */
	public function size():Int
	{
		return _h.size();
	}
	
	/**
	 * Removes all elements.
	 * <o>n</o>
	 * @param purge if true, nullifies references upon removal and shrinks the hash set to the initial capacity defined in the constructor.
	 */
	public function clear(purge = false)
	{
		_h.clear(purge);
		for (i in 0...getCapacity()) _vals[i] = null;
		
		if (purge)
		{
			while (_sizeLevel > 0) _shrink();
			
			for (i in 0...getCapacity())
				_vals[i] = null;
		}
		
		for (i in 0...getCapacity() - 1) __setNext(i, i + 1);
		__setNext(getCapacity() - 1, IntIntHashTable.NULL_POINTER);
		_free = 0;
	}
	
	/**
	 * Returns a new <em>HashSetIterator</em> object to iterate over all elements contained in this hash set.<br/>
	 * The elements are visited in a random order.
	 * @see <a href="http://haxe.org/ref/iterators" target="_blank">http://haxe.org/ref/iterators</a>
	 */
	public function iterator():Itr<T>
	{
		if (reuseIterator)
		{
			if (_iterator == null)
				_iterator = new HashSetIterator(this);
			else
				_iterator.reset();
			return _iterator;
		}
		else
			return new HashSetIterator(this);
	}
	
	/**
	 * Returns true if the set is empty. 
	 * <o>1</o>
	 */
	inline public function isEmpty():Bool
	{
		return _h.isEmpty();
	}
	
	/**
	 * Returns an unordered array containing all elements in this set.
	 */
	public function toArray():Array<T>
	{
		var a:Array<T> = ArrayUtil.alloc(size());
		var j = 0;
		for (i in 0...getCapacity())
		{
			var v = _vals[i];
			if (v != null) a[j++] = v;
		}
		return a;
	}
	
	#if flash10
	/**
	 * Returns a Vector.&lt;T&gt; object containing all elements in this set.
	 */
	public function toVector():flash.Vector<Dynamic>
	{
		var a = new flash.Vector<Dynamic>(size());
		var j = 0;
		for (i in 0...getCapacity())
		{
			var v = _vals[i];
			if (v != null) a[j++] = v;
		}
		return a;
	}
	#end
	
	/**
	 * Duplicates this hash set. Supports shallow (structure only) and deep copies (structure & elements).
	 * @param assign if true, the <code>copier</code> parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.<br/>
	 * If false, the <em>clone()</em> method is called on each element. <warn>In this case all elements have to implement <em>Cloneable</em>.</warn>
	 * @param copier a custom function for copying elements. Replaces element.<em>clone()</em> if <code>assign</code> is false.
	 * @throws de.polygonal.ds.error.AssertError element is not of type <em>Cloneable</em> (debug only).
	 */
	public function clone(assign = true, copier:T->T = null):Collection<T>
	{
		var c:HashSet<T> = Type.createEmptyInstance(HashSet);
		
		c._isResizable = _isResizable;
		c.maxSize = maxSize;
		c.key = HashKey.next();
		c._h = cast _h.clone(false);
		
		if (assign)
		{
			c._vals = new Array<T>();
			ArrayUtil.copy(_vals, c._vals);
		}
		else
		{
			var tmp:Array<T> = ArrayUtil.alloc(getCapacity());
			if (copier != null)
			{
				for (i in 0...getCapacity())
				{
					var v = _vals[i];
					if (v != null)
						tmp[i] = copier(v);
				}
			}
			else
			{
				var c:Cloneable<T> = null;
				for (i in 0...getCapacity())
				{
					var v = _vals[i];
					if (v != null)
					{
						#if debug
						assert(Std.is(v, Cloneable), 'element is not of type Cloneable ($v)');
						#end
						
						c = untyped v;
						tmp[i] = c.clone();
					}
				}
			}
			c._vals = tmp;
		}
		
		c._sizeLevel = _sizeLevel;
		c._free = _free;
		
		#if flash10
		#if alchemy
		c._next = _next.clone();
		#else
		c._next = new Vector<Int>(_next.length);
		for (i in 0...Std.int(_next.length)) c._next[i] = _next[i];
		#end
		#else
		c._next = new Array<Int>();
		ArrayUtil.copy(_next, c._next);
		#end
		
		return c;
	}
	
	inline function _expand(oldSize:Int)
	{
		var newSize = oldSize << 1;
		
		#if flash10
		#if alchemy
		_next.resize(newSize);
		#else
		var tmp = new Vector<Int>(newSize);
		for (i in 0...oldSize) tmp[i] = _next[i];
		_next = tmp;
		#end
		#else
		var tmp:Array<Int> = ArrayUtil.alloc(newSize);
		ArrayUtil.copy(_next, tmp, 0, oldSize);
		_next = tmp;
		#end
		
		for (i in oldSize - 1...newSize - 1) __setNext(i, i + 1);
		__setNext(newSize - 1, IntIntHashTable.NULL_POINTER);
		_free = oldSize;
		
		var tmp:Array<T> = ArrayUtil.alloc(newSize);
		ArrayUtil.copy(_vals, tmp, 0, oldSize);
		_vals = tmp;
		
		_sizeLevel++;
	}
	
	inline function _shrink()
	{
		_sizeLevel--;
		
		var oldSize = getCapacity() << 1;
		var newSize = getCapacity();
		
		#if flash10
		#if alchemy
		_next.resize(newSize);
		#else
		_next = new Vector<Int>(newSize);
		#end
		#else
		_next = ArrayUtil.alloc(newSize);
		#end
		
		for (i in 0...newSize - 1) __setNext(i, i + 1);
		__setNext(newSize - 1, IntIntHashTable.NULL_POINTER);
		_free = 0;
		
		var tmpVals:Array<T> = ArrayUtil.alloc(newSize);
		
		for (i in _h)
		{
			tmpVals[_free] = _vals[i];
			_free = __getNext(_free);
		}
		
		_vals = tmpVals;
		
		for (i in 0..._free)
			_h.remap(__key(_vals[i]), i);
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
	
	inline function __key(x:Hashable)
	{
		#if debug
		assert(x != null, "element is null");
		#end
		
		return x.key;
	}
}

#if doc
private
#end
class HashSetIterator<T> implements de.polygonal.ds.Itr<T>
{
	var _f:HashSetFriend<T>;
	
	var _vals:Array<T>;
	
	var _i:Int;
	var _s:Int;
	
	public function new(f:HashSetFriend<T>)
	{
		_f = f;
		reset();
	}
	
	inline public function reset():Itr<T>
	{
		_vals = __vals(_f);
		_i = -1;
		_s = _f._h.getCapacity();
		return this;
	}
	
	inline public function hasNext():Bool
	{
		while (++_i < _s)
		{
			if (_vals[_i] != null)
				return true;
		}
		return false;
	}
	
	inline public function next():T
	{
		return _vals[_i];
	}
	
	inline public function remove()
	{
		throw "unsupported operation";
	}
	
	inline function __vals(f:HashSetFriend<T>)
	{
		return f._vals;
	}
}