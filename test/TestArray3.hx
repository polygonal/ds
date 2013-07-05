package;

import de.polygonal.ds.Array3;
import de.polygonal.ds.ListSet;
import de.polygonal.ds.Set;

class TestArray3 extends haxe.unit.TestCase
{
	inline static var DEFAULT_SIZE = 10;
	
	var _w:Int;
	var _h:Int;
	var _d:Int;
	
	function new(w = DEFAULT_SIZE, h = DEFAULT_SIZE, d = DEFAULT_SIZE)
	{
		_w = w;
		_h = h;
		_d = d;
		super();
	}
	
	function testRemove()
	{
		var a = new Array3<Int>(10, 10, 10);
		a.set(0, 0, 0, 1);
		a.set(1, 1, 1, 1);
		a.set(2, 2, 2, 1);
		var k = a.remove(1);
		assertEquals(k, true);
		
		var x = a.get(0, 0, 0);
		assertEquals(#if (js || neko) null #else 0 #end, x);
		
		var x = a.get(1, 1, 1);
		assertEquals(#if (js || neko) null #else 0 #end, x);
		
		var x = a.get(2, 2, 2);
		assertEquals(#if (js || neko) null #else 0 #end, x);
	}
	
	function testIndexOf()
	{
		var a = new Array3<Int>(10, 10, 10);
		assertEquals(-1, a.indexOf(1));
		a.set(0, 0, 9, 1);
		assertEquals(1000 - 100, a.indexOf(1));
	}
	
	function testIndexToCell()
	{
		var a = new Array3<Int>(5, 5, 5);
		var c = new Array3Cell();
		for (z in 0...5)
		{
			for (y in 0...5)
			{
				for (x in 0...5)
				{
					var i = a.getIndex(x, y, z);
					a.indexToCell(i, c);
					assertEquals(c.x, x);
					assertEquals(c.y, y);
					assertEquals(c.z, z);
				}
			}
		}
	}
	
	function testCellOf()
	{
		var c = new Array3Cell();
		var a = new Array3<Int>(9, 9, 9);
		a.set(8, 6, 3, 1);
		var index = a.indexOf(1);
		a.indexToCell(index, c);
		assertEquals(8, c.x);
		assertEquals(6, c.y);
		assertEquals(3, c.z);
	}
	
	function testAssign()
	{
		var a = new Array3<Int>(_w, _h, _d);
		a.fill(99);
		for (z in 0..._d)
			for (y in 0..._h)
				for (x in 0..._w)
					assertEquals(99, a.get(x, y, z));
	}
	
	function testIterator()
	{
		var a = new Array3<Int>(_w, _h, _d);
		a.fill(99);
		var c = 0;
		for (val in a)
		{
			assertEquals(val, 99);
			c++;
		}
		assertEquals(c, a.size());
		var c = 0;
		for (val in a)
		{
			assertEquals(val, 99);
			c++;
		}
		assertEquals(c, a.size());
		var s = new ListSet<String>();
		var a = new Array3<String>(_w, _h, _d);
		a.walk(function(val:String, x:Int, y:Int, z:Int):String
		{
			var t = [x, y, z].join('.');
			s.set(t);
			return t;
		});
		var s1:Set<String> = cast s.clone(true);
		var s2:Set<String> = cast s.clone(true);
		var itr:de.polygonal.ds.ResettableIterator<String> = cast a.iterator();
		
		for (i in itr) assertEquals(true, s1.remove(i));
		assertTrue(s1.isEmpty());
		itr.reset();
		for (i in itr) assertEquals(true, s2.remove(i));
		
		assertTrue(s2.isEmpty());
	}
	
	function testIteratorRemove()
	{
		var a = new Array3<String>(_w, _h, _d);
		a.fill('?');
		
		var itr = a.iterator();
		while (itr.hasNext())
		{
			itr.next();
			itr.remove();
		}
		var arr = a.getArray();
		for (i in arr)
			assertEquals(i, null);
	}
}