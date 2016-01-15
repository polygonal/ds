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

/**
	A double-ended queue that supports fast element insertion and removal at both ends
**/
interface Deque<T> extends Collection<T>
{
	/**
		Returns the first element of the deque.
	**/
	function front():T;
	
	/**
		Inserts the element `x` at the front of the deque.
	**/
	function pushFront(x:T):Void;
	
	/**
		Removes and returns the element at the beginning of the deque.
	**/
	function popFront():T;
	
	/**
		Returns the last element of the deque.
	**/
	function back():T;
	
	/**
		Inserts the element `x` at the back of the deque.
	**/
	function pushBack(x:T):Void;
	
	/**
		Deletes the element at the end of the deque.
	**/
	function popBack():T;
}