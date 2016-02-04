package;

import de.polygonal.ds.Container;
import de.polygonal.ds.tools.NativeArray;

using de.polygonal.ds.tools.NativeArray;

class TestNativeArray extends AbstractTest
{
	function new()
	{
		super();
	}
	
	function testLength()
	{
		var v = NativeArray.init(10);
		var length = NativeArray.size(v);
		assertEquals(10, length);
	}
	
	function testBlit()
	{
		var v = NativeArray.init(10);
		
		for (i in 0...10) v.set(i, i);
		NativeArray.blit(v, 0, v, 1, 10 - 1);
		for (i in 1...10) assertEquals(i - 1, v.get(i));
		assertEquals(0, 0);
		
		for (i in 0...10) v.set(i, i);
		NativeArray.blit(v, 1, v, 0, 10 - 1);
		for (i in 0...9) assertEquals(i + 1, v.get(i));
		assertEquals(9, v.get(10 - 1));
		
		for (i in 0...10) v.set(i, i);
		NativeArray.blit(v, 0, v, 0, 10);
		for (i in 0...10) assertEquals(i, v.get(i));
	}
	
	function testToArray()
	{
		var v = NativeArray.init(10);
		for (i in 0...10) v.set(i, i);
		
		var a = NativeArray.toArray(v);
		for (i in 0...10) assertEquals(v.get(i), a[i]);
		
		var a = NativeArray.toArray(v, 1);
		assertEquals(9, a.length);
		for (i in 0...10 - 1) assertEquals(i + 1, a[i]);
		
		var a = NativeArray.toArray(v, 1, 9);
		assertEquals(9, a.length);
		for (i in 0...10 - 1) assertEquals(i + 1, a[i]);
		
		var a = NativeArray.toArray(v, 0, 5);
		assertEquals(5, a.length);
		for (i in 0...5) assertEquals(i, a[i]);
	}
	
	function testBinarySearch()
	{
		var v = NativeArray.init(10);
		for (i in 0...10) v.set(i, i);
		
		var i = v.binarySearchCmp(5, 0, 9, function(a:Int, b:Int) return a - b);
		assertEquals(5, i);
		
		var i = v.binarySearchCmp(20, 0, 9, function(a:Int, b:Int) return a - b);
		assertEquals(10, ~i);
		
		var i = v.binarySearchCmp(-20, 0, 9, function(a:Int, b:Int) return a - b);
		assertEquals(0, ~i);
		
		var v:Container<Float> = NativeArray.init(10);
		for (i in 0...10) v.set(i, i + .001);
		
		var i = v.binarySearchf(5, 0, 9);
		assertEquals(5, ~i);
		var i = v.binarySearchf(20., 0, 9);
		assertEquals(10, ~i);
		var i = v.binarySearchf(-20., 0, 9);
		assertEquals(0, ~i);
		
		var v:Container<Int> = NativeArray.init(10);
		for (i in 0...10) v.set(i, i);
		var i = v.binarySearchi(5, 0, 9);
		assertEquals(5, i);
		var i = v.binarySearchi(20, 0, 9);
		assertEquals(10, ~i);
		var i = v.binarySearchi(-20, 0, 9);
		assertEquals(0, ~i);
	}
	
	function testCopy()
	{
		var v = NativeArray.init(10);
		for (i in 0...10) v.set(i, i);
		
		var c = v.copy();
		assertTrue(v != c);
		assertEquals(10, NativeArray.size(c));
		for (i in 0...10) assertEquals(i, c.get(i));
	}
	
	function testZero()
	{
		var v = NativeArray.init(10);
		for (i in 0...10) v.set(i, 1);
		
		v.zero(0, 10);
		assertEquals(10, NativeArray.size(v));
		for (i in 0...10) assertEquals(0, v.get(i));
	}
}