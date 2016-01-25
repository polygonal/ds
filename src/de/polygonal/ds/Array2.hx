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

import de.polygonal.ds.Array2.Array2Cell;
import de.polygonal.ds.error.Assert.assert;

/**
	A two-dimensional array based on a rectangular sequential array
	
	_<o>Worst-case running time in Big O notation</o>_
**/
#if generic
@:generic
#end
class Array2<T> implements Collection<T>
{
	/**
		A unique identifier for this object.
		
		A hash table transforms this key into an index of an array element by using a hash function.
		
		<warn>This value should never be changed by the user.</warn>
	**/
	public var key:Int;
	
	/**
		If true, reuses the iterator object instead of allocating a new one when calling ``iterator()``.
		
		The default is false.
		
		<warn>If true, nested iterations are likely to fail as only one iteration is allowed at a time.</warn>
	**/
	public var reuseIterator:Bool;
	
	var mData:Vector<T>;
	var mW:Int;
	var mH:Int;
	var mIterator:Array2Iterator<T>;
	
	/**
		Creates a two-dimensional array with dimensions `width` and `height`.
		
		The minimum size is 2x2.
		<assert>invalid `width` or `height`</assert>
	**/
	public function new(width:Int, height:Int)
	{
		assert(width >= 2 && height >= 2, 'invalid size (width:$width, height:$height)');
		
		mW = width;
		mH = height;
		mData = new Vector(size());
		mIterator = null;
		key = HashKey.next();
		reuseIterator = false;
	}
	
	/**
		Returns the element that is stored in column `x` and row `y`.
		<o>1</o>
		<assert>`x`/`y` out of range</assert>
	**/
	inline public function get(x:Int, y:Int):T
	{
		assert(x >= 0 && x < getW(), 'x index out of range ($x)');
		assert(y >= 0 && y < getH(), 'y index out of range ($y)');
		
		return _get(getIndex(x, y));
	}
	
	/**
		Returns the element that is stored in column ``cell::x`` and row ``cell::y``.
		<o>1</o>
		<assert>`cell` is null</assert>
		<assert>`x`/`y` out of range</assert>
	**/
	inline public function getAtCell(cell:Array2Cell):T
	{
		assert(cell != null, "cell is null");
		
		return _get(getIndex(cell.x, cell.y));
	}
	
	/**
		Replaces the element at column `x` and row `y` with `val`.
		<o>1</o>
		<assert>`x`/`y` out of range</assert>
	**/
	inline public function set(x:Int, y:Int, val:T)
	{
		assert(x >= 0 && x < getW(), 'x index out of range ($x)');
		assert(y >= 0 && y < getH(), 'y index out of range ($y)');
		
		_set(getIndex(x, y), val);
	}
	
	/**
		Returns the element at index `i`.
		<o>1</o>
		<assert>`i` out of range</assert>
	**/
	inline public function getAtIndex(i:Int):T
	{
		assert(i >= 0 && i < size(), 'index out of range ($i)');
		
		return _get(getIndex(i % mW, Std.int(i / mW)));
	}
	
	/**
		Replaces the element that is stored in column ``cell::x`` and row ``cell::y`` with `val`.
		<o>1</o>
		<assert>`cell` is null</assert>
		<assert>`x`/`y` out of range</assert>
	**/
	inline public function setAtCell(cell:Array2Cell, val:T)
	{
		assert(cell != null, "cell is null");
		
		return _set(getIndex(cell.x, cell.y), val);
	}
	
	/**
		Replaces the element at index `i` with `val`.
		<o>1</o>
		<assert>`i` out of range</assert>
	**/
	inline public function setAtIndex(i:Int, val:T)
	{
		assert(i >= 0 && i < size(), 'index out of range ($i)');
		
		_set(getIndex(i % mW, Std.int(i / mW)), val);
	}
	
	/**
		The width (#columns).
		<o>1</o>
	**/
	inline public function getW():Int
	{
		return mW;
	}
	
	/**
		Sets the width to `x`.
		
		The minimum value is 2.
		<o>1</o>
		<assert>invalid width</assert>
	**/
	inline public function setW(x:Int)
	{
		resize(x, mH);
	}
	
	/**
		The height (#rows).
		<o>1</o>
	**/
	inline public function getH():Int
	{
		return mH;
	}
	
	/**
		Sets the height to `x`.
		
		The minimum value is 2.
		<o>1</o>
		<assert>invalid height</assert>
	**/
	inline public function setH(x:Int)
	{
		resize(mW, x);
	}
	
