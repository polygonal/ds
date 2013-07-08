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

private typedef Array2Friend<T> =
{
	private var _a:Array<T>;
	private var _w:Int;
	private var _h:Int;
}

/**
 * <p>A two-dimensional array based on a rectangular sequential array.</p>
 * <p><o>Worst-case running time in Big O notation</o></p>
 */

#if (generic && cpp)
@:generic
#end
class Array2<T> implements Collection<T>
{
	/**
	 * A unique identifier for this object.<br/>
	 * A hash table transforms this key into an index of an array element by using a hash function.<br/>
	 * <warn>This value should never be changed by the user.</warn>
	 */
	public var key:Int;
	
	/**
	 * If true, reuses the iterator object instead of allocating a new one when calling <code>iterator()</code>.<br/>
	 * The default is false.<br/>
	 * <warn>If true, nested iterations are likely to fail as only one iteration is allowed at a time.</warn>
	 */
	public var reuseIterator:Bool;
	
	var _a:Array<T>;
	var _w:Int;
	var _h:Int;
	var _iterator:Array2Iterator<T>;
	
	/**
	 * Creates a two-dimensional array with dimensions <code>width</code> and <code>height</code>.<br/>
	 * The minimum size is 2x2.
	 * @throws de.polygonal.ds.error.AssertError invalid <code>width</code> or <code>height</code> (debug only).
	 */
	public function new(width:Int, height:Int)
	{
		#if debug
		assert(width >= 2 && height >= 2, 'invalid size (width:$width, height:$height)');
		#end
		
		_w            = width;
		_h            = height;
		_a            = ArrayUtil.alloc(size());
		_iterator     = null;
		key           = HashKey.next();
		reuseIterator = false;
	}
	
	/**
	 * Returns the element that is stored in column <code>x</code> and row <code>y</code>.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError <code>x</code>/<code>y</code> out of range (debug only).
	 */
	inline public function get(x:Int, y:Int):T
	{
		#if debug
		assert(x >= 0 && x < getW(), 'x index out of range ($x)');
		assert(y >= 0 && y < getH(), 'y index out of range ($y)');
		#end
		
		return __get(getIndex(x, y));
	}
	
	/**
	 * Returns the element that is stored in column <code>cell</code>.x and row <code>cell</code>.y.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError <code>cell</code> is null (debug only).
	 * @throws de.polygonal.ds.error.AssertError <code>x</code>/<code>y</code> out of range (debug only).
	 */
	inline public function getAt(cell:Array2Cell):T
	{
		#if debug
		assert(cell != null, "cell is null");
		#end
		
		return __get(getIndex(cell.x, cell.y));
	}
	
	/**
	 * Replaces the element at column <code>x</code> and row <code>y</code> with <code>val</code>.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError <code>x</code>/<code>y</code> out of range (debug only).
	 */
	inline public function set(x:Int, y:Int, val:T)
	{
		#if debug
		assert(x >= 0 && x < getW(), 'x index out of range ($x)');
		assert(y >= 0 && y < getH(), 'y index out of range ($y)');
		#end
		
		__set(getIndex(x, y), val);
	}
	
	/**
	 * Returns the element at index <code>i</code>.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError index out of range (debug only).
	 */
	inline public function getAtIndex(i:Int):T
	{
		#if debug
		assert(i >= 0 && i < size(), 'index out of range ($i)');
		#end
		
		return __get(getIndex(i % _w, Std.int(i / _w)));
	}
	
	/**
	 * Replaces the element at index <code>i</code> with the <code>x</code>.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError index out of range (debug only).
	 */
	inline public function setAtIndex(i:Int, val:T)
	{
		#if debug
		assert(i >= 0 && i < size(), 'index out of range ($i)');
		#end
		
		__set(getIndex(i % _w, Std.int(i / _w)), val);
	}
	
