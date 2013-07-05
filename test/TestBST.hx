package;

import de.polygonal.core.math.random.Random;
import de.polygonal.ds.BinaryTreeNode;
import de.polygonal.ds.BST;
import de.polygonal.ds.Collection;
import de.polygonal.ds.ListSet;
import de.polygonal.ds.Set;

class TestBST extends haxe.unit.TestCase
{
	function testPreorder()
	{
		var bst = new BST<E>();
		
		var data = [5, 1, -20, 100, 23, 67, 13];
		var order = [5, 1, -20, 100, 23, 13, 67];
		
		for (i in 0...data.length)
			bst.insert(new E(data[i]));
		
		var c = 0;
		var scope = this;
		var f = function(node:BinaryTreeNode<E>, userData:Dynamic):Bool
		{
			scope.assertEquals(order[c++], node.val.id);
			return true;
		};
		
		//f
		bst.root().preorder(f);
		c = 0;
		bst.root().preorder(f, true);
		
		//visitable
		bst.root().preorder(null);
		c = 0;
		for (i in bst.root())
		{
			if (i.visited) c++;
		}
		assertEquals(data.length, c);
		for (i in bst.root()) i.visited = false;
		
		bst.root().preorder(null, true);
		c = 0;
		for (i in bst.root())
		{
			if (i.visited) c++;
		}
		assertEquals(data.length, c);
		
		//f abort
		var abortId:Int = 0;
		var visited = new Array<Int>();
		var fAbort = function(node:BinaryTreeNode<E>, userData:Dynamic):Bool
		{
			if (node.val.id == abortId)
				return false;
			else
			{
				visited.push(node.val.id);
				return true;
			}
		};
		for (i in 0...order.length)
		{
			abortId = order[i];
			visited = new Array<Int>();
			bst.root().preorder(fAbort);
			var expected = [];
			for (j in 0...i) expected[j] = order[j];
			assertEquals(visited.length, expected.length);
			for (i in 0...expected.length) assertEquals(expected[i], visited[i]);
		}
	}
	
	function testInOrder()
	{
		var bst = new BST<E>();
		var data = [5, 1, -20, 100, 23, 67, 13];
		var order = [-20, 1, 5, 13, 23, 67, 100];
		for (i in 0...data.length) bst.insert(new E(data[i]));
		var c = 0;
		var scope = this;
		var f = function(node:BinaryTreeNode<E>, userData:Dynamic):Bool
		{
			scope.assertEquals(order[c++], node.val.id);
			return true;
		};
		
		//f
		bst.root().inorder(f);
		c = 0;
		bst.root().inorder(f, true);
		
		//visitable
		bst.root().inorder(null);
		c = 0;
		for (i in bst.root())
		{
			if (i.visited) c++;
		}
		assertEquals(data.length, c);
		for (i in bst.root()) i.visited = false;
		
		bst.root().inorder(null, true);
		c = 0;
		for (i in bst.root())
		{
			if (i.visited) c++;
		}
		assertEquals(data.length, c);
		
		//f abort
		var abortId:Int = 0;
		var visited = new Array<Int>();
		var fAbort = function(node:BinaryTreeNode<E>, userData:Dynamic):Bool
		{
			if (node.val.id == abortId)
				return false;
			else
			{
				visited.push(node.val.id);
				return true;
			}
		};
		for (i in 0...order.length)
		{
			abortId = order[i];
			visited = new Array<Int>();
			bst.root().inorder(fAbort);
			var expected = [];
			for (j in 0...i) expected[j] = order[j];
			assertEquals(visited.length, expected.length);
			for (i in 0...expected.length) assertEquals(expected[i], visited[i]);
		}
	}
	
	function testPostOrder()
	{
		var bst = new BST<E>();
		var data = [5, 1, -20, 100, 23, 67, 13];
		var order = [-20, 1, 13, 67, 23, 100, 5];
		for (i in 0...data.length) bst.insert(new E(data[i]));
		var c = 0;
		var scope = this;
		var f = function(node:BinaryTreeNode<E>, userData:Dynamic):Bool
		{
			scope.assertEquals(order[c++], node.val.id);
			return true;
		};
		bst.root().postorder(f);
		c = 0;
		bst.root().postorder(f, true);
		c = 0;
		bst.root().postorder(f, true);
		c = 0;
		bst.root().postorder(f, true);
		
		//visitable
		bst.root().postorder(null);
		c = 0;
		for (i in bst.root())
		{
			if (i.visited) c++;
		}
		assertEquals(data.length, c);
		for (i in bst.root()) i.visited = false;
		
		bst.root().postorder(null, true);
		c = 0;
		for (i in bst.root())
		{
			if (i.visited) c++;
		}
		assertEquals(data.length, c);
		
		//f abort
		var abortId:Int = 0;
		var visited = new Array<Int>();
		var fAbort = function(node:BinaryTreeNode<E>, userData:Dynamic):Bool
		{
			if (node.val.id == abortId)
				return false;
			else
			{
				visited.push(node.val.id);
				return true;
			}
		};
		for (i in 0...order.length)
		{
			abortId = order[i];
			visited = new Array<Int>();
			bst.root().postorder(fAbort);
			var expected = [];
			for (j in 0...i) expected[j] = order[j];
			assertEquals(visited.length, expected.length);
			for (i in 0...expected.length) assertEquals(expected[i], visited[i]);
		}
	}
	
