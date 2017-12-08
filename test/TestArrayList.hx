import de.polygonal.ds.ArrayList;
import de.polygonal.ds.ListSet;
import de.polygonal.ds.tools.Compare;

import de.polygonal.ds.tools.NativeArrayTools;

@:access(de.polygonal.ds.ArrayList)
class TestArrayList extends AbstractTest
{
	function testBasic()
	{
		var a = new ArrayList<Int>();
		
		for (i in 0...20) a.add(i);
		
		for (i in 0...20) assertEquals(i, a.get(i));
		assertEquals(20, a.size);
		assertTrue(a.capacity >= a.size);
		
		var c = a.mData;
		for (i in 0...NativeArrayTools.size(c))
		{
			if (i < 20)
				assertEquals(i, c[i]);
			else
				assertEquals(0, 0);
		}
	}
	
	function testReserve()
	{
		var a = new ArrayList<Int>();
		for (i in 0...5) a.add(5 - i);
		a.reserve(100);
		
		assertEquals(100, a.capacity);
		assertEquals(5, a.size);
		
		for (i in 0...95) a.pushBack(i);
		for (i in 0...5) assertEquals(5 - i, a.get(i));
		for (i in 0...95) assertEquals(i, a.get(5 + i));
	}
	
	function testInit()
	{
		var a = new ArrayList<Int>();
		a.init(5, 10);
		
		assertEquals(5, a.size);
		for (i in 0...5) assertEquals(10, a.get(i));
		
		var a = new ArrayList<Int>(2);
		a.init(10, 10);
		assertEquals(10, a.size);
		assertEquals(10, a.capacity);
		for (i in 0...10) assertEquals(10, a.get(i));
	}
	
	function testPack()
	{
		var a = new ArrayList<Int>().init(20, 0);
		a.pack();
		assertEquals(a.size, 20);
		assertEquals(20, a.capacity);
		for (i in 0...10) a.pushBack(i);
		assertEquals(a.size, 30);
		var a = new ArrayList<Int>().init(20, 0);
		a.clear();
		a.pack();
		assertEquals(a.size, 0);
		assertEquals(2, a.capacity);
	}
	
	function testIter()
	{
		var a = new ArrayList<Int>();
		a.forEach(function(e, i) return i);
		assertEquals(0, a.size);
		
		var a = new ArrayList<Int>();
		a.init(20, 0);
		a.forEach(function(e, i) return i);
		assertEquals(20, a.size);
		for (i in 0...20) assertEquals(i, a.get(i));
	}
	
	function testSwap()
	{
		var a = new ArrayList<Int>();
		a.pushBack(2);
		a.pushBack(3);
		assertEquals(2, a.get(0));
		assertEquals(3, a.get(1));
		a.swap(0, 1);
		assertEquals(3, a.get(0));
		assertEquals(2, a.get(1));
	}
	
	function testCopy()
	{
		var a = new ArrayList<Int>();
		a.pushBack(2);
		a.pushBack(3);
		a.copy(0, 1);
		assertEquals(2, a.front());
		assertEquals(2, a.back());
	}
	
	function testFront()
	{
		var a = new ArrayList<Int>();
		
		#if debug
		var fail = false;
		try
		{
			a.front();
		}
		catch (unknown:Dynamic)
		{
			fail = true;
		}
		assertTrue(fail);
		#end
		
		a.pushBack(0);
		assertEquals(0, a.front());
		assertEquals(1, a.size);
		
		a.pushBack(1);
		assertEquals(0, a.front());
		
		a.insert(0, 1);
		assertEquals(1, a.front());
	}
	
	function testBack()
	{
		var a = new ArrayList<Int>();
		
		#if debug
		var fail = false;
		try
		{
			a.back();
		}
		catch (unknown:Dynamic)
		{
			fail = true;
		}
		assertTrue(fail);
		#end
		
		a.pushBack(0);
		assertEquals(0, a.back());
		assertEquals(1, a.size);
		
		a.pushBack(1);
		assertEquals(1, a.back());
	}
	
