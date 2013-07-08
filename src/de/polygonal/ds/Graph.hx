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
 * <p>A weighted graph.</p>
 * <p>A graph is composed of <em>GraphNode</em> and <em>GraphArc</em> objects.</p>
 * <p>See <a href="http://lab.polygonal.de/?p=185" target="_blank">http://lab.polygonal.de/?p=185/</a></p>
 * <p><o>Worst-case running time in Big O notation</o></p>
 */
#if generic
@:generic
#end
class Graph<T> implements Collection<T>
{
	/**
	 * A unique identifier for this object.<br/>
	 * A hash table transforms this key into an index of an array element by using a hash function.<br/>
	 * <warn>This value should never be changed by the user.</warn>
	 */
	public var key:Int;
	
	/**
	 * The maximum allowed size of this graph.<br/>
	 * Once the maximum size is reached, adding an element will fail with an error (debug only).<br/>
	 * A value of -1 indicates that the size is unbound.<br/>
	 * <warn>Always equals -1 in release mode.</warn>
	 */
	public var maxSize:Int;
	
	/**
	 * If true, automatically clears the mark-flag on all graph nodes prior to starting a new traversal.<br/>
	 * Default is false;
	 */
	public var autoClearMarks:Bool;
	
	/**
	 * If true, reuses the iterator object instead of allocating a new one when calling <code>iterator()</code>.<br/>
	 * The default is false.<br/>
	 * <warn>If true, nested iterations are likely to fail as only one iteration is allowed at a time.</warn>
	 */
	public var reuseIterator:Bool;
	
	/**
	 * If specified, <code>borrowArc()</code> is called in order to create <em>GraphArc</em> objects.<br/>
	 * Useful for pooling <em>GraphArc</em> objects.
	 * Default is null.
	 */
	public var borrowArc:GraphNode<T>->Float->GraphArc<T>;
	
	/**
	 * A function pointer responsible for returning <em>GraphArc</em> objects.<br/>
	 * Required if <code>borrowArc</code> is specified.
	 * Default is null.
	 */
	public var returnArc:GraphArc<T>->Void;
	
	var _nodeList:GraphNode<T>;
	var _size:Int;
	
	var _stack:Array<GraphNode<T>>;
	var _que:Array<GraphNode<T>>;
	var _iterator:GraphIterator<T>;
	
	#if debug
	var _busy:Bool;
	var _nodeSet:Set<GraphNode<T>>;
	#end
	
	/**
	 * @param maxSize the maximum allowed size of this graph.<br/>
	 * The default value of -1 indicates that there is no upper limit.
	 */
	public function new(maxSize = -1)
	{
		#if debug
		this.maxSize = (maxSize == -1) ? M.INT32_MAX : maxSize;
		#else
		this.maxSize = -1;
		#end
		
		clear();
		
		_size = 0;
		_iterator = null;
		
		#if debug
		_busy = false;
		_nodeSet = new ListSet<GraphNode<T>>();
		#end
		
		autoClearMarks = false;
		key = HashKey.next();
		reuseIterator = false;
	}
	
	/** 
	 * The graph nodes stored as a doubly linked list of <em>GraphNode</em> objects.
	 * <o>1</o>
	 * @return the first node in a list of <em>GraphNode</em> objects or null if the graph is empty.
	 */
	inline public function getNodeList():GraphNode<T>
	{
		return _nodeList;
	}
	
