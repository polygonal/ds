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
import de.polygonal.ds.HashKey;
import de.polygonal.ds.Itr;

private typedef DynamicObjectPoolFriend<T> =
{
	private var _pool:Array<T>;
	private var _size:Int;
}

/**
 * <p>An dynamic, arrayed object pool with an unbounded size that creates new objects on-the-fly and stores them for repeated use.</p>
 * <p>Use this pool if the number of objects is not known in advance.</p>
 * <p>Example:</p>
 * <p><pre class="prettyprint">
 * class Main
 * {
 *     static function main() {
 *         new Main();
 *     }
 *     
 *     var _pool:de.polygonal.ds.pooling.DynamicObjectPool&lt;Point&gt;;
 *     
 *     public function new() {
 *         //setup the pool
 *         _pool = new de.polygonal.ds.pooling.DynamicObjectPool(Point);
 *         
 *         //setup an algorithm that runs every 100ms
 *         var timer = new haxe.Timer(100);
 *         timer.run = algorithm;
 *     }
 *     
 *     function algorithm() {
 *         //add two points together and store the result in c
 *         var a = getPoint(10, 10);
 *         var b = getPoint(20, 20);
 *         var c = addition(a, b);
 *         
 *         //at this point the pool has allocated three point objects;
 *         //we could call _pool.get() to create a new point, but instead we reuse the points we already have
 *         _pool.put(a);
 *         _pool.put(b);
 *         _pool.put(c);
 *         
 *         //now the same calculation doesn't allocate any objects
 *         var a = getPoint(10, 10);
 *         var b = getPoint(20, 20);
 *         var c = addition(a, b);
 *         
 *         //after we are done, call reclaim() to mark all objects as available for reuse in the next iteration
 *         _pool.reclaim();
 *     }
 *     
 *     inline function getPoint(x:Float, y:Float):Point {
 *         var p = _pool.get();
 *         p.x = x;
 *         p.y = y;
 *         return p;
 *     }
 *     
 *     inline function addition(a:Point, b:Point):Point {
 *         var sum = _pool.get();
 *         sum.x = a.x + b.x;
 *         sum.y = a.y + b.y;
 *         return sum;
 *     }
 * }
 * 
 * class Point
 * {
 *     public var x:Float;
 *     public var y:Float;
 *     public function new() {}
 * }
 * </pre></p>
 */
class DynamicObjectPool<T>
{
	/**
	 * A unique identifier for this object.<br/>
	 * A hash table transforms this key into an index of an array element by using a hash function.<br/>
	 * <warn>This value should never be changed by the user.</warn>
	 */
	public var key:Int;
	
	var _size:Int;
	var _oldSize:Int;
	var _capacity:Int;
	var _top:Int;
	var _used:Int;
	var _usedMax:Int;
	var _pool:Array<T>;
	
	var _class:Class<T>;
	var _args:Array<Dynamic>;
	var _fabricate:Void->T;
	var _factory:Factory<T>;
	var _allocType:Int;
	
	#if debug
	var _set:de.polygonal.ds.Set<T>;
	#end
	
	/**
	 * Creates an empty pool.
	 * @param C allocates objects by instantiating the class <code>C</code>.
	 * @param fabricate allocates objects by calling <code>fabricate()</code>.
	 * @param factory allocates objects by using a <em>Factory</em> object (calling <code>factory</code>.<em>create()</em>).
	 * @param capacity the maximum number of objects that are stored in this pool.<br/>
	 * The default value of 0x7fffffff indicates that the size is unbound.
	 * @throws de.polygonal.ds.error.AssertError invalid arguments.
	 */
	public function new(C:Class<T> = null, fabricate:Void->T = null, factory:Factory<T> = null, capacity = M.INT32_MAX)
	{
		_class     = C;
		_args      = new Array<Dynamic>();
		_fabricate = fabricate;
		_factory   = factory;
		_capacity  = capacity;
		_pool      = new Array<T>();
		_allocType = 0;
		_top       = 0;
		_size      = 0;
		_oldSize   = 0;
		_used      = 0;
		_usedMax   = 0;
		
		if (C         != null) _allocType |= Bits.BIT_01;
		if (fabricate != null) _allocType |= Bits.BIT_02;
		if (factory   != null) _allocType |= Bits.BIT_03;
		
		#if debug
		assert(Bits.ones(_allocType) == 1, "invalid arguments");
		#end
		
		key = HashKey.next();
		
		#if debug
		_set = new de.polygonal.ds.ListSet<T>();
		#end
	}
	
