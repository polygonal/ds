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

private typedef HashTableFriend<K, T> =
{
	private var _h:IntIntHashTable;
	private var _keys:Array<K>;
	private var _vals:Array<T>;
}

/**
 * <p>An array hash table for mapping <em>Hashable</em> keys to generic elements.</p>
 * <p>The implementation is based on <em>IntIntHashTable</em>.</p>
 * <p><o>Worst-case running time in Big O notation</o></p>
 */
class HashTable<K:Hashable, T> implements Map<K, T>
{
	/**
	 * A unique identifier for this object.<br/>
	 * A hash table transforms this key into an index of an array element by using a hash function.<br/>
	 * <warn>This value should never be changed by the user.</warn>
	 */
	public var key:Int;
	
	/**
	 * If true, reuses the iterator object instead of allocating a new one when calling <code>iterator()</code>.<br/>
	 * The default is false.<br/>
	 * <warn>If true, nested iterations are likely to fail as only one iteration is allowed at a time.</warn>
	 */
	public var reuseIterator:Bool;
	
	var _h:IntIntHashTable;
	
	var _keys:Array<K>;
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
	var _iterator:HashTableValIterator<K, T>;
	
	var _tmpArr:Array<Int>;
	
	/**
	 * @param slotCount the total number of slots into which the hashed keys are distributed.
	 * This defines the space-time trade off of the hash table.
	 * Increasing the <code>slotCount</code> reduces the computation time (read/write/access) of the hash table at the cost of increased memory use.
	 * This value is fixed and can only be changed by calling <em>rehash()</em>, which rebuilds the hash table (expensive).
	 * 
	 * @param capacity the initial physical space for storing the key/value pairs at the time the hash table is created.
	 * This is also the minimum allowed size of the hash table and cannot be changed in the future. If omitted, the initial <em>capacity</em> equals <code>slotCount</code>.
	 * The <em>capacity</em> is automatically adjusted according to the storage requirements based on two rules:
	 * <ol>
	 * <li>If the hash table runs out of space, the <em>capacity</em> is doubled (if <code>isResizable</code> is true).</li>
	 * <li>If the size falls below a quarter of the current <em>capacity</em>, the <em>capacity</em> is cut in half while the minimum <em>capacity</em> can't fall below <code>capacity</code>.</li>
	 * </ol>
	 * 
	 * @param isResizable if false, the hash table is treated as fixed size table.
	 * Thus adding a value when <em>size()</em> equals <em>capacity</em> throws an error.
	 * Otherwise the <em>capacity</em> is automatically adjusted.
	 * Default is true.
	 * 
	 * @param maxSize the maximum allowed size of this hash table.
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
		
		_h = new IntIntHashTable(slotCount, capacity, isResizable, maxSize);
		_keys = ArrayUtil.alloc(capacity);
		_vals = ArrayUtil.alloc(capacity);
		
		#if flash10
		#if alchemy
		_next = new IntMemory(capacity, "HashTable._next");
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
		_tmpArr = [];
		
		key = HashKey.next();
		reuseIterator = false;
	}
	
	/**
	 * The load factor measure the "denseness" of a hash table and is proportional to the time cost to look up an entry.<br/>
	 * E.g. assuming that the keys are perfectly distributed, a load factor of 4.0 indicates that each slot stores 4 keys, which have to be sequentially searched in order to find a value.<br/>
	 * A high load factor thus indicates poor performance.
	 * If the load factor gets too high, additional slots can be allocated by calling <em>rehash()</em>.
	 */
	inline public function getLoadFactor():Float
	{
		return _h.getLoadFactor();
	}
	
	/**
	 * The total number of allocated slots. 
	 */
	inline public function getSlotCount():Int
	{
		return _h.getSlotCount();
	}
	
	/**
	 * The size of the allocated storage space for the key/value pairs.<br/>
	 * If more space is required to accomodate new elements, the <em>capacity</em> is doubled every time <em>size()</em> grows beyond <em>capacity</em>, and split in half when <em>size()</em> is a quarter of <em>capacity</em>.
	 * The <em>capacity</em> never falls below the initial size defined in the constructor.
	 */
	inline public function getCapacity():Int
	{
		return _h.getCapacity();
	}
	
	/**
	 * Counts the total number of collisions.<br/>
	 * A collision occurs when two distinct keys are hashed into the same slot.
	 */
	public function getCollisionCount():Int
	{
		return _h.getCollisionCount();
	}
	