	/**
	 * The width (#columns).
	 * <o>1</o>
	 */
	inline public function getW():Int
	{
		return _w;
	}
	
	/**
	 * Sets the width to <code>x</code>.<br/>
	 * The minimum value is 2.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError invalid width (debug only).
	 */
	inline public function setW(x:Int)
	{
		resize(x, _h);
	}
	
	/**
	 * The height (#rows).
	 * <o>1</o>
	 */
	inline public function getH():Int
	{
		return _h;
	}
	
	/**
	 * Sets the height to <code>x</code>.<br/>
	 * The minimum value is 2.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError invalid height (debug only).
	 */
	inline public function setH(x:Int)
	{
		resize(_w, x);
	}
	
	/**
	 * Computes an index into the linear array from the <code>x<code> and <code>y</code> index.
	 * <o>1</o>
	 */
	inline public function getIndex(x:Int, y:Int):Int
	{
		return y * _w + x;
	}
	
	/**
	 * Returns the index of the first occurrence of the element <code>x</code> or returns -1 if element <code>x</code> does not exist.<br/>
	 * The index is in the range &#091;0, size() - 1&#093;.
	 * <o>n</o>
	 */
	inline public function indexOf(x:T):Int
	{
		var i = 0;
		var j = _w * _h;
		while (i < j)
		{
			if (__get(i) == x) break;
			i++;
		}
		
		return (i == j) ? -1 : i;
	}
	
	/**
	 * Returns true if <code>x</code> and <code>y</code> are valid.
	 */
	inline public function inRange(x:Int, y:Int):Bool
	{
		return x >= 0 && x < _w && y >= 0 && y < _h;
	}
	
	/**
	 * Returns the cell coordinates of the first occurrence of the element <code>x</code> or null if element <code>x</code> does not exist.
	 * <o>n</o>
	 * @param cell stores the result.
	 * @return a reference to <code>cell</code>.
	 * @throws de.polygonal.ds.error.AssertError <code>cell</code> is null (debug only).
	 */
	inline public function cellOf(x:T, cell:Array2Cell):Array2Cell
	{
		#if debug
		assert(cell != null, "cell != null");
		#end
		
		var i = indexOf(x);
		if (i == -1)
			return null;
		else
			return indexToCell(i, cell);
	}
	
	/**
	 * Transforms the index <code>i</code> into <code>cell</code> coordinates.
	 * <o>1</o>
	 * @param cell stores the result.
	 * @return a reference to <code>cell</code>.
	 * @throws de.polygonal.ds.error.AssertError index out of range (debug only).
	 * @throws de.polygonal.ds.error.AssertError <code>cell</code> is null (debug only).
	 */
	inline public function indexToCell(i:Int, cell:Array2Cell):Array2Cell
	{
		#if debug
		assert(i >= 0 && i < size(), 'index out of range ($i)');
		assert(cell != null, "cell is null");
		#end
		
		cell.y = Std.int(i / _w);
		cell.x = i % _w;
		return cell;
	}
	
	/**
	 * Computes an array index into the linear array from the <code>cell</code> coordinates.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError <code>cell</code> index out of range (debug only).
	 * @throws de.polygonal.ds.error.AssertError <code>cell</code> is null (debug only).
	 */
	inline public function cellToIndex(cell:Array2Cell):Int
	{
		#if debug
		assert(cell != null, "cell != null");
		assert(cell.x >= 0 && cell.x < getW(), 'x index out of range (${cell.x})');
		assert(cell.y >= 0 && cell.y < getH(), 'y index out of range (${cell.y})');
		#end
		
		return getIndex(cell.x, cell.y);
	}
	
