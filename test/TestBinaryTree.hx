import polygonal.ds.BinaryTreeNode;

class TestBinaryTree extends AbstractTest
{
	function testFree()
	{
		var node = new BinaryTreeNode<E>(new E());
		node.setLeft(new E());
		node.setRight(new E());
		node.left.setLeft(new E());
		node.left.left.setRight(new E());
		node.free();
		assertTrue(true);
	}
	
	function testClear()
	{
		var node = new BinaryTreeNode<String>("root");
		node.setLeft("e1");
		node.setRight("e2");
		node.left.setLeft("e1");
		node.left.left.setRight("e2");
		
		node.clear(false);
		assertEquals(1, node.size);
		
		var node = new BinaryTreeNode<String>("root");
		node.setLeft("e1");
		node.setRight("e2");
		node.left.setLeft("e1");
		node.left.left.setRight("e2");
		
		node.clear(true);
		assertEquals(1, node.size);
	}
	
	function testRemove()
	{
		var node = new BinaryTreeNode<String>("root");
		
		node.setLeft("e1");
		node.setRight("e2");
		node.left.setLeft("e1");
		node.left.left.setRight("e2");
		
		assertTrue(node.hasLeft());
		assertTrue(node.hasRight());
		assertTrue(node.left.hasLeft());
		assertTrue(node.left.left.hasRight());
		
		assertEquals("e1", node.left.val);
		assertEquals("e2", node.right.val);
		assertEquals("e1", node.left.left.val);
		assertEquals("e2", node.left.left.right.val);
		
		node.remove("e1");
		
		assertFalse(node.hasLeft());
		assertTrue(node.hasRight());
		assertFalse(node.isLeaf());
		
		assertEquals(2, node.size);
	}
	
	function testClone()
	{
		var node = new BinaryTreeNode<String>("root");
		
		node.setLeft("e1");
		node.setRight("e2");
		node.left.setLeft("e1");
		node.left.left.setRight("e2");
		
		var copy:BinaryTreeNode<String> = cast node.clone(true);
		
		assertEquals("e1", copy.left.val);
		assertEquals("e2", copy.right.val);
		
		assertEquals("e1", copy.left.left.val);
		assertEquals("e2", copy.left.left.right.val);
	}
	
	function testContains()
	{
		var node = new BinaryTreeNode<String>("root");
		node.setLeft("e1");
		node.setRight("e2");
		assertFalse(node.contains("e3"));
		assertTrue(node.contains("e1"));
		assertTrue(node.contains("e2"));
	}
	
	function testIter()
	{
		var node = new BinaryTreeNode<Int>(0);
		node.setLeft(1);
			node.left.setLeft(2);
			node.left.setRight(3);
		node.setRight(4);
			node.right.setLeft(5);
			node.right.setRight(6);
		var s = "";
		node.iter(function(e) s += "" + e);
		assertEquals("0465132", s);
	}
	
	function testStackResize()
	{
		var c = 0;
		
		function add(parent:BinaryTreeNode<String>)
		{
			parent.setLeft('l_$c');
			parent.setRight('r_$c');
			c++;
		}
		
		var root = new BinaryTreeNode<String>("root");
		
		var left = root;
		var right = root;
		for (i in 0...10)
		{
			add(left); left = left.left;
			add(right); right = right.right;
		}
		
		var n = root.size;
		
		c = 0;
		root.preorder(
			function(_, _)
			{
				c++;
				return true;
			}, true);
		
		assertEquals(n, c);
		
		c = 0;
		root.postorder(
			function(_, _)
			{
				c++;
				return true;
			}, true);
		
		assertEquals(n, c);
		
		c = 0;
		root.inorder(
			function(node, u)
			{
				c++;
				return true;
			}, true);
		
		assertEquals(n, c);
	}
}

private class E
{
	public function new() {}
}