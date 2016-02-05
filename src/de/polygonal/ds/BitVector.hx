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
package de.polygonal.ds;

import de.polygonal.ds.error.Assert.assert;

using de.polygonal.ds.tools.NativeArray;

using de.polygonal.ds.Bits;

/**
	An array data structure that compactly stores individual bits (boolean values)
	
	_<o>Worst-case running time in Big O notation</o>_
**/
class BitVector implements Hashable
{
	/**
		A unique identifier for this object.
		
		A hash table transforms this key into an index of an array element by using a hash function.
		
		<warn>This value should never be changed by the user.</warn>
	**/
	public var key(default, null):Int;
	
	var mData:Container<Int>;
	var mArrSize:Int;
	var mBitSize:Int;
	
	/**
		Creates a bit-vector capable of storing a total of `numBits` bits.
		
		<assert>invalid `numBits` value</assert>
	**/
	public function new(numBits:Int)
	{
		assert(numBits > 0);
		
		mData = null;
		mBitSize = 0;
		mArrSize = 0;
		resize(numBits);
		key = HashKey.next();
	}
	
	/**
		Destroys this object by explicitly nullifying the array storing the bits.
		<o>1</o>
	**/
	public function free()
	{
		mData = null;
	}
	
	/**
		The exact number of bits that the bit-vector can store.
		<o>1</o>
	**/
	inline public function capacity():Int
	{
		return mBitSize;
	}
	
	/**
		The total number of bits set to one.
		<o>n</o>
	**/
	inline public function size():Int
	{
		var c = 0, d = mData;
		for (i in 0...mArrSize) c += d.get(i).ones();
		return c;
	}
	
	/**
		The total number of 32-bit integers allocated for storing the bits.
		<o>1</o>
	**/
	inline public function bucketSize():Int
	{
		return mArrSize;
	}
	
	/**
		Returns true if the bit at index `i` is 1.
		<o>1</o>
		<assert>`i` out of range</assert>
	**/
	inline public function has(i:Int):Bool
	{
		assert(i < capacity(), 'i index out of range ($i)');
		
		return ((mData.get(i >> 5) & (1 << (i & (32 - 1)))) >> (i & (32 - 1))) != 0;
	}
	
	/**
		Sets the bit at index `i` to one.
		<o>1</o>
		<assert>`i` out of range</assert>
	**/
	inline public function set(i:Int)
	{
		assert(i < capacity(), 'i index out of range ($i)');
		
		var p = i >> 5, d = mData;
		d.set(p, d.get(p) | (1 << (i & (32 - 1))));
	}
	
	/**
		Sets the bit at index `i` to zero.
		<o>1</o>
		<assert>`i` out of range</assert>
	**/
	inline public function clr(i:Int)
	{
		assert(i < capacity(), 'i index out of range ($i)');
		
		var p = i >> 5, d = mData;
		d.set(p, d.get(p) & (~(1 << (i & (32 - 1)))));
	}
	
	/**
		Sets all bits in the bit-vector to zero.
		<o>n</o>
	**/
	inline public function clrAll()
	{
		var d = mData;
		
		#if cpp
		cpp.NativeArray.zero(mData, 0, mArrSize);
		#else
		var d = mData;
		for (i in 0...mArrSize) d.set(i, 0);
		#end
	}
	
	/**
		Sets all bits in the bit-vector to one.
		<o>n</o>
	**/
	inline public function setAll()
	{
		var d = mData;
		for (i in 0...mArrSize) d.set(i, -1);
	}
	
	/**
		Clears all bits in the range [`min`, `max`).
		
		This is faster than clearing individual bits by using ``clr()``.
		<o>n</o>
		<assert>`min` out of range</assert>
		<assert>`max` out of range</assert>
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
		
		This is faster than setting individual bits by using ``set()``.
		<o>n</o>
		<assert>`min` out of range</assert>
		<assert>`max` out of range</assert>
	**/
	public function setRange(min:Int, max:Int)
	{
		assert(min >= 0 && min <= max && max < mBitSize, 'min/max out of range ($min/$max)');
		
		var current = min;
		
		while ( current < max )
		{
			var binIndex = current >> 5;
			var nextBound = (binIndex + 1) << 5;
			var mask = -1 << (32 - nextBound + current);
			mask &= (max < nextBound) ? -1 >>> (nextBound - max) : -1;
			mData[binIndex] |= mask;
			
			current = nextBound;
		}
	}
	
