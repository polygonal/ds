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
package de.polygonal.ds.mem;

import de.polygonal.ds.error.Assert.assert;
import de.polygonal.ds.Bits;

private typedef MemoryAccessFriend =
{
	private var _memory:MemorySegment;
}

/**
 * <p>Manages fast "alchemy memory".</p>
 * <p>See <a href="http://lab.polygonal.de/2009/03/14/a-little-alchemy-in-hx3ds/" target="_blank">http://lab.polygonal.de/2009/03/14/a-little-alchemy-in-hx3ds/</a>.</p>
 * <p>See <a href="http://lab.polygonal.de/2010/03/15/memorymanager-revisited/" target="_blank">http://lab.polygonal.de/2010/03/15/memorymanager-revisited/</a>
 */
class MemoryManager
{
	static var _instance:MemoryManager = null;
	inline public static function get():MemoryManager
	{
		return _instance == null ? (_instance = new MemoryManager()) : _instance;
	}
	
	/**
	 * The total number of bytes that are preallocated prior to the first call to <em>malloc()</em>.<br/>
	 * Default is 0 bytes.
	 */
	public static var RESERVE_BYTES = 0;
	
	/**
	 * The total number bytes that the user is allowed to allocate (1 MiB equals 1.048.576 bytes).<br/>
	 * This should be used as a safe upper limit for detecting memory leaks during development.<br/>
	 * The default value is 64 MiB.
	 */
	public static var MEMORY_LIMIT_BYTES = 64 << 20;
	
	/**
	 * The minimum block size for allocating additional memory on the fly.<br/>
	 * The default value is 64 KiB. The minimum value is 1024 bytes or 1 KiB.<br/>
	 * <warn>Changing this value has no effect after memory has been allocated for the first time.</warn>
	 */
	public static var BLOCK_SIZE_BYTES = 1024 << 6;
	
	/**
	 * A reserved, fixed portion of bytes at the beginning of the byte array which can be used as a temporary buffer or for doing math tricks.<br/>
	 * <warn>Changing this value has no effect after memory has been allocated for the first time.</warn>
	 */
	public static var RAW_BYTES = 1024;
	
	#if flash
	/**
	 * If true, allocated memory will be automatically freed when the reference to a <em>MemoryAccess</em> object is garbage collected.
	 */
	public static var AUTO_RECLAIM_MEMORY = false;
	
	/**
	 * The update rate in seconds for the weak reference monitor that detects GCed <em>MemoryAccess</em> objects.<br/>
	 * A smaller value requires more CPU time but releases memory earlier.<br/>
	 * The default value is 0.25 seconds.
	 */
	public static var AUTO_RECLAIM_INTERVAL = 0.25;
	#end
	
	/**
	 * Releases all allocated memory and nullifies references for GC'ing used resources. 
	 */
	public static function free()
	{
		if (_instance != null) _instance._free();
		_instance = null;
	}
	
	#if (alchemy && flash)
	/**
	 * The byte array that is managed by this memory manager. 
	 */
	public static function bytes():flash.utils.ByteArray { return get()._bytes; }
	#end
	
	/**
	 * Returns the total number of allocated bytes. 
	 */
	public static function bytesTotal():Int { return get()._bytesTotal; }
	
	/**
	 * Returns the total number of used bytes. 
	 */
	public static function bytesUsed():Int { return get()._bytesUsed; }
	
	/**
	 * Returns the total number of free bytes (allocated but unused).
	 */
	public static function bytesFree():Int { return bytesTotal() - bytesUsed(); }
	
	/**
	 * The total number of <em>ArrayAccess</em> objects that have access to the heap.
	 */
	public static function size():Int
	{
		var c = 0;
		var node = get()._segmentList;
		while (node != null)
		{
			if (!node.isEmpty) c++;
			node = node.next; 
		}
		return c;
	}
	
	/**
	 * Allocates and assigns <code>numBytes</code> to be accessed by <code>accessor</code>. 
	 */
	public static function malloc(accessor:MemoryAccess, numBytes:Int)
	{
		get()._malloc(accessor, numBytes);
		get()._changed = true;
	}
	
	/**
	 * Deallocates the memory used by <code>accessor</code>. 
	 */
	public static function dealloc(accessor:MemoryAccess)
	{
		get()._dealloc(accessor);
		get()._changed = true;
	}
	
