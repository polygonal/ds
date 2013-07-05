package;

import de.polygonal.ds.ArrayConvert;
import de.polygonal.ds.Compare;
import de.polygonal.ds.DA;
import de.polygonal.ds.ListSet;
import de.polygonal.ds.SLL;
import de.polygonal.ds.SLLNode;

class TestSLL extends haxe.unit.TestCase
{
	function testCircular()
	{
		var l = new SLL<Int>();
		l.close();
		
		l.append(0);
		assertEquals(l.head, l.tail.next);
		
		l.append(1);
		
		assertEquals(0, l.head.val);
		assertEquals(1, l.tail.val);
		assertEquals(l.tail, l.head.next);
		assertEquals(l.head, l.tail.next);
		
		l.prepend(2);
		
		assertEquals(2, l.head.val);
		assertEquals(0, l.head.next.val);
		assertEquals(1, l.tail.val);
		assertEquals(l.head, l.tail.next);
		
		var l = new SLL<Int>();
		l.close();
		l.append(0);
		l.insertAfter(l.nodeOf(0), 1);
		
		assertEquals(0, l.head.val);
		assertEquals(l.head, l.tail.next);
		
		l.insertAfter(l.nodeOf(1), 2);
		
		assertEquals(0, l.head.val);
		assertEquals(1, l.head.next.val);
		assertEquals(2, l.tail.val);
		assertEquals(l.head, l.tail.next);
		
		l.insertAfter(l.nodeOf(1), 3);
		
		assertEquals(0, l.head.val);
		assertEquals(1, l.head.next.val);
		assertEquals(3, l.head.next.next.val);
		assertEquals(2, l.head.next.next.next.val);
		assertEquals(2, l.tail.val);
		assertEquals(l.head, l.tail.next);
		
		var l = new SLL<Int>();
		l.close();
		l.append(0);
		l.insertBefore(l.nodeOf(0), 1);
		
		assertEquals(1, l.head.val);
		assertEquals(0, l.head.next.val);
		assertEquals(0, l.tail.val);
		assertEquals(l.head, l.tail.next);
		
		var l = new SLL<Int>();
		l.close();
		l.append(0);
		l.append(1);
		l.append(2);
		
		var node = l.nodeOf(2);
		l.unlink(node);
		
		assertEquals(1, l.tail.val);
		assertEquals(l.head, l.tail.next);
		assertEquals(0, l.head.val);
		assertEquals(null, node.next);
		
		node = l.nodeOf(0);
		l.unlink(node);
		
		assertEquals(1, l.head.val);
		assertEquals(1, l.tail.val);
		assertEquals(l.head, l.tail.next);
		assertEquals(null, node.next);
		
		var node = l.nodeOf(1);
		l.unlink(node);
		assertEquals(null, l.head);
		assertEquals(null, l.tail);
		assertEquals(null, node.next);
		
		var l = new SLL<Int>();
		l.close();
		l.append(0);
		l.append(1);
		l.append(2);
		
		l.removeHead();
		assertEquals(2, l.tail.val);
		assertEquals(1, l.head.val);
		assertEquals(l.head, l.tail.next);
		
		l.removeHead();
		assertEquals(2, l.head.val);
		assertEquals(2, l.tail.val);
		assertEquals(l.head, l.tail.next);
		
		l.removeHead();
		assertEquals(null, l.head);
		assertEquals(null, l.tail);
		
		var l = new SLL<Int>();
		l.close();
		l.append(0);
		l.append(1);
		l.append(2);
		
		l.removeTail();
		assertEquals(1, l.tail.val);
		assertEquals(0, l.head.val);
		assertEquals(l.head, l.tail.next);
		
		l.removeTail();
		assertEquals(0, l.head.val);
		assertEquals(0, l.tail.val);
		assertEquals(l.head, l.tail.next);
		
		l.removeTail();
		assertEquals(null, l.head);
		assertEquals(null, l.tail);
		
		var l = new SLL<Int>();
		l.close();
		l.append(0);
		l.append(1);
		
		l.shiftUp();
		assertEquals(1, l.head.val);
		assertEquals(0, l.tail.val);
		assertEquals(l.head, l.tail.next);
		
		var l = new SLL<Int>();
		l.close();
		l.append(0);
		l.append(1);
		l.append(2);
		
		l.shiftUp();
		assertEquals(1, l.head.val);
		assertEquals(0, l.tail.val);
		assertEquals(l.head, l.tail.next);
		
		var l = new SLL<Int>();
		l.close();
		l.append(0);
		l.append(1);
		
		l.popDown();
		assertEquals(1, l.head.val);
		assertEquals(0, l.tail.val);
		assertEquals(l.head, l.tail.next);
		
		var l = new SLL<Int>();
		l.close();
		l.append(0);
		l.append(1);
		l.append(2);
		
		l.popDown();
		assertEquals(2, l.head.val);
		assertEquals(1, l.tail.val);
		assertEquals(l.head, l.tail.next);
	}
	
