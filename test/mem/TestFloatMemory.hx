package mem;

import de.polygonal.ds.mem.FloatMemory;

import haxe.io.Bytes;
import haxe.io.BytesData;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;

#if alchemy
import de.polygonal.ds.mem.MemoryManager;
#end

class TestFloatMemory extends haxe.unit.TestCase
{
	public function new()
	{
		super();
		
		#if (flash && alchemy)
		MemoryManager.free();
		#end
	}
	
	function test()
	{
		var b = new FloatMemory(256);
		fillData(b);
		checkData(b);
		
		assertEquals(256, b.size);
		assertEquals(256 << 2, b.bytes);
		
		b.clear();
		for (i in 0...256) assertEquals(.0, b.get(i));
		
		b.free();
		#if alchemy MemoryManager.free(); #end
	}
	
	function testClone()
	{
		var m = new FloatMemory(100);
		for (i in 0...100) m.set(i, 1.0 * i);
		
		var c = m.clone();
		for (i in 0...100) assertEquals(i * 1.0, c.get(i));
		assertEquals(m.size, c.size);
	}
	
	function testFill()
	{
		for (i in 1...10 + 1)
		{
			var m = new FloatMemory(i);
			m.fill(123.);
			for (j in 0...i) assertEquals(123., m.get(j));
			m.free();
		}
	}
	
	function testToArray()
	{
		var b = new FloatMemory(256);
		fillData(b);
		
		var v = FloatMemory.toArray(b);
		
		checkArray(v, 0, 256);
		assertEquals(256, v.length);
		
		var v = FloatMemory.toArray(b, 64, 128);
		checkArray(v, 64, 128);
		assertEquals(64, v.length);
		
		b.free();
		#if alchemy MemoryManager.free(); #end
	}
	function testOfArray()
	{
		var v = new Array<Float>();
		for (i in 0...256) v[i] = i % 10;
		
		var b = FloatMemory.ofArray(v);
		
		checkData(b);
		b.free();
		#if alchemy MemoryManager.free(); #end
		
		var b = new FloatMemory(256);
		var b = FloatMemory.ofArray(v, 64, 128);
		checkData(b, 64, 128);
		b.free();
		#if alchemy MemoryManager.free(); #end
	}
	#if flash10
	function testToVector()
	{
		var b = new FloatMemory(256);
		fillData(b);
		
		var v = FloatMemory.toVector(b);
		
		checkVector(v, 0, 256);
		assertEquals(256, v.length);
		
		var v = FloatMemory.toVector(b, 64, 128);
		checkVector(v, 64, 128);
		assertEquals(64, v.length);
		
		b.free();
		#if alchemy MemoryManager.free(); #end
	}
	function testOfVector()
	{
		var v = new flash.Vector<Float>(256, true);
		for (i in 0...256) v[i] = i % 10;
		
		var b = FloatMemory.ofVector(v);
		
		checkData(b);
		b.free();
		#if alchemy MemoryManager.free(); #end
		
		var b = new FloatMemory(256);
		var b = FloatMemory.ofVector(v, 64, 128);
		checkData(b, 64, 128);
		b.free();
		#if alchemy MemoryManager.free(); #end
	}
	#end
	
