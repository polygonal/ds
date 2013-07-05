package;

import de.polygonal.ds.BitVector;
import haxe.io.Bytes;
import haxe.io.BytesInput;

class TestBitVector extends haxe.unit.TestCase
{
	function test()
	{
		var bv = new BitVector(100);
		for (i in 0...100)
		{
			if ((i & 1) == 1)
				bv.set(i);
		}
		
		for (i in 0...100)
		{
			if ((i & 1) == 1)
				assertTrue(bv.has(i));
			else
				assertFalse(bv.has(i));
		}
	}
	
	function testBytes()
	{
		var capacity = 32 * 2 + 15;
		var bv = new BitVector(capacity);
		
		for (i in 0...capacity)
		{
			if (i & 1 == 0)
				bv.set(i);
			else
				bv.clr(i);
		}
		
		var ba = bv.toBytes();
		var bytes = Bytes.ofData(ba);
		var input = new haxe.io.BytesInput(bytes);
		input.bigEndian = false;
		
		var i = 0;
		var c = 0;
		var mod = 0;
		
		var byteCount = 0;
		
		for (b in 0...bytes.length)
		{
			var byte = input.readByte();
			
			var byteIntCount = 8;
			byteCount++;
			if (byteCount == 4)
			{
				#if (neko && !neko_v2)
				byteIntCount = 7;
				#end
				byteCount = 0;
			}
			
			for (j in 0...byteIntCount)
			{
				if (c == capacity)
					return;
					
				var x = byte & 1;
				
				byte >>= 1;
				
				if (i & 1 == 0)
					assertEquals(1, x);
				else
					assertEquals(0, x);
				i++;
				c++;
			}
		}
		
		var bv = new BitVector(capacity);
		bv.ofBytes(ba);
		for (i in 0...capacity)
		{
			if (i & 1 == 0)
				assertTrue(bv.has(i));
			else
				assertFalse(bv.has(i));
		}
	}
	
	function testClone()
	{
		var b = new BitVector(70);
		for (i in 0...70)
		{
			if ((i & 1) == 0)
				b.set(i);
		}
		
		var clone:BitVector = b.clone();
		for (i in 0...70)
		{
			if ((i & 1) == 0)
				assertTrue(clone.has(i));
		}
	}
	
	function testSetBit()
	{
		var b = new BitVector(32);
		for (i in 0...32)
			b.set(i);
		
		for (i in 0...32)
			assertTrue(b.has(i));
			
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
	}
	
	function testSize()
	{
		var b = new BitVector(16);
		assertEquals(b.capacity(), 16);
		assertEquals(b.size(), 0);
    }
	
	function testHasBit()
	{
		var b = new BitVector(100);
		for (i in 0...100)
		{
			b.set(i);
			assertTrue(b.has(i));
		}
    }
	
	function testClrBit()
	{
		var b = new BitVector(100);
		for (i in 0...100)
		{
			b.set(i);
			b.clr(i);
		}
		for (i in 0...100)
			assertFalse(b.has(i));
    }
	
