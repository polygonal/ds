/*
Copyright (c) 2014 Michael Baczynski, http://www.polygonal.de

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
	<h3>An array divided into several virtual *buckets*.<h3>
	
	- Like an array of arrays, but more memory efficient
	- Each bucket is has an initial size
	- Each bucket can grow/shrink independently on demand
**/
#if generic
@:generic
#end
class BucketList<T>
{
	public var numBuckets(default, null):Int;
	
	var mCapacity:Int;
	
	var mData:Vector<T>;
	var mBucketSize:Vector<Int>;
	var mBucketPos:Vector<Int>;
	var mBucketCapacity:Vector<Int>;
	//var mBucketSorted:Vector<Bool>;
	
	var mInitialBucketCapacity:Int;
	
	var mAllowShrink:Bool;
	
	public function new(numBuckets:Int, initialBucketCapacity:Int, allowShrink:Bool = true)
	{
		assert(numBuckets >= 2);
		
		this.numBuckets = numBuckets;
		mInitialBucketCapacity = initialBucketCapacity;
		mCapacity = numBuckets * initialBucketCapacity;
		mAllowShrink = allowShrink;
		mData = new Vector<T>(mCapacity);
		
		mBucketPos = new Vector<Int>(numBuckets);
		mBucketSize = new Vector<Int>(numBuckets);
		VectorUtil.fill(mBucketSize, 0, numBuckets);
		
		mBucketCapacity = new Vector<Int>(numBuckets);
		for (i in 0...numBuckets)
		{
			mBucketPos[i] = i * initialBucketCapacity;
			mBucketCapacity[i] = initialBucketCapacity;
		}
	}
	
	public function getBucketArray(bucket:Int):Array<T>
	{
		var a = [];
		var i = mBucketPos[bucket];
		var k = i + mBucketCapacity[bucket];
		while (i < k) a.push(mData[i++]);
		return a;
	}
	
	public function getBucketData(bucket:Int, output:Array<T>, offset:Int = 0):Int
	{
		var i = mBucketPos[bucket];
		var j = 0;
		var k = i + mBucketSize[bucket];
		while (i < k) output[j++ + offset] = mData[i++];
		return j;
	}
	
	public function sortBucket(bucket:Int)
	{
		insertionSort(cast mData, mBucketPos[bucket], mBucketSize[bucket]);
	}
	
	public function findIndex(bucket:Int, e:Int):Int
	{
		return bsearchInt(cast mData, e, mBucketPos[bucket], mBucketSize[bucket]);
	}
	
	function insertionSort(a:Vector<Int>, first:Int, k:Int)
	{
		//trace( "BucketList.insertionSort > a : " + a + ", first : " + first + ", k : " + k );
		for (i in first + 1...first + k)
		{
			var x = a[i];
			var j = i;
			while (j > first)
			{
				var y = a[j - 1];
				if (y - x > 0) //cmp
				{
					a[j] = y;
					j--;
				}
				else
					break;
			}
			
			a[j] = x;
		}
	}
	
	function bsearchInt(a:Vector<Int>, x:Int, min:Int, max:Int):Int
	{
		#if debug
		assert(a != null, "a != null");
		assert(min >= 0 && min < a.length, "min >= 0 && min < a.length");
		assert(max < a.length, "max < a.length");
		#end
		
		var l = min, m, h = max + 1;
		while (l < h)
		{
			m = l + ((h - l) >> 1);
			if (a[m] < x)
				l = m + 1;
			else
				h = m;
		}
		
		if ((l <= max) && (a[l] == x))
			return l;
		else
			return ~l;
	}
	
	/**
		Add val to bucket.
	**/
	public function add(bucket:Int, val:T)
	{
		//trace('bucketlist: add $val to $bucket');
		
		var c = mBucketCapacity[bucket];
		var s = mBucketSize[bucket];
		var p = mBucketPos[bucket] + s; //write index
		
		mBucketSize[bucket] = s + 1; //increment bucket size
		
		if (s < c)
			mData[p] = val; //value fits into bucket
		else
		{
			//bucket is full so increase its capacity
			#if verbose
			trace('double bucket $bucket from $s to ${s << 1}');
			#end
			
			var src = mData;
			var oldCapacity = mCapacity;
			
			//create new, bigger vector and copy data over
			mCapacity = oldCapacity + c;
			var dst = new Vector<T>(mCapacity);
			
			//if there are preceding buckets, copy their data over
			if (bucket > 0)
			{
				var i = 0;
				var k = mBucketPos[bucket - 1] + mBucketCapacity[bucket - 1];
				while (i < k)
				{
					dst[i] = src[i];
					i++;
				}
			}
			
			//now copy the data stored in the current bucket
			var i = mBucketPos[bucket];
			var k = i + c;
			while (i < k)
			{
				dst[i] = src[i];
				i++;
			}
			
			//and finally shift data of subsequent buckets to the right
			//because the current bucket has grown
			while (i < oldCapacity)
			{
				dst[i + c] = src[i];
				i++;
			}
			
			mData = dst;
			
			//now we can put val into the current bucket
			mData[p] = val;
			
			mBucketCapacity[bucket] <<= 1; //double capacity of current bucket
			
			//update bucket positions
			while (++bucket < numBuckets) mBucketPos[bucket] += c;
		}
	}
	
