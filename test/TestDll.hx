import de.polygonal.ds.Cloneable;
import de.polygonal.ds.Collection;
import de.polygonal.ds.Dll;
import de.polygonal.ds.DllNode;
import de.polygonal.ds.ListSet;
import de.polygonal.ds.Set;
import de.polygonal.ds.tools.Compare;

@:access(de.polygonal.ds.Dll)
class TestDll extends AbstractTest
{
	function testSource()
	{
		var a = new Dll<Int>([0, 1, 2, 3]);
		assertEquals(4, a.size);
		
		assertEquals(0, a.head.val);
		assertEquals(1, a.head.next.val);
		assertEquals(2, a.head.next.next.val); 
		assertEquals(3, a.tail.val);
		assertEquals(a.head, a.head.next.prev);
		assertEquals(a.head.next, a.head.next.next.prev);
		assertEquals(a.head.next.next, a.head.next.next.next.prev);
		assertEquals(null, a.head.prev);
		assertEquals(null, a.tail.next);
		assertEquals(a.tail, a.head.next.next.next);
	}
	
	function testPool()
	{
		var l = new Dll<Int>(20);
		
		for (i in 0...10) l.append(i);
		for (i in 0...10) l.removeHead();
		assertEquals(10, l.mPoolSize);
		
		for (i in 0...10) l.append(i);
		assertEquals(0, l.mPoolSize);
		
		for (i in 0...10) l.removeTail();
		assertEquals(10, l.mPoolSize);
		
		for (i in 0...10) l.prepend(i);
		assertEquals(0, l.mPoolSize);
		
		assertEquals(10, l.size);
		assertTrue(l.head != null);
		
		for (i in 0...10)
			l.head.unlink();
		
		assertEquals(10, l.mPoolSize);
		assertEquals(0, l.size);
		assertTrue(l.head == null);
	}
	
	function testJoin()
	{
		var list = new Dll<Int>();
		for (i in 0...10) list.append(i);
		assertEquals(list.join(""), "0123456789");
	}
	
	function testForEach()
	{
		var list = new Dll<Int>();
		for (i in 0...3) list.append(i);
		
		var j = 0;
		list.forEach(
			function(v, i)
			{
				assertEquals(j++, i);
				assertEquals(i, v);
				return v;
			});
	}
	
	function testIter()
	{
		var list = new Dll<Int>();
		for (i in 0...3) list.append(i);
		var i = 0;
		list.iter(function(e) assertEquals(i++, e));
	}
	
	function testShuffle()
	{
		var list = new Dll<Int>();
		for (i in 0...10) list.append(i);
		list.shuffle(null);
		var s:Set<Int> = new ListSet<Int>();
		for (i in list) assertTrue(s.set(i));
		assertEquals(10, s.size);
	}
	
	function testGetNodeAt()
	{
		var list = new Dll<Int>();
		for (i in 0...10) list.append(i);
		assertEquals(list.getNodeAt(0).val, 0);
		assertEquals(list.getNodeAt(9).val, 9);
	}
	
	function testInsertAfter()
	{
		var list = new Dll<Int>();
		list.append(0);
		
		list.insertAfter(list.head, 1);
		assertEquals(2, list.size);
		assertEquals(0, list.head.val);
		assertEquals(1, list.head.next.val);
		assertEquals(list.tail.next, null);
		assertEquals(list.tail.prev, list.head);
		assertEquals(list.head.prev, null);
		assertEquals(list.head.next, list.tail);
	}
	
	function testIndexOf()
	{
		var list = new Dll<Int>();
		assertEquals(-1, list.indexOf(0));
		for (i in 0...3) list.append(i);
		assertEquals(0, list.indexOf(0));
		assertEquals(1, list.indexOf(1));
		assertEquals(2, list.indexOf(2));
		assertEquals(-1, list.indexOf(4));
	}
	
	function testRemoveAt()
	{
		var list = new Dll<Int>([0, 1, 2]);
		for (i in 0...3)
		{
			assertEquals(i, list.removeAt(0));
			assertEquals(3 - i - 1, list.size);
		}
		assertEquals(0, list.size);
		
		for (i in 0...3) list.append(i);
		
		var size = 3;
		while (list.size > 0)
		{
			list.removeAt(list.size - 1);
			size--;
			assertEquals(size, list.size);
		}
		
		assertEquals(0, list.size);
	}
	
