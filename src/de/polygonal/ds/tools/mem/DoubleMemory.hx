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
"DoubleMemory is only available when targeting flash"
#end

/**
	A chunk of fast "alchemy memory" for storing IEEE 754 double-precision floating point numbers.
**/
class DoubleMemory extends MemoryAccess
{
	/**
		Converts `input` in the range [`min`, `max`] to a byte array.
		If no range is specified, all `input` bytes are copied.
		_The bytes are written in little endian format._
		@param min index pointing to the first double.
		@param max index pointing to the last double.
	**/
	#if flash
	public static function toByteArray(input:DoubleMemory, min:Int = -1, max:Int = -1):flash.utils.ByteArray
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
		#if alchemy
		while (min <= max)
		{
			out.writeDouble(flash.Memory.getDouble(min));
			min += 8;
		}
		#else
		for (i in 0...(max - min) + 1) out.writeDouble(input.get(min + i));
		#end
		out.position = 0;
		return out;
	}
	#end
	
	/**
		Converts `input` in the range [`min`, `max`] to a `DoubleMemory` object.
		If no range is specified, all `input` bytes are copied.
		@param min index pointing to the byte storing the first double.
		@param min index pointing to the byte storing the last double.
	**/
	#if flash
	public static function ofByteArray(input:flash.utils.ByteArray, min:Int = -1, max:Int = -1):DoubleMemory
	{
		assert(input != null, "invalid input");
		
		if (min == -1) min = 0;
		if (max == -1) max = input.length;
		
		assert(min >= 0);
		assert(max <= Std.int(input.length), "max <= input.length");
		
		input.position = min;
		min >>= 3;
		max >>= 3;
		var out = new DoubleMemory(max - min, "ofByteArray");
		for (i in min...max) out.set(i - min, input.readDouble());
		return out;
	}
	#end
	
	/**
		Converts `input` in the range [`min`, `max`] to a `BytesData` object.
		If no range is specified, all `input` bytes are copied.
		@param min index pointing to the first double.
		@param max index pointing to the last double.
	**/
	public static function toBytesData(input:DoubleMemory, min:Int = -1, max:Int = -1):haxe.io.BytesData
	{
		assert(input != null, "invalid input");
		
		if (min == -1) min = 0;
		if (max == -1) max = input.size;
		
		assert(min >= 0, 'min out of range ($min)');
		assert(max <= input.size, 'max out of range ($max)');
		assert(max - min > 0, 'min equals max ($min)');
		
		var out = new haxe.io.BytesOutput();
		for (i in 0...max - min)
			out.writeDouble(input.get(min + i));
		return out.getBytes().getData();
	}
	
	/**
		Converts `input` in the range [`min`, `max`]` to a `DoubleMemory` object.
		If no range is specified, all `input` bytes are copied.
		@param min index pointing to the byte storing the first float.
		@param min index pointing to the byte storing the last float.
	**/
	public static function ofBytesData(input:haxe.io.BytesData, min:Int = -1, max:Int = -1):DoubleMemory
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
		
		var bytesInput = new haxe.io.BytesInput(haxe.io.Bytes.ofData(input), min);
		min >>= 3;
		max >>= 3;
		var out = new DoubleMemory(max - min, "ofBytesData");
		for (i in min...max) out.set(i - min, bytesInput.readDouble());
		return out;
	}
	
	/**
		Converts `input` in the range [`min`, `max`] to an array.
		If no range is specified, all `input` bytes are copied.
		@param min index pointing to the first double.
		@param max index pointing to the last double.
	**/
	public static function toArray(input:DoubleMemory, min:Int = -1, max:Int = -1):Array<Float>
	{
		assert(input != null, "invalid input");
		
		if (min == -1) min = 0;
		if (max == -1) max = input.size;
		
		assert(min >= 0, 'min out of range ($min)');
		assert(max <= input.size, 'max out of range ($max)');
		assert(max - min > 0, 'min equals max ($min)');
		
		var out = new Array();
		
		#if alchemy
		min = input.getAddr(min);
		max = input.getAddr(max - 1);
		while (min <= max)
		{
			out.push(flash.Memory.getDouble(min));
			min += 8;
		}
		#else
		for (i in 0...max - min) out[i] = input.get(min + i);
		#end
		return out;
	}
	
	/**
		Converts `input` in the range [`min`, `max`] to a `DoubleMemory` object.
		If no range is specified, all `input` values are copied.
		@param min index pointing to the first double.
		@param max index pointing to the last double.
	**/
	public static function ofArray(input:Array<Float>, min:Int = -1, max:Int = -1):DoubleMemory
	{
		assert(input != null, "invalid input");
		
		if (min == -1) min = 0;
		if (max == -1) max = input.length;
		
		assert(min >= 0);
		assert(max <= Std.int(input.length), "max <= input.length");
		
		var out = new DoubleMemory(max - min, "ofArray");
		for (i in min...max) out.set(i - min, input[i]);
		return out;
	}
	
	/**
		Converts `input` in the range [`min`, `max`] to a vector object.
		If no range is specified, all `input` bytes are copied.</i>
		@param min index pointing to the first double.
		@param max index pointing to the last double.
		@param out the `Vector` object to write into. If null, a new Vector object is created on-the-fly.
	**/
	public static function toVector(input:DoubleMemory, min:Int = -1, max:Int = -1, out:Vector<Float> = null):Vector<Float>
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
		
		if (out == null) out = new Vector<Float>(max - min);
		
		#if alchemy
		min = input.getAddr(min);
		max = input.getAddr(max - 1);
		var i = 0;
		while (min <= max)
		{
			out[i++] = flash.Memory.getDouble(min);
			min += 8;
		}
		#else
		for (i in 0...max - min) out[i] = input.get(min + i);
		#end
		return out;
	}
	
	/**
		Converts `input` in the range [`min`, `max`] to a `DoubleMemory` object.
		If no range is specified, all `input` values are copied.
		@param min index pointing to the first double.
		@param max index pointing to the last double.
	**/
	public static function ofVector(input:Vector<Float>, min:Int = -1, max:Int = -1):DoubleMemory
	{
		assert(input != null, "invalid input");
		
		if (min == -1) min = 0;
		if (max == -1) max = input.length;
		
		assert(min >= 0);
		assert(max <= Std.int(input.length), "max <= input.length");
		
		var out = new DoubleMemory(max - min, "ofVector");
		for (i in min...max) out.set(i - min, input[i]);
		return out;
	}
	
	#if !alchemy
	var mData:Vector<Float>;
	#end
	
	/**
		The size measured in doubles.
	**/
	public var size(default, null):Int;
	
	/**
		Creates a byte array capable of storing a total of `size` doubles.
	**/
	public function new(size:Int, name:String = null)
	{
		super(size << 3, name);
		this.size = size;
		
		#if !alchemy
		mData = new Vector<Float>(size);
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
	public function clone():DoubleMemory
	{
		var c = new DoubleMemory(bytes >> 3, name);
		#if alchemy
		var src = getAddr(0);
		var dst = c.getAddr(0);
		for (i in 0...size)
			flash.Memory.setDouble(dst + (i << 3), flash.Memory.getDouble(src + (i << 3)));
		#else
		var t = c.mData;
		for (i in 0...size) t[i] = mData[i];
		#end
		return c;
	}
	
	/**
		Sets all doubles to the value `x`.
	**/
	public function setAll(x:Float):DoubleMemory
	{
		#if alchemy
		var offset = getAddr(0);
		for (i in 0...size) flash.Memory.setDouble(offset + (i << 3), x);
		#else
		for (i in 0...size) mData[i] = x;
		#end
		return this;
	}
	
	/**
		Adjusts the size of this object so it's capable of storing `newSize` doubles.
	**/
	override public function resize(newSize:Int)
	{
		assert(newSize >= 0, 'invalid size ($newSize)');
		
		#if alchemy
		super.resize(newSize << 3);
		#else
		var t = new Vector<Float>(newSize);
		for (i in 0...MathTools.min(newSize, size)) t[i] = mData[i];
		mData = t;
		#end
		
		size = newSize;
	}
	
	/**
		Returns the double at index `i`.
	**/
	public inline function get(i:Int):Float
	{
		#if alchemy
		return flash.Memory.getDouble(getAddr(i));
		#else
		return mData[i];
		#end
	}
	
	/**
		Replaces the double at the index `i` with the double `x`.
	**/
	public inline function set(i:Int, x:Float)
	{
		#if alchemy
		flash.Memory.setDouble(getAddr(i), x);
		#else
		mData[i] = x;
		#end
	}
	
	/**
		Swaps the double at index `i` with the double at index `j`.
	**/
	public inline function swap(i:Int, j:Int)
	{
		assert(i != j, 'i equals j ($i)');
		
		#if alchemy
		var ai = getAddr(i);
		var aj = getAddr(j);
		var t = flash.Memory.getDouble(ai);
		flash.Memory.setDouble(ai, flash.Memory.getDouble(aj));
		flash.Memory.setDouble(ai, t);
		#else
		var t = mData[i]; mData[i] = mData[j]; mData[j] = t;
		#end
	}
	
	/**
		Returns the memory byte offset of the first byte storing the double at index `i`.
	**/
	public inline function getAddr(i:Int):Int
	{
		assert(i >= 0 && i < size, 'segfault, index $i');
		assert(mMemory != null, "memory deallocated");
		
		#if alchemy
		return offset + (i << 3);
		#else
		return i;
		#end
	}
	
	#if !alchemy
	override public function clear()
	{
		for (i in 0...size) mData[i] = .0;
	}
	#end
	
	/**
		Prints out all elements.
	**/
	#if !no_tostring
	public function toString():String
	{
		if (mMemory == null) return "[ DoubleMemory (unassigned) ]";
		var b = new StringBuf();
		b.add('[ DoubleMemory size=$size');
		if (name != null) b.add(' name=$name');
		b.add("\n");
		var args = new Array<Dynamic>();
		for (i in 0...size)
		{
			args[0] = i;
			args[1] = get(i);
			b.add(Printf.format("  %3d -> %#.3f\n", args));
		}
		b.add("]");
		return b.toString();
	}
	#end
}