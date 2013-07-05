package;

import de.polygonal.ds.Graph;
import de.polygonal.ds.GraphArc;
import de.polygonal.ds.GraphNode;

class TestGraph extends haxe.unit.TestCase
{
	var c:Int;
	var d:Int;
	
	function testParentAndDepth()
	{
		c = 0;
		d = 0;
		
		//function
		var graph = new Graph<String>();
		
		var a = graph.addNode(graph.createNode('a'));
		var b = graph.addNode(graph.createNode('b'));
		var c = graph.addNode(graph.createNode('c'));
		
		graph.addSingleArc(a, b);
		graph.addSingleArc(b, c);
		
		var me = this;
		var process = function(node, pre, u)
		{
			if (node == a)
			{
				me.assertEquals(node.parent, a);
				me.assertEquals(node.depth, 0);
			}
			
			if (node == b)
			{
				me.assertEquals(node.parent, a);
				me.assertEquals(node.depth, 1);
			}
			if (node == c)
			{
				me.assertEquals(node.parent, b);
				me.assertEquals(node.depth, 2);
			}
			
			return true;
		}
		
		graph.DFS(false, a, process, false);
		graph.DFS(false, a, process, true);
		graph.DFS(true, a, process, false);
		graph.DFS(true, a, process, true);
		graph.BFS(false, a, process, false);
		graph.BFS(false, a, process, true);
		graph.BFS(true, a, process, false);
		graph.BFS(true, a, process, true);
		
		//visitable
		var graph = new Graph<E>();
		
		var ea = new E(this, 0);
		var eb = new E(this, 1);
		var ec = new E(this, 2);
		
		var a = graph.addNode(graph.createNode(ea));
		var b = graph.addNode(graph.createNode(eb));
		var c = graph.addNode(graph.createNode(ec));
		
		graph.addSingleArc(a, b);
		graph.addSingleArc(b, c);
		
		var me = this;
		var onVisit = function(e, pre, u)
		{
			if (e == ea)
			{
				me.assertEquals(a.parent, a);
				me.assertEquals(a.depth, 0);
			}
			
			if (e == eb)
			{
				me.assertEquals(b.parent, a);
				me.assertEquals(b.depth, 1);
			}
			if (e == ec)
			{
				me.assertEquals(c.parent, b);
				me.assertEquals(c.depth, 2);
			}
			
			return true;
		}
		
		ea.onVisit = onVisit;
		
		graph.DFS(false, a, null, false);
		graph.DFS(false, a, null, true);
		graph.DFS(true, a, null, false);
		graph.DFS(true, a, null, true);
		
		graph.BFS(false, a, null, false);
		graph.BFS(false, a, null, true);
		graph.BFS(true, a, null, false);
		graph.BFS(true, a, null, true);
	}
	
	function testBFS_DFS_Func()
	{
		var graph = new Graph<Int>();
		for (i in 0...4) graph.addNode(graph.createNode(i));
		for (i in 0...4)
		{
			var node = graph.findNode(i);
			for (j in 0...4)
			{
				if (j == i) continue;
				node.addArc(graph.findNode(j), 1);
			}
		}
		
		var scope = this;
		var visit = function(node:GraphNode<Int>, preflight:Bool, userData:Dynamic):Bool
		{
			if (preflight)
			{
				scope.d++;
				return true;
			}
			
			scope.c++;
			return true;
		}
		
		c = 0;
		d = 0;
		graph.clearMarks();
		graph.DFS(false, graph.getNodeList(), visit);
		assertEquals(graph.size(), c);
		
		c = 0;
		d = 0;
		graph.clearMarks();
		graph.DFS(true, graph.getNodeList(), visit);
		assertEquals(graph.size(), c);
		
		//recursive process preflight
		c = 0;
		d = 0;
		graph.clearMarks();
		graph.DFS(true, graph.getNodeList(), visit, null, true);
		assertEquals(graph.size(), c);
		assertEquals(4, c);
		assertEquals(4, d);
		
		//recursive process
		c = 0;
		d = 0;
		graph.clearMarks();
		graph.DFS(false, graph.getNodeList(), visit, null, true);
		assertEquals(graph.size(), c);
		assertEquals(4, c);
		assertEquals(0, d);
		
		c = 0;
		d = 0;
		graph.clearMarks();
		graph.BFS(false, graph.getNodeList(), visit);
		assertEquals(graph.size(), c);
		
		c = 0;
		d = 0;
		graph.clearMarks();
		graph.BFS(true, graph.getNodeList(), visit);
		assertEquals(graph.size(), c);
	}
	
