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
package de.polygonal.ds;

import de.polygonal.ds.tools.Assert.assert;
import de.polygonal.ds.tools.MathTools;
import de.polygonal.ds.tools.Shuffle;

using de.polygonal.ds.tools.NativeArrayTools;

/**
	A two-dimensional array based on a rectangular sequential array
	
	Example:
		var o = new de.polygonal.ds.Array2<String>(3, 3);
		o.forEach(function(_, x, y) return '$x,$y');
		trace(o); //outputs:
		
		[ Array2 cols=3 rows=3
		  0 -> 0,0 | 1,0 | 2,0
		  1 -> 0,1 | 1,1 | 2,1
		  2 -> 0,2 | 1,2 | 2,2
		]
**/
#if generic
@:generic
#end
class Array2<T> implements Collection<T>
{
	/**
		The width (#columns).
		
		The minimum value is 2.
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
		Equals `this.width`.
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
		Equals `this.height`.
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
	**/
	public var key(default, null):Int = HashKey.next();
	
	/**
		If true, reuses the iterator object instead of allocating a new one when calling `this.iterator()`.
		
		The default is false.
		
		_If this value is true, nested iterations will fail as only one iteration is allowed at a time._
	**/
	public var reuseIterator:Bool = false;
	
	var mData:NativeArray<T>;
	var mW:Int;
	var mH:Int;
	var mIterator:Array2Iterator<T> = null;
	
