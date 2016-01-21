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
	A weighted graph
	
	A graph is composed of `GraphNode` and `GraphArc` objects.
	
	See <a href="http://lab.polygonal.de/?p=185" target="mBlank">http://lab.polygonal.de/?p=185/</a>
	
	_<o>Worst-case running time in Big O notation</o>_
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
	public var key:Int;
	
	/**
		The maximum allowed size of this graph.
		
		Once the maximum size is reached, adding an element will fail with an error (debug only).
		
		A value of -1 indicates that the size is unbound.
		
		<warn>Always equals -1 in release mode.</warn>
	**/
	public var maxSize:Int;
	
	/**
		If true, automatically clears the mark-flag on all graph nodes prior to starting a new traversal.
		
		Default is false.
	**/
	public var autoClearMarks:Bool;
	
	/**
		If true, reuses the iterator object instead of allocating a new one when calling ``iterator()``.
		
		The default is false.
		
		<warn>If true, nested iterations are likely to fail as only one iteration is allowed at a time.</warn>
	**/
	public var reuseIterator:Bool;
	
	/**
		If specified, ``borrowArc()`` is called in order to create `GraphArc` objects.
		
		Useful for pooling `GraphArc` objects.
		
		Default is null.
	**/
	public var borrowArc:GraphNode<T>->Float->GraphArc<T>;
	
	/**
		A function pointer responsible for returning `GraphArc` objects.
		
		Required if ``borrowArc`` is specified.
		
		Default is null.
	**/
	public var returnArc:GraphArc<T>->Void;
	
	var mNodeList:GraphNode<T>;
	var mSize:Int;
	
	var mStack:Array<GraphNode<T>>;
	var mQue:Array<GraphNode<T>>;
	var mIterator:GraphIterator<T>;
	
	#if debug
	var mBusy:Bool;
	var mNodeSet:Set<GraphNode<T>>;
	#end
	
	/**
		@param maxSize the maximum allowed size of this graph.
		The default value of -1 indicates that there is no upper limit.
	**/
	public function new(maxSize = -1)
	{
		#if debug
		this.maxSize = (maxSize == -1) ? M.INT32_MAX : maxSize;
		#else
		this.maxSize = -1;
		#end
		
		clear();
		
		mSize = 0;
		mIterator = null;
		
		#if debug
		mBusy = false;
		mNodeSet = new ListSet<GraphNode<T>>();
		#end
		
		autoClearMarks = false;
		key = HashKey.next();
		reuseIterator = false;
	}
	
	/**
		The graph nodes stored as a doubly linked list of `GraphNode` objects.
		<o>1</o>
		@return the first node in a list of `GraphNode` objects or null if the graph is empty.
	**/
	inline public function getNodeList():GraphNode<T>
	{
		return mNodeList;
	}
	
	/**
		Finds and returns the node storing the element `x` or null if such a node does not exist.
		<o>n</o>
	**/
	public function findNode(x:T):GraphNode<T>
	{
		var found = false;
		var n = mNodeList;
		while (n != null)
		{
			if (n.val == x)
			{
				found = true;
				break;
			}
			n = n.next;
		}
		return found ? n : null;
	}
	
	/**
		Creates and returns a node object storing the element `x`.
		<o>1</o>
	**/
	public function createNode(x:T):GraphNode<T>
	{
		return new GraphNode<T>(this, x);
	}
	
	/**
		Adds the node `x` to this graph.
		<o>1</o>
		<assert>``size()`` equals maxSize</assert>
	**/
	public function addNode(x:GraphNode<T>):GraphNode<T>
	{
		#if debug
		if (maxSize != -1)
			assert(size() < maxSize, 'size equals max size ($maxSize)');
		#end
		
		assert(mNodeSet.set(x), "node exists");
		
		mSize++;
		
		x.next = mNodeList;
		if (x.next != null) x.next.prev = x;
		mNodeList = x;
		
		return x;
	}
	
	/**
		Removes the node `x` from this graph.
		
		This clears all outgoing and incoming arcs and removes `x` from the node list.
		<o>1</o>
		<assert>graph is empty</assert>
	**/
	public function removeNode(x:GraphNode<T>)
	{
		assert(size() > 0, "graph is empty");
		
		unlink(x);
		
		if (x.prev != null) x.prev.next = x.next;
		if (x.next != null) x.next.prev = x.prev;
		if (mNodeList == x) mNodeList = x.next;
		mSize--;
	}
	
	/**
		Creates an uni-directional link between two nodes with a weight of `cost` (default is 1.0).
		
		This creates an arc pointing from the `source` node to the `target` node.
		<o>n</o>
		<assert>`source` or `target` is null</assert>
		<assert>`source` equals `target`</assert>
	**/
	public function addSingleArc(source:GraphNode<T>, target:GraphNode<T>, cost = 1.)
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
		<o>n</o>
		<assert>`source` or `target` is null</assert>
		<assert>`source` equals `target`</assert>
	**/
	public function addMutualArc(source:GraphNode<T>, target:GraphNode<T>, cost = 1.)
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
		<o>(n&sup2; - n) / 2</o>
		<assert>`node` is null</assert>
		<assert>graph is empty</assert>
		<assert>`node` does not belong to this graph</assert>
		@return the disconnected graph node.
	**/
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
		<o>n</o>
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
		<o>n</o>
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
		The first pass visits all elements and calls ``element::visit()`` with the `preflight` parameter set to true.
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
		If omitted, ``element::visit()`` is used.
		<warn>In this case the elements of all nodes have to implement `Visitable`.</warn>
		@param userData custom data that is passed to every visited node via `process` or ``element::visit()``. If omitted, null is used.
		@param recursive if true, performs a recursive traversal (default traversal style is iterative).
	**/
	public function DFS(preflight = false, seed:GraphNode<T> = null, process:GraphNode<T>->Bool->Dynamic->Bool = null, userData:Dynamic = null, recursive = false)
	{
		if (mSize == 0) return;
		
		#if debug
		assert(mBusy == false, "recursive call to iterative DFS");
		mBusy = true;
		#end
		
		if (autoClearMarks) clearMarks();
		
		var c = 1;
		
		if (seed == null) seed = mNodeList;
		mStack[0] = seed;
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
					var n = mStack[0];
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
						var n = mStack[--c];
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
								mStack[c++] = a.node;
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
					var n = mStack[0];
					if (!process(n, true, userData))
					{
						#if debug
						mBusy = false;
						#end
						return;
					}
					
					while (c > 0)
					{
						var n = mStack[--c];
						
						if (n.marked) continue;
						n.marked = true;
						
						if (!process(n, false, userData)) break;
						
						var a = n.arcList;
						while (a != null)
						{
							a.node.parent = n;
							a.node.depth = n.depth + 1;
							
							if (process(a.node, true, userData))
								mStack[c++] = a.node;
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
						var n = mStack[--c];
						if (n.marked) continue;
						n.marked = true;
						
						v = n.val;
						if (!v.visit(false, userData)) break;
						
						var a = n.arcList;
						while (a != null)
						{
							mStack[c++] = a.node;
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
						var n = mStack[--c];
						if (n.marked) continue;
						n.marked = true;
						
						if (!process(n, false, userData)) break;
						
						var a = n.arcList;
						while (a != null)
						{
							mStack[c++] = a.node;
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
		The first pass visits all elements and calls ``element::visit()`` with the `preflight` parameter set to true.
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
		If omitted, ``element::visit()`` is used.
		<warn>In this case the elements of all nodes have to implement `Visitable`.</warn>
		@param userData custom data that is passed to every visited node via `process` or ``element::visit()``. If omitted, null is used.
	**/
	public function BFS(preflight = false, seed:GraphNode<T> = null, process:GraphNode<T>->Bool->Dynamic->Bool = null, userData:Dynamic = null)
	{
		if (mSize == 0) return;
		
		#if debug
		assert(mBusy == false, "recursive call to iterative BFS");
		mBusy = true;
		#end
		
		if (autoClearMarks) clearMarks();
		
		var front = 0;
		var c = 1;
		
		if (seed == null) seed = mNodeList;
		mQue[0] = seed;
		
		seed.marked = true;
		seed.parent = seed;
		seed.depth = 0;
		
		if (preflight)
		{
			if (process == null)
			{
				var v:Dynamic = null;
				
				var n = mQue[front];
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
					n = mQue[front];
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
							mQue[c++ + front] = m;
						a = a.next;
					}
					front++;
					c--;
				}
			}
			else
			{
				var n = mQue[front];
				if (!process(n, true, userData))
				{
					#if debug
					mBusy = false;
					#end
					return;
				}
				
				while (c > 0)
				{
					n = mQue[front];
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
							mQue[c++ + front] = m;
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
					var n = mQue[front];
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
						
						mQue[c++ + front] = m;
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
					var n = mQue[front];
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
						
						mQue[c++ + front] = m;
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
		The first pass visits all elements and calls ``element::visit()`` with the `preflight` parameter set to true.
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
		If omitted, ``element::visit()`` is used.
		<warn>In this case the elements of all nodes have to implement `Visitable`.</warn>
		@param userData custom data that is passed to every visited node via `process` or ``element::visit()``. If omitted, null is used.
	**/
	public function DLBFS(maxDepth:Int, preflight = false, seed:GraphNode<T> = null, process:GraphNode<T>->Bool->Dynamic->Bool = null, userData:Dynamic = null)
	{
		if (mSize == 0) return;
		
		#if debug
		assert(mBusy == false, "recursive call to iterative BFS");
		mBusy = true;
		#end
		
		if (autoClearMarks) clearMarks();
		
		var front = 0;
		var c = 1;
		
		var node = mNodeList;
		while (node != null)
		{
			node.depth = 0;
			node = node.next;
		}
		
		if (seed == null) seed = mNodeList;
		mQue[0] = seed;
		
		seed.marked = true;
		seed.parent = seed;
		
		if (preflight)
		{
			if (process == null)
			{
				var v:Dynamic = null;
				
				var n = mQue[front];
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
					n = mQue[front];
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
								mQue[c++ + front] = m;
						}
						a = a.next;
					}
					front++;
					c--;
				}
			}
			else
			{
				var n = mQue[front];
				if (!process(n, true, userData))
				{
					#if debug
					mBusy = false;
					#end
					return;
				}
				
				while (c > 0)
				{
					n = mQue[front];
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
								mQue[c++ + front] = m;
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
					var n = mQue[front];
					
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
							mQue[c++ + front] = m;
						
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
					var n = mQue[front];
					
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
							mQue[c++ + front] = m;
						
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
		Returns a string representing the current object.
		
		Example:
		<pre class="prettyprint">
		var graph = new de.polygonal.ds.Graph<String>();
		var a = graph.addNode("a");
		var b = graph.addNode("b");
		var c = graph.addNode("c");
		graph.addSingleArc(a, b, 1.0);
		graph.addSingleArc(b, a, 1.0);
		graph.addMutualArc(a, c, 1.0);
		trace(graph);</pre>
		<pre class="console">
		{ Graph size: 3 }
		[
		  {GraphNode, val: c, connected to: a}
		  {GraphNode, val: b, connected to: a}
		  {GraphNode, val: a, connected to: c,b}
		]</pre>
	**/
	public function toString():String
	{
		var s = '{ Graph size: ${size()} }';
		if (isEmpty()) return s;
		s += "\n[\n";
		var node = mNodeList;
		while (node != null)
		{
			s += '  ${node.toString()}\n';
			node = node.next;
		}
		s += "]";
		return s;
	}
	
	/*///////////////////////////////////////////////////////
	// collection
	///////////////////////////////////////////////////////*/
	
	/**
		Destroys this object by explicitly nullifying all nodes, elements and pointers for GC'ing used resources.
		
		Improves GC efficiency/performance (optional).
		<o>n</o>
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
		
		for (i in 0...mStack.length) mStack[i] = null; mStack = null;
		for (i in 0...mQue.length) mQue[i] = null; mQue = null;
		
		mIterator = null;
		
		#if debug
		mNodeSet.free();
		mNodeSet = null;
		#end
	}
	
	/**
		Returns true if this graph contains a node storing the element `x`.
		<o>n</o>
	**/
	public function contains(x:T):Bool
	{
		var found = false;
		var node = mNodeList;
		while (node != null)
		{
			if (node.val == x)
				return true;
			node = node.next;
		}
		return false;
	}
	
	/**
		Removes all nodes storing the element `x`.
		
		Nodes and elements are nullified.
		<o>n</o>
		@return true if at least one node storing `x` was removed.
	**/
	public function remove(x:T):Bool
	{
		var found = false;
		var node = mNodeList;
		while (node != null)
		{
			var nextNode = node.next;
			
			if (node.val == x)
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
		
		<o>1 or n if `purge` is true</o>
		@param purge if true, explicitly nullifies nodes and elements upon removal.
		Improves GC efficiency/performance (optional).
	**/
	public function clear(purge = false)
	{
		if (purge)
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
		}
		
		mNodeList = null;
		mSize = 0;
		
		mStack = new Array<GraphNode<T>>();
		mQue = new Array<GraphNode<T>>();
	}
	
	/**
		Returns a new `GraphIterator` object to iterate over all elements stored in the graph nodes of this graph.
		
		The nodes are visited in a random order.
		
		See <a href="http://haxe.org/ref/iterators" target="mBlank">http://haxe.org/ref/iterators</a>
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
		Returns a new `GraphNodeIterator` object to iterate over all `GraphNode` objects in this graph.
		
		The nodes are visited in a random order.
		
		See <a href="http://haxe.org/ref/iterators" target="mBlank">http://haxe.org/ref/iterators</a>
	**/
	public function nodeIterator():Itr<GraphNode<T>>
	{
		return new GraphNodeIterator<T>(this);
	}
	
	/**
		Returns a new `GraphArcIterator` object to iterate over all `GraphArc` objects in this graph.
		
		The arcs are visited in a random order.
		
		See <a href="http://haxe.org/ref/iterators" target="mBlank">http://haxe.org/ref/iterators</a>
	**/
	public function arcIterator():Itr<GraphArc<T>>
	{
		return new GraphArcIterator<T>(this);
	}
	
	/**
		The total number of elements in this graph.
		
		Equals the number of graph nodes.
		<o>1</o>
	**/
	inline public function size():Int
	{
		return mSize;
	}
	
	/**
		Returns true if this graph is empty.
		<o>1</o>
	**/
	inline public function isEmpty():Bool
	{
		return mSize == 0;
	}
	
	/**
		Returns an unordered array containing all elements stored in the graph nodes of this graph.
	**/
	public function toArray():Array<T>
	{
		var a:Array<T> = ArrayUtil.alloc(size());
		var node = mNodeList;
		while (node != null)
		{
			a.push(node.val);
			node = node.next;
		}
		return a;
	}
	
	/**
		Returns an unordered `Vector<T>` object containing all elements stored in the graph nodes of this graph.
	**/
	public function toVector():Vector<T>
	{
		var v = new Vector<T>(size());
		var node = mNodeList;
		var i = 0;
		while (node != null)
		{
			v[i++] = node.val;
			node = node.next;
		}
		return v;
	}
	
	/**
		Duplicates this graph. Supports shallow (structure only) and deep copies (structure & elements).
		<assert>element is not of type `Cloneable`</assert>
		@param assign if true, the `copier` parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.
		If false, the ``clone()`` method is called on each element. <warn>In this case all elements have to implement `Cloneable`.</warn>
		@param copier a custom function for copying elements. Replaces ``element::clone()`` if `assign` is false.
	**/
	public function clone(assign = true, copier:T->T = null):Collection<T>
	{
		var copy = new Graph<T>(maxSize);
		if (mNodeList == null) return copy;
		
		var t = new Array<GraphNode<T>>();
		var i = 0;
		var n = mNodeList;
		
		if (assign)
		{
			while (n != null)
			{
				var m = copy.addNode(copy.createNode(n.val));
				t[i++] = m;
				n = n.next;
			}
		}
		else
		if (copier == null)
		{
			var c:Dynamic = null;
			while (n != null)
			{
				assert(Std.is(n.val, Cloneable), 'element is not of type Cloneable (${n.val})');
				
				c = n.val;
				var m = copy.addNode(copy.createNode(c.clone()));
				t[i++] = m;
				n = n.next;
			}
		}
		else
		{
			while (n != null)
			{
				var m = copy.addNode(copy.createNode(copier(n.val)));
				t[i++] = m;
				n = n.next;
			}
		}
		
		i = 0;
		n = mNodeList;
		while (n != null)
		{
			var m = t[i++];
			var a = n.arcList;
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
}

#if generic
@:generic
#end
@:access(de.polygonal.ds.Graph)
@:dox(hide)
class GraphIterator<T> implements de.polygonal.ds.Itr<T>
{
	var mF:Graph<T>;
	var mNode:GraphNode<T>;
	
	public function new(f:Graph<T>)
	{
		mF = f;
		reset();
	}
	
	inline public function reset():Itr<T>
	{
		mNode = mF.mNodeList;
		return this;
	}
	
	inline public function hasNext():Bool
	{
		return mNode != null;
	}
	
	inline public function next():T
	{
		var x = mNode.val;
		mNode = mNode.next;
		return x;
	}
	
	inline public function remove()
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
	var mF:Graph<T>;
	var mNode:GraphNode<T>;
	
	public function new(f:Graph<T>)
	{
		mF = f;
		reset();
	}
	
	inline public function reset():Itr<GraphNode<T>>
	{
		mNode = mF.mNodeList;
		return this;
	}
	
	inline public function hasNext():Bool
	{
		return mNode != null;
	}
	
	inline public function next():GraphNode<T>
	{
		var x = mNode;
		mNode = mNode.next;
		return x;
	}
	
	inline public function remove()
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
	var mF:Graph<T>;
	var mNode:GraphNode<T>;
	var mArc:GraphArc<T>;
	
	public function new(f:Graph<T>)
	{
		mF = f;
		reset();
	}
	
	inline public function reset():Itr<GraphArc<T>>
	{
		mNode = mF.mNodeList;
		mArc = mNode.arcList;
		return this;
	}
	
	inline public function hasNext():Bool
	{
		return mArc != null && mNode != null;
	}
	
	inline public function next():GraphArc<T>
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
	
	inline public function remove()
	{
		throw "unsupported operation";
	}
}