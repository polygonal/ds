import de.polygonal.ds.tools.ArrayTools;
import de.polygonal.ds.tools.Compare;
import haxe.ds.IntMap;

class TestArrayTools extends AbstractTest
{
	function testSortRange()
	{
		var a = [9., 8, 7, 1, 2, 3, 7, 8, 9];
		ArrayTools.sortRange(a, Compare.cmpFloatFall, false, 3, 3);
		var b = [9., 8, 7, 3, 2, 1, 7, 8, 9];
		assertEquals(a.length, b.length);
		for (i in 0...a.length) assertEquals(b[i], a[i]);
		
		var a = [9., 8, 7, 1, 2, 3, 7, 8, 9];
		ArrayTools.sortRange(a, Compare.cmpFloatFall, true, 3, 3);
		var b = [9., 8, 7, 3, 2, 1, 7, 8, 9];
		assertEquals(a.length, b.length);
		for (i in 0...a.length) assertEquals(b[i], a[i]);
	}
	
	function testTrim()
	{
		var a = ArrayTools.alloc(10);
		for (i in 0...5) a[i] = i;
		a = ArrayTools.trim(a, 5);
		assertEquals(5, a.length);
		for (i in 0...5) assertEquals(i, a[i]);
	}
	
	function testBinarySearchInt()
	{
		var a = new Array<Int>();
		a.push(0);
		assertEquals(0, ArrayTools.binarySearchi(a, 0, 0, 0));
		a.push(1);
		assertEquals(0, ArrayTools.binarySearchi(a, 0, 0, 1));
		assertEquals(1, ArrayTools.binarySearchi(a, 1, 0, 1));
		a.push(2);
		assertEquals(0, ArrayTools.binarySearchi(a, 0, 0, 2));
		assertEquals(1, ArrayTools.binarySearchi(a, 1, 0, 2));
		assertEquals(2, ArrayTools.binarySearchi(a, 2, 0, 2));
		a.push(3);
		assertEquals(0, ArrayTools.binarySearchi(a, 0, 0, 3));
		assertEquals(1, ArrayTools.binarySearchi(a, 1, 0, 3));
		assertEquals(2, ArrayTools.binarySearchi(a, 2, 0, 3));
		assertEquals(3, ArrayTools.binarySearchi(a, 3, 0, 3));
		assertEquals(0, ArrayTools.binarySearchi(a, 0, 0, 1));
		assertEquals(0, ArrayTools.binarySearchi(a, 0, 0, 2));
		assertTrue(ArrayTools.binarySearchi(a, 0, 2, 3) < 0);
		assertTrue(ArrayTools.binarySearchi(a, 3, 0, 1) < 0);
		assertTrue(ArrayTools.binarySearchi(a, 3, 0, 2) < 0);
	}
	
	function testShuffle()
	{
		var a = new Array<Int>();
		a.push(0);
		a.push(1);
		a.push(2);
		a.push(3);
		
		var set = new IntMap<Bool>();
		for (i in 0...4) set.set(i, true);
		
		ArrayTools.shuffle(a);
		
		for (i in 0...4)
		{
			var v = a[i];
			assertTrue(set.exists(v));
			assertTrue(set.remove(v));
		}
		
		var c = 0;
		for (i in set.keys()) c++;
		assertEquals(0, c);
	}
	
	function testBinarySearchComparator()
	{
		var comparator = function(a:Int, b:Int):Int return a - b;
		var a = new Array<Int>();
		a.push(0);
		assertEquals(0, ArrayTools.binarySearchCmp(a, 0, 0, 0, comparator));
		a.push(1);
		assertEquals(0, ArrayTools.binarySearchCmp(a, 0, 0, 1, comparator));
		assertEquals(1, ArrayTools.binarySearchCmp(a, 1, 0, 1, comparator));
		a.push(2);
		assertEquals(0, ArrayTools.binarySearchCmp(a, 0, 0, 2, comparator));
		assertEquals(1, ArrayTools.binarySearchCmp(a, 1, 0, 2, comparator));
		assertEquals(2, ArrayTools.binarySearchCmp(a, 2, 0, 2, comparator));
		a.push(3);
		assertEquals(0, ArrayTools.binarySearchCmp(a, 0, 0, 3, comparator));
		assertEquals(1, ArrayTools.binarySearchCmp(a, 1, 0, 3, comparator));
		assertEquals(2, ArrayTools.binarySearchCmp(a, 2, 0, 3, comparator));
		assertEquals(3, ArrayTools.binarySearchCmp(a, 3, 0, 3, comparator));
		assertEquals(0, ArrayTools.binarySearchCmp(a, 0, 0, 1, comparator));
		assertTrue(ArrayTools.binarySearchCmp(a, 0, 1, 2, comparator) < 0);
		assertTrue(ArrayTools.binarySearchCmp(a, 0, 2, 3, comparator) < 0);
		assertTrue(ArrayTools.binarySearchCmp(a, 3, 0, 1, comparator) < 0);
		assertTrue(ArrayTools.binarySearchCmp(a, 3, 0, 2, comparator) < 0);
	}
	
	function testAlloc()
	{
		var a = ArrayTools.alloc(10);
		assertEquals(10, a.length);
	}
	
	function testBlit()
	{
		var a = [for (i in 0...10) i];
		
		ArrayTools.blit(a, 0, a, 1, 10 - 1);
		for (i in 1...10) assertEquals(i - 1, a[i]);
		assertEquals(0, 0);
		
		var a = [for (i in 0...10) i];
		ArrayTools.blit(a, 1, a, 0, 10 - 1);
		for (i in 0...9) assertEquals(i + 1, a[i]);
		assertEquals(9, a[10 - 1]);
		
		var a = [for (i in 0...10) i];
		ArrayTools.blit(a, 0, a, 0, 10);
		for (i in 0...10) assertEquals(i, a[i]);
	}

	function testSwap()
	{
		var a = [1, 2, 3, 4, 5];
		ArrayTools.swap(a, 1, 4);

		assertEquals(5, a[1]);
	}

	function testGetFront()
	{
		var a = [1, 2, 3, 4, 5];
		var b = ArrayTools.getFront(a, 4);
		assertEquals(b, a[0]);
	}
	
	function testBruteforce()
	{
		var s = "";
		ArrayTools.bruteforce(["a", "b", "c"], function(a, b) s += a + b);
		assertEquals("abacbc", s);
	}
}