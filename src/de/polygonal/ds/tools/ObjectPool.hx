/*
Copyright (c) 2016 Michael Baczynski, http://www.polygonal.de

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
	An object pool with an unbounded size that creates new objects on-the-fly and stores them for repeated use.
	
	Example:
**/
#if generic
@:generic
#end
class ObjectPool<T>
{
	public var growthRate:Int = GrowthRate.MILD;
	
	var mFactory:Void->T;
	var mDispose:T->Void;
	
	public var size:Int = 0;
	
	var mPool:NativeArray<T>;
	
	var mCapacity:Int = 16;
	var mSizeMax:Int;
	var mGrowthRate:Int;
	
	var mSet:Set<T>;
	
	/**
		@maxNumObjects The maximum allowed number of pooled object. If omitted, there is no upper limit.
	**/
	
	public function new(factory:Void->T, dispose:T->Void, maxNumObjects:Int = -1) 
	{
		mFactory = factory;
		mDispose = dispose;
		mSizeMax = maxNumObjects;
		mPool = NativeArrayTools.alloc(mCapacity);
		
		mSet = new ListSet();
	}
	
	public function preallocate(numObjects:Int)
	{
		if (size > 0) numObjects = M.min(numObjects, size);
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
		mFactory = null;
		mDispose = null;
		NativeArrayTools.nullify(mPool);
		mPool = null;
	}
	
	/**
		Acquires the next object from this pool or creates a new object if all objects are in use.
		To minimize object creation, return objects back to the pool as soon as their life cycle ends by calling `this.put()`.
		<warn>If `this.size` equals `this.capacity()`, `this.get()` still allocates a new object but does not pool it. This effectively disables pooling.</warn>
	**/
	public inline function get():T
	{
		#if debug
		if (size > 0)
		{
			var obj = mFactory();
			return obj;
		}
		else
		{
			var obj = mPool.get(--size);
			
			mSet.remove(obj);
			
			return obj;
		}
		#else
		return size > 0 ? mPool.get(--size) : mFactory();
		#end
	}
	
	/**
		Returns the object `x` to the pool.
		Objects are pushed onto a stack, so `this.get()` returns `x` if called immediately after `this.put()`.
	**/
	inline public function put(obj:T)
	{
		#if debug
		assert(!mSet.has(obj), 'object $obj was returned twice to the pool');
		mSet.set(obj);
		#end
		
		if (size == mSizeMax)
			mDispose(obj);
		else
		{
			if (size == mCapacity) resize();
			mPool.set(size++, obj);
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