	/**
	 * Returns the value that is mapped to <code>key</code> or null if <code>key</code> does not exist.<br/>
	 * Uses move-to-front-on-access which reduces access time when similar keys are frequently queried.
	 * <o>n</o>
	 * @throws de.polygonal.ds.error.AssertError <code>key</code> is null (debug only).
	 */
	inline public function getFront(key:K):T
	{
		var i = _h.getFront(__key(key));
		if (i == IntIntHashTable.KEY_ABSENT)
			return null;
		else
			return _vals[i];
	}
	
	/**
	 * Maps <code>val</code> to <code>key</code> in this map, but only if <code>key</code> does not exist yet.<br/>
	 * <o>n</o>
	 * @return true if <code>key</code> was mapped to <code>val</code> for the first time.
	 * @throws de.polygonal.ds.error.AssertError out of space - hash table is full but not resizable.
	 * @throws de.polygonal.ds.error.AssertError <code>key</code> is null (debug only).
	 * @throws de.polygonal.ds.error.AssertError <em>size()</em> equals <em>maxSize</em> (debug only).
	 */
	inline public function setIfAbsent(key:K, val:T):Bool
	{
		if ((size() == getCapacity()))
		{
			if (_h.setIfAbsent(__key(key), size()))
			{
				_expand(getCapacity() >> 1);
				
				_vals[_free] = val;
				_keys[_free] = key;
				_free = __getNext(_free);
				return true;
			}
			else
				return false;
		}
		else
		{
			if (_h.setIfAbsent(__key(key), _free))
			{
				_vals[_free] = val;
				_keys[_free] = key;
				_free = __getNext(_free);
				return true;
			}
			else
				return false;
		}
	}
	
	/**
	 * Redistributes all keys over <code>slotCount</code>.<br/>
	 * This is an expensive operations as the hash table is rebuild from scratch.
	 * <o>n</o>
	 * @throws de.polygonal.ds.error.AssertError <code>slotCount</code> is not a power of two (debug only).
	 */
	public function rehash(slotCount:Int)
	{
		_h.rehash(slotCount);
	}
	
	/**
	 * Remaps the first occurrence of <code>key</code> to a new value <code>val</code>.
	 * <o>n</o>
	 * @return true if <code>val</code> was successfully remapped to <code>key</code>.
	 * @throws de.polygonal.ds.error.AssertError <code>key</code> is null (debug only).
	 */
	inline public function remap(key:K, val:T):Bool
	{
		var i = _h.get(__key(key));
		if (i != IntIntHashTable.KEY_ABSENT)
		{
			_vals[i] = val;
			return true;
		}
		else
			return false;
	}
	
	/**
	 * Creates and returns an unordered array of all keys.
	 * <o>n</o>
	 */
	public function toKeyArray():Array<K>
	{
		var a:Array<K> = ArrayUtil.alloc(size());
		var j = 0;
		for (i in 0...getCapacity())
		{
			if (_keys[i] != null)
				a[j++] = _keys[i];
		}
		return a;
	}
	
	/**
	 * Creates and returns an unordered dense array of all keys.
	 * <o>n</o>
	 */
	public function toKeyDA():DA<K>
	{
		var a = new DA<K>(size());
		for (i in 0...getCapacity())
		{
			if (_keys[i] != null)
				a.pushBack(_keys[i]);
		}
		return a;
	}
	
	/**
	 * For performance reasons the hash table does nothing to ensure that empty locations contain null.<br/>
	 * <em>pack()</em> therefore nullifies all obsolete references.
	 * <o>n</o>
	 */
	public function pack()
	{
		for (i in 0...getCapacity())
			if (_keys[i] != null) _vals[i] = cast null;
	}
	
	/**
	 * Returns a string representing the current object.<br/>
	 * Example:<br/>
	 * <pre class="prettyprint">
	 * class Foo extends de.polygonal.ds.HashableItem
	 * {
	 *     var value:Int;
	 *     
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
	 *     static function main() {
	 *         var hash = new de.polygonal.ds.HashTable&lt;Foo, String&gt;(16);
	 *         for (i in 0...4) hash.set(new Foo(i), "foo"  + i);
	 *         trace(hash);
	 *     }
	 * }</pre>
	 * <pre class="console">
	 * { HashTable size/capacity: 4/16, load factor: 0.25 }
	 * [
	 *   {Foo value: 0} -> foo0
	 *   {Foo value: 1} -> foo1
	 *   {Foo value: 2} -> foo2
	 *   {Foo value: 3} -> foo3
	 * ]</pre>
	 */
	public function toString():String
	{
		var s = Printf.format("{ HashTable size/capacity: %d/%d, load factor: %.2f }", [size(), getCapacity(), getLoadFactor()]);
		if (isEmpty()) return s;
		s += "\n[\n";
		
		var max = 0;
		for (key in keys()) max = M.max(max, Std.string(key).length);
		
		for (key in keys())
			s += Printf.format("  %- " + max + "s -> %s\n", [key, Std.string(get(key))]);
		
		s += "]";
		return s;
	}
	
