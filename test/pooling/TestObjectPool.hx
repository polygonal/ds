package pooling;

import de.polygonal.ds.ListSet;

class TestObjectPool extends AbstractTest
{
	static function shuffle<T>(v:Array<T>)
	{
		var m = Math;
		var s:Int = v.length, i:Int, t:T;
		while (s > 1)
		{
			s--;
			i = Std.int(m.random() * s);
			t    = v[s];
			v[s] = v[i];
			v[i] = t;
		}
	}
	
	function test()
	{
		var o = new de.polygonal.ds.pooling.ObjectPool<E>(10);
		o.allocate(false, E);
		assertEquals(10, o.size);
		
		for (iter in 0...20)
		{
			var ids = new Array<Int>();
			var obj = new Array<E>();
			var idset = new ListSet<Int>();
			var objset = new ListSet<E>();
			var idrange = new Array<Int>();
			var r = rand() % 10;
			for (j in 0...r) idrange.push(j); shuffle(idrange);
			
			var t = new ListSet<Int>();
			for (i in idrange) assertTrue(t.set(i));
			for (i in 0...r)
			{
				var id = o.next();
				ids[i] = id;
				obj[i] = o.get(id);
				assertTrue(idset.set(id));
				assertTrue(objset.set(o.get(id)));
			}
			
			assertEquals(r, o.countUsedObjects());
			assertEquals(10 - r, o.countUnusedObjects());
			assertEquals(r, idset.size);
			assertEquals(r, objset.size);
			assertEquals(r, ids.length);
			
			for (i in 0...r)
			{
				var id = ids[i];
				var item = o.get(id);
				assertTrue(item != null);
				o.put(id);
				assertEquals(true, idset.remove(id));
				assertEquals(true, objset.remove(item));
			}
			
			assertEquals(0, o.countUsedObjects());
			assertEquals(10, o.countUnusedObjects());
			assertEquals(0, idset.size);
			assertEquals(0, objset.size);
		}
	}
}

private class E
{
	public function new()
	{
	}
}