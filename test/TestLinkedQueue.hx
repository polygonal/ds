package;

import de.polygonal.ds.LinkedQueue;
import de.polygonal.ds.ListSet;
import de.polygonal.ds.Queue;

class TestLinkedQueue extends haxe.unit.TestCase
{
	function testPool()
	{
		var l = new LinkedQueue<Int>(20);
		
		for (i in 0...10) l.enqueue(i);
		for (i in 0...10) l.dequeue();
		assertEquals(10, untyped l._poolSize);
		
		for (i in 0...10) l.enqueue(i);
		assertEquals(0, untyped l._poolSize);
		
		for (i in 0...10) l.dequeue();
		assertEquals(10, untyped l._poolSize);
	}
	
	function test()
	{
		var l = new LinkedQueue<Int>();
		for (i in 0...10)
		{
			l.enqueue(1);
			var x = l.dequeue();
			assertEquals(1, x);
			
			l.enqueue(1);
			var x = l.dequeue();
			assertEquals(1, x);
			
			l.enqueue(1);
			l.enqueue(2);
			l.enqueue(3);
			
			var a = l.dequeue();
			var b = l.dequeue();
			var c = l.dequeue();
			
			assertEquals(1, a);
			assertEquals(2, b);
			assertEquals(3, c);
		}
	}
	
	function testFree()
	{
		var l = new LinkedQueue<Int>();
		for (i in 0...5) l.enqueue(i);
		l.free();
		assertTrue(true);
	}
	
	function testRemove()
	{
		var l = new LinkedQueue<Int>();
		for (i in 0...5) l.enqueue(i);
		
		var k = l.remove(0);
		assertEquals(true, k);
		
		var l = new LinkedQueue<Int>();
		for (i in 0...5) l.enqueue(1);
		
		var k = l.remove(1);
		assertEquals(true, k);
		assertTrue(l.isEmpty());
		
		#if generic
		assertEquals(untyped l._head, null);
		assertEquals(untyped l._tail, null);
		#else
		var h:LinkedQueueNode<Int> = untyped l._head;
		var t:LinkedQueueNode<Int> = untyped l._tail;
		assertEquals(h, null);
		assertEquals(t, null);
		#end
		
		//single element
		var l = new LinkedQueue<Int>();
		l.enqueue(5);
		assertFalse(l.remove(4));
		assertTrue(l.remove(5));
		assertEquals(0, l.size());
	}
	
	function testIterator()
	{
		var l = new LinkedQueue<Int>();
		for (i in 0...5) l.enqueue(i);
		
		var s:de.polygonal.ds.Set<Int> = new ListSet<Int>();
		for (i in 0...5) s.set(i);
		
		var itr:de.polygonal.ds.ResettableIterator<Int> = cast l.iterator();
		
		var c:de.polygonal.ds.Set<Int> = cast s.clone(true);
		for (i in itr) assertEquals(true, c.remove(i));
		assertTrue(c.isEmpty());
		
		s.set(6);
		l.enqueue(6);
		
		var c:de.polygonal.ds.Set<Int> = cast s.clone(true);
		itr.reset();
		for (i in itr) assertEquals(true, c.remove(i));
		assertTrue(c.isEmpty());
	}
	
	function testIteratorRemove()
	{
		for (i in 0...5)
		{
			var l = new LinkedQueue<Int>();
			var set = new ListSet<Int>();
			for (j in 0...5)
			{
				l.enqueue(j);
				if (i != j) set.set(j);
			}
			
			var itr = l.iterator();
			while (itr.hasNext())
			{
				var val = itr.next();
				if (val == i) itr.remove();
			}
			
			while (!l.isEmpty()) assertTrue(set.remove(l.dequeue()));
			assertTrue(set.isEmpty());
			assertEquals(null, untyped l._head);
			assertEquals(null, untyped l._tail);
		}
		
		var l = new de.polygonal.ds.LinkedQueue<Int>();
		for (j in 0...5) l.enqueue(j);
		
		var itr = l.iterator();
		while (itr.hasNext())
		{
			itr.next();
			itr.remove();
		}
		assertTrue(l.isEmpty());
		assertEquals(null, untyped l._head);
		assertEquals(null, untyped l._tail);
	}
	