	function testPopFront()
	{
		var a = new ArrayList<Int>();
		a.init(5, 0);
		a.forEach(function(e, i) return i);
		var x = a.popFront();
		assertEquals(0, x);
		assertEquals(4, a.size);
		for (i in 0...4) assertEquals(i + 1, a.get(i));
		
		var a = new ArrayList<Int>();
		a.add(1);
		var x = a.popFront();
		assertEquals(1, x);
		assertEquals(0, a.size);
	}
	
	function testPushFront()
	{
		var a = new ArrayList<Int>();
		a.init(5, 0);
		a.forEach(function(e, i) return i);
		a.pushFront(10);
		assertEquals(6, a.size);
		assertEquals(10, a.get(0));
		for (i in 0...5) assertEquals(i, a.get(i + 1));
		
		var a = new ArrayList<Int>();
		a.pushFront(10);
		assertEquals(1, a.size);
		assertEquals(10, a.get(0));
	}
	
	function testPushBack()
	{
		var a = new ArrayList<Int>();
		a.pushBack(1);
		assertEquals(1, a.back());
		assertEquals(1, a.size);
		a.pushBack(2);
		assertEquals(2, a.back());
		assertEquals(2, a.size);
		a.pushBack(3);
		assertEquals(3, a.back());
		assertEquals(3, a.size);
		assertEquals(3, a.popBack());
		assertEquals(2, a.back());
		assertEquals(2, a.popBack());
		assertEquals(1, a.back());
		assertEquals(1, a.popBack());
		assertEquals(0, a.size);
	}
	
	function testPopBack()
	{
		var a = new ArrayList<Int>();
		var x = 0;
		a.pushBack(x);
		assertEquals(1, a.size);
		assertEquals(x, a.front());
		assertEquals(x, a.popBack());
		assertEquals(0, a.size);
		x = 1;
		a.pushBack(x);
		assertEquals(1, a.size);
		assertEquals(x, a.front());
		assertEquals(x, a.popBack());
		assertEquals(0, a.size);
	}
	
	function testSwapPop()
	{
		var a = new ArrayList<Int>();
		a.init(5, 0);
		a.forEach(function(e, i) return i);
		var x = a.swapPop(0);
		assertEquals(0, x);
		assertEquals(4, a.size);
		assertEquals(1, a.get(1));
		assertEquals(2, a.get(2));
		assertEquals(3, a.get(3));
		
		var a = new ArrayList<Int>();
		a.pushBack(0);
		a.swapPop(0);
		assertEquals(0, a.size);
		
		var a = new ArrayList<Int>();
		a.pushBack(0);
		a.pushBack(1);
		a.swapPop(0);
		assertEquals(1, a.size);
		assertEquals(a.get(0), 1);
		
		var a = new ArrayList<Int>();
		a.pushBack(0);
		a.pushBack(1);
		a.pushBack(2);
		a.swapPop(1);
		
		assertEquals(2, a.size);
		assertEquals(a.get(0), 0);
		assertEquals(a.get(1), 2);
	}
	
	function testTrim()
	{
		var a = new ArrayList<Int>();
		a.init(20, 0);
		a.forEach(function(e, i) return i);
		a.trim(10);
		assertEquals(10, a.size);
		for (i in 0...10) assertEquals(i, a.get(i));
	}
	
