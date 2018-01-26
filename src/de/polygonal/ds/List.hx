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

import de.polygonal.ds.Collection;

/**
	An ordered list of elements
**/
interface List<T> extends Collection<T>
{
	/**
		Returns the value at the given `index`.
	**/
	function get(index:Int):T;
	
	/**
		Overwrites the value at the given `index` with `val`.
	**/
	function set(index:Int, val:T):Void;
	
	/**
		Adds `val` to the end of the list.
	**/
	function add(val:T):Void;
	
	/**
		Inserts `val` at the specified index.
		
		Shifts the element currently at that position (if any) and any subsequent elements to the right (indices + 1).
		If `index` equals `Collection.size`, `val` gets appended to the end of the list.
	**/
	function insert(index:Int, val:T):Void;
	
	/**
		Removes the value at the given `index`.
	**/
	function removeAt(index:Int):T;
	
	/**
		Returns the index of the first occurrence of `val`, or -1 if this list does not contain `val`.
	**/
	function indexOf(val:T):Int;
	
	/**
		Returns a shallow copy of a range of elements in the interval [`fromIndex`, `toIndex`).
		If `toIndex` is negative, the value represents the number of elements.
	**/
	function getRange(fromIndex:Int, toIndex:Int):List<T>;
}