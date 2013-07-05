package;

import de.polygonal.ds.ArrayedStack;
import de.polygonal.ds.ListSet;
import de.polygonal.ds.Stack;

class TestArrayedStack extends haxe.unit.TestCase
{
	inline static var DEFAULT_SIZE = 100;
	
	var _size:Int;
	
	function new(size = DEFAULT_SIZE)
	{
		_size = size;
		super();
	}
	
	function testFree()
	{
		var s:ArrayedStack<Int> = new ArrayedStack<Int>(5);
		for (i in 0...3) s.push(i);
		s.free();
		assertTrue(true);
	}
	
	function testDup()
	{
		var s:ArrayedStack<Int> = new ArrayedStack<Int>(5);
		for (i in 0...2) s.push(i);
		s.dup();
		assertEquals(3, s.size());
		assertEquals(1, s.top());
		assertEquals(1, s.get(s.size() - 2));
		assertEquals(0, s.get(s.size() - 3));
	}
	
	function testExchange()
	{
		var s:ArrayedStack<Int> = new ArrayedStack<Int>(5);
		s.push(0);
		s.push(1);
		s.exchange();
		assertEquals(0, s.top());
		assertEquals(1, s.get(s.size() - 2));
		var s:ArrayedStack<Int> = new ArrayedStack<Int>(5);
		s.push(0);
		s.push(1);
		s.push(2);
		s.exchange();
		assertEquals(1, s.top());
		assertEquals(2, s.get(s.size() - 2));
	}
	
	function testRotRight()
	{
		var s:ArrayedStack<Int> = new ArrayedStack<Int>(5);
		s.push(0);
		s.push(1);
		s.push(2);
		s.push(3);
		s.push(4);
		
		s.rotRight(5);
		
		assertEquals(0, s.get(4));
		assertEquals(4, s.get(3));
		assertEquals(3, s.get(2));
		assertEquals(2, s.get(1));
		assertEquals(1, s.get(0));
		
		s.rotRight(5);
		
		assertEquals(1, s.get(4));
		assertEquals(0, s.get(3));
		assertEquals(4, s.get(2));
		assertEquals(3, s.get(1));
		assertEquals(2, s.get(0));
		
		var s:ArrayedStack<Int> = new ArrayedStack<Int>(5);
		s.push(0);
		s.push(1);
		s.push(2);
		s.push(3);
		s.push(4);
		
		s.rotRight(3);
		
		assertEquals(2, s.get(4));
		assertEquals(4, s.get(3));
		assertEquals(3, s.get(2));
		assertEquals(1, s.get(1));
		assertEquals(0, s.get(0));
		
		s.rotRight(3);
		
		assertEquals(3, s.get(4));
		assertEquals(2, s.get(3));
		assertEquals(4, s.get(2));
		assertEquals(1, s.get(1));
		assertEquals(0, s.get(0));
		
		s.rotRight(3);
		
		assertEquals(4, s.get(4));
		assertEquals(3, s.get(3));
		assertEquals(2, s.get(2));
		assertEquals(1, s.get(1));
		assertEquals(0, s.get(0));
	}
	
	function testRotLeft()
	{
		var s:ArrayedStack<Int> = new ArrayedStack<Int>(5);
		s.push(0);
		s.push(1);
		s.push(2);
		s.push(3);
		s.push(4);
		
		s.rotLeft(5);
		
		assertEquals(3, s.get(4));
		assertEquals(2, s.get(3));
		assertEquals(1, s.get(2));
		assertEquals(0, s.get(1));
		assertEquals(4, s.get(0));
		
		s.rotLeft(5);
		
		assertEquals(2, s.get(4));
		assertEquals(1, s.get(3));
		assertEquals(0, s.get(2));
		assertEquals(4, s.get(1));
		assertEquals(3, s.get(0));
		
		var s:ArrayedStack<Int> = new ArrayedStack<Int>(5);
		s.push(0);
		s.push(1);
		s.push(2);
		s.push(3);
		s.push(4);
		
		s.rotLeft(3);
		
		assertEquals(3, s.get(4));
		assertEquals(2, s.get(3));
		assertEquals(4, s.get(2));
		assertEquals(1, s.get(1));
		assertEquals(0, s.get(0));
		
		s.rotLeft(3);
		
		assertEquals(2, s.get(4));
		assertEquals(4, s.get(3));
		assertEquals(3, s.get(2));
		assertEquals(1, s.get(1));
		assertEquals(0, s.get(0));
		
		s.rotLeft(3);
		
		assertEquals(4, s.get(4));
		assertEquals(3, s.get(3));
		assertEquals(2, s.get(2));
		assertEquals(1, s.get(1));
		assertEquals(0, s.get(0));
	}
	
