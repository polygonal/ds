import de.polygonal.ds.tools.ArrayTools;
import de.polygonal.ds.HashableItem;
import de.polygonal.ds.HashTable;
import de.polygonal.ds.IntIntHashTable;
import de.polygonal.ds.tools.GrowthRate;

class TestHashTable extends AbstractTest
{
	function new()
	{
		super();
		#if (flash && alchemy)
		de.polygonal.ds.tools.mem.MemoryManager.free();
		#end
	}
	
	function testGetFront()
	{
		var h = new HashTable<E, Null<Int>>(16, 16);
		
		var items = new Array<E>();
		for (i in 0...5) items.push(new E(i));
		
		for (i in 0...4)
		{
			h.set(items[i], i);
			assertEquals(i, h.getFront(items[i]));
			
		}
		for (i in 0...4)
			assertEquals(i, h.getFront(items[i]));
		
		items.push(new E(5));
		assertEquals(null, h.getFront(items[5]));
	}
	
	function testRehash()
	{
		var items = new Array<E>();
		for (i in 0...16) items.push(new E(i));
		
		var h = new HashTable<E, Null<Int>>(4);
		for (i in 0...16) h.set(items[i], i);
		
		h.rehash(32);
		
		for (i in 0...16) assertEquals(i, h.get(items[i]));
		
		var h = new HashTable<E, Null<Int>>(4, 4);
		for (i in 0...8) h.set(items[i], i);
		
		h.rehash(512);
		assertEquals(8, h.size);
		assertEquals(8, h.capacity);
		
		for (i in 0...8) assertEquals(i, h.get(items[i]));
	}
	
	function testRemap()
	{
		var items = new Array<E>();
		for (i in 0...4) items.push(new E(i));
		
		var h = new HashTable<E, Null<Int>>(4, 4);
		h.set(items[0], 0);
		h.set(items[1], 1);
		h.set(items[2], 2);
		h.set(items[3], 3);
		
		assertTrue(h.remap(items[3], 13));
		assertTrue(h.remap(items[2], 12));
		assertTrue(h.remap(items[1], 11));
		assertTrue(h.remap(items[0], 10));
		
		assertTrue(h.hasKey(items[3]));
		assertTrue(h.hasKey(items[2]));
		assertTrue(h.hasKey(items[1]));
		assertTrue(h.hasKey(items[0]));
		
		assertTrue(h.contains(13));
		assertTrue(h.contains(12));
		assertTrue(h.contains(11));
		assertTrue(h.contains(10));
		
		assertEquals(13, h.get(items[3]));
		assertEquals(12, h.get(items[2]));
		assertEquals(11, h.get(items[1]));
		assertEquals(10, h.get(items[0]));
	}
	
	function testPack()
	{
		var keys = new Array<E>();
		for (i in 0...32) keys.push(new E(i));
		
		var h = new HashTable<E, Null<Int>>(16, 16);
		for (i in 0...16) h.set(keys[i], i);
		for (i in 0...16) assertTrue(h.has(i));
		
		assertEquals(16, h.size);
		assertEquals(16, h.capacity);
		for (i in 0...12) assertTrue(h.remove(i));
		h.pack();
		assertEquals(4, h.size);
		assertEquals(16, h.capacity);
		
		var h = new HashTable<E, Null<Int>>(16, 4);
		for (i in 0...8) h.set(keys[i], i);
		for (i in 0...8) assertTrue(h.has(i));
		assertEquals(8, h.size);
		assertEquals(8, h.capacity);
		for (i in 0...6) assertTrue(h.remove(i));
		
		h.pack();
		assertEquals(2, h.size);
		assertEquals(4, h.capacity);
		
		assertTrue(h.has(6));
		assertTrue(h.has(7));
		
		var h = new HashTable<E, Null<Int>>(16, 2);
		for (i in 0...16) h.set(keys[i], i);
		for (i in 0...16)
		{
			h.remove(i);
			h.pack();
			assertEquals(Math.max(2, 16 - (i + 1)), h.capacity);
			for (j in i + 1...16)
			{
				assertTrue(h.hasKey(keys[j]));
				assertTrue(h.has(j));
			}
		}
	}
	
