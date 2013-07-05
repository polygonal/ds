package;

import de.polygonal.ds.Compare;
import de.polygonal.ds.DLL;
import de.polygonal.ds.DLLNode;
import de.polygonal.ds.ListSet;

class TestDLL extends haxe.unit.TestCase
{
	function testPool()
	{
		var l = new DLL<Int>(20);
		
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
	
	function testJoin()
	{
		var list = new DLL<Int>();
		for (i in 0...10) list.append(i);
		assertEquals(list.join(''), '0123456789');
	}
	
	#if debug
	function testMaxSize()
	{
		var list = new DLL<Int>(3, 3);
		list.append(0);
		list.append(1);
		list.append(2);
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
		
		var list = new DLL<Int>(3, 3);
		list.append(0);
		list.append(1);
		list.append(2);
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
		
		var list = new DLL<Int>(3, 3);
		list.append(0);
		list.append(1);
		list.append(2);
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
		
		var list = new DLL<Int>(3, 3);
		list.append(0);
		list.append(1);
		list.append(2);
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
		
		var list1 = new DLL<Int>(3, 3);
		list1.append(0);
		list1.append(1);
		list1.append(2);
		var list2 = new DLL<Int>(3, 3);
		list2.append(0);
		list2.append(1);
		list2.append(2);
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
		
		var list = new DLL<Int>(3, 3);
		list.append(0);
		list.append(1);
		list.append(2);
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
		var list = new DLL<Int>();
		for (i in 0...10) list.append(i);
		
		list.fill(0);
		
		var n = list.head;
		for (i in 0...10)
		{
			assertEquals(0, n.val);
			n = n.next;
		}
		
		var list = new DLL<Int>();
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
	}
	
	function testAssign()
	{
		var list = new DLL<E>();
		for (i in 0...10) list.append(null);
		
		list.assign(E, [0]);
		
		var n = list.head;
		for (i in 0...10)
		{
			assertEquals(E, cast Type.getClass(n.val));
			n = n.next;
		}
		
		var list = new DLL<E>();
		for (i in 0...10) list.append(null);
		
		list.assign(E, [0], 5);
		
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
		
		var list = new DLL<E>();
		for (i in 0...10) list.append(null);
		
		list.assign(E, [5], 10);
		
		var n = list.head;
		for (i in 0...10)
		{
			assertEquals(5, n.val.x);
			n = n.next;
		}
	}
	
	function testShuffle()
	{
		var list = new DLL<Int>();
		for (i in 0...10) list.append(i);
		
		list.shuffle(null);
		
		var s:de.polygonal.ds.Set<Int> = new ListSet<Int>();
		
		for (i in list)
		{
			assertTrue(s.set(i));
		}
		
		assertEquals(10, s.size());
	}
	
	function testGetNodeAt()
	{
		var list = new DLL<Int>();
		for (i in 0...10) list.append(i);
		assertEquals(list.getNodeAt(0).val, 0);
		assertEquals(list.getNodeAt(9).val, 9);
	}
	
	function testInsertAfter()
	{
		var list = new DLL<Int>();
		list.append(0);
		
		var newNode = list.insertAfter(list.head, 1);
		assertEquals(2, list.size());
		assertEquals(0, list.head.val);
		assertEquals(1, list.head.next.val);
		assertEquals(list.tail.next, null);
		assertEquals(list.tail.prev, list.head);
		assertEquals(list.head.prev, null);
		assertEquals(list.head.next, list.tail);
		
		list.insertAfter(newNode, 2);
	}
	
	function testInsertBefore()
	{
		var list = new DLL<Int>();
		list.append(1);
		list.append(2);
		list.insertBefore(list.tail, 0);
		assertEquals(3, list.size());
		assertEquals(0, list.head.next.val);
		list.clear();
		assertEquals(list.size(), 0);
	}
	
	function testReverse()
	{
		for (i in 1...10)
		{
			var list = new DLL<Int>();
			for (j in 0...i) list.append(j);
			var k = i;
			list.reverse();
			for (e in list) assertEquals(e, --k);
		}
	}
	
	function testNodeOf()
	{
		var list = new DLL<Int>();
		var data:Array<Int> = [2, 3, 4, 9, 5, 1, 7, 6, 8, 0];
		for (i in 0...10) list.append(data[i]);
		
		var node = list.nodeOf(3, list.head);
		
		assertTrue(node != null);
		assertEquals(3, node.val);
		
		var node = list.nodeOf(5, list.head.next.next);
		assertTrue(node != null);
		assertEquals(5, node.val);
	}
	
	function testMerge()
	{
		var list1 = new DLL<Int>();
		var data:Array<Int> = [0, 1, 2, 3, 4];
		for (i in 0...data.length) list1.append(data[i]);
		
		var list2 = new DLL<Int>();
		var data:Array<Int> = [5, 6, 7, 8, 9];
		for (i in 0...data.length) list2.append(data[i]);
		
		list1.merge(list2);
		
		var c:Int = 0;
		assertEquals(10, list1.size());
		for (i in list1) assertEquals(c++, i);
	}
	
	function testConcat()
	{
		var list1 = new DLL<Int>();
		var data:Array<Int> = [0, 1, 2, 3, 4];
		for (i in 0...data.length) list1.append(data[i]);
		
		var list2 = new DLL<Int>();
		var data:Array<Int> = [5, 6, 7, 8, 9];
		for (i in 0...data.length) list2.append(data[i]);
		
		var list3 = new DLL<Int>();
		list3 = list3.concat(list1);
		list3 = list3.concat(list2);
		
		var c:Int = 0;
		assertEquals(10, list3.size());
		for (i in list1) assertEquals(c++, i);
	}
	
	function testLastNodeOf()
	{
		var list = new DLL<Int>();
		var data:Array<Int> = [2, 3, 4, 9, 5, 1, 7, 6, 8, 0];
		for (i in 0...10) list.append(data[i]);
		
		var node = list.lastNodeOf(8, list.tail);
		assertTrue(node != null);
		assertEquals(8, node.val);
		
		var node = list.lastNodeOf(5, list.tail.prev.prev);
		assertTrue(node != null);
		assertEquals(5, node.val);
		
		var list = new DLL<Int>();
		list.append(0);
		list.append(1);
		list.append(2);
		list.append(3);
		list.close();
		
		var node = list.lastNodeOf(1, list.getNodeAt(2));
		assertEquals(1, node.val);
		
		var node = list.lastNodeOf(123, list.getNodeAt(2));
		assertEquals(null, node);
	}
	
	function testInsertionSort()
	{
		var list = new DLL<Int>();
		list.append(1);
		list.append(2);
		list.sort(Compare.compareNumberRise, true);
		
		var c = 1; for (i in list) assertEquals(c++, i);
		assertEquals(2, list.tail.val);
		assertEquals(1, list.tail.prev.val);
		assertFalse(list.head.hasPrev());
		assertFalse(list.tail.hasNext());
		
		var list = new DLL<Int>();
		list.append(2);
		list.append(1);
		list.sort(Compare.compareNumberRise, true);
		
		var c = 1; for (i in list) assertEquals(c++, i);
		assertEquals(2, list.tail.val);
		assertEquals(1, list.tail.prev.val);
		assertFalse(list.head.hasPrev());
		assertFalse(list.tail.hasNext());
		
		var list = new DLL<Int>();
		list.append(1);
		list.append(2);
		list.append(3);
		list.sort(Compare.compareNumberRise, true);
		
		var c = 1; for (i in list) assertEquals(c++, i);
		
		assertEquals(3, list.tail.val);
		assertEquals(2, list.tail.prev.val);
		assertEquals(1, list.head.val);
		assertFalse(list.head.hasPrev());
		assertFalse(list.tail.hasNext());
		
		var list = new DLL<Int>();
		list.append(3);
		list.append(2);
		list.append(1);
		list.sort(Compare.compareNumberRise, true);
		
		var c = 1; for (i in list) assertEquals(c++, i);
		
		assertEquals(3, list.tail.val);
		assertEquals(2, list.tail.prev.val);
		assertEquals(1, list.head.val);
		assertFalse(list.head.hasPrev());
		assertFalse(list.tail.hasNext());
		
		var list = new DLL<Int>();
		list.append(3);
		list.append(1);
		list.append(2);
		list.sort(Compare.compareNumberRise, true);
		
		var c = 1; for (i in list) assertEquals(c++, i);
		
		assertEquals(3, list.tail.val);
		assertEquals(2, list.tail.prev.val);
		assertEquals(1, list.head.val);
		assertFalse(list.head.hasPrev());
		assertFalse(list.tail.hasNext());
		
		var list = new DLL<Int>();
		list.append(4);
		list.append(3);
		list.append(2);
		list.append(1);
		
		list.sort(Compare.compareNumberRise, true);
		
		var c = 1; for (i in list) assertEquals(c++, i);
		assertEquals(4, list.tail.val);
		assertEquals(3, list.tail.prev.val);
		assertFalse(list.head.hasPrev());
		assertFalse(list.tail.hasNext());
	}
	
	function testSortTail()
	{
		//insertion sort
		var list = new DLL<Int>();
		
		list.append(1);
		list.append(3);
		list.append(2);
		
		list.sort(Compare.compareNumberRise, true);
		
		var c = 1; for (i in list) assertEquals(c++, i);
		assertFalse(list.head.hasPrev());
		assertFalse(list.tail.hasNext());
		
		list.sort(Compare.compareNumberFall, true);
		
		var c = 3; for (i in list) assertEquals(c--, i);
		assertFalse(list.head.hasPrev());
		assertFalse(list.tail.hasNext());
		
		list.clear();
		list.append(3);
		list.append(2);
		list.append(1);
		list.sort(Compare.compareNumberRise, true);
		var c = 1; for (i in list) assertEquals(c++, i);
		assertFalse(list.head.hasPrev());
		assertFalse(list.tail.hasNext());
		list.sort(Compare.compareNumberFall, true);
		var c = 3; for (i in list) assertEquals(c--, i);
		assertFalse(list.head.hasPrev());
		assertFalse(list.tail.hasNext());
		
		//merge sort
		var list = new DLL<Int>();
		
		list.append(1);
		list.append(3);
		list.append(2);
		
		list.sort(Compare.compareNumberRise, false);
		
		var c = 1; for (i in list) assertEquals(c++, i);
		assertFalse(list.head.hasPrev());
		assertFalse(list.tail.hasNext());
		
		list.sort(Compare.compareNumberFall);
		
		var c = 3; for (i in list) assertEquals(c--, i);
		assertFalse(list.head.hasPrev());
		assertFalse(list.tail.hasNext());
		
		list.clear();
		list.append(3);
		list.append(2);
		list.append(1);
		list.sort(Compare.compareNumberRise);
		var c = 1; for (i in list) assertEquals(c++, i);
		assertFalse(list.head.hasPrev());
		assertFalse(list.tail.hasNext());
		list.sort(Compare.compareNumberFall);
		var c = 3; for (i in list) assertEquals(c--, i);
		assertFalse(list.head.hasPrev());
		assertFalse(list.tail.hasNext());
	}
	
	function testSort()
	{
		var list = new DLL<Int>();
		var data:Array<Int> = [2, 3, 4, 9, 5, 1, 7, 6, 8, 0];
		for (i in 0...10) list.append(data[i]);
		list.sort(Compare.compareNumberRise, false);
		
		var c = 10;
		var node = list.tail;
		while (node != null)
		{
			c--;
			assertEquals(node.val, c);
			node = node.prev;
		}
		assertEquals(0, c);
		
		var list = new DLL<EComparable>();
		var data:Array<Int> = [2, 3, 4, 9, 5, 1, 7, 6, 8, 0];
		for (i in 0...10) list.append(new EComparable(data[i]));
		list.sort(null, false);
		
		var c = 0;
		var node = list.tail;
		while (node != null)
		{
			assertEquals(node.val.id, c++);
			node = node.prev;
		}
		assertEquals(10, c);
		
		var list = new DLL<Int>();
		
		var data:Array<Int> = [2, 3, 4, 9, 5, 1, 7, 6, 8, 0];
		for (i in 0...10) list.append(data[i]);
		
		list.sort(Compare.compareNumberRise, false);
		var c:Int = 0;
		for (i in list) assertEquals(c++, i);
		assertFalse(list.head.hasPrev());
		assertFalse(list.tail.hasNext());
		
		list.sort(Compare.compareNumberFall, false);
		var c:Int = 10;
		for (i in list) assertEquals(--c, i);
		assertFalse(list.head.hasPrev());
		assertFalse(list.tail.hasNext());
		
		list.sort(Compare.compareNumberRise, true);
		var c:Int = 0;
		for (i in list) assertEquals(c++, i);
		assertFalse(list.head.hasPrev());
		assertFalse(list.tail.hasNext());
		
		list.sort(Compare.compareNumberFall, true);
		var c:Int = 10;
		for (i in list) assertEquals(--c, i);
		assertFalse(list.head.hasPrev());
		assertFalse(list.tail.hasNext());
		
		var list:DLL<EComparable> = new DLL<EComparable>();
		var data:Array<Int> = [2, 3, 4, 9, 5, 1, 7, 6, 8, 0];
		for (i in 0...10) list.append(new EComparable(data[i]));
		
		list.sort(null, false);
		
		var c:Int = 10;
		for (i in list) assertEquals(--c, i.id);
		assertFalse(list.head.hasPrev());
		assertFalse(list.tail.hasNext());
		
		var list:DLL<EComparable> = new DLL<EComparable>();
		var data:Array<Int> = [2, 3, 4, 9, 5, 1, 7, 6, 8, 0];
		for (i in 0...10) list.append(new EComparable(data[i]));
		
		list.sort(null, true);
		var c:Int = 10;
		for (i in list) assertEquals(--c, i.id);
		assertFalse(list.head.hasPrev());
		assertFalse(list.tail.hasNext());
		
		var list:DLL<EComparable> = new DLL<EComparable>();
		var data:Array<Int> = [2, 3, 4, 9, 5, 1, 7, 6, 8, 0];
		for (i in 0...10) list.append(new EComparable(data[i]));
		
		var ff = function(a:EComparable, b:EComparable):Int
		{
			return b.id - a.id;
		}
		
		list.sort(ff, true);
		
		var c:Int = 10;
		for (i in list) assertEquals(--c, i.id);
		assertFalse(list.head.hasPrev());
		assertFalse(list.tail.hasNext());
	}
	
	function testIterator()
	{
		var list = new DLL<Int>();
		for (i in 0...10) list.append(i);
		var j:Int = 0;
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
			var list = new DLL<Int>();
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
			{
				assertTrue(set.remove(list.removeHead()));
			}
			assertTrue(set.isEmpty());
			assertEquals(null, untyped list.head);
			assertEquals(null, untyped list.tail);
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
			var itr = list.iterator();
			while (itr.hasNext())
			{
				var value = itr.next();
				itr.remove();
				set.remove(value);
			}
			assertTrue(list.isEmpty());
			assertTrue(set.isEmpty());
			assertEquals(null, untyped list.head);
			assertEquals(null, untyped list.tail);
		}
	}
	
