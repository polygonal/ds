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

using de.polygonal.ds.Bits;

#if !doc
private
#end
/**
	Grants access to the private `mBits` field storing the bit field.
**/
typedef BitField =
{
	/**
		The bit field.
	**/
	private var mBits:Int;
}

/**
	<h3>Helper class for working with bit flags.</h3>
**/
class BitFlags
{
	/**
		Returns `x` AND `mask`.
	**/
	inline public static function getf(x:BitField, mask:Int):Int
	{
		return x.mBits.getBits(mask);
	}
	
	/**
		Returns `x` AND `mask` != 0
	**/
	inline public static function hasf(x:BitField, mask:Int):Bool
	{
		return x.mBits.hasBits(mask);
	}
	
	/**
		Returns `x` AND `mask` == `mask` (`x` includes all `mask` bits).
	**/
	inline public static function incf(x:BitField, mask:Int):Bool
	{
		return x.mBits.incBits(mask);
	}
	
	/**
		`x` = `x` | `mask`.
	**/
	inline public static function setf(x:BitField, mask:Int)
	{
		x.mBits = x.mBits.setBits(mask);
	}
	
	/**
		`x` = `x` AND ~`mask`.
	**/
	inline public static function clrf(x:BitField, mask:Int)
	{
		x.mBits = x.mBits.clrBits(mask);
	}
	
	/**
		`x` = `x` ^ `mask`.
	**/
	inline public static function invf(x:BitField, mask:Int)
	{
		x.mBits = x.mBits.invBits(mask);
	}
	
	/**
		`x` = 0.
	**/
	inline public static function nulf(x:BitField)
	{
		x.mBits = 0;
	}
	
	/**
		`x` = `other`.
	**/
	inline public static function cpyf(x:BitField, other:BitField)
	{
		x.mBits = other.mBits;
	}
	
	/**
		Swaps the bit at index `i` with the bit at index `j` (LSB 0).
		@param x the bits that are modified.
	**/
	inline public static function swpf(x:BitField, i:Int, j:Int)
	{
		var b = x.mBits;
		var t = ((b >> i) ^ (b >> j)) & 0x01;
		x.mBits = b ^ ((t << i) | (t << j));
	}
	
	/**
		Calls `setf(x, bits)` if `expr` is true or `clrf(x, bits)` if `expr` is false.
	**/
	inline public static function setfif(x:BitField, bits:Int, expr:Bool)
	{
		expr ? setf(x, bits) : clrf(x, bits);
	}
}