	function testInsert()
	{
		var a = new ArrayList<Int>();
		a.insert(0, 1);
		assertEquals(1, a.size);
		assertEquals(1, a.get(0));
		
		var a = new ArrayList<Int>();
		for (i in 0...3) a.pushBack(i);
		assertEquals(3, a.size);
		
		a.insert(0, 5);
		assertEquals(4, a.size);
		assertEquals(5, a.get(0));
		assertEquals(0, a.get(1));
		assertEquals(1, a.get(2));
		assertEquals(2, a.get(3));
		
		var a = new ArrayList<Int>();
		for (i in 0...3) a.pushBack(i);
		assertEquals(3, a.size);
		
		a.insert(1, 5);
		assertEquals(4, a.size);
		
		assertEquals(0, a.get(0));
		assertEquals(5, a.get(1));
		assertEquals(1, a.get(2));
		assertEquals(2, a.get(3));
		
		var a = new ArrayList<Int>();
		for (i in 0...3) a.pushBack(i);
		assertEquals(3, a.size);
		
		a.insert(2, 5);
		assertEquals(4, a.size);
		
		assertEquals(0, a.get(0));
		assertEquals(1, a.get(1));
		assertEquals(5, a.get(2));
		assertEquals(2, a.get(3));
		
		var a = new ArrayList<Int>();
		for (i in 0...3) a.pushBack(i);
		assertEquals(3, a.size);
		
		a.insert(3, 5);
		assertEquals(4, a.size);
		assertEquals(0, a.get(0));
		assertEquals(1, a.get(1));
		assertEquals(2, a.get(2));
		assertEquals(5, a.get(3));
		
		var a = new ArrayList<Int>();
		a.insert(0, 0);
		a.insert(1, 1);
		assertEquals(0, a.get(0));
		assertEquals(1, a.get(1));
		
		var s = 20;
		for (i in 0...s)
		{
			var a = new ArrayList<Int>(s);
			for (i in 0...s) a.add(i);
			
			a.insert(i, 100);
			for (j in 0...i) assertEquals(j, a.get(j));
			assertEquals(100, a.get(i));
			var v = i;
			for (j in i + 1...s + 1) assertEquals(v++, a.get(j));
		}
	}
	
	function testRemoveAt()
	{
		var a = new ArrayList<Int>();
		for (i in 0...3) a.pushBack(i);
		
		for (i in 0...3)
		{
			assertEquals(i, a.removeAt(0));
			assertEquals(3 - i - 1, a.size);
		}
		assertEquals(0, a.size);
		
		for (i in 0...3) a.pushBack(i);
		
		var size = 3;
		while (a.size > 0)
		{
			a.removeAt(a.size - 1);
			size--;
			assertEquals(size, a.size);
		}
		
		assertEquals(0, a.size);
		
		var a = new ArrayList<Int>();
		a.add(1);
		a.removeAt(0);
		assertEquals(0, a.size);
		
		a.pushBack(1);
		a.pushBack(2);
		assertEquals(2, a.removeAt(1));
		assertEquals(1, a.size);
		
		var len = a.capacity;
		a = new ArrayList<Int>();
		for (i in 0...len) a.pushBack(i);
		assertEquals(len - 1, a.removeAt(a.size - 1));
		assertEquals(len - 1, a.size);
	}
	
	function testJoin()
	{
		var a = new ArrayList<Int>();
		assertEquals("", a.join(","));
		a.pushBack(0);
		assertEquals("0", a.join(","));
		a.pushBack(1);
		assertEquals("0,1", a.join(","));
		a.pushBack(2);
		assertEquals("0,1,2", a.join(","));
		a.pushBack(3);
		assertEquals("0,1,2,3", a.join(","));
	}
	
