import de.polygonal.ds.Collection;
import de.polygonal.ds.ListSet;
import de.polygonal.ds.Set;

class TestListSet extends AbstractTest
{
	function testSource()
	{
		var s = new ListSet<String>(["a", "b", "c", "a", "b", "c"]);
		assertEquals(3, s.size);
		assertTrue(s.has("a"));
		assertTrue(s.has("b"));
		assertTrue(s.has("c"));
	}
	
	function test()
	{
		var s1 = new ListSet<String>();
		
		s1.set("a");
		assertTrue(s1.has("a"));
		assertEquals(1, s1.size);
		
		var s2 = new ListSet<String>();
		s2.set("b");
		assertEquals(s2.contains("b"), true);
		assertTrue(s2.has("b"));
		
		s1.merge(s2, true);
		assertEquals(2, s1.size);
		assertTrue(s1.contains("b"));
		assertTrue(s1.has("b"));
		s1.remove("b");
		
		assertEquals(1, s1.size);
		s1.merge(s2, false, function(val:String) { return val; });
		
		assertTrue(s1.contains("b"));
		assertEquals(2, s1.size);
		
		s1.remove("a");
		s1.remove("b");
		assertTrue(s1.isEmpty());
	}
	
	function testClone()
	{
		var s1 = new ListSet<String>();
		s1.set("a");
		s1.set("b");
		s1.set("c");
		
		var s2 = s1.clone(true);
		assertTrue(s2.contains("a"));
		assertTrue(s2.contains("b"));
		assertTrue(s2.contains("c"));
		assertEquals(3, s2.size);
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
		
		var itr = S.iterator();
		
		for (i in itr) assertEquals(true, c.remove(i));
		
		itr.reset();
		
		var c:de.polygonal.ds.Set<Int> = cast s.clone(true);
		for (i in itr) assertEquals(true, c.remove(i));
	}
	
	function testIter()
	{
		var s = new ListSet<Int>();
		for (i in 0...4) s.set(i);
		var i = 0;
		s.iter(function(e) assertEquals(i++, e));
	}
	
	function testCollection()
	{
		var c:de.polygonal.ds.Collection<String> = new ListSet<String>();
		assertEquals(true, true);
	}
	
	function testReserve()
	{
		var s = new ListSet<Null<Int>>(2);
		s.reserve(20);
		assertEquals(20, s.capacity);
		for (i in 0...20) s.set(i);
		for (i in 0...20) assertTrue(s.has(i));
	}
	
	function testPack()
	{
		var s = new ListSet<Null<Int>>(2);
		for (i in 0...16) s.set(i);
		for (i in 0...8) s.remove(i);
		s.pack();
		for (i in 8...16) assertTrue(s.has(i));
	}
}