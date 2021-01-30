import ds.tools.RadixSort;

class TestRadixSort extends AbstractTest
{
	function test()
	{
		var inp = [ 43, 4500, 98, 1, 1, 0x7FFFFFFF, 0, 6, 756];
		
		var indices = [for (i in 0...8) i];
		
		var len = 2;
		while (len < 8)
		{
			for (i in 0...10)
				indices.unshift(indices.pop());
			
			var src = [];
			for (i in 0...len) src.push(inp[indices[i]]);
			
			var a = src.copy();
			a.sort(
				function(a, b)
				{
					return
						if (a < b) -1;
						else if (a > b) 1;
						else 0;
				});
			
			var b = RadixSort.sort(src);
			cmp(a, b);
			len++;
		}
	}
	
	function cmp(expected:Array<Int>, actual:Array<Int>)
	{
		assertEquals(expected.length, actual.length);
		for (i in 0...expected.length)
			assertEquals(expected[i], actual[i]);
	}
}