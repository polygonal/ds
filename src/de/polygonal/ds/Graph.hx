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

import de.polygonal.ds.tools.ArrayTools;
import de.polygonal.ds.tools.Assert.assert;
import de.polygonal.ds.tools.NativeArrayTools;

using de.polygonal.ds.tools.NativeArrayTools;

/**
	A weighted graph
	
	A graph is composed of `GraphNode` and `GraphArc` objects.
	
	Example:
		var o = new de.polygonal.ds.Graph<String>();
		var a = o.addNode(o.createNode("a"));
		var b = o.addNode(o.createNode("b"));
		var c = o.addNode(o.createNode("c"));
		o.addSingleArc(a, b);
		o.addSingleArc(b, a);
		o.addMutualArc(a, c);
		trace(o); //outputs:
		
		[ Graph size=3
		  c -> a
		  b -> a
		  a -> c,b
		]
**/
#if generic
@:generic
#end
class Graph<T> implements Collection<T>
{
	/**
		A unique identifier for this object.
		
		A hash table transforms this key into an index of an array element by using a hash function.
		
		<warn>This value should never be changed by the user.</warn>
	**/
	public var key(default, null):Int = HashKey.next();
	
	/**
		If true, automatically clears the mark-flag on all graph nodes prior to starting a new traversal.
		
		Default is false.
	**/
	public var autoClearMarks:Bool = false;
	
	/**
		If true, reuses the iterator object instead of allocating a new one when calling `this.iterator()`.
		
		The default is false.
		
		<warn>If true, nested iterations are likely to fail as only one iteration is allowed at a time.</warn>
	**/
	public var reuseIterator:Bool = false;
	
	/**
		If specified, `this.borrowArc()` is called in order to create `GraphArc` objects.
		
		Useful for pooling `GraphArc` objects.
		
		Default is null.
	**/
	public var borrowArc:GraphNode<T>->Float->GraphArc<T>;
	
	/**
		A function pointer responsible for returning `GraphArc` objects.
		
		Required if `this.borrowArc` is specified.
		
		Default is null.
	**/
	public var returnArc:GraphArc<T>->Void;
	
	var mNodeList:GraphNode<T> = null;
	var mSize:Int = 0;
	var mIterator:GraphIterator<T> = null;
	
	var mStack:NativeArray<GraphNode<T>>;
	var mStackSize:Int = 16;
	var mQue:NativeArray<GraphNode<T>>;
	var mQueSize:Int = 16;
	
	#if debug
	var mBusy:Bool;
	var mNodeSet:Set<GraphNode<T>>;
	#end
	
	public function new()
	{
		mStack = NativeArrayTools.alloc(mStackSize);
		mQue = NativeArrayTools.alloc(mQueSize);
		
		#if debug
		mBusy = false;
		mNodeSet = new ListSet<GraphNode<T>>();
		#end
	}
	
	/**
		The graph nodes stored as a doubly linked list of `GraphNode` objects.
		@return the first node in a list of `GraphNode` objects or null if the graph is empty.
	**/
	public inline function getNodeList():GraphNode<T>
	{
		return mNodeList;
	}
	
	/**
		Finds and returns the node storing `val` or null if such a node does not exist.
	**/
	public function findNode(val:T):GraphNode<T>
	{
		var found = false;
		var n = mNodeList;
		while (n != null)
		{
			if (n.val == val)
			{
				found = true;
				break;
			}
			n = n.next;
		}
		return found ? n : null;
	}
	
	/**
		Creates and returns a node object storing `val`.
	**/
	public function createNode(val:T):GraphNode<T>
	{
		return new GraphNode<T>(this, val);
	}
	
	/**
		Adds the node `node` to this graph and returns `node`.
	**/
	public function addNode(node:GraphNode<T>):GraphNode<T>
	{
		assert(mNodeSet.set(node), "node exists");
		
		mSize++;
		
		node.next = mNodeList;
		if (node.next != null) node.next.prev = node;
		mNodeList = node;
		return node;
	}
	
	/**
		Removes `node` from this graph.
		
		This clears all outgoing and incoming arcs and removes `node` from the node list.
	**/
	public function removeNode(node:GraphNode<T>)
	{
		assert(size > 0, "graph is empty");
		assert(mNodeSet.has(node), "unknown node");
		
		unlink(node);
		
		if (node.prev != null) node.prev.next = node.next;
		if (node.next != null) node.next.prev = node.prev;
		if (mNodeList == node) mNodeList = node.next;
		mSize--;
	}
	
