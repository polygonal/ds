import de.polygonal.ds.Array2;
import de.polygonal.ds.Cloneable;
import de.polygonal.ds.tools.NativeArrayTools;

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
	
	function testSource()
	{
		var a = new Array2<Int>(2, 2, [0, 1, 2, 3]);
		assertEquals(0, a.get(0, 0));
		assertEquals(1, a.get(1, 0));
		assertEquals(2, a.get(0, 1));
		assertEquals(3, a.get(1, 1));
	}
	
	function testRemove()
	{
		var a = new Array2<Int>(10, 10);
		a.set(0, 0, 1);
		a.set(1, 1, 1);
		a.set(2, 2, 1);
		var success = a.remove(1);
		assertEquals(true, success);
		var x = a.get(0, 0); assertEquals(isDynamic() ? null : 0, x);
		var x = a.get(1, 1); assertEquals(isDynamic() ? null : 0, x);
		var x = a.get(2, 2); assertEquals(isDynamic() ? null : 0, x);
	}
	
	function testIndexOf()
	{
		var a = new Array2<Int>(10, 10);
		assertEquals(-1, a.indexOf(1));
		a.set(0, 9, 1);
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
	
	function testToString()
	{
		#if no_tostring
		assertTrue(true);
		#else
		var array2 = new de.polygonal.ds.Array2<String>(4, 4);
		array2.forEach(function(val:String, x:Int, y:Int):String { return Std.string(x) + "." + Std.string(y); });
		array2.toString();
		assertTrue(true);
		#end
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
		assertEquals(mW, a.cols);
		assertEquals(mH, a.rows);
		a.width = mW * 2;
		assertEquals(mW * 2, a.cols);
		a.height = mW * 2;
		assertEquals(mW * 2, a.rows);
	}
	
	function testRow()
	{
		var a = getIntArray();
		for (i in 0...a.cols) a.set(i, 0, i);
		var output = new Array<Int>();
		a.getRow(0, output);
		var input = new Array<Int>();
		for (i in 0...output.length)
		{
			assertEquals(i, output[i]);
			input.push((a.size) + i);
		}
		a.setRow(1, input);
		for (i in 0...a.cols) assertEquals((a.size) + i, a.get(i, 1));
	}
	
	function testCol()
	{
		var a = getIntArray();
		for (i in 0...a.rows) a.set(0, i, i);
		var output = new Array<Int>();
		a.getCol(0, output);
		var input = new Array<Int>();
		for (i in 0...output.length)
		{
			assertEquals(i, output[i]);
			input.push((a.size) + i);
		}
		a.setCol(1, input);
		for (i in 0...a.rows) assertEquals((a.size) + i, a.get(1, i));
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
		a.forEach(function(e, x, y) return 5);
		for (y in 0...a.rows)
			for (x in 0...a.cols)
				assertEquals(5, a.get(x, y));
		a.resize(mW, mH);
		assertEquals(a.cols, mW);
		assertEquals(a.rows, mH);
		for (y in 0...mH)
		{
			for (x in 0...mW)
			{
				if (x < w2 && y < h2)
					assertEquals(5, a.get(x, y));
				else
				{
					var z = a.get(x, y);
					assertEquals(isDynamic() ? null : 0, z);
				}
			}
		}
		
		var a = getStrArray(4, 4);
		a.forEach(function(e, x, y) return x + "" + y);
		a.resize(4, 3);
		assertEquals(a.cols, 4);
		assertEquals(a.rows, 3);
		a.forEach(
			function(e, x, y)
			{
				assertEquals(e, x + "" + y);
				return e;
			});
		
		var a = getStrArray(4, 3);
		a.forEach(function(e, x, y) return x + "" + y);
		a.resize(4, 4);
		assertEquals(a.cols, 4);
		assertEquals(a.rows, 4);
		a.forEach(
			function(e, x, y)
			{
				if (y == 3)
					assertEquals(e, null);
				else
					assertEquals(e, x + "" + y);
				return e;
			});
	}
	
	function testShiftLeft()
	{
		var a = getStrArray();
		a.shiftLeft(true);
		for (y in 0...mH)
			for (x in 0...mW - 1)
				assertEquals((x + 1) + "." + y, a.get(x, y));
		for (y in 0...mH)
			assertEquals("0." + y, a.get(mW - 1, y));
		
		var a = getStrArray();
		a.shiftLeft(false);
		for (y in 0...mH)
			for (x in 0...mW - 1)
				assertEquals((x + 1) + "." + y, a.get(x, y));
		for (y in 0...mH)
			assertEquals("9." + y, a.get(mW - 1, y));
	}
	
	function testShiftRight()
	{
		var a = getStrArray();
		a.shiftRight(true);
		for (y in 0...mH)
			for (x in 1...mW)
				assertEquals((x - 1) + "." + y, a.get(x, y));
		for (y in 0...mH)
			assertEquals((mW - 1) + "." + y, a.get(0, y));
		
		var a = getStrArray();
		a.shiftRight(false);
		for (y in 0...mH)
			for (x in 1...mW)
				assertEquals((x - 1) + "." + y, a.get(x, y));
		for (y in 0...mH)
			assertEquals("0." + y, a.get(0, y));
	}
	
	function testShiftUp()
	{
		var a = getStrArray();
		a.shiftUp(true);
		for (y in 0...(mH - 1))
			for (x in 0...mW)
				assertEquals(x + "." + (y + 1), a.get(x, y));
		for (x in 0...mW)
			assertEquals(x + ".0", a.get(x, mH - 1));
		
		var a = getStrArray();
		a.shiftUp(false);
		for (y in 0...(mH - 1))
			for (x in 0...mW)
				assertEquals(x + "." + (y + 1), a.get(x, y));
		for (x in 0...mW)
			assertEquals(x + ".9", a.get(x, mH - 1));
	}
	
	function testShiftDown()
	{
		var a = getStrArray();
		a.shiftDown(true);
		for (y in 1...mH)
			for (x in 0...mW)
				assertEquals(Std.string(x) + "." + (y - 1), a.get(x, y));
		for (x in 0...mW)
			assertEquals(Std.string(x) + "." + Std.string(mH - 1), a.get(x, 0));
		
		var a = getStrArray();
		a.shiftDown(false);
		for (y in 1...mH)
			for (x in 0...mW)
				assertEquals(Std.string(x) + "." + (y - 1), a.get(x, y));
		for (x in 0...mW)
			assertEquals(x + ".0", a.get(x, 0));
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
		assertEquals(a.rows, mH);
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
		
		assertEquals(a.cols, mW);
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
		
		assertEquals(a.rows, mH);
		
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
		
		assertEquals(a.cols, mW);
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
	
	function testCopy()
	{
		var a = getIntArray(3, 3);
		a.forEach(function(_, _, _) return 1);
		var b = getIntArray(3, 3);
		b.forEach(function(_, _, _) return 2);
		b.copy(a, 0, 0, 0, 0);
		var data = a.getData();
		for (i in 0...9) assertEquals(1, NativeArrayTools.get(data, i));
		
		var a = getIntArray(5, 5);
		a.forEach(function(_, _, _) return 1);
		var b = getIntArray(3, 3);
		b.forEach(function(_, _, _) return 2);
		
		a.copy(b, 0, 0, 1, 1);
		
		var values =
		[
			1,1,1,1,1,
			1,2,2,2,1,
			1,2,2,2,1,
			1,2,2,2,1,
			1,1,1,1,1
		];
		
		var data = a.getData();
		for (i in 0...25) assertEquals(values[i], NativeArrayTools.get(data, i));
		
		a.forEach(function(_, _, _) return 1);
		a.copy(b, 0, 0, 3, 3);
		
		var values =
		[
			1,1,1,1,1,
			1,1,1,1,1,
			1,1,1,1,1,
			1,1,1,2,2,
			1,1,1,2,2
		];
		
		var data = a.getData();
		for (i in 0...25) assertEquals(values[i], NativeArrayTools.get(data, i));
		
		a.forEach(function(_, _, _) return 1);
		a.resize(2, 2);
		a.copy(b, 0, 0, 0, 0);
		
		var values =
		[
			2,2,
			2,2
		];
		
		var data = a.getData();
		for (i in 0...4) assertEquals(values[i], NativeArrayTools.get(data, i));
		
		var a = getStrArray(3, 3);
		var b = getStrArray(3, 3);
		b.forEach(function(_, _, _) return null);
		b.copy(a, 1, 1, 0, 0);
		
		var values =
		[
			"1.1", "2.1", null,
			"1.2", "2.2", null,
			null ,  null, null
		];
		var data = b.getData();
		for (i in 0...9) assertEquals(values[i], NativeArrayTools.get(data, i));
		
		var a = getStrArray(3, 3);
		var b = getStrArray(3, 3);
		b.forEach(function(_, _, _) return null);
		b.copy(a, 1, 1, 2, 1);
		var values =
		[
			null, null,  null,
			null, null, "1.1",
			null, null, "1.2"
		];
		var data = b.getData();
		for (i in 0...9) assertEquals(values[i], NativeArrayTools.get(data, i));
		
		var a = getStrArray(3, 3);
		var b = getStrArray(3, 3);
		b.forEach(function(_, _, _) return null);
		b.copy(a, 3, 3, 3, 3);
		var data = b.getData();
		for (i in 0...9) assertEquals(null, NativeArrayTools.get(data, i));
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
		a.forEach(function(e, x, y) return "?");
		for (y in 0...mH)
			for (x in 0...mW)
				assertEquals(true, a.contains("?"));
	}
	
	function testToArray()
	{
		var a = getStrArray();
		a.forEach(function(e, x, y) return "?");
		var out = a.toArray();
		for (i in out)
			assertEquals("?", i);
		assertEquals(out.length, a.size);
	}
	
	function testIterator()
	{
		var a = getStrArray();
		a.forEach(function(e, x, y) return "?");
		var c = 0;
		for (val in a)
		{
			assertEquals(val, "?");
			c++;
		}
		assertEquals(c, a.size);
		var c = 0;
		for (val in a)
		{
			assertEquals(val, "?");
			c++;
		}
		assertEquals(c, a.size);
		
		var a = getStrArray();
		var set1 = [];
		var set2 = [];
		var set3 = [];
		a.forEach(function(val:String, x:Int, y:Int):String
		{
			var s = x + "." + y;
			set1.push(s);
			set2.push(s);
			set3.push(s);
			return s;
		});
		
		var itr = a.iterator();
		for (i in itr) assertEquals(true, set1.remove(i));
		assertEquals(0, set1.length);
		
		itr.reset();
		for (i in itr) assertEquals(true, set2.remove(i));
		assertEquals(0, set2.length);
		
		var itr = a.iterator();
		while (itr.hasNext())
		{
			itr.hasNext();
			var e = itr.next();
			assertEquals(true, set3.remove(e));
		}
		assertEquals(0, set3.length);
	}
	
	function testIteratorRemove()
	{
		var a = getStrArray();
		a.forEach(function(e, x, y) return "?");
		var itr = a.iterator();
		while (itr.hasNext())
		{
			itr.next();
			itr.remove();
		}
		
		for (i in a)
			assertEquals(i, null);
	}
	
	function testShuffle()
	{
		var a = getIntArray();
		var counter = 0;
		a.forEach(function(x:Int, y:Int, val:Int):Int
		{
			return counter++;
		});
		
		assertEquals(a.size, counter);
		
		var set = [];
		for (i in a)
		{
			assertFalse(contains(set, i));
			set.push(i);
		}
		
		var rval = [];
		for (i in 0...a.size) rval.push(Math.random());
		a.shuffle(rval);
		
		for (i in a) assertEquals(true, set.remove(i));
		assertEquals(0, set.length);
	}
	
	function testClone()
	{
		var a = getIntArray();
		a.set(0, 0, 1);
		a.set(mW - 1 , mH - 1, 1);
		var copier = function(input:Int):Int return input;
		
		var myCopy:Array2<Int> = cast a.clone(false, copier);
		assertEquals(myCopy.get(0, 0), 1);
		assertEquals(myCopy.get(mW - 1, mH - 1), 1);
		myCopy = cast myCopy.clone(true);
		assertEquals(myCopy.get(0, 0), 1);
		assertEquals(myCopy.get(mW - 1, mH - 1), 1);
		
		var i = 0;
		var a = new Array2<E>(2, 2);
		a.forEach(function(e, x, y) return new E(i++));
		var clone:Array2<E> = cast a.clone(false);
		assertEquals(4, clone.size);
		i = 0;
		clone.forEach(function(e, x, y) {assertEquals(i++, e.x); return e; });
    }
	
	function testCollection()
	{
		var c:de.polygonal.ds.Collection<Int> = cast getIntArray();
		assertEquals(true, c != null);
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
		a.forEach(function(val, x, y):String return x + "." + y);
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
	
	function testForEach()
	{
		var a = getStrArray(3, 3);
		for (y in 0...3)
			for (x in 0...3)
				a.set(x, y, '$x$y');
		
		a.forEach(
			function(v, x, y)
			{
				assertEquals(v, '$x$y');
				return 'v$x$y';
			});
		
		a.forEach(
			function(v, x, y)
			{
				assertEquals(v, 'v$x$y');
				return v;
			});
	}
	
	function testIter()
	{
		var a = getStrArray(3, 3);
		
		var s1 = "";
		
		for (y in 0...3)
		{
			for (x in 0...3)
			{
				a.set(x, y, '$x$y');
				s1 += '$x$y';
			}
		}
		
		var s2 = "";
		a.iter(function(e) s2 += e);
		assertEquals(s1, s2);
	}
	
	function testCountNeighbors()
	{
		var a = getIntArray(3, 3);
		a.setAll(1);
		
		var c = a.countNeighbors(1, 1, function(value:Int) return value > 0);
		assertEquals(8, c);
		
		var c = a.countNeighbors(1, 1, function(value:Int) return value > 0, true);
		assertEquals(4 , c);
	}
}

private class E implements Cloneable<E>
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