class TestObjectPool extends AbstractTest
{
	function test()
	{
		var counter = 0;
		var create = function() return new E(counter++);
		
		var pool = new de.polygonal.ds.tools.ObjectPool<E>(create);
		
		var objects = [];
		objects.push(pool.get());
		objects.push(pool.get());
		objects.push(pool.get());
		
		assertEquals(0, pool.size);
		assertEquals(0, objects[0].id);
		assertEquals(1, objects[1].id);
		assertEquals(2, objects[2].id);
		
		while (objects.length > 0) pool.put(objects.pop());
		
		assertEquals(3, pool.size);
		
		objects.push(pool.get());
		objects.push(pool.get());
		objects.push(pool.get());
		assertEquals(0, objects[0].id);
		assertEquals(1, objects[1].id);
		assertEquals(2, objects[2].id);
		
		var o = pool.get();
		assertEquals(3, o.id);
		pool.put(o);
		
		pool.get();
		
		counter = 0;
		pool.preallocate(10);
		assertEquals(10, pool.size);
		
		for (i in 0...10) assertEquals(9 - i, pool.get().id);
	}
	
	function testIterator()
	{
		var counter = 0;
		var create = function() return new E(counter++);
		
		var pool = new de.polygonal.ds.tools.ObjectPool<E>(create);
		
		var objects = [];
		objects.push(pool.get());
		objects.push(pool.get());
		objects.push(pool.get());
		
		for (i in objects) pool.put(i);
		objects = [];
		
		assertEquals(3, Lambda.count(pool));
		var c = 0;
		for (i in pool) assertEquals(c++, i.id);
	}
}

private class E
{
	public var id:Int;
	
	public function new(id:Int)
	{
		this.id = id;
	}
}