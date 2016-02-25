import haxe.unit.TestRunner;

class UnitTest extends TestRunner
{
	static function main()
	{
		new UnitTest();
	}
	
	function new()
	{
		super();
		
		#if flash
			flash.Lib.current.stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
			var output = "";
			var f = TestRunner.print;
			f("");
			cast(flash.Lib.current.getChildAt(0), flash.text.TextField).defaultTextFormat =
				new flash.text.TextFormat("Courier New", 11);
			TestRunner.print = function(v:Dynamic)
			{
				output += v;
				f(v);
			}
		#end
		
		var flags = [];
		
		#if debug
		flags.push("-debug");
		#end
		#if generic
		flags.push("-D generic");
		#end
		#if alchemy
		flags.push("-D alchemy");
		#end
		#if no_inline
		flags.push("--no-inline");
		#end
		
		TestRunner.print('compile flags: ${flags.join(" ")}\n');
		
		var success = true;
		
		add(new TestArray2());
		add(new TestArray3());
		add(new TestArrayedDeque());
		add(new TestArrayedQueue());
		add(new TestArrayedStack());
		add(new TestArrayList());
		add(new TestArrayTools());
		add(new TestBinaryTree());
		add(new TestBits());
		add(new TestBitVector());
		add(new TestBst());
		add(new TestDll());
		add(new TestDllCircular());
		add(new TestGraph());
		add(new TestHashSet());
		add(new TestHashTable());
		add(new TestHeap());
		add(new TestIntHashSet());
		add(new TestIntHashTable());
		add(new TestIntIntHashTable());
		add(new TestLinkedDeque());
		add(new TestLinkedQueue());
		add(new TestLinkedStack());
		add(new TestListSet());
		add(new TestNativeArray());
		add(new TestPriorityQueue());
		add(new TestSll());
		add(new TestTree());
		
		add(new pooling.TestObjectPool());
		add(new pooling.TestDynamicObjectPool());
		
		#if (flash && alchemy)
		add(new mem.TestMemoryManager());
		run();
		this.cases = new List<haxe.unit.TestCase>();
		de.polygonal.ds.mem.MemoryManager.free();
		de.polygonal.ds.mem.MemoryManager.RESERVE_BYTES = 1024 * 1024 * 20;
		de.polygonal.ds.mem.MemoryManager.BLOCK_SIZE_BYTES = 1024 * 512;
		#end
		
		#if flash
		add(new mem.TestByteMemory());
		add(new mem.TestBitMemory());
		add(new mem.TestShortMemory());
		add(new mem.TestFloatMemory());
		add(new mem.TestDoubleMemory());
		add(new mem.TestIntMemory());
		#end
		
		success = success && run();
		
		#if (flash && !ide)
		if (success) flash.system.System.exit(0);
		#elseif js
		(untyped process).exit(success ? 0 : 1);
		#elseif sys
		Sys.exit(success ? 0 : 1);
		#end
	}
}