	function testPool()
	{
		var l = new SLL<Int>(20);
		
		for (i in 0...10) l.append(i);
		for (i in 0...10) l.removeHead();
		assertEquals(10, untyped l._poolSize);
		
		for (i in 0...10) l.append(i);
		assertEquals(0, untyped l._poolSize);
		
		for (i in 0...10) l.removeTail();
		assertEquals(10, untyped l._poolSize);
		
		for (i in 0...10) l.prepend(i);
		assertEquals(0, untyped l._poolSize);
		
		assertEquals(10, l.size());
		assertTrue(l.head != null);
		
		for (i in 0...10)
			l.head.unlink();
		
		assertEquals(10, untyped l._poolSize);
		assertEquals(0, l.size());
		assertTrue(l.head == null);
	}
	
	function testRemove()
	{
		var list = new SLL<Int>();
		for (i in 0...10) list.append(i);
		
		var head = list.head;
		var node = head;
		
		for (i in 0...8) node = node.next;
		
		assertTrue(list.remove(9));
		assertEquals(9, list.size());
		assertEquals(node, list.tail);
		assertEquals(list.join(''), '012345678');
		
		assertTrue(list.remove(0));
		assertEquals(8, list.size());
		assertEquals(list.join(''), '12345678');
		
		var list = new SLL<Int>();
		for (i in 0...10) list.append(i);
		var i = 0;
		while (!list.isEmpty())
		{
			assertTrue(list.remove(i++));
			if (list.size() == 1)
				assertEquals(list.head, list.tail);
		}
		
		assertTrue(list.isEmpty());
		
		var list = new SLL<Int>();
		for (i in 0...10) list.append(i);
		var i = 9;
		while (!list.isEmpty())
		{
			assertTrue(list.remove(i--));
			if (list.size() == 1)
				assertEquals(list.head, list.tail);
		}
		
		assertTrue(list.isEmpty());
		
		var list = new SLL<Int>();
		for (i in 0...10) list.append(1);
		
		assertTrue(list.remove(1));
		assertTrue(list.isEmpty());
		
		assertEquals(null, list.head);
		assertEquals(null, list.tail);
		
		//circular
		var list = new SLL<Int>();
		list.close();
		for (i in 0...10) list.append(i);
		assertTrue(list.remove(9));
		assertEquals(9, list.size());
		
		var head = list.head;
		var node = head;
		for (i in 0...8) node = node.next;
		assertEquals(node, list.tail);
		assertEquals(list.join(''), '012345678');
		
		assertTrue(list.remove(0));
		assertEquals(8, list.size());
		assertEquals(list.join(''), '12345678');
		
		assertEquals(list.head, list.tail.next);
		
		var list = new SLL<Int>();
		list.close();
		for (i in 0...10) list.append(i);
		var i = 0;
		while (!list.isEmpty())
		{
			assertTrue(list.remove(i++));
			
			if (list.size() > 0)
				assertEquals(list.head, list.tail.next);
			
			if (list.size() == 1)
				assertEquals(list.head, list.tail);
		}
		
		assertTrue(list.isEmpty());
		
		var list = new SLL<Int>();
		list.close();
		for (i in 0...10) list.append(i);
		var i = 9;
		while (!list.isEmpty())
		{
			assertTrue(list.remove(i--));
			
			if (list.size() == 1)
				assertEquals(list.head, list.tail);
		}
		
		assertTrue(list.isEmpty());
		
		var list = new SLL<Int>();
		for (i in 0...10) list.append(1);
		
		assertTrue(list.remove(1));
		assertTrue(list.isEmpty());
		
		assertEquals(null, list.head);
		assertEquals(null, list.tail);
		
		var list = new SLL<Int>();
		list.close();
		list.append(0);
		list.append(1);
		list.remove(0);
		assertEquals(list.head, list.tail.next);
		assertEquals(1, list.head.val);
		assertEquals(1, list.tail.val);
	}
	
