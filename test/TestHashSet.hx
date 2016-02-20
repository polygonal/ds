import de.polygonal.ds.tools.ArrayTools;
import de.polygonal.ds.Dll;
import de.polygonal.ds.HashableItem;
import de.polygonal.ds.HashSet;
import de.polygonal.ds.tools.GrowthRate;
import haxe.ds.IntMap;

class TestHashSet extends AbstractTest
{
	function new()
	{
		super();
		
		#if (flash && alchemy)
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
		assertEquals(32, h.size);
		assertEquals(32, h.capacity);
		
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
		
		assertEquals(8, h.size);
		assertEquals(8, h.capacity);
		
		for (i in 0...8) assertTrue(h.has(values[i]));
	}
	
	function testPack()
	{
		var values = new Array<E>();
		for (i in 0...32) values.push(new E(i));
		
		var h = new HashSet<E>(16, 16);
		for (i in 0...16) h.set(values[i]);
		for (i in 0...16) assertTrue(h.has(values[i]));
		assertEquals(16, h.size);
		assertEquals(16, h.capacity);
		for (i in 0...12) assertTrue(h.remove(values[i]));
		h.pack();
		assertEquals(4, h.size);
		assertEquals(16, h.capacity);
		
		var h = new HashSet<E>(16, 4);
		for (i in 0...8) h.set(values[i]);
		for (i in 0...8) assertTrue(h.has(values[i]));
		assertEquals(8, h.size);
		assertEquals(8, h.capacity);
		for (i in 0...6) assertTrue(h.remove(values[i]));
		
		h.pack();
		assertEquals(2, h.size);
		assertEquals(4, h.capacity);
		
		assertTrue(h.has(values[6]));
		assertTrue(h.has(values[7]));
		
		var h = new HashSet<E>(16, 2);
		for (i in 0...16) h.set(values[i]);
		
		for (i in 0...16)
		{
			h.remove(values[i]);
			h.pack();
			assertEquals(Math.max(2, 16 - (i + 1)), h.capacity);
			for (j in i + 1...16)
				assertTrue(h.has(values[j]));
		}
	}
	
	function testSize1()
	{
		var values = new Array<E>();
		for (i in 0...128) values.push(new E(i));
		
		var h = new HashSet<E>(16, 2);
		h.growthRate = GrowthRate.NORMAL;
		
		var t = [for (i in 0...128) i];
		ArrayTools.shuffle(t);
		
		for (i in t) assertTrue(h.set(values[i]));
		
		ArrayTools.shuffle(t);
		for (i in 0...64) assertTrue(h.remove(values[t[i]]));
		for (i in 64...128) assertTrue(h.has(values[t[i]]));
		
		h.pack();
		
		for (i in 0...64) t.shift();
		
		ArrayTools.shuffle(t);
		for (i in 0...64) assertTrue(h.has(values[t[i]]));
		for (i in 0...64) assertTrue(h.remove(values[t[i]]));
		
		h.pack();
		
		assertEquals(2, h.capacity);
	}
	
	function testSize2()
	{
		var values = new Array<E>();
		for (i in 0...2) values.push(new E(i));
		
		var h = new HashSet<E>(4, 2);
		h.growthRate = GrowthRate.DOUBLE;
		
		for (i in 0...3)
		{
			h.set(values[0]);
			h.set(values[1]);
			
			assertTrue(h.has(values[0]));
			assertTrue(h.has(values[1]));
			assertEquals(2, h.size);
			
			assertTrue(h.remove(values[0]));
			
			assertFalse(h.has(values[0]));
			assertTrue(h.has(values[1]));
			assertEquals(1, h.size);
			
			assertTrue(h.remove(values[1]));
			
			assertFalse(h.has(values[0]));
			assertFalse(h.has(values[1]));
			assertEquals(0, h.size);
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
			assertEquals(3, h.size);
			
			assertTrue(h.remove(values[0]));
			
			assertFalse(h.has(values[0]));
			assertTrue(h.has(values[1]));
			assertTrue(h.has(values[2]));
			assertEquals(2, h.size);
			
			assertTrue(h.remove(values[1]));
			
			assertFalse(h.has(values[0]));
			assertFalse(h.has(values[1]));
			assertTrue(h.has(values[2]));
			assertEquals(1, h.size);
			
			assertTrue(h.remove(values[2]));
			
			assertFalse(h.has(values[0]));
			assertFalse(h.has(values[1]));
			assertFalse(h.has(values[2]));
			assertEquals(0, h.size);
		}
	}
	
