package;

import de.polygonal.core.math.random.ParkMiller;
import de.polygonal.ds.ArrayConvert;
import de.polygonal.ds.ArrayUtil;
import de.polygonal.ds.DA;
import de.polygonal.ds.DLL;
import de.polygonal.ds.HashableItem;
import de.polygonal.ds.IntIntHashTable;
import de.polygonal.ds.ListSet;
import de.polygonal.ds.mem.MemoryManager;

class TestIntIntHashTable extends haxe.unit.TestCase
{
	function new()
	{
		super();
		#if (flash10 && alchemy)
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
		
		assertTrue(h.clr(1));
		//assertTrue(h.clr(2));
		//assertFalse(h.contains(1));
		
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
		
		assertEquals(32, h.size());
	}
	
	function testToValSet()
	{
		var h = new IntIntHashTable(16, 16);
		h.set(0, 0);
		h.set(1, 1);
		h.set(2, 2);
		h.set(2, 3);
		
		var s = h.toKeySet();
		assertEquals(3, s.size());
		
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
		assertEquals(3, s.size());
		
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
		assertTrue(ArrayUtil.equals(a, [10, 11, 12]));
		
		var b = [];
		assertEquals(3, h.getAll(2, b));
		assertTrue(ArrayUtil.equals(b, [20, 21, 22]));
		
		var c = [];
		assertEquals(3, h.getAll(3, c));
		assertTrue(ArrayUtil.equals(c, [30, 31, 32]));
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
		h.clr(1);
		assertEquals(2, h.get(1));
		h.clr(1);
		assertEquals(3, h.get(1));
		h.clr(1);
		
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
		
		assertEquals(8, h.size());
		assertEquals(8, h.getCapacity());
		
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
			assertEquals(2, h.size());
			
			assertTrue(h.remove(0));
			
			var x:Int = IntIntHashTable.KEY_ABSENT;
			
			assertEquals(x, h.get(0));
			assertEquals(1, h.get(1));
			assertEquals(1, h.size());
			
			assertTrue(h.remove(1));
			
			assertEquals(x, h.get(0));
			assertEquals(x, h.get(1));
			assertEquals(0, h.size());
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
			assertEquals(3, h.size());
			
			assertTrue(h.remove(0));
			
			assertEquals(x, h.get(0));
			assertEquals(1, h.get(1));
			assertEquals(2, h.get(2));
			assertEquals(2, h.size());
			
			assertTrue(h.remove(1));
			
			assertEquals(x, h.get(0));
			assertEquals(x, h.get(1));
			assertEquals(2, h.get(2));
			assertEquals(1, h.size());
			
			
			assertTrue(h.remove(2));
			
			assertEquals(x, h.get(0));
			assertEquals(x, h.get(1));
			assertEquals(x, h.get(2));
			assertEquals(0, h.size());
		}
	}
	
	function testResizeSmall()
	{
		var h = new IntIntHashTable(16, 2);
		var keys = new Array<Int>();
		var key = 0;
		
		for (i in 0...2)
		{
			keys.push(key); h.set(key, key); key++;
			keys.push(key); h.set(key, key); key++;
			assertEquals(2, h.size());
			assertEquals(2, h.getCapacity());
			for (i in keys) assertEquals(i, h.get(i));
			
			keys.push(key); h.set(key, key); key++;
			for (i in keys) assertEquals(i, h.get(i));
			
			assertEquals(3, h.size());
			assertEquals(4, h.getCapacity());
			
			keys.push(key); h.set(key, key); key++;
			for (i in keys) assertEquals(i, h.get(i));
			assertEquals(4, h.size());
			assertEquals(4, h.getCapacity());
			
			for (i in 0...4)
			{
				keys.push(key); h.set(key, key); key++;
			}
			for (i in keys) assertEquals(i, h.get(i));
			assertEquals(8, h.size());
			assertEquals(8, h.getCapacity());
			
			for (i in 0...8)
			{
				keys.push(key); h.set(key, key); key++;
			}
			for (i in keys) assertEquals(i, h.get(i));
			assertEquals(16, h.size());
			assertEquals(16, h.getCapacity());
			
			for (i in 0...12)
				assertTrue(h.remove(keys.pop()));
			assertEquals(8, h.getCapacity());
			assertEquals(4, h.size());
			for (i in keys) assertEquals(i, h.get(i));
			
			for (i in 0...2) assertTrue(h.remove(keys.pop()));
			
			assertEquals(4, h.getCapacity());
			assertEquals(2, h.size());
			for (i in keys) assertEquals(i, h.get(i));
			
			assertTrue(h.remove(keys.pop()));
			assertTrue(h.remove(keys.pop()));
			
			assertEquals(2, h.getCapacity());
			assertEquals(0, h.size());
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
			assertTrue(h.clr(0) );
			assertEquals(2, h.get(0));
			assertTrue(h.clr(0) );
			assertEquals(3, h.get(0));
			assertTrue(h.clr(0) );
			assertFalse(h.hasKey(0));
			assertTrue(h.get(0) == IntIntHashTable.KEY_ABSENT);
			
			assertEquals(1, h.get(1));
			assertTrue(h.clr(1) );
			assertEquals(2, h.get(1));
			assertTrue(h.clr(1) );
			assertEquals(3, h.get(1));
			assertTrue(h.clr(1) );
			assertFalse(h.hasKey(1));
			assertTrue(h.get(1) == IntIntHashTable.KEY_ABSENT);
		}
	}
	
	function testRemove()
	{
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
		
		var keys = new DA<Int>();
		for (i in 0...K.length)
		{
			keys.pushBack(K[i]);
		}
		
		for (i in 0...keys.size())
		{
			h.set(keys.get(i), i);
		}
		
		keys.shuffle();
		
		for (i in 0...keys.size())
		{
			assertTrue(clrAll(h, (keys.get(i))));
		}
	}
	
	function testInsertRemoveRandom2()
	{
		var h = new IntIntHashTable(16);
		
		var seed = new ParkMiller();
		
		for (i in 0...100)
		{
			var keys = new DA<Int>();
			for (i in 0...8)
			{
				var x = Std.int(seed.random()) % 64;
				while (keys.contains(x)) x = Std.int(seed.random()) % 64;
				
				keys.pushBack(x);
			}
			
			for (i in 0...keys.size())
			{
				h.set(keys.get(i), i);
			}
			
			keys.shuffle();
			
			for (i in 0...keys.size())
			{
				assertTrue(clrAll(h, keys.get(i)));
			}
			
			keys.shuffle();
		}
	}
	
	function testInsertRemoveRandom3()
	{
		var h = new IntIntHashTable(16);
		
		var seed = new ParkMiller();
		
		var j = 0;
		for (i in 0...100)
		{
			j++;
			var keys = new DA<Int>();
			for (i in 0...8)
			{
				var x = Std.int(seed.random()) % 64;
				while (keys.contains(x)) x = Std.int(seed.random()) % 64;
				
				keys.pushBack(x);
			}
			
			for (i in 0...keys.size())
			{
				h.set(keys.get(i), i);
			}
			
			keys.shuffle();
			
			for (i in 0...keys.size())
			{
				assertTrue(h.get(keys.get(i)) != IntIntHashTable.KEY_ABSENT);
			}
			
			keys.shuffle();
			
			for (i in 0...keys.size())
			{
				assertTrue(clrAll(h, keys.get(i)));
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
		
		assertEquals(s, h.size());
		
		for (i in 0...s)
		{
			assertTrue(clrAll(h, i * s));
		}
		
		assertEquals(0, h.size());
		
		for (i in 0...s)
		{
			h.set(i * s, i);
		}
		
		assertEquals(s, h.size());
		
		for (i in 0...s)
		{
			assertTrue(clrAll(h, i * s));
		}
		
		assertEquals(0, h.size());
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
		
		var seed = new ParkMiller();
		
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
		
		for (i in 0...8) h.set(i, i);
		assertTrue(h.size() == h.getCapacity());
		
		h.set(8, 8);
		
		assertEquals(9, h.size());
		
		for (i in 0...8 + 1)
		{
			assertEquals(i, h.get(i));
		}
		for (i in 9...16)
		{
			h.set(i, i);
		}
		
		assertTrue(h.size() == h.getCapacity());
		
		for (i in 0...16)
		{
			assertEquals(i, h.get(i));
		}
		var i = 16;
		while (i-- > 0)
		{
			if (h.size() == 4)
			{
				return;
			}
			
			assertTrue(h.remove(i));
		}
		
		assertTrue(h.isEmpty());
		
		for (i in 0...16) h.set(i, i);
		assertTrue(h.size() == h.getCapacity());
		for (i in 0...16) assertEquals(i, h.get(i));
	}
	
	function testClone()
	{
		var h = new IntIntHashTable(8);
		for (i in 0...8) h.set(i, i);
		
		var c:IntIntHashTable = cast h.clone(true);
		
		var i = 0;
		var l = new DLL<Int>();
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
	
	function testToArrayToDA()
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
	
	function testToKeyArrayToDA()
	{
		var h = new IntIntHashTable(8);
		for (i in 0...8) h.set(i, i * 10);
		
		var a = h.toKeyArray();
		assertEquals(8, a.length);
		
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
		
		var a = h.toKeyDA();
		
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
		var h = new IntIntHashTable(8);
		for (i in 0...8) h.set(i, i);
		h.clear();
		var c = 0;
		for (i in h) c++;
		assertEquals(0, c);
		
		var h = new IntIntHashTable(8);
		for (i in 0...8) h.set(i, i);
		assertEquals(8, h.getCapacity());
		for (i in 8...16) h.set(i, i);
		assertEquals(16, h.getCapacity());
		
		h.clear();
		
		assertEquals(16, h.getCapacity());
		assertEquals(0, h.size());
		assertTrue(h.isEmpty());
		
		for (i in 0...16) h.set(i, i);
		assertEquals(16, h.getCapacity());
		for (i in 0...16) assertEquals(i, h.get(i));
		
		//clear with purge
		var h = new IntIntHashTable(8);
		for (i in 0...16) h.set(i, i);
		h.clear(true);
		
		assertEquals(8, h.getCapacity());
		assertEquals(0, h.size());
		
		for (i in 0...16) h.set(i, i);
		assertEquals(16, h.getCapacity());
		for (i in 0...16) assertEquals(i, h.get(i));
		
		h.clear(true);
		assertEquals(8, h.getCapacity());
		
		for (i in 0...16) h.set(i, i);
		assertEquals(16, h.getCapacity());
		for (i in 0...16) assertEquals(i, h.get(i));
	}
	
	function testIterator()
	{
		var h = new IntIntHashTable(8);
		for (i in 0...8) h.set(i, i * 10);
		
		var set = new DA<Int>();
		for (val in h)
		{
			assertFalse(set.contains(val));
			set.pushBack(val);
		}
		assertEquals(8, set.size());
		for (i in 0...8) assertTrue(set.contains(i * 10));
		
		var set = new DA<Int>();
		for (key in h.keys())
		{
			assertFalse(set.contains(key));
			set.pushBack(key);
		}
		assertEquals(8, set.size());
		for (i in 0...8) assertTrue(set.contains(i));
		
		var h = new IntIntHashTable(8);
		var c = 0;
		for (x in h)
		{
			c++;
		}
		
		assertEquals(0, c);
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
	
	#if (!flash8)
	/*function testBug1()
	{
		var hash:IntIntHashTable = new IntIntHashTable(8192, 512);
        hash.set(1, 0);
     hash.clr(1);
        hash.set(1, 0);
        hash.set(2, 1);
        hash.set(65538, 2);
     hash.clr(65538);
     hash.clr(2);
        hash.set(2, 1);
        hash.set(65538, 2);
        hash.set(3, 3);
        hash.set(131075, 4);
     hash.clr(131075);
     hash.clr(3);
        hash.set(3, 3);
        hash.set(131075, 4);
        hash.set(4, 5);
        hash.set(196612, 6);
     hash.clr(196612);
     hash.clr(4);
        hash.set(4, 5);
        hash.set(196612, 6);
        hash.set(5, 7);
        hash.set(262149, 8);
     hash.clr(5);
     hash.clr(262149);
        hash.set(5, 8);
        hash.set(262149, 7);
        hash.set(6, 9);
     hash.clr(6);
        hash.set(6, 9);
        hash.set(7, 10);
        hash.set(393223, 11);
     hash.clr(393223);
     hash.clr(7);
        hash.set(7, 10);
        hash.set(393223, 11);
        hash.set(8, 12);
        hash.set(458760, 13);
     hash.clr(458760);
     hash.clr(8);
        hash.set(8, 12);
        hash.set(458760, 13);
        hash.set(9, 14);
        hash.set(524297, 15);
     hash.clr(524297);
     hash.clr(9);
        hash.set(9, 14);
        hash.set(524297, 15);
        hash.set(10, 16);
        hash.set(589834, 17);
     hash.clr(589834);
     hash.clr(10);
        hash.set(10, 16);
        hash.set(589834, 17);
        hash.set(11, 18);
        hash.set(65547, 19);
        hash.set(131083, 20);
        hash.set(196619, 21);
     hash.clr(65547);
     hash.clr(11);
     hash.clr(131083);
     hash.clr(196619);
        hash.set(11, 21);
        hash.set(65547, 20);
        hash.set(131083, 18);
        hash.set(196619, 19);
        hash.set(720908, 22);
        hash.set(12, 23);
        hash.set(131084, 24);
        hash.set(196620, 25);
     hash.clr(12);
     hash.clr(131084);
     hash.clr(196620);
     hash.clr(720908);
        hash.set(720908, 22);
        hash.set(12, 25);
        hash.set(131084, 24);
        hash.set(196620, 23);
        hash.set(720909, 26);
        hash.set(786445, 27);
        hash.set(13, 28);
        hash.set(131085, 29);
        hash.set(196621, 30);
        hash.set(262157, 31);
     hash.clr(131085);
     hash.clr(720909);
     hash.clr(786445);
     hash.clr(13);
     hash.clr(196621);
     hash.clr(262157);
        hash.set(720909, 31);
        hash.set(786445, 30);
        hash.set(13, 28);
        hash.set(131085, 27);
        hash.set(196621, 26);
        hash.set(262157, 29);
        hash.set(851982, 32);
        hash.set(14, 33);
        hash.set(196622, 34);
        hash.set(262158, 35);
        hash.set(327694, 36);
     hash.clr(196622);
     hash.clr(851982);
     hash.clr(14);
     hash.clr(262158);
     hash.clr(327694);
        hash.set(851982, 36);
        hash.set(14, 35);
        hash.set(196622, 33);
        hash.set(262158, 32);
        hash.set(327694, 34);
        hash.set(917519, 37);
        hash.set(15, 38);
        hash.set(262159, 39);
        hash.set(327695, 40);
        hash.set(393231, 41);
        hash.set(458767, 42);
     hash.clr(262159);
     hash.clr(327695);
     hash.clr(917519);
     hash.clr(15);
     hash.clr(393231);
     hash.clr(458767);
        hash.set(917519, 42);
        hash.set(15, 41);
        hash.set(262159, 38);
        hash.set(327695, 37);
        hash.set(393231, 40);
        hash.set(458767, 39);
        hash.set(983056, 43);
        hash.set(16, 44);
        hash.set(393232, 45);
        hash.set(458768, 46);
        hash.set(524304, 47);
     hash.clr(393232);
     hash.clr(983056);
     hash.clr(16);
     hash.clr(458768);
     hash.clr(524304);
        hash.set(983056, 47);
        hash.set(16, 46);
        hash.set(393232, 44);
        hash.set(458768, 43);
        hash.set(524304, 45);
        hash.set(1048593, 48);
        hash.set(17, 49);
        hash.set(458769, 50);
        hash.set(524305, 51);
        hash.set(589841, 52);
     hash.clr(458769);
     hash.clr(1048593);
     hash.clr(17);
     hash.clr(524305);
     hash.clr(589841);
        hash.set(1048593, 52);
        hash.set(17, 51);
        hash.set(458769, 49);
        hash.set(524305, 48);
        hash.set(589841, 50);
        hash.set(1114130, 53);
        hash.set(18, 54);
        hash.set(524306, 55);
        hash.set(589842, 56);
     hash.clr(18);
     hash.clr(524306);
     hash.clr(589842);
     hash.clr(1114130);
        hash.set(1114130, 53);
        hash.set(18, 56);
        hash.set(524306, 55);
        hash.set(589842, 54);
        hash.set(1114131, 57);
        hash.set(1179667, 58);
        hash.set(19, 59);
        hash.set(524307, 60);
        hash.set(589843, 61);
        hash.set(655379, 62);
     hash.clr(524307);
     hash.clr(1114131);
     hash.clr(1179667);
     hash.clr(19);
     hash.clr(589843);
     hash.clr(655379);
        hash.set(1114131, 62);
        hash.set(1179667, 61);
        hash.set(19, 59);
        hash.set(524307, 58);
        hash.set(589843, 57);
        hash.set(655379, 60);
        hash.set(1245204, 63);
        hash.set(20, 64);
//194 DEBUG Root                 line 1155 IntIntHashTable::_expand()    expand from 64 to 128
        hash.set(589844, 65);
        hash.set(655380, 66);
     hash.clr(589844);
     hash.clr(1245204);
     hash.clr(20);
     hash.clr(655380);
        hash.set(1245204, 66);
        hash.set(20, 64);
        hash.set(589844, 63);
        hash.set(655380, 65);
        hash.set(720917, 67);
     hash.clr(720917);
        hash.set(720917, 67);
        hash.set(720918, 68);
        hash.set(1376278, 69);
        hash.set(786454, 70);
        hash.set(851990, 71);
     hash.clr(1376278);
     hash.clr(720918);
     hash.clr(786454);
     hash.clr(851990);
        hash.set(720918, 71);
        hash.set(1376278, 70);
        hash.set(786454, 68);
        hash.set(851990, 69);
        hash.set(720919, 72);
        hash.set(786455, 73);
        hash.set(851991, 74);
        hash.set(1441815, 75);
        hash.set(917527, 76);
     hash.clr(720919);
     hash.clr(786455);
     hash.clr(1441815);
     hash.clr(851991);
     hash.clr(917527);
        hash.set(720919, 76);
        hash.set(786455, 74);
        hash.set(851991, 75);
        hash.set(1441815, 73);
        hash.set(917527, 72);
        hash.set(851992, 77);
        hash.set(917528, 78);
        hash.set(1507352, 79);
        hash.set(983064, 80);
     hash.clr(851992);
     hash.clr(1507352);
     hash.clr(917528);
     hash.clr(983064);
        hash.set(851992, 80);
        hash.set(917528, 78);
        hash.set(1507352, 79);
        hash.set(983064, 77);
        hash.set(917529, 81);
        hash.set(983065, 82);
        hash.set(1572889, 83);
     hash.clr(917529);
     hash.clr(983065);
     hash.clr(1572889);
        hash.set(917529, 83);
        hash.set(983065, 82);
        hash.set(1572889, 81);
        hash.set(983066, 84);
        hash.set(1048602, 85);
     hash.clr(983066);
     hash.clr(1048602);
        hash.set(983066, 85);
        hash.set(1048602, 84);
        hash.set(983067, 86);
        hash.set(1048603, 87);
        hash.set(1703963, 88);
        hash.set(1114139, 89);
     hash.clr(983067);
     hash.clr(1703963);
     hash.clr(1048603);
     hash.clr(1114139);
        hash.set(983067, 89);
        hash.set(1048603, 87);
        hash.set(1703963, 88);
        hash.set(1114139, 86);
        hash.set(1048604, 90);
        hash.set(1114140, 91);
        hash.set(1769500, 92);
        hash.set(1179676, 93);
        hash.set(1245212, 94);
     hash.clr(1048604);
     hash.clr(1769500);
     hash.clr(1114140);
     hash.clr(1179676);
     hash.clr(1245212);
        hash.set(1048604, 94);
        hash.set(1114140, 93);
        hash.set(1769500, 91);
        hash.set(1179676, 92);
        hash.set(1245212, 90);
        hash.set(1114141, 95);
        hash.set(1179677, 96);
        hash.set(1245213, 97);
        hash.set(1835037, 98);
        hash.set(1310749, 99);
     hash.clr(1114141);
     hash.clr(1179677);
     hash.clr(1835037);
     hash.clr(1245213);
     hash.clr(1310749);
        hash.set(1114141, 99);
        hash.set(1179677, 97);
        hash.set(1245213, 98);
        hash.set(1835037, 96);
        hash.set(1310749, 95);
        hash.set(1245214, 100);
        hash.set(1310750, 101);
        hash.set(1900574, 102);
     hash.clr(1245214);
     hash.clr(1900574);
     hash.clr(1310750);
        hash.set(1245214, 101);
        hash.set(1310750, 102);
        hash.set(1900574, 100);
        hash.set(720927, 103);
        hash.set(1376287, 104);
        hash.set(1441823, 105);
        hash.set(786463, 106);
        hash.set(851999, 107);
        hash.set(1507359, 108);
     hash.clr(1376287);
     hash.clr(720927);
     hash.clr(786463);
     hash.clr(851999);
     hash.clr(1441823);
     hash.clr(1507359);
        hash.set(720927, 108);
        hash.set(1376287, 105);
        hash.set(1441823, 107);
        hash.set(786463, 106);
        hash.set(851999, 103);
        hash.set(1507359, 104);
        hash.set(2031648, 109);
        hash.set(720928, 110);
        hash.set(786464, 111);
        hash.set(852000, 112);
        hash.set(1441824, 113);
        hash.set(1507360, 114);
     hash.clr(720928);
     hash.clr(786464);
     hash.clr(852000);
     hash.clr(1441824);
     hash.clr(1507360);
     hash.clr(2031648);
        hash.set(2031648, 109);
        hash.set(720928, 114);
        hash.set(786464, 113);
        hash.set(852000, 112);
        hash.set(1441824, 111);
        hash.set(1507360, 110);
        hash.set(2031649, 115);
        hash.set(2097185, 116);
        hash.set(720929, 117);
        hash.set(786465, 118);
        hash.set(852001, 119);
        hash.set(1441825, 120);
        hash.set(1507361, 121);
        hash.set(917537, 122);
        hash.set(1572897, 123);
     hash.clr(720929);
     hash.clr(786465);
     hash.clr(1441825);
     hash.clr(2031649);
     hash.clr(2097185);
     hash.clr(852001);
     hash.clr(917537);
     hash.clr(1507361);
     hash.clr(1572897);
        hash.set(2031649, 123);
        hash.set(2097185, 121);
        hash.set(720929, 122);
        hash.set(786465, 119);
        hash.set(852001, 116);
        hash.set(1441825, 115);
        hash.set(1507361, 120);
        hash.set(917537, 118);
        hash.set(1572897, 117);
        hash.set(2162722, 124);
        hash.set(852002, 125);
        hash.set(917538, 126);
        hash.set(1507362, 127);
        hash.set(1572898, 128);
//381 DEBUG Root                 line 1155 IntIntHashTable::_expand()    expand from 128 to 256
        hash.set(983074, 129);
        hash.set(1638434, 130);
     hash.clr(852002);
     hash.clr(1507362);
     hash.clr(2162722);
     hash.clr(917538);
     hash.clr(983074);
     hash.clr(1572898);
     hash.clr(1638434);
        hash.set(2162722, 130);
        hash.set(852002, 128);
        hash.set(917538, 129);
        hash.set(1507362, 126);
        hash.set(1572898, 124);
        hash.set(983074, 127);
        hash.set(1638434, 125);
        hash.set(2228259, 131);
        hash.set(917539, 132);
        hash.set(983075, 133);
        hash.set(1572899, 134);
        hash.set(1638435, 135);
        hash.set(1048611, 136);
        hash.set(1703971, 137);
        hash.set(1769507, 138);
     hash.clr(917539);
     hash.clr(1572899);
     hash.clr(1638435);
     hash.clr(2228259);
     hash.clr(983075);
     hash.clr(1048611);
     hash.clr(1703971);
     hash.clr(1769507);
        hash.set(2228259, 138);
        hash.set(917539, 137);
        hash.set(983075, 136);
        hash.set(1572899, 133);
        hash.set(1638435, 131);
        hash.set(1048611, 135);
        hash.set(1703971, 134);
        hash.set(1769507, 132);
        hash.set(2293796, 139);
        hash.set(983076, 140);
        hash.set(1048612, 141);
        hash.set(1703972, 142);
        hash.set(1769508, 143);
        hash.set(1114148, 144);
        hash.set(1835044, 145);
     hash.clr(983076);
     hash.clr(1703972);
     hash.clr(2293796);
     hash.clr(1048612);
     hash.clr(1114148);
     hash.clr(1769508);
     hash.clr(1835044);
        hash.set(2293796, 145);
        hash.set(983076, 143);
        hash.set(1048612, 144);
        hash.set(1703972, 141);
        hash.set(1769508, 139);
        hash.set(1114148, 142);
        hash.set(1835044, 140);
        hash.set(2359333, 146);
        hash.set(1048613, 147);
        hash.set(1114149, 148);
        hash.set(1769509, 149);
        hash.set(1835045, 150);
        hash.set(1179685, 151);
        hash.set(1245221, 152);
        hash.set(1900581, 153);
     hash.clr(1048613);
     hash.clr(1769509);
     hash.clr(2359333);
     hash.clr(1114149);
     hash.clr(1179685);
     hash.clr(1245221);
     hash.clr(1835045);
     hash.clr(1900581);
        hash.set(2359333, 153);
        hash.set(1048613, 150);
        hash.set(1114149, 152);
        hash.set(1769509, 151);
        hash.set(1835045, 148);
        hash.set(1179685, 146);
        hash.set(1245221, 149);
        hash.set(1900581, 147);
        hash.set(2424870, 154);
        hash.set(1114150, 155);
        hash.set(1179686, 156);
        hash.set(1245222, 157);
        hash.set(1835046, 158);
        hash.set(1900582, 159);
     hash.clr(1114150);
     hash.clr(1179686);
     hash.clr(1245222);
     hash.clr(1835046);
     hash.clr(1900582);
     hash.clr(2424870);
        hash.set(2424870, 154);
        hash.set(1114150, 159);
        hash.set(1179686, 158);
        hash.set(1245222, 157);
        hash.set(1835046, 156);
        hash.set(1900582, 155);
        hash.set(2424871, 160);
        hash.set(2490407, 161);
        hash.set(1114151, 162);
        hash.set(1179687, 163);
        hash.set(1245223, 164);
        hash.set(1835047, 165);
        hash.set(1900583, 166);
        hash.set(1310759, 167);
        hash.set(1966119, 168);
     hash.clr(1114151);
     hash.clr(1179687);
     hash.clr(1835047);
     hash.clr(2424871);
     hash.clr(2490407);
     hash.clr(1245223);
     hash.clr(1310759);
     hash.clr(1900583);
     hash.clr(1966119);
        hash.set(2424871, 168);
        hash.set(2490407, 166);
        hash.set(1114151, 167);
        hash.set(1179687, 164);
        hash.set(1245223, 161);
        hash.set(1835047, 160);
        hash.set(1900583, 165);
        hash.set(1310759, 163);
        hash.set(1966119, 162);
        hash.set(2555944, 169);
        hash.set(1245224, 170);
        hash.set(1310760, 171);
        hash.set(1900584, 172);
        hash.set(1966120, 173);
     hash.clr(1245224);
     hash.clr(1900584);
     hash.clr(2555944);
     hash.clr(1310760);
     hash.clr(1966120);
        hash.set(2555944, 173);
        hash.set(1245224, 171);
        hash.set(1310760, 169);
        hash.set(1900584, 172);
        hash.set(1966120, 170);
        hash.set(2031657, 174);
     hash.clr(2031657);
        hash.set(2031657, 174);
        hash.set(2031658, 175);
        hash.set(2687018, 176);
        hash.set(2097194, 177);
        hash.set(2162730, 178);
     hash.clr(2687018);
     hash.clr(2031658);
     hash.clr(2097194);
     hash.clr(2162730);
        hash.set(2031658, 178);
        hash.set(2687018, 177);
        hash.set(2097194, 175);
        hash.set(2162730, 176);
        hash.set(2031659, 179);
        hash.set(2097195, 180);
        hash.set(2162731, 181);
        hash.set(2752555, 182);
        hash.set(2228267, 183);
     hash.clr(2031659);
     hash.clr(2097195);
     hash.clr(2752555);
     hash.clr(2162731);
     hash.clr(2228267);
        hash.set(2031659, 183);
        hash.set(2097195, 181);
        hash.set(2162731, 182);
        hash.set(2752555, 180);
        hash.set(2228267, 179);
        hash.set(2162732, 184);
        hash.set(2228268, 185);
        hash.set(2818092, 186);
        hash.set(2293804, 187);
     hash.clr(2162732);
     hash.clr(2818092);
     hash.clr(2228268);
     hash.clr(2293804);
        hash.set(2162732, 187);
        hash.set(2228268, 185);
        hash.set(2818092, 186);
        hash.set(2293804, 184);
        hash.set(2228269, 188);
        hash.set(2293805, 189);
        hash.set(2883629, 190);
     hash.clr(2228269);
     hash.clr(2293805);
     hash.clr(2883629);
        hash.set(2228269, 190);
        hash.set(2293805, 189);
        hash.set(2883629, 188);
        hash.set(2293806, 191);
        hash.set(2359342, 192);
     hash.clr(2293806);
     hash.clr(2359342);
        hash.set(2293806, 192);
        hash.set(2359342, 191);
        hash.set(2293807, 193);
        hash.set(2359343, 194);
        hash.set(3014703, 195);
        hash.set(2424879, 196);
     hash.clr(2293807);
     hash.clr(3014703);
     hash.clr(2359343);
     hash.clr(2424879);
        hash.set(2293807, 196);
        hash.set(2359343, 194);
        hash.set(3014703, 195);
        hash.set(2424879, 193);
        hash.set(2359344, 197);
        hash.set(2424880, 198);
        hash.set(3080240, 199);
        hash.set(2490416, 200);
        hash.set(2555952, 201);
     hash.clr(2359344);
     hash.clr(3080240);
     hash.clr(2424880);
     hash.clr(2490416);
     hash.clr(2555952);
        hash.set(2359344, 201);
        hash.set(2424880, 200);
        hash.set(3080240, 198);
        hash.set(2490416, 199);
        hash.set(2555952, 197);
        hash.set(2424881, 202);
        hash.set(2490417, 203);
        hash.set(2555953, 204);
        hash.set(3145777, 205);
        hash.set(2621489, 206);
     hash.clr(2424881);
     hash.clr(2490417);
     hash.clr(3145777);
     hash.clr(2555953);
     hash.clr(2621489);
        hash.set(2424881, 206);
        hash.set(2490417, 204);
        hash.set(2555953, 205);
        hash.set(3145777, 203);
        hash.set(2621489, 202);
        hash.set(2555954, 207);
        hash.set(2621490, 208);
        hash.set(3211314, 209);
     hash.clr(2555954);
     hash.clr(3211314);
     hash.clr(2621490);
        hash.set(2555954, 208);
        hash.set(2621490, 209);
        hash.set(3211314, 207);
        hash.set(2031667, 210);
        hash.set(2687027, 211);
        hash.set(2752563, 212);
        hash.set(2097203, 213);
        hash.set(2162739, 214);
        hash.set(2818099, 215);
     hash.clr(2687027);
     hash.clr(2031667);
     hash.clr(2097203);
     hash.clr(2162739);
     hash.clr(2752563);
     hash.clr(2818099);
        hash.set(2031667, 215);
        hash.set(2687027, 212);
        hash.set(2752563, 214);
        hash.set(2097203, 213);
        hash.set(2162739, 210);
        hash.set(2818099, 211);
        hash.set(2031668, 216);
        hash.set(2097204, 217);
        hash.set(2162740, 218);
        hash.set(2752564, 219);
        hash.set(2818100, 220);
        hash.set(3342388, 221);
     hash.clr(2031668);
     hash.clr(2097204);
     hash.clr(2162740);
     hash.clr(2752564);
     hash.clr(2818100);
     hash.clr(3342388);
        hash.set(2031668, 221);
        hash.set(2097204, 220);
        hash.set(2162740, 219);
        hash.set(2752564, 218);
        hash.set(2818100, 217);
        hash.set(3342388, 216);
        hash.set(2031669, 222);
        hash.set(2097205, 223);
        hash.set(2162741, 224);
        hash.set(2752565, 225);
        hash.set(2818101, 226);
        hash.set(3342389, 227);
        hash.set(3407925, 228);
        hash.set(2228277, 229);
        hash.set(2883637, 230);
     hash.clr(2031669);
     hash.clr(2097205);
     hash.clr(2752565);
     hash.clr(3342389);
     hash.clr(3407925);
     hash.clr(2162741);
     hash.clr(2228277);
     hash.clr(2818101);
     hash.clr(2883637);
        hash.set(2031669, 230);
        hash.set(2097205, 226);
        hash.set(2162741, 229);
        hash.set(2752565, 224);
        hash.set(2818101, 228);
        hash.set(3342389, 227);
        hash.set(3407925, 225);
        hash.set(2228277, 223);
        hash.set(2883637, 222);
        hash.set(2162742, 231);
        hash.set(2228278, 232);
        hash.set(2818102, 233);
        hash.set(2883638, 234);
        hash.set(3473462, 235);
        hash.set(2293814, 236);
        hash.set(2949174, 237);
     hash.clr(2162742);
     hash.clr(2818102);
     hash.clr(3473462);
     hash.clr(2228278);
     hash.clr(2293814);
     hash.clr(2883638);
     hash.clr(2949174);
        hash.set(2162742, 237);
        hash.set(2228278, 234);
        hash.set(2818102, 236);
        hash.set(2883638, 232);
        hash.set(3473462, 235);
        hash.set(2293814, 233);
        hash.set(2949174, 231);
        hash.set(2228279, 238);
        hash.set(2293815, 239);
        hash.set(2883639, 240);
        hash.set(2949175, 241);
        hash.set(3538999, 242);
        hash.set(2359351, 243);
        hash.set(3014711, 244);
        hash.set(3080247, 245);
     hash.clr(2228279);
     hash.clr(2883639);
     hash.clr(2949175);
     hash.clr(3538999);
     hash.clr(2293815);
     hash.clr(2359351);
     hash.clr(3014711);
     hash.clr(3080247);
        hash.set(2228279, 245);
        hash.set(2293815, 244);
        hash.set(2883639, 243);
        hash.set(2949175, 239);
        hash.set(3538999, 242);
        hash.set(2359351, 241);
        hash.set(3014711, 240);
        hash.set(3080247, 238);
        hash.set(2293816, 246);
        hash.set(2359352, 247);
        hash.set(3014712, 248);
        hash.set(3080248, 249);
        hash.set(3604536, 250);
        hash.set(2424888, 251);
        hash.set(3145784, 252);
     hash.clr(2293816);
     hash.clr(3014712);
     hash.clr(3604536);
     hash.clr(2359352);
     hash.clr(2424888);
     hash.clr(3080248);
     hash.clr(3145784);
        hash.set(2293816, 252);
        hash.set(2359352, 249);
        hash.set(3014712, 251);
        hash.set(3080248, 247);
        hash.set(3604536, 250);
        hash.set(2424888, 248);
        hash.set(3145784, 246);
        hash.set(2359353, 253);
        hash.set(2424889, 254);
        hash.set(3080249, 255);
        hash.set(3145785, 256);
//768 DEBUG Root                 line 1155 IntIntHashTable::_expand()    expand from 256 to 512
        hash.set(3670073, 257);
        hash.set(2490425, 258);
        hash.set(2555961, 259);
        hash.set(3211321, 260);
     hash.clr(2359353);
     hash.clr(3080249);
     hash.clr(3670073);
     hash.clr(2424889);
     hash.clr(2490425);
     hash.clr(2555961);
     hash.clr(3145785);
     hash.clr(3211321);
        hash.set(2359353, 260);
        hash.set(2424889, 256);
        hash.set(3080249, 259);
        hash.set(3145785, 258);
        hash.set(3670073, 254);
        hash.set(2490425, 257);
        hash.set(2555961, 255);
        hash.set(3211321, 253);
        hash.set(2424890, 261);
        hash.set(2490426, 262);
        hash.set(2555962, 263);
        hash.set(3145786, 264);
        hash.set(3211322, 265);
        hash.set(3735610, 266);
     hash.clr(2424890);
     hash.clr(2490426);
     hash.clr(2555962);
     hash.clr(3145786);
     hash.clr(3211322);
     hash.clr(3735610);
        hash.set(2424890, 266);
        hash.set(2490426, 265);
        hash.set(2555962, 264);
        hash.set(3145786, 263);
        hash.set(3211322, 262);
        hash.set(3735610, 261);
        hash.set(2424891, 267);
        hash.set(2490427, 268);
        hash.set(2555963, 269);
        hash.set(3145787, 270);
        hash.set(3211323, 271);
        hash.set(3735611, 272);
        hash.set(3801147, 273);
        hash.set(2621499, 274);
        hash.set(3276859, 275);
     hash.clr(2424891);
     hash.clr(2490427);
     hash.clr(3145787);
     hash.clr(3735611);
     hash.clr(3801147);
     hash.clr(2555963);
     hash.clr(2621499);
     hash.clr(3211323);
     hash.clr(3276859);
        hash.set(2424891, 275);
        hash.set(2490427, 271);
        hash.set(2555963, 274);
        hash.set(3145787, 269);
        hash.set(3211323, 273);
        hash.set(3735611, 272);
        hash.set(3801147, 270);
        hash.set(2621499, 268);
        hash.set(3276859, 267);
        hash.set(2555964, 276);
        hash.set(2621500, 277);
        hash.set(3211324, 278);
        hash.set(3276860, 279);
        hash.set(3866684, 280);
     hash.clr(2555964);
     hash.clr(3211324);
     hash.clr(3866684);
     hash.clr(2621500);
     hash.clr(3276860);
        hash.set(2555964, 279);
        hash.set(2621500, 277);
        hash.set(3211324, 280);
        hash.set(3276860, 278);
        hash.set(3866684, 276);
        hash.set(2687037, 281);
        hash.set(2031677, 282);
        hash.set(2752573, 283);
        hash.set(3342397, 284);
     hash.clr(2031677);
     hash.clr(2687037);
     hash.clr(2752573);
     hash.clr(3342397);
        hash.set(2687037, 284);
        hash.set(2031677, 283);
        hash.set(2752573, 281);
        hash.set(3342397, 282);
        hash.set(3997758, 285);
        hash.set(2031678, 286);
        hash.set(2687038, 287);
        hash.set(2752574, 288);
        hash.set(3342398, 289);
        hash.set(2097214, 290);
        hash.set(2162750, 291);
        hash.set(2818110, 292);
        hash.set(3407934, 293);
        hash.set(3473470, 294);
     hash.clr(2687038);
     hash.clr(3997758);
     hash.clr(2031678);
     hash.clr(2097214);
     hash.clr(2162750);
     hash.clr(2752574);
     hash.clr(2818110);
     hash.clr(3342398);
     hash.clr(3407934);
     hash.clr(3473470);
        hash.set(3997758, 294);
        hash.set(2031678, 293);
        hash.set(2687038, 289);
        hash.set(2752574, 292);
        hash.set(3342398, 288);
        hash.set(2097214, 291);
        hash.set(2162750, 290);
        hash.set(2818110, 286);
        hash.set(3407934, 285);
        hash.set(3473470, 287);
        hash.set(4063295, 295);
        hash.set(2031679, 296);
        hash.set(2097215, 297);
        hash.set(2162751, 298);
        hash.set(2752575, 299);
        hash.set(2818111, 300);
        hash.set(3342399, 301);
        hash.set(3407935, 302);
        hash.set(3473471, 303);
        hash.set(2228287, 304);
        hash.set(2883647, 305);
        hash.set(3539007, 306);
     hash.clr(2031679);
     hash.clr(2097215);
     hash.clr(2752575);
     hash.clr(3342399);
     hash.clr(3407935);
     hash.clr(4063295);
     hash.clr(2162751);
     hash.clr(2228287);
     hash.clr(2818111);
     hash.clr(2883647);
     hash.clr(3473471);
     hash.clr(3539007);
        hash.set(4063295, 306);
        hash.set(2031679, 303);
        hash.set(2097215, 305);
        hash.set(2162751, 300);
        hash.set(2752575, 304);
        hash.set(2818111, 298);
        hash.set(3342399, 295);
        hash.set(3407935, 302);
        hash.set(3473471, 301);
        hash.set(2228287, 299);
        hash.set(2883647, 297);
        hash.set(3539007, 296);
        hash.set(4128832, 307);
        hash.set(2162752, 308);
        hash.set(2228288, 309);
        hash.set(2818112, 310);
        hash.set(2883648, 311);
        hash.set(3473472, 312);
        hash.set(3539008, 313);
        hash.set(2293824, 314);
        hash.set(2949184, 315);
        hash.set(3604544, 316);
     hash.clr(2162752);
     hash.clr(2818112);
     hash.clr(3473472);
     hash.clr(4128832);
     hash.clr(2228288);
     hash.clr(2293824);
     hash.clr(2883648);
     hash.clr(2949184);
     hash.clr(3539008);
     hash.clr(3604544);
        hash.set(4128832, 316);
        hash.set(2162752, 313);
        hash.set(2228288, 315);
        hash.set(2818112, 311);
        hash.set(2883648, 314);
        hash.set(3473472, 309);
        hash.set(3539008, 307);
        hash.set(2293824, 312);
        hash.set(2949184, 310);
        hash.set(3604544, 308);
        hash.set(4194369, 317);
        hash.set(2228289, 318);
        hash.set(2293825, 319);
        hash.set(2883649, 320);
        hash.set(2949185, 321);
        hash.set(3539009, 322);
        hash.set(3604545, 323);
     hash.clr(2228289);
     hash.clr(2293825);
     hash.clr(2883649);
     hash.clr(2949185);
     hash.clr(3539009);
     hash.clr(3604545);
     hash.clr(4194369);
        hash.set(4194369, 317);
        hash.set(2228289, 323);
        hash.set(2293825, 322);
        hash.set(2883649, 321);
        hash.set(2949185, 320);
        hash.set(3539009, 319);
        hash.set(3604545, 318);
        hash.set(2293826, 324);
        hash.set(2359362, 325);
        hash.set(3014722, 326);
        hash.set(3080258, 327);
        hash.set(3604546, 328);
        hash.set(3670082, 329);
     hash.clr(2293826);
     hash.clr(2359362);
     hash.clr(3014722);
     hash.clr(3080258);
     hash.clr(3604546);
     hash.clr(3670082);
        hash.set(2293826, 329);
        hash.set(2359362, 328);
        hash.set(3014722, 327);
        hash.set(3080258, 326);
        hash.set(3604546, 325);
        hash.set(3670082, 324);
        hash.set(4325443, 330);
        hash.set(2293827, 331);
        hash.set(2359363, 332);
        hash.set(3014723, 333);
        hash.set(3080259, 334);
        hash.set(3604547, 335);
        hash.set(3670083, 336);
        hash.set(2424899, 337);
        hash.set(3145795, 338);
        hash.set(3735619, 339);
     hash.clr(2293827);
     hash.clr(3014723);
     hash.clr(3604547);
     hash.clr(4325443);
     hash.clr(2359363);
     hash.clr(2424899);
     hash.clr(3080259);
     hash.clr(3145795);
     hash.clr(3670083);
     hash.clr(3735619);
        hash.set(4325443, 339);
        hash.set(2293827, 336);
        hash.set(2359363, 338);
        hash.set(3014723, 334);
        hash.set(3080259, 337);
        hash.set(3604547, 332);
        hash.set(3670083, 330);
        hash.set(2424899, 335);
        hash.set(3145795, 333);
        hash.set(3735619, 331);
        hash.set(4390980, 340);
        hash.set(2359364, 341);
        hash.set(2424900, 342);
        hash.set(3080260, 343);
        hash.set(3145796, 344);
        hash.set(3670084, 345);
        hash.set(3735620, 346);
        hash.set(2490436, 347);
        hash.set(2555972, 348);
        hash.set(3211332, 349);
        hash.set(3801156, 350);
        hash.set(3866692, 351);
     hash.clr(2359364);
     hash.clr(3080260);
     hash.clr(3670084);
     hash.clr(4390980);
     hash.clr(2424900);
     hash.clr(2490436);
     hash.clr(2555972);
     hash.clr(3145796);
     hash.clr(3211332);
     hash.clr(3735620);
     hash.clr(3801156);
     hash.clr(3866692);
        hash.set(4390980, 351);
        hash.set(2359364, 350);
        hash.set(2424900, 346);
        hash.set(3080260, 349);
        hash.set(3145796, 344);
        hash.set(3670084, 348);
        hash.set(3735620, 347);
        hash.set(2490436, 342);
        hash.set(2555972, 340);
        hash.set(3211332, 345);
        hash.set(3801156, 343);
        hash.set(3866692, 341);
        hash.set(4456517, 352);
        hash.set(2424901, 353);
        hash.set(2490437, 354);
        hash.set(2555973, 355);
        hash.set(3145797, 356);
        hash.set(3211333, 357);
        hash.set(3735621, 358);
        hash.set(3801157, 359);
        hash.set(3866693, 360);
        hash.set(2621509, 361);
        hash.set(3276869, 362);
        hash.set(3932229, 363);
     hash.clr(2424901);
     hash.clr(2490437);
     hash.clr(3145797);
     hash.clr(3735621);
     hash.clr(3801157);
     hash.clr(4456517);
     hash.clr(2555973);
     hash.clr(2621509);
     hash.clr(3211333);
     hash.clr(3276869);
     hash.clr(3866693);
     hash.clr(3932229);
        hash.set(4456517, 363);
        hash.set(2424901, 360);
        hash.set(2490437, 362);
        hash.set(2555973, 357);
        hash.set(3145797, 361);
        hash.set(3211333, 355);
        hash.set(3735621, 352);
        hash.set(3801157, 359);
        hash.set(3866693, 358);
        hash.set(2621509, 356);
        hash.set(3276869, 354);
        hash.set(3932229, 353);
        hash.set(4522054, 364);
        hash.set(2555974, 365);
        hash.set(2621510, 366);
        hash.set(3211334, 367);
        hash.set(3276870, 368);
        hash.set(3866694, 369);
        hash.set(3932230, 370);
     hash.clr(2555974);
     hash.clr(3211334);
     hash.clr(3866694);
     hash.clr(4522054);
     hash.clr(2621510);
     hash.clr(3276870);
     hash.clr(3932230);
        hash.set(4522054, 370);
        hash.set(2555974, 368);
        hash.set(2621510, 366);
        hash.set(3211334, 364);
        hash.set(3276870, 369);
        hash.set(3866694, 367);
        hash.set(3932230, 365);
        hash.set(3997767, 371);
        hash.set(4063303, 372);
        hash.set(4128839, 373);
     hash.clr(3997767);
     hash.clr(4063303);
     hash.clr(4128839);
        hash.set(3997767, 373);
        hash.set(4063303, 372);
        hash.set(4128839, 371);
        hash.set(4063304, 374);
        hash.set(4128840, 375);
        hash.set(4653128, 376);
     hash.clr(4063304);
     hash.clr(4128840);
     hash.clr(4653128);
        hash.set(4063304, 376);
        hash.set(4128840, 375);
        hash.set(4653128, 374);
        hash.set(4063305, 377);
        hash.set(4128841, 378);
        hash.set(4653129, 379);
        hash.set(4718665, 380);
        hash.set(4194377, 381);
     hash.clr(4063305);
     hash.clr(4653129);
     hash.clr(4718665);
     hash.clr(4128841);
     hash.clr(4194377);
        hash.set(4063305, 381);
        hash.set(4128841, 378);
        hash.set(4653129, 380);
        hash.set(4718665, 379);
        hash.set(4194377, 377);
        hash.set(4128842, 382);
        hash.set(4194378, 383);
        hash.set(4784202, 384);
        hash.set(4259914, 385);
     hash.clr(4128842);
     hash.clr(4784202);
     hash.clr(4194378);
     hash.clr(4259914);
        hash.set(4128842, 385);
        hash.set(4194378, 383);
        hash.set(4784202, 384);
        hash.set(4259914, 382);
        hash.set(4194379, 386);
        hash.set(4259915, 387);
        hash.set(4849739, 388);
        hash.set(4325451, 389);
        hash.set(4390987, 390);
     hash.clr(4194379);
     hash.clr(4259915);
     hash.clr(4849739);
     hash.clr(4325451);
     hash.clr(4390987);
        hash.set(4194379, 390);
        hash.set(4259915, 389);
        hash.set(4849739, 388);
        hash.set(4325451, 387);
        hash.set(4390987, 386);
        hash.set(4325452, 391);
        hash.set(4390988, 392);
        hash.set(4915276, 393);
        hash.set(4456524, 394);
     hash.clr(4325452);
     hash.clr(4915276);
     hash.clr(4390988);
     hash.clr(4456524);
        hash.set(4325452, 394);
        hash.set(4390988, 392);
        hash.set(4915276, 393);
        hash.set(4456524, 391);
        hash.set(4390989, 395);
        hash.set(4456525, 396);
        hash.set(4980813, 397);
        hash.set(4522061, 398);
     hash.clr(4390989);
     hash.clr(4980813);
     hash.clr(4456525);
     hash.clr(4522061);
        hash.set(4390989, 398);
        hash.set(4456525, 396);
        hash.set(4980813, 397);
        hash.set(4522061, 395);
        hash.set(4456526, 399);
        hash.set(4522062, 400);
        hash.set(5046350, 401);
     hash.clr(4456526);
     hash.clr(4522062);
     hash.clr(5046350);
        hash.set(4456526, 401);
        hash.set(4522062, 400);
        hash.set(5046350, 399);
        hash.set(4456527, 402);
        hash.set(4522063, 403);
        hash.set(5046351, 404);
        hash.set(5111887, 405);
        hash.set(4587599, 406);
     hash.clr(4456527);
     hash.clr(5046351);
     hash.clr(5111887);
     hash.clr(4522063);
     hash.clr(4587599);
        hash.set(4456527, 406);
        hash.set(4522063, 403);
        hash.set(5046351, 405);
        hash.set(5111887, 404);
        hash.set(4587599, 402);
        hash.set(4522064, 407);
        hash.set(4587600, 408);
        hash.set(5177424, 409);
     hash.clr(4522064);
     hash.clr(5177424);
     hash.clr(4587600);
        hash.set(4522064, 408);
        hash.set(4587600, 409);
        hash.set(5177424, 407);
        hash.set(3997777, 410);
        hash.set(4063313, 411);
        hash.set(4653137, 412);
     hash.clr(3997777);
     hash.clr(4063313);
     hash.clr(4653137);
        hash.set(3997777, 412);
        hash.set(4063313, 411);
        hash.set(4653137, 410);
        hash.set(5308498, 413);
        hash.set(3997778, 414);
        hash.set(4063314, 415);
        hash.set(4653138, 416);
        hash.set(4128850, 417);
        hash.set(4718674, 418);
        hash.set(4784210, 419);
     hash.clr(3997778);
     hash.clr(5308498);
     hash.clr(4063314);
     hash.clr(4128850);
     hash.clr(4653138);
     hash.clr(4718674);
     hash.clr(4784210);
        hash.set(5308498, 419);
        hash.set(3997778, 418);
        hash.set(4063314, 416);
        hash.set(4653138, 417);
        hash.set(4128850, 415);
        hash.set(4718674, 413);
        hash.set(4784210, 414);
        hash.set(5374035, 420);
        hash.set(4063315, 421);
        hash.set(4128851, 422);
        hash.set(4653139, 423);
        hash.set(4718675, 424);
        hash.set(4784211, 425);
        hash.set(4194387, 426);
        hash.set(4849747, 427);
     hash.clr(4063315);
     hash.clr(4653139);
     hash.clr(4718675);
     hash.clr(5374035);
     hash.clr(4128851);
     hash.clr(4194387);
     hash.clr(4784211);
     hash.clr(4849747);
        hash.set(5374035, 427);
        hash.set(4063315, 425);
        hash.set(4128851, 426);
        hash.set(4653139, 422);
        hash.set(4718675, 420);
        hash.set(4784211, 424);
        hash.set(4194387, 423);
        hash.set(4849747, 421);
        hash.set(5439572, 428);
        hash.set(4128852, 429);
        hash.set(4194388, 430);
        hash.set(4784212, 431);
        hash.set(4849748, 432);
        hash.set(4259924, 433);
        hash.set(4915284, 434);
     hash.clr(4128852);
     hash.clr(4784212);
     hash.clr(5439572);
     hash.clr(4194388);
     hash.clr(4259924);
     hash.clr(4849748);
     hash.clr(4915284);
        hash.set(5439572, 434);
        hash.set(4128852, 432);
        hash.set(4194388, 433);
        hash.set(4784212, 430);
        hash.set(4849748, 428);
        hash.set(4259924, 431);
        hash.set(4915284, 429);
        hash.set(5505109, 435);
        hash.set(4194389, 436);
        hash.set(4259925, 437);
        hash.set(4849749, 438);
        hash.set(4915285, 439);
     hash.clr(4194389);
     hash.clr(4259925);
     hash.clr(4849749);
     hash.clr(4915285);
     hash.clr(5505109);
        hash.set(5505109, 435);
        hash.set(4194389, 439);
        hash.set(4259925, 438);
        hash.set(4849749, 437);
        hash.set(4915285, 436);
        hash.set(4325462, 440);
        hash.set(4390998, 441);
        hash.set(4915286, 442);
        hash.set(4980822, 443);
     hash.clr(4325462);
     hash.clr(4390998);
     hash.clr(4915286);
     hash.clr(4980822);
        hash.set(4325462, 443);
        hash.set(4390998, 442);
        hash.set(4915286, 441);
        hash.set(4980822, 440);
        hash.set(5636183, 444);
        hash.set(4325463, 445);
        hash.set(4390999, 446);
        hash.set(4915287, 447);
        hash.set(4980823, 448);
        hash.set(4456535, 449);
        hash.set(5046359, 450);
     hash.clr(4325463);
     hash.clr(4915287);
     hash.clr(5636183);
     hash.clr(4390999);
     hash.clr(4456535);
     hash.clr(4980823);
     hash.clr(5046359);
        hash.set(5636183, 450);
        hash.set(4325463, 448);
        hash.set(4390999, 449);
        hash.set(4915287, 446);
        hash.set(4980823, 444);
        hash.set(4456535, 447);
        hash.set(5046359, 445);
        hash.set(5701720, 451);
        hash.set(4391000, 452);
        hash.set(4456536, 453);
        hash.set(4980824, 454);
        hash.set(5046360, 455);
        hash.set(4522072, 456);
        hash.set(5111896, 457);
        hash.set(5177432, 458);
     hash.clr(4391000);
     hash.clr(4980824);
     hash.clr(5701720);
     hash.clr(4456536);
     hash.clr(4522072);
     hash.clr(5046360);
     hash.clr(5111896);
     hash.clr(5177432);
        hash.set(5701720, 458);
        hash.set(4391000, 457);
        hash.set(4456536, 455);
        hash.set(4980824, 456);
        hash.set(5046360, 453);
        hash.set(4522072, 451);
        hash.set(5111896, 454);
        hash.set(5177432, 452);
        hash.set(5767257, 459);
        hash.set(4456537, 460);
        hash.set(4522073, 461);
        hash.set(5046361, 462);
        hash.set(5111897, 463);
        hash.set(5177433, 464);
        hash.set(4587609, 465);
        hash.set(5242969, 466);
     hash.clr(4456537);
     hash.clr(5046361);
     hash.clr(5111897);
     hash.clr(5767257);
     hash.clr(4522073);
     hash.clr(4587609);
     hash.clr(5177433);
     hash.clr(5242969);
        hash.set(5767257, 466);
        hash.set(4456537, 464);
        hash.set(4522073, 465);
        hash.set(5046361, 461);
        hash.set(5111897, 459);
        hash.set(5177433, 463);
        hash.set(4587609, 462);
        hash.set(5242969, 460);
        hash.set(5832794, 467);
        hash.set(4522074, 468);
        hash.set(4587610, 469);
        hash.set(5177434, 470);
        hash.set(5242970, 471);
     hash.clr(4522074);
     hash.clr(5177434);
     hash.clr(5832794);
     hash.clr(4587610);
     hash.clr(5242970);
        hash.set(5832794, 471);
        hash.set(4522074, 469);
        hash.set(4587610, 467);
        hash.set(5177434, 470);
        hash.set(5242970, 468);
        hash.set(5308507, 472);
        hash.set(5374043, 473);
        hash.set(5439579, 474);
     hash.clr(5308507);
     hash.clr(5374043);
     hash.clr(5439579);
        hash.set(5308507, 474);
        hash.set(5374043, 473);
        hash.set(5439579, 472);
        hash.set(5374044, 475);
        hash.set(5439580, 476);
        hash.set(5963868, 477);
     hash.clr(5374044);
     hash.clr(5439580);
     hash.clr(5963868);
        hash.set(5374044, 477);
        hash.set(5439580, 476);
        hash.set(5963868, 475);
        hash.set(5374045, 478);
        hash.set(5439581, 479);
        hash.set(5963869, 480);
        hash.set(6029405, 481);
        hash.set(5505117, 482);
     hash.clr(5374045);
     hash.clr(5963869);
     hash.clr(6029405);
     hash.clr(5439581);
     hash.clr(5505117);
        hash.set(5374045, 482);
        hash.set(5439581, 479);
        hash.set(5963869, 481);
        hash.set(6029405, 480);
        hash.set(5505117, 478);
        hash.set(5439582, 483);
        hash.set(5505118, 484);
        hash.set(6094942, 485);
        hash.set(5570654, 486);
     hash.clr(5439582);
     hash.clr(6094942);
     hash.clr(5505118);
     hash.clr(5570654);
        hash.set(5439582, 486);
        hash.set(5505118, 484);
        hash.set(6094942, 485);
        hash.set(5570654, 483);
        hash.set(5505119, 487);
        hash.set(5570655, 488);
        hash.set(6160479, 489);
        hash.set(5636191, 490);
        hash.set(5701727, 491);
     hash.clr(5505119);
     hash.clr(5570655);
     hash.clr(6160479);
     hash.clr(5636191);
     hash.clr(5701727);
        hash.set(5505119, 491);
        hash.set(5570655, 490);
        hash.set(6160479, 489);
        hash.set(5636191, 488);
        hash.set(5701727, 487);
        hash.set(5636192, 492);
        hash.set(5701728, 493);
        hash.set(6226016, 494);
        hash.set(5767264, 495);
     hash.clr(5636192);
     hash.clr(6226016);
     hash.clr(5701728);
     hash.clr(5767264);
        hash.set(5636192, 495);
        hash.set(5701728, 493);
        hash.set(6226016, 494);
        hash.set(5767264, 492);
        hash.set(5701729, 496);
        hash.set(5767265, 497);
        hash.set(6291553, 498);
        hash.set(5832801, 499);
     hash.clr(5701729);
     hash.clr(6291553);
     hash.clr(5767265);
     hash.clr(5832801);
        hash.set(5701729, 499);
        hash.set(5767265, 497);
        hash.set(6291553, 498);
        hash.set(5832801, 496);
        hash.set(5767266, 500);
        hash.set(5832802, 501);
        hash.set(6357090, 502);
     hash.clr(5767266);
     hash.clr(5832802);
     hash.clr(6357090);
        hash.set(5767266, 502);
        hash.set(5832802, 501);
        hash.set(6357090, 500);
        hash.set(5767267, 503);
        hash.set(5832803, 504);
        hash.set(6357091, 505);
        hash.set(6422627, 506);
        hash.set(5898339, 507);
     hash.clr(5767267);
     hash.clr(6357091);
     hash.clr(6422627);
     hash.clr(5832803);
     hash.clr(5898339);
        hash.set(5767267, 507);
        hash.set(5832803, 504);
        hash.set(6357091, 506);
        hash.set(6422627, 505);
        hash.set(5898339, 503);
        hash.set(5832804, 508);
        hash.set(5898340, 509);
        hash.set(6488164, 510);
     hash.clr(5832804);
     hash.clr(6488164);
     hash.clr(5898340);
        hash.set(5832804, 509);
        hash.set(5898340, 510);
        hash.set(6488164, 508);
        hash.set(1245234, 511);
        hash.set(1310770, 512);
//541 DEBUG Root                 line 1155 IntIntHashTable::_expand()    expand from 512 to 1024
        hash.set(1900594, 513);
        hash.set(1966130, 514);
        hash.set(1114161, 515);
        hash.set(1179697, 516);
        hash.set(1245233, 517);
        hash.set(1835057, 518);
        hash.set(1900593, 519);
        hash.set(1310769, 520);
        hash.set(1966129, 521);
        hash.set(1048624, 522);
        hash.set(1114160, 523);
        hash.set(1769520, 524);
        hash.set(1835056, 525);
        hash.set(1179696, 526);
        hash.set(1245232, 527);
        hash.set(1900592, 528);
        hash.set(983087, 529);
        hash.set(1048623, 530);
        hash.set(1703983, 531);
        hash.set(1769519, 532);
        hash.set(1114159, 533);
        hash.set(1835055, 534);
        hash.set(983086, 535);
        hash.set(1048622, 536);
        hash.set(1703982, 537);
        hash.set(1769518, 538);
        hash.set(917549, 539);
        hash.set(983085, 540);
        hash.set(1572909, 541);
        hash.set(1638445, 542);
        hash.set(852012, 543);
        hash.set(917548, 544);
        hash.set(1507372, 545);
        hash.set(1572908, 546);
        hash.set(983084, 547);
        hash.set(1638444, 548);
        hash.set(720939, 549);
        hash.set(786475, 550);
        hash.set(852011, 551);
        hash.set(1441835, 552);
        hash.set(1507371, 553);
        hash.set(917547, 554);
        hash.set(1572907, 555);
        hash.set(720938, 556);
        hash.set(1376298, 557);
        hash.set(1441834, 558);
        hash.set(786474, 559);
        hash.set(852010, 560);
        hash.set(1507370, 561);
        hash.set(1376297, 562);
        hash.set(720937, 563);
        hash.set(1441833, 564);
     hash.clr(2621499);
     hash.clr(2621509);
     hash.clr(2621510);
     hash.clr(2621500);
     hash.clr(2555961);
     hash.clr(2555962);
     hash.clr(2555972);
     hash.clr(2555973);
     hash.clr(2555974);
     hash.clr(2555963);
     hash.clr(2555964);
     hash.clr(2162739);
     hash.clr(2162740);
     hash.clr(2162750);
     hash.clr(2162752);
     hash.clr(2162741);
     hash.clr(2162742);
     hash.clr(2162751);
     hash.clr(2097214);
     hash.clr(2097215);
     hash.clr(2097203);
     hash.clr(2097204);
     hash.clr(2097205);
     hash.clr(2031677);
     hash.clr(2031669);
     hash.clr(2031678);
     hash.clr(2031679);
     hash.clr(2031667);
     hash.clr(2031668);
     hash.clr(2490436);
     hash.clr(2490437);
     hash.clr(2490425);
     hash.clr(2490426);
     hash.clr(2490427);
     hash.clr(2424888);
     hash.clr(2424899);
     hash.clr(2424891);
     hash.clr(2424900);
     hash.clr(2424901);
     hash.clr(2424889);
     hash.clr(2424890);
     hash.clr(2359351);
     hash.clr(2359362);
     hash.clr(2359363);
     hash.clr(2359364);
     hash.clr(2359352);
     hash.clr(2359353);
     hash.clr(2293825);
     hash.clr(2293814);
     hash.clr(2293824);
     hash.clr(2293826);
     hash.clr(2293827);
     hash.clr(2293815);
     hash.clr(2293816);
     hash.clr(2228287);
     hash.clr(2228277);
     hash.clr(2228288);
     hash.clr(2228289);
     hash.clr(2228278);
     hash.clr(2228279);
        hash.set(4522084, 245);
        hash.set(4587620, 234);
        hash.set(5177444, 323);
        hash.set(5242980, 315);
        hash.set(4456547, 223);
        hash.set(4522083, 299);
        hash.set(5046371, 252);
        hash.set(5111907, 244);
        hash.set(5177443, 336);
        hash.set(4587619, 329);
        hash.set(5242979, 312);
        hash.set(4456546, 233);
        hash.set(4522082, 322);
        hash.set(5046370, 260);
        hash.set(5111906, 249);
        hash.set(5177442, 350);
        hash.set(4391009, 338);
        hash.set(4456545, 328);
        hash.set(4980833, 241);
        hash.set(5046369, 266);
        hash.set(4522081, 256);
        hash.set(5111905, 360);
        hash.set(5177441, 346);
        hash.set(4325472, 275);
        hash.set(4391008, 335);
        hash.set(4915296, 248);
        hash.set(4980832, 271);
        hash.set(4456544, 265);
        hash.set(5046368, 257);
        hash.set(4194399, 362);
        hash.set(4259935, 342);
        hash.set(4849759, 221);
        hash.set(4915295, 215);
        hash.set(4325471, 303);
        hash.set(4391007, 293);
        hash.set(4980831, 230);
        hash.set(4128862, 283);
        hash.set(4194398, 226);
        hash.set(4784222, 220);
        hash.set(4849758, 213);
        hash.set(4259934, 305);
        hash.set(4915294, 291);
        hash.set(4063325, 300);
        hash.set(4128861, 237);
        hash.set(4653149, 229);
        hash.set(4718685, 313);
        hash.set(4784221, 290);
        hash.set(4194397, 219);
        hash.set(4849757, 210);
        hash.set(4063324, 279);
        hash.set(4128860, 274);
        hash.set(4653148, 368);
        hash.set(4718684, 357);
        hash.set(4784220, 340);
        hash.set(3997787, 264);
        hash.set(4063323, 255);
        hash.set(4653147, 277);
        hash.set(4128859, 366);
        hash.set(4718683, 356);
        hash.set(4784219, 268);
		
     hash.clr(4522084);
     hash.clr(5177444);
     hash.clr(5832804);
     hash.clr(6488164);
     hash.clr(4587620);
     hash.clr(5242980);
     hash.clr(5898340);
     hash.clr(4456547);
     hash.clr(5046371);
     hash.clr(5111907);
     hash.clr(5767267);
     hash.clr(6357091);
     hash.clr(6422627);
     hash.clr(4522083);
     hash.clr(4587619);
     hash.clr(5177443);
     hash.clr(5242979);
     hash.clr(5832803);
     hash.clr(5898339);
     hash.clr(4456546);
     hash.clr(4522082);
     hash.clr(5046370);
     hash.clr(5111906);
     hash.clr(5177442);
     hash.clr(5767266);
     hash.clr(5832802);
     hash.clr(6357090);
     hash.clr(4391009);
     hash.clr(4980833);
     hash.clr(5701729);
     hash.clr(6291553);
     hash.clr(4456545);
     hash.clr(4522081);
     hash.clr(5046369);
     hash.clr(5111905);
     hash.clr(5177441);
     hash.clr(5767265);
     hash.clr(5832801);
     hash.clr(4325472);
     hash.clr(4915296);
     hash.clr(5636192);
     hash.clr(6226016);
     hash.clr(4391008);
     hash.clr(4456544);
     hash.clr(4980832);
     hash.clr(5046368);
     hash.clr(5701728);
     hash.clr(5767264);
     hash.clr(4194399);
     hash.clr(4259935);
     hash.clr(4849759);
     hash.clr(5505119);
     hash.clr(5570655);
     hash.clr(6160479);
     hash.clr(4325471);
     hash.clr(4391007);
     hash.clr(4915295);
     hash.clr(4980831);
     hash.clr(5636191);
     hash.clr(5701727);
     hash.clr(4128862);
     hash.clr(4784222);
     hash.clr(5439582);
     hash.clr(6094942);
     hash.clr(4194398);
     hash.clr(4259934);
     hash.clr(4849758);
     hash.clr(4915294);
     hash.clr(5505118);
     hash.clr(5570654);
     hash.clr(4063325);
     hash.clr(4653149);
     hash.clr(4718685);
     hash.clr(5374045);
     hash.clr(5963869);
     hash.clr(6029405);
     hash.clr(4128861);
     hash.clr(4194397);
     hash.clr(4784221);
     hash.clr(4849757);
     hash.clr(5439581);
     hash.clr(5505117);
     hash.clr(4063324);
     hash.clr(4128860);
     hash.clr(4653148);
     hash.clr(4718684);
     hash.clr(4784220);
     hash.clr(5374044);
     hash.clr(5439580);
     hash.clr(5963868);
     hash.clr(3997787);
     hash.clr(5308507);
     hash.clr(4063323);
     hash.clr(4128859);
     hash.clr(4653147);
     hash.clr(4718683);
     hash.clr(4784219);
     hash.clr(5374043);
     hash.clr(5439579);
     hash.clr(4522074);
     hash.clr(5177434);
     hash.clr(5832794);
     hash.clr(4587610);
     hash.clr(5242970);
     hash.clr(4456537);
     hash.clr(5046361);
     hash.clr(5111897);
     hash.clr(5767257);
     hash.clr(4522073);
     hash.clr(4587609);
     hash.clr(5177433);
     hash.clr(5242969);
     hash.clr(4391000);
     hash.clr(4980824);
     hash.clr(5701720);
     hash.clr(4456536);
     hash.clr(4522072);
     hash.clr(5046360);
     hash.clr(5111896);
     hash.clr(5177432);
     hash.clr(4325463);
     hash.clr(4915287);
     hash.clr(5636183);
     hash.clr(4390999);
     hash.clr(4456535);
     hash.clr(4980823);
     hash.clr(5046359);
     hash.clr(4325462);
     hash.clr(4390998);
     hash.clr(4915286);
     hash.clr(4980822);
     hash.clr(4194389);
     hash.clr(4259925);
     hash.clr(4849749);
     hash.clr(4915285);
     hash.clr(5505109);
     hash.clr(4128852);
     hash.clr(4784212);
     hash.clr(5439572);
     hash.clr(4194388);
     hash.clr(4259924);
     hash.clr(4849748);
     hash.clr(4915284);
     hash.clr(4063315);
     hash.clr(4653139);
     hash.clr(4718675);
     hash.clr(5374035);
     hash.clr(4128851);
     hash.clr(4194387);
     hash.clr(4784211);
     hash.clr(4849747);
     hash.clr(3997778);
     hash.clr(5308498);
     hash.clr(4063314);
     hash.clr(4128850);
     hash.clr(4653138);
     hash.clr(4718674);
     hash.clr(4784210);
     hash.clr(3997777);
     hash.clr(4063313);
     hash.clr(4653137);
     hash.clr(4522064);
     hash.clr(5177424);
     hash.clr(4587600);
     hash.clr(4456527);
     hash.clr(5046351);
     hash.clr(5111887);
     hash.clr(4522063);
     hash.clr(4587599);
     hash.clr(4456526);
     hash.clr(4522062);
     hash.clr(5046350);
     hash.clr(4390989);
     hash.clr(4980813);
     hash.clr(4456525);
     hash.clr(4522061);
     hash.clr(4325452);
     hash.clr(4915276);
     hash.clr(4390988);
     hash.clr(4456524);
     hash.clr(4194379);
     hash.clr(4259915);
     hash.clr(4849739);
     hash.clr(4325451);
     hash.clr(4390987);
     hash.clr(4128842);
     hash.clr(4784202);
     hash.clr(4194378);
     hash.clr(4259914);
     hash.clr(4063305);
     hash.clr(4653129);
     hash.clr(4718665);
     hash.clr(4128841);
     hash.clr(4194377);
     hash.clr(4063304);
     hash.clr(4128840);
     hash.clr(4653128);
     hash.clr(3997767);
     hash.clr(4063303);
     hash.clr(4128839);
     hash.clr(4522054);
     hash.clr(3211334);
     hash.clr(3866694);
     hash.clr(3932230);
     hash.clr(3276870);
     hash.clr(4456517);
     hash.clr(3801157);
     hash.clr(3145797);
     hash.clr(3735621);
     hash.clr(3866693);
     hash.clr(3932229);
     hash.clr(3211333);
     hash.clr(3276869);
     hash.clr(4390980);
     hash.clr(3080260);
     hash.clr(3670084);
     hash.clr(3866692);
     hash.clr(3735620);
     hash.clr(3801156);
     hash.clr(3145796);
     hash.clr(3211332);
     hash.clr(4325443);
     hash.clr(3014723);
     hash.clr(3604547);
     hash.clr(3670083);
     hash.clr(3735619);
     hash.clr(3080259);
     hash.clr(3145795);
     hash.clr(3604546);
     hash.clr(3670082);
     hash.clr(3014722);
     hash.clr(3080258);
     hash.clr(4194369);
     hash.clr(3604545);
     hash.clr(2883649);
     hash.clr(2949185);
     hash.clr(3539009);
     hash.clr(4128832);
     hash.clr(2818112);
     hash.clr(3473472);
     hash.clr(3539008);
     hash.clr(3604544);
     hash.clr(2883648);
     hash.clr(2949184);
     hash.clr(4063295);
     hash.clr(3407935);
     hash.clr(2752575);
     hash.clr(3342399);
     hash.clr(3539007);
     hash.clr(3473471);
     hash.clr(2818111);
     hash.clr(2883647);
     hash.clr(3997758);
     hash.clr(2687038);
     hash.clr(3473470);
     hash.clr(3342398);
     hash.clr(3407934);
     hash.clr(2752574);
     hash.clr(2818110);
     hash.clr(3342397);
     hash.clr(2687037);
     hash.clr(2752573);
     hash.clr(3866684);
     hash.clr(3211324);
     hash.clr(3276860);
     hash.clr(3735611);
     hash.clr(3801147);
     hash.clr(3145787);
     hash.clr(3211323);
     hash.clr(3276859);
     hash.clr(3211322);
     hash.clr(3735610);
     hash.clr(3145786);
     hash.clr(3670073);
     hash.clr(3080249);
     hash.clr(3211321);
     hash.clr(3145785);
     hash.clr(3604536);
     hash.clr(3014712);
     hash.clr(3080248);
     hash.clr(3145784);
     hash.clr(3538999);
     hash.clr(2949175);
     hash.clr(2883639);
     hash.clr(3014711);
     hash.clr(3080247);
     hash.clr(3473462);
     hash.clr(2818102);
     hash.clr(2883638);
     hash.clr(2949174);
     hash.clr(3342389);
     hash.clr(3407925);
     hash.clr(2752565);
     hash.clr(2883637);
     hash.clr(2818101);
     hash.clr(2818100);
     hash.clr(3342388);
     hash.clr(2752564);
     hash.clr(2687027);
     hash.clr(2818099);
     hash.clr(2752563);
     hash.clr(1245234);
     hash.clr(1900594);
     hash.clr(2555954);
     hash.clr(3211314);
     hash.clr(1310770);
     hash.clr(1966130);
     hash.clr(2621490);
     hash.clr(1114161);
	 
	  assertTrue(true);
	}*/
	
	/*function testBug2()
	{
		var ht = new IntIntHashTable(32, 32);
		ht.set(resolve(28), 28);
		ht.clr(resolve(28));
		ht.set(resolve(49), 49);
		ht.set(resolve(75), 75);
		ht.set(resolve(86), 86);
		ht.set(resolve(97), 97);
		ht.set(resolve(108), 108);
		ht.set(resolve(119), 119);
		ht.set(resolve(130), 130);
		ht.set(resolve(139), 139);
		ht.set(resolve(159), 159);
		ht.clr(resolve(49));
		ht.clr(resolve(75));
		ht.clr(resolve(86));
		ht.clr(resolve(97));
		ht.clr(resolve(108));
		ht.clr(resolve(119));
		ht.clr(resolve(130));
		ht.set(resolve(291), 291);
		ht.set(resolve(305), 305);
		ht.clr(resolve(305));
		ht.set(resolve(316), 316);
		ht.set(resolve(327), 327);
		ht.clr(resolve(316));
		ht.clr(resolve(327));
		ht.set(resolve(316), 316);
		ht.set(resolve(338), 338);
		ht.clr(resolve(316));
		ht.clr(resolve(338));
		ht.set(resolve(316), 316);
		ht.set(resolve(349), 349);
		ht.clr(resolve(316));
		ht.clr(resolve(349));
		ht.set(resolve(316), 316);
		ht.clr(resolve(316));
		ht.set(resolve(392), 392);
		ht.clr(resolve(392));
		ht.set(resolve(403), 403);
		ht.set(resolve(414), 414);
		ht.clr(resolve(403));
		ht.clr(resolve(414));
		ht.set(resolve(403), 403);
		ht.clr(resolve(403));
		ht.set(resolve(456), 456);
		ht.set(resolve(467), 467);
		ht.set(resolve(478), 478);
		ht.set(resolve(489), 489);
		ht.set(resolve(500), 500);
		ht.set(resolve(511), 511);
		ht.set(resolve(522), 522);
		ht.set(resolve(533), 533);
		ht.set(resolve(544), 544);
		ht.set(resolve(555), 555);
		ht.set(resolve(566), 566);
		ht.set(resolve(577), 577);
		ht.set(resolve(445), 445);
		ht.clr(resolve(445));
		ht.set(resolve(588), 588);
		ht.set(resolve(164), 164);
		ht.set(resolve(591), 591);
		ht.clr(resolve(591));
		ht.set(resolve(238), 238);
		ht.set(resolve(179), 179);
		ht.set(resolve(163), 163);
		ht.clr(resolve(163));
		ht.set(resolve(180), 180);
		ht.set(resolve(163), 163);
		ht.clr(resolve(163));
		ht.set(resolve(181), 181);
		ht.set(resolve(163), 163);
		ht.clr(resolve(163));
		ht.set(resolve(182), 182);
		ht.set(resolve(163), 163);
		ht.clr(resolve(163));
		ht.set(resolve(183), 183);
		ht.set(resolve(163), 163);
		ht.clr(resolve(163));
		ht.set(resolve(209), 209);
		ht.set(resolve(208), 208);
		ht.set(resolve(211), 211);
		ht.set(resolve(210), 210);
		ht.set(resolve(213), 213);
		ht.set(resolve(212), 212);
		ht.set(resolve(215), 215);
		ht.set(resolve(214), 214);
		ht.set(resolve(217), 217);
		ht.set(resolve(216), 216);
		ht.set(resolve(610), 610);
		ht.clr(resolve(179));
		ht.clr(resolve(180));
		ht.clr(resolve(181));
		ht.clr(resolve(182));
		ht.clr(resolve(183));
		ht.clr(resolve(610));
		ht.set(resolve(613), 613);
		ht.clr(resolve(215));
		ht.clr(resolve(214));
		ht.clr(resolve(213));
		ht.clr(resolve(212));
		ht.clr(resolve(613));
		ht.clr(resolve(238));
		ht.set(resolve(238), 238);
		ht.clr(resolve(217));
		ht.clr(resolve(216));
		ht.clr(resolve(211));
		ht.clr(resolve(210));
		ht.clr(resolve(209));
		ht.clr(resolve(208));
		ht.set(resolve(182), 182);
		ht.set(resolve(163), 163);
		ht.set(resolve(181), 181);
		ht.clr(resolve(163));
		ht.set(resolve(180), 180);
		ht.set(resolve(163), 163);
		ht.clr(resolve(163));
		ht.set(resolve(179), 179);
		ht.set(resolve(163), 163);
		ht.clr(resolve(163));
		ht.clr(resolve(182));
		ht.clr(resolve(181));
		ht.clr(resolve(180));
		ht.clr(resolve(179));
		ht.set(resolve(179), 179);
		ht.set(resolve(163), 163);
		ht.set(resolve(180), 180);
		ht.clr(resolve(163));
		ht.set(resolve(181), 181);
		ht.set(resolve(163), 163);
		ht.set(resolve(236), 236);
		ht.clr(resolve(163));
		ht.set(resolve(182), 182);
		ht.set(resolve(163), 163);
		ht.set(resolve(184), 184);
		ht.clr(resolve(163));
		ht.set(resolve(185), 185);
		ht.set(resolve(163), 163);
		ht.clr(resolve(163));
		ht.set(resolve(209), 209);
		ht.set(resolve(208), 208);
		ht.set(resolve(211), 211);
		ht.set(resolve(210), 210);
		ht.set(resolve(217), 217);
		ht.set(resolve(216), 216);
		ht.set(resolve(213), 213);
		ht.set(resolve(212), 212);
		ht.set(resolve(215), 215);
		ht.set(resolve(214), 214);
		ht.set(resolve(219), 219);
		ht.set(resolve(218), 218);
		ht.clr(resolve(236));
		ht.set(resolve(627), 627);
		ht.clr(resolve(179));
		ht.clr(resolve(180));
		ht.clr(resolve(181));
		ht.clr(resolve(182));
		ht.clr(resolve(185));
		ht.clr(resolve(184));
		ht.clr(resolve(627));
		ht.set(resolve(630), 630);
		ht.clr(resolve(213));
		ht.clr(resolve(212));
		ht.clr(resolve(219));
		ht.clr(resolve(218));
		ht.clr(resolve(217));
		ht.clr(resolve(216));
		ht.clr(resolve(630));
		ht.clr(resolve(238));
		ht.set(resolve(238), 238);
		ht.clr(resolve(211));
		ht.clr(resolve(210));
		ht.clr(resolve(215));
		ht.clr(resolve(214));
		ht.clr(resolve(209));
		ht.clr(resolve(208));
		ht.set(resolve(182), 182);
		ht.set(resolve(163), 163);
		ht.clr(resolve(163));
		ht.set(resolve(181), 181);
		ht.set(resolve(163), 163);
		ht.clr(resolve(163));
		ht.set(resolve(180), 180);
		ht.set(resolve(163), 163);
		ht.set(resolve(179), 179);
		ht.set(resolve(186), 186);
		ht.clr(resolve(163));
		ht.set(resolve(187), 187);
		ht.set(resolve(163), 163);
		ht.clr(resolve(163));
		ht.set(resolve(188), 188);
		ht.set(resolve(163), 163);
		ht.set(resolve(189), 189);
		ht.clr(resolve(163));
		ht.set(resolve(209), 209);
		ht.set(resolve(208), 208);
		ht.set(resolve(215), 215);
		ht.set(resolve(214), 214);
		ht.set(resolve(211), 211);
		ht.set(resolve(210), 210);
		ht.set(resolve(217), 217);
		ht.set(resolve(216), 216);
		ht.set(resolve(219), 219);
		ht.set(resolve(218), 218);
		ht.set(resolve(213), 213);
		ht.set(resolve(212), 212);
		ht.set(resolve(221), 221);
		ht.set(resolve(220), 220);
		ht.set(resolve(223), 223);
		ht.set(resolve(222), 222);
		ht.set(resolve(642), 642);
		ht.clr(resolve(182));
		ht.clr(resolve(181));
		ht.clr(resolve(180));
		ht.clr(resolve(179));
		ht.clr(resolve(186));
		ht.clr(resolve(187));
		ht.clr(resolve(189));
		ht.clr(resolve(188));
		ht.clr(resolve(642));
		ht.set(resolve(645), 645);
		ht.clr(resolve(215));
		ht.clr(resolve(214));
		ht.clr(resolve(223));
		ht.clr(resolve(222));
		ht.clr(resolve(221));
		ht.clr(resolve(220));
		ht.clr(resolve(217));
		ht.clr(resolve(216));
		ht.clr(resolve(219));
		ht.clr(resolve(218));
		ht.clr(resolve(213));
		ht.clr(resolve(212));
		ht.clr(resolve(211));
		ht.clr(resolve(210));
		ht.clr(resolve(209));
		ht.clr(resolve(208));
		ht.clr(resolve(645));
		ht.clr(resolve(238));
		ht.set(resolve(238), 238);
		ht.set(resolve(188), 188);
		ht.set(resolve(163), 163);
		ht.clr(resolve(163));
		ht.set(resolve(187), 187);
		ht.set(resolve(163), 163);
		ht.clr(resolve(163));
		ht.set(resolve(186), 186);
		ht.set(resolve(163), 163);
		ht.clr(resolve(163));
		ht.set(resolve(179), 179);
		ht.set(resolve(163), 163);
		ht.clr(resolve(163));
		ht.set(resolve(180), 180);
		ht.set(resolve(163), 163);
		ht.set(resolve(181), 181);
		ht.clr(resolve(163));
		ht.set(resolve(182), 182);
		ht.set(resolve(163), 163);
		ht.set(resolve(190), 190);
		ht.set(resolve(191), 191);
		ht.clr(resolve(163));
		ht.set(resolve(209), 209);
		ht.set(resolve(208), 208);
		ht.set(resolve(211), 211);
		ht.set(resolve(210), 210);
		ht.set(resolve(213), 213);
		ht.set(resolve(212), 212);
		ht.set(resolve(219), 219);
		ht.set(resolve(218), 218);
		ht.set(resolve(217), 217);
		ht.set(resolve(216), 216);
		ht.set(resolve(221), 221);
		ht.set(resolve(220), 220);
		ht.set(resolve(223), 223);
		ht.set(resolve(222), 222);
		ht.set(resolve(215), 215);
		ht.set(resolve(214), 214);
		ht.set(resolve(225), 225);
		ht.set(resolve(224), 224);
		ht.set(resolve(658), 658);
		ht.clr(resolve(188));
		ht.clr(resolve(187));
		ht.clr(resolve(186));
		ht.clr(resolve(179));
		ht.clr(resolve(180));
		ht.clr(resolve(181));
		ht.clr(resolve(182));
		ht.clr(resolve(190));
		ht.clr(resolve(191));
		ht.clr(resolve(658));
		ht.set(resolve(661), 661);
		ht.clr(resolve(213));
		ht.clr(resolve(212));
		ht.clr(resolve(209));
		ht.clr(resolve(208));
		ht.clr(resolve(211));
		ht.clr(resolve(210));
		ht.clr(resolve(219));
		ht.clr(resolve(218));
		ht.clr(resolve(221));
		ht.clr(resolve(220));
		ht.clr(resolve(223));
		ht.clr(resolve(222));
		ht.clr(resolve(661));
		ht.clr(resolve(238));
		ht.set(resolve(238), 238);
		ht.clr(resolve(215));
		ht.clr(resolve(214));
		ht.clr(resolve(225));
		ht.clr(resolve(224));
		ht.clr(resolve(217));
		ht.clr(resolve(216));
		ht.set(resolve(189), 189);
		ht.set(resolve(163), 163);
		ht.clr(resolve(163));
		ht.set(resolve(191), 191);
		ht.set(resolve(163), 163);
		ht.clr(resolve(163));
		ht.set(resolve(190), 190);
		ht.set(resolve(163), 163);
		ht.set(resolve(182), 182);
		ht.clr(resolve(163));
		ht.set(resolve(181), 181);
		ht.set(resolve(163), 163);
		ht.clr(resolve(163));
		ht.set(resolve(180), 180);
		ht.set(resolve(163), 163);
		ht.set(resolve(179), 179);
		ht.set(resolve(186), 186);
		ht.clr(resolve(163));
		ht.set(resolve(217), 217);
		ht.set(resolve(216), 216);
		ht.set(resolve(225), 225);
		ht.set(resolve(224), 224);
		ht.set(resolve(215), 215);
		ht.set(resolve(214), 214);
		ht.set(resolve(223), 223);
		ht.set(resolve(222), 222);
		ht.set(resolve(221), 221);
		ht.set(resolve(220), 220);
		ht.set(resolve(219), 219);
		ht.set(resolve(218), 218);
		ht.set(resolve(211), 211);
		ht.set(resolve(210), 210);
		ht.set(resolve(209), 209);
		ht.set(resolve(208), 208);
		ht.set(resolve(673), 673);
		ht.clr(resolve(189));
		ht.clr(resolve(191));
		ht.clr(resolve(190));
		ht.clr(resolve(182));
		ht.clr(resolve(181));
		ht.clr(resolve(180));
		ht.clr(resolve(179));
		ht.clr(resolve(186));
		ht.clr(resolve(673));
		ht.set(resolve(676), 676);
		ht.clr(resolve(221));
		ht.clr(resolve(220));
		ht.clr(resolve(217));
		ht.clr(resolve(216));
		ht.clr(resolve(215));
		ht.clr(resolve(214));
		ht.clr(resolve(209));
		ht.clr(resolve(208));
		ht.clr(resolve(225));
		ht.clr(resolve(224));
		ht.clr(resolve(223));
		ht.clr(resolve(222));
		ht.clr(resolve(219));
		ht.clr(resolve(218));
		ht.clr(resolve(676));
		ht.clr(resolve(238));
		ht.set(resolve(238), 238);
		ht.clr(resolve(211));
		ht.clr(resolve(210));
		ht.set(resolve(183), 183);
		ht.set(resolve(163), 163);
		ht.set(resolve(185), 185);
		ht.clr(resolve(163));
		ht.set(resolve(184), 184);
		ht.set(resolve(163), 163);
		ht.set(resolve(186), 186);
		ht.set(resolve(179), 179);
		ht.clr(resolve(163));
		ht.set(resolve(211), 211);
		ht.set(resolve(210), 210);
		ht.set(resolve(219), 219);
		ht.set(resolve(218), 218);
		ht.set(resolve(223), 223);
		ht.set(resolve(222), 222);
		ht.set(resolve(225), 225);
		ht.set(resolve(224), 224);
		ht.set(resolve(209), 209);
		ht.set(resolve(208), 208);
		ht.set(resolve(685), 685);
		ht.clr(resolve(183));
		ht.clr(resolve(185));
		ht.clr(resolve(184));
		ht.clr(resolve(186));
		ht.clr(resolve(179));
		ht.clr(resolve(685));
		ht.set(resolve(688), 688);
		ht.clr(resolve(219));
		ht.clr(resolve(218));
		ht.clr(resolve(209));
		ht.clr(resolve(208));
		ht.clr(resolve(223));
		ht.clr(resolve(222));
		ht.clr(resolve(225));
		ht.clr(resolve(224));
		ht.clr(resolve(688));
		ht.clr(resolve(238));
		ht.set(resolve(238), 238);
		ht.clr(resolve(211));
		ht.clr(resolve(210));
		ht.set(resolve(184), 184);
		ht.set(resolve(163), 163);
		ht.clr(resolve(163));
		ht.set(resolve(185), 185);
		ht.set(resolve(163), 163);
		ht.clr(resolve(163));
		ht.set(resolve(183), 183);
		ht.set(resolve(163), 163);
		ht.clr(resolve(163));
		ht.set(resolve(180), 180);
		ht.set(resolve(163), 163);
		ht.clr(resolve(163));
		ht.set(resolve(181), 181);
		ht.set(resolve(163), 163);
		ht.clr(resolve(163));
		ht.set(resolve(182), 182);
		ht.set(resolve(163), 163);
		ht.set(resolve(190), 190);
		ht.clr(resolve(163));
		ht.set(resolve(211), 211);
		ht.set(resolve(210), 210);
		ht.set(resolve(225), 225);
		ht.set(resolve(224), 224);
		ht.set(resolve(223), 223);
		ht.set(resolve(222), 222);
		ht.set(resolve(209), 209);
		ht.set(resolve(208), 208);
		ht.set(resolve(219), 219);
		ht.set(resolve(218), 218);
		ht.set(resolve(215), 215);
		ht.set(resolve(214), 214);
		ht.set(resolve(217), 217);
		ht.set(resolve(216), 216);
		ht.set(resolve(699), 699);
		ht.clr(resolve(184));
		ht.clr(resolve(185));
		ht.clr(resolve(183));
		ht.clr(resolve(180));
		ht.clr(resolve(181));
		ht.clr(resolve(182));
		ht.clr(resolve(190));
		ht.clr(resolve(699));
		ht.set(resolve(702), 702);
		ht.clr(resolve(164));
		ht.clr(resolve(217));
		ht.clr(resolve(216));
		ht.clr(resolve(215));
		ht.clr(resolve(214));
		ht.clr(resolve(209));
		ht.clr(resolve(208));
		ht.clr(resolve(223));
		ht.clr(resolve(222));
		ht.clr(resolve(211));
		ht.clr(resolve(210));
		ht.clr(resolve(702));
		ht.clr(resolve(238));
		ht.set(resolve(238), 238);
		ht.clr(resolve(219));
		ht.clr(resolve(218));
		ht.clr(resolve(225));
		ht.clr(resolve(224));
		ht.set(resolve(190), 190);
		ht.set(resolve(163), 163);
		ht.set(resolve(182), 182);
		ht.set(resolve(181), 181);
		ht.clr(resolve(163));
		ht.set(resolve(180), 180);
		ht.set(resolve(163), 163);
		ht.clr(resolve(163));
		ht.set(resolve(183), 183);
		ht.set(resolve(163), 163);
		ht.clr(resolve(163));
		ht.set(resolve(185), 185);
		ht.set(resolve(163), 163);
		ht.set(resolve(184), 184);
		ht.clr(resolve(163));
		ht.set(resolve(225), 225);
		ht.set(resolve(224), 224);
		ht.set(resolve(219), 219);
		ht.set(resolve(218), 218);
		ht.set(resolve(211), 211);
		ht.set(resolve(210), 210);
		ht.set(resolve(223), 223);
		ht.set(resolve(222), 222);
		ht.set(resolve(209), 209);
		ht.set(resolve(208), 208);
		ht.set(resolve(215), 215);
		ht.set(resolve(214), 214);
		ht.set(resolve(217), 217);
		ht.set(resolve(216), 216);
		ht.set(resolve(713), 713);
		ht.clr(resolve(190));
		ht.clr(resolve(182));
		ht.clr(resolve(181));
		ht.clr(resolve(180));
		ht.clr(resolve(183));
		ht.clr(resolve(185));
		ht.clr(resolve(184));
		ht.clr(resolve(713));
		ht.clr(resolve(456));
		ht.clr(resolve(467));
		ht.clr(resolve(478));
		ht.clr(resolve(489));
		ht.clr(resolve(500));
		ht.clr(resolve(511));
		ht.clr(resolve(522));
		ht.clr(resolve(533));
		ht.clr(resolve(544));
		ht.clr(resolve(555));
		ht.clr(resolve(566));
		ht.clr(resolve(577));
		ht.clr(resolve(238));
		ht.clr(resolve(211));
		
		var keys = ht.toKeyArray();
		var da = ArrayConvert.toDA(keys);
		da.remove(210);
		
		ht.clr(resolve(210));
		
		for (key in ht.keys())
			assertTrue(ht.hasKey(key));
			
		for (key in ht.keys())
		{
			assertTrue(ht.hasKey(da.popBack()));
		}
		assertTrue(da.isEmpty());
		
		//ht.dump();
	}*/
	#end
	inline function resolve(i:Int) { return i; }
	
	function clrAll(h:IntIntHashTable, key:Int):Bool
	{
		if (h.clr(key))
		{
			while (h.clr(key)) {}
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