	/**
	 * Copies all elements stored in row <code>y</code> by reference into the <code>output</code> array.
	 * <o>n</o>
	 * @return a reference to the <code>output</code> array.
	 * @throws de.polygonal.ds.error.AssertError <code>y</code> out of range (debug only).
	 * @throws de.polygonal.ds.error.AssertError <code>output</code> is null (debug only).
	 */
	inline public function getRow(y:Int, output:Array<T>):Array<T>
	{
		#if debug
		assert(y >= 0 && y < getH(), 'y index out of range ($y)');
		assert(output != null, "output is null");
		#end
		
		var offset = y * _w;
		for (x in 0..._w)
			output[x] = __get(offset + x);
		return output;
	}
	
	/**
	 * Overwrites all elements in row <code>y</code> with the elements stored in the <code>input</code> array.
	 * <o>n</o>
	 * @throws de.polygonal.ds.error.AssertError <code>y</code> out of range or <code>input</code> is null or insufficient input values (debug only).
	 */
	public function setRow(y:Int, input:Array<T>)
	{
		#if debug
		assert(y >= 0 && y < getH(), 'y index out of range ($y)');
		assert(input != null, "input is null");
		assert(input.length >= getW(), "insufficient input values");
		#end
		
		var offset = y * _w;
		for (x in 0..._w)
			__set(offset + x, input[x]);
	}
	
	/**
	 * Copies all elements stored in column <code>x</code> by reference into the <code>output</code> array.
	 * <o>n</o>
	 * @return a reference to the <code>output</code> array.
	 * @throws de.polygonal.ds.error.AssertError <code>x</code> out of range (debug only).
	 * @throws de.polygonal.ds.error.AssertError <code>output</code> is null (debug only).
	 */
	public function getCol(x:Int, output:Array<T>):Array<T>
	{
		#if debug
		assert(x >= 0 && x < getW(), 'x index out of range ($x)');
		assert(output != null, "output is null");
		#end
		
		for (i in 0..._h)
			output[i] = __get(i * _w + x);
		return output;
	}
	
	/**
	 * Overwrites all elements in column <code>x</code> with the elements stored in the <code>input</code> array.
	 * <o>n</o>
	 * @throws de.polygonal.ds.error.AssertError <code>x</code> out of range (debug only).
	 * @throws de.polygonal.ds.error.AssertError <code>input</code> is null or insufficient input values (debug only).
	 */
	public function setCol(x:Int, input:Array<T>)
	{
		#if debug
		assert(x >= 0 && x < getW(), 'x index out of range ($x)');
		assert(input != null, "input is null");
		assert(input.length >= getH(), "insufficient input values");
		#end
		
		for (y in 0..._h)
			__set(getIndex(x, y), input[y]);
	}
	
	/**
	 * Replaces all existing elements with objects of type <code>C</code>.
	 * <o>n</o>
	 * @param C the class to instantiate for each element.
	 * @param args passes additional constructor arguments to the class <code>C</code>.
	 */
	public function assign(C:Class<T>, args:Array<Dynamic> = null)
	{
		if (args == null) args = [];
		for (i in 0...size()) __set(i, Type.createInstance(C, args));
	}
	
	/**
	 * Replaces all existing elements with the instance of <code>x</code>.
	 * <o>n</o>
	 */
	public function fill(x:T):Array2<T>
	{
		for (i in 0...size()) __set(i, x);
		return this;
	}
	
	/**
	 * Invokes the <code>process</code> function for each element.<br/>
	 * The function signature is: <em>process(oldValue, xIndex, yIndex):newValue</em>
	 * <o>n</o>
	 */
	public function walk(process:T->Int->Int->T)
	{
		for (y in 0..._h)
		{
			for (x in 0..._w)
			{
				var i = getIndex(x, y);
				__set(i, process(__get(i), x, y));
			}
		}
	}
	
