package;

import de.polygonal.ds.Collection;
import de.polygonal.ds.ListSet;
import de.polygonal.ds.Set;

class TestListSet extends haxe.unit.TestCase
{
	function test()
	{
		var s1 = new ListSet<String>();
		
		s1.set('a');
		assertEquals(s1.contains('a'), true);
		assertTrue(s1.has('a'));
		assertEquals(1, s1.size());
		
		var s2 = new ListSet<String>();
		s2.set('b');
		assertEquals(s2.contains('b'), true);
		assertTrue(s2.has('b'));
		
		s1.merge(s2, true);
		
		assertTrue(s1.contains('b'));
		assertTrue(s1.has('b'));
		s1.remove('b');
		
		s1.merge(s2, false, function(val:String) { return val; });
		
		assertTrue(s1.contains('b'));
		
		assertEquals(2, s1.size());
		
		s1.remove('a');
		s1.remove('b');
		
		assertTrue(s1.isEmpty());
	}
	
	function testClone()
	{
		var s1 = new ListSet<String>();
		s1.set('a');
		s1.set('b');
		s1.set('c');
		
		var s2 = s1.clone(true);
		assertTrue(s2.contains('a'));
		assertTrue(s2.contains('b'));
		assertTrue(s2.contains('c'));
		assertEquals(3, s2.size());
	}
	
	function testIterator()
	{
		var S = new ListSet<Int>();
		var s = new ListSet<Int>();
		for (i in 0...10)
		{
			s.set(i);
			S.set(i);
		}
		
		var c:de.polygonal.ds.Set<Int> = cast s.clone(true);
		
		var itr:de.polygonal.ds.ResettableIterator<Int> = cast S.iterator();
		
		for (i in itr) assertEquals(true, c.remove(i));
		
		itr.reset();
		
		var c:de.polygonal.ds.Set<Int> = cast s.clone(true);
		for (i in itr) assertEquals(true, c.remove(i));
	}
	
	function testCollection()
	{
		var c:de.polygonal.ds.Collection<String> = new ListSet<String>();
		assertEquals(true, true);
	}
}