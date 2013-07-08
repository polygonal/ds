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

/**
 * <p>A dynamic object pool based on a doubly linked list.</p>
 * <p>See <a href="http://lab.polygonal.de/2008/06/18/using-object-pools/" target="_blank">http://lab.polygonal.de/2008/06/18/using-object-pools/</a>.</p>
 */
#if generic
@:generic
#end
class LinkedObjectPool<T> implements Hashable
{
	/**
	 * A unique identifier for this object.<br/>
	 * A hash table transforms this key into an index of an array element by using a hash function.<br/>
	 * <warn>This value should never be changed by the user.</warn>
	 */
	public var key:Int;
	
	var _initSize:Int;
	var _currSize:Int;
	var _usageCount:Int;

	var _head:ObjNode<T>;
	var _tail:ObjNode<T>;
	
	var _emptyNode:ObjNode<T>;
	var _allocNode:ObjNode<T>;
	
	var _growable:Bool;
	
	var _C:Class<T>;
	var _fabricate:Void->T;
	var _factory:Factory<T>;
	
	/** 
	 * Creates a <em>LinkedObjectPool</em> object capable of managing <code>x</code> pre-allocated objects.<br/>
	 * Use <em>allocate()</em> to fill the pool.<br/>
	 * @param growable if true, new objects are allocated the first time an object is requested while the pool being empty.
	 */
	public function new(x:Int, growable = false)
	{
		_initSize = _currSize = x;
		_growable = growable;
		
		key = HashKey.next();
	}
	
	/**
	 * Destroys this object by explicitly nullifying all nodes, pointers and elements for GC'ing used resources.<br/>
	 * Improves GC efficiency/performance (optional).
	 */
	public function free()
	{
		var node = _head;
		while (node != null)
		{
			var t = node.next;
			node.next = null;
			node.val = null;
			node = t;
		}
		_head = _tail = _emptyNode = _allocNode = null;
		
		_C = null;
		_fabricate = null;
		_factory = null;
	}
	
	/**
	 * The total number of pre-allocated objects in the pool. 
	 */
	inline public function getSize():Int
	{
		return _currSize;
	}
	
	/**
	 * The number of used objects. 
	 */
	inline public function getUsageCount():Int
	{
		return _usageCount;
	}
	
	/**
	 * The total number of unused thus wasted objects.<br/>
	 * Use <em>purge()</em> to compact the pool.
	 */
	inline public function getWasteCount():Int
	{
		return _currSize - _usageCount;
	}
	
	/**
	 * Retrieves the next available object from the pool.
	 * @throws de.polygonal.ds.error.AssertError object pool exhausted (debug only).
	 */
	inline public function get():T
	{
		if (_usageCount == _currSize)
		{
			if (_growable)
			{
				_grow();
				return _getInternal();
			}
			else
			{
				#if debug
				if (!_growable) assert(false, "object pool exhausted");
				#end
				return null;
			}
		}
		else
			return _getInternal();
	}
	
	/**
	 * Recycles the object <code>o</code> so it can be reused by calling <em>get()</em>.
	 * @throws de.polygonal.ds.error.AssertError object pool is full (debug only).
	 */
	inline public function put(o:T)
	{
		#if debug
		assert(_usageCount != 0, "object pool is full");
		#end
		
		_usageCount--;
		_emptyNode.val = o;
		_emptyNode = _emptyNode.next;
	}
	
	/**
	 * Allocates the pool.
	 * @param C allocates objects by instantiating the class <code>C</code>.
	 * @param fabricate allocates objects by calling <code>fabricate()</code>.
	 * @param factory allocates objects by calling <code>factory</code>.<em>create()</em>.
	 * @throws de.polygonal.ds.error.AssertError invalid arguments.
	 */
	public function allocate(C:Class<T> = null, fabricate:Void->T = null, factory:Factory<T> = null)
	{
		free();
		
		#if debug
		assert(C != null || fabricate != null || factory != null, "invalid arguments");
		#end
		
		var buffer = new Array<T>();
		if (C != null)
		{
			for (i in 0..._initSize)
				buffer.push(Type.createInstance(C, []));
		}
		else
		if (fabricate != null)
		{
			for (i in 0..._initSize)
				buffer.push(fabricate());
		}
		else
		if (factory != null)
		{
			for (i in 0..._initSize)
				buffer.push(factory.create());
		}
		
		_fill(buffer);
		
		_C = C;
		_fabricate = fabricate;
		_factory = factory;
	}
	
