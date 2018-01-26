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

/**
	A singly linked list node
	
	Each node wraps an element and stores a reference to the next list node.
	
	`SllNode` objects are created and managed by the `Sll` class.
**/
#if generic
@:generic
#end
class SllNode<T>
{
	/**
		The node's data.
	**/
	public var val:T;
	
	/**
		The next node in the list being referenced or null if this node has no next node.
	**/
	public var next:SllNode<T>;
	
	var mList:Sll<T>;
	
	/**
		@param val the element to store in this node.
		@param list the list storing this node.
	**/
	public function new(val:T, list:Sll<T>)
	{
		this.val = val;
		mList = list;
	}
	
	/**
		Destroys this object by explicitly nullifying all pointers and elements for GC'ing used resources.
		
		Improves GC efficiency/performance (optional).
	**/
	public function free()
	{
		val = cast null;
		next = null;
	}
	
	/**
		Returns true if this node is the head of a list.
	**/
	@:extern public inline function isHead():Bool
	{
		assert(mList != null, "node is not managed by a list");
		
		return this == mList.head;
	}
	
	/**
		Returns true if this node is the tail of a list.
	**/
	@:extern public inline function isTail():Bool
	{
		assert(mList != null, "node is not managed by a list");
		
		return this == mList.tail;
	}
	
	/**
		Returns true if this node points to a next node.
	**/
	@:extern public inline function hasNext():Bool
	{
		return next != null;
	}
	
	/**
		Returns the element of the next node.
	**/
	@:extern public inline function nextVal():T
	{
		assert(hasNext(), "invalid next node");
		
		return next.val;
	}
	
	/**
		The list that owns this node or null if this node is not part of a list.
	**/
	@:extern public inline function getList():Sll<T>
	{
		return mList;
	}
	
	/**
		Unlinks this node from its list and returns `node.next`.
	**/
	@:extern public inline function unlink():SllNode<T>
	{
		assert(mList != null);
		
		return mList.unlink(this);
	}
	
	/**
		Prints out all elements.
	**/
	#if !no_tostring
	public function toString():String
	{
		return '{ SllNode ${Std.string(val)} }';
	}
	#end
	
	@:extern inline function insertAfter(node:SllNode<T>)
	{
		node.next = next;
		next = node;
	}
}