	function testContains()
	{
		var list = new DLL<Int>();
		for (i in 0...10) list.append(i);
		for (i in 0...10) assertTrue(list.contains(i));
	}
	
	function testClone0()
	{
		var list = new DLL<Int>();
		var copy = cast list.clone(true);
		assertEquals(0, copy.size());
		assertEquals(null, copy.head);
		assertEquals(null, copy.tail);
		
		var list = new DLL<Int>();
		list.close();
		var copy = cast list.clone(true);
		assertEquals(0, copy.size());
		assertEquals(null, copy.head);
		assertEquals(null, copy.tail);
	}
	
	function testClone1()
	{
		var list = new DLL<Int>();
		list.append(0);
		var copy:DLL<Int> = cast list.clone(true);
		assertEquals(1, copy.size());
		assertEquals(0, copy.head.val);
		assertEquals(0, copy.tail.val);
		
		var list = new DLL<Int>();
		list.close();
		list.append(0);
		var copy:DLL<Int> = cast list.clone(true);
		assertEquals(1, copy.size());
		assertEquals(0, copy.head.val);
		assertEquals(0, copy.tail.val);
		assertEquals(copy.head, copy.tail.next);
	}
	
	function testClone2()
	{
		var list = new DLL<Int>();
		list.append(0);
		list.append(1);
		var copy:DLL<Int> = cast list.clone(true);
		assertEquals(2, copy.size());
		assertEquals(0, copy.head.val);
		assertEquals(1, copy.tail.val);
		assertEquals(0, copy.tail.prev.val);
		
		var list = new DLL<Int>();
		list.close();
		list.append(0);
		list.append(1);
		var copy:DLL<Int> = cast list.clone(true);
		assertEquals(2, copy.size());
		assertEquals(0, copy.head.val);
		assertEquals(1, copy.tail.val);
		assertEquals(0, copy.tail.prev.val);
		assertEquals(copy.head, copy.tail.next);
	}
	
