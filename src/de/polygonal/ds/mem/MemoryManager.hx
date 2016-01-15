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

#if (alchemy && !flash)
"MemoryManager is only available when targeting flash"
#end

/**
	Manages fast "alchemy memory"
	
	See <a href="http://lab.polygonal.de/2009/03/14/a-little-alchemy-in-hx3ds/" target="_blank">http://lab.polygonal.de/2009/03/14/a-little-alchemy-in-hx3ds/</a>.
	See <a href="http://lab.polygonal.de/2010/03/15/memorymanager-revisited/" target="_blank">http://lab.polygonal.de/2010/03/15/memorymanager-revisited/</a>
**/
@:access(de.polygonal.ds.mem.MemorySegment)
@:access(de.polygonal.ds.mem.MemoryAccess)
class MemoryManager
{
	public static var instance(get_instance, never):MemoryManager;
	static function get_instance():MemoryManager return mInstance == null ? (mInstance = new MemoryManager()) : mInstance;
	static var mInstance:MemoryManager = null;
	
	/**
		Releases all allocated memory and nullifies references for GC'ing used resources.
	**/
	public static function free()
	{
		if (mInstance != null) mInstance._free();
		mInstance = null;
	}
	
	/**
		The total number of bytes that are preallocated prior to the first call to `malloc()`.
		
		Default is 0 bytes.
	**/
	public static var RESERVE_BYTES = 0;
	
	/**
		The total number bytes that the user is allowed to allocate (1 MiB equals 1.048.576 bytes).
		
		This should be used as a safe upper limit for detecting memory leaks during development.
		
		The default value is 64 MiB.
	**/
	public static var MEMORY_LIMIT_BYTES = 64 << 20;
	
	/**
		The minimum block size for allocating additional memory on the fly.
		
		The default value is 64 KiB. The minimum value is 1024 bytes or 1 KiB.
		
		<warn>Changing this value has no effect after memory has been allocated for the first time.</warn>
	**/
	public static var BLOCK_SIZE_BYTES = 1024 << 6;
	
	/**
		A reserved, fixed portion of bytes at the beginning of the byte array which can be used as a temporary buffer or for doing math tricks.
		
		<warn>Changing this value has no effect after memory has been allocated for the first time.</warn>
	**/
	public static var RAW_BYTES = 1024;
	
	#if flash
	/**
		If true, allocated memory will be automatically freed when the reference to a `MemoryAccess` object is garbage collected.
	**/
	public static var AUTO_RECLAIM_MEMORY = false;
	
	/**
		The update rate in seconds for the weak reference monitor that detects GCed `MemoryAccess` objects.
		
		A smaller value requires more CPU time but releases memory earlier.
		
		The default value is 0.25 seconds.
	**/
	public static var AUTO_RECLAIM_INTERVAL = 0.25;
	#end
	
	/**
		Returns the total number of used bytes.
	**/
	public var bytesUsed:Int;
	
	/**
		Returns the total number of allocated bytes.
	**/
	public var bytesTotal:Int;
	
	#if alchemy
	var mBytes:flash.utils.ByteArray;
	#end
	
	var mSegmentList:MemorySegment;
	var mBytesRaw:Int;
	var mBlockSizeBytes:Int;
	var mBlockSizeShift:Int;
	var mChanged:Bool;
	
	function new()
	{
		assert(M.isPow2(BLOCK_SIZE_BYTES));
		assert(BLOCK_SIZE_BYTES >= 1024);
		assert(RAW_BYTES >= 1024);
		
		mBlockSizeBytes = BLOCK_SIZE_BYTES;
		mBlockSizeShift = Bits.ntz(mBlockSizeBytes);
		mBytesRaw = RAW_BYTES;
		bytesUsed = 0;
		bytesTotal = mBlockSizeBytes;
		
		mSegmentList = new MemorySegment(this, mBytesRaw);
		mSegmentList.expandRight(bytesTotal);
		
		#if alchemy
			mBytes = new flash.utils.ByteArray();
			#if flash
			var tmp = new Array<Int>();
			for (i in 0...1024) tmp[i] = flash.Memory.getByte(i);
			mBytes.length = mBytesRaw + bytesTotal;
			flash.Memory.select(null);
			flash.Memory.select(mBytes);
			for (i in 0...1024) flash.Memory.setByte(i, tmp[i]);
			#elseif cpp
			mBytes.setLength(mBytesRaw + bytesTotal);
			flash.Memory.select(null);
			flash.Memory.select(mBytes);
			#end
		#end
		
		if (RESERVE_BYTES > 0) grow(RESERVE_BYTES);
	}
	
