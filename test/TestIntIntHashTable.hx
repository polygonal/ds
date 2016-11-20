import de.polygonal.ds.Dll;
import de.polygonal.ds.HashableItem;
import de.polygonal.ds.IntIntHashTable;
import de.polygonal.ds.ListSet;
import de.polygonal.ds.mem.MemoryManager;
import de.polygonal.ds.tools.ArrayTools;
import de.polygonal.ds.tools.GrowthRate;

class TestIntIntHashTable extends AbstractTest
{
	function new()
	{
		super();
		#if (flash && alchemy)
		MemoryManager.free();
		#end
	}
	
	function test()
	{
		var h = new IntIntHashTable(16);
		var key = 0;
		var keys = new Array<Int>();
		
		for (i in 0...32)
		{
			keys.push(key);
			h.set(key, i);
			key++;
		}
		
		for (i in 0...32)
		{
			assertEquals(i, h.get(keys[i]));
		}
		
		for (i in 0...24)
		{
			assertTrue(h.remove(keys.pop()));
		}
		
		for (i in 0...8)
		{
			assertTrue(h.hasKey(keys[i]));
		}
		
		for (i in 0...32 - 24)
		{
			assertTrue(h.remove(keys.pop()));
		}
	}
	
	function testClr()
	{
		var h = new IntIntHashTable(16);
		h.set(1, 1);
		h.set(1, 2);
		h.set(1, 3);
		
		assertTrue(h.unset(1));
		//assertTrue(h.unset(2));
		assertFalse(h.contains(1));
		
		//trace(h.extract(1));
		//trace(h.extract(3));
		
		//assertFalse(h.contains(2));
		//assertFalse(h.contains(3));
	}
	
	function testSetIfAbsent()
	{
		var h = new IntIntHashTable(4, 100);
		
		for (i in 0...32)
		{
			assertTrue(h.setIfAbsent(i, i));
			assertFalse(h.setIfAbsent(i, i));
		}
		
		for (i in 0...32)
			assertFalse(h.setIfAbsent(i, i));
		
		assertEquals(32, h.size);
	}
	
	function testToValSet()
	{
		var h = new IntIntHashTable(16, 16);
		h.set(0, 0);
		h.set(1, 1);
		h.set(2, 2);
		h.set(2, 3);
		
		var s = h.toKeySet();
		assertEquals(3, s.size);
		
		assertTrue(s.has(0));
		assertTrue(s.has(1));
		assertTrue(s.has(2));
	}
	
	function testToKeySet()
	{
		var h = new IntIntHashTable(16, 16);
		h.set(0, 0);
		h.set(1, 1);
		h.set(2, 2);
		h.set(3, 2);
		
		var s = h.toValSet();
		assertEquals(3, s.size);
		
		assertTrue(s.has(0));
		assertTrue(s.has(1));
		assertTrue(s.has(2));
	}
	
	function testHas()
	{
		var h = new IntIntHashTable(16, 16);
		h.set(0, 0);
		h.set(1, 1);
		h.set(2, 2);
		
		assertTrue(h.has(0));
		assertTrue(h.has(1));
		assertTrue(h.has(2));
		
		clrAll(h,2);
		
		assertTrue(h.has(1));
		assertTrue(h.has(0));
		
		clrAll(h, 1);
		
		assertTrue(h.has(0));
		
		clrAll(h, 0);
		
		assertFalse(h.has(0));
		assertFalse(h.has(1));
		assertFalse(h.has(2));
		
		h.set(0, 3);
		h.set(1, 3);
		
		assertTrue(h.has(3));
		
		clrAll(h, 0);
		
		assertTrue(h.has(3));
		
		clrAll(h, 1);
		
		assertFalse(h.has(3));
	}
	
