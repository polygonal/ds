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
"IntMemory is only available when targeting flash"
#end

/**
	A chunk of "alchemy memory" for storing 32-bit signed integers.
**/
class IntMemory extends MemoryAccess
{
	/**
		Converts `input` in the range [`min`, `max`] to a byte array.
		If no range is specified, all `input` bytes are copied.
		<warn>The bytes are written in little endian format.</warn>
			@param min index pointing to the first integer.
		@param max index pointing to the last integer.
		<assert>invalid range, invalid `input` or memory deallocated</assert>
	**/
	#if flash
	public static function toByteArray(input:IntMemory, min = -1, max = -1):flash.utils.ByteArray
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
		
		var output = new flash.utils.ByteArray();
		output.endian = flash.utils.Endian.LITTLE_ENDIAN;
		#if alchemy
		while (min <= max)
		{
			output.writeInt(flash.Memory.getI32(min));
			min += 4;
		}
		#else
		for (i in 0...(max - min) + 1) output.writeInt(input.get(min + i));
		#end
		output.position = 0;
		return output;
	}
	#end
	
	/**
		Converts `input` in the range [`min`, `max`] to an `IntMemory` object.
		If no range is specified, all `input` bytes are copied.
		@param min index pointing to the byte storing the first integer.
		@param min index pointing to the byte storing the last integer.
		<assert>invalid range, invalid `input` or memory deallocated</assert>
	**/
	#if flash
	public static function ofByteArray(input:flash.utils.ByteArray, min = -1, max = -1):IntMemory
	{
		assert(input != null, "invalid input");
		
		if (min == -1) min = 0;
		if (max == -1) max = input.length;
		
		assert(min >= 0);
		assert(max <= Std.int(input.length), "max <= input.length");
		
		input.position = min;
		min >>= 2;
		max >>= 2;
		var output = new IntMemory(max - min, "ofByteArray");
		for (i in min...max) output.set(i - min, input.readInt());
		return output;
	}
	#end
	
	/**
		Converts `input` in the range [`min`, `max`] to a `BytesData` object.
		If no range is specified, all `input` bytes are copied.
		<warn>The bytes are written in little endian format.</warn>
			@param min index pointing to the first integer.
		@param max index pointing to the last integer.
		<assert>invalid range, invalid `input` or memory deallocated</assert>
	**/
	public static function toBytesData(input:IntMemory, min = -1, max = -1):haxe.io.BytesData
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
		
		var output = new haxe.io.BytesOutput();
		
		for (i in 0...(max - min) + 1)
		output.writeInt32(input.get(min + i));
		return output.getBytes().getData();
	}
	
	/**
		Converts `input` in the range [`min`, `max`] to an `IntMemory` object.
		If no range is specified, all `input` bytes are copied.
		@param min index pointing to the byte storing the first integer.
		@param min index pointing to the byte storing the last integer.
		<assert>invalid range, invalid `input` or memory deallocated</assert>
	**/
	public static function ofBytesData(input:haxe.io.BytesData, min = -1, max = -1):IntMemory
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
		min >>= 2;
		max >>= 2;
		var output = new IntMemory(max - min, "ofBytesData");
		for (i in min...max)
		output.set(i - min, bytesInput.readInt32());
		return output;
	}
	
	/**
		Converts `input` in the range [`min`, `max`] to an array.
		If no range is specified, all `input` bytes are copied.
			@param min index pointing to the first integer.
		@param max index pointing to the last integer.
		<assert>invalid range, invalid `input` or memory deallocated</assert>
	**/
	public static function toArray(input:IntMemory, min = -1, max = -1):Array<Int>
	{
		assert(input != null, "invalid input");
		
		if (min == -1) min = 0;
		if (max == -1) max = input.size;
		
		assert(min >= 0, 'min out of range ($min)');
		assert(max <= input.size, 'max out of range ($max)');
		assert(max - min > 0, 'min equals max ($min)');
		
		var output = new Array();
		
		#if alchemy
		min = input.getAddr(min);
		max = input.getAddr(max - 1);
		while (min <= max)
		{
			output.push(flash.Memory.getI32(min));
			min += 4;
		}
		#else
		for (i in 0...max - min) output[i] = input.get(min + i);
		#end
		
		return output;
	}
	
	/**
		Converts `input` in the range [`min`, `max`] to an `IntMemory` object.
		If no range is specified, all `input` values are copied.
			@param min index pointing to the first integer.
		@param max index pointing to the last integer.
		<assert>invalid range, invalid `input` or memory deallocated</assert>
	**/
	public static function ofArray(input:Array<Int>, min = -1, max = -1):IntMemory
	{
		assert(input != null, "invalid input");
		
		if (min == -1) min = 0;
		if (max == -1) max = input.length;
		
		assert(min >= 0);
		assert(max <= Std.int(input.length), "max <= input.length");
		
		var output = new IntMemory(max - min, "ofArray");
		for (i in min...max) output.set(i - min, input[i]);
		return output;
	}
	
	/**
		Converts `input` in the range [`min`, `max`] to a vector object
		If no range is specified, all `input` bytes are copied.
			@param min index pointing to the first integer.
		@param max index pointing to the last integer.
		@param output the `Vector` object to write into. If null, a new Vector object is created on-the-fly.
		<assert>invalid range, invalid `input` or memory deallocated</assert>
	**/
	public static function toVector(input:IntMemory, min = -1, max = -1, output:Vector<Int> = null):Vector<Int>
	{
		assert(input != null, "invalid input");
		
		if (min == -1) min = 0;
		if (max == -1) max = input.size;
		
		assert(min >= 0, 'min out of range ($min)');
		assert(max <= input.size, 'max out of range ($max)');
		assert(max - min > 0, 'min equals max ($min)');
		
		#if (debug && flash && generic)
		if (output != null)
			if (output.fixed)
				assert(Std.int(output.length) >= max - min, "output vector is too small");
		#end
		
		if (output == null) output = new Vector<Int>(max - min);
		
		#if alchemy
		min = input.getAddr(min);
		max = input.getAddr(max - 1);
		var i = 0;
		while (min <= max)
		{
			output[i++] = flash.Memory.getI32(min);
			min += 4;
		}
		#else
		for (i in 0...max - min) output[i] = input.get(min + i);
		#end
		
		return output;
	}
	
	#if flash
	/**
		Converts `input` in the range [`min`, `max`] to a vector object.
		If no range is specified, all `input` bytes are copied.
			@param min index pointing to the first integer.
		@param max index pointing to the last integer.
		<assert>invalid range, invalid `input` or memory deallocated</assert>
	**/
	public static function toUnsignedVector(input:IntMemory, min = -1, max = -1):Vector<UInt>
	{
		assert(input != null, "invalid input");
		
		if (min == -1) min = 0;
		if (max == -1) max = input.size;
		
		assert(min >= 0, 'min out of range ($min)');
		assert(max <= input.size, 'max out of range ($max)');
		assert(max - min > 0, 'min equals max ($min)');
		
		var output = new Vector<UInt>(max - min);
		
		#if alchemy
		min = input.getAddr(min);
		max = input.getAddr(max - 1);
		var i = 0;
		while (min <= max)
		{
			output[i++] = flash.Memory.getI32(min);
			min += 4;
		}
		#else
		for (i in 0...max - min) output[i] = input.get(min + i);
		#end
		
		return output;
	}
	#end
	
	/**
		Converts `input` in the range [`min`, `max`] to an `IntMemory` object.
		If no range is specified, all `input` values are copied.
			@param min index pointing to the first integer.
		@param max index pointing to the last integer.
		<assert>invalid range, invalid `input` or memory deallocated</assert>
	**/
	public static function ofVector(input:Vector<Int>, min = -1, max = -1):IntMemory
	{
		assert(input != null, "invalid input");
		
		if (min == -1) min = 0;
		if (max == -1) max = input.length;
		
		assert(min >= 0);
		assert(max <= Std.int(input.length), "max <= input.length");
		
		var output = new IntMemory(max - min, "ofVector");
		for (i in min...max) output.set(i - min, input[i]);
		
		return output;
	}
	
	#if !alchemy
	var mData:Vector<Int>;
	#end
	
	/**
		The size measured in integers.
	**/
	public var size(default, null):Int;
	
	/**
		Creates a byte array capable of storing a total of `size` integers.
	**/
	public function new(size:Int, name = "?")
	{
		super(size << 2, name);
		this.size = size;
		
		#if !alchemy
		mData = new Vector<Int>(size);
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
	public function clone():IntMemory
	{
		var c = new IntMemory(bytes >> 2, name);
		#if alchemy
		var src = getAddr(0);
		var dst = c.getAddr(0);
		for (i in 0...size)
			flash.Memory.setI32(dst + (i << 2), flash.Memory.getI32(src + (i << 2)));
		#else
		var t = c.mData;
		for (i in 0...size) t[i] = mData[i];
		#end
		return c;
	}
	
	/**
		Sets all integers to the value `x`.
	**/
	public function fill(x:Int):IntMemory
	{
		#if alchemy
		flash.Memory.setI32(0, x);
		flash.Memory.setI32(4, x);
		var d = flash.Memory.getDouble(0);
		var offset = getAddr(0);
		for (i in 0...size >> 1)
			flash.Memory.setDouble(offset + (i << 3), d);
		if ((size & 1) == 1)
			flash.Memory.setI32(getAddr(size - 1), x);
		#else
		for (i in 0...size) mData[i] = x;
		#end
		
		return this;
	}
	
	/**
		Adjusts the size of this object so it's capable of storing `newSize` integers.
		<assert>invalid size</assert>
		<assert>memory was already deallocated</assert>
	**/
	override public function resize(newSize:Int)
	{
		assert(newSize >= 0, 'invalid size ($newSize)');
		
		#if alchemy
		super.resize(newSize << 2);
		#else
		var tmp = new Vector<Int>(newSize);
		for (i in 0...M.min(newSize, size)) tmp[i] = mData[i];
		mData = tmp;
		#end
		
		size = newSize;
	}
	
	/**
		Returns the integer at index `i`.
		<assert>index out of range</assert>
		<assert>memory deallocated</assert>
	**/
	inline public function get(i:Int):Int
	{
		#if alchemy
		return flash.Memory.getI32(getAddr(i));
		#else
		return mData[i];
		#end
	}
	
	/**
		Replaces the integer at the index `i` with the integer `x`.
		<assert>index out of range</assert>
		<assert>memory deallocated</assert>
	**/
	inline public function set(i:Int, x:Int)
	{
		#if alchemy
		flash.Memory.setI32(getAddr(i), x);
		#else
		mData[i] = x;
		#end
	}
	
	/**
		Swaps the integer at index `i` with the integer at index `j`.
		<assert>index out of range</assert>
		<assert>`i` equals `j`</assert>
	**/
	inline public function swp(i:Int, j:Int)
	{
		assert(i != j, 'i equals j ($i)');
		
		#if alchemy
		var ai = getAddr(i);
		var aj = getAddr(j);
		var tmp = flash.Memory.getI32(ai);
		flash.Memory.setI32(ai, flash.Memory.getI32(aj));
		flash.Memory.setI32(ai, tmp);
		#else
		var tmp = mData[i]; mData[i] = mData[j]; mData[j] = tmp;
		#end
	}
	
	/**
		Returns the memory byte offset of the first byte storing the integer at index `i`.
		<assert>index out of range</assert>
		<assert>memory deallocated</assert>
	**/
	inline public function getAddr(i:Int):Int
	{
		assert(i >= 0 && i < size, 'segfault, index $i');
		assert(mMemory != null, "memory deallocated");
		
		#if alchemy
		return offset + (i << 2);
		#else
		return i;
		#end
	}
	
	#if !alchemy
	override public function clear()
	{
		for (i in 0...size) mData[i] = 0;
	}
	#end
	
	/**
		Returns a string representing the current object.
		Prints out all elements if compiled with the `-debug` directive.
		
		Example:
		<pre class="prettyprint">
		var mem = new new de.polygonal.ds.mem.IntMemory(4);
		for (i in 0...4) {
		    mem.set(i, i);
		}
		trace(mem);</pre>
		<pre class="console">
		{ IntMemory size: 4 }
		[
		  0 -> 0
		  1 -> 1
		  2 -> 2
		  3 -> 3
		]</pre>
	**/
	public function toString():String
	{
		#if debug
		if (mMemory == null) return "{ IntMemory (unassigned) }";
		var s = '{ IntMemory size: $size, name: $name }';
		s += "\n[\n";
		for (i in 0...size)
			s += Printf.format("  %3d -> %#d\n", [i, get(i)]);
		s += "\n]";
		return s;
		#else
		return '{ IntMemory size: $size, name: $name }';
		#end
	}
}