	function testShuffle()
	{
		var list = new SLL<Int>();
		for (i in 0...10) list.append(i);
		
		var s = new ListSet();
		list.shuffle(null);
		var node = list.head;
		while (node != null)
		{
			if (s.has(node.val)) throw 'error';
			s.set(node.val);
			node = node.next;
		}
		assertEquals(10, s.size());
		
		//circular
		var list = new SLL<Int>();
		list.close();
		for (i in 0...10) list.append(i);
		
		var s = new ListSet();
		list.shuffle(null);
		var node = list.head;
		for (i in 0...list.size())
		{
			if (s.has(node.val)) throw 'error';
			s.set(node.val);
			node = node.next;
		}
		
		assertEquals(10, s.size());
	}
	
	#if debug
	function testMaxSize()
	{
		var list = new SLL<Int>(0, 3);
		list.append(1);
		list.append(2);
		list.append(3);
		var failed = false;
		try
		{
			list.append(4);
		}
		catch (unknown:Dynamic)
		{
			failed = true;
		}
		assertTrue(failed);
		
		return;
		
		var list = ArrayConvert.toSLL([0, 1, 2]);
		var failed = false;
		try
		{
			list.prepend(4);
		}
		catch (unknown:Dynamic)
		{
			failed = true;
		}
		assertTrue(failed);
		
		var list = ArrayConvert.toSLL([0, 1, 2]);
		var failed = false;
		try
		{
			list.insertAfter(list.nodeOf(0, null), 4);
		}
		catch (unknown:Dynamic)
		{
			failed = true;
		}
		assertTrue(failed);
		
		var list = ArrayConvert.toSLL([0, 1, 2]);
		var failed = false;
		try
		{
			list.insertBefore(list.nodeOf(0, null), 4);
		}
		catch (unknown:Dynamic)
		{
			failed = true;
		}
		assertTrue(failed);
		
		var list1 = ArrayConvert.toSLL([0, 1, 2]);
		var list2 = ArrayConvert.toSLL([0, 1, 2]);
		var failed = false;
		try
		{
			list1.merge(list2);
		}
		catch (unknown:Dynamic)
		{
			failed = true;
		}
		assertTrue(failed);
		
		var list = ArrayConvert.toSLL([0, 1, 2]);
		var failed = false;
		try
		{
			list.fill(0, 10);
		}
		catch (unknown:Dynamic)
		{
			failed = true;
		}
		assertTrue(failed);
	}
	#end
	
	function testFill()
	{
		var list = new SLL<Int>();
		for (i in 0...10) list.append(i);
		
		list.fill(0);
		
		var n = list.head;
		for (i in 0...10)
		{
			assertEquals(0, n.val);
			n = n.next;
		}
		
		var list = new SLL<Int>();
		for (i in 0...10) list.append(i);
		
		list.fill(0, 5);
		
		var n = list.head;
		for (i in 0...5)
		{
			assertEquals(0, n.val);
			n = n.next;
		}
		for (i in 0...5)
		{
			assertEquals(i+5, n.val);
			n = n.next;
		}
		
		var list = new SLL<Int>();
		list.close();
		for (i in 0...10) list.append(i);
		
		list.fill(0);
		
		var n = list.head;
		for (i in 0...10)
		{
			assertEquals(0, n.val);
			n = n.next;
		}
	}
	