	function testClone3()
	{
		var list = new DLL<Int>();
		for (i in 0...10) list.append(i);
		
		var copy:DLL<Int> = cast list.clone(true);
		var j = 0;
		for (i in copy) assertEquals(i, j++);
		
		var i = 0;
		var node = copy.head;
		
		while (node != null)
		{
			assertEquals(i, node.val);
			
			if (i == 0)
			{
				if (copy.size() > 1)
				{
					assertEquals(i + 1, node.next.val);
					assertEquals(i, node.next.prev.val);
				}
			}
			else
			if (i == 9)
			{
				assertEquals(i - 1, node.prev.val);
				assertEquals(i, node.prev.next.val);
			}
			else
			{
				assertEquals(i + 1, node.next.val);
				assertEquals(i - 1, node.prev.val);
			}
			i++;
			
			node = node.next;
		}
	}
	
	function testArray()
	{
		var list = new DLL<Int>();
		for (i in 0...10) list.append(i);
		var a:Array<Int> = list.toArray();
		for (i in a) assertEquals(a[i], i);
		
		#if flash10
		var list = new DLL<Int>();
		for (i in 0...10) list.append(i);
		var a = list.toVector();
		for (i in a) assertEquals(a[i], i);
		#end
	}
	
	function testClear()
	{
		var list = new DLL<Int>();
		for (i in 0...10) list.append(i);
		list.clear();
		assertEquals(list.size(), 0);
		assertEquals(list.head, null);
		assertEquals(list.tail, null);
		
		var list = new DLL<Int>(10);
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
		var list = new DLL<Int>();
		
		assertEquals(list.size(), 0);
		
		for (i in 0...10)
			list.append(i);
		
		var i:Int = 0;
		var walker = list.head;
		while (walker != null)
		{
			assertEquals(walker.val, i++);
			walker = walker.next;
		}
		
		assertEquals(list.head.val, 0);
		assertEquals(list.tail.val, 9);
		
		var list = new DLL<Int>();
		list.append(0);
		assertEquals(list.head.val, 0);
		assertEquals(list.tail.val, 0);
		assertEquals(null, list.head.next);
		assertEquals(null, list.tail.prev);
		
		list.append(1);
		
		assertEquals(list.head.val, 0);
		assertEquals(list.tail.val, 1);
		assertEquals(1, list.head.next.val);
		assertEquals(0, list.tail.prev.val);
    }
	
