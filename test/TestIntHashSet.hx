import de.polygonal.ds.tools.ArrayTools;
import de.polygonal.ds.Dll;
import de.polygonal.ds.IntHashSet;
import de.polygonal.ds.tools.GrowthRate;

class TestIntHashSet extends AbstractTest
{
	function new()
	{
		super();
		#if (flash && alchemy)
		de.polygonal.ds.tools.mem.MemoryManager.free();
		#end
	}
	
	function testDuplicate()
	{
		var s = new IntHashSet(32);
		
		for (i in 0...10)
		{
			assertTrue(s.set(i));
			assertFalse(s.set(i));
		}
		for (i in 0...10)
		{
			assertFalse(s.set(i));
		}
	}
	
	function testPack()
	{
		var h = new IntHashSet(4, 16);
		h.growthRate = GrowthRate.DOUBLE;
		
		assertEquals(16, h.capacity);
		
		for (i in 0...32) assertTrue(h.set(i));
		for (i in 0...16) h.remove(i);
		
		assertEquals(16, h.size);
		assertEquals(32, h.capacity);
		for (i in 16...32) assertTrue(h.has(i));
		
		h.pack(); //32->16
		
		assertEquals(16, h.size);
		assertEquals(16, h.capacity);
		
		for (i in 16...32) assertTrue(h.has(i));
		
		h.free();
		
		var h = new IntHashSet(4, 4);
		h.growthRate = GrowthRate.NORMAL;
		
		for (i in 0...8) h.set(i);
		for (i in 0...8) assertTrue(h.has(i));
		
		for (i in 0...6) h.remove(i);
		assertEquals(2, h.size);
		assertEquals(11, h.capacity);
		
		h.pack();
		assertEquals(2, h.size);
		assertEquals(4, h.capacity);
		assertTrue(h.has(6));
		assertTrue(h.has(7));
	}
	
	function test()
	{
		var h = new IntHashSet(16);
		
		for (i in 0...32) h.set(i);
		for (i in 0...32) assertTrue(h.has(i));
		
		for (i in 0...24)
			assertTrue(h.remove(i));
		for (i in 24...32)
			assertTrue(h.has(i));
		
		for (i in 0...24 - 32)
			assertTrue(h.remove(i));
	}
	
	function testHas()
	{
		var h = new IntHashSet(16, 16);
		h.set(0);
		h.set(1);
		h.set(2);
		
		assertTrue(h.has(0));
		assertTrue(h.has(1));
		assertTrue(h.has(2));
		
		h.remove(2);
		
		assertTrue(h.has(1));
		assertTrue(h.has(0));
		
		h.remove(1);
		
		assertTrue(h.has(0));
		
		h.remove(0);
		
		assertFalse(h.has(0));
		assertFalse(h.has(1));
		assertFalse(h.has(2));
	}
	
	function testRehash()
	{
		var h = new IntHashSet(4);
		h.growthRate = GrowthRate.DOUBLE;
		for (i in 0...8) h.set(i);
		
		h.rehash(512);
		
		assertEquals(8, h.size);
		assertEquals(8, h.capacity);
		assertEquals(512, h.slotCount);
		
		for (i in 0...8) assertTrue(h.has(i));
	}
	
	function testSize2()
	{
		var h = new IntHashSet(4, 2);
		
		for (i in 0...3)
		{
			h.set(0);
			h.set(1);
			
			assertTrue(h.has(0));
			assertTrue(h.has(1));
			assertEquals(2, h.size);
			
			assertTrue(h.remove(0));
			
			assertFalse(h.has(0));
			assertTrue(h.has(1));
			assertEquals(1, h.size);
			
			assertTrue(h.remove(1));
			
			assertFalse(h.has(0));
			assertFalse(h.has(1));
			assertEquals(0, h.size);
		}
	}
	
	function testSize3()
	{
		var h = new IntHashSet(4, 3);
		
		for (i in 0...3)
		{
			h.set(0);
			h.set(1);
			h.set(2);
			
			assertTrue(h.has(0));
			assertTrue(h.has(1));
			assertTrue(h.has(2));
			assertEquals(3, h.size);
			
			assertTrue(h.remove(0));
			
			assertFalse(h.has(0));
			assertTrue(h.has(1));
			assertTrue(h.has(2));
			assertEquals(2, h.size);
			
			assertTrue(h.remove(1));
			
			assertFalse(h.has(0));
			assertFalse(h.has(1));
			assertTrue(h.has(2));
			assertEquals(1, h.size);
			
			assertTrue(h.remove(2));
			
			assertFalse(h.has(0));
			assertFalse(h.has(1));
			assertFalse(h.has(2));
			assertEquals(0, h.size);
		}
	}
	