	function testAssign()
	{
		var list = new SLL<E>();
		for (i in 0...10) list.append(null);
		
		list.assign(E, [0]);
		
		var n = list.head;
		for (i in 0...10)
		{
			assertEquals(E, cast Type.getClass(n.val));
			n = n.next;
		}
		
		var list = new SLL<E>();
		for (i in 0...10) list.append(null);
		
		list.assign(E, [1], 5);
		
		var n = list.head;
		for (i in 0...5)
		{
			assertEquals(E, cast Type.getClass(n.val));
			n = n.next;
		}
		
		for (i in 0...5)
		{
			assertEquals(null, n.val);
			n = n.next;
		}
		
		var list = new SLL<E>();
		for (i in 0...10) list.append(null);
		
		list.assign(E, [5], 10);
		
		var n = list.head;
		for (i in 0...10)
		{
			assertEquals(5, n.val.x);
			n = n.next;
		}
		
		var list = new SLL<E>();
		list.close();
		for (i in 0...10) list.append(null);
		
		list.assign(E, [0]);
		
		var n = list.head;
		for (i in 0...10)
		{
			assertEquals(E, cast Type.getClass(n.val));
			n = n.next;
		}
	}
	
	function testGetNodeAt()
	{
		var list = new SLL<Int>();
		for (i in 0...10) list.append(i);
		
		assertEquals(list.getNodeAt(0).val, 0);
		assertEquals(list.getNodeAt(9).val, 9);
	}
	
	function testInsertAfter()
	{
		var list = new SLL<Int>();
		list.append(0);
		
		var newNode:SLLNode<Int> = list.insertAfter(list.head, 1);
		
		assertEquals(2, list.size());
		assertEquals(0, list.head.val);
		assertEquals(1, list.head.next.val);
		assertEquals(list.tail.next, null);
		assertEquals(list.head.next, list.tail);
		
		list = new SLL<Int>();
		list.append(0);
		list.append(1);
		list.append(2);
		
		var node = list.insertAfter(list.nodeOf(1), 4);
		
		assertEquals(0, list.head.val);
		assertEquals(1, list.head.next.val);
		assertEquals(4, list.head.next.next.val);
		assertEquals(2, list.tail.val);
	}
	
	function testInsertBefore()
	{
		var list = new SLL<Int>();
		list.append(0);
		var newNode:SLLNode<Int> = list.insertBefore(list.head, 1);
		
		assertEquals(2, list.size());
		assertEquals(1, list.head.val);
		assertEquals(0, list.head.next.val);
		
		assertEquals(list.head.next, list.tail);
		assertEquals(list.tail.next, null);
		
		var list = new SLL<Int>();
		list.append(0);
		list.append(1);
		var newNode:SLLNode<Int> = list.insertBefore(list.tail, 2);
		
		assertEquals(3, list.size());
		assertEquals(0, list.head.val);
		assertEquals(2, list.head.next.val);
		assertEquals(1, list.head.next.next.val);
		assertEquals(null, list.tail.next);
		assertEquals(1, list.tail.val);
	}
	
	function testJoin()
	{
		var list = new SLL<Int>();
		for (i in 0...10) list.append(i);
		assertEquals(list.join(''), '0123456789');
		
		var list = new SLL<Int>();
		list.close();
		for (i in 0...10) list.append(i);
		assertEquals(list.join(''), '0123456789');
	}
	
	function testReverse()
	{
		var list = new SLL<Int>();
		for (i in 0...10) list.append(i);
		list.reverse();
		var j = 10;
		for (i in list) assertEquals(i, --j);
		
		
		var list = new SLL<Int>();
		list.close();
		for (i in 0...10) list.append(i);
		list.reverse();
		var j = 10;
		for (i in list) assertEquals(i, --j);
	}
	
	function testNodeOf()
	{
		var list = new SLL<Int>();
		var data:Array<Int> = [2, 3, 4, 9, 5, 1, 7, 6, 8, 0];
		for (i in 0...10) list.append(data[i]);
		
		var node:SLLNode<Int> = list.nodeOf(3, list.head);
		assertTrue(node != null);
		assertEquals(3, node.val);
		
		var node:SLLNode<Int> = list.nodeOf(5, list.head.next.next);
		assertTrue(node != null);
		assertEquals(5, node.val);
	}
	