	/**
	 * Finds and returns the node storing the element <code>x</code> or null if such a node does not exist.
	 * <o>n</o>
	 */
	inline public function findNode(x:T):GraphNode<T>
	{
		var found = false;
		var n = _nodeList;
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
	 * Creates and returns a node object storing the element <code>x</code>.
	 * <o>1</o>
	 */
	public function createNode(x:T):GraphNode<T>
	{
		return new GraphNode<T>(this, x);
	}
	
	/**
	 * Adds the node <code>x</code> to this graph.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError size() equals maxSize (debug only).
	 */
	public function addNode(x:GraphNode<T>):GraphNode<T>
	{
		#if debug
		if (maxSize != -1)
			assert(size() < maxSize, 'size equals max size ($maxSize)');
		assert(_nodeSet.set(x), "node exists");
		#end
		
		_size++;
		
		x.next = _nodeList;
		if (x.next != null) x.next.prev = x;
		_nodeList = x;
		
		return x;
	}
	
	/**
	 * Removes the node <code>x</code> from this graph.<br/>
	 * This clears all outgoing and incoming arcs and removes <code>x</code> from the node list.
	 * <o>1</o>
	 * @throws de.polygonal.ds.error.AssertError graph is empty (debug only).
	 */
	public function removeNode(x:GraphNode<T>)
	{
		#if debug
		assert(size() > 0, "graph is empty");
		#end
		
		unlink(x);
		
		if (x.prev != null) x.prev.next = x.next;
		if (x.next != null) x.next.prev = x.prev;
		if (_nodeList == x) _nodeList = x.next;
		_size--;
	}
	
	/**
	 * Creates an uni-directional link between two nodes with a weight of <code>cost</code> (default is 1.0).<br/>
	 * This creates an arc pointing from the <code>source</code> node to the <code>target</code> node.
	 * <o>n</o>
	 * @throws de.polygonal.ds.error.AssertError <code>source</code> or <code>target</code> is null (debug only).
	 * @throws de.polygonal.ds.error.AssertError <code>source</code> equals <code>target</code> (debug only).
	 */
	public function addSingleArc(source:GraphNode<T>, target:GraphNode<T>, cost = 1.)
	{
		#if debug
		assert(source != null, "source is null");
		assert(target != null, "target is null");
		assert(source != target, "source equals target");
		#end
		
		var walker = _nodeList;
		while (walker != null)
		{
			if (walker == source)
			{
				var sourceNode = walker;
				walker = _nodeList;
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
	 * Creates a bi-directional link between two nodes with a weight of <code>cost</code> (default is 1.0).<br/>
	 * This creates two arcs - an arc that points from the <code>source</code> node to the <code>target</code> node and vice versa.
	 * <o>n</o>
	 * @throws de.polygonal.ds.error.AssertError <code>source</code> or <code>target</code> is null (debug only).
	 * @throws de.polygonal.ds.error.AssertError <code>source</code> equals <code>target</code> (debug only).
	 */
	public function addMutualArc(source:GraphNode<T>, target:GraphNode<T>, cost = 1.)
	{
		#if debug
		assert(source != null, "source is null");
		assert(target != null, "target is null");
		assert(source != target, "source equals target");
		assert(source.getArc(target) == null, "arc from source to target already exists");
		assert(target.getArc(source) == null, "arc from target to source already exists");
		#end
		
		var walker = _nodeList;
		while (walker != null)
		{
			if (walker == source)
			{
				var sourceNode = walker;
				walker = _nodeList;
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
	 * Isolates <code>node</code> from this graph by unlinking it from all outgoing and incoming arcs.<br/>
	 * The size remains unchanged as the node is not removed from the graph.
	 * <o>(n&sup2; - n) / 2</o>
	 * @return the disconnected graph node.
	 * @throws de.polygonal.ds.error.AssertError <code>node</code> is null (debug only).
	 * @throws de.polygonal.ds.error.AssertError graph is empty (debug only).
	 * @throws de.polygonal.ds.error.AssertError <code>node</code> does not belong to this graph (debug only).
	 */
	public function unlink(node:GraphNode<T>):GraphNode<T>
	{
		#if debug
		assert(_nodeList != null, "graph is empty");
		assert(_nodeSet.has(node), "unknown node");
		assert(node != null, "node is null");
		#end
		
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
	 * Clears the mark-flag on all graph nodes that were set in a BFS/DFS traversal.<br/>
	 * <warn>Call this method to start a fresh traversal.</warn>
	 * <o>n</o>
	 */
	inline public function clearMarks()
	{
		var node = _nodeList;
		while (node != null)
		{
			node.marked = false;
			node = node.next;
		}
	}
	
	/**
	 * Clears the parent pointers on all graph nodes.
	 * <o>n</o>
	 */
	inline public function clearParent()
	{
		var node = _nodeList;
		while (node != null)
		{
			node.parent = null;
			node = node.next;
		}
	}
	
	/**
	 * Performs an iterative depth-first search (DFS).
	 * @param preflight if true, an extra traversal is performed before the actual traversal runs.
	 * The first pass visits all elements and calls element.<em>visit()</em> with the <code>preflight</code> parameter set to true.
	 * In this pass the return value determines whether the element will be processed (true) or
	 * excluded (false) from the final traversal, which is the second pass (<code>preflight</code> parameter set to false).
	 * The same applies when using a <code>process</code> function.
	 * @param seed the starting point of the traversal. If omitted, the first node in the list of graph nodes is used.
	 * @param process a function that is invoked for every traversed node. The parameters are:
	 * <ol>
	 * <li>a reference to the visited node.</li>
	 * <li>the <code>preflight</code> flag.</li>
	 * <li>custom data specified by the <code>userData</code> parameter (default is null).</li>
	 * </ol>
	 * Once <code>process</code> returns false, the traversal stops immediately and no further nodes are examined (termination condition).<br/>
	 * If omitted, element.<em>visit()</em> is used.
	 * <warn>In this case the elements of all nodes have to implement <em>Visitable</em>.</warn><br/>
	 * @param userData custom data that is passed to every visited node via <code>process</code> or element.<em>visit()</em>. If omitted, null is used.
	 * @param recursive if true, performs a recursive traversal (default traversal style is iterative).
	 */
	public function DFS(preflight = false, seed:GraphNode<T> = null, process:GraphNode<T>->Bool->Dynamic->Bool = null, userData:Dynamic = null, recursive = false)
	{
		if (_size == 0) return;
		
		#if debug
		assert(_busy == false, "recursive call to iterative DFS");
		_busy = true;
		#end
		
		if (autoClearMarks) clearMarks();
		
		var c = 1;
		
		if (seed == null) seed = _nodeList;
		_stack[0] = seed;
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
						_DFSRecursiveVisit(seed, true, userData);
				}
				else
				{
					var v:Dynamic = null;
					var n = _stack[0];
					v = n.val;
					if (!v.visit(true, userData))
					{
						#if debug
						_busy = false;
						#end
						return;
					}
					
					while (c > 0)
					{
						var n = _stack[--c];
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
								_stack[c++] = a.node;
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
						_DFSRecursiveProcess(seed, process, true, userData);
				}
				else
				{
					var n = _stack[0];
					if (!process(n, true, userData))
					{
						#if debug
						_busy = false;
						#end
						return;
					}
					
					while (c > 0)
					{
						var n = _stack[--c];
						
						if (n.marked) continue;
						n.marked = true;
						
						if (!process(n, false, userData)) break;
						
						var a = n.arcList;
						while (a != null)
						{
							a.node.parent = n;
							a.node.depth = n.depth + 1;
							
							if (process(a.node, true, userData))
								_stack[c++] = a.node;
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
					_DFSRecursiveVisit(seed, false, userData);
				else
				{
					var v:Dynamic = null;
					while (c > 0)
					{
						var n = _stack[--c];
						if (n.marked) continue;
						n.marked = true;
						
						v = n.val;
						if (!v.visit(false, userData)) break;
						
						var a = n.arcList;
						while (a != null)
						{
							_stack[c++] = a.node;
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
					_DFSRecursiveProcess(seed, process, false, userData);
				else
				{
					while (c > 0)
					{
						var n = _stack[--c];
						if (n.marked) continue;
						n.marked = true;
						
						if (!process(n, false, userData)) break;
						
						var a = n.arcList;
						while (a != null)
						{
							_stack[c++] = a.node;
							a.node.parent = n;
							a.node.depth = n.depth + 1;
							a = a.next;
						}
					}
				}
			}
		}
		
		#if debug
		_busy = false;
		#end
	}
	
	/**
	 * Performs an iterative breadth-first search (BFS).
	 * @param preflight if true, an extra traversal is performed before the actual traversal runs.
	 * The first pass visits all elements and calls element.<em>visit()</em> with the <code>preflight</code> parameter set to true.
	 * In this pass the return value determines whether the element will be processed (true) or
	 * excluded (false) from the final traversal, which is the second pass (<code>preflight</code> parameter set to false).
	 * The same applies when using a <code>process</code> function.
	 * @param seed the starting point of the traversal. If omitted, the first node in the list of graph nodes is used.
	 * @param process a function that is invoked for every traversed node. The parameters are:
	 * <ol>
	 * <li>a reference to the visited node.</li>
	 * <li>the <code>preflight</code> flag.</li>
	 * <li>custom data specified by the <code>userData</code> parameter (default is null).</li>
	 * </ol>
	 * Once <code>process</code> returns false, the traversal stops immediately and no further nodes are examined (termination condition).<br/>
	 * If omitted, element.<em>visit()</em> is used.
	 * <warn>In this case the elements of all nodes have to implement Visitable.</warn><br/>
	 * @param userData custom data that is passed to every visited node via <code>process</code> or element.<em>visit()</em>. If omitted, null is used.
	 */
	public function BFS(preflight = false, seed:GraphNode<T> = null, process:GraphNode<T>->Bool->Dynamic->Bool = null, userData:Dynamic = null)
	{
		if (_size == 0) return;
		
		#if debug
		assert(_busy == false, "recursive call to iterative BFS");
		_busy = true;
		#end
		
		if (autoClearMarks) clearMarks();
		
		var front = 0;
		var c = 1;
		
		if (seed == null) seed = _nodeList;
		_que[0] = seed;
		
		seed.marked = true;
		seed.parent = seed;
		seed.depth = 0;
		
		if (preflight)
		{
			if (process == null)
			{
				var v:Dynamic = null;
				
				var n = _que[front];
				v = n.val;
				if (!v.visit(true, userData))
				{
					#if debug
					_busy = false;
					#end
					return;
				}
				
				while (c > 0)
				{
					n = _que[front];
					v = n.val;
					if (!v.visit(false, userData))
					{
						#if debug
						_busy = false;
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
							_que[c++ + front] = m;
						a = a.next;
					}
					front++;
					c--;
				}
			}
			else
			{
				var n = _que[front];
				if (!process(n, true, userData))
				{
					#if debug
					_busy = false;
					#end
					return;
				}
				
				while (c > 0)
				{
					n = _que[front];
					if (!process(n, false, userData))
					{
						#if debug
						_busy = false;
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
							_que[c++ + front] = m;
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
					var n = _que[front];
					v = n.val;
					if (!v.visit(false, userData))
					{
						#if debug
						_busy = false;
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
						
						_que[c++ + front] = m;
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
					var n = _que[front];
					if (!process(n, false, userData))
					{
						#if debug
						_busy = false;
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
						
						_que[c++ + front] = m;
						a = a.next;
					}
					front++;
					c--;
				}
			}
		}
		
		#if debug
		_busy = false;
		#end
	}
	
	/**
	 * Performs an iterative depth-limited breadth-first search (DLBFS).
	 * @param maxDepth A <code>maxDepth</code> value of 1 means that only all direct neighbors of <code>seed</code> are visited.
	 * @param preflight if true, an extra traversal is performed before the actual traversal runs.
	 * The first pass visits all elements and calls element.<em>visit()</em> with the <code>preflight</code> parameter set to true.
	 * In this pass the return value determines whether the element will be processed (true) or
	 * excluded (false) from the final traversal, which is the second pass (<code>preflight</code> parameter set to false).
	 * The same applies when using a <code>process</code> function.
	 * @param seed the starting point of the traversal. If omitted, the first node in the list of graph nodes is used.
	 * @param process a function that is invoked for every traversed node. The parameters are:
	 * <ol>
	 * <li>a reference to the visited node.</li>
	 * <li>the <code>preflight</code> flag.</li>
	 * <li>custom data specified by the <code>userData</code> parameter (default is null).</li>
	 * </ol>
	 * Once <code>process</code> returns false, the traversal stops immediately and no further nodes are examined (termination condition).<br/>
	 * If omitted, element.<em>visit()</em> is used.
	 * <warn>In this case the elements of all nodes have to implement Visitable.</warn><br/>
	 * @param userData custom data that is passed to every visited node via <code>process</code> or element.<em>visit()</em>. If omitted, null is used.
	 */
	public function DLBFS(maxDepth:Int, preflight = false, seed:GraphNode<T> = null, process:GraphNode<T>->Bool->Dynamic->Bool = null, userData:Dynamic = null)
	{
		if (_size == 0) return;
		
		#if debug
		assert(_busy == false, "recursive call to iterative BFS");
		_busy = true;
		#end
		
		if (autoClearMarks) clearMarks();
		
		var front = 0;
		var c = 1;
		
		var node = _nodeList;
		while (node != null)
		{
			node.depth = 0;
			node = node.next;
		}
		
		if (seed == null) seed = _nodeList;
		_que[0] = seed;
		
		seed.marked = true;
		seed.parent = seed;
		
		if (preflight)
		{
			if (process == null)
			{
				var v:Dynamic = null;
				
				var n = _que[front];
				v = n.val;
				if (!v.visit(true, userData))
				{
					#if debug
					_busy = false;
					#end
					return;
				}
				
				while (c > 0)
				{
					n = _que[front];
					v = n.val;
					if (!v.visit(false, userData))
					{
						#if debug
						_busy = false;
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
								_que[c++ + front] = m;
						}
						a = a.next;
					}
					front++;
					c--;
				}
			}
			else
			{
				var n = _que[front];
				if (!process(n, true, userData))
				{
					#if debug
					_busy = false;
					#end
					return;
				}
				
				while (c > 0)
				{
					n = _que[front];
					if (!process(n, false, userData))
					{
						#if debug
						_busy = false;
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
								_que[c++ + front] = m;
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
					var n = _que[front];
					
					v = n.val;
					if (!v.visit(false, userData))
					{
						#if debug
						_busy = false;
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
							_que[c++ + front] = m;
						
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
					var n = _que[front];
					
					if (n.depth > maxDepth) continue;
					
					if (!process(n, false, userData))
					{
						#if debug
						_busy = false;
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
							_que[c++ + front] = m;
						
						a = a.next;
					}
					front++;
					c--;
				}
			}
		}
		
		#if debug
		_busy = false;
		#end
	}
	
	/**
	 * Returns a string representing the current object.<br/>
	 * Example:<br/>
	 * <pre class="prettyprint">
	 * var graph = new de.polygonal.ds.Graph&lt;String&gt;();
	 * var a = graph.addNode("a");
	 * var b = graph.addNode("b");
	 * var c = graph.addNode("c");
	 * graph.addSingleArc(a, b, 1.0);
	 * graph.addSingleArc(b, a, 1.0);
	 * graph.addMutualArc(a, c, 1.0);
	 * trace(graph);</pre>
	 * <pre class="console">
	 * { Graph size: 3 }
	 * [
	 *   {GraphNode, val: c, connected to: a}
	 *   {GraphNode, val: b, connected to: a}
	 *   {GraphNode, val: a, connected to: c,b}
	 * ]</pre>
	 */
	public function toString():String
	{
		var s = '{ Graph size: ${size()} }';
		if (isEmpty()) return s;
		s += "\n[\n";
		var node = _nodeList;
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
	 * Destroys this object by explicitly nullifying all nodes, elements and pointers for GC'ing used resources.<br/>
	 * Improves GC efficiency/performance (optional).
	 * <o>n</o>
	 */
	public function free()
	{
		var node = _nodeList;
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
		
		_nodeList = null;
		
		for (i in 0..._stack.length) _stack[i] = null; _stack = null;
		for (i in 0..._que.length) _que[i] = null; _que = null;
		
		_iterator = null;
		
		#if debug
		_nodeSet.free();
		_nodeSet = null;
		#end
	}
	
	/**
	 * Returns true if this graph contains a node storing the element <code>x</code>.
	 * <o>n</o>
	 */
	public function contains(x:T):Bool
	{
		var found = false;
		var node = _nodeList;
		while (node != null)
		{
			if (node.val == x)
				return true;
			node = node.next;
		}
		return false;
	}
	
	/**
	 * Removes all nodes storing the element <code>x</code>.<br/>
	 * Nodes and elements are nullified.
	 * <o>n</o>
	 * @return true if at least one node storing <code>x</code> was removed.
	 */
	public function remove(x:T):Bool
	{
		var found = false;
		var node = _nodeList;
		while (node != null)
		{
			var nextNode = node.next;
			
			if (node.val == x)
			{
				unlink(node);
				node.val = cast null;
				node.next = node.prev = null;
				node.arcList = null;
				found = true;
				_size--;
			}
			
			node = nextNode;
		}
		
		return found;
	}
	
	/**
	 * Removes all elements.
	 * <o>1 or n if <code>purge</code> is true</o>
	 * @param purge if true, explicitly nullifies nodes and elements upon removal.<br/>
	 * Improves GC efficiency/performance (optional).
	 */
	public function clear(purge = false)
	{
		if (purge)
		{
			var node = _nodeList;
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
		
		_nodeList = null;
		_size = 0;
		
		_stack = new Array<GraphNode<T>>();
		_que = new Array<GraphNode<T>>();
	}
	
	/**
	 * Returns a new <em>GraphIterator</em> object to iterate over all elements stored in the graph nodes of this graph.
	 * The nodes are visited in a random order.
	 * @see <a href="http://haxe.org/ref/iterators" target="_blank">http://haxe.org/ref/iterators</a>
	 */
	public function iterator():Itr<T>
	{
		if (reuseIterator)
		{
			if (_iterator == null)
				_iterator = new GraphIterator<T>(this);
			else
				_iterator.reset();
			return _iterator;
		}
		else
			return new GraphIterator<T>(this);
	}
	
	/**
	 * Returns a new <em>GraphNodeIterator</em> object to iterate over all <em>GraphNode</em> objects in this graph.
	 * The nodes are visited in a random order.
	 * @see <a href="http://haxe.org/ref/iterators" target="_blank">http://haxe.org/ref/iterators</a>
	 */
	public function nodeIterator():Itr<GraphNode<T>>
	{
		return new GraphNodeIterator<T>(this);
	}
	
	/**
	 * Returns a new <em>GraphArcIterator</em> object to iterate over all <em>GraphArc</em> objects in this graph.
	 * The arcs are visited in a random order.
	 * @see <a href="http://haxe.org/ref/iterators" target="_blank">http://haxe.org/ref/iterators</a>
	 */
	public function arcIterator():Itr<GraphArc<T>>
	{
		return new GraphArcIterator<T>(this);
	}
	
	/**
	 * The total number of elements in this graph.<br/>
	 * Equals the number of graph nodes.
	 * <o>1</o>
	 */
	inline public function size():Int
	{
		return _size;
	}
	
	/**
	 * Returns true if this graph is empty.
	 * <o>1</o>
	 */
	inline public function isEmpty():Bool
	{
		return _size == 0;
	}
	
	/**
	 * Returns an unordered array containing all elements stored in the graph nodes of this graph.
	 */
	public function toArray():Array<T>
	{
		var a:Array<T> = ArrayUtil.alloc(size());
		var node = _nodeList;
		while (node != null)
		{
			a.push(node.val);
			node = node.next;
		}
		return a;
	}
	
	#if flash10
	/**
	 * Returns an unordered Vector.&lt;T&gt; object containing all elements stored in the graph nodes of this graph.
	 */
	public function toVector():flash.Vector<Dynamic>
	{
		var a = new flash.Vector<Dynamic>(size());
		var node = _nodeList;
		while (node != null)
		{
			a.push(node.val);
			node = node.next;
		}
		return a;
	}
	#end
	
	/**
	 * Duplicates this graph. Supports shallow (structure only) and deep copies (structure & elements).
	 * @param assign if true, the <code>copier</code> parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.<br/>
	 * If false, the <em>clone()</em> method is called on each element. <warn>In this case all elements have to implement <em>Cloneable</em>.</warn>
	 * @param copier a custom function for copying elements. Replaces element.<em>clone()</em> if <code>assign</code> is false.
	 * @throws de.polygonal.ds.error.AssertError element is not of type <em>Cloneable</em> (debug only).
	 */
	public function clone(assign = true, copier:T->T = null):Collection<T>
	{
		var copy = new Graph<T>(maxSize);
		if (_nodeList == null) return copy;
		
		var t = new Array<GraphNode<T>>();
		var i = 0;
		var n = _nodeList;
		
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
				#if debug
				assert(Std.is(n.val, Cloneable), 'element is not of type Cloneable (${n.val})');
				#end
				
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
		n = _nodeList;
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
	
	function _DFSRecursiveVisit(node:GraphNode<T>, preflight:Bool, userData:Dynamic):Bool
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
					if (!_DFSRecursiveVisit(m, true, userData))
						return false;
			}
			else
			{
				if (!_DFSRecursiveVisit(m, false, userData))
					return false;
			}
			
			a = a.next;
		}
		
		return true;
	}
	
	function _DFSRecursiveProcess(node:GraphNode<T>, process:GraphNode<T>->Bool->Dynamic->Bool = null, preflight:Bool, userData:Dynamic):Bool
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
					if (!_DFSRecursiveProcess(m, process, true, userData))
						return false;
			}
			else
			{
				if (!_DFSRecursiveProcess(m, process, false, userData))
						return false;
			}
			
			a = a.next;
		}
		
		return true;
	}
}

private typedef GraphFriend<T> =
{
	private var _nodeList:GraphNode<T>;
}

#if generic
@:generic
#end
#if doc
private
#end
class GraphIterator<T> implements de.polygonal.ds.Itr<T>
{
	var _f:Graph<T>;
	var _node:GraphNode<T>;
	
	public function new(f:Graph<T>)
	{
		_f = f;
		reset();
	}
	
	inline public function reset():Itr<T>
	{
		_node = __nodeList(_f);
		return this;
	}
	
	inline public function hasNext():Bool
	{
		return _node != null;
	}
	
	inline public function next():T
	{
		var x = _node.val;
		_node = _node.next;
		return x;
	}
	
	inline public function remove()
	{
		throw "unsupported operation";
	}
	
	inline function __nodeList(f:GraphFriend<T>)
	{
		return f._nodeList;
	}
}

#if generic
@:generic
#end
#if doc
private
#end
class GraphNodeIterator<T> implements de.polygonal.ds.Itr<GraphNode<T>>
{
	var _f:Graph<T>;
	var _node:GraphNode<T>;
	
	public function new(f:Graph<T>)
	{
		_f = f;
		reset();
	}
	
	inline public function reset():Itr<GraphNode<T>>
	{
		_node = __nodeList(_f);
		return this;
	}
	
	inline public function hasNext():Bool
	{
		return _node != null;
	}
	
	inline public function next():GraphNode<T>
	{
		var x = _node;
		_node = _node.next;
		return x;
	}
	
	inline public function remove()
	{
		throw "unsupported operation";
	}
	
	inline function __nodeList(f:GraphFriend<T>)
	{
		return f._nodeList;
	}
}

#if generic
@:generic
#end
#if doc
private
#end
class GraphArcIterator<T> implements de.polygonal.ds.Itr<GraphArc<T>>
{
	var _f:Graph<T>;
	var _node:GraphNode<T>;
	var _arc:GraphArc<T>;
	
	public function new(f:Graph<T>)
	{
		_f = f;
		reset();
	}
	
	inline public function reset():Itr<GraphArc<T>>
	{
		_node = __nodeList(_f);
		_arc = _node.arcList;
		return this;
	}
	
	inline public function hasNext():Bool
	{
		return _arc != null && _node != null;
	}
	
	inline public function next():GraphArc<T>
	{
		var x = _arc;
		_arc = _arc.next;
		
		if (_arc == null)
		{
			_node = _node.next;
			if (_node != null) _arc = _node.arcList;
		}
		
		return x;
	}
	
	inline public function remove()
	{
		throw "unsupported operation";
	}
	
	inline function __nodeList(f:GraphFriend<T>)
	{
		return f._nodeList;
	}
}