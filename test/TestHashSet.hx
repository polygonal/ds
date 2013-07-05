package;

import de.polygonal.core.math.random.ParkMiller;
import de.polygonal.ds.DA;
import de.polygonal.ds.DLL;
import de.polygonal.ds.HashableItem;
import de.polygonal.ds.HashSet;

class TestHashSet extends haxe.unit.TestCase
{
	function new()
	{
		super();
		
		#if (flash10 && alchemy)
		de.polygonal.ds.mem.MemoryManager.free();
		#end
	}
	
	function testDuplicate()
	{
		var values = new Array<E>();
		for (i in 0...10) values.push(new E(i));
		
		var s = new HashSet<E>(32);
		for (i in 0...10)
		{
			assertTrue(s.set(values[i]));
			assertFalse(s.set(values[i]));
		}
		for (i in 0...10)
			assertFalse(s.set(values[i]));
	}
	
	function test()
	{
		var values = new Array<E>();
		for (i in 0...32) values.push(new E(i));
		
		var h = new HashSet<E>(16);
		
		for (i in 0...32) h.set(values[i]);
		for (i in 0...32) assertTrue(h.has(values[i]));
		assertEquals(32, h.size());
		assertEquals(32, h.getCapacity());
		
		for (i in 0...24) assertTrue(h.remove(values[i]));
		for (i in 24...32) assertTrue(h.has(values[i]));
		for (i in 0...24 - 32) assertTrue(h.remove(values[i]));
	}
	
	function testHas()
	{
		var values = new Array<E>();
		for (i in 0...32) values.push(new E(i));
		
		var h = new HashSet<E>(16, 16);
		h.set(values[0]);
		h.set(values[1]);
		h.set(values[2]);
		
		assertTrue(h.has(values[0]));
		assertTrue(h.has(values[1]));
		assertTrue(h.has(values[2]));
		
		h.remove(values[2]);
		
		assertTrue(h.has(values[1]));
		assertTrue(h.has(values[0]));
		
		h.remove(values[1]);
		
		assertTrue(h.has(values[0]));
		
		h.remove(values[0]);
		
		assertFalse(h.has(values[0]));
		assertFalse(h.has(values[1]));
		assertFalse(h.has(values[2]));
	}
	
	function testRehash()
	{
		var values = new Array<E>();
		for (i in 0...32) values.push(new E(i));
		
		var h = new HashSet<E>(4);
		for (i in 0...8) h.set(values[i]);
		
		h.rehash(512);
		
		assertEquals(8, h.size());
		assertEquals(8, h.getCapacity());
		
		for (i in 0...8) assertTrue(h.has(values[i]));
	}
	
	function testSize2()
	{
		var values = new Array<E>();
		for (i in 0...32) values.push(new E(i));
		
		var h = new HashSet<E>(4, 2);
		for (i in 0...3)
		{
			h.set(values[0]);
			h.set(values[1]);
			
			assertTrue(h.has(values[0]));
			assertTrue(h.has(values[1]));
			assertEquals(2, h.size());
			
			assertTrue(h.remove(values[0]));
			
			assertFalse(h.has(values[0]));
			assertTrue(h.has(values[1]));
			assertEquals(1, h.size());
			
			assertTrue(h.remove(values[1]));
			
			assertFalse(h.has(values[0]));
			assertFalse(h.has(values[1]));
			assertEquals(0, h.size());
		}
	}
	
	function testSize3()
	{
		var values = new Array<E>();
		for (i in 0...32) values.push(new E(i));
		
		var h = new HashSet<E>(4, 3);
		for (i in 0...3)
		{
			h.set(values[0]);
			h.set(values[1]);
			h.set(values[2]);
			
			assertTrue(h.has(values[0]));
			assertTrue(h.has(values[1]));
			assertTrue(h.has(values[2]));
			assertEquals(3, h.size());
			
			assertTrue(h.remove(values[0]));
			
			assertFalse(h.has(values[0]));
			assertTrue(h.has(values[1]));
			assertTrue(h.has(values[2]));
			assertEquals(2, h.size());
			
			assertTrue(h.remove(values[1]));
			
			assertFalse(h.has(values[0]));
			assertFalse(h.has(values[1]));
			assertTrue(h.has(values[2]));
			assertEquals(1, h.size());
			
			assertTrue(h.remove(values[2]));
			
			assertFalse(h.has(values[0]));
			assertFalse(h.has(values[1]));
			assertFalse(h.has(values[2]));
			assertEquals(0, h.size());
		}
	}
	
