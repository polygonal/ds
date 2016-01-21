/*
Copyright (c) 2008-2014 Michael Baczynski, http://www.polygonal.de

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
package de.polygonal.ds.pooling;

import de.polygonal.ds.error.Assert.assert;

/**
	An dynamic, arrayed object pool with an unbounded size that creates new objects on-the-fly and stores them for repeated use.
	Use this pool if the number of objects is not known in advance.
	
	Example:
	<pre class="prettyprint">
	class Main
	{
	    static function main() {
	        new Main();
	    }
	    var mPool:de.polygonal.ds.pooling.DynamicObjectPool<Point>;
	    public function new() {
	        //setup the pool
	        mPool = new de.polygonal.ds.pooling.DynamicObjectPool(Point);
	
	        //setup an algorithm that runs every 100ms
	        var timer = new haxe.Timer(100);
	        timer.run = algorithm;
	    }
	
	    function algorithm() {
	        //add two points together and store the result in c
	        var a = getPoint(10, 10);
	        var b = getPoint(20, 20);
	        var c = addition(a, b);
	
	        //at this point the pool has allocated three point objects;
	        //we could call mPool.get() to create a new point, but instead we reuse the points we already have
	        mPool.put(a);
	        mPool.put(b);
	        mPool.put(c);
	
	        //now the same calculation doesn't allocate any objects
	        var a = getPoint(10, 10);
	        var b = getPoint(20, 20);
	        var c = addition(a, b);
	
	        //after we are done, call reclaim() to mark all objects as available for reuse in the next iteration
	        mPool.reclaim();
	    }
	
	    inline function getPoint(x:Float, y:Float):Point {
	        var p = mPool.get();
	        p.x = x;
	        p.y = y;
	        return p;
	    }
	
	    inline function addition(a:Point, b:Point):Point {
	        var sum = mPool.get();
	        sum.x = a.x + b.x;
	        sum.y = a.y + b.y;
	        return sum;
	    }
	}
	
	class Point
	{
	    public var x:Float;
	    public var y:Float;
	    public function new() {}
	}
	</pre>
**/
class DynamicObjectPool<T>
{
	/**
		A unique identifier for this object.
		A hash table transforms this key into an index of an array element by using a hash function.
		<warn>This value should never be changed by the user.</warn>
	**/
	public var key:Int;
	
	var mSize:Int;
	var mOldSize:Int;
	var mCapacity:Int;
	var mTop:Int;
	var mUsed:Int;
	var mUsedMax:Int;
	var mPool:Array<T>;
	
	var mClass:Class<T>;
	var mArgs:Array<Dynamic>;
	var mFabricate:Void->T;
	var mFactory:Factory<T>;
	var mAllocType:Int;
	
	#if debug
	var mSet:de.polygonal.ds.Set<T>;
	#end
	
	/**
		Creates an empty pool.
		@param cl allocates objects by instantiating the class `cl`.
		@param fabricate allocates objects by calling `fabricate()`.
		@param factory allocates objects by using a `Factory` object (calling `factory`::create()).
		@param capacity the maximum number of objects that are stored in this pool.
		The default value of 0x7FFFFFFF indicates that the size is unbound.
		<assert>invalid arguments</assert>
	**/
	public function new(cl:Class<T> = null, fabricate:Void->T = null, factory:Factory<T> = null, capacity = M.INT32_MAX)
	{
		mClass = cl;
		mArgs = new Array<Dynamic>();
		mFabricate = fabricate;
		mFactory = factory;
		mCapacity = capacity;
		mPool = new Array<T>();
		mAllocType = 0;
		mTop = 0;
		mSize = 0;
		mOldSize = 0;
		mUsed = 0;
		mUsedMax = 0;
		
		if (cl        != null) mAllocType |= Bits.BIT_01;
		if (fabricate != null) mAllocType |= Bits.BIT_02;
		if (factory   != null) mAllocType |= Bits.BIT_03;
		
		assert(Bits.ones(mAllocType) == 1, "invalid arguments");
		
		key = HashKey.next();
		
		#if debug
		mSet = new de.polygonal.ds.ListSet<T>();
		#end
	}
	
