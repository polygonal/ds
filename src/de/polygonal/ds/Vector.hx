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

#if flash
@:dox(hide)
abstract MockVector<T>(Array<T>)
{
	public inline function new(length:Int, ?fixed:Bool) untyped
	{
		this = new Array<T>();
		this.length = length;
		
		#if debug
		this["fixed"] = fixed;
		#end
	}
	
	@:arrayAccess public inline function get(index:Int):Null<T> return this[index];
	@:arrayAccess public inline function set(index:Int, val:T):T
	{
		#if debug
		if (index >= this.length) throw 'RangeError: The index $index is out of range ${this.length}';
		#end
		
		return this[index] = val;
	}
	
	public var length(get, never):Int;
	inline function get_length():Int return untyped this.length;

	public static function blit<T>(src:MockVector<T>, srcPos:Int, dest:MockVector<T>, destPos:Int, len:Int) for (i in 0...len) dest[destPos + i] = src[srcPos + i];

	public inline function toArray():Array<T>
	{
		var a = new Array<T>();
		for (i in 0...length) a[i] = get(i);
		return a;
	}

	public inline function toData():Array<T> return cast this;

	static public inline function fromData<T>(data:Array<T>):MockVector<T> return cast data;

	@:extern static public inline function fromArrayCopy<T>(array:Array<T>):MockVector<T>
	{
		var vec = new MockVector<T>(array.length);
		for (i in 0...array.length) vec.set(i, array[i]);
		return vec;
	}
}
#end

/**
	Unifies haxe.ds.Vector<T> and flash.Vector<T>
**/
typedef Vector<T> =
#if flash
	#if generic
	flash.Vector<T>
	#else
	MockVector<T>
	#end
#else
haxe.ds.Vector<T>
#end
;