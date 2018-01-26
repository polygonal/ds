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
package de.polygonal.ds.tools;

import de.polygonal.ds.ListSet;
import de.polygonal.ds.Set;
import de.polygonal.ds.tools.Assert.assert;

using de.polygonal.ds.tools.NativeArrayTools;

/**
	A lightweight object pool
**/
#if generic
@:generic
#end
class ObjectPool<T>
{
	/**
		The growth rate of the pool.
		@see `GrowthRate`
	**/
	public var growthRate:Int = GrowthRate.MILD;
	
	/**
		The current number of pooled objects.
	**/
	public var size(default, null):Int = 0;
	
	/**
		The maximum allowed number of pooled objects.
	**/
	public var maxSize(default, null):Int;
	
	var mPool:NativeArray<T>;
	var mFactory:Void->T;
	var mDispose:T->Void;
	var mCapacity:Int = 16;
	
	#if debug
	var mSet:Set<T>;
	#end
	
	/**
		@param factory a function responsible for creating new objects.
		@param dispose a function responsible for disposing objects (optional).
		<br/>Invoked when the user tries to return an object to a full pool.
		@param maxNumObjects the maximum allowed number of pooled object.
		<br/>If omitted, there is no upper limit.
	**/
	public function new(factory:Void->T, ?dispose:T->Void, maxNumObjects:Int = -1) 
	{
		mFactory = factory;
		mDispose = dispose == null ? function(x:T) {} : dispose;
		maxSize = maxNumObjects;
		mPool = NativeArrayTools.alloc(mCapacity);
		
		#if debug
		mSet = new ListSet<T>();
		#end
	}
	
	/**
		Fills the pool in advance with `numObjects` objects.
	**/
	public function preallocate(numObjects:Int)
	{
		assert(size == 0);
		
		size = mCapacity = numObjects;
		mPool.nullify();
		mPool = NativeArrayTools.alloc(size);
		for (i in 0...numObjects) mPool.set(i, mFactory());
	}
	
	/**
		Destroys this object by explicitly nullifying all objects for GC'ing used resources.
		Improves GC efficiency/performance (optional).
	**/
	public function free()
	{
		for (i in 0...mCapacity) mDispose(mPool.get(i));
		NativeArrayTools.nullify(mPool);
		mPool = null;
		mFactory = null;
		mDispose = null;
		
		#if debug
		mSet.free();
		mSet = null;
		#end
	}
	
	/**
		Gets an object from the pool; the method either creates a new object if the pool is empty (no object has been returned yet) or returns an existing object from the pool.
		To minimize object allocation, return objects back to the pool as soon as their life cycle ends.
	**/
	public inline function get():T
	{
		#if debug
		if (size > 0)
		{
			var obj = mPool.get(--size);
			mSet.remove(obj);
			return obj;
		}
		else
		{
			var obj = mFactory();
			return obj;
		}
		#else
		return size > 0 ? mPool.get(--size) : mFactory();
		#end
	}
	
	/**
		Puts `obj` into the pool, incrementing `this.size`.
		
		Discards `obj` if the pool is full by passing it to the dispose function (`this.size` == `this.maxSize`).
	**/
	inline public function put(obj:T)
	{
		#if debug
		assert(!mSet.has(obj), 'object $obj was returned twice to the pool');
		mSet.set(obj);
		#end
		
		if (size == maxSize)
			mDispose(obj);
		else
		{
			if (size == mCapacity) resize();
			mPool.set(size++, obj);
		}
	}
	
	public function iterator():Iterator<T>
	{
		var i = 0;
		var s = size;
		var d = mPool;
		return
		{
			hasNext: function() return i < s,
			next: function() return d.get(i++)
		}
	}
	
	function resize()
	{
		var newCapacity = GrowthRate.compute(growthRate, mCapacity);
		var t = NativeArrayTools.alloc(newCapacity);
		mCapacity = newCapacity;
		mPool.blit(0, t, 0, size);
		mPool = t;
	}
}