	function testBucketSize()
	{
		var b = new BitVector(64);
		assertEquals(b.bucketSize(), #if (neko && !neko_v2) 3 #else 2 #end);
		
		var b = new BitVector(65);
		assertEquals(b.bucketSize(), 3);
		
		b.resize(64);
		assertEquals(b.bucketSize(), #if (neko && !neko_v2) 3 #else 2 #end);
		
		b.resize(16);
		assertEquals(b.bucketSize(), 1);
	}
	
	function testClear()
	{
		var b = new BitVector(64);
		for (i in 0...64)
			b.set(i);
		
		b.clrAll();
		
		for (i in 0...64)
			assertFalse(b.has(i));
	}
	
	function testClearRange()
	{
		// base case clear nothing
		var b = new BitVector(2);
		for (i in 0...2) b.set(i);
		b.clrRange(0, 0);
		for (i in 0...2) assertTrue(b.has(i));
		
		var b = new BitVector(32);
		for (i in 0...32) b.set(i);
		b.clrRange(0, 16);
		for (i in 0...16) assertFalse(b.has(i));
		for (i in 16...32) assertTrue(b.has(i));
		
		var b = new BitVector(64);
		for (i in 0...64) b.set(i);
		b.clrRange(0, 25);
		for (i in 0...25) assertFalse(b.has(i));
		for (i in 25...64) assertTrue(b.has(i));
		
		var b = new BitVector(64);
		for (i in 0...64) b.set(i);
		b.clrRange(0, 35);
		for (i in 0...35) assertFalse(b.has(i));
		for (i in 35...64) assertTrue(b.has(i));
		
		//min > 0
		var b = new BitVector(32);
		for (i in 0...32) b.set(i);
		b.clrRange(5, 16);
		
		for (i in 0...5) assertTrue(b.has(i));
		for (i in 5...16) assertFalse(b.has(i));
		for (i in 16...32) assertTrue(b.has(i));
		
		var b = new BitVector(64);
		for (i in 0...64) b.set(i);
		b.clrRange(5, 25);
		for (i in 0...5) assertTrue(b.has(i));
		for (i in 5...25) assertFalse(b.has(i));
		for (i in 25...64) assertTrue(b.has(i));
		
		var b = new BitVector(64);
		for (i in 0...64) b.set(i);
		b.clrRange(5, 35);
		for (i in 0...5) assertTrue(b.has(i));
		for (i in 5...35) assertFalse(b.has(i));
		for (i in 35...64) assertTrue(b.has(i));
	}
	
	function testSetRange()
	{
		// base case clear nothing
		var b = new BitVector(2);
		b.setRange(0, 0);
		for (i in 0...2) assertFalse(b.has(i));
		
		var b = new BitVector(32);
		b.setRange(0, 16);
		for (i in 0...16) assertTrue(b.has(i));
		for (i in 16...32) assertFalse(b.has(i));
		
		var b = new BitVector(64);
		b.setRange(0, 25);
		for (i in 0...25) assertTrue(b.has(i));
		for (i in 25...64) assertFalse(b.has(i));
		
		var b = new BitVector(64);
		b.setRange(0, 35);
		for (i in 0...35) assertTrue(b.has(i));
		for (i in 35...64) assertFalse(b.has(i));
		
		//min > 0
		var b = new BitVector(32);
		b.setRange(5, 16);
		for (i in 0...5) assertFalse(b.has(i));
		for (i in 5...16) assertTrue(b.has(i));
		for (i in 16...32) assertFalse(b.has(i));
		
		var b = new BitVector(64);
		b.setRange(5, 25);
		for (i in 0...5) assertFalse(b.has(i));
		for (i in 5...25) assertTrue(b.has(i));
		for (i in 25...64) assertFalse(b.has(i));
		
		var b = new BitVector(64);
		b.setRange(5, 35);
		for (i in 0...5) assertFalse(b.has(i));
		for (i in 5...35) assertTrue(b.has(i));
		for (i in 35...64) assertFalse(b.has(i));
	}
	
	function testSetAll()
	{
		var b = new BitVector(64);
		b.setAll();
		for (i in 0...64)
			assertTrue(b.has(i));
	}
	
	function testResize()
	{
		var b = new BitVector(32);
		for (i in 0...10)
			b.set(i);
		
		b.resize(16);
		for (i in 0...16) assertFalse(b.has(i));
		
		for (i in 0...10) b.set(i);
		
		b.resize(64);
		for (i in 0...10)
			assertTrue(b.has(i));
		
		for (i in 11...64)
			assertFalse(b.has(i));
		
		b.resize(10);
		
		for (i in 0...10)
			assertFalse(b.has(i));
    }
	
	function testGetBuckets()
	{
		var b = new BitVector(64);
		b.setAll();
		
		var buckets = [];
		var c = b.getBuckets(buckets);
		
		#if (neko && !neko_v2)
		assertEquals(3, c); //31bit
		#else
		assertEquals(2, c);
		#end
		
		assertEquals(-1, buckets[0]);
		assertEquals(-1, buckets[1]);
	}
	
	function testGetBucketAt()
	{
		var b = new BitVector(64);
		b.setAll();
		
		var buckets = [];
		assertEquals(-1, b.getBucketAt(0));
	}
}