	function testResizeSmall()
	{
		var h = new IntHashSet(16, 2);
		h.growthRate = GrowthRate.DOUBLE;
		var keys = new Array<Int>();
		var key = 0;
		
		for (i in 0...2)
		{
			keys.push(key); h.set(key); key++;
			keys.push(key); h.set(key); key++;
			assertEquals(2, h.size);
			assertEquals(2, h.capacity);
			
			for (i in keys) assertTrue(h.has(i));
			keys.push(key); h.set(key); key++;
			for (i in keys) assertTrue(h.has(i));
			assertEquals(3, h.size);
			assertEquals(4, h.capacity);
			
			keys.push(key); h.set(key); key++;
			
			for (i in keys) assertTrue(h.has(i));
			assertEquals(4, h.size);
			assertEquals(4, h.capacity);
			
			for (i in 0...4)
			{
				keys.push(key); h.set(key); key++;
			}
			
			for (i in keys) assertTrue(h.has(i));
			assertEquals(8, h.size);
			assertEquals(8, h.capacity);
			
			for (i in 0...8)
				keys.push(key); h.set(key); key++;
			
			for (i in keys) assertTrue(h.has(i));
			
			assertEquals(9, h.size);
			assertEquals(16, h.capacity);
			
			for (i in 0...5) assertTrue(h.remove(i));
			
			h.pack();
			assertEquals(4, h.capacity);
			assertEquals(4, h.size);
			
			assertTrue(h.remove(5));
			assertTrue(h.remove(6));
			h.pack();
			assertEquals(2, h.capacity);
			assertEquals(2, h.size);
			assertTrue(h.has(7));
			assertTrue(h.has(8));
			
			assertTrue(h.remove(7));
			assertTrue(h.remove(8));
			
			h.pack();
			assertEquals(2, h.capacity);
			assertEquals(0, h.size);
			keys = [];
			key = 0;
		}
	}
	
	function testRemove()
	{
		var h = new IntHashSet(16, 32);
		
		for (j in 0...2)
		{
			for (i in 0...10)
			{
				h.set(i);
			}
			
			assertTrue(h.has(0));
			h.remove(0);
			
			assertFalse(h.contains(0));
		}
	}
	
	function testInsertRemoveFind()
	{
		var h = new de.polygonal.ds.IntHashSet(16);
		
		//everything to key #2
		h.set(34);
		h.set(50);
		h.set(66);
		
		assertTrue(h.has(66));
		assertTrue(h.has(34));
		assertTrue(h.has(50));
		
		assertTrue(h.remove(34));
		assertTrue(h.remove(50));
		assertTrue(h.remove(66));
		
		assertFalse(h.remove(34));
		assertFalse(h.remove(50));
		assertFalse(h.remove(66));
	}
	
	function testInsertRemoveRandom1()
	{
		var h = new IntHashSet(16);
		
		var K = [17, 25, 10, 2, 8, 24, 30, 3];
		
		var keys = new Array<Int>();
		for (i in 0...K.length)
		{
			keys.push(K[i]);
		}
		
		for (i in 0...keys.length)
		{
			h.set(keys[i]);
		}
		
		ArrayTools.shuffle(keys);
		
		for (i in 0...keys.length)
		{
			assertTrue(h.remove(keys[i]));
		}
	}
	
	function testInsertRemoveRandom2()
	{
		var h = new IntHashSet(16);
		
		initPrng();
		
		for (i in 0...100)
		{
			var keys = new Array<Int>();
			for (i in 0...8)
			{
				var x = Std.int(prand()) % 64;
				while (contains(keys, x)) x = Std.int(prand()) % 64;
				keys.push(x);
			}
			for (i in 0...keys.length)
			{
				h.set(keys[i]);
			}
			for (i in 0...keys.length)
			{
				assertTrue(h.has(keys[i]));
			}
			
			ArrayTools.shuffle(keys);
			
			for (i in 0...keys.length)
			{
				assertTrue(h.remove(keys[i]));
			}
		}
	}
	
	function testInsertRemoveRandom3()
	{
		var h = new IntHashSet(16);
		
		initPrng();
		
		var j = 0;
		for (i in 0...100)
		{
			j++;
			var keys = new Array<Int>();
			for (i in 0...8)
			{
				var x = Std.int(prand()) & (64 - 1);
				while (contains(keys, x)) x = Std.int(prand()) % 64;
				
				keys.push(x);
			}
			
			for (i in 0...keys.length)
			{
				h.set(keys[i]);
			}
			
			ArrayTools.shuffle(keys);
			
			for (i in 0...keys.length)
				assertTrue(h.has(keys[i]));
			
			ArrayTools.shuffle(keys);
			
			for (i in 0...keys.length)
				assertTrue(h.remove(keys[i]));
		}
		
		assertEquals(100, j);
	}
	
	function testCollision()
	{
		var s = 128;
		var h = new IntHashSet(s);
		for (i in 0...s)
		{
			h.set(i * s);
		}
		
		assertEquals(s, h.size);
		
		for (i in 0...s)
		{
			assertTrue(h.remove(i * s));
		}
		
		assertEquals(0, h.size);
		
		for (i in 0...s)
		{
			h.set(i * s);
		}
		
		assertEquals(s, h.size);
		
		for (i in 0...s)
		{
			assertTrue(h.remove(i * s));
		}
		
		assertEquals(0, h.size);
	}
	
