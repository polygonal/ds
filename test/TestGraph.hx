import polygonal.ds.Graph;
import polygonal.ds.GraphArc;
import polygonal.ds.GraphNode;

class TestGraph extends AbstractTest
{
	var c:Int;
	var d:Int;
	
	function testParentAndDepth()
	{
		c = 0;
		d = 0;
		
		//function
		var graph = new Graph<String>();
		
		var a = graph.add("a");
		var b = graph.add("b");
		var c = graph.add("c");
		
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
		
		graph.dfs(false, a, process, false);
		graph.dfs(false, a, process, true);
		graph.dfs(true, a, process, false);
		graph.dfs(true, a, process, true);
		graph.bfs(false, a, process, false);
		graph.bfs(false, a, process, true);
		graph.bfs(true, a, process, false);
		graph.bfs(true, a, process, true);
		
		//visitable
		var graph = new Graph<E>();
		
		var ea = new E(this, 0);
		var eb = new E(this, 1);
		var ec = new E(this, 2);
		
		var a = graph.add(ea);
		var b = graph.add(eb);
		var c = graph.add(ec);
		
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
		
		graph.dfs(false, a, null, false);
		graph.dfs(false, a, null, true);
		graph.dfs(true, a, null, false);
		graph.dfs(true, a, null, true);
		
		graph.bfs(false, a, null, false);
		graph.bfs(false, a, null, true);
		graph.bfs(true, a, null, false);
		graph.bfs(true, a, null, true);
	}
	
	function testBFS_DFS_Func()
	{
		var graph = new Graph<Int>();
		for (i in 0...4) graph.add(i);
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
		graph.dfs(false, graph.getNodeList(), visit);
		assertEquals(graph.size, c);
		
		c = 0;
		d = 0;
		graph.clearMarks();
		graph.dfs(true, graph.getNodeList(), visit);
		assertEquals(graph.size, c);
		
		//recursive process preflight
		c = 0;
		d = 0;
		graph.clearMarks();
		graph.dfs(true, graph.getNodeList(), visit, null, true);
		assertEquals(graph.size, c);
		assertEquals(4, c);
		assertEquals(4, d);
		
		//recursive process
		c = 0;
		d = 0;
		graph.clearMarks();
		graph.dfs(false, graph.getNodeList(), visit, null, true);
		assertEquals(graph.size, c);
		assertEquals(4, c);
		assertEquals(0, d);
		
		c = 0;
		d = 0;
		graph.clearMarks();
		graph.bfs(false, graph.getNodeList(), visit);
		assertEquals(graph.size, c);
		
		c = 0;
		d = 0;
		graph.clearMarks();
		graph.bfs(true, graph.getNodeList(), visit);
		assertEquals(graph.size, c);
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
			graph.add(n);
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
		graph.bfs(false);
		
		assertEquals(graph.size, c);
	}
	