	function testReverse()
	{
		var a = new ArrayList<Int>();
		a.pushBack(0);
		a.pushBack(1);
		a.reverse();
		
		assertEquals(1, a.get(0));
		assertEquals(0, a.get(1));
		
		var a = new ArrayList<Int>();
		a.pushBack(0);
		a.pushBack(1);
		a.pushBack(2);
		a.reverse();
		assertEquals(2, a.get(0));
		assertEquals(1, a.get(1));
		assertEquals(0, a.get(2));
		
		var a = new ArrayList<Int>();
		a.pushBack(0);
		a.pushBack(1);
		a.pushBack(2);
		a.pushBack(3);
		a.reverse();
		assertEquals(3, a.get(0));
		assertEquals(2, a.get(1));
		assertEquals(1, a.get(2));
		assertEquals(0, a.get(3));
		
		var a = new ArrayList<Int>();
		a.pushBack(0);
		a.pushBack(1);
		a.pushBack(2);
		a.pushBack(3);
		a.pushBack(4);
		
		a.reverse();
		
		assertEquals(4, a.get(0));
		assertEquals(3, a.get(1));
		assertEquals(2, a.get(2));
		assertEquals(1, a.get(3));
		assertEquals(0, a.get(4));
		
		var a = new ArrayList<Int>();
		for (i in 0...27) a.pushBack(i);
		a.reverse();
		for (i in 0...27) assertEquals(26 - i, a.get(i));
		
		var a = new ArrayList<Int>();
		for (i in 0...4) a.add(i);
		a.reverse();
		for (i in 0...4) assertEquals(3 - i, a.get(i));
		
		var a = new ArrayList<Int>();
		
		a.pushBack(8);
		a.pushBack(7);
		a.pushBack(4);
		a.pushBack(2);
		a.pushBack(4);
		
		a.reverse();
		a.clear();
		
		a.pushBack(8);
		a.pushBack(10);
		a.pushBack(11);
		a.pushBack(3);
		
		a.reverse();
		
		assertEquals(3 , a.get(0));
		assertEquals(11, a.get(1));
		assertEquals(10, a.get(2));
		assertEquals(8 , a.get(3));
		
		var a = new ArrayList<Int>(10);
		for (i in 0...10) a.pushBack(i);
		a.reverse();
		for (i in 0...10) assertEquals(10 - i - 1, a.get(i));
		
		var a = new ArrayList<Int>(10);
		for (i in 0...10) a.pushBack(i);
		a.reverse(0, 5);
		for (i in 0...5) assertEquals(5 - i - 1, a.get(i));
		for (i in 5...10) assertEquals(i, a.get(i));
		
		var a = new ArrayList<Int>(10);
		for (i in 0...10) a.pushBack(i);
		a.reverse(0, 1);
		assertEquals(0, a.get(0));
		assertEquals(1, a.get(1));
		
		var a = new ArrayList<Int>(10);
		for (i in 0...10) a.pushBack(i);
		a.reverse(0, 2);
		assertEquals(1, a.get(0));
		assertEquals(0, a.get(1));
	}
	
	function testBinarySearch()
	{
		var a = new ArrayList<Int>();
		for (i in 0...10) a.pushBack(i);
		
		#if !neko
		assertEquals(10, ~a.binarySearch(10, 0, function(a, b) { return a - b;}));
		#end
		assertEquals(-1, a.binarySearch(-100, 0, function(a, b) { return a - b;}));
		
		for (i in 0...10) assertEquals(i, a.binarySearch(i, 0, function(a, b) { return a - b;}));
		for (i in 0...10) assertEquals(i, a.binarySearch(i, i, function(a, b) { return a - b;}));
		for (i in 0...9)
			assertTrue(a.binarySearch(i, i+1, function(a, b) { return a - b;}) < 0);
		
		var a = new ArrayList<E>();
		
		for (i in 0...10) a.pushBack(new E(i));
		
		for (i in 0...10) assertEquals(i, a.binarySearch(a.get(i), 0));
		for (i in 0...10) assertEquals(i, a.binarySearch(a.get(i), i));
		for (i in 0...9) assertTrue(a.binarySearch(a.get(i), i + 1) < 0);
	}
	
	function testIndexOf()
	{
		var a = new ArrayList<Int>();
		assertEquals(-1, a.indexOf(0));
		for (i in 0...3) a.pushBack(i);
		assertEquals(0, a.indexOf(0));
		assertEquals(1, a.indexOf(1));
		assertEquals(2, a.indexOf(2));
		assertEquals(-1, a.indexOf(4));
	}
	
