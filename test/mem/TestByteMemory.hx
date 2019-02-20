package mem;

import polygonal.ds.tools.mem.ByteMemory;
import haxe.ds.Vector;
import haxe.io.BytesData;

#if alchemy
import polygonal.ds.tools.mem.MemoryManager;
#end

class TestByteMemory extends AbstractTest
{
	function new()
	{
		super();
		
		#if (flash && alchemy)
		MemoryManager.free();
		#end
	}
	
	function test()
	{
		var b = new ByteMemory(256);
		fillData(b);
		checkData(b);
		
		assertEquals(256, b.size);
		assertEquals(256, b.bytes);
		
		b.clear();
		for (i in 0...256) assertEquals(0, b.get(i));
		
		b.free();
		#if alchemy MemoryManager.free(); #end
	}
	
	function testClone()
	{
		var m = new ByteMemory(100);
		for (i in 0...100) m.set(i, i);
		
		var c = m.clone();
		for (i in 0...100) assertEquals(i, c.get(i));
		
		assertEquals(m.size, c.size);
		#if alchemy MemoryManager.free(); #end
	}
	
	function testToArray()
	{
		var b = new ByteMemory(256);
		fillData(b);
		
		var v = ByteMemory.toArray(b);
		checkArray(v, 0, 256);
		assertEquals(256, v.length);
		var v = ByteMemory.toArray(b, 64, 128);
		checkArray(v, 64, 128);
		assertEquals(64, v.length);
		
		b.free();
		#if alchemy MemoryManager.free(); #end
	}
	
	function testOfArray()
	{
		var v = new Array();
		for (i in 0...256) v[i] = i % 10;
		
		var b = ByteMemory.ofArray(v);
		checkData(b);
		b.free();
		#if alchemy MemoryManager.free(); #end
		
		var b = ByteMemory.ofArray(v, 64, 128);
		checkData(b, 64, 128);
		b.free();
		#if alchemy MemoryManager.free(); #end
	}
	
	function testToVector()
	{
		var b = new ByteMemory(256);
		fillData(b);
		
		var v = ByteMemory.toVector(b);
		checkVector(v, 0, 256);
		assertEquals(256, v.length);
		
		var v = ByteMemory.toVector(b, 64, 128);
		checkVector(v, 64, 128);
		assertEquals(64, v.length);
		
		b.free();
		#if alchemy MemoryManager.free(); #end
	}
	
	function testOfVector()
	{
		var v = new Vector(256);
		for (i in 0...256) v[i] = i % 10;
		
		var b = ByteMemory.ofVector(v);
		checkData(b);
		b.free();
		
		var b = ByteMemory.ofVector(v, 64, 128);
		checkData(b, 64, 128);
		b.free();
		#if alchemy MemoryManager.free(); #end
	}
	
	#if (flash || nme)
	function testToByteArray()
	{
		var b = new ByteMemory(256);
		fillData(b);
		var v = ByteMemory.toByteArray(b);
		checkByteArray(v, 0, 256);
		assertEquals(256, v.length);
		var v = ByteMemory.toByteArray(b, 64, 128);
		checkByteArray(v, 64, 128);
		assertEquals(64, v.length);
		b.free();
		#if alchemy MemoryManager.free(); #end
	}
	
	function testOfByteArray()
	{
		var v = new flash.utils.ByteArray();
		for (i in 0...256) v.writeByte(i % 10);
		var b = ByteMemory.ofByteArray(v);
		checkData(b);
		b.free();
		#if alchemy MemoryManager.free(); #end
		var v = new flash.utils.ByteArray();
		for (i in 0...256) v.writeByte(i % 10);
		var b = ByteMemory.ofByteArray(v, 64, 128);
		checkData(b, 64, 128);
		b.free();
		#if alchemy MemoryManager.free(); #end
	}
	#end
	
	function testFill()
	{
		for (i in 1...32 + 1)
		{
			var m = new ByteMemory(i);
			m.setAll(123);
			for (j in 0...i) assertEquals(123, m.get(j));
			m.free();
		}
		#if (flash && alchemy) MemoryManager.free(); #end
	}
	
	function fillData(m:ByteMemory)
	{
		for (i in 0...m.size) m.set(i, i % 10);
	}
	
	function checkData(m:ByteMemory, min = -1, max = -1)
	{
		if (min == -1) min = 0;
		if (max == -1) max = m.size;
		
		for (i in 0...max - min) assertEquals((i + min) % 10, m.get(i));
	}
	
	inline function checkVector(v:Vector<Int>, min = -1, max = -1)
	{
		if (min == -1) min = 0;
		if (max == -1) max = v.length;
		
		for (i in 0...max - min) assertEquals((i + min) % 10, v[i]);
	}
	
	function checkArray(v:Array<Int>, min = -1, max = -1)
	{
		if (min == -1) min = 0;
		if (max == -1) max = v.length;
		
		for (i in 0...max - min) assertEquals((i + min) % 10, v[i]);
	}
	
	#if flash
	function checkByteArray(v:flash.utils.ByteArray, min = -1, max = -1)
	{
		v.position = 0;
		if (min == -1) min = 0;
		if (max == -1) max = v.length;
		for (i in 0...max - min) assertEquals((i + min) % 10, v[i]);
	}
	#end
	
	function checkBytesData(v:BytesData, min = -1, max = -1)
	{
		#if flash
		v.position = 0;
		
		if (min == -1) min = 0;
		if (max == -1) max = v.length;
		
		for (i in 0...max - min) assertEquals((i + min) % 10, v[i]);
		#else
		var bytes = Bytes.ofData(v);
		var input:BytesInput = new BytesInput(bytes);
		
		if (min == -1) min = 0;
		if (max == -1) max = bytes.length;
		for (i in 0...max - min) assertEquals((i + min) % 10, input.readByte());
		#end
	}
}