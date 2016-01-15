import de.polygonal.ds.BinaryTreeNode;
import haxe.ds.StringMap;

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
		assertEquals(1, node.size());
		
		var node = new BinaryTreeNode<String>("root");
		node.setL("e1");
		node.setR("e2");
		node.l.setL("e1");
		node.l.l.setR("e2");
		
		node.clear(true);
		assertEquals(1, node.size());
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
		
		assertEquals(2, node.size());
	}
	
	function testIterator()
	{
		var map = new StringMap<Bool>();
		
		var node = new BinaryTreeNode<String>("root");
		node.setL("a");
		node.setR("b");
		node.l.setL("c");
		node.l.l.setR("d");
		
		map.set("root", true);
		map.set("a", true);
		map.set("b", true);
		map.set("c", true);
		map.set("d", true);
		
		var c = 0;
		var itr = node.iterator();
		while (itr.hasNext())
		{
			itr.hasNext();
			var val = itr.next();
			assertTrue(map.exists(val));
			assertTrue(map.remove(val));
			c++;
		}
		assertEquals(5, c);
	}
}

private class E
{
	public function new() {}
}