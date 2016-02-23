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

import de.polygonal.ds.tools.Assert.assert;
import de.polygonal.ds.tools.M;

using de.polygonal.ds.tools.NativeArrayTools;

/**
	A three-dimensional array based on a rectangular sequential array
**/
#if generic
@:generic
#end
class Array3<T> implements Collection<T>
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
		resize(val, mH, mD);
		return val;
	}
	
	/**
		The height (#rows).
		The minimum value is 2.
		<assert>invalid width</assert>
	**/
	public var height(get, set):Int;
	inline function get_height():Int
	{
		return mH;
	}
	function set_height(val:Int):Int
	{
		resize(mW, val, mD);
		return val;
	}
	
	/**
		The depth (#layers).
		The minimum value is 2.
		<assert>invalid depth</assert>
	**/
	public var depth(get, set):Int;
	inline function get_depth():Int
	{
		return mD;
	}
	function set_depth(val:Int):Int
	{
		resize(mW, mH, val);
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
	var mD:Int;
	var mIterator:Array3Iterator<T> = null;
	
	/**
		Creates a three-dimensional array with dimensions `width`, `height` and `depth`.
		
		The minimum size is 2x2x2.
		<assert>invalid `width`, `height` or `depth`</assert>
	**/
	public function new(width:Int, height:Int, depth:Int, ?source:Array<T>)
	{
		assert(width >= 2 && height >= 2 && depth >= 2, 'invalid size (width: $width, height: $height, depth: $depth)');
		
		mW = width;
		mH = height;
		mD = depth;
		mData = NativeArrayTools.alloc(size);
		
		if (source != null)
		{
			assert(source.length >= size, "invalid source");
			
			var d = mData;
			for (i in 0...size) d.set(i, source[i]);
		}
	}
	
	/**
		Returns the element that is stored in column `x`, row `y` and layer `z`.
		<assert>`x`/`y`/`z` out of range</assert>
	**/
	public inline function get(x:Int, y:Int, z:Int):T
	{
		assert(x >= 0 && x < cols, 'x index out of range ($x)');
		assert(y >= 0 && y < rows, 'y index out of range ($y)');
		assert(z >= 0 && z < depth, 'z index out of range ($z)');
		
		return mData.get(getIndex(x, y, z));
	}
	
	/**
		Returns the element that is stored in column cell.`x`, row cell.`y` and layer cell.`z`.
		<assert>`x`/`y`/`z` out of range</assert>
	**/
	public inline function getAtCell(cell:Array3Cell):T
	{
		assert(cell != null, "cell is null");
		assert(cell.x >= 0 && cell.x < cols, 'cell.x out of range (${cell.x})');
		assert(cell.y >= 0 && cell.y < rows, 'cell.y out of range (${cell.y})');
		assert(cell.z >= 0 && cell.z < depth, 'cell.z out of range (${cell.z})');
		
		return mData.get(getIndex(cell.x, cell.y, cell.z));
	}
	
	/**
		Replaces the element at column `x`, row `y` and layer `z` with `val`.
		<assert>`x`/`y`/`z` out of range</assert>
	**/
	public inline function set(x:Int, y:Int, z:Int, val:T)
	{
		assert(x >= 0 && x < cols, 'x index out of range ($x)');
		assert(y >= 0 && y < rows, 'y index out of range ($y)');
		assert(z >= 0 && z < depth, 'z index out of range ($z)');
		
		mData.set(getIndex(x, y, z), val);
	}
	
	/**
		Computes an index into the linear array from the `x`, `y` and `z` index.
	**/
	public inline function getIndex(x:Int, y:Int, z:Int):Int
	{
		return (z * mW * mH) + (y * mW) + x;
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
		Returns true if `x`, `y` and `z` are valid indices.
	**/
	public inline function inRange(x:Int, y:Int, z:Int):Bool
	{
		return x >= 0 && x < mW && y >= 0 && y < mH && z >= 0 && z < mD;
	}
	
	/**
		Returns the cell coordinates of the first occurrence of the element `x` or null if element `x` does not exist.
		<assert>`out` is null</assert>
		@param out stores the result.
		@return a reference to `out`.
	**/
	public inline function cellOf(x:T, out:Array3Cell):Array3Cell
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
	public inline function indexToCell(i:Int, out:Array3Cell):Array3Cell
	{
		assert(i >= 0 && i < size, 'index out of range ($i)');
		assert(out != null, "out is null");
		
		var s = mW * mH;
		var t = i % s;
		out.z = Std.int(i / s);
		out.y = Std.int(t / mW);
		out.x = t % mW;
		return out;
	}
	
	/**
		Computes an array index into the linear array from the `cell` coordinates.
		<assert>`cell` index out of range or `cell` is null</assert>
	**/
	public inline function cellToIndex(cell:Array3Cell):Int
	{
		assert(cell != null);
		assert(cell.x >= 0 && cell.x < cols, 'x index out of range (${cell.x})');
		assert(cell.y >= 0 && cell.y < rows, 'y index out of range (${cell.y})');
		assert(cell.z >= 0 && cell.z < depth, 'z index out of range (${cell.z})');
		
		return getIndex(cell.x, cell.y, cell.z);
	}
	
	/**
		Copies all elements stored in layer `z` by reference into a two-dimensional array.
		<assert>`z` out of range</assert>
		<assert>invalid layer or `out` is null or `out` too small</assert>
		@param out stores the "slice" of this three-dimensional array.
		@return a reference to `out`.
	**/
	public function getLayer(z:Int, out:Array2<T>):Array2<T>
	{
		assert(z >= 0 && z < depth, 'z index out of range ($z)');
		assert(out != null);
		assert(out.cols == cols && out.rows == rows, 'out too small (w: ${out.cols}, d: ${out.rows})');
		
		var offset = z * mW * mH, d = mData;
		for (x in 0...mW)
			for (y in 0...mH)
				out.set(x, y, d.get(offset + (y * mW) + x));
		return out;
	}
	
	/**
		Copies all elements stored in row `y` and layer `z` by reference to the `out` array.
		<assert>`x`/`y` out of range or `out` is null</assert>
		@return a reference to the `out` array.
	**/
	public function getRow(z:Int, y:Int, out:Array<T>):Array<T>
	{
		assert(y >= 0 && y < rows, 'y index out of range ($y)');
		assert(z >= 0 && z < depth, 'z index out of range ($z)');
		assert(out != null);
		
		var offset = (z * mW * mH) + (y * mW), d = mData;
		for (x in 0...mW) out[x] = d.get(offset + x);
		return out;
	}
	
	/**
		Overwrites all elements in row `y` and layer `z` with the elements stored in the `input` array.
		<assert>`z`/`y` out of range</assert>
		<assert>`input` is null or insufficient input values</assert>
	**/
	public function setRow(z:Int, y:Int, input:Array<T>)
	{
		assert(y >= 0 && y < rows, 'y index out of range ($y)');
		assert(z >= 0 && z < depth, 'z index out of range ($z)');
		assert(input != null, "input is null");
		assert(input.length >= size, "insufficient values");
		
		var offset = (z * mW * mH) + (y * mW), d = mData;
		for (x in 0...mW) d.set(offset + x, input[x]);
	}
	
	/**
		Copies all elements stored in column `x` and layer `z` by reference to the `out` array.
		<assert>`z`/`x` out of range</assert>
		<assert>`out` is null</assert>
		@return a reference to the `out` array.
	**/
	public function getCol(z:Int, x:Int, out:Array<T>):Array<T>
	{
		assert(x >= 0 && x < cols, 'x index out of range (${x})');
		assert(z >= 0 && z < depth, 'z index out of range (${z})');
		assert(out != null);
		
		var offset = z * mW * mH, d = mData;
		for (y in 0...mH) out[y] = d.get(offset + (y * mW + x));
		return out;
	}

	/**
		Overwrites all elements in column `x` and layer `z` with the elements stored in the `input` array.
		<assert>`z`/`x` out of range</assert>
		<assert>`input` is null or insufficient input values</assert>
	**/
	public function setCol(z:Int, x:Int, input:Array<T>)
	{
		assert(x >= 0 && x < cols, 'x index out of range ($x)');
		assert(z >= 0 && z < depth, 'z index out of range ($z)');
		assert(input != null, "input is null");
		assert(input.length >= rows, "insufficient values");
		
		var offset = z * mW * mH, d = mData;
		for (i in 0...mH) d.set(offset + (i * mW + x), input[i]);
	}
	
	/**
		Copies all elements stored in the pile at column `x` and row `y` by reference to the `out` array.
		<assert>`x`/`y` out of range</assert>
		<assert>`out` is null</assert>
		@return a reference to the `out` array.
	**/
	public function getPile(x:Int, y:Int, out:Array<T>):Array<T>
	{
		assert(x >= 0 && x < cols, 'x index out of range ($x)');
		assert(y >= 0 && y < rows, 'y index out of range ($y)');
		assert(out != null);
		
		var offset1 = mW * mH;
		var offset2 = (y * mW + x);
		var d = mData;
		for (z in 0...mD) out[z] = d.get(z * offset1 + offset2);
		return out;
	}
	
	/**
		Overwrites all elements in column `x` and row `y` with the elements stored in the `input` array.
		<assert>`x`/`y` out of range</assert>
		<assert>`input` is null or insufficient input values</assert>
	**/
	public function setPile(x:Int, y:Int, input:Array<T>)
	{
		assert(x >= 0 && x < cols, 'x index out of range ($x)');
		assert(y >= 0 && y < rows, 'y index out of range ($y)');
		assert(input != null, "input is null");
		assert(input.length >= depth, "insufficient values");
		
		var offset1 = mW * mH;
		var offset2 = (y * mW + x);
		var d = mData;
		for (z in 0...mD)
			d.set(z * offset1 + offset2, input[z]);
	}
	
	/**
		Calls the `f` function on all elements.
		
		The function signature is: `f(element, xIndex, yIndex, zIndex):element`
		<assert>`f` is null</assert>
	**/
	public function forEach(f:T->Int->Int->Int->T, z:Int = -1):Array3<T>
	{
		var w = mW, s = w * mH, invS = 1 / s, invW = 1 / w, t;
		var i, j;
		if (z < 0)
		{
			i = 0;
			j = size;
		}
		else
		{
			i = z * s;
			j = i = s;
		}
		
		var d = mData;
		while (i < j)
		{
			t = i % s;
			d.set(i, f(d.get(i), t % w, Std.int(t * invW), Std.int(i * invS)));
			i++;
		}
		return this;
	}
	
	/**
		Resizes this three-dimensional array.
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
		mData = NativeArrayTools.alloc(width * height * depth);
		
		var minX = width < mW ? width : mW;
		var minY = height < mH ? height : mH;
		var minZ = depth < mD ? depth : mD;
		var t1, t2, t3, t4, d = mData;
		for (z in 0...minZ)
		{
			t1 = z * width * height;
			t2 = z * mW * mH;
			for (y in 0...minY)
			{
				t3 = y * width;
				t4 = y * mW;
				for (x in 0...minX)
					d.set(t1 + t3 + x, t.get(t2 + t4 + x));
			}
		}
		
		mW = width;
		mH = height;
		mD = depth;
	}
	
	/**
		Swaps the element at column/row/layer `x0`, `y0`, `z0` with the element at column/row/layer `x1`, `y1`, `z1`.
		<assert>`x0`/`y0`/`z0` or `x1`/`y1`/`z1` out of range</assert>
		<assert>`x0`, `y0`, `z0` equals `x1`, `y1`, `z1`</assert>
	**/
	public inline function swap(x0:Int, y0:Int, z0:Int, x1:Int, y1:Int, z1:Int)
	{
		assert(x0 >= 0 && x0 < cols, 'x0 index out of range ($x0)');
		assert(y0 >= 0 && y0 < rows, 'y0 index out of range ($y0)');
		assert(z0 >= 0 && z0 < depth, 'z0 index out of range ($z0)');
		assert(x1 >= 0 && x1 < cols, 'x1 index out of range ($x1)');
		assert(y1 >= 0 && y1 < rows, 'y1 index out of range ($y1)');
		assert(z1 >= 0 && z1 < depth, 'z1 index out of range ($z1)');
		assert(!(x0 == x1 && y0 == y1 && z0 == z1), 'source indices equal target indices (x: $x0, y: $y0, z: $z0)');
		
		var i = (z0 * mW * mH) + (y0 * mW) + x0;
		var j = (z1 * mW * mH) + (y1 * mW) + x1;
		var d = mData;
		var t = d.get(i);
		d.set(i, d.get(j));
		d.set(j, t);
	}
	
	/**
		Grants access to the rectangular sequential array storing the elements of this three-dimensional array.
		
		Useful for fast iteration or low-level operations.
	**/
	public inline function getStorage():NativeArray<T>
	{
		return mData;
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
			var m = Math, i, j, t;
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
			
			var i, j = 0, t;
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
		var l = 0, out = [];
		for (y in 0...rows)
		{
			for (x in 0...cols)
			{
				getPile(x, y, out);
				l = M.max(l, out.join(",").length);
			}
		}
		
		var b = new StringBuf();
		b.add('{ Array3 ${cols}x${rows}x${depth} }');
		b.add("\n[\n");
		
		var row = 0, args = new Array<Dynamic>();
		var w = M.numDigits(rows);
		for (y in 0...rows)
		{
			args[0] = row++;
			b.add(Printf.format('  %${w}d: ', args));
			for (x in 0...cols)
			{
				args[0] = getPile(x, y, out).join(",");
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
		The number of elements in this three-dimensional array.
		
		Always equals ``width`` * ``height`` * ``depth``.
	**/
	public var size(get, never):Int;
	inline function get_size():Int
	{
		return mW * mH * mD;
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
		Returns true if this three-dimensional array contains the element `x`.
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
		@return true if at least one occurrence of `x` is nullified.
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
		Clears this three-dimensional array by nullifying all elements.
		
		The `gc` parameter has no effect.
	**/
	public function clear(gc:Bool = false)
	{
		mData.nullify(size);
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
		return mData.toArray(0, size);
	}
	
	/**
		Duplicates this three-dimensional array. Supports shallow (structure only) and deep copies (structure & elements).
		<assert>element is not of type `Cloneable`</assert>
		@param assign if true, the `copier` parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.
		If false, the ``clone()`` method is called on each element.
		<warn>In this case all elements have to implement `Cloneable`.</warn>
		@param copier a custom function for copying elements. Replaces ``element::clone()`` if `assign` is false.
	**/
	public function clone(assign:Bool = true, copier:T->T = null):Collection<T>
	{
		var out = new Array3<T>(mW, mH, mD);
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
@:access(de.polygonal.ds.Array3)
@:dox(hide)
class Array3Iterator<T> implements de.polygonal.ds.Itr<T>
{
	var mObject:Array3<T>;
	var mData:NativeArray<T>;
	var mI:Int;
	var mS:Int;
	
	public function new(x:Array3<T>)
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
	Stores the (x,y,z) position of a three-dimensional cell
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
	
	public function new(x:Int = 0, y:Int = 0, z:Int = 0)
	{
		this.x = x;
		this.y = y;
		this.z = z;
	}
}