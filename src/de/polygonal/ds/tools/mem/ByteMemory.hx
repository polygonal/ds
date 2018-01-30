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
package de.polygonal.ds.tools.mem;

import de.polygonal.ds.tools.Assert.assert;
import haxe.ds.Vector;

#if !alchemy
import de.polygonal.ds.tools.MathTools;
#end

#if (alchemy && !flash)
"ByteMemory is only available when targeting flash"
#end

/**
	A byte array using fast "alchemy-memory" for data storage.
**/
class ByteMemory extends MemoryAccess
{
	/**
		Converts `input` in the range [`min`, `max`] to a byte array.
		If no range is specified, all `input` bytes are copied.</i>
		_The bytes are written in little endian format._
	**/
	#if flash
	public static function toByteArray(input:ByteMemory, min:Int = -1, max:Int = -1):flash.utils.ByteArray
	{
		assert(input != null, "invalid input");
		
		if (min == -1) min = 0;
		if (max == -1) max = input.size;
		
		assert(min >= 0, 'min out of range ($min)');
		assert(max <= input.size, 'max out of range ($max)');
		assert(max - min > 0, 'min equals max ($min)');
		
		var t = min;
		min = input.getAddr(t);
		max = input.getAddr(max - 1);
		
		var out = new flash.utils.ByteArray();
		out.endian = flash.utils.Endian.LITTLE_ENDIAN;
		
		#if (flash && alchemy)
		while (min <= max) out.writeByte(flash.Memory.getByte(min++));
		#else
		for (i in 0...(max - min) + 1) out.writeByte(input.get(min + i));
		#end
		out.position = 0;
		return out;
	}
	
	/**
		Converts `input` in the range [`min`, `max`] to a `ByteMemory` object.
		If no range is specified, all `input` bytes are copied.
	**/
	public static function ofByteArray(input:flash.utils.ByteArray, min:Int = -1, max:Int = -1):ByteMemory
	{
		assert(input != null, "invalid input");
		
		if (min == -1) min = 0;
		if (max == -1) max = input.length;
		
		input.position = min;
		
		assert(min >= 0);
		assert(max <= Std.int(input.length), "max <= input.length");
		
		var out = new ByteMemory(max - min, "ofByteArray");
		for (i in min...max) out.set(i - min, input.readByte());
		return out;
	}
	#end
	
	/**
		Converts `input` in the range [`min`, `max`] to a `BytesData` object.
		If no range is specified, all `input` bytes are copied.</i>
		_The bytes are written in little endian format._
	**/
	public static function toBytesData(input:ByteMemory, min:Int = -1, max:Int = -1):haxe.io.BytesData
	{
		assert(input != null, "invalid input");
		
		if (min == -1) min = 0;
		if (max == -1) max = input.size;
		
		assert(min >= 0, 'min out of range ($min)');
		assert(max <= input.size, 'max out of range ($max)');
		assert(max - min > 0, 'min equals max ($min)');
		
		var out = new haxe.io.BytesBuffer();
		for (i in 0...max - min) out.addByte(input.get(min + i));
		return out.getBytes().getData();
	}
	
	/**
		Converts `input` in the range [`min`, `max`] to a `ByteMemory` object.
		If no range is specified, all `input` bytes are copied.
	**/
	public static function ofBytesData(input:haxe.io.BytesData, min:Int = -1, max:Int = -1):ByteMemory
	{
		assert(input != null, "invalid input");
		
		if (min == -1) min = 0;
		
		var bytes = haxe.io.Bytes.ofData(input);
		if (max == -1) max = bytes.length;
		
		assert(min >= 0);
		assert(max <= Std.int(bytes.length), "max <= input.length");
		
		var out = new ByteMemory(max - min, "ofBytesData");
		for (i in min...max) out.set(i - min, bytes.get(i));
		return out;
	}
	