	function testLastIndexOf()
	{
		var a = new ArrayList<Int>();
		assertEquals(-1, a.lastIndexOf(0));
		
		for (i in 0...3) a.pushBack(i);
		assertEquals(0, a.lastIndexOf(0));
		assertEquals(1, a.lastIndexOf(1));
		assertEquals(2, a.lastIndexOf(2));
		assertEquals(-1, a.lastIndexOf(4));
		
		var a = new ArrayList<Int>();
		a.pushBack(0);
		a.pushBack(1);
		a.pushBack(2);
		a.pushBack(3);
		a.pushBack(4);
		a.pushBack(5);
		
		assertEquals(5, a.lastIndexOf(5, -1));
		assertEquals(5, a.lastIndexOf(5));
		
		assertEquals(-1, a.lastIndexOf(5, -2));
		assertEquals(-1, a.lastIndexOf(5, -3));
		assertEquals(-1, a.lastIndexOf(5, 1));
	}
	
	function testBlit()
	{
		var a = new ArrayList<Int>();
		for (i in 0...20) a.pushBack(i);
		
		a.blit(0, 10, 10);
		
		for (i in 0...10)
			assertEquals(i + 10, a.get(i));
		for (i in 10...20)
			assertEquals(i, a.get(i));
		
		var a = new ArrayList<Int>();
		for (i in 0...20) a.pushBack(i);
		
		a.blit(10, 0, 10);
		
		for (i in 0...10)
			assertEquals(i, a.get(i));
		for (i in 10...20)
			assertEquals(i-10, a.get(i));
		
		var a = new ArrayList<Int>();
		for (i in 0...20) a.pushBack(i);
		
		a.blit(5, 0, 10);
		
		for (i in 0...5) assertEquals(i, a.get(i));
		for (i in 5...15) assertEquals(i - 5, a.get(i));
		for (i in 15...20) assertEquals(i, a.get(i));
	}
	
	function testConcat()
	{
		var a = new ArrayList<Int>();
		a.pushBack(0);
		a.pushBack(1);
		var b = new ArrayList<Int>();
		b.pushBack(2);
		b.pushBack(3);
		var c = a.concat(b, true);
		assertEquals(4, c.size);
		for (i in 0...4) assertEquals(i, c.get(i));
		a.concat(b);
		assertEquals(4, a.size);
		for (i in 0...4) assertEquals(i, a.get(i));
		
		var a = new ArrayList<Int>();
		a.pushBack(0);
		a.pushBack(1);
		var b = new ArrayList<Int>();
		b.pushBack(2);
		b.pushBack(3);
		a.concat(b);
		assertEquals(4, a.size);
		assertEquals(2, b.size);
		for (i in 0...4) assertEquals(i, a.get(i));
	}
	
	function testConvert()
	{
		var a = new ArrayList([0, 1, 2, 3]);
		
		assertEquals(a.size, 4);
		for (x in 0...4) assertEquals(x, a.get(x));
		
		var a = new ArrayList<Int>();
		a.iterator();
		for (i in a) {}
		
		var a = new ArrayList([0, 1, 2, 3]);
		a.iterator();
		for (i in a) {}
	}
	
