package;

import de.polygonal.core.math.random.ParkMiller;
import de.polygonal.ds.ArrayUtil;
import de.polygonal.ds.DA;
import de.polygonal.ds.DLL;
import de.polygonal.ds.HashableItem;
import de.polygonal.ds.HashTable;
import de.polygonal.ds.IntIntHashTable;

class TestHashTable extends haxe.unit.TestCase
{
	function new()
	{
		super();
		#if (flash10 && alchemy)
		de.polygonal.ds.mem.MemoryManager.free();
		#end
	}
	
	function testGetFront()
	{
		var h = new HashTable<E, Null<Int>>(16, 16, true);
		
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
		assertEquals(8, h.size());
		assertEquals(8, h.getCapacity());
		
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
	
	function testSetFirst()
	{
		var items = new Array<E>();
		for (i in 0...32) items.push(new E(i));
		
		var h = new HashTable<E, Null<Int>>(4);
		for (i in 0...32)
		{
			assertTrue(h.setIfAbsent(items[i], i));
			assertFalse(h.setIfAbsent(items[i], i));
		}
		
		for (i in 0...32) assertFalse(h.setIfAbsent(items[i], i));
		
		assertEquals(32, h.size());
	}
	
	function test()
	{
		var items = new Array<E>();
		for (i in 0...32) items.push(new E(i));
		
		var h = new HashTable<E, Null<Int>>(16);
		for (i in 0...32) h.set(items[i], i);
		for (i in 0...32) assertEquals(i, h.get(items[i]));
		for (i in 0...24) assertTrue(h.clr(items.pop()));
		for (i in 0...8) assertTrue(h.hasKey(items[i]));
		for (i in 0...32 - 24) assertTrue(h.clr(items.pop()));
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
		assertEquals(3, s.size());
		
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
		assertEquals(4, s.size());
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
		
		h.clr(items[2]);
		
		assertTrue(h.has(1));
		assertTrue(h.has(0));
		
		h.clr(items[1]);
		
		assertTrue(h.has(0));
		
		h.clr(items[0]);
		
		assertFalse(h.has(0));
		assertFalse(h.has(1));
		assertFalse(h.has(2));
		
		h.set(items[0], 3);
		h.set(items[1], 3);
		
		assertTrue(h.has(3));
		
		h.clr(items[0]);
		
		assertTrue(h.has(3));
		
		h.clr(items[1]);
		
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
		assertTrue(ArrayUtil.equals(a, [1]));
		
		h.set(key, 2);
		
		var a = [];
		assertEquals(2, h.getAll(key, a));
		assertTrue(ArrayUtil.equals(a, [1, 2]));
		
		h.set(key, 3);
		
		var a = [];
		assertEquals(3, h.getAll(key, a));
		assertTrue(ArrayUtil.equals(a, [1, 2, 3]));
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
			assertEquals(2, h.size());
			
			assertTrue(h.clr(items[0]));
			
			assertEquals(null, h.get(items[0]));
			assertEquals(1, h.get(items[1]));
			assertEquals(1, h.size());
			
			assertTrue(h.clr(items[1]));
			
			assertEquals(null, h.get(items[0]));
			assertEquals(null, h.get(items[1]));
			assertEquals(0, h.size());
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
			assertEquals(3, h.size());
			
			assertTrue(h.clr(items[0]));
			
			assertEquals(null, h.get(items[0]));
			assertEquals(1, h.get(items[1]));
			assertEquals(2, h.get(items[2]));
			assertEquals(2, h.size());
			
			assertTrue(h.clr(items[1]));
			
			assertEquals(null, h.get(items[0]));
			assertEquals(null, h.get(items[1]));
			assertEquals(2, h.get(items[2]));
			assertEquals(1, h.size());
			
			assertTrue(h.clr(items[2]));
			
			assertEquals(null, h.get(items[0]));
			assertEquals(null, h.get(items[1]));
			assertEquals(null, h.get(items[2]));
			assertEquals(0, h.size());
		}
	}
	
