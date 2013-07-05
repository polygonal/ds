package;

import de.polygonal.ds.ArrayedQueue;
import de.polygonal.ds.ListSet;
import de.polygonal.ds.Queue;

class TestArrayedQueue extends haxe.unit.TestCase
{
	inline static var DEFAULT_SIZE = 16;
	
	var _size:Int;
	
	function new(size = DEFAULT_SIZE)
	{
		_size = size;
		super();
	}
	
	function testPack()
	{
		var q = new ArrayedQueue<Int>(16);
		for (i in 0...16) q.enqueue(i);
		for (i in 0...8) q.dequeue();
		for (i in 100...104) q.enqueue(i);
		for (i in 0...4) q.dequeue();
		q.pack();
		var values = [12, 13, 14, 15, 100, 101, 102, 103];
		while (q.size() > 0)
			assertEquals(values.shift(), q.dequeue());
		
		var q = new ArrayedQueue<Int>(16);
		for (i in 0...16) q.enqueue(i);
		for (i in 0...8) q.dequeue();
		q.pack();
		var values = [8, 9, 10, 11, 12, 13, 14, 15];
		while (q.size() > 0)
			assertEquals(values.shift(), q.dequeue());
	}
	
	function testGrow()
	{
		for (s in 2...5)
		{
			var q = new ArrayedQueue<Int>(s);
			for (i in 0...s - 1) q.enqueue(i);
			q.enqueue(s - 1);
			for (i in 0...s)
			{
				assertEquals(s - i, q.size());
				assertEquals(i, q.dequeue());
			}
			assertTrue(q.isEmpty());
		}
		
		#if debug
		var q = new ArrayedQueue<Int>(10, false);
		for (i in 0...10) q.enqueue(i);
		
		var success = true;
		try
		{
			q.enqueue(99);
		}
		catch (unknown:Dynamic)
		{
			success = false;
		}
		
		assertFalse(success);
		
		var q = new ArrayedQueue<Int>(32, false);
		for (i in 0...32) q.enqueue(i);
		for (i in 0...32) q.dequeue();
		assertEquals(32, q.getCapacity());
		
		var q = new ArrayedQueue<Int>(32, false);
		for (i in 0...32) q.enqueue(i);
		q.clear(true);
		assertEquals(32, q.getCapacity());
		#end
	}
	
	function testShrinkDequeue()
	{
		var q = new ArrayedQueue<Int>(8);
		for (i in 0...16) q.enqueue(i);
		for (i in 0...12) assertEquals(i, q.dequeue());
		assertEquals(4, q.size());
		for (i in 0...4) assertEquals(12 + i, q.dequeue());
	}
	
	function testShrinkRemove()
	{
		var q = new ArrayedQueue<Int>(2);
		for (i in 0...8) q.enqueue(i);
		for (i in 0...32 - 8) q.enqueue(99);
		q.remove(99);
		assertEquals(8, q.size());
		for (i in 0...8) assertEquals(i, q.dequeue());
		
		var q = new ArrayedQueue<Int>(2);
		for (i in 0...3) q.enqueue(i);
		for (i in 0...32 - 3) q.enqueue(99);
		q.remove(99);
		assertEquals(3, q.size());
		assertEquals(8, q.getCapacity());
		q.remove(0);
		assertEquals(2, q.size());
		assertEquals(2, q.getCapacity());
		assertEquals(1, q.dequeue());
		assertEquals(2, q.dequeue());
		assertTrue(q.isEmpty());
		
		var q = new ArrayedQueue<Int>(2);
		for (i in 0...2) q.enqueue(i);
		for (i in 0...32 - 2) q.enqueue(99);
		q.remove(99);
		assertEquals(2, q.size());
		assertEquals(2, q.getCapacity());
		q.remove(0);
		assertEquals(1, q.size());
		assertEquals(2, q.getCapacity());
		q.remove(1);
		assertEquals(0, q.size());
		assertEquals(2, q.getCapacity());
	}
	
