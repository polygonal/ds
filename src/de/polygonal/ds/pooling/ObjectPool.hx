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
package de.polygonal.ds.pooling;

import de.polygonal.ds.error.Assert.assert;
import de.polygonal.ds.Hashable;
import de.polygonal.ds.HashKey;
import de.polygonal.ds.Itr;

private typedef ObjectPoolFriend<T> =
{
	private var _pool:Array<T>;
	private var _size:Int;
}

/**
 *<p>A fixed sized, arrayed object pool.</p>
 */
class ObjectPool<T> implements Hashable
{
	/**
	 * A unique identifier for this object.<br/>
	 * A hash table transforms this key into an index of an array element by using a hash function.<br/>
	 * <warn>This value should never be changed by the user.</warn>
	 */
	public var key:Int;
	
	#if flash10
	#if alchemy
	var _next:de.polygonal.ds.mem.IntMemory;
	#else
	var _next:flash.Vector<Int>;
	#end
	#else
	var _next:Array<Int>;
	#end
	
	var _pool:Array<T>;
	var _size:Int;
	var _free:Int;
	
	var _lazy:Bool;
	var _lazyConstructor:Void->T;
	
	#if debug
	var _usage:de.polygonal.ds.BitVector;
	var _count:Int;
	#end
	
	/** 
	 * Creates an <em>ObjectPool</em> object capable of managing <code>x</code> pre-allocated objects.<br/>
	 * Use <em>allocate()</em> to fill the pool.
	 */
	public function new(x:Int)
	{
		_size = x;
		_free = -1;
		
		key = HashKey.next();
		
		#if debug
		_count = 0;
		#end
	}
	
	/**
	 * Destroys this object by explicitly nullifying all objects for GC'ing used resources.<br/>
	 * Improves GC efficiency/performance (optional).
	 */
	public function free()
	{
		if (_pool == null) return;
		
		for (i in 0..._size)
			_pool[i] = null;
		_pool = null;
		
		#if (flash10 && alchemy)
		_next.free();
		#end
		
		_next = null;
		_lazyConstructor = null;
		
		#if debug
		if (_usage != null)
		{
			_usage.free();
			_usage = null;
		}
		#end
	}
	
	/**
	 * Returns true if all objects are in use. 
	 */
	inline public function isEmpty():Bool
	{
		return _free == -1;
	}
	
	/**
	 * The total number of pre-allocated objects in the pool. 
	 */
	inline public function size():Int
	{
		return _size;
	}
	
	/**
	 * The total number of objects in use. 
	 */
	public function countUsedObjects():Int
	{
		return size() - countUnusedObjects();
	}
	
	/**
	 * The total number of available objects. 
	 */
	public function countUnusedObjects():Int
	{
		var c = 0;
		var i = _free;
		while (i != -1)
		{
			i = __getNext(i);
			c++;
		}
		
		return c;
	}
	
	/** 
	 * Returns the id to the next free object.<br/>
	 * After an id has been obtained, the corresponding object can be retrieved using <em>get(id)</em>.
	 * @throws de.polygonal.ds.error.AssertError pool exhausted (debug only).
	 */
	inline public function next():Int
	{
		#if debug
		assert(_count < _size && _free != -1, "pool exhausted");
		++_count;
		#end
		
		var id = _free;
		_free = __getNext(id);
		
		#if debug
		_usage.set(id);
		#end
		
		return id;
	}
	
	/**
	 * Returns the object that is mapped to <code>id</code>.<br/>
	 * Call <em>next()</em> to request an <code>id</code> first.
	 * @throws de.polygonal.ds.error.AssertError invalid <code>id</code> or object linked to <code>id</code> is not used.
	 */
	inline public function get(id:Int):T
	{
		#if debug
		assert(_usage.has(id), 'id $id is not used');
		#end
		
		if (_lazy)
		{
			if (_pool[id] == null)
				_pool[id] = _lazyConstructor();
		}
		
		return _pool[id];
	}
	
