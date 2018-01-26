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
	A doubly linked list node
	
	Each node wraps an element and stores a reference to the next and previous list node.
	
	`DllNode` objects are created and managed by the `Dll` class.
**/
#if generic
@:generic
#end
class DllNode<T>
{
	/**
		The node's data.
	**/
	public var val:T;
	
	/**
		The next node in the list being referenced or null if this node has no next node.
	**/
	public var next:DllNode<T>;
	
	/**
		The previous node in the list being referenced or null if this node has no previous node.
	**/
	public var prev:DllNode<T>;
	
	var mList:Dll<T>;
	
	/**
		@param val the element to store in this node.
		@param list the list storing this node.
	**/
	public function new(val:T, list:Dll<T>)
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
		next = prev = null;
		mList = null;
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
		Returns true if this node points to a previous node.
	**/
	@:extern public inline function hasPrev():Bool
	{
		return prev != null;
	}
	
	/**
		Returns the element of the next node.
	**/
	@:extern public inline function nextVal():T
	{
		assert(hasNext(), "next node is null");
		
		return next.val;
	}
	
	/**
		Returns the element of the previous node.
	**/
	@:extern public inline function prevVal():T
	{
		assert(hasPrev(), "previous node is null");
		
		return prev.val;
	}
	
	/**
		The list that owns this node or null if this node is not part of a list.
	**/
	@:extern public inline function getList():Dll<T>
	{
		return mList;
	}
	
	/**
		Unlinks this node from its list and returns `this.next`.
	**/
	@:extern public inline function unlink():DllNode<T>
	{
		assert(mList != null);
		
		return mList.unlink(this);
	}
	
	/**
		Prepends `node` to this node assuming this is the **head** node of a list.
		
		Useful for updating a list which is not managed by a `Dll` object.
		
		Example:
			var a = new DllNode<Int>(0, null);
			var b = new DllNode<Int>(1, null);
			var head = b.prepend(a);
			trace(head.val); //0
			trace(head.nextVal()); //1
		@return the list's new head node.
	**/
	@:extern public inline function prepend(node:DllNode<T>):DllNode<T>
	{
		assert(node != null, "node is null");
		assert(prev == null, "prev is not null");
		assert(mList == null && node.mList == null, "node is managed by a list");
		
		node.next = this;
		prev = node;
		return node;
	}
	
	/**
		Appends `node` to this node assuming this is the **tail** node of a list.
		
		Useful for updating a list which is not managed by a `Dll` object.
		
		Example:
			var a = new DllNode<Int>(0, null);
			var b = new DllNode<Int>(1, null);
			var tail = a.append(b);
			trace(tail.val); //1
			trace(tail.prevVal()); //0
		@return the list's new tail node.
	**/
	@:extern public inline function append(node:DllNode<T>):DllNode<T>
	{
		assert(node != null, "node is null");
		assert(next == null, "next is not null");
		assert(mList == null && node.mList == null, "node is managed by a list");
		
		next = node;
		node.prev = this;
		return node;
	}
	
	/**
		Prepends this node to `node` assuming `node` is the **head** node of a list.
		
		Useful for updating a list which is not managed by a `Dll` object.
		
		Example:
			var a = new DllNode<Int>(0, null);
			var b = new DllNode<Int>(1, null);
			var head = a.prependTo(b);
			trace(head.val); //0
			trace(head.nextVal()); //1

		@return the list's new head node.
	**/
	@:extern public inline function prependTo(node:DllNode<T>):DllNode<T>
	{
		assert(node != null, "node is null");
		assert(mList == null && node.mList == null, "node is managed by a list");
		assert(node.prev == null, "node.prev is not null");
		
		next = node;
		if (node != null) node.prev = this;
		return this;
	}
	
	/**
		Appends this node to `node` assuming `node` is the **tail** node of a list.
		
		Useful for updating a list which is not managed by a `Dll` object.
		
		Example:
			var a = new DllNode<Int>(0, null);
			var b = new DllNode<Int>(1, null);
			var tail = b.appendTo(a);
			trace(tail.val); //1
			trace(tail.prevVal()); //0
		
		@return the list's new tail node.
	**/
	@:extern public inline function appendTo(node:DllNode<T>):DllNode<T>
	{
		assert(node != null, "node is null");
		assert(mList == null && node.mList == null, "node is managed by a list");
		assert(node.next == null, "node.next is not null");
		
		prev = node;
		if (node != null) node.next = this;
		return this;
	}
	
	/**
		Prints out all elements.
	**/
	#if !no_tostring
	public function toString():String
	{
		return '{ DllNode ${Std.string(val)} }';
	}
	#end
	
	@:extern inline function insertAfter(node:DllNode<T>)
	{
		node.next = next;
		node.prev = this;
		if (hasNext()) next.prev = node;
		next = node;
	}
	
	@:extern inline function insertBefore(node:DllNode<T>)
	{
		node.next = this;
		node.prev = prev;
		if (hasPrev()) prev.next = node;
		prev = node;
	}
}