	#if (alchemy && flash)
	/**
		The byte array that is managed by this memory manager.
	**/
	public var bytes(get_bytes, never):flash.utils.ByteArray;
	inline function get_bytes():flash.utils.ByteArray return mBytes;
	#end
	
	/**
		The total number of `ArrayAccess` objects that have access to the heap.
	**/
	public function size():Int
	{
		var c = 0;
		var node = mSegmentList;
		while (node != null)
		{
			if (!node.isEmpty) c++;
			node = node.next;
		}
		return c;
	}
	
	public function dump():String
	{
		#if (flash && alchemy)
		var s = '{ MemoryManager, ${bytesTotal} bytes total, ${bytesFree} bytes free (${mBytes.length - mBlockSizeBytes}) }';
		s += "\n[ front\n";
		var i = mSegmentList;
		var j = 0;
		while (i != null)
		{
			s += Printf.format("  %4d -> %s (%s)\n", [j++, Std.string(i), i.mAccess]);
			i = i.next;
		}
		s += "]";
		return s;
		#else
		return "{ MemoryManager }";
		#end
	}
	
	/**
		Returns the total number of free bytes (allocated but unused).
	**/
	public var bytesFree(get_bytesFree, never):Int;
	inline function get_bytesFree():Int return bytesTotal - bytesUsed;
	
	/**
		Copies `n` bytes from the location pointed by the index `source` to the location pointed by the index `destination`.
		
		Copying takes place as if an intermediate buffer was used, allowing the destination and source to overlap.
		
		See <a href="http://www.cplusplus.com/reference/clibrary/cstring/memmove/" target="_blank">http://www.cplusplus.com/reference/clibrary/cstring/memmove/</a>
		<assert>invalid `destination`, `source` or `n` value</assert>
	**/
	#if (flash && alchemy)
	public function memmove(destination:Int, source:Int, n:Int)
	{
		assert(destination >= 0 && source >= 0 && n >= 0);
		assert(source < Std.int(mBytes.length), "source < Std.int(bytes.length)");
		assert(destination + n <= Std.int(mBytes.length), "destination + n <= Std.int(bytes.length)");
		assert(n <= Std.int(mBytes.length), "n <= Std.int(bytes.length)");
		
		if (source == destination)
			return;
		else
		if (source <= destination)
		{
			var i = source + n;
			var j = destination + n;
			for (k in 0...n)
			{
				i--;
				j--;
				flash.Memory.setByte(j, flash.Memory.getByte(i));
			}
		}
		else
		{
			var i = source;
			var j = destination;
			for (k in 0...n)
			{
				flash.Memory.setByte(j, flash.Memory.getByte(i));
				i++;
				j++;
			}
		}
	}
	#end
	
	/**
		Allocates and assigns `numBytes` to be accessed by `access`.
	**/
	public function malloc(access:MemoryAccess, numBytes:Int)
	{
		mChanged = true;
		
		//check upper limit
		assert(bytesUsed + numBytes < MEMORY_LIMIT_BYTES, 'OOM (failed to allocate $numBytes bytes, ${bytesUsed} out of ${bytesTotal} bytes used)');
		assert(numBytes > 0, "invalid numBytes");
		assert(access != null, "invalid access");
		assert(access.mMemory == null, "access already allocated");
		
		//allocate more memory?
		var bytesLeft = bytesTotal - bytesUsed;
		if (numBytes > bytesLeft)
			grow(numBytes);
		
		//update usage count
		bytesUsed += numBytes;
		
		//find interval
		var memory = findEmptySpace(numBytes);
		
		//defragmentation is needed
		if (memory == null)
		{
			defrag();
			memory = findEmptySpace(numBytes);
		}
		
		//setup access
		access.mMemory = memory;
		memory.setAccess(access);
		memory.setOffset();
	}
	
	/**
		Deallocates the memory used by `access`.
	**/
	public function dealloc(access:MemoryAccess)
	{
		assert(access != null, "invalid access");
		assert(access.mMemory != null, "access already deallocated");
		
		//resolve memory from access
		var memory:MemorySegment = access.mMemory;
		access.mMemory = null;
		
		access.name = "?";
		
		#if flash
		memory.stopMonitor();
		#end
		memory.wipe();
		memory.isEmpty = true;
		
		//update usage count
		bytesUsed -= memory.size;
		
		//try to merge adjacent empty intervals
		if (memory.next != null)
		{
			if (memory.next.isEmpty)
				mergeRight(memory);
		}
		else
		if (memory.prev != null)
		{
			if (memory.prev.isEmpty)
				mergeLeft(memory);
		}
		else
			memory.free();
	}
	