	function testResizeSmall()
	{
		var h = new HashSet<E>(16, 2);
		h.growthRate = GrowthRate.DOUBLE;
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
			
			assertEquals(2, h.size);
			assertEquals(2, h.capacity);
			
			for (i in values) assertTrue(h.has(i));
			
			var item = new E(1);
			values.push(item);
			h.set(item);
			
			assertEquals(3, h.size);
			assertEquals(4, h.capacity);
			
			var item = new E(1);
			values.push(item);
			h.set(item);
			for (i in values) assertTrue(h.has(i));
			assertEquals(4, h.size);
			assertEquals(4, h.capacity);
			
			for (i in 0...4)
			{
				var item = new E(1);
				values.push(item);
				h.set(item);
			}
			
			for (i in values) assertTrue(h.has(i));
			assertEquals(8, h.size);
			assertEquals(8, h.capacity);
			
			for (i in 0...8)
			{
				var item = new E(1);
				values.push(item);
				h.set(item);
			}
			for (i in values) assertTrue(h.has(i));
			assertEquals(16, h.size);
			assertEquals(16, h.capacity);
			
			for (i in 0...12) assertTrue(h.remove(values.pop()));
			
			h.pack();
			
			assertEquals(4, h.capacity);
			assertEquals(4, h.size);
			for (i in values) assertTrue(h.has(i));
			
			for (i in 0...2) assertTrue(h.remove(values.pop()));
			
			h.pack();
			
			assertEquals(2, h.capacity);
			assertEquals(2, h.size);
			for (i in values) assertTrue(h.has(i));
			
			assertTrue(h.remove(values.pop()));
			assertTrue(h.remove(values.pop()));
			
			h.pack();
			
			assertEquals(2, h.capacity);
			assertEquals(0, h.size);
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
	
	@:access(E)
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
		
		var keys = new Array<Int>();
		
		for (i in 0...K.length) keys.push(K[i]);
		for (i in 0...keys.length) h.set(values[keys[i]]);
		
		ArrayTools.shuffle(keys);
		
		for (i in 0...keys.length) assertTrue(h.remove(values[keys[i]]));
	}
	
	function testInsertRemoveRandom2()
	{
		var h = new HashSet<E>(16);
		
		initPrng();
		
		for (i in 0...100)
		{
			var values = new Array<E>();
			for (i in 0...64) values.push(new E(i));
			
			var keys = new Array<Int>();
			
			for (i in 0...8)
			{
				var x:Int = Std.int(prand() % 64);
				while (contains(keys, x)) x = Std.int(prand() % 64);
				keys.push(x);
			}
			for (i in 0...keys.length) h.set(values[keys[i]]);
			for (i in 0...keys.length) assertTrue(h.has(values[keys[i]]));
			
			ArrayTools.shuffle(keys);
			
			for (i in 0...keys.length) assertTrue(h.remove(values[keys[i]]));
		}
	}
	