	/**
		Destroys this object by explicitly nullifying all objects for GC'ing used resources.
		Improves GC efficiency/performance (optional).
	**/
	public function free()
	{
		for (i in 0...mSize) mPool[i] = null;
		mClass = null;
		mArgs = null;
		mFabricate = null;
		mFactory = null;
		mPool = null;
	}
	
	/**
		The total number of objects in this pool.
	**/
	inline public function size():Int
	{
		return mSize;
	}
	
	/**
		The maximum allowed number of pooled resources.
		This is an optional upper limit to counteract memory leaks.
	**/
	inline public function capacity():Int
	{
		return mCapacity;
	}
	
	/**
		The total number of objects in use.
	**/
	inline public function used():Int
	{
		return mUsed;
	}
	
	/**
		The maximum number of objects in use between calls to code>reclaim()`.
	**/
	inline public function maxUsageCount():Int
	{
		return mUsedMax;
	}
	
	/**
		Acquires the next object from this pool or creates a new object if all objects are in use.
		To minimize object creation, return objects back to the pool as soon as their life cycle ends by calling `put()`.
		<warn>If ``size()`` equals `capacity()`, `get()` still allocates a new object but does not pool it. This effectively disables pooling.</warn>
	**/
	inline public function get():T
	{
		var x = null;
		
		if (mTop > 0)
		{
			x = mPool[--mTop];
			
			#if debug
			mSet.remove(x);
			#end
		}
		else
		{
			x = alloc();
			if (mSize < mCapacity)
				mPool[mSize++] = x;
		}
		
		mUsed++;
		return x;
	}
	
	/**
		Returns the object `x` to the pool.
		Objects are pushed onto a stack, so `get()` returns `x` if called immediately after `put()`.
		<assert>`x` was returned twice to the pool</assert>
	**/
	inline public function put(x:T)
	{
		#if debug
		assert(!mSet.has(x), 'object $x was returned twice to the pool');
		mSet.set(x);
		#end
		
		mPool[mTop++] = x;
		mUsed--;
	}
	
	/**
		Marks all pooled resources as avaiable for use by `get()`.
		<warn>The user is responsible for re-initializing an object.</warn>
		<warn>Don't call this method while objects are still in use or `get()` will return a used object.</warn>
		@return The total number of allocated objects since the last call to `reclaim()`.
	**/
	inline public function reclaim():Int
	{
		mTop = mSize;
		
		#if debug
		mSet.clear();
		#end
		
		var c = mSize - mOldSize;
		mOldSize = mSize;
		mUsedMax = M.max(mUsedMax, mUsed);
		mUsed = 0;
		
		return c;
	}
	
	/**
		Returns a new `DynamicObjectPoolIterator` object to iterate over all pooled objects.
		
		See <a href="http://haxe.org/ref/iterators" target="mBlank">http://haxe.org/ref/iterators</a>
	**/
	public function iterator():Itr<T>
	{
		return new DynamicObjectPoolIterator<T>(this);
	}
	
	/**
		Returns the string form of the value that this object represents.
	**/
	public function toString():String
	{
		return '{ DynamicObjectPool, size/capacity: ${size()}/${capacity()} }';
	}
	
	inline function alloc()
	{
		var x = null;
		
		switch (mAllocType)
		{
			case Bits.BIT_01: x = Type.createInstance(mClass, mArgs);
			case Bits.BIT_02: x = mFabricate();
			case Bits.BIT_03: x = mFactory.create();
		}
		
		return x;
	}
}

#if generic
@:generic
#end
@:access(de.polygonal.ds.pooling.DynamicObjectPool)
@:dox(hide)
class DynamicObjectPoolIterator<T> implements de.polygonal.ds.Itr<T>
{
	var mF:DynamicObjectPool<T>;
	var mData:Array<T>;
	var mS:Int;
	var mI:Int;
	
	public function new(f:DynamicObjectPool<T>)
	{
		mF = f;
		reset();
	}
	
	inline public function reset():Itr<T>
	{
		mData = mF.mPool;
		mS = mF.mSize;
		mI = 0;
		return this;
	}
	
	inline public function hasNext():Bool
	{
		return mI < mS;
	}
	
	inline public function remove()
	{
		throw "unsupported operation";
	}
	
	inline public function next():T
	{
		return mData[mI++];
	}
}