	function testRemove()
	{
		var s = new ArrayedStack<Int>(5);
		var values = [1, 2, 3, 4, 5];
		for (i in values) s.push(i);
		var k = 5;
		for (i in 0...5)
		{
			s.remove(values.shift());
			assertEquals(s.size(), --k);
			for (j in values) assertTrue(s.contains(j));
		}
		assertTrue(s.isEmpty());
	}
	
	function testReserve()
	{
		var stack = new ArrayedStack<Int>(0, 20);
		for (i in 0...10) stack.push(i);
		stack.reserve(20);
		assertEquals(10, stack.size());
		for (i in 0...10) assertEquals(9 - i, stack.pop());
	}
	
	#if debug
	function testMaxSize()
	{
		var stack = new ArrayedStack(0, 3);
		stack.push(0);
		stack.push(1);
		stack.push(2);
		
		var failed = false;
		try
		{
			stack.push(4);
		}
		catch (unknown:Dynamic)
		{
			failed = true;
		}
		
		assertTrue(failed);
		var stack = new ArrayedStack(0, 3);
		stack.push(0);
		stack.push(1);
		stack.push(2);
		
		var failed = false;
		try
		{
			stack.fill(0, 10);
		}
		catch (unknown:Dynamic)
		{
			failed = true;
		}
		
		assertTrue(failed);
	}
	#end
	
	function testStack()
	{
		var s:Stack<Int> = new ArrayedStack<Int>(5);
		assertTrue(true);
	}
	