	function testResizeSmall()
	{
		var h = new HashTable<E, E>(16, 2);
		
		var items = new Array<E>();
		
		for (i in 0...2)
		{
			var item = new E(0);
			items.push(item);
			h.set(item, item);
			
			var item = new E(0);
			items.push(item);
			h.set(item, item);
			
			assertEquals(2, h.size());
			assertEquals(2, h.getCapacity());
			for (i in items) assertEquals(i, h.get(i));
			
			var item = new E(0);
			items.push(item);
			h.set(item, item);
			for (i in items) assertEquals(i, h.get(i));
			
			assertEquals(3, h.size());
			assertEquals(4, h.getCapacity());
			
			var item = new E(0);
			items.push(item);
			h.set(item, item);
			for (i in items) assertEquals(i, h.get(i));
			
			assertEquals(4, h.size());
			assertEquals(4, h.getCapacity());
			
			for (i in 0...4)
			{
				var item = new E(0);
				items.push(item);
				h.set(item, item);
			}
			for (i in items) assertEquals(i, h.get(i));
			assertEquals(8, h.size());
			assertEquals(8, h.getCapacity());
			
			for (i in 0...8)
			{
				var item = new E(0);
				items.push(item);
				h.set(item, item);
			}
			for (i in items) assertEquals(i, h.get(i));
			assertEquals(16, h.size());
			assertEquals(16, h.getCapacity());
			
			for (i in 0...12)
				assertTrue(h.clr(items.pop()));
			assertEquals(8, h.getCapacity());
			assertEquals(4, h.size());
			for (i in items) assertEquals(i, h.get(i));
			
			for (i in 0...2) assertTrue(h.clr(items.pop()));
			
			assertEquals(4, h.getCapacity());
			assertEquals(2, h.size());
			for (i in items) assertEquals(i, h.get(i));
			
			assertTrue(h.clr(items.pop()));
			assertTrue(h.clr(items.pop()));
			
			assertEquals(2, h.getCapacity());
			assertEquals(0, h.size());
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
			assertTrue(h.clr(items[0]));
			assertEquals(2, h.get(items[0]));
			assertTrue(h.clr(items[0]));
			assertEquals(3, h.get(items[0]));
			assertTrue(h.clr(items[0]));
			assertFalse(h.hasKey(items[0]));
			assertEquals(null, h.get(items[0]));
			
			assertEquals(1, h.get(items[1]));
			assertTrue(h.clr(items[1]));
			assertEquals(2, h.get(items[1]));
			assertTrue(h.clr(items[1]));
			assertEquals(3, h.get(items[1]));
			assertTrue(h.clr(items[1]));
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
			
			while (h.clr(items[0])) {}
			
			assertFalse(h.hasKey(items[0]));
			
			assertFalse(h.contains(0));
			assertTrue(h.isEmpty());
		}
	}
	
	function testInsertRemoveFind()
	{
		var h = new HashTable<E, Null<Int>>(16);
		
		var a = new E(1);
		untyped a.key = 34;
		
		var b = new E(2);
		untyped a.key = 50;
		
		var c = new E(3);
		untyped a.key = 66;
		
		//everything to key #2
		h.set(a, 1);
		h.set(b, 2);
		h.set(c, 3);
		
		assertEquals(3, h.get(c));
		assertEquals(1, h.get(a));
		assertEquals(2, h.get(b));
		
		assertTrue(h.clr(a));
		assertTrue(h.clr(b));
		assertTrue(h.clr(c));
		
		assertFalse(h.clr(a));
		assertFalse(h.clr(b));
		assertFalse(h.clr(c));
	}
	
	function testInsertRemoveRandom1()
	{
		var h = new HashTable<E, Null<Int>>(16);
		
		var K = [17, 25, 10, 2, 8, 24, 30, 3];
		
		var items = new DA<E>();
		var keys = new DA<Int>();
		for (i in 0...K.length)
		{
			keys.pushBack(K[i]);
			
			var item = new E(i);
			untyped item.key = K[i];
			items.pushBack(item);
		}
		
		for (i in 0...items.size())
			h.set(items.get(i), i);
		
		items.shuffle();
		
		for (i in 0...items.size())
			assertTrue(h.clr(items.get(i)));
	}
	
