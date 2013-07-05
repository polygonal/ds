package;

import de.polygonal.ds.DA;
import de.polygonal.ds.Heap;

class TestHeap extends haxe.unit.TestCase
{
	inline static var DEFAULT_SIZE = 100;
	
	var _size:Int;
	
	function new(size = DEFAULT_SIZE)
	{
		super();
		_size = size;
	}
	
	function testChange()
	{
		var heap = new Heap<E2>();
		
		//descending order, root = largest item
		var values = [46, 8, 19, 5, 40, 14, 74, 66];
		
		var items = new Array<E2>();
		for (i in 0...values.length)
		{
			var item = new E2(values[i]);
			items.push(item);
		}
		
		for (i in 0...items.length)
			heap.add(items[i]);
		
		items[0].y = 100; //46=> 100
		heap.change(items[0], 1);
		
		var v = heap.pop().y;
		
		while (!heap.isEmpty())
		{
			var w = heap.pop().y;
			assertTrue(v > w);
			v = w;
		}
		
		//descending order 9, 5, 2
		var heap = new Heap<E2>();
		var item2 = new E2(2);
		var item5 = new E2(5);
		var item9 = new E2(9);
		heap.add(item2);
		heap.add(item5);
		heap.add(item9);
		item9.y -= 6;
		heap.change(item9, -1);
		assertEquals(item5, heap.pop());
		assertEquals(item9, heap.pop());
		assertEquals(item2, heap.pop());
		
		var heap = new Heap<E2>();
		var values = [0, 1, 2, 3, 4];
		
		var items = new Array<E2>();
		for (i in 0...values.length)
		{
			var item = new E2(values[i]);
			items.push(item);
		}
		
		for (i in 0...items.length)
		{
			heap.add(items[i]);
			
			items[i].y += 10;
			heap.change(items[i], 1);
		}
		
		assertEquals(14., heap.pop().y);
		assertEquals(13., heap.pop().y);
		assertEquals(12., heap.pop().y);
		assertEquals(11., heap.pop().y);
		assertEquals(10., heap.pop().y);
	}
	
	function testReplace()
	{
		var heap = new Heap<E2>();
		
		var values = [46, 8, 19, 5, 40, 14, 74, 66];
		
		var items = new Array<E2>();
		for (i in 0...values.length)
		{
			var item = new E2(values[i]);
			items.push(item);
		}
		
		for (i in 0...items.length)
			heap.add(items[i]);
		
		var item = new E2(200);
		heap.replace(item);
		
		var v = heap.pop().y;
		
		while (!heap.isEmpty())
		{
			var w = heap.pop().y;
			assertTrue(v > w);
			v = w;
		}
	}
	
	function testSort()
	{
		var values = [46, 8, 19, 5, 40, 14, 74, 66];
		var items = new Array<E2>();
		for (i in 0...values.length)
		{
			var item = new E2(values[i]);
			items.push(item);
		}
		
		var heap = new Heap<E2>();
		for (i in 0...items.length) heap.add(items[i]);
		
		var a = heap.sort();
		
		var v = a.shift();
		while (a.length > 0)
		{
			var w = a.shift();
			assertTrue(w.y < v.y);
			v = w;
		}
	}
	
	function testBottom()
	{
		for (s in 1...20)
		{
			var pq = new Heap<E2>();
			for (i in 0...s) pq.add(new E2(i));
			for (i in 0...s - 1)
			{
				assertEquals(0.0, pq.bottom().y);
				pq.pop();
				assertEquals(0.0, pq.bottom().y);
			}
		}
	}
	
	function testReserve()
	{
		var a = new E1(0);
		var b = new E1(1);
		var c = new E1(2);
		
		var l = new de.polygonal.ds.Heap<E1>();
		
		l.add(a);
		l.add(b);
		l.add(c);
		
		var a:Array<E1> = untyped l._a;
		
		assertEquals(null, a[0]);
		assertEquals(0   , a[1].ID);
		assertEquals(1   , a[2].ID);
		assertEquals(2   , a[3].ID);
		
		l.reserve(10);
		
		assertEquals(null, a[0]);
		assertEquals(0   , a[1].ID);
		assertEquals(1   , a[2].ID);
		assertEquals(2   , a[3].ID);
		
		var i = 0;
		while (!l.isEmpty())
		{
			var foo:E1 = l.pop();
			assertEquals(i++, foo.ID);
		}
	}
	