	function testDispose()
	{
		var q = new ArrayedQueue<Int>(16);
		for (i in 0...16) q.enqueue(i);
		for (i in 0...16)
		{
			q.dequeue();
			q.dispose();
		}
		
		var a = untyped q._a;
		for (i in 0...16) assertEquals(#if (js||flash8||neko) null #else 0 #end, a[i]);
		var q = new ArrayedQueue<Int>(16);
		for (i in 0...16) q.enqueue(i);
		for (i in 0...10) q.dequeue();
		assertEquals(6, q.size());
		for (i in 0...10) q.enqueue(i);
		assertEquals(16, q.size());
		for (i in 0...16)
		{
			q.dequeue();
			q.dispose();
		}
		var a:Array<Int> = untyped q._a;
		for (i in 0...16)
			assertEquals(#if (js||flash8||neko) null #else 0 #end, untyped a[i]);
	}
	
	function testRemove()
	{
		var q = new ArrayedQueue<Int>(8);
		for (i in 0...8) q.enqueue(i);
		for (i in 0...8) q.remove(i);
		assertTrue(q.isEmpty());
		q.clear();
		for (i in 0...8) q.enqueue(i);
		for (i in 0...6)
		{
			q.dequeue();
			q.dispose();
		}
		q.remove(7);
		q.remove(6);
		assertTrue(q.isEmpty());
		q.clear();
		for (i in 0...8) q.enqueue(i);
		for (i in 0...8) q.remove(i);
		assertTrue(q.isEmpty());
		q.clear();
		for (i in 0...8) q.enqueue(i);
		for (i in 0...7)
		{
			q.dequeue();
			q.dispose();
		}
		
		for (i in 0...3) q.enqueue(i * 10);
		q.remove(10);
		
		assertEquals(q.get(0), 7);
		assertEquals(q.get(1), 0);
		assertEquals(q.get(2), 20);
		assertEquals(3, q.size());
		
		var q = new ArrayedQueue<Int>(_size);
		for (i in 0...16) q.enqueue(i);
		for (i in 0...16) q.remove(i);
		
		var friend:{ private var _front:Int; private var _size:Int; } = q;
		
		assertEquals(friend._front, 0);
		assertEquals(friend._size, 0);
		assertEquals(q.isEmpty(), true);
		
		for (i in 0...16) q.enqueue(i);
		for (i in 0...15) q.remove(16 - i - 1);
			
		q.remove(0);
		assertEquals(q.isEmpty(), true);
		
		for (i in 0...16) q.enqueue(i);
		
		assertEquals(16, q.size());
		
		for (i in 0...8)
		{
			q.dequeue();
			q.dispose();
		}
		
		q.remove(10);
		assertEquals(16 - 8 - 1, q.size());
		assertEquals(q.dequeue(), 8);
		assertEquals(q.dequeue(), 9);
		assertEquals(q.dequeue(), 11);
		assertEquals(q.dequeue(), 12);
		assertEquals(q.dequeue(), 13);
		assertEquals(q.dequeue(), 14);
		assertEquals(q.dequeue(), 15);
		assertTrue(q.isEmpty());
	}
	
	function testMaxSize()
	{
		var q:ArrayedQueue<Int> = new ArrayedQueue<Int>(_size);
		assertEquals(_size, q.getCapacity());
	}
	
	function testQueue()
	{
		var l:Queue<Int> = new ArrayedQueue<Int>(_size);
		l.enqueue(1);
		l.enqueue(2);
		l.enqueue(3);
		assertEquals(3, l.size());
	}
	
	function testPeek()
	{
		var q:ArrayedQueue<Int> = new ArrayedQueue<Int>(_size);
		for (i in 0...10)
		{
			q.enqueue(i);
			assertEquals(0, q.peek());
		}
	}
	
	function testBack()
	{
		var q:ArrayedQueue<Int> = new ArrayedQueue<Int>(_size);
		for (i in 0...10)
		{
			q.enqueue(i);
			assertEquals(i, q.back());
		}
	}
	
	function testEnqueueDequeue()
	{
		var q:ArrayedQueue<Int> = new ArrayedQueue<Int>(_size);
		for (i in 0...10) q.enqueue(i);
		for (i in 0...10) assertEquals(i, q.dequeue());
	}
	
	function testAssign()
	{
		var q:ArrayedQueue<E> = new ArrayedQueue<E>(_size);
		assertEquals(0, q.size());
		q.assign(E, [0]);
		assertEquals(_size, q.size());
		for (i in 0..._size) assertEquals(E, cast Type.getClass(q.dequeue()));
		
		assertTrue(q.isEmpty());
		
		q.assign(E, [0], 10);
		assertEquals(10, q.size());
		for (i in 0...10) assertEquals(E, cast Type.getClass(q.dequeue()));
		
		assertTrue(q.isEmpty());
		
		q.assign(E, [5], 10);
		assertEquals(10, q.size());
		for (i in 0...10)
		{
			var e = q.dequeue();
			assertEquals(E, cast Type.getClass(e));
			assertEquals(5, e.x);
		}
		
		assertTrue(q.isEmpty());
	}
	
	function testFill()
	{
		var q:ArrayedQueue<Int> = new ArrayedQueue<Int>(_size);
		assertEquals(0, q.size());
		q.fill(99);
		assertEquals(_size, q.size());
		for (i in 0..._size) assertEquals(99, q.dequeue());
		assertTrue(q.isEmpty());
		q.fill(88, 10);
		assertEquals(10, q.size());
		for (i in 0...10) assertEquals(88, q.dequeue());
		assertTrue(q.isEmpty());
	}
	
	function testGetAtSetAt()
	{
		var q:ArrayedQueue<Int> = new ArrayedQueue<Int>(_size);
		for (i in 0...10) q.enqueue(i);
		for (i in 0...10) assertEquals(i, q.get(i));
		for (i in 0...10) q.set(i, 100 + i);
		for (i in 0...10) assertEquals(100 + i, q.get(i));
	}
	
	function testSwp()
	{
		var q:ArrayedQueue<Int> = new ArrayedQueue<Int>(_size);
		for (i in 0...10) q.enqueue(i);
		q.swp(0, 9);
		assertEquals(9, q.get(0));
		assertEquals(0, q.get(9));
		for (i in 1...9) assertEquals(i, q.get(i));
	}
	
	function testCpy()
	{
		var q:ArrayedQueue<Int> = new ArrayedQueue<Int>(_size);
		for (i in 0...10) q.enqueue(i);
		q.cpy(0, 1);
		assertEquals(1, q.get(0));
		assertEquals(1, q.get(1));
		for (i in 1...10) assertEquals(i, q.get(i));
	}
	
	function testWalk()
	{
		var q:ArrayedQueue<Int> = new ArrayedQueue<Int>(_size);
		for (i in 0..._size) q.enqueue(i);
		
		var process = function(val:Int, index:Int):Int
		{
			return (val+index) * 3;
		}
		q.walk(process);
		for (i in 0...10) assertEquals((i + i) * 3, q.get(i));
	}
	
	function testContains()
	{
		var q:ArrayedQueue<Int> = new ArrayedQueue<Int>(_size);
		for (i in 0...10) q.enqueue(5);
		assertEquals(true, q.contains(5));
	}
	
	function testClear()
	{
		var q:ArrayedQueue<Int> = new ArrayedQueue<Int>(_size);
		for (i in 0...10) q.enqueue(5);
		q.clear();
		assertEquals(0, q.size());
		
		//shrink to initial capacity
		var q:ArrayedQueue<Int> = new ArrayedQueue<Int>(4);
		for (i in 0...8) q.enqueue(i);
		q.clear();
		assertEquals(8, q.getCapacity());
		assertEquals(0, q.size());
		q.clear(true);
		assertEquals(4, q.getCapacity());
		assertEquals(0, q.size());
		var q:ArrayedQueue<Int> = new ArrayedQueue<Int>(3);
		for (i in 0...111) q.enqueue(i);
		q.clear(true);
		assertEquals(3, q.getCapacity());
		assertEquals(0, q.size());
	}
	
	function testIsEmpty()
	{
		var q = new ArrayedQueue<Int>(_size);
		assertEquals(true, q.isEmpty());
		assertEquals(false, q.isFull());
		for (i in 0..._size - 1) q.enqueue(i);
		assertEquals(false, q.isEmpty());
		assertEquals(false, q.isFull());
		q.enqueue(0);
		assertEquals(true, q.isFull());
		assertEquals(false, q.isEmpty());
		for (i in 0..._size - 1) q.dequeue();
		assertEquals(false, q.isFull());
		assertEquals(false, q.isEmpty());
		q.dequeue();
		assertEquals(true, q.isEmpty());
		assertEquals(false, q.isFull());
		var q:ArrayedQueue<Int> = new ArrayedQueue<Int>(_size);
		for (i in 0...10) q.enqueue(i);
		q.clear();
		assertEquals(true, q.isEmpty());
	}
	
	function testIterator()
	{
		var q:ArrayedQueue<Int> = new ArrayedQueue<Int>(_size);
		for (i in 0...10) q.enqueue(i);
		var c = 0;
		var itr:de.polygonal.ds.ResettableIterator<Int> = cast q.iterator();
		for (val in itr) assertEquals(c++, val);
		assertEquals(c, 10);
		c = 0;
		itr.reset();
		for (val in itr) assertEquals(c++, val);
		assertEquals(c, 10);
		var set = new ListSet<Int>();
		for (val in q) assertTrue(set.set(val));
		var itr:de.polygonal.ds.ResettableIterator<Int> = cast q.iterator();
		var s = cast set.clone(true);
		var c = 0;
		for (val in itr) assertTrue(s.remove(val));
		assertTrue(s.isEmpty());
		var s:de.polygonal.ds.Set<Int> = cast set.clone(true);
		itr.reset();
		for (val in itr) assertTrue(s.remove(val));
		assertTrue(s.isEmpty());
		q.enqueue(10);
		var s:de.polygonal.ds.Set<Int> = cast set.clone(true);
		s.set(10);
		itr.reset();
		for (val in itr) assertTrue(s.remove(val));
		assertTrue(s.isEmpty());
	}
	
	function testIteratorRemove()
	{
		for (i in 0...5)
		{
			var s = new ArrayedQueue<Int>(64);
			var set = new de.polygonal.ds.ListSet<Int>();
			for (j in 0...5)
			{
				s.enqueue(j);
				if (i != j) set.set(j);
			}
			
			var itr = s.iterator();
			while (itr.hasNext())
			{
				var val = itr.next();
				if (i == val)
					itr.remove();
			}
			while (!s.isEmpty()) assertTrue(set.remove(s.dequeue()));
			assertTrue(set.isEmpty());
		}
		
		var da = new ArrayedQueue<Int>(64);
		for (j in 0...5) da.enqueue(j);
		
		var itr = da.iterator();
		while (itr.hasNext())
		{
			itr.next();
			itr.remove();
		}
		assertTrue(da.isEmpty());
	}
	
	function testToArray()
	{
		var q:ArrayedQueue<Int> = new ArrayedQueue<Int>(_size);
		for (i in 0...10) q.enqueue(i);
		var a = q.toArray();
		assertEquals(a.length, 10);
		for (i in 0...a.length) assertEquals(i, a[i]);
	}
	
	function testShuffle()
	{
		var q:ArrayedQueue<Int> = new ArrayedQueue<Int>(_size);
		for (i in 0...10) q.enqueue(i);
		var s:de.polygonal.ds.Set<Int> = new ListSet<Int>();
		q.shuffle(null);
		for (i in 0...10) assertEquals(true, s.set(q.get(i)));
	}
	
	function testClone()
	{
		var a:ArrayedQueue<Int> = new ArrayedQueue<Int>(16);
		for (i in 0...10) a.enqueue(i);
		var clone:ArrayedQueue<Int> = cast a.clone(true);
		assertEquals(clone.size(), a.size());
		for (i in 0...10) assertEquals(clone.dequeue(), i);
	}
	
	function testCollection()
	{
		var c:de.polygonal.ds.Collection<Int> = cast new ArrayedQueue<Int>(16);
		assertTrue(c != null);
	}
}

private class E
{
	public var x:Int;
	public function new(x:Int)
	{
		this.x = x;
	}
	
	public function clone():E
	{
		return new E(x);
	}
}