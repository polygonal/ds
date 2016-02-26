/*
Copyright (c) 2008-2016 Michael Baczynski, http://www.polygonal.de

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

import de.polygonal.ds.Array2.Array2Cell;
import de.polygonal.ds.tools.Assert.assert;
import de.polygonal.ds.tools.M;

using de.polygonal.ds.tools.NativeArrayTools;

/**
	A two-dimensional array based on a rectangular sequential array
**/
#if generic
@:generic
#end
class Array2<T> implements Collection<T>
{
	/**
		The width (#columns).
		
		The minimum value is 2.
		<assert>invalid width</assert>
	**/
	public var width(get, set):Int;
	inline function get_width():Int
	{
		return mW;
	}
	function set_width(val:Int):Int
	{
		resize(val, mH);
		return val;
	}
	
	/**
		The height (#rows).
		
		The minimum value is 2.
		<assert>invalid height</assert>
	**/
	public var height(get, set):Int;
	inline function get_height():Int
	{
		return mH;
	}
	function set_height(val:Int):Int
	{
		resize(mW, val);
		return val;
	}
	
	/**
		Equals `width`.
	**/
	public var cols(get, set):Int;
	inline function get_cols():Int
	{
		return width;
	}
	function set_cols(val:Int):Int
	{
		return width = val;
	}
	
	/**
		Equals `height`.
	**/
	public var rows(get, set):Int;
	inline function get_rows():Int
	{
		return height;
	}
	function set_rows(val:Int):Int
	{
		return height = val;
	}
	
	/**
		A unique identifier for this object.
		
		A hash table transforms this key into an index of an array element by using a hash function.
		
		<warn>This value should never be changed by the user.</warn>
	**/
	public var key(default, null):Int = HashKey.next();
	
	/**
		If true, reuses the iterator object instead of allocating a new one when calling ``iterator()``.
		
		The default is false.
		
		<warn>If true, nested iterations are likely to fail as only one iteration is allowed at a time.</warn>
	**/
	public var reuseIterator:Bool = false;
	
	var mData:NativeArray<T>;
	var mW:Int;
	var mH:Int;
	var mIterator:Array2Iterator<T> = null;
	
	/**
		Creates a two-dimensional array with dimensions `width` and `height`.
		
		The minimum size is 2x2.
		<assert>invalid `width` or `height`</assert>
	**/
	public function new(width:Int, ?height:Null<Int>, ?source:Array<T>)
	{
		assert(width >= 2 && height >= 2, 'invalid size (width:$width, height:$height)');
		
		if (source != null)
		{
			assert(source.length >= 4, "invalid source");
			
			if (height == null) height = Std.int(source.length / width);
			
			mW = width;
			mH = height;
			
			var d = mData = NativeArrayTools.alloc(size);
			for (i in 0...size) d.set(i, source[i]);
		}
		else
		{
			assert(width >= 2 && height >= 2, 'invalid size (width:$width, height:$height)');
			mW = width;
			mH = height;
			mData = NativeArrayTools.alloc(size);
		}
	}
	
	/**
		Returns the element that is stored in column `x` and row `y`.
		<assert>`x`/`y` out of range</assert>
	**/
	public inline function get(x:Int, y:Int):T
	{
		assert(x >= 0 && x < cols, 'x index out of range ($x)');
		assert(y >= 0 && y < rows, 'y index out of range ($y)');
		
		return mData.get(getIndex(x, y));
	}
	
	/**
		Returns the element that is stored in column ``cell::x`` and row ``cell::y``.
		<assert>`cell` is null</assert>
		<assert>`x`/`y` out of range</assert>
	**/
	public inline function getAtCell(cell:Array2Cell):T
	{
		assert(cell != null, "cell is null");
		assert(cell.x >= 0 && cell.x < cols, 'cell.x out of range (${cell.x})');
		assert(cell.y >= 0 && cell.y < rows, 'cell.y out of range (${cell.y})');
		
		return mData.get(getIndex(cell.x, cell.y));
	}
	
