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
	A queue is a First-In-First-Out (FIFO) data structure
	
	The first element added to the queue will be the first one to be removed.
	
	The "opposite" of a queue is a stack.
**/
interface Queue<T> extends Collection<T>
{
	/**
		Inserts the element `x` at the back of the queue.
	**/
	function enqueue(x:T):Void;
	
	/**
		Removes and returns the element at the front of the queue.
	**/
	function dequeue():T;
	
	/**
		Returns the element at the front of the queue.
		
		This is the "oldest" element.
	**/
	function peek():T;
	
	/**
		Returns the element at the back of the queue.
		
		This is the "newest" element.
	**/
	function back():T;
}