	function testPrepend()
	{
		var list = new DLL<Int>();
		assertEquals(list.size(), 0);
		
		for (i in 0...10) list.prepend(i);
		
		var i:Int = 10;
		var walker = list.head;
		while (walker != null)
		{
			assertEquals(walker.val, --i);
			walker = walker.next;
		}
		
		assertEquals(list.head.val, 9);
		assertEquals(list.tail.val, 0);
	}
	
	function testRemove()
	{
		var list = new DLL<Int>();
		
		assertEquals(list.size(), 0);
		
		for (i in 0...10)
			list.append(i);
		
		var i = 10;
		var walker = list.head;
		while (walker != null)
		{
			var hook = walker.next;
			list.unlink(walker);
			assertEquals(list.size(), --i);
			walker = hook;
		}
		
		assertEquals(list.size(), 0);
		assertEquals(list.head, null);
		assertEquals(list.tail, null);
		
		var list = new DLL<Int>();
		assertEquals(list.size(), 0);
		for (i in 0...10) list.append(0);
		assertEquals(true, list.remove(0));
		assertTrue(list.isEmpty());
	}
	
	function testPop()
	{
		var list = new DLL<Int>();
		assertEquals(list.size(), 0);
		
		for (i in 0...10) list.append(i);
		
		var i:Int = 10;
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
		var list = new DLL<Int>();
		
		assertEquals(list.size(), 0);
		for (i in 0...10) list.append(i);
			
		var i:Int = 0;
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
		var list = new DLL<Int>();
		assertEquals(list.size(), 0);
		for (i in 0...10) list.append(i);
		list.shiftUp();
		assertEquals(list.tail.val, 0);
	}
	
