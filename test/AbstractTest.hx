import haxe.unit.TestCase;

class AbstractTest extends TestCase
{
	var mSeed:Float;
	
	public function new() 
	{
		super();
	}
	
	function isEven(x:Int):Bool return (x & 1) == 0;
	
	function rand():Int return cast (Math.random() * 0x7FFFFFFF);
	
	function randRange(min:Int, max:Int):Int
	{
		var l = min - .4999;
		var h = max + .4999;
		return Math.round(l + (h - l) * Math.random());
	}
	
	function initPrng(seed:Int = 1) mSeed = seed;
	
	function prand():Float return mSeed = (mSeed * 16807.) % 2147483647.;
	
	function isDynamic():Bool return #if (js || neko || python) true; #else false; #end
}