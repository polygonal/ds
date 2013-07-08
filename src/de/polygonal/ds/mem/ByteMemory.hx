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

/**
 * <p>A byte array using fast "alchemy-memory" for data storage.</p>
 */
class ByteMemory extends MemoryAccess
{
	/**
	 * Converts <code>input</code> in the range &#091;<code>min</code>, <code>max</code>&#093; to a byte array.<br/>
	 * If no range is specified, all <code>input</code> bytes are copied.</i><br/>
	 * <warn>The bytes are written in little endian format.</warn>
	 * @throws de.polygonal.ds.error.AssertError invalid range, invalid <code>input</code> or memory deallocated (debug only).
	 */
	#if (flash9 || cpp)
	public static function toByteArray(input:ByteMemory, min = -1, max = -1):flash.utils.ByteArray
	{
		#if debug
		assert(input != null, "invalid input");
		#end
		
		if (min == -1) min = 0;
		if (max == -1) max = input.size;
		
		#if debug
		assert(min >= 0, 'min out of range ($min)');
		assert(max <= input.size, 'max out of range ($max)');
		assert(max - min > 0, 'min equals max ($min)');
		#end
		
		var t = min;
		min = input.getAddr(t);
		max = input.getAddr(max - 1);
		
		var output = new flash.utils.ByteArray();
		output.endian = flash.utils.Endian.LITTLE_ENDIAN;
		
		#if alchemy
		while (min <= max) output.writeByte(flash.Memory.getByte(min++));
		#else
		for (i in 0...(max - min) + 1) output.writeByte(input.get(min + i));
		#end
		output.position = 0;
		return output;
	}
	#end
	
	/**
	 * Converts <code>input</code> in the range &#091;<code>min</code>, <code>max</code>&#093; to a <em>ByteMemory</em> object.<br/>
	 * If no range is specified, all <code>input</code> bytes are copied.
	 * @throws de.polygonal.ds.error.AssertError invalid range, invalid <code>input</code> or memory deallocated (debug only).
	 */
	#if (flash9 || cpp)
	public static function ofByteArray(input:flash.utils.ByteArray, min = -1, max = -1):ByteMemory
	{
		#if debug
		assert(input != null, "invalid input");
		#end
		
		if (min == -1) min = 0;
		if (max == -1) max = input.length;
		
		input.position = min;
		
		#if debug
		assert(min >= 0, "min >= 0");
		assert(max <= Std.int(input.length), "max <= input.length");
		#end
		
		var output = new ByteMemory(max - min, "ofByteArray");
		for (i in min...max) output.set(i - min, input.readByte());
		return output;
	}
	#end
	
	/**
	 * Converts <code>input</code> in the range &#091;<code>min</code>, <code>max</code>&#093; to a <code>BytesData</code> object.<br/>
	 * If no range is specified, all <code>input</code> bytes are copied.</i><br/>
	 * <warn>The bytes are written in little endian format.</warn>
	 * @throws de.polygonal.ds.error.AssertError invalid range, invalid <code>input</code> or memory deallocated (debug only).
	 */
	public static function toBytesData(input:ByteMemory, min = -1, max = -1):haxe.io.BytesData
	{
		#if debug
		assert(input != null, "invalid input");
		#end
		
		if (min == -1) min = 0;
		if (max == -1) max = input.size;
		
		#if debug
		assert(min >= 0, 'min out of range ($min)');
		assert(max <= input.size, 'max out of range ($max)');
		assert(max - min > 0, 'min equals max ($min)');
		#end
		
		var output = new haxe.io.BytesBuffer();
		for (i in 0...max - min) output.addByte(input.get(min + i));
		return output.getBytes().getData();
	}
	
	/**
	 * Converts <code>input</code> in the range &#091;<code>min</code>, <code>max</code>&#093; to a <em>ByteMemory</em> object.<br/>
	 * If no range is specified, all <code>input</code> bytes are copied.
	 * @throws de.polygonal.ds.error.AssertError invalid range, invalid <code>input</code> or memory deallocated (debug only).
	 */
	public static function ofBytesData(input:haxe.io.BytesData, min = -1, max = -1):ByteMemory
	{
		#if debug
		assert(input != null, "invalid input");
		#end
		
		if (min == -1) min = 0;
		
		var bytes = haxe.io.Bytes.ofData(input);
		if (max == -1) max = bytes.length;
		
		#if debug
		assert(min >= 0, "min >= 0");
		assert(max <= Std.int(bytes.length), "max <= input.length");
		#end
		
		var output = new ByteMemory(max - min, "ofBytesData");
		for (i in min...max) output.set(i - min, bytes.get(i));
		return output;
	}
	
