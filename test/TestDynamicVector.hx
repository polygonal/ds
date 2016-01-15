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
	
	function testReserve()
	{
		var dv = new DynamicVector<Int>(true);
		for (i in 0...5) dv.set(i, 5 - i);
		dv.reserve(100);
		for (i in 0...95) dv.push(i);
		for (i in 0...5) assertEquals(5 - i, dv.get(i));
		for (i in 0...95) assertEquals(i, dv.get(5 + i));
	}
	
	function testGrowShrink()
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
	}
	
	function testGrow()
	{
		var dv = new DynamicVector<Int>(false);
		
		for (i in 0...100) dv.set(i, i);
		for (i in 0...100) dv.pop();
		
		assertTrue(dv.capacity >= 100);
	}
	
	function testTrim()
	{
		var dv = new DynamicVector<Int>(true);
		for (i in 0...100) dv.set(i, i);
		
		dv.trim(10);
		
		assertEquals(10, dv.size);
		for (i in 0...10) assertEquals(i, dv.get(i));
	}
	
	function testShrinkToFit()
	{
		var dv = new DynamicVector<Int>(true);
		for (i in 0...100) dv.set(i, i);
		for (i in 0...90) dv.pop();
		
		assertTrue(dv.capacity >= dv.size);
		
		dv.shrinkToFit();
		
		assertTrue(dv.capacity == dv.size);
		
		for (i in 0...10) assertEquals(i, dv.get(i));
		
		for (i in 0...10) dv.push(i * 1000);
	}
	
	function testPushPop()
	{
		var dv = new DynamicVector<Int>(true, 10);
		
		for (i in 0...10) dv.push(i);
		for (i in 0...10) assertEquals(i, dv.get(i));
		for (i in 0...10) assertEquals(10 - i - 1, dv.pop());
		assertEquals(0, dv.size);
	}
	
	function testReverse()
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
	}
}