	/**
	 * Resizes this two-dimensional array.
	 * <o>n</o>
	 * @param width the new width (minimum is 2).
	 * @param height the new height (minimum is 2).
	 * @throws de.polygonal.ds.error.AssertError invalid dimensions (debug only).
	 */
	public function resize(width:Int, height:Int)
	{
		#if debug
		assert(width >= 2 && height >= 2, 'invalid size (width:$width, height:$height)');
		#end
		
		if (width == _w && height == _h) return;
		var t = _a;
		_a = ArrayUtil.alloc(width * height);
		
		var minX = width  < _w ? width  : _w;
		var minY = height < _h ? height : _h;
		
		for (y in 0...minY)
		{
			var t1 = y *  width;
			var t2 = y * _w;
			for (x in 0...minX)
				__set(t1 + x, t[t2 + x]);
		}
		
		_w = width;
		_h = height;
	}
	
	/**
	 * Shifts all columns to the west by one position.<br/>
	 * Columns are wrapped so the column at index 0 is not lost but appended to the rightmost column.
	 * <o>n</o>
	 */
	public function shiftW()
	{
		var t, k;
		for (y in 0..._h)
		{
			k = y * _w;
			t = __get(k);
			for (x in 1..._w)
				__set(k + x - 1, __get(k + x));
			__set(k + _w - 1, t);
		}
	}
	
	/**
	 * Shifts all columns to the east by one position.<br/>
	 * Columns are wrapped, so the column at index &#091;<em>getW()</em> - 1&#093; is not lost but prepended to the leftmost column.
	 * <o>n</o>
	 */
	public function shiftE()
	{
		var t, x, k;
		for (y in 0..._h)
		{
			k = y * _w;
			t = __get(k + _w - 1);
			x = _w - 1;
			while (x-- > 0)
				__set(k + x + 1, __get(k + x));
			__set(k, t);
		}
	}
	
	/**
	 * Shifts all rows to the north by one position.<br/>
	 * Rows are wrapped, so the row at index 0 is not lost but appended to the bottommost row.
	 * <o>n</o>
	 */
	public function shiftN()
	{
		var t;
		var k = _h - 1;
		var l = (_h - 1) * _w;
		for (x in 0..._w)
		{
			t = __get(x);
			for (y in 0...k)
				__set(getIndex(x, y), __get((y + 1) * _w + x));
			__set(l + x, t);
		}
	}
	
	/**
	 * Shifts all rows to the south by one position.<br/>
	 * Rows are wrapped, so row at index &#091;<em>getH()</em> - 1&#093; is not lost but prepended to the topmost row.
	 * <o>n</o>
	 */
	public function shiftS()
	{
		var t, k, y;
		var k = _h - 1;
		var l = k * _w;
		for (x in 0..._w)
		{
			t = __get(l + x);
			y = k;
			while(y-- > 0) __set((y + 1) * _w + x, __get(getIndex(x, y)));
			__set(x, t);
		}
	}
	
	/**
	 * Swaps the element at column/row <code>x0</code>, <code>y0</code> with the element at column/row <code>x1</code>, <code>y1</code>.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError <code>x0</code>/<code>y0</code> or <code>x1</code>/<code>y1</code> out of range (debug only).
	 * @throws de.polygonal.ds.error.AssertError <code>x0</code>, <code>y0</code> equals <code>x1</code>, <code>y1</code> (debug only).
	 */
	inline public function swap(x0:Int, y0:Int, x1:Int, y1:Int)
	{
		#if debug
		assert(x0 >= 0 && x0 < getW(), 'x0 index out of range ($x0)');
		assert(y0 >= 0 && y0 < getH(), 'y0 index out of range ($y0)');
		assert(x1 >= 0 && x1 < getW(), 'x1 index out of range ($x1)');
		assert(y1 >= 0 && y1 < getH(), 'y1 index out of range ($y1)');
		assert(!(x0 == x1 && y0 == y1), 'source indices equal target indices (x: $x0, y: $y0)');
		#end
		
		var i = y0 * _w + x0;
		var j = y1 * _w + x1;
		var t = __get(i);
		__set(i, __get(j));
		__set(j, t);
	}
	
