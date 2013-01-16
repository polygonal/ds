package test.mem;

import de.polygonal.core.math.Mathematics;
import de.polygonal.core.math.random.Random;
import de.polygonal.ds.mem.ByteMemory;
import de.polygonal.ds.mem.MemoryAccess;
import de.polygonal.ds.mem.MemoryManager;
import flash.geom.Rectangle;
import flash.Lib;

class TestMemoryManager extends haxe.unit.TestCase
{
	public function new() 
	{
		super();
		MemoryManager.BLOCK_SIZE_BYTES = 1024;
	}
	
	function test1a()
	{
		//initial allocation, exact fit
		var m = new ByteMemory(1024);
		assertEquals(0, MemoryManager.bytesFree());
		assertEquals(1024, MemoryManager.bytesUsed());
		assertEquals(1024, MemoryManager.bytesTotal());
		m.free();
		MemoryManager.free();
	}
	
	function test2a()
	{
		//initial allocation, fits in bucket
		var m = new ByteMemory(1024 - 10);
		assertEquals(10, MemoryManager.bytesFree());
		assertEquals(1014, MemoryManager.bytesUsed());
		assertEquals(1024, MemoryManager.bytesTotal());
		m.free();
		MemoryManager.free();
	}
	
	function test3a()
	{
		//initial allocation, doesn't fit in bucket
		var m = new ByteMemory(1024 + 10);
		assertEquals(2048 - 1024 - 10, MemoryManager.bytesFree());
		assertEquals(1024 + 10, MemoryManager.bytesUsed());
		assertEquals(1024 * 2, MemoryManager.bytesTotal());
		m.free();
		MemoryManager.free();
	}
	
	function test1b()
	{
		//initial + second allocation, exact fit
		var m1 = new ByteMemory(1024);
		fillBytes(m1);
		var m2 = new ByteMemory(1024);
		fillBytes(m2);
		
		checkBytes(m1);
		checkBytes(m2);
		
		assertEquals(0, MemoryManager.bytesFree());
		assertEquals(1024 * 2, MemoryManager.bytesUsed());
		assertEquals(1024 * 2, MemoryManager.bytesTotal());
		checkBytes(m1);
		checkBytes(m2);
		m1.free();
		m2.free();
		MemoryManager.free();
	}
	
	function test2b()
	{
		//initial + second allocation, doesn't fit in bucket
		var m1 = new ByteMemory(1024 + 10);
		fillBytes(m1);
		var m2 = new ByteMemory(1024 + 10);
		fillBytes(m2);
		assertEquals(1024 * 3 - 1024 * 2 - 20, MemoryManager.bytesFree());
		assertEquals(1024 * 2 + 20, MemoryManager.bytesUsed());
		assertEquals(1024 * 3, MemoryManager.bytesTotal());
		checkBytes(m1);
		checkBytes(m2);
		m1.free();
		m2.free();
		MemoryManager.free();
	}
	
	function test3b()
	{
		//initial + second allocation, t fit in bucket
		var m1 = new ByteMemory(1024 - 10);
		fillBytes(m1);
		var m2 = new ByteMemory(1024 - 10);
		fillBytes(m2);
		assertEquals(20, MemoryManager.bytesFree());
		assertEquals(1024 * 2 - 20, MemoryManager.bytesUsed());
		assertEquals(1024 * 2, MemoryManager.bytesTotal());
		checkBytes(m1);
		checkBytes(m2);
		m1.free();
		m2.free();
		MemoryManager.free();
	}
	
	function test4()
	{
		var m1 = new ByteMemory(512);
		fillBytes(m1);
		var m2 = new ByteMemory(512);
		fillBytes(m2);
		var m3 = new ByteMemory(4096);
		fillBytes(m3);
		
		checkBytes(m1);
		checkBytes(m2);
		checkBytes(m3);
		
		m3.free();
		
		checkBytes(m1);
		checkBytes(m2);
		
		m2.free();
		
		checkBytes(m1);
		
		m1.free();
		MemoryManager.free();
	}
	
