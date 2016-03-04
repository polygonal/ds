/*
Copyright (c) 2008-2016 Michael Baczynski, http://www.polygonal.de

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
	A graph node manages a doubly linked list of GraphArc objects
	
	`GraphNode` objects are created and managed by the `Graph` class.
**/
#if generic
@:generic
#end
class GraphNode<T> implements Hashable
{
	/**
		A unique identifier for this object.
		
		A hash table transforms this key into an index of an array element by using a hash function.
		
		<warn>This value should never be changed by the user.</warn>
	**/
	public var key(default, null):Int = HashKey.next();
	
	/**
		The node's data.
	**/
	public var val:T;
	
	/**
		The node's parent.
		
		During a BFS/DFS traversal, `parent` points to the previously visited node or to
		itself if the search originated at that node.
	**/
	public var parent:GraphNode<T>;
	
	/**
		The traversal depth (distance from the first traversed node).
	**/
	public var depth:Int;
	
	/**
		A reference to the next graph node in the list.
		
		The `Graph` class manages a doubly linked list of `GraphNode` objects.
	**/
	public var next:GraphNode<T>;
	
	/**
		A reference to the previous graph node in the list.
		
		The `Graph` class manages a doubly linked list of `GraphNode` objects.
	**/
	public var prev:GraphNode<T>;
	
	/**
		The head of a a doubly linked list of `GraphArc` objects.
	**/
	public var arcList:GraphArc<T>;
	
	/**
		True if the graph node was marked in a DFS/BFS traversal.
	**/
	public var marked:Bool;
	
	/**
		The total number of outgoing arcs.
	**/
	public var numArcs(default, null):Int;
	
	var mGraph:Graph<T>;
	
	/**
		Creates a graph node storing the element `x`.
	**/
	public function new(graph:Graph<T>, x:T)
	{
		val = x;
		arcList = null;
		marked = false;
		mGraph = graph;
	}
	
	/**
		Destroys this object by explicitly nullifying the element and all pointers for GC'ing used resources.
		
		Improves GC efficiency/performance (optional).
	**/
	public function free()
	{
		val = cast null;
		next = prev = null;
		arcList = null;
		mGraph = null;
	}
	
	/**
		Returns a new `NodeValIterator` object to iterate over the elements stored in all nodes that are connected to this node by an outgoing arc.
		
		See <a href="http://haxe.org/ref/iterators" target="mBlank">http://haxe.org/ref/iterators</a>
	**/
	public function iterator():Itr<T>
	{
		return new NodeValIterator<T>(this);
	}
	
	/**
		Returns true if this node is connected to the `target` node.
		<assert>`target` is null</assert>
	**/
	public inline function isConnected(target:GraphNode<T>):Bool
	{
		assert(target != null, "target is null");
		
		return getArc(target) != null;
	}
	
	/**
		Returns true if this node and the `target` node are pointing to each other.
		<assert>`target` is null</assert>
	**/
	public inline function isMutuallyConnected(target:GraphNode<T>):Bool
	{
		assert(target != null, "target is null");
		
		return getArc(target) != null && target.getArc(this) != null;
	}
	
	/**
		Finds the arc that is pointing to the `target` node or returns null if such an arc does not exist.
		<assert>`target` is null</assert>
		<assert>`target` equals this</assert>
	**/
	public function getArc(target:GraphNode<T>):GraphArc<T>
	{
		assert(target != null, "target is null");
		assert(target != this, "target equals this node");
		
		var found = false;
		var a = arcList;
		while (a != null)
		{
			if (a.node == target)
			{
				found = true;
				break;
			}
			a = a.next;
		}
		
		if (found)
			return a;
		else
			return null;
	}
	
	/**
		Adds an arc pointing from this node to the specified `target` node.
		<assert>`target` is null or arc to `target` already exists</assert>
		@param cost defines how "hard" it is to get from one node to the other. Default is 1.0.
	**/
	public function addArc(target:GraphNode<T>, cost:Float = 1)
	{
		assert(target != this, "target is null");
		assert(getArc(target) == null, "arc to target already exists");
		
		var arc =
		if (mGraph.borrowArc != null)
			mGraph.borrowArc(target, cost);
		else
			new GraphArc<T>(target, cost);
		arc.next = arcList;
		if (arcList != null) arcList.prev = arc;
		arcList = arc;
		
		numArcs++;
	}
	
	/**
		Removes the arc that is pointing to the specified `target` node.
		<assert>`target`</assert>
		@return true if the arc is successfully removed, false if such an arc does not exist.
	**/
	public function removeArc(target:GraphNode<T>):Bool
	{
		assert(target != this, "target is null");
		assert(getArc(target) != null, "arc to target does not exist");
		
		var arc = getArc(target);
		if (arc != null)
		{
			if (arc.prev != null) arc.prev.next = arc.next;
			if (arc.next != null) arc.next.prev = arc.prev;
			if (arcList == arc) arcList = arc.next;
			arc.next = null;
			arc.prev = null;
			arc.node = null;
			if (mGraph.returnArc != null) mGraph.returnArc(arc);
			numArcs--;
			return true;
		}
		return false;
	}
	
	/**
		Removes all outgoing arcs from this node.
	**/
	public function removeSingleArcs()
	{
		var arc = arcList;
		while (arc != null)
		{
			removeArc(arc.node);
			arc = arc.next;
		}
		numArcs = 0;
	}
	
	/**
		Remove all outgoing and incoming arcs from this node.
	**/
	public function removeMutualArcs()
	{
		var arc = arcList;
		while (arc != null)
		{
			arc.node.removeArc(this);
			removeArc(arc.node);
			arc = arc.next;
		}
		arcList = null;
		numArcs = 0;
	}
	
	/**
		Returns a string representing the current object.
	**/
	public function toString():String
	{
		var t = [], arc;
		if (arcList != null)
		{
			arc = arcList;
			while (arc != null)
			{
				t.push(Std.string(arc.val));
				arc = arc.next;
			}
		}
		return
		if (t.length > 0)
			'{ GraphNode val: $val, connected to: ${t.join(",")} }';
		else
			'{ GraphNode val: $val }';
	}
}

#if generic
@:generic
#end
@:dox(hide)
class NodeValIterator<T> implements de.polygonal.ds.Itr<T>
{
	var mObject:GraphNode<T>;
	var mArcList:GraphArc<T>;
	
	public function new(x:GraphNode<T>)
	{
		mObject = x;
		reset();
	}
	
	public inline function reset():Itr<T>
	{
		mArcList = mObject.arcList;
		return this;
	}
	
	public inline function hasNext():Bool
	{
		return mArcList != null;
	}
	
	public inline function next():T
	{
		var val = mArcList.node.val;
		mArcList = mArcList.next;
		return val;
	}
	
	public function remove()
	{
		throw "unsupported operation";
	}
}