	function testResizeSmall()
	{
		var h = new HashSet<E>(16, 2);
		var keys = new Array<Int>();
		var key = 0;
		
		var values = new Array<E>();
		for (i in 0...2)
		{
			var item = new E(0);
			values.push(item);
			h.set(item);
			
			var item = new E(1);
			values.push(item);
			h.set(item);
			
			assertEquals(2, h.size());
			assertEquals(2, h.getCapacity());
			
			for (i in values) assertTrue(h.has(i));
			
			var item = new E(1);
			values.push(item);
			h.set(item);
			
			assertEquals(3, h.size());
			assertEquals(4, h.getCapacity());
			
			var item = new E(1);
			values.push(item);
			h.set(item);
			for (i in values) assertTrue(h.has(i));
			assertEquals(4, h.size());
			assertEquals(4, h.getCapacity());
			
			for (i in 0...4)
			{
				var item = new E(1);
				values.push(item);
				h.set(item);
			}
			
			for (i in values) assertTrue(h.has(i));
			assertEquals(8, h.size());
			assertEquals(8, h.getCapacity());
			
			for (i in 0...8)
			{
				var item = new E(1);
				values.push(item);
				h.set(item);
			}
			for (i in values) assertTrue(h.has(i));
			assertEquals(16, h.size());
			assertEquals(16, h.getCapacity());
			
			for (i in 0...12)
				assertTrue(h.remove(values.pop()));
			assertEquals(8, h.getCapacity());
			assertEquals(4, h.size());
			for (i in values) assertTrue(h.has(i));
			
			for (i in 0...2) assertTrue(h.remove(values.pop()));
			
			assertEquals(4, h.getCapacity());
			assertEquals(2, h.size());
			for (i in values) assertTrue(h.has(i));
			
			assertTrue(h.remove(values.pop()));
			assertTrue(h.remove(values.pop()));
			
			assertEquals(2, h.getCapacity());
			assertEquals(0, h.size());
			assertTrue(h.isEmpty());
		}
	}
	
	function testRemove()
	{
		var values = new Array<E>();
		for (i in 0...32) values.push(new E(i));
		
		var h = new HashSet<E>(16, 32);
		for (j in 0...2)
		{
			for (i in 0...10) h.set(values[i]);
			
			assertTrue(h.has(values[0]));
			h.remove(values[0]);
			
			assertFalse(h.contains(values[0]));
		}
	}
	
	function testInsertRemoveFind()
	{
		var values = new Array<E>();
		
		var h = new HashSet<E>(16);
		var a = new E(0);
		a.key = 34;
		var b = new E(1);
		b.key = 50;
		var c = new E(2);
		c.key = 66;
		
		//everything to key #2
		h.set(a);
		h.set(b);
		h.set(c);
		
		assertTrue(h.has(c));
		assertTrue(h.has(a));
		assertTrue(h.has(b));
		
		assertTrue(h.remove(a));
		assertTrue(h.remove(b));
		assertTrue(h.remove(c));
		
		assertFalse(h.remove(a));
		assertFalse(h.remove(b));
		assertFalse(h.remove(c));
	}
	
	function testInsertRemoveRandom1()
	{
		var values = new Array<E>();
		for (i in 0...32) values.push(new E(i));
		
		var h = new HashSet<E>(16);
		
		var K = [17, 25, 10, 2, 8, 24, 30, 3];
		
		var keys = new DA<Int>();
		for (i in 0...K.length) keys.pushBack(K[i]);
		for (i in 0...keys.size()) h.set(values[keys.get(i)]);
		
		keys.shuffle();
		
		for (i in 0...keys.size()) assertTrue(h.remove(values[keys.get(i)]));
	}
	
