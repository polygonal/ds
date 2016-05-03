/*
Copyright (c) 2008-2016 Michael Baczynski, http://www.polygonal.de

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
package de.polygonal.ds;

import de.polygonal.ds.tools.Assert.assert;
import de.polygonal.ds.tools.M;

using de.polygonal.ds.tools.NativeArrayTools;

using de.polygonal.ds.Bits;

/**
	An array data structure that compactly stores individual bits (boolean values)
**/
class BitVector implements Hashable
{
	/**
		A unique identifier for this object.
		
		A hash table transforms this key into an index of an array element by using a hash function.
		
		<warn>This value should never be changed by the user.</warn>
	**/
	public var key(default, null):Int = HashKey.next();
	
	/**
		The exact number of bits that the bit-vector can store.
	**/
	public var capacity(get, never):Int;
	inline function get_capacity():Int
	{
		return mBitSize;
	}
	
	var mData:NativeArray<Int>;
	var mArrSize:Int;
	var mBitSize:Int;
	
	/**
		Creates a bit-vector capable of storing a total of `numBits` bits.
	**/
	public function new(numBits:Int)
	{
		assert(numBits > 0);
		
		mData = null;
		mBitSize = 0;
		mArrSize = 0;
		resize(numBits);
	}
	
	/**
		Destroys this object by explicitly nullifying the array storing the bits.
	**/
	public function free()
	{
		mData = null;
	}
	
	/**
		The total number of bits set to one.
	**/
	public function ones():Int
	{
		var c = 0, d = mData;
		for (i in 0...mArrSize) c += d.get(i).ones();
		return c;
	}
	
	/**
		The total number of 32-bit integers allocated for storing the bits.
	**/
	public inline function bucketSize():Int
	{
		return mArrSize;
	}
	
	/**
		Returns true if the bit at index `i` is 1.
	**/
	public inline function has(i:Int):Bool
	{
		assert(i < capacity, 'i index out of range ($i)');
		
		return ((mData.get(i >> 5) & (1 << (i & (32 - 1)))) >> (i & (32 - 1))) != 0;
	}
	
	/**
		Sets the bit at index `i` to one.
	**/
	public inline function set(i:Int)
	{
		assert(i < capacity, 'i index out of range ($i)');
		
		var p = i >> 5, d = mData;
		d.set(p, d.get(p) | (1 << (i & (32 - 1))));
	}
	
	/**
		Sets the bit at index `i` to zero.
	**/
	public inline function clr(i:Int)
	{
		assert(i < capacity, 'i index out of range ($i)');
		
		var p = i >> 5, d = mData;
		d.set(p, d.get(p) & (~(1 << (i & (32 - 1)))));
	}
	
	/**
		Sets all bits in the bit-vector to zero.
	**/
	public inline function clrAll()
	{
		#if cpp
		cpp.NativeArray.zero(mData, 0, mArrSize);
		#else
		var d = mData;
		for (i in 0...mArrSize) d.set(i, 0);
		#end
	}
	
	/**
		Sets all bits in the bit-vector to one.
	**/
	public inline function setAll()
	{
		var d = mData;
		for (i in 0...mArrSize) d.set(i, -1);
	}
	
	/**
		Clears all bits in the range [`min`, `max`).
		
		This is faster than clearing individual bits by using `clr()`.
	**/
	public function clrRange(min:Int, max:Int)
	{
		assert(min >= 0 && min <= max && max < mBitSize, 'min/max out of range ($min/$max)');
		
		var current = min, binIndex, nextBound, mask, d = mData;
		while (current < max)
		{
			binIndex = current >> 5;
			nextBound = (binIndex + 1) << 5;
			mask = -1 << (32 - nextBound + current);
			mask &= (max < nextBound) ? -1 >>> (nextBound - max) : -1;
			d.set(binIndex, d.get(binIndex) & ~mask);
			current = nextBound;
		}
	}
	
	/**
		Sets all bits in the range [`min`, `max`).
		
		This is faster than setting individual bits by using `set()`.
	**/
	public function setRange(min:Int, max:Int)
	{
		assert(min >= 0 && min <= max && max < mBitSize, 'min/max out of range ($min/$max)');
		
		var current = min;
		while (current < max)
		{
			var binIndex = current >> 5;
			var nextBound = (binIndex + 1) << 5;
			var mask = -1 << (32 - nextBound + current);
			mask &= (max < nextBound) ? -1 >>> (nextBound - max) : -1;
			mData.set(binIndex, mData.get(binIndex) | mask);
			current = nextBound;
		}
	}
	
	/**
		Sets the bit at index `i` to one if `cond` is true or clears the bit at index `i` if `cond` is false.
	**/
	public inline function ofBool(i:Int, cond:Bool)
	{
		cond ? set(i) : clr(i);
	}
	
