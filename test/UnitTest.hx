package;

class UnitTest extends haxe.unit.TestRunner
{
	static function main()
	{
		new UnitTest();
	}
	
	function new()
	{
		super();
		
		#if alchemy
		#if (flash10 || cpp)
		add(new test.mem.TestMemoryManager());
		run();
		this.cases = new List<haxe.unit.TestCase>();
		de.polygonal.ds.mem.MemoryManager.free();
		de.polygonal.ds.mem.MemoryManager.RESERVE_BYTES = 1024 * 1024 * 20;
		de.polygonal.ds.mem.MemoryManager.BLOCK_SIZE_BYTES = 1024 * 512;
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
		
		#if flash9
		add(new TestHashMap());
		#end
		
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
		
		add(new test.mem.TestByteMemory());
		add(new test.mem.TestBitMemory());
		add(new test.mem.TestShortMemory());
		add(new test.mem.TestFloatMemory());
		add(new test.mem.TestDoubleMemory());
		add(new test.mem.TestIntMemory());
		
		add(new test.pooling.TestObjectPool());
		add(new test.pooling.TestDynamicObjectPool());
		
		run();
	}
}