	function testInsert()
	{
		var list = new Dll<Int>();
		list.insert(0, 1);
		assertEquals(1, list.size);
		assertEquals(1, list.get(0));
		
		var list = new Dll<Int>([0, 1, 2]);
		assertEquals(3, list.size);
		list.insert(0, 5);
		assertEquals(4, list.size);
		assertEquals(5, list.get(0));
		assertEquals(0, list.get(1));
		assertEquals(1, list.get(2));
		assertEquals(2, list.get(3));
		
		var list = new Dll<Int>([0, 1, 2]);
		assertEquals(3, list.size);
		
		list.insert(1, 5);
		assertEquals(4, list.size);
		
		assertEquals(0, list.get(0));
		assertEquals(5, list.get(1));
		assertEquals(1, list.get(2));
		assertEquals(2, list.get(3));
		
		var list = new Dll<Int>([0, 1, 2]);
		assertEquals(3, list.size);
		
		list.insert(2, 5);
		assertEquals(4, list.size);
		
		assertEquals(0, list.get(0));
		assertEquals(1, list.get(1));
		assertEquals(5, list.get(2));
		assertEquals(2, list.get(3));
		
		var list = new Dll<Int>([0, 1, 2]);
		assertEquals(3, list.size);
		list.insert(3, 5);
		assertEquals(4, list.size);
		assertEquals(0, list.get(0));
		assertEquals(1, list.get(1));
		assertEquals(2, list.get(2));
		assertEquals(5, list.get(3));
		
		var list = new Dll<Int>();
		list.insert(0, 0);
		list.insert(1, 1);
		assertEquals(0, list.get(0));
		assertEquals(1, list.get(1));
		
		var s = 20;
		for (i in 0...s)
		{
			var list = new Dll<Int>(s);
			for (i in 0...s) list.append(i);
			
			list.insert(i, 100);
			for (j in 0...i) assertEquals(j, list.get(j));
			assertEquals(100, list.get(i));
			var v = i;
			for (j in i + 1...s + 1) assertEquals(v++, list.get(j));
		}
	}
	
	function testInsertBefore()
	{
		var list = new Dll<Int>();
		list.append(1);
		list.append(2);
		list.insertBefore(list.tail, 0);
		assertEquals(3, list.size);
		assertEquals(0, list.head.next.val);
		list.clear();
		assertEquals(list.size, 0);
	}
	
	function testReverse()
	{
		for (i in 1...10)
		{
			var list = new Dll<Int>();
			for (j in 0...i) list.append(j);
			var k = i;
			list.reverse();
			for (e in list) assertEquals(e, --k);
		}
	}
	
	function testNodeOf()
	{
		var list = new Dll<Int>();
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
		var list1 = new Dll<Int>();
		var data:Array<Int> = [0, 1, 2, 3, 4];
		for (i in 0...data.length) list1.append(data[i]);
		
		var list2 = new Dll<Int>();
		var data:Array<Int> = [5, 6, 7, 8, 9];
		for (i in 0...data.length) list2.append(data[i]);
		
		list1.merge(list2);
		
		var c:Int = 0;
		assertEquals(10, list1.size);
		for (i in list1) assertEquals(c++, i);
	}
	
	function testConcat()
	{
		var list1 = new Dll<Int>();
		var data:Array<Int> = [0, 1, 2, 3, 4];
		for (i in 0...data.length) list1.append(data[i]);
		
		var list2 = new Dll<Int>();
		var data:Array<Int> = [5, 6, 7, 8, 9];
		for (i in 0...data.length) list2.append(data[i]);
		
		var list3 = new Dll<Int>();
		list3 = list3.concat(list1);
		list3 = list3.concat(list2);
		
		var c:Int = 0;
		assertEquals(10, list3.size);
		for (i in list1) assertEquals(c++, i);
	}
	