	/**
		Removes the first occurence of `val` from the bucket at the given `index`.
	**/
	public function removeAt(bucket:Int, val:T):Bool
	{
		var c = mBucketCapacity[bucket];
		var s = mBucketSize[bucket];
		var p = mBucketPos[bucket];
		
		//find and remove element
		var min = p;
		var max = p + s;
		var exists = false;
		while (min < max)
		{
			var e = mData[min];
			if (e == val)
			{
				exists = true;
				break;
			}
			min++;
		}
		
		if (!exists) return false;
		
		//shift elements by one position to the left
		while (min < max - 1)
		{
			mData[min] = mData[min + 1];
			min++;
		}
		mData[max - 1] = cast null;
		
		s--; //decrement bucket size
		
		mBucketSize[bucket] = s; 
		
		if (mAllowShrink && c >= 8 && (s == c >> 2)) //cut bucket size in half?
		{
			#if verbose
			trace('half bucket $bucket from $c to ${s >> 1}');
			#end
			
			c >>= 1;
			
			var i, k;
			
			var src = mData;
			var dst = new Vector<T>(mCapacity - c);
			
			//if there are preceding buckets, copy their data over
			if (bucket > 0)
			{
				i = 0;
				k = mBucketPos[bucket - 1] + mBucketCapacity[bucket - 1];
				while (i < k)
				{
					dst[i] = src[i];
					i++;
				}
			}
			
			//now copy the data stored in the current bucket
			i = mBucketPos[bucket];
			k = i + c;
			while (i < k)
			{
				dst[i] = src[i];
				i++;
			}
			
			if (bucket + 1 < numBuckets) //subsequent buckets exist?
			{
				//copy data over
				min = mBucketPos[bucket + 1];
				max = mCapacity;
				while (min < max) dst[i++] = src[min++];
			}
			
			//update capacity lut
			mCapacity -= c;
			mBucketCapacity[bucket] = c;
			
			//update position lut
			while (++bucket < numBuckets) mBucketPos[bucket] -= c;
			
			mData = dst;
		}
		
		return true;
	}
	
	public function exists(bucket:Int, val:T):Bool
	{
		//search in [min,max]
		var min = mBucketPos[bucket];
		var max = min + mBucketSize[bucket];
		while (min < max)
		{
			if (mData[min] == val)
				return true;
			min++;
		}
		
		return false;
	}
	
	public function removeFromAllBuckets(val:T):Bool
	{
		for (i in 0...numBuckets)
		{
			var c = mBucketCapacity[i];
			var s = mBucketSize[i];
			var p = mBucketPos[i];
		}
		
		throw "TODO";
		return false;
	}
	
	public function shift(fromBucket:Int, toBucket:Int, val:T)
	{
		throw "TODO";
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
		
	}
	
	/**
		Returns true if this two-dimensional array contains the element `x`.
		<o>n</o>
	**/
	public function contains(x:T):Bool
	{
		for (i in 0...numBuckets)
			if (!exists(i, x))
				return false;
		return true;
	}
	
	/**
		Nullifies all occurrences of `x`.
		The size is not altered.
		<o>n</o>
		@return true if at least one occurrence of `x` was nullified.
	**/
	/*public function remove(x:T):Bool
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
	}*/
	
	/**
		Clears this two-dimensional array by nullifying all elements.
		If `purge` is true, elements are nullified upon removal and `capacity` is set to the initial `capacity` defined in the constructor.
		<o>1 or n if `purge` is true</o>
	**/
	public function clear(purge = false)
	{
		mCapacity = numBuckets * mInitialBucketCapacity;
		mData = new Vector<T>(mCapacity);
		
		VectorUtil.fill(mBucketSize, 0, numBuckets);
		for (i in 0...numBuckets)
		{
			mBucketPos[i] = i * mInitialBucketCapacity;
			mBucketCapacity[i] = mInitialBucketCapacity;
		}
	}
	
	/**
		Returns a new `BucketListIterator` object to iterate over all elements contained in this two-dimensional array.
		
		See <a href="http://haxe.org/ref/iterators" target="mBlank">http://haxe.org/ref/iterators</a>
	**/
	public function iterator():Itr<T>
	{
		/*if (reuseIterator)
		{
			if (mIterator == null)
				mIterator = new BucketListIterator<T>(this);
			else
				mIterator.reset();
			return mIterator;
		}
		else
			return new BucketListIterator<T>(this);*/
		return null;
	}
	
	/**
		The number of elements stored in all buckets.
		<o>1</o>
	**/
	inline public function size():Int
	{
		throw 0;
	}
	
	/**
		Unsupported operation - always returns false.
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
		throw null;
	}
	
	/**
		Returns a `Vector<T>` object containing all elements in this two-dimensional array.
		Order: Row-major order (row-by-row).
	**/
	public function toVector():Vector<T>
	{
		throw null;
	}
	
	/**
		Duplicates this two-dimensional array. Supports shallow (structure only) and deep copies (structure & elements).
		@param assign if true, the `copier` parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.
		If false, the `clone()` method is called on each element. __*In this case all elements have to implement `Cloneable`.*__
		@param copier a custom function for copying elements. Replaces element.`clone()` if `assign` is false.
		@throws de.polygonal.ds.error.AssertError element is not of type `Cloneable` (debug only).
	**/
	public function clone(assign = true, copier:T->T = null):Collection<T>
	{
		/*var copy = new Array2<T>(mW, mH);
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
		return copy;*/
		return null;
	}
}