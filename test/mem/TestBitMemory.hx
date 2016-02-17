package mem;

import de.polygonal.ds.Bits;
import de.polygonal.ds.BitVector;
import de.polygonal.ds.mem.BitMemory;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;

#if alchemy
import de.polygonal.ds.mem.MemoryManager;
#end

using de.polygonal.ds.Bits;

class TestBitMemory extends AbstractTest
{
	function new()
	{
		super();
		
		#if (flash && alchemy)
		MemoryManager.free();
		#end
	}
	
	#if flash
	function testOfByteArray()
	{
		var b = new flash.utils.ByteArray();
		#if flash
		b.endian = flash.utils.Endian.LITTLE_ENDIAN;
		#else
		b.bigEndian = false;
		#end
		var i = Bits.BIT_01 | Bits.BIT_02 | Bits.BIT_03 | Bits.BIT_08 | Bits.BIT_09 | Bits.BIT_16 | Bits.BIT_17 | Bits.BIT_24 | Bits.BIT_25 | Bits.BIT_31;
		b.writeInt(i);
		var m:BitMemory = BitMemory.ofByteArray(b);
		
		assertEquals(m.size, 32);
		assertEquals(m.bytes, 4);
		assertTrue(m.has(0));
		assertTrue(m.has(1));
		assertTrue(m.has(2));
		assertTrue(m.has(7));
		assertTrue(m.has(8));
		assertTrue(m.has(15));
		assertTrue(m.has(16));
		assertTrue(m.has(23));
		assertTrue(m.has(24));
		assertTrue(m.has(30));
		
		m.free();
		#if alchemy MemoryManager.free(); #end
		
		#if flash
		var b = new flash.utils.ByteArray();
		b.endian = flash.utils.Endian.LITTLE_ENDIAN;
		
		b.writeInt(i);
		b.position = 0;
		
		var m = BitMemory.ofByteArray(b);
		assertEquals(m.size, 32);
		assertEquals(m.bytes, 4);
		assertTrue(m.has(0));
		assertTrue(m.has(1));
		assertTrue(m.has(2));
		assertTrue(m.has(7));
		assertTrue(m.has(8));
		assertTrue(m.has(15));
		assertTrue(m.has(16));
		assertTrue(m.has(23));
		assertTrue(m.has(24));
		assertTrue(m.has(30));
		
		m.free();
		#if alchemy MemoryManager.free(); #end
		#end
	}
	function testToByteArray()
	{
		var capacity = 64;
		
		var mem = new BitMemory(capacity);
		for (i in 0...capacity)
		{
			if (isEven(i))
				mem.set(i);
		}
		for (i in 0...capacity)
		{
			if (isEven(i))
				assertTrue(mem.has(i));
			else
				assertFalse(mem.has(i));
		}
		
		var c = Math.ceil(mem.size / 8);
		var input = BitMemory.toByteArray(mem);
		assertEquals(c, input.length);
		c = 0;
		var i = 0;
		var byteCount = 0;
		
		var k = input.length;
		
		for (b in 0...k)
		{
			var byte = input.readByte();
			for (j in 0...8)
			{
				if (c == capacity) return;
				var x = byte & 1;
				byte >>= 1;
				if (isEven(i))
					assertEquals(1, x);
				else
					assertEquals(0, x);
				i++;
				c++;
			}
		}
		
		mem.free();
		#if alchemy MemoryManager.free(); #end
	}
	#end
	
	function testToBytesData()
	{
		var capacity = 64;
		
		var mem = new BitMemory(capacity);
		for (i in 0...capacity)
		{
			if (isEven(i))
				mem.set(i);
		}
		for (i in 0...capacity)
		{
			if (isEven(i))
				assertTrue(mem.has(i));
			else
				assertFalse(mem.has(i));
		}
		
		var c = Math.ceil(mem.size / 8);
		var v = BitMemory.toBytesData(mem);
		var input = new BytesInput(Bytes.ofData(v));
		
		#if neko
		assertEquals(c, neko.NativeString.length(v));
		#else
		assertEquals(c, v.length);
		#end
		c = 0;
		var i = 0;
		var byteCount = 0;
		
		var k = 
		#if neko
		neko.NativeString.length(v);
		#else
		v.length;
		#end
		
		for (b in 0...k)
		{
			var byte = input.readByte();
			for (j in 0...8)
			{
				if (c == capacity) return;
				var x = byte & 1;
				byte >>= 1;
				if (isEven(i))
					assertEquals(1, x);
				else
					assertEquals(0, x);
				i++;
				c++;
			}
		}
		
		mem.free();
		#if alchemy MemoryManager.free(); #end
	}
	