	/**
		Creates an uni-directional link between two nodes with a weight of `cost` (default is 1.0).
		
		This creates an arc pointing from the `source` node to the `target` node.
	**/
	public function addSingleArc(source:GraphNode<T>, target:GraphNode<T>, cost:Float = 1.)
	{
		assert(source != null, "source is null");
		assert(target != null, "target is null");
		assert(source != target, "source equals target");
		
		var walker = mNodeList;
		while (walker != null)
		{
			if (walker == source)
			{
				var sourceNode = walker;
				walker = mNodeList;
				while (walker != null)
				{
					if (walker == target)
					{
						sourceNode.addArc(walker, cost);
						break;
					}
					walker = walker.next;
				}
				break;
			}
			walker = walker.next;
		}
	}
	
	/**
		Creates a bi-directional link between two nodes with a weight of `cost` (default is 1.0).
		
		This creates two arcs - an arc that points from the `source` node to the `target` node and vice versa.
	**/
	public function addMutualArc(source:GraphNode<T>, target:GraphNode<T>, cost:Float = 1.)
	{
		assert(source != null, "source is null");
		assert(target != null, "target is null");
		assert(source != target, "source equals target");
		assert(source.getArc(target) == null, "arc from source to target already exists");
		assert(target.getArc(source) == null, "arc from target to source already exists");
		
		var walker = mNodeList;
		while (walker != null)
		{
			if (walker == source)
			{
				var sourceNode = walker;
				walker = mNodeList;
				while (walker != null)
				{
					if (walker == target)
					{
						sourceNode.addArc(walker, cost);
						walker.addArc(sourceNode, cost);
						break;
					}
					
					walker = walker.next;
				}
				break;
			}
			walker = walker.next;
		}
	}
	
	/**
		Isolates `node` from this graph by unlinking it from all outgoing and incoming arcs.
		
		The size remains unchanged as the node is not removed from the graph.
		@return the disconnected graph node.
	**/
	@:access(de.polygonal.ds.GraphNode)
	public function unlink(node:GraphNode<T>):GraphNode<T>
	{
		assert(mNodeList != null, "graph is empty");
		assert(mNodeSet.has(node), "unknown node");
		assert(node != null, "node is null");
		
		var arc0 = node.arcList;
		while (arc0 != null)
		{
			var node1 = arc0.node;
			var arc1 = node1.arcList;
			while (arc1 != null)
			{
				var hook = arc1.next;
				
				if (arc1.node == node)
				{
					if (arc1.prev != null) arc1.prev.next = hook;
					if (hook != null) hook.prev = arc1.prev;
					if (node1.arcList == arc1) node1.arcList = hook;
					arc1.free();
					node1.numArcs--;
					if (returnArc != null)
						returnArc(arc1);
				}
				
				arc1 = hook;
			}
			
			var hook = arc0.next;
			
			if (arc0.prev != null) arc0.prev.next = hook;
			if (hook != null) hook.prev = arc0.prev;
			if (node.arcList == arc0) node.arcList = hook;
			arc0.free();
			node.numArcs--;
			if (returnArc != null)
				returnArc(arc0);
			
			arc0 = hook;
		}
		
		node.arcList = null;
		return node;
	}
	
	/**
		Clears the mark-flag on all graph nodes that were set in a BFS/DFS traversal.
		
		<warn>Call this method to start a fresh traversal.</warn>
	**/
	public function clearMarks()
	{
		var node = mNodeList;
		while (node != null)
		{
			node.marked = false;
			node = node.next;
		}
	}
	
	/**
		Clears the parent pointers on all graph nodes.
	**/
	public function clearParent()
	{
		var node = mNodeList;
		while (node != null)
		{
			node.parent = null;
			node = node.next;
		}
	}
	
