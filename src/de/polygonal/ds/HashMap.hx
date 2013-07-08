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

#if !flash
"The HashMap class is only available for flash9+"
#end

private typedef HashMapFriend<K, T> =
{
	private var _map:flash.utils.Dictionary;
}

/**
 * <p>A hash using flash.utils.Dictionary (<b>Flash only</b>).</p>
 * <ul>
 * <li>Each key can only map a <b>single value</b>.</li>
 * <li><em>null</em> keys and <em>null</em> values are not allowed.</li>
 * </ul>
 * <p><o>Worst-case running time in Big O notation</o></p>
 */
class HashMap<K, T> implements Map<K, T>
{
	/**
	 * A unique identifier for this object.<br/>
	 * A hash table transforms this key into an index of an array element by using a hash function.<br/>
	 * <warn>This value should never be changed by the user.</warn>
	 */
	public var key:Int;
	
	/**
	 * The maximum allowed size of this hash map.<br/>
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
	
	var _map:flash.utils.Dictionary;
	var _weak:Bool;
	var _size:Int;
	var _iterator:HashMapValIterator<K, T>;
	
	/**
	 * @param weak if true, weak keys are used. A key/value pair is lost when no other object
	 * besides this object holds a reference to the key. Default is false.
	 * 
	 * @param maxSize the maximum allowed size of the stack.
	 * The default value of -1 indicates that there is no upper limit.
	 */
	public function new(weak = false, maxSize = -1)
	{
		_map          = new flash.utils.Dictionary(_weak = weak);
		_size         = 0;
		_iterator     = null;
		key           = HashKey.next();
		reuseIterator = false;
		
		#if debug
		this.maxSize = (maxSize == -1) ? M.INT32_MAX : maxSize;
		#else
		this.maxSize = -1;
		#end
	}
	
	/**
	 * Remaps an existing <code>key</code> to a new <code>val</code>.
	 * <o>1</o>
	 * @return true if <code>key</code> was successfully remapped to <code>val</code>.
	 * @throws de.polygonal.ds.error.AssertError <code>key</code>/<code>val</code> is null (debug only).
	 */
	inline public function remap(key:K, val:T):Bool
	{
		#if debug
		var x:Null<K> = key;
		assert(x != null, "null keys are not allowed");
		#end
		
		var x:Null<T> = untyped _map[key];
		if (x != null)
		{
			#if debug
			x = val;
			assert(x != null, "null values are not allowed");
			#end
			
			untyped _map[key] = val;
			return true;
		}
		else
			return false;
	}
	
	/**
	 * Returns an array of all keys.
	 * <o>n</o>
	 */
	public function toKeyArray():Array<K>
	{
		return untyped __keys__(_map);
	}
	
	/**
	 * Returns a dense array of all keys.
	 * <o>n</o>
	 */
	public function toKeyDA():DA<K>
	{
		return ArrayConvert.toDA(toKeyArray());
	}
	
	/**
	 * Returns a string representing the current object.<br/>
	 * Example:<br/>
	 * <pre class="prettyprint">
	 * var hm = new de.polygonal.ds.HashMap&lt;String, String&gt;();
	 * hm.set("key1", "val1");
	 * hm.set("key2", "val2");
	 * trace(hm);</pre>
	 * <pre class="console">
	 * {HashMap, size: 2}
	 * [
	 *   key1 -> val1
	 *   key2 -> val2
	 * ]</pre>
	 */
	public function toString():String
	{
		var s = '{ HashMap size: ${size()} }';
		if (isEmpty()) return s;
		s += "\n[\n";
		for (key in keys())
			s += '  ${Std.string(key)} -> ${Std.string(get(key))}\n';
		s += "]";
		return s;
	}
	
	/*///////////////////////////////////////////////////////
	// map
	///////////////////////////////////////////////////////*/
	
	/**
	 * Returns true if this map contains a mapping for <code>val</code>.
	 * <o>n</o>
	 * @throws de.polygonal.ds.error.AssertError <code>val</code> is null (debug only).
	 */
	inline public function has(val:T):Bool
	{
		#if debug
		var x:Null<T> = val;
		assert(x != null, "null values are not allowed");
		#end
		
		var exists = false;
		var a:Array<K> = untyped __keys__(_map);
		for (i in a)
		{
			if (untyped _map[i] == val)
			{
				exists = true;
				break;
			}
		}
		return exists;
	}
	
