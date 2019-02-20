import haxe.unit.TestCase;

class AbstractTest extends TestCase
{
	var mSeed:Float;
	
	public function new() 
	{
		super();
	}
	
	function isEven(x:Int):Bool return (x & 1) == 0;
	
	function rand():Int return Std.int(Math.random() * 0x7FFFFFFF);
	
	function initPrng(seed:Int = 1) mSeed = seed;
	
	function prand():Float return mSeed = (mSeed * 16807.) % 2147483647.;
	
	function isDynamic():Bool return #if (js || neko || python || php) true; #else false; #end
	
	function contains<T>(x:Array<T>, v:T):Bool
	{
		for (i in 0...x.length)
			if (x[i] == v) return true;
		return false;
	}
}