	/*///////////////////////////////////////////////////////
	// map
	///////////////////////////////////////////////////////*/
	
	/**
	 * Returns true if this map contains a mapping for the value <code>val</code>.
	 * <o>n</o>
	 */
	inline public function has(val:T):Bool
	{
		var exists = false;
		for (i in 0...getCapacity())
		{
			if (_keys[i] != null)
			{
				if (_vals[i] == val)
				{
					exists = true;
					break;
				}
			}
		}
		return exists;
	}
	
	/**
	 * Returns true if this map contains <code>key</code>.
	 * <o>n</o>
	 * @throws de.polygonal.ds.error.AssertError <code>key</code> is null (debug only).
	 */
	inline public function hasKey(key:K):Bool
	{
		return _h.hasKey(__key(key));
	}
	
	/**
	 * Returns the value that is mapped to <code>key</code> or null if <code>key</code> does not exist.
	 * <o>n</o>
	 * @throws de.polygonal.ds.error.AssertError <code>key</code> is null (debug only).
	 */
	inline public function get(key:K):T
	{
		#if debug
		assert(key != null, "key != null");
		#end
		
		var i = _h.get(__key(key));
		if (i == IntIntHashTable.KEY_ABSENT)
			return null;
		else
			return _vals[i];
	}
	
	/**
	 * Stores all values that are mapped to <code>key</code> in <code>values</code> or returns 0 if <code>key</code> does not exist.
	 * @return the total number of values mapped to <code>key</code>.
	 */
	public function getAll(key:K, values:Array<T>):Int
	{
		var i = _h.get(__key(key));
		if (i == IntIntHashTable.KEY_ABSENT)
			return 0;
		else
		{
			var c = _h.getAll(__key(key), _tmpArr);
			for (i in 0...c) values[i] = _vals[_tmpArr[i]];
			return c;
		}
	}
	
	/**
	 * Maps the value <code>val</code> to <code>key</code>.<br/>
	 * The method allows duplicate keys.<br/>
	 * <warn>To ensure unique keys either use <em>hasKey()</em> before <em>set()</em> or <em>setIfAbsent()</em></warn>
	 * <o>n</o>
	 * @return true if <code>key</code> was added for the first time, false if another instance of <code>key</code> was inserted.
	 * @throws de.polygonal.ds.error.AssertError out of space - hash table is full but not resizable.
	 * @throws de.polygonal.ds.error.AssertError <code>key</code> is null (debug only).
	 * @throws de.polygonal.ds.error.AssertError <em>size()</em> equals <em>maxSize</em> (debug only).
	 */
	inline public function set(key:K, val:T):Bool
	{
		if (size() == getCapacity())
		{
			_expand(getCapacity());
		}
		
		var first = _h.set(__key(key), _free);
		_vals[_free] = val;
		_keys[_free] = key;
		
		_free = __getNext(_free);
		return first;
	}
	
	/**
	 * Removes and nullifies the first occurrence of <code>key</code>.</br>
	 * Only the key is nullified, to nullifiy the value call <em>pack()</em>.
	 * <o>n</o>
	 * @return true if <code>key</code> is successfully removed.
	 * @throws de.polygonal.ds.error.AssertError <code>key</code> is null (debug only).
	 */
	inline public function clr(key:K):Bool
	{
		var i = _h.get(__key(key));
		if (i == IntIntHashTable.KEY_ABSENT)
			return false;
		else
		{
			_keys[i] = null;
			__setNext(i, _free);
			_free = i;
			
			var shrink = false;
			
			if (_sizeLevel > 0)
				if (size() - 1 == (getCapacity() >> 2))
					if (_isResizable)
						shrink = true;
			
			_h.clr(__key(key));
			
			if (shrink) _shrink();
			
			return true;
		}
	}
	