	/**
		Replaces the element at column `x` and row `y` with `val`.
		<assert>`x`/`y` out of range</assert>
	**/
	public inline function set(x:Int, y:Int, val:T)
	{
		assert(x >= 0 && x < cols, 'x index out of range ($x)');
		assert(y >= 0 && y < rows, 'y index out of range ($y)');
		
		mData.set(getIndex(x, y), val);
	}
	
	/**
		Returns the element at index `i`.
		<assert>`i` out of range</assert>
	**/
	public inline function getAtIndex(i:Int):T
	{
		assert(i >= 0 && i < size, 'index out of range ($i)');
		
		return mData.get(getIndex(i % mW, Std.int(i / mW)));
	}
	
	/**
		Replaces the element that is stored in column ``cell::x`` and row ``cell::y`` with `val`.
		<assert>`cell` is null</assert>
		<assert>`x`/`y` out of range</assert>
	**/
	public inline function setAtCell(cell:Array2Cell, val:T)
	{
		assert(cell != null, "cell is null");
		assert(cell.x >= 0 && cell.x < cols, 'cell.x out of range (${cell.x})');
		assert(cell.y >= 0 && cell.y < rows, 'cell.y out of range (${cell.y})');
		
		return mData.set(getIndex(cell.x, cell.y), val);
	}
	
	/**
		Replaces the element at index `i` with `val`.
		<assert>`i` out of range</assert>
	**/
	public inline function setAtIndex(i:Int, val:T)
	{
		assert(i >= 0 && i < size, 'index out of range ($i)');
		
		mData.set(getIndex(i % mW, Std.int(i / mW)), val);
	}
	
	/**
		Sets all elements to `val`.
	**/
	public function setAll(val:T)
	{
		var d = mData;
		for (i in 0...size) d.set(i, val);
	}
	
	/**
		Computes an index into the linear array from the `x` and `y` index.
	**/
	public inline function getIndex(x:Int, y:Int):Int
	{
		return y * mW + x;
	}
	
	/**
		Returns the index of the first occurrence of the element `x` or returns -1 if element `x` does not exist.
		
		The index is in the range [0, ``size`` - 1].
	**/
	public function indexOf(x:T):Int
	{
		var i = 0, j = size, d = mData;
		while (i < j)
		{
			if (d.get(i) == x) break;
			i++;
		}
		return (i == j) ? -1 : i;
	}
	
	/**
		Returns true if `x` and `y` are valid indices.
	**/
	public inline function inRange(x:Int, y:Int):Bool
	{
		return x >= 0 && x < mW && y >= 0 && y < mH;
	}
	
	/**
		Returns the cell coordinates of the first occurrence of the element `x` or null if element `x` does not exist.
		<assert>`out` is null</assert>
		@param out stores the result.
		@return a reference to `out`.
	**/
	public inline function cellOf(x:T, out:Array2Cell):Array2Cell
	{
		assert(out != null);
		
		var i = indexOf(x);
		return i == -1 ? null : indexToCell(i, out);
	}
	
	/**
		Transforms the index `i` into `out` coordinates.
		<assert>`i` out of range</assert>
		<assert>`out` is null</assert>
		@param out stores the result.
		@return a reference to `out`.
	**/
	public inline function indexToCell(i:Int, out:Array2Cell):Array2Cell
	{
		assert(i >= 0 && i < size, 'index out of range ($i)');
		assert(out != null, "out is null");
		
		out.y = Std.int(i / mW);
		out.x = i % mW;
		return out;
	}
	
	/**
		Computes an array index into the linear array from the `cell` coordinates.
		<assert>`cell` index out of range</assert>
		<assert>`cell` is null</assert>
	**/
	public inline function cellToIndex(cell:Array2Cell):Int
	{
		assert(cell != null);
		assert(cell.x >= 0 && cell.x < cols, 'x index out of range (${cell.x})');
		assert(cell.y >= 0 && cell.y < rows, 'y index out of range (${cell.y})');
		
		return getIndex(cell.x, cell.y);
	}
	