	function testOfBytesData()
	{
		var b = new BytesOutput();
		
		var i = 
		#if neko
		Bits.BIT_01 | Bits.BIT_02 | Bits.BIT_03 | Bits.BIT_08 | Bits.BIT_09 | Bits.BIT_16 | Bits.BIT_17 | Bits.BIT_24 | Bits.BIT_25;
		#else
		Bits.BIT_01 | Bits.BIT_02 | Bits.BIT_03 | Bits.BIT_08 | Bits.BIT_09 | Bits.BIT_16 | Bits.BIT_17 | Bits.BIT_24 | Bits.BIT_25 | Bits.BIT_31;
		#end
		
		b.writeInt32(i);
		
		var bytesData = b.getBytes().getData();
		
		var m:BitMemory = BitMemory.ofBytesData(bytesData);
		assertEquals(m.size, 32);
		assertEquals(m.bytes, #if (neko && !neko_v2) 8 #else 4 #end);
		
		assertTrue(m.has(0));
		assertTrue(m.has(1));
		assertTrue(m.has(2));
		assertTrue(m.has(7));
		assertTrue(m.has(8));
		assertTrue(m.has(15));
		assertTrue(m.has(16));
		assertTrue(m.has(23));
		assertTrue(m.has(24));
		
		#if !neko
		assertTrue(m.has(30));
		#end
		
		m.free();
		#if alchemy MemoryManager.free(); #end
		
		#if flash
		var b = new flash.utils.ByteArray();
		b.endian = flash.utils.Endian.LITTLE_ENDIAN;
		
		b.writeInt(i);
		b.position = 0;
		
		var m:BitMemory = BitMemory.ofByteArray(b);
		assertEquals(m.size, 32);
		assertEquals(m.bytes, 4);
		assertTrue(m.has(0));
		assertTrue(m.has(1));
		assertTrue(m.has(2));
		assertTrue(m.has(7));
		assertTrue(m.has(8));
		assertTrue(m.has(15));
		assertTrue(m.has(16));
		assertTrue(m.has(23));
		assertTrue(m.has(24));
		assertTrue(m.has(30));
		
		m.free();
		#if alchemy MemoryManager.free(); #end
		#end
	}
	
	function testToBitVector()
	{
		var capacity = 100;
		
		var mem = new BitMemory(capacity);
		for (i in 0...capacity)
		{
			if (isEven(i))
				mem.set(i);
		}
		for (i in 0...capacity)
		{
			if (isEven(i))
				assertTrue(mem.has(i));
			else
				assertFalse(mem.has(i));
		}
		
		var v:BitVector = BitMemory.toBitVector(mem);
		
		assertEquals(#if (neko && !neko_v2) 5 #else 4 #end, v.bucketSize());
		assertEquals(#if (neko && !neko_v2) (5*31) #else (4*32) #end, v.capacity);
		
		for (i in 0...100)
		{
			if (isEven(i))
				assertTrue(v.has(i));
			else
				assertFalse(v.has(i));
		}
		
		#if alchemy MemoryManager.free(); #end
	}
	
	function testSetBit()
	{
		var b:BitMemory = new BitMemory(32);
		
		for (i in 0...32) b.set(i);
		for (i in 0...32) assertTrue(b.has(i));
		for (i in 0...32)
		{
			if ((i & 1) == 0)
				b.clr(i);
		}
		
		for (i in 0...32)
		{
			if ((i & 1) == 0)
				assertFalse(b.has(i));
		}
		
		for (i in 0...32)
		{
			if ((i & 1) == 1)
				assertTrue(b.has(i));
		}
		for (i in 0...32)
		{
			if ((i & 1) == 1)
				b.clr(i);
		}
		for (i in 0...32)
		{
			if ((i & 1) == 1)
				assertFalse(b.has(i));
		}
		
		b.free();
		#if alchemy MemoryManager.free(); #end
	}
	
	function testSize()
	{
		var b:BitMemory = new BitMemory(32);
		assertEquals(32, b.size);
		b.free();
		#if alchemy MemoryManager.free(); #end
    }
	
	function testHasBit()
	{
		var b = new BitMemory(100);
		for (i in 0...100)
		{
			b.set(i);
			assertTrue(b.has(i));
		}
		
		b.free();
		#if alchemy MemoryManager.free(); #end
    }
	
	function testGetBit()
	{
		var b = new BitMemory(100);
		for (i in 0...100)
		{
			if (isEven(i))
				b.set(i);
		}
		for (i in 0...100)
		{
			if (isEven(i))
				assertTrue(b.get(i) != 0)
			else
				assertEquals(0, b.get(i));
		}
		b.free();
		#if alchemy MemoryManager.free(); #end
    }
	
	function testClrBit()
	{
		var b:BitMemory = new BitMemory(100);
		for (i in 0...100)
		{
			b.set(i);
			b.clr(i);
		}
		for (i in 0...100)
			assertFalse(b.has(i));
		b.free();
		#if alchemy MemoryManager.free(); #end
    }
	
	function testClear()
	{
		var b:BitMemory = new BitMemory(64);
		for (i in 0...64) b.set(i);
		b.clrAll();
		
		for (i in 0...64) assertFalse(b.has(i));
		for (i in 0...64) b.set(i);
		b.clear();
		for (i in 0...64) assertFalse(b.has(i));
		
		b.free();
		#if alchemy MemoryManager.free(); #end
	}
	
	function testSetAll()
	{
		var b:BitMemory = new BitMemory(64);
		b.setAll();
		for (i in 0...64) assertTrue(b.has(i));
		
		b.free();
		#if alchemy MemoryManager.free(); #end
	}
	
	function testFill()
	{
		var s = 1;
		for (s in 1...40 + 1)
		{
			var m = new BitMemory(s);
			m.fill(1);
			for (i in 0...s) assertEquals(true, m.has(i));
			
			#if (flash && alchemy)
			var addr = m.getAddr(0);
			for (i in 0...s) assertEquals(-1, flash.Memory.getI32(addr + i));
			#end
		}
		
		#if alchemy MemoryManager.free(); #end
	}
	
	function testClone()
	{
		for (i in 1...100)
		{
			var m = new BitMemory(i);
			for (j in 0...i) m.set(j);
			
			var c = m.clone();
			for (j in 0...i) assertTrue(m.has(j));
			assertEquals(m.size, c.size);
			
			m.free();
			c.free();
		}
	}
}