	function testFind()
	{
		var h = new IntHashSet(16);
		
		for (i in 0...100)
		{
			for (i in 0...16)
				h.set(i);
			
			for (i in 0...16)
				assertTrue(h.has(i));
			
			for (i in 0...16)
				assertTrue(h.remove(i));
		}
	}
	
	function testResize1()
	{
		var h = new IntHashSet(8);
		h.growthRate = GrowthRate.DOUBLE;
		
		for (i in 0...8) h.set(i);
		assertTrue(h.size == h.capacity);
		
		h.set(8);
		assertEquals(9, h.size);
		
		for (i in 0...8 + 1) assertTrue(h.has(i));
		for (i in 9...16) h.set(i);
		assertTrue(h.size == h.capacity);
		
		for (i in 0...16) assertTrue(h.has(i));
		var i = 16;
		while (i-- > 0) assertTrue(h.remove(i));
		assertTrue(h.isEmpty());
		
		for (i in 0...16) h.set(i);
		assertTrue(h.size == h.capacity);
		for (i in 0...16) assertTrue(h.has(i));
	}
	
	function testClone()
	{
		var h = new IntHashSet(8);
		for (i in 0...8) h.set(i);
		
		var c:IntHashSet = cast h.clone(true);
		
		var i = 0;
		var l = new Dll<Int>();
		for (key in c)
		{
			l.append(key);
			i++;
		}
		
		l.sort(function(a, b) { return a - b; } );
		
		var a:Array<Int> = l.toArray();
		for (i in 0...a.length)
			assertEquals(i, a[i]);
		
		assertEquals(8, i);
	}
	
	function testToArray()
	{
		var h = new IntHashSet(8);
		for (i in 0...8) h.set(i);
		
		var a = h.toArray();
		
		var values = [0, 1, 2, 3, 4, 5, 6, 7];
		for (i in a)
		{
			var found = false;
			for (j in 0...8)
			{
				if (values[j] == i)
				{
					values.remove(i);
					found = true;
				}
			}
			
			assertTrue(found);
		}
		
		assertEquals(0, values.length);
		
		var a = h.toArray();
		var values = [0, 1, 2, 3, 4, 5, 6, 7];
		for (i in a)
		{
			var found = false;
			for (j in 0...8)
			{
				if (values[j] == i)
				{
					values.remove(i);
					found = true;
				}
			}
			
			assertTrue(found);
		}
		
		assertEquals(0, values.length);
		
		var a = h.toArray();
		
		var values = [0, 1, 2, 3, 4, 5, 6, 7];
		for (i in a)
		{
			var found = false;
			for (j in 0...8)
			{
				if (values[j] == i)
				{
					values.remove(i);
					found = true;
				}
			}
			
			assertTrue(found);
		}
		
		assertEquals(0, values.length);
		
		var a = h.toArray();
		
		var values = [0, 1, 2, 3, 4, 5, 6, 7];
		for (i in a)
		{
			var found = false;
			for (j in 0...8)
			{
				if (values[j] == i)
				{
					values.remove(i);
					found = true;
				}
			}
			
			assertTrue(found);
		}
		
		assertEquals(0, values.length);
	}
	
	function testClear()
	{
		var h = new IntHashSet(8);
		for (i in 0...8) h.set(i);
		h.clear();
		
		var c = 0;
		for (i in h) c++;
		assertEquals(c, 0);
		
		var h = new IntHashSet(8);
		h.growthRate = GrowthRate.DOUBLE;
		for (i in 0...8) h.set(i);
		assertEquals(8, h.capacity);
		for (i in 8...16) h.set(i);
		assertEquals(16, h.capacity);
		
		h.clear();
		assertEquals(16, h.capacity);
		assertTrue(h.isEmpty());
		for (i in 0...16) assertFalse(h.has(i));
	}
	
	function testIterator()
	{
		var h = new IntHashSet(8);
		for (i in 0...8) h.set(i);
		
		var a = new Array<Int>();
		
		for (key in h)
		{
			assertFalse(contains(a, key));
			a.push(key);
		}
		
		assertEquals(8, a.length);
		
		for (i in 0...8)
		{
			contains(a, i);
		}
		
		var h = new IntHashSet(8);
		var c = 0;
		for (key in h)
		{
			c++;
		}
		
		assertEquals(0, c);
		
		var h = new IntHashSet(8);
		for (i in 0...8) h.set(i);
		
		var a = new Array<Int>();
		var itr = h.iterator();
		while (itr.hasNext())
		{
			itr.hasNext();
			var key = itr.next();
			assertFalse(contains(a, key));
			a.push(key);
		}
		assertEquals(8, a.length);
		
		for (i in 0...8) contains(a, i);
		
		var h = new IntHashSet(8);
		var c = 0;
		var itr = h.iterator();
		while (itr.hasNext())
		{
			itr.hasNext();
			itr.next();
			c++;
		}
		
		assertEquals(0, c);
	}
	
	function testIter()
	{
		var h = new IntHashSet(4);
		for (i in 0...8) h.set(i);
		var i = 0;
		h.iter(function(v) assertEquals(i++, v));
	}
}