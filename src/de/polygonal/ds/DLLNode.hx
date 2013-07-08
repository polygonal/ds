/*
 *                            _/                                                    _/
 *       _/_/_/      _/_/    _/  _/    _/    _/_/_/    _/_/    _/_/_/      _/_/_/  _/
 *      _/    _/  _/    _/  _/  _/    _/  _/    _/  _/    _/  _/    _/  _/    _/  _/
 *     _/    _/  _/    _/  _/  _/    _/  _/    _/  _/    _/  _/    _/  _/    _/  _/
 *    _/_/_/      _/_/    _/    _/_/_/    _/_/_/    _/_/    _/    _/    _/_/_/  _/
 *   _/                            _/        _/
 *  _/                        _/_/      _/_/
 *
 * POLYGONAL - A HAXE LIBRARY FOR GAME DEVELOPERS
 * Copyright (c) 2009 Michael Baczynski, http://www.polygonal.de
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */
package de.polygonal.ds;

import de.polygonal.ds.error.Assert.assert;

/**
 * <p>A doubly linked list node.</p>
 * <p>Each node wraps an element and stores a reference to the next and previous list node.</p>
 * <p><em>DLLNode</em> objects are created and managed by the <em>DLL</em> class.</p>
 * <p><o>Worst-case running time in Big O notation</o></p>
 */
#if generic
@:generic
#end
class DLLNode<T>
{
	/**
	 * The node's data. 
	 */
	public var val:T;
	
	/**
	 * The next node in the list being referenced or null if this node has no next node. 
	 */
	public var next:DLLNode<T>;
	
	/**
	 * The previous node in the list being referenced or null if this node has no previous node. 
	 */
	public var prev:DLLNode<T>;
	
	var _list:DLL<T>;
	
	/**
	 * @param x the element to store in this node.
	 * @param list the list storing this node.
	 */
	public function new(x:T, list:DLL<T>)
	{
		val = x;
		_list = list;
	}
	
	/**
	 * Destroys this object by explicitly nullifying all pointers and elements for GC'ing used resources.<br/>
	 * Improves GC efficiency/performance (optional).
	 * <o>1</o>
	 */
	public function free()
	{
		val = cast null;
		next = prev = null;
		_list = null;
	}
	
	/**
	 * Returns true if this node is the head of a list.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError node is not managed by a list (debug only).
	 */
	inline public function isHead():Bool
	{
		#if debug
		assert(_list != null, "node is not managed by a list");
		#end
		
		return this == _list.head;
	}
	
	/**
	 * Returns true if this node is the tail of a list.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError node is not managed by a list (debug only).
	 */
	inline public function isTail():Bool
	{
		#if debug
		assert(_list != null, "node is not managed by a list");
		#end
		
		return this == _list.tail;
	}
	
	/**
	 * Returns true if this node points to a next node.
	 * <o>1</o>
	 */
	inline public function hasNext():Bool
	{
		return next != null;
	}
	
	/**
	 * Returns true if this node points to a previous node.
	 * <o>1</o>
	 */
	inline public function hasPrev():Bool
	{
		return prev != null;
	}
	
	/**
	 * Returns the element of the next node.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError next node is null (debug only).
	 */
	inline public function nextVal():T
	{
		#if debug
		assert(hasNext(), "next node is null");
		#end
		
		return next.val;
	}
	
	/**
	 * Returns the element of the previous node.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError previous node is null (debug only).
	 */
	inline public function prevVal():T
	{
		#if debug
		assert(hasPrev(), "previous node is null");
		#end
		
		return prev.val;
	}
	
	/**
	 * The list that owns this node or null if this node is not part of a list.
	 * <o>1</o>
	 */
	inline public function getList():DLL<T>
	{
		return _list;
	}
	
	/**
	 * Unlinks this node from its list and returns node.<em>next</em>.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError list is null (debug only).
	 */
	inline public function unlink():DLLNode<T>
	{
		#if debug
		assert(_list != null, "_list != null");
		#end
		
		return _list.unlink(this);
	}
	
	/**
	 * Prepends <code>node</code> to this node assuming this is the <warn>head</warn> node of a list.<br/>
	 * Useful for updating a list which is not managed by a <em>DLL</em> object.<br/>
	 * Example:<br/>
	 * <pre class="prettyprint">
	 * var a = new DLLNode&lt;Int&gt;(0, null);
	 * var b = new DLLNode&lt;Int&gt;(1, null);
	 * var head = b.prepend(a);
	 * trace(head.val); //0
	 * trace(head.nextVal()); //1</pre>
	 * <o>1</o>
	 * @return the list's new head node.
	 * @throws de.polygonal.ds.error.AssertError <code>node</code> is null or managed by a list.
	 * @throws de.polygonal.ds.error.AssertError <code>node</code>.<em>prev</em> exists (debug only).
	 */
	inline public function prepend(node:DLLNode<T>):DLLNode<T>
	{
		#if debug
		assert(node != null, "node is null");
		assert(prev == null, "prev is not null");
		assert(_list == null && node._list == null, "node is managed by a list");
		#end
		
		node.next = this;
		prev = node;
		return node;
	}
	
