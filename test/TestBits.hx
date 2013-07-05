package;

import de.polygonal.core.fmt.NumberFormat;
import de.polygonal.core.math.Limits;
import de.polygonal.ds.Bits;

using de.polygonal.ds.Bits;

class TestBits extends haxe.unit.TestCase
{
	function testReverse()
	{
		#if neko
		var x = 0;
		x = x.setBitAt(0);
		x = x.setBitAt(1);
		x = x.setBitAt(2);
		x = x.reverse();
		assertTrue(!x.hasBitAt(0));
		assertTrue(!x.hasBitAt(1));
		assertTrue(!x.hasBitAt(2));
		
		assertTrue(x.hasBitAt(27));
		assertTrue(x.hasBitAt(28));
		assertTrue(x.hasBitAt(29));
		#else
		var x = 0;
		x = x.setBitAt(0);
		x = x.setBitAt(1);
		x = x.setBitAt(2);
		
		x = x.reverse();
		
		assertTrue(!x.hasBitAt(0));
		assertTrue(!x.hasBitAt(1));
		assertTrue(!x.hasBitAt(2));
		
		assertTrue(x.hasBitAt(29));
		assertTrue(x.hasBitAt(30));
		assertTrue(x.hasBitAt(31));
		#end
	}
	
	function testMsb()
	{
		var k = Limits.INT_BITS;
		var x = 0;
		for (i in 0...k)
		{
			x |= 1 << i;
			assertEquals(1 << i, x.msb());
		}
		
		for (i in 0...k-1)
		{
			x = x.clrBits(1 << i);
			assertEquals(1 << k-1, x.msb());
		}
	}
	
	function testNTZ()
	{
		var k = Limits.INT_BITS;
		for (i in 0...k)
		{
			var x = 1 << i;
			assertEquals(i, x.ntz());
		}
		for (i in 0...k - 1)
		{
			var x = 1 << i | 1 << (i + 1);
			assertEquals(i, x.ntz());
		}
	}
	
	function testNLZ()
	{
		var k = Limits.INT_BITS;
		var n = k - 1;
		for (i in 0...k)
		{
			var x = 1 << i;
			assertEquals(n, x.nlz());
			n--;
		}
	}
	
	function testOnes()
	{
		var k = Limits.INT_BITS;
		var x = 0;
		for (i in 0...k)
		{
			x |= 1 << i;
			assertEquals(i + 1, x.ones());
		}
	}
	
	function testBitMask()
	{
		var k = Limits.INT_BITS - 1;
		for (i in 0...k)
		{
			var x = (i + 1).mask();
			for (j in 0...i + 1)
			{
				var b = (x & (1 << j)) != 0;
				assertTrue(b);
			}
		}
	}

	function testSetIf()
	{
		var x = 0;
		x = x.setBitsIf(0x02, true);
		assertTrue(x.hasBits(0x02));
		x = x.setBitsIf(0x04, false);
		assertTrue(!x.hasBits(0x04));
	}
	
	function testSetAll()
	{
		var x = 0;
		var k = Limits.INT_BITS;
		for (i in 0...k)
		{
			x = x.setBits(1 << i);
			assertEquals(i + 1, x.ones());
		}
	}
	
	function testGet()
	{
		var b = Bits.BIT_01 | Bits.BIT_03;
		assertTrue(b.incBits(Bits.BIT_01 | Bits.BIT_03));
		assertTrue(b.hasBits(Bits.BIT_01));
		assertTrue(b.hasBits(Bits.BIT_03));
		assertFalse(b.incBits(Bits.BIT_01 | Bits.BIT_05));
	}
	
	function testRange()
	{
		var b = 0;
		assertEquals(0, b.ones());
		var k = Limits.INT_BITS;
		for (i in 0...k)
		{
			b = b.setBits(1 << i);
			assertEquals(i + 1, b.ones());
		}
	}
	
	function testGetBitAt()
	{
		var b = Bits.BIT_01 | Bits.BIT_03;
		assertTrue(b.hasBitAt(0));
		assertTrue(b.hasBitAt(2));
	}
	
	function testSet()
	{
		var b = Bits.BIT_01 | Bits.BIT_03;
		b = b.setBits(Bits.BIT_04);
		assertTrue(b.hasBits(Bits.BIT_04));
	}
	
	function testSetAt()
	{
		var b = 0;
		b = b.setBitAt(0);
		b = b.setBitAt(3);
		assertTrue(b.hasBits(Bits.BIT_01 | Bits.BIT_04));
	}
	
	function testClrBitAt()
	{
		var b = 0;
		b = b.setBitAt(1);
		b = b.setBitAt(4);
		b = b.clrBitAt(1);
		assertTrue(!b.hasBits(Bits.BIT_01));
		b = b.clrBitAt(4);
		assertTrue(!b.hasBits(Bits.BIT_04));
	}
	
	function testIf()
	{
		var b = Bits.BIT_01 | Bits.BIT_03;
		b = b.setBitsIf(Bits.BIT_04, true);
		assertTrue(b.hasBits(Bits.BIT_04));
		b = b.setBitsIf(Bits.BIT_04, false);
		assertFalse(b.hasBits(Bits.BIT_04));
	}
	
	function testClr()
	{
		var b = Bits.BIT_01 | Bits.BIT_03;
		b = b.setBits(Bits.BIT_04);
		b = b.clrBits(Bits.BIT_04);
		assertFalse(b.hasBits(Bits.BIT_04));
		var b = Bits.ALL;
		var k = Limits.INT_BITS;
		for (i in 0...k)
		{
			b = b.clrBits(1 << i);
			assertFalse(b.hasBits(1 << i));
		}
	}
	
	function testFlip()
	{
		var b = Bits.BIT_01 | Bits.BIT_03;
		b = b.invBits(Bits.BIT_04);
		assertTrue(b.hasBits(Bits.BIT_04));
		b = b.invBits(Bits.BIT_04);
		assertFalse(b.hasBits(Bits.BIT_04));
	}
	
	function testFlipAt()
	{
		var b = Bits.BIT_01 | Bits.BIT_03;
		b = b.invBitAt(3);
		assertTrue(b.hasBitAt(3));
		b = b.invBitAt(0);
		assertTrue(!b.hasBitAt(0));
		b = b.invBitAt(2);
		assertTrue(!b.hasBitAt(2));
	}
	
	function testHas()
	{
		var b = Bits.BIT_01 | Bits.BIT_03;
		assertTrue(b.hasBits(Bits.BIT_01));
		assertTrue(b.hasBits(Bits.BIT_01 | Bits.BIT_03));
		assertTrue(b.hasBits(Bits.BIT_01 | Bits.BIT_05));
	}
	
	function testSetRange()
	{
		var b = 0;
		b = b.setBitsRange(0, 3);
		b = b.setBitsRange(7, 15);
		
		assertTrue(b.hasBits(Bits.BIT_01));
		assertTrue(b.hasBits(Bits.BIT_02));
		assertTrue(b.hasBits(Bits.BIT_03));
		
		assertTrue(b.hasBits(Bits.BIT_08));
		assertTrue(b.hasBits(Bits.BIT_09));
		assertTrue(b.hasBits(Bits.BIT_10));
		assertTrue(b.hasBits(Bits.BIT_11));
		assertTrue(b.hasBits(Bits.BIT_12));
		assertTrue(b.hasBits(Bits.BIT_13));
		assertTrue(b.hasBits(Bits.BIT_14));
		assertTrue(b.hasBits(Bits.BIT_15));
	}
}