	function testSetFirst()
	{
		var items = new Array<E>();
		for (i in 0...32) items.push(new E(i));
		
		var h = new HashTable<E, Null<Int>>(4, 4);
		for (i in 0...32)
		{
			assertTrue(h.setIfAbsent(items[i], i));
			assertFalse(h.setIfAbsent(items[i], i));
		}
		
		for (i in 0...32) assertFalse(h.setIfAbsent(items[i], i));
		
		assertEquals(32, h.size);
	}
	
	function test()
	{
		var items = new Array<E>();
		for (i in 0...32) items.push(new E(i));
		
		var h = new HashTable<E, Null<Int>>(16);
		for (i in 0...32) h.set(items[i], i);
		for (i in 0...32) assertEquals(i, h.get(items[i]));
		for (i in 0...24) assertTrue(h.unset(items.pop()));
		for (i in 0...8) assertTrue(h.hasKey(items[i]));
		for (i in 0...32 - 24) assertTrue(h.unset(items.pop()));
	}
	
	function testToKeySet()
	{
		var items = new Array<E>();
		for (i in 0...32) items.push(new E(i));
		
		var h = new HashTable<E, Null<Int>>(16);
		h.set(items[0], 10);
		h.set(items[1], 20);
		h.set(items[2], 30);
		h.set(items[2], 40);
		
		var s = h.toKeySet();
		assertEquals(3, s.size);
		
		assertTrue(s.has(items[0]));
		assertTrue(s.has(items[1]));
		assertTrue(s.has(items[2]));
	}
	
	function testToValSet()
	{
		var items = new Array<E>();
		for (i in 0...16) items.push(new E(i));
		
		var h = new HashTable<E, Null<Int>>(16, 16);
		h.set(items[0], 10);
		h.set(items[1], 20);
		h.set(items[2], 30);
		h.set(items[3], 40);
		h.set(items[4], 40);
		
		var s = h.toValSet();
		assertEquals(4, s.size);
		assertTrue(s.has(10));
		assertTrue(s.has(20));
		assertTrue(s.has(30));
		assertTrue(s.has(40));
	}
	
	function testHas()
	{
		var items = new Array<E>();
		for (i in 0...16) items.push(new E(i));
		
		var h = new HashTable<E, Null<Int>>(16, 16);
		h.set(items[0], 0);
		h.set(items[1], 1);
		h.set(items[2], 2);
		
		assertTrue(h.has(0));
		assertTrue(h.has(1));
		assertTrue(h.has(2));
		
		h.unset(items[2]);
		
		assertTrue(h.has(1));
		assertTrue(h.has(0));
		
		h.unset(items[1]);
		
		assertTrue(h.has(0));
		
		h.unset(items[0]);
		
		assertFalse(h.has(0));
		assertFalse(h.has(1));
		assertFalse(h.has(2));
		
		h.set(items[0], 3);
		h.set(items[1], 3);
		
		assertTrue(h.has(3));
		
		h.unset(items[0]);
		
		assertTrue(h.has(3));
		
		h.unset(items[1]);
		
		assertFalse(h.has(3));
	}
	
	function testGetAll()
	{
		var h = new HashTable<E, Int>(16, 16);
		var key = new E(1);
		
		var a = [];
		assertEquals(0, h.getAll(key, a));
		
		h.set(key, 1);
		
		var a = [];
		assertEquals(1, h.getAll(key, a));
		assertTrue(ArrayTools.equals(a, [1]));
		
		h.set(key, 2);
		
		var a = [];
		assertEquals(2, h.getAll(key, a));
		assertTrue(ArrayTools.equals(a, [1, 2]));
		
		h.set(key, 3);
		
		var a = [];
		assertEquals(3, h.getAll(key, a));
		assertTrue(ArrayTools.equals(a, [1, 2, 3]));
	}
	
	function testSize2()
	{
		var items = new Array<E>();
		for (i in 0...16) items.push(new E(i));
		
		var h = new HashTable<E, Null<Int>>(4, 2);
		
		for (i in 0...3)
		{
			h.set(items[0], 0);
			h.set(items[1], 1);
			
			assertEquals(0, h.get(items[0]));
			assertEquals(1, h.get(items[1]));
			assertEquals(2, h.size);
			
			assertTrue(h.unset(items[0]));
			
			assertEquals(null, h.get(items[0]));
			assertEquals(1, h.get(items[1]));
			assertEquals(1, h.size);
			
			assertTrue(h.unset(items[1]));
			
			assertEquals(null, h.get(items[0]));
			assertEquals(null, h.get(items[1]));
			assertEquals(0, h.size);
		}
	}
	
