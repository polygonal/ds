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
package de.polygonal.ds.tools;

import de.polygonal.ds.tools.Assert.assert;

/**
	Helper class for working with bits
**/
class Bits
{
	/**
		Constructs a mask of `n` bits.
	**/
	public static inline function mask(n:Int):Int
	{
		assert(n >= 1 && n <= 32);
		
		return (1 << n) - 1;
	}
	
	/**
		Counts the number of "1"-bits in `x`. For example 0b00110111 has 5 bits set.
	**/
	public static inline function ones(x:Int)
	{
		x -= ((x >> 1) & 0x55555555);
		x = (((x >> 2) & 0x33333333) + (x & 0x33333333));
		x = (((x >> 4) + x) & 0x0F0F0F0F);
		x += (x >> 8);
		x += (x >> 16);
		return(x & 0x0000003F);
	}
	
	/**
		Counts the number of trailing 0's in `x`. For example 0b10000 has 4 trailing 0's.
	**/
	public static inline function ntz(x:Int):Int
	{
		#if (flash && alchemy)
		if (x == 0)
			return 0;
		else
		{
			if (flash.Memory.getByte(956) != 31)
			{
				var x = 0x077CB531;
				for (i in 0...32)
				{
					flash.Memory.setI32(cast(1020 - ((x >>> 27) << 2), UInt), i);
					x <<= 1;
				}
			}
			return flash.Memory.getI32(cast(1020 - ((((x & -x) * 0x077CB531) >>> 27) << 2), UInt));
		}
		#else
		var n = 0;
		if (x != 0)
		{
			x = (x ^ (x - 1)) >>> 1;
			while (x != 0)
			{
				x >>= 1;
				n++;
			}
		}
		return n;
		#end
	}
	
	/**
		Counts the number of leading 0's in `x`. For example 0b10000 has 27 leading 0's.
	**/
	public static inline function nlz(x:Int):Int
	{
		if (x < 0)
			return 0;
		else
		{
			x |= (x >> 1);
			x |= (x >> 2);
			x |= (x >> 4);
			x |= (x >> 8);
			x |= (x >> 16);
			return(32 - ones(x));
		}
	}
	
	/**
		Returns the most significant bit of `x`.
	**/
	public static inline function msb(x:Int):Int
	{
		x |= (x >> 1);
		x |= (x >> 2);
		x |= (x >> 4);
		x |= (x >> 8);
		x |= (x >> 16);
		return(x & ~(x >>> 1));
	}
	
	/**
		Bitwise rotates the integer `x` by `n` places to the left.
	**/
	public static inline function rol(x:Int, n:Int)
	{
		return (x << n) | (x >>> (32 - n));
	}
	
	/**
		Bitwise rotates the integer `x` by `n` places to the right.
	**/
	public static inline function ror(x:Int, n:Int)
	{
		return (x >>> n) | (x << (32 - n));
	}
	
	/**
		Reverses `x`; For example 0b111000 becomes 0b000111.
	**/
	public static inline function reverse(x:Int):Int
	{
		var y = 0x55555555;
		x = (((x >> 1) & y) | ((x & y) << 1));
		y = 0x33333333;
		x = (((x >> 2) & y) | ((x & y) << 2));
		y = 0x0F0F0F0F;
		x = (((x >> 4) & y) | ((x & y) << 4));
		y = 0x00FF00FF;
		x = (((x >> 8) & y) | ((x & y) << 8));
		return (x >> 16) | (x << 16);
	}
	
	/**
		Flips the bytes within the WORD `x` (2 bytes) to convert between little endian and big endian format.
	**/
	public static inline function flipWORD(x:Int):Int
	{
		return (x << 8 | x >> 8);
	}
	
	/**
		Flips the bytes within the DWORD `x` (4 bytes) to convert between little endian and big endian format.
	**/
	public static inline function flipDWORD(x:Int):Int
	{
		return (x << 24 | ((x << 8) & 0x00FF0000) | ((x >> 8) & 0x0000FF00) | x >> 24);
	}
	
	/**
		Swaps the bit at index `i` with the bit at index `j` in the bit field `x` (LSB=0).
	**/
	public static inline function swap(x:Int, i:Int, j:Int):Int
	{
		var t = ((x >> i) ^ (x >> j)) & 0x01;
		return x ^ ((t << i) | (t << j));
	}
}