	/**
		Performs an iterative depth-first search (DFS).
		@param preflight if true, an extra traversal is performed before the actual traversal runs.
		The first pass visits all elements and calls `element.visit()` with the `preflight` parameter set to true.
		In this pass the return value determines whether the element will be processed (true) or
		excluded (false) from the final traversal, which is the second pass (`preflight` parameter set to false).
		The same applies when using a `process` function.
		@param seed the starting point of the traversal. If omitted, the first node in the list of graph nodes is used.
		@param process a function that is invoked for every traversed node. The parameters are:
		<ul>
		<li>a reference to the visited node.</li>
		<li>the `preflight` flag.</li>
		<li>custom data specified by the `userData` parameter (default is null).</li>
		</ul>
		Once `process` returns false, the traversal stops immediately and no further nodes are examined (termination condition).
		If omitted, `element.visit()` is used.
		<warn>In this case the elements of all nodes have to implement `Visitable`.</warn>
		@param userData custom data that is passed to every visited node via `process` or `element.visit()`. If omitted, null is used.
		@param recursive if true, performs a recursive traversal (default traversal style is iterative).
	**/
	public function DFS(preflight:Bool = false, seed:GraphNode<T> = null, process:GraphNode<T>->Bool->Dynamic->Bool = null, userData:Dynamic = null, recursive:Bool = false)
	{
		if (size == 0) return;
		
		#if debug
		assert(mBusy == false, "recursive call to iterative DFS");
		mBusy = true;
		#end
		
		if (autoClearMarks) clearMarks();
		
		var c = 1;
		
		if (seed == null) seed = mNodeList;
		
		var max = mStackSize;
		var s = mStack;
		
		s.set(0, seed);
		
		inline function popOffStack() return s.get(--c);
		inline function pushOnStack(x)
		{
			if (c == max) resizeStack(max = max * 2);
			s.set(c++, x);
		}
		
		seed.parent = seed;
		seed.depth = 0;
		
		if (preflight)
		{
			if (process == null)
			{
				if (recursive)
				{
					var v:Dynamic = seed.val;
					if (v.visit(true, userData))
						dFSRecursiveVisit(seed, true, userData);
				}
				else
				{
					var v:Dynamic = null;
					var n = s.get(0);
					v = n.val;
					if (!v.visit(true, userData))
					{
						#if debug
						mBusy = false;
						#end
						return;
					}
					
					while (c > 0)
					{
						var n = popOffStack();
						
						if (n.marked) continue;
						n.marked = true;
						
						v = n.val;
						if (!v.visit(false, userData)) break;
						
						var a = n.arcList;
						while (a != null)
						{
							v = n.val;
							
							a.node.parent = n;
							a.node.depth = n.depth + 1;
							
							if (v.visit(true, userData))
								pushOnStack(a.node);
							a = a.next;
						}
					}
				}
			}
			else
			{
				if (recursive)
				{
					if (process(seed, true, userData))
						dFSRecursiveProcess(seed, process, true, userData);
				}
				else
				{
					var n = s.get(0);
					if (!process(n, true, userData))
					{
						#if debug
						mBusy = false;
						#end
						return;
					}
					
					while (c > 0)
					{
						var n = popOffStack();
						
						if (n.marked) continue;
						n.marked = true;
						
						if (!process(n, false, userData)) break;
						
						var a = n.arcList;
						while (a != null)
						{
							a.node.parent = n;
							a.node.depth = n.depth + 1;
							
							if (process(a.node, true, userData))
								pushOnStack(a.node);
							a = a.next;
						}
					}
				}
			}
		}
		else
		{
			if (process == null)
			{
				if (recursive)
					dFSRecursiveVisit(seed, false, userData);
				else
				{
					var v:Dynamic = null;
					while (c > 0)
					{
						var n = popOffStack();
						if (n.marked) continue;
						n.marked = true;
						
						v = n.val;
						if (!v.visit(false, userData)) break;
						
						var a = n.arcList;
						while (a != null)
						{
							pushOnStack(a.node);
							a.node.parent = n;
							a.node.depth = n.depth + 1;
							a = a.next;
						}
					}
				}
			}
			else
			{
				if (recursive)
					dFSRecursiveProcess(seed, process, false, userData);
				else
				{
					while (c > 0)
					{
						var n = popOffStack();
						if (n.marked) continue;
						n.marked = true;
						
						if (!process(n, false, userData)) break;
						
						var a = n.arcList;
						while (a != null)
						{
							pushOnStack(a.node);
							a.node.parent = n;
							a.node.depth = n.depth + 1;
							a = a.next;
						}
					}
				}
			}
		}
		
		#if debug
		mBusy = false;
		#end
	}
	