	/**
		Resizes `access` to match `numBytes`.
	**/
	public function realloc(access:MemoryAccess, numBytes:Int)
	{
		mChanged = true;
		
		assert(access != null, "invalid access");
		assert(numBytes > 0, "invalid numBytes");
		assert(access.mMemory != null, "access already deallocated");
		
		//resolve memory from access
		var memory:MemorySegment = access.mMemory;
		
		assert(!memory.isEmpty, "invalid access");
		
		//early out; no change in size
		if (numBytes == memory.size) return;
		
		//grow or shrink?
		if (numBytes > memory.size)
		{
			//grow
			var bytesLeft = numBytes - memory.size;
			
			var m = memory;
			var i = memory.prev;
			
			//find first empty interval left of m
			while (i != null && !i.isEmpty) i = i.prev;
			
			//allocate more memory?
			if (i == null)
			{
				grow(bytesLeft);
				i = mSegmentList;
			}
			
			//eat up space in empty intervals and add to m
			while (bytesLeft > 0)
			{
				var bytesToEat = M.min(i.size, bytesLeft);
				bytesLeft -= bytesToEat;
				
				bytesUsed += bytesToEat;
				
				if (i.next == m)
				{
					//resize m
					//[i    ][m] ==> [i][mxxx]
					_memmove(i.next.b - bytesToEat, i.next.b, i.next.size, i.offset);
					wipe(i.next.e - bytesToEat + 1, bytesToEat, i.offset);
					
					i.shrinkLeft(bytesToEat);
					i.next.expandLeft(bytesToEat);
					i.next.setOffset();
					
					if (i.size == 0)
					{
						//drop empty interval
						if (i == mSegmentList) mSegmentList = mSegmentList.next;
						var t = i.next;
						if (i.prev != null) i.prev.next = i.next;
						if (i.next != null) i.next.prev = i.prev;
						i.free();
						i = t;
					}
				}
				else
				{
					//make room next to m by shifting non-empty intervals to the left
					//[i   ][full][full][m] ==> [i][full][full][   m]
					i.shrinkLeft(bytesToEat);
					
					var j = i.next;
					while (j != m)
					{
						_memmove(j.b - bytesToEat, j.b, j.size, j.offset);
						j.shiftLeft(bytesToEat);
						j.setOffset();
						j = j.next;
					}
					
					//[   m] ==> [mxxx]
					//move data
					_memmove(m.b - bytesToEat, m.b, m.size, m.offset);
					wipe(m.e - bytesToEat + 1, bytesToEat, m.offset);
					
					//update intervals
					m.shiftLeft(bytesToEat);
					m.expandRight(bytesToEat);
					m.setOffset();
				}
				
				//done
				if (bytesLeft == 0) break;
				
				//find next empty interval
				i = i.prev;
				while (i != null && !i.isEmpty) i = i.prev;
				
				if (i == null)
				{
					//allocate more space
					grow(bytesLeft);
					i = mSegmentList;
				}
			}
		}
		else
		{
			//shrink; shift data to the right
			var gap = memory.size - numBytes;
			var b = memory.b;
			
			_memmove(b + gap, b, numBytes, memory.offset);
			wipe(b, gap, memory.offset);
			memory.shiftRight(gap);
			memory.shrinkLeft(gap);
			memory.setOffset();
			
			bytesUsed -= gap;
			
			if (memory.prev != null)
			{
				if (memory.prev.isEmpty)
				{
					//refit empty interval to close gap
					memory.prev.expandRight(gap);
				}
				else
				{
					//previous interval is full
					//fill gap with an empty interval
					var i = new MemorySegment(this, mBytesRaw);
					i.b = b;
					i.expandRight(gap);
					
					//insert into linked list
					i.next = memory;
					i.prev = memory.prev;
					
					memory.prev.next = i;
					memory.prev = i;
				}
			}
			else
			{
				//fill gap with an empty interval
				var i = new MemorySegment(this, mBytesRaw);
				i.expandRight(gap);
				
				//prepend
				memory.prev = i;
				i.next = memory;
				mSegmentList = i;
			}
		}
	}
	