	/**
		Copies all elements stored in row `y` by reference to the `out` array.
		<assert>`y` out of range</assert>
		<assert>`out` is null</assert>
		@return a reference to the `out` array.
	**/
	public function getRow(y:Int, out:Array<T>):Array<T>
	{
		assert(y >= 0 && y < rows, 'y index out of range ($y)');
		assert(out != null, "out is null");
		
		var offset = y * mW, d = mData;
		for (x in 0...mW) out[x] = d.get(offset + x);
		return out;
	}
	
	/**
		Overwrites all elements in row `y` with the elements stored in the `input` array.
		<assert>`y` out of range or `input` is null or insufficient input values</assert>
	**/
	public function setRow(y:Int, input:Array<T>)
	{
		assert(y >= 0 && y < rows, 'y index out of range ($y)');
		assert(input != null, "input is null");
		assert(input.length >= cols, "insufficient input values");
		
		var offset = y * mW, d = mData;
		for (x in 0...mW) d.set(offset + x, input[x]);
	}
	
	/**
		Copies all elements stored in column `x` by reference to the `out` array.
		<assert>`x` out of range</assert>
		<assert>`out` is null</assert>
		@return a reference to the `out` array.
	**/
	public function getCol(x:Int, out:Array<T>):Array<T>
	{
		assert(x >= 0 && x < cols, 'x index out of range ($x)');
		assert(out != null, "out is null");
		
		var d = mData;
		for (i in 0...mH) out[i] = d.get(getIndex(x, i));
		return out;
	}
	
	/**
		Overwrites all elements in column `x` with the elements stored in the `input` array.
		<assert>`x` out of range</assert>
		<assert>`input` is null or insufficient input values</assert>
	**/
	public function setCol(x:Int, input:Array<T>)
	{
		assert(x >= 0 && x < cols, 'x index out of range ($x)');
		assert(input != null, "input is null");
		assert(input.length >= rows, "insufficient input values");
		
		var d = mData;
		for (y in 0...mH) d.set(getIndex(x, y), input[y]);
	}
	
	/**
		Calls the `f` function on all elements.
		
		The function signature is: `f(element, xIndex, yIndex):element`
		<assert>`f` is null</assert>
	**/
	public function forEach(f:T->Int->Int->T):Array2<T>
	{
		var d = mData;
		for (i in 0...size) d.set(i, f(d.get(i), i % mW, Std.int(i / mW)));
		return this;
	}
	
	/**
		Resizes this two-dimensional array.
		<assert>invalid dimensions</assert>
		@param width the new width (minimum is 2).
		@param height the new height (minimum is 2).
	**/
	public function resize(width:Int, height:Int)
	{
		assert(width >= 2 && height >= 2, 'invalid size (width:$width, height:$height)');
		
		if (width == mW && height == mH) return;
		
		var t = mData;
		mData = NativeArrayTools.alloc(width * height);
		
		var minX = width < mW ? width : mW;
		var minY = height < mH ? height : mH;
		
		var t1, t2, d = mData;
		
		for (y in 0...minY)
		{
			t1 = y * width;
			t2 = y * mW;
			for (x in 0...minX)
				d.set(t1 + x, t.get(t2 + x));
		}
		
		mW = width;
		mH = height;
	}
	
	/**
		Shifts all columns to the west by one position.
		
		Columns are wrapped so the column at index 0 is not lost but appended to the rightmost column.
	**/
	public function shiftW()
	{
		var t, k, d = mData;
		for (y in 0...mH)
		{
			k = y * mW;
			t = d.get(k);
			for (x in 1...mW)
				d.set(k + x - 1, d.get(k + x));
			d.set(k + mW - 1, t);
		}
	}
	
	/**
		Shifts all columns to the east by one position.
		
		Columns are wrapped, so the column at index [``cols`` - 1] is not lost but prepended to the leftmost column.
	**/
	public function shiftE()
	{
		var t, x, k, d = mData;
		for (y in 0...mH)
		{
			k = y * mW;
			t = d.get(k + mW - 1);
			x = mW - 1;
			while (x-- > 0)
				d.set(k + x + 1, d.get(k + x));
			d.set(k, t);
		}
	}
	
