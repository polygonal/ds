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
	A graph arc represents an uni-directional link between two GraphNode objects
	
	`GraphArc` objects are created and managed by the `Graph` class.
	
	_<o>Worst-case running time in Big O notation</o>_
**/
#if generic
@:generic
#end
class GraphArc<T> implements Hashable
{
	/**
		A unique identifier for this object.
		
		A hash table transforms this key into an index of an array element by using a hash function.
		
		<warn>This value should never be changed by the user.</warn>
	**/
	public var key:Int;
	
	/**
		The node that this arc points to.
	**/
	public var node:GraphNode<T>;
	
	/**
		The weight (or cost) of this arc.
	**/
	public var cost:Float;
	
	/**
		A reference to the next graph arc in the list.
		
		The `GraphNode` class manages a doubly linked list of `GraphArc` objects.
	**/
	public var next:GraphArc<T>;
	
	/**
		A reference to the previous graph arc in the list.
		
		The `GraphNode` class manages a doubly linked list of `GraphArc` objects.
	**/
	public var prev:GraphArc<T>;
	
	/**
		The data of the node that this arc points to.
	**/
	public var val(get_val, never):T;
	inline function get_val():T return node.val;
	
	/**
		Creates a graph arc pointing to `node` with a weight of `cost` .
	**/
	public function new(node:GraphNode<T>, cost:Float)
	{
		this.node = node;
		this.cost = cost;
		next = null;
		prev = null;
		key = HashKey.next();
	}
	
	/**
		Destroys this object by explicitly nullifying the node and all pointers for GC'ing used resources.
		
		Improves GC efficiency/performance (optional).
		<o>1</o>
	**/
	public function free()
	{
		node = null;
		next = prev = null;
	}
}