	/**
	 * Returns true if this map contains the key <code>key</code>.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError <code>key</code> is null (debug only).
	 */
	inline public function hasKey(key:K):Bool
	{
		#if debug
		var x:Null<K> = key;
		assert(x != null, "null keys are not allowed");
		#end
		
		var x:Null<T> = untyped _map[key];
		return x != null;
	}
	
	/**
	 * Returns the value that is mapped to <code>key</code> or null if <code>key</code> does not exist.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError <code>key</code> is null (debug only).
	 */
	inline public function get(key:K):T
	{
		#if debug
		var x:Null<K> = key;
		assert(x != null, "null keys are not allowed");
		#end
		
		return untyped _map[key];
	}
	
	/**
	 * Maps <code>val</code> to <code>key</code>.
	 * <o>1</o>
	 * @return true if <code>key</code> was added, false if <code>key</code> already exists.
	 * @throws de.polygonal.ds.error.AssertError <em>size()</em> equals <em>maxSize</em> (debug only).
	 * @throws de.polygonal.ds.error.AssertError <code>key</code>/<code>val</code> is null (debug only).
	 */
	inline public function set(key:K, val:T):Bool
	{
		#if debug
		var x:Null<K> = key;
		assert(x != null, "null keys are not allowed");
		var x:Null<T> = val;
		assert(x != null, "null values are not allowed");
		#end
		
		if (hasKey(key))
			return false;
		else
		{
			#if debug
			assert(size() < maxSize, 'size equals max size ($maxSize)');
			#end
			
			untyped _map[key] = val;
			_size++;
			return true;
		}
	}
	
	/**
	 * Removes <code>key</code> and the value that is mapped to it.
	 * <o>1</o>
	 * @return true if <code>key</code> is successfully removed, false if <code>key</code> does not exist.
	 * @throws de.polygonal.ds.error.AssertError <code>key</code> is null (debug only).
	 */
	inline public function clr(key:K):Bool
	{
		#if debug
		var x:Null<K> = key;
		assert(x != null, "null keys are not allowed");
		#end
		
		if (untyped _map[key] != null)
		{
			untyped __delete__(_map, key);
			_size--;
			return true;
		}
		else
			return false;
	}
	
	/**
	 * Returns a set view of the mappings contained in this map.
	 * <o>n</o>
	 */
	public function toValSet():Set<T>
	{
		var s = new ListSet<T>();
		var a:Array<K> = untyped __keys__(_map);
		for (key in a) s.set(untyped _map[key]);
		return s;
	}
	
	/**
	 * Returns a set view of the keys contained in this map.
	 * <o>n</o>
	 */
	public function toKeySet():Set<K>
	{
		var s = new ListSet<K>();
		var a:Array<K> = untyped __keys__(_map);
		for (key in a) s.set(key);
		return s;
	}
	
	/**
	 * Iterates over all keys.
	 */
	public function keys():Itr<K>
	{
		return new HashMapKeyIterator(this);
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
		if (!_weak)
		{
			var a:Array<K> = untyped __keys__(_map);
			for (i in a) untyped __delete__(_map, i);
		}
		_map = null;
		_iterator = null;
	}
	
	/**
	 * Same as <em>has()</em>.
	 * <o>n</o>
	 * @throws de.polygonal.ds.error.AssertError <code>x</code> is null (debug only).
	 */
	inline public function contains(x:T):Bool
	{
		return has(x);
	}
	
	/**
	 * Removes all keys that map the value <code>x</code>.
	 * <o>n</o>
	 * @return true if at least one value was removed, otherwise false.
	 * @throws de.polygonal.ds.error.AssertError <code>x</code> is null (debug only).
	 */
	public function remove(x:T):Bool
	{
		var success = false;
		if (has(x))
		{
			var a:Array<K> = untyped __keys__(_map);
			for (k in a)
			{
				if (untyped _map[k] == x)
				{
					untyped __delete__(_map, k);
					_size--;
					success = true;
				}
			}
		}
		return success;
	}
	
	/**
	 * Removes all key/value pairs.
	 * <o>n</o>
	 * @param purge if true, elements are nullified upon removal.
	 */
	inline public function clear(purge = false)
	{
		var a:Array<K> = untyped __keys__(_map);
		for (key in a) untyped __delete__(_map, key);
		_size = 0;
	}
	