	/**
	 * Resizes <code>accessor</code> to match <code>numBytes</code>. 
	 */
	public static function realloc(accessor:MemoryAccess, numBytes:Int)
	{
		get()._realloc(accessor, numBytes);
		get()._changed = true;
	}
	
	/**
	 * Performs a full defragmentation of the allocated memory. 
	 */
	public static function defrag()
	{
		get()._defrag();
		get()._changed = true;
	}
	
	/**
	 * Releases unused memory. 
	 */
	public static function pack()
	{
		get()._pack();
		get()._changed = true;
	}
	
	/**
	 * Copies <code>n</code> bytes from the location pointed by the index <code>source</code> to the location pointed by the index <code>destination</code>.<br/>
	 * Copying takes place as if an intermediate buffer was used, allowing the destination and source to overlap.
	 * @throws de.polygonal.ds.error.AssertError invalid <code>destination</code>, <code>source</code> or <code>n</code> value (debug only).
	 * @see <a href="http://www.cplusplus.com/reference/clibrary/cstring/memmove/" target="_blank">http://www.cplusplus.com/reference/clibrary/cstring/memmove/</a>
	 */
	#if (flash10 && alchemy)
	inline public static function memmove(destination:Int, source:Int, n:Int)
	{
		#if debug
		assert(destination >= 0 && source >= 0 && n >= 0, "destination >= 0 && source >= 0 && n >= 0");
		assert(source < Std.int(bytes().length), "source < Std.int(bytes.length)");
		assert(destination + n <= Std.int(bytes().length), "destination + n <= Std.int(bytes.length)");
		assert(n <= Std.int(bytes().length), "n <= Std.int(bytes.length)");
		#end
		
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
	
	public static function dump():String
	{
		#if alchemy
		var s = '{ MemoryManager, ${bytesTotal()} bytes total, ${bytesFree()} bytes free (${get()._bytes.length - get()._blockSizeBytes}) }';
		s += "\n[ front\n";
		var i = get()._segmentList;
		var j = 0;
		while (i != null)
		{
			var friend:{private var _access:MemoryAccess;} = i;
			s += Printf.format("  %4d -> %s (%s)\n", [j++, Std.string(i), friend._access]);
			i = i.next;
		}
		s += "]";
		return s;
		#else
		return "{ MemoryManager }";
		#end
	}
	
	var _segmentList:MemorySegment;
	
	#if alchemy
	var _bytes:flash.utils.ByteArray;
	#end
	
	var _bytesUsed:Int;
	
	var _bytesTotal:Int;
	var _bytesRaw:Int;
	
	var _blockSizeBytes:Int;
	var _blockSizeShift:Int;
	
	var _changed:Bool;
	
	function new()
	{
		#if debug
		assert(M.isPow2(BLOCK_SIZE_BYTES), "M.isPow2(BLOCK_SIZE_BYTES)");
		assert(BLOCK_SIZE_BYTES >= 1024, "BLOCK_SIZE_BYTES >= 1024");
		assert(RAW_BYTES >= 1024, "RAW_BYTES >= 1024");
		#end
		
		_blockSizeBytes = BLOCK_SIZE_BYTES;
		_blockSizeShift = Bits.ntz(_blockSizeBytes);
		_bytesRaw     = RAW_BYTES;
		_bytesUsed    = 0;
		_bytesTotal   = _blockSizeBytes;
		
		_segmentList = new MemorySegment(this, _bytesRaw);
		_segmentList.expandRight(_bytesTotal);
		
		#if alchemy
			_bytes = new flash.utils.ByteArray();
			#if flash10
			var tmp = new Array<Int>();
			for (i in 0...1024) tmp[i] = flash.Memory.getByte(i);
			_bytes.length = _bytesRaw + _bytesTotal;
			flash.Memory.select(null);
			flash.Memory.select(_bytes);
			for (i in 0...1024) flash.Memory.setByte(i, tmp[i]);
			#elseif cpp
			_bytes.setLength(_bytesRaw + _bytesTotal);
			flash.Memory.select(null);
			flash.Memory.select(_bytes);
			#end
		#end
		
		if (RESERVE_BYTES > 0) _grow(RESERVE_BYTES);
	}
	
	function _free()
	{
		while (_segmentList != null)
		{
			var next = _segmentList.next;
			_segmentList.free();
			_segmentList = next;
		}
		
		#if flash9
		if (MemorySegment.monitor != null)
		{
			MemorySegment.monitor.stop();
			MemorySegment.monitor = null;
		}
		#end
		
		#if alchemy
		flash.Memory.select(null);
			#if flash
			_bytes.length = 0;
			#elseif cpp
			_bytes.setLength(0);
			#end
		_bytes = null;
		#end
	}
	
	function _malloc(access:MemoryAccess, numBytes:Int)
	{
		#if debug
		//check upper limit
		assert(_bytesUsed + numBytes < MEMORY_LIMIT_BYTES, 'OOM (failed to allocate $numBytes bytes, ${bytesUsed()} out of ${bytesTotal()} bytes used)');
		assert(numBytes > 0, "invalid numBytes");
		assert(access != null, "invalid access");
		assert(__getMem(access) == null, "access already allocated");
		#end
		
		//allocate more memory?
		var bytesLeft = _bytesTotal - _bytesUsed;
		if (numBytes > bytesLeft)
			_grow(numBytes);
		
		//update usage count
		_bytesUsed += numBytes;
		
		//find interval
		var memory = _findEmptySpace(numBytes);
		
		//defragmentation is needed
		if (memory == null)
		{
			_defrag();
			memory = _findEmptySpace(numBytes);
		}
		
		//setup access
		__setMem(access, memory);
		memory.setAccess(access);
		memory.setOffset();
	}
	
	function _dealloc(access:MemoryAccess)
	{
		#if debug
		assert(access != null, "invalid access");
		assert(__getMem(access) != null, "access already deallocated");
		#end
		
		//resolve memory from access
		var memory:MemorySegment = __getMem(access);
		__setMem(access, null);
		
		access.name = "?";
		
		#if flash9
		memory.stopMonitor();
		#end
		memory.wipe();
		memory.isEmpty = true;
		
		//update usage count
		_bytesUsed -= memory.size;
		
		//try to merge adjacent empty intervals
		if (memory.next != null)
		{
			if (memory.next.isEmpty)
				_mergeRight(memory);
		}
		else
		if (memory.prev != null)
		{
			if (memory.prev.isEmpty)
				_mergeLeft(memory);
		}
		else
			memory.free();
	}
	
	function _realloc(access:MemoryAccess, numBytes:Int)
	{
		#if debug
		assert(access != null, "invalid access");
		assert(numBytes > 0, "invalid numBytes");
		assert(__getMem(access) != null, "access already deallocated");
		#end
		
		//resolve memory from access
		var memory = __getMem(access);
		
		#if debug
		assert(!memory.isEmpty, "invalid access");
		#end
		
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
				_grow(bytesLeft);
				i = _segmentList;
			}
			
			//eat up space in empty intervals and add to m
			while (bytesLeft > 0)
			{
				var bytesToEat = M.min(i.size, bytesLeft);
				bytesLeft -= bytesToEat;
				
				_bytesUsed += bytesToEat;
				
				if (i.next == m)
				{
					//resize m
					//[i    ][m] ==> [i][mxxx]
					_memmove(i.next.b - bytesToEat, i.next.b, i.next.size, i.offset);
					_wipe(i.next.e - bytesToEat + 1, bytesToEat, i.offset);
					
					i.shrinkLeft(bytesToEat);
					i.next.expandLeft(bytesToEat);
					i.next.setOffset();
					
					if (i.size == 0)
					{
						//drop empty interval
						if (i == _segmentList) _segmentList = _segmentList.next;
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
					_wipe(m.e - bytesToEat + 1, bytesToEat, m.offset);
					
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
					_grow(bytesLeft);
					i = _segmentList;
				}
			}
		}
		else
		{
			//shrink; shift data to the right
			var gap = memory.size - numBytes;
			var b = memory.b;
			
			_memmove(b + gap, b, numBytes, memory.offset);
			_wipe(b, gap, memory.offset);
			memory.shiftRight(gap);
			memory.shrinkLeft(gap);
			memory.setOffset();
			
			_bytesUsed -= gap;
			
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
					var i = new MemorySegment(this, _bytesRaw);
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
				var i = new MemorySegment(this, _bytesRaw);
				i.expandRight(gap);
				
				//prepend
				memory.prev = i;
				i.next = memory;
				_segmentList = i;
			}
		}
	}
	
	function _grow(numBytes:Int)
	{
		//calculate #required buckets
		var requiredBuckets = M.max(1, Math.ceil((_bytesUsed + numBytes - _bytesTotal) / _blockSizeBytes));
		var curBuckets      = _bytesTotal >> _blockSizeShift;
		var maxBuckets      = requiredBuckets + curBuckets;
		var requiredBytes   = maxBuckets << _blockSizeShift;
		var freeSpace       = requiredBytes - _bytesTotal;
		var rawOffset       = _bytesRaw;
		
		#if alchemy
		//copy "raw" bytes to the start of the byte array while "data" bytes go to the end of the byte array
		var copy = new flash.utils.ByteArray();
		#if flash
		copy.length = rawOffset + requiredBytes;
		for (i in 0..._bytesRaw) copy[i] = flash.Memory.getByte(i);
		for (i in 0..._bytesTotal) copy[rawOffset + freeSpace + i] = flash.Memory.getByte(rawOffset + i);
		#elseif cpp
		copy.setLength(rawOffset + requiredBytes);
		for (i in 0..._bytesRaw) copy.__set(i, flash.Memory.getByte(i));
		for (i in 0..._bytesTotal) copy.__set(rawOffset + freeSpace + i, flash.Memory.getByte(rawOffset + i));
		#end
		//register bytes
		flash.Memory.select(null);
		flash.Memory.select(copy);
		_bytes = copy;
		#end
		
		_bytesTotal = requiredBytes;
		
		//shift all intervals to the end, but exclude first interval (if empty)
		var i = _segmentList;
		if (i.isEmpty) i = i.next;
		while (i != null)
		{
			i.shiftRight(freeSpace);
			i.setOffset();
			i = i.next;
		}
		
		//adjust first interval to cover the extra space or create new one
		if (_segmentList.isEmpty)
		{
			//just expand empty interval to cover the extra space
			_segmentList.expandRight(freeSpace);
		}
		else
		{
			//span interval over extra space
			var i = new MemorySegment(this, rawOffset);
			i.expandRight(freeSpace);
			
			//append to interval list
			i.next = _segmentList;
			_segmentList.prev = i;
			_segmentList = i;
		}
	}
	
	function _pack()
	{
		if (_bytesUsed == 0) return;
		var freeBytes = _bytesTotal - _bytesUsed;
		var numBuckets = freeBytes >> _blockSizeShift;
		if (numBuckets == 0) return;
		
		//make sure at least one bucket survives
		if (numBuckets == (_bytesTotal >> _blockSizeShift)) numBuckets--;
		if (numBuckets == 0) return;
		
		//always defrag first
		if (_bytesUsed > 0) _defrag();
		
		var rawOffset = _bytesRaw;
		var freeSpaceBefore = numBuckets << _blockSizeShift;
		
		//update total memory
		_bytesTotal -= freeSpaceBefore;
		
		//copy "raw" bytes to the start of the byte array while "data" bytes go to the end of the byte array
		#if alchemy
		var copy = new flash.utils.ByteArray();
		
			#if flash
			copy.length = rawOffset + _bytesTotal;
			for (i in 0..._bytesRaw) copy[i] = _bytes[i];
			for (i in 0..._bytesTotal) copy[rawOffset + i] = _bytes[rawOffset + freeSpaceBefore + i];
			#elseif cpp
			copy.setLength(rawOffset + _bytesTotal);
			for (i in 0..._bytesRaw) copy.__set(i, _bytes.__get(i));
			for (i in 0..._bytesTotal) copy.__set(rawOffset + i, _bytes.__get(rawOffset + freeSpaceBefore + i));
			#end
		
		//register bytes
		flash.Memory.select(null);
		flash.Memory.select(copy);
		_bytes = copy;
		#end
		
		_segmentList.shrinkLeft(freeSpaceBefore);
		
		var i = _segmentList.next;
		while (i != null)
		{
			i.shiftLeft(freeSpaceBefore);
			i.setOffset();
			i = i.next;
		}
		
		//drop empty interval
		if (_segmentList.size == 0)
		{
			_segmentList = _segmentList.next;
			_segmentList.prev = null;
		}
	}
	
	function _defrag()
	{
		if (_bytesUsed == _bytesTotal) return;
		
		var i1 = _segmentList.next;
		
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
					__setMem(i1.getAccess(), i1);
					
					//update state
					i1.isEmpty = false;
					i0.isEmpty = true;
				}
				else
				{
					//merge empty intervals
					_mergeRight(i0);
					i1 = i0.next;
				}
			}
			
			i1 = i1.prev;
		}
		
		//zero out empty space
		_segmentList.wipe();
	}
	
	function _wipe(destination:Int, size:Int, offset:Int)
	{
		#if alchemy
		for (i in offset...size + offset) flash.Memory.setByte(destination + i, 0);
		#end
	}
	
	function _findEmptySpace(size:Int):MemorySegment
	{
		var m = _segmentList;
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
	
	function _mergeLeft(m:MemorySegment)
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
			_segmentList = m;
	}
	
	function _mergeRight(m:MemorySegment)
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
	
	inline function __getMem(f:MemoryAccessFriend)
	{
		return f._memory;
	}
	inline function __setMem(f:MemoryAccessFriend, x:MemorySegment)
	{
		f._memory = x;
	}
}

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
	
	var _access:MemoryAccess;
	
	#if flash9
	var _weakPointer:flash.utils.Dictionary;
	public static var monitor:flash.utils.Timer;
	public static var listenerCount = 0; 
	#end
	
	public function new(manager:MemoryManager, offset:Int)
	{
		this.manager = manager;
		this.offset = offset;
		b = e = size = 0;
		isEmpty = true;
	}
	
	public function free()
	{
		#if flash9
		if (monitor != null) monitor.removeEventListener(flash.events.TimerEvent.TIMER, _checkPointer);
		_weakPointer = null;
		#end
		
		prev         = null;
		next         = null;
		manager      = null;
		_access      = null;
		b            = -1;
		e            = -1;
		size         = -1;
		offset       = -1;
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
			var t:Array<Dynamic> = untyped __keys__(_weakPointer);
			return untyped __keys__(_weakPointer)[0];
		}
		else
		#end
			return _access;
	}
	
	inline public function setAccess(x:MemoryAccess)
	{
		#if flash9
		if (MemoryManager.AUTO_RECLAIM_MEMORY)
		{
			if (_weakPointer != null)
			{
				//update
				untyped __delete__(_weakPointer, getAccess());
				
				if (x != null)
					untyped _weakPointer[x] = 1;
			}
			else
			{
				#if debug
				assert(x != null, "x != null");
				#end
				if (x == null)
				{
					monitor.removeEventListener(flash.events.TimerEvent.TIMER, _checkPointer);
					_weakPointer = null;
				}
				else
				{
					_weakPointer = new flash.utils.Dictionary(true);
					untyped _weakPointer[x] = 1;
					if (monitor == null)
					{
						monitor = new flash.utils.Timer(MemoryManager.AUTO_RECLAIM_INTERVAL * 1000);
						monitor.start();
					}
					monitor.addEventListener(flash.events.TimerEvent.TIMER, _checkPointer, false, 0, true);
				}
			}
		}
		else
		#end
			_access = x;
	}
	
	#if flash9
	inline public function stopMonitor()
	{
		if (MemoryManager.AUTO_RECLAIM_MEMORY)
		{
			if (_weakPointer != null)
			{
				monitor.removeEventListener(flash.events.TimerEvent.TIMER, _checkPointer);
				_weakPointer = null;
			}
		}
	}
	#end
	
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
	
	#if flash9
	function _checkPointer(e:flash.events.TimerEvent) 
	{
		var keys:Array<Dynamic> = untyped __keys__(_weakPointer);
		for (key in keys) return;
		
		monitor.removeEventListener(flash.events.TimerEvent.TIMER, _checkPointer);
		_weakPointer = null;
		
		var fakeAccess:MemoryAccess = Type.createEmptyInstance(MemoryAccess);
		var friend:MemoryAccessFriend = fakeAccess;
		friend._memory = this;
		MemoryManager.dealloc(fakeAccess);
	}
	#end
}