	/**
	 * Removes all unused objects from the pool.<br/>
	 * If the number of remaining used objects is smaller than the initial capacity defined in the constructor, new objects are created to refill the pool. 
	 */
	public function purge()
	{
		if (_usageCount == 0)
		{
			if (_currSize == _initSize)
				return;
			
			if (_currSize > _initSize)
			{
				var i:Int = 0;
				var node:ObjNode<T> = _head;
				while (++i < _initSize)
					node = node.next;
				
				_tail = node;
				_allocNode = _emptyNode = _head;
				
				_currSize = _initSize;
				return;
			}
		}
		else
		{
			var i = 0;
			var a = new Array<ObjNode<T>>();
			var node =_head;
			while (node != null)
			{
				if (node.val == null) a[i++] = node;
				if (node == _tail) break;
				node = node.next;
			}
			
			_currSize = a.length;
			_usageCount = _currSize;
			
			_head = _tail = a[0];
			for (i in 1..._currSize)
			{
				node = a[i];
				node.next = _head;
				_head = node;
			}
			
			_emptyNode = _allocNode = _head;
			_tail.next = _head;
			
			if (_usageCount < _initSize)
			{
				_currSize = _initSize;
				
				var n = _tail;
				var t = _tail;
				var k = _initSize - _usageCount;
				for (i in 0...k)
				{
					node = new ObjNode<T>();
					node.val = _factory.create();
					
					t.next = node;
					t = node;
				}
				
				_tail = t;
				
				_tail.next = _emptyNode = _head;
				_allocNode = n.next;
				
			}
		}
	}
	
	/**
	 * Returns a string representing the current object.<br/>
	 * Prints out all object if compiled with the <em>-debug</em> directive.<br/>
	 */
	public function toString():String
	{
		#if debug
		var s = 'LinkedObjectPool (${getUsageCount()}/${getSize()} objects used)';
		if (getSize() == 0) return s;
		s += "\n[\n";
		var node = _head;
		var i = 0;
		while (true)
		{
			s += '  ${i} -> ${node.val}\n';
			i++;
			node = node.next;
			if (node == _head) break;
		}
		s += "]";
		return s;
		#else
		return 'LinkedObjectPool (${getUsageCount()}/${getSize()} objects used)';
		#end
	}
	
	inline function _grow()
	{
		_currSize += _initSize;
		
		var n = _tail;
		var t = _tail;
		
		if (_C != null)
		{
			for (i in 0..._initSize)
			{
				var node = new ObjNode<T>();
				node.val = Type.createInstance(_C, []);
				t.next = node;
				t = node;
			}
		}
		else
		if (_fabricate != null)
		{
			for (i in 0..._initSize)
			{
				var node = new ObjNode<T>();
				node.val = _fabricate();
				t.next = node;
				t = node;
			}
		}
		else
		if (_factory != null)
		{
			for (i in 0..._initSize)
			{
				var node = new ObjNode<T>();
				node.val = _factory.create();
				t.next = node;
				t = node;
			}
		}
		
		_tail = t;
		_tail.next = _emptyNode = _head;
		_allocNode = _tail;
		_allocNode = n.next;
	}
	
	inline function _fill(buffer:Array<T>)
	{
		_head = _tail = new ObjNode<T>();
		_head.val = buffer.pop();
		
		for (i in 1..._initSize)
		{
			var n = new ObjNode<T>();
			n.val = buffer.pop();
			n.next = _head;
			_head = n;
		}
		
		_emptyNode = _allocNode = _head;
		_tail.next = _head;
	}
	
	inline function _getInternal():T
	{
		_usageCount++;
		var o = _allocNode.val;
		_allocNode.val = null;
		_allocNode = _allocNode.next;
		return o;
	}
}

#if generic
@:generic
#end
#if doc
private
#end
class ObjNode<T>
{
	public var next:ObjNode<T>;
	public var val:T;
	
	public function new() {}
}