	function testInsertRemoveRandom2()
	{
		var h = new HashSet<E>(16);
		
		var seed = new ParkMiller(1);
		
		for (i in 0...100)
		{
			var values = new Array<E>();
			for (i in 0...64) values.push(new E(i));
		
			var keys = new DA<Int>();
			for (i in 0...8)
			{
				var x:Int = Std.int(seed.random() % 64);
				while (keys.contains(x)) x = Std.int(seed.random() % 64);
				keys.pushBack(x);
			}
			for (i in 0...keys.size()) h.set(values[keys.get(i)]);
			for (i in 0...keys.size()) assertTrue(h.has(values[keys.get(i)]));
			
			keys.shuffle();
			
			for (i in 0...keys.size()) assertTrue(h.remove(values[keys.get(i)]));
		}
	}
	
	function testInsertRemoveRandom3()
	{
		var h = new HashSet<E>(16);
		var seed = new ParkMiller(1);
		
		var j = 0;
		for (i in 0...100)
		{
			var values = new Array<E>();
			for (i in 0...64) values.push(new E(i));
			
			j++;
			var keys = new DA<Int>();
			for (i in 0...8)
			{
				var x = Std.int(seed.random() % 64);
				while (keys.contains(x)) x = Std.int(seed.random() % 64);
				keys.pushBack(x);
			}
			
			for (i in 0...keys.size()) h.set(values[keys.get(i)]);
			
			keys.shuffle();
			
			for (i in 0...keys.size()) assertTrue(h.has(values[keys.get(i)]));
			
			keys.shuffle();
			
			for (i in 0...keys.size()) assertTrue(h.remove(values[keys.get(i)]));
		}
		
		assertEquals(100, j);
	}
	
	function testCollision()
	{
		var s = 128;
		
		var values = new Array<E>();
		for (i in 0...s)
		{
			var item = new E(i);
			untyped item.key = i * s;
			values.push(item);
		}
		
		var h = new HashSet<E>(s);
		for (i in 0...s) h.set(values[i]);
		
		assertEquals(s, h.size());
		
		for (i in 0...s) assertTrue(h.remove(values[i]));
		
		assertEquals(0, h.size());
		
		for (i in 0...s) h.set(values[i]);
		
		assertEquals(s, h.size());
		
		for (i in 0...s) assertTrue(h.remove(values[i]));
		
		assertEquals(0, h.size());
	}
	
	function testFind()
	{
		var values = new Array<E>();
		for (i in 0...16) values.push(new E(i));
		
		var h = new HashSet<E>(16);
		var seed = new ParkMiller(1);
		for (i in 0...100)
		{
			for (i in 0...16) h.set(values[i]);
			for (i in 0...16) assertTrue(h.has(values[i]));
			for (i in 0...16) assertTrue(h.remove(values[i]));
		}
	}
	
	function testResize1()
	{
		var values = new Array<E>();
		for (i in 0...16) values.push(new E(i));
		
		var h = new HashSet<E>(8);
		
		for (i in 0...8) h.set(values[i]);
		assertTrue(h.size() == h.getCapacity());
		
		h.set(values[8]);
		
		assertEquals(9, h.size());
		
		for (i in 0...8 + 1) assertTrue(h.has(values[i]));
		for (i in 9...16) h.set(values[i]);
		
		assertTrue(h.size() == h.getCapacity());
		
		for (i in 0...16) assertTrue(h.has(values[i]));
		var i = 16;
		while (i-- > 0)
		{
			if (h.size() == 4) return;
			assertTrue(h.remove(values[i]));
		}
		
		assertTrue(h.isEmpty());
		
		for (i in 0...16) h.set(values[i]);
		assertTrue(h.size() == h.getCapacity());
		for (i in 0...16) assertTrue(h.has(values[i]));
	}
	
