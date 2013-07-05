package;

import de.polygonal.ds.DLL;
import de.polygonal.ds.ListSet;

class TestDLLCircular extends haxe.unit.TestCase
{
	function testClose()
	{
		var list = new DLL<Int>();
		list.close();
		assertTrue(list.isCircular());
	}
	
	function testOpen()
	{
		var list = new DLL<Int>();
		list.close();
		assertTrue(list.isCircular());
		assertEquals(null, list.head);
		assertEquals(null, list.tail);
		
		list.open();
		assertFalse(list.isCircular());
		assertEquals(null, list.head);
		assertEquals(null, list.tail);
		
		list.append(0);
		list.close();
		assertEquals(list.tail, list.head);
		assertEquals(list.head, list.tail);
		
		list.append(1);
		assertEquals(list.tail.next, list.head);
		assertEquals(list.head.prev, list.tail);
	}
	
	function testShuffle()
	{
		var list = new DLL<Int>();
		list.close();
		for (i in 0...10) list.append(i);
		
		list.shuffle(null);
		assertEquals(list.tail.next, list.head);
		assertEquals(list.head.prev, list.tail);
		var s:ListSet<Int> = new ListSet<Int>();
		for (i in list) assertTrue(s.set(i));
		assertEquals(10, s.size());
	}
	
	function testAppend()
	{
		var list = new DLL<Int>();
		list.close();
		list.append(0);
		assertEquals(1, list.size());
		assertEquals(list.tail.next, list.head);
		assertEquals(list.head.prev, list.tail);
		
		list.append(1);
		list.append(2);
		assertEquals(3, list.size());
		assertEquals(list.tail.next, list.head);
		assertEquals(list.head.prev, list.tail);
	}
	
	function testPrepend()
	{
		var list = new DLL<Int>();
		list.close();
		list.prepend(0);
		assertEquals(1, list.size());
		assertEquals(list.tail.next, list.head);
		assertEquals(list.head.prev, list.tail);
		
		list.prepend(1);
		list.prepend(2);
		assertEquals(3, list.size());
		assertEquals(list.tail.next, list.head);
		assertEquals(list.head.prev, list.tail);
	}
	
	function testInsertAfter()
	{
		var list = new DLL<Int>();
		list.close();
		var node1 = list.append(0);
		list.insertAfter(node1, 1);
		assertEquals(list.head.val, 0);
		assertEquals(list.tail.val, 1);
		assertEquals(list.tail.next, list.head);
		assertEquals(list.head.prev, list.tail);
		
		var list = new DLL<Int>();
		list.close();
		var node1 = list.append(0);
		var node2 = list.append(1);
		var node3 = list.append(2);
		list.insertAfter(node1, 3);
		
		assertEquals(list.head.val, 0);
		assertEquals(list.head.next.val, 3);
		assertEquals(list.head.next.next.val, 1);
		assertEquals(list.head.next.next.next.val, 2);
		
		assertEquals(list.tail.next, list.head);
		assertEquals(list.head.prev, list.tail);
		
		var list = new DLL<Int>();
		list.close();
		var node1 = list.append(0);
		var node2 = list.append(1);
		var node3 = list.append(2);
		list.insertAfter(node3, 3);
		
		assertEquals(list.head.val, 0);
		assertEquals(list.head.next.val, 1);
		assertEquals(list.head.next.next.val, 2);
		assertEquals(list.head.next.next.next.val, 3);
		
		assertEquals(list.tail.next, list.head);
		assertEquals(list.head.prev, list.tail);
	}
	
	function testInsertBefore()
	{
		var list = new DLL<Int>();
		list.close();
		var node1 = list.append(0);
		list.insertBefore(node1, 1);
		assertEquals(list.head.val, 1);
		assertEquals(list.tail.val, 0);
		assertEquals(list.tail.next, list.head);
		assertEquals(list.head.prev, list.tail);
		
		var list = new DLL<Int>();
		list.close();
		var node1 = list.append(0);
		var node2 = list.append(1);
		var node3 = list.append(2);
		list.insertBefore(node1, 3);
		
		assertEquals(list.head.val, 3);
		assertEquals(list.head.next.val, 0);
		assertEquals(list.head.next.next.val, 1);
		assertEquals(list.head.next.next.next.val, 2);
		assertEquals(list.tail.next, list.head);
		assertEquals(list.head.prev, list.tail);
		
		var list = new DLL<Int>();
		list.close();
		var node1 = list.append(0);
		var node2 = list.append(1);
		var node3 = list.append(2);
		list.insertBefore(node3, 3);
		
		assertEquals(list.head.val, 0);
		assertEquals(list.head.next.val, 1);
		assertEquals(list.head.next.next.val, 3);
		assertEquals(list.head.next.next.next.val, 2);
		
		assertEquals(list.tail.next, list.head);
		assertEquals(list.head.prev, list.tail);
	}
	