	function testPack()
	{
		var l = new de.polygonal.ds.Heap<E1>();
		l.add(new E1(0));
		l.add(new E1(1));
		l.add(new E1(2));
		
		l.clear();
		
		var a:Array<E1> = untyped l._a;
		
		assertEquals(null, a[0]);
		assertEquals(0, a[1].ID);
		assertEquals(1, a[2].ID);
		assertEquals(2, a[3].ID);
		
		l.pack();
		
		var a:Array<E1> = untyped l._a;
		assertEquals(1, a.length);
		assertEquals(null, a[0]);
	}
	
	function testFront()
	{
		var h = createHeap();
		h.add(new E1(99));
		h.add(new E1(77));
		assertEquals(77, h.top().ID);
	}
	
	function testDynamic()
	{
		var h = new Heap<E1>();
		assertTrue(h.isEmpty());
		assertEquals(0, h.size());
		h.add(new E1(99));
		h.add(new E1(77));
		assertEquals(2, h.size());
		assertEquals(77, h.top().ID);
	}
	
	function testFrontRemoveable()
	{
		var h = createHeap();
		h.add(new E1(99));
		h.add(new E1(77));
		assertEquals(77, h.top().ID);
	}
	
	function testRemove()
	{
		var h = createHeap();
		
		var a = new E1(99);
		var b = new E1(77);
		
		h.add(a);
		h.add(b);
		assertEquals(77, h.top().ID);
		h.remove(a);
		assertEquals(77, h.top().ID);
		h.remove(b);
		assertTrue(h.isEmpty());
		
		var h = createHeap();
		
		var a = new E1(99);
		var b = new E1(77);
		
		h.add(a);
		h.add(b);
		assertEquals(77, h.top().ID);
		h.remove(b);
		assertEquals(99, h.top().ID);
		h.remove(a);
		assertTrue(h.isEmpty());
	}
	
	#if (debug && flash)
	function testRemove3()
	{
		var h = createHeap();
		
		var a = new E1(99);
		var b = a;
		
		var failed = false;
		
		try
		{
			h.add(a);
			h.add(b);
		}
		catch (unknown:Dynamic)
		{
			failed = true;
		}
		
		assertTrue(failed);
	}
	#end
	
	function testRemove2()
	{
		var h = createHeap();
		
		var ids = uniqueRandomArray();
		var foo = new Array<E1>();
		
		for (i in 0...ids.length) foo[i] = new E1(ids[i]);
		for (i in 0...ids.length) h.add(foo[i]);
		for (i in 0...ids.length) h.remove(foo[i]);
		
		assertTrue(h.isEmpty());
		assertTrue(h.size() == 0);
		
		for (i in 0...ids.length) h.add(foo[i]);
		
		assertEquals(h.size(), _size);
	}
	
	function testRemove4()
	{
		var toRemove = new DA<E2>();
		
		var i:Int;
		
		var last:Float = Math.NaN;
		
		var heap = new Heap<E2>();
		
		for (i in 0...10000)
		{
			var item = new E2(Math.random() * 1000);
			if (Math.random() < 0.05) toRemove.pushBack(item);
			heap.add(item);
		}
		
		last = heap.pop().y;
		
		var iter = 0;
		
		while (!heap.isEmpty())
		{
			iter++;
			
			var e = heap.pop(); //e should be smaller than last
			
			var rem:E2 = null;
			var removed = false;
			if (Math.random() > 0.015)
			{
				if(toRemove.size()>0) 
				{
					rem = toRemove.popBack();
					if (heap.contains(rem))
						heap.remove(rem);
				}
			}
			
			assertTrue(e.y <= last);
			last = e.y;
		}
	}
	
	function testEnqueueDequeue()
	{
		var h = createHeap();
		
		assertTrue(h.isEmpty());
		
		var data = new Array<Int>();
		for (i in 0...10) data[i] = i;
		
		for (i in 0...10)
			h.add(new E1(data[i]));
		
		for (i in 0...10)
		{
			var val = h.pop();
			assertEquals(i, val.ID);
		}
		
		assertEquals(h.size(), 0);
		
		for (i in 0...10)
		{
			h.add(new E1(data[i]));
			assertEquals(i + 1, h.size());
		}
		
		for (i in 0...10)
		{
			assertEquals(i, h.top().ID);
			h.pop();
		}
		
		assertTrue(h.isEmpty());
		h.clear();
		
		assertEquals(h.size(), 0);
		assertTrue(h.isEmpty());
	}
	