	function testMerge()
	{
		var list1 = new SLL<Int>();
		var data:Array<Int> = [0, 1, 2, 3, 4];
		for (i in 0...data.length) list1.append(data[i]);
		
		var list2 = new SLL<Int>();
		var data:Array<Int> = [5, 6, 7, 8, 9];
		for (i in 0...data.length) list2.append(data[i]);
		
		list1.merge(list2);
		
		var c = 0;
		assertEquals(10, list1.size());
		for (i in list1) assertEquals(c++, i);
		
		var list1 = new SLL<Int>();
		list1.close();
		var data:Array<Int> = [0, 1, 2, 3, 4];
		for (i in 0...data.length) list1.append(data[i]);
		
		var list2 = new SLL<Int>();
		list2.close();
		var data:Array<Int> = [5, 6, 7, 8, 9];
		for (i in 0...data.length) list2.append(data[i]);
		
		list1.merge(list2);
		
		var c = 0;
		assertEquals(10, list1.size());
		for (i in list1) assertEquals(c++, i);
		
		assertEquals(list1.head, list1.tail.next);
	}
	
	function testConcat()
	{
		var list1 = new SLL<Int>();
		var data:Array<Int> = [0, 1, 2, 3, 4];
		for (i in 0...data.length) list1.append(data[i]);
		
		var list2 = new SLL<Int>();
		var data:Array<Int> = [5, 6, 7, 8, 9];
		for (i in 0...data.length) list2.append(data[i]);
		
		var list3 = new SLL<Int>();
		list3 = list3.concat(list1);
		list3 = list3.concat(list2);
		
		var c = 0;
		assertEquals(10, list3.size());
		for (i in list1) assertEquals(c++, i);
		
		//circular, also test concat DLL
		var list1 = new SLL<Int>();
		list1.close();
		var data:Array<Int> = [0, 1, 2, 3, 4];
		for (i in 0...data.length) list1.append(data[i]);
		
		var list2 = new SLL<Int>();
		list2.close();
		var data:Array<Int> = [5, 6, 7, 8, 9];
		for (i in 0...data.length) list2.append(data[i]);
		
		var list3 = new SLL<Int>();
		//list3.close();
		list3 = list3.concat(list1);
		list3 = list3.concat(list2);
		
		var c = 0;
		assertEquals(10, list3.size());
		for (i in list1) assertEquals(c++, i);
	}
	
	function testSortTail()
	{
		//insertion sort
		var list = new SLL<Int>();
		
		list.append(1);
		list.append(3);
		list.append(2);
		
		list.sort(Compare.compareNumberRise, true);
		
		var c = 1; for (i in list) assertEquals(c++, i);
		assertFalse(list.tail.hasNext());
		
		list.sort(Compare.compareNumberFall, true);
		
		var c = 3; for (i in list) assertEquals(c--, i);
		assertFalse(list.tail.hasNext());
		
		list.clear();
		list.append(3);
		list.append(2);
		list.append(1);
		list.sort(Compare.compareNumberRise, true);
		var c = 1; for (i in list) assertEquals(c++, i);
		assertFalse(list.tail.hasNext());
		list.sort(Compare.compareNumberFall, true);
		var c = 3; for (i in list) assertEquals(c--, i);
		assertFalse(list.tail.hasNext());
		
		//merge sort
		var list = new SLL<Int>();
		
		list.append(1);
		list.append(3);
		list.append(2);
		
		list.sort(Compare.compareNumberRise);
		
		var c = 1; for (i in list) assertEquals(c++, i);
		assertFalse(list.tail.hasNext());
		
		list.sort(Compare.compareNumberFall);
		
		var c = 3; for (i in list) assertEquals(c--, i);
		assertFalse(list.tail.hasNext());
		
		list.clear();
		list.append(3);
		list.append(2);
		list.append(1);
		list.sort(Compare.compareNumberRise);
		var c = 1; for (i in list) assertEquals(c++, i);
		assertFalse(list.tail.hasNext());
		list.sort(Compare.compareNumberFall);
		var c = 3; for (i in list) assertEquals(c--, i);
		assertFalse(list.tail.hasNext());
	}
	