	function testClone()
	{
		var values = new Array<E>();
		for (i in 0...16) values.push(new E(i));
		
		var h = new HashSet<E>(8);
		for (i in 0...8) h.set(values[i]);
		
		var c:HashSet<E> = cast h.clone(true);
		
		var i = 0;
		var l = new DLL<E>();
		for (val in c)
		{
			l.append(val);
			i++;
		}
		
		l.sort(function(a, b) { return a.value - b.value; } );
		
		var a:Array<E> = l.toArray();
		for (i in 0...a.length)
		{
			assertEquals(i, a[i].value);
		}
		
		assertEquals(8, i);
	}
	
	function testToArrayToDA()
	{
		var values = new Array<E>();
		for (i in 0...16) values.push(new E(i));
		
		var h = new HashSet<E>(8);
		for (i in 0...8) h.set(values[i]);
		
		var a = h.toArray();
		
		var keys = [0, 1, 2, 3, 4, 5, 6, 7];
		for (i in a)
		{
			var found = false;
			for (j in 0...8)
			{
				if (keys[j] == i.value)
				{
					keys.remove(keys[j]);
					found = true;
				}
			}
			
			assertTrue(found);
		}
		
		assertEquals(0, keys.length);
		var a = h.toArray();
		var keys = [0, 1, 2, 3, 4, 5, 6, 7];
		for (i in a)
		{
			var found = false;
			for (j in 0...8)
			{
				if (keys[j] == i.value)
				{
					keys.remove(keys[j]);
					found = true;
				}
			}
			
			assertTrue(found);
		}
		assertEquals(0, keys.length);
	}
	
	function testClear()
	{
		var values = new Array<E>();
		for (i in 0...16) values.push(new E(i));
		
		var h = new HashSet<E>(8);
		for (i in 0...8) h.set(values[i]);
		h.clear();
		var c = 0;
		for (i in h) c++;
		assertEquals(0, c);
		
		var h = new HashSet<E>(8);
		for (i in 0...8) h.set(values[i]);
		assertEquals(8, h.getCapacity());
		for (i in 8...16) h.set(values[i]);
		assertEquals(16, h.getCapacity());
		
		h.clear();
		
		assertEquals(16, h.getCapacity());
		
		assertEquals(0, h.size());
		assertTrue(h.isEmpty());
		
		for (i in 0...16) h.set(values[i]);
		assertEquals(16, h.getCapacity());
		for (i in 0...16) assertTrue(h.has(values[i]));
		
		//test with purge
		var values = new Array<E>();
		for (i in 0...16) values.push(new E(i));
		
		var h = new HashSet<E>(8);
		for (i in 0...16) h.set(values[i]);
		
		h.clear(true);
		
		assertEquals(8, h.getCapacity());
		assertEquals(0, h.size());
		
		for (i in 0...16) h.set(values[i]);
		assertEquals(16, h.getCapacity());
		for (i in 0...16) assertTrue(h.has(values[i]));
		
		h.clear(true);
		
		for (i in 0...16) h.set(values[i]);
		assertEquals(16, h.getCapacity());
		for (i in 0...16) assertTrue(h.has(values[i]));
	}
	
	function testIterator()
	{
		var values = new Array<E>();
		for (i in 0...16) values.push(new E(i));
		
		var h = new HashSet<E>(8);
		for (i in 0...8) h.set(values[i]);
		
		var a = new DA<E>();
		
		for (val in h) a.pushBack(val);
		
		assertEquals(8, a.size());
		
		for (i in 0...8) a.contains(values[i]);
		
		var h = new HashSet<E>(8);
		var c = 0;
		for (key in h) c++;
		
		assertEquals(0, c);
	}
}

private class E extends HashableItem
{
	public var value:Int;
	public function new(v:Int)
	{
		super();
		this.value = v;
	}
	
	public function toString():String
	{
		return 'HSItem_' + value;
	}
}