	function testSize3()
	{
		var items = new Array<E>();
		for (i in 0...16) items.push(new E(i));
		
		var h = new HashTable<E, Null<Int>>(4, 3);
		
		for (i in 0...3)
		{
			h.set(items[0], 0);
			h.set(items[1], 1);
			h.set(items[2], 2);
			
			assertEquals(0, h.get(items[0]));
			assertEquals(1, h.get(items[1]));
			assertEquals(2, h.get(items[2]));
			assertEquals(3, h.size);
			
			assertTrue(h.unset(items[0]));
			
			assertEquals(null, h.get(items[0]));
			assertEquals(1, h.get(items[1]));
			assertEquals(2, h.get(items[2]));
			assertEquals(2, h.size);
			
			assertTrue(h.unset(items[1]));
			
			assertEquals(null, h.get(items[0]));
			assertEquals(null, h.get(items[1]));
			assertEquals(2, h.get(items[2]));
			assertEquals(1, h.size);
			
			assertTrue(h.unset(items[2]));
			
			assertEquals(null, h.get(items[0]));
			assertEquals(null, h.get(items[1]));
			assertEquals(null, h.get(items[2]));
			assertEquals(0, h.size);
		}
	}
	
	function testResizeSmall()
	{
		var h = new HashTable<E, E>(16, 2);
		h.growthRate = GrowthRate.DOUBLE;
		
		var items = new Array<E>();
		
		for (i in 0...2)
		{
			var item = new E(0);
			items.push(item);
			h.set(item, item);
			
			var item = new E(0);
			items.push(item);
			h.set(item, item);
			
			assertEquals(2, h.size);
			assertEquals(2, h.capacity);
			for (i in items) assertEquals(i, h.get(i));
			
			var item = new E(0);
			items.push(item);
			h.set(item, item);
			for (i in items) assertEquals(i, h.get(i));
			
			assertEquals(3, h.size);
			assertEquals(4, h.capacity);
			
			var item = new E(0);
			items.push(item);
			h.set(item, item);
			for (i in items) assertEquals(i, h.get(i));
			
			assertEquals(4, h.size);
			assertEquals(4, h.capacity);
			
			for (i in 0...4)
			{
				var item = new E(0);
				items.push(item);
				h.set(item, item);
			}
			for (i in items) assertEquals(i, h.get(i));
			assertEquals(8, h.size);
			assertEquals(8, h.capacity);
			
			for (i in 0...8)
			{
				var item = new E(0);
				items.push(item);
				h.set(item, item);
			}
			for (i in items) assertEquals(i, h.get(i));
			assertEquals(16, h.size);
			assertEquals(16, h.capacity);
			
			for (i in 0...12)
				assertTrue(h.unset(items.pop()));
			
			h.pack();
			
			assertEquals(4, h.capacity);
			assertEquals(4, h.size);
			for (i in items) assertEquals(i, h.get(i));
			
			for (i in 0...2) assertTrue(h.unset(items.pop()));
			
			h.pack();
			
			assertEquals(2, h.capacity);
			assertEquals(2, h.size);
			for (i in items) assertEquals(i, h.get(i));
			
			assertTrue(h.unset(items.pop()));
			assertTrue(h.unset(items.pop()));
			
			h.pack();
			
			assertEquals(2, h.capacity);
			assertEquals(0, h.size);
			assertTrue(h.isEmpty());
		}
	}
	
	function testDuplicateKeys()
	{
		var h = new HashTable<E, Null<Int>>(16, 32);
		
		var items = new Array<E>();
		for (i in 0...16) items.push(new E(i));
		
		for (i in 0...2)
		{
			h.set(items[0], 1);
			h.set(items[0], 2);
			h.set(items[0], 3);
			
			h.set(items[1], 1);
			h.set(items[1], 2);
			h.set(items[1], 3);
			
			assertEquals(1, h.get(items[0]));
			assertTrue(h.unset(items[0]));
			assertEquals(2, h.get(items[0]));
			assertTrue(h.unset(items[0]));
			assertEquals(3, h.get(items[0]));
			assertTrue(h.unset(items[0]));
			assertFalse(h.hasKey(items[0]));
			assertEquals(null, h.get(items[0]));
			
			assertEquals(1, h.get(items[1]));
			assertTrue(h.unset(items[1]));
			assertEquals(2, h.get(items[1]));
			assertTrue(h.unset(items[1]));
			assertEquals(3, h.get(items[1]));
			assertTrue(h.unset(items[1]));
			assertFalse(h.hasKey(items[1]));
			assertEquals(null, h.get(items[1]));
		}
	}
	
