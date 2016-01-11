import haxe.unit.TestCase;

class AbstractTest extends TestCase
{
	var mSeed:Float;
	
	public function new() 
	{
		super();
	}
	
	function isEven(x:Int) return (x & 1) == 0;
	
	function rand():Int return cast (Math.random() * 0x7FFFFFFF);
	
	function initPrng(seed:Int = 1)
	{
		mSeed = seed;
	}
	
	function prand()
	{
		return mSeed = (mSeed * 16807.) % 2147483647.;
	}
}