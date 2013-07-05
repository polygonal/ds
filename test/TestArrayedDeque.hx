package;

import de.polygonal.ds.ArrayedDeque;
import de.polygonal.ds.Deque;

class TestArrayedDeque extends haxe.unit.TestCase
{
	inline static var BLOCK_SIZE = 4;
	
	function new()
	{
		super();
	}
	
	function testAdjacent()
	{
		//[x, x, x, h] [t, x, x, ]
		var d = createDequeInt();
		d.pushBack(0);
		d.pushBack(1);
		d.pushBack(2);
		d.popFront();
		d.popFront();
		d.popFront();
		assertTrue(d.isEmpty());
		d.pushFront(3);
		d.pushBack(4);
		assertEquals(3, d.getFront(0));
		assertEquals(4, d.getBack(0));
	}
	
	function testFill()
	{
		var d = createDequeInt();
		d.fill(9, 10);
		assertEquals(10, d.size());
		for (i in 0...10) assertEquals(9, d.getFront(i));
		var d = createDequeInt(8);
		for (i in 0...3) d.pushBack(i);
		d.fill(9, 1);
		d.fill(9, 2);
		d.fill(9, 3);
		var d = createDequeInt(4);
		for (i in 0...20) d.pushBack(i);
		d.fill(99);
		assertEquals(20, d.size());
		for (i in 0...20)
			assertEquals(99, d.getFront(i));
		var d = createDequeInt(4);
		for (i in 0...30) d.pushBack(i);
		d.fill(99);
		assertEquals(30, d.size());
		for (i in 0...30)
			assertEquals(99, d.getFront(i));
		for (s in 0...15)
		{
			var d = createDequeInt(4);
			for (i in 0...20) d.pushBack(i);
			d.fill(99, s);
			for (i in 0...s)
				assertEquals(99, d.getFront(i));
		}
	}
	
	function testClear()
	{
		var d = createDequeInt();
		d.fill(9, 10);
		d.clear(true);
		assertTrue(d.isEmpty());
		assertEquals(0, d.size());
	}
	
	function testIndexOf()
	{
		var d = createDequeInt();
		var s = 0;
		for (i in 0...20)
			d.pushFront(i);
		for (i in 0...20)
		{
			assertEquals(20 - 1 - i, d.indexOfFront(i));
			assertEquals(i, d.indexOfBack(i));
		}
	}
	
	function testGetFront()
	{
		var d = createDequeInt();
		var s = 0;
		for (i in 1...20)
		{
			d.pushFront(i);
			s++;
			var j = s;
			var k = 0;
			while (j > 0)
			{
				assertEquals(j, d.getFront(k));
				k++;
				j--;
			}
		}
		var d = createDequeInt();
		var s = 0;
		for (i in 1...20)
		{
			d.pushBack(i);
			s++;
			var j = 0;
			while (j < s)
			{
				assertEquals(j+1, d.getFront(j));
				j++;
			}
		}
	}
	
	function testGetBack()
	{
		var d = createDequeInt();
		var s = 0;
		for (i in 1...20)
		{
			d.pushFront(i);
			s++;
			var j = 0;
			while (j < s)
			{
				assertEquals(j+1, d.getBack(j));
				j++;
			}
		}
		var d = createDequeInt();
		var s = 0;
		for (i in 1...4)
		{
			d.pushBack(i);
			s++;
			var j = s;
			var k = 0;
			while (j > 0)
			{
				assertEquals(j, d.getBack(k));
				j--;
				k++;
			}
		}
	}
	
	function testClone()
	{
		var s = 1;
		while (s < 20)
		{
			var d = createDequeInt();
			var i = 0;
			for (k in 0...s) d.pushBack(i++);
			var c:Deque<Int> = cast d.clone(true);
			assertEquals(d.size(), c.size());
			i = 0;
			var z = 0;
			for (x in c)
			{
				assertEquals(x, i++);
				z++;
			}
			assertEquals(s, z);
			s++;
		}
		
		var s = 1;
		while (s < 20)
		{
			var d = createDequeFoo();
			var i = 0;
			for (k in 0...s) d.pushBack(new E(i++));
			var c:Deque<E> = cast d.clone(false);
			assertEquals(d.size(), c.size());
			i = 0;
			var z = 0;
			for (x in c)
			{
				assertEquals(x.x, i++);
				z++;
			}
			assertEquals(s, z);
			s++;
		}
		
		var copier = function(x:E) { return new E(x.x); }
		
		var s = 1;
		while (s < 20)
		{
			var d = createDequeFoo();
			var i = 0;
			for (k in 0...s) d.pushBack(new E(i++));
			var c:Deque<E> = cast d.clone(false, copier);
			assertEquals(d.size(), c.size());
			i = 0;
			var z = 0;
			for (x in c)
			{
				assertEquals(x.x, i++);
				z++;
			}
			assertEquals(s, z);
			s++;
		}
	}
	