	/**
		Computes an index into the linear array from the `x` and `y` index.
		<o>1</o>
	**/
	inline public function getIndex(x:Int, y:Int):Int
	{
		return y * mW + x;
	}
	
	/**
		Returns the index of the first occurrence of the element `x` or returns -1 if element `x` does not exist.
		
		The index is in the range [0, ``size()`` - 1].
		<o>n</o>
	**/
	public function indexOf(x:T):Int
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
		Returns true if `x` and `y` are valid indices.
	**/
	inline public function inRange(x:Int, y:Int):Bool
	{
		return x >= 0 && x < mW && y >= 0 && y < mH;
	}
	
	/**
		Returns the cell coordinates of the first occurrence of the element `x` or null if element `x` does not exist.
		<o>n</o>
		<assert>`output` is null</assert>
		@param output stores the result.
		@return a reference to `output`.
	**/
	inline public function cellOf(x:T, output:Array2Cell):Array2Cell
	{
		assert(output != null);
		
		var i = indexOf(x);
		if (i == -1)
			return null;
		else
			return indexToCell(i, output);
	}
	
	/**
		Transforms the index `i` into `output` coordinates.
		<o>1</o>
		<assert>`i` out of range</assert>
		<assert>`output` is null</assert>
		@param output stores the result.
		@return a reference to `output`.
	**/
	inline public function indexToCell(i:Int, output:Array2Cell):Array2Cell
	{
		assert(i >= 0 && i < size(), 'index out of range ($i)');
		assert(output != null, "output is null");
		
		output.y = Std.int(i / mW);
		output.x = i % mW;
		return output;
	}
	
	/**
		Computes an array index into the linear array from the `cell` coordinates.
		<o>1</o>
		<assert>`cell` index out of range</assert>
		<assert>`cell` is null</assert>
	**/
	inline public function cellToIndex(cell:Array2Cell):Int
	{
		assert(cell != null);
		assert(cell.x >= 0 && cell.x < getW(), 'x index out of range (${cell.x})');
		assert(cell.y >= 0 && cell.y < getH(), 'y index out of range (${cell.y})');
		
		return getIndex(cell.x, cell.y);
	}
	
	/**
		Copies all elements stored in row `y` by reference to the `output` array.
		<o>n</o>
		<assert>`y` out of range</assert>
		<assert>`output` is null</assert>
		@return a reference to the `output` array.
	**/
	public function getRow(y:Int, output:Array<T>):Array<T>
	{
		assert(y >= 0 && y < getH(), 'y index out of range ($y)');
		assert(output != null, "output is null");
		
		var offset = y * mW;
		for (x in 0...mW)
			output[x] = _get(offset + x);
		return output;
	}
	
	/**
		Overwrites all elements in row `y` with the elements stored in the `input` array.
		<o>n</o>
		<assert>`y` out of range or `input` is null or insufficient input values</assert>
	**/
	public function setRow(y:Int, input:Array<T>)
	{
		assert(y >= 0 && y < getH(), 'y index out of range ($y)');
		assert(input != null, "input is null");
		assert(input.length >= getW(), "insufficient input values");
		
		var offset = y * mW;
		for (x in 0...mW)
			_set(offset + x, input[x]);
	}
	
	/**
		Copies all elements stored in column `x` by reference to the `output` array.
		<o>n</o>
		<assert>`x` out of range</assert>
		<assert>`output` is null</assert>
		@return a reference to the `output` array.
	**/
	public function getCol(x:Int, output:Array<T>):Array<T>
	{
		assert(x >= 0 && x < getW(), 'x index out of range ($x)');
		assert(output != null, "output is null");
		
		for (i in 0...mH)
			output[i] = _get(i * mW + x);
		return output;
	}
	
	/**
		Overwrites all elements in column `x` with the elements stored in the `input` array.
		<o>n</o>
		<assert>`x` out of range</assert>
		<assert>`input` is null or insufficient input values</assert>
	**/
	public function setCol(x:Int, input:Array<T>)
	{
		assert(x >= 0 && x < getW(), 'x index out of range ($x)');
		assert(input != null, "input is null");
		assert(input.length >= getH(), "insufficient input values");
		
		for (y in 0...mH)
			_set(getIndex(x, y), input[y]);
	}
	