	/**
	 * Appends the elements of the <code>input</code> array in the range &#091;0, <em>getW()</em>&#093; by adding a new row.
	 * <o>n</o>
	 * @throws de.polygonal.ds.error.AssertError <code>input</code> is null or too short (debug only).
	 */
	public function appendRow(input:Array<T>)
	{
		#if debug
		assert(input != null, "input is null");
		assert(input.length >= getW(), "insufficient input values");
		#end
		
		var t = _w * _h++;
		for (i in 0..._w) __set(t + i, input[i]);
	}
	
	/**
	 * Appends the elements of the <code>input</code> array in the range &#091;0, <em>getH()</em>&#093; by adding a new column.
	 * <o>n</o>
	 * @throws de.polygonal.ds.error.AssertError <code>input</code> is null or too short (debug only).
	 */
	public function appendCol(input:Array<T>)
	{
		#if debug
		assert(input != null, "input is null");
		assert(input.length >= getH(), "insufficient input values");
		#end
		
		var t = size();
		var l = t + _h;
		var i = _h - 1;
		var j = _h;
		var x = _w;
		var y = l;
		while (y-- > 0)
		{
			if (++x > _w)
			{
				x = 0;
				j--;
				__set(y, input[i--]);
			}
			else
				__set(y, __get(y - j));
		}
		_w++;
	}
	
	/**
	 * Prepends the elements of the <code>input</code> array in the range &#091;0, <em>getW()</em>&#093; by adding a new row.
	 * <o>n</o>
	 * @throws de.polygonal.ds.error.AssertError <code>input</code> is null or too short (debug only).
	 */
	public function prependRow(input:Array<T>)
	{
		#if debug
		assert(input != null, "input is null");
		assert(input.length >= getW(), "insufficient input values");
		#end
		
		_h++;
		
		var y = size();
		while (y-- > _w)
			__set(y, __get(y - _w));
		
		y++;
		
		while (y-- > 0)
			__set(y, input[y]);
	}
	
	/**
	 * Prepends the elements of the <code>input</code> array in the range &#091;0, <em>getH()</em>&#093; by adding a new column.
	 * <o>n</o>
	 * @throws de.polygonal.ds.error.AssertError <code>input</code> is null or too short (debug only).
	 */
	public function prependCol(input:Array<T>)
	{
		#if debug
		assert(input != null, "input is null");
		assert(input.length >= getH(), "insufficient input values");
		#end
		
		var t = size();
		var l = t + _h;
		var i = _h - 1;
		var j = _h;
		var x = 0;
		var y = l;
		while (y-- > 0)
		{
			if (++x > _w)
			{
				x = 0;
				j--;
				__set(y, input[i--]);
			}
			else
				__set(y, __get(y - j));
		}
		_w++;
	}
	
	/**
	 * Copies row elements from row <code>i</code> to row <code>j</code>.
	 * <o>n</o>
	 * @throws de.polygonal.ds.error.AssertError <code>i</code>/<code>j</code> out of range (debug only).
	 */
	public function copyRow(i:Int, j:Int)
	{
		#if debug
		assert(i >= 0 && i < getH(), 'i index out of range ($i)');
		assert(j >= 0 && j < getH(), 'j index out of range ($j)');
		#end
		
		if (i != j)
		{
			var srcOffset = _w * i;
			var dstOffset = _w * j;
			for (x in 0..._w) __set(dstOffset + x, __get(srcOffset + x));
		}
	}
	
	/**
	 * Swaps row elements at row <code>i</code> with row elements at row <code>j</code>.
	 * <o>n</o>
	 * @throws de.polygonal.ds.error.AssertError <code>i</code>/<code>j</code> out of range (debug only).
	 */
	public function swapRow(i:Int, j:Int)
	{
		#if debug
		assert(i >= 0 && i < getH(), 'i index out of range ($i)');
		assert(j >= 0 && j < getH(), 'j index out of range ($j)');
		#end
		
		if (i != j)
		{
			var srcOffset = _w * i;
			var dstOffset = _w * j;
			
			for (x in 0..._w)
			{
				var tmp = __get(srcOffset + x);
				var k = dstOffset + x;
				__set(srcOffset + x, __get(k));
				__set(k, tmp);
			}
		}
	}
	