	function testLastNodeOf()
	{
		var list = new Dll<Int>();
		var data:Array<Int> = [2, 3, 4, 9, 5, 1, 7, 6, 8, 0];
		for (i in 0...10) list.append(data[i]);
		
		var node = list.lastNodeOf(8, list.tail);
		assertTrue(node != null);
		assertEquals(8, node.val);
		
		var node = list.lastNodeOf(5, list.tail.prev.prev);
		assertTrue(node != null);
		assertEquals(5, node.val);
		
		var list = new Dll<Int>();
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
		var list = new Dll<Int>();
		list.append(1);
		list.append(2);
		list.sort(Compare.cmpFloatRise, true);
		
		var c = 1; for (i in list) assertEquals(c++, i);
		assertEquals(2, list.tail.val);
		assertEquals(1, list.tail.prev.val);
		assertFalse(list.head.hasPrev());
		assertFalse(list.tail.hasNext());
		
		var list = new Dll<Int>();
		list.append(2);
		list.append(1);
		list.sort(Compare.cmpFloatRise, true);
		
		var c = 1; for (i in list) assertEquals(c++, i);
		assertEquals(2, list.tail.val);
		assertEquals(1, list.tail.prev.val);
		assertFalse(list.head.hasPrev());
		assertFalse(list.tail.hasNext());
		
		var list = new Dll<Int>();
		list.append(1);
		list.append(2);
		list.append(3);
		list.sort(Compare.cmpFloatRise, true);
		
		var c = 1; for (i in list) assertEquals(c++, i);
		
		assertEquals(3, list.tail.val);
		assertEquals(2, list.tail.prev.val);
		assertEquals(1, list.head.val);
		assertFalse(list.head.hasPrev());
		assertFalse(list.tail.hasNext());
		
		var list = new Dll<Int>();
		list.append(3);
		list.append(2);
		list.append(1);
		list.sort(Compare.cmpFloatRise, true);
		
		var c = 1; for (i in list) assertEquals(c++, i);
		
		assertEquals(3, list.tail.val);
		assertEquals(2, list.tail.prev.val);
		assertEquals(1, list.head.val);
		assertFalse(list.head.hasPrev());
		assertFalse(list.tail.hasNext());
		
		var list = new Dll<Int>();
		list.append(3);
		list.append(1);
		list.append(2);
		list.sort(Compare.cmpFloatRise, true);
		
		var c = 1; for (i in list) assertEquals(c++, i);
		
		assertEquals(3, list.tail.val);
		assertEquals(2, list.tail.prev.val);
		assertEquals(1, list.head.val);
		assertFalse(list.head.hasPrev());
		assertFalse(list.tail.hasNext());
		
		var list = new Dll<Int>();
		list.append(4);
		list.append(3);
		list.append(2);
		list.append(1);
		
		list.sort(Compare.cmpFloatRise, true);
		
		var c = 1; for (i in list) assertEquals(c++, i);
		assertEquals(4, list.tail.val);
		assertEquals(3, list.tail.prev.val);
		assertFalse(list.head.hasPrev());
		assertFalse(list.tail.hasNext());
	}
	
