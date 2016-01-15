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
package de.polygonal.ds.mem;

import de.polygonal.ds.error.Assert.assert;

/**
	Abstract class that grants read/write access to a chunk of fast "alchemy memory".
**/
class MemoryAccess implements Hashable
{
	/**
		A unique identifier for this object.
		A hash table transforms this key into an index of an array element by using a hash function.
		<warn>This value should never be changed by the user.</warn>
	**/
	public var key:Int;
	
	/**
		The number of allocated bytes.
	**/
	public var bytes(default, null):Int;
	
	/**
		The memory offset in bytes.
	**/
	public var offset(default, null):Int;
	
	public var name:String;
	
	var mMemory:Dynamic;
	
	function new(bytes:Int, name = "?")
	{
		assert(bytes > 0);
		
		this.bytes = bytes;
		this.name = name;
		
		#if alchemy
		MemoryManager.instance.malloc(this, bytes);
		#else
		mMemory = {};
		#end
		
		key = HashKey.next();
		
		#if verbose
		trace('allocated $bytes bytes for $name');
		#end
	}
	
	/**
		Destroys this object by explicitly nullifying all pointers and instantly releases any memory that was allocated by this accessor.
		<warn>Invoke this method when the life cycle of this object ends to prevent a memory leak.</warn>
		This is not optional if `MemoryManager.AUTO_RECLAIM_MEMORY` is true.
		<assert>memory was already deallocated</assert>
	**/
	public function free()
	{
		assert(mMemory != null, "memory deallocated");
		
		#if alchemy
		MemoryManager.instance.dealloc(this);
		#else
		mMemory = null;
		#end
	}
	
	/**
		Sets all bytes to 0.
		<assert>memory was already deallocated</assert>
	**/
	public function clear()
	{
		#if alchemy
		for (i in 0...bytes)
			flash.Memory.setByte(offset + i, 0);
		#end
	}
	
	/**
		Resizes the memory to `byteSize` bytes.
		<assert>bytes <= 0</assert>
		<assert>memory was already deallocated</assert>
	**/
	public function resize(byteSize:Int)
	{
		assert(byteSize > 0);
		assert(mMemory != null, "memory deallocated");
		
		bytes = byteSize;
		
		#if alchemy
		MemoryManager.instance.realloc(this, byteSize);
		#end
	}
}