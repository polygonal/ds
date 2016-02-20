import de.polygonal.ds.ArrayedStack;
import de.polygonal.ds.Cloneable;
import de.polygonal.ds.ListSet;
import de.polygonal.ds.Stack;

@:access(de.polygonal.ds.ArrayedStack)
class TestArrayedStack extends AbstractTest
{
	inline static var DEFAULT_SIZE = 100;
	
	var mSize:Int;
	
	function new(size = DEFAULT_SIZE)
	{
		mSize = size;
		super();
	}
	
	function testSource()
	{
		var s = new ArrayedStack<Int>([0, 1, 2, 3]);
		assertEquals(4, s.size);
		for (i in 0...4) assertEquals((4 - i) - 1, s.pop());
	}
	
	function testGrow()
	{
		var s = new ArrayedStack<Int>(4);
		for (i in 0...4) s.push(i);
		assertEquals(4, s.size);
		assertEquals(4, s.capacity);
		
		s.push(4);
		assertEquals(5, s.size);
		assertTrue(s.capacity > 4);
	}
	
	function testFree()
	{
		var s:ArrayedStack<Int> = new ArrayedStack<Int>();
		for (i in 0...3) s.push(i);
		s.free();
		assertTrue(true);
	}
	
	function testDup()
	{
		var s:ArrayedStack<Int> = new ArrayedStack<Int>();
		for (i in 0...2) s.push(i);
		s.dup();
		assertEquals(3, s.size);
		assertEquals(1, s.top());
		assertEquals(1, s.get(s.size - 2));
		assertEquals(0, s.get(s.size - 3));
	}
	
	function testExchange()
	{
		var s:ArrayedStack<Int> = new ArrayedStack<Int>();
		s.push(0);
		s.push(1);
		s.exchange();
		assertEquals(0, s.top());
		assertEquals(1, s.get(s.size - 2));
		var s:ArrayedStack<Int> = new ArrayedStack<Int>();
		s.push(0);
		s.push(1);
		s.push(2);
		s.exchange();
		assertEquals(1, s.top());
		assertEquals(2, s.get(s.size - 2));
	}
	
	function testRotRight()
	{
		var s:ArrayedStack<Int> = new ArrayedStack<Int>();
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
		
		var s:ArrayedStack<Int> = new ArrayedStack<Int>();
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
		var s:ArrayedStack<Int> = new ArrayedStack<Int>();
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
		
		var s:ArrayedStack<Int> = new ArrayedStack<Int>();
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
		var s = new ArrayedStack<Int>();
		var values = [1, 2, 3, 4, 5];
		for (i in values) s.push(i);
		var k = 5;
		for (i in 0...5)
		{
			s.remove(values.shift());
			assertEquals(s.size, --k);
			for (j in values) assertTrue(s.contains(j));
		}
		assertTrue(s.isEmpty());
	}
	
	/*function testReserve()
	{
		var stack = new ArrayedStack<Int>(16, 20);
		for (i in 0...10) stack.push(i);
		stack.reserve(20);
		assertEquals(10, stack.size);
		for (i in 0...10) assertEquals(9 - i, stack.pop());
	}*/
	
	function _testPack() //TODO
	{
		var l = new de.polygonal.ds.ArrayedStack<Int>();
		l.push(0);
		l.push(1);
		l.push(2);
		
		l.clear();
		
		//assertEquals(0, l._get(0));
		//assertEquals(1, l._get(1));
		//assertEquals(2, l._get(2));
		//l.shrinkToFit();
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
		stack.swap(0, 1);
		assertEquals(1, stack.get(0));
		assertEquals(0, stack.get(1));
	}
	
	function testCpy()
	{
		var stack = getStack();
		for (i in 0...10) stack.push(i);
		stack.copy(0, 1);
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
		stack.forEach(f);
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
		assertEquals(0, stack.size);
		assertEquals(true, stack.isEmpty());
	}
	
	/*function testDispose()
	{
		var stack = getStack();
		for (i in 0...3) stack.push(i);
		var x = stack.mData[stack.mTop - 1];
		assertEquals(2, x);
		stack.pop();
		stack.dispose();
		var x = stack.mData[stack.mTop];
		//var value = #if (flash) 0 #else null #end;
		//assertEquals(value, x);
	}*/
	
	function testIterator()
	{
		var stack = getStack(100);
		for (i in 0...10) stack.push(i);
		var c = 10;
		var itr = stack.iterator();
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
		assertEquals(10, stack.size);
		for (i in 0...mSize - 10) stack.push(i);
	}
	
	function testForEach()
	{
		var s = new ArrayedStack<Int>(mSize);
		s.push(0);
		s.push(1);
		s.push(2);
		s.forEach(
			function(v, i)
			{
				assertEquals(i, v);
				return v;
			});
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
		assertEquals(10, copy.size);
		
		var copy:de.polygonal.ds.ArrayedStack<Int> = cast stack.clone(false, function(x) return x);
		for (i in 0...10) assertEquals(copy.get(i), stack.get(i));
		assertEquals(10, copy.size);
		
		var stack = new de.polygonal.ds.ArrayedStack<E>(4);
		for (i in 0...4) stack.push(new E(i));
		var copy:de.polygonal.ds.ArrayedStack<E> = cast stack.clone(false);
		for (i in 0...4) assertEquals(i, stack.get(i).x);
		assertEquals(4, copy.size);
	}
	
	function testCollection()
	{
		var c:de.polygonal.ds.Collection<Int> = cast new ArrayedStack<Int>(16);
		assertEquals(true, true);
	}
	
	function getStack(size = -1):ArrayedStack<Int>
	{
		if (size != -1)
			return new de.polygonal.ds.ArrayedStack<Int>(size);
		else
			return new de.polygonal.ds.ArrayedStack<Int>(mSize);
	}
}

private class E implements Cloneable<E>
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