	function testGetAll()
	{
		var h = new IntIntHashTable(16, 16);
		assertEquals(0, h.getAll(1, []));
		h.set(1, 1);
		assertEquals(0, h.getAll(2, []));
		
		var a = [];
		for (i in 0...5)
		{
			var h = new IntIntHashTable(16, 16);
			
			for (j in 0...i) h.set(1, j);
			
			var count = h.getAll(1, a);
			assertEquals(i, count);
			
			var set = new ListSet<Int>();
			for (i in 0...count) set.set(i);
			for (j in 0...i)
				assertTrue(set.remove(j));
			assertTrue(set.isEmpty());
		}
		
		var h = new IntIntHashTable(16, 16);
		
		h.set(1, 10);
		h.set(1, 11);
		h.set(1, 12);
		
		h.set(2, 20);
		h.set(2, 21);
		h.set(2, 22);
		
		h.set(3, 30);
		h.set(3, 31);
		h.set(3, 32);
		
		var a = [];
		assertEquals(3, h.getAll(1, a));
		assertTrue(ArrayTools.equals(a, [10, 11, 12]));
		
		var b = [];
		assertEquals(3, h.getAll(2, b));
		assertTrue(ArrayTools.equals(b, [20, 21, 22]));
		
		var c = [];
		assertEquals(3, h.getAll(3, c));
		assertTrue(ArrayTools.equals(c, [30, 31, 32]));
	}
	
	function testRemap()
	{
		var h = new IntIntHashTable(4, 4);
		h.set(0, 0);
		h.set(1, 1);
		h.set(2, 2);
		h.set(3, 3);
		
		assertTrue(h.remap(3, 13));
		assertTrue(h.remap(2, 12));
		assertTrue(h.remap(1, 11));
		assertTrue(h.remap(0, 10));
		
		assertTrue(h.hasKey(3));
		assertTrue(h.hasKey(2));
		assertTrue(h.hasKey(1));
		assertTrue(h.hasKey(0));
		
		assertEquals(13, h.get(3));
		assertEquals(12, h.get(2));
		assertEquals(11, h.get(1));
		assertEquals(10, h.get(0));
		
		var h = new IntIntHashTable(4, 4);
		h.set(1, 1);
		h.set(1, 2);
		h.set(1, 3);
		
		assertTrue(h.remap(1, 5));
		
		assertEquals(5, h.get(1));
		h.unset(1);
		assertEquals(2, h.get(1));
		h.unset(1);
		assertEquals(3, h.get(1));
		h.unset(1);
		
		assertTrue(h.isEmpty());
		
		h.set(0, 1);
		h.set(4, 2);
		h.set(8, 3);
		
		assertTrue(h.remap(0, 2));
		assertTrue(h.remap(4, 3));
		assertTrue(h.remap(8, 4));
		assertFalse(h.remap(9, 4));
	}
	
	function testRehash()
	{
		var h = new IntIntHashTable(4, 4);
		for (i in 0...8) h.set(i, i);
		
		h.rehash(512);
		
		assertEquals(8, h.size);
		assertEquals(8, h.capacity);
		assertEquals(512, h.slotCount);
		
		for (i in 0...8) assertEquals(i, h.get(i));
	}
	
	function testSize2()
	{
		var h = new IntIntHashTable(4, 2);
		
		for (i in 0...3)
		{
			h.set(0, 0);
			h.set(1, 1);
			
			assertEquals(0, h.get(0));
			assertEquals(1, h.get(1));
			assertEquals(2, h.size);
			
			assertTrue(h.remove(0));
			
			var x:Int = IntIntHashTable.KEY_ABSENT;
			
			assertEquals(x, h.get(0));
			assertEquals(1, h.get(1));
			assertEquals(1, h.size);
			
			assertTrue(h.remove(1));
			
			assertEquals(x, h.get(0));
			assertEquals(x, h.get(1));
			assertEquals(0, h.size);
		}
	}
	