	/**
		Releases unused memory.
	**/
	public function pack()
	{
		mChanged = true;
		
		if (bytesUsed == 0) return;
		var freeBytes = bytesTotal - bytesUsed;
		var numBuckets = freeBytes >> mBlockSizeShift;
		if (numBuckets == 0) return;
		
		//make sure at least one bucket survives
		if (numBuckets == (bytesTotal >> mBlockSizeShift)) numBuckets--;
		if (numBuckets == 0) return;
		
		//always defrag first
		if (bytesUsed > 0) defrag();
		
		var rawOffset = mBytesRaw;
		var freeSpaceBefore = numBuckets << mBlockSizeShift;
		
		//update total memory
		bytesTotal -= freeSpaceBefore;
		
		//copy "raw" bytes to the start of the byte array while "data" bytes go to the end of the byte array
		#if alchemy
		var copy = new flash.utils.ByteArray();
		
			#if flash
			copy.length = rawOffset + bytesTotal;
			for (i in 0...mBytesRaw) copy[i] = mBytes[i];
			for (i in 0...bytesTotal) copy[rawOffset + i] = mBytes[rawOffset + freeSpaceBefore + i];
			#elseif cpp
			copy.setLength(rawOffset + bytesTotal);
			for (i in 0...mBytesRaw) copy.__set(i, mBytes.__get(i));
			for (i in 0...bytesTotal) copy.__set(rawOffset + i, mBytes.__get(rawOffset + freeSpaceBefore + i));
			#end
		
		//register bytes
		flash.Memory.select(null);
		flash.Memory.select(copy);
		mBytes = copy;
		#end
		
		mSegmentList.shrinkLeft(freeSpaceBefore);
		
		var i = mSegmentList.next;
		while (i != null)
		{
			i.shiftLeft(freeSpaceBefore);
			i.setOffset();
			i = i.next;
		}
		
		//drop empty interval
		if (mSegmentList.size == 0)
		{
			mSegmentList = mSegmentList.next;
			mSegmentList.prev = null;
		}
	}
	
	/**
		Performs a full defragmentation of the allocated memory.
	**/
	public function defrag()
	{
		mChanged = true;
		
		if (bytesUsed == bytesTotal) return;
		
		var i1 = mSegmentList.next;
		
		//empty list
		if (i1 == null) return;
		
		var offset = i1.offset;
		
		//find tail
		while (i1.next != null) i1 = i1.next;
		
		//iterate from tail to head
		while (i1.prev != null)
		{
			var i0 = i1.prev;
			if (i1.isEmpty)
			{
				if (!i0.isEmpty)
				{
					//move data
					var t = i0.size - i1.size;
					if (t == 0)
					{
						//exact fit [i0][i1]
						_memmove(i1.b, i0.b, i0.size, offset);
					}
					else
					if (t < 0)
					{
						//fits [i0][  i1  ]
						_memmove(i1.e - i0.size + 1, i0.b, i0.size, offset);
						
						i0.expandRight(-t);
						i1.shrinkRight(-t);
					}
					else
					if (t > 0)
					{
						//does not fit [  i0  ][i1]
						_memmove(i0.b + i1.size, i0.b, i0.size, offset);
						
						i1.expandLeft(t);
						i0.shrinkLeft(t);
					}
					
					//assign accessor to other area
					i1.setAccess(i0.getAccess());
					i0.setAccess(null);
					i1.setOffset();
					i1.getAccess().mMemory = i1;
					
					//update state
					i1.isEmpty = false;
					i0.isEmpty = true;
				}
				else
				{
					//merge empty intervals
					mergeRight(i0);
					i1 = i0.next;
				}
			}
			
			i1 = i1.prev;
		}
		
		//zero out empty space
		mSegmentList.wipe();
	}
	
	function _free()
	{
		if (mInstance == null) return;
		
		while (mSegmentList != null)
		{
			var next = mSegmentList.next;
			mSegmentList.free();
			mSegmentList = next;
		}
		
		#if flash
		if (MemorySegment.monitor != null)
		{
			MemorySegment.monitor.stop();
			MemorySegment.monitor = null;
		}
		#end
		
		#if alchemy
		flash.Memory.select(null);
			#if flash
			mBytes.length = 0;
			#elseif cpp
			mBytes.setLength(0);
			#end
		mBytes = null;
		#end
	}
	