	/**
	 * Copies column elements from column <code>i</code> to column <code>j</code>.
	 * <o>n</o>
	 * @throws de.polygonal.ds.error.AssertError <code>i</code>/<code>j</code> out of range (debug only).
	 */
	public function copyCol(i:Int, j:Int)
	{
		#if debug
		assert(i >= 0 && i < getW(), 'i index out of range ($i)');
		assert(j >= 0 && j < getW(), 'j index out of range ($j)');
		#end
		
		if (i != j)
		{
			for (y in 0..._h)
			{
				var t = y * _w;
				__set(t + j, __get(t + i));
			}
		}
	}
	
	/**
	 * Swaps column elements at column <code>i</code> with column elements at row <code>j</code>.
	 * <o>n</o>
	 * @throws de.polygonal.ds.error.AssertError <code>i</code>/<code>j</code> out of range (debug only).
	 */
	public function swapCol(i:Int, j:Int)
	{
		#if debug
		assert(i >= 0 && i < getW(), 'i index out of range ($i)');
		assert(j >= 0 && j < getW(), 'j index out of range ($j)');
		#end
		
		if (i != j)
		{
			for (y in 0..._h)
			{
				var t = y * _w;
				var k = t + i;
				var l = t + j;
				var tmp = __get(k);
				__set(k, __get(l));
				__set(l, tmp);
			}
		}
	}
	
	/**
	 * Transposes this two-dimensional array.
	 * <o>n</o>
	 */
	public function transpose()
	{
		if (_w == _h)
		{
			for (y in 0..._h)
				for (x in y + 1..._w)
					swap(x, y, y, x);
		}
		else
		{
			var t = new Array<T>();
			for (y in 0..._h)
				for (x in 0..._w)
					t[x * _h + y] = get(x, y);
			_a = t;
			_w ^= _h;
			_h ^= _w;
			_w ^= _h;
		}
	}
	
	/**
	 * Grants access to the rectangular sequential array storing the elements of this two-dimensional array.<br/>
	 * Useful for fast iteration or low-level operations.
	 * <o>1</o>
	 */
	inline public function getArray():Array<T>
	{
		return _a;
	}
	
	/**
	 * Copies all elements from the given nested two-dimensional array <code>a</code> into this two-dimensional array.
	 * @throws de.polygonal.ds.error.AssertError invalid dimensions of <code>a</code> (debug only).
	 */
	public function setNestedArray(a:Array<Array<T>>)
	{
		#if debug
		assert(a.length == getH() && a[0] != null && a[0].length == getW(), "invalid input");
		#end
		
		var w = a[0].length;
		for (y in 0...a.length)
		{
			var row = a[y];
			for (x in 0...w)
				__set(getIndex(x, y), row[x]);
		}
	}
	
	/**
	 * Shuffles the elements of this collection by using the Fisher-Yates algorithm.<
	 * <o>n</o>
	 * @param rval a list of random double values in the range between 0 (inclusive) to 1 (exclusive) defining the new positions of the elements.
	 * If omitted, random values are generated on-the-fly by calling <em>Math.random()</em>.
	 * @throws de.polygonal.ds.error.AssertError insufficient random values (debug only).
	 */
	public function shuffle(rval:DA<Float> = null)
	{
		var s = size();
		if (rval == null)
		{
			var m = Math;
			while (--s > 1)
			{
				var i = Std.int(m.random() * s);
				var t = __get(s);
				__set(s, __get(i));
				__set(i, t);
			}
		}
		else
		{
			#if debug
			assert(rval.size() >= size(), "insufficient random values");
			#end
			
			var j = 0;
			while (--s > 1)
			{
				var i = Std.int(rval.get(j++) * s);
				var t = __get(s);
				__set(s, __get(i));
				__set(i, t);
			}
		}
	}
	