	function testRemove()
	{
		var graph = new Graph<Int>();
		var nodes = new Array<Int>();
		for (i in 0...10)
		{
			nodes[i] = i;
			graph.add(i);
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
		assertEquals(10, graph.size);
		var k = graph.remove(0);
		assertEquals(true, k);
		assertEquals(9, graph.size);
		for (i in 1...10)
		{
			var k = graph.remove(i);
			assertEquals(true, k);
		}
		assertTrue(graph.isEmpty());
		
		var graph = new Graph<Int>();
		graph.add(5);
		graph.add(3);
		assertTrue(graph.remove(5));
		assertTrue(graph.remove(3));
		
		graph.add(5);
		graph.add(3);
		assertTrue(graph.remove(3));
		assertTrue(graph.remove(5));
	}
	
	function testDLBFS()
	{
		var graph = new Graph<Int>();
		graph.autoClearMarks = true;
		var node1 = graph.add(1);
		var node2 = graph.add(2);
		var node3 = graph.add(3);
		
		var nodeLut = [];
		nodeLut[1] = node1;
		nodeLut[2] = node2;
		nodeLut[3] = node3;
		
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
		graph.dlbfs(0, false, node1, process);
		assertEquals(1, result.length);
		assertEquals(result[0], 1);
		
		result = [];
		graph.dlbfs(1, false, node1, process);
		assertEquals(2, result.length);
		assertEquals(result[0], 1);
		assertEquals(result[1], 2);
		
		result = [];
		graph.dlbfs(2, false, node1, process);
		assertEquals(3, result.length);
		assertEquals(result[0], 1);
		assertEquals(result[1], 2);
		assertEquals(result[2], 3);
		
		assertEquals(node1.parent, node1);
		assertEquals(node2.parent, node1);
		assertEquals(node3.parent, node2);
		
		result = [];
		graph.dlbfs(0, true, node1, process);
		assertEquals(1, result.length);
		assertEquals(result[0], 1);
		
		result = [];
		graph.dlbfs(1, true, node1, process);
		assertEquals(2, result.length);
		assertEquals(result[0], 1);
		assertEquals(result[1], 2);
		
		result = [];
		graph.dlbfs(2, true, node1, process);
		assertEquals(3, result.length);
		assertEquals(result[0], 1);
		assertEquals(result[1], 2);
		assertEquals(result[2], 3);
		
		assertEquals(node1.parent, node1);
		assertEquals(node2.parent, node1);
		assertEquals(node3.parent, node2);
		
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
		
		var node1 = graph.add(e1);
		var node2 = graph.add(e2);
		var node3 = graph.add(e3);
		graph.addMutualArc(node1, node2);
		graph.addMutualArc(node2, node3);
		
		result = [];
		graph.dlbfs(0, false, node1, null);
		assertEquals(1, result.length);
		assertEquals(result[0], 1);
		
		result = [];
		graph.dlbfs(1, false, node1, null);
		assertEquals(2, result.length);
		assertEquals(result[0], 1);
		assertEquals(result[1], 2);
		
		result = [];
		graph.dlbfs(2, false, node1, null);
		assertEquals(3, result.length);
		assertEquals(result[0], 1);
		assertEquals(result[1], 2);
		assertEquals(result[2], 3);
		
		assertEquals(node1.parent, node1);
		assertEquals(node2.parent, node1);
		assertEquals(node3.parent, node2);
		
		result = [];
		graph.dlbfs(0, true, node1, null);
		assertEquals(1, result.length);
		assertEquals(result[0], 1);
		
		result = [];
		graph.dlbfs(1, true, node1, null);
		assertEquals(2, result.length);
		assertEquals(result[0], 1);
		assertEquals(result[1], 2);
		
		result = [];
		graph.dlbfs(2, true, node1, null);
		assertEquals(3, result.length);
		assertEquals(result[0], 1);
		assertEquals(result[1], 2);
		assertEquals(result[2], 3);
		
		assertEquals(node1.parent, node1);
		assertEquals(node2.parent, node1);
		assertEquals(node3.parent, node2);
	}
	
	function testBFS_DFS_Visitable()
	{
		var graph = new Graph<E>();
		var elements = new Array<E>();
		for (i in 0...4)
		{
			elements[i] = new E(this, i);
			graph.add(elements[i]);
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
		graph.dfs(false);
		assertEquals(graph.size, c);
		
		c = 0;
		d = 0;
		graph.clearMarks();
		graph.dfs(true);
		assertEquals(graph.size, c);
		
		//recursive process preflight
		c = 0;
		d = 0;
		graph.clearMarks();
		graph.dfs(true, null, null, null, true);
		assertEquals(graph.size, c);
		assertEquals(4, c);
		assertEquals(4, d);
		
		//recursive process
		c = 0;
		d = 0;
		graph.clearMarks();
		graph.dfs(false, graph.getNodeList(), null, true);
		assertEquals(graph.size, c);
		assertEquals(4, c);
		assertEquals(0, d);
		
		c = 0;
		d = 0;
		graph.clearMarks();
		graph.bfs(false);
		assertEquals(graph.size, c);
		
		c = 0;
		d = 0;
		graph.clearMarks();
		graph.bfs(true);
		assertEquals(graph.size, c);
	}
	
	function testIterator()
	{
		var graph = new Graph<E>();
		var nodes = new Array<GraphNode<E>>();
		for (i in 0...10)
		{
			var node:GraphNode<E> = graph.add(new E(this, i));
			nodes[i] = node;
		}
		
		var s = new polygonal.ds.HashSet<E>(1024);
		for (i in graph) assertEquals(true, s.set(i));
		assertEquals(10, s.size);
		
		var c:polygonal.ds.Set<E> = cast s.clone(true);
		var itr = graph.iterator();
		
		for (i in itr) assertEquals(true, c.remove(i));
		assertTrue(c.isEmpty());
		
		var c:polygonal.ds.Set<E> = cast s.clone(true);
		itr.reset();
		for (i in itr) assertEquals(true, c.remove(i));
		assertTrue(c.isEmpty());
		
		var node:polygonal.ds.GraphNode<E> = graph.getNodeList();
		while (node != null)
		{
			var node1:polygonal.ds.GraphNode<E> = graph.getNodeList();
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
			var s = new polygonal.ds.HashSet<E>(1024);
			for (i in node) assertEquals(true, s.set(i));
			assertEquals(9, s.size);
			node = node.next;
		}
		
		var graph = new Graph<Int>();
		var nodes = new Array<GraphNode<Int>>();
		for (i in 0...10)
		{
			var node:GraphNode<Int> = graph.add(i);
			nodes[i] = node;
		}
		
		var s = new polygonal.ds.IntHashSet(1024);
		for (i in graph) assertEquals(true, s.set(i));
		assertEquals(10, s.size);
		
		var node:polygonal.ds.GraphNode<Int> = graph.getNodeList();
		while (node != null)
		{
			var node1:polygonal.ds.GraphNode<Int> = graph.getNodeList();
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
			var s = new polygonal.ds.IntHashSet(1024);
			for (i in node) assertEquals(true, s.set(i));
			assertEquals(9, s.size);
			node = node.next;
		}
	}
	
	function testIter()
	{
		var graph = new Graph<Int>();
		for (i in 0...4) graph.add(i);
		var i = 4;
		graph.iter(function(e) assertEquals(--i, e));
	}
	
	function test()
	{
		var graph = new Graph<E>();
		var nodes = new Array<GraphNode<E>>();
		for (i in 0...10)
		{
			var node = graph.add(new E(this, i));
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
		
		assertEquals(graph.size, 10);
		
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
		
		assertEquals(10, graph.size);
		
		for (i in 0...10)
			graph.remove(nodes[i].val);
		
		assertEquals(0, graph.size);
    }
	
	function testUnlink()
	{
		var graph = new Graph<E>();
		var nodes = new Array<GraphNode<E>>();
		for (i in 0...3)
		{
			var node = graph.add(new E(this, i));
			nodes[i] = node;
		}
		
		//0 <-> 1
		//1 <-> 2
		//2 <-> 0
		graph.addMutualArc(nodes[0], nodes[1]);
		graph.addMutualArc(nodes[1], nodes[2]);
		graph.addMutualArc(nodes[2], nodes[0]);
		
		assertEquals(2, nodes[0].numArcs);
		assertEquals(2, nodes[1].numArcs);
		assertEquals(2, nodes[2].numArcs);
		
		graph.unlink(nodes[0]);
		
		assertEquals(0, nodes[0].numArcs);
		assertEquals(1, nodes[1].numArcs);
		assertEquals(1, nodes[2].numArcs);
		
		graph.unlink(nodes[1]);
		
		assertEquals(0, nodes[1].numArcs);
		assertEquals(0, nodes[2].numArcs);
		
		//0 <-> 1
		//0 <-> 2
		graph.addMutualArc(nodes[0], nodes[1]);
		graph.addMutualArc(nodes[0], nodes[2]);
		assertEquals(2, nodes[0].numArcs);
		assertEquals(1, nodes[1].numArcs);
		assertEquals(1, nodes[2].numArcs);
		
		graph.unlink(nodes[0]);
		assertEquals(0, nodes[0].numArcs);
		assertEquals(0, nodes[1].numArcs);
		assertEquals(0, nodes[2].numArcs);
	}
	
	function testRemovArc()
	{
		var graph = new Graph<E>();
		var nodes = new Array<GraphNode<E>>();
		for (i in 0...3)
		{
			var node = graph.add(new E(this, i));
			nodes[i] = node;
		}
		
		//0 <-> 1
		//0 <-> 2
		//2 <-> 1
		
		graph.addMutualArc(nodes[0], nodes[1]);
		graph.addSingleArc(nodes[0], nodes[2]);
		graph.addSingleArc(nodes[2], nodes[1]);
		
		var success = nodes[0].removeArc(nodes[1], true);
		assertTrue(success);
		assertFalse(nodes[0].isConnected(nodes[1]));
		assertFalse(nodes[1].isConnected(nodes[0]));
		
		var success = nodes[0].removeArc(nodes[2], true);
		assertFalse(success);
		assertFalse(nodes[0].isConnected(nodes[2]));
		assertTrue(nodes[2].isConnected(nodes[1]));
	}
	
	function testCustomGraph()
	{
		var f = function(node:GraphNode<String>, preflight:Bool, userData:Dynamic):Bool return true;
		
		var graph = new Graph<String>();
		var node1 = new CustomGraphNode<String>("a");
		var node2 = new CustomGraphNode<String>("b");
		
		graph.addNode(node1);
		graph.addNode(node2);
		
		graph.addMutualArc(node1, node2);
		graph.bfs(true, node1, f);
		
		var graph = new Graph<E>();
		var node1 = new CustomGraphNode<E>(new E(this, 2));
		var node2 = new CustomGraphNode<E>(new E(this, 3));
		graph.addNode(node1);
		graph.addNode(node2);
		graph.addMutualArc(node1, node2);
		graph.bfs(true, node1);
		
		assertTrue(true);
	}
	
	function testSerialize()
	{
		var graph = new Graph<E>();
		var nodeA = new GraphNode<E>(new E(this, 10));
		var nodeB = new GraphNode<E>(new E(this, 20));
		var nodeC = new GraphNode<E>(new E(this, 30));
		graph.addNode(nodeA);
		graph.addNode(nodeB);
		graph.addNode(nodeC);
		graph.addMutualArc(nodeA, nodeB);
		graph.addMutualArc(nodeB, nodeC);
		graph.addMutualArc(nodeA, nodeC);
		
		var vals = [];
		var n = graph.getNodeList();
		while (n != null)
		{
			vals.push(n.val.id);
			n = n.next;
		}
		
		var data = graph.serialize(function(x:E) return x.id);
		
		var arcs = [0,2,0,1,1,0,1,2,2,0,2,1];
		for (i in 0...vals.length) assertEquals(vals[i], data.vals[i]);
		for (i in 0...arcs.length) assertEquals(arcs[i], data.arcs[i]);
		
		graph.unserialize(data, function(value:Int) return new E(this, value));
		
		assertEquals(3, graph.size);
		
		var i = 0;
		var l = graph.getNodeList();
		while (l != null)
		{
			assertEquals(vals[i++], l.val.id);
			l = l.next;
		}
		
		var nodes = [];
		var n = graph.getNodeList();
		while (n != null)
		{
			nodes.push(n);
			n = n.next;
		}
		
		assertTrue(nodes[0].isMutuallyConnected(nodes[1]));
		assertTrue(nodes[1].isMutuallyConnected(nodes[2]));
		assertTrue(nodes[0].isMutuallyConnected(nodes[2]));
	}
	
	function process(node:GraphNode<E>, preflight:Bool, userData:Dynamic):Bool
	{
		return true;
	}
}

private class E extends polygonal.ds.HashableItem implements polygonal.ds.Visitable
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
		return "" + id;
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

#if generic
@:generic
#end
private class CustomGraphNode<T> extends GraphNode<T>
{
	public function new(value:T)
	{
		super(value);
	}
}