	/**
		Performs an iterative breadth-first search (BFS).
		@param preflight if true, an extra traversal is performed before the actual traversal runs.
		The first pass visits all elements and calls `element.visit()` with the `preflight` parameter set to true.
		In this pass the return value determines whether the element will be processed (true) or
		excluded (false) from the final traversal, which is the second pass (`preflight` parameter set to false).
		The same applies when using a `process` function.
		@param seed the starting point of the traversal. If omitted, the first node in the list of graph nodes is used.
		@param process a function that is invoked for every traversed node. The parameters are:
		<ul>
		<li>a reference to the visited node.</li>
		<li>the `preflight` flag.</li>
		<li>custom data specified by the `userData` parameter (default is null).</li>
		</ul>
		Once `process` returns false, the traversal stops immediately and no further nodes are examined (termination condition).
		If omitted, `element.visit()` is used.
		<warn>In this case the elements of all nodes have to implement `Visitable`.</warn>
		@param userData custom data that is passed to every visited node via `process` or `element.visit()`. If omitted, null is used.
	**/
	public function BFS(preflight:Bool = false, seed:GraphNode<T> = null, process:GraphNode<T>->Bool->Dynamic->Bool = null, userData:Dynamic = null)
	{
		if (size == 0) return;
		
		#if debug
		assert(mBusy == false, "recursive call to iterative BFS");
		mBusy = true;
		#end
		
		if (autoClearMarks) clearMarks();
		
		var front = 0;
		var c = 1;
		var q = mQue, max = mQueSize;
		
		inline function getQue(i) return q.get(i);
		inline function setQue(i, x)
		{
			if (i == max)
			{
				resizeQue(max = max * 2);
				q = mQue;
			}
			q.set(i, x);
		}
		
		if (seed == null) seed = mNodeList;
		q.set(0, seed);
		
		seed.marked = true;
		seed.parent = seed;
		seed.depth = 0;
		
		if (preflight)
		{
			if (process == null)
			{
				var v:Dynamic = null;
				
				var n = getQue(front);
				v = n.val;
				if (!v.visit(true, userData))
				{
					#if debug
					mBusy = false;
					#end
					return;
				}
				
				while (c > 0)
				{
					n = getQue(front);
					v = n.val;
					if (!v.visit(false, userData))
					{
						#if debug
						mBusy = false;
						#end
						return;
					}
					var a = n.arcList;
					while (a != null)
					{
						var m = a.node;
						if (m.marked)
						{
							a = a.next;
							continue;
						}
						m.marked = true;
						m.parent = n;
						m.depth = n.depth + 1;
						v = m.val;
						if (v.visit(true, userData))
							setQue(c++ + front, m);
						a = a.next;
					}
					front++;
					c--;
				}
			}
			else
			{
				var n = getQue(front);
				if (!process(n, true, userData))
				{
					#if debug
					mBusy = false;
					#end
					return;
				}
				
				while (c > 0)
				{
					n = getQue(front);
					if (!process(n, false, userData))
					{
						#if debug
						mBusy = false;
						#end
						return;
					}
					
					var a = n.arcList;
					while (a != null)
					{
						var m = a.node;
						if (m.marked)
						{
							a = a.next;
							continue;
						}
						m.marked = true;
						m.parent = n;
						m.depth = n.depth + 1;
						if (process(m, true, userData))
							setQue(c++ + front, m);
						a = a.next;
					}
					front++;
					c--;
				}
			}
		}
		else
		{
			if (process == null)
			{
				var v:Dynamic = null;
				while (c > 0)
				{
					var n = getQue(front);
					v = n.val;
					if (!v.visit(false, userData))
					{
						#if debug
						mBusy = false;
						#end
						return;
					}
					var a = n.arcList;
					while (a != null)
					{
						var m = a.node;
						if (m.marked)
						{
							a = a.next;
							continue;
						}
						m.marked = true;
						m.parent = n;
						m.depth = n.depth + 1;
						setQue(c++ + front, m);
						a = a.next;
					}
					front++;
					c--;
				}
			}
			else
			{
				while (c > 0)
				{
					var n = getQue(front);
					if (!process(n, false, userData))
					{
						#if debug
						mBusy = false;
						#end
						return;
					}
					var a = n.arcList;
					while (a != null)
					{
						var m = a.node;
						if (m.marked)
						{
							a = a.next;
							continue;
						}
						m.marked = true;
						m.parent = n;
						m.depth = n.depth + 1;
						setQue(c++ + front, m);
						a = a.next;
					}
					front++;
					c--;
				}
			}
		}
		
		#if debug
		mBusy = false;
		#end
	}
	
