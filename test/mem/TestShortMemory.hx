package mem;

import polygonal.ds.tools.mem.ShortMemory;
import haxe.ds.Vector;
import haxe.io.Bytes;
import haxe.io.BytesData;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;

#if alchemy
import polygonal.ds.tools.mem.MemoryManager;
#end

class TestShortMemory extends AbstractTest
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
		var b = new ShortMemory(256);
		fillData(b);
		checkBytes(b);
		
		assertEquals(256, b.size);
		assertEquals(256 << 1, b.bytes);
		
		b.clear();
		for (i in 0...256) assertEquals(0, b.get(i));
		
		b.free();
		#if alchemy MemoryManager.free(); #end
	}
	
	function testClone()
	{
		var m = new ShortMemory(100);
		for (i in 0...100) m.set(i, i);
		
		var c = m.clone();
		for (i in 0...100) assertEquals(i, c.get(i));
		
		assertEquals(m.size, c.size);
	}
	
	function testFill()
	{
		for (i in 1...10 + 1)
		{
			var m = new ShortMemory(i);
			m.setAll(123);
			for (j in 0...i) assertEquals(123, m.get(j));
			m.free();
		}
	}
	
	function testToArray()
	{
		var b = new ShortMemory(256);
		fillData(b);
		var v = ShortMemory.toArray(b);
		checkArray(v, 0, 256);
		assertEquals(256, v.length);
		var v = ShortMemory.toArray(b, 64, 128);
		checkArray(v, 64, 128);
		assertEquals(64, v.length);
		b.free();
		#if alchemy MemoryManager.free(); #end
	}
	
	function testOfArray()
	{
		var v = new Array();
		for (i in 0...256) v[i] = i % 10;
		
		var b = ShortMemory.ofArray(v);
		
		checkBytes(b);
		b.free();
		#if alchemy MemoryManager.free(); #end
		
		var b = ShortMemory.ofArray(v, 64, 128);
		checkBytes(b, 64, 128);
		b.free();
		#if alchemy MemoryManager.free(); #end
	}
	
	#if flash
	function testToVector()
	{
		var b = new ShortMemory(256);
		fillData(b);
		
		var v = ShortMemory.toVector(b);
		checkVector(v, 0, 256);
		assertEquals(256, v.length);
		
		var v = ShortMemory.toVector(b, 64, 128);
		checkVector(v, 64, 128);
		assertEquals(64, v.length);
		
		b.free();
		
		var b = new ShortMemory(256);
		fillData(b);
		
		var output = new Vector<Int>(b.size);
		var v = ShortMemory.toVector(b, -1, -1, output);
		checkVector(v, 0, 256);
		assertEquals(256, v.length);
		
		var v = ShortMemory.toVector(b, 64, 128);
		checkVector(v, 64, 128);
		assertEquals(64, v.length);
		
		b.free();
		
		#if alchemy MemoryManager.free(); #end
	}
	
	function testOfVector()
	{
		var v = new Vector(256);
		for (i in 0...256) v[i] = i % 10;
		
		var b = ShortMemory.ofVector(v);
		
		checkBytes(b);
		b.free();
		#if alchemy MemoryManager.free(); #end
		
		var b = ShortMemory.ofVector(v, 64, 128);
		checkBytes(b, 64, 128);
		b.free();
		#if alchemy MemoryManager.free(); #end
	}
	#end
	
	#if flash
	function testToByteArray()
	{
		var b = new ShortMemory(256);
		fillData(b);
		var v = ShortMemory.toByteArray(b);
		assertEquals(256 << 1, v.length);
		checkByteArray(v);
		//var v = ShortMemory.toByteArray(b, 64, 128);
		//checkByteArray(v, 64, 128);
		//assertEquals(64 << 1, v.length);
		//b.free();
		//#if alchemy MemoryManager.free(); #end
	}
	
	function testOfByteArray()
	{
		var bytes = new flash.utils.ByteArray();
		for (i in 0...256) bytes.writeShort(i % 10);
		
		var m = ShortMemory.ofByteArray(bytes);
		assertEquals(m.size, 256);
		checkBytes(m);
		m.free();
		#if alchemy MemoryManager.free(); #end
		
		#if flash
		var bytes = new flash.utils.ByteArray();
		bytes.endian = flash.utils.Endian.BIG_ENDIAN;
		for (i in 0...256) bytes.writeShort(i % 10);
		bytes.endian = flash.utils.Endian.BIG_ENDIAN;
		var m = ShortMemory.ofByteArray(bytes);
		assertEquals(m.size, 256);
		
		checkBytes(m);
		m.free();
		#if alchemy MemoryManager.free(); #end
		
		var bytes = new flash.utils.ByteArray();
		bytes.endian = flash.utils.Endian.BIG_ENDIAN;
		for (i in 0...256) bytes.writeShort(i % 10);
		
		var m = ShortMemory.ofByteArray(bytes, 64 << 1, 128 << 1);
		assertEquals(m.size, 64);
		
		checkBytes(m, 64, 128);
		m.free();
		#if alchemy MemoryManager.free(); #end
		#end
	}
	#end
	
	function testToBytesData()
	{
		var b = new ShortMemory(256);
		fillData(b);
		
		var v = ShortMemory.toBytesData(b);
		
		#if neko
		assertEquals(256 << 1, neko.NativeString.length(v));
		#else
		assertEquals(256 << 1, v.length);
		#end
		
		checkBytesData(v);
		
		var v = ShortMemory.toBytesData(b, 64, 128);
		checkBytesData(v, 64, 128);
		#if neko
		assertEquals(64 << 1, neko.NativeString.length(v));
		#else
		assertEquals(64 << 1, v.length);
		#end
		
		b.free();
		#if alchemy MemoryManager.free(); #end
	}
	
	function testOfBytesData()
	{
		var output = new BytesOutput();
		for (i in 0...256) output.writeInt16(i % 10);
		var m = ShortMemory.ofBytesData(output.getBytes().getData());
		assertEquals(m.size, 256);
		checkBytes(m);
		m.free();
		#if alchemy MemoryManager.free(); #end
	}
	
	function fillData(data:ShortMemory)
	{
		for (i in 0...data.size) data.set(i, i % 10);
	}
	
	function checkBytes(data:ShortMemory, min = -1, max = -1)
	{
		if (min == -1) min = 0;
		if (max == -1) max = data.size;
		
		for (i in 0...max - min) assertEquals((i + min) % 10, data.get(i));
	}
	
	#if flash
	inline function checkVector(data:Vector<Int>, min = -1, max = -1)
	{
		if (min == -1) min = 0;
		if (max == -1) max = data.length;
		
		for (i in 0...max - min)
		{
			assertEquals((i + min) % 10, data[i]);
		}
	}
	#end
	
	function checkArray(data:Array<Int>, min = -1, max = -1)
	{
		if (min == -1) min = 0;
		if (max == -1) max = data.length;
		for (i in 0...max - min) assertEquals((i + min) % 10, data[i]);
	}
	
	
	#if flash
	function checkByteArray(data:flash.utils.ByteArray, min = -1, max = -1)
	{
		data.position = 0;
		if (min == -1) min = 0;
		if (max == -1) max = data.length >> 1;
		for (i in 0...max - min) assertEquals((i + min) % 10, Std.int(data.readShort()));
	}
	#end
	
	function checkBytesData(data:BytesData, min = -1, max = -1)
	{
		var bytes = Bytes.ofData(data);
		var input:BytesInput = new BytesInput(bytes);
		
		if (min == -1) min = 0;
		if (max == -1) max = bytes.length >> 1;
		for (i in 0...max - min) assertEquals((i + min) % 10, Std.int(input.readUInt16()));
	}
}