	function testSortRange()
	{
		var d = new ArrayList<Int>();
		d.pushBack(0);
		d.pushBack(1);
		d.pushBack(2);
		d.pushBack(3);
		d.pushBack(30);
		d.pushBack(20);
		d.pushBack(30);
		d.sort(Compare.cmpIntFall, true, 0, 4);
		
		var sorted = [3, 2, 1, 0, 30, 20, 30];
		for (i in 0...d.size) assertEquals(sorted[i], d.get(i));
		assertEquals(3, d.get(0));
		assertEquals(2, d.get(1));
		assertEquals(1, d.get(2));
		assertEquals(0, d.get(3));
		assertEquals(30, d.get(4));
		assertEquals(20, d.get(5));
		assertEquals(30, d.get(6));
		
		var d = new ArrayList([9, 8, 1, 2, 3, 8, 9]);
		d.sort(Compare.cmpIntFall, true, 2, 3);
		
		var sorted = new ArrayList([9, 8, 3, 2, 1, 8, 9]);
		for (i in 0...d.size) assertEquals(sorted.get(i), d.get(i));
		
		var d = new ArrayList([9, 8, 1, 2, 3, 8, 9]);
		d.sort(Compare.cmpIntFall, false, 2, 3);
		var sorted = [9, 8, 3, 2, 1, 8, 9];
		for (i in 0...d.size) assertEquals(sorted[i], d.get(i));
		
		var d = new ArrayList([1, 2, 3]);
		d.sort(Compare.cmpIntFall, true, 2, -1);
		var sorted = [1, 2, 3];
		for (i in 0...d.size) assertEquals(sorted[i], d.get(i));
		
		var d = new ArrayList([1, 2, 3]);
		d.sort(Compare.cmpIntFall, false, 1, 2);
		var sorted = [1, 3, 2];
		for (i in 0...d.size) assertEquals(sorted[i], d.get(i));
		
		var d = new ArrayList([1, 2, 3]);
		d.sort(Compare.cmpIntFall, true, 1, 2);
		var sorted = [1, 3, 2];
		for (i in 0...d.size) assertEquals(sorted[i], d.get(i));
	}
	
	function testSort()
	{
		//1
		var v = new ArrayList([4]);
		v.sort(Compare.cmpIntRise);
		assertEquals(4, v.front());
		
		var v = new ArrayList([4]);
		v.sort(Compare.cmpIntRise, true);
		assertEquals(4, v.front());
		
		var v = new ArrayList([new E(4)]);
		v.sort();
		assertEquals(4, v.front().x);
		
		var v = new ArrayList([new E(4)]);
		v.sort(true);
		assertEquals(4, v.front().x);
		
		//2
		var v = new ArrayList([4, 2]);
		v.sort(Compare.cmpIntRise);
		assertEquals(2, v.front());
		assertEquals(4, v.back());
		
		var v = new ArrayList([4, 2]);
		v.sort(Compare.cmpIntFall);
		assertEquals(4, v.front());
		assertEquals(2, v.back());
		
		var v = new ArrayList([4, 2]);
		v.sort(Compare.cmpIntRise, true);
		assertEquals(2, v.front());
		assertEquals(4, v.back());
		
		var v = new ArrayList([4, 2]);
		v.sort(Compare.cmpIntFall, true);
		assertEquals(4, v.front());
		assertEquals(2, v.back());
		
		var v = new ArrayList([new E(4), new E(2)]);
		v.sort();
		assertEquals(2, v.front().x);
		assertEquals(4, v.back().x);
		
		//n
		var v = new ArrayList([4, 1, 7, 3, 2]);
		v.sort(Compare.cmpIntRise);
		assertEquals(1, v.front());
		var j = 0; for (i in v) { assertTrue(i > j); j = i; }
		
		var v = new ArrayList([4, 1, 7, 3, 2]);
		v.sort(Compare.cmpIntFall);
		assertEquals(7, v.front());
		var j = 8; for (i in v) { assertTrue(i < j); j = i; }
		
		var v = new ArrayList([new E(4), new E(1), new E(7), new E(3), new E(2)]);
		v.sort();
		assertEquals(1, v.front().x);
		var j = 0; for (i in v) { assertTrue(i.x > j); j = i.x; }
	}
	
	function testShuffle()
	{
		var q = new ArrayList<Int>();
		q.init(10, 0).forEach(function(e, i) return i);
		q.shuffle();
		assertEquals(10, q.size);
		var set = new Array<Int>();
		for (i in 0...10)
		{
			assertFalse(contains(set, q.get(i)));
			set.push(q.get(i));
		}
		set.sort(function(a, b) return a - b);
		for (i in 0...10) assertEquals(i, set[i]);
	}
	