	/**
	 * Destroys this object by explicitly nullifying all objects for GC'ing used resources.<br/>
	 * Improves GC efficiency/performance (optional).
	 */
	public function free()
	{
		for (i in 0..._size) _pool[i] = null;
		_class     = null;
		_args      = null;
		_fabricate = null;
		_factory   = null;
		_pool      = null;
	}
	
	/**
	 * The total number of objects in this pool.
	 */
	inline public function size():Int
	{
		return _size;
	}
	
	/**
	 * The maximum allowed number of pooled resources.<br/>
	 * This is an optional upper limit to counteract memory leaks.
	 */
	inline public function capacity():Int
	{
		return _capacity;
	}
	
	/**
	 * The total number of objects in use. 
	 */
	inline public function used():Int
	{
		return _used;
	}
	
	/**
	 * The maximum number of objects in use between calls to code>reclaim()</code>.
	 */
	inline public function maxUsageCount():Int
	{
		return _usedMax;
	}
	
	/**
	 * Acquires the next object from this pool or creates a new object if all objects are in use.<br/>
	 * To minimize object creation, return objects back to the pool as soon as their life cycle ends by calling <em>put()</em>.<br/>
	 * <warn>If <em>size()</em> equals <em>capacity()</em>, <em>get()</em> still allocates a new object but does not pool it. This effectively disables pooling.</warn>
	 */
	inline public function get():T
	{
		var x = null;
		
		if (_top > 0)
		{
			x = _pool[--_top];
			
			#if debug
			_set.remove(x);
			#end
		}
		else
		{
			x = _alloc();
			if (_size < _capacity)
				_pool[_size++] = x;
		}
		
		_used++;
		return x;
	}
	
	/**
	 * Returns the object <code>x</code> to the pool.<br/>
	 * Objects are pushed onto a stack, so <em>get()</em> returns <code>x</code> if called immediately after <em>put()</em>.<br/>
	 * @throws de.polygonal.ds.error.AssertError <code>x</code> was returned twice to the pool (debug only).
	 */
	inline public function put(x:T)
	{
		#if debug
		assert(!_set.has(x), 'object $x was returned twice to the pool');
		_set.set(x);
		#end
		
		_pool[_top++] = x;
		_used--;
	}
	
	/**
	 * Marks all pooled resources as avaiable for use by <code>get()</code>.<br/>
	 * <warn>The user is responsible for re-initializing an object.</warn>
	 * <warn>Don't call this method while objects are still in use or <em>get()</em> will return a used object.</warn>
	 * @return The total number of allocated objects since the last call to <em>reclaim()</em>.
	 */
	inline public function reclaim():Int
	{
		_top = _size;
		
		#if debug
		_set.clear();
		#end
		
		var c = _size - _oldSize;
		_oldSize = _size;
		_usedMax = M.max(_usedMax, _used);
		_used = 0;
		
		return c;
	}
	
	/**
	 * Returns a new <em>DynamicObjectPoolIterator</em> object to iterate over all pooled objects.<br/>
	 * @see <a href="http://haxe.org/ref/iterators" target="_blank">http://haxe.org/ref/iterators</a>
	 */
	public function iterator():Itr<T>
	{
		return new DynamicObjectPoolIterator<T>(this);
	}
	
	/**
	 * Returns the string form of the value that this object represents.
	 */
	public function toString():String
	{
		return '{ DynamicObjectPool, size/capacity: ${size()}/${capacity()} }';
	}
	
	inline function _alloc()
	{
		var x = null;
		
		switch (_allocType)
		{
			case Bits.BIT_01: x = Type.createInstance(_class, _args);
			case Bits.BIT_02: x = _fabricate();
			case Bits.BIT_03: x = _factory.create();
		}
		
		return x;
	}
}

#if generic
@:generic
#end
#if doc
private
#end
class DynamicObjectPoolIterator<T> implements de.polygonal.ds.Itr<T>
{
	var _f:DynamicObjectPoolFriend<T>;
	var _a:Array<T>;
	var _s:Int;
	var _i:Int;
	
	public function new(f:DynamicObjectPoolFriend<T>)
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
		return _i < _s;
	}
	
	inline public function remove()
	{
		throw "unsupported operation";
	}
	
	inline public function next():T
	{
		return _a[_i++];
	}
	
	inline function __pool<T>(f:DynamicObjectPoolFriend<T>)
	{
		return _f._pool;
	}
	inline function __size<T>(f:DynamicObjectPoolFriend<T>)
	{
		return f._size;
	}
}