	function test5()
	{
		var m = new Array<ByteMemory>();
		for (i in 0...10)
		{
			m[i] = new ByteMemory(800);
			fillBytes(m[i]);
		}
		
		for (i in 0...10)
		{
			if (Mathematics.isEven(i))
				m[i].free();
		}
		
		for (i in 0...10)
		{
			if (!Mathematics.isEven(i))
				checkBytes(m[i]);
		}
		
		var m2 = new ByteMemory(2048);
		MemoryManager.free();
	}
	
	function testGrowCase1()
	{
		var mem = new ByteMemory(100);
		fillBytes(mem);
		
		mem.resize(200);
		
		checkBytes(mem, 100);
		checkZeroBytes(mem, 100);
		
		mem.free();
		MemoryManager.free();
	}
	
	function testGrowCase2()
	{
		//one full interval - allocate more memory
		var mem = new ByteMemory(1024);
		fillBytes(mem);
		
		mem.resize(1024 + 100);
		
		checkBytes(mem, 1024);
		checkZeroBytes(mem, 1024);
		
		mem.free();
		MemoryManager.free();
	}
	
	function testGrowCase3()
	{
		//one interval gets filled to block size; drop empty
		var mem = new ByteMemory(512);
		fillBytes(mem);
		
		mem.resize(1024);
		
		checkBytes(mem, 512);
		checkZeroBytes(mem, 512);
		
		mem.free();
		MemoryManager.free();
	}
	
	function testGrowCase4()
	{
		//collect emtpy spaces
		var mem1 = new ByteMemory(100);
		var mem2 = new ByteMemory(100);
		var mem3 = new ByteMemory(100);
		fillBytes(mem1);
		fillBytes(mem2);
		fillBytes(mem3);
		
		mem2.free();
		
		assertEquals(1024 - 200, MemoryManager.bytesFree());
		assertEquals(1024, MemoryManager.bytesTotal());
		assertEquals(200, MemoryManager.bytesUsed());
		
		mem1.resize(300);
		
		checkBytes(mem1, 100);
		checkZeroBytes(mem1, 100);
		checkBytes(mem3);
		assertEquals(1024 - 300 - 100, MemoryManager.bytesFree());
		assertEquals(1024, MemoryManager.bytesTotal());
		assertEquals(300 + 100, MemoryManager.bytesUsed());
		
		mem3.resize(724);
		
		checkBytes(mem1, 100);
		checkZeroBytes(mem1, 100);
		checkBytes(mem3, 100);
		checkZeroBytes(mem3, 100);
		
		mem1.free();
		mem3.free();
		MemoryManager.free();
	}
	
	function testGrowCase5()
	{
		//collect emtpy spaces and resize at end
		var a = new Array();
		for (i in 0...10)
		{
			a[i] = new ByteMemory(10 + i * 50);
			fillBytes(a[i]);
			
		}
		
		a[1].free();
		a[3].free();
		a[6].free();
		a[8].free();
		
		for (i in 0...10)
		{
			#if debug
			if (untyped a[i]._memory == null) continue;
			checkBytes(a[i]);
			#end
		}
		
		var newSize = 2000;
		
		a[0].resize(newSize);
		
		checkBytes(a[0], 10);
		checkZeroBytes(a[0], 10);
		
		for (i in 1...10)
		{
			#if debug
			if (untyped a[i]._memory == null) continue;
			checkBytes(a[i]);
			#end
		}
		
		for (i in 0...10)
		{
			#if debug
			if (untyped a[i]._memory == null) continue;
			a[i].free();
			#end
		}
		
		MemoryManager.free();
	}
	
	function testGrowCase6()
	{
		//collect emtpy spaces and resize at end
		var m1 = new ByteMemory(1560);
		fillBytes(m1);
		
		var m2 = new ByteMemory(105);
		fillBytes(m2);
		
		var m3 = new ByteMemory(1404);
		fillBytes(m3);
		
		var m4 = new ByteMemory(1069);
		fillBytes(m4);
		
		var m5 = new ByteMemory(1704);
		fillBytes(m5);
		
		var m6 = new ByteMemory(80);
		fillBytes(m6);
		
		m1.resize(m1.size + 10);
		
		checkBytes(m1, m1.size - 10);
		checkZeroBytes(m1, m1.size - 10, m1.size);
		checkBytes(m2);
		checkBytes(m3);
		checkBytes(m4);
		checkBytes(m5);
		checkBytes(m6);
		
		m1.free();
		m2.free();
		m3.free();
		m4.free();
		m5.free();
		m6.free();
		MemoryManager.free();
	}
	