	function testDepth()
	{
		var bst = new BST<E>();
		var data = [5, 1, -20, 100, 23, 67, 13];
		var order = [5, 1, -20, 100, 23, 13, 67];
		var nodes = new Array<BinaryTreeNode<E>>();
		for (i in 0...data.length)
			nodes[i] = bst.insert(new E(data[i]));
		assertEquals(0, nodes[0].depth());
		assertEquals(1, nodes[1].depth());
		assertEquals(2, nodes[2].depth());
		assertEquals(1, nodes[3].depth());
		assertEquals(2, nodes[4].depth());
		assertEquals(3, nodes[5].depth());
		assertEquals(3, nodes[6].depth());
	}
	
	function testHeight()
	{
		var bst = new BST<E>();
		var data = [4,2,6,5,1,3,7];
		var height = [3, 2, 2, 1, 1, 1, 1];
		var nodes = new Array<BinaryTreeNode<E>>();
		for (i in 0...data.length)
			nodes[i] = bst.insert(new E(data[i]));
		for (i in 0...nodes.length)
			assertEquals(height[i], nodes[i].height());
	}
	
	function testContains()
	{
		var bst = new BST<E>();
		var data = [5, 1, -20, 100, 23, 67, 13];
		var order = [5, 1, -20, 100, 23, 13, 67];
		var nodes = new Array<BinaryTreeNode<E>>();
		for (i in 0...data.length)
			nodes[i] = bst.insert(new E(data[i]));
		for (i in 0...nodes.length)
			assertTrue(bst.root().contains(nodes[i].val));
	}
	
	function testRemove()
	{
		var num = new Array<E>();
		var bst = new BST<E>();
		var k = 10;
		for (i in 0...k)
		{
			var i = Random.rand() % 100;
			num.unshift(new E(i));
			bst.insert(num[0]);
		}
		var found = 0;
		for (i in 0...k)
			bst.remove(num.pop());
		assertEquals(0, bst.size());
	}
	
	function testIterator()
	{
		var bst = new BST<E>();
		var data = [5, 1, -20, 100, 23, 67, 13];
		var s = new ListSet<Int>();
		for (i in 0...data.length)
		{
			bst.insert(new E(data[i]));
			s.set(data[i]);
		}
		for (i in bst)
			assertEquals(true, s.remove(i.id));
		assertTrue(s.isEmpty());
	}
	
	function testClone()
	{
		var bst = new BST<E>();
		var data = [5, 1, -20, 100, 23, 67, 13];
		var s:Set<Int> = new ListSet<Int>();
		for (i in 0...data.length)
		{
			bst.insert(new E(data[i]));
			s.set(data[i]);
		}
		
		var clone = bst.clone(true);
		for (i in clone)
			assertEquals(true, s.remove(i.id));
	}
	
	function testToArray()
	{
		var bst = new BST<E>();
		var data = [5, 1, -20, 100, 23, 67, 13];
		for (i in 0...data.length) bst.insert(new E(data[i]));
		
		var set = new ListSet<E>();
		for (i in bst) set.set(i);
		var arr = bst.toArray();
		assertEquals(bst.size(), arr.length);
		
		for (i in arr) assertEquals(true, set.remove(i));
		assertTrue(set.isEmpty());
	}
	
	function testToDenseArray()
	{
		var bst = new BST<E>();
		var data = [5, 1, -20, 100, 23, 67, 13];
		for (i in 0...data.length)
			bst.insert(new E(data[i]));
		
		var set = new ListSet<E>();
		for (i in bst) set.set(i);
		
		var arr = bst.toArray();
		assertEquals(bst.size(), arr.length);
		for (i in arr) assertEquals(true, set.remove(i));
		assertTrue(set.isEmpty());
	}
	
	function testFind()
	{
		var num = new Array<E>();
		var bst = new BST<E>();
		var k = 10;
		for (i in 0...k)
		{
			var i = Random.rand() % 100;
			num.unshift(new E(i));
			bst.insert(num[0]);
		}
		var found = 0;
		for (i in 0...k)
		{
			var n = num[i];
			if (bst.find(n) != null)
				found++;
		}
		assertEquals(k, found);
	}
	
	function testCollection()
	{
		var c:de.polygonal.ds.Collection<E> = cast new BST<E>();
		assertEquals(true, true);
	}
	
	function testEmptyAndRefill()
	{
		var bst = new BST<E>();
		var data = [1, 2, 3];
		var nodes = new Array();
		for (i in 0...data.length) nodes.push(bst.insert(new E(data[i])));
		while (nodes.length > 0) bst.removeNode(nodes.pop());
		
		assertTrue(bst.isEmpty());
		assertEquals(null, untyped bst._root);
		
		var data = [4, 5, 6];
		var nodes = new Array();
		for (i in 0...data.length)
			nodes.push(bst.insert(new E(data[i])));
		
		while (nodes.length > 0)
			bst.removeNode(nodes.pop());
		
		assertTrue(bst.isEmpty());
		assertEquals(null, untyped bst._root);
	}
}

#if haxe3
private class E implements de.polygonal.ds.Comparable<E> implements de.polygonal.ds.Visitable
#else
private class E implements de.polygonal.ds.Comparable<E>, implements de.polygonal.ds.Visitable
#end
{
	public var id:Int;
	
	public var visited:Bool;
	
	public function new(id:Int)
	{
		this.id = id;
	}
	
	public function compare(other:E):Int
	{
		return id - other.id;
	}
	
	public function visit(preflight:Bool, userData:Dynamic):Bool
	{
		visited = true;
		return true;
	}
	
	public function toString():String
	{
		return '[' + id + ']';
	}
}