	/**
	 * Creates a <em>ListSet</em> object of the values in this map.
	 * <o>n</o>
	 */
	public function toValSet():Set<T>
	{
		var s = new ListSet<T>();
		for (i in 0...getCapacity())
		{
			if (_keys[i] != null)
				s.set(_vals[i]);
		}
		
		return s;
	}
	
	/**
	 * Creates a <em>ListSet</em> object of the keys in this map.
	 * <o>n</o>
	 */
	public function toKeySet():Set<K>
	{
		var s = new ListSet<K>();
		for (i in 0...getCapacity())
		{
			if (_keys[i] != null)
				s.set(_keys[i]);
		}
		
		return s;
	}
	
	/**
	 * Returns a new <em>HashTableKeyIterator</em> object to iterate over all keys stored in this map.
	 * The keys are visited in a random order.
	 * <o>n</o>
	 * @see <a href="http://haxe.org/ref/iterators" target="_blank">http://haxe.org/ref/iterators</a>
	 */
	public function keys():Itr<K>
	{
		return new HashTableKeyIterator(this);
	}
	
	/*///////////////////////////////////////////////////////
	// collection
	///////////////////////////////////////////////////////*/
	
	/**
	 * Destroys this object by explicitly nullifying all key/values.<br/>
	 * <warn>If "alchemy memory" is used, always call this method when the life cycle of this object ends to prevent a memory leak.</warn>
	 * <o>n</o>
	 */
	public function free()
	{
		for (i in 0...size())
		{
			_vals[i] = cast null;
			_keys[i] = null;
		}
		_vals = null;
		_keys = null;
		
		#if (flash10 && alchemy)
		_next.free();
		#end
		_next = null;
		
		_h.free();
		_h = null;
		_iterator = null;
		_tmpArr = null;
	}
	
	/**
	 * Same as <em>has()</em>.
	 * <o>n</o>
	 */
	public function contains(val:T):Bool
	{
		return has(val);
	}
	
	/**
	 * Removes all occurrences of the value <code>val</code>.
	 * <o>n</o>
	 * @return true if <code>val</code> was removed, false if <code>val</code> does not exist.
	 */
	public function remove(val:T):Bool
	{
		var found = false;
		var tmp = new Array<K>();
		for (i in 0...getCapacity())
		{
			if (_keys[i] != null)
			{
				if (_vals[i] == val)
				{
					tmp.push(_keys[i]);
					found = true;
				}
			}
		}
		
		if (found)
		{
			for (key in tmp) clr(key);
			return true;
		}
		else
			return false;
	}
	
	/**
	 * Removes all key/value pairs.<br/>
	 * <o>n</o>
	 * @param purge if true, nullifies all keys and values and shrinks the hash table to the initial capacity defined in the constructor.
	 */
	public function clear(purge = false)
	{
		_h.clear(purge);
		for (i in 0...getCapacity()) _keys[i] = null;
		
		if (purge)
		{
			for (i in 0...getCapacity())
			{
				_vals[i] = cast null;
				_keys[i] = null;
			}
			
			while (_sizeLevel > 0) _shrink();
		}
		
		for (i in 0...getCapacity() - 1) __setNext(i, i + 1);
		__setNext(getCapacity() - 1, IntIntHashTable.NULL_POINTER);
		_free = 0;
	}
	
	/**
	 * Returns a new <em>HashTableValIterator</em> object to iterate over all values contained in this hash table.<br/>
	 * The values are visited in a random order.
	 * @see <a href="http://haxe.org/ref/iterators" target="_blank">http://haxe.org/ref/iterators</a>
	 */
	public function iterator():Itr<T>
	{
		if (reuseIterator)
		{
			if (_iterator == null)
				_iterator = new HashTableValIterator<K, T>(this);
			else
				_iterator.reset();
			return _iterator;
		}
		else
			return new HashTableValIterator<K, T>(this);
	}
	
	/**
	 * Returns true if this hash table is empty.
	 * <o>1</o>
	 */
	inline public function isEmpty():Bool
	{
		return _h.isEmpty();
	}
	
	/**
	 * The total number of key/value pairs.
	 * <o>1</o>
	 */
	inline public function size():Int
	{
		return _h.size();
	}
	
	/**
	 * Returns an unordered array containing all values in this hash table. 
	 */
	public function toArray():Array<T>
	{
		var a:Array<T> = ArrayUtil.alloc(size());
		var j = 0;
		for (i in 0...getCapacity())
		{
			if (_keys[i] != null)
				a[j++] = _vals[i];
		}
		return a;
	}
	
