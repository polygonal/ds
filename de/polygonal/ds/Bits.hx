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
package de.polygonal.ds;

import de.polygonal.ds.error.Assert.assert;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
#end

/**
 * <p>Helper class for working with bit flags.</p>
 */
class Bits 
{
	/**
	 * 1 << 00 (0x00000001) 
	 */
	inline public static var BIT_01 = 1 << 00;
	/**
	 * 1 << 01 (0x00000002) 
	 */
	inline public static var BIT_02 = 1 << 01;
	/**
	 * 1 << 02 (0x00000004) 
	 */
	inline public static var BIT_03 = 1 << 02;
	/**
	 * 1 << 03 (0x00000008) 
	 */
	inline public static var BIT_04 = 1 << 03;
	/**
	 * 1 << 04 (0x00000010) 
	 */
	inline public static var BIT_05 = 1 << 04;
	/**
	 * 1 << 05 (0x00000020) 
	 */
	inline public static var BIT_06 = 1 << 05;
	/**
	 * 1 << 06 (0x00000040) 
	 */
	inline public static var BIT_07 = 1 << 06;
	/**
	 * 1 << 07 (0x00000080) 
	 */
	inline public static var BIT_08 = 1 << 07;
	/**
	 * 1 << 08 (0x00000100) 
	 */
	inline public static var BIT_09 = 1 << 08;
	/**
	 * 1 << 09 (0x00000200) 
	 */
	inline public static var BIT_10 = 1 << 09;
	/**
	 * 1 << 10 (0x00000400) 
	 */
	inline public static var BIT_11 = 1 << 10;
	/**
	 * 1 << 11 (0x00000800) 
	 */
	inline public static var BIT_12 = 1 << 11;
	/**
	 * 1 << 12 (0x00001000) 
	 */
	inline public static var BIT_13 = 1 << 12;
	/**
	 * 1 << 13 (0x00002000) 
	 */
	inline public static var BIT_14 = 1 << 13;
	/**
	 * 1 << 14 (0x00004000) 
	 */
	inline public static var BIT_15 = 1 << 14;
	/**
	 * 1 << 15 (0x00008000) 
	 */
	inline public static var BIT_16 = 1 << 15;
	/**
	 * 1 << 16 (0x00010000) 
	 */
	inline public static var BIT_17 = 1 << 16;
	/**
	 * 1 << 17 (0x00020000) 
	 */
	inline public static var BIT_18 = 1 << 17;
	/**
	 * 1 << 18 (0x00040000) 
	 */
	inline public static var BIT_19 = 1 << 18;
	/**
	 * 1 << 19 (0x00080000) 
	 */
	inline public static var BIT_20 = 1 << 19;
	/**
	 * 1 << 20 (0x00100000) 
	 */
	inline public static var BIT_21 = 1 << 20;
	/**
	 * 1 << 21 (0x00200000) 
	 */
	inline public static var BIT_22 = 1 << 21;
	/**
	 * 1 << 22 (0x00400000) 
	 */
	inline public static var BIT_23 = 1 << 22;
	/**
	 * 1 << 23 (0x00800000) 
	 */
	inline public static var BIT_24 = 1 << 23;
	/**
	 * 1 << 24 (0x01000000) 
	 */
	inline public static var BIT_25 = 1 << 24;
	/**
	 * 1 << 25 (0x02000000) 
	 */
	inline public static var BIT_26 = 1 << 25;
	/**
	 * 1 << 26 (0x04000000) 
	 */
	inline public static var BIT_27 = 1 << 26;
	/**
	 * 1 << 27 (0x08000000) 
	 */
	inline public static var BIT_28 = 1 << 27;
	/**
	 * 1 << 28 (0x10000000) 
	 */
	inline public static var BIT_29 = 1 << 28;
	/**
	 * 1 << 29 (0x20000000) 
	 */
	inline public static var BIT_30 = 1 << 29;
	
	/**
	 * 1 << 30 (0x40000000) 
	 */
	inline public static var BIT_31 = 1 << 30;
	
	/**
	 * 1 << 31 (0x80000000) 
	 */
	inline public static var BIT_32 = 1 << 31;
	
	/**
	 * 0xFFFFFFFF 
	 */
	inline public static var ALL = -1;
	
	/**
	 * Returns <code>x</code> AND <code>mask</code>. 
	 */
	inline public static function getBits(x:Int, mask:Int):Int { return x & mask; }
	
