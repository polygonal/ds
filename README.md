# Data Structures For Games (ds)

![ds logo](http://polygonal.github.com/ds/images/ds-small.png)

Formerly known as "_AS3 Data Structures For Game Developers (AS3DS)_", the package contains parametrized classes that allow programmers to easily implement standard data structures like linked lists, queues, stacks or multi-dimensional arrays. The result is somewhere in between the C++ STL (Standard Template Library) and the Java Collection framework. The library is highly optimized and uses advanced Haxe features like inlining or code generation for parametrized classes through the haxe.rtti.Generics interface.

## Documentation
-    Slides [Introduction to ds - Data Structures For Games](http://lab.polygonal.de/wp-content/assets/120111/introduction_to_ds.pdf)
-    API [http://polygonal.github.com/ds/doc](http://polygonal.github.com/ds/doc)

## Articles

-    [A* Pathfinding](http://lab.polygonal.de/?p=1815)
-    [Heaps and Priority Queues](http://lab.polygonal.de/?p=1710)
-    [What is a Deque?](http://lab.polygonal.de/?p=1472)
-    [Fast hash tables](http://lab.polygonal.de/?p=1325)
-    [Alchemy Memory Management](http://lab.polygonal.de/?p=1230)

## Cross-Platform Support

ds currently supports Flash AVM1+2, JavaScript, C++ and Neko

## Conditional Compilation Flags
`-D generic`

Enables generic classes (implements `haxe.rtti.Generic`). Optimization for strictly typed runtimes (AVM2), but increases file size.

`-D alchemy`

Enables fast virtual memory for FP10+ ("alchemy memory"). By default, memory access is replaced with arrays or the flash Vector class.

`-D doc`

Prevents less important inner classes from being documented.

## Questions, Comments, Feature Requests...

http://groups.google.com/group/polygonal-ds

## Installation
Install [Haxe](http://haxe.org/download) and run `$ haxelib install polygonal-ds` from the console.
This installs the polygonal-ds library hosted on [lib.haxe.org](http://lib.haxe.org/p/polygonal-ds), which always mirrors the git master branch. From now on just compile with `$ haxe ... -lib polygonal-ds`.
If you want to test the latest beta build, you should pull the dev branch and add the src folder to the classpath via `$ haxe ... -cp src`.

## Changelog

### 1.4.1 (released 2013-07-08)

 * modified: removed "polygonal-core" haxelib dependency
 
### 1.4.0 (released 2013-06-28)
_support Haxe Compiler 3.0.0_

 * modified: support Haxe 3 only (Haxe 2.x and Neko 1.x are no longer supported)
 * modified: sacrifice Collection.toDA() for proper @:generic support
 * modified: explicitly allocate elements in ArrayUtil.alloc() when targeting neko
 * fixed: several fixes when compilin with -D generic 
 * modified: change BitVector to use the haxe.ds.Vector as data
 * modified: ArrayUtil.shrink(): trim when targeting cpp
 * modified: ArrayUtil.alloc(): explicitly allocate elements when targeting cpp
 * modified: more conservative inlining
 * modified: don't allocate stack arrays when doing iterative pre/post-order traversals
 * modified: optimized TreeNode.contains()
 * modified: optimize TreeNode.levelOrder by using an implicit queue
 * modified: all: fill() method returns this for chaining

### 1.39 (released 2013-02-12)
_supports Haxe 2.10 & Haxe 3.00 r6189_

 * fixed: swc files: get rid of warnings for Flash Builder 4.7 + falcon compiler
 * fixed: cpp + blackberry target
 * fixed: some Haxe 3 fixes

### 1.38 (released 2013-01-27)

 * modified: swc: moved Haxe classes to hx package
 * added: serialization of TreeNode structures (de.polygonal.ds.Serialization)
 * fixed: minor fixes for -D haxe3
 * added: ArrayUtil#equals()
 * added: IntIntHashTable, IntHashTable, HashTable#getAll()
 * fixed: IntIntHashTable#remove()
 * added: BitVector#getBucketAt(), getBuckets()
 * modified: replaced DA#swapWithBack() with DA#swapPop()
 * added: ArrayUtil#split()
 * fixed: TreeNode.removeChildren()
 * added: unit tests
 * added: support Neko 2.0 RC (compile with -D neko_v2)

### 1.37 (released 2012-11-15)

 * modified: Graph: added Graph#borrowArc() and Graph#returnArc() to allow optional arc pooling
 * fixed: TreeNode#isAncestor(), TreeNode#isDescendant()
 * fixed: LinkedObjectPool: object instantiation for non-flash targets
 * added: ArrayUtil#quickPerm(): counting quickperm algorithm

### 1.36 (released 2012-07-25)

 * added: TreeNode#isAncestor()
 * added: TreeNode#isDescendant()
 * added: TreeNode#getChildIndex()
 * modified: TreeNode#preorder, postorder: allow node removal during traversal
 * fixed: PriorityQueue#toString(): now prints elements in sorted order
 * modified: faster debugging with --no-inline through macro-based asserts
 * fixed: DA#inRange()
 * added: DLL#createNode(), DLL#appendNode(), DLL#prependNode()
 * fixed: typo Bitflags#setiff() => setfif()
 * added: TreeNode#insertChildAt()
 * added: TreeNode#removeChildAt()
 * added: TreeNode#setChildIndex()
 * added: TreeNode#swapChildren()
 * added: TreeNode#swapChildrenAt()
 * fixed: TreeNode#insertAfterChild(), insertBeforeChild()
 * modified: TreeNode#numChildren() is now O(1)
 * added: TreeNode#removeChildren()
 * added: TreeNode#setStack()
 * modified: TreeNode#getChildAtIndex() => TreeNode.getChildAt()
 * modified: cpp/nme target: now supporting MemoryManager
 * added: XmlConvert.toTreeNode(): xml => TreeNode conversion
 * added: Array2#copyCol(), Array2#swapCol()
 * added: Array2#copyRow(), Array2#swapRow()
 * fixed: support Haxe 2.10
 * modified: also dump state with toString() in release mode
 * fixed: DA.sort() out of bound access
 * fixed: BitVector.ofBytes for neko

### 1.35 (released 2011-12-22)

 * modified: Collection.clone(): make assign parameter optional so clone() does a shallow copy per default
 * added: Array2#setNestedArray()
 * added: TreeNode#getChildAtIndex()
 * added: include Lambda class in swc files (http://haxe.org/api/lambda)
 * added: TreeNode#childIterator()
 * fixed: Heap#remove(), PriorityQueue#remove()
 * fixed: Collection#toVector()
 * modified: Heap#remove(), PriorityQueue#remove() is now O(1)

### 1.34 (released 2011-10-26)

 * added: all: Collection#toVector() for FP10+
 * modified: too many issues with -D swf-protected so revert back to prefixing private members with underscore

### 1.33 (released 2011-10-21)

 * modified: disabled haxe.rtti.Generic optimization by default, enable with -D 'generic' (replaces 'no_rtti' flag)
 * fixed: DynamicObjectPool: 'object x was returned twice to the pool' assert
 * added: DynamicObjectPool#used()
 * added: Compare#lexiographic()
 * added: Bits#unpackUI16Lo(), unpackUI16Hi()
 * fixed: DLL#lastNodeOf()
 * fixed: TreeNode#levelOrder
 * modified: ObjectPool: allow lazy allocation by using ObjectPool#allocate(true, ...)
 * added: ArrayedDeque#indexOfFront(), indexOfBack()
 * added: LinkedDeque#indexOfFront(), indexOfBack()
 * fixed: HashMap#toArray()
 * added: BitVector#clrRange(), setRange()
 * added: Array2#inRange(), Array3#inRange()
 * added: Array2#getAt(), Array3#getAt()
 * fixed: MemoryAccess#swp()
 * fixed: PriorityQueue#reprioritze(): use float type for priority value
 * fixed: HashSet remove obsolete \<K\> type parameter
 * added: all except TreeNode+BinaryTreeNode: added reuseIterator flag
 * modified: by default alchemy memory optimization is now disabled, enable with -D alchemy (removed -D 'no_alchemy')
 * added: support for Itr#remove()
 * added: DynamicObjectPool#maxUsageCount()
 * modified: swc: compiled with Haxe 2.08
 * modified: swc: only show public API (all private fields marked with an underscore are now protected)

### 1.32 (released 2011-07-17)

 * fixed: LinkedObjectPool#get()
 * added: Array2#getAtIndex()
 * added: Array2#setAtIndex()
 * fixed: HashMap#remove(x): now removes all keys that map the value x
 * fixed: BinaryTreeNode docs
 * fixed: Graph#DFS(), Graph#BFS(): include seed in traversal when preflight flag is set
 * fixed: IntHashTable memory leak
 * modified: added MemoryAccess#name for better debugging/profiling
 * fixed: LinkedQueue#remove() infinite loop in edge cases
 * modified: IntHashSet, HashSet, IntIntHashTable, IntHashTable, HashTable#clear(): only shrink container if purge=true
 * fixed MemoryManager OOM error when calling realloc
 * added: BitMemory#get()
 * fixed: ArrayedDeque#iterator()
 * changed: Itr#next() now returns a reference to itself
 * fixed: Graph#unlink()
 * modified: added Graph#removeNode()
 * fixed: HashMap#remap()
 * fixed: HashTable, IntHashTable, IntIntHashTable#toString()
 * fixed: HashSet, IntHashTable, IntHashTable#clear()
 * fixed: LinkedStack#clear()
 * fixed: Graph#remove(): update size when removing node
 * added: DA#inRange(): check if given index is valid
 * fixed: DA#sort() using quicksort
 * modified: GraphNode: added traversal depth and parent pointer
 * modified: Graph: cost is now optional (default is 1.0)
 * modified: changed Graph#addNode() to allow subclassing of GraphNode objects
 * fixed: various fixes for the cpp target
 * added: Graph#autoClearMarks
 * modified: de.polygonal.ds.mem package now works with hxcpp+NME "alchemy" memory
 * added: Graph#DLBFS(): depth-limited breadth-first search
 * fixed: DLL#sort: mergesort produced invalid prev pointers
 * modified: optimized TreeNode class
 * modified: added support for circular singly linked lists
 * fixed: Graph#free(): infinite loop lockup
 * fixed: TreeNode#free(): also nullify parent and val field
 * fixed: SLL#nodeOf(): always returned null
 * modified: support circular singly linked lists
 * fixed: DLL#free(), clear(): infinite loop lockup
 * fixed: DLL#clone(): preserve circular property
 * modified: PriorityQueue: use float type for storing priority value
 * modified: DA#sort(): support range sorting
 * added: ArrayUtil#sortRange()
 * modified: document complexity
 * fixed: ArrayQueue#fill(), assign() for js target

### 1.31 (released 2011-04-11)

 * modified: better AS3/SWC support: removed some redundant classes, haxe.init(mc) is no longer required
 * added: TreeNode#sort() - sort children
 * added: preflight flag for TreeNode#preorder - exclude subtree from traversal
 * modified: improved TreeNode and BinaryTreeNode iterative traversal performance
 * fixed PriorityQueue#clear(), dequeue(), remove()
 * fixed: Heap#remove()
 * modified: improved Heap performance
 * modified: Heap#enqueue(), dequeue(), front() renamed to Heap#add(), pop(), top()
 * modified: added Heap#replace(), change(), sort(), bottom(), repair(), height()
 * added: Heapable interface
 * modified: PriorityQueue now implements Queue interface
 * modified: added PriorityQueue#back()
 * fixed: some neko compatibility fixes
 * added: optional binary search for DA#indexOf()
 * added: ArrayUtil#shrink()
 * modified: ArrayUtil#bsearchInt/bsearchFloat/bsearchComparator: now returns insertion point instead of just -1
 * added: Bits#next(): macro based bit flag generation

### 1.30 (released 2011-03-03)

 * modified: GraphNode and GraphArc now implement Hashable
 * fixed: DA#reverse()
 * added: Graph#nodeIterator(), Graph#arcIterator()
 * modified: renamed GraphNodeIterator to NodeValIterator
 * added: GraphNode#getArcCount()
 * fixed: return value of Array#getRow(), getCol(), getPile()
 * fixed: TreeBuilder#nextChild(),prevChild()
 * added: TreeBuilder#hasNextChild(), hasPrevChild()
 * fixed: Bits#ntz(): removed static initializer for swc compatibility
 * fixed: Array3#setCol(), setPile()
 * added: TreeNode#getFirstChild(), TreeNode#setFirst(), TreeNode#setLast()
 * fixed: renamed TreeNode#getChildIndex() to TreeNode#getSiblingIndex()
 * fixed: BST: nullify tree if empty
 * added: ArrayedQueue#pack()
 * modified: HashMap: don't allow null keys and null values
 * added: Deque\<T\> interface
 * added: LinkedDeque\<T\>: linked deque implementation
 * added: ArrayedDeque\<T\>: arrayed deque implementation

### 1.23 (released 2011-01-30)

 * added: DynamicObjectPool
 * modified: moved Factory to de.polygonal.ds
 * added: ArrayedStack/LinkedStack: dup(), exchange(), rotRight(), rotLeft()
 * added: MemoryManager.size()
 * modified: Collection#iterator() changed to Collection#itr() (unify AS3/Haxe)
 * modified: Hashable#getKey() changed to Hashable#key for SWC also (unify AS3/Haxe)
 * modified: removed various C++ workarounds that are no longer needed in Haxe 2.07
 * fixed: incorrent maxSize value in release builds
 * modified: IntHashTable/HashTable/HashSet/HashMap: removed nullValue, use Null\<T\> instead
 * fixed: Bits#ntz() and Bits#setBits() for js target
 * added: SLLNode/DLLNode#isHead(), isTail()
 * fixed: Flash AVM1 support
 * modified: ArrayedQueue is now dynamic
 * modified: SWC files compiled with Haxe 2.07

### 1.22 (released 2011-01-11)

 * added: TreeNode levelorder traversal
 * added: MemoryManager: automatically reclaim memory when MemoryAccess object is GCed
 * added: ArrayUtil#assign()
 * added: IntIntHashTable#extract()
 * modified: Collection now implements Hashable
 * fixed: Bits#flipDWORD()
 * modified: allow ByteArray access from MemoryManager
 * added: Da#getNext(), DA#getPrev()
 * modified: refactoring of Assert statements
 * modified: optimized MemoryAccess#fill()
 * fixed: IntIntHashTable shrink segmentation fault
 * fixed: IntIntHashTable set() return value
 * modified: improved MemoryManager defrag performance
 * modified: renamed DA#move() to memmove() and improved performance
 * modified: improved ArrayUtil#memmove()
 * added: MemoryManager#memmove()
 * modified: improved documentation
 * modified: maxSize() is now a property
 * added: ByteMemory#clone()
 * fixed: MemoryManager issues when using SWC files - static getters are now static functions
 * fixed: Bits#hasBitAt()
 * modified: updated documentation
 * modified: simplified ArrayConvert class

### 1.21 (released 2010-12-12)

 * added: HashTable#dispose()
 * fixed: don't skip constructor call in assign() methods
 * fixed: Bits class
 * fixed: SLL/DLL node caching
 * added: DA#swapWithBack()
 * fixed: DA#join()
 * added: IntIntHashTable#count()
 * fixed: IntIntHashTable infinite loop trap when resizing
 * fixed: ObjectPool#iterator() for non-allocated pools
 * modified: ObjectPool: improved performance, smaller memory footprint
 * modified: IntIntHashTable/IntHashTable/HashTable/IntHashSet/HashSet: added resizable parameter to constructor (enforce fixed size)
 * added: BitFlags helper class

### 1.20 (released 2010-11-01)

 * fixed: C++ and JavaScript compatibility
 * added: IntIntHashTable: an array hash table implementation using 32-bit integers for keys and values
 * added: IntHashTable\<T\>: a generic hash table using 32-bit integers for keys
 * added: HashTable\<K, T\>: a generic hash table
 * added: IntHashSet: a hash set for 32-bit integer values
 * added: HashSet\<T\>: a generic hash set
 * added: added Map interface
 * added: added Set interface (Set replaced with ListSet)
 * added: Hashable interface
 * added: HashableItem abstract helper class
 * added: HashKey class
 * added: ListSet: simple replacement for the Set class which was using the flash.utils.Dictionary class.
 * modified: Collection#toArray(?output:Array\<T\>):Array\<T\> changed to Collection#toArray():Array\<T\> (c++ compatibility)
 * modified: Collection#toDA(?output:DA\<T\>):Array\<T\> changed to Collection#toDA():DA\<T\> (c++ compatibility)
 * modified: HashMap refactoring; HashMap\<K, V\> now  implements Map\<K, T\> instead of Collection\<K\>

### 1.12 (released 2010-10-18)

 * fixed: ArrayedQueue#remove(),dispose()
 * fixed: LinkedObjectPool#put()
 * fixed: SLL#merge()
 * fixed: Graph#BFS()
 * modified: SLL/DLL/LinkedStack/LinkedQueue: structures can be created with a reserved size (increases performance at the cost of memory usage through object pooling)
 * fixed: revised dense array (DA)
 * modified: added iterative Graph#DFS()
 * fixed: LinkedQueue#clone()
 * fixed: ArrayedQueue#isFull()
 * fixed: PriorityQueue#toString()
 * fixed: MemoryManager: remember existing 1024 bytes after initialization
 * fixed: TreeNode#postOrder()
 * modified: split assign(x:Dynamic) into fill(x:T) and assign(x:Class\<T\>) because of type safety, performance and cross-platform compatibility
 * some fixes for js/cpp target
 * added: MemoryAccess#clone()
 * added: MemoryAccess#fill()
 * added: MemoryAccess#resize()
 * added: ArrayTools class
 * fixed: several cross-platform issues for de.polygonal.ds.mem when compiled with -D no_alchemy

### 1.11 (released 2010-07-22)

 * added: ObjectPool.isEmpty()
 * added: Array2&3: getIndex(), cellToIndex(), indexToCell(), indexOf(), cellOf()
 * added: Bits.flipWORD and Bits.flipDWORD
 * modified: MemoryManager: default block size is now 64 KiB
 * modified: Set is now cross-platform
 * code style: SLL/DLL: head and tail are now properties
 * modified: SLL/DLL/SLLNode/DLLNode: renamed remove() to unlink() since remove(x:T) is now part of the Collection interface
 * modified: Graph: renamed removeNode() to unlink() since remove(x:T) is now part of the Collection interface
 * modified: de.polygonal.ds.mem.*: added FP9 compatibility when using -D no_alchemy
 * fixed: ShortMemory/IntMemory/FloatMemory/DoubleMemory ofByteArray() endianness
 * added: TreeNode: unlink(), prependNode(), appendNode(), insertAfterChild(), insertBeforeChild(), numNextSiblings(), numPrevSiblings()
 * added: BinaryTreeNode#unlink()
 * modified: renamed Vector to DA (dense array) to avoid confusion with flash's built in Vector class. As a consequence, Collection#toVector() changed to Collection#toDA(), and HashMap#valuesToVector() changed to HashMap#valuesToDA()
 * added: ArrayedStack/Heap/PrioriyQueue/DA#reserve(): If size is known in advance storage can be preallocated to increase performance/reduce memory usage. This is automatically done for fixed-size structures (http://jpauclair.net/2009/12/05/tamarin-part-ii-more-on-array-and-vector/).
 * code style: compact() changed to pack() (prefer shorter names)
 * added: Collection#free(): 'Deconstructor' that nullifies all references (optimizes memory usage and results in faster garbage collection)
 * added: Collection#remove(x:T): Removes all occurrences of x from a collection
 * modified: Collection#clear() changed to Collection#clear(?purge = false)
 * added: ArrayedStack#dispose(): Nullifies reference to popped element for GC
 * modified: Set/HashMap: removed setIfAbsent() and removeIfExists() (merged into set() and remove())
 * modified: improved Collection#toArray()/Collection#toDA()
 * modified: swc files only: Collection#iterator():Object now typed to Collection#iterator():Itr

### 1.1 (released 2010-03-15)

 * added: TreeNode#getChildIndex()
 * fixed: LinkedStack#clear()
 * fixed: LinkedStack#toArray()/toVector()
 * added: Stack interface (implemented by ArrayedStack/LinkedStack)
 * added: Queue interface (implemented by ArrayedQueue/LinkedQueue)
 * fixed: TreeBuilder#removeChild()
 * modified: removed superfluous type parameter from Visitable interface
 * modified: enhanced Bits class (new methods + cross platform compatibility)
 * modified: enhanced BitVector class (cross platform compatibility)
 * added: new MemoryManager (http://lab.polygonal.de/2010/03/04/memorymanager-revisited)
 * added: ShortMemory for storing 16bit integers.
 * fixed: BitVector.ofBytes

### 1.06 (released 2010-01-31)

 * added: ArrayConvert helper class
 * added: ArrayedQueue, ArrayedStack, Vector: swp() and cpy() methods
 * added: LinkedStack, LinkedQueue, SLL, DLL: size constraint when compiled with -debug
 * modified: ArrayedQueue, ArrayedStack, Vector: renamed getAt()/setAt() to get()/set()
 * modified: SLL.nodeOf(): from parameter is now optional (matches DLL.nodeOf())
 * fixed: ArrayedStack.push(): maxSize() assert not fired
 * fixed: Vector.pushBack, pushFront(), insertAt(): maxSize() assert not fired
 * modified: SLL, DLL.remove(node): returns the next node in the list
 * fixed: Vector.iterator()#reset()
 * fixed: Bits.hasAllBits()
 * code style: type inference for optional parameters
 * modified: small optimization in TreeNode.preorder and TreeNode.postorder
 * fixed: TreeNode/Graph/BinaryTreeNode: invalid stack for iterative preorder/inorder/postorder traversals (called from within visit()/process())
 * fixed: TreeNode/Graph/BinaryTreeNode: preorder/inorder/postorder: now accepts optional user data that is passed to every visited node
 * modified: TreeWalker#appendChild(),prependChild(),insertBeforeChild(),insertAfterChild(): now returns the node object storing the child
 * fixed: TreeWalker#new(): wrong vertical pointer
 * added: TreeNode#getRoot(): finds the root of the tree
 * added: Graph#isMarked()
 * added: BitMemory/DoubleMemory/FloatMemory/IntMemory: getIndex(i:Int): memory byte offset for value at index i
 * code style: different 'friend' syntax that ensures strict typing for improved performance (http://www.weblob.net/2010/01/friend-types-are-slow-really)
 * modified: Graph: added maxSize() constraint() for debugging

### 1.05 (released 2009-12-24)

 * all: interfaces can be accessed in swc files
 * all: parameter names are now available in swc files
 * all: switched from flash.Vector to Array for now because a dyamic array (used in swc files) is faster than a dynamic vector and alchemy memory is much faster than typed number vectors.
 * all: iterators now implement de.polygonal.ds.Itr\<T\> (to distinguish between the built-in Iterator typedef)
 * all: iterators can be reused by calling iterator.reset() when typed to ResettableIterator\<T\> or Itr\<T\>
 * all: enhanced assign(): collection can be filled entirely/partially with elements
 * all: enhanced shuffle(): now accepts external random values so different RNG/PRNG can be used.
 * all: enhanced Collection#toArray() and Collection#toVector()
 * all: minor documentation improvements
 * added: Vector collection (growable dense array) as a more advanced Array/Vector replacement (no performance degradation in Haxe).
 * added: compact() method for growable collections that use an array (ArrayedStack, Heap, PriorityQueue, Vector)
 * added: TreeNode#find()
 * added: Bits.hx class (much nicer/faster with 'using' syntax) as a replacement for BitField.hx
 * added: -D no_rtti compiler flag (disables haxe.rtti.Generic)
 * modified: Graph#size(), HashMap#size() and Set#size(): now O(c) instead of O(n)
 * modified: removed size constraint from ArrayedStack, Heap and PriorityQueue (grows on demand)
 * modified: removed obsolete isFull()/capacity() methods
 * fixed: DLL insertionSort
 * fixed: MemoryManager.defragment() + minor improvements
 * fixed: graph.addSingleArc()
 * fixed: Array3#walk()
 * fixed: LinkedStack#iterator()
 * fixed: HashMap#toString()
 * fixed: ObjectPool#get()
 * fixed: TreeNode#height()
 * fixed: BST#height()
 * fixed: BST#toString()

### 1.0 (released 2009-12-09)

 * Significant performance improvements compared to as3ds thanks to the Haxe compiler :)
 * Fixed most issues posted on the old as3ds google code projects page
 * Enhanced documentation
 * Supports "alchemy memory"
 * Collections can be cloned (shallow&deep copy)
 * Some collections can be shuffled
 * Added support for circular doubly linked lists
 * Added object pooling library
 * Added iterative traversal algorithms
 * Added linked graph structure
 * Many small improvements I don't remember...