	/**
		Performs an iterative depth-limited breadth-first search (DLBFS).
		@param maxDepth A `maxDepth` value of 1 means that only all direct neighbors of `seed` are visited.
		@param preflight if true, an extra traversal is performed before the actual traversal runs.
		The first pass visits all elements and calls `element.visit()` with the `preflight` parameter set to true.
		In this pass the return value determines whether the element will be processed (true) or
		excluded (false) from the final traversal, which is the second pass (`preflight` parameter set to false).
		The same applies when using a `process` function.
		@param seed the starting point of the traversal. If omitted, the first node in the list of graph nodes is used.
		@param process a function that is invoked for every traversed node. The parameters are:
		<ul>
		<li>a reference to the visited node.</li>
		<li>the `preflight` flag.</li>
		<li>custom data specified by the `userData` parameter (default is null).</li>
		</ul>
		Once `process` returns false, the traversal stops immediately and no further nodes are examined (termination condition).
		If omitted, `element.visit()` is used.
		<warn>In this case the elements of all nodes have to implement `Visitable`.</warn>
		@param userData custom data that is passed to every visited node via `process` or `element.visit()`. If omitted, null is used.
	**/
	public function DLBFS(maxDepth:Int, preflight:Bool = false, seed:GraphNode<T> = null, process:GraphNode<T>->Bool->Dynamic->Bool = null, userData:Dynamic = null)
	{
		if (size == 0) return;
		
		#if debug
		assert(mBusy == false, "recursive call to iterative BFS");
		mBusy = true;
		#end
		
		if (autoClearMarks) clearMarks();
		
		var front = 0;
		var c = 1;
		
		var q = mQue, max = mQueSize;
		
		inline function getQue(i) return q.get(i);
		inline function setQue(i, x)
		{
			if (i == max)
			{
				resizeQue(max = max * 2);
				q = mQue;
			}
			q.set(i, x);
		}
		
		var node = mNodeList;
		while (node != null)
		{
			node.depth = 0;
			node = node.next;
		}
		
		if (seed == null) seed = mNodeList;
		
		seed.marked = true;
		seed.parent = seed;
		
		q.set(0, seed);
		
		if (preflight)
		{
			if (process == null)
			{
				var v:Dynamic = null;
				
				var n = getQue(front);
				v = n.val;
				if (!v.visit(true, userData))
				{
					#if debug
					mBusy = false;
					#end
					return;
				}
				
				while (c > 0)
				{
					n = getQue(front);
					v = n.val;
					if (!v.visit(false, userData))
					{
						#if debug
						mBusy = false;
						#end
						return;
					}
					var a = n.arcList;
					while (a != null)
					{
						var m = a.node;
						if (m.marked)
						{
							a = a.next;
							continue;
						}
						m.marked = true;
						m.parent = n;
						m.depth = n.depth + 1;
						if (m.depth <= maxDepth)
						{
							v = m.val;
							if (v.visit(true, userData))
								setQue(c++ + front, m);
						}
						a = a.next;
					}
					front++;
					c--;
				}
			}
			else
			{
				var n = getQue(front);
				if (!process(n, true, userData))
				{
					#if debug
					mBusy = false;
					#end
					return;
				}
				
				while (c > 0)
				{
					n = getQue(front);
					if (!process(n, false, userData))
					{
						#if debug
						mBusy = false;
						#end
						return;
					}
					
					var a = n.arcList;
					while (a != null)
					{
						var m = a.node;
						if (m.marked)
						{
							a = a.next;
							continue;
						}
						m.marked = true;
						m.parent = n;
						m.depth = n.depth + 1;
						if (m.depth <= maxDepth)
						{
							if (process(m, true, userData))
								setQue(c++ + front, m);
						}
						a = a.next;
					}
					front++;
					c--;
				}
			}
		}
		else
		{
			if (process == null)
			{
				var v:Dynamic = null;
				while (c > 0)
				{
					var n = getQue(front);
					
					v = n.val;
					if (!v.visit(false, userData))
					{
						#if debug
						mBusy = false;
						#end
						return;
					}
					var a = n.arcList;
					while (a != null)
					{
						var m = a.node;
						if (m.marked)
						{
							a = a.next;
							continue;
						}
						m.marked = true;
						m.depth = n.depth + 1;
						m.parent = n.parent;
						if (m.depth <= maxDepth)
							setQue(c++ + front, m);
						a = a.next;
					}
					front++;
					c--;
				}
			}
			else
			{
				while (c > 0)
				{
					var n = getQue(front);
					
					if (n.depth > maxDepth) continue;
					
					if (!process(n, false, userData))
					{
						#if debug
						mBusy = false;
						#end
						return;
					}
					var a = n.arcList;
					while (a != null)
					{
						var m = a.node;
						if (m.marked)
						{
							a = a.next;
							continue;
						}
						m.marked = true;
						m.depth = n.depth + 1;
						m.parent = n.parent;
						if (m.depth <= maxDepth)
							setQue(c++ + front, m);
						a = a.next;
					}
					front++;
					c--;
				}
			}
		}
		
		#if debug
		mBusy = false;
		#end
	}
	