	/**
	 * Returns true if <code>x</code> AND <code>mask</code> != 0. 
	 */
	inline public static function hasBits(x:Int, mask:Int):Bool { return (x & mask) != 0; }
	
	/**
	 * Returns true if <code>x</code> AND <code>mask</code> == <code>mask</code> (<code>x</code> includes all <code>mask</code> bits). 
	 */
	inline public static function incBits(x:Int, mask:Int):Bool { return (x & mask) == mask; }
	
	/**
	 * Returns <code>x</code> OR <code>mask</code>. 
	 */
	inline public static function setBits(x:Int, mask:Int):Int { return x | mask; }
	
	/**
	 * Returns <code>x</code> AND ~<code>mask</code>. 
	 */
	inline public static function clrBits(x:Int, mask:Int):Int
	{
		return x & ~mask;
	}
	
	/**
	 * Returns <code>x</code> ^ <code>mask</code>. 
	 */
	inline public static function invBits(x:Int, mask:Int):Int { return x ^ mask; }
	
	/**
	 * Sets all <code>mask</code> bits in <code>x</code> if <code>expr</code> is true,
	 * or clears all <code>mask</code> bits in <code>x</code> if <code>expr</code> is false. */
	inline public static function setBitsIf(x:Int, mask:Int, expr:Bool):Int
	{
		return expr ? (x | mask) : (x & ~mask);
	}
	
	/**
	 * Returns true if the bit in <code>x</code> at index <code>i</code> (LSB 0) is 1.
	 * @throws de.polygonal.ds.error.AssertError index out of range (debug only).
	 */
	inline public static function hasBitAt(x:Int, i:Int):Bool
	{
		#if debug
		assert(i >= 0 && i < 32, 'index out of range ($i)');
		#end
		
		return (x & (1 << i)) != 0;
	}
	
	/**
	 * Sets the bit in <code>x</code> at index <code>i</code> (LSB 0) to 1.
	 * @throws de.polygonal.ds.error.AssertError index out of range (debug only).
	 */
	inline public static function setBitAt(x:Int, i:Int):Int
	{
		#if debug
		assert(i >= 0 && i < 32, 'index out of range ($i)');
		#end
		
		return x | (1 << i);
	}
	
	/**
	 * Sets the bit in <code>x</code> at index <code>i</code> (LSB 0) to 0.
	 * @throws de.polygonal.ds.error.AssertError index out of range (debug only).
	 */
	inline public static function clrBitAt(x:Int, i:Int):Int
	{
		#if debug
		assert(i >= 0 && i < 32, 'index out of range ($i)');
		#end
		
		return x & ~(1 << i);
	}
	
	/**
	 * Flips the bit in <code>x</code> at index <code>i</code> (LSB 0).
	 * @throws de.polygonal.ds.error.AssertError index out of range (debug only).
	 */
	inline public static function invBitAt(x:Int, i:Int):Int
	{
		#if debug
		assert(i >= 0 && i < 32, 'index out of range ($i)');
		#end
		
		return x ^ (1 << i);
	}
	
	/**
	 * Sets all bits in <code>x</code> in the range &#091;0, 31&#093;.
	 * @throws de.polygonal.ds.error.AssertError invalid range (debug only).
	 */
	inline public static function setBitsRange(x:Int, min:Int, max:Int):Int
	{
		#if debug
		assert
		(
			min < max  &&
			min != max &&
			min >= 0   &&
			min < 32,
			'invalid range (min: $min, max: $max)'
		);
		#end
		
		for (i in min...max) x = setBits(x, 1 << i);
		return x;
	}
	
	/**
	 * Constructs a mask of n bits. 
	 */
	inline public static function mask(n:Int):Int
	{
		#if debug
		assert(n >= 1 && n <= 32, "n >= 1 && n <= 32");
		#end
		
		return (1 << n) - 1;
	}
	
	/**
	 * Counts the number of "1"-bits.<br/>
	 * e.g. 00110111 has 5 bits set.
	 */
	inline public static function ones(x:Int)
	{
		x -= ((x >> 1) & 0x55555555);
		x = (((x >> 2) & 0x33333333) + (x & 0x33333333));
		x = (((x >> 4) + x) & 0x0f0f0f0f);
		x += (x >> 8);
		x += (x >> 16);
		return(x & 0x0000003f);
	}
	