	/**
	 * Puts the object mapped to <code>id</code> back into the pool.
	 * @throws de.polygonal.ds.error.AssertError pool is full or object linked to <code>id</code> is not used (debug only).
	 */
	inline public function put(id:Int)
	{
		#if debug
		assert(_usage.has(id), 'id $id is not used');
		assert(_count > 0, "pool is full");
		_usage.clr(id);
		--_count;
		#end
		
		__setNext(id, _free);
		_free = id;
	}
	
	/**
	 * Allocates the pool.
	 * @param lazy if true, objects are allocated on-the-fly until the pool is full.
	 * @param C allocates objects by instantiating the class <code>C</code>.
	 * @param fabricate allocates objects by calling <code>fabricate()</code>.
	 * @param factory allocates objects by using a <em>Factory</em> object (calling <code>factory</code>.<em>create()</em>).
	 * @throws de.polygonal.ds.error.AssertError invalid arguments.
	 */
	public function allocate(lazy:Bool, C:Class<T> = null, fabricate:Void->T = null, factory:Factory<T> = null)
	{
		_lazy = lazy;
		
		#if flash10
		#if alchemy
		_next = new de.polygonal.ds.mem.IntMemory(_size, "ObjectPool._next");
		#else
		_next = new flash.Vector<Int>(_size);
		#end
		#else
		_next = de.polygonal.ds.ArrayUtil.alloc(_size);
		#end
		
		for (i in 0..._size - 1) __setNext(i, i + 1);
		__setNext(_size - 1, -1);
		_free = 0;
		_pool = de.polygonal.ds.ArrayUtil.alloc(_size);
		
		#if debug
		assert(C != null || fabricate != null || factory != null, "invalid arguments");
		#end
		
		if (_lazy)
		{
			if (C != null)
				_lazyConstructor = function() return Type.createInstance(C, []);
			else
			if (fabricate != null)
				_lazyConstructor = function() return fabricate();
			else
			if (factory != null)
				_lazyConstructor = function() return factory.create();
		}
		else
		{
			if (C != null)
				for (i in 0..._size) _pool[i] = Type.createInstance(C, []);
			else
			if (fabricate != null)
				for (i in 0..._size) _pool[i] = fabricate();
			else
			if (factory != null)
				for (i in 0..._size) _pool[i] = factory.create();
		}
		
		#if debug
		_usage = new de.polygonal.ds.BitVector(_size);
		#end
	}
	
	/**
	 * Returns a new <em>ObjectPoolIterator</em> object to iterate over all pooled objects, regardless if an object is used or not.<br/>
	 * @see <a href="http://haxe.org/ref/iterators" target="_blank">http://haxe.org/ref/iterators</a>
	 */
	public function iterator():Itr<T>
	{
		return new ObjectPoolIterator<T>(this);
	}
	
	/**
	 * Returns a string representing the current object.<br/>
	 * Prints out all object if compiled with the <em>-debug</em> directive.<br/>
	 */
	public function toString():String
	{
		#if debug
		var s = '{ ObjectPool used/total: $_count/$_size }';
		if (size() == 0) return s;
		s += "\n[\n";
		
		for (i in 0...size())
		{
			var t = Std.string(_pool[i]);
			s += Printf.format("  %4d -> {%s}\n", [i, t]);
		}
		s += "]";
		return s;
		#else
		return '{ ObjectPool used/total: ${countUsedObjects()}/$_size }';
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
}

#if doc
private
#end
#if generic
@:generic
#end
class ObjectPoolIterator<T> implements de.polygonal.ds.Itr<T>
{
	var _f:ObjectPoolFriend<T>;
	var _a:Array<T>;
	var _s:Int;
	var _i:Int;
	
	public function new(f:ObjectPoolFriend<T>)
	{
		_f = f;
		reset();
	}

	inline public function reset():Itr<T>
	{
		_a = __pool(_f);
		_s = __size(_f);
		_i = 0;
		return this;
	}
	
	inline public function hasNext():Bool
	{
		return _a != null && _i < _s;
	}
	
	inline public function next():T
	{
		return _a[_i++];
	}
	
	inline public function remove()
	{
		throw "unsupported operation";
	}
	
	inline function __pool<T>(f:ObjectPoolFriend<T>)
	{
		return _f._pool;
	}
	inline function __size<T>(f:ObjectPoolFriend<T>)
	{
		return f._size;
	}
}