	function testSort()
	{
		var list = new SLL<Int>();
		
		var data:Array<Int> = [2, 3, 4, 9, 5, 1, 7, 6, 8, 0];
		for (i in 0...10) list.append(data[i]);
		
		list.sort(Compare.compareNumberRise, false);
		var c = 0;
		for (i in list) assertEquals(c++, i);
		
		list.sort(Compare.compareNumberFall, false);
		var c = 10;
		for (i in list) assertEquals(--c, i);
		
		list.sort(Compare.compareNumberRise, true);
		var c = 0;
		for (i in list) assertEquals(c++, i);
		
		list.sort(Compare.compareNumberFall, true);
		var c = 10;
		for (i in list) assertEquals(--c, i);
		
		var list:SLL<ESortable> = new SLL<ESortable>();
		var data:Array<Int> = [2, 3, 4, 9, 5, 1, 7, 6, 8, 0];
		for (i in 0...10)
			list.append(new ESortable(data[i]));
		list.sort(null);
		var c = 10;
		for (i in list)
			assertEquals(--c, i.id);
		
		var list:SLL<ESortable> = new SLL<ESortable>();
		var data:Array<Int> = [2, 3, 4, 9, 5, 1, 7, 6, 8, 0];
		for (i in 0...10)
			list.append(new ESortable(data[i]));
		list.sort(null, true);
		var c = 10;
		for (i in list)
			assertEquals(--c, i.id);
	}
	
	function testSortComparable()
	{
		var list = new SLL<Int>();
		
		var data:Array<Int> = [2, 3, 4, 9, 5, 1, 7, 6, 8, 0];
		for (i in 0...10) list.append(data[i]);
		
		list.sort(Compare.compareNumberRise, false);
		var c = 0;
		for (i in list) assertEquals(c++, i);
		
		list.sort(Compare.compareNumberFall, false);
		var c = 10;
		for (i in list) assertEquals(--c, i);
		
		list.sort(Compare.compareNumberRise, true);
		var c = 0;
		for (i in list) assertEquals(c++, i);
		
		list.sort(Compare.compareNumberFall, true);
		var c = 10;
		for (i in list) assertEquals(--c, i);
	}
	
	function testSortCircular()
	{
		var list = new SLL<Int>();
		
		var data:Array<Int> = [2, 3, 4, 9, 5, 1, 7, 6, 8, 0];
		for (i in 0...10) list.append(data[i]);
		
		list.sort(Compare.compareNumberRise, false);
		var c = 0;
		for (i in list) assertEquals(c++, i);
		
		list.sort(Compare.compareNumberFall, false);
		var c = 10;
		for (i in list) assertEquals(--c, i);
		
		list.sort(Compare.compareNumberRise, true);
		var c = 0;
		for (i in list) assertEquals(c++, i);
	}
	
	function testIterator()
	{
		var list = new SLL<Int>();
		for (i in 0...10) list.append(i);
		var j = 0;
		for (i in list) assertEquals(i, j++);
		assertEquals(10, j);
		
		var itr:de.polygonal.ds.ResettableIterator<Int> = cast list.iterator();
		j = 0;
		for (i in itr) assertEquals(i, j++);
		assertEquals(10, j);
		
		itr.reset();
		j = 0;
		for (i in itr) assertEquals(i, j++);
		assertEquals(10, j);
	}
	
