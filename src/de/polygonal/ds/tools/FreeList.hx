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

import de.polygonal.ds.NativeArray;
import de.polygonal.ds.tools.Assert.assert;

using de.polygonal.ds.tools.NativeArrayTools;

#if generic
@:generic
#end
class FreeList<T>
{
	public var size(default, null) = 0;
	public var capacity(default, null):Int;
	
	var mData:NativeArray<T>;
	var mNext:NativeArray<Int>;
	var mFree = 0;
	
	#if debug
	var mUsage = new Array<Bool>();
	#end
	
	/**
		@param `capacity` the maximum capacity.
		@param `factory` if passed, preallocates the list by calling the `factory` function `capacity` times.
	**/
	public function new(capacity:Int, ?factory:Void->T)
	{
		this.capacity = capacity;
		mData = NativeArrayTools.alloc(capacity);
		mNext = NativeArrayTools.alloc(capacity);
		for (i in 0...capacity - 1) mNext.set(i, i + 1);
		mNext.set(capacity - 1, -1);
		
		if (factory != null)
			for (i in 0...capacity)
				mData.set(i, factory());
	}
	
	/**
		Destroys this object by explicitly nullifying all elements for GC'ing used resources.
		
		Improves GC efficiency/performance (optional).
	**/
	public function free()
	{
		mData.nullify();
		mData = null;
	}
	
	/**
		Returns an index to the next free slot or -1 if all slots are occupied.
	**/
	public inline function next():Int
	{
		return
		if (mFree < 0)
			-1;
		else
		{
			var i = mFree;
			mFree = mNext.get(i);
			size++;
			#if debug
			mUsage[i] = true;
			#end
			i;
		}
	}
	
	/**
		Returns the element stored in the slot at index `i`.
	**/
	public inline function get(i:Int):T
	{
		assert(i >= 0 && i < capacity);
		
		#if debug
		assert(mUsage[i], "invalid index, call next() first");
		#end
		
		return mData.get(i);
	}
	
	/**
		Replaces the element stored in the slot at index `i` with `val`.
	**/
	public inline function set(i:Int, val:T)
	{
		assert(i >= 0 && i < capacity);
		
		#if debug
		assert(mUsage[i], "invalid index, call next() first");
		#end
		
		mData.set(i, val);
	}
	
	/**
		"Returns" the element at index `i`. The slot is marked empty.
	**/
	public inline function put(i:Int)
	{
		mNext.set(i, mFree);
		mFree = i;
		size--;
		
		#if debug
		assert(mUsage[i], "invalid index, call next() first");
		mUsage[i] = false;
		#end
	}
}