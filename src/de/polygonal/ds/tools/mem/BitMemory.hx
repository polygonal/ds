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

#if !alchemy
import de.polygonal.ds.tools.MathTools;
import haxe.ds.Vector;
#end

#if (alchemy && !flash)
"BitMemory is only available when targeting flash"
#end

/**
	A bit-vector using fast "alchemy-memory" for data storage.
**/
class BitMemory extends MemoryAccess
{
	/**
		Converts `input` to a `ByteArray` object.
		_The bytes are written in little endian format._
	**/
	#if flash
	public static function toByteArray(input:BitMemory):flash.utils.ByteArray
	{
		var out = new flash.utils.ByteArray();
		out.endian = flash.utils.Endian.LITTLE_ENDIAN;
		
		var x = 0;
		var b = 0;
		for (i in 0...input.size)
		{
			if (input.has(i)) x |= 1 << b;
			b++;
			if (b & 7 == 0)
			{
				out.writeByte(x);
				x = 0;
				b = 0;
			}
		}
		
		if (b > 0) out.writeByte(x);
		out.position = 0;
		return out;
	}
	#end
	
	/**
		Converts `input` in the range [`min`, `max`] to a `ByteMemory` object.
		If no range is specified, all `input` bytes are copied.
	**/
	#if flash
	public static function ofByteArray(input:flash.utils.ByteArray, min:Int = -1, max:Int = -1):BitMemory
	{
		assert(input != null, "invalid input");
		
		if (min == -1) min = 0;
		if (max == -1) max = input.length;
		
		assert(min >= 0);
		assert(max <= Std.int(input.length), "max <= input.length");
		
		var out = new BitMemory((max - min) << 3, "ofByteArray");
		#if alchemy
		var a = out.getAddr(0);
		for (i in min...max) flash.Memory.setByte(a++, cast input[i]);
		#else
		var i = 0;
		for (j in min...max)
		{
			var b = input[j];
			for (k in 0...8)
			{
				var bit = b & 1;
				b >>= 1;
				if (bit == 1) out.set(i);
				i++;
			}
		}
		#end
		return out;
	}
	#end
	
	/**
		Converts `input` to a `BytesData` object.
		_The bytes are written in little endian format._
	**/
	public static function toBytesData(input:BitMemory):haxe.io.BytesData
	{
		var out = new haxe.io.BytesOutput();
		out.bigEndian = false;
		
		var x = 0;
		var b = 0;
		for (i in 0...input.size)
		{
			if (input.has(i)) x |= 1 << b;
			b++;
			if (b & 7 == 0)
			{
				out.writeByte(x);
				x = 0;
				b = 0;
			}
		}
		
		if (b > 0) out.writeByte(x);
		return out.getBytes().getData();
	}
	
	/**
		Converts `input` in the range [`min`, `max`] to a `ByteMemory` object.
		If no range is specified, all `input` bytes are copied.
	**/
	public static function ofBytesData(input:haxe.io.BytesData, min:Int = -1, max:Int = -1):BitMemory
	{
		assert(input != null, "invalid input");
		
		if (min == -1) min = 0;
		if (max == -1) max =
		#if neko
		neko.NativeString.length(input);
		#else
		input.length;
		#end
		
		assert(min >= 0);
		
		#if neko
		assert(max <= neko.NativeString.length(input), "max <= input.length");
		#else
		assert(max <= Std.int(input.length), "max <= input.length");
		#end
		
		var out = new BitMemory((max - min) << 3, "ofByteArray");
		#if alchemy
		var a = out.getAddr(0);
		for (i in min...max)
			flash.Memory.setByte(a++, cast input[i]);
		#else
			#if flash
			var i = 0;
			for (j in min...max)
			{
				var b = input[j];
				for (k in 0...8)
				{
					var bit = b & 1;
					b >>= 1;
					if (bit == 1) out.set(i);
					i++;
				}
			}
			#else
			var input2 = haxe.io.Bytes.ofData(input);
			var i = 0;
			for (j in min...max)
			{
				var b = input2.get(j);
				for (k in 0...8)
				{
					var bit = b & 1;
					b >>= 1;
					if (bit == 1) out.set(i);
					i++;
				}
			}
			#end
		#end
		return out;
	}
	
	/**
		Converts `input` to a `BitVector` object.
	**/
	public static function toBitVector(input:BitMemory):BitVector
	{
		var bytes = toBytesData(input);
		var bv = new BitVector(input.size);
		bv.ofBytes(bytes);
		return bv;
	}
	
	#if !alchemy
	var mData:Vector<Int>;
	#end
	
	/**
		The size measured in bits.
	**/
	public var size(default, null):Int;
	
