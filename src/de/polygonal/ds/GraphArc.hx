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
 * <p>A graph arc represents an uni-directional link between two <em>GraphNode</em> objects.</p>
 * <p><em>GraphArc</em> objects are created and managed by the <em>Graph</em> class.</p>
 * <p><o>Worst-case running time in Big O notation</o></p>
 */
#if generic
@:generic
#end
class GraphArc<T> implements Hashable
{
	/**
	 * A unique identifier for this object.<br/>
	 * A hash table transforms this key into an index of an array element by using a hash function.<br/>
	 * <warn>This value should never be changed by the user.</warn>
	 */
	public var key:Int;
	
	/**
	 * The node that this arc points to. 
	 */
	public var node:GraphNode<T>;
	
	/**
	 * The weight (or cost) of this arc. 
	 */
	public var cost:Float;
	
	/**
	 * A reference to the next graph arc in the list.<br/>
	 * The <em>GraphNode</em> class manages a doubly linked list of <em>GraphArc</em> objects.
	 */
	public var next:GraphArc<T>;
	
	/**
	 * A reference to the previous graph arc in the list.<br/>
	 * The <em>GraphNode</em> class manages a doubly linked list of <em>GraphArc</em> objects.
	 */
	public var prev:GraphArc<T>;
	
	/**
	 * Creates a graph arc pointing to <code>node</code> with a weight of <code>cost</code> . 
	 */
	public function new(node:GraphNode<T>, cost:Float)
	{
		this.node = node;
		this.cost = cost;
		next      = null;
		prev      = null;
		key       = HashKey.next();
	}
	
	/**
	 * Destroys this object by explicitly nullifying the node and all pointers for GC'ing used resources.<br/>
	 * Improves GC efficiency/performance (optional).
	 * <o>1</o>
	 */
	public function free()
	{
		node = null;
		next = prev = null;
	}
	
	/**
	 * Returns the data of the node that this arc points to. 
	 */
	inline public function val():T
	{
		return node.val;
	}
}