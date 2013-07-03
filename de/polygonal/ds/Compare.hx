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

/**
 * <p>Various comparison functions.</p>
 */
class Compare
{
	/**
	 * Comparison function for sorting floats in descending order. 
	 */
	public static function compareNumberFall<T>(a:Float, b:Float):Int
	{
		return Std.int(b - a);
	}
	
	/**
	 * Comparison function for sorting floats in ascending order. 
	 */
	public static function compareNumberRise<T>(a:Float, b:Float):Int
	{
		return Std.int(a - b);
	}
	
	/**
	 * Comparison function for sorting strings in case insensitive descending order. 
	 */
	public static function compareStringCaseInSensitiveFall(a:String, b:String):Int
	{
		a = a.toLowerCase();
		b = b.toLowerCase();
		
		if (a.length + b.length > 2)
		{
			var r = 0;
			var k = a.length > b.length ? a.length : b.length;
			for (i in 0...k)
			{
				r = a.charCodeAt(i) - b.charCodeAt(i);
				if (r != 0)	break;
			}
			return r;
		}
		else
			return a.charCodeAt(0) - b.charCodeAt(0);
	}
	
	/**
	 * Comparison function for sorting strings in case insensitive ascending order. 
	 */
	public static function compareStringCaseInSensitiveRise(a:String, b:String):Int
	{
		return compareStringCaseInSensitiveFall(b, a);
	}
	
	/**
	 * Comparison function for sorting strings in case sensitive descending order. 
	 */
	public static function compareStringCaseSensitiveFall(a:String, b:String):Int
	{
		if (a.length + b.length > 2)
		{
			var r = 0;
			var k = a.length > b.length ? a.length : b.length;
			for (i in 0...k)
			{
				r = a.charCodeAt(i) - b.charCodeAt(i);
				if (r != 0)	break;
			}
			return r;
		}
		else
			return a.charCodeAt(0) - b.charCodeAt(0);
	}
	
	/**
	 * Comparison function for sorting strings in case sensitive ascending order. 
	 */
	public static function compareStringCaseSensitiveRise(a:String, b:String):Int
	{
		return compareStringCaseSensitiveFall(b, a);
	}
	
	/**
	 * Comparison function for sorting strings in lexiographic order. 
	 */
	public static function lexiographic(a:String, b:String):Int
	{
		var ak = a.length;
		var bk = b.length;
		var d = 0;
		
		for (i in 0...M.min(ak, bk))
		{
			var ca = StringTools.fastCodeAt(a, i);
			var cb = StringTools.fastCodeAt(b, i);
			
			if (StringTools.isEof(ca) || StringTools.isEof(cb)) break;
			
			d = ca - cb;
			if (d != 0) return d;
		}
		
		return ak - bk;
	}
}