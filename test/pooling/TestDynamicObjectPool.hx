package pooling;

import de.polygonal.ds.pooling.DynamicObjectPool;

class TestDynamicObjectPool extends AbstractTest
{
	var _counter:Int;
	
	function test()
	{
		_counter = 0;
		
		var c = new DynamicObjectPool(null, fabricate, null, 10);
		
		var objects = new Array();
		for (i in 0...3) objects.push(c.get());
		
		assertEquals(3, c.size());
		
		for (i in 0...3) c.put(objects.pop());
		
		for (i in 0...3) objects.push(c.get());
		
		for (i in 0...3) assertEquals('E' + Std.string(i), Std.string(objects[i]));
		
		//pool is empty, create objects on-the-fly
		for (i in 3...6) objects.push(c.get());
		
		assertEquals(6, c.size());
		
		for (i in 0...6) assertEquals('E' + Std.string(i), Std.string(objects[i]));
		
		c.reclaim();
		
		objects = new Array();
		for (i in 0...6) objects.push(c.get());
		for (i in 0...6) c.put(objects.pop());
		for (i in 0...6) objects.push(c.get());
	}
	
	function fabricate()
	{
		return new E(_counter++);
	}
}

private class E
{
	var _i:Int;
	
	public function new(i:Int)
	{
		_i = i;
	}
	
	public function toString():String
	{
		return 'E' + _i;
	}
}