	/**
		Creates a two-dimensional array with dimensions `width` and `height`.
		
		The minimum size is 2x2.
		
		@param source initial values for populating this two-dimensional array;
		<br/>`source.length` should match `width` × `height`.
	**/
	public function new(width:Int, height:Int, ?source:Array<T>)
	{
		assert(width >= 2 && height >= 2, 'invalid size (width:$width, height:$height)');
		
		if (source != null)
		{
			assert(source.length >= 4, "invalid source");
			
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
		Counts the number of neighbors at column `x` and row `y`, calling `f` on all adjacent cells.
		if `manhatten` is true, only counts in 4 directions (N,S,W,E), otherwise 8 (NW,N,NE,W,E,SW,S,SE).
		
		Example:
			var a = new Array2<Int>(3, 3);
			a.set(0, 0, 1);
			a.set(2, 1, 1);
			var count = a.countNeighbors(1, 1, function(value) return value == 1); //outputs 2
	**/
	public inline function countNeighbors(x:Int, y:Int, f:T->Bool, manhatten = false):Int
	{
		assert(x >= 0 && x < cols, 'x index out of range ($x)');
		assert(y >= 0 && y < rows, 'y index out of range ($y)');
		
		var c = 0;
		var l = x > 0;
		var r = x < mW - 1;
		var t = y > 0;
		var b = y < mH - 1;
		var d = mData;
		var w = mW;
		var i = y * w + x;
		
		inline function test(v) if (f(d.get(v))) c++;
		
		if (l) test(i - 1);
		if (r) test(i + 1);
		if (t)
		{
			i = (y - 1) * w + x;
			test(i);
			if (!manhatten)
			{
				if (l) test(i - 1);
				if (r) test(i + 1);
			}
		}
		if (b)
		{
			i = (y + 1) * w + x;
			test(i);
			if (!manhatten)
			{
				if (l) test(i - 1);
				if (r) test(i + 1);
			}
		}
		return c;
	}
	
	/**
		Passes the original value at `x`,`y` to `f` and replaces it with the value returned by `f`.
		
		Example:
			var a = new Array2<Int>(3, 3);
			a.replace(1, 2, v -> v + 1); // Haxe4
			a.replace(1, 2, function(v) return v + 1);
	**/
	public inline function replace(x:Int, y:Int, f:T->T)
	{
		assert(x >= 0 && x < cols, 'x index out of range ($x)');
		assert(y >= 0 && y < rows, 'y index out of range ($y)');
		
		var i = getIndex(x, y);
		var d = mData;
		return d.set(i, f(d.get(i)));
	}
	
	/**
		Returns the element that is stored in column `x` and row `y`.
	**/
	public inline function get(x:Int, y:Int):T
	{
		assert(x >= 0 && x < cols, 'x index out of range ($x)');
		assert(y >= 0 && y < rows, 'y index out of range ($y)');
		
		return mData.get(getIndex(x, y));
	}
	
	/**
		Returns the element that is stored in column `cell.x` and row `cell.y`.
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
	**/
	public inline function set(x:Int, y:Int, val:T):Array2<T>
	{
		assert(x >= 0 && x < cols, 'x index out of range ($x)');
		assert(y >= 0 && y < rows, 'y index out of range ($y)');
		
		mData.set(getIndex(x, y), val);
		return this;
	}
	
	/**
		Returns the element at index `i`.
	**/
	public inline function getAtIndex(i:Int):T
	{
		assert(i >= 0 && i < size, 'index out of range ($i)');
		
		return mData.get(getIndex(i % mW, Std.int(i / mW)));
	}
	
	/**
		Replaces the element that is stored in column `cell.x` and row `cell.y` with `val`.
	**/
	public inline function setAtCell(cell:Array2Cell, val:T):Array2<T>
	{
		assert(cell != null, "cell is null");
		assert(cell.x >= 0 && cell.x < cols, 'cell.x out of range (${cell.x})');
		assert(cell.y >= 0 && cell.y < rows, 'cell.y out of range (${cell.y})');
		
		mData.set(getIndex(cell.x, cell.y), val);
		return this;
	}
	
	/**
		Replaces the element at index `i` with `val`.
	**/
	public inline function setAtIndex(i:Int, val:T):Array2<T>
	{
		assert(i >= 0 && i < size, 'index out of range ($i)');
		
		mData.set(getIndex(i % mW, Std.int(i / mW)), val);
		return this;
	}
	
	/**
		Sets all elements to `val`.
	**/
	public function setAll(val:T):Array2<T>
	{
		var d = mData;
		for (i in 0...size) d.set(i, val);
		return this;
	}
	
	/**
		Computes an index into the linear array from the `x` and `y` index.
	**/
	public inline function getIndex(x:Int, y:Int):Int
	{
		return y * mW + x;
	}
	
	/**
		Computes an index into the linear array for the given `cell`.
	**/
	public inline function getIndexAtCell(cell:Array2Cell):Int
	{
		return cell.y * mW + cell.x;
	}
	
	/**
		Returns the index of the first occurrence of `val` or returns -1 if `val` does not exist.
		
		The index is in the range [0, `this.size` - 1].
	**/
	public function indexOf(val:T):Int
	{
		var i = 0, j = size, d = mData;
		while (i < j)
		{
			if (d.get(i) == val) break;
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
		Returns the cell coordinates of the first occurrence of `val` or null if `val` does not exist.
		@param out stores the result.
		@return a reference to `out`.
	**/
	public inline function cellOf(val:T, out:Array2Cell):Array2Cell
	{
		assert(out != null);
		
		var i = indexOf(val);
		return i == -1 ? null : indexToCell(i, out);
	}
	
	/**
		Transforms the index `i` into cell coordinates.
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
		Computes an array index into the linear array from the given `cell` coordinates.
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
		@param out stores the result.
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
		Overwrites all elements in row `y` with elements from `input`.
	**/
	public function setRow(y:Int, input:Array<T>):Array2<T>
	{
		assert(y >= 0 && y < rows, 'y index out of range ($y)');
		assert(input != null, "input is null");
		assert(input.length >= cols, "insufficient input values");
		
		var offset = y * mW, d = mData;
		for (x in 0...mW) d.set(offset + x, input[x]);
		return this;
	}
	
	/**
		Copies all elements stored in column `x` by reference to the `out` array.
		@param out stores the result.
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
		Overwrites all elements in column `x` with elements from `input`.
	**/
	public function setCol(x:Int, input:Array<T>):Array2<T>
	{
		assert(x >= 0 && x < cols, 'x index out of range ($x)');
		assert(input != null, "input is null");
		assert(input.length >= rows, "insufficient input values");
		
		var d = mData;
		for (y in 0...mH) d.set(getIndex(x, y), input[y]);
		return this;
	}
	
	/**
		Calls `f` on all elements.
		
		The function signature is: `f(input, x, y):output`
		
		- input: element at (x,y)
		- x: current x index
		- y: current y index
		- output: element to be stored at (x,y)
	**/
	public inline function forEach(f:T->Int->Int->T):Array2<T>
	{
		var d = mData;
		for (i in 0...size) d.set(i, f(d.get(i), i % mW, Std.int(i / mW)));
		return this;
	}
	
	/**
		Calls 'f` on all elements in order.
	**/
	public inline function iter(f:T->Void):Array2<T>
	{
		assert(f != null);
		var d = mData;
		for (i in 0...size) f(d.get(i));
		return this;
	}
	
	/**
		Calls 'f` on all elements in order.
	**/
	public inline function call(f:T->Void):Array2<T>
	{
		var d = mData;
		for (i in 0...size) f(d.get(i));
		return this;
	}
	
	/**
		Resizes this two-dimensional array.
		@param width the new width (minimum is 2).
		@param height the new height (minimum is 2).
	**/
	public function resize(width:Int, height:Int):Array2<T>
	{
		assert(width >= 2 && height >= 2, 'invalid size (width:$width, height:$height)');
		
		if (width == mW && height == mH) return this;
		
		var t = mData;
		mData = NativeArrayTools.alloc(width * height);
		
		if (width == mW)
		{
			t.blit(0, mData, 0, mW * (height < mH ? height : mH));
			mW = width;
			mH = height;
			return this;
		}
		
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
		return this;
	}
	
	/**
		Shifts all columns to the left by one position.
		
		@param wrap if true columns are wrapped so the column at index 0 is not lost but appended to the rightmost column.
	**/
	public function shiftLeft(wrap = true):Array2<T>
	{
		var t, k, d = mData;
		for (y in 0...mH)
		{
			k = y * mW;
			t = d.get(k);
			for (x in 1...mW)
				d.set(k + x - 1, d.get(k + x));
			if (wrap) d.set(k + mW - 1, t);
		}
		return this;
	}
	
	/**
		Shifts all columns to the right by one position.
		
		@param wrap if true columns are wrapped, so the column at index [`this.cols` - 1] is not lost but prepended to the leftmost column.
	**/
	public function shiftRight(wrap = true):Array2<T>
	{
		var t, x, k, d = mData;
		for (y in 0...mH)
		{
			k = y * mW;
			t = d.get(k + mW - 1);
			x = mW - 1;
			while (x-- > 0)
				d.set(k + x + 1, d.get(k + x));
			if (wrap) d.set(k, t);
		}
		return this;
	}
	
	/**
		Shifts all rows up by one position.
		
		@param wrap if true rows are wrapped, so the row at index 0 is not lost but appended to the bottommost row.
	**/
	public function shiftUp(wrap = true):Array2<T>
	{
		var k = mH - 1, l = (mH - 1) * mW, t, d = mData;
		for (x in 0...mW)
		{
			t = d.get(x);
			for (y in 0...k) d.set(getIndex(x, y), d.get(getIndex(x, y + 1)));
			if (wrap) d.set(l + x, t);
		}
		return this;
	}
	
	/**
		Shifts all rows down by one position.
		
		@param wrap if true rows are wrapped, so row at index [`this.rows` - 1] is not lost but prepended to the topmost row.
	**/
	public function shiftDown(wrap = true):Array2<T>
	{
		var k = mH - 1, l = k * mW, y, t, d = mData;
		for (x in 0...mW)
		{
			t = d.get(l + x);
			y = k;
			while (y-- > 0)
				d.set(getIndex(x, y + 1), d.get(getIndex(x, y)));
			if (wrap) d.set(x, t);
		}
		return this;
	}
	
	/**
		Swaps the element at column/row `x0`, `y0` with the element at column/row `x1`, `y1`.
	**/
	public inline function swap(x0:Int, y0:Int, x1:Int, y1:Int):Array2<T>
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
		return this;
	}
	
	/**
		Appends the elements of the `input` array in the range [0, `this.cols`] by adding a new row.
	**/
	public function appendRow(input:Array<T>):Array2<T>
	{
		assert(input != null, "input is null");
		assert(input.length >= cols, "insufficient input values");
		
		var t = NativeArrayTools.alloc(mW * (mH + 1));
		mData.blit(0, t, 0, size);
		mData = t;
		var s = size, d = mData;
		mH++;
		for (i in 0...mW) d.set(s + i, input[i]);
		return this;
	}
	
	/**
		Appends the elements of the `input` array in the range [0, `this.rows`] by adding a new column.
	**/
	public function appendCol(input:Array<T>):Array2<T>
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
		return this;
	}
	
	/**
		Prepends the elements of the `input` array in the range [0, `this.cols`] by adding a new row.
	**/
	public function prependRow(input:Array<T>):Array2<T>
	{
		assert(input != null, "input is null");
		assert(input.length >= cols, "insufficient input values");
		
		var t = NativeArrayTools.alloc(mW * (mH + 1));
		mData.blit(0, t, mW, size);
		mData = t;
		mH++;
		var d = mData;
		for (i in 0...mW) d.set(i, input[i]);
		return this;
	}
	
	/**
		Prepends the elements of the `input` array in the range [0, `this.rows`] by adding a new column.
	**/
	public function prependCol(input:Array<T>):Array2<T>
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
		return this;
	}
	
	/**
		Copies row elements from row `i` to row `j`.
	**/
	public function copyRow(i:Int, j:Int):Array2<T>
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
		return this;
	}
	