	function testIterator()
	{
		var s = 1;
		while (s < 20)
		{
			var d = createDequeInt();
			var i = 0;
			for (k in 0...s)
				d.pushBack(i++);
			i = 0;
			var z = 0;
			for (x in d)
			{
				assertEquals(x, i++);
				z++;
			}
			assertEquals(s, z);
			s++;
		}
		
		var d = createDequeInt(16);
		d.pushBack(0);
		d.pushBack(1);
		d.pushBack(2);
		d.pushBack(3);
		d.pushBack(4);
		
		var values = [0, 1, 2, 3, 4];
		for (e in d) assertEquals(values.shift(), e);
		
		d.pushFront(5);
		
		var values = [5, 0, 1, 2, 3, 4];
		for (e in d) assertEquals(values.shift(), e);
	}
	
	function testContains()
	{
		var s = 1;
		while (s < 20)
		{
			var d = createDequeInt();
			var i = 0;
			for (k in 0...s) d.pushBack(i++);
			i = 0;
			for (x in d)
				assertTrue(d.contains(i++));
			s++;
		}
	}
	
	function testToArray()
	{
		//2
		var d = createDequeInt();
		for (i in 0...2) d.pushBack(i);
		var a = d.toArray();
		for (i in 0...a.length)
			assertEquals(a[i], d.popFront());
		assertEquals(2, a.length);
		
		//4
		var d = createDequeInt();
		for (i in 0...4) d.pushBack(i);
		var a = d.toArray();
		for (i in 0...a.length)
			assertEquals(a[i], d.popFront());
		assertEquals(4, a.length);
		
		//16
		var d = createDequeInt();
		for (i in 0...16) d.pushBack(i);
		var a = d.toArray();
		for (i in 0...a.length)
			assertEquals(a[i], d.popFront());
		assertEquals(16, a.length);
	}
	
	function testRemoveCase1()
	{
		//work to back case2
		var d = createDequeInt(4);
		d.pushBack(0);
		d.pushBack(1);
		d.pushBack(2);
		d.pushBack(3);
		
		d.remove(2);
		var c = 0;
		var data = [0, 1, 3];
		for (x in d)
		{
			c++;
			assertEquals(x, data.shift());
		}
		assertEquals(3, c);
		
		d.remove(3);
		var c = 0;
		var data = [0, 1];
		for (x in d)
		{
			c++;
			assertEquals(x, data.shift());
		}
		assertEquals(2, c);
		
		//work to back case2
		var d = createDequeInt();
		for (i in 0...20)
			d.pushBack(i);
		d.remove(2);
		var c = 0;
		var data = [0, 1, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19];
		for (x in d)
		{
			c++;
			assertEquals(x, data.shift());
		}
		assertEquals(19, c);
		
		//work to head case2
		var d = createDequeInt(8);
		d.pushBack(0);
		d.pushBack(1);
		d.pushBack(2);
		d.pushBack(3);
		d.pushBack(4);
		d.pushBack(5);
		d.pushBack(6);
		d.pushBack(7);
		d.pushBack(8);
		d.remove(2);
		var c = 0;
		var data = [0, 1, 3, 4, 5, 6, 7, 8];
		for (x in d)
		{
			c++;
			assertEquals(x, data.shift());
		}
		assertEquals(8, c);
		
		var d = createDequeInt(8);
		d.pushBack(0);
		d.pushBack(1);
		d.pushBack(2);
		d.pushBack(3);
		d.pushBack(4);
		
		d.remove(0); //block0, head++
		assertEquals(4, d.size());
		var i = 1;
		var c = 0;
		for (x in d)
		{
			c++;
			assertEquals(x, i++);
		}
		assertEquals(4, c);
		
		d.remove(4); //block0, tail--
		assertEquals(3, d.size());
		var i = 1;
		var c = 0;
		for (x in d)
		{
			c++;
			assertEquals(x, i++);
		}
		assertEquals(3, c);
		
		d.remove(2);
		assertEquals(2, d.size());
		var i = 1;
		var c = 0;
		var data = [1, 3];
		for (x in d)
		{
			c++;
			assertEquals(x, data.shift());
		}
		assertEquals(2, c);
		
		d.remove(1);
		assertEquals(1, d.size());
		var i = 1;
		var c = 0;
		var data = [3];
		for (x in d)
		{
			c++;
			assertEquals(x, data.shift());
		}
		assertEquals(1, c);
		
		d.remove(3);
		assertEquals(0, d.size());
	}
	
