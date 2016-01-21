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
	A doubly linked list node
	
	Each node wraps an element and stores a reference to the next and previous list node.
	
	``DllNode`` objects are created and managed by the ``Dll`` class.
	
	_<o>Worst-case running time in Big O notation</o>_
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
		@param x the element to store in this node.
		@param list the list storing this node.
	**/
	public function new(x:T, list:Dll<T>)
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
		next = prev = null;
		mList = null;
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
		Returns true if this node points to a previous node.
		<o>1</o>
	**/
	inline public function hasPrev():Bool
	{
		return prev != null;
	}
	
	/**
		Returns the element of the next node.
		<o>1</o>
		<assert>next node is null</assert>
	**/
	inline public function nextVal():T
	{
		assert(hasNext(), "next node is null");
		
		return next.val;
	}
	
	/**
		Returns the element of the previous node.
		<o>1</o>
		<assert>previous node is null</assert>
	**/
	inline public function prevVal():T
	{
		assert(hasPrev(), "previous node is null");
		
		return prev.val;
	}
	
	/**
		The list that owns this node or null if this node is not part of a list.
		<o>1</o>
	**/
	inline public function getList():Dll<T>
	{
		return mList;
	}
	
	/**
		Unlinks this node from its list and returns `next`.
		<o>1</o>
		<assert>list is null</assert>
	**/
	inline public function unlink():DllNode<T>
	{
		assert(mList != null);
		
		return mList.unlink(this);
	}
	
	/**
		Prepends `node` to this node assuming this is the ***head*** node of a list.
		
		Useful for updating a list which is not managed by a ``Dll`` object.
		
		Example:
		<pre class="prettyprint">
		var a = new DllNode<Int>(0, null);
		var b = new DllNode<Int>(1, null);
		var head = b.prepend(a);
		trace(head.val); //0
		trace(head.nextVal()); //1</pre>
		<o>1</o>
		<assert>`node` is null or managed by a list</assert>
		<assert>`node`::prev exists</assert>
		@return the list's new head node.
	**/
	inline public function prepend(node:DllNode<T>):DllNode<T>
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
		
		Useful for updating a list which is not managed by a ``Dll`` object.
		
		Example:
		<pre class="prettyprint">
		var a = new DllNode<Int>(0, null);
		var b = new DllNode<Int>(1, null);
		var tail = a.append(b);
		trace(tail.val); //1
		trace(tail.prevVal()); //0</pre>
		<o>1</o>
		<assert>`node` is null or managed by a list</assert>
		<assert>`node`::next exists</assert>
		@return the list's new tail node.
	**/
	inline public function append(node:DllNode<T>):DllNode<T>
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
		
		Useful for updating a list which is not managed by a ``Dll`` object.
		
		Example:
		<pre class="prettyprint">
		var a = new DllNode<Int>(0, null);
		var b = new DllNode<Int>(1, null);
		var head = a.prependTo(b);
		trace(head.val); //0
		trace(head.nextVal()); //1</pre>
		<o>1</o>
		<assert>`node` is null or managed by a list</assert>
		<assert>`node`::prev exists</assert>
		@return the list's new head node.
	**/
	inline public function prependTo(node:DllNode<T>):DllNode<T>
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
		
		Useful for updating a list which is not managed by a ``Dll`` object.
		
		Example:
		<pre class="prettyprint">
		var a = new DllNode<Int>(0, null);
		var b = new DllNode<Int>(1, null);
		var tail = b.appendTo(a);
		trace(tail.val); //1
		trace(tail.prevVal()); //0</pre>
		<o>1</o>
		<assert>`node` is null or managed by a list</assert>
		<assert>`node`::next exists</assert>
		@return the list's new tail node.
	**/
	inline public function appendTo(node:DllNode<T>):DllNode<T>
	{
		assert(node != null, "node is null");
		assert(mList == null && node.mList == null, "node is managed by a list");
		assert(node.next == null, "node.next is not null");
		
		prev = node;
		if (node != null) node.next = this;
		return this;
	}
	
	/**
		Returns a string representing the current object.
	**/
	public function toString():String
	{
		return '{ DllNode ${Std.string(val)} }';
	}
	
	inline function insertAfter(node:DllNode<T>)
	{
		node.next = next;
		node.prev = this;
		if (hasNext()) next.prev = node;
		next = node;
	}
	
	inline function insertBefore(node:DllNode<T>)
	{
		node.next = this;
		node.prev = prev;
		if (hasPrev()) prev.next = node;
		prev = node;
	}
	
	inline function _unlink():DllNode<T>
	{
		var t = next;
		if (hasPrev()) prev.next = next;
		if (hasNext()) next.prev = prev;
		next = prev = null;
		return t;
	}
}