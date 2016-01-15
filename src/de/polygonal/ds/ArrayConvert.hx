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

/**
	Helper class for converting arrays to various collections
**/
class ArrayConvert
{
	/**
		Converts the array `x` to a two-dimensional array with dimensions `width` and `height`.
		<assert>`x` is null</assert>
		<assert>`x`::length < `width` * `height`</assert>
	**/
	public static function toArray2<T>(x:Array<T>, width:Int, height:Int):Array2<T>
	{
		assert(x != null);
		assert(x.length >= width * height);
		
		var c = new Array2<T>(width, height);
		var a = c.getVector();
		for (i in 0...x.length) a[i] = x[i];
		return c;
	}
	
	/**
		Converts the array `x` to a three-dimensional array with dimensions `width`, `height` and `depth`.
		<assert>`x` is null</assert>
		<assert>`x`::length < `width` * `height` * `depth`</assert>
	**/
	public static function toArray3<T>(x:Array<T>, width:Int, height:Int, depth:Int):Array3<T>
	{
		assert(x != null);
		assert(x.length >= width * height * depth);
		
		var c = new Array3<T>(width, height, depth);
		var a = c.getVector();
		for (i in 0...x.length) a[i] = x[i];
		return c;
	}
	
	/**
		Converts the array `x` to an arrayed queue.
		
		The size of the queue equals `x`::length.
		<assert>`x` is null</assert>
		<assert>`x` is empty</assert>
	**/
	public static function toArrayedQueue<T>(x:Array<T>):ArrayedQueue<T>
	{
		assert(x != null);
		assert(x.length > 0);
		
		var k = x.length;
		var c = new ArrayedQueue<T>(M.nextPow2(k));
		for (i in 0...k) c.enqueue(x[i]);
		return c;
	}
	
	/**
		Converts the array `x` to an arrayed stack.
		
		The size of the stack equals `x`::length.
		<assert>`x` is null</assert>
		<assert>`x` is empty</assert>
	**/
	public static function toArrayedStack<T>(x:Array<T>):ArrayedStack<T>
	{
		assert(x != null);
		assert(x.length > 0);
		
		var c = new ArrayedStack<T>(x.length);
		for (i in 0...x.length) c.push(x[i]);
		return c;
	}
	
	/**
		Converts the array `x` to a singly linked list.
		
		The size of the linked list equals `x`::length.
		<assert>`x` is null</assert>
		<assert>`x` is empty</assert>
	**/
	public static function toSll<T>(x:Array<T>):Sll<T>
	{
		assert(x != null);
		assert(x.length > 0);
		
		var c = new Sll<T>();
		for (i in 0...x.length) c.append(x[i]);
		return c;
	}
	
	/**
		Converts the array `x` to a doubly linked list.
		
		The size of the linked list equals `x`::length.
		<assert>`x` is null</assert>
		<assert>`x` is empty</assert>
	**/
	public static function toDll<T>(x:Array<T>):Dll<T>
	{
		assert(x != null);
		assert(x.length > 0);
		
		var c = new Dll<T>();
		for (i in 0...x.length) c.append(x[i]);
		return c;
	}
	
	/**
		Converts the array `x` to a linked queue.
		
		The size of the queue equals `x`::length.
		<assert>`x` is null</assert>
		<assert>`x` is empty</assert>
	**/
	public static function toLinkedQueue<T>(x:Array<T>):LinkedQueue<T>
	{
		assert(x != null);
		assert(x.length > 0);
		
		var c = new LinkedQueue<T>();
		for (i in 0...x.length) c.enqueue(x[i]);
		return c;
	}
	
	/**
		Converts the array `x` to a linked stack.
		
		The size of the stack equals `x`::length.
		<assert>`x` is null</assert>
		<assert>`x` is empty</assert>
	**/
	public static function toLinkedStack<T>(x:Array<T>):LinkedStack<T>
	{
		assert(x != null);
		assert(x.length > 0);
		
		var c = new LinkedStack<T>();
		for (i in 0...x.length) c.push(x[i]);
		return c;
	}
	
	/**
		Converts the array `x` to a dense array.
		
		The size of the dense array equals `x`::length.
		<assert>`x` is null</assert>
		<assert>`x` is empty</assert>
	**/
	public static function toDa<T>(x:Array<T>):Da<T>
	{
		assert(x != null);
		assert(x.length > 0);
		
		var c = new Da<T>();
		for (i in 0...x.length) c.pushBack(x[i]);
		return c;
	}
}