	function testSortTail()
	{
		//insertion sort
		var list = new Dll<Int>();
		
		list.append(1);
		list.append(3);
		list.append(2);
		
		list.sort(Compare.cmpFloatRise, true);
		
		var c = 1; for (i in list) assertEquals(c++, i);
		assertFalse(list.head.hasPrev());
		assertFalse(list.tail.hasNext());
		
		list.sort(Compare.cmpFloatFall, true);
		
		var c = 3; for (i in list) assertEquals(c--, i);
		assertFalse(list.head.hasPrev());
		assertFalse(list.tail.hasNext());
		
		list.clear();
		list.append(3);
		list.append(2);
		list.append(1);
		list.sort(Compare.cmpFloatRise, true);
		var c = 1; for (i in list) assertEquals(c++, i);
		assertFalse(list.head.hasPrev());
		assertFalse(list.tail.hasNext());
		list.sort(Compare.cmpFloatFall, true);
		var c = 3; for (i in list) assertEquals(c--, i);
		assertFalse(list.head.hasPrev());
		assertFalse(list.tail.hasNext());
		
		//merge sort
		var list = new Dll<Int>();
		
		list.append(1);
		list.append(3);
		list.append(2);
		
		list.sort(Compare.cmpFloatRise, false);
		
		var c = 1; for (i in list) assertEquals(c++, i);
		assertFalse(list.head.hasPrev());
		assertFalse(list.tail.hasNext());
		
		list.sort(Compare.cmpFloatFall);
		
		var c = 3; for (i in list) assertEquals(c--, i);
		assertFalse(list.head.hasPrev());
		assertFalse(list.tail.hasNext());
		
		list.clear();
		list.append(3);
		list.append(2);
		list.append(1);
		list.sort(Compare.cmpFloatRise);
		var c = 1; for (i in list) assertEquals(c++, i);
		assertFalse(list.head.hasPrev());
		assertFalse(list.tail.hasNext());
		list.sort(Compare.cmpFloatFall);
		var c = 3; for (i in list) assertEquals(c--, i);
		assertFalse(list.head.hasPrev());
		assertFalse(list.tail.hasNext());
	}
	
	function testSort()
	{
		var list = new Dll<Int>();
		var data:Array<Int> = [2, 3, 4, 9, 5, 1, 7, 6, 8, 0];
		for (i in 0...10) list.append(data[i]);
		list.sort(Compare.cmpFloatRise, false);
		
		var c = 10;
		var node = list.tail;
		while (node != null)
		{
			c--;
			assertEquals(node.val, c);
			node = node.prev;
		}
		assertEquals(0, c);
		
		var list = new Dll<EComparable>();
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
		
		var list = new Dll<Int>();
		
		var data:Array<Int> = [2, 3, 4, 9, 5, 1, 7, 6, 8, 0];
		for (i in 0...10) list.append(data[i]);
		
		list.sort(Compare.cmpFloatRise, false);
		var c:Int = 0;
		for (i in list) assertEquals(c++, i);
		assertFalse(list.head.hasPrev());
		assertFalse(list.tail.hasNext());
		
		list.sort(Compare.cmpFloatFall, false);
		var c:Int = 10;
		for (i in list) assertEquals(--c, i);
		assertFalse(list.head.hasPrev());
		assertFalse(list.tail.hasNext());
		
		list.sort(Compare.cmpFloatRise, true);
		var c:Int = 0;
		for (i in list) assertEquals(c++, i);
		assertFalse(list.head.hasPrev());
		assertFalse(list.tail.hasNext());
		
		list.sort(Compare.cmpFloatFall, true);
		var c:Int = 10;
		for (i in list) assertEquals(--c, i);
		assertFalse(list.head.hasPrev());
		assertFalse(list.tail.hasNext());
		
		var list:Dll<EComparable> = new Dll<EComparable>();
		var data:Array<Int> = [2, 3, 4, 9, 5, 1, 7, 6, 8, 0];
		for (i in 0...10) list.append(new EComparable(data[i]));
		
		list.sort(null, false);
		
		var c:Int = 10;
		for (i in list) assertEquals(--c, i.id);
		assertFalse(list.head.hasPrev());
		assertFalse(list.tail.hasNext());
		
		var list:Dll<EComparable> = new Dll<EComparable>();
		var data:Array<Int> = [2, 3, 4, 9, 5, 1, 7, 6, 8, 0];
		for (i in 0...10) list.append(new EComparable(data[i]));
		
		list.sort(null, true);
		var c:Int = 10;
		for (i in list) assertEquals(--c, i.id);
		assertFalse(list.head.hasPrev());
		assertFalse(list.tail.hasNext());
		
		var list:Dll<EComparable> = new Dll<EComparable>();
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
		var list = new Dll<Int>();
		for (i in 0...10) list.append(i);
		var j:Int = 0;
		for (i in list) assertEquals(i, j++);
		assertEquals(10, j);
		
		var itr = list.iterator();
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
			var list = new Dll<Int>();
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
			assertEquals(null, list.head);
			assertEquals(null, list.tail);
		}
		