	function testIterator()
	{
		var q:ArrayList<Int> = new ArrayList<Int>();
		for (i in 0...10) q.pushBack(i);
		
		var c = 0;
		var itr = q.iterator();
		for (val in itr)
			assertEquals(c++, val);
		assertEquals(c, 10);
		
		c = 0;
		itr.reset();
		for (val in itr) assertEquals(c++, val);
		assertEquals(c, 10);
		
		var set = new ListSet<Int>();
		for (val in q) assertTrue(set.set(val));
		
		var itr = q.iterator();
		
		var s:de.polygonal.ds.Set<Int> = cast set.clone(true);
		for (val in itr) assertEquals(true, s.remove(val));
		assertTrue(s.isEmpty());
		
		var s:de.polygonal.ds.Set<Int> = cast set.clone(true);
		
		itr.reset();
		for (val in itr) assertEquals(true, s.remove(val));
		assertTrue(s.isEmpty());
		
		q.pushBack(10);
		var s:de.polygonal.ds.Set<Int> = cast set.clone(true);
		s.set(10);
		
		itr.reset();
		for (val in itr) assertEquals(true, s.remove(val));
		assertTrue(s.isEmpty());
	}
	
	function testIteratorRemove()
	{
		for (i in 0...5)
		{
			var a = new ArrayList<Int>();
			var set = new de.polygonal.ds.ListSet<Int>();
			for (j in 0...5)
			{
				a.pushBack(j);
				if (i != j) set.set(j);
			}
			
			var itr = a.iterator();
			while (itr.hasNext())
			{
				var val = itr.next();
				if (val == i) itr.remove();
			}
			
			while (!a.isEmpty())
				assertTrue(set.remove(a.popBack()));
			assertTrue(set.isEmpty());
		}
		
		var a = new ArrayList<Int>();
		for (j in 0...5) a.pushBack(j);
		
		var itr = a.iterator();
		while (itr.hasNext())
		{
			itr.next();
			itr.remove();
		}
		assertTrue(a.isEmpty());
	}
	
	function testRemove()
	{
		var a = new ArrayList([0, 1, 2, 2, 2, 3]);
		
		assertEquals(6, a.size);
		
		var k = a.remove(0);
		assertEquals(true, k);
		assertEquals(5, a.size);
		
		var k = a.remove(2);
		assertEquals(true, k);
		assertEquals(2, a.size);
		
		var k = a.remove(1);
		assertEquals(true, k);
		assertEquals(1, a.size);
		
		var k = a.remove(3);
		assertEquals(true, k);
		
		assertTrue(a.isEmpty());
		
		var a = new ArrayList([0, 0, 0, 0, 0]);
		var k = a.remove(0);
		assertEquals(true, k);
		assertTrue(a.isEmpty());
		
		var a = new ArrayList<Int>([0, 1, 2, 2, 3, 3, 3]);
		a.remove(2);
		assertEquals(5, a.size);
		assertEquals(0, a.get(0));
		assertEquals(1, a.get(1));
		assertEquals(3, a.get(2));
		assertEquals(3, a.get(3));
		assertEquals(3, a.get(4));
		
		a.remove(1);
		assertEquals(4, a.size);
		assertEquals(0, a.get(0));
		assertEquals(3, a.get(1));
		assertEquals(3, a.get(2));
		assertEquals(3, a.get(3));
		
		a.remove(3);
		assertEquals(1, a.size);
		assertEquals(0, a.get(0));
		
		var a = new ArrayList<Int>([2, 2, 2]);
		a.remove(2);
		assertEquals(0, a.size);
		
		var a = new ArrayList<Int>([1, 1, 1, 2, 2, 2]);
		a.remove(1);
		assertEquals(3, a.size);
		assertEquals(2, a.get(0));
		assertEquals(2, a.get(1));
		assertEquals(2, a.get(2));
		a.remove(2);
		assertEquals(0, a.size);
		
		var a = new ArrayList<Int>([1, 2, 3]);
		a.remove(1);
		assertEquals(2, a.size);
		assertEquals(2, a.get(0));
		assertEquals(3, a.get(1));
		a.remove(2);
		assertEquals(1, a.size);
		assertEquals(3, a.get(0));
		a.remove(3);
		assertEquals(0, a.size);
	}
	