	/**
		Prints out all elements.
	**/
	public function toString():String
	{
		#if no_tostring
		return Std.string(this);
		#else
		var tmp = [];
		function printNode(n:GraphNode<T>)
		{
			var arc, i = 0;
			if (n.arcList != null)
			{
				arc = n.arcList;
				while (arc != null)
				{
					tmp[i++] = Std.string(arc.val);
					arc = arc.next;
				}
			}
			while (tmp.length > i) tmp.pop();
			return
			if (i > 0)
				n.val + " -> " + tmp.join(",");
			else
				n.val + "";
		}
		
		var b = new StringBuf();
		b.add('[ Graph size=$size');
		if (isEmpty())
		{
			b.add(" ]");
			return b.toString();
		}
		b.add("\n");
		var node = mNodeList;
		while (node != null)
		{
			b.add("  ");
			b.add(printNode(node));
			b.add("\n");
			node = node.next;
		}
		b.add("]");
		return b.toString();
		#end
	}
	
	public function serialize()
	{
		
	}
	
	/* INTERFACE Collection */
	
	/**
		The total number of elements in this graph.
		
		Equals the number of graph nodes.
	**/
	public var size(get, never):Int;
	inline function get_size():Int
	{
		return mSize;
	}
	
	/**
		Destroys this object by explicitly nullifying all nodes, elements and pointers for GC'ing used resources.
		
		Improves GC efficiency/performance (optional).
	**/
	public function free()
	{
		var node = mNodeList;
		while (node != null)
		{
			var nextNode = node.next;
			
			var arc = node.arcList;
			while (arc != null)
			{
				var nextArc = arc.next;
				arc.next = arc.prev = null;
				arc.node = null;
				arc = nextArc;
			}
			
			node.free();
			node = nextNode;
		}
		
		mNodeList = null;
		
		mStack.nullify();
		mStack = null;
		
		mQue.nullify();
		mQue = null;
		
		if (mIterator != null)
		{
			mIterator.free();
			mIterator = null;
		}
		
		#if debug
		mNodeSet.free();
		mNodeSet = null;
		#end
		
		borrowArc = null;
		returnArc = null;
	}
	
	/**
		Returns true if this graph contains a node storing `val`.
	**/
	public function contains(val:T):Bool
	{
		var found = false;
		var node = mNodeList;
		while (node != null)
		{
			if (node.val == val)
				return true;
			node = node.next;
		}
		return false;
	}
	
	/**
		Removes all nodes storing `val`.
		
		Nodes and elements are nullified.
		@return true if at least one node storing `val` was removed.
	**/
	public function remove(val:T):Bool
	{
		var found = false;
		var node = mNodeList;
		while (node != null)
		{
			var nextNode = node.next;
			
			if (node.val == val)
			{
				unlink(node);
				if (node == mNodeList) mNodeList = nextNode;
				node.val = cast null;
				node.next = node.prev = null;
				node.arcList = null;
				found = true;
				mSize--;
			}
			
			node = nextNode;
		}
		return found;
	}
	
