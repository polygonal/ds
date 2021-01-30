import ds.tools.Bitfield;

class TestBitfield extends AbstractTest
{
	function test1()
	{
		var b = new Bitfield();
		
		b[0] = true;
		assertTrue(b[0]);
		
		b[31] = 1;
		assertTrue(b[31]);
		
		b[0] = 0;
		assertFalse(b[0]);
		
		b[31] = false;
		assertFalse(b[31]);
	}
	
	function test2()
	{
		var b = new Bitfield();
		var values = [];
		for (i in 0...32) b[i] = values[i] = i & 1 == 1 ? true : false;
		for (i in 0...values.length) assertEquals(values[i], b[i]);
	}
	
	function test3()
	{
		var a = new Bitfield();
		a.set(1, 3);
		var b = new Bitfield();
		b.set(0, 2);
		
		a += b;
		
		assertTrue(a[0]);
		assertTrue(a[1]);
		assertTrue(a[2]);
		assertTrue(a[3]);
		
		a -= b;
		assertFalse(a[0]);
		assertTrue(a[1]);
		assertFalse(a[2]);
		assertTrue(a[3]);
	}
	
	function test4()
	{
		var b = new Bitfield();
		b.set(0, 1, 2, 3, 4);
		b.inv(1, 2);
		assertTrue(b[0]);
		assertFalse(b[1]);
		assertFalse(b[2]);
		assertTrue(b[3]);
		assertTrue(b[4]);
	}
	
	function test5()
	{
		var b = new Bitfield();
		b.set(2, 4, 8);
		
		assertTrue(b.any(1, 2, 3));
		assertFalse(b.any(3));
		assertTrue(b.all(2, 4, 8));
		
		assertFalse(b.all(4, 8, 3));
	}
	
	function test6()
	{
		var b = new Bitfield();
		b.set(2, 4, 8);
		b.unset(2);
		assertFalse(b[2]);
		assertTrue(b[4]);
		assertTrue(b[8]);
		b.unset(4, 8);
		assertEquals(0, b);
	}
	
	function test7()
	{
		var b:Bitfield = 1 | 2 | 4;
		trace(b);
		assertTrue(b[1]);
		assertTrue(b[1]);
		assertTrue(b[2]);
	}
	
	function test8()
	{
		var b:Bitfield = 1 | 2;
		assertTrue(b.any(0, 3, 4));
		
		var b:Bitfield = 1 | 2;
		assertFalse(b.all(0, 2));
		assertTrue(b.all(0, 1));
		
		var b:Bitfield = 1 | 4;
		b.inv(1);
		b.inv(0, 2);
		assertTrue(b[1]);
		assertFalse(b[0]);
		assertFalse(b[2]);
	}
}