	function testIteratorRemove()
	{
		for (i in 0...5)
		{
			var list = new SLL<Int>();
			var set = new de.polygonal.ds.ListSet<Int>();
			for (j in 0...5)
			{
				list.append(j);
				if (i != j) set.set(j);
			}
			
			var itr = list.iterator();
			while (itr.hasNext())
			{
				var val = itr.next();
				if (val == i) itr.remove();
			}
			
			while (!list.isEmpty())
				assertTrue(set.remove(list.removeHead()));
			assertTrue(set.isEmpty());
		}
		
		for (i in 0...5)
		{
			var list = new SLL<Int>();
			var set = new de.polygonal.ds.ListSet<Int>();
			for (j in 0...i)
			{
				list.append(j);
				set.set(j);
			}
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
	
	function testIteratorRemoveCircular()
	{
		for (i in 0...5)
		{
			var list = new SLL<Int>();
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
				assertTrue(set.remove(list.removeHead()));
			assertTrue(set.isEmpty());
		}
		
		for (i in 0...5)
		{
			var list = new SLL<Int>();
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
	
	function testContains()
	{
		var list = new SLL<Int>();
		for (i in 0...10) list.append(i);
		for (i in 0...10) assertTrue(list.contains(i));
		
		var list = new SLL<Int>();
		list.close();
		for (i in 0...10) list.append(i);
		for (i in 0...10) assertTrue(list.contains(i));
	}
	
	function testClone()
	{
		//size 0
		var list = new SLL<Int>();
		var copy:SLL<Int> = cast list.clone(true);
		assertEquals(0, copy.size());
		
		//size 1
		var list = new SLL<Int>();
		list.append(0);
		var copy:SLL<Int> = cast list.clone(true);
		assertEquals(1, copy.size());
		assertEquals(0, copy.head.val);
		assertEquals(0, copy.tail.val);
		assertEquals(copy.head, copy.tail);
		
		//size 2
		var list = new SLL<Int>();
		list.append(0);
		list.append(1);
		var copy:SLL<Int> = cast list.clone(true);
		assertEquals(2, copy.size());
		assertEquals(0, copy.head.val);
		assertEquals(1, copy.tail.val);
		assertEquals(copy.head.next, copy.tail);
		assertEquals(1, copy.head.next.val);
		assertEquals(null, copy.tail.next);
		
		//size>2
		var list = new SLL<Int>();
		for (i in 0...10) list.append(i);
		
		var copy:SLL<Int> = cast list.clone(true);
		assertEquals(10, copy.size());
		
		var j = 0;
		for (i in copy) assertEquals(i, j++);
		
		var i = 0;
		var node = copy.head;
		while (node != null)
		{
			assertEquals(i++, node.val);
			node = node.next;
		}
		
		//circular
		//size 0
		var list = new SLL<Int>();
		list.close();
		var copy:SLL<Int> = cast list.clone(true);
		assertEquals(0, copy.size());
		
		//size 1
		var list = new SLL<Int>();
		list.close();
		list.append(0);
		var copy:SLL<Int> = cast list.clone(true);
		assertEquals(1, copy.size());
		assertEquals(0, copy.head.val);
		assertEquals(0, copy.tail.val);
		assertEquals(copy.head, copy.tail);
		assertTrue(copy.isCircular());
		assertEquals(copy.head, copy.tail.next);
		
		//size 2
		var list = new SLL<Int>();
		list.close();
		list.append(0);
		list.append(1);
		var copy = cast list.clone(true);
		assertEquals(2, copy.size());
		assertEquals(0, copy.head.val);
		assertEquals(1, copy.tail.val);
		assertEquals(copy.head.next, copy.tail);
		assertEquals(1, copy.head.next.val);
		assertEquals(copy.head, cast copy.tail.next);
		assertTrue(copy.isCircular());
		
		//size 10
		var list = new SLL<Int>();
		list.close();
		for (i in 0...10) list.append(i);
		
		var copy:SLL<Int> = cast list.clone(true);
		assertEquals(10, copy.size());
		assertEquals(copy.head, copy.tail.next);
		assertTrue(copy.isCircular());
		assertEquals(0, copy.head.val);
		assertEquals(9, copy.tail.val);
		var j = 0;
		for (i in copy) assertEquals(i, j++);
		var node = copy.head;
		for (i in 0...copy.size())
		{
			assertEquals(i, node.val);
			node = node.next;
		}
	}
	
	function testArray()
	{
		var list = new SLL<Int>();
		for (i in 0...10) list.append(i);
		var a:Array<Int> = list.toArray();
		for (i in a) assertEquals(a[i], i);
	}
	
	function testClear()
	{
		var list = new SLL<Int>();
		for (i in 0...10) list.append(i);
		list.clear();
		assertEquals(list.size(), 0);
		assertEquals(list.head, null);
		assertEquals(list.tail, null);
		
		var list = new SLL<Int>(10);
		for (i in 0...10) list.append(i);
		for (i in 0...10) list.removeHead();
		for (i in 0...10) list.append(i);
		
		list.clear(true);
		assertEquals(list.size(), 0);
		assertEquals(list.head, null);
		assertEquals(list.tail, null);
		assertEquals(10, untyped list._poolSize);
		
		for (i in 0...10) list.append(i);
		for (i in 0...10) list.removeHead();
		assertEquals(10, untyped list._poolSize);
		for (i in 0...10) list.append(i);
		assertEquals(0, untyped list._poolSize);
	}
	
	function testAppend()
	{
		var list = new SLL<Int>();
		assertEquals(list.size(), 0);
		list.append(0);
		assertEquals(1, list.size());
		assertEquals(list.head, list.tail);
		
		for (i in 1...10) list.append(i);
		
		var i = 0;
		var walker:SLLNode<Int> = list.head;
		while (walker != null)
		{
			assertEquals(walker.val, i++);
			walker = walker.next;
		}
		
		assertEquals(list.head.val, 0);
		assertEquals(list.tail.val, 9);
	}
	
	function testPrepend()
	{
		var list = new SLL<Int>();
		assertEquals(list.size(), 0);
		for (i in 0...10) list.prepend(i);
		var i = 10;
		var walker:SLLNode<Int> = list.head;
		while (walker != null)
		{
			assertEquals(walker.val, --i);
			walker = walker.next;
		}
		assertEquals(list.head.val, 9);
		assertEquals(list.tail.val, 0);
	}
	
	function testUnlink()
	{
		var list = new SLL<Int>();
		
		assertEquals(list.size(), 0);
		for (i in 0...10) list.append(i);
		
		var i = 10;
		var walker:SLLNode<Int> = list.head;
		while (walker != null)
		{
			var hook:SLLNode<Int> = walker.next;
			list.unlink(walker);
			assertEquals(list.size(), --i);
			walker = hook;
		}
		
		assertEquals(list.size(), 0);
		assertEquals(list.head, null);
		assertEquals(list.tail, null);
	}
	
	function testPop()
	{
		var list = new SLL<Int>();
		assertEquals(list.size(), 0);
		for (i in 0...10) list.append(i);
		
		var i = 10;
		while (list.size() > 0)
		{
			var val:Int = list.removeTail();
			assertEquals(val, --i);
		}
		
		assertEquals(list.size(), 0);
		assertEquals(list.head, null);
		assertEquals(list.tail, null);
	}
	
	function testShift()
	{
		var list = new SLL<Int>();
		assertEquals(list.size(), 0);
		for (i in 0...10) list.append(i);
		var i = 0;
		while (list.size() > 0)
		{
			var val:Int = list.removeHead();
			assertEquals(val, i++);
		}
		assertEquals(list.size(), 0);
		assertEquals(list.head, null);
		assertEquals(list.tail, null);
	}
	
	function testShiftUp()
	{
		var list = new SLL<Int>();
		assertEquals(list.size(), 0);
		for (i in 0...10) list.append(i);
		list.shiftUp();
		assertEquals(list.tail.val, 0);
	}
	
	function testPopDown()
	{
		var list = new SLL<Int>();
		assertEquals(list.size(), 0);
		for (i in 0...10) list.append(i);
		list.popDown();
		assertEquals(list.head.val, 9);
	}
}

private class E
{
	public var x:Int;
	
	public function new(x:Int)
	{
		this.x = x;
	}
}

private class ESortable implements de.polygonal.ds.Comparable<ESortable>
{
	public var id:Int;
	public function new(id:Int)
	{
		this.id = id;
	}
	
	public function compare(other:ESortable):Int
	{
		return id - other.id;
	}
	
	public function toString():String
	{
		return 'Node_' + id;
	}
}