	/**
		Replaces all existing elements with objects of type `cl`.
		<o>n</o>
		@param cl the class to instantiate for each element.
		@param args passes additional constructor arguments to the class `cl`.
	**/
	public function assign(cl:Class<T>, args:Array<Dynamic> = null)
	{
		if (args == null) args = [];
		for (i in 0...size()) _set(i, Type.createInstance(cl, args));
	}
	
	/**
		Replaces all existing elements with the instance `x`.
		<o>n</o>
	**/
	public function fill(x:T):Array2<T>
	{
		for (i in 0...size()) _set(i, x);
		return this;
	}
	
	/**
		Invokes the `process` function for each element.
		
		The function signature is: ``process(oldValue, xIndex, yIndex):newValue``
		<o>n</o>
	**/
	public function iter(process:T->Int->Int->T)
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
		Resizes this two-dimensional array.
		<o>n</o>
		<assert>invalid dimensions</assert>
		@param width the new width (minimum is 2).
		@param height the new height (minimum is 2).
	**/
	public function resize(width:Int, height:Int)
	{
		assert(width >= 2 && height >= 2, 'invalid size (width:$width, height:$height)');
		
		if (width == mW && height == mH) return;
		var t = mData;
		mData = new Vector(width * height);
		
		var minX = width < mW ? width : mW;
		var minY = height < mH ? height : mH;
		
		for (y in 0...minY)
		{
			var t1 = y * width;
			var t2 = y * mW;
			for (x in 0...minX)
				_set(t1 + x, t[t2 + x]);
		}
		
		mW = width;
		mH = height;
	}
	
	/**
		Shifts all columns to the west by one position.
		
		Columns are wrapped so the column at index 0 is not lost but appended to the rightmost column.
		<o>n</o>
	**/
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
		Shifts all columns to the east by one position.
		
		Columns are wrapped, so the column at index [``getW()`` - 1] is not lost but prepended to the leftmost column.
		<o>n</o>
	**/
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
		Shifts all rows to the north by one position.
		
		Rows are wrapped, so the row at index 0 is not lost but appended to the bottommost row.
		<o>n</o>
	**/
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
		Shifts all rows to the south by one position.
		
		Rows are wrapped, so row at index [``getH()`` - 1] is not lost but prepended to the topmost row.
		<o>n</o>
	**/
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
		Swaps the element at column/row `x0`, `y0` with the element at column/row `x1`, `y1`.
		<o>1</o>
		<assert>`x0`/`y0` or `x1`/`y1` out of range</assert>
		<assert>`x0`, `y0` equals `x1`, `y1`</assert>
	**/
	inline public function swap(x0:Int, y0:Int, x1:Int, y1:Int)
	{
		assert(x0 >= 0 && x0 < getW(), 'x0 index out of range ($x0)');
		assert(y0 >= 0 && y0 < getH(), 'y0 index out of range ($y0)');
		assert(x1 >= 0 && x1 < getW(), 'x1 index out of range ($x1)');
		assert(y1 >= 0 && y1 < getH(), 'y1 index out of range ($y1)');
		assert(!(x0 == x1 && y0 == y1), 'source indices equal target indices (x: $x0, y: $y0)');
		
		var i = y0 * mW + x0;
		var j = y1 * mW + x1;
		var t = _get(i);
		_set(i, _get(j));
		_set(j, t);
	}
	
	/**
		Appends the elements of the `input` array in the range [0, ``getW()``] by adding a new row.
		<o>n</o>
		<assert>`input` is null or too short</assert>
	**/
	public function appendRow(input:Array<T>)
	{
		assert(input != null, "input is null");
		assert(input.length >= getW(), "insufficient input values");
		
		var tmp = new Vector<T>(mW * (mH + 1));
		VectorUtil.blit(mData, 0, tmp, 0, mW * mH);
		mData = tmp;
		
		var t = mW * mH++;
		for (i in 0...mW) _set(t + i, input[i]);
	}
	
