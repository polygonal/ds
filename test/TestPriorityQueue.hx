import de.polygonal.ds.Container;
import de.polygonal.ds.PriorityQueue;
import de.polygonal.ds.tools.NativeArrayTools;

@:access(de.polygonal.ds.PriorityQueue)
class TestPriorityQueue extends AbstractTest
{
	function testSource()
	{
		var pq = new PriorityQueue<E>(true, [new E(1), new E(3), new E(0), new E(2)]);
		assertEquals(4, pq.size);
		for (i in 0...4) assertEquals(i, Std.int(pq.dequeue().priority));
		
		var pq = new PriorityQueue<E>(false, [new E(1), new E(3), new E(0), new E(2)]);
		assertEquals(4, pq.size);
		for (i in 0...4) assertEquals((4 - i) - 1, Std.int(pq.dequeue().priority));
	}
	
	function test()
	{
		var pq = new PriorityQueue<E>(false);
		pq.enqueue(new E(1));
		pq.enqueue(new E(2));
		pq.enqueue(new E(3));
		assertEquals(3, pq.size);
		assertEquals(3., pq.dequeue().priority);
		assertEquals(2., pq.dequeue().priority);
		assertEquals(1., pq.dequeue().priority);
		assertTrue(pq.isEmpty());
	}
	
	function testReserve()
	{
		var l = new PriorityQueue<E>(4, true);
		for (i in 0...4) l.enqueue(new E(i));
		assertEquals(4, l.capacity);
		#if (flash && generic && !no_inline)
		var d:Container<E> = flash.Vector.convert(l.mData);
		#else
		var d = l.mData;
		#end
		assertEquals(null, d[0]);
		assertEquals(0., d[1].priority);
		assertEquals(1., d[2].priority);
		assertEquals(2., d[3].priority);
		assertEquals(3., d[4].priority);
		assertEquals(5., NativeArrayTools.size(d));
		
		l.reserve(8);
		assertEquals(8, l.capacity);
		#if (flash && generic && !no_inline)
		var d:Container<E> = flash.Vector.convert(l.mData);
		#else
		var d = l.mData;
		#end
		assertEquals(null, d[0]);
		assertEquals(0., d[1].priority);
		assertEquals(1., d[2].priority);
		assertEquals(2., d[3].priority);
		assertEquals(3., d[4].priority);
		assertEquals(null, d[5]);
		assertEquals(null, d[6]);
		assertEquals(null, d[7]);
		assertEquals(null, d[8]);
		assertEquals(9, NativeArrayTools.size(d));
		
		for (i in 0...4) l.enqueue(new E(i + 4));
		
		#if (flash && generic && !no_inline)
		var d:Container<E> = flash.Vector.convert(l.mData);
		#else
		var d = l.mData;
		#end
		
		for (i in 1...8) assertEquals(i - 1., d[i].priority);
	}
	
	function _testPack()
	{
		/*var pq = new de.polygonal.ds.PriorityQueue<E>(false, 3);
		pq.enqueue(new E(0));
		pq.enqueue(new E(1));
		pq.enqueue(new E(2));
		pq.clear();
		
		var a:Container<E> = pq.mData;
		assertEquals(null, a[0]);
		assertEquals(2.  , a[1].priority);
		assertEquals(0.  , a[2].priority);
		assertEquals(1.  , a[3].priority);
		pq.pack();
		
		var a:Container<E> = pq.mData;
		assertEquals(null, a[0]);
		assertEquals(null, a[1]);
		assertEquals(null, a[2]);
		assertEquals(null, a[3]);*/
	}
	
	function testInverse()
	{
		var pq = new PriorityQueue<E>(3, true);
		pq.enqueue(new E(1));
		pq.enqueue(new E(2));
		pq.enqueue(new E(3));
		assertEquals(3, pq.size);
		assertEquals(1., pq.dequeue().priority);
		assertEquals(2., pq.dequeue().priority);
		assertEquals(3., pq.dequeue().priority);
		assertTrue(pq.isEmpty());
	}
	
	function testClear()
	{
		var pq = new PriorityQueue<E>(true);
		var item = new E(1);
		pq.enqueue(item);
		pq.clear(true);
		pq.enqueue(item);
		pq.clear(true);
		pq.enqueue(item);
		pq.clear(true);
		assertTrue(true);
	}
	
	function testEnqueueDequeue()
	{
		var pq = new PriorityQueue<E>(true);
		var item = new E(1);
		pq.enqueue(item);
		pq.dequeue();
		pq.enqueue(item);
		assertTrue(true);
	}
	
	function testClone()
	{
		var pq = new PriorityQueue<E>(3, false);
		pq.enqueue(new E(1));
		pq.enqueue(new E(2));
		pq.enqueue(new E(3));
		
		var copy:PriorityQueue<E> = cast pq.clone(false);
		assertEquals(3., copy.dequeue().priority);
		assertEquals(2., copy.dequeue().priority);
		assertEquals(1., copy.dequeue().priority);
		assertTrue(copy.isEmpty());
	}
	
