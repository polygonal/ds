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
	A fixed sized, arrayed object pool.
**/
class ObjectPool<T> implements Hashable
{
	/**
		A unique identifier for this object.
		A hash table transforms this key into an index of an array element by using a hash function.
		<warn>This value should never be changed by the user.</warn>
	**/
	public var key:Int;
	
	#if alchemy
	var mNext:de.polygonal.ds.mem.IntMemory;
	#else
	var mNext:Vector<Int>;
	#end
	
	var mPool:Array<T>;
	var mSize:Int;
	var mFree:Int;
	
	var mLazy:Bool;
	var mLazyConstructor:Void->T;
	
	#if debug
	var mUsage:de.polygonal.ds.BitVector;
	var mCount:Int;
	#end
	
	/**
		Creates an `ObjectPool` object capable of managing `x` pre-allocated objects.
		Use `allocate()` to fill the pool.
	**/
	public function new(x:Int)
	{
		mSize = x;
		mFree = -1;
		
		key = HashKey.next();
		
		#if debug
		mCount = 0;
		#end
	}
	
	/**
		Destroys this object by explicitly nullifying all objects for GC'ing used resources.
		Improves GC efficiency/performance (optional).
	**/
	public function free()
	{
		if (mPool == null) return;
		
		for (i in 0...mSize) mPool[i] = null;
		mPool = null;
		
		#if alchemy
		mNext.free();
		#end
		
		mNext = null;
		mLazyConstructor = null;
		
		#if debug
		if (mUsage != null)
		{
			mUsage.free();
			mUsage = null;
		}
		#end
	}
	
	/**
		Returns true if all objects are in use.
	**/
	inline public function isEmpty():Bool
	{
		return mFree == -1;
	}
	
	/**
		The total number of pre-allocated objects in the pool.
	**/
	inline public function size():Int
	{
		return mSize;
	}
	
	/**
		The total number of objects in use.
	**/
	public function countUsedObjects():Int
	{
		return size() - countUnusedObjects();
	}
	
	/**
		The total number of available objects.
	**/
	public function countUnusedObjects():Int
	{
		var c = 0;
		var i = mFree;
		while (i != -1)
		{
			i = getNext(i);
			c++;
		}
		
		return c;
	}
	
	/**
		Returns the id to the next free object.
		After an id has been obtained, the corresponding object can be retrieved using `get(id)`.
		<assert>pool exhausted</assert>
	**/
	inline public function next():Int
	{
		#if debug
		assert(mCount < mSize && mFree != -1, "pool exhausted");
		++mCount;
		#end
		
		var id = mFree;
		mFree = getNext(id);
		
		#if debug
		mUsage.set(id);
		#end
		
		return id;
	}
	
	/**
		Returns the object that is mapped to `id`.
		Call `next()` to request an `id` first.
		<assert>invalid `id` or object linked to `id` is not used</assert>
	**/
	inline public function get(id:Int):T
	{
		assert(mUsage.has(id), 'id $id is not used');
		
		if (mLazy)
		{
			if (mPool[id] == null)
				mPool[id] = mLazyConstructor();
		}
		
		return mPool[id];
	}
	
	/**
		Puts the object mapped to `id` back into the pool.
		<assert>pool is full or object linked to `id` is not used</assert>
	**/
	inline public function put(id:Int)
	{
		#if debug
		assert(mUsage.has(id), 'id $id is not used');
		assert(mCount > 0, "pool is full");
		mUsage.clr(id);
		--mCount;
		#end
		
		setNext(id, mFree);
		mFree = id;
	}
	
	/**
		Allocates the pool.
		@param lazy if true, objects are allocated on-the-fly until the pool is full.
		@param cl allocates objects by instantiating the class `cl`.
		@param fabricate allocates objects by calling `fabricate()`.
		@param factory allocates objects by using a `Factory` object (calling `factory`::create()).
		<assert>invalid arguments</assert>
	**/
	public function allocate(lazy:Bool, cl:Class<T> = null, fabricate:Void->T = null, factory:Factory<T> = null)
	{
		mLazy = lazy;
		
		#if alchemy
		mNext = new de.polygonal.ds.mem.IntMemory(mSize, "ObjectPool.mNext");
		#else
		mNext = new Vector<Int>(mSize);
		#end
		
		for (i in 0...mSize - 1) setNext(i, i + 1);
		setNext(mSize - 1, -1);
		mFree = 0;
		mPool = de.polygonal.ds.ArrayUtil.alloc(mSize);
		
		assert(cl != null || fabricate != null || factory != null, "invalid arguments");
		
		if (mLazy)
		{
			if (cl != null)
				mLazyConstructor = function() return Type.createInstance(cl, []);
			else
			if (fabricate != null)
				mLazyConstructor = function() return fabricate();
			else
			if (factory != null)
				mLazyConstructor = function() return factory.create();
		}
		else
		{
			if (cl != null)
				for (i in 0...mSize) mPool[i] = Type.createInstance(cl, []);
			else
			if (fabricate != null)
				for (i in 0...mSize) mPool[i] = fabricate();
			else
			if (factory != null)
				for (i in 0...mSize) mPool[i] = factory.create();
		}
		
		#if debug
		mUsage = new de.polygonal.ds.BitVector(mSize);
		#end
	}
	
	/**
		Returns a new `ObjectPoolIterator` object to iterate over all pooled objects, regardless if an object is used or not.
		
		See <a href="http://haxe.org/ref/iterators" target="mBlank">http://haxe.org/ref/iterators</a>
	**/
	public function iterator():Itr<T>
	{
		return new ObjectPoolIterator<T>(this);
	}
	
	/**
		Returns a string representing the current object.
		Prints out all object if compiled with the `-debug` directive.
	**/
	public function toString():String
	{
		#if debug
		var s = '{ ObjectPool used/total: $mCount/$mSize }';
		if (size() == 0) return s;
		s += "\n[\n";
		
		for (i in 0...size())
		{
			var t = Std.string(mPool[i]);
			s += Printf.format("  %4d -> {%s}\n", [i, t]);
		}
		s += "]";
		return s;
		#else
		return '{ ObjectPool used/total: ${countUsedObjects()}/$mSize }';
		#end
	}
	
	inline function getNext(i:Int)
	{
		#if alchemy
		return mNext.get(i);
		#else
		return mNext[i];
		#end
	}
	inline function setNext(i:Int, x:Int)
	{
		#if alchemy
		mNext.set(i, x);
		#else
		mNext[i] = x;
		#end
	}
}

#if generic
@:generic
#end
@:access(de.polygonal.ds.pooling.ObjectPool)
@:dox(hide)
class ObjectPoolIterator<T> implements de.polygonal.ds.Itr<T>
{
	var mF:ObjectPool<T>;
	var mData:Array<T>;
	var mS:Int;
	var mI:Int;
	
	public function new(f:ObjectPool<T>)
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
		return mData != null && mI < mS;
	}
	
	inline public function next():T
	{
		return mData[mI++];
	}
	
	inline public function remove()
	{
		throw "unsupported operation";
	}
}