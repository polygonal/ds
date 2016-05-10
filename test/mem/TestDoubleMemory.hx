package mem;

import de.polygonal.ds.mem.DoubleMemory;
import haxe.ds.Vector;
import haxe.io.Bytes;
import haxe.io.BytesData;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;

#if alchemy
import de.polygonal.ds.mem.MemoryManager;
#end

class TestDoubleMemory extends AbstractTest
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
		var b = new DoubleMemory(256);
		fillData(b);
		checkData(b);
		assertEquals(256, b.size);
		assertEquals(256 << 3, b.bytes);
		b.clear();
		for (i in 0...256) assertEquals(.0, b.get(i));
		
		b.free();
		#if alchemy MemoryManager.free(); #end
	}
	
	function testClone()
	{
		var m = new DoubleMemory(100);
		for (i in 0...100) m.set(i, 1.0 * i);
		var c = m.clone();
		for (i in 0...100) assertEquals(i * 1.0, c.get(i));
		
		assertEquals(m.size, c.size);
	}
	
	function testFill()
	{
		var m = new DoubleMemory(100);
		m.setAll(123.);
		for (i in 0...100) assertEquals(123., m.get(i));
	}
	
	function testToArray()
	{
		var b = new DoubleMemory(256);
		fillData(b);
		
		var v = DoubleMemory.toArray(b);
		checkArray(v, 0, 256);
		assertEquals(256, v.length);
		
		var v = DoubleMemory.toArray(b, 64, 128);
		checkArray(v, 64, 128);
		assertEquals(64, v.length);
		
		b.free();
		#if alchemy MemoryManager.free(); #end
	}
	
	function testOfArray()
	{
		var v = new Array<Float>();
		for (i in 0...256) v[i] = i % 10;
		
		var b = DoubleMemory.ofArray(v);
		
		checkData(b);
		b.free();
		#if alchemy MemoryManager.free(); #end
		
		var b = new DoubleMemory(256);
		var b = DoubleMemory.ofArray(v, 64, 128);
		checkData(b, 64, 128);
		b.free();
		#if alchemy MemoryManager.free(); #end
	}
	
	#if flash
	function testToVector()
	{
		var b = new DoubleMemory(256);
		fillData(b);
		
		var v = DoubleMemory.toVector(b);
		checkVector(v, 0, 256);
		assertEquals(256, v.length);
		
		var v = DoubleMemory.toVector(b, 64, 128);
		checkVector(v, 64, 128);
		assertEquals(64, v.length);
		
		b.free();
		#if alchemy MemoryManager.free(); #end
	}
	
	function testOfVector()
	{
		var v = new Vector<Float>(256);
		for (i in 0...256) v[i] = i % 10;
		
		var b = DoubleMemory.ofVector(v);
		checkData(b);
		b.free();
		#if alchemy MemoryManager.free(); #end
		
		var b = new DoubleMemory(256);
		var b = DoubleMemory.ofVector(v, 64, 128);
		checkData(b, 64, 128);
		b.free();
		#if alchemy MemoryManager.free(); #end
	}
	#end
	
	#if flash
	function testToByteArray()
	{
		var b = new DoubleMemory(256);
		fillData(b);
		var v = DoubleMemory.toByteArray(b);
		assertEquals(256 << 3, v.length);
		checkByteArray(v);
		var v = DoubleMemory.toByteArray(b, 64, 128);
		checkByteArray(v, 64, 128);
		assertEquals(64 << 3, v.length);
		b.free();
		#if alchemy MemoryManager.free(); #end
	}
	
	function testOfByteArray()
	{
		var bytes = new flash.utils.ByteArray();
		for (i in 0...256) bytes.writeDouble(i % 10);
		var m = DoubleMemory.ofByteArray(bytes);
		assertEquals(m.size, 256);
		checkData(m);
		m.free();
		#if alchemy MemoryManager.free(); #end
		
		var bytes = new flash.utils.ByteArray();
		bytes.endian = flash.utils.Endian.BIG_ENDIAN;
		for (i in 0...256) bytes.writeDouble(i % 10);
		
		var m = DoubleMemory.ofByteArray(bytes);
		assertEquals(m.size, 256);
		
		checkData(m);
		m.free();
		#if alchemy MemoryManager.free(); #end
		
		var bytes = new flash.utils.ByteArray();
		bytes.endian = flash.utils.Endian.BIG_ENDIAN;
		for (i in 0...256) bytes.writeDouble(i % 10);
		
		var m = DoubleMemory.ofByteArray(bytes, 64 << 3, 128 << 3);
		assertEquals(m.size, 64);
		
		checkData(m, 64, 128);
		m.free();
		#if alchemy MemoryManager.free(); #end
	}
	#end
	
	#if flash
	function testToBytesData()
	{
		var b = new DoubleMemory(256);
		fillData(b);
		var v = DoubleMemory.toBytesData(b);
		
		#if neko
		assertEquals(256 << 3, neko.NativeString.length(v));
		#else
		assertEquals(256 << 3, v.length);
		#end
		
		checkBytesData(v);
		
		var v = DoubleMemory.toBytesData(b, 64, 128);
		checkBytesData(v, 64, 128);
		#if neko
		assertEquals(64 << 3, neko.NativeString.length(v));
		#else
		assertEquals(64 << 3, v.length);
		#end
		
		b.free();
		#if alchemy MemoryManager.free(); #end
	}
	
	function testOfBytesData()
	{
		var output = new BytesOutput();
		for (i in 0...256) output.writeDouble(i % 10);
		var m = DoubleMemory.ofBytesData(output.getBytes().getData());
		assertEquals(m.size, 256);
		checkData(m);
		m.free();
		#if alchemy MemoryManager.free(); #end
	}
	#end
	
	function fillData(data:DoubleMemory)
	{
		for (i in 0...data.size) data.set(i, i % 10);
	}
	
	function checkData(data:DoubleMemory, min = -1, max = -1)
	{
		if (min == -1) min = 0;
		if (max == -1) max = data.size;
		for (i in 0...max - min) assertEquals((i + min) % 10, Std.int(data.get(i)));
	}
	
	function checkArray(data:Array<Float>, min = -1, max = -1)
	{
		if (min == -1) min = 0;
		if (max == -1) max = data.length;
		for (i in 0...max - min) assertEquals((i + min) % 10, Std.int(data[i]));
	}
	
	inline function checkVector(data:Vector<Float>, min = -1, max = -1)
	{
		if (min == -1) min = 0;
		if (max == -1) max = data.length;
		for (i in 0...max - min) assertEquals((i + min) % 10, Std.int(data[i]));
	}
	
	#if flash
	function checkByteArray(data:flash.utils.ByteArray, min = -1, max = -1)
	{
		data.position = 0;
		if (min == -1) min = 0;
		if (max == -1) max = data.length >> 3;
		for (i in 0...max - min) assertEquals((i + min) % 10, Std.int(data.readDouble()));
	}
	#end
	
	function checkBytesData(data:BytesData, min = -1, max = -1)
	{
		#if flash
		data.position = 0;
		
		if (min == -1) min = 0;
		if (max == -1) max = data.length >> 3;
		
		for (i in 0...max - min) assertEquals((i + min) % 10, Std.int(data.readDouble()));
		#else
		var bytes = Bytes.ofData(data);
		var input:BytesInput = new BytesInput(bytes);
		
		if (min == -1) min = 0;
		if (max == -1) max = bytes.length >> 3;
		for (i in 0...max - min) assertEquals((i + min) % 10, Std.int(input.readDouble()));
		#end
	}
}