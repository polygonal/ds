import de.polygonal.ds.tools.FreeList;

class TestFreeList extends AbstractTest
{
	function test()
	{
		var i = 0;
		var list = new FreeList(16, function() return new E(i++));
		
		assertEquals(0, list.size);
		
		for (j in 0...list.capacity)
		{
			var id = list.next();
			assertEquals(j + 1, list.size);
			assertEquals(j, id);
			assertEquals(id, list.get(id).value);
		}
		assertEquals(-1, list.next());
		assertEquals(list.capacity, list.size);
		
		for (j in 0...list.capacity)
		{
			list.put(j);
			assertEquals(list.capacity - (j + 1), list.size);
		}
		assertEquals(0, list.size);
		
		for (j in 0...list.capacity)
		{
			var id = list.next();
			assertEquals(16 - (j + 1), id);
		}
	}
}

private class E
{
	public var value:Int;
	
	public function new(value:Int)
	{
		this.value = value;
	}
}