	function testRemoveCase2()
	{
		var d = createDequeInt(4);
		d.pushBack(0);
		d.pushBack(1);
		d.pushBack(2);
		d.pushBack(3);
		d.pushBack(4);
		d.pushBack(5);
		d.remove(3);
		assertEquals(5, d.size());
		var c = 0;
		var data = [0, 1, 2, 4, 5];
		for (x in d)
		{
			c++;
			assertEquals(x, data.shift());
		}
		assertEquals(5, c);
	}
	
	function testRemoveCase3()
	{
		//work to head
		var d = createDequeInt();
		for (i in 0...20)
			d.pushBack(i);
		
		d.remove(16);
		
		var c = 0;
		var data = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 17, 18, 19];
		for (x in d)
		{
			c++;
			assertEquals(x, data.shift());
		}
		assertEquals(19, c);
		
		//work to tail
		var d = createDequeInt();
		for (i in 0...20)
			d.pushBack(i);
		
		d.remove(8);
		
		var c = 0;
		var data = [0, 1, 2, 3, 4, 5, 6, 7, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19];
		for (x in d)
		{
			c++;
			assertEquals(x, data.shift());
		}
		assertEquals(19, c);
	}
	
	function testPushPopFront1()
	{
		var d = createDequeInt();
		d.pushFront(1);
		assertEquals(1, d.front());
		assertEquals(1, d.back());
		assertEquals(1, d.popFront());
		assertTrue(d.isEmpty());
		assertEquals(0, d.size());
	}
	
	function testPushPopFront2()
	{
		var d = createDequeInt();
		d.pushBack(1);
		assertEquals(1, d.front());
		assertEquals(1, d.back());
	}
	
	function testInterface()
	{
		//pushFront, popFront
		var d = createDequeInt();
		for (i in 0...4)
		{
			d.pushFront(i);
			assertEquals(i, d.front());
			assertEquals(0, d.back());
		}
		assertEquals(4, d.size());
		for (i in 4...8)
		{
			d.pushFront(i);
			assertEquals(i, d.front());
			assertEquals(0, d.back());
		}
		assertEquals(8, d.size());
		var j = 7;
		for (i in 0...8)
		{
			assertEquals(j--, d.popFront());
			
			if (j > 0)
				assertEquals(j, d.front());
		}
		assertEquals(0, d.size());
		
		//pushFront, popBack
		var d = createDequeInt();
		for (i in 0...8)
		{
			d.pushFront(i);
			assertEquals(i, d.front());
			assertEquals(0, d.back());
		}
		var j = 7;
		for (i in 0...8)
		{
			assertEquals(i, d.popBack());
			
			if (i < 7)
			{
				assertEquals(7, d.front());
				assertEquals(i + 1, d.back());
			}
		}
		assertEquals(0, d.size());
		
		//pushBack, popFront
		var d = createDequeInt();
		for (i in 0...8)
		{
			d.pushBack(i);
			assertEquals(0, d.front());
			assertEquals(i, d.back());
		}
		
		for (i in 0...8)
		{
			assertEquals(i, d.popFront());
			
			if (i < 7)
			{
				assertEquals(i + 1, d.front());
				assertEquals(7, d.back());
			}
		}
		
		//pushBack, popBack
		var d = createDequeInt();
		for (i in 0...8)
		{
			d.pushBack(i);
			assertEquals(0, d.front());
			assertEquals(i, d.back());
		}
		var j = 7;
		for (i in 0...8)
		{
			assertEquals(j--, d.popBack());
			
			if (i < 7)
			{
				assertEquals(0, d.front());
				assertEquals(j, d.back());
			}
		}
	}
	
	function testFrontFill()
	{
		var d = createDequeInt(8);
		for (i in 0...5)
		{
			d.pushFront(i);
			assertEquals(i, d.front());
			assertEquals(0, d.back());
		}
		for (i in 0...5)
		{
			var x = d.popFront();
			assertEquals(5 - 1 - i, x);
		}
	}
	
	function testBackFill()
	{
		var d = createDequeInt(8);
		for (i in 0...5)
		{
			d.pushBack(i);
			assertEquals(i, d.back());
			assertEquals(0, d.front());
		}
		
		for (i in 0...5)
		{
			assertEquals(5 - i - 1, d.back());
			var x = d.popBack();
			assertEquals(5 - i - 1, x);
		}
	}
	
	function createDequeInt(size = BLOCK_SIZE)
	{
		return new ArrayedDeque<Int>(size);
	}
	
	function createDequeFoo(size = BLOCK_SIZE)
	{
		return new ArrayedDeque<E>(size);
	}
}

private class E implements de.polygonal.ds.Cloneable<E>
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