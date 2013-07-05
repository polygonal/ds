package;

import de.polygonal.ds.ArrayConvert;
import de.polygonal.ds.Compare;
import de.polygonal.ds.DA;
import de.polygonal.ds.ListSet;

class TestDA extends haxe.unit.TestCase
{
	function testGetSet()
	{
		var a = new DA<Int>();
		for (i in 0...1000) a.set(i, i);
		assertEquals(1000, a.size());
		var l = new DA<Int>(10);
		var x = 0;
		l.pushBack(x);
		assertEquals(x, l.get(0));
		assertEquals(1, l.size());
	}
	
	function testNextPrev()
	{
		var a = new DA<Int>();
		for (i in 0...10) a.set(i, i);
		assertEquals(0, a.getNext(9));
		assertEquals(9, a.getPrev(0));
		assertEquals(8, a.getPrev(9));
		assertEquals(9, a.getPrev(0));
		assertEquals(8, a.getPrev(9));
	}
	
	function testConvert()
	{
		var a = ArrayConvert.toDA([0, 1, 2, 3]);
		assertEquals(a.size(), 4);
		for (x in 0...4)
			assertEquals(x, a.get(x));
	}
	
	function testReserve()
	{
		var da = new DA<Int>();
		for (i in 0...10) da.pushBack(i);
		da.reserve(100);
		assertEquals(10, da.size());
		for (i in 0...10) assertEquals(i, da.get(i));
	}
	
