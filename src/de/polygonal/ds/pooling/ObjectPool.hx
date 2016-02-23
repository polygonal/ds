/*
Copyright (c) 2008-2016 Michael Baczynski, http://www.polygonal.de

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

import de.polygonal.ds.NativeArray;
import de.polygonal.ds.tools.ArrayTools;
import de.polygonal.ds.tools.Assert.assert;
import de.polygonal.ds.tools.NativeArrayTools;

using de.polygonal.ds.tools.NativeArrayTools;

/**
	A fixed sized, arrayed object pool.
**/
#if generic
@:generic
#end
class ObjectPool<T> implements Hashable
{
	/**
		A unique identifier for this object.
		A hash table transforms this key into an index of an array element by using a hash function.
		<warn>This value should never be changed by the user.</warn>
	**/
	public var key(default, null):Int = HashKey.next();
	
	/**
		The total number of pre-allocated objects in the pool.
	**/
	public var size(default, null):Int;
	
	#if alchemy
	var mNext:de.polygonal.ds.mem.IntMemory;
	#else
	var mNext:NativeArray<Int>;
	#end
	
	var mPool:NativeArray<T>;
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
		size = x;
		mFree = -1;
		
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
		
		mPool.nullify();
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
	public inline function isEmpty():Bool
	{
		return mFree == -1;
	}
	
	/**
		The total number of objects in use.
	**/
	public function countUsedObjects():Int
	{
		return size - countUnusedObjects();
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
			i = mNext.get(i);
			c++;
		}
		return c;
	}
	
	/**
		Returns the id to the next free object.
		After an id has been obtained, the corresponding object can be retrieved using `get(id)`.
		<assert>pool exhausted</assert>
	**/
	public inline function next():Int
	{
		#if debug
		assert(mCount < size && mFree != -1, "pool exhausted");
		++mCount;
		#end
		
		var id = mFree;
		mFree = mNext.get(id);
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
	public inline function get(id:Int):T
	{
		assert(mUsage.has(id), 'id $id is not used');
		if (mLazy) construct(id);
		return mPool.get(id);
	}
	
	/**
		Puts the object mapped to `id` back into the pool.
		<assert>pool is full or object linked to `id` is not used</assert>
	**/
	public inline function put(id:Int)
	{
		#if debug
		assert(mUsage.has(id), 'id $id is not used');
		assert(mCount > 0, "pool is full");
		mUsage.clr(id);
		--mCount;
		#end
		
		mNext.set(id, mFree);
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
		mNext = new de.polygonal.ds.mem.IntMemory(size, "ObjectPool.mNext");
		#else
		mNext = NativeArrayTools.alloc(size);
		#end
		
		for (i in 0...size - 1) mNext.set(i, i + 1);
		mNext.set(size - 1, -1);
		mFree = 0;
		mPool = NativeArrayTools.alloc(size);
		
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
				for (i in 0...size) mPool[i] = Type.createInstance(cl, []);
			else
			if (fabricate != null)
				for (i in 0...size) mPool[i] = fabricate();
			else
			if (factory != null)
				for (i in 0...size) mPool[i] = factory.create();
		}
		
		#if debug
		mUsage = new de.polygonal.ds.BitVector(size);
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
		var b = new StringBuf();
		
		#if debug
		b.add('{ ObjectPool used/total: $mCount/$size }');
		#else
		b.add('{ ObjectPool total: size }');
		#end
		if (size == 0) return b.toString();
		b.add("\n[\n");
		var args = new Array<Dynamic>();
		for (i in 0...size)
		{
			args[0] = i;
			args[1] = Std.string(mPool[i]);
			b.add(Printf.format("  %4d -> {%s}\n", args));
		}
		b.add("]");
		return b.toString();
	}
	
	function construct(id:Int)
	{
		if (mPool.get(id) == null)
			mPool.set(id, mLazyConstructor());
	}
}

#if generic
@:generic
#end
@:access(de.polygonal.ds.pooling.ObjectPool)
@:dox(hide)
class ObjectPoolIterator<T> implements de.polygonal.ds.Itr<T>
{
	var mObject:ObjectPool<T>;
	var mData:NativeArray<T>;
	var mS:Int;
	var mI:Int;
	
	public function new(x:ObjectPool<T>)
	{
		mObject = x;
		reset();
	}

	public inline function reset():Itr<T>
	{
		mData = mObject.mPool;
		mS = mObject.size;
		mI = 0;
		return this;
	}
	
	public inline function hasNext():Bool
	{
		return mData != null && mI < mS;
	}
	
	public inline function next():T
	{
		return mData.get(mI++);
	}
	
	public function remove()
	{
		throw "unsupported operation";
	}
}