	/**
		Shifts all rows to the north by one position.
		
		Rows are wrapped, so the row at index 0 is not lost but appended to the bottommost row.
	**/
	public function shiftN()
	{
		var k = mH - 1, l = (mH - 1) * mW, t, d = mData;
		for (x in 0...mW)
		{
			t = d.get(x);
			for (y in 0...k)
				d.set(getIndex(x, y), d.get(getIndex(x, y + 1)));
			d.set(l + x, t);
		}
	}
	
	/**
		Shifts all rows to the south by one position.
		
		Rows are wrapped, so row at index [``rows`` - 1] is not lost but prepended to the topmost row.
	**/
	public function shiftS()
	{
		var k = mH - 1, l = k * mW, y, t, d = mData;
		for (x in 0...mW)
		{
			t = d.get(l + x);
			y = k;
			while (y-- > 0)
				d.set(getIndex(x, y + 1), d.get(getIndex(x, y)));
			d.set(x, t);
		}
	}
	
	/**
		Swaps the element at column/row `x0`, `y0` with the element at column/row `x1`, `y1`.
		<assert>`x0`/`y0` or `x1`/`y1` out of range</assert>
		<assert>`x0`, `y0` equals `x1`, `y1`</assert>
	**/
	public inline function swap(x0:Int, y0:Int, x1:Int, y1:Int)
	{
		assert(x0 >= 0 && x0 < cols, 'x0 index out of range ($x0)');
		assert(y0 >= 0 && y0 < rows, 'y0 index out of range ($y0)');
		assert(x1 >= 0 && x1 < cols, 'x1 index out of range ($x1)');
		assert(y1 >= 0 && y1 < rows, 'y1 index out of range ($y1)');
		assert(!(x0 == x1 && y0 == y1), 'source indices equal target indices (x: $x0, y: $y0)');
		
		var i = getIndex(x0, y0);
		var j = getIndex(x1, y1);
		var d = mData;
		var t = d.get(i);
		d.set(i, d.get(j));
		d.set(j, t);
	}
	
	/**
		Appends the elements of the `input` array in the range [0, ``cols``] by adding a new row.
		<assert>`input` is null or too short</assert>
	**/
	public function appendRow(input:Array<T>)
	{
		assert(input != null, "input is null");
		assert(input.length >= cols, "insufficient input values");
		
		var t = NativeArrayTools.alloc(mW * (mH + 1));
		mData.blit(0, t, 0, size);
		mData = t;
		var s = size, d = mData;
		mH++;
		for (i in 0...mW) d.set(s + i, input[i]);
	}
	
	/**
		Appends the elements of the `input` array in the range [0, ``rows``] by adding a new column.
		<assert>`input` is null or too short</assert>
	**/
	public function appendCol(input:Array<T>)
	{
		assert(input != null, "input is null");
		assert(input.length >= rows, "insufficient input values");
		
		var t = NativeArrayTools.alloc((mW + 1) * mH);
		mData.blit(0, t, 0, size);
		mData = t;
		var y = size + mH, i = mH - 1, j = mH, x = mW, d = mData;
		while (y-- > 0)
		{
			if (++x > mW)
			{
				x = 0;
				j--;
				d.set(y, input[i--]);
			}
			else
				d.set(y, d.get(y - j));
		}
		mW++;
	}
	
	/**
		Prepends the elements of the `input` array in the range [0, ``cols``] by adding a new row.
		<assert>`input` is null or too short</assert>
	**/
	public function prependRow(input:Array<T>)
	{
		assert(input != null, "input is null");
		assert(input.length >= cols, "insufficient input values");
		
		var t = NativeArrayTools.alloc(mW * (mH + 1));
		mData.blit(0, t, mW, size);
		mData = t;
		mH++;
		var d = mData;
		for (i in 0...mW) d.set(i, input[i]);
	}
	
