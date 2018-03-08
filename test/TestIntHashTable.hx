import de.polygonal.ds.tools.ArrayTools;
import de.polygonal.ds.Dll;
import de.polygonal.ds.IntIntHashTable;
import de.polygonal.ds.IntHashTable;
import de.polygonal.ds.ListSet;
import de.polygonal.ds.HashableItem;
import de.polygonal.ds.tools.GrowthRate;

class TestIntHashTable extends AbstractTest
{
	function new()
	{
		super();
		#if (flash && alchemy)
		de.polygonal.ds.tools.mem.MemoryManager.free();
		#end
	}
	
	function testPack()
	{
		var h = new IntHashTable<Int>(4, 16);
		h.growthRate = GrowthRate.DOUBLE;
		
		assertEquals(16, h.capacity);
		
		for (i in 0...32) assertTrue(h.set(i, i));
		for (i in 0...16) h.remove(i);
		
		assertEquals(16, h.size);
		assertEquals(32, h.capacity);
		for (i in 16...32) assertTrue(h.has(i));
		
		h.pack(); //32->16
		
		assertEquals(16, h.size);
		assertEquals(16, h.capacity);
		
		for (i in 16...32) assertTrue(h.has(i));
		
		h.free();
		
		var h = new IntHashTable<Int>(4, 4);
		h.growthRate = GrowthRate.NORMAL;
		
		for (i in 0...8) h.set(i, i);
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
	
	function testGetFront()
	{
		var h = new IntHashTable<Null<Int>>(16, 16);
		for (i in 0...4)
		{
			h.set(i, i);
			assertEquals(i, h.getFront(i));
		}
		
		for (i in 0...4) assertEquals(i, h.getFront(i));
		assertEquals(#if (cpp && generic) 0 #else cast null #end, h.getFront(5));
	}
	
	function testRehash()
	{
		var h = new IntHashTable<Null<Int>>(4);
		for (i in 0...16) h.set(i, i);
		
		h.rehash(32);
		
		for (i in 0...16) assertEquals(i, h.get(i));
		
		var h = new IntHashTable<Null<Int>>(4, 4);
		for (i in 0...8) h.set(i, i);
		
		h.rehash(512);
		
		assertEquals(8, h.size);
		assertEquals(8, h.capacity);
		
		for (i in 0...8) assertEquals(i, h.get(i));
	}
	
	function testRemap()
	{
		var h = new IntHashTable<Null<Int>>(4, 4);
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
		
		assertTrue(h.contains(13));
		assertTrue(h.contains(12));
		assertTrue(h.contains(11));
		assertTrue(h.contains(10));
		
		assertEquals(13, h.get(3));
		assertEquals(12, h.get(2));
		assertEquals(11, h.get(1));
		assertEquals(10, h.get(0));
	}
	
	function testSetFirst()
	{
		var h = new IntHashTable<Null<Int>>(4);
		
		for (i in 0...32)
		{
			assertTrue(h.setIfAbsent(i, i));
			assertFalse(h.setIfAbsent(i, i));
		}
		
		for (i in 0...32)
			assertFalse(h.setIfAbsent(i, i));
		
		assertEquals(32, h.size);
	}
	
	function test()
	{
		var h = new IntHashTable<E>(16);
		var key = 0;
		var keys = new Array<Int>();
		
		for (i in 0...32)
		{
			keys.push(key);
			h.set(key, new E(i));
			key++;
		}
		
		for (i in 0...32)
		{
			assertEquals(i, h.get(keys[i]).value);
		}
		
		for (i in 0...24)
		{
			assertTrue(h.unset(keys.pop()));
		}
		for (i in 0...8)
		{
			assertTrue(h.hasKey(keys[i]));
		}
		
		for (i in 0...32 - 24)
		{
			assertTrue(h.unset(keys.pop()));
		}
	}
	
	function testToKeySet()
	{
		var h = new IntHashTable<Int>(16);
		h.set(0, 10);
		h.set(1, 20);
		h.set(2, 30);
		h.set(2, 40);
		
		var s = h.toKeySet();
		assertEquals(3, s.size);
		
		assertTrue(s.has(0));
		assertTrue(s.has(1));
		assertTrue(s.has(2));
	}
	
	function testToValSet()
	{
		var h = new IntHashTable<Int>(16, 16);
		h.set(0, 10);
		h.set(1, 20);
		h.set(2, 30);
		h.set(3, 40);
		h.set(4, 40);
		
		var s = h.toValSet();
		assertEquals(4, s.size);
		assertTrue(s.has(10));
		assertTrue(s.has(20));
		assertTrue(s.has(30));
		assertTrue(s.has(40));
	}
	
	function testHas()
	{
		var h = new IntHashTable<Null<Int>>(16, 16);
		h.set(0, 0);
		h.set(1, 1);
		h.set(2, 2);
		
		assertTrue(h.has(0));
		assertTrue(h.has(1));
		assertTrue(h.has(2));
		
		h.unset(2);
		
		assertTrue(h.has(1));
		assertTrue(h.has(0));
		
		h.unset(1);
		
		assertTrue(h.has(0));
		
		h.unset(0);
		
		assertFalse(h.has(0));
		assertFalse(h.has(1));
		assertFalse(h.has(2));
		
		h.set(0, 3);
		h.set(1, 3);
		
		assertTrue(h.has(3));
		
		h.unset(0);
		
		assertTrue(h.has(3));
		
		h.unset(1);
		
		assertFalse(h.has(3));
	}
	
	function testGetAll()
	{
		var h = new IntHashTable<Int>(16, 16);
		assertEquals(0, h.getAll(1, []));
		h.set(1, 1);
		assertEquals(0, h.getAll(2, []));
		
		var a = [];
		for (i in 0...5)
		{
			var h = new IntHashTable<Int>(16, 16);
			
			for (j in 0...i) h.set(1, j);
			
			var count = h.getAll(1, a);
			assertEquals(i, count);
			
			var set = new ListSet<Int>();
			for (i in 0...count) set.set(i);
			for (j in 0...i)
				assertTrue(set.remove(j));
			assertTrue(set.isEmpty());
		}
		
		var h = new IntHashTable<Int>(16, 16);
		
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
	
	function testSize2()
	{
		var h = new IntHashTable<Null<Int>>(4, 2);
		for (i in 0...3)
		{
			h.set(0, 0);
			h.set(1, 1);
			
			assertEquals(0, h.get(0));
			assertEquals(1, h.get(1));
			assertEquals(2, h.size);
			
			assertTrue(h.unset(0));
			
			assertEquals(#if (cpp && generic) 0 #else cast null #end, h.get(0));
			assertEquals(1, h.get(1));
			assertEquals(1, h.size);
			
			assertTrue(h.unset(1));
			
			assertEquals(#if (cpp && generic) 0 #else cast null #end, h.get(0));
			assertEquals(#if (cpp && generic) 0 #else cast null #end, h.get(1));
			assertEquals(0, h.size);
		}
	}
	
	function testSize3()
	{
		var h = new IntHashTable<Null<Int>>(4, 3);
		for (i in 0...3)
		{
			h.set(0, 0);
			h.set(1, 1);
			h.set(2, 2);
			
			assertEquals(0, h.get(0));
			assertEquals(1, h.get(1));
			assertEquals(2, h.get(2));
			assertEquals(3, h.size);
			
			assertTrue(h.unset(0));
			
			assertEquals(#if (cpp && generic) 0 #else cast null #end, h.get(0));
			assertEquals(1, h.get(1));
			assertEquals(2, h.get(2));
			assertEquals(2, h.size);
			
			assertTrue(h.unset(1));
			
			assertEquals(#if (cpp && generic) 0 #else cast null #end, h.get(0));
			assertEquals(#if (cpp && generic) 0 #else cast null #end, h.get(1));
			assertEquals(2, h.get(2));
			assertEquals(1, h.size);
			
			assertTrue(h.unset(2));
			
			assertEquals(#if (cpp && generic) 0 #else cast null #end, h.get(0));
			assertEquals(#if (cpp && generic) 0 #else cast null #end, h.get(1));
			assertEquals(#if (cpp && generic) 0 #else cast null #end, h.get(2));
			assertEquals(0, h.size);
		}
	}
	
	function testResizeSmall()
	{
		var h = new IntHashTable<Null<Int>>(16, 2);
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
			
			assertEquals(3, h.size);
			assertEquals(4, h.capacity);
			
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
			
			for (i in 0...8)
			{
				keys.push(key); h.set(key, key); key++;
			}
			for (i in keys) assertEquals(i, h.get(i));
			assertEquals(16, h.size);
			assertEquals(16, h.capacity);
			
			for (i in 0...12)
				assertTrue(h.unset(keys.pop()));
			
			h.pack();
			
			assertEquals(4, h.capacity);
			assertEquals(4, h.size);
			
			for (i in keys) assertEquals(i, h.get(i));
			
			for (i in 0...2) assertTrue(h.unset(keys.pop()));
			
			h.pack();
			
			assertEquals(2, h.capacity);
			assertEquals(2, h.size);
			for (i in keys) assertEquals(i, h.get(i));
			
			assertTrue(h.unset(keys.pop()));
			assertTrue(h.unset(keys.pop()));
			
			h.pack();
			
			assertEquals(2, h.capacity);
			assertEquals(0, h.size);
			assertTrue(h.isEmpty());
		}
	}
	
	function testDuplicateKeys()
	{
		var h = new IntHashTable<Null<Int>>(16, 32);
		for (i in 0...2)
		{
			h.set(0, 1);
			h.set(0, 2);
			h.set(0, 3);
			
			h.set(1, 1);
			h.set(1, 2);
			h.set(1, 3);
			
			assertEquals(1, h.get(0));
			assertTrue(h.unset(0));
			assertEquals(2, h.get(0));
			assertTrue(h.unset(0));
			assertEquals(3, h.get(0));
			assertTrue(h.unset(0));
			assertFalse(h.hasKey(0));
			assertEquals(#if (cpp && generic) 0 #else cast null #end, h.get(0));
			
			assertEquals(1, h.get(1));
			assertTrue(h.unset(1));
			assertEquals(2, h.get(1));
			assertTrue(h.unset(1));
			assertEquals(3, h.get(1));
			assertTrue(h.unset(1));
			assertFalse(h.hasKey(1));
			assertEquals(#if (cpp && generic) 0 #else cast null #end, h.get(1));
		}
	}
	
	function testRemove()
	{
		var h = new IntHashTable<Null<Int>>(16, 32);
		
		for (j in 0...2)
		{
			for (i in 0...10)
			{
				h.set(0, i);
			}
			
			assertTrue(h.hasKey(0));
			
			while (h.unset(0)) {}
			
			assertFalse(h.hasKey(0));
			
			assertFalse(h.contains(0));
			assertTrue(h.isEmpty());
		}
	}
	
	function testInsertRemoveFind()
	{
		var h = new de.polygonal.ds.IntHashTable<Null<Int>>(16);
		
		//everything to key #2
		h.set(34, 1);
		h.set(50, 2);
		h.set(66, 3);
		
		assertEquals(3, h.get(66));
		assertEquals(1, h.get(34));
		assertEquals(2, h.get(50));
		
		assertTrue(h.unset(34));
		assertTrue(h.unset(50));
		assertTrue(h.unset(66));
		
		assertFalse(h.unset(34));
		assertFalse(h.unset(50));
		assertFalse(h.unset(66));
	}
	
	function testInsertRemoveRandom1()
	{
		var h = new IntHashTable<Null<Int>>(16);
		
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
			assertTrue(h.unset(keys[i]));
		}
	}
	
	function testInsertRemoveRandom2()
	{
		var h = new IntHashTable<Null<Int>>(16);
		
		initPrng();
		
		for (i in 0...100)
		{
			var keys = new Array<Int>();
			for (i in 0...8)
			{
				var x = Std.int(prand()) & (64 - 1);
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
				assertTrue(h.unset(keys[i]));
			}
			
			ArrayTools.shuffle(keys);
		}
	}
	
	function testInsertRemoveRandom3()
	{
		var h = new IntHashTable<Null<Int>>(16);
		
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
				assertTrue(h.unset(keys[i]));
			}
		}
		
		assertEquals(100, j);
	}
	
	function testCollision()
	{
		var s = 128;
		var h = new IntHashTable<Null<Int>>(s);
		for (i in 0...s)
		{
			h.set(i * s, i);
		}
		
		assertEquals(s, h.size);
		
		for (i in 0...s)
		{
			assertTrue(h.unset(i * s));
		}
		
		assertEquals(0, h.size);
		
		for (i in 0...s)
		{
			h.set(i * s, i);
		}
		
		assertEquals(s, h.size);
		
		for (i in 0...s)
		{
			assertTrue(h.unset(i * s));
		}
		
		assertEquals(0, h.size);
	}
	
	function testFind()
	{
		var h = new IntHashTable<Null<Int>>(16);
		
		for (i in 0...100)
		{
			for (i in 0...16)
				h.setIfAbsent(i, i);
			
			for (i in 0...16)
				assertEquals(i, h.get(i));
			
			for (i in 0...16)
				assertTrue(h.unset(i));
		}
	}
	
	function testFindToFront()
	{
		var h = new IntHashTable<Null<Int>>(16);
		
		for (i in 0...100)
		{
			for (i in 0...16)
				h.set(i, i);
			
			for (i in 0...16) assertEquals(i, h.getFront(i));
			for (i in 0...16) assertEquals(i, h.getFront(i));
			for (i in 0...16) assertEquals(i, h.getFront(i));
			
			for (i in 0...16)
				assertTrue(h.unset(i));
		}
	}
	
	function testResize1()
	{
		var h = new IntHashTable<Null<Int>>(8);
		
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
		var h = new IntHashTable<Int>(8);
		for (i in 0...8) h.set(i, i);
		
		var c:IntHashTable<Int> = cast h.clone(true);
		
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
		{
			assertEquals(i, a[i]);
		}
		
		assertEquals(8, i);
	}
	
	function testToArray()
	{
		var h = new IntHashTable<Null<Int>>(8);
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
	}
	
	function testToKeyArray()
	{
		var h = new IntHashTable<Null<Int>>(8);
		for (i in 0...8) h.set(i, i * 10);
		
		var a = h.toKeyArray();
		
		var keys = [0, 1, 2, 3, 4, 5, 6, 7];
		for (i in a)
		{
			for (j in 0...8)
			{
				if (keys[j] == i)
				{
					keys.remove(i);
				}
			}
		}
		
		assertEquals(0, keys.length);
	}
	
	function testClear()
	{
		var h = new IntHashTable<Null<Int>>(8);
		h.set(1, 1);
		h.set(2, 2);
		h.set(3, 3);
		h.set(4, 4);
		h.clear();
		var c = 0;
		for (value in h) c++;
		assertEquals(0, c);
		h.set(1, 1);
		h.set(2, 2);
		h.set(3, 3);
		h.set(4, 4);
		var c = 0;
		for (value in h) c++;
		assertEquals(4, c);
		
		var h = new IntHashTable<Null<Int>>(8);
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
		
		for (i in 0...16)
			assertEquals(i, h.get(i));
	}
	
	function testIterator()
	{
		var h = new IntHashTable<Int>(8);
		for (i in 0...8) h.set(i, i * 10);
		
		var set = new Array<Int>();
		for (val in h)
		{
			assertFalse(contains(set, val));
			set.push(val);
		}
		
		assertEquals(8, set.length);
		
		for (i in 0...8)
		{
			assertTrue(contains(set, i * 10));
		}
		
		var h = new IntHashTable<Int>(8);
		var c = 0;
		for (val in h)
		{
			c++;
		}
		
		assertEquals(0, c);
	}
	
	function testIter()
	{
		var h = new IntHashTable<Int>(4);
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
}

private class E extends HashableItem
{
	public var value:Int;
	
	public function new(value:Int)
	{
		super();
		this.value = value;
	}
	
	function toString():String
	{
		return "item_" + value;
	}
}