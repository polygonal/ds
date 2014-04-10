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
			#if no_inline
			TestRunner.print("using against flash.Vector<Dynamic>\n");
			#else
			TestRunner.print("using against flash.Vector<T>\n");
			#end
		#end
		
		add(new TestArray2());
		add(new TestArray3());
		add(new TestArrayedDeque());
		add(new TestArrayedQueue());
		add(new TestArrayedStack());
		add(new TestArrayUtil());
		add(new TestBinaryTree());
		add(new TestBits());
		add(new TestBitVector());
		add(new TestBST());
		add(new TestDA());
		add(new TestDLL());
		add(new TestDLLCircular());
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
		add(new TestPriorityQueue());
		add(new TestSLL());
		add(new TestTree());
		
		#if flash
		add(new TestHashMap());
		#end
		
		add(new test.pooling.TestObjectPool());
		add(new test.pooling.TestDynamicObjectPool());
		
		#if flash
		add(new mem.TestMemoryManager());
		run();
		this.cases = new List<haxe.unit.TestCase>();
		de.polygonal.ds.mem.MemoryManager.free();
		de.polygonal.ds.mem.MemoryManager.RESERVE_BYTES = 1024 * 1024 * 20;
		de.polygonal.ds.mem.MemoryManager.BLOCK_SIZE_BYTES = 1024 * 512;
		#end
		
		add(new mem.TestByteMemory());
		add(new mem.TestBitMemory());
		add(new mem.TestShortMemory());
		add(new mem.TestFloatMemory());
		add(new mem.TestDoubleMemory());
		add(new mem.TestIntMemory());
		
		run();
	}
}