	/**
		Converts `input` in the range [`min`, `max`] to an array.
		If no range is specified, all `input` bytes are copied.
	**/
	public static function toArray(input:ByteMemory, min:Int = -1, max:Int = -1):Array<Int>
	{
		assert(input != null, "invalid input");
		
		if (min == -1) min = 0;
		if (max == -1) max = input.size;
		
		assert(min >= 0, 'min out of range ($min)');
		assert(max <= input.size, 'max out of range ($max)');
		assert(max - min > 0, 'min equals max ($min)');
		
		var out = new Array();
		
		#if (flash && alchemy)
		min = input.getAddr(min);
		max = input.getAddr(max - 1);
		while (min <= max)
		{
			out.push(flash.Memory.getByte(min));
			min++;
		}
		#else
		for (i in 0...max - min) out[i] = input.get(min + i);
		#end
		return out;
	}
	
	/**
		Converts `input` in the range [`min`, `max`] to a `ByteMemory` object.
		If no range is specified, all `input` bytes are copied.
	**/
	public static function ofArray(input:Array<Int>, min:Int = -1, max:Int = -1):ByteMemory
	{
		assert(input != null, "invalid input");
		
		if (min == -1) min = 0;
		if (max == -1) max = input.length;
		
		assert(min >= 0);
		assert(max <= Std.int(input.length), "max <= input.length");
		
		var out = new ByteMemory(max - min, "ofArray");
		for (i in min...max) out.set(i - min, input[i]);
		return out;
	}
	
	/**
		Converts `input` in the range [`min`, `max`] to a Vector object.
		If no range is specified, all `input` bytes are copied.
		@param out the `Vector` object to write into. If null, a new Vector object is created on-the-fly.
	**/
	public static function toVector(input:ByteMemory, min:Int = -1, max:Int = -1, out:Vector<Int> = null):Vector<Int>
	{
		assert(input != null, "invalid input");
		
		if (min == -1) min = 0;
		if (max == -1) max = input.size;
		
		assert(min >= 0, 'min out of range ($min)');
		assert(max <= input.size, 'max out of range ($max)');
		assert(max - min > 0, 'min equals max ($min)');
		
		#if debug
		if (out != null) assert(Std.int(out.length) >= max - min, "out vector is too small");
		#end
		
		if (out == null) out = new Vector<Int>(max - min);
		
		#if (flash && alchemy)
		min = input.getAddr(min);
		max = input.getAddr(max - 1);
		var i = 0;
		while (min <= max)
		{
			out[i++] = flash.Memory.getByte(min);
			min++;
		}
		#else
		for (i in 0...max - min) out[i] = input.get(min + i);
		#end
		return out;
	}
	
	/**
		Converts `input` in the range [`min`, `max`] to a `ByteMemory` object.
		If no range is specified, all `input` bytes are copied.
	**/
	public static function ofVector(input:Vector<Int>, min:Int = -1, max:Int = -1):ByteMemory
	{
		assert(input != null, "invalid input");
		
		if (min == -1) min = 0;
		if (max == -1) max = input.length;
		
		assert(min >= 0);
		assert(max <= Std.int(input.length), "max <= input.length");
		
		var out = new ByteMemory(max - min, "ofVector");
		for (i in min...max) out.set(i - min, input[i]);
		return out;
	}
	
	#if (!flash && alchemy)
	var mData:haxe.io.Bytes;
	#else
		#if flash
		var mData:flash.utils.ByteArray;
		#else
		var mData:haxe.io.Bytes;
		#end
	#end
	
	/**
		The size measured in bytes.
	**/
	public var size(default, null):Int;
	
	/**
		Creates a byte array capable of storing a total of `size` bytes.
	**/
	public function new(size:Int, name:String = null)
	{
		super(this.size = size, name);
		
		#if !alchemy
			#if flash
			mData = new flash.utils.ByteArray();
			mData.length = size;
			#else
			mData = haxe.io.Bytes.alloc(size);
			#end
		#end
	}
	
	#if !alchemy
	override public function free()
	{
		mData = null;
		super.free();
	}
	#end
	
	/**
		Creates a deep copy of this object.
	**/
	public function clone():ByteMemory
	{
		var c = new ByteMemory(bytes, name);
		#if (flash && alchemy)
		var src = getAddr(0);
		var dst = c.getAddr(0);
		for (i in 0...size)
			flash.Memory.setByte(dst + i, flash.Memory.getByte(src + i));
		#else
		var t = c.mData;
			#if flash
			for (i in 0...size) t[i] = mData[i];
			#else
			for (i in 0...size)
			{
				#if flash
				t[i] = mData[i];
				#else
				t.set(i, mData.get(i));
				#end
			}
			#end
		#end
		return c;
	}
	
