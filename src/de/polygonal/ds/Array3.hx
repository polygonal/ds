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
	A three-dimensional array based on a rectangular sequential array
	
	_<o>Worst-case running time in Big O notation</o>_
**/
#if generic
@:generic
#end
class Array3<T> implements Collection<T>
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
	var mD:Int;
	var mIterator:Array3Iterator<T>;
	
	/**
		Creates a three-dimensional array with dimensions `width`, `height` and `depth`.
		
		The minimum size is 2x2x2.
		<assert>invalid `width`, `height` or `depth`</assert>
	**/
	public function new(width:Int, height:Int, depth:Int)
	{
		assert(width >= 2 && height >= 2 && depth >= 2, 'invalid size (width: $width, height: $height, depth: $depth)');
		
		mW = width;
		mH = height;
		mD = depth;
		mData = new Vector<T>(size());
		mIterator = null;
		key = HashKey.next();
		reuseIterator = false;
	}
	
	/**
		Returns the element that is stored in column `x`, row `y` and layer `z`.
		<o>1</o>
		<assert>`x`/`y`/`z` out of range</assert>
	**/
	inline public function get(x:Int, y:Int, z:Int):T
	{
		assert(x >= 0 && x < getW(), 'x index out of range ($x)');
		assert(y >= 0 && y < getH(), 'y index out of range ($y)');
		assert(z >= 0 && z < getD(), 'z index out of range ($z)');
		
		return _get(getIndex(x, y, z));
	}
	
	/**
		Returns the element that is stored in column cell.`x`, row cell.`y` and layer cell.`z`.
		<o>1</o>
		<assert>`x`/`y`/`z` out of range</assert>
	**/
	inline public function getAt(cell:Array3Cell):T
	{
		return _get(getIndex(cell.x, cell.y, cell.z));
	}
	
	/**
		Replaces the element at column `x`, row `y` and layer `z` with `val`.
		<o>1</o>
		<assert>`x`/`y`/`z` out of range</assert>
	**/
	inline public function set(x:Int, y:Int, z:Int, val:T)
	{
		assert(x >= 0 && x < getW(), 'x index out of range ($x)');
		assert(y >= 0 && y < getH(), 'y index out of range ($y)');
		assert(z >= 0 && z < getD(), 'z index out of range ($z)');
		
		_set(getIndex(x, y, z), val);
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
		resize(x, mH, mD);
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
		resize(mW, x, mD);
	}
	
	/**
		The depth (#layers).
		<o>1</o>
	**/
	inline public function getD():Int
	{
		return mD;
	}
	
	/**
		Sets the depth to `x`.
		
		The minimum value is 2.
		<o>1</o>
		<assert>invalid height</assert>
	**/
	inline public function setD(x:Int)
	{
		resize(mW, mH, x);
	}
	
	/**
		Computes an index into the linear array from the `x`, `y` and `z` index.
		<o>1</o>
	**/
	inline public function getIndex(x:Int, y:Int, z:Int):Int
	{
		return (z * mW * mH) + (y * mW) + x;
	}
	
	/**
		Returns the index of the first occurrence of the element `x` or returns -1 if element `x` does not exist.
		
		The index is in the range [0, ``size()`` - 1].
		<o>n</o>
	**/
	public function indexOf(x:T):Int
	{
		var i = 0;
		var j = size();
		while (i < j)
		{
			if (_get(i) == x) break;
			i++;
		}
		
		return (i == j) ? -1 : i;
	}
	
	/**
		Returns true if `x`, `y` and `z` are valid indices.
	**/
	inline public function inRange(x:Int, y:Int, z:Int):Bool
	{
		return x >= 0 && x < mW && y >= 0 && y < mH && z >= 0 && z < mD;
	}
	
	/**
		Returns the cell coordinates of the first occurrence of the element `x` or null if element `x` does not exist.
		<o>n</o>
		<assert>`output` is null</assert>
		@param output stores the result.
		@return a reference to `output`.
	**/
	inline public function cellOf(x:T, output:Array3Cell):Array3Cell
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
	inline public function indexToCell(i:Int, output:Array3Cell):Array3Cell
	{
		assert(i >= 0 && i < size(), 'index out of range ($i)');
		assert(output != null, "output is null");
		
		var s = mW * mH;
		var t = i % s;
		output.z = Std.int(i / s);
		output.y = Std.int(t / mW);
		output.x = t % mW;
		return output;
	}
	
	/**
		Computes an array index into the linear array from the `cell` coordinates.
		<o>1</o>
		<assert>`cell` index out of range or `cell` is null</assert>
	**/
	inline public function cellToIndex(cell:Array3Cell):Int
	{
		assert(cell != null);
		assert(cell.x >= 0 && cell.x < getW(), 'x index out of range (${cell.x})');
		assert(cell.y >= 0 && cell.y < getH(), 'y index out of range (${cell.y})');
		assert(cell.z >= 0 && cell.z < getD(), 'z index out of range (${cell.z})');
		
		return getIndex(cell.x, cell.y, cell.z);
	}
	
	/**
		Copies all elements stored in layer `z` by reference into a two-dimensional array.
		<o>n</o>
		<assert>`z` out of range</assert>
		<assert>invalid layer or `output` is null or `output` too small</assert>
		@param output stores the "slice" of this three-dimensional array.
		@return a reference to `output`.
	**/
	public function getLayer(z:Int, output:Array2<T>):Array2<T>
	{
		assert(z >= 0 && z < getD(), 'z index out of range ($z)');
		assert(output != null);
		assert(output.getW() == getW() && output.getH() == getH(), 'output too small (w: ${output.getW()}, d: ${output.getH()})');
		
		var offset = z * mW * mH;
		for (x in 0...mW)
			for (y in 0...mH)
				output.set(x, y, _get(offset + (y * mW) + x));
		return output;
	}
	
	/**
		Copies all elements stored in row `y` and layer `z` by reference to the `output` array.
		<o>n</o>
		<assert>`x`/`y` out of range or `output` is null</assert>
		@return a reference to the `output` array.
	**/
	public function getRow(z:Int, y:Int, output:Array<T>):Array<T>
	{
		assert(y >= 0 && y < getH(), 'y index out of range ($y)');
		assert(z >= 0 && z < getD(), 'z index out of range ($z)');
		assert(output != null);
		
		var offset = (z * mW * mH) + (y * mW);
		for (x in 0...mW) output.push(_get(offset + x));
		return output;
	}
	
	/**
		Overwrites all elements in row `y` and layer `z` with the elements stored in the `input` array.
		<o>n</o>
		<assert>`z`/`y` out of range</assert>
		<assert>`input` is null or insufficient input values</assert>
	**/
	public function setRow(z:Int, y:Int, input:Array<T>)
	{
		assert(y >= 0 && y < getH(), 'y index out of range ($y)');
		assert(z >= 0 && z < getD(), 'z index out of range ($z)');
		assert(input != null, "input is null");
		assert(input.length >= size(), "insufficient values");
		
		var offset = (z * mW * mH) + (y * mW);
		for (x in 0...mW) _set(offset + x, input[x]);
	}
	
	/**
		Copies all elements stored in column `x` and layer `z` by reference to the `output` array.
		<o>n</o>
		<assert>`z`/`x` out of range</assert>
		<assert>`output` is null</assert>
		@return a reference to the `output` array.
	**/
	public function getCol(z:Int, x:Int, output:Array<T>):Array<T>
	{
		assert(x >= 0 && x < getW(), 'x index out of range (${x})');
		assert(z >= 0 && z < getD(), 'z index out of range (${z})');
		assert(output != null);
		
		var offset = z * mW * mH;
		for (i in 0...mH) output.push(_get(offset + (i * mW + x)));
		return output;
	}

	/**
		Overwrites all elements in column `x` and layer `z` with the elements stored in the `input` array.
		<o>n</o>
		<assert>`z`/`x` out of range</assert>
		<assert>`input` is null or insufficient input values</assert>
	**/
	public function setCol(z:Int, x:Int, input:Array<T>)
	{
		assert(x >= 0 && x < getW(), 'x index out of range ($x)');
		assert(z >= 0 && z < getD(), 'z index out of range ($z)');
		assert(input != null, "input is null");
		assert(input.length >= getH(), "insufficient values");
		
		var offset = z * mW * mH;
		for (i in 0...mH) _set(offset + (i * mW + x), input[i]);
	}
	
	/**
		Copies all elements stored in the pile at column `x` and row `y` by reference to the `output` array.
		<o>n</o>
		<assert>`x`/`y` out of range</assert>
		<assert>`output` is null</assert>
		@return a reference to the `output` array.
	**/
	public function getPile(x:Int, y:Int, output:Array<T>):Array<T>
	{
		assert(x >= 0 && x < getW(), 'x index out of range ($x)');
		assert(y >= 0 && y < getH(), 'y index out of range ($y)');
		assert(output != null);
		
		var offset1 = mW * mH;
		var offset2 = (y * mW + x);
		for (z in 0...mD) output.push(_get(z * offset1 + offset2));
		return output;
	}
	
	/**
		Overwrites all elements in column `x` and row `y` with the elements stored in the `input` array.
		<o>n</o>
		<assert>`x`/`y` out of range</assert>
		<assert>`input` is null or insufficient input values</assert>
	**/
	public function setPile(x:Int, y:Int, input:Array<T>)
	{
		assert(x >= 0 && x < getW(), 'x index out of range ($x)');
		assert(y >= 0 && y < getH(), 'y index out of range ($y)');
		assert(input != null, "input is null");
		assert(input.length >= getD(), "insufficient values");
		
		var offset1 = mW * mH;
		var offset2 = (y * mW + x);
		for (z in 0...mD)
			_set(z * offset1 + offset2, input[z]);
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
	public function fill(x:T):Array3<T>
	{
		for (i in 0...size()) _set(i, x);
		return this;
	}
	
	/**
		Invokes the `process` function for each element.
		
		The function signature is: ``process(oldValue, xIndex, yIndex, zIndex):newValue``
		<o>n</o>
	**/
	public function iter(process:T->Int->Int->Int->T)
	{
		for (z in 0...mD)
		{
			for (y in 0...mH)
			{
				for (x in 0...mW)
				{
					var i = z * mW * mH + y * mW + x;
					_set(i, process(_get(i), x, y, z));
				}
			}
		}
	}
	
	/**
		Resizes this three-dimensional array.
		<o>n</o>
		<assert>invalid dimensions</assert>
		@param width the new width (minimum is 2).
		@param height the new height (minimum is 2).
		@param depth the new depth (minimum is 2).
	**/
	public function resize(width:Int, height:Int, depth:Int)
	{
		assert(width >= 2 && height >= 2 && depth >= 1, 'invalid size (width:$width, height:$height, depth: $depth)');
		
		if (width == mW && height == mH && depth == mD) return;
		var t = mData;
		mData = new Vector<T>(width * height * depth);
		
		var minX = width < mW ? width : mW;
		var minY = height < mH ? height : mH;
		var zmin = depth < mD ? depth : mD;
		
		for (z in 0...zmin)
		{
			var t1 = z * width * height;
			var t2 = z * mW * mH;
			
			for (y in 0...minY)
			{
				var t3 = y * width;
				var t4 = y * mW;
				
				for (x in 0...minX)
					_set(t1 + t3 + x, t[t2 + t4 + x]);
			}
		}
		
		mW = width;
		mH = height;
		mD = depth;
	}
	
	/**
		Swaps the element at column/row/layer `x0`, `y0`, `z0` with the element at column/row/layer `x1`, `y1`, `z1`.
		<o>1</o>
		<assert>`x0`/`y0`/`z0` or `x1`/`y1`/`z1` out of range</assert>
		<assert>`x0`, `y0`, `z0` equals `x1`, `y1`, `z1`</assert>
	**/
	inline public function swap(x0:Int, y0:Int, z0:Int, x1:Int, y1:Int, z1:Int)
	{
		assert(x0 >= 0 && x0 < getW(), 'x0 index out of range ($x0)');
		assert(y0 >= 0 && y0 < getH(), 'y0 index out of range ($y0)');
		assert(z0 >= 0 && z0 < getD(), 'z0 index out of range ($z0)');
		assert(x1 >= 0 && x1 < getW(), 'x1 index out of range ($x1)');
		assert(y1 >= 0 && y1 < getH(), 'y1 index out of range ($y1)');
		assert(z1 >= 0 && z1 < getD(), 'z1 index out of range ($z1)');
		assert(!(x0 == x1 && y0 == y1 && z0 == z1), 'source indices equal target indices (x: $x0, y: $y0, z: $z0)');
		
		var i = (z0 * mW * mH) + (y0 * mW) + x0;
		var j = (z1 * mW * mH) + (y1 * mW) + x1;
		var t = _get(i);
		_set(i, _get(j));
		_set(j, t);
	}
	
	/**
		Grants access to the rectangular sequential array storing the elements of this three-dimensional array.
		
		Useful for fast iteration or low-level operations.
		<o>1</o>
	**/
	inline public function getStorage():Vector<T>
	{
		return mData;
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
				_set(i,  t);
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
		Returns a string representing the current object.
		
		Use ``getLayer()`` to print the elements of a specific layer.
		
		Example:
		<pre class="prettyprint">
		var array3 = new de.polygonal.ds.Array3<String>(4, 4, 3);
		trace(array3);</pre>
		<pre class="console">
		{ Array3 4x4x3 }
		</pre>
	**/
	public function toString():String
	{
		return '{ Array3 ${getW()}x${getH()}x${getD()} }';
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
		Returns true if this three-dimensional array contains the element `x`.
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
		@return true if at least one occurrence of `x` is nullified.
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
		Clears this three-dimensional array by nullifying all elements.
		
		The `purge` parameter has no effect.
		<o>1 or n if `purge` is true</o>
	**/
	inline public function clear(purge = false)
	{
		for (i in 0...size()) _set(i, cast null);
	}
	
	/**
		Returns a new `Array3Iterator` object to iterate over all elements contained in this three-dimensional array.
		
		Order: Row-major order (layer-by-layer, row-by-row).
		
		See <a href="http://haxe.org/ref/iterators" target="mBlank">http://haxe.org/ref/iterators</a>
	**/
	public function iterator():Itr<T>
	{
		if (reuseIterator)
		{
			if (mIterator == null)
				mIterator = new Array3Iterator<T>(this);
			else
				mIterator.reset();
			return mIterator;
		}
		else
			return new Array3Iterator<T>(this);
	}
	
	/**
		The number of elements in this three-dimensional array.
		
		Always equals ``getW()`` * ``getH()`` * ``getD()``.
		<o>1</o>
	**/
	inline public function size():Int
	{
		return mW * mH * mD;
	}
	
	/**
		<warn>Unsupported operation - always returns false.</warn>
	**/
	public function isEmpty():Bool
	{
		return false;
	}
	
	/**
		Returns an array containing all elements in this three-dimensional array.
		
		Order: Row-major order (layer-by-layer, row-by-row).
	**/
	public function toArray():Array<T>
	{
		var a:Array<T> = ArrayUtil.alloc(size());
		for (i in 0...size())
			a[i] = _get(i);
		return a;
	}
	
	/**
		Returns a `Vector<T>` object containing all elements in this three-dimensional array.
		
		Order: Row-major order (row-by-row).
	**/
	public function toVector():Vector<T>
	{
		var v = new Vector<T>(size());
		for (i in 0...size()) v[i] = _get(i);
		return v;
	}
	
	/**
		Duplicates this three-dimensional array. Supports shallow (structure only) and deep copies (structure & elements).
		<assert>element is not of type `Cloneable`</assert>
		@param assign if true, the `copier` parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.
		If false, the ``clone()`` method is called on each element.
		<warn>In this case all elements have to implement `Cloneable`.</warn>
		@param copier a custom function for copying elements. Replaces ``element::clone()`` if `assign` is false.
	**/
	public function clone(assign = true, copier:T->T = null):Collection<T>
	{
		var copy = new Array3<T>(getW(), getH(), getD());
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
@:access(de.polygonal.ds.Array3)
@:dox(hide)
class Array3Iterator<T> implements de.polygonal.ds.Itr<T>
{
	var mStructure:Array3<T>;
	var mData:Vector<T>;
	var mI:Int;
	var mS:Int;
	
	public function new(f:Array3<T>)
	{
		mStructure = f;
		reset();
	}
	
	inline public function reset():Itr<T>
	{
		mData = mStructure.mData;
		mS = mStructure.mW * mStructure.mH * mStructure.mD;
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
	Stores the x,y,z position of a three-dimensional cell
**/
class Array3Cell
{
	/**
		The column index.
	**/
	public var x:Int;
	
	/**
		The row index.
	**/
	public var y:Int;
	
	/**
		The depth index.
	**/
	public var z:Int;
	
	public function new(x = 0, y = 0, z = 0)
	{
		this.x = x;
		this.y = y;
		this.z = z;
	}
}