	function testPopDown()
	{
		var list = new DLL<Int>();
		assertEquals(list.size(), 0);
		for (i in 0...10) list.append(i);
		list.popDown();
		assertEquals(list.head.val, 9);
	}
	
	function testPrependUnmanaged()
	{
		var a = new DLLNode<Int>(0, null);
		var b = new DLLNode<Int>(1, null);
		var head = b.prepend(a);
		
		assertTrue(a.prev == null);
		assertTrue(a.next == b);
		
		assertTrue(b.prev == a);
		assertTrue(b.next == null);
		
		assertTrue(head.val == 0);
		assertTrue(head.nextVal() == 1);
	}
	
	function testAppendUnmanaged()
	{
		var a = new DLLNode<Int>(0, null);
		var b = new DLLNode<Int>(1, null);
		var tail = a.append(b);
		
		assertTrue(a.prev == null);
		assertTrue(a.next == b);
		
		assertTrue(b.prev == a);
		assertTrue(b.next == null);
		
		assertTrue(tail.next == null);
		assertTrue(tail.val == 1);
		assertTrue(tail.prevVal() == 0);
	}
	
	function testPrependToUnmanaged()
	{
		var a = new DLLNode<Int>(0, null);
		var b = new DLLNode<Int>(1, null);
		var head = a.prependTo(b);
		
		assertTrue(a.prev == null);
		assertTrue(a.next == b);
		
		assertTrue(b.prev == a);
		assertTrue(b.next == null);
		
		assertTrue(head.val == 0);
		assertTrue(head.nextVal() == 1);
	}
	
	function testAppendToUnmanaged()
	{
		var a = new DLLNode<Int>(0, null);
		var b = new DLLNode<Int>(1, null);
		var tail = b.appendTo(a);
		
		assertTrue(a.prev == null);
		assertTrue(a.next == b);
		
		assertTrue(b.prev == a);
		assertTrue(b.next == null);
		
		assertTrue(tail.next == null);
		assertTrue(tail.val == 1);
		assertTrue(tail.prevVal() == 0);
	}
	
	function testCollection()
	{
		var c:de.polygonal.ds.Collection<Int> = cast new DLL<Int>();
		assertEquals(true, true);
	}
}

private class EComparable implements de.polygonal.ds.Comparable<EComparable>
{
	public var id:Int;
	public function new(id:Int)
	{
		this.id = id;
	}
	
	public function compare(other:EComparable):Int
	{
		return id - other.id;
	}
	
	public function toString():String
	{
		return '' + id;
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