	function testRemove()
	{
		var list = new DLL<Int>();
		list.close();
		var node1 = list.append(0);
		list.unlink(node1);
		assertEquals(null, list.head);
		assertEquals(null, list.tail);
		
		var list = new DLL<Int>();
		list.close();
		var node1 = list.append(0);
		var node2 = list.append(1);
		list.unlink(node2);
		assertEquals(node1, list.head);
		assertEquals(node1, list.tail);
		
		assertEquals(list.tail.next, list.head);
		assertEquals(list.head.prev, list.tail);
		
		var list = new DLL<Int>();
		list.close();
		var node1 = list.append(0);
		var node2 = list.append(1);
		var node3 = list.append(2);
		list.unlink(node2);
		assertEquals(node1, list.head);
		assertEquals(node3, list.tail);
		
		assertEquals(list.tail.next, list.head);
		assertEquals(list.head.prev, list.tail);
	}
	
	function testGetNodeAt()
	{
		var list = new DLL<Int>();
		list.close();
		var node1 = list.append(0);
		assertEquals(node1, list.getNodeAt(0));
		
		var list = new DLL<Int>();
		list.close();
		var node1 = list.append(0);
		var node2 = list.append(1);
		assertEquals(node2, list.getNodeAt(1));
		
		var list = new DLL<Int>();
		list.close();
		var node1 = list.append(0);
		var node2 = list.append(1);
		var node3 = list.append(2);
		assertEquals(node3, list.getNodeAt(2));
	}
	
	function testRemoveHead()
	{
		var list = new DLL<Int>();
		list.close();
		var node1 = list.append(0);
		list.removeHead();
		
		assertEquals(null, list.head);
		assertEquals(null, list.tail);
		
		var list = new DLL<Int>();
		list.close();
		var node1 = list.append(0);
		var node2 = list.append(1);
		list.removeHead();
		
		assertEquals(node2, list.head);
		assertEquals(list.tail.next, list.head);
		assertEquals(list.head.prev, list.tail);
		
		var list = new DLL<Int>();
		list.close();
		var node1 = list.append(0);
		var node2 = list.append(1);
		var node3 = list.append(2);
		list.removeHead();
		
		assertEquals(node2, list.head);
		assertEquals(list.tail.next, list.head);
		assertEquals(list.head.prev, list.tail);
	}
	
	function testRemoveTail()
	{
		var list = new DLL<Int>();
		list.close();
		var node1 = list.append(0);
		list.removeTail();
		
		assertEquals(null, list.head);
		assertEquals(null, list.tail);
		
		var list = new DLL<Int>();
		list.close();
		var node1 = list.append(0);
		var node2 = list.append(1);
		list.removeTail();
		
		assertEquals(node1, list.tail);
		assertEquals(list.tail.next, list.head);
		assertEquals(list.head.prev, list.tail);
		
		var list = new DLL<Int>();
		list.close();
		var node1 = list.append(0);
		var node2 = list.append(1);
		var node3 = list.append(2);
		list.removeTail();
		
		assertEquals(node2, list.tail);
		assertEquals(list.tail.next, list.head);
		assertEquals(list.head.prev, list.tail);
	}
	
	function testShiftUp()
	{
		var list = new DLL<Int>();
		list.close();
		var node1 = list.append(0);
		var node2 = list.append(1);
		
		list.shiftUp();
		
		assertEquals(node2, list.head);
		assertEquals(node1, list.tail);
		assertEquals(list.tail.next, list.head);
		assertEquals(list.head.prev, list.tail);
		
		var list = new DLL<Int>();
		list.close();
		var node1 = list.append(0);
		var node2 = list.append(1);
		var node3 = list.append(2);
		
		list.shiftUp();
		
		assertEquals(node2, list.head);
		assertEquals(node1, list.tail);
		assertEquals(list.tail.next, list.head);
		assertEquals(list.head.prev, list.tail);
	}
	
	function testPopDown()
	{
		var list = new DLL<Int>();
		list.close();
		var node1 = list.append(0);
		var node2 = list.append(1);
		
		list.popDown();
		
		assertEquals(node2, list.head);
		assertEquals(node1, list.tail);
		assertEquals(list.tail.next, list.head);
		assertEquals(list.head.prev, list.tail);
		
		var list = new DLL<Int>();
		list.close();
		var node1 = list.append(0);
		var node2 = list.append(1);
		var node3 = list.append(2);
		
		list.popDown();
		
		assertEquals(node3, list.head);
		assertEquals(node2, list.tail);
		assertEquals(list.tail.next, list.head);
		assertEquals(list.head.prev, list.tail);
	}
	
	function testNodeOf()
	{
		var list = new DLL<Int>();
		list.close();
		var node1 = list.append(0);
		assertEquals(node1, list.nodeOf(0, list.head));
		
		var list = new DLL<Int>();
		list.close();
		var node1 = list.append(0);
		var node2 = list.append(1);
		var node3 = list.append(2);
		
		assertEquals(node1, list.nodeOf(0, list.head));
		assertEquals(node2, list.nodeOf(1, list.head));
		assertEquals(node3, list.nodeOf(2, list.head));
	}
	