	/**
	 * Converts <code>input</code> in the range &#091;<code>min</code>, <code>max</code>&#093; to an array.<br/>
	 * If no range is specified, all <code>input</code> bytes are copied.
	 * @throws de.polygonal.ds.error.AssertError invalid range, invalid <code>input</code> or memory deallocated (debug only).
	 */
	public static function toArray(input:ByteMemory, min = -1, max = -1):Array<Int>
	{
		#if debug
		assert(input != null, "invalid input");
		#end
		
		if (min == -1) min = 0;
		if (max == -1) max = input.size;
		
		#if debug
		assert(min >= 0, 'min out of range ($min)');
		assert(max <= input.size, 'max out of range ($max)');
		assert(max - min > 0, 'min equals max ($min)');
		#end
		
		var output = new Array();
		
		#if alchemy
		min = input.getAddr(min);
		max = input.getAddr(max - 1);
		while (min <= max)
		{
			output.push(flash.Memory.getByte(min));
			min++;
		}
		#else
		for (i in 0...max - min) output[i] = input.get(min + i);
		#end
		
		return output;
	}
	
	/**
	 * Converts <code>input</code> in the range &#091;<code>min</code>, <code>max</code>&#093; to a <em>ByteMemory</em> object.<br/>
	 * If no range is specified, all <code>input</code> bytes are copied.
	 * @throws de.polygonal.ds.error.AssertError invalid range, invalid <code>input</code> or memory deallocated (debug only).
	 */
	public static function ofArray(input:Array<Int>, min = -1, max = -1):ByteMemory
	{
		#if debug
		assert(input != null, "invalid input");
		#end
		
		if (min == -1) min = 0;
		if (max == -1) max = input.length;
		
		#if debug
		assert(min >= 0, "min >= 0");
		assert(max <= Std.int(input.length), "max <= input.length");
		#end
		
		var output = new ByteMemory(max - min, "ofArray");
		for (i in min...max) output.set(i - min, input[i]);
		
		return output;
	}
	
	#if flash10
	/**
	 * Converts <code>input</code> in the range &#091;<code>min</code>, <code>max</code>&#093; to a Vector object.<br/>
	 * If no range is specified, all <code>input</code> bytes are copied.
	 * @param output the <code>Vector</code> object to write into. If null, a new Vector object is created on-the-fly.
	 * @throws de.polygonal.ds.error.AssertError invalid range, invalid <code>input</code> or memory deallocated (debug only).
	 */
	public static function toVector(input:ByteMemory, min = -1, max = -1, output:flash.Vector<Int> = null):flash.Vector<Int>
	{
		#if debug
		assert(input != null, "invalid input");
		#end
		
		if (min == -1) min = 0;
		if (max == -1) max = input.size;
		
		#if debug
		assert(min >= 0, 'min out of range ($min)');
		assert(max <= input.size, 'max out of range ($max)');
		assert(max - min > 0, 'min equals max ($min)');
		#end
		
		#if debug
		if (output != null)
			if (output.fixed)
				assert(Std.int(output.length) >= max - min, "output vector is too small");
		#end
		
		if (output == null) output = new flash.Vector<Int>(max - min, true);
		
		#if alchemy
		min = input.getAddr(min);
		max = input.getAddr(max - 1);
		var i = 0;
		while (min <= max)
		{
			output[i++] = flash.Memory.getByte(min);
			min++;
		}
		#else
		for (i in 0...max - min) output[i] = input.get(min + i);
		#end
		
		return output;
	}
	
	/**
	 * Converts <code>input</code> in the range &#091;<code>min</code>, <code>max</code>&#093; to a <em>ByteMemory</em> object.<br/>
	 * If no range is specified, all <code>input</code> bytes are copied.
	 * @throws de.polygonal.ds.error.AssertError invalid range, invalid <code>input</code> or memory deallocated (debug only).
	 */
	public static function ofVector(input:flash.Vector<Int>, min = -1, max = -1):ByteMemory
	{
		#if debug
		assert(input != null, "invalid input");
		#end
		
		if (min == -1) min = 0;
		if (max == -1) max = input.length;
		
		#if debug
		assert(min >= 0, "min >= 0");
		assert(max <= Std.int(input.length), "max <= input.length");
		#end
		
		var output = new ByteMemory(max - min, "ofVector");
		for (i in min...max) output.set(i - min, input[i]);
		
		return output;
	}
	#end
	
	#if !alchemy
		#if flash9
		var _data:flash.utils.ByteArray;
		#else
		var _data:haxe.io.Bytes;
		#end
	#end
	
	/**
	 * The size measured in bytes.
	 */
	public var size(default, null):Int;
	
	/**
	 * Creates a byte array capable of storing a total of <code>size</code> bytes.
	 */
	public function new(size:Int, name = "?")
	{
		super(this.size = size, name);
		
		#if !alchemy
			#if flash9
			_data = new flash.utils.ByteArray();
			_data.length = size;
			#else
			_data = haxe.io.Bytes.alloc(size);
			#end
		#end
	}
	
	#if !alchemy
	override public function free()
	{
		_data = null;
		super.free();
	}
	#end
	