	function testPack()
	{
		var l = new de.polygonal.ds.DA<Int>();
		l.pushBack(0);
		l.pushBack(1);
		l.pushBack(2);
		l.clear();
		assertEquals(0, untyped l.__get(0));
		assertEquals(1, untyped l.__get(1));
		assertEquals(2, untyped l.__get(2));
		l.pack();
		
		#if (cpp && generic)
		assertEquals(0, untyped l.__get(0));
		assertEquals(0, untyped l.__get(1));
		assertEquals(0, untyped l.__get(2));
		#else
		assertEquals(#if (flash9 || flash10) 0 #else null #end, untyped l.__get(0));
		assertEquals(#if (flash9 || flash10) 0 #else null #end, untyped l.__get(1));
		assertEquals(#if (flash9 || flash10) 0 #else null #end, untyped l.__get(2));
		#end
	}
	
	function testSwap()
	{
		var l = new de.polygonal.ds.DA<Int>();
		l.pushBack(0);
		l.pushBack(1);
		l.swp(0, 1);
		assertEquals(1, l.get(0));
		assertEquals(0, l.get(1));
	}
	
	function testSortRange()
	{
		var d = new DA<Int>();
		d.pushBack(0);
		d.pushBack(1);
		d.pushBack(2);
		d.pushBack(3);
		d.pushBack(30);
		d.pushBack(20);
		d.pushBack(30);
		
		d.sort(Compare.compareNumberFall, true, 0, 4);
		
		var sorted = [3, 2, 1, 0, 30, 20, 30];
		for (i in 0...d.size()) assertEquals(sorted[i], d.get(i));
		
		assertEquals(3, d.get(0));
		assertEquals(2, d.get(1));
		assertEquals(1, d.get(2));
		assertEquals(0, d.get(3));
		assertEquals(30, d.get(4));
		assertEquals(20, d.get(5));
		assertEquals(30, d.get(6));
		
		var d = ArrayConvert.toDA([9, 8, 1, 2, 3, 8, 9]);
		d.sort(Compare.compareNumberFall, true, 2, 3);
		var sorted = [9, 8, 3, 2, 1, 8, 9];
		for (i in 0...d.size()) assertEquals(sorted[i], d.get(i));
		
		var d = ArrayConvert.toDA([9, 8, 1, 2, 3, 8, 9]);
		d.sort(Compare.compareNumberFall, false, 2, 3);
		var sorted = [9, 8, 3, 2, 1, 8, 9];
		for (i in 0...d.size()) assertEquals(sorted[i], d.get(i));
		
		var d = ArrayConvert.toDA([1, 2, 3]);
		d.sort(Compare.compareNumberFall, true, 2, -1);
		var sorted = [1, 2, 3];
		for (i in 0...d.size()) assertEquals(sorted[i], d.get(i));
		
		var d = ArrayConvert.toDA([1, 2, 3]);
		d.sort(Compare.compareNumberFall, false, 1, 2);
		var sorted = [1, 3, 2];
		for (i in 0...d.size()) assertEquals(sorted[i], d.get(i));
		
		var d = ArrayConvert.toDA([1, 2, 3]);
		d.sort(Compare.compareNumberFall, true, 1, 2);
		var sorted = [1, 3, 2];
		for (i in 0...d.size()) assertEquals(sorted[i], d.get(i));
	}
	
	function testSort()
	{
		//1
		var v = ArrayConvert.toDA([4]);
		v.sort(Compare.compareNumberRise);
		assertEquals(4, v.front());
		
		var v = ArrayConvert.toDA([4]);
		v.sort(Compare.compareNumberRise, true);
		assertEquals(4, v.front());
		
		var v = ArrayConvert.toDA([new EComparable(4)]);
		v.sort(null);
		assertEquals(4, v.front().val);
		
		var v = ArrayConvert.toDA([new EComparable(4)]);
		v.sort(null, true);
		assertEquals(4, v.front().val);
		
		//2
		var v = ArrayConvert.toDA([4, 2]);
		v.sort(Compare.compareNumberRise);
		assertEquals(2, v.front());
		assertEquals(4, v.back());
		
		var v = ArrayConvert.toDA([4, 2]);
		v.sort(Compare.compareNumberFall);
		assertEquals(4, v.front());
		assertEquals(2, v.back());
		
		var v = ArrayConvert.toDA([4, 2]);
		v.sort(Compare.compareNumberRise, true);
		assertEquals(2, v.front());
		assertEquals(4, v.back());
		
		var v = ArrayConvert.toDA([4, 2]);
		v.sort(Compare.compareNumberFall, true);
		assertEquals(4, v.front());
		assertEquals(2, v.back());
		
		var v = ArrayConvert.toDA([new EComparable(4), new EComparable(2)]);
		v.sort(null);
		assertEquals(2, v.front().val);
		assertEquals(4, v.back().val);
		
		//n
		var v = ArrayConvert.toDA([4, 1, 7, 3, 2]);
		v.sort(Compare.compareNumberRise);
		assertEquals(1, v.front());
		var j = 0; for (i in v) { assertTrue(i >= j); j = i; }
		
		var v = ArrayConvert.toDA([4, 1, 7, 3, 2]);
		v.sort(Compare.compareNumberFall);
		assertEquals(7, v.front());
		var j = 7; for (i in v) { assertTrue(i <= j); j = i; }
		
		var v = ArrayConvert.toDA([new EComparable(4), new EComparable(1), new EComparable(7), new EComparable(3), new EComparable(2)]);
		v.sort(null);
		assertEquals(1, v.front().val);
		var j = 0; for (i in v) { assertTrue(i.val >= j); j = i.val; }
	}
	
	function testConcat()
	{
		var a = new de.polygonal.ds.DA<Int>();
		a.pushBack(0);
		a.pushBack(1);
		var b = new de.polygonal.ds.DA<Int>();
		b.pushBack(2);
		b.pushBack(3);
		var c = a.concat(b, true);
		assertEquals(4, c.size());
		for (i in 0...4) assertEquals(i, c.get(i));
		a.concat(b);
		assertEquals(4, a.size());
		for (i in 0...4) assertEquals(i, a.get(i));
	}
	
	function testReverse()
	{
		var l = new de.polygonal.ds.DA<Int>();
		l.pushBack(0);
		l.pushBack(1);
		l.reverse();
		
		assertEquals(1, l.get(0));
		assertEquals(0, l.get(1));
		
		var l = new de.polygonal.ds.DA<Int>();
		l.pushBack(0);
		l.pushBack(1);
		l.pushBack(2);
		l.reverse();
		assertEquals(2, l.get(0));
		assertEquals(1, l.get(1));
		assertEquals(0, l.get(2));
		
		var l = new de.polygonal.ds.DA<Int>();
		l.pushBack(0);
		l.pushBack(1);
		l.pushBack(2);
		l.pushBack(3);
		l.reverse();
		assertEquals(3, l.get(0));
		assertEquals(2, l.get(1));
		assertEquals(1, l.get(2));
		assertEquals(0, l.get(3));
		
		var l = new de.polygonal.ds.DA<Int>();
		l.pushBack(0);
		l.pushBack(1);
		l.pushBack(2);
		l.pushBack(3);
		l.pushBack(4);
		
		l.reverse();
		
		assertEquals(4, l.get(0));
		assertEquals(3, l.get(1));
		assertEquals(2, l.get(2));
		assertEquals(1, l.get(3));
		assertEquals(0, l.get(4));
		
		var l = new de.polygonal.ds.DA<Int>();
		for (i in 0...27) l.pushBack(i);
		l.reverse();
		for (i in 0...27) assertEquals(26 - i, l.get(i));
		
		var l = new DA<Int>(10, 10);
		for (i in 0...4) l.set(i, i);
		l.reverse();
		for (i in 0...4) assertEquals(3 - i, l.get(i));
		
		var da = new DA<Int>();
		
		da.pushBack(8);
		da.pushBack(7);
		da.pushBack(4);
		da.pushBack(2);
		da.pushBack(4);
		
		da.reverse();
		da.clear();
		
		da.pushBack(8);
		da.pushBack(10);
		da.pushBack(11);
		da.pushBack(3);
		
		da.reverse();
		
		assertEquals(3 , da.get(0));
		assertEquals(11, da.get(1));
		assertEquals(10, da.get(2));
		assertEquals(8 , da.get(3));
	}
	
	function testJoin()
	{
		var l = new de.polygonal.ds.DA<Int>();
		assertEquals('', l.join(','));
		l.pushBack(0);
		assertEquals('0', l.join(','));
		l.pushBack(1);
		assertEquals('0,1', l.join(','));
		l.pushBack(2);
		assertEquals('0,1,2', l.join(','));
		l.pushBack(3);
		assertEquals('0,1,2,3', l.join(','));
	}
	
	function testFill()
	{
		var l = new DA<Int>(20);
		assertEquals(0, l.size());
		l.fill(99, 20);
		assertEquals(20, l.size());
		for (i in 0...20)
			assertEquals(99, l.get(i));
	}
	
	function testAssign()
	{
		var l = new DA<E>(20);
		
		assertEquals(0, l.size());
		l.assign(E, [0], 20);
		assertEquals(20, l.size());
		
		for (i in 0...20)
			assertEquals(E, cast Type.getClass(l.get(i)));
		
		var l = new DA<E>(20);
		
		assertEquals(0, l.size());
		l.assign(E, [5], 20);
		assertEquals(20, l.size());
		
		for (i in 0...20)
		{
			assertEquals(E, cast Type.getClass(l.get(i)));
			assertEquals(5, l.get(i).x);
		}
	}
	
	function testMove()
	{
		var l = new DA<Int>(20);
		for (i in 0...20) l.pushBack(i);
		
		l.memmove(0, 10, 10);
		
		for (i in 0...10)
			assertEquals(i + 10, l.get(i));
		for (i in 10...20)
			assertEquals(i, l.get(i));
		
		
		var l = new DA<Int>(20);
		for (i in 0...20) l.pushBack(i);
		
		l.memmove(10, 0, 10);
		
		for (i in 0...10)
			assertEquals(i, l.get(i));
		for (i in 10...20)
			assertEquals(i-10, l.get(i));
		
		var l = new DA<Int>(20);
		for (i in 0...20) l.pushBack(i);
		
		l.memmove(5, 0, 10);
		
		for (i in 0...5) assertEquals(i, l.get(i));
		for (i in 5...15) assertEquals(i - 5, l.get(i));
		for (i in 15...20) assertEquals(i, l.get(i));
	}
	
	function testSwp()
	{
		var l = new DA<Int>(10);
		l.pushBack(0);
		l.pushBack(1);
		l.swp(0, 1);
		assertEquals(1, l.front());
		assertEquals(0, l.back());
	}
	
	function testCpy()
	{
		var l = new DA<Int>(10);
		l.pushBack(0);
		l.pushBack(1);
		l.cpy(0, 1);
		assertEquals(1, l.front());
		assertEquals(1, l.back());
	}
	
	#if debug
	function testGetOutOfBound()
	{
		var l = new DA<Int>(10);
		try
		{
			l.get(1);
			assertTrue(false);
		}
		catch (unknown:Dynamic)
		{
			assertTrue(true);
		}
	}
	#end
	
	#if debug
	function testMaxSize()
	{
		var stack = new DA(0, 3);
		stack.pushBack(0);
		stack.pushBack(1);
		stack.pushBack(2);
		var failed = false;
		try
		{
			stack.pushBack(4);
		}
		catch (unknown:Dynamic)
		{
			failed = true;
		}
		assertTrue(failed);
		
		var stack = new DA(0, 3);
		stack.pushBack(0);
		stack.pushBack(1);
		stack.pushBack(2);
		var failed = false;
		try
		{
			stack.pushFront(4);
		}
		catch (unknown:Dynamic)
		{
			failed = true;
		}
		assertTrue(failed);
		
		var stack = new DA(0, 3);
		stack.pushBack(0);
		stack.pushBack(1);
		stack.pushBack(2);
		var failed = false;
		try
		{
			stack.insertAt(4, 0);
		}
		catch (unknown:Dynamic)
		{
			failed = true;
		}
		assertTrue(failed);
		
		var stack = new DA(0, 3);
		stack.pushBack(0);
		stack.pushBack(1);
		stack.pushBack(2);
		var failed = false;
		try
		{
			stack.fill(0, 10);
		}
		catch (unknown:Dynamic)
		{
			failed = true;
		}
		assertTrue(failed);
	}
	#end
	
	#if debug
	function testSetOutOfBound()
	{
		var l = new DA<Int>(10);
		var x = 0;
		
		try
		{
			l.set(1, x);
			assertTrue(false);
		}
		catch (unknown:Dynamic)
		{
			assertTrue(true);
		}
		
		try
		{
			l.set(-1, x);
			assertTrue(false);
		}
		catch (unknown:Dynamic)
		{
			assertTrue(true);
		}
	}
	#end
	
	function testFront()
	{
		var l = new DA<Int>(10);
		
		#if debug
		var fail = false;
		try
		{
			l.front();
		}
		catch (unknown:Dynamic)
		{
			fail = true;
		}
		assertTrue(fail);
		#end
		
		l.pushBack(0);
		assertEquals(0, l.front());
		assertEquals(1, l.size());
		
		l.pushBack(1);
		assertEquals(0, l.front());
		
		l.insertAt(0, 1);
		assertEquals(1, l.front());
	}
	
	function testPopBack()
	{
		var l = new DA<Int>(10);
		var x = 0;
		l.pushBack(x);
		assertEquals(1, l.size());
		assertEquals(x, l.front());
		assertEquals(x, l.popBack());
		assertEquals(0, l.size());
		x = 1;
		l.pushBack(x);
		assertEquals(1, l.size());
		assertEquals(x, l.front());
		assertEquals(x, l.popBack());
		assertEquals(0, l.size());
	}
	
	function testPushBack()
	{
		var l = new DA<Int>(10);
		l.pushBack(1);
		assertEquals(1, l.back());
		assertEquals(1, l.size());
		l.pushBack(2);
		assertEquals(2, l.back());
		assertEquals(2, l.size());
		l.pushBack(3);
		assertEquals(3, l.back());
		assertEquals(3, l.size());
		assertEquals(3, l.popBack());
		assertEquals(2, l.back());
		assertEquals(2, l.popBack());
		assertEquals(1, l.back());
		assertEquals(1, l.popBack());
		assertEquals(0, l.size());
	}
	
	#if debug
	function testInsertOutOfBound()
	{
		var l = new DA<Int>(10);
		try
		{
			l.insertAt(1, 0);
			assertTrue(false);
		}
		catch (unknown:Dynamic)
		{
			assertTrue(true);
		}
	}
	#end
	
	#if debug
	function testRemoveOutOfBound()
	{
		var l = new DA<Int>(10);
		
		try
		{
			l.removeAt(1);
			assertTrue(false);
		}
		catch (unknown:Dynamic)
		{
			assertTrue(true);
		}
	}
	#end
	
	function testIndexOf()
	{
		var l = new DA<Int>(10);
		assertEquals(-1, l.indexOf(0));
		for (i in 0...3) l.pushBack(i);
		assertEquals(0, l.indexOf(0));
		assertEquals(1, l.indexOf(1));
		assertEquals(2, l.indexOf(2));
		assertEquals(-1, l.indexOf(4));
		
		var l = new DA<Int>();
		for (i in 0...3) l.pushBack(i);
		l.indexOf(0, 2);
		
		var l = new DA<Int>(10);
		for (i in 0...10) l.pushBack(i);
		
		#if !neko
		assertEquals(10, ~l.indexOf(10, 0, true, function(a, b) { return a - b;}));
		#end
		assertEquals(-1, l.indexOf(-100, 0, true, function(a, b) { return a - b;}));
		
		for (i in 0...10) assertEquals(i, l.indexOf(i, 0, true, function(a, b) { return a - b;}));
		for (i in 0...10) assertEquals(i, l.indexOf(i, i, true, function(a, b) { return a - b;}));
		for (i in 0...9)
			assertTrue(l.indexOf(i, i+1, true, function(a, b) { return a - b;}) < 0);
		
		var l = new DA<E>(10);
		
		for (i in 0...10) l.pushBack(new E(i));
		
		for (i in 0...10) assertEquals(i, l.indexOf(l.get(i), 0, true));
		for (i in 0...10) assertEquals(i, l.indexOf(l.get(i), i, true));
		for (i in 0...9)
			assertTrue(l.indexOf(l.get(i), i+1, true) < 0);
	}
	
	function testLastIndexOf()
	{
		var l = new DA<Int>(10);
		assertEquals(-1, l.lastIndexOf(0));
		
		for (i in 0...3) l.pushBack(i);
		assertEquals(0, l.lastIndexOf(0));
		assertEquals(1, l.lastIndexOf(1));
		assertEquals(2, l.lastIndexOf(2));
		assertEquals(-1, l.lastIndexOf(4));
		
		var l = new DA<Int>(10);
		l.pushBack(0);
		l.pushBack(1);
		l.pushBack(2);
		l.pushBack(3);
		l.pushBack(4);
		l.pushBack(5);
		
		assertEquals(5, l.lastIndexOf(5, -1));
		assertEquals(5, l.lastIndexOf(5));
		
		assertEquals(-1, l.lastIndexOf(5, -2));
		assertEquals(-1, l.lastIndexOf(5, -3));
		assertEquals(-1, l.lastIndexOf(5, 1));
	}
	
	function testRemoveRange()
	{
		var l = new DA<Int>(10);
		for (i in 0...10) l.pushBack(i);
		
		l.removeRange(0, 5);
		
		assertEquals(5, l.size());
		
		for (i in 0...5)
			assertEquals(i + 5, l.get(i));
		
		var l = new DA<Int>(10);
		for (i in 0...10) l.pushBack(i);
		var output = l.removeRange(0, 5, new de.polygonal.ds.DA<Int>(5));
		
		assertEquals(5, output.size());
		assertEquals(5, l.size());
		
		for (i in 0...5)
		{
			assertEquals(i, output.get(i));
			assertEquals(i + 5, l.get(i));
		}
		
		var l = new DA<Int>();
		for (i in 0...10) l.pushBack(i);
		l.removeRange(0, 10);
		assertEquals(0, l.size());
	}
	
	function testInsert()
	{
		var l = new DA<Int>(10);
		l.insertAt(0, 0);
		
		assertEquals(1, l.size());
		
		var l = new DA<Int>(10);
		for (i in 0...3) l.pushBack(i);
		assertEquals(3, l.size());
		
		l.insertAt(0, 5);
		assertEquals(4, l.size());
		
		assertEquals(5, l.get(0));
		assertEquals(0, l.get(1));
		assertEquals(1, l.get(2));
		assertEquals(2, l.get(3));
		
		var l = new DA<Int>(10);
		for (i in 0...3) l.pushBack(i);
		assertEquals(3, l.size());
		
		l.insertAt(1, 5);
		assertEquals(4, l.size());
		
		assertEquals(0, l.get(0));
		assertEquals(5, l.get(1));
		assertEquals(1, l.get(2));
		assertEquals(2, l.get(3));
		
		var l = new DA<Int>(10);
		for (i in 0...3) l.pushBack(i);
		assertEquals(3, l.size());
		
		l.insertAt(2, 5);
		assertEquals(4, l.size());
		
		assertEquals(0, l.get(0));
		assertEquals(1, l.get(1));
		assertEquals(5, l.get(2));
		assertEquals(2, l.get(3));
		
		var l = new DA<Int>(10);
		for (i in 0...3) l.pushBack(i);
		assertEquals(3, l.size());
		
		l.insertAt(3, 5);
		assertEquals(4, l.size());
		
		assertEquals(0, l.get(0));
		assertEquals(1, l.get(1));
		assertEquals(2, l.get(2));
		assertEquals(5, l.get(3));
		
		var l = new DA<Int>();
		l.insertAt(0, 0);
		l.insertAt(1, 1);
		
		assertEquals(0, l.get(0));
		assertEquals(1, l.get(1));
	}
	
	function testClone()
	{
		var l = new DA<Int>(10);
		for (i in 0...3) l.pushBack(i);
		
		var copy:de.polygonal.ds.DA<Int> = cast l.clone(true);
		
		assertEquals(3, copy.size());
		
		for (i in 0...3)
			assertEquals(i, copy.get(i));
	}
	
	function testRemoveAt()
	{
		var l = new DA<Int>(10);
		for (i in 0...3) l.pushBack(i);
		
		for (i in 0...3)
		{
			assertEquals(i, l.removeAt(0));
			assertEquals(3 - i - 1, l.size());
		}
		assertEquals(0, l.size());
		
		for (i in 0...3) l.pushBack(i);
		
		var size = 3;
		while (l.size() > 0)
		{
			l.removeAt(l.size() - 1);
			size--;
			assertEquals(size, l.size());
		}
		
		assertEquals(0, l.size());
	}
	
	function testRemove()
	{
		var a = ArrayConvert.toDA([0, 1, 2, 2, 2, 3]);
		
		assertEquals(6, a.size());
		
		var k = a.remove(0);
		assertEquals(true, k);
		assertEquals(5, a.size());
		
		var k = a.remove(2);
		assertEquals(true, k);
		assertEquals(2, a.size());
		
		var k = a.remove(1);
		assertEquals(true, k);
		assertEquals(1, a.size());
		
		var k = a.remove(3);
		assertEquals(true, k);
		
		assertTrue(a.isEmpty());
		
		var a = ArrayConvert.toDA([0, 0, 0, 0, 0]);
		var k = a.remove(0);
		assertEquals(true, k);
		assertTrue(a.isEmpty());
	}
	
	function testIterator()
	{
		var q:DA<Int> = new DA<Int>();
		for (i in 0...10) q.pushBack(i);
		
		var c = 0;
		var itr:de.polygonal.ds.ResettableIterator<Int> = cast q.iterator();
		for (val in itr)
			assertEquals(c++, val);
		assertEquals(c, 10);
		
		c = 0;
		itr.reset();
		for (val in itr) assertEquals(c++, val);
		assertEquals(c, 10);
		
		var set = new ListSet<Int>();
		for (val in q) assertTrue(set.set(val));
		
		var itr:de.polygonal.ds.ResettableIterator<Int> = cast q.iterator();
		
		var s:de.polygonal.ds.Set<Int> = cast set.clone(true);
		var c = 0;
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
			var da = new de.polygonal.ds.DA<Int>();
			var set = new de.polygonal.ds.ListSet<Int>();
			for (j in 0...5)
			{
				da.pushBack(j);
				if (i != j) set.set(j);
			}
			
			var itr = da.iterator();
			while (itr.hasNext())
			{
				var val = itr.next();
				if (val == i) itr.remove();
			}
			
			while (!da.isEmpty())
				assertTrue(set.remove(da.popBack()));
			assertTrue(set.isEmpty());
		}
		
		var da = new de.polygonal.ds.DA<Int>();
		for (j in 0...5) da.pushBack(j);
		
		var itr = da.iterator();
		while (itr.hasNext())
		{
			itr.next();
			itr.remove();
		}
		assertTrue(da.isEmpty());
	}
	
	function testSwapPop()
	{
		var da = new DA<Int>();
		da.pushBack(0);
		da.swapPop(0);
		assertEquals(0, da.size());
		
		var da = new DA<Int>();
		da.pushBack(0);
		da.pushBack(1);
		da.swapPop(0);
		assertEquals(1, da.size());
		assertEquals(da.get(0), 1);
		
		var da = new DA<Int>();
		da.pushBack(0);
		da.pushBack(1);
		da.pushBack(2);
		da.swapPop(1);
		
		assertEquals(2, da.size());
		assertEquals(da.get(0), 0);
		assertEquals(da.get(1), 2);
	}
}

private class E implements de.polygonal.ds.Comparable<E>
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
}

private class EComparable implements de.polygonal.ds.Comparable<EComparable>
{
	public var val:Int;
	public function new(val:Int)
	{
		this.val = val;
	}
	
	public function compare(other:EComparable):Int
	{
		return val - other.val;
	}
	
	public function toString():String
	{
		return '' + val;
	}
}