	function testSize3()
	{
		var h = new IntIntHashTable(4, 3);
		
		for (i in 0...3)
		{
			h.set(0, 0);
			h.set(1, 1);
			h.set(2, 2);
			
			var x:Int = IntIntHashTable.KEY_ABSENT;
			
			assertEquals(0, h.get(0));
			assertEquals(1, h.get(1));
			assertEquals(2, h.get(2));
			assertEquals(3, h.size);
			
			assertTrue(h.remove(0));
			
			assertEquals(x, h.get(0));
			assertEquals(1, h.get(1));
			assertEquals(2, h.get(2));
			assertEquals(2, h.size);
			
			assertTrue(h.remove(1));
			
			assertEquals(x, h.get(0));
			assertEquals(x, h.get(1));
			assertEquals(2, h.get(2));
			assertEquals(1, h.size);
			
			
			assertTrue(h.remove(2));
			
			assertEquals(x, h.get(0));
			assertEquals(x, h.get(1));
			assertEquals(x, h.get(2));
			assertEquals(0, h.size);
		}
	}
	
	function testResizeSmall()
	{
		var h = new IntIntHashTable(16, 2);
		h.growthRate = GrowthRate.DOUBLE;
		var keys = new Array<Int>();
		var key = 0;
		
		for (i in 0...2)
		{
			keys.push(key); h.set(key, key); key++;
			keys.push(key); h.set(key, key); key++;
			assertEquals(2, h.size);
			assertEquals(2, h.capacity);
			for (i in keys) assertEquals(i, h.get(i));
			
			keys.push(key); h.set(key, key); key++;
			for (i in keys) assertEquals(i, h.get(i));
			
			//2/4
			assertEquals(3, h.size);
			assertEquals(4, h.capacity);
			
			//4/4
			keys.push(key); h.set(key, key); key++;
			for (i in keys) assertEquals(i, h.get(i));
			assertEquals(4, h.size);
			assertEquals(4, h.capacity);
			
			for (i in 0...4)
			{
				keys.push(key); h.set(key, key); key++;
			}
			for (i in keys) assertEquals(i, h.get(i));
			assertEquals(8, h.size);
			assertEquals(8, h.capacity);
			//8/8
			
			for (i in 0...8)
			{
				keys.push(key); 
				h.set(key, key);
				key++;
			}
			for (i in keys) assertEquals(i, h.get(i));
			
			assertEquals(16, h.size);
			assertEquals(16, h.capacity);
			//16/16
			
			//4/16 -> //4/8
			for (i in 0...12) assertTrue(h.remove(keys.pop()));
			
			h.pack();
			
			assertEquals(4, h.capacity);
			assertEquals(4, h.size);
			for (i in keys) assertEquals(i, h.get(i));
			//4/4
			
			for (i in 0...2) assertTrue(h.remove(keys.pop()));
			h.pack();
			
			//2/4
			assertEquals(2, h.capacity);
			assertEquals(2, h.size);
			for (i in keys) assertEquals(i, h.get(i));
			
			assertTrue(h.remove(keys.pop()));
			assertTrue(h.remove(keys.pop()));
			
			h.pack();
			
			assertEquals(2, h.capacity);
			assertEquals(0, h.size);
			assertTrue(h.isEmpty());
		}
	}
	
	function testDuplicateKeys()
	{
		var h = new IntIntHashTable(16, 32);
		
		for (i in 0...2)
		{
			h.set(0, 1);
			h.set(0, 2);
			h.set(0, 3);
			
			h.set(1, 1);
			h.set(1, 2);
			h.set(1, 3);
			
			assertEquals(1, h.get(0));
			assertTrue(h.unset(0) );
			assertEquals(2, h.get(0));
			assertTrue(h.unset(0) );
			assertEquals(3, h.get(0));
			assertTrue(h.unset(0) );
			assertFalse(h.hasKey(0));
			assertTrue(h.get(0) == IntIntHashTable.KEY_ABSENT);
			
			assertEquals(1, h.get(1));
			assertTrue(h.unset(1) );
			assertEquals(2, h.get(1));
			assertTrue(h.unset(1) );
			assertEquals(3, h.get(1));
			assertTrue(h.unset(1) );
			assertFalse(h.hasKey(1));
			assertTrue(h.get(1) == IntIntHashTable.KEY_ABSENT);
		}
	}
	