	function testBack()
	{
		var priorities = [3, 54, 35, 11];
		
		var pq = new PriorityQueue<E>(false);
		for (i in 0...priorities.length)
			pq.enqueue(new E(priorities.shift()));
		
		assertEquals(3., pq.back().priority);
		pq.dequeue();
		assertEquals(3., pq.back().priority);
		pq.dequeue();
		assertEquals(3., pq.back().priority);
		pq.dequeue();
		assertEquals(3., pq.back().priority);
		assertEquals(3., pq.peek().priority);
		
		for (s in 1...20)
		{
			var pq = new PriorityQueue<E>(false);
			for (i in 0...s) pq.enqueue(new E(i));
			for (i in 0...s - 1)
			{
				assertEquals(0., pq.back().priority);
				pq.dequeue();
				assertEquals(0., pq.back().priority);
			}
		}
		
		for (s in 1...20)
		{
			var pq = new PriorityQueue<E>(true);
			for (i in 0...s) pq.enqueue(new E(i));
			
			for (i in 0...s - 1)
			{
				assertEquals(s - 1., pq.back().priority);
				pq.dequeue();
				assertEquals(s - 1., pq.back().priority);
			}
		}
	}
	
	function testRemove()
	{
		var a;
		
		var pq = new PriorityQueue<E>(3, false);
		pq.enqueue(a = new E(1));
		pq.enqueue(new E(2));
		pq.enqueue(new E(3));
		pq.remove(a);
		
		assertEquals(3., pq.dequeue().priority);
		assertEquals(2., pq.dequeue().priority);
		assertTrue(pq.isEmpty());
		
		var pq = new PriorityQueue<E>(3, false);
		pq.enqueue(new E(1));
		pq.enqueue(a = new E(2));
		pq.enqueue(new E(3));
		pq.remove(a);
		
		assertEquals(3., pq.dequeue().priority);
		assertEquals(1., pq.dequeue().priority);
		assertTrue(pq.isEmpty());
		
		var pq = new PriorityQueue<E>(3, false);
		pq.enqueue(new E(1));
		pq.enqueue(new E(2));
		pq.enqueue(a = new E(3));
		pq.remove(a);
		
		assertEquals(2., pq.dequeue().priority);
		assertEquals(1., pq.dequeue().priority);
		assertTrue(pq.isEmpty());
		
		pq = new de.polygonal.ds.PriorityQueue<E>(false);
		var item = new E(1);
		pq.enqueue(item);
		assertTrue(pq.remove(item));
		pq.enqueue(item);
	}
	
	function testReprioritize()
	{
		var a = new E(1);
		var pq = new PriorityQueue<E>(3, false);
		pq.enqueue(a);
		pq.enqueue(new E(2));
		pq.enqueue(new E(3));
		
		pq.reprioritize(a, 100);
		assertEquals(100., pq.dequeue().priority);
		assertEquals(3., pq.dequeue().priority);
		assertEquals(2., pq.dequeue().priority);
	}
	
	function testToString()
	{
		var pq = new PriorityQueue<E>(3, false);
		pq.enqueue(new E(1));
		pq.enqueue(new E(2));
		pq.enqueue(new E(3));
		pq.toString();
		
		assertEquals(3., pq.dequeue().priority);
		assertEquals(2., pq.dequeue().priority);
		assertEquals(1., pq.dequeue().priority);
		
		pq.enqueue(new E(1));
		pq.enqueue(new E(2));
		pq.enqueue(new E(3));
		pq.toString();
		
		assertEquals(3., pq.dequeue().priority);
		assertEquals(2., pq.dequeue().priority);
		assertEquals(1., pq.dequeue().priority);
	}
	
	function testIterator()
	{
		var pq = new PriorityQueue<E>(3, false);
		pq.enqueue(new E(1));
		pq.enqueue(new E(2));
		pq.enqueue(new E(3));
		var c = 0;
		for (x in pq) c++;
		assertEquals(3, c);
	}
	
	function testIteratorRemove()
	{
		var pq = new PriorityQueue<E>(3, false);
		pq.enqueue(new E(1));
		pq.enqueue(new E(2));
		pq.enqueue(new E(3));
		var itr = pq.iterator();
		while (itr.hasNext())
		{
			var x = itr.next();
			itr.remove();
		}
		assertTrue(pq.isEmpty());
	}
}

private class E extends de.polygonal.ds.HashableItem implements de.polygonal.ds.Prioritizable implements de.polygonal.ds.Cloneable<E>
{
	public var priority:Float;
	public var position:Int;
	
	public function new(priority:Float)
	{
		super();
		this.priority = priority;
	}
	
	public function clone():E
	{
		return new E(priority);
	}
	
	public function toString():String
	{
		return "" + priority;
	}
}