	function testRemove()
	{
		var items = new Array<E>();
		for (i in 0...16) items.push(new E(i));
		
		var h = new HashTable<E, Null<Int>>(16, 32);
		
		for (j in 0...2)
		{
			for (i in 0...10)
				h.set(items[0], i);
			
			assertTrue(h.hasKey(items[0]));
			
			while (h.unset(items[0])) {}
			
			assertFalse(h.hasKey(items[0]));
			
			assertFalse(h.contains(0));
			assertTrue(h.isEmpty());
		}
	}
	
	@:access(E)
	function testInsertRemoveFind()
	{
		var h = new HashTable<E, Null<Int>>(16);
		
		var a = new E(1);
		a.key = 34;
		
		var b = new E(2);
		a.key = 50;
		
		var c = new E(3);
		a.key = 66;
		
		//everything to key #2
		h.set(a, 1);
		h.set(b, 2);
		h.set(c, 3);
		
		assertEquals(3, h.get(c));
		assertEquals(1, h.get(a));
		assertEquals(2, h.get(b));
		
		assertTrue(h.unset(a));
		assertTrue(h.unset(b));
		assertTrue(h.unset(c));
		
		assertFalse(h.unset(a));
		assertFalse(h.unset(b));
		assertFalse(h.unset(c));
	}
	
	@:access(E)
	function testInsertRemoveRandom1()
	{
		var h = new HashTable<E, Null<Int>>(16);
		
		var K = [17, 25, 10, 2, 8, 24, 30, 3];
		
		var items = new Array<E>();
		var keys = new Array<Int>();
		for (i in 0...K.length)
		{
			keys.push(K[i]);
			
			var item = new E(i);
			item.key = K[i];
			items.push(item);
		}
		
		for (i in 0...items.length)
			h.set(items[i], i);
		
		ArrayTools.shuffle(items);
		
		for (i in 0...items.length)
			assertTrue(h.unset(items[i]));
	}
	
	@:access(E)
	function testInsertRemoveRandom2()
	{
		var h = new HashTable<E, Null<Int>>(16);
		
		initPrng();
		
		for (i in 0...100)
		{
			var items = new Array<E>();
			var keys = new Array<Int>();
			for (i in 0...8)
			{
				var x = Std.int(prand()) & (64 - 1);
				while (contains(keys, x)) x = Std.int(prand()) % 64;
				keys.push(x);
				
				var item = new E(i);
				item.key = x;
				
				items.push(item);
			}
			
			for (i in 0...keys.length)
				h.set(items[i], i);
			
			ArrayTools.shuffle(items);
			
			for (i in 0...keys.length)
				assertTrue(h.unset(items[i]));
			
			ArrayTools.shuffle(items);
		}
	}
	
	@:access(E)
	function testInsertRemoveRandom3()
	{
		var h = new HashTable<E, Null<Int>>(16);
		
		initPrng();
		
		var j = 0;
		for (i in 0...100)
		{
			j++;
			var items = new Array<E>();
			var keys = new Array<Int>();
			for (i in 0...8)
			{
				var x = Std.int(prand()) & (64 - 1);
				while (contains(keys, x)) x = Std.int(prand()) % 64;
				keys.push(x);
				
				var item = new E(i);
				item.key = x;
				
				items.push(item);
			}
			
			for (i in 0...keys.length)
				h.set(items[i], i);
			
			ArrayTools.shuffle(items);
			
			for (i in 0...keys.length)
				assertTrue(h.get(items[i]) != IntIntHashTable.KEY_ABSENT);
			
			ArrayTools.shuffle(items);
			
			for (i in 0...keys.length)
				assertTrue(h.unset(items[i]));
		}
		
		assertEquals(100, j);
	}
	