	function testRemove()
	{
		var h = new IntIntHashTable(16, 32);
		
		h.set(0, 1);
		h.set(1, 1);
		h.set(2, 1);
		h.set(3, 1);
		h.set(4, 1);
		
		assertTrue(h.remove(1));
		assertFalse(h.has(1));
		
		var h = new IntIntHashTable(16, 32);
		
		for (j in 0...2)
		{
			for (i in 0...10)
			{
				h.set(0, i);
			}
			
			assertTrue(h.hasKey(0));
			
			clrAll(h, 0);
			
			assertFalse(h.hasKey(0));
			assertTrue(h.isEmpty());
		}
	}
	
	function testExtract()
	{
		var h = new IntIntHashTable(16, 32);
		
		for (j in 0...2)
		{
			for (i in 0...10)
			{
				h.set(i, i);
			}
			
			for (i in 0...10)
			{
				assertEquals(i, h.extract(i));
			}
		}
	}
	
	function testInsertRemoveFind()
	{
		var h = new de.polygonal.ds.IntIntHashTable(16);
		
		//everything to key #2
		h.set(34, 1);
		h.set(50, 2);
		h.set(66, 3);
		
		assertEquals(3, h.get(66));
		assertEquals(1, h.get(34));
		assertEquals(2, h.get(50));
		
		assertTrue(clrAll(h,34));
		assertTrue(clrAll(h,50));
		assertTrue(clrAll(h,66));
		
		assertFalse(clrAll(h,34));
		assertFalse(clrAll(h,50));
		assertFalse(clrAll(h,66));
	}
	
	function testInsertRemoveRandom1()
	{
		var h = new IntIntHashTable(16);
		
		var K = [17, 25, 10, 2, 8, 24, 30, 3];
		
		var keys = new Array<Int>();
		for (i in 0...K.length)
		{
			keys.push(K[i]);
		}
		
		for (i in 0...keys.length)
		{
			h.set(keys[i], i);
		}
		
		ArrayTools.shuffle(keys);
		
		for (i in 0...keys.length)
		{
			assertTrue(clrAll(h, (keys[i])));
		}
	}
	
	function testInsertRemoveRandom2()
	{
		var h = new IntIntHashTable(16);
		
		initPrng();
		
		for (i in 0...100)
		{
			var keys = new Array<Int>();
			for (i in 0...8)
			{
				var x = Std.int(prand()) % 64;
				while (contains(keys, x))
				{
					x = Std.int(prand()) % 64;
				}
				
				keys.push(x);
			}
			
			for (i in 0...keys.length)
			{
				h.set(keys[i], i);
			}
			
			ArrayTools.shuffle(keys);
			
			for (i in 0...keys.length)
			{
				assertTrue(clrAll(h, keys[i]));
			}
			
			ArrayTools.shuffle(keys);
		}
	}
	
	function testInsertRemoveRandom3()
	{
		var h = new IntIntHashTable(16);
		
		initPrng();
		
		var j = 0;
		for (i in 0...100)
		{
			j++;
			var keys = new Array<Int>();
			for (i in 0...8)
			{
				var x = Std.int(prand()) % 64;
				while (contains(keys, x)) x = Std.int(prand()) % 64;
				
				keys.push(x);
			}
			
			for (i in 0...keys.length)
			{
				h.set(keys[i], i);
			}
			
			ArrayTools.shuffle(keys);
			
			for (i in 0...keys.length)
			{
				assertTrue(h.get(keys[i]) != IntIntHashTable.KEY_ABSENT);
			}
			
			ArrayTools.shuffle(keys);
			
			for (i in 0...keys.length)
			{
				assertTrue(clrAll(h, keys[i]));
			}
		}
		
		assertEquals(100, j);
	}
	