	/**
	 * Returns a string representing the current object.<br/>
	 * Example:<br/>
	 * <pre class="prettyprint">
	 * var array2 = new de.polygonal.ds.Array2&lt;String&gt;(4, 4);
	 * array2.walk(function(val:String, x:Int, y:Int):String { return Std.string(x) + "." + Std.string(y); });
	 * trace(array2);</pre>
	 * <pre class="console">
	 * { Array2 4x4 }
	 * [
	 *   &#091;0.0&#093;&#091;1.0&#093;&#091;2.0&#093;&#091;3.0&#093;
	 *   &#091;0.1&#093;&#091;1.1&#093;&#091;2.1&#093;&#091;3.1&#093;
	 *   &#091;0.2&#093;&#091;1.2&#093;&#091;2.2&#093;&#091;3.2&#093;
	 *   &#091;0.3&#093;&#091;1.3&#093;&#091;2.3&#093;&#091;3.3&#093;
	 * ]</pre>
	 */
	public function toString():String
	{
		var l = 0;
		for (i in 0...size())
		{
			var s = Std.string(__get(i));
			l = Std.int(Math.max(s.length, l));
		}
		var s = '{ Array2 ${_w}x${_h} }';
		s += "\n[\n";
		var offset, value;
		for (y in 0..._h)
		{
			s += "  ";
			offset = y * _w;
			for (x in 0..._w)
				s += Printf.format("%" + l + "s%s", [Std.string(__get(offset + x)), x < _w - 1 ? ", " : ""]);
			s += "\n";
		}
		
		s += "]";
		return s;
	}
	
	/*///////////////////////////////////////////////////////
	// collection
	///////////////////////////////////////////////////////*/
	
	/**
	 * Destroys this object by explicitly nullifying all elements for GC'ing used resources.<br/>
	 * Improves GC efficiency/performance (optional).
	 * <o>n</o>
	 */
	public function free()
	{
		for (i in 0...size()) __set(i, cast null);
		_a = null;
		_iterator = null;
	}
	
	/**
	 * Returns true if this two-dimensional array contains the element <code>x</code>.
	 * <o>n</o>
	 */
	public function contains(x:T):Bool
	{
		for (i in 0...size())
		{
			if (__get(i) == x)
				return true;
		}
		return false;
	}
	
	/**
	 * Nullifies all occurrences of <code>x</code>.<br/>
	 * The size is not altered.
	 * <o>n</o>
	 * @return true if at least one occurrence of <code>x</code> was nullified.
	 */
	public function remove(x:T):Bool
	{
		var found = false;
		for (i in 0...size())
		{
			if (__get(i) == x)
			{
				__set(i, cast null);
				found = true;
			}
		}
		
		return found;
	}
	
	/**
	 * Clears this two-dimensional array by nullifying all elements.<br/>
	 * The <code>purge</code> parameter has no effect.
	 * <o>1 or n if <code>purge</code> is true</o>
	 */
	public function clear(purge = false)
	{
		for (i in 0...size()) __set(i, cast null);
	}
	
	/**
	 * Returns a new <em>Array2Iterator</em> object to iterate over all elements contained in this two-dimensional array.<br/>
	 * Order: Row-major order (row-by-row).
	 * @see <a href="http://haxe.org/ref/iterators" target="_blank">http://haxe.org/ref/iterators</a>
	 */
	public function iterator():Itr<T>
	{
		if (reuseIterator)
		{
			if (_iterator == null)
				_iterator = new Array2Iterator<T>(this);
			else
				_iterator.reset();
			return _iterator;
		}
		else
			return new Array2Iterator<T>(this);
	}
	