	/**
		Prepends the elements of the `input` array in the range [0, ``rows``] by adding a new column.
		<assert>`input` is null or too short</assert>
	**/
	public function prependCol(input:Array<T>)
	{
		assert(input != null, "input is null");
		assert(input.length >= rows, "insufficient input values");
		
		var t = NativeArrayTools.alloc((mW + 1) * mH);
		mData.blit(0, t, 0, size);
		mData = t;
		var y = size + mH, i = mH - 1, j = mH, x = 0, d = mData;
		while (y-- > 0)
		{
			if (++x > mW)
			{
				x = 0;
				j--;
				d.set(y, input[i--]);
			}
			else
				d.set(y, d.get(y - j));
		}
		mW++;
	}
	
	/**
		Copies row elements from row `i` to row `j`.
		<assert>`i`/`j` out of range</assert>
	**/
	public function copyRow(i:Int, j:Int)
	{
		assert(i >= 0 && i < rows, 'i index out of range ($i)');
		assert(j >= 0 && j < rows, 'j index out of range ($j)');
		
		if (i != j)
		{
			var srcOffset = mW * i;
			var dstOffset = mW * j;
			var d = mData;
			for (x in 0...mW) d.set(dstOffset + x, d.get(srcOffset + x));
		}
	}
	
	/**
		Swaps row elements at row `i` with row elements at row `j`.
		<assert>`i`/`j` out of range</assert>
	**/
	public function swapRow(i:Int, j:Int)
	{
		assert(i >= 0 && i < rows, 'i index out of range ($i)');
		assert(j >= 0 && j < rows, 'j index out of range ($j)');
		
		if (i != j)
		{
			var srcOffset = mW * i;
			var dstOffset = mW * j;
			var t, k, d = mData;
			for (x in 0...mW)
			{
				t = d.get(srcOffset + x);
				k = dstOffset + x;
				d.set(srcOffset + x, d.get(k));
				d.set(k, t);
			}
		}
	}
	
	/**
		Copies column elements from column `i` to column `j`.
		<assert>`i`/`j` out of range</assert>
	**/
	public function copyCol(i:Int, j:Int)
	{
		assert(i >= 0 && i < cols, 'i index out of range ($i)');
		assert(j >= 0 && j < cols, 'j index out of range ($j)');
		
		if (i != j)
		{
			var t, d = mData;
			for (y in 0...mH)
			{
				t = y * mW;
				d.set(t + j, d.get(t + i));
			}
		}
	}
	
	/**
		Swaps column elements at column `i` with column elements at row `j`.
		<assert>`i`/`j` out of range</assert>
	**/
	public function swapCol(i:Int, j:Int)
	{
		assert(i >= 0 && i < cols, 'i index out of range ($i)');
		assert(j >= 0 && j < cols, 'j index out of range ($j)');
		
		if (i != j)
		{
			var k, l, m, t, d = mData;
			for (y in 0...mH)
			{
				m = y * mW;
				k = m + i;
				l = m + j;
				t = d.get(k);
				d.set(k, d.get(l));
				d.set(l, t);
			}
		}
	}
	
