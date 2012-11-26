import de.polygonal.core.math.Mathematics;
import de.polygonal.ds.Array2;
import de.polygonal.ds.ArrayedQueue;
import de.polygonal.ds.ListSet;
import de.polygonal.ds.Queue;
import haxe.unit.TestCase;


class TestArrayedQueue extends TestCase
{
	var _size:Int;
	
	public function new(size:Int)
	{
		_size = size;
		super();
	}
	
	public function testPack():Void
	{
		var q = new ArrayedQueue<Int>(16);
		
		for (i in 0...16)
			q.enqueue(i);
		for (i in 0...8)
			q.dequeue();
		for (i in 100...104)
			q.enqueue(i);
		for (i in 0...4)
			q.dequeue();
		q.pack();
		
		var values = [12, 13, 14, 15, 100, 101, 102, 103];
		
		while (q.size() > 0)
			assertEquals(values.shift(), q.dequeue());
			
		var q = new ArrayedQueue<Int>(16);
		
		for (i in 0...16)
			q.enqueue(i);
		for (i in 0...8)
			q.dequeue();
		q.pack();
		
		var values = [8, 9, 10, 11, 12, 13, 14, 15];
		while (q.size() > 0)
			assertEquals(values.shift(), q.dequeue());
	}
	
	public function testGrow():Void
	{
		for (s in 2...5)
		{
			var q = new ArrayedQueue<Int>(s);
			for (i in 0...s - 1)
			{
				q.enqueue(i);
			}
			
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
	
	public function testShrinkDequeue():Void
	{
		var q = new ArrayedQueue(8);
		for (i in 0...16) q.enqueue(i);
		for (i in 0...12) assertEquals(i, q.dequeue());
		
		assertEquals(4, q.size());
		
		for (i in 0...4)
			assertEquals(12 + i, q.dequeue());
	}
	
	public function testShrinkRemove():Void
	{
		var q = new ArrayedQueue(2);
		
		for (i in 0...8) q.enqueue(i);
		for (i in 0...32 - 8) q.enqueue(99);
		
		q.remove(99);
		
		assertEquals(8, q.size());
		for (i in 0...8)
		{
			assertEquals(i, q.dequeue());
		}
		
		var q = new ArrayedQueue(2);
		
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
		
		var q = new ArrayedQueue(2);
		
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
	
	public function testDispose():Void
	{
		var q:ArrayedQueue<Int> = new ArrayedQueue<Int>(16);
		
		for (i in 0...16)
			q.enqueue(i);
		
		for (i in 0...16)
		{
			q.dequeue();
			q.dispose();
		}
		
		var a = untyped q._a;
		
		for (i in 0...16)
			assertEquals(#if (js||flash8||neko) null #else 0 #end, a[i]);
			
		var q:ArrayedQueue<Int> = new ArrayedQueue<Int>(16);
		
		for (i in 0...16)
			q.enqueue(i);
		
		for (i in 0...10)
			q.dequeue();
			
		assertEquals(6, q.size());
		
		for (i in 0...10)
			q.enqueue(i);
			
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
	
	public function testRemove():Void
	{
		var q = new ArrayedQueue<Int>(8);
		
		for (i in 0...8)
			q.enqueue(i);
		for (i in 0...8)
			q.remove(i);
		
		assertTrue(q.isEmpty());
		
		q.clear();
		
		for (i in 0...8)
			q.enqueue(i);
		for (i in 0...6)
		{
			q.dequeue();
			q.dispose();
		}
			
		q.remove(7);
		q.remove(6);
		
		assertTrue(q.isEmpty());
		
		q.clear();
		
		for (i in 0...8)
			q.enqueue(i);
		for (i in 0...8)
			q.remove(i);
		
		assertTrue(q.isEmpty());
		
		q.clear();
		
		for (i in 0...8)
			q.enqueue(i);
		for (i in 0...7)
		{
			q.dequeue();
			q.dispose();
		}
			
		for (i in 0...3)
			q.enqueue(i * 10);
			
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
		
		for (i in 0...16)
			q.enqueue(i);
		for (i in 0...15)
		{
			q.remove(16 - i - 1);
		}
			
		q.remove(0);
		assertEquals(q.isEmpty(), true);
		
		for (i in 0...16)
			q.enqueue(i);
		
		assertEquals(16, q.size());
		
		for (i in 0...8)
		{
			q.dequeue();
			q.dispose();
		}
		
		//trace([untyped q._a, untyped q._a.length, untyped q._front]);
		
		q.remove(10);
		
		//trace([untyped q._a, untyped q._a.length, untyped q._front]);
		
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
	
	public function testMaxSize():Void
	{
		var q:ArrayedQueue<Int> = new ArrayedQueue<Int>(_size);
		assertEquals(_size, q.getCapacity());
	}
	
	public function testQueue():Void
	{
		var l:Queue<Int> = new ArrayedQueue<Int>(_size);
		l.enqueue(1);
		l.enqueue(2);
		l.enqueue(3);
		assertEquals(3, l.size());
	}
	
	public function testPeek():Void
	{
		var q:ArrayedQueue<Int> = new ArrayedQueue<Int>(_size);
		
		for (i in 0...10)
		{
			q.enqueue(i);
			assertEquals(0, q.peek());
		}
	}
	
	public function testBack():Void
	{
		var q:ArrayedQueue<Int> = new ArrayedQueue<Int>(_size);
		
		for (i in 0...10)
		{
			q.enqueue(i);
			
			
			assertEquals(i, q.back());
		}
	}
	
	public function testEnqueueDequeue():Void
	{
		var q:ArrayedQueue<Int> = new ArrayedQueue<Int>(_size);
		
		for (i in 0...10)
			q.enqueue(i);
			
		for (i in 0...10)
			assertEquals(i, q.dequeue());
	}
	
	public function testAssign():Void
	{
		var q:ArrayedQueue<TestArrayedQueueFoo> = new ArrayedQueue<TestArrayedQueueFoo>(_size);
		
		assertEquals(0, q.size());
		
		q.assign(TestArrayedQueueFoo, [0]);
		
		assertEquals(_size, q.size());
		for (i in 0..._size)
		{
			assertEquals(TestArrayedQueueFoo, cast Type.getClass(q.dequeue()));
		}
		
		assertTrue(q.isEmpty());
		
		q.assign(TestArrayedQueueFoo, [0], 10);
		assertEquals(10, q.size());
		for (i in 0...10)
		{
			assertEquals(TestArrayedQueueFoo, cast Type.getClass(q.dequeue()));
		}
		
		assertTrue(q.isEmpty());
		
		q.assign(TestArrayedQueueFoo, [5], 10);
		assertEquals(10, q.size());
		for (i in 0...10)
		{
			var e = q.dequeue();
			assertEquals(TestArrayedQueueFoo, cast Type.getClass(e));
			assertEquals(5, e.x);
		}
		
		assertTrue(q.isEmpty());
	}
	
	public function testFill():Void
	{
		var q:ArrayedQueue<Int> = new ArrayedQueue<Int>(_size);
		
		assertEquals(0, q.size());
		
		q.fill(99);
		
		assertEquals(_size, q.size());
		for (i in 0..._size)
		{
			assertEquals(99, q.dequeue());
		}
		
		assertTrue(q.isEmpty());
		
		q.fill(88, 10);
		
		assertEquals(10, q.size());
		
		for (i in 0...10)
		{
			assertEquals(88, q.dequeue());
		}
		
		assertTrue(q.isEmpty());
	}
	
	public function testGetAtSetAt():Void
	{
		var q:ArrayedQueue<Int> = new ArrayedQueue<Int>(_size);
		
		for (i in 0...10)
			q.enqueue(i);
			
		for (i in 0...10)
			assertEquals(i, q.get(i));
			
		for (i in 0...10)
			q.set(i, 100 + i);
		
		for (i in 0...10)
			assertEquals(100 + i, q.get(i));
	}
	
	public function testSwp():Void
	{
		var q:ArrayedQueue<Int> = new ArrayedQueue<Int>(_size);
		
		for (i in 0...10)
			q.enqueue(i);
			
		q.swp(0, 9);
		
		assertEquals(9, q.get(0));
		assertEquals(0, q.get(9));
		
		for (i in 1...9)
		{
			assertEquals(i, q.get(i));
		}
	}
	
	public function testCpy():Void
	{
		var q:ArrayedQueue<Int> = new ArrayedQueue<Int>(_size);
		
		for (i in 0...10)
			q.enqueue(i);
			
		q.cpy(0, 1);
		
		assertEquals(1, q.get(0));
		assertEquals(1, q.get(1));
		
		for (i in 1...10)
		{
			assertEquals(i, q.get(i));
		}
	}
	
	public function testWalk():Void
	{
		var q:ArrayedQueue<Int> = new ArrayedQueue<Int>(_size);
		for (i in 0..._size) q.enqueue(i);
		
		var process = function(val:Int, index:Int):Int
		{
			return (val+index) * 3;
		}
		
		q.walk(process);
		
		for (i in 0...10)
			assertEquals((i + i) * 3, q.get(i));
	}
	
	public function testContains():Void
	{
		var q:ArrayedQueue<Int> = new ArrayedQueue<Int>(_size);
		for (i in 0...10) q.enqueue(5);
		
		assertEquals(true, q.contains(5));
	}
	
	public function testClear():Void
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
	
	public function testIsEmpty():Void
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
	
	/*public function testFlag():Void
	{
		var q:ArrayedQueue<Int> = new ArrayedQueue<Int>(_size);
		for (i in 0...10) q.enqueue(i);
		
		var itr = q.iterator();
		
		for (i in itr)
		{
			untyped itr.mark();
		}
		
		var out:flash.Vector<Int> = new flash.Vector<Int>();
		var e:flash.Vector<Int> = untyped itr.getMarkedElements();
		for (i in e)
		{
			trace('m ' + i);
		}
	}*/
	
	public function testIterator():Void
	{
		var q:ArrayedQueue<Int> = new ArrayedQueue<Int>(_size);
		for (i in 0...10) q.enqueue(i);
		
		var c = 0;
		var itr:de.polygonal.ds.ResettableIterator<Int> = cast q.iterator();
		for (val in itr)
			assertEquals(c++, val);
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
	
	public function testIteratorRemove()
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
			
			while (!s.isEmpty())
			{
				assertTrue(set.remove(s.dequeue()));
			}
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
	
	public function testToArray():Void
	{
		var q:ArrayedQueue<Int> = new ArrayedQueue<Int>(_size);
		for (i in 0...10) q.enqueue(i);
		
		var a = q.toArray();
		
		assertEquals(a.length, 10);
		
		for (i in 0...a.length)
		{
			assertEquals(i, a[i]);
		}
	}
	
	public function testToDA():Void
	{
		var q:ArrayedQueue<Int> = new ArrayedQueue<Int>(_size);
		for (i in 0...10) q.enqueue(i);
		
		var a = q.toDA();
		
		assertEquals(10, a.size());
		
		for (i in 0...a.size())
		{
			assertEquals(i, a.get(i));
		}
	}
	
	public function testShuffle():Void
	{
		var q:ArrayedQueue<Int> = new ArrayedQueue<Int>(_size);
		for (i in 0...10) q.enqueue(i);
		
		var s:de.polygonal.ds.Set<Int> = new ListSet<Int>();
		
		q.shuffle(null);
		
		for (i in 0...10)
		{
			assertEquals(true, s.set(q.get(i)));
		}
	}
	
	public function testClone()
	{
		var a:ArrayedQueue<Int> = new ArrayedQueue<Int>(16);
		
		for (i in 0...10)
		{
			a.enqueue(i);
		}
		
		var clone:ArrayedQueue<Int> = cast a.clone(true);
		assertEquals(clone.size(), a.size());
		
		for (i in 0...10)
		{
			assertEquals(clone.dequeue(), i);
		}
    }
	
	public function testCollection()
	{
		var c:de.polygonal.ds.Collection<Int> = cast new ArrayedQueue<Int>(16);
		assertTrue(c != null);
	}
}


class TestArrayedQueueFoo
{
	public var x:Int;
	public function new(x:Int)
	{
		this.x = x;
	}
}