	/**
		Sets the bit at index `i` to one if `cond` is true or clears the bit at index `i` if `cond` is false.
		<o>1</o>
		<assert>`i` out of range</assert>
	**/
	inline public function ofBool(i:Int, cond:Bool)
	{
		cond ? set(i) : clr(i);
	}
	
	/**
		Returns the bucket at index `i`.
		
		A bucket is a 32-bit integer for storing the bit flags.
		<assert>`i` out of range</assert>
	**/
	inline public function getBucketAt(i:Int):Int
	{
		assert(i >= 0 && i < mArrSize, 'i index out of range ($i)');
		
		return mData[i];
	}
	
	/**
		Writes all buckets to `output`.
		
		A bucket is a 32-bit integer for storing the bit flags.
		@return the total number of buckets.
	**/
	inline public function getBuckets(output:Array<Int>):Int
	{
		var d = mData;
		for (i in 0...mArrSize) output[i] = d.get(i);
		return mArrSize;
	}
	
	/**
		Resizes the bit-vector to `numBits` bits.
		
		Preserves existing values if new size > old size.
		<o>n</o>
	**/
	public function resize(numBits:Int)
	{
		if (mBitSize == numBits) return;
		
		var newArrSize = numBits >> 5;
		if ((numBits & (32 - 1)) > 0) newArrSize++;
		
		if (mData == null || newArrSize < mArrSize)
		{
			mData = NativeArray.init(newArrSize);
			mData.zero(0, newArrSize);
		}
		else
		if (newArrSize > mArrSize)
		{
			var tmp = NativeArray.init(newArrSize);
			tmp.zero(0, newArrSize);
			mData.blit(0, tmp, 0, mArrSize);
			mData = tmp;
		}
		else
		if (numBits < mBitSize)
			mData.zero(0, newArrSize);
		
		mBitSize = numBits;
		mArrSize = newArrSize;
	}
	
	/**
		Writes the data in this bit-vector to a byte array.
		
		The number of bytes equals ``bucketSize()`` * 4 and the number of bits equals ``capacity()``.
		<o>n</o>
		@param bigEndian the byte order (default is little endian)
	**/
	public function toBytes(bigEndian = false):haxe.io.BytesData
	{
		#if flash
		var output = new flash.utils.ByteArray();
		if (!bigEndian) output.endian = flash.utils.Endian.LITTLE_ENDIAN;
		for (i in 0...mArrSize)
			output.writeInt(mData[i]);
		return output;
		#else
		var output = new haxe.io.BytesOutput();
		output.bigEndian = bigEndian;
		for (i in 0...mArrSize)
			output.writeInt32(mData[i]);
		return output.getBytes().getData();
		#end
	}
	
	/**
		Copies the bits from `bytes` into this bit vector.
		
		The bit-vector is resized to the size of `bytes`.
		<o>n</o>
		<assert>`input` is null</assert>
		@param bigEndian the input byte order (default is little endian)
	**/
	public function ofBytes(bytes:haxe.io.BytesData, bigEndian = false)
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
		mData = NativeArray.init(mArrSize);
		for (i in 0...mArrSize) mData[i] = 0;
		for (i in 0...numIntegers)
		{
			#if flash
			mData[i] = input.readInt();
			#elseif cpp
			mData[i] = (cast input.readInt32()) & 0xFFFFFFFF;
			#else
			mData[i] = cast input.readInt32();
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
		Returns a string representing the current object.
		
		Example:
		<pre class="prettyprint">
		var bv = new de.polygonal.ds.BitVector(40);
		for (i in 0...bv.capacity()) {
		    if (i & 1 == 0) {
		        bv.set(i);
		    }
		}
		trace(bv);</pre>
		<pre class="console">
		{ BitVector set/all: 20/40 }
		[
		  0 -> b01010101010101010101010101010101
		  1 -> b00000000000000000000000001010101
		]</pre>
	**/
	public function toString():String
	{
		var s = '{ BitVector set/all: ${size()}/${capacity()} }';
		if (size() == 0) return s;
		s += "\n[\n";
		for (i in 0...mArrSize)
			s += Printf.format("  %4d -> %#.32b\n", [i, mData[i]]);
		s += "]";
		return s;
	}
	
	/**
		Creates a copy of this bit vector.
		<o>n</o>
	**/
	public function clone():BitVector
	{
		var copy = new BitVector(mBitSize);
		mData.blit(0, copy.mData, 0, mArrSize);
		return copy;
	}
}