	/**
		Transposes this two-dimensional array.
	**/
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
			var t = NativeArrayTools.alloc(size);
			for (y in 0...mH)
				for (x in 0...mW)
					t.set(x * mH + y, get(x, y));
			mData = t;
			mW ^= mH;
			mH ^= mW;
			mW ^= mH;
		}
	}
	
	/**
		Grants access to the rectangular sequential array storing the elements of this two-dimensional array.
		
		Useful for fast iteration or low-level operations.
	**/
	public inline function getData():NativeArray<T>
	{
		return mData;
	}
	
	/**
		Copies all elements from the nested two-dimensional array `a` into this two-dimensional array.
		<assert>invalid dimensions of `a`</assert>
	**/
	public function ofNestedArray(input:Array<Array<T>>)
	{
		assert(input.length == rows && input[0] != null && input[0].length == cols, "invalid input");
		
		var w = input[0].length, row, d = mData;
		for (y in 0...input.length)
		{
			row = input[y];
			for (x in 0...w)
				d.set(getIndex(x, y), row[x]);
		}
	}
	
	/**
		Shuffles the elements of this collection by using the Fisher-Yates algorithm.
		<assert>insufficient random values</assert>
		@param rvals a list of random double values in the range between 0 (inclusive) to 1 (exclusive) defining the new positions of the elements.
		If omitted, random values are generated on-the-fly by calling `Math::random()`.
	**/
	public function shuffle(rvals:Array<Float> = null)
	{
		var s = size;
		var d = mData;
		if (rvals == null)
		{
			var m = Math, i, t;
			while (--s > 1)
			{
				i = Std.int(m.random() * s);
				t = d.get(s);
				d.set(s, d.get(i));
				d.set(i, t);
			}
		}
		else
		{
			assert(rvals.length >= size, "insufficient random values");
			
			var j = 0, i, t;
			while (--s > 1)
			{
				i = Std.int(rvals[j++] * s);
				t = d.get(s);
				d.set(s, d.get(i));
				d.set(i, t);
			}
		}
	}
	
	/**
		Copies all elements inside the rectangular region bounded by [`minX`, `minY`] and [`maxX`, `maxY`] by reference to the `out` array.
		<assert>`minX` or `minY` out of range</assert>
		@return a reference to the `out` array.
	**/
	public function getRect(minX:Int, minY:Int, maxX:Int, maxY:Int, out:Array<T>):Array<T>
	{
		assert(minX <= maxX, 'minX index out of range ($minX)');
		assert(minY <= maxY, 'minY index out of range ($minY)');
		
		if (minX < 0) minX = 0;
		if (minY < 0) minY = 0;
		if (maxX > mW - 1) maxX = mW - 1;
		if (maxY > mH - 1) maxY = mH - 1;
		
		var y = minY, x, i = 0, offset, w = mW, d = mData;
		while (y <= maxY)
		{
			offset = y * w;
			x = minX;
			while (x <= maxX)
			{
				out[i++] = d.get(offset + x);
				x++;
			}
			y++;
		}
		return out;
	}
	
	/**
		Returns a string representing the current object.
		
		Example:
		<pre class="prettyprint">
		var array2 = new de.polygonal.ds.Array2<String>(4, 4);
		array2.walk(function(val:String, x:Int, y:Int):String { return Std.string(x) + "." + Std.string(y); });
		trace(array2);</pre>
		<pre class="console">
		{ Array2 4x4 }
		[
		  [0.0][1.0][2.0][3.0]
		  [0.1][1.1][2.1][3.1]
		  [0.2][1.2][2.2][3.2]
		  [0.3][1.3][2.3][3.3]
		]</pre>
	**/
	public function toString():String
	{
		var l = 0, s, d = mData;
		for (i in 0...size)
		{
			s = Std.string(d.get(i));
			l = Std.int(Math.max(s.length, l));
		}
		
		var b = new StringBuf();
		b.add('{ Array2 ${cols}x${rows} }');
		b.add("\n[\n");
		
		var offset, row = 0, args = new Array<Dynamic>();
		var w = M.numDigits(rows);
		for (y in 0...rows)
		{
			args[0] = row++;
			b.add(Printf.format('  %${w}d: ', args));
			offset = y * cols;
			for (x in 0...cols)
			{
				args[0] = Std.string(d.get(offset + x));
				args[1] = x < cols - 1 ? ", " : "";
				b.add(Printf.format('%${l}s%s', args));
			}
			b.add("\n");
		}
		b.add("]");
		return b.toString();
	}
	
	/* INTERFACE Collection */
	
	/**
		The number of elements in this two-dimensional array.
		
		Always equals ``cols`` * ``rows``.
	**/
	public var size(get, never):Int;
	inline function get_size():Int
	{
		return mW * mH;
	}
	
	/**
		Destroys this object by explicitly nullifying all elements for GC'ing used resources.
		
		Improves GC efficiency/performance (optional).
	**/
	public function free()
	{
		mData.nullify();
		mData = null;
		if (mIterator != null)
		{
			mIterator.free();
			mIterator = null;
		}
	}
	
	/**
		Returns true if this two-dimensional array contains the element `x`.
	**/
	public function contains(x:T):Bool
	{
		var d = mData;
		for (i in 0...size)
		{
			if (d.get(i) == x)
				return true;
		}
		return false;
	}
	
	/**
		Nullifies all occurrences of `x`.
		The size is not altered.
		@return true if at least one occurrence of `x` was nullified.
	**/
	public function remove(x:T):Bool
	{
		var found = false, d = mData;
		for (i in 0...size)
		{
			if (d.get(i) == x)
			{
				d.set(i, cast null);
				found = true;
			}
		}
		return found;
	}
	
	/**
		Clears this two-dimensional array by nullifying all elements.
		
		The `gc` parameter has no effect.
	**/
	public function clear(gc:Bool = false)
	{
		mData.nullify(size);
	}
	
	/**
		Returns a new `Array2Iterator` object to iterate over all elements contained in this two-dimensional array.
		
		Order: Row-major order (row-by-row).
		
		See <a href="http://haxe.org/ref/iterators" target="mBlank">http://haxe.org/ref/iterators</a>
	**/
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
		<warn>Unsupported operation - always returns false.</warn>
	**/
	public function isEmpty():Bool
	{
		return false;
	}
	
	/**
		Returns an array containing all elements in this two-dimensional array.
		
		Order: Row-major order (row-by-row).
	**/
	public function toArray():Array<T>
	{
		return mData.toArray(0, size);
	}
	
	/**
		Duplicates this two-dimensional array. Supports shallow (structure only) and deep copies (structure & elements).
		<assert>element is not of type `Cloneable`</assert>
		@param assign if true, the `copier` parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.
		If false, the ``clone()`` method is called on each element.
		
		<warn>In this case all elements have to implement `Cloneable`.</warn>
		@param copier a custom function for copying elements. Replaces ``element::clone()`` if `assign` is false.
	**/
	public function clone(assign:Bool = true, copier:T->T = null):Collection<T>
	{
		var out = new Array2<T>(mW, mH);
		var src = mData;
		var dst = out.mData;
		
		if (assign)
			src.blit(0, dst, 0, size);
		else
		{
			if (copier == null)
			{
				for (i in 0...size)
				{
					assert(Std.is(src.get(i), Cloneable), "element is not of type Cloneable");
					
					dst.set(i, cast(src.get(i), Cloneable<Dynamic>).clone());
				}
			}
			else
			{
				for (i in 0...size)
					dst.set(i, copier(src.get(i)));
			}
		}
		return out;
	}
}