	#if debug
	function testMaxSize()
	{
		var queue = new LinkedQueue<Int>(0, 3);
		queue.enqueue(0);
		queue.enqueue(1);
		queue.enqueue(2);
		
		var failed = false;
		
		try
		{
			queue.enqueue(4);
		}
		catch (unknown:Dynamic)
		{
			failed = true;
		}
		
		assertTrue(failed);
		
		queue = new LinkedQueue<Int>(0, 3);
		for (i in 0...3) queue.enqueue(i);
		
		var failed = false;
		
		try
		{
			queue.fill(0, 10);
		}
		catch (unknown:Dynamic)
		{
			failed = true;
		}
		
		assertTrue(failed);
	}
	#end
	
	function testFill()
	{
		var l = new LinkedQueue<Int>();
		for (i in 0...5) l.enqueue(i);
		l.fill(99);
		
		assertEquals(5, l.size());
		for (i in 0...5) assertEquals(99, l.dequeue());
		assertTrue(l.isEmpty());
	}
	
	function testAssign()
	{
		var l = new LinkedQueue<E>();
		for (i in 0...5) l.enqueue(null);
		l.assign(E, [5]);
		
		assertEquals(5, l.size());
		for (i in 0...5) assertEquals(E, cast Type.getClass(l.dequeue()));
		assertTrue(l.isEmpty());
		
		var l = new LinkedQueue<E>();
		for (i in 0...5) l.enqueue(null);
		l.assign(E, [5]);
		
		assertEquals(5, l.size());
		for (i in 0...5) assertEquals(5, l.dequeue().x);
		assertTrue(l.isEmpty());
	}
	
	function testQueue()
	{
		var l:Queue<Int> = new LinkedQueue<Int>();
		l.enqueue(1);
		l.enqueue(2);
		l.enqueue(3);
		assertEquals(3, l.size());
	}
	
	function testClone()
	{
		var l = new LinkedQueue<Int>();
		l.enqueue(1);
		l.enqueue(2);
		l.enqueue(3);
		
		var copy:LinkedQueue<Int> = cast l.clone(true);
		var a = copy.dequeue();
		var b = copy.dequeue();
		var c = copy.dequeue();
		assertEquals(1, a);
		assertEquals(2, b);
		assertEquals(3, c);
		copy.enqueue(1);
		copy.enqueue(2);
		copy.enqueue(3);
		assertEquals(1, copy.dequeue());
		assertEquals(2, copy.dequeue());
		assertEquals(3, copy.dequeue());
		
		var a = l.dequeue();
		var b = l.dequeue();
		var c = l.dequeue();
		assertEquals(1, a);
		assertEquals(2, b);
		assertEquals(3, c);
		copy.enqueue(1);
		copy.enqueue(2);
		copy.enqueue(3);
		assertEquals(1, copy.dequeue());
		assertEquals(2, copy.dequeue());
		assertEquals(3, copy.dequeue());
		
		var l = new LinkedQueue<Int>();
		l.enqueue(1);
		l.enqueue(2);
		
		var copy:LinkedQueue<Int> = cast l.clone(true);
		var a = copy.dequeue();
		var b = copy.dequeue();
		assertEquals(1, a);
		assertEquals(2, b);
		copy.enqueue(1);
		copy.enqueue(2);
		assertEquals(1, copy.dequeue());
		assertEquals(2, copy.dequeue());
		
		var l = new LinkedQueue<Int>();
		l.enqueue(1);
		var copy:LinkedQueue<Int> = cast l.clone(true);
		assertEquals(1, copy.dequeue());
		copy.enqueue(1);
		assertEquals(1, copy.dequeue());
	}
	
	function testToArray()
	{
		var l = new LinkedQueue<Int>();
		l.enqueue(1);
		l.enqueue(2);
		l.enqueue(3);
		
		var a = l.toArray();
		
		assertEquals(a.length, 3);
		
		for (i in 0...3)
		{
			assertEquals(i + 1, a[i]);
		}
	}
}

private class E
{
	public var x:Int;
	public function new(x:Int)
	{
		this.x = x;
	}
}