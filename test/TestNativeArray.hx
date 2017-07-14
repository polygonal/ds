package;

import de.polygonal.ds.NativeArray;

using de.polygonal.ds.tools.NativeArrayTools;

class TestNativeArray extends AbstractTest
{
	function new()
	{
		super();
	}
	
	function testLength()
	{
		var v = NativeArrayTools.alloc(10);
		var length = NativeArrayTools.size(v);
		assertEquals(10, length);
	}
	
	function testBlit()
	{
		var v = NativeArrayTools.alloc(10);
		
		for (i in 0...10) v.set(i, i);
		NativeArrayTools.blit(v, 0, v, 1, 10 - 1);
		for (i in 1...10) assertEquals(i - 1, v.get(i));
		assertEquals(0, 0);
		
		for (i in 0...10) v.set(i, i);
		NativeArrayTools.blit(v, 1, v, 0, 10 - 1);
		for (i in 0...9) assertEquals(i + 1, v.get(i));
		assertEquals(9, v.get(10 - 1));
		
		for (i in 0...10) v.set(i, i);
		NativeArrayTools.blit(v, 0, v, 0, 10);
		for (i in 0...10) assertEquals(i, v.get(i));
	}
	
	function testToArray()
	{
		var v = NativeArrayTools.alloc(10);
		for (i in 0...10) v.set(i, i);
		
		var a = NativeArrayTools.toArray(v, 0, 10, new Array<Int>());
		assertEquals(10, a.length);
		for (i in 0...10) assertEquals(v.get(i), a[i]);
		
		var a = NativeArrayTools.toArray(v, 5, 5, new Array<Int>());
		assertEquals(5, a.length);
		for (i in 0...5) assertEquals(i + 5, a[i]);
		
		var a = NativeArrayTools.toArray(v, 0, 5, new Array<Int>());
		assertEquals(5, a.length);
		for (i in 0...5) assertEquals(i, a[i]);
		
		var a = NativeArrayTools.toArray(v, 0, 0, new Array<Int>());
		assertEquals(0, a.length);
	}
	
	function testOfArray()
	{
		var a = [1, 2, 3];
		
		var v:NativeArray<Int> = NativeArrayTools.ofArray(a);
		assertEquals(3, NativeArrayTools.size(v));
		
		assertEquals(1, NativeArrayTools.get(v, 0));
		assertEquals(2, NativeArrayTools.get(v, 1));
		assertEquals(3, NativeArrayTools.get(v, 2));
	}
	
	function testBinarySearch()
	{
		var v = NativeArrayTools.alloc(10);
		for (i in 0...10) v.set(i, i);
		
		var i = v.binarySearchCmp(5, 0, 9, function(a:Int, b:Int) return a - b);
		assertEquals(5, i);
		
		var i = v.binarySearchCmp(20, 0, 9, function(a:Int, b:Int) return a - b);
		assertEquals(10, ~i);
		
		var i = v.binarySearchCmp(-20, 0, 9, function(a:Int, b:Int) return a - b);
		assertEquals(0, ~i);
		
		var v:NativeArray<Float> = NativeArrayTools.alloc(10);
		for (i in 0...10) v.set(i, i + .001);
		
		var i = v.binarySearchf(5, 0, 9);
		assertEquals(5, ~i);
		var i = v.binarySearchf(20., 0, 9);
		assertEquals(10, ~i);
		var i = v.binarySearchf(-20., 0, 9);
		assertEquals(0, ~i);
		
		var v:NativeArray<Int> = NativeArrayTools.alloc(10);
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
		var v = NativeArrayTools.alloc(10);
		for (i in 0...10) v.set(i, i);
		
		var c = v.copy();
		assertTrue(v != c);
		assertEquals(10, NativeArrayTools.size(c));
		for (i in 0...10) assertEquals(i, c.get(i));
	}
	
	function testZero()
	{
		var v = NativeArrayTools.alloc(10);
		for (i in 0...10) v.set(i, 1);
		
		v.zero(0, 10);
		assertEquals(10, NativeArrayTools.size(v));
		for (i in 0...10) assertEquals(0, v.get(i));
	}
	
	function testNullify()
	{
		var v = NativeArrayTools.alloc(10);
		for (i in 0...10) v.set(i, 1);
		v.nullify();
		for (i in 0...10) assertEquals(isDynamic() ? null : 0, v.get(i));
		
		var v = NativeArrayTools.alloc(10);
		for (i in 0...10) v.set(i, new E());
		v.nullify();
		for (i in 0...10) assertEquals(null, v.get(i));
	}
	
	function testInit()
	{
		var v:NativeArray<String> = NativeArrayTools.alloc(4);
		v.init("a");
		for (i in 0...4) assertEquals("a", v.get(i));
		assertEquals(4, v.size());
		
		var v:NativeArray<String> = NativeArrayTools.alloc(4);
		v.init("a", 2);
		assertEquals(4, v.size());
		assertEquals(null, v.get(0));
		assertEquals(null, v.get(1));
		assertEquals("a", v.get(2));
		assertEquals("a", v.get(3));
		
		var v:NativeArray<String> = NativeArrayTools.alloc(4);
		v.init("a", 3, 1);
		assertEquals(null, v.get(0));
		assertEquals(null, v.get(1));
		assertEquals(null, v.get(2));
		assertEquals("a", v.get(3));
		
		var v:NativeArray<String> = NativeArrayTools.alloc(4);
		v.init("a", 0, 2);
		assertEquals("a", v.get(0));
		assertEquals("a", v.get(1));
		assertEquals(null, v.get(2));
		assertEquals(null, v.get(3));
	}
}

private class E
{
	public function new()
	{
	}
}