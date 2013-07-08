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

using de.polygonal.ds.Bits;

#if !doc
private
#end
/**
 * <p>Grants access to the private <code>_bits</code> field storing the bit field.</p>
 */
typedef BitField =
{
	/**
	 * The bit field. 
	 */
	private var _bits:Int;
}

/**
 * <p>Small helper class for working with bit flags.</p>
 */
class BitFlags
{
	/**
	 * Returns <code>x</code> AND <code>mask</code>. 
	 */
	inline public static function getf(x:BitField, mask:Int):Int
	{
		return x._bits.getBits(mask);
	}
	
	/**
	 * Returns <code>x</code> AND <code>mask</code> != 0 
	 */
	inline public static function hasf(x:BitField, mask:Int):Bool
	{
		return x._bits.hasBits(mask);
	}
	
	/**
	 * Returns <code>x</code> AND <code>mask</code> == <code>mask</code> (<code>x</code> includes all <code>mask</code> bits). 
	 */
	inline public static function incf(x:BitField, mask:Int):Bool
	{
		return x._bits.incBits(mask);
	}
	
	/**
	 * <code>x</code> = <code>x</code> | <code>mask</code>. 
	 */
	inline public static function setf(x:BitField, mask:Int)
	{
		x._bits = x._bits.setBits(mask);
	}
	
	/**
	 * <code>x</code> = <code>x</code> AND ~<code>mask</code>. 
	 */
	inline public static function clrf(x:BitField, mask:Int)
	{
		x._bits = x._bits.clrBits(mask);
	}
	
	/**
	 * <code>x</code> = <code>x</code> ^ <code>mask</code>. 
	 */
	inline public static function invf(x:BitField, mask:Int)
	{
		x._bits = x._bits.invBits(mask);
	}
	
	/**
	 * <code>x</code> = 0.
	 */
	inline public static function nulf(x:BitField)
	{
		x._bits = 0;
	}
	
	/**
	 * <code>x</code> = <code>other</code>.
	 */
	inline public static function cpyf(x:BitField, other:BitField)
	{
		x._bits = other._bits;
	}
	
	/**
	 * Swaps the bit at index <code>i</code> with the bit at index <code>j</code> (LSB 0).
	 * @param x the bits that are modified.
	 */
	inline public static function swpf(x:BitField, i:Int, j:Int)
	{
		var b = x._bits;
		var t = ((b >> i) ^ (b >> j)) & 0x01;
		x._bits = b ^ ((t << i) | (t << j));
	}
	
	/**
	 * Calls <code>setf(x, bits)</code> if <code>expr</code> is true or <code>clrf(x, bits)</code> if <code>expr</code> is false. 
	 */
	inline public static function setfif(x:BitField, bits:Int, expr:Bool)
	{
		expr ? setf(x, bits) : clrf(x, bits);
	}
}