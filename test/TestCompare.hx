package;

import de.polygonal.ds.tools.Compare;

class TestCompare extends AbstractTest
{
	function testCmpNumber()
	{
		var a = [1., 3., 2.];
		a.sort(Compare.cmpFloatFall);
		assertEquals(3., a[0]);
		assertEquals(2., a[1]);
		assertEquals(1., a[2]);
		
		var a = [1., 3., 2.];
		a.sort(Compare.cmpFloatRise);
		assertEquals(1., a[0]);
		assertEquals(2., a[1]);
		assertEquals(3., a[2]);
		
		var a = [1, 3, 2];
		a.sort(Compare.cmpIntFall);
		assertEquals(3, a[0]);
		assertEquals(2, a[1]);
		assertEquals(1, a[2]);
		
		var a = [1, 3, 2];
		a.sort(Compare.cmpIntRise);
		assertEquals(1, a[0]);
		assertEquals(2, a[1]);
		assertEquals(3, a[2]);
	}
	
	function testCmpString()
	{
		var a =
		[
			"At",
			"As",
			"Aster",
			"Astrolabe",
			"Baa",
			"Astrophysics",
			"Astronomy",
			"Ataman",
			"Attack"
		];
		a.sort(Compare.cmpAlphabeticalRise);
		assertEquals("As", a[0]);
		assertEquals("Aster", a[1]);
		assertEquals("Astrolabe", a[2]);
		assertEquals("Astronomy", a[3]);
		assertEquals("Astrophysics", a[4]);
		assertEquals("At", a[5]);
		assertEquals("Ataman", a[6]);
		assertEquals("Attack", a[7]);
		assertEquals("Baa", a[8]);
		
		a.sort(Compare.cmpAlphabeticalFall);
		assertEquals("Baa", a[0]);
		assertEquals("Attack", a[1]);
		assertEquals("Ataman", a[2]);
		assertEquals("At", a[3]);
		assertEquals("Astrophysics", a[4]);
		assertEquals("Astronomy", a[5]);
		assertEquals("Astrolabe", a[6]);
		assertEquals("Aster", a[7]);
		assertEquals("As", a[8]);
	}
}