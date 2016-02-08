import de.polygonal.ds.Array3;
import de.polygonal.ds.Cloneable;
import de.polygonal.ds.ListSet;
import de.polygonal.ds.Set;
import de.polygonal.ds.tools.NativeArrayTools;

class TestArray3 extends AbstractTest
{
	inline static var DEFAULT_SIZE = 10;
	
	var mW:Int;
	var mH:Int;
	var mD:Int;
	
	function new(w = DEFAULT_SIZE, h = DEFAULT_SIZE, d = DEFAULT_SIZE)
	{
		mW = w;
		mH = h;
		mD = d;
		super();
	}
	
	function testSource()
	{
		var a = new Array3<Int>(2, 2, 2, [0, 1, 2, 3, 4, 5, 6, 7]);
		assertEquals(0, a.get(0, 0, 0));
		assertEquals(1, a.get(1, 0, 0));
		assertEquals(2, a.get(0, 1, 0));
		assertEquals(3, a.get(1, 1, 0));
		assertEquals(4, a.get(0, 0, 1));
		assertEquals(5, a.get(1, 0, 1));
		assertEquals(6, a.get(0, 1, 1));
		assertEquals(7, a.get(1, 1, 1));
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
		assertEquals(isDynamic() ? null : 0, x);
		
		var x = a.get(1, 1, 1);
		assertEquals(isDynamic() ? null : 0, x);
		
		var x = a.get(2, 2, 2);
		assertEquals(isDynamic() ? null : 0, x);
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
	
	function testForEach()
	{
		var a = new Array3<String>(3, 3, 3);
		for (z in 0...3)
			for (y in 0...3)
				for (x in 0...3)
					a.set(x, y, z, '$x$y$z');
		
		a.forEach(
			function(v, x, y, z)
			{
				assertEquals(v, '$x$y$z');
				return 'v$x$y$z';
			});
		
		a.forEach(
			function(v, x, y, z)
			{
				assertEquals(v, 'v$x$y$z');
				return v;
			});
		
		for (i in 0...3)
		{
			a.forEach(
				function(v, x, y, z)
				{
					assertEquals(v, 'v$x$y$i');
					return v;
				}, i);
		}
	}
	
	function testIterator()
	{
		var a = new Array3<Int>(mW, mH, mD);
		a.forEach(function(e, x, y, z) return 99);
		var c = 0;
		for (val in a)
		{
			assertEquals(val, 99);
			c++;
		}
		assertEquals(c, a.size);
		var c = 0;
		for (val in a)
		{
			assertEquals(val, 99);
			c++;
		}
		assertEquals(c, a.size);
		var s = new ListSet<String>();
		var a = new Array3<String>(mW, mH, mD);
		a.forEach(function(val:String, x:Int, y:Int, z:Int):String
		{
			var t = [x, y, z].join(".");
			s.set(t);
			return t;
		});
		var s1:Set<String> = cast s.clone(true);
		var s2:Set<String> = cast s.clone(true);
		var itr = a.iterator();
		
		for (i in itr) assertEquals(true, s1.remove(i));
		assertTrue(s1.isEmpty());
		itr.reset();
		for (i in itr) assertEquals(true, s2.remove(i));
		
		assertTrue(s2.isEmpty());
	}
	
	function testIteratorRemove()
	{
		var a = new Array3<String>(mW, mH, mD);
		a.forEach(function(e, x, y, z) return "?");
		
		var itr = a.iterator();
		while (itr.hasNext())
		{
			itr.next();
			itr.remove();
		}
		var arr = a.getStorage();
		for (i in 0...NativeArrayTools.size(arr)) assertEquals(null, arr[i]);
	}
	
	function testClone()
	{
		var i = 0;
		var a = new Array3<E>(2, 2, 2);
		a.forEach(function(e, x, y, z) return new E(i++));
		var clone:Array3<E> = cast a.clone(false);
		assertEquals(8, clone.size);
		i = 0;
		clone.forEach(function(e, x, y, z) {assertEquals(i++, e.x); return e; });
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