	function testInsertRemoveRandom2()
	{
		var h = new HashTable<E, Null<Int>>(16);
		
		var seed = new ParkMiller(1);
		
		for (i in 0...100)
		{
			var items = new DA<E>();
			var keys = new DA<Int>();
			for (i in 0...8)
			{
				var x = Std.int(seed.random()) & (64 - 1);
				while (keys.contains(x)) x = Std.int(seed.random()) % 64;
				keys.pushBack(x);
				
				var item = new E(i);
				untyped item.key = x;
				
				items.pushBack(item);
			}
			
			for (i in 0...keys.size())
				h.set(items.get(i), i);
			
			items.shuffle();
			
			for (i in 0...keys.size())
				assertTrue(h.clr(items.get(i)));
			
			items.shuffle();
		}
	}
	
	function testInsertRemoveRandom3()
	{
		var h = new HashTable<E, Null<Int>>(16);
		
		var seed = new ParkMiller(1);
		
		var j = 0;
		for (i in 0...100)
		{
			j++;
			var items = new DA<E>();
			var keys = new DA<Int>();
			for (i in 0...8)
			{
				var x = Std.int(seed.random()) & (64 - 1);
				while (keys.contains(x)) x = Std.int(seed.random()) % 64;
				keys.pushBack(x);
				
				var item = new E(i);
				untyped item.key = x;
				
				items.pushBack(item);
			}
			
			for (i in 0...keys.size())
				h.set(items.get(i), i);
			
			items.shuffle();
			
			for (i in 0...keys.size())
				assertTrue(h.get(items.get(i)) != IntIntHashTable.KEY_ABSENT);
			
			items.shuffle();
			
			for (i in 0...keys.size())
				assertTrue(h.clr(items.get(i)));
		}
		
		assertEquals(100, j);
	}
	
	function testCollision()
	{
		var items = new Array<E>();
		for (i in 0...128) items.push(new E(i));
		
		var s = 128;
		var h = new HashTable<E, Null<Int>>(s);
		for (i in 0...s)
		{
			var item = items[i];
			untyped item.key = i * 2;
			h.set(item, i);
		}
		
		assertEquals(s, h.size());
		
		for (i in 0...s)
			assertTrue(h.clr(items[i]));
		
		assertEquals(0, h.size());
		
		for (i in 0...s)
			h.set(items[i], i);
		
		assertEquals(s, h.size());
		
		for (i in 0...s)
			assertTrue(h.clr(items[i]));
		
		assertEquals(0, h.size());
	}
	
	function testFind()
	{
		var h = new HashTable<E, Null<Int>>(16);
		var items = new Array<E>();
		for (i in 0...16) items.push(new E(i));
		
		var seed = new ParkMiller(1);
		for (i in 0...100)
		{
			for (i in 0...16) h.setIfAbsent(items[i], i);
			for (i in 0...16) assertEquals(i, h.get(items[i]));
			for (i in 0...16) assertTrue(h.clr(items[i]));
		}
	}
	
	function testFindToFront()
	{
		var items = new Array<E>();
		for (i in 0...32) items.push(new E(i));
		
		var h = new HashTable<E, Null<Int>>(16);
		var seed = new ParkMiller(1);
		
		for (i in 0...100)
		{
			for (i in 0...16) h.set(items[i], i);
			
			for (i in 0...16) assertEquals(i, h.getFront(items[i]));
			for (i in 0...16) assertEquals(i, h.getFront(items[i]));
			for (i in 0...16) assertEquals(i, h.getFront(items[i]));
			
			for (i in 0...16)
				assertTrue(h.clr(items[i]));
		}
	}
	
	function testResize1()
	{
		var items = new Array<E>();
		for (i in 0...32) items.push(new E(i));
		
		var h = new HashTable<E, Null<Int>>(8);
		
		for (i in 0...8) h.set(items[i], i);
		assertTrue(h.size() == h.getCapacity());
		
		h.set(items[8], 8);
		
		assertEquals(9, h.size());
		
		for (i in 0...8 + 1) assertEquals(i, h.get(items[i]));
		
		for (i in 9...16) h.set(items[i], i);
		
		assertTrue(h.size() == h.getCapacity());
		
		for (i in 0...16) assertEquals(i, h.get(items[i]));
		var i = 16;
		while (i-- > 0)
		{
			if (h.size() == 4) return;
			assertTrue(h.remove(i));
		}
		
		assertTrue(h.isEmpty());
		
		for (i in 0...16) h.set(items[i], i);
		assertTrue(h.size() == h.getCapacity());
		for (i in 0...16) assertEquals(i, h.get(items[i]));
	}
	