		for (i in 0...5)
		{
			var list = new Dll<Int>();
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
			assertEquals(null, list.head);
			assertEquals(null, list.tail);
		}
	}
	
	function testContains()
	{
		var list = new Dll<Int>();
		for (i in 0...10) list.append(i);
		for (i in 0...10) assertTrue(list.contains(i));
	}
	
	function testClone0()
	{
		var list = new Dll<Int>();
		var copy:Dll<Int> = cast list.clone(true);
		assertEquals(0, copy.size);
		assertEquals(null, copy.head);
		assertEquals(null, copy.tail);
		var list = new Dll<Int>();
		list.close();
		var copy:Dll<Int> = cast list.clone(true);
		assertEquals(0, copy.size);
		assertEquals(null, copy.head);
		assertEquals(null, copy.tail);
	}
	
	function testClone1()
	{
		var list = new Dll<Int>();
		list.append(0);
		var copy:Dll<Int> = cast list.clone(true);
		assertEquals(1, copy.size);
		assertEquals(0, copy.head.val);
		assertEquals(0, copy.tail.val);
		
		var list = new Dll<Int>();
		list.close();
		list.append(0);
		var copy:Dll<Int> = cast list.clone(true);
		assertEquals(1, copy.size);
		assertEquals(0, copy.head.val);
		assertEquals(0, copy.tail.val);
		assertEquals(copy.head, copy.tail.next);
	}
	
	function testClone2()
	{
		var list = new Dll<Int>();
		list.append(0);
		list.append(1);
		var copy:Dll<Int> = cast list.clone(true);
		assertEquals(2, copy.size);
		assertEquals(0, copy.head.val);
		assertEquals(1, copy.tail.val);
		assertEquals(0, copy.tail.prev.val);
		
		var list = new Dll<Int>();
		list.close();
		list.append(0);
		list.append(1);
		var copy:Dll<Int> = cast list.clone(true);
		assertEquals(2, copy.size);
		assertEquals(0, copy.head.val);
		assertEquals(1, copy.tail.val);
		assertEquals(0, copy.tail.prev.val);
		assertEquals(copy.head, copy.tail.next);
	}
	
	function testClone3()
	{
		var list = new Dll<Int>();
		for (i in 0...10) list.append(i);
		
		var copy:Dll<Int> = cast list.clone(true);
		var j = 0;
		for (i in copy) assertEquals(i, j++);
		
		var i = 0;
		var node = copy.head;
		
		while (node != null)
		{
			assertEquals(i, node.val);
			
			if (i == 0)
			{
				if (copy.size > 1)
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
	
	function testClone4()
	{
		var list = new Dll<E>();
		for (i in 0...3) list.append(new E(i));
		
		var copy:Dll<E> = cast list.clone(false);
		var j = 0;
		for (i in copy) assertEquals(j++, i.x);
	}
	
	function testArray()
	{
		var list = new Dll<Int>();
		for (i in 0...10) list.append(i);
		var a:Array<Int> = list.toArray();
		for (i in a) assertEquals(a[i], i);
	}
	
	function testClear()
	{
		var list = new Dll<Int>();
		for (i in 0...10) list.append(i);
		list.clear();
		assertEquals(list.size, 0);
		assertEquals(list.head, null);
		assertEquals(list.tail, null);
		
		var list = new Dll<Int>(10);
		for (i in 0...10) list.append(i);
		for (i in 0...10) list.removeHead();
		for (i in 0...10) list.append(i);
		
		list.clear(true);
		assertEquals(list.size, 0);
		assertEquals(list.head, null);
		assertEquals(list.tail, null);
		assertEquals(10, list.mPoolSize);
		
		for (i in 0...10) list.append(i);
		for (i in 0...10) list.removeHead();
		assertEquals(10, list.mPoolSize);
		for (i in 0...10) list.append(i);
		assertEquals(0, list.mPoolSize);
	}
	
	function testAppend()
	{
		var list = new Dll<Int>();
		
		assertEquals(list.size, 0);
		
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
		
		var list = new Dll<Int>();
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
		var list = new Dll<Int>();
		assertEquals(list.size, 0);
		
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
		var list = new Dll<Int>();
		
		assertEquals(list.size, 0);
		
		for (i in 0...10)
			list.append(i);
		
		var i = 10;
		var walker = list.head;
		while (walker != null)
		{
			var hook = walker.next;
			list.unlink(walker);
			assertEquals(list.size, --i);
			walker = hook;
		}
		
		assertEquals(list.size, 0);
		assertEquals(list.head, null);
		assertEquals(list.tail, null);
		
		var list = new Dll<Int>();
		assertEquals(list.size, 0);
		for (i in 0...10) list.append(0);
		assertEquals(true, list.remove(0));
		assertTrue(list.isEmpty());
	}
	
	function testPop()
	{
		var list = new Dll<Int>();
		assertEquals(list.size, 0);
		
		for (i in 0...10) list.append(i);
		
		var i:Int = 10;
		while (list.size > 0)
		{
			var val:Int = list.removeTail();
			assertEquals(val, --i);
		}
		
		assertEquals(list.size, 0);
		assertEquals(list.head, null);
		assertEquals(list.tail, null);
	}
	
	function testShift()
	{
		var list = new Dll<Int>();
		
		assertEquals(list.size, 0);
		for (i in 0...10) list.append(i);
			
		var i:Int = 0;
		while (list.size > 0)
		{
			var val:Int = list.removeHead();
			assertEquals(val, i++);
		}
		
		assertEquals(list.size, 0);
		assertEquals(list.head, null);
		assertEquals(list.tail, null);
	}
	
	function testShiftUp()
	{
		var list = new Dll<Int>();
		assertEquals(list.size, 0);
		for (i in 0...10) list.append(i);
		list.headToTail();
		assertEquals(list.tail.val, 0);
	}
	
	function testPopDown()
	{
		var list = new Dll<Int>();
		assertEquals(list.size, 0);
		for (i in 0...10) list.append(i);
		list.tailToHead();
		assertEquals(list.head.val, 9);
	}
	
	function testPrependUnmanaged()
	{
		var a = new DllNode<Int>(0, null);
		var b = new DllNode<Int>(1, null);
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
		var a = new DllNode<Int>(0, null);
		var b = new DllNode<Int>(1, null);
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
		var a = new DllNode<Int>(0, null);
		var b = new DllNode<Int>(1, null);
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
		var a = new DllNode<Int>(0, null);
		var b = new DllNode<Int>(1, null);
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
		var c:de.polygonal.ds.Collection<Int> = cast new Dll<Int>();
		assertEquals(true, c != null);
	}
	
	function testRange()
	{
		var a = new Dll<Int>([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
		
		var b = cast a.getRange(0, 5);
		for (i in 0...5)
		{
			assertEquals(i, b.get(i));
		}
		
		var b:Dll<Int> = cast a.getRange(0, 5);
		
		var i = 0;
		var m = b.head;
		while (m != null)
		{
			i++;
			m = m.next;
		}
		
		assertEquals(5, i);
		assertEquals(5, b.size);
		for (i in 0...5) assertEquals(i, b.get(i));
		
		var b:Dll<Int> = cast a.getRange(0, -5);
		var i = 0;
		var m = b.head;
		while (m != null)
		{
			i++;
			m = m.next;
		}
		assertEquals(5, i);
		assertEquals(5, b.size);
		for (i in 0...5) assertEquals(i, b.get(i));
		
		var b:Dll<Int> = cast a.getRange(1, 1);
		var i = 0;
		var m = b.head;
		while (m != null)
		{
			i++;
			m = m.next;
		}
		assertEquals(0, i);
		assertEquals(0, b.size);
		
		var b:Dll<Int> = cast a.getRange(8, -1);
		var i = 0;
		var m = b.head;
		while (m != null)
		{
			i++;
			m = m.next;
		}
		assertEquals(1, i);
		assertEquals(1, b.size);
		assertEquals(8, b.get(0));
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
		return "" + id;
	}
}

private class E implements Cloneable<E>
{
	public var x:Int;
	public function new(x:Int)
	{
		this.x = x;
	}
	
	public function clone():E
	{
		return new E(x);
	}
}