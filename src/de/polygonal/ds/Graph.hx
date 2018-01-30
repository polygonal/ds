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

import de.polygonal.ds.tools.ArrayTools;
import de.polygonal.ds.tools.Assert.assert;

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
		
		_If this value is true, nested iterations will fail as only one iteration is allowed at a time._
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
	#end
	
	public function new()
	{
		mStack = NativeArrayTools.alloc(mStackSize);
		mQue = NativeArrayTools.alloc(mQueSize);
		
		#if debug
		mBusy = false;
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
		Wraps `val` in a `GraphNode` object and adds the newly created node to this graph.
		
		Shortcut for:
			var node = new GraphNode<String>("value");
			myGraph.addNode(node);
		
		@return the `GraphNode` object storing `val`.
	**/
	public function add(val:T):GraphNode<T>
	{
		return addNode(new GraphNode<T>(val));
	}
	
	/**
		Adds the node `node` to this graph and returns `node`.
		
		Silently fails if the node was already added to this graph.
	**/
	public function addNode(node:GraphNode<T>):GraphNode<T>
	{
		if (node.mGraph != null) return node;
		
		mSize++;
		node.next = mNodeList;
		if (node.next != null) node.next.prev = node;
		mNodeList = node;
		node.mGraph = this;
		return node;
	}
	
	/**
		Removes `node` from this graph.
		
		This clears all outgoing and incoming arcs and removes `node` from the node list.
		Silently fails if `node` was already removed from this graph.
	**/
	public function removeNode(node:GraphNode<T>):Graph<T>
	{
		if (size == 0 || node.mGraph == null) return this;
		
		unlink(node);
		
		if (node.prev != null) node.prev.next = node.next;
		if (node.next != null) node.next.prev = node.prev;
		if (mNodeList == node) mNodeList = node.next;
		mSize--;
		node.mGraph = null;
		return this;
	}
	
	/**
		Creates an uni-directional link between two nodes.
		This creates an arc pointing from `source` to `target`.
		
		The newly created arc can be accessed via `source.arcList`.
	**/
	public function addSingleArc(source:GraphNode<T>, target:GraphNode<T>):Graph<T>
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
						sourceNode.addArc(walker);
						break;
					}
					walker = walker.next;
				}
				break;
			}
			walker = walker.next;
		}
		return this;
	}
	
	/**
		Creates an uni-directional link between two nodes.
		This creates two arcs; an arc pointing from `source` to `target` and vv.
		
		The newly created arcs can be accessed via `source.arcList` (pointing to `target`) and `target.arcList` (pointing to `source`).
	**/
	public function addMutualArc(source:GraphNode<T>, target:GraphNode<T>):Graph<T>
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
						sourceNode.addArc(walker);
						walker.addArc(sourceNode);
						break;
					}
					walker = walker.next;
				}
				break;
			}
			walker = walker.next;
		}
		return this;
	}
	
	/**
		Isolates `node` from this graph by unlinking it from all outgoing and incoming arcs.
		
		The size remains unchanged as the node is not removed from the graph.
		Silently fails if `node` was not added to this graph.
		@return the disconnected graph node.
	**/
	public function unlink(node:GraphNode<T>):GraphNode<T>
	{
		assert(node != null, "node is null");
		
		if (node.mGraph == null) return node;
		
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
		
		Call this method to start a fresh traversal.
	**/
	public function clearMarks():Graph<T>
	{
		var node = mNodeList;
		while (node != null)
		{
			node.marked = false;
			node = node.next;
		}
		return this;
	}
	
	/**
		Clears the parent pointers on all graph nodes.
	**/
	public function clearParent():Graph<T>
	{
		var node = mNodeList;
		while (node != null)
		{
			node.parent = null;
			node = node.next;
		}
		return this;
	}
	
	/**
		Performs an iterative depth-first search (DFS).
		@param preflight if true, an extra traversal is performed before the actual traversal runs.
		The first pass visits all elements and calls `element.visit()` with the `preflight` parameter set to true.
		In this pass the return value determines whether the element will be processed (true) or
		excluded (false) from the final traversal, which is the second pass (`preflight` parameter set to false).
		The same applies when using a `process` function.
		@param seed the starting point of the traversal. If omitted, the first node in the list of graph nodes is used.
		@param process a function that is invoked for every traversed node.
		<br/>The parameters are:
		<ul>
		<li>a reference to the visited node.</li>
		<li>the `preflight` flag.</li>
		<li>custom data specified by the `userData` parameter (default is null).</li>
		</ul>
		Once `process` returns false, the traversal stops immediately and no further nodes are examined (termination condition).
		If omitted, `element.visit()` is used.
		<br/>_In this case the elements of all nodes have to implement `Visitable`._
		@param userData custom data that is passed to every visited node via `process` or `element.visit()`. If omitted, null is used.
		@param recursive if true, performs a recursive traversal (default traversal style is iterative).
	**/
	public function dfs(preflight:Bool = false, seed:GraphNode<T> = null, process:GraphNode<T>->Bool->Dynamic->Bool = null, userData:Dynamic = null, recursive:Bool = false):Graph<T>
	{
		if (size == 0) return this;
		
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
			if (c == max) s = resizeStack(max = max * 2);
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
					var v:Visitable = cast seed.val;
					if (v.visit(true, userData))
						dfsRecursiveVisit(seed, true, userData);
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
						return this;
					}
					
					while (c > 0)
					{
						n = popOffStack();
						
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
						dfsRecursiveProcess(seed, process, true, userData);
				}
				else
				{
					var n = s.get(0);
					if (!process(n, true, userData))
					{
						#if debug
						mBusy = false;
						#end
						return this;
					}
					
					while (c > 0)
					{
						n = popOffStack();
						
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
					dfsRecursiveVisit(seed, false, userData);
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
					dfsRecursiveProcess(seed, process, false, userData);
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
		
		return this;
	}
	
	/**
		Performs an iterative breadth-first search (BFS).
		@param preflight if true, an extra traversal is performed before the actual traversal runs.
		The first pass visits all elements and calls `element.visit()` with the `preflight` parameter set to true.
		In this pass the return value determines whether the element will be processed (true) or
		excluded (false) from the final traversal, which is the second pass (`preflight` parameter set to false).
		The same applies when using a `process` function.
		@param seed the starting point of the traversal. If omitted, the first node in the list of graph nodes is used.
		@param process a function that is invoked for every traversed node.
		<br/>The parameters are:
		<ul>
		<li>a reference to the visited node.</li>
		<li>the `preflight` flag.</li>
		<li>custom data specified by the `userData` parameter (default is null).</li>
		</ul>
		Once `process` returns false, the traversal stops immediately and no further nodes are examined (termination condition).
		If omitted, `element.visit()` is used.
		<br/>_In this case the elements of all nodes have to implement `Visitable`._
		@param userData custom data that is passed to every visited node via `process` or `element.visit()`. If omitted, null is used.
	**/
	public function bfs(preflight:Bool = false, seed:GraphNode<T> = null, process:GraphNode<T>->Bool->Dynamic->Bool = null, userData:Dynamic = null):Graph<T>
	{
		if (size == 0) return this;
		
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
					return this;
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
						return this;
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
					return this;
				}
				
				while (c > 0)
				{
					n = getQue(front);
					if (!process(n, false, userData))
					{
						#if debug
						mBusy = false;
						#end
						return this;
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
						return this;
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
						return this;
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
		
		return this;
	}
	
	/**
		Performs an iterative depth-limited breadth-first search (DLBFS).
		@param maxDepth a `maxDepth` value of 1 means that only all direct neighbors of `seed` are visited.
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
		_In this case the elements of all nodes have to implement `Visitable`._
		@param userData custom data that is passed to every visited node via `process` or `element.visit()`. If omitted, null is used.
	**/
	public function dlbfs(maxDepth:Int, preflight:Bool = false, seed:GraphNode<T> = null, process:GraphNode<T>->Bool->Dynamic->Bool = null, userData:Dynamic = null):Graph<T>
	{
		if (size == 0) return this;
		
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
					return this;
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
						return this;
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
					return this;
				}
				
				while (c > 0)
				{
					n = getQue(front);
					if (!process(n, false, userData))
					{
						#if debug
						mBusy = false;
						#end
						return this;
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
						return this;
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
						m.parent = n;
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
						return this;
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
						m.parent = n;
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
		
		return this;
	}
	
	/**
		Calls 'f` on all elements in preorder.
	**/
	public inline function iter(f:T->Void):Graph<T>
	{
		assert(f != null);
		var node = mNodeList;
		while (node != null)
		{
			f(node.val);
			node = node.next;
		}
		return this;
	}
	
	/**
		Serializes the graph, outputting two arrays: the first one stores all node values, while the second one
		contains a list of indices describing how the nodes are connected via arcs.
		
		Example:
			class Element {
			    public var name:String;
			    public function new(name:String) {
			        this.name = name;
			    }
			}
			
			...
			
			var graph = new Graph<Element>();
			var a = graph.createNode(new Element("a"));
			var b = graph.createNode(new Element("b"));
			var c = graph.createNode(new Element("c"));
			graph.addNode(a);
			graph.addNode(b);
			graph.addNode(c);
			graph.addMutualArc(a, b);
			graph.addMutualArc(b, c);
			graph.addMutualArc(a, c);
			
			//serialize
			var data = graph.serialize(function(nodeValue:Element) return nodeValue.name); //only store name property
			trace(data.arcs); //[0,2,0,1,1,0,1,2,2,0,2,1]
			trace(data.vals); //["c","b","a"]
			
			//unserialize
			var graph = new Graph<Element>();
			graph.unserialize(data, function(val:String) return new Element(val));
	**/
	public function serialize(getVal:T->Dynamic):{arcs:Array<Int>, vals:Array<Dynamic>}
	{
		var vals = [];
		var arcs = [];
		var node = getNodeList(), arc;
		
		var indexLut = new haxe.ds.IntMap<Int>();
		
		var i = 0;
		while (node != null)
		{
			indexLut.set(node.key, i++);
			node = node.next;
		}
		
		i = 0;
		node = getNodeList();
		while (node != null)
		{
			vals[i] = getVal(node.val);
			arc = node.arcList;
			while (arc != null)
			{
				arcs.push(i);
				arcs.push(indexLut.get(arc.node.key));
				arc = arc.next;
			}
			node = node.next;
			i++;
		}
		return {arcs: arcs, vals: vals};
	}
	
	/**
		See `this.serialize`.
	**/
	public function unserialize(data:{arcs:Array<Int>, vals:Array<Dynamic>}, setVal:Dynamic->T)
	{
		clear(true);
		
		var nodes = [];
		var vals = data.vals;
		var i = 0;
		var k = vals.length;
		while (i < k) nodes.push(new GraphNode(setVal(vals[i++])));
		
		i = k;
		while (i > 0) addNode(nodes[--i]);
		
		var arcs = data.arcs;
		i = arcs.length;
		while (i > 0)
		{
			var target = arcs[--i];
			var source = arcs[--i];
			addSingleArc(nodes[source], nodes[target]);
		}
	}
	
	/**
		Prints out all elements.
	**/
	#if !no_tostring
	public function toString():String
	{
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
	}
	#end
	
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
		
		borrowArc = null;
		returnArc = null;
	}
	
	/**
		Returns true if this graph contains a node storing `val`.
	**/
	public function contains(val:T):Bool
	{
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
				var hook1 = node.next;
				var arc = node.arcList;
				while (arc != null)
				{
					var hook2 = arc.next;
					arc.free();
					arc = hook2;
				}
				node.free();
				node = hook1;
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
				m = copy.add(n.val);
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
				
				m = copy.add(cast(n.val, Cloneable<Dynamic>).clone());
				t[i++] = m;
				n = n.next;
			}
		}
		else
		{
			while (n != null)
			{
				m = copy.add(copier(n.val));
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
				m.addArc(a.node, a.userData);
				a = a.next;
			}
			n = n.next;
		}
		return copy;
	}
	
	function dfsRecursiveVisit(node:GraphNode<T>, preflight:Bool, userData:Dynamic):Bool
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
					if (!dfsRecursiveVisit(m, true, userData))
						return false;
			}
			else
			{
				if (!dfsRecursiveVisit(m, false, userData))
					return false;
			}
			
			a = a.next;
		}
		return true;
	}
	
	function dfsRecursiveProcess(node:GraphNode<T>, process:GraphNode<T>->Bool->Dynamic->Bool = null, preflight:Bool, userData:Dynamic):Bool
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
					if (!dfsRecursiveProcess(m, process, true, userData))
						return false;
			}
			else
			{
				if (!dfsRecursiveProcess(m, process, false, userData))
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
		return mStack;
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