	function testCollision()
	{
		var s = 128;
		var h = new IntIntHashTable(s);
		for (i in 0...s)
		{
			h.set(i * s, i);
		}
		
		assertEquals(s, h.size);
		
		for (i in 0...s)
		{
			assertTrue(clrAll(h, i * s));
		}
		
		assertEquals(0, h.size);
		
		for (i in 0...s)
		{
			h.set(i * s, i);
		}
		
		assertEquals(s, h.size);
		
		for (i in 0...s)
		{
			assertTrue(clrAll(h, i * s));
		}
		
		assertEquals(0, h.size);
	}
	
	function testFind()
	{
		var h = new IntIntHashTable(16);
		
		for (i in 0...100)
		{
			for (i in 0...16)
				h.set(i, i);
			
			for (i in 0...16)
				assertEquals(i, h.get(i));
			
			for (i in 0...16)
				assertTrue(h.remove(i));
		}
	}
	
	function testSetFirst()
	{
		var h = new IntIntHashTable(4, 4);
		
		//force hash collision
		assertTrue(h.set(0, 1));
		assertTrue(h.set(4, 2));
		assertTrue(h.set(8, 3));
	}
	
	function testFindToFront()
	{
		var h = new IntIntHashTable(16);
		
		initPrng();
		
		for (i in 0...100)
		{
			for (i in 0...16)
				h.set(i, i);
			
			for (i in 0...16) assertEquals(i, h.getFront(i));
			for (i in 0...16) assertEquals(i, h.getFront(i));
			for (i in 0...16) assertEquals(i, h.getFront(i));
			
			for (i in 0...16)
				assertTrue(h.remove(i));
		}
	}
	
	function testResize1()
	{
		var h = new IntIntHashTable(8);
		h.growthRate = GrowthRate.DOUBLE;
		
		for (i in 0...8) h.set(i, i);
		assertTrue(h.size == h.capacity);
		
		h.set(8, 8);
		
		assertEquals(9, h.size);
		
		for (i in 0...8 + 1)
		{
			assertEquals(i, h.get(i));
		}
		for (i in 9...16)
		{
			h.set(i, i);
		}
		
		assertTrue(h.size == h.capacity);
		
		for (i in 0...16)
		{
			assertEquals(i, h.get(i));
		}
		var i = 16;
		while (i-- > 0)
		{
			if (h.size == 4)
			{
				return;
			}
			
			assertTrue(h.remove(i));
		}
		
		assertTrue(h.isEmpty());
		
		for (i in 0...16) h.set(i, i);
		assertTrue(h.size == h.capacity);
		for (i in 0...16) assertEquals(i, h.get(i));
	}
	
	function testClone()
	{
		var h = new IntIntHashTable(8);
		for (i in 0...8) h.set(i, i);
		
		var c:IntIntHashTable = cast h.clone(true);
		for (i in 0...8) assertTrue(h.has(i));
		for (i in 0...8) assertEquals(i, h.get(i));
		assertEquals(8, c.size);
		assertEquals(8, c.capacity);
		assertEquals(8, Lambda.count(c));
		var keys = [];
		for (key in c)
		{
			keys.push(key);
		}
		keys.sort(function(a, b) return a - b);
		for (i in 0...keys.length)
			assertEquals(i, keys[i]);
	}
	