	/**
		Creates a bit vector capable of storing a total of `size` bits.
	**/
	public function new(size:Int, name:String = null)
	{
		super(((size & (32 - 1)) > 0 ? ((size >> 5) + 1) : (size >> 5)) << 2, name);
		
		this.size = size;
		
		#if !alchemy
		mData = new Vector<Int>(bytes >> 2);
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
	public function clone():BitMemory
	{
		var c = new BitMemory(size, name);
		#if alchemy
		var src = getAddr(0);
		var dst = c.getAddr(0);
		for (i in 0...bytes >> 2)
			flash.Memory.setI32(dst + (i << 2), flash.Memory.getI32(src + (i << 2)));
		#else
		var t = c.mData;
		for (i in 0...bytes >> 2) t[i] = mData[i];
		#end
		return c;
	}
	
	/**
		Sets all bits to the value `x`.
	**/
	public function setAll(x:Int):BitMemory
	{
		assert(x == 0 || x == 1, "x == 0 || x == 1");
		
		#if alchemy
		var offset = getAddr(0);
		var bits = x == 0 ? 0 : -1;
		flash.Memory.setI32(0, bits);
		flash.Memory.setI32(4, bits);
		var d = flash.Memory.getDouble(0);
		for (i in 0...(bytes >> 2) >> 1)
			flash.Memory.setDouble(offset + (i << 3), d);
		
		if (((bytes >> 2) & 1) == 1)
			flash.Memory.setI32(offset + (bytes - 4), bits);
		#else
		if (x == 0)
			for (i in 0...bytes >> 2) mData[i] = 0;
		else
			for (i in 0...bytes >> 2) mData[i] =-1;
		#end
		return this;
	}
	
	/**
		Adjusts the size of this object so it's capable of storing `newSize` bits.
	**/
	override public function resize(newSize:Int)
	{
		assert(newSize >= 0, 'invalid size ($newSize)');
		
		var newBytes = ((size & (32 - 1)) > 0 ? ((size >> 5) + 1) : (size >> 5)) << 2;
		
		#if alchemy
		super.resize(newBytes);
		#else
			var t = new Vector<Int>(newBytes >> 2);
			for (i in 0...MathTools.min(newSize, size)) t[i] = mData[i];
			mData = t;
		#end
		
		size = newSize;
	}
	
	/**
		Returns true if the bit at index `i` is 1.
	**/
	public inline function has(i:Int):Bool
	{
		#if alchemy
		return ((flash.Memory.getI32(getAddr(i)) & (1 << (i & (32 - 1)))) >> (i & (32 - 1))) != 0;
		#else
		return (mData[getAddr(i)] & (1 << (i & (32 - 1)))) >> (i & (32 - 1)) != 0;
		#end
	}
	
	/**
		Returns 1 if the bit at index `i` is set, otherwise zero.
	**/
	public inline function get(i:Int):Int
	{
		#if alchemy
			return ((flash.Memory.getI32(getAddr(i)) & (1 << (i & (32 - 1)))) >> (i & (32 - 1)));
		#else
		return (mData[getAddr(i)] & (1 << (i & (32 - 1)))) >> (i & (32 - 1));
		#end
	}
	
	/**
		Sets the bit at index `i` to 1.
	**/
	public inline function set(i:Int)
	{
		var idx = getAddr(i);
		#if alchemy
		flash.Memory.setI32(idx, flash.Memory.getI32(idx) | (1 << (i & (32 - 1))));
		#else
		mData[idx] = mData[idx] | (1 << (i & (32 - 1)));
		#end
	}
	
	/**
		Sets the bit at index `i` to 0.
	**/
	public inline function clr(i:Int)
	{
		var idx = getAddr(i);
		#if alchemy
		flash.Memory.setI32(idx, flash.Memory.getI32(idx) & ~(1 << (i & (32 - 1))));
		#else
		mData[idx] = mData[idx] & ~(1 << (i & (32 - 1)));
		#end
	}
	
	/**
		Sets the bit at index `i` to 1 if `cond` is true or clears the bit at index `i` if `cond` is false.
	**/
	public inline function ofBool(i:Int, cond:Bool)
	{
		cond ? set(i) : clr(i);
	}
	
	/**
		Returns the memory byte offset for the byte storing the bit at index `i`.
	**/
	public inline function getAddr(i:Int):Int
	{
		assert(i >= 0 && i < size, 'segfault, index $i');
		assert(mMemory != null, "memory deallocated");
		
		#if alchemy
		return offset + ((i >> 5) << 2);
		#else
		return ((i >> 5) << 2) >> 2;
		#end
	}
	
	#if !alchemy
	override public function clear()
	{
		for (i in 0...size) mData[getAddr(i)] = 0;
	}
	#end
	
	/**
		Prints out all elements.
	**/
	#if !no_tostring
	public function toString():String
	{
		if (mMemory == null) return "[ BitMemory (unassigned) ]";
		var b = new StringBuf();
		b.add('[ BitMemory size=$size');
		if (name != null) b.add(' name=$name');
		b.add("\n");
		var args = new Array<Dynamic>();
		for (i in 0...bytes >> 2)
		{
			var t = "";
			for (j in 0...32)
			{
				var k = (i << 5) + j;
				if (k < size)
					t += has(k) ? "1" : "0";
				else
					t += "#";
			}
			args[0] = i;
			args[1] = t;
			b.add(Printf.format("  %4d -> %s\n", args));
		}
		b.add("]");
		return b.toString();
	}
	#end
}