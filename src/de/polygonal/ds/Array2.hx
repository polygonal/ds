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
	
	var mA:Array<T>;
	var mW:Int;
	var mH:Int;
	var mIterator:Array2Iterator<T>;
	
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
		
		mW            = width;
		mH            = height;
		mA            = ArrayUtil.alloc(size());
		mIterator     = null;
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
		
		return _get(getIndex(x, y));
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
		
		return _get(getIndex(cell.x, cell.y));
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
		
		_set(getIndex(x, y), val);
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
		
		return _get(getIndex(i % mW, Std.int(i / mW)));
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
		
		_set(getIndex(i % mW, Std.int(i / mW)), val);
	}
	
	/**
	 * The width (#columns).
	 * <o>1</o>
	 */
	inline public function getW():Int
	{
		return mW;
	}
	
	/**
	 * Sets the width to <code>x</code>.<br/>
	 * The minimum value is 2.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError invalid width (debug only).
	 */
	inline public function setW(x:Int)
	{
		resize(x, mH);
	}
	
	/**
	 * The height (#rows).
	 * <o>1</o>
	 */
	inline public function getH():Int
	{
		return mH;
	}
	
	/**
	 * Sets the height to <code>x</code>.<br/>
	 * The minimum value is 2.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError invalid height (debug only).
	 */
	inline public function setH(x:Int)
	{
		resize(mW, x);
	}
	
	/**
	 * Computes an index into the linear array from the <code>x<code> and <code>y</code> index.
	 * <o>1</o>
	 */
	inline public function getIndex(x:Int, y:Int):Int
	{
		return y * mW + x;
	}
	
	/**
	 * Returns the index of the first occurrence of the element <code>x</code> or returns -1 if element <code>x</code> does not exist.<br/>
	 * The index is in the range &#091;0, size() - 1&#093;.
	 * <o>n</o>
	 */
	inline public function indexOf(x:T):Int
	{
		var i = 0;
		var j = mW * mH;
		while (i < j)
		{
			if (_get(i) == x) break;
			i++;
		}
		
		return (i == j) ? -1 : i;
	}
	
	/**
	 * Returns true if <code>x</code> and <code>y</code> are valid.
	 */
	inline public function inRange(x:Int, y:Int):Bool
	{
		return x >= 0 && x < mW && y >= 0 && y < mH;
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
		
		cell.y = Std.int(i / mW);
		cell.x = i % mW;
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
		
		var offset = y * mW;
		for (x in 0...mW)
			output[x] = _get(offset + x);
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
		
		var offset = y * mW;
		for (x in 0...mW)
			_set(offset + x, input[x]);
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
		
		for (i in 0...mH)
			output[i] = _get(i * mW + x);
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
		
		for (y in 0...mH)
			_set(getIndex(x, y), input[y]);
	}
	
	/**
	 * Copies all elements inside the rectangular region bounded by &#91;<code>minX</code>, <code>minY</code>&#93; and &#91;<code>maxX</code>, <code>maxY</code>&#93;
	 * by reference to the <code>output</code> array.
	 * <o>n</o>
	 * @return a reference to the <code>output</code> array.
	 */
	public function getRect(minX:Int, minY:Int, maxX:Int, maxY:Int, output:Array<T>):Array<T>
	{
		if (minX < 0) minX = 0;
		if (minY < 0) minY = 0;
		if (maxX > mW - 1) maxX = mW - 1;
		if (maxY > mH - 1) maxY = mH - 1;
		
		var y = minY, x, i = 0, offset, w = mW;
		while (y <= maxY)
		{
			offset = y * w;
			x = minX;
			while (x <= maxX)
			{
				output[i++] = _get(offset + x);
				x++;
			}
			y++;
		}
		
		return output;
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
		for (i in 0...size()) _set(i, Type.createInstance(C, args));
	}
	
	/**
	 * Replaces all existing elements with the instance of <code>x</code>.
	 * <o>n</o>
	 */
	public function fill(x:T):Array2<T>
	{
		for (i in 0...size()) _set(i, x);
		return this;
	}
	
	/**
	 * Invokes the <code>process</code> function for each element.<br/>
	 * The function signature is: <em>process(oldValue, xIndex, yIndex):newValue</em>
	 * <o>n</o>
	 */
	public function walk(process:T->Int->Int->T)
	{
		for (y in 0...mH)
		{
			for (x in 0...mW)
			{
				var i = getIndex(x, y);
				_set(i, process(_get(i), x, y));
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
		
		if (width == mW && height == mH) return;
		var t = mA;
		mA = ArrayUtil.alloc(width * height);
		
		var minX = width  < mW ? width  : mW;
		var minY = height < mH ? height : mH;
		
		for (y in 0...minY)
		{
			var t1 = y *  width;
			var t2 = y * mW;
			for (x in 0...minX)
				_set(t1 + x, t[t2 + x]);
		}
		
		mW = width;
		mH = height;
	}
	
	/**
	 * Shifts all columns to the west by one position.<br/>
	 * Columns are wrapped so the column at index 0 is not lost but appended to the rightmost column.
	 * <o>n</o>
	 */
	public function shiftW()
	{
		var t, k;
		for (y in 0...mH)
		{
			k = y * mW;
			t = _get(k);
			for (x in 1...mW)
				_set(k + x - 1, _get(k + x));
			_set(k + mW - 1, t);
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
		for (y in 0...mH)
		{
			k = y * mW;
			t = _get(k + mW - 1);
			x = mW - 1;
			while (x-- > 0)
				_set(k + x + 1, _get(k + x));
			_set(k, t);
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
		var k = mH - 1;
		var l = (mH - 1) * mW;
		for (x in 0...mW)
		{
			t = _get(x);
			for (y in 0...k)
				_set(getIndex(x, y), _get((y + 1) * mW + x));
			_set(l + x, t);
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
		var k = mH - 1;
		var l = k * mW;
		for (x in 0...mW)
		{
			t = _get(l + x);
			y = k;
			while(y-- > 0) _set((y + 1) * mW + x, _get(getIndex(x, y)));
			_set(x, t);
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
		
		var i = y0 * mW + x0;
		var j = y1 * mW + x1;
		var t = _get(i);
		_set(i, _get(j));
		_set(j, t);
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
		
		var t = mW * mH++;
		for (i in 0...mW) _set(t + i, input[i]);
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
		var l = t + mH;
		var i = mH - 1;
		var j = mH;
		var x = mW;
		var y = l;
		while (y-- > 0)
		{
			if (++x > mW)
			{
				x = 0;
				j--;
				_set(y, input[i--]);
			}
			else
				_set(y, _get(y - j));
		}
		mW++;
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
		
		mH++;
		
		var y = size();
		while (y-- > mW)
			_set(y, _get(y - mW));
		
		y++;
		
		while (y-- > 0)
			_set(y, input[y]);
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
		var l = t + mH;
		var i = mH - 1;
		var j = mH;
		var x = 0;
		var y = l;
		while (y-- > 0)
		{
			if (++x > mW)
			{
				x = 0;
				j--;
				_set(y, input[i--]);
			}
			else
				_set(y, _get(y - j));
		}
		mW++;
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
			var srcOffset = mW * i;
			var dstOffset = mW * j;
			for (x in 0...mW) _set(dstOffset + x, _get(srcOffset + x));
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
			var srcOffset = mW * i;
			var dstOffset = mW * j;
			
			for (x in 0...mW)
			{
				var tmp = _get(srcOffset + x);
				var k = dstOffset + x;
				_set(srcOffset + x, _get(k));
				_set(k, tmp);
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
			for (y in 0...mH)
			{
				var t = y * mW;
				_set(t + j, _get(t + i));
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
			for (y in 0...mH)
			{
				var t = y * mW;
				var k = t + i;
				var l = t + j;
				var tmp = _get(k);
				_set(k, _get(l));
				_set(l, tmp);
			}
		}
	}
	
	/**
	 * Transposes this two-dimensional array.
	 * <o>n</o>
	 */
	public function transpose()
	{
		if (mW == mH)
		{
			for (y in 0...mH)
				for (x in y + 1...mW)
					swap(x, y, y, x);
		}
		else
		{
			var t = new Array<T>();
			for (y in 0...mH)
				for (x in 0...mW)
					t[x * mH + y] = get(x, y);
			mA = t;
			mW ^= mH;
			mH ^= mW;
			mW ^= mH;
		}
	}
	
	/**
	 * Grants access to the rectangular sequential array storing the elements of this two-dimensional array.<br/>
	 * Useful for fast iteration or low-level operations.
	 * <o>1</o>
	 */
	inline public function getArray():Array<T>
	{
		return mA;
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
				_set(getIndex(x, y), row[x]);
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
				var t = _get(s);
				_set(s, _get(i));
				_set(i, t);
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
				var t = _get(s);
				_set(s, _get(i));
				_set(i, t);
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
			var s = Std.string(_get(i));
			l = Std.int(Math.max(s.length, l));
		}
		var s = '{ Array2 ${mW}x${mH} }';
		s += "\n[\n";
		var offset, value;
		for (y in 0...mH)
		{
			s += "  ";
			offset = y * mW;
			for (x in 0...mW)
				s += Printf.format("%" + l + "s%s", [Std.string(_get(offset + x)), x < mW - 1 ? ", " : ""]);
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
		for (i in 0...size()) _set(i, cast null);
		mA = null;
		mIterator = null;
	}
	
	/**
	 * Returns true if this two-dimensional array contains the element <code>x</code>.
	 * <o>n</o>
	 */
	public function contains(x:T):Bool
	{
		for (i in 0...size())
		{
			if (_get(i) == x)
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
			if (_get(i) == x)
			{
				_set(i, cast null);
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
		for (i in 0...size()) _set(i, cast null);
	}
	
	/**
	 * Returns a new <em>Array2Iterator</em> object to iterate over all elements contained in this two-dimensional array.<br/>
	 * Order: Row-major order (row-by-row).
	 * @see <a href="http://haxe.org/ref/iterators" target="mBlank">http://haxe.org/ref/iterators</a>
	 */
	public function iterator():Itr<T>
	{
		if (reuseIterator)
		{
			if (mIterator == null)
				mIterator = new Array2Iterator<T>(this);
			else
				mIterator.reset();
			return mIterator;
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
		return mW * mH;
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
			a[i] = _get(i);
		return a;
	}
	
	/**
	 * Returns a Vector.&lt;T&gt; object containing all elements in this two-dimensional array.<br/>
	 * Order: Row-major order (row-by-row).
	 */
	inline public function toVector():Vector<T>
	{
		var v = new Vector<T>(size());
		for (i in 0...size()) v[i] = _get(i);
		return v;
	}
	
	/**
	 * Duplicates this two-dimensional array. Supports shallow (structure only) and deep copies (structure & elements).
	 * @param assign if true, the <code>copier</code> parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.<br/>
	 * If false, the <em>clone()</em> method is called on each element. <warn>In this case all elements have to implement <em>Cloneable</em>.</warn>
	 * @param copier a custom function for copying elements. Replaces element.<em>clone()</em> if <code>assign</code> is false.
	 * @throws de.polygonal.ds.error.AssertError element is not of type <em>Cloneable</em> (debug only).
	 */
	public function clone(assign = true, copier:T->T = null):Collection<T>
	{
		var copy = new Array2<T>(mW, mH);
		if (assign)
		{
			for (i in 0...size())
				copy._set(i, untyped _get(i));
		}
		else
		if (copier == null)
		{
			var c:Cloneable<Dynamic> = null;
			for (i in 0...size())
			{
				#if debug
				assert(Std.is(_get(i), Cloneable), 'element is not of type Cloneable (${_get(i)})');
				#end
				
				c = cast(_get(i), Cloneable<Dynamic>);
				copy._set(i, c.clone());
			}
		}
		else
		{
			for (i in 0...size())
				copy._set(i, copier(_get(i)));
		}
		return copy;
	}
	
	inline function _get(i:Int) return mA[i];
	
	inline function _set(i:Int, x:T) mA[i] = x;
}

#if (generic && cpp)
@:generic
#end
#if doc
private
#end
@:access(de.polygonal.ds.Array2)
class Array2Iterator<T> implements de.polygonal.ds.Itr<T>
{
	var mF:Array2<T>;
	var mA:Array<T>;
	var mI:Int;
	var mS:Int;
	
	public function new(f:Array2<T>)
	{
		mF = f;
		reset();
	}
	
	inline public function reset():Itr<T>
	{
		mA = mF.mA;
		mS = mF.mW * mF.mH;
		mI = 0;
		return this;
	}
	
	inline public function hasNext():Bool
	{
		return mI < mS;
	}
	
	inline public function next():T
	{
		return mA[mI++];
	}
	
	inline public function remove()
	{
		//just nullify value
		#if debug
		assert(mI > 0, "call next() before removing an element");
		#end
		mA[mI - 1] = cast null;
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