	/**
		Removes all elements.
		
		@param gc if true, explicitly nullifies nodes and elements upon removal so the garbage collector can reclaim used memory.
	**/
	public function clear(gc:Bool = false)
	{
		if (gc)
		{
			var node = mNodeList;
			while (node != null)
			{
				var hook = node.next;
				var arc = node.arcList;
				while (arc != null)
				{
					var hook = arc.next;
					arc.free();
					arc = hook;
				}
				node.free();
				node = hook;
			}
			
			mStack.nullify();
			mQue.nullify();
		}
		
		mNodeList = null;
		mSize = 0;
	}
	
	/**
		Returns a new *GraphIterator* object to iterate over all elements stored in the graph nodes of this graph.
		
		The nodes are visited in a random order.
		
		@see http://haxe.org/ref/iterators
	**/
	public function iterator():Itr<T>
	{
		if (reuseIterator)
		{
			if (mIterator == null)
				mIterator = new GraphIterator<T>(this);
			else
				mIterator.reset();
			return mIterator;
		}
		else
			return new GraphIterator<T>(this);
	}
	
	/**
		Returns a new *GraphNodeIterator* object to iterate over all `GraphNode` objects in this graph.
		
		The nodes are visited in a random order.
		
		@see http://haxe.org/ref/iterators
	**/
	public function nodeIterator():Itr<GraphNode<T>>
	{
		return new GraphNodeIterator<T>(this);
	}
	
	/**
		Returns a new *GraphArcIterator* object to iterate over all `GraphArc` objects in this graph.
		
		The arcs are visited in a random order.
		
		@see http://haxe.org/ref/iterators
	**/
	public function arcIterator():Itr<GraphArc<T>>
	{
		return new GraphArcIterator<T>(this);
	}
	
	/**
		Returns true only if `this.size` is 0.
	**/
	public inline function isEmpty():Bool
	{
		return size == 0;
	}
	
	/**
		Returns an unordered array containing all elements stored in the graph nodes of this graph.
	**/
	public function toArray():Array<T>
	{
		if (isEmpty()) return [];
		
		var i = 0;
		var out = ArrayTools.alloc(size);
		var node = mNodeList;
		while (node != null)
		{
			out[i++] = node.val;
			node = node.next;
		}
		return out;
	}
	
	/**
		Creates and returns a shallow copy (structure only - default) or deep copy (structure & elements) of this graph.
		
		If `byRef` is true, primitive elements are copied by value whereas objects are copied by reference.
		
		If `byRef` is false, the `copier` function is used for copying elements. If omitted, `clone()` is called on each element assuming all elements implement `Cloneable`.
	**/
	public function clone(byRef:Bool = true, copier:T->T = null):Collection<T>
	{
		var copy = new Graph<T>();
		if (mNodeList == null) return copy;
		
		var t = new Array<GraphNode<T>>();
		var i = 0;
		var n = mNodeList, m;
		
		if (byRef)
		{
			while (n != null)
			{
				m = copy.addNode(copy.createNode(n.val));
				t[i++] = m;
				n = n.next;
			}
		}
		else
		if (copier == null)
		{
			while (n != null)
			{
				assert(Std.is(n.val, Cloneable), "element is not of type Cloneable");
				
				m = copy.addNode(copy.createNode(cast(n.val, Cloneable<Dynamic>).clone()));
				t[i++] = m;
				n = n.next;
			}
		}
		else
		{
			while (n != null)
			{
				m = copy.addNode(copy.createNode(copier(n.val)));
				t[i++] = m;
				n = n.next;
			}
		}
		
		i = 0;
		n = mNodeList;
		var a;
		while (n != null)
		{
			m = t[i++];
			a = n.arcList;
			while (a != null)
			{
				m.addArc(a.node, a.cost);
				a = a.next;
			}
			n = n.next;
		}
		return copy;
	}
	