	#if (flash9 || cpp)
	function testToByteArray()
	{
		var b = new FloatMemory(256);
		fillData(b);
		var v = FloatMemory.toByteArray(b);
		assertEquals(256 << 2, v.length);
		checkByteArray(v);
		var v = FloatMemory.toByteArray(b, 64, 128);
		checkByteArray(v, 64, 128);
		assertEquals(64 << 2, v.length);
		b.free();
		#if alchemy MemoryManager.free(); #end
	}
	function testOfByteArray()
	{
		var bytes = new flash.utils.ByteArray();
		for (i in 0...256) bytes.writeFloat(i % 10);
		var m = FloatMemory.ofByteArray(bytes);
		assertEquals(m.size, 256);
		checkData(m);
		m.free();
		#if alchemy MemoryManager.free(); #end
		
		var bytes = new flash.utils.ByteArray();
		bytes.endian = flash.utils.Endian.BIG_ENDIAN;
		for (i in 0...256) bytes.writeFloat(i % 10);
		
		var m = FloatMemory.ofByteArray(bytes);
		assertEquals(m.size, 256);
		
		checkData(m);
		m.free();
		#if alchemy MemoryManager.free(); #end
		
		var bytes = new flash.utils.ByteArray();
		bytes.endian = flash.utils.Endian.BIG_ENDIAN;
		for (i in 0...256) bytes.writeFloat(i % 10);
		
		var m = FloatMemory.ofByteArray(bytes, 64 << 2, 128 << 2);
		assertEquals(m.size, 64);
		
		checkData(m, 64, 128);
		m.free();
		#if alchemy MemoryManager.free(); #end
	}
	#end
	
	#if (flash9 || cpp)
	function testToBytesData()
	{
		var b = new FloatMemory(256);
		fillData(b);
		var v = FloatMemory.toBytesData(b);
		
		#if neko
		assertEquals(256 << 2, neko.NativeString.length(v));
		#else
		assertEquals(256 << 2, v.length);
		#end
		
		checkBytesData(v);
		
		var v = FloatMemory.toBytesData(b, 64, 128);
		checkBytesData(v, 64, 128);
		#if neko
		assertEquals(64 << 2, neko.NativeString.length(v));
		#else
		assertEquals(64 << 2, v.length);
		#end
		
		b.free();
		#if alchemy MemoryManager.free(); #end
	}
	#end
	
	#if (flash9 || cpp)
	function testOfBytesData()
	{
		var output = new BytesOutput();
		for (i in 0...256) output.writeFloat(i % 10);
		var m = FloatMemory.ofBytesData(output.getBytes().getData());
		assertEquals(m.size, 256);
		checkData(m);
		m.free();
		#if alchemy MemoryManager.free(); #end
	}
	#end
	
	function fillData(m:FloatMemory)
	{
		for (i in 0...m.size) m.set(i, i % 10);
	}
	
	function checkData(m:FloatMemory, min = -1, max = -1)
	{
		if (min == -1) min = 0;
		if (max == -1) max = m.size;
		
		for (i in 0...max - min) assertEquals((i + min) % 10, Std.int(m.get(i)));
	}
	
	#if flash10
	function checkVector(data:flash.Vector<Float>, min = -1, max = -1)
	{
		if (min == -1) min = 0;
		if (max == -1) max = data.length;
		
		for (i in 0...max - min) assertEquals((i + min) % 10, Std.int(data[i]));
	}
	#end
	
	function checkArray(data:Array<Float>, min = -1, max = -1)
	{
		if (min == -1) min = 0;
		if (max == -1) max = data.length;
		
		for (i in 0...max - min) assertEquals((i + min) % 10, Std.int(data[i]));
	}
	
	#if (flash9 || cpp)
	function checkByteArray(data:flash.utils.ByteArray, min = -1, max = -1)
	{
		data.position = 0;
		if (min == -1) min = 0;
		if (max == -1) max = data.length >> 2;
		for (i in 0...max - min) assertEquals((i + min) % 10, Std.int(data.readFloat()));
	}
	#end
	
	function checkBytesData(data:BytesData, min = -1, max = -1)
	{
		#if flash
		data.position = 0;
		
		if (min == -1) min = 0;
		if (max == -1) max = data.length >> 2;
		
		for (i in 0...max - min) assertEquals((i + min) % 10, Std.int(data.readFloat()));
		#else
		var bytes = Bytes.ofData(data);
		var input:BytesInput = new BytesInput(bytes);
		
		if (min == -1) min = 0;
		if (max == -1) max = bytes.length >> 2;
		for (i in 0...max - min) assertEquals((i + min) % 10, Std.int(input.readFloat()));
		#end
	}
}