	/**
		Sets all bytes to the value `x`.
	**/
	public function setAll(x:Int):ByteMemory
	{
		#if (flash && alchemy)
		var offset = getAddr(0);
		flash.Memory.setByte(0, x);
		flash.Memory.setByte(1, x);
		flash.Memory.setByte(2, x);
		flash.Memory.setByte(3, x);
		flash.Memory.setByte(4, x);
		flash.Memory.setByte(5, x);
		flash.Memory.setByte(6, x);
		flash.Memory.setByte(7, x);
		var d = flash.Memory.getDouble(0);
		for (i in 0...size >> 3)
			flash.Memory.setDouble(offset + (i << 3), d);
		var r = size & 7;
		if (r > 0)
		{
			offset = getAddr(size - r);
			for (i in 0...r) flash.Memory.setByte(offset + i, x);
		}
		#else
		for (i in 0...size) set(i, x);
		#end
		return this;
	}
	
	/**
		Adjusts the size of this object so it's capable of storing `newSize` bytes.
	**/
	override public function resize(newSize:Int)
	{
		assert(newSize >= 0, 'invalid size ($newSize)');
		
		#if alchemy
		super.resize(newSize);
		#else
			#if flash
			var t = new flash.utils.ByteArray();
			t.length = newSize;
			for (i in 0...MathTools.min(newSize, size)) t[i] = mData[i];
			#else
			var t = haxe.io.Bytes.alloc(newSize);
			for (i in 0...MathTools.min(newSize, size)) t.set(i, mData.get(i));
			#end
		mData = t;
		#end
		
		size = newSize;
	}
	
	/**
		Returns the byte at index `i`.
	**/
	public inline function get(i:Int):Int
	{
		#if (flash && alchemy)
		return flash.Memory.getByte(getAddr(i));
		#else
			#if flash
			return mData[i];
			#else
			return mData.get(i);
			#end
		#end
	}
	
	/**
		Replaces the byte at the index `i` with the byte `x`.
	**/
	public inline function set(i:Int, x:Int)
	{
		#if (flash && alchemy)
		flash.Memory.setByte(getAddr(i), x);
		#else
			#if flash
			mData[i] = x;
			#else
			mData.set(i, x);
			#end
		#end
	}
	
	/**
		Swaps the byte at the index `i` with the byte at the index `j`.
	**/
	public inline function swap(i:Int, j:Int)
	{
		assert(i != j, 'i equals j ($i)');
		
		#if (flash && alchemy)
		var ai = getAddr(i);
		var aj = getAddr(j);
		var t = flash.Memory.getByte(ai);
		flash.Memory.setByte(ai, flash.Memory.getByte(aj));
		flash.Memory.setByte(ai, t);
		#else
		var t = get(i); set(i, get(j)); set(j, t);
		#end
	}
	
	/**
		Returns the memory byte offset for the byte at index `i`.
	**/
	public inline function getAddr(i:Int):Int
	{
		assert(i >= 0 && i < size, 'segfault, index $i');
		assert(mMemory != null, "memory deallocated");
		
		#if alchemy
		return offset + i;
		#else
		return i;
		#end
	}
	
	#if !alchemy
	override public function clear()
	{
		for (i in 0...size) set(i, 0);
	}
	#end
	
	/**
		Prints out all elements.
	**/
	#if !no_tostring
	public function toString():String
	{
		if (mMemory == null) return "[ ByteMemory (unassigned) ]";
		var b = new StringBuf();
		b.add('[ ByteMemory size=$size');
		if (name != null) b.add(' name=$name');
		b.add("\n");
		var args = new Array<Dynamic>();
		for (i in 0...size)
		{
			args[0] = i;
			args[1] = get(i);
			b.add(Printf.format("  %3d -> %d\n", args));
		}
		b.add("]");
		return b.toString();
	}
	#end
}