	@:access(E)
	function testCollision()
	{
		var items = new Array<E>();
		for (i in 0...128) items.push(new E(i));
		
		var s = 128;
		var h = new HashTable<E, Null<Int>>(s);
		for (i in 0...s)
		{
			var item = items[i];
			item.key = i * 2;
			h.set(item, i);
		}
		
		assertEquals(s, h.size);
		
		for (i in 0...s)
			assertTrue(h.unset(items[i]));
		
		assertEquals(0, h.size);
		
		for (i in 0...s)
			h.set(items[i], i);
		
		assertEquals(s, h.size);
		
		for (i in 0...s)
			assertTrue(h.unset(items[i]));
		
		assertEquals(0, h.size);
	}
	
	function testFind()
	{
		var h = new HashTable<E, Null<Int>>(16);
		var items = new Array<E>();
		for (i in 0...16) items.push(new E(i));
		
		var a = [for (j in 0...16) j];
		for (i in 0...100)
		{
			ArrayTools.shuffle(a);
			for (i in 0...16) assertTrue(h.setIfAbsent(items[a[i]], a[i]));
			for (i in 0...16) assertEquals(a[i], h.get(items[a[i]]));
			for (i in 0...16) assertTrue(h.unset(items[a[i]]));
		}
	}
	
	function testFindToFront()
	{
		var items = new Array<E>();
		for (i in 0...32) items.push(new E(i));
		
		var h = new HashTable<E, Null<Int>>(16);
		initPrng();
		
		for (i in 0...100)
		{
			for (i in 0...16) h.set(items[i], i);
			
			for (i in 0...16) assertEquals(i, h.getFront(items[i]));
			for (i in 0...16) assertEquals(i, h.getFront(items[i]));
			for (i in 0...16) assertEquals(i, h.getFront(items[i]));
			
			for (i in 0...16)
				assertTrue(h.unset(items[i]));
		}
	}
	
	function testResize1()
	{
		var items = new Array<E>();
		for (i in 0...32) items.push(new E(i));
		
		var h = new HashTable<E, Null<Int>>(8);
		
		for (i in 0...8) h.set(items[i], i);
		assertTrue(h.size == h.capacity);
		
		h.set(items[8], 8);
		
		assertEquals(9, h.size);
		
		for (i in 0...8 + 1) assertEquals(i, h.get(items[i]));
		
		for (i in 9...16) h.set(items[i], i);
		
		assertTrue(h.size == h.capacity);
		
		for (i in 0...16) assertEquals(i, h.get(items[i]));
		var i = 16;
		while (i-- > 0)
		{
			if (h.size == 4) return;
			assertTrue(h.remove(i));
		}
		
		assertTrue(h.isEmpty());
		
		for (i in 0...16) h.set(items[i], i);
		assertTrue(h.size == h.capacity);
		for (i in 0...16) assertEquals(i, h.get(items[i]));
	}
	
	function testClone()
	{
		var items = [for (i in 0...8) new E(i)];
		
		var h = new HashTable<E, Null<Int>>(8);
		for (i in 0...8) h.set(items[i], i);
		
		var c:HashTable<E, Null<Int>> = cast h.clone(true);
		
		var i = 0;
		var a = [];
		for (val in c)
		{
			a.push(val);
			i++;
		}
		
		a.sort(function(a, b) return a - b );
		
		assertEquals(8, a.length);
		for (i in 0...a.length) assertEquals(i, a[i]);
		assertEquals(8, i);
	}
	
