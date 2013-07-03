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

/**
 * <p>Helper class for converting arrays to various collections.</p>
 */
class ArrayConvert
{
	/**
	 * Converts the array <code>x</code> to a two-dimensional array with dimensions <code>width</code> and <code>height</code>.
	 * @throws de.polygonal.ds.error.AssertError <code>x</code> is null (debug only).
	 * @throws de.polygonal.ds.error.AssertError <code>x</code>.length &lt; <code>width</code> * <code>height</code> (debug only).
	 */
	#if !generic
	public static function toArray2<T>(x:Array<T>, width:Int, height:Int):Array2<T>
	{
		#if debug
		assert(x != null, "x != null");
		assert(x.length >= width * height, "x.length >= width * height");
		#end
		
		var c = new Array2<T>(width, height);
		var a = c.getArray();
		for (i in 0...x.length) a[i] = x[i];
		return c;
	}
	#end
	
	/**
	 * Converts the array <code>x</code> to a three-dimensional array with dimensions <code>width</code>, <code>height</code> and <code>depth</code>.
	 * @throws de.polygonal.ds.error.AssertError <code>x</code> is null (debug only).
	 * @throws de.polygonal.ds.error.AssertError <code>x</code>.length &lt; <code>width</code> * <code>height</code> * <code>depth</code> (debug only).
	 */
	#if !generic
	public static function toArray3<T>(x:Array<T>, width:Int, height:Int, depth:Int):Array3<T>
	{
		#if debug
		assert(x != null, "x != null");
		assert(x.length >= width * height * depth, "x.length >= width * height * depth");
		#end
		
		var c = new Array3<T>(width, height, depth);
		var a = c.getArray();
		for (i in 0...x.length) a[i] = x[i];
		return c;
	}
	#end
	
	/**
	 * Converts the array <code>x</code> to an arrayed queue.<br/>
	 * The size of the queue is the nearest power of 2 of a.length.
	 * @throws de.polygonal.ds.error.AssertError <code>x</code> is null (debug only).
	 * @throws de.polygonal.ds.error.AssertError <code>x</code> is empty (debug only).
	 */
	public static function toArrayedQueue<T>(x:Array<T>):ArrayedQueue<T>
	{
		#if debug
		assert(x != null, "x != null");
		assert(x.length > 0, "x.length > 0");
		#end
		
		var k = x.length;
		var c = new ArrayedQueue<T>(M.nextPow2(k));
		for (i in 0...k) c.enqueue(x[i]);
		return c;
	}
	
	/**
	 * Converts the array <code>x</code> to an arrayed stack.<br/>
	 * The size of the stack equals <code>x</code>.length.
	 * @throws de.polygonal.ds.error.AssertError <code>x</code> is null (debug only).
	 * @throws de.polygonal.ds.error.AssertError <code>x</code> is empty (debug only).
	 */
	public static function toArrayedStack<T>(x:Array<T>):ArrayedStack<T>
	{
		#if debug
		assert(x != null, "x != null");
		assert(x.length > 0, "x.length > 0");
		#end
		
		var c = new ArrayedStack<T>(x.length);
		for (i in 0...x.length) c.push(x[i]);
		return c;
	}
	
	/**
	 * Converts the array <code>x</code> to a singly linked list.<br/>
	 * The size of the linked list equals <code>x</code>.length.
	 * @throws de.polygonal.ds.error.AssertError <code>x</code> is null (debug only).
	 * @throws de.polygonal.ds.error.AssertError <code>x</code> is empty (debug only).
	 */
	public static function toSLL<T>(x:Array<T>):SLL<T>
	{
		#if debug
		assert(x != null, "x != null");
		assert(x.length > 0, "x.length > 0");
		#end
		
		var c = new SLL<T>();
		for (i in 0...x.length) c.append(x[i]);
		return c;
	}
	
	/**
	 * Converts the array <code>x</code> to a doubly linked list.<br/>
	 * The size of the linked list equals <code>x</code>.length.
	 * @throws de.polygonal.ds.error.AssertError <code>x</code> is null (debug only).
	 * @throws de.polygonal.ds.error.AssertError <code>x</code> is empty (debug only).
	 */
	public static function toDLL<T>(x:Array<T>):DLL<T>
	{
		#if debug
		assert(x != null, "x != null");
		assert(x.length > 0, "x.length > 0");
		#end
		
		var c = new DLL<T>();
		for (i in 0...x.length) c.append(x[i]);
		return c;
	}
	
	/**
	 * Converts the array <code>x</code> to a linked queue.<br/>
	 * The size of the queue equals <code>x</code>.length.
	 * @throws de.polygonal.ds.error.AssertError <code>x</code> is null (debug only).
	 * @throws de.polygonal.ds.error.AssertError <code>x</code> is empty (debug only).
	 */
	public static function toLinkedQueue<T>(x:Array<T>):LinkedQueue<T>
	{
		#if debug
		assert(x != null, "x != null");
		assert(x.length > 0, "x.length > 0");
		#end
		
		var c = new LinkedQueue<T>();
		for (i in 0...x.length) c.enqueue(x[i]);
		return c;
	}
	
	/**
	 * Converts the array <code>x</code> to a linked stack.<br/>
	 * The size of the stack equals <code>x</code>.length.
	 * @throws de.polygonal.ds.error.AssertError <code>x</code> is null (debug only).
	 * @throws de.polygonal.ds.error.AssertError <code>x</code> is empty (debug only).
	 */
	public static function toLinkedStack<T>(x:Array<T>):LinkedStack<T>
	{
		#if debug
		assert(x != null, "x != null");
		assert(x.length > 0, "x.length > 0");
		#end
		
		var c = new LinkedStack<T>();
		for (i in 0...x.length) c.push(x[i]);
		return c;
	}
	
	/**
	 * Converts the array <code>x</code> to a dense array.<br/>
	 * The size of the dense array equals <code>x</code>.length.
	 * @throws de.polygonal.ds.error.AssertError <code>x</code> is null (debug only).
	 * @throws de.polygonal.ds.error.AssertError <code>x</code> is empty (debug only).
	 */
	public static function toDA<T>(x:Array<T>):DA<T>
	{
		#if debug
		assert(x != null, "x != null");
		assert(x.length > 0, "x.length > 0");
		#end
		
		var c = new DA<T>(x.length);
		for (i in 0...x.length) c.pushBack(x[i]);
		return c;
	}
}