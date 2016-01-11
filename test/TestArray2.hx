import de.polygonal.ds.Array2;
import de.polygonal.ds.ArrayConvert;
import de.polygonal.ds.Da;
import de.polygonal.ds.ListSet;
import de.polygonal.ds.Set;
import de.polygonal.ds.Vector;

class TestArray2 extends AbstractTest
{
	inline static var DEFAULT_SIZE = 10;
	
	var mW:Int;
	var mH:Int;
	
	function new(w = DEFAULT_SIZE, h = DEFAULT_SIZE)
	{
		super();
		mW = w;
		mH = h;
	}
	
	function testRemove()
	{
		var a = new Array2<Int>(10, 10);
		a.set(0, 0, 1);
		a.set(1, 1, 1);
		a.set(2, 2, 1);
		var success = a.remove(1);
		assertEquals(true, success);
		
		var x = a.get(0, 0);
		assertEquals(#if (js || neko) null #else 0 #end, x);
		
		var x = a.get(1, 1);
		assertEquals(#if (js || neko) null #else 0 #end, x);
		
		var x = a.get(2, 2);
		assertEquals(#if (js || neko) null #else 0 #end, x);
	}
	
	function testIndexOf()
	{
		var a = new Array2<Int>(10, 10);
		assertEquals(-1, a.indexOf(1));
		a.set( 0, 9, 1);
		assertEquals(100 - 10, a.indexOf(1));
	}
	
	function testIndexToCell()
	{
		var a = new Array2<Int>(5, 5);
		var c = new Array2Cell();
		for (y in 0...5)
		{
			for (x in 0...5)
			{
				var i = a.getIndex(x, y);
				a.indexToCell(i, c);
				assertEquals(x, c.x);
				assertEquals(y, c.y);
			}
		}
	}
	
	function testCellOf()
	{
		var c = new Array2Cell();
		var a = new Array2<Int>(9, 9);
		a.set(6, 3, 1);
		var index = a.indexOf(1);
		a.indexToCell(index, c);
		assertEquals(6, c.x);
		assertEquals(3, c.y);
	}
	
	#if !generic
	function testConvert()
	{
		var a = ArrayConvert.toArray2([0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3], 4, 3);
		assertEquals(a.size(), 4 * 3);
		assertEquals(a.getW(), 4);
		assertEquals(a.getH(), 3);
		for (y in 0...3)
			for (x in 0...4)
				assertEquals(x, a.get(x, y));
	}
	#end
	
	function testToString()
	{
		var array2 = new de.polygonal.ds.Array2<String>(4, 4);
		array2.iter(function(val:String, x:Int, y:Int):String { return Std.string(x) + "." + Std.string(y); });
		array2.toString();
		assertTrue(true);
	}
	
	function testReadWrite()
	{
		var a = getIntArray();
		a.set(0, 0, 1);
		a.set(mW - 1, mH - 1, 1);
		assertEquals(1, a.get(0, 0));
		assertEquals(1, a.get(mW - 1,mH - 1));
	}
	
	function testWidthHeight()
	{
		var a = getIntArray();
		assertEquals(mW, a.getW());
		assertEquals(mH, a.getH());
		a.setW(mW * 2);
		assertEquals(mW * 2, a.getW());
		a.setH(mW * 2);
		assertEquals(mW * 2, a.getH());
	}
	
	function testRow()
	{
		var a = getIntArray();
		for (i in 0...a.getW()) a.set(i, 0, i);
		var output = new Array<Int>();
		a.getRow(0, output);
		var input = new Array<Int>();
		for (i in 0...output.length)
		{
			assertEquals(i, output[i]);
			input.push((a.size()) + i);
		}
		a.setRow(1, input);
		for (i in 0...a.getW()) assertEquals((a.size()) + i, a.get(i, 1));
	}
	
	function testCol()
	{
		var a = getIntArray();
		for (i in 0...a.getH()) a.set(0, i, i);
		var output = new Array<Int>();
		a.getCol(0, output);
		var input = new Array<Int>();
		for (i in 0...output.length)
		{
			assertEquals(i, output[i]);
			input.push((a.size()) + i);
		}
		a.setCol(1, input);
		for (i in 0...a.getH()) assertEquals((a.size()) + i, a.get(1, i));
	}
	
	function testAssign()
	{
		var a = new Array2<E>(mW, mH);
		a.assign(E, [1]);
		for (y in 0...mH)
			for (x in 0...mW)
				assertEquals(E, cast Type.getClass(a.get(x, y)));
		
		var a = new Array2<E>(mW, mH);
		a.assign(E, [5]);
		for (y in 0...mH)
		{
			for (x in 0...mW)
			{
				assertEquals(E, cast Type.getClass(a.get(x, y)));
				assertEquals(5, a.get(x, y).x);
			}
		}
	}
	
	function testFill()
	{
		var a = getIntArray();
		a.fill(99);
		for (y in 0...mH)
			for (x in 0...mW)
				assertEquals(99, a.get(x, y));
		
		var a = new Array2<E>(mW, mH);
		var v = new E(0);
		a.fill(v);
		for (y in 0...mH)
			for (x in 0...mW)
				assertEquals(v, a.get(x, y));
	}
	
	function testWalk()
	{
		var a = getStrArray();
		for (y in 0...mH)
			for (x in 0...mW)
				assertEquals(x + "." + y, a.get(x, y));
	}
	
	function testResize()
	{
		var w2 = mW >> 1;
		var h2 = mH >> 1;
		var a = getIntArray(w2, h2);
		a.fill(5);
		for (y in 0...a.getH())
			for (x in 0...a.getW())
				assertEquals(5, a.get(x, y));
		a.resize(mW, mH);
		assertEquals(a.getW(), mW);
		assertEquals(a.getH(), mH);
		for (y in 0...mH)
		{
			for (x in 0...mW)
			{
				if (x < w2 && y < h2)
					assertEquals(5, a.get(x, y));
				else
				{
					var z = a.get(x, y);
					assertEquals(#if (js||neko) null #else 0 #end, z);
				}
			}
		}
	}
	
	function testShiftW()
	{
		var a = getStrArray();
		a.shiftW();
		for (y in 0...mH)
			for (x in 0...mW - 1)
				assertEquals((x + 1) + "." + y, a.get(x, y));
		for (y in 0...mH)
			assertEquals("0." + y, a.get(mW - 1, y));
	}
	
	function testShiftE()
	{
		var a = getStrArray();
		a.shiftE();
		for (y in 0...mH)
			for (x in 1...mW)
				assertEquals((x - 1) + "." + y, a.get(x, y));
		for (y in 0...mH)
			assertEquals((mW - 1) + "." + y, a.get(0, y));
	}
	
	function testShiftN()
	{
		var a = getStrArray();
		a.shiftN();
		for (y in 0...(mH - 1))
			for (x in 0...mW)
				assertEquals(x + "." + (y + 1), a.get(x, y));
		for (x in 0...mW)
			assertEquals(x + ".0", a.get(x, mH - 1));
	}
	
	function testShiftS()
	{
		var a = getStrArray();
		a.shiftS();
		for (y in 1...mH)
			for (x in 0...mW)
				assertEquals(Std.string(x) + "." + (y - 1), a.get(x, y));
		for (x in 0...mW)
			assertEquals(Std.string(x) + "." + Std.string(mH - 1), a.get(x, 0));
	}
	
	function testSwap()
	{
		var a = getIntArray();
		a.set(1, 1, 1);
		a.set(mW - 1, mH - 1, 9);
		a.swap(1, 1, mW - 1, mH - 1);
		assertEquals(a.get(1, 1), 9);
		assertEquals(a.get(mW - 1, mH - 1), 1);
	}
	
	function testAppendRow()
	{
		var a = getIntArray(mW, mH - 1);
		for (i in 0...mW) a.set(i, 0, i);
		var input = new Array<Int>();
		for (i in 0...mW) input.push(i);
		a.appendRow(input);
		assertEquals(a.getH(), mH);
		for (x in 0...mW) assertEquals(x, a.get(x, 0));
		for (x in 0...mW) assertEquals(x, a.get(x, mH - 1));
	}
	
	function testAppendCol()
	{
		var a = getIntArray(mW - 1, mH);
		for (i in 0...mH) a.set(0, i, i);
		
		var input = new Array<Int>();
		for (i in 0...mH) input.push(i);
		
		a.appendCol(input);
		
		assertEquals(a.getW(), mW);
		for (y in 0...mH) assertEquals(y, a.get(0, y));
		for (y in 0...mH) assertEquals(y, a.get(mW - 1, y));
	}
	
	function testPrependRow()
	{
		var a = getIntArray(mW, mH - 1);
		
		var c = 0;
		for (j in 0...mH - 1)
			for (i in 0...mW)
				a.set(i, j, c++);
		
		var input = new Array<Int>();
		for (i in 0...mW) input.push(100+i*100);
		
		a.prependRow(input);
		
		assertEquals(a.getH(), mH);
		
		var c = 0;
		for (j in 1...mH)
		{
			for (i in 0...mW)
			{
				assertEquals(c, a.get(i, j));
				c++;
			}
		}
		
		for (x in 0...mW) assertEquals(100 + x * 100, a.get(x, 0));
	}
	
	function testPrependCol()
	{
		var a = getIntArray(mW - 1, mH);
		
		for (i in 0...mH) a.set(mW - 2, i, 10 + i * 10);
		
		var input = new Array<Int>();
		for (i in 0...mH) input.push(i);
		a.prependCol(input);
		
		assertEquals(a.getW(), mW);
		for (y in 0...mH) assertEquals(y, a.get(0, y));
		for (y in 0...mH) assertEquals(10 + y * 10, a.get(mW - 1, y));
	}
	
	function testCopyRow()
	{
		var a = getIntArray(mW, mH);
		var dataRow1 = new Array();
		for (i in 0...mW) dataRow1[i] = i;
		var dataRow2 = new Array();
		for (i in 0...mW) dataRow2[i] = i + 10;
		a.setRow(0, dataRow1);
		a.setRow(2, dataRow2);
		a.copyRow(0, 3);
		a.copyRow(2, 1);
		for (i in 0...mW)
		{
			assertEquals(i, a.get(i, 3));
			assertEquals(i + 10, a.get(i, 2));
		}
	}
	
	function testSwapRow()
	{
		var a = getIntArray(mW, mH);
		var dataRow1 = new Array();
		for (i in 0...mW) dataRow1[i] = i;
		var dataRow2 = new Array();
		for (i in 0...mW) dataRow2[i] = i + 10;
		a.setRow(0, dataRow1);
		a.setRow(1, dataRow2);
		a.swapRow(0, 1);
		for (i in 0...mW)
		{
			assertEquals(i, a.get(i, 1));
			assertEquals(i + 10, a.get(i, 0));
		}
	}
	
	function testCopyCol()
	{
		var a = getIntArray(mW, mH);
		var dataCol1 = new Array();
		for (i in 0...mH) dataCol1[i] = i;
		var dataCol2 = new Array();
		for (i in 0...mH) dataCol2[i] = i + 10;
		a.setCol(0, dataCol1);
		a.setCol(2, dataCol2);
		a.copyCol(0, 3);
		a.copyCol(2, 1);
		for (i in 0...mH)
		{
			assertEquals(i, a.get(3, i));
			assertEquals(i + 10, a.get(2, i));
		}
	}
	
	function testSwapCol()
	{
		var a = getIntArray(mW, mH);
		var dataCol1 = new Array();
		for (i in 0...mH) dataCol1[i] = i;
		var dataCol2 = new Array();
		for (i in 0...mH) dataCol2[i] = i + 10;
		a.setCol(0, dataCol1);
		a.setCol(1, dataCol2);
		a.swapCol(0, 1);
		for (i in 0...mH)
		{
			assertEquals(i, a.get(1, i));
			assertEquals(i + 10, a.get(0, i));
		}
	}
	
	function testTranspose()
	{
		if (mW != mH)
			assertTrue(true);
		else
		{
			var a = getStrArray();
			a.transpose();
			for (y in 0...mH)
				for (x in 0...mW)
				 assertEquals(Std.string(y) + "." + Std.string(x), a.get(x, y));
			var a = getStrArray(4, 3);
			a.transpose();
			for (y in 0...4)
				for (x in 0...3)
				 assertEquals(Std.string(y) + "." + Std.string(x), a.get(x, y));
		}
	}
	
	function testContains()
	{
		var a = getStrArray();
		a.fill("?");
		for (y in 0...mH)
			for (x in 0...mW)
				assertEquals(true, a.contains("?"));
	}
	
	function testToArray()
	{
		var a = getStrArray();
		a.fill("?");
		var out = new Array<String>();
		var out = a.toArray();
		for (i in out)
			assertEquals("?", i);
		assertEquals(out.length, a.size());
	}
	
	function testToVector()
	{
		var a = getStrArray();
		a.fill("?");
		var arr = a.toVector();
		for (i in arr) assertEquals("?", i);
		assertEquals(arr.length, a.size());
	}
	
	function testIterator()
	{
		var a = getStrArray();
		a.fill("?");
		var c = 0;
		for (val in a)
		{
			assertEquals(val, "?");
			c++;
		}
		assertEquals(c, a.size());
		var c = 0;
		for (val in a)
		{
			assertEquals(val, "?");
			c++;
		}
		assertEquals(c, a.size());
		var s = new ListSet<String>();
		var a = getStrArray();
		a.iter(function(val:String, x:Int, y:Int):String
		{
			s.set(x + "." + y);
			return x + "." + y;
		});
		var s1:Set<String> = cast s.clone(true);
		var s2:Set<String> = cast s.clone(true);
		var itr:de.polygonal.ds.ResettableIterator<String> = cast a.iterator();
		for (i in itr) assertEquals(true, s1.remove(i));
		assertTrue(s1.isEmpty());
		itr.reset();
		for (i in itr) assertEquals(true, s2.remove(i));
		assertTrue(s2.isEmpty());
	}
	
	function testIteratorRemove()
	{
		var a = getStrArray();
		a.fill("?");
		var itr = a.iterator();
		while (itr.hasNext())
		{
			itr.next();
			itr.remove();
		}
		
		var arr = a.getVector();
		for (i in arr)
			assertEquals(i, null);
	}
	
	function testShuffle()
	{
		var a = getIntArray();
		var counter = 0;
		a.iter(function(x:Int, y:Int, val:Int):Int
		{
			return counter++;
		});
		assertEquals(a.size(), counter);
		var s = new ListSet<Int>();
		for (i in a) assertTrue(s.set(i));
		var rval = [];
		for (i in 0...a.size()) rval.push(Math.random());
		a.shuffle(rval);
		for (i in a) assertEquals(true, s.remove(i));
	}
	
	function testClone()
	{
		var a = getIntArray();
		a.set(0, 0, 1);
		a.set(mW - 1 , mH - 1, 1);
		var copier = function(input:Int):Int
		{
			return input;
		}
		var myCopy:Array2<Int> = cast a.clone(false, copier);
		assertEquals(myCopy.get(0, 0), 1);
		assertEquals(myCopy.get(mW - 1, mH - 1), 1);
		myCopy = cast myCopy.clone(true);
		assertEquals(myCopy.get(0, 0), 1);
		assertEquals(myCopy.get(mW - 1, mH - 1), 1);
    }
	
	function testCollection()
	{
		var c:de.polygonal.ds.Collection<Int> = cast getIntArray();
		assertEquals(true, true);
	}
	
	function getIntArray(w = -1, h = -1)
	{
		if (w == -1) w = mW;
		if (h == -1) h = mH;
		return new Array2<Int>(w, h);
	}
	
	function getStrArray(w = -1, h = -1)
	{
		if (w == -1) w = mW;
		if (h == -1) h = mH;
		var a = new Array2<String>(w, h);
		a.iter(function(val, x, y):String return x + "." + y);
		return a;
	}
	
	function testGetRect()
	{
		var a = getStrArray(10, 10);
		
		var output = a.getRect(-2, -2, 4, 4, []);
		
		var i = 0;
		for (y in 0...5)
			for (x in 0...5)
				assertEquals(x + "." + y, output[i++]);
				
		var a = getStrArray(3, 3);
		
		var output = a.getRect(0, 0, 0, 0, []);
		assertEquals(1, output.length);
		assertEquals("0.0", output[0]);
		
		var output = a.getRect(-1, -1, -1, -1, []);
		assertEquals(0, output.length);
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