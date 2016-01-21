package test.pooling;

import de.polygonal.ds.pooling.LinkedObjectPool;
import flash.geom.Point;

class TestLinkedObjectPool extends AbstractTest
{
	function test()
	{
		var pool = new LinkedObjectPool<E>(10);
		
		pool.allocate(E);
		
		var objects = new Array<LinkedPoolNode<E>>();
		
		for (i in 0...10) objects.push(pool.get());
		
		assertEquals(10, objects.length);
		assertEquals(10, pool.countUsedObjects());
		
		for (i in 0...10) pool.put(objects[i]);
		assertEquals(0, pool.countUsedObjects());
			
		var objects = new Array<LinkedPoolNode<E>>();
		for (i in 0...5) objects.push(pool.get());
		assertEquals(5, pool.countUsedObjects());
			
		for (i in 0...5) pool.put(objects[i]);
		assertEquals(0, pool.countUsedObjects());
			
		var objects = new Array<LinkedPoolNode<E>>();
		for (i in 0...10) objects.push(pool.get());
		assertEquals(10, pool.countUsedObjects());
		for (i in 0...10) pool.put(objects[i]);
		assertEquals(0, pool.countUsedObjects());
	}
}

private class E
{
	public function new()
	{
	}
}