	function testLargeBFS()
	{
		var graph = new Graph<E>();
		var size = 200;
		var nodes = new Array<E>();
		for (i in 0...size)
		{
			var n = new E(this, i);
			nodes[i] = n;
			graph.addNode(graph.createNode(n));
		}
		
		for (i in 0...size)
		{
			var node = graph.findNode(nodes[i]);
			for (j in 0...size)
			{
				if (j == i) continue;
				node.addArc(graph.findNode(nodes[j]), 1);
			}
		}
		
		c = 0;
		graph.BFS(false);
		
		assertEquals(graph.size(), c);
	}
	
	function testRemove()
	{
		var graph = new Graph<Int>();
		var nodes = new Array<Int>();
		for (i in 0...10)
		{
			nodes[i] = i;
			graph.addNode(graph.createNode(i));
		}
		
		for (i in 0...10)
		{
			var node = graph.findNode(nodes[i]);
			for (j in 0...10)
			{
				if (j == i) continue;
				node.addArc(graph.findNode(nodes[j]), 1);
			}
		}
		assertEquals(10, graph.size());
		var k = graph.remove(0);
		assertEquals(true, k);
		assertEquals(9, graph.size());
		for (i in 1...10)
		{
			var k = graph.remove(i);
			assertEquals(true, k);
		}
		assertTrue(graph.isEmpty());
	}
	
	function testDLBFS()
	{
		var graph = new Graph<Int>();
		graph.autoClearMarks = true;
		var node1 = graph.addNode(graph.createNode(1));
		var node2 = graph.addNode(graph.createNode(2));
		var node3 = graph.addNode(graph.createNode(3));
		graph.addMutualArc(node1, node2);
		graph.addMutualArc(node2, node3);
		var result:Array<Int> = [];
		var process = function(node, preflight, userData)
		{
			if (preflight) return true;
			result.push(node.val);
			return true;
		}
		
		result = [];
		graph.DLBFS(0, false, node1, process);
		assertEquals(1, result.length);
		assertEquals(result[0], 1);
		
		result = [];
		graph.DLBFS(1, false, node1, process);
		assertEquals(2, result.length);
		assertEquals(result[0], 1);
		assertEquals(result[1], 2);
		
		result = [];
		graph.DLBFS(2, false, node1, process);
		assertEquals(3, result.length);
		assertEquals(result[0], 1);
		assertEquals(result[1], 2);
		assertEquals(result[2], 3);
		
		result = [];
		graph.DLBFS(0, true, node1, process);
		assertEquals(1, result.length);
		assertEquals(result[0], 1);
		
		result = [];
		graph.DLBFS(1, true, node1, process);
		assertEquals(2, result.length);
		assertEquals(result[0], 1);
		assertEquals(result[1], 2);
		
		result = [];
		graph.DLBFS(2, true, node1, process);
		assertEquals(3, result.length);
		assertEquals(result[0], 1);
		assertEquals(result[1], 2);
		assertEquals(result[2], 3);
		
		//visitable
		var graph = new Graph<E>();
		graph.autoClearMarks = true;
		
		var result = new Array<Int>();
		var f = function(x:Int, preflight:Bool)
		{
			if (!preflight)
				result.push(x);
		}
		
		var e1 = new E(this, 1); e1.f = f;
		var e2 = new E(this, 2); e2.f = f;
		var e3 = new E(this, 3); e3.f = f;
		
		var node1 = graph.addNode(graph.createNode(e1));
		var node2 = graph.addNode(graph.createNode(e2));
		var node3 = graph.addNode(graph.createNode(e3));
		graph.addMutualArc(node1, node2);
		graph.addMutualArc(node2, node3);
		
		result = [];
		graph.DLBFS(0, false, node1, null);
		assertEquals(1, result.length);
		assertEquals(result[0], 1);
		
		result = [];
		graph.DLBFS(1, false, node1, null);
		assertEquals(2, result.length);
		assertEquals(result[0], 1);
		assertEquals(result[1], 2);
		
		result = [];
		graph.DLBFS(2, false, node1, null);
		assertEquals(3, result.length);
		assertEquals(result[0], 1);
		assertEquals(result[1], 2);
		assertEquals(result[2], 3);
		
		result = [];
		graph.DLBFS(0, true, node1, null);
		assertEquals(1, result.length);
		assertEquals(result[0], 1);
		
		result = [];
		graph.DLBFS(1, true, node1, null);
		assertEquals(2, result.length);
		assertEquals(result[0], 1);
		assertEquals(result[1], 2);
		
		result = [];
		graph.DLBFS(2, true, node1, null);
		assertEquals(3, result.length);
		assertEquals(result[0], 1);
		assertEquals(result[1], 2);
		assertEquals(result[2], 3);
	}
	