	/**
	 * Returns a new <em>HashMapValIterator</em> object to iterate over all values contained in this hash map.<br/>
	 * The values are visited in a random order.
	 * @see <a href="http://haxe.org/ref/iterators" target="_blank">http://haxe.org/ref/iterators</a>
	 */
	public function iterator():Itr<T>
	{
		if (reuseIterator)
		{
			if (_iterator == null)
				_iterator = new HashMapValIterator<K, T>(this);
			else
				_iterator.reset();
			return _iterator;
		}
		else
			return new HashMapValIterator<K, T>(this);
	}
	
	/**
	 * The total number of key/value pairs.
	 * <o>1</o>
	 */
	inline public function size():Int
	{
		return _size;
	}
	
	/**
	 * Returns true if this hash map is empty.
	 * <o>1</o>
	 */
	inline public function isEmpty():Bool
	{
		return _size == 0;
	}
	
	/**
	 * Returns an unordered array containing all values in this hash map.
	 */
	public function toArray():Array<T>
	{
		var a:Array<T> = ArrayUtil.alloc(size());
		var i = 0;
		for (v in this) a[i++] = v;
		return a;
	}
	
	#if flash10
	/**
	 * Returns a Vector.&lt;T&gt; object containing all values in this hash map.
	 */
	public function toVector():flash.Vector<Dynamic>
	{
		var a = new flash.Vector<Dynamic>(size());
		var i = 0;
		for (v in this) a[i++] = v;
		return a;
	}
	#end
	
	/**
	 * Duplicates this hash map either by creating a shallow or deep copy.
	 * @param assign if true, the <code>copier</code> parameter is ignored and
	 * primitive elements are copied by value whereas objects are copied by reference.<br/>
	 * If false, element.<em>clone()</em> is used for duplicating elements.<br/>
	 * <warn>In this case all elements have to implement <em>Cloneable</em>.</warn>
	 * @param copier uses a custom function instead of element.<em>clone()</em> for copying elements if the <code>assign</code> parameter is false.
	 * @throws de.polygonal.ds.error.AssertError element is not of type <em>Cloneable</em> (debug only).
	 */
	public function clone(assign = true, copier:T->T = null):Collection<T>
	{
		var copy = new HashMap<K, T>(_weak, maxSize);
		var a:Array<K> = untyped __keys__(_map);
		if (assign)
		{
			for (key in a) copy.set(key, get(key));
		}
		else
		if (copier == null)
		{
			for (key in a)
			{
				#if debug
				assert(Std.is(get(key), Cloneable), 'key is not of type Cloneable (${get(key)})');
				#end
				
				var c:Cloneable<T> = cast get(key);
				copy.set(key, get(key));
			}
		}
		else
		{
			for (key in a)
				copy.set(key, copier(get(key)));
		}
		return copy;
	}
}

#if doc
private
#end
class HashMapKeyIterator<K, T> implements de.polygonal.ds.Itr<K>
{
	var _f:HashMap<K, T>;
	var _keys:Array<K>;
	var _i:Int;
	var _s:Int;
	
	public function new(f:HashMap<K, T>)
	{
		_f = f;
		reset();
	}
	
	inline public function reset():Itr<K>
	{
		_keys = untyped __keys__(__map(_f));
		_i = 0;
		_s = _keys.length;
		return this;
	}
	
	inline public function hasNext():Bool
	{
		return _i < _s;
	}

	inline public function next():K
	{
		return _keys[_i++];
	}
	
	inline public function remove()
	{
		#if debug
		assert(_i > 0, "call next() before removing an element");
		#end
		
		_f.clr(_keys[_i - 1]);
	}
	
	inline function __map(f:HashMapFriend<K, T>)
	{
		return f._map;
	}
}

#if doc
private
#end
class HashMapValIterator<K, T> implements de.polygonal.ds.Itr<T>
{
	var _f:HashMap<K, T>;
	var _map:flash.utils.Dictionary;
	var _keys:Array<K>;
	var _i:Int;
	var _s:Int;
	
	public function new(f:HashMap<K, T>)
	{
		_f = f;
		reset();
	}
	
	inline public function reset():Itr<T>
	{
		_map = __map(_f);
		_keys = untyped __keys__(_map);
		_i = 0;
		_s = _keys.length;
		return this;
	}
	
	inline public function hasNext():Bool
	{
		return _i < _s;
	}
	
	inline public function next():T
	{
		return untyped _map[_keys[_i++]];
	}
	
	inline public function remove()
	{
		#if debug
		assert(_i > 0, "call next() before removing an element");
		#end
		
		_f.remove(untyped _map[_keys[_i - 1]]);
	}
	
	inline function __map(f:HashMapFriend<K, T>)
	{
		return f._map;
	}
}