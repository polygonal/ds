package;

import de.polygonal.ds.HashMap;
import de.polygonal.ds.Set;

class TestHashMap extends haxe.unit.TestCase
{
	function testRemove()
	{
		var h = new de.polygonal.ds.HashMap<String, Null<Int>>();
		for (i in 0...2)
		{
			h.set('a', 1);
			h.set('b', 1);
			h.set('c', 1);
			h.remove(1);
			assertFalse(h.has(1));
			assertFalse(h.hasKey('a'));
			assertFalse(h.hasKey('b'));
			assertFalse(h.hasKey('c'));
			assertEquals(0, h.size());
		}
		
		var h = new de.polygonal.ds.HashMap<String, Null<Int>>();
		h.set('a', 0);
		
		assertEquals(0, h.get('a'));
		h.remove(0);
		assertEquals(null, h.get('a'));
		assertEquals(0, h.size());
	}
	
	function testRemap()
	{
		var h = new de.polygonal.ds.HashMap < String, Null<Int> > ();
		
		h.set('a', 1);
		assertEquals(1, h.get('a'));
		assertEquals(1, h.size());
		
		var result = h.remap('a', 2);
		assertTrue(result);
		assertEquals(2, h.get('a'));
		assertEquals(1, h.size());
		
		h.set('b', 1);
		assertEquals(1, h.get('b'));
		assertEquals(2, h.size());
		
		var result = h.remap('b', 2);
		assertTrue(result);
		assertEquals(2, h.get('b'));
		assertEquals(2, h.size());
	}
	
	function testHasVal()
	{
		var h = new de.polygonal.ds.HashMap<String, Null<Int>>();
		h.set('a', 1);
		h.set('b', 2);
		h.set('c', 3);
		
		assertTrue(h.has(1));
		assertTrue(h.has(2));
		assertTrue(h.has(3));
		assertFalse(h.has(0));
		
		var h = new de.polygonal.ds.HashMap<Int, Int>();
		h.set(1, 1);
		h.set(2, 2);
		h.set(3, 3);
		
		assertTrue(h.has(1));
		assertTrue(h.has(2));
		assertTrue(h.has(3));
		assertFalse(h.has(0));
	}
	
	function testHasKey()
	{
		var h = new de.polygonal.ds.HashMap<String, Null<Int>>();
		h.set('a', 1);
		h.set('b', 2);
		h.set('c', 3);
		
		assertTrue(h.hasKey('a'));
		assertTrue(h.hasKey('b'));
		assertTrue(h.hasKey('c'));
		assertFalse(h.hasKey('d'));
		
		var h = new de.polygonal.ds.HashMap<Int, Int>();
		h.set(1, 1);
		h.set(2, 2);
		h.set(3, 3);
		
		assertTrue(h.hasKey(1));
		assertTrue(h.hasKey(2));
		assertTrue(h.hasKey(3));
		assertFalse(h.hasKey(0));
	}
	
	function testGetSet()
	{
		var h = new de.polygonal.ds.HashMap<String, Null<Int>>();
		assertTrue(h.set('a', 1));
		assertTrue(h.set('b', 2));
		assertTrue(h.set('c', 3));
		assertFalse(h.set('c', 3));
		
		assertEquals(1, h.get('a'));
		assertEquals(2, h.get('b'));
		assertEquals(3, h.get('c'));
		assertEquals(null, h.get('d'));
		
		var h = new de.polygonal.ds.HashMap<Int, Null<Int>>();
		h.set(1, 1);
		h.set(2, 2);
		h.set(3, 3);
		
		assertEquals(1, h.get(1));
		assertEquals(2, h.get(2));
		assertEquals(3, h.get(3));
		assertEquals(null, h.get(0));
		
		var h = new de.polygonal.ds.HashMap<Int, String>();
		h.set(1, 'a');
		h.set(2, 'b');
		h.set(3, 'c');
		
		assertEquals('a', h.get(1));
		assertEquals('b', h.get(2));
		assertEquals('c', h.get(3));
		assertEquals(null, h.get(0));
	}
	
	function testClr()
	{
		var h = new de.polygonal.ds.HashMap<String, Null<Int>>();
		assertTrue(h.set('a', 1));
		assertTrue(h.set('b', 2));
		assertTrue(h.set('c', 3));
		assertFalse(h.set('c', 3));
		
		assertTrue(h.clr('a'));
		assertTrue(h.clr('b'));
		assertTrue(h.clr('c'));
		assertFalse(h.clr('c'));
	}
	