	function testClone()
	{
		var a = new ArrayList<Int>();
		for (i in 0...3) a.pushBack(i);
		var copy:ArrayList<Int> = cast a.clone();
		assertEquals(3, copy.size);
		for (i in 0...3) assertEquals(i, copy.get(i));
		
		var a = new ArrayList<E>();
		for (i in 0...3) a.pushBack(new E(i));
		var copy:ArrayList<E> = cast a.clone(false);
		assertEquals(3, copy.size);
		for (i in 0...3) assertEquals(i, copy.get(i).x);
		
		var a = new ArrayList<Int>();
		for (i in 0...3) a.pushBack(i);
		var copy:ArrayList<Int> = cast a.clone(false, function(e) return e);
		assertEquals(3, copy.size);
		for (i in 0...3) assertEquals(i, copy.get(i));
	}
	
	function testRange()
	{
		var a = new ArrayList<Int>([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
		
		var b:ArrayList<Int> = cast a.getRange(0, 5);
		assertEquals(5, b.size);
		for (i in 0...5) assertEquals(i, b.get(i));
		
		var b:ArrayList<Int> = cast a.getRange(0, -5);
		assertEquals(5, b.size);
		for (i in 0...5) assertEquals(i, b.get(i));
		
		var b:ArrayList<Int> = cast a.getRange(1, 1);
		assertEquals(0, b.size);
		
		var b:ArrayList<Int> = cast a.getRange(8, -1);
		assertEquals(1, b.size);
		assertEquals(8, b.get(0));
	}
	
	function testOf()
	{
		var a = new ArrayList<Int>();
		a.init(3, 0);
		a.set(0, 0);
		a.set(1, 1);
		a.set(2, 2);
		var b = new ArrayList<Int>();
		b.of(a);
		
		assertEquals(3, b.size);
		for (i in 0...3) assertEquals(i, b.get(i));
		var a = new ArrayList<Int>();
		var b = new ArrayList<Int>();
		b.of(a);
		assertTrue(b.isEmpty());
	}
	
	function testAddArray()
	{
		var a = new ArrayList<Int>();
		a.addArray([1, 2, 3]);
		assertEquals(3, a.size);
		assertEquals(1, a.get(0));
		assertEquals(2, a.get(1));
		assertEquals(3, a.get(2));
		
		var a = new ArrayList<Int>();
		a.addArray([1, 2, 3], 1);
		assertEquals(2, a.size);
		assertEquals(2, a.get(0));
		assertEquals(3, a.get(1));
		
		var a = new ArrayList<Int>();
		a.addArray([1, 2, 3], 2);
		assertEquals(1, a.size);
		assertEquals(3, a.get(0));
		
		var a = new ArrayList<Int>();
		a.addArray([1, 2, 3], 0, 2);
		assertEquals(2, a.size);
		assertEquals(1, a.get(0));
		assertEquals(2, a.get(1));
		
		var a = new ArrayList<Int>(2);
		a.addArray([1, 2, 3, 4]);
	}
	
	function testBruteforce()
	{
		var s = "";
		var a = new ArrayList<String>(["a", "b", "c"]);
		a.bruteforce(function(a, b) s += a + b);
		assertEquals("abacbc", s);
	}
}

private class E implements de.polygonal.ds.Comparable<E> implements de.polygonal.ds.Cloneable<E>
{
	public var x:Int;
	public function new(x:Int)
	{
		this.x = x;
	}
	
	public function compare(other:E):Int
	{
		return x - other.x;
	}
	
	public function clone():E
	{
		return new E(x);
	}
	
	public function toString():String
	{
		return '{$x}';
	}
}