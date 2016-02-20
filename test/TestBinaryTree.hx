import de.polygonal.ds.BinaryTreeNode;

class TestBinaryTree extends AbstractTest
{
	function testFree()
	{
		var node = new BinaryTreeNode<E>(new E());
		node.setL(new E());
		node.setR(new E());
		node.l.setL(new E());
		node.l.l.setR(new E());
		node.free();
		assertTrue(true);
	}
	
	function testClear()
	{
		var node = new BinaryTreeNode<String>("root");
		node.setL("e1");
		node.setR("e2");
		node.l.setL("e1");
		node.l.l.setR("e2");
		
		node.clear(false);
		assertEquals(1, node.size);
		
		var node = new BinaryTreeNode<String>("root");
		node.setL("e1");
		node.setR("e2");
		node.l.setL("e1");
		node.l.l.setR("e2");
		
		node.clear(true);
		assertEquals(1, node.size);
	}
	
	function testRemove()
	{
		var node = new BinaryTreeNode<String>("root");
		
		node.setL("e1");
		node.setR("e2");
		node.l.setL("e1");
		node.l.l.setR("e2");
		
		assertTrue(node.hasL());
		assertTrue(node.hasR());
		assertTrue(node.l.hasL());
		assertTrue(node.l.l.hasR());
		
		assertEquals("e1", node.l.val);
		assertEquals("e2", node.r.val);
		assertEquals("e1", node.l.l.val);
		assertEquals("e2", node.l.l.r.val);
		
		node.remove("e1");
		
		assertFalse(node.hasL());
		assertTrue(node.hasR());
		
		assertEquals(2, node.size);
	}
	
	function testClone()
	{
		var node = new BinaryTreeNode<String>("root");
		
		node.setL("e1");
		node.setR("e2");
		node.l.setL("e1");
		node.l.l.setR("e2");
		
		var copy:BinaryTreeNode<String> = cast node.clone(true);
		
		assertEquals("e1", copy.l.val);
		assertEquals("e2", copy.r.val);
		
		assertEquals("e1", copy.l.l.val);
		assertEquals("e2", copy.l.l.r.val);
	}
}

private class E
{
	public function new() {}
}