	function testEnqueueDequeueRemoveable()
	{
		var h = createHeap();
		
		assertTrue(h.isEmpty());
		
		var data = new Array<Int>();
		for (i in 0...10) data[i] = i;
		for (i in 0...10) h.add(new E1(data[i]));
		
		for (i in 0...10)
		{
			var val = h.pop();
			assertEquals(i, val.ID);
		}
		
		assertEquals(h.size(), 0);
		
		for (i in 0...10)
		{
			h.add(new E1(data[i]));
			assertEquals(i + 1, h.size());
		}
		
		for (i in 0...10)
		{
			assertEquals(i, h.top().ID);
			h.pop();
		}
		
		assertTrue(h.isEmpty());
		h.clear();
		
		assertEquals(h.size(), 0);
		assertTrue(h.isEmpty());
	}
	
	function testClone()
	{
		var h:Heap<E1> = new Heap<E1>(10);
		var data = new Array<Int>();
		var sum = 0;
		for (i in 0...10)
		{
			data[i] = i;
			sum += i;
		}
		for (i in 0...10) h.add(new E1(data[i]));
		
		var myCopy = h.clone(false);
		
		var c = 0;
		var d = 0;
		for (i in myCopy)
		{
			c++;
			d += i.ID;
		}
		assertEquals(c, 10);
		assertEquals(d, sum);
	}
	
	function testHeapIterator()
	{
		var h:Heap<E1> = new Heap<E1>(10);
		var data = new Array<Int>();
		var sum:Int = 0;
		for (i in 0...10)
		{
			data[i] = i;
			sum += i;
		}
		
		for (i in 0...10) h.add(new E1(data[i]));
		
		var c:Int = 0;
		var d:Int = 0;
		for (i in h)
		{
			c++;
			d += i.ID;
		}
		assertEquals(c, 10);
		assertEquals(d, sum);
	}
	
	function testIteratorRemove()
	{
		var h = new Heap<E1>(10);
		h.add(new E1(0));
		h.add(new E1(1));
		h.add(new E1(2));
		var itr = h.iterator();
		while (itr.hasNext())
		{
			var x = itr.next();
			itr.remove();
		}
		assertTrue(h.isEmpty());
	}
	
	function testToArray()
	{
		var h:Heap<E1> = new Heap<E1>(10);
		
		var data = new Array<Int>();
		
		for (i in 0...10) data[i] = i;
		for (i in 0...10) h.add(new E1(data[i]));
		
		var a = h.toArray();
		assertEquals(10, a.length);
	}
	
	function uniqueRandomArray():Array<Int>
	{
		var a = new Array<Int>();
		for (i in 0..._size)
			a.push(i);
			
		var m = Math;
		var s:Int = a.length, i:Int, t:Int;
		while (s > 1)
		{
			s--;
			i = Std.int(m.random() * s);
			t    = a[s];
			a[s] = a[i];
			a[i] = t;
		}
		return a;
	}
	
	function createHeap():Heap<E1>
	{
		return new Heap<E1>(_size);
	}
}

#if haxe3
private class E1 implements de.polygonal.ds.Heapable<E1> implements de.polygonal.ds.Cloneable<E1>
#else
private class E1 implements de.polygonal.ds.Heapable<E1>, implements de.polygonal.ds.Cloneable<E1>
#end
{
	public var position:Int;
	
	public var ID:Int;
	public function new(ID:Int)
	{
		this.ID = ID;
	}
	
	public function compare(other:E1):Int
	{
		return other.ID - ID;
	}
	
	public function clone():E1
	{
		return new E1(ID);
	}
	
	public function toString():String
	{
		return '' + ID;
	}
}

private class E2 implements de.polygonal.ds.Heapable<E2>
{
	public var y:Float;
	
	public var position:Int;
	
	public function new(y:Float)
	{
		this.y = y;
	}
	
	public function toString():String
	{
		return '' + y;
	}
	
	public function compare(other:E2):Int
	{
		var dt = other.y - y;
		if (dt > 0) return -1;
		else
		if (dt < 0) return 1;
		return 0;
	}
}