	function testPack()
	{
		var l = new de.polygonal.ds.ArrayedStack<Int>();
		l.push(0);
		l.push(1);
		l.push(2);
		
		l.clear();
		
		assertEquals(0, untyped l.__get(0));
		assertEquals(1, untyped l.__get(1));
		assertEquals(2, untyped l.__get(2));
		
		l.pack();
		
		assertEquals(#if (flash9||flash10) 0 #else null #end, untyped l.__get(0));
		assertEquals(#if (flash9||flash10) 0 #else null #end, untyped l.__get(1));
		assertEquals(#if (flash9||flash10) 0 #else null #end, untyped l.__get(2));
	}
	
	function testPeek()
	{
		var stack = getStack();
		for (i in 0...10)
		{
			stack.push(i);
			assertEquals(stack.top(), i);
		}
    }
	
	function testPush()
	{
		var stack = getStack();
		for (i in 0...10) stack.push(i);
		for (i in 0...10) assertEquals(stack.get(i), i);
    }
	
	function testPop()
	{
		var stack = getStack();
		for (i in 0...10) stack.push(i);
		for (i in 0...10) assertEquals(stack.pop(), 10 - i - 1);
    }
	
	function testSetAt()
	{
		var stack = getStack();
		for (i in 0...10) stack.push(i);
		for (i in 0...10) stack.set(i, 10 + i);
		for (i in 0...10) assertEquals(10 + i, stack.get(i));
	}
	
	function testSwp()
	{
		var stack = getStack();
		for (i in 0...10) stack.push(i);
		stack.swp(0, 1);
		assertEquals(1, stack.get(0));
		assertEquals(0, stack.get(1));
	}
	
	function testCpy()
	{
		var stack = getStack();
		for (i in 0...10) stack.push(i);
		stack.cpy(0, 1);
		assertEquals(1, stack.get(0));
		assertEquals(1, stack.get(1));
	}
	
	function testWalk()
	{
		var stack = getStack();
		for (i in 0...10) stack.push(i);
		var f = function(val:Int, i:Int):Int
		{
			return val * i;
		}
		stack.walk(f);
		for (i in 0...10) assertEquals(i * i , stack.get(i));
	}
	
	function testContains()
	{
		var stack = getStack();
		for (i in 0...10) stack.push(i);
		for (i in 0...10) assertEquals(true, stack.contains(i));
	}
	
	function testClear()
	{
		var stack = getStack();
		for (i in 0...10) stack.push(i);
		stack.clear();
		assertEquals(0, stack.size());
		assertEquals(true, stack.isEmpty());
	}
	
	function testDispose()
	{
		var stack = getStack();
		for (i in 0...3) stack.push(i);
		var x = untyped stack._a[stack._top - 1];
		assertEquals(2, x);
		stack.pop();
		stack.dispose();
		var x = untyped stack._a[stack._top];
		var value = #if (flash) 0 #else null #end;
		assertEquals(value, x);
	}
	
	function testIterator()
	{
		var stack = getStack(100);
		for (i in 0...10) stack.push(i);
		var c = 10;
		var itr:de.polygonal.ds.ResettableIterator<Int> = cast stack.iterator();
		for (i in itr) assertEquals(i, --c);
		assertEquals(c, 0);
		c = 10;
		itr.reset();
		for (i in itr) assertEquals(i, --c);
		assertEquals(c, 0);
		c = 20;
		for (i in 0...10) stack.push(i + 10);
		itr.reset();
		for (i in itr) assertEquals(i, --c);
		assertEquals(c, 0);
	}
	
	function testIteratorRemove()
	{
		for (i in 0...5)
		{
			var s = new ArrayedStack<Int>(64);
			var set = new de.polygonal.ds.ListSet<Int>();
			for (j in 0...5)
			{
				s.push(j);
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
				assertTrue(set.remove(s.pop()));
			assertTrue(set.isEmpty());
		}
		
		var da = new ArrayedStack<Int>(64);
		for (j in 0...5) da.push(j);
		var itr = da.iterator();
		while (itr.hasNext())
		{
			itr.next();
			itr.remove();
		}
		assertTrue(da.isEmpty());
	}
	
	function testSize()
	{
		var stack = getStack();
		for (i in 0...10) stack.push(i);
		assertEquals(10, stack.size());
		for (i in 0..._size - 10) stack.push(i);
	}
	
	function testAssign()
	{
		var q = new ArrayedStack<E>(_size);
		assertEquals(0, q.size());
		q.assign(E, [0], _size);
		
		assertEquals(_size, q.size());
		for (i in 0..._size) assertEquals(E, cast Type.getClass(q.pop()));
		
		assertTrue(q.isEmpty());
		q.assign(E, [0], 10);
		assertEquals(10, q.size());
		for (i in 0...10) assertEquals(E, cast Type.getClass(q.pop()));
		
		assertTrue(q.isEmpty());
		q.assign(E, [5], _size);
		assertEquals(_size, q.size());
		for (i in 0..._size) assertEquals(5, q.pop().x);
		assertTrue(q.isEmpty());
	}
	
	function testFill()
	{
		var q = getStack();
		assertEquals(0, q.size());
		q.fill(99, _size);
		assertEquals(_size, q.size());
		for (i in 0..._size) assertEquals(99, q.pop());
		
		assertTrue(q.isEmpty());
		q.fill(88, 10);
		assertEquals(10, q.size());
		for (i in 0...10) assertEquals(88, q.pop());
		
		assertTrue(q.isEmpty());
	}
	
	function testToArray()
	{
		var stack = getStack();
		for (i in 0...10) stack.push(i);
		var a = stack.toArray();
		assertEquals(a.length, 10);
		for (i in 0...10) assertEquals(stack.pop(), a[i]);
	}
	
	function testShuffle()
	{
		var stack = getStack();
		for (i in 0...10) stack.push(i);
		var s = new ListSet<Int>();
		stack.shuffle(null);
		for (i in 0...10) assertEquals(true, s.set(stack.get(i)));
	}

	function testClone()
	{
		var stack = getStack();
		for (i in 0...10) stack.push(i);
		var copy:de.polygonal.ds.ArrayedStack<Int> = cast stack.clone(true);
		for (i in 0...10) assertEquals(copy.get(i), stack.get(i));
		assertEquals(10, copy.size());
	}
	
	function testCollection()
	{
		var c:de.polygonal.ds.Collection<Int> = cast new ArrayedStack<Int>(16);
		assertEquals(true, true);
	}
	
	function getStack(size = -1)
	{
		if (size != -1)
			return new de.polygonal.ds.ArrayedStack<Int>(size);
		else
			return new de.polygonal.ds.ArrayedStack<Int>(_size);
	}
}

private class E
{
	public var x:Int;
	public function new(x = 0)
	{
		this.x = x;
	}
	
	public function clone():E
	{
		return new E(x);
	}
}