	/**
	 * Counts the number of trailing 0's.<br/>
	 * e.g. 16 (0x10 or b10000) has 4 trailing 0's.
	 */
	inline public static function ntz(x:Int):Int
	{
		#if (flash10 && alchemy)
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
	 * Counts the number of leading 0's.<br/>
	 * e.g. 16 (0x10 or b10000) has 27 leading 0's.
	 */
	inline public static function nlz(x:Int):Int
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
	 * Returns the most significant bit of <code>x</code>. 
	 */
	inline public static function msb(x:Int):Int
	{
		x |= (x >> 1);
		x |= (x >> 2);
		x |= (x >> 4);
		x |= (x >> 8);
		x |= (x >> 16);
		return(x & ~(x >>> 1));
	}
	
	/**
	 * Bitwise rotates the integer <code>x</code> by <code>n</code> places to the left. 
	 */
	inline public static function rol(x:Int, n:Int) { return (x << n) | (x >>> (32 - n)); }
	
	/**
	 * Bitwise rotates the integer <code>x</code> by <code>n</code> places to the right. 
	 */
	inline public static function ror(x:Int, n:Int) { return (x >>> n) | (x << (32 - n)); }
	
	/**
	 * Reverses <code>x</code>.<br/>
	 * e.g. b111000 becomes b000111.
	 */
	inline public static function reverse(x:Int):Int
	{
		var y = 0x55555555;
		x = (((x >> 1) & y) | ((x & y) << 1));
		y = 0x33333333;
		x = (((x >> 2) & y) | ((x & y) << 2));
		y = 0x0f0f0f0f;
		x = (((x >> 4) & y) | ((x & y) << 4));
		y = 0x00ff00ff;
		x = (((x >> 8) & y) | ((x & y) << 8));
		return((x >> 16) | (x << 16));
	}
	
	/**
	 * Flips the bytes within the WORD <code>x</code> (2 byte) to convert between little endian and big endian format. 
	 */
	inline public static function flipWORD(x:Int):Int
	{
		return (x << 8 | x >> 8);
	}
	
	/**
	 * Flips the bytes within the DWORD <code>x</code> (4 byte) to convert between little endian and big endian format. 
	 */
	inline public static function flipDWORD(x:Int):Int
	{
		return (x << 24 | ((x << 8) & 0x00FF0000) | ((x >> 8) & 0x0000FF00) | x >> 24);
	}
	
	/**
	 * Packs two signed shorts into a single integer.
	 * @param lo the short that is stored in the lower 16 bits (LSB 0).
	 * @param hi the short that is stored in the upper 16 bits.
	 */
	inline public static function packI16(lo:Int, hi:Int):Int
	{
		#if debug
		assert(lo >= M.INT16_MIN && lo <= M.INT16_MAX, "lo overflow");
		assert(hi >= M.INT16_MIN && hi <= M.INT16_MAX, "hi overflow");
		#end
		
		return ((hi + 0x8000) << 16) | (lo + 0x8000);
	}
	
	/**
	 * Packs two unsigned shorts into a single integer.
	 * @param lo the short that is stored in the lower 16 bits (LSB 0).
	 * @param hi the short that is stored in the upper 16 bits.
	 */
	inline public static function packUI16(lo:Int, hi:Int):Int
	{
		#if debug
		assert(lo >= 0 && lo <= M.UINT16_MAX, "lo overflow");
		assert(hi >= 0 && hi <= M.UINT16_MAX, "hi overflow");
		#end
		
		return (hi << 16) | lo;
	}
	
	/**
	 * Extracts a signed short from the lower 16 bits (LSB 0). 
	 */
	inline public static function unpackI16Lo(x:Int):Int
	{
		return (x & 0xffff) - 0x8000;
	}
	
	/**
	 * Extracts a signed short from the upper 16 bits (LSB 0). 
	 */
	inline public static function unpackI16Hi(x:Int):Int
	{
		return (x >>> 16) - 0x8000;
	}
	
	
	/**
	 * Extracts an unsigned short from the lower 16 bits (LSB 0). 
	 */
	inline public static function unpackUI16Lo(x:Int):Int
	{
		return x & 0xffff;
	}
	
	/**
	 * Extracts an unsigned short from the upper 16 bits (LSB 0). 
	 */
	inline public static function unpackUI16Hi(x:Int):Int
	{
		return x >>> 16;
	}
}