	function testClear()
	{
		var h = new de.polygonal.ds.HashMap<String, Null<Int>>();
		h.set('a', 1);
		h.set('b', 2);
		h.set('c', 3);
		
		h.clear();
		
		assertEquals(0, h.size());
		assertFalse(h.has(1));
		assertFalse(h.has(2));
		assertFalse(h.has(3));
		
		assertFalse(h.hasKey('a'));
		assertFalse(h.hasKey('b'));
		assertFalse(h.hasKey('c'));
	}
	
	function testToValSet()
	{
		var h = new de.polygonal.ds.HashMap<String, Null<Int>>();
		h.set('a', 1);
		h.set('b', 2);
		h.set('c', 3);
		
		var s:Set<Int> = h.toValSet();
		assertEquals(3, s.size());
		assertTrue(s.contains(1));
		assertTrue(s.contains(2));
		assertTrue(s.contains(3));
	}
	
	function testToKeySet()
	{
		var h = new de.polygonal.ds.HashMap<String, Null<Int>>();
		h.set('a', 1);
		h.set('b', 2);
		h.set('c', 3);
		var s:Set<String> = h.toKeySet();
		assertEquals(3, s.size());
		assertTrue(s.contains('a'));
		assertTrue(s.contains('b'));
		assertTrue(s.contains('c'));
		
		var a = h.toKeyArray();
		assertEquals(3, s.size());
		
		var ref = ['a', 'b', 'c'];
		while (a.length > 0)
		{
			for (i in 0...a.length)
			{
				if (a[i] == ref[0])
				{
					ref.shift();
					a.splice(i, 1);
				}
			}
		}
		
		var a = h.toKeyDA();
		assertEquals(3, s.size());
		assertTrue(a.contains('a'));
		assertTrue(a.contains('b'));
		assertTrue(a.contains('c'));
	}
	
	function testClone()
	{
		var h:HashMap<String, String> = new HashMap<String, String>(true);
		h.set('key1a', 'val1');
		h.set('key1b', 'val1');
		h.set('key2', 'val2');
		h.set('key3', 'val3');
		
		var clone:de.polygonal.ds.HashMap<String, String> = untyped h.clone(true);
		assertEquals(clone.get('key1a'), 'val1');
		assertEquals(clone.get('key1b'), 'val1');
		assertEquals(clone.get('key2') , 'val2');
		assertEquals(clone.get('key3') , 'val3');
	}
	
	function testIterator()
	{
		var h:HashMap<Int, Int> = new HashMap<Int, Int>(true);
		var s = new de.polygonal.ds.ListSet<Int>();
		for (i in 0...10)
		{
			s.set(i);
			h.set(i * 10, i);
		}
		
		var c:de.polygonal.ds.Set<Int> = cast s.clone(true);
		var itr:de.polygonal.ds.ResettableIterator<Int> = cast h.iterator();
		
		for (i in itr) assertEquals(true, c.remove(i));
		
		itr.reset();
		var c:de.polygonal.ds.Set<Int> = cast s.clone(true);
		for (i in itr) assertEquals(true, c.remove(i));
		
		var h:HashMap<Int, Int> = new HashMap<Int, Int>(true);
		var s = new de.polygonal.ds.ListSet<Int>();
		for (key in 0...10)
		{
			s.set(key * 10);
			h.set(key * 10, key);
		}
		
		var c:de.polygonal.ds.Set<Int> = cast s.clone(true);
		var itr:de.polygonal.ds.ResettableIterator<Int> = cast h.keys();
		
		for (key in itr) assertEquals(true, c.remove(key));
		
		itr.reset();
		var c:de.polygonal.ds.Set<Int> = cast s.clone(true);
		for (i in itr) assertEquals(true, c.remove(i));
	}
	
	function testRemoveIterator()
	{
		var h:HashMap<Int, Int> = new HashMap<Int, Int>(true);
		for (i in 0...10) h.set(i, i);
		var itr = h.iterator();
		while (itr.hasNext())
		{
			var x = itr.next();
			itr.remove();
		}
		assertEquals(0, h.size());
		var h:HashMap<Int, Int> = new HashMap<Int, Int>(true);
		for (i in 0...10) h.set(i, i);
		var itr = h.keys();
		while (itr.hasNext())
		{
			var x = itr.next();
			itr.remove();
		}
		assertEquals(0, h.size());
	}
}