	function testInsertRemoveRandom3()
	{
		var h = new HashSet<E>(16);
		
		initPrng();
		
		var j = 0;
		for (i in 0...100)
		{
			var values = new Array<E>();
			for (i in 0...64) values.push(new E(i));
			
			j++;
			var keys = new Array<Int>();
			for (i in 0...8)
			{
				var x = Std.int(prand() % 64);
				while (contains(keys, x)) x = Std.int(prand() % 64);
				keys.push(x);
			}
			
			for (i in 0...keys.length) h.set(values[keys[i]]);
			
			ArrayTools.shuffle(keys);
			
			for (i in 0...keys.length) assertTrue(h.has(values[keys[i]]));
			
			ArrayTools.shuffle(keys);
			
			for (i in 0...keys.length) assertTrue(h.remove(values[keys[i]]));
		}
		
		assertEquals(100, j);
	}
	
	@:access(E)
	function testCollision()
	{
		var s = 128;
		
		var values = new Array<E>();
		for (i in 0...s)
		{
			var item = new E(i);
			item.key = i * s;
			values.push(item);
		}
		
		var h = new HashSet<E>(s);
		for (i in 0...s) h.set(values[i]);
		
		assertEquals(s, h.size);
		
		for (i in 0...s) assertTrue(h.remove(values[i]));
		
		assertEquals(0, h.size);
		
		for (i in 0...s) h.set(values[i]);
		
		assertEquals(s, h.size);
		
		for (i in 0...s) assertTrue(h.remove(values[i]));
		
		assertEquals(0, h.size);
	}
	
	function testFind()
	{
		var values = new Array<E>();
		for (i in 0...16) values.push(new E(i));
		
		var h = new HashSet<E>(16);
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
		assertTrue(h.size == h.capacity);
		
		h.set(values[8]);
		
		assertEquals(9, h.size);
		
		for (i in 0...8 + 1) assertTrue(h.has(values[i]));
		for (i in 9...16) h.set(values[i]);
		
		assertTrue(h.size == h.capacity);
		
		for (i in 0...16) assertTrue(h.has(values[i]));
		var i = 16;
		while (i-- > 0)
		{
			if (h.size == 4) return;
			assertTrue(h.remove(values[i]));
		}
		
		assertTrue(h.isEmpty());
		
		for (i in 0...16) h.set(values[i]);
		assertTrue(h.size == h.capacity);
		for (i in 0...16) assertTrue(h.has(values[i]));
	}
	
	function testClone()
	{
		var values = new Array<E>();
		for (i in 0...16) values.push(new E(i));
		
		var h = new HashSet<E>(8);
		for (i in 0...8) h.set(values[i]);
		
		var c:HashSet<E> = cast h.clone(true);
		assertEquals(8, c.size);
		assertEquals(8, c.capacity);
		for (i in 0...8) assertTrue(c.has(values[i]));
	}
	
	function testToArray()
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
		assertEquals(8, h.capacity);
		for (i in 8...16) h.set(values[i]);
		assertEquals(16, h.capacity);
		
		h.clear();
		
		assertEquals(16, h.capacity);
		
		assertEquals(0, h.size);
		assertTrue(h.isEmpty());
		
		for (i in 0...16) h.set(values[i]);
		assertEquals(16, h.capacity);
		for (i in 0...16) assertTrue(h.has(values[i]));
	}
	
	function testIterator()
	{
		var values = new Array<E>();
		for (i in 0...16) values.push(new E(i));
		
		var h = new HashSet<E>(8);
		for (i in 0...8) h.set(values[i]);
		
		var a = new Array<E>();
		
		for (val in h) a.push(val);
		
		assertEquals(8, a.length);
		
		for (i in 0...8) assertTrue(contains(a, values[i]));
		
		var h = new HashSet<E>(8);
		var c = 0;
		for (key in h) c++;
		assertEquals(0, c);
		
		var values = [for (i in 0...16) new E(i)];
		var h = new HashSet<E>(8);
		for (i in 0...8) h.set(values[i]);
		var a = new Array<E>();
		var itr = h.iterator();
		while (itr.hasNext())
		{
			itr.hasNext();
			a.push(itr.next());
		}
		assertEquals(8, a.length);
		for (i in 0...8) contains(a, values[i]);
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
		return "HSItem_" + value;
	}
}