	function grow(numBytes:Int)
	{
		//calculate #required buckets
		var requiredBuckets = M.max(1, Math.ceil((bytesUsed + numBytes - bytesTotal) / mBlockSizeBytes));
		var curBuckets = bytesTotal >> mBlockSizeShift;
		var maxBuckets = requiredBuckets + curBuckets;
		var requiredBytes = maxBuckets << mBlockSizeShift;
		var freeSpace = requiredBytes - bytesTotal;
		var rawOffset = mBytesRaw;
		
		#if alchemy
		//copy "raw" bytes to the start of the byte array while "data" bytes go to the end of the byte array
		var copy = new flash.utils.ByteArray();
		#if flash
		copy.length = rawOffset + requiredBytes;
		for (i in 0...mBytesRaw) copy[i] = flash.Memory.getByte(i);
		for (i in 0...bytesTotal) copy[rawOffset + freeSpace + i] = flash.Memory.getByte(rawOffset + i);
		#elseif cpp
		copy.setLength(rawOffset + requiredBytes);
		for (i in 0...mBytesRaw) copy.__set(i, flash.Memory.getByte(i));
		for (i in 0...bytesTotal) copy.__set(rawOffset + freeSpace + i, flash.Memory.getByte(rawOffset + i));
		#end
		//register bytes
		flash.Memory.select(null);
		flash.Memory.select(copy);
		mBytes = copy;
		#end
		
		bytesTotal = requiredBytes;
		
		//shift all intervals to the end, but exclude first interval (if empty)
		var i = mSegmentList;
		if (i.isEmpty) i = i.next;
		while (i != null)
		{
			i.shiftRight(freeSpace);
			i.setOffset();
			i = i.next;
		}
		
		//adjust first interval to cover the extra space or create new one
		if (mSegmentList.isEmpty)
		{
			//just expand empty interval to cover the extra space
			mSegmentList.expandRight(freeSpace);
		}
		else
		{
			//span interval over extra space
			var i = new MemorySegment(this, rawOffset);
			i.expandRight(freeSpace);
			
			//append to interval list
			i.next = mSegmentList;
			mSegmentList.prev = i;
			mSegmentList = i;
		}
	}
	
	function wipe(destination:Int, size:Int, offset:Int)
	{
		#if alchemy
		for (i in offset...size + offset) flash.Memory.setByte(destination + i, 0);
		#end
	}
	
	function findEmptySpace(size:Int):MemorySegment
	{
		var m = mSegmentList;
		var j = 0;
		
		while (m != null)
		{
			if (m.isEmpty)
			{
				//found interval
				if (m.size >= size)
				{
					//exact match
					if (m.size == size)
					{
						m.isEmpty = false;
						return m;
					}
					else
					{
						//split in half
						var m1 = m.copy();
						m1.isEmpty = false;
						
						m.shrinkLeft(size);
						m1.shrinkRight(m.size);
						
						m1.prev = m;
						m1.next = m.next;
						
						if (m.next != null)
							m.next.prev = m1;
						
						m.next = m1;
						
						return m1;
					}
				}
			}
			
			m = m.next;
		}
		
		return null;
	}
	
	function mergeLeft(m:MemorySegment)
	{
		//merge m and m.prev
		var m0 = m.prev;
		
		m.b = m0.b;
		m.size = m.e - m.b + 1;
		
		m.prev = m0.prev;
		if (m.prev != null) m.prev.next = m;
		
		m0.free();
		
		//update head
		if (m.prev == null)
			mSegmentList = m;
	}
	
	function mergeRight(m:MemorySegment)
	{
		//merge m and m.next
		var m1 = m.next;
		
		m.e = m1.e;
		m.size = m.e - m.b + 1;
		
		m.next = m1.next;
		if (m.next != null) m.next.prev = m;
		
		m1.free();
	}
	
	function _memmove(destination:Int, source:Int, n:Int, offset:Int)
	{
		#if alchemy
		if (source == destination)
			return;
		else
		if (source <= destination)
		{
			var i = offset + source + n - 1;
			var j = offset + destination + n - 1;
			for (k in 0...n)
			{
				flash.Memory.setByte(j, flash.Memory.getByte(i));
				i--;
				j--;
			}
		}
		else
		{
			var i = offset + source;
			var j = offset + destination;
			for (k in 0...n)
			{
				flash.Memory.setByte(j, flash.Memory.getByte(i));
				i++;
				j++;
			}
		}
		#end
	}
}

@:access(de.polygonal.ds.mem.MemoryAccess)
private class MemorySegment
{
	public var next:MemorySegment;
	public var prev:MemorySegment;

	public var b:Int;
	public var e:Int;
	