	function testBFS_DFS_Visitable()
	{
		var graph = new Graph<E>();
		var elements = new Array<E>();
		for (i in 0...4)
		{
			elements[i] = new E(this, i);
			graph.addNode(graph.createNode(elements[i]));
		}
		
		for (i in 0...4)
		{
			var node = graph.findNode(elements[i]);
			for (j in 0...4)
			{
				if (j == i) continue;
				node.addArc(graph.findNode(elements[j]), 1);
			}
		}
		
		c = 0;
		d = 0;
		graph.DFS(false);
		assertEquals(graph.size(), c);
		
		c = 0;
		d = 0;
		graph.clearMarks();
		graph.DFS(true);
		assertEquals(graph.size(), c);
		
		//recursive process preflight
		c = 0;
		d = 0;
		graph.clearMarks();
		graph.DFS(true, null, null, null, true);
		assertEquals(graph.size(), c);
		assertEquals(4, c);
		assertEquals(4, d);
		
		//recursive process
		c = 0;
		d = 0;
		graph.clearMarks();
		graph.DFS(false, graph.getNodeList(), null, true);
		assertEquals(graph.size(), c);
		assertEquals(4, c);
		assertEquals(0, d);
		
		c = 0;
		d = 0;
		graph.clearMarks();
		graph.BFS(false);
		assertEquals(graph.size(), c);
		
		c = 0;
		d = 0;
		graph.clearMarks();
		graph.BFS(true);
		assertEquals(graph.size(), c);
	}
	
	function testIterator()
	{
		var graph = new Graph<E>();
		var nodes = new Array<GraphNode<E>>();
		for (i in 0...10)
		{
			var node:GraphNode<E> = graph.addNode(graph.createNode(new E(this, i)));
			nodes[i] = node;
		}
		
		var s = new de.polygonal.ds.HashSet<E>(1024);
		var c = 0;
		for (i in graph) assertEquals(true, s.set(i));
		assertEquals(10, s.size());
		
		var c:de.polygonal.ds.Set<E> = cast s.clone(true);
		var itr = graph.iterator();
		var itr:de.polygonal.ds.ResettableIterator<E> = cast graph.iterator();
		
		for (i in itr) assertEquals(true, c.remove(i));
		assertTrue(c.isEmpty());
		
		var c:de.polygonal.ds.Set<E> = cast s.clone(true);
		itr.reset();
		for (i in itr) assertEquals(true, c.remove(i));
		assertTrue(c.isEmpty());
		
		var node:de.polygonal.ds.GraphNode<E> = graph.getNodeList();
		while (node != null)
		{
			var node1:de.polygonal.ds.GraphNode<E> = graph.getNodeList();
			while (node1 != null)
			{
				if (node != node1)
					node.addArc(node1, 1);
				node1 = node1.next;
			}
			node = node.next;
		}
		
		var node = graph.getNodeList();
		while (node != null)
		{
			var s = new de.polygonal.ds.HashSet<E>(1024);
			var c = 0;
			for (i in node) assertEquals(true, s.set(i));
			assertEquals(9, s.size());
			node = node.next;
		}
		
		var graph = new Graph<Int>();
		var nodes = new Array<GraphNode<Int>>();
		for (i in 0...10)
		{
			var node:GraphNode<Int> = graph.addNode(graph.createNode(i));
			nodes[i] = node;
		}
		
		var s = new de.polygonal.ds.IntHashSet(1024);
		var c = 0;
		for (i in graph) assertEquals(true, s.set(i));
		assertEquals(10, s.size());
		
		var node:de.polygonal.ds.GraphNode<Int> = graph.getNodeList();
		while (node != null)
		{
			var node1:de.polygonal.ds.GraphNode<Int> = graph.getNodeList();
			while (node1 != null)
			{
				if (node != node1)
					node.addArc(node1, 1);
				node1 = node1.next;
			}
			node = node.next;
		}
		
		var node = graph.getNodeList();
		while (node != null)
		{
			var s = new de.polygonal.ds.IntHashSet(1024);
			var c = 0;
			for (i in node) assertEquals(true, s.set(i));
			assertEquals(9, s.size());
			node = node.next;
		}
	}
	