	function testToArray()
	{
		var h = new IntIntHashTable(8);
		for (i in 0...8) h.set(i, i);
		
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
	
	function testPack()
	{
		var h = new IntIntHashTable(4, 16);
		h.growthRate = GrowthRate.DOUBLE;
		assertEquals(16, h.capacity);
		
		for (i in 0...32) assertTrue(h.set(i, i));
		for (i in 0...16) assertTrue(h.unset(i));
		
		assertEquals(16, h.size);
		assertEquals(32, h.capacity);
		for (i in 16...32) assertTrue(h.hasKey(i));
		
		h.pack(); //32->16
		
		assertEquals(16, h.size);
		assertEquals(16, h.capacity);
		
		for (i in 16...32) assertTrue(h.hasKey(i));
		for (i in 16...32) assertTrue(h.has(i));
		
		h.free();
		
		var h = new IntIntHashTable(4, 4);
		h.growthRate = GrowthRate.NORMAL;
		
		for (i in 0...8) h.set(i, i);
		for (i in 0...8) assertTrue(h.hasKey(i));
		for (i in 0...8) assertTrue(h.has(i));
		
		for (i in 0...6) h.unset(i);
		assertEquals(2, h.size);
		assertEquals(11, h.capacity);
		
		h.pack();
		assertEquals(2, h.size);
		assertEquals(4, h.capacity);
		assertTrue(h.hasKey(6));
		assertTrue(h.has(6));
		assertTrue(h.hasKey(7));
		assertTrue(h.has(7));
	}
	
	function testClear()
	{
		var h = new IntIntHashTable(8);
		for (i in 0...8) h.set(i, i);
		h.clear();
		var c = 0;
		for (i in h) c++;
		assertEquals(0, c);
		
		var h = new IntIntHashTable(8);
		h.growthRate = GrowthRate.DOUBLE;
		for (i in 0...8) h.set(i, i);
		assertEquals(8, h.capacity);
		for (i in 8...16) h.set(i, i);
		assertEquals(16, h.capacity);
		
		h.clear();
		
		assertEquals(16, h.capacity);
		assertEquals(0, h.size);
		assertTrue(h.isEmpty());
		
		for (i in 0...16) h.set(i, i);
		assertEquals(16, h.capacity);
		for (i in 0...16) assertEquals(i, h.get(i));
	}
	
	function testIterator()
	{
		var h = new IntIntHashTable(8);
		for (i in 0...8) h.set(i, i * 10);
		
		var set = new Array<Int>();
		for (val in h)
		{
			assertFalse(contains(set, val));
			set.push(val);
		}
		assertEquals(8, set.length);
		for (i in 0...8) assertTrue(contains(set, i * 10));
		
		var set = new Array<Int>();
		for (key in h.keys())
		{
			assertFalse(contains(set, key));
			set.push(key);
		}
		assertEquals(8, set.length);
		for (i in 0...8) assertTrue(contains(set, i));
		
		var h = new IntIntHashTable(8);
		var c = 0;
		for (x in h)
		{
			c++;
		}
		
		assertEquals(0, c);
	}
	
	function testIter()
	{
		var h = new IntIntHashTable(4);
		for (i in 0...8) h.set(i, i * 10);
		var i = 0;
		h.iter(
			function(k, v)
			{
				assertEquals(i, k);
				assertEquals(i * 10, v);
				i++;
			});
	}
	
	function testCount()
	{
		var h = new IntIntHashTable(8);
		
		h.set(0, 0);
		assertEquals(1, h.count(0));
		
		h.set(0, 1);
		assertEquals(2, h.count(0));
		
		h.set(0, 2);
		assertEquals(3, h.count(0));
	}
	
	function testGetDuplicateKeys()
	{
		var h = new IntIntHashTable(8);
		h.set(0, 0);
		h.set(1, 1);
		h.set(2, 2);
		assertEquals(0, h.get(0));
	}
	
	function testunsetPair()
	{
		var values = [20, 30, 40];
		
		for (order in ArrayTools.quickPerm(3))
		{
			var h = new IntIntHashTable(16);
			for (i in values) h.set(10, i);
			var size = 3;
			for (i in order)
			{
				assertEquals(true, h.unsetPair(10, values[i - 1]));
				assertEquals(--size, h.size);
			}
		}
	}
	
	function clrAll(h:IntIntHashTable, key:Int):Bool
	{
		var forEach = 0;
		
		if (h.unset(key))
		{
			while (h.unset(key))
			{
				if (forEach++ > 1000) throw 'bail out';
			}
			return true;
		}
		return false;
	}
}

class HashableFoo extends HashableItem
{
	function new()
	{
		super();
	}
}