import de.polygonal.ds.tools.ArrayTools;
import de.polygonal.ds.Compare;
import haxe.ds.IntMap;

class TestArrayTools extends AbstractTest
{
	function testSortRange()
	{
		var a = [9., 8, 7, 1, 2, 3, 7, 8, 9];
		ArrayTools.sortRange(a, Compare.cmpNumberFall, false, 3, 3);
		var b = [9., 8, 7, 3, 2, 1, 7, 8, 9];
		assertEquals(a.length, b.length);
		for (i in 0...a.length) assertEquals(b[i], a[i]);
		
		var a = [9., 8, 7, 1, 2, 3, 7, 8, 9];
		ArrayTools.sortRange(a, Compare.cmpNumberFall, true, 3, 3);
		var b = [9., 8, 7, 3, 2, 1, 7, 8, 9];
		assertEquals(a.length, b.length);
		for (i in 0...a.length) assertEquals(b[i], a[i]);
	}
	
	function testShrink()
	{
		var a = ArrayTools.alloc(10);
		for (i in 0...5) a[i] = i;
		a = ArrayTools.shrink(a, 5);
		assertEquals(5, a.length);
		for (i in 0...5) assertEquals(i, a[i]);
	}
	
	function testBinarySearchInt()
	{
		var a = new Array<Int>();
		a.push(0);
		assertEquals(0, ArrayTools.bsearchInt(a, 0, 0, 0));
		a.push(1);
		assertEquals(0, ArrayTools.bsearchInt(a, 0, 0, 1));
		assertEquals(1, ArrayTools.bsearchInt(a, 1, 0, 1));
		a.push(2);
		assertEquals(0, ArrayTools.bsearchInt(a, 0, 0, 2));
		assertEquals(1, ArrayTools.bsearchInt(a, 1, 0, 2));
		assertEquals(2, ArrayTools.bsearchInt(a, 2, 0, 2));
		a.push(3);
		assertEquals(0, ArrayTools.bsearchInt(a, 0, 0, 3));
		assertEquals(1, ArrayTools.bsearchInt(a, 1, 0, 3));
		assertEquals(2, ArrayTools.bsearchInt(a, 2, 0, 3));
		assertEquals(3, ArrayTools.bsearchInt(a, 3, 0, 3));
		assertEquals(0, ArrayTools.bsearchInt(a, 0, 0, 1));
		assertEquals(0, ArrayTools.bsearchInt(a, 0, 0, 2));
		assertTrue(ArrayTools.bsearchInt(a, 0, 2, 3) < 0);
		assertTrue(ArrayTools.bsearchInt(a, 3, 0, 1) < 0);
		assertTrue(ArrayTools.bsearchInt(a, 3, 0, 2) < 0);
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
		assertEquals(0, ArrayTools.bsearchComparator(a, 0, 0, 0, comparator));
		a.push(1);
		assertEquals(0, ArrayTools.bsearchComparator(a, 0, 0, 1, comparator));
		assertEquals(1, ArrayTools.bsearchComparator(a, 1, 0, 1, comparator));
		a.push(2);
		assertEquals(0, ArrayTools.bsearchComparator(a, 0, 0, 2, comparator));
		assertEquals(1, ArrayTools.bsearchComparator(a, 1, 0, 2, comparator));
		assertEquals(2, ArrayTools.bsearchComparator(a, 2, 0, 2, comparator));
		a.push(3);
		assertEquals(0, ArrayTools.bsearchComparator(a, 0, 0, 3, comparator));
		assertEquals(1, ArrayTools.bsearchComparator(a, 1, 0, 3, comparator));
		assertEquals(2, ArrayTools.bsearchComparator(a, 2, 0, 3, comparator));
		assertEquals(3, ArrayTools.bsearchComparator(a, 3, 0, 3, comparator));
		assertEquals(0, ArrayTools.bsearchComparator(a, 0, 0, 1, comparator));
		assertTrue(ArrayTools.bsearchComparator(a, 0, 1, 2, comparator) < 0);
		assertTrue(ArrayTools.bsearchComparator(a, 0, 2, 3, comparator) < 0);
		assertTrue(ArrayTools.bsearchComparator(a, 3, 0, 1, comparator) < 0);
		assertTrue(ArrayTools.bsearchComparator(a, 3, 0, 2, comparator) < 0);
	}
	
	function testAlloc()
	{
		var a = ArrayTools.alloc(100);
		#if flash
		assertEquals(100, a.length);
		#else
		assertTrue(a != null);
		#end
	}
	
	function testMemMove()
	{
		var a = new Array<Int>();
		for (i in 0...20) a[i] = i;
		ArrayTools.memmove(a, 5, 0, 5);
		var j = 0;
		for (i in 0...5) assertEquals(i, a[i]);
		for (i in 5...5+5) assertEquals(j++, a[i]);
		for (i in 5+5...20) assertEquals(i, a[i]);
		
		var a = new Array<Int>();
		for (i in 0...20) a[i] = i;
		ArrayTools.memmove(a, 5, 0, 6);
		var j = 0;
		for (i in 0...5) assertEquals(i, a[i]);
		for (i in 5...5+6) assertEquals(j++, a[i]);
		for (i in 5+6...20) assertEquals(i, a[i]);
		
		var a = new Array<Int>();
		for (i in 0...20) a[i] = i;
		ArrayTools.memmove(a, 0, 5, 5);
		var j = 5;
		for (i in 0...5) assertEquals(j++, a[i]);
		for (i in 5...20) assertEquals(i, a[i]);
		
		var a = new Array<Int>();
		for (i in 0...20) a[i] = i;
		ArrayTools.memmove(a, 0, 5, 6);
		var j = 5;
		for (i in 0...6) assertEquals(j++, a[i]);
		for (i in 6...20) assertEquals(i, a[i]);
	}
}