	function testLastNodeOf()
	{
		var list = new DLL<Int>();
		list.close();
		var node1 = list.append(0);
		assertEquals(node1, list.lastNodeOf(0, list.head));
		
		var list = new DLL<Int>();
		list.close();
		var node1 = list.append(0);
		var node2 = list.append(1);
		var node3 = list.append(2);
		
		assertEquals(node1, list.lastNodeOf(0, list.head));
		assertEquals(node2, list.lastNodeOf(1, list.tail));
		assertEquals(null, list.lastNodeOf(1, list.head));
		assertEquals(node3, list.lastNodeOf(2, list.tail));
	}
	
	function testMerge()
	{
		var list1 = new DLL<Int>();
		list1.close();
		list1.append(0);
		list1.append(1);
		
		var list2 = new DLL<Int>();
		list2.close();
		list2.append(2);
		list2.append(3);
		
		list1.merge(list2);
		
		assertEquals(4, list1.size());
		assertEquals(list1.tail.next, list1.head);
		assertEquals(list1.head.prev, list1.tail);
	}
	
	function testConcat()
	{
		var list1 = new DLL<Int>();
		list1.close();
		list1.append(0);
		list1.append(1);
		list1.append(2);
		
		var list2 = new DLL<Int>();
		list2.close();
		list2.append(3);
		list2.append(4);
		list2.append(5);
		
		var list3 = list1.concat(list2);
		assertEquals(null, list3.tail.next);
		assertEquals(null, list3.head.prev);
		
		var node = list3.head;
		for (i in 0...list1.size() + list2.size())
		{
			assertEquals(i, node.val);
			node = node.next;
		}
		
		var list1 = new DLL<Int>();
		list1.append(0);
		list1.append(1);
		list1.append(2);
		var list2 = new DLL<Int>();
		
		var list3 = list1.concat(list2);
		assertEquals(null, list3.tail.next);
		assertEquals(null, list3.head.prev);
		
		var node = list3.head;
		for (i in 0...list1.size() + list2.size())
		{
			assertEquals(i, node.val);
			node = node.next;
		}
	}
	
	function testReverse()
	{
		var list = new DLL<Int>();
		list.close();
		list.append(0);
		list.append(1);
		list.reverse();
		assertEquals(1, list.head.val);
		assertEquals(0, list.tail.val);
		assertEquals(list.tail.next, list.head);
		assertEquals(list.head.prev, list.tail);
		
		var list = new DLL<Int>();
		list.close();
		list.append(0);
		list.append(1);
		list.append(2);
		list.reverse();
		
		assertEquals(2, list.head.val);
		assertEquals(1, list.head.next.val);
		assertEquals(0, list.head.next.next.val);
		assertEquals(list.tail.next, list.head);
		assertEquals(list.head.prev, list.tail);
	}
	
	function testJoin()
	{
		var list = new DLL<Int>();
		list.close();
		list.append(0);
		assertEquals('0',list.join('|'));
		list.append(1);
		assertEquals('0|1',list.join('|'));
		list.append(2);
		assertEquals('0|1|2',list.join('|'));
	}
	
	function testIterator()
	{
		var list = new DLL<Int>();
		for (i in 0...10) list.append(i);
		list.close();
		var c = 0;
		for (i in list) assertEquals(c++, i);
		assertEquals(10, c);
	}
	
	function testIteratorRemove()
	{
		for (i in 0...5)
		{
			var list = new DLL<Int>();
			var set = new de.polygonal.ds.ListSet<Int>();
			for (j in 0...5)
			{
				list.append(j);
				if (i != j) set.set(j);
			}
			list.close();
			
			var itr = list.iterator();
			while (itr.hasNext())
			{
				var val = itr.next();
				if (val == i) itr.remove();
			}
			
			while (!list.isEmpty())
			{
				assertTrue(set.remove(list.removeHead()));
			}
			assertTrue(set.isEmpty());
		}
		
		for (i in 0...5)
		{
			var list = new DLL<Int>();
			var set = new de.polygonal.ds.ListSet<Int>();
			for (j in 0...i)
			{
				list.append(j);
				set.set(j);
			}
			list.close();
			
			var itr = list.iterator();
			while (itr.hasNext())
			{
				var value = itr.next();
				itr.remove();
				set.remove(value);
			}
			assertTrue(list.isEmpty());
			assertTrue(set.isEmpty());
		}
	}
}

private class E implements de.polygonal.ds.Comparable<E>
{
	var id:Int;
	public function new(id:Int)
	{
		this.id = id;
	}
	
	public function compare(other:E):Int
	{
		return id - other.id;
	}
	
	public function toString():String
	{
		return '' + id;
	}
}