	/**
		Returns the bucket at index `i`.
		
		A bucket is a 32-bit integer for storing the bit flags.
	**/
	public inline function getBucketAt(i:Int):Int
	{
		assert(i >= 0 && i < mArrSize, 'i index out of range ($i)');
		
		return mData.get(i);
	}
	
	/**
		Writes all buckets to `out`.
		
		A bucket is a 32-bit integer for storing the bit flags.
		@return the total number of buckets.
	**/
	public inline function getBuckets(out:Array<Int>):Int
	{
		var d = mData;
		for (i in 0...mArrSize) out[i] = d.get(i);
		return mArrSize;
	}
	
	/**
		Resizes the bit-vector to `numBits` bits.
		
		Preserves existing values if new size > old size.
	**/
	public function resize(numBits:Int)
	{
		if (mBitSize == numBits) return;
		
		var newArrSize = numBits >> 5;
		if ((numBits & (32 - 1)) > 0) newArrSize++;
		
		if (mData == null || newArrSize < mArrSize)
		{
			mData = NativeArrayTools.alloc(newArrSize);
			mData.zero(0, newArrSize);
		}
		else
		if (newArrSize > mArrSize)
		{
			var t = NativeArrayTools.alloc(newArrSize);
			t.zero(0, newArrSize);
			mData.blit(0, t, 0, mArrSize);
			mData = t;
		}
		else
		if (numBits < mBitSize)
			mData.zero(0, newArrSize);
		
		mBitSize = numBits;
		mArrSize = newArrSize;
	}
	
	/**
		Writes the data in this bit-vector to a byte array.
		
		The number of bytes equals `bucketSize()` * 4 and the number of bits equals `capacity`.
		@param bigEndian the byte order (default is little endian)
	**/
	public function toBytes(bigEndian:Bool = false):haxe.io.BytesData
	{
		#if flash
		var out = new flash.utils.ByteArray();
		if (!bigEndian) out.endian = flash.utils.Endian.LITTLE_ENDIAN;
		for (i in 0...mArrSize)
			out.writeInt(mData.get(i));
		return out;
		#else
		var out = new haxe.io.BytesOutput();
		out.bigEndian = bigEndian;
		for (i in 0...mArrSize)
			out.writeInt32(mData.get(i));
		return out.getBytes().getData();
		#end
	}
	
	/**
		Copies the bits from `bytes` into this bit vector.
		
		The bit-vector is resized to the size of `bytes`.
		@param bigEndian the input byte order (default is little endian)
	**/
	public function ofBytes(bytes:haxe.io.BytesData, bigEndian:Bool = false)
	{
		#if flash
		var input = bytes;
		input.position = 0;
		if (!bigEndian) input.endian = flash.utils.Endian.LITTLE_ENDIAN;
		#else
		var input = new haxe.io.BytesInput(haxe.io.Bytes.ofData(bytes));
		input.bigEndian = bigEndian;
		#end
		
		var k =
		#if neko
		neko.NativeString.length(bytes);
		#elseif js
		bytes.byteLength;
		#else
		bytes.length;
		#end
		
		var numBytes = k & 3;
		var numIntegers = (k - numBytes) >> 2;
		mArrSize = numIntegers + (numBytes > 0 ? 1 : 0);
		mBitSize = mArrSize << 5;
		mData = NativeArrayTools.alloc(mArrSize);
		for (i in 0...mArrSize) mData.set(i, 0);
		for (i in 0...numIntegers)
		{
			#if flash
			mData.set(i, input.readInt());
			#elseif cpp
			mData.set(i, (cast input.readInt32()) & 0xFFFFFFFF);
			#else
			mData.set(i, cast input.readInt32());
			#end
		}
		var index:Int = numIntegers << 5;
		var shift = 0, t = 0;
		for (i in 0...numBytes)
		{
			var b = input.readByte();
			for (j in 0...8)
			{
				if ((b & 1) == 1) set(index);
				b >>= 1;
				index++;
			}
		}
	}
	
	/**
		Prints out all elements.
	**/
	public function toString():String
	{
		#if no_tostring
		return Std.string(this);
		#else
		var b = new StringBuf();
		b.add('{ BitVector bits: ${capacity} }');
		if (ones() == 0) return b.toString();
		b.add("\n[\n");
		var args = new Array<Dynamic>();
		var fmt = '  %${M.numDigits(mArrSize)}d: %.32b\n';
		for (i in 0...mArrSize)
		{
			args[0] = i;
			args[1] = mData.get(i);
			b.add(Printf.format(fmt, args));
		}
		b.add("]");
		return b.toString();
		#end
	}
	
	/**
		Creates a copy of this bit vector.
	**/
	public function clone():BitVector
	{
		var copy = new BitVector(mBitSize);
		mData.blit(0, copy.mData, 0, mArrSize);
		return copy;
	}
}