	/**
		Swaps row elements at row `i` with row elements at row `j`.
	**/
	public function swapRow(i:Int, j:Int):Array2<T>
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
		return this;
	}
	
	/**
		Copies all elements from `src` at position (`srcX`,`srcY`) to this two-dimensional array at position (`dstX`,`dstY`).
	**/
	public function copy(src:Array2<T>, srcX:Int, srcY:Int, dstX:Int, dstY:Int):Array2<T>
	{
		var a = src.getData();
		var b = getData();
		var maxX = cols - 1;
		var maxY = rows - 1;
		var srcW = src.cols;
		var srcH = src.rows;
		var dstW = cols;
		
		if (srcX > srcW - 1) return this;
		if (srcY > srcH - 1) return this;
		
		if (size == src.size)
		{
			if (srcX == 0 && srcY == 0 && dstX == 0 && dstY == 0)
			{
				a.blit(0, b, 0, size);
				return this;
			}
		}
		
		var s0x = srcX;
		var s0y = srcY;
		var s1x = s0x + srcW; if (s1x > srcW) s1x = srcW;
		var s1y = s0y + srcH; if (s1y > srcH) s1y = srcH;
		
		var dX = 0, dY = 0;
		for (y in s0y...s1y)
		{
			dX = 0;
			for (x in s0x...s1x)
			{
				var ix = dstX + dX++;
				if (ix > maxX) continue;
				var iy = dstY + dY;
				if (iy > maxY) continue;
				b.set(iy * dstW + ix, a.get(y * srcW + x));
			}
			dY++;
		}
		return this;
	}
	
	/**
		Copies column elements from column `i` to column `j`.
	**/
	public function copyCol(i:Int, j:Int):Array2<T>
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
		return this;
	}
	
	/**
		Swaps column elements at column `i` with column elements at row `j`.
	**/
	public function swapCol(i:Int, j:Int):Array2<T>
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
		return this;
	}
	
	/**
		Transposes this two-dimensional array.
	**/
	public function transpose():Array2<T>
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
		return this;
	}
	
	/**
		Returns a reference to the internal container storing the elements of this collection.
		
		Useful for fast iteration or low-level operations.
	**/
	public inline function getData():NativeArray<T>
	{
		return mData;
	}
	
	/**
		Copies all elements from the nested two-dimensional array `input` into this two-dimensional array by reference.
	**/
	public function ofNestedArray(input:Array<Array<T>>):Array2<T>
	{
		assert(input.length == rows && input[0] != null && input[0].length == cols, "invalid input");
		
		var w = input[0].length, row, d = mData;
		for (y in 0...input.length)
		{
			row = input[y];
			for (x in 0...w)
				d.set(getIndex(x, y), row[x]);
		}
		return this;
	}
	
	/**
		Shuffles the elements of this collection by using the Fisher-Yates algorithm.
		@param rvals a list of random double values in the interval [0, 1) defining the new positions of the elements.
		If omitted, random values are generated on-the-fly by calling `Shuffle.frand()`.
	**/
	public function shuffle(rvals:Array<Float> = null):Array2<T>
	{
		var s = size;
		var d = mData;
		if (rvals == null)
		{
			var i, t;
			while (--s > 1)
			{
				i = Std.int(Shuffle.frand() * s);
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
		return this;
	}
	
	/**
		Copies all elements inside the rectangular region bounded by [`minX`, `minY`] and [`maxX`, `maxY`] by reference to the `out` array.
		@param out stores the result.
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
		Prints out all elements.
	**/
	#if !no_tostring
	public function toString():String
	{
		var l = 0, s, d = mData;
		for (i in 0...size)
		{
			s = Std.string(d.get(i));
			l = Std.int(Math.max(s.length, l));
		}
		
		var b = new StringBuf();
		b.add('[ Array2 cols=$cols rows=$rows\n');
		
		var offset, row = 0, args = new Array<Dynamic>();
		var w = MathTools.numDigits(rows);
		for (y in 0...rows)
		{
			args[0] = row++;
			b.add(Printf.format('  %${w}d -> ', args));
			offset = y * cols;
			for (x in 0...cols)
			{
				args[0] = Std.string(d.get(offset + x));
				args[1] = x < cols - 1 ? " | " : "";
				b.add(Printf.format('%${l}s%s', args));
			}
			b.add("\n");
		}
		b.add("]");
		return b.toString();
	}
	#end
	
	/* INTERFACE Collection */
	
	/**
		The number of elements in this two-dimensional array.
		
		Always equals `this.cols` × `this.rows`.
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
		Returns true if this two-dimensional array contains `val`.
	**/
	public function contains(val:T):Bool
	{
		var d = mData;
		for (i in 0...size)
		{
			if (d.get(i) == val)
				return true;
		}
		return false;
	}
	
	/**
		Nullifies all occurrences of `val`.
		The size is not altered.
		@return true if at least one occurrence of `val` was nullified.
	**/
	public function remove(val:T):Bool
	{
		var found = false, d = mData;
		for (i in 0...size)
		{
			if (d.get(i) == val)
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
		mData.nullify();
	}
	
	/**
		Returns a new *Array2Iterator* object to iterate over all elements contained in this two-dimensional array.
		
		Order: Row-major order (row-by-row).
		
		@see http://haxe.org/ref/iterators
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
		Unsupported operation; always returns false.
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
		return mData.toArray(0, size, []);
	}
	
	/**
		Creates and returns a shallow copy (structure only - default) or deep copy (structure & elements) of this two-dimensional array.
		
		If `byRef` is true, primitive elements are copied by value whereas objects are copied by reference.
		
		If `byRef` is false, the `copier` function is used for copying elements. If omitted, `clone()` is called on each element assuming all elements implement `Cloneable`.
	**/
	public function clone(byRef:Bool = true, copier:T->T = null):Collection<T>
	{
		var out = new Array2<T>(mW, mH);
		var src = mData;
		var dst = out.mData;
		
		if (byRef)
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
	
	@:extern public inline function equals(other:Array2Cell):Bool
	{
		return x == other.x && y == other.y;
	}
	
	@:extern public inline function set(x:Int, y:Int):Array2Cell
	{
		this.x = x;
		this.y = y;
		return this;
	}
	
	@:extern public inline function of(other:Array2Cell):Array2Cell
	{
		x = other.x;
		y = other.y;
		return this;
	}
	
	#if !no_tostring
	public function toString():String
	{
		return ('[object Array2Cell $x,$y]');
	}
	#end
}