	function dFSRecursiveVisit(node:GraphNode<T>, preflight:Bool, userData:Dynamic):Bool
	{
		node.marked = true;
		
		var v:Dynamic = node.val;
		if (!v.visit(false, userData)) return false;
		
		var a = node.arcList;
		while (a != null)
		{
			var m = a.node;
			
			if (m.marked)
			{
				a = a.next;
				continue;
			}
			
			a.node.parent = node;
			a.node.depth = node.depth + 1;
			
			if (preflight)
			{
				v = m.val;
				if (v.visit(true, userData))
					if (!dFSRecursiveVisit(m, true, userData))
						return false;
			}
			else
			{
				if (!dFSRecursiveVisit(m, false, userData))
					return false;
			}
			
			a = a.next;
		}
		return true;
	}
	
	function dFSRecursiveProcess(node:GraphNode<T>, process:GraphNode<T>->Bool->Dynamic->Bool = null, preflight:Bool, userData:Dynamic):Bool
	{
		node.marked = true;
		if (!process(node, false, userData))
			return false;
		
		var a = node.arcList;
		while (a != null)
		{
			var m = a.node;
			if (m.marked)
			{
				a = a.next;
				continue;
			}
			
			a.node.parent = node;
			a.node.depth = node.depth + 1;
			
			if (preflight)
			{
				if (process(m, true, userData))
					if (!dFSRecursiveProcess(m, process, true, userData))
						return false;
			}
			else
			{
				if (!dFSRecursiveProcess(m, process, false, userData))
						return false;
			}
			
			a = a.next;
		}
		return true;
	}
	
	function resizeStack(newSize:Int)
	{
		var t = NativeArrayTools.alloc(newSize);
		mStack.blit(0, t, 0, mStackSize);
		mStack = t;
		mStackSize = newSize;
	}
	
	function resizeQue(newSize:Int)
	{
		var t = NativeArrayTools.alloc(newSize);
		mQue.blit(0, t, 0, mQueSize);
		mQue = t;
		mQueSize = newSize;
	}
}

#if generic
@:generic
#end
@:access(de.polygonal.ds.Graph)
@:dox(hide)
class GraphIterator<T> implements de.polygonal.ds.Itr<T>
{
	var mObject:Graph<T>;
	var mNode:GraphNode<T>;
	
	public function new(x:Graph<T>)
	{
		mObject = x;
		reset();
	}
	
	public function free()
	{
		mObject = null;
		mNode = null;
	}
	
	public inline function reset():Itr<T>
	{
		mNode = mObject.mNodeList;
		return this;
	}
	
	public inline function hasNext():Bool
	{
		return mNode != null;
	}
	
	public inline function next():T
	{
		var x = mNode.val;
		mNode = mNode.next;
		return x;
	}
	
	public function remove()
	{
		throw "unsupported operation";
	}
}

#if generic
@:generic
#end
@:access(de.polygonal.ds.Graph)
@:dox(hide)
class GraphNodeIterator<T> implements de.polygonal.ds.Itr<GraphNode<T>>
{
	var mObject:Graph<T>;
	var mNode:GraphNode<T>;
	
	public function new(x:Graph<T>)
	{
		mObject = x;
		reset();
	}
	
	public inline function reset():Itr<GraphNode<T>>
	{
		mNode = mObject.mNodeList;
		return this;
	}
	
	public inline function hasNext():Bool
	{
		return mNode != null;
	}
	
	public inline function next():GraphNode<T>
	{
		var x = mNode;
		mNode = mNode.next;
		return x;
	}
	
	public function remove()
	{
		throw "unsupported operation";
	}
}

#if generic
@:generic
#end
@:access(de.polygonal.ds.Graph)
@:dox(hide)
class GraphArcIterator<T> implements de.polygonal.ds.Itr<GraphArc<T>>
{
	var mObject:Graph<T>;
	var mNode:GraphNode<T>;
	var mArc:GraphArc<T>;
	
	public function new(x:Graph<T>)
	{
		mObject = x;
		reset();
	}
	
	public inline function reset():Itr<GraphArc<T>>
	{
		mNode = mObject.mNodeList;
		mArc = mNode.arcList;
		return this;
	}
	
	public inline function hasNext():Bool
	{
		return mArc != null && mNode != null;
	}
	
	public inline function next():GraphArc<T>
	{
		var x = mArc;
		mArc = mArc.next;
		
		if (mArc == null)
		{
			mNode = mNode.next;
			if (mNode != null) mArc = mNode.arcList;
		}
		return x;
	}
	
	public function remove()
	{
		throw "unsupported operation";
	}
}