	function testToArray()
	{
		var items = new Array<E>();
		for (i in 0...8) items.push(new E(i));
		
		var h = new HashTable<E, Null<Int>>(8);
		for (i in 0...8) h.set(items[i], i);
		
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
		
		var a:Array<Int> = h.toArray();
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
	
	function testToKeyArray()
	{
		var items = new Array<E>();
		for (i in 0...8) items.push(new E(i));
		
		var tmp =items.copy();
		
		var h = new HashTable<E, Null<Int>>(8);
		for (i in 0...8) h.set(items[i], i * 10);
		
		var a = h.toKeyArray();
		assertEquals(8, a.length);
		for (i in a)
		{
			for (j in 0...8)
			{
				if (items[j] == i)
				{
					items.remove(i);
					break;
				}
			}
		}
		
		assertEquals(0, items.length);
		items = tmp;
	}
	
	function testClear()
	{
		var items = new Array<E>();
		for (i in 0...16) items.push(new E(i));
		
		var h = new HashTable<E, Null<Int>>(8);
		for (i in 0...8) h.set(items[i], i);
		h.clear();
		var c = 0;
		for (i in h) c++;
		assertEquals(0, c);
		
		for (i in 0...8) h.set(items[i], i);
		var c = 0;
		for (i in h) c++;
		assertEquals(8, c);
		
		var h = new HashTable<E, Null<Int>>(8);
		for (i in 0...8) h.set(items[i], i);
		assertEquals(8, h.capacity);
		for (i in 8...16) h.set(items[i], i);
		assertEquals(16, h.capacity);
		
		h.clear();
		
		assertEquals(16, h.capacity);
		
		assertEquals(0, h.size);
		assertTrue(h.isEmpty());
		
		for (i in 0...16) h.set(items[i], i);
		assertEquals(16, h.capacity);
		
		for (i in 0...16)
			assertEquals(i, h.get(items[i]));
	}
	
	function testValIterator()
	{
		var items = new Array<E>();
		for (i in 0...16) items.push(new E(i));
		
		var h = new HashTable<E, Null<Int>>(8);
		
		for (i in 0...8) h.set(items[i], i * 10);
		
		var set = new Array<Int>();
		for (val in h)
		{
			assertFalse(contains(set, val));
			set.push(val);
		}
		
		assertEquals(8, set.length);
		
		for (i in 0...8) assertTrue(contains(set, i * 10));
		
		var h = new HashTable<E, Null<Int>>(8);
		var c = 0;
		for (val in h) c++;
		
		assertEquals(0, c);
		
		var items = [for (i in 0...16) new E(i)];
		var h = new HashTable<E, Null<Int>>(8);
		for (i in 0...8) h.set(items[i], i * 10);
		
		var set = new Array<Int>();
		
		var itr = h.iterator();
		while (itr.hasNext())
		{
			itr.hasNext();
			var val = itr.next();
			assertFalse(contains(set, val));
			set.push(val);
		}
		
		assertEquals(8, set.length);
		for (i in 0...8) assertTrue(contains(set, i * 10));
		
		var h = new HashTable<E, Null<Int>>(8);
		var c = 0;
		var itr = h.iterator();
		while (itr.hasNext())
		{
			itr.next();
			c++;
		}
		assertEquals(0, c);
	}
	
	function testKeyIterator()
	{
		var items = new Array<E>();
		for (i in 0...16) items.push(new E(i));
		
		var h = new HashTable<E, Null<Int>>(8);
		
		for (i in 0...8) h.set(items[i], i * 10);
		
		var set = new Array<E>();
		for (key in h.keys())
		{
			assertFalse(contains(set, key));
			set.push(key);
		}
		
		assertEquals(8, set.length);
		
		for (i in 0...8) assertTrue(contains(set, items[i]));
		
		var h = new HashTable<E, Null<Int>>(8);
		var c = 0;
		for (key in h.keys()) c++;
		assertEquals(0, c);
		
		var items = [for (i in 0...16) new E(i)];
		var h = new HashTable<E, Null<Int>>(8);
		for (i in 0...8) h.set(items[i], i * 10);
		
		var set = new Array<E>();
		var itr = h.keys();
		while (itr.hasNext())
		{
			itr.hasNext();
			var key = itr.next();
			assertFalse(contains(set, key));
			set.push(key);
		}
		
		assertEquals(8, set.length);
		for (i in 0...8) assertTrue(contains(set, items[i]));
		
		var h = new HashTable<E, Null<Int>>(8);
		var c = 0;
		var itr = h.keys();
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
		var items = [for (i in 0...4) new E(i)];
		var h = new HashTable<E, Null<Int>>(8);
		for (i in 0...4)
		{
			var key = items[i];
			h.set(key, i);
		}
		var i = 0;
		h.iter(
			function(k, v)
			{
				assertEquals(i, k.value);
				assertEquals(i, v);
				i++;
			});
	}
}

private class E extends HashableItem
{
	public var value:Int;
	
	public function new(value:Int)
	{
		super();
		
		this.value = value;
	}
	
	public function toString():String
	{
		return "item_" + value;
	}
}