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
	A singly linked list node
	
	Each node wraps an element and stores a reference to the next list node.
	
	``SllNode`` objects are created and managed by the ``Sll`` class.
	
	_<o>Worst-case running time in Big O notation</o>_
**/
#if (flash && generic)
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
		@param x the element to store in this node.
		@param list the list storing this node.
	**/
	public function new(x:T, list:Sll<T>)
	{
		val = x;
		mList = list;
	}
	
	/**
		Destroys this object by explicitly nullifying all pointers and elements for GC'ing used resources.
		
		Improves GC efficiency/performance (optional).
		<o>1</o>
	**/
	public function free()
	{
		val = cast null;
		next = null;
	}
	
	/**
		Returns true if this node is the head of a list.
		<o>1</o>
		<assert>node is not managed by a list</assert>
	**/
	inline public function isHead():Bool
	{
		assert(mList != null, "node is not managed by a list");
		
		return this == mList.head;
	}
	
	/**
		Returns true if this node is the tail of a list.
		<o>1</o>
		<assert>node is not managed by a list</assert>
	**/
	inline public function isTail():Bool
	{
		assert(mList != null, "node is not managed by a list");
		
		return this == mList.tail;
	}
	
	/**
		Returns true if this node points to a next node.
		<o>1</o>
	**/
	inline public function hasNext():Bool
	{
		return next != null;
	}
	
	/**
		Returns the element of the next node.
		<o>1</o>
		<assert>next node is null</assert>
	**/
	inline public function nextVal():T
	{
		assert(hasNext(), "invalid next node");
		
		return next.val;
	}
	
	/**
		The list that owns this node or null if this node is not part of a list.
		<o>1</o>
	**/
	inline public function getList():Sll<T>
	{
		return mList;
	}
	
	/**
		Unlinks this node from its list and returns node.`next`.
		<o>n</o>
		<assert>list is null</assert>
	**/
	inline public function unlink():SllNode<T>
	{
		assert(mList != null);
		
		return mList.unlink(this);
	}
	
	/**
		Returns a string representing the current object.
	**/
	public function toString():String
	{
		return '{ SllNode ${Std.string(val)} }';
	}
	
	inline function insertAfter(node:SllNode<T>)
	{
		node.next = next;
		next = node;
	}
}