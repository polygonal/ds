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
package de.polygonal.ds.tools;

using de.polygonal.ds.tools.NativeArrayTools;

class RadixSort
{
	static var _inp:NativeArray<Int>;
	static var _out:NativeArray<Int>;
	static var _num:NativeArray<Int>;
	static var _bin:NativeArray<Int>;
	
	/**
		A Least significant digit (LSD) Radix sort implementation for unsigned integers <= 0x7FFFFFFF.
		
		- This operation modifies the `input` Array in place.
		- The original order of duplicate keys is preserved.
		- Much faster for big integer arrays.
	**/
	public static function sort(input:Array<Int>):Array<Int>
	{
		if (_num == null)
		{
			_num = NativeArrayTools.alloc(0x100);
			_inp = NativeArrayTools.alloc(0x100);
			_out = NativeArrayTools.alloc(0x100);
			_bin = NativeArrayTools.alloc(0x200);
		}
		
		var i, j, k, l = input.length;
		var flip = false;
		var mask = 255;
		var shr = 0;
		
		if (_inp.size() < l)
		{
			_inp = NativeArrayTools.alloc(l << 1);
			_out = NativeArrayTools.alloc(l << 1);
		}
		
		var num = _num;
		var inp = _inp;
		var out = _out;
		var bin = _bin;
		
		i = 0;
		while (i < l)
		{
			inp.set(i, input[i]);
			i++;
		}
		
		while (mask != 0)
		{
			#if cpp
			cpp.NativeArray.zero(num, 0, 0x100);
			#else
			i = 0;
			while (i < 0x100)
			{
				num.set(i, 0);
				i++;
			}
			#end
			i = 0;
			while (i < l)
			{
				#if php
				j = inp.get(i) & mask;
				if (shr > 0) j = j >>> shr;
				#else
				j = (inp.get(i) & mask) >>> shr;
				#end
				
				num.set(j, num.get(j) + 1);
				i++;
			}
			bin.set(0, 0);
			bin.set(0x100, 0);
			i = 1;
			while (i < 0x100)
			{
				k = bin.get(i - 1) + num.get(i - 1);
				bin.set(i, k);
				bin.set(i + 0x100, k);
				i++;
			}
			i = 0;
			while (i < l)
			{
				#if php
				j = inp.get(i) & mask;
				if (shr > 0) j = j >>> shr;
				#else
				j = (inp.get(i) & mask) >>> shr;
				#end
				
				k = bin.get(j + 0x100);
				bin.set(j + 0x100, k + 1);
				out.set(k, inp.get(i));
				i++;
			}
			mask = (mask << 8) & 0x7fffff;
			shr += 8;
			flip = !flip;
			var tmp = inp; inp = out; out = tmp;
		}
		
		if (flip) inp = out;
		i = 0;
		while (i < l)
		{
			input[i] = inp.get(i);
			i++;
		}
		return input;
	}
}