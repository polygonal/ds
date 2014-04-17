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
 * <p>A dynamic object pool based on a doubly linked list.</p>
 * <p>See <a href="http://lab.polygonal.de/2008/06/18/using-object-pools/" target="mBlank">http://lab.polygonal.de/2008/06/18/using-object-pools/</a>.</p>
 */
#if (flash && generic)
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
	
	var mInitSize:Int;
	var mCurrSize:Int;
	var mUsageCount:Int;

	var mHead:ObjNode<T>;
	var mTail:ObjNode<T>;
	
	var mEmptyNode:ObjNode<T>;
	var mAllocNode:ObjNode<T>;
	
	var mGrowable:Bool;
	
	var mC:Class<T>;
	var mFabricate:Void->T;
	var mFactory:Factory<T>;
	
	/**
	 * Creates a <em>LinkedObjectPool</em> object capable of managing <code>x</code> pre-allocated objects.<br/>
	 * Use <em>allocate()</em> to fill the pool.<br/>
	 * @param growable if true, new objects are allocated the first time an object is requested while the pool being empty.
	 */
	public function new(x:Int, growable = false)
	{
		mInitSize = mCurrSize = x;
		mGrowable = growable;
		
		key = HashKey.next();
	}
	
	/**
	 * Destroys this object by explicitly nullifying all nodes, pointers and elements for GC'ing used resources.<br/>
	 * Improves GC efficiency/performance (optional).
	 */
	public function free()
	{
		var node = mHead;
		while (node != null)
		{
			var t = node.next;
			node.next = null;
			node.val = null;
			node = t;
		}
		mHead = mTail = mEmptyNode = mAllocNode = null;
		
		mC = null;
		mFabricate = null;
		mFactory = null;
	}
	
	/**
	 * The total number of pre-allocated objects in the pool.
	 */
	inline public function getSize():Int
	{
		return mCurrSize;
	}
	
	/**
	 * The number of used objects.
	 */
	inline public function getUsageCount():Int
	{
		return mUsageCount;
	}
	
	/**
	 * The total number of unused thus wasted objects.<br/>
	 * Use <em>purge()</em> to compact the pool.
	 */
	inline public function getWasteCount():Int
	{
		return mCurrSize - mUsageCount;
	}
	
	/**
	 * Retrieves the next available object from the pool.
	 * @throws de.polygonal.ds.error.AssertError object pool exhausted (debug only).
	 */
	inline public function get():T
	{
		if (mUsageCount == mCurrSize)
		{
			if (mGrowable)
			{
				grow();
				return getInternal();
			}
			else
			{
				#if debug
				if (!mGrowable) assert(false, "object pool exhausted");
				#end
				return null;
			}
		}
		else
			return getInternal();
	}
	
	/**
	 * Recycles the object <code>o</code> so it can be reused by calling <em>get()</em>.
	 * @throws de.polygonal.ds.error.AssertError object pool is full (debug only).
	 */
	inline public function put(o:T)
	{
		#if debug
		assert(mUsageCount != 0, "object pool is full");
		#end
		
		mUsageCount--;
		mEmptyNode.val = o;
		mEmptyNode = mEmptyNode.next;
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
			for (i in 0...mInitSize)
				buffer.push(Type.createInstance(C, []));
		}
		else
		if (fabricate != null)
		{
			for (i in 0...mInitSize)
				buffer.push(fabricate());
		}
		else
		if (factory != null)
		{
			for (i in 0...mInitSize)
				buffer.push(factory.create());
		}
		
		fill(buffer);
		
		mC = C;
		mFabricate = fabricate;
		mFactory = factory;
	}
	
	/**
	 * Removes all unused objects from the pool.<br/>
	 * If the number of remaining used objects is smaller than the initial capacity defined in the constructor, new objects are created to refill the pool.
	 */
	public function purge()
	{
		if (mUsageCount == 0)
		{
			if (mCurrSize == mInitSize)
				return;
			
			if (mCurrSize > mInitSize)
			{
				var i:Int = 0;
				var node:ObjNode<T> = mHead;
				while (++i < mInitSize)
					node = node.next;
				
				mTail = node;
				mAllocNode = mEmptyNode = mHead;
				
				mCurrSize = mInitSize;
				return;
			}
		}
		else
		{
			var i = 0;
			var a = new Array<ObjNode<T>>();
			var node =mHead;
			while (node != null)
			{
				if (node.val == null) a[i++] = node;
				if (node == mTail) break;
				node = node.next;
			}
			
			mCurrSize = a.length;
			mUsageCount = mCurrSize;
			
			mHead = mTail = a[0];
			for (i in 1...mCurrSize)
			{
				node = a[i];
				node.next = mHead;
				mHead = node;
			}
			
			mEmptyNode = mAllocNode = mHead;
			mTail.next = mHead;
			
			if (mUsageCount < mInitSize)
			{
				mCurrSize = mInitSize;
				
				var n = mTail;
				var t = mTail;
				var k = mInitSize - mUsageCount;
				for (i in 0...k)
				{
					node = new ObjNode<T>();
					node.val = mFactory.create();
					
					t.next = node;
					t = node;
				}
				
				mTail = t;
				
				mTail.next = mEmptyNode = mHead;
				mAllocNode = n.next;
				
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
		var node = mHead;
		var i = 0;
		while (true)
		{
			s += '  ${i} -> ${node.val}\n';
			i++;
			node = node.next;
			if (node == mHead) break;
		}
		s += "]";
		return s;
		#else
		return 'LinkedObjectPool (${getUsageCount()}/${getSize()} objects used)';
		#end
	}
	
	inline function grow()
	{
		mCurrSize += mInitSize;
		
		var n = mTail;
		var t = mTail;
		
		if (mC != null)
		{
			for (i in 0...mInitSize)
			{
				var node = new ObjNode<T>();
				node.val = Type.createInstance(mC, []);
				t.next = node;
				t = node;
			}
		}
		else
		if (mFabricate != null)
		{
			for (i in 0...mInitSize)
			{
				var node = new ObjNode<T>();
				node.val = mFabricate();
				t.next = node;
				t = node;
			}
		}
		else
		if (mFactory != null)
		{
			for (i in 0...mInitSize)
			{
				var node = new ObjNode<T>();
				node.val = mFactory.create();
				t.next = node;
				t = node;
			}
		}
		
		mTail = t;
		mTail.next = mEmptyNode = mHead;
		mAllocNode = mTail;
		mAllocNode = n.next;
	}
	
	inline function fill(buffer:Array<T>)
	{
		mHead = mTail = new ObjNode<T>();
		mHead.val = buffer.pop();
		
		for (i in 1...mInitSize)
		{
			var n = new ObjNode<T>();
			n.val = buffer.pop();
			n.next = mHead;
			mHead = n;
		}
		
		mEmptyNode = mAllocNode = mHead;
		mTail.next = mHead;
	}
	
	inline function getInternal():T
	{
		mUsageCount++;
		var o = mAllocNode.val;
		mAllocNode.val = null;
		mAllocNode = mAllocNode.next;
		return o;
	}
}

#if (flash && generic)
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