	/**
	 * The number of elements in this two-dimensional array.<br/>
	 * Always equals <em>getW()</em> * <em>getH()</em>.
	 * <o>1</o>
	 */
	inline public function size():Int
	{
		return _w * _h;
	}
	
	/**
	 * Unsupported operation - always returns false in release mode.
	 * <o>1</o>
	 */
	public function isEmpty():Bool
	{
		return false;
	}
	
	/**
	 * Returns an array containing all elements in this two-dimensional array.<br/>
	 * Order: Row-major order (row-by-row).
	 */
	public function toArray():Array<T>
	{
		var a:Array<T> = ArrayUtil.alloc(size());
		for (i in 0...size())
			a[i] = __get(i);
		return a;
	}
	
	#if flash10
	/**
	 * Returns a Vector.&lt;T&gt; object containing all elements in this two-dimensional array.<br/>
	 * Order: Row-major order (row-by-row).
	 */
	public function toVector():flash.Vector<Dynamic>
	{
		var a = new flash.Vector<Dynamic>(size(), false);
		for (i in 0...size()) a[i] = __get(i);
		return a;
	}
	#end
	
	/**
	 * Duplicates this two-dimensional array. Supports shallow (structure only) and deep copies (structure & elements).
	 * @param assign if true, the <code>copier</code> parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.<br/>
	 * If false, the <em>clone()</em> method is called on each element. <warn>In this case all elements have to implement <em>Cloneable</em>.</warn>
	 * @param copier a custom function for copying elements. Replaces element.<em>clone()</em> if <code>assign</code> is false.
	 * @throws de.polygonal.ds.error.AssertError element is not of type <em>Cloneable</em> (debug only).
	 */
	public function clone(assign = true, copier:T->T = null):Collection<T>
	{
		var copy = new Array2<T>(_w, _h);
		if (assign)
		{
			for (i in 0...size())
				copy.__set(i, untyped __get(i));
		}
		else
		if (copier == null)
		{
			var c:Cloneable<Dynamic> = null;
			for (i in 0...size())
			{
				#if debug
				assert(Std.is(__get(i), Cloneable), 'element is not of type Cloneable (${__get(i)})');
				#end
				
				c = cast(__get(i), Cloneable<Dynamic>);
				copy.__set(i, c.clone());
			}
		}
		else
		{
			for (i in 0...size())
				copy.__set(i, copier(__get(i)));
		}
		return copy;
	}
	
	inline function __get(i:Int)
	{
		return _a[i];
	}
	inline function __set(i:Int, x:T)
	{
		_a[i] = x;
	}
}

#if (generic && cpp)
@:generic
#end
#if doc
private
#end
class Array2Iterator<T> implements de.polygonal.ds.Itr<T>
{
	var _f:Array2<T>;
	var _a:Array<T>;
	var _i:Int;
	var _s:Int;
	
	public function new(f:Array2<T>)
	{
		_f = f;
		reset();
	}
	
	inline public function reset():Itr<T>
	{
		_a = __a(_f);
		_s = __size(_f);
		_i = 0;
		return this;
	}
	
	inline public function hasNext():Bool
	{
		return _i < _s;
	}
	
	inline public function next():T
	{
		return _a[_i++];
	}
	
	inline public function remove()
	{
		//just nullify value
		#if debug
		assert(_i > 0, "call next() before removing an element");
		#end
		_a[_i - 1] = cast null;
	}
	
	inline function __a<T>(f:Array2Friend<T>)
	{
		return f._a;
	}
	inline function __size<T>(f:Array2Friend<T>)
	{
		return f._w * f._h;
	}
}

/**
 * <p>Stores the x,y position of a two-dimensional cell.</p>
 */
class Array2Cell
{
	/**
	 * The column index.
	 */
	public var x:Int;
	
	/**
	 * The row index.
	 */
	public var y:Int;
	
	public function new(x = 0, y = 0)
	{
		this.x = x;
		this.y = y;
	}
}