	/**
	 * Appends <code>node</code> to this node assuming this is the <warn>tail</warn> node of a list.<br/>
	 * Useful for updating a list which is not managed by a <em>DLL</em> object.<br/>
	 * Example:<br/>
	 * <pre class="prettyprint">
	 * var a = new DLLNode&lt;Int&gt;(0, null);
	 * var b = new DLLNode&lt;Int&gt;(1, null);
	 * var tail = a.append(b);
	 * trace(tail.val); //1
	 * trace(tail.prevVal()); //0</pre>
	 * <o>1</o>
	 * @return the list's new tail node.
	 * @throws de.polygonal.ds.error.AssertError <code>node</code> is null or managed by a list.
	 * @throws de.polygonal.ds.error.AssertError <code>node</code>.<em>next</em> exists (debug only).
	 */
	inline public function append(node:DLLNode<T>):DLLNode<T>
	{
		#if debug
		assert(node != null, "node is null");
		assert(next == null, "next is not null");
		assert(_list == null && node._list == null, "node is managed by a list");
		#end
		
		next = node;
		node.prev = this;
		return node;
	}
	
	/**
	 * Prepends this node to <code>node</code> assuming <code>node</code> is the <warn>head</warn> node of a list.<br/>
	 * Useful for updating a list which is not managed by a <em>DLL</em> object.
	 * Example:<br/>
	 * <pre class="prettyprint">
	 * var a = new DLLNode&lt;Int&gt;(0, null);
	 * var b = new DLLNode&lt;Int&gt;(1, null);
	 * var head = a.prependTo(b);
	 * trace(head.val); //0
	 * trace(head.nextVal()); //1</pre>
	 * <o>1</o>
	 * @return the list's new head node.
	 * @throws de.polygonal.ds.error.AssertError <code>node</code> is null or managed by a list (debug only).
	 * @throws de.polygonal.ds.error.AssertError <code>node</code>.<em>prev</em> exists (debug only).
	 */
	inline public function prependTo(node:DLLNode<T>):DLLNode<T>
	{
		#if debug
		assert(node != null, "node is null");
		assert(_list == null && node._list == null, "node is managed by a list");
		assert(node.prev == null, "node.prev is not null");
		#end
		
		next = node;
		if (node != null) node.prev = this;
		return this;
	}
	
	/**
	 * Appends this node to <code>node</code> assuming <code>node</code> is the <warn>tail</warn> node of a list.<br/>
	 * Useful for updating a list which is not managed by a <em>DLL</em> object.<br/>
	 * Example:<br/>
	 * <pre class="prettyprint">
	 * var a = new DLLNode&lt;Int&gt;(0, null);
	 * var b = new DLLNode&lt;Int&gt;(1, null);
	 * var tail = b.appendTo(a);
	 * trace(tail.val); //1
	 * trace(tail.prevVal()); //0</pre>
	 * <o>1</o>
	 * @return the list's new tail node.
	 * @throws de.polygonal.ds.error.AssertError <code>node</code> is null or managed by a list (debug only).
	 * @throws de.polygonal.ds.error.AssertError <code>node</code>.<em>next</em> exists (debug only).
	 */
	inline public function appendTo(node:DLLNode<T>):DLLNode<T>
	{
		#if debug
		assert(node != null, "node is null");
		assert(_list == null && node._list == null, "node is managed by a list");
		assert(node.next == null, "node.next is not null");
		#end
		
		prev = node;
		if (node != null) node.next = this;
		return this;
	}
	
	/**
	 * Returns a string representing the current object. 
	 */
	public function toString():String
	{
		return '{ DLLNode ${Std.string(val)} }';
	}
	
	inline function _unlink():DLLNode<T>
	{
		var t = next;
		if (hasPrev()) prev.next = next;
		if (hasNext()) next.prev = prev;
		next = prev = null;
		return t;
	}
	
	inline function _insertAfter(node:DLLNode<T>)
	{
		node.next = next;
		node.prev = this;
		if (hasNext()) next.prev = node;
		next = node;
	}
	
	inline function _insertBefore(node:DLLNode<T>)
	{
		node.next = this;
		node.prev = prev;
		if (hasPrev()) prev.next = node;
		prev = node;
	}
}