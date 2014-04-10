package mem;

import de.polygonal.ds.mem.IntMemory;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;
#if alchemy
import de.polygonal.ds.mem.MemoryManager;
#end
import haxe.io.BytesData;

class TestIntMemory extends haxe.unit.TestCase
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
		var b = new IntMemory(256);
		fillData(b);
		checkBytes(b);
		
		assertEquals(256, b.size);
		assertEquals(256 << 2, b.bytes);
		
		b.clear();
		for (i in 0...256) assertEquals(0, b.get(i));
		
		b.free();
		
		#if alchemy MemoryManager.free(); #end
	}
	
	function testFill()
	{
		for (i in 1...10 + 1)
		{
			var m = new IntMemory(i);
			m.fill(123);
			for (j in 0...i) assertEquals(123, m.get(j));
			m.free();
		}
	}
	
	function testClone()
	{
		var m = new IntMemory(100);
		for (i in 0...100) m.set(i, i);
		
		var c = m.clone();
		for (i in 0...100) assertEquals(i, c.get(i));
		
		assertEquals(m.size, c.size);
	}
	
	function testToArray()
	{
		var b = new IntMemory(256);
		fillData(b);
		var v = IntMemory.toArray(b);
		checkArray(v, 0, 256);
		assertEquals(256, v.length);
		var v = IntMemory.toArray(b, 64, 128);
		checkArray(v, 64, 128);
		assertEquals(64, v.length);
		b.free();
		#if alchemy MemoryManager.free(); #end
	}
	
	function testOfArray()
	{
		var v = new Array();
		for (i in 0...256) v[i] = i % 10;
		
		var b = IntMemory.ofArray(v);
		
		checkBytes(b);
		b.free();
		#if alchemy MemoryManager.free(); #end
		
		var b = new IntMemory(256);
		var b = IntMemory.ofArray(v, 64, 128);
		checkBytes(b, 64, 128);
		b.free();
		#if alchemy MemoryManager.free(); #end
	}
	
	#if flash
	function testToVector()
	{
		var b = new IntMemory(256);
		fillData(b);
		
		var v = IntMemory.toVector(b);
		checkVector(v, 0, 256);
		assertEquals(256, v.length);
		
		var v = IntMemory.toVector(b, 64, 128);
		checkVector(v, 64, 128);
		assertEquals(64, v.length);
		
		b.free();
		#if alchemy MemoryManager.free(); #end
	}
	
	function testOfVector()
	{
		var v = new flash.Vector(256, true);
		for (i in 0...256) v[i] = i % 10;
		
		var b = IntMemory.ofVector(v);
		
		checkBytes(b);
		b.free();
		#if alchemy MemoryManager.free(); #end
		
		var b = new IntMemory(256);
		var b = IntMemory.ofVector(v, 64, 128);
		checkBytes(b, 64, 128);
		b.free();
		#if alchemy MemoryManager.free(); #end
	}
	#end
	
	#if flash
	function testToByteArray()
	{
		var mem = new IntMemory(256);
		fillData(mem);
		var bytes = IntMemory.toByteArray(mem);
		assertEquals(256 << 2, bytes.length);
		checkByteArray(bytes);
		var bytes = IntMemory.toByteArray(mem, 64, 128);
		checkByteArray(bytes, 64, 128);
		assertEquals(64 << 2, bytes.length);
		mem.free();
		#if alchemy MemoryManager.free(); #end
	}
	
	function testOfByteArray()
	{
		var bytes = new flash.utils.ByteArray();
		for (i in 0...256) bytes.writeInt(i % 10);
		var m = IntMemory.ofByteArray(bytes);
		assertEquals(m.size, 256);
		checkBytes(m);
		
		m.free();
		#if alchemy MemoryManager.free(); #end
		
		var bytes = new flash.utils.ByteArray();
		bytes.endian = flash.utils.Endian.BIG_ENDIAN;
		for (i in 0...256) bytes.writeInt(i % 10);
		
		var m = IntMemory.ofByteArray(bytes);
		assertEquals(m.size, 256);
		
		checkBytes(m);
		m.free();
		#if alchemy MemoryManager.free(); #end
		
		var bytes = new flash.utils.ByteArray();
		bytes.endian = flash.utils.Endian.BIG_ENDIAN;
		for (i in 0...256) bytes.writeInt(i % 10);
		
		var m = IntMemory.ofByteArray(bytes, 64 << 2, 128 << 2);
		assertEquals(m.size, 64);
		
		checkBytes(m, 64, 128);
		m.free();
		#if alchemy MemoryManager.free(); #end
	}
	#end
	
	#if flash
	function testToBytesData()
	{
		var mem = new IntMemory(256);
		fillData(mem);
		
		var bytes = IntMemory.toByteArray(mem);
		#if neko
		assertEquals(256 << 2, neko.NativeString.length(bytes));
		#else
		assertEquals(256 << 2, bytes.length);
		#end
		
		checkByteArray(bytes);
		
		var bytes = IntMemory.toByteArray(mem, 64, 128);
		checkByteArray(bytes, 64, 128);
		#if neko
		assertEquals(64 << 2, neko.NativeString.length(bytes));
		#else
		assertEquals(64 << 2, bytes.length);
		#end
		
		mem.free();
		#if alchemy MemoryManager.free(); #end
	}
	
	function testOfBytesData()
	{
		var bytes =
		#if neko
		neko.NativeString.ofString('');
		#else
		new BytesData();
		#end
		
		var output = new BytesOutput();
		
		for (i in 0...256)
		#if haxe3
		output.writeInt32(i % 10);
		#else
		output.writeInt32(haxe.Int32.ofInt(i % 10));
		#end
		
		var m = IntMemory.ofBytesData(output.getBytes().getData());
		assertEquals(m.size, 256);
		
		checkBytes(m);
		m.free();
		#if alchemy MemoryManager.free(); #end
	}
	#end
	
	function fillData(data:IntMemory)
	{
		for (i in 0...data.size) data.set(i, i % 10);
	}
	
	function checkBytes(data:IntMemory, min = -1, max = -1)
	{
		if (min == -1) min = 0;
		if (max == -1) max = data.size;
		
		for (i in 0...max - min)
			assertEquals((i + min) % 10, data.get(i));
	}
	
	#if flash
	inline function checkVector(data:flash.Vector<Int>, min = -1, max = -1)
	{
		if (min == -1) min = 0;
		if (max == -1) max = data.length;
		
		for (i in 0...max - min)
			assertEquals((i + min) % 10, data[i]);
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
		if (max == -1) max = data.length >> 2;
		for (i in 0...max - min) assertEquals((i + min) % 10, Std.int(data.readInt()));
	}
	#end
	
	function checkBytesData(data:BytesData, min = -1, max = -1)
	{
		#if flash
		data.position = 0;
		
		if (min == -1) min = 0;
		if (max == -1) max = data.length >> 2;
		
		for (i in 0...max - min) assertEquals((i + min) % 10, Std.int(data.readInt()));
		#else
		var bytes = Bytes.ofData(data);
		var input:BytesInput = new BytesInput(bytes);
		
		if (min == -1) min = 0;
		if (max == -1) max = bytes.length >> 2;
		
		#if haxe3
		for (i in 0...max - min) assertEquals((i + min) % 10, input.readInt32());
		#else
		for (i in 0...max - min) assertEquals((i + min) % 10, haxe.Int32.toInt(input.readInt32()));
		#end
		#end
	}
}