	function testClone()
	{
		var items = new Array<E>();
		for (i in 0...8) items.push(new E(i));
		
		var h = new HashTable<E, Null<Int>>(8);
		for (i in 0...8) h.set(items[i], i);
		
		var c:HashTable<E, Int> = cast h.clone(true);
		
		var i = 0;
		var l = new DLL<Int>();
		for (val in c)
		{
			l.append(val);
			i++;
		}
		
		l.sort(function(a, b) { return a - b; } );
		
		var a:Array<Int> = l.toArray();
		assertEquals(8, a.length);
		for (i in 0...a.length) assertEquals(i, a[i]);
		assertEquals(8, i);
	}
	
	function testToArrayToDA()
	{
		var items = new DA<E>();
		for (i in 0...8) items.pushBack(new E(i));
		
		var h = new HashTable<E, Null<Int>>(8);
		for (i in 0...8) h.set(items.get(i), i);
		
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
	
	function testToKeyArrayToDA()
	{
		var items = new DA<E>();
		for (i in 0...8) items.pushBack(new E(i));
		
		var tmp:DA<E> = cast items.clone(true);
		
		var h = new HashTable<E, Null<Int>>(8);
		for (i in 0...8) h.set(items.get(i), i * 10);
		
		var a = h.toKeyArray();
		assertEquals(8, a.length);
		for (i in a)
		{
			for (j in 0...8)
			{
				if (items.get(j) == i)
				{
					items.remove(i);
					break;
				}
			}
		}
		
		assertEquals(0, items.size());
		items = tmp;
		var a = h.toKeyDA();
		for (i in a)
		{
			for (j in 0...8)
			{
				if (items.get(j) == i)
				{
					items.remove(i);
					break;
				}
			}
		}
		
		assertEquals(0, items.size());
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
		assertEquals(8, h.getCapacity());
		for (i in 8...16) h.set(items[i], i);
		assertEquals(16, h.getCapacity());
		
		h.clear();
		
		assertEquals(16, h.getCapacity());
		
		assertEquals(0, h.size());
		assertTrue(h.isEmpty());
		
		for (i in 0...16) h.set(items[i], i);
		assertEquals(16, h.getCapacity());
		
		for (i in 0...16)
			assertEquals(i, h.get(items[i]));
			
		//test with purge
		var items = new Array<E>();
		for (i in 0...16) items.push(new E(i));
		
		var h = new HashTable<E, Null<Int>>(8);
		for (i in 0...16) h.set(items[i], i);
		h.clear(true);
		
		assertEquals(8, h.getCapacity());
		assertEquals(0, h.size());
		
		for (i in 0...16) h.set(items[i], i);
		assertEquals(16, h.getCapacity());
		for (i in 0...16) assertEquals(i, h.get(items[i]));
		
		h.clear(true);
		
		for (i in 0...16) h.set(items[i], i);
		assertEquals(16, h.getCapacity());
		for (i in 0...16) assertEquals(i, h.get(items[i]));
	}
	
	function testValIterator()
	{
		var items = new Array<E>();
		for (i in 0...16) items.push(new E(i));
		
		var h = new HashTable<E, Null<Int>>(8);
		
		for (i in 0...8) h.set(items[i], i * 10);
		
		var set = new DA<Int>();
		var i = 0;
		for (val in h)
		{
			assertFalse(set.contains(val));
			set.pushBack(val);
		}
		
		assertEquals(8, set.size());
		
		for (i in 0...8) assertTrue(set.contains(i * 10));
		
		var h = new HashTable<E, Null<Int>>(8);
		var c = 0;
		for (val in h) c++;
		
		assertEquals(0, c);
	}
	
	function testKeyIterator()
	{
		var items = new Array<E>();
		for (i in 0...16) items.push(new E(i));
		
		var h = new HashTable<E, Null<Int>>(8);
		
		for (i in 0...8) h.set(items[i], i * 10);
		
		var set = new DA<E>();
		var i = 0;
		for (key in h.keys())
		{
			assertFalse(set.contains(key));
			set.pushBack(key);
		}
		
		assertEquals(8, set.size());
		
		for (i in 0...8) assertTrue(set.contains(items[i]));
		
		var h = new HashTable<E, Null<Int>>(8);
		var c = 0;
		for (key in h.keys()) c++;
		assertEquals(0, c);
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
		return 'item_' + value;
	}
}