	/**
		Appends the elements of the `input` array in the range [0, ``getH()``] by adding a new column.
		<o>n</o>
		<assert>`input` is null or too short</assert>
	**/
	public function appendCol(input:Array<T>)
	{
		assert(input != null, "input is null");
		assert(input.length >= getH(), "insufficient input values");
		
		var tmp = new Vector<T>((mW + 1) * mH);
		VectorUtil.blit(mData, 0, tmp, 0, mW * mH);
		mData = tmp;
		
		var l = size() + mH;
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
		Prepends the elements of the `input` array in the range [0, ``getW()``] by adding a new row.
		<o>n</o>
		<assert>`input` is null or too short</assert>
	**/
	public function prependRow(input:Array<T>)
	{
		assert(input != null, "input is null");
		assert(input.length >= getW(), "insufficient input values");
		
		var tmp = new Vector<T>(mW * (mH + 1));
		VectorUtil.blit(mData, 0, tmp, mW, mW * mH);
		mData = tmp;
		
		mH++;
		
		for (i in 0...mW) _set(i, input[i]);
	}
	
	/**
		Prepends the elements of the `input` array in the range [0, ``getH()``] by adding a new column.
		<o>n</o>
		<assert>`input` is null or too short</assert>
	**/
	public function prependCol(input:Array<T>)
	{
		assert(input != null, "input is null");
		assert(input.length >= getH(), "insufficient input values");
		
		var tmp = new Vector<T>((mW + 1) * mH);
		VectorUtil.blit(mData, 0, tmp, 0, mW * mH);
		mData = tmp;
		
		var l = size() + mH;
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
		Copies row elements from row `i` to row `j`.
		<o>n</o>
		<assert>`i`/`j` out of range</assert>
	**/
	public function copyRow(i:Int, j:Int)
	{
		assert(i >= 0 && i < getH(), 'i index out of range ($i)');
		assert(j >= 0 && j < getH(), 'j index out of range ($j)');
		
		if (i != j)
		{
			var srcOffset = mW * i;
			var dstOffset = mW * j;
			for (x in 0...mW) _set(dstOffset + x, _get(srcOffset + x));
		}
	}
	
	/**
		Swaps row elements at row `i` with row elements at row `j`.
		<o>n</o>
		<assert>`i`/`j` out of range</assert>
	**/
	public function swapRow(i:Int, j:Int)
	{
		assert(i >= 0 && i < getH(), 'i index out of range ($i)');
		assert(j >= 0 && j < getH(), 'j index out of range ($j)');
		
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
		Copies column elements from column `i` to column `j`.
		<o>n</o>
		<assert>`i`/`j` out of range</assert>
	**/
	public function copyCol(i:Int, j:Int)
	{
		assert(i >= 0 && i < getW(), 'i index out of range ($i)');
		assert(j >= 0 && j < getW(), 'j index out of range ($j)');
		
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
		Swaps column elements at column `i` with column elements at row `j`.
		<o>n</o>
		<assert>`i`/`j` out of range</assert>
	**/
	public function swapCol(i:Int, j:Int)
	{
		assert(i >= 0 && i < getW(), 'i index out of range ($i)');
		assert(j >= 0 && j < getW(), 'j index out of range ($j)');
		
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
		Transposes this two-dimensional array.
		<o>n</o>
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
			var t = new Vector(mW * mH);
			for (y in 0...mH)
				for (x in 0...mW)
					t[x * mH + y] = get(x, y);
			mData = t;
			mW ^= mH;
			mH ^= mW;
			mW ^= mH;
		}
	}
	
	/**
		Grants access to the rectangular sequential array storing the elements of this two-dimensional array.
		
		Useful for fast iteration or low-level operations.
		<o>1</o>
	**/
	inline public function getStorage():Vector<T>
	{
		return mData;
	}
	
	/**
		Copies all elements from the nested two-dimensional array `a` into this two-dimensional array.
		<assert>invalid dimensions of `a`</assert>
	**/
	public function ofNestedArray(a:Array<Array<T>>)
	{
		assert(a.length == getH() && a[0] != null && a[0].length == getW(), "invalid input");
		
		var w = a[0].length;
		for (y in 0...a.length)
		{
			var row = a[y];
			for (x in 0...w)
				_set(getIndex(x, y), row[x]);
		}
	}
	
	/**
		Shuffles the elements of this collection by using the Fisher-Yates algorithm.
		<o>n</o>
		<assert>insufficient random values</assert>
		@param rval a list of random double values in the range between 0 (inclusive) to 1 (exclusive) defining the new positions of the elements.
		If omitted, random values are generated on-the-fly by calling `Math::random()`.
	**/
	public function shuffle(rval:Array<Float> = null)
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
			assert(rval.length >= size(), "insufficient random values");
			
			var j = 0;
			while (--s > 1)
			{
				var i = Std.int(rval[j++] * s);
				var t = _get(s);
				_set(s, _get(i));
				_set(i, t);
			}
		}
	}
	
	/**
		Copies all elements inside the rectangular region bounded by [`minX`, `minY`] and [`maxX`, `maxY`] by reference to the `output` array.
		<o>n</o>
		<assert>`minX` or `minY` out of range</assert>
		@return a reference to the `output` array.
	**/
	public function getRect(minX:Int, minY:Int, maxX:Int, maxY:Int, output:Array<T>):Array<T>
	{
		assert(minX <= maxX, 'minX index out of range ($minX)');
		assert(minY <= maxY, 'minY index out of range ($minY)');
		
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
		var l = 0;
		for (i in 0...size())
		{
			var s = Std.string(_get(i));
			l = Std.int(Math.max(s.length, l));
		}
		var s = '{ Array2 ${mW}x${mH} }';
		s += "\n[\n";
		
		var offset, value;
		var row = 0;
		for (y in 0...mH)
		{
			s += Printf.format("%- 4d: ", [row++]);
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
		Destroys this object by explicitly nullifying all elements for GC'ing used resources.
		
		Improves GC efficiency/performance (optional).
		<o>n</o>
	**/
	public function free()
	{
		for (i in 0...size()) _set(i, cast null);
		mData = null;
		mIterator = null;
	}
	
	/**
		Returns true if this two-dimensional array contains the element `x`.
		<o>n</o>
	**/
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
		Nullifies all occurrences of `x`.
		The size is not altered.
		<o>n</o>
		@return true if at least one occurrence of `x` was nullified.
	**/
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
		Clears this two-dimensional array by nullifying all elements.
		
		The `purge` parameter has no effect.
		<o>1 or n if `purge` is true</o>
	**/
	public function clear(purge = false)
	{
		for (i in 0...size()) _set(i, cast null);
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
		The number of elements in this two-dimensional array.
		
		Always equals ``getW()`` * ``getH()``.
		<o>1</o>
	**/
	inline public function size():Int
	{
		return mW * mH;
	}
	
	/**
		<warn>Unsupported operation - always returns false.</warn>
		<o>1</o>
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
		var a:Array<T> = ArrayUtil.alloc(size());
		for (i in 0...size())
			a[i] = _get(i);
		return a;
	}
	
	/**
		Returns a `Vector<T>` object containing all elements in this two-dimensional array.
		
		Order: Row-major order (row-by-row).
	**/
	public function toVector():Vector<T>
	{
		var v = new Vector<T>(size());
		for (i in 0...size()) v[i] = _get(i);
		return v;
	}
	
	/**
		Duplicates this two-dimensional array. Supports shallow (structure only) and deep copies (structure & elements).
		<assert>element is not of type `Cloneable`</assert>
		@param assign if true, the `copier` parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.
		If false, the ``clone()`` method is called on each element.
		
		<warn>In this case all elements have to implement `Cloneable`.</warn>
		@param copier a custom function for copying elements. Replaces ``element::clone()`` if `assign` is false.
	**/
	public function clone(assign = true, copier:T->T = null):Collection<T>
	{
		var copy = new Array2<T>(mW, mH);
		if (assign)
		{
			for (i in 0...size())
				copy._set(i, _get(i));
		}
		else
		if (copier == null)
		{
			var c:Cloneable<Dynamic> = null;
			for (i in 0...size())
			{
				assert(Std.is(_get(i), Cloneable), 'element is not of type Cloneable (${_get(i)})');
				
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
	
	inline function _get(i:Int) return mData[i];
	
	inline function _set(i:Int, x:T) mData[i] = x;
}

#if generic
@:generic
#end
@:access(de.polygonal.ds.Array2)
@:dox(hide)
class Array2Iterator<T> implements de.polygonal.ds.Itr<T>
{
	var mStructure:Array2<T>;
	var mData:Vector<T>;
	var mI:Int;
	var mS:Int;
	
	public function new(f:Array2<T>)
	{
		mStructure = f;
		reset();
	} 
	
	inline public function reset():Itr<T>
	{
		mData = mStructure.mData;
		mS = mStructure.mW * mStructure.mH;
		mI = 0;
		return this;
	}
	
	inline public function hasNext():Bool
	{
		return mI < mS;
	}
	
	inline public function next():T
	{
		return mData[mI++];
	}
	
	inline public function remove()
	{
		//just nullify value
		assert(mI > 0, "call next() before removing an element");
		mData[mI - 1] = cast null;
	}
}

/**
	Stores the x,y position of a two-dimensional cell
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
	
	public function new(x = 0, y = 0)
	{
		this.x = x;
		this.y = y;
	}
}