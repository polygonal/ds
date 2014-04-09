package mem;

import de.polygonal.core.math.Mathematics;
import de.polygonal.core.math.random.Random;
import de.polygonal.ds.mem.ByteMemory;
import de.polygonal.ds.mem.MemoryAccess;
import de.polygonal.ds.mem.MemoryManager;

@:access(de.polygonal.ds.mem.MemoryAccess)
class TestMemoryManager extends haxe.unit.TestCase
{
	function new()
	{
		super();
		MemoryManager.BLOCK_SIZE_BYTES = 1024;
	}
	
	function test1a()
	{
		//initial allocation, exact fit
		var m = new ByteMemory(1024);
		assertEquals(0, MemoryManager.instance.bytesFree);
		assertEquals(1024, MemoryManager.instance.bytesUsed);
		assertEquals(1024, MemoryManager.instance.bytesTotal);
		m.free();
		MemoryManager.free();
	}
	
	function test2a()
	{
		//initial allocation, fits in bucket
		var m = new ByteMemory(1024 - 10);
		assertEquals(10, MemoryManager.instance.bytesFree);
		assertEquals(1014, MemoryManager.instance.bytesUsed);
		assertEquals(1024, MemoryManager.instance.bytesTotal);
		m.free();
		MemoryManager.free();
	}
	
	function test3a()
	{
		//initial allocation, doesn't fit in bucket
		var m = new ByteMemory(1024 + 10);
		assertEquals(2048 - 1024 - 10, MemoryManager.instance.bytesFree);
		assertEquals(1024 + 10, MemoryManager.instance.bytesUsed);
		assertEquals(1024 * 2, MemoryManager.instance.bytesTotal);
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
		
		assertEquals(0, MemoryManager.instance.bytesFree);
		assertEquals(1024 * 2, MemoryManager.instance.bytesUsed);
		assertEquals(1024 * 2, MemoryManager.instance.bytesTotal);
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
		assertEquals(1024 * 3 - 1024 * 2 - 20, MemoryManager.instance.bytesFree);
		assertEquals(1024 * 2 + 20, MemoryManager.instance.bytesUsed);
		assertEquals(1024 * 3, MemoryManager.instance.bytesTotal);
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
		assertEquals(20, MemoryManager.instance.bytesFree);
		assertEquals(1024 * 2 - 20, MemoryManager.instance.bytesUsed);
		assertEquals(1024 * 2, MemoryManager.instance.bytesTotal);
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
		
		assertEquals(1024 - 200, MemoryManager.instance.bytesFree);
		assertEquals(1024, MemoryManager.instance.bytesTotal);
		assertEquals(200, MemoryManager.instance.bytesUsed);
		
		mem1.resize(300);
		
		checkBytes(mem1, 100);
		checkZeroBytes(mem1, 100);
		checkBytes(mem3);
		assertEquals(1024 - 300 - 100, MemoryManager.instance.bytesFree);
		assertEquals(1024, MemoryManager.instance.bytesTotal);
		assertEquals(300 + 100, MemoryManager.instance.bytesUsed);
		
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
			if (a[i].mMemory == null) continue;
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
			if (a[i].mMemory == null) continue;
			checkBytes(a[i]);
			#end
		}
		
		for (i in 0...10)
		{
			#if debug
			if (a[i].mMemory == null) continue;
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
		
		assertEquals(768, MemoryManager.instance.bytesFree);
		assertEquals(256, MemoryManager.instance.bytesUsed);
		
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
		
		assertEquals(256, MemoryManager.instance.bytesFree);
		assertEquals(768, MemoryManager.instance.bytesUsed);
		
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
		MemoryManager.instance.pack();
		
		checkBytes(m1);
		checkBytes(m3);
		
		assertEquals(0, MemoryManager.instance.bytesFree);
		assertEquals(2048, MemoryManager.instance.bytesUsed);
		assertEquals(2048, MemoryManager.instance.bytesTotal);
		
		var m2 = new ByteMemory(1024);
		fillBytes(m2);
		checkBytes(m1);
		checkBytes(m2);
		checkBytes(m3);
		
		assertEquals(0, MemoryManager.instance.bytesFree);
		assertEquals(1024 * 3, MemoryManager.instance.bytesUsed);
		assertEquals(1024 * 3, MemoryManager.instance.bytesTotal);
		
		MemoryManager.free();
	}
	
	function testPack2()
	{
		var m1 = new ByteMemory(1024);
		fillBytes(m1);
		var m2 = new ByteMemory(1024);
		fillBytes(m2);
		
		MemoryManager.instance.pack();
		
		assertEquals(0, MemoryManager.instance.bytesFree);
		assertEquals(2048, MemoryManager.instance.bytesUsed);
		assertEquals(2048, MemoryManager.instance.bytesTotal);
		
		MemoryManager.free();
	}
	
	function testPackMultiple()
	{
		var m1 = new ByteMemory(1024);
		fillBytes(m1);
		var m2 = new ByteMemory(1024);
		fillBytes(m2);
		
		MemoryManager.instance.pack();
		
		assertEquals(0, MemoryManager.instance.bytesFree);
		assertEquals(2048, MemoryManager.instance.bytesUsed);
		assertEquals(2048, MemoryManager.instance.bytesTotal);
		
		MemoryManager.free();
	}
	
	function testDefragCaseDoesNotFit()
	{
		var m1 = new ByteMemory(100);
		fillBytes(m1);
		var m2 = new ByteMemory(200);
		fillBytes(m2);
		m1.free();
		
		MemoryManager.instance.defrag();
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
		MemoryManager.instance.defrag();
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
		MemoryManager.instance.defrag();
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
			MemoryManager.instance.defrag();
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
			MemoryManager.instance.defrag();
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
			MemoryManager.instance.defrag();
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
			MemoryManager.instance.defrag();
			for (t in a) checkBytes(t);
		}
		
		MemoryManager.free();
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