	function testShrink1()
	{
		var mem = new ByteMemory(1024);
		fillBytes(mem);
		
		mem.resize(512);
		
		checkBytes(mem);
		
		mem.free();
		MemoryManager.free();
	}
	
	function testShrink2()
	{
		var mem = new ByteMemory(512);
		fillBytes(mem);
		
		mem.resize(256);
		
		checkBytes(mem);
		
		assertEquals(768, MemoryManager.bytesFree());
		assertEquals(256, MemoryManager.bytesUsed());
		
		mem.free();
		MemoryManager.free();
	}
	
	function testShrink3()
	{
		var mem1 = new ByteMemory(512);
		var mem2 = new ByteMemory(512);
		fillBytes(mem1);
		fillBytes(mem2);
		
		mem1.resize(256);
		
		checkBytes(mem1);
		checkBytes(mem2);
		
		assertEquals(256, MemoryManager.bytesFree());
		assertEquals(768, MemoryManager.bytesUsed());
		
		mem1.free();
		mem2.free();
		MemoryManager.free();
	}
	
	function testPack1()
	{
		var m1 = new ByteMemory(1024);
		fillBytes(m1);
		
		var m2 = new ByteMemory(1024);
		fillBytes(m2);
		
		var m3 = new ByteMemory(1024);
		fillBytes(m3);
		
		m2.free();
		MemoryManager.pack();
		
		checkBytes(m1);
		checkBytes(m3);
		
		assertEquals(0, MemoryManager.bytesFree());
		assertEquals(2048, MemoryManager.bytesUsed());
		assertEquals(2048, MemoryManager.bytesTotal());
		
		var m2 = new ByteMemory(1024);
		fillBytes(m2);
		checkBytes(m1);
		checkBytes(m2);
		checkBytes(m3);
		
		assertEquals(0, MemoryManager.bytesFree());
		assertEquals(1024 * 3, MemoryManager.bytesUsed());
		assertEquals(1024 * 3, MemoryManager.bytesTotal());
		
		MemoryManager.free();
	}
	
	function testPack2()
	{
		var m1 = new ByteMemory(1024);
		fillBytes(m1);
		var m2 = new ByteMemory(1024);
		fillBytes(m2);
		
		MemoryManager.pack();
		
		assertEquals(0, MemoryManager.bytesFree());
		assertEquals(2048, MemoryManager.bytesUsed());
		assertEquals(2048, MemoryManager.bytesTotal());
		
		MemoryManager.free();
	}
	
	function testPackMultiple()
	{
		var m1 = new ByteMemory(1024);
		fillBytes(m1);
		var m2 = new ByteMemory(1024);
		fillBytes(m2);
		
		MemoryManager.pack();
		
		assertEquals(0, MemoryManager.bytesFree());
		assertEquals(2048, MemoryManager.bytesUsed());
		assertEquals(2048, MemoryManager.bytesTotal());
		
		MemoryManager.free();
	}
	
	function testDefragCaseDoesNotFit()
	{
		var m1 = new ByteMemory(100);
		fillBytes(m1);
		var m2 = new ByteMemory(200);
		fillBytes(m2);
		m1.free();
		
		MemoryManager.defrag();
		checkBytes(m2);
		MemoryManager.free();
	}
	
	function testDefragCaseFit()
	{
		var m1 = new ByteMemory(200);
		fillBytes(m1);
		var m2 = new ByteMemory(100);
		fillBytes(m2);
		m1.free();
		MemoryManager.defrag();
		checkBytes(m2);
		MemoryManager.free();
	}
	
	function testDefragCaseExactFit()
	{
		var m1 = new ByteMemory(200);
		fillBytes(m1);
		var m2 = new ByteMemory(200);
		fillBytes(m2);
		m1.free();
		MemoryManager.defrag();
		checkBytes(m2);
		MemoryManager.free();
	}
	
