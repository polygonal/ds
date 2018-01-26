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

/**
	Various comparison functions
**/
class Compare
{
	/**
		Comparison function for sorting floats in descending order.
	**/
	public static function cmpIntFall<T>(a:Int, b:Int):Int return b - a;
	
	/**
		Comparison function for sorting floats in ascending order.
	**/
	public static function cmpIntRise<T>(a:Int, b:Int):Int return a - b;
	
	/**
		Comparison function for sorting floats in descending order.
	**/
	public static function cmpFloatFall<T>(a:Float, b:Float):Int return Std.int(b - a);
	
	/**
		Comparison function for sorting floats in ascending order.
	**/
	public static function cmpFloatRise<T>(a:Float, b:Float):Int return Std.int(a - b);
	
	/**
		Comparison function for sorting strings in alphabetical order (descending, case insensitive).
	**/
	public static function cmpAlphabeticalFall(a:String, b:String):Int
	{
		a = a.toLowerCase();
		b = b.toLowerCase();
		return a < b ? 1 : (a > b ? -1 : 0);
	}
	
	/**
		Comparison function for sorting strings in alphabetical order (ascending, case insensitive).
	**/
	public static function cmpAlphabeticalRise(a:String, b:String):Int
	{
		a = a.toLowerCase();
		b = b.toLowerCase();
		return a < b ? -1 : (a > b ? 1 : 0);
	}
}