	/**
	 * Creates a deep copy of this object.
	 */
	public function clone():ByteMemory
	{
		var c = new ByteMemory(bytes, name);
		#if alchemy
		var src = getAddr(0);
		var dst = c.getAddr(0);
		for (i in 0...size)
			flash.Memory.setByte(dst + i, flash.Memory.getByte(src + i));
		#else
		var t = c._data;
			#if flash9
			for (i in 0...size) t[i] = _data[i];
			#else
			for (i in 0...size)
			{
				#if flash9
				t[i] = _data[i];
				#else
				t.set(i, _data.get(i));
				#end
			}
			#end
		#end
		return c;
	}
	
	/**
	 * Sets all bytes to the value <code>x</code>. 
	 */
	public function fill(x:Int):ByteMemory
	{
		#if alchemy
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
	 * Adjusts the size of this object so it's capable of storing <code>newSize</code> bytes.
	 * @throws de.polygonal.ds.error.AssertError invalid size (debug only).
	 * @throws de.polygonal.ds.error.AssertError memory was already deallocated (debug only).
	 */
	override public function resize(newSize:Int)
	{
		#if debug
		assert(newSize >= 0, 'invalid size ($newSize)');
		#end
		
		#if alchemy
		super.resize(newSize);
		#else
			#if flash9
			var tmp = new flash.utils.ByteArray();
			tmp.length = newSize;
			for (i in 0...M.min(newSize, size)) tmp[i] = _data[i];
			#else
			var tmp = haxe.io.Bytes.alloc(newSize);
			for (i in 0...M.min(newSize, size)) tmp.set(i, _data.get(i));
			#end
		_data = tmp;
		#end
		
		size = newSize;
	}
	
	/**
	 * Returns the byte at index <code>i</code>.
	 * @throws de.polygonal.ds.error.AssertError segmentation Fault (debug only).
	 * @throws de.polygonal.ds.error.AssertError memory deallocated (debug only).
	 */
	inline public function get(i:Int):Int
	{
		#if alchemy
		return flash.Memory.getByte(getAddr(i));
		#else
			#if flash9
			return _data[i];
			#else
			return _data.get(i);
			#end
		#end
	}
	
	/**
	 * Replaces the byte at the index <code>i</code> with the byte <code>x</code>.
	 * @throws de.polygonal.ds.error.AssertError segmentation Fault (debug only).
	 * @throws de.polygonal.ds.error.AssertError memory deallocated (debug only).
	 */
	inline public function set(i:Int, x:Int)
	{
		#if alchemy
		flash.Memory.setByte(getAddr(i), x);
		#else
			#if flash9
			_data[i] = x;
			#else
			_data.set(i, x);
			#end
		#end
	}
	
	/**
	 * Swaps the byte at the index <code>i</code> with the byte at the index <code>j</code>.
	 * @throws de.polygonal.ds.error.AssertError <code>i</code> equals <code>j</code> (debug only).
	 * @throws de.polygonal.ds.error.AssertError segmentation Fault (debug only).
	 * @throws de.polygonal.ds.error.AssertError memory deallocated (debug only).
	 */
	inline public function swp(i:Int, j:Int)
	{
		#if debug
		assert(i != j, 'i equals j ($i)');
		#end
		
		#if alchemy
		var ai = getAddr(i);
		var aj = getAddr(j);
		var tmp = flash.Memory.getByte(ai);
		flash.Memory.setByte(ai, flash.Memory.getByte(aj));
		flash.Memory.setByte(ai, tmp);
		#else
		var tmp = get(i); set(i, get(j)); set(j, tmp);
		#end
	}
	
	/**
	 * Returns the memory byte offset for the byte at index <code>i</code>.
	 * @throws de.polygonal.ds.error.AssertError segmentation fault (debug only).
	 * @throws de.polygonal.ds.error.AssertError memory deallocated (debug only).
	 */
	inline public function getAddr(i:Int):Int
	{
		#if debug
		assert(i >= 0 && i < size, 'segfault, index $i');
		assert(_memory != null, "memory deallocated");
		#end
		
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
	 * Returns a string representing the current object.<br/>
	 * Prints out all elements if compiled with the <em>-debug</em> directive.<br/>
	 * Example:<br/>
	 * <pre class="prettyprint">
	 * var mem = new new de.polygonal.ds.mem.ByteMemory(4);
	 * for (i in 0...4) {
	 *     mem.set(i, i);
	 * }
	 * trace(mem);</pre>
	 * <pre class="console">
	 * { ByteMemory size: 4 }
	 * [
	 *   0 -> 0
	 *   1 -> 1
	 *   2 -> 2
	 *   3 -> 3
	 * ]</pre>
	 */
	public function toString():String
	{
		#if debug
		if (_memory == null) return "{ ByteMemory (unassigned) }";
		var s = '{ ByteMemory size: $size, name: $name }';
		s += "\n[\n";
		for (i in 0...size)
			s += Printf.format("  %3d -> %d\n", [i, get(i)]);
		s += "\n]";
		return s;
		#else
		return '{ ByteMemory size: $size, name: $name }';
		#end
	}
}