	function testDefragMultipleExactFit()
	{
		var a = new Array<ByteMemory>();
		for (i in 0...10)
		{
			a[i] = new ByteMemory(100);
			fillBytes(a[i]);
		}
		
		for (i in 0...10)
		{
			var m = a.shift();
			
			m.free();
			MemoryManager.defrag();
			for (t in a) checkBytes(t);
		}
		
		MemoryManager.free();
	}
	
	function testDefragMultipleFit()
	{
		var a = new Array<ByteMemory>();
		for (i in 0...10)
		{
			a[i] = new ByteMemory(100 + ((10 - i) * 100));
			fillBytes(a[i]);
		}
		
		for (i in 0...10)
		{
			var m = a.shift();
			
			m.free();
			MemoryManager.defrag();
			for (t in a) checkBytes(t);
		}
		
		MemoryManager.free();
	}
	
	function testDefragMultipleDoesNotFit()
	{
		var a = new Array<ByteMemory>();
		for (i in 0...10)
		{
			a[i] = new ByteMemory(100 + (i * 10));
			fillBytes(a[i]);
		}
		
		for (i in 0...10)
		{
			var m = a.shift();
			
			m.free();
			MemoryManager.defrag();
			for (t in a) checkBytes(t);
		}
		
		MemoryManager.free();
	}
	
	function testDefragMultipleRandom()
	{
		var a = new Array<ByteMemory>();
		for (i in 0...10)
		{
			a[i] = new ByteMemory(100 + Random.randRange(0, 100));
			fillBytes(a[i]);
		}
		
		for (i in 0...10)
		{
			var m = a.shift();
			
			m.free();
			MemoryManager.defrag();
			for (t in a) checkBytes(t);
		}
		
		MemoryManager.free();
	}
	
	function testDefragState()
	{
		var data =
		[
			[0,602,0],
			[603,912,0],
			[913,2482,0],
			[2483,4524,0],
			[4525,4905,1],
			[4906,6418,0],
			[6419,7079,0],
			[7080,8307,0],
			[8308,10310,1],
			[10311,10573,0],
			[10574,12497,0],
			[12498,13796,0],
			[13797,14060,0],
			[14061,15824,1],
			[15825,17082,0],
			[17083,18820,0],
			[18821,19618,0],
			[19619,20106,1],
			[20107,21057,0],
			[21058,21270,0],
			[21271,21601,0],
			[21602,23435,0],
			[23436,25292,0],
			[25293,26121,0],
			[26122,27603,1],
			[27604,29330,0],
			[29331,32399,1],
			[32400,32459,0],
			[32460,32982,0],
			[32983,33426,1],
			[33427,34269,0],
			[34270,34585,0],
			[34586,36016,0],
			[36017,36544,1],
			[36545,36601,0],
			[36602,37537,0],
			[37538,39096,0],
			[39097,40483,0],
			[40484,41152,0],
			[41153,41756,0],
			[41757,41874,0],
			[41875,42408,0],
			[42409,45306,1],
			[45307,46594,0],
			[46595,47923,0],
			[47924,49019,0],
			[49020,50168,0],
			[50169,52003,0],
			[52004,53092,0],
			[53093,54717,0],
			[54718,55101,1],
			[55102,57074,0],
			[57075,57115,0],
			[57116,57417,1],
			[57418,59458,0],
			[59459,60189,0],
			[60190,63889,1],
			[63890,64605,0],
			[64606,65310,0],
			[65311,65546,0],
			[65547,66109,0],
			[66110,67214,0],
			[67215,68607,0]
		];
		MemoryManager.restoreState(data);
		MemoryManager.defrag();
	}
	
	function fillBytes(m:ByteMemory)
	{
		for (i in 0...m.size) m.set(i, i % 10);
	}
	
	function checkBytes(m:ByteMemory, limit = -1)
	{
		if (limit == -1) limit = m.size;
		for (i in 0...limit) assertEquals(i % 10, m.get(i));
	}
	
	function checkZeroBytes(m:ByteMemory, min:Int, max = -1)
	{
		if  (max == -1) max = m.size;
		for (i in min...max) assertEquals(0, m.get(i));
	}
}