	function test()
	{
		var graph = new Graph<E>();
		var nodes = new Array<GraphNode<E>>();
		for (i in 0...10)
		{
			var node = graph.addNode(graph.createNode(new E(this, i)));
			nodes[i] = node;
		}
		
		var c = 0;
		for (i in 0...10)
		{
			var a:GraphNode<E> = nodes[i];
			for (j in 0...10)
			{
				if (i != j)
				{
					var b:GraphNode<E> = nodes[j];
					a.addArc(b, 1);
					c++;
				}
			}
		}
		
		assertEquals(graph.size(), 10);
		
		for (i in 0...10)
		{
			var node:GraphNode<E> = nodes[i];
			var c = 0;
			var a:GraphArc<E> = node.arcList;
			while (a != null)
			{
				c++;
				a = a.next;
			}
			
			assertEquals(9, c);
		}
		
		for (i in 0...10)
		{
			var node:GraphNode<E> = nodes[i];
			graph.unlink(node);
		}
		
		assertEquals(10, graph.size());
		
		for (i in 0...10)
			graph.remove(nodes[i].val);
		
		assertEquals(0, graph.size());
    }
	
	function testCustomGraph()
	{
		var f = function(node:GraphNode<String>, preflight:Bool, userData:Dynamic):Bool return true;
		
		var graph = new Graph<String>();
		var node1 = new CustomGraphNode<String>(graph, 'a');
		var node2 = new CustomGraphNode<String>(graph, 'b');
		
		graph.addNode(node1);
		graph.addNode(node2);
		
		graph.addMutualArc(node1, node2);
		graph.BFS(true, node1, f);
		
		var graph = new Graph<E>();
		var node1 = new CustomGraphNode<E>(graph, new E(this, 2));
		var node2 = new CustomGraphNode<E>(graph, new E(this, 3));
		graph.addNode(node1);
		graph.addNode(node2);
		graph.addMutualArc(node1, node2);
		graph.BFS(true, node1);
		
		assertTrue(true);
	}
	
	function process(node:GraphNode<E>, preflight:Bool, userData:Dynamic):Bool
	{
		return true;
	}
}

#if haxe3
private class E extends de.polygonal.ds.HashableItem implements de.polygonal.ds.Visitable
#else
private class E extends de.polygonal.ds.HashableItem, implements de.polygonal.ds.Visitable
#end
{
	public var f:Int->Bool->Void;
	public var id:Int;
	public var t:TestGraph;
	public var onVisit:E->Bool->Dynamic->Bool;
	
	public function new(t:TestGraph, id:Int)
	{
		super();
		this.id = id;
		this.t = t;
		f = null;
		onVisit = null;
	}
	
	public function toString():String
	{
		return '' + id;
	}
	
	public function visit(preflight:Bool, userData:Dynamic):Bool
	{
		if (f != null) f(id, preflight);
		
		if (onVisit != null)
		{
			return onVisit(this, preflight, userData);
		}
		
		if (preflight)
		{
			t.d++;
			return true;
		}
		
		t.c++;
		return true;
	}
}

#if haxe3 @:generic #end
private class CustomGraphNode<T> extends GraphNode<T>
#if !haxe3
, implements haxe.rtti.Generic
#end
{
	public function new(graph:Graph<T>, value:T)
	{
		super(graph, value);
	}
}