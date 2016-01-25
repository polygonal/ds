import de.polygonal.ds.DynamicVector;

@:access(de.polygonal.ds.DynamicVector)
class TestDynamicVector extends AbstractTest
{
	function testBasic()
	{
		var dv = new DynamicVector<Int>(true);
		
		for (i in 0...20) dv.set(i, i);
		
		for (i in 0...20) assertEquals(i, dv.get(i));
		assertEquals(20, dv.size);
		assertTrue(dv.capacity >= dv.size);
		
		var c = dv.mData;
		for (i in 0...c.length)
		{
			if (i < 20)
				assertEquals(i, c[i]);
			else
				assertEquals(0, 0);
		}
	}
	
	@:access(de.polygonal.ds.DynamicVector)
	function testReserve()
	{
		var dv = new DynamicVector<Int>(true);
		for (i in 0...5) dv.set(i, 5 - i);
		dv.reserve(100);
		
		assertEquals(100, dv.capacity);
		assertEquals(5, dv.size);
		
		for (i in 0...95) dv.pushBack(i);
		for (i in 0...5) assertEquals(5 - i, dv.get(i));
		for (i in 0...95) assertEquals(i, dv.get(5 + i));
	}
	
	function testSwap()
	{
		var dv = new DynamicVector<Int>();
		dv.pushBack(2);
		dv.pushBack(3);
		assertEquals(2, dv.get(0));
		assertEquals(3, dv.get(1));
		dv.swap(0, 1);
		
		assertEquals(3, dv.get(0));
		assertEquals(2, dv.get(1));
	}
	
	function testCopy()
	{
		var dv = new DynamicVector<Int>();
		dv.pushBack(2);
		dv.pushBack(3);
		dv.copy(0, 1);
		assertEquals(2, dv.front());
		assertEquals(2, dv.back());
	}
	
	function testFront()
	{
		var dv = new DynamicVector<Int>();
		
		#if debug
		var fail = false;
		try
		{
			dv.front();
		}
		catch (unknown:Dynamic)
		{
			fail = true;
		}
		assertTrue(fail);
		#end
		
		dv.pushBack(0);
		assertEquals(0, dv.front());
		assertEquals(1, dv.size);
		
		dv.pushBack(1);
		assertEquals(0, dv.front());
		
		//dv.insertAt(0, 1);
		//assertEquals(1, dv.front());
	}
	
	function testBack()
	{
		var dv = new DynamicVector<Int>();
		
		#if debug
		var fail = false;
		try
		{
			dv.back();
		}
		catch (unknown:Dynamic)
		{
			fail = true;
		}
		assertTrue(fail);
		#end
		
		dv.pushBack(0);
		assertEquals(0, dv.back());
		assertEquals(1, dv.size);
		
		dv.pushBack(1);
		assertEquals(1, dv.back());
		
		//dv.insertAt(0, 1);
		//assertEquals(1, dv.front());
	}
	
	function testInsertAt()
	{
		var dv = new DynamicVector<Int>();
		dv.insertAt(0, 0);
		
		assertEquals(1, dv.size);
		
		var dv = new DynamicVector<Int>();
		for (i in 0...3) dv.pushBack(i);
		assertEquals(3, dv.size);
		
		dv.insertAt(0, 5);
		assertEquals(4, dv.size);
		
		assertEquals(5, dv.get(0));
		assertEquals(0, dv.get(1));
		assertEquals(1, dv.get(2));
		assertEquals(2, dv.get(3));
		
		var dv = new DynamicVector<Int>();
		for (i in 0...3) dv.pushBack(i);
		assertEquals(3, dv.size);
		
		dv.insertAt(1, 5);
		assertEquals(4, dv.size);
		
		assertEquals(0, dv.get(0));
		assertEquals(5, dv.get(1));
		assertEquals(1, dv.get(2));
		assertEquals(2, dv.get(3));
		
		var dv = new DynamicVector<Int>();
		for (i in 0...3) dv.pushBack(i);
		assertEquals(3, dv.size);
		
		dv.insertAt(2, 5);
		assertEquals(4, dv.size);
		
		assertEquals(0, dv.get(0));
		assertEquals(1, dv.get(1));
		assertEquals(5, dv.get(2));
		assertEquals(2, dv.get(3));
		
		var dv = new DynamicVector<Int>();
		for (i in 0...3) dv.pushBack(i);
		assertEquals(3, dv.size);
		
		dv.insertAt(3, 5);
		assertEquals(4, dv.size);
		
		assertEquals(0, dv.get(0));
		assertEquals(1, dv.get(1));
		assertEquals(2, dv.get(2));
		assertEquals(5, dv.get(3));
		
		var dv = new DynamicVector<Int>();
		dv.insertAt(0, 0);
		dv.insertAt(1, 1);
		
		assertEquals(0, dv.get(0));
		assertEquals(1, dv.get(1));
		
		var s = 20;
		for (i in 0...s)
		{
			var dv = new DynamicVector<Int>(s);
			for (i in 0...s) dv.set(i, i);
			dv.insertAt(i, 100);
			for (j in 0...i) assertEquals(j, dv.get(j));
			assertEquals(100, dv.get(i));
			var v = i;
			for (j in i + 1...s + 1) assertEquals(v++, dv.get(j));
		}
	}
	