#if generic
@:generic
#end
@:access(de.polygonal.ds.Array2)
@:dox(hide)
class Array2Iterator<T> implements de.polygonal.ds.Itr<T>
{
	var mObject:Array2<T>;
	var mData:NativeArray<T>;
	var mI:Int;
	var mS:Int;
	
	public function new(x:Array2<T>)
	{
		mObject = x;
		reset();
	}
	
	public function free()
	{
		mObject = null;
		mData = null;
	}
	
	public inline function reset():Itr<T>
	{
		mData = mObject.mData;
		mS = mObject.size;
		mI = 0;
		return this;
	}
	
	public inline function hasNext():Bool
	{
		return mI < mS;
	}
	
	public inline function next():T
	{
		return mData.get(mI++);
	}
	
	public function remove()
	{
		assert(mI > 0, "call next() before removing an element");
		
		mData.set(mI - 1, cast null);
	}
}

/**
	Stores the (x,y) position of a two-dimensional cell
**/
class Array2Cell
{
	/**
		The column index.
	**/
	public var x:Int;
	
	/**
		The row index.
	**/
	public var y:Int;
	
	public function new(x:Int = 0, y:Int = 0)
	{
		this.x = x;
		this.y = y;
	}
	
	public inline function equals(other:Array2Cell):Bool
	{
		return x == other.x && y == other.y;
	}
}