	#if flash10
	/**
	 * Returns a Vector.&lt;T&gt; object containing all values in this hash table.
	 */
	public function toVector():flash.Vector<Dynamic>
	{
		var a = new flash.Vector<Dynamic>(size());
		var j = 0;
		for (i in 0...getCapacity())
		{
			if (_keys[i] != null)
				a[j++] = _vals[i];
		}
		return a;
	}
	#end
	
	/**
	 * Duplicates this hash table. Supports shallow (structure only) and deep copies (structure & elements).
	 * @param assign if true, the <code>copier</code> parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.<br/>
	 * If false, the <em>clone()</em> method is called on each element. <warn>In this case all elements have to implement <em>Cloneable</em>.</warn>
	 * @param copier a custom function for copying elements. Replaces element.<em>clone()</em> if <code>assign</code> is false.
	 * @throws de.polygonal.ds.error.AssertError element is not of type <em>Cloneable</em> (debug only).
	 */
	public function clone(assign = true, copier:T->T = null):Collection<T>
	{
		var c:HashTable<K, T> = Type.createEmptyInstance(HashTable);
		
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
					if (_keys[i] != null)
						tmp[i] = copier(_vals[i]);
				}
			}
			else
			{
				var c:Cloneable<T> = null;
				for (i in 0...getCapacity())
				{
					if (_keys[i] != null)
					{
						#if debug
						assert(Std.is(_vals[i], Cloneable), 'element is not of type Cloneable (${_vals[i]})');
						#end
						
						c = untyped _vals[i];
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
		
		c._keys = new Array<K>();
		ArrayUtil.copy(_keys, c._keys);
		
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
		
		var tmp:Array<K> = ArrayUtil.alloc(newSize);
		ArrayUtil.copy(_keys, tmp, 0, oldSize);
		_keys = tmp;
		
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
		
		var tmpKeys:Array<K> = ArrayUtil.alloc(newSize);
		var tmpVals:Array<T> = ArrayUtil.alloc(newSize);
		
		for (i in _h)
		{
			tmpKeys[_free] = _keys[i];
			tmpVals[_free] = _vals[i];
			_free = __getNext(_free);
		}
		
		_keys = tmpKeys;
		_vals = tmpVals;
		
		for (i in 0..._free)
			_h.remap(__key(_keys[i]), i);
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
		assert(x != null, "key is null");
		#end
		
		return x.key;
	}
}

#if doc
private
#end
class HashTableKeyIterator<K, T> implements de.polygonal.ds.Itr<K>
{
	var _f:HashTableFriend<K, T>;
	
	var _keys:Array<K>;
	
	var _i:Int;
	var _s:Int;
	
	public function new(f:HashTableFriend<K, T>)
	{
		_f = f;
		reset();
	}
	
	inline public function reset():Itr<K>
	{
		_keys = __keys(_f);
		_i = -1;
		_s = _f._h.getCapacity();
		return this;
	}
	
	inline public function hasNext():Bool
	{
		while (++_i < _s)
		{
			if (_keys[_i] != null)
				return true;
		}
		return false;
	}

	inline public function next():K
	{
		return _keys[_i];
	}
	
	inline public function remove()
	{
		throw "unsupported operation";
	}
	
	inline function __vals(f:HashTableFriend<K, T>)
	{
		return f._vals;
	}
	inline function __keys(f:HashTableFriend<K, T>)
	{
		return f._keys;
	}
}

#if doc
private
#end
class HashTableValIterator<K, T> implements de.polygonal.ds.Itr<T>
{
	var _f:HashTableFriend<K, T>;
	
	var _keys:Array<K>;
	var _vals:Array<T>;
	
	var _i:Int;
	var _s:Int;
	
	public function new(f:HashTableFriend<K, T>)
	{
		_f = f;
		reset();
	}
	
	inline public function reset():Itr<T>
	{
		_vals = __vals(_f);
		_keys = __keys(_f);
		_i = -1;
		_s = _f._h.getCapacity();
		return this;
	}
	
	inline public function hasNext():Bool
	{
		while (++_i < _s)
		{
			if (_keys[_i] != null)
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
	
	inline function __vals(f:HashTableFriend<K, T>)
	{
		return f._vals;
	}
	inline function __keys(f:HashTableFriend<K, T>)
	{
		return f._keys;
	}
}