	function testRemoveAt()
	{
		var dv = new DynamicVector<Int>();
		for (i in 0...3) dv.pushBack(i);
		
		for (i in 0...3)
		{
			assertEquals(i, dv.removeAt(0));
			assertEquals(3 - i - 1, dv.size);
		}
		assertEquals(0, dv.size);
		
		for (i in 0...3) dv.pushBack(i);
		
		var size = 3;
		while (dv.size > 0)
		{
			dv.removeAt(dv.size - 1);
			size--;
			assertEquals(size, dv.size);
		}
		
		assertEquals(0, dv.size);
	}
	
	/*function testGrowShrink()
	{
		var dv = new DynamicVector<Int>(true, 10);
		
		for (i in 0...100) dv.set(i, i);
		for (i in 0...100) assertEquals(i, dv.get(i));
		
		for (i in 0...100) assertEquals(100 - i - 1, dv.pop());
		
		assertEquals(0, dv.size);
		
		for (i in 0...100) dv.set(i, i);
		for (i in 0...100) assertEquals(i, dv.get(i));
		for (i in 0...100) assertEquals(100 - i - 1, dv.pop());
		assertEquals(0, dv.size);
		
		var dv = new DynamicVector<Int>(true);
		
		for (i in 0...100) dv.set(i, i);
		for (i in 0...100) assertEquals(i, dv.get(i));
		for (i in 0...100) assertEquals(100 - i - 1, dv.pop());
		assertEquals(0, dv.size);
		
		for (i in 0...100) dv.set(i, i);
		for (i in 0...100) assertEquals(i, dv.get(i));
		for (i in 0...100) assertEquals(100 - i - 1, dv.pop());
		assertEquals(0, dv.size);
	}*/
	
	/*function testGrow()
	{
		var dv = new DynamicVector<Int>(false);
		
		for (i in 0...100) dv.set(i, i);
		for (i in 0...100) dv.pop();
		
		assertTrue(dv.capacity >= 100);
	}*/
	
	/*function testTrim()
	{
		var dv = new DynamicVector<Int>(true);
		for (i in 0...100) dv.set(i, i);
		
		dv.trim(10);
		
		assertEquals(10, dv.size);
		for (i in 0...10) assertEquals(i, dv.get(i));
	}*/
	
	/*function testShrinkToFit()
	{
		var dv = new DynamicVector<Int>(true);
		for (i in 0...100) dv.set(i, i);
		for (i in 0...90) dv.pop();
		
		assertTrue(dv.capacity >= dv.size);
		
		dv.shrinkToFit();
		
		assertTrue(dv.capacity == dv.size);
		
		for (i in 0...10) assertEquals(i, dv.get(i));
		
		for (i in 0...10) dv.push(i * 1000);
	}*/
	
	/*function testPushPop()
	{
		var dv = new DynamicVector<Int>(true, 10);
		
		for (i in 0...10) dv.push(i);
		for (i in 0...10) assertEquals(i, dv.get(i));
		for (i in 0...10) assertEquals(10 - i - 1, dv.pop());
		assertEquals(0, dv.size);
	}*/
	
	/*function testReverse()
	{
		var dv = new DynamicVector<Int>(true, 10);
		for (i in 0...10) dv.push(i);
		dv.reverse();
		for (i in 0...10) assertEquals(10 - i - 1, dv.get(i));
		
		var dv = new DynamicVector<Int>(true, 10);
		for (i in 0...10) dv.push(i);
		dv.reverse(0, 5);
		for (i in 0...5) assertEquals(5 - i - 1, dv.get(i));
		for (i in 5...10) assertEquals(i, dv.get(i));
		
		var dv = new DynamicVector<Int>(true, 10);
		for (i in 0...10) dv.push(i);
		dv.reverse(0, 1);
		assertEquals(0, dv.get(0));
		assertEquals(1, dv.get(1));
		
		var dv = new DynamicVector<Int>(true, 10);
		for (i in 0...10) dv.push(i);
		dv.reverse(0, 2);
		assertEquals(1, dv.get(0));
		assertEquals(0, dv.get(1));
	}*/
}