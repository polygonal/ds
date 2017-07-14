using de.polygonal.ds.tools.Bits;

class TestBits extends AbstractTest
{
	function testReverse()
	{
		var x = (1 << 0 | 1 << 1 | 1 << 2);
		
		x = x.reverse();
		
		assertEquals(0, x & (1 << 0));
		assertEquals(0, x & (1 << 1));
		assertEquals(0, x & (1 << 2));
		assertEquals(1 << 29, x & (1 << 29));
		assertEquals(1 << 30, x & (1 << 30));
		
		#if (!python && !php)
		assertEquals(1 << 31, x & (1 << 31));
		#end
	}
	
	function testMsb()
	{
		var k = 32;
		var x = 0;
		for (i in 0...k)
		{
			x |= 1 << i;
			assertEquals(1 << i, x.msb());
		}
	}
	
	function testNtz()
	{
		var k = 32;
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
	
	function testNlz()
	{
		var k = 32;
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
		var k = 32;
		var x = 0;
		for (i in 0...k)
		{
			x |= 1 << i;
			assertEquals(i + 1, x.ones());
		}
	}
	
	function testBitMask()
	{
		var k = 32 - 1;
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
}