	public var isEmpty:Bool;
	public var size:Int;
	
	public var manager:MemoryManager;
	public var offset:Int;
	
	var mAccess:MemoryAccess;
	
	public function new(manager:MemoryManager, offset:Int)
	{
		this.manager = manager;
		this.offset = offset;
		b = e = size = 0;
		isEmpty = true;
	}
	
	public function free()
	{
		#if flash
		if (monitor != null) monitor.removeEventListener(flash.events.TimerEvent.TIMER, checkPointer);
		mWeakPointer = null;
		#end
		
		prev = null;
		next = null;
		manager = null;
		mAccess = null;
		b = -1;
		e = -1;
		size = -1;
		offset = -1;
	}
	
	inline public function shiftLeft(x:Int)
	{
		b -= x;
		e -= x;
		setOffset();
	}
	
	inline public function shiftRight(x:Int)
	{
		b += x;
		e += x;
		setOffset();
	}
	
	inline public function expandLeft(s:Int)
	{
		size += s;
		b = e - size + 1;
	}
	
	inline public function shrinkLeft(s:Int)
	{
		size -= s;
		e = b + size - 1;
	}
	
	inline public function expandRight(s:Int)
	{
		size += s;
		e = b + size - 1;
	}
	
	inline public function shrinkRight(s:Int)
	{
		size -= s;
		b = e - size + 1;
	}
	
	inline public function setOffset()
	{
		#if alchemy
		var access = getAccess();
		if (access != null) untyped access.offset = offset + b;
		#end
	}
	
	inline public function wipe()
	{
		#if alchemy
		for (i in offset...offset + size) flash.Memory.setByte(b + i, 0);
		#end
	}
	
	inline public function getAccess():MemoryAccess
	{
		#if flash
		if (MemoryManager.AUTO_RECLAIM_MEMORY)
		{
			var t:Array<Dynamic> = untyped __keys__(mWeakPointer);
			return untyped __keys__(mWeakPointer)[0];
		}
		else
		#end
			return mAccess;
	}
	
	inline public function setAccess(x:MemoryAccess)
	{
		#if flash
		if (MemoryManager.AUTO_RECLAIM_MEMORY)
		{
			if (mWeakPointer != null)
			{
				//update
				untyped __delete__(mWeakPointer, getAccess());
				
				if (x != null)
					untyped mWeakPointer[x] = 1;
			}
			else
			{
				if (x == null)
				{
					monitor.removeEventListener(flash.events.TimerEvent.TIMER, checkPointer);
					mWeakPointer = null;
				}
				else
				{
					mWeakPointer = new flash.utils.Dictionary(true);
					untyped mWeakPointer[x] = 1;
					if (monitor == null)
					{
						monitor = new flash.utils.Timer(MemoryManager.AUTO_RECLAIM_INTERVAL * 1000);
						monitor.start();
					}
					monitor.addEventListener(flash.events.TimerEvent.TIMER, checkPointer, false, 0, true);
				}
			}
		}
		else
		#end
			mAccess = x;
	}
	
	public function copy():MemorySegment
	{
		var copy = new MemorySegment(manager, offset);
		copy.b = b;
		copy.e = e;
		copy.isEmpty = isEmpty;
		copy.size = size;
		return copy;
	}
	
	public function toString():String
	{
		#if debug
		return '{ MemorySegment range: $b...$e, bytes: $size, isEmpty: $isEmpty }';
		#else
		return '{ MemorySegment bytes: $size }';
		#end
	}
	
	#if flash
	var mWeakPointer:flash.utils.Dictionary;
	public static var monitor:flash.utils.Timer;
	public static var listenerCount = 0;
	
	function stopMonitor()
	{
		if (MemoryManager.AUTO_RECLAIM_MEMORY)
		{
			if (mWeakPointer != null)
			{
				monitor.removeEventListener(flash.events.TimerEvent.TIMER, checkPointer);
				mWeakPointer = null;
			}
		}
	}
	
	function checkPointer(e:flash.events.TimerEvent)
	{
		var keys:Array<Dynamic> = untyped __keys__(mWeakPointer);
		for (key in keys) return;
		
		monitor.removeEventListener(flash.events.TimerEvent.TIMER, checkPointer);
		mWeakPointer = null;
		
		var fakeAccess:MemoryAccess = Type.createEmptyInstance(MemoryAccess);
		fakeAccess.mMemory = this;
		MemoryManager.instance.dealloc(fakeAccess);
	}
	#end
}