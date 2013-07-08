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
 * <p>A singly linked list node.</p>
 * <p>Each node wraps an element and stores a reference to the next list node.</p>
 * <p><em>SLLNode</em> objects are created and managed by the <em>SLL</em> class.</p>
 * <p><o>Worst-case running time in Big O notation</o></p>
 */
#if generic
@:generic
#end
class SLLNode<T>
{
	/**
	 * The node's data.
	 */
	public var val:T;
	
	/**
	 * The next node in the list being referenced or null if this node has no next node. 
	 */
	public var next:SLLNode<T>;
	
	var _list:SLL<T>;
	
	/**
	 * @param x the element to store in this node.
	 * @param list the list storing this node.
	 */
	public function new(x:T, list:SLL<T>)
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
		next = null;
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
	 * Returns the element of the next node.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError next node is null (debug only).
	 */
	inline public function nextVal():T
	{
		#if debug
		assert(hasNext(), "invalid next node");
		#end
		
		return next.val;
	}
	
	/**
	 * The list that owns this node or null if this node is not part of a list.
	 * <o>1</o>
	 */
	inline public function getList():SLL<T>
	{
		return _list;
	}
	
	/**
	 * Unlinks this node from its list and returns node.<em>next</em>.
	 * <o>n</o>
	 * @throws de.polygonal.ds.error.AssertError list is null (debug only).
	 */
	inline public function unlink():SLLNode<T>
	{
		#if debug
		assert(_list != null, "_list != null");
		#end
		
		return _list.unlink(this);
	}
	
	/**
	 * Returns a string representing the current object.
	 */
	public function toString():String
	{
		return '{ SLLNode ${Std.string(val)} }';
	}
	
	inline function _insertAfter(node:SLLNode<T>)
	{
		node.next = next;
		next = node;
	}
}