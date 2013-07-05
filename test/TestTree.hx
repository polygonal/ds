package;

import de.polygonal.ds.Compare;
import de.polygonal.ds.TreeBuilder;
import de.polygonal.ds.TreeNode;
import haxe.Serializer;
import haxe.Unserializer;

class TestTree extends haxe.unit.TestCase
{
	function testRemove()
	{
		var root = new TreeNode<String>('root');
		var itr = root.getBuilder();
		itr.appendChild('element');
		itr.appendChild('root.a2');
		itr.appendChild('root.a3');
		itr.childStart();
		itr.down();
		itr.appendChild('root.b1');
		itr.appendChild('root.b2');
		itr.appendChild('element');
		itr.down();
		itr.appendChild('element');
		assertTrue(root.remove('element'));
	}
	
	function testXmlToTreeNode()
	{
		var xml = '<root rootAttr=\'rootAttrValue\'><node1 node1Attr1=\'a\' node1Attr2=\'b\'><node2 node2Attr=\'c\'/></node1></root>';
		var root = de.polygonal.ds.XmlConvert.toTreeNode(xml);
		
		assertEquals(root.val.name, 'root');
		assertEquals('rootAttrValue', root.val.attributes.get('rootAttr'));
		assertEquals('a', root.children.val.attributes.get('node1Attr1'));
		assertEquals('b', root.children.val.attributes.get('node1Attr2'));
		assertEquals('node1', root.children.val.name);
		assertEquals('c', root.children.children.val.attributes.get('node2Attr'));
		assertEquals('node2', root.children.children.val.name);
	}
	
	function testUnlink()
	{
		var root = new TreeNode<String>('root');
		var itr = root.getBuilder();
		itr.appendChild('root.a1');
		itr.appendChild('root.a2');
		itr.appendChild('root.a3');
		
		var node = root.children.unlink();
		assertEquals(null, node.parent);
		assertEquals(root.numChildren(), 2);
		
		var lastChild = root.getLastChild();
		assertTrue(lastChild != null);
		
		var node = lastChild.unlink();
		assertEquals(node.parent, null);
		assertEquals(root.numChildren(), 1);
		
		var lastChild = root.getLastChild();
		var node = lastChild.unlink();
		assertEquals(node.parent, null);
		assertEquals(root.numChildren(), 0);
	}
	
	function testAppendNode()
	{
		var root = new TreeNode<String>('root');
		var itr = root.getBuilder();
		itr.appendChild('root.a1');
		itr.appendChild('root.a2');
		itr.appendChild('root.a3');
		
		var node = new TreeNode<String>('new');
		var itr = node.getBuilder();
		itr.appendChild('new.a1');
		itr.appendChild('new.a2');
		itr.appendChild('new.a3');
		
		root.appendNode(node);
		assertEquals(8, root.size());
	}
	
	function testPrependNode()
	{
		var root = new TreeNode<String>('root');
		var itr = root.getBuilder();
		itr.appendChild('root.a1');
		itr.appendChild('root.a2');
		itr.appendChild('root.a3');
		
		var node = new TreeNode<String>('new');
		var itr = node.getBuilder();
		itr.appendChild('new.a1');
		itr.appendChild('new.a2');
		itr.appendChild('new.a3');
		
		root.prependNode(node);
		assertEquals(8, root.size());
	}
	
	function testInsertAfter()
	{
		var root = new TreeNode<String>('root');
		var itr = root.getBuilder();
		itr.appendChild('root.a1');
		itr.appendChild('root.a3');
		
		var node = new TreeNode<String>('new');
		var itr = node.getBuilder();
		itr.appendChild('new.a1');
		itr.appendChild('new.a2');
		itr.appendChild('new.a3');
		
		root.insertAfterChild(root.children, node);
		assertEquals(3, root.numChildren());
		assertEquals(7, root.size());
	}
	
	function testInsertBefore()
	{
		var root = new TreeNode<String>('root');
		var itr = root.getBuilder();
		itr.appendChild('root.a1');
		itr.appendChild('root.a3');
		
		var node = new TreeNode<String>('new');
		var itr = node.getBuilder();
		itr.appendChild('new.a1');
		itr.appendChild('new.a2');
		itr.appendChild('new.a3');
		
		root.insertBeforeChild(root.children, node);
		assertEquals(3, root.numChildren());
		assertEquals(7, root.size());
	}
	
	function testLevelOrder()
	{
		var root = new TreeNode<String>('R');
		var itr = root.getBuilder();
		
		itr.appendChild('a');
		itr.appendChild('b');
		itr.appendChild('c');
		
		itr.childStart();
		itr.down();
		itr.appendChild('d');
		itr.appendChild('e');
		itr.appendChild('f');
		itr.childStart();
		itr.nextChild();
		itr.down();
		itr.appendChild('g');
		itr.appendChild('h');
		
		var visitOrder = [];
		
		var process = function(x:TreeNode<String>, userData:Dynamic):Bool
		{
			visitOrder.push(x.val);
			return true;
		}
		
		visitOrder = [];
		root.find('a').levelorder(process);
		assertEquals('a,d,e,f,g,h', visitOrder.join(','));
		
		visitOrder = [];
		root.find('f').levelorder(process);
		assertEquals('f', visitOrder.join(','));
		
		visitOrder = [];
		root.find('d').levelorder(process);
		assertEquals('d', visitOrder.join(','));
		
		visitOrder = [];
		root.find('e').levelorder(process);
		assertEquals('e,g,h', visitOrder.join(','));
		
		var root = new TreeNode<String>('root');
		var itr = root.getBuilder();
		
		itr.appendChild('root.a1');
		itr.appendChild('root.a2');
		itr.appendChild('root.a3');
		
		itr.childStart();
		itr.down();
		itr.appendChild('root.a1.b1');
		itr.appendChild('root.a1.b2');
		
		var order = ['root', 'root.a1', 'root.a2', 'root.a3', 'root.a1.b1', 'root.a1.b2'];
		var i = 0;
		
		var scope = this;
		var visit = function(x:TreeNode<String>, userData:Dynamic):Bool
		{
			scope.assertEquals(x.val, order[i++]);
			return true;
		}
		
		root.levelorder(visit);
		
		//visitable
		var root = new TreeNode<Visitor>(new Visitor('root'));
		var itr = root.getBuilder();
		
		itr.appendChild(new Visitor('root.a1'));
		itr.appendChild(new Visitor('root.a2'));
		itr.appendChild(new Visitor('root.a3'));
		
		itr.childStart();
		itr.down();
		itr.appendChild(new Visitor('root.a1.b1'));
		itr.appendChild(new Visitor('root.a1.b2'));
		
		Visitor.c = 0;
		Visitor.t = this;
		Visitor.order = order;
		
		root.levelorder(null, false);
		assertEquals(root.size(), Visitor.c);
	}
	
	function testPreOrderPreflight()
	{
		//function
		var root = new TreeNode<String>('root');
		var itr = root.getBuilder();
		
		itr.appendChild('root.a1');
		itr.appendChild('root.a2');
		itr.appendChild('root.a3');
		
		itr.childStart();
		itr.down();
		itr.appendChild('root.a1.b1');
		itr.appendChild('root.a1.b2');
		
		var order = ['root', 'root.a2', 'root.a3'];
		var i = 0;
		
		var scope = this;
		var visit = function(x:TreeNode<String>, preflight:Bool, userData:Dynamic):Bool
		{
			if (preflight)
			{
				if (x.val == 'root.a1')
					return false;
				return true;
			}
			
			scope.assertEquals(x.val, order[i++]);
			return true;
		}
		
		i = 0;
		root.preorder(visit, true, false);
		i = 0;
		root.preorder(visit, true, true);
		
		//visitable
		var root = new TreeNode<Visitor>(new Visitor('root'));
		var itr = root.getBuilder();
		
		itr.appendChild(new Visitor('root.a1'));
		itr.appendChild(new Visitor('root.a2'));
		itr.appendChild(new Visitor('root.a3'));
		
		itr.childStart();
		itr.down();
		itr.appendChild(new Visitor('root.a1.b1'));
		itr.appendChild(new Visitor('root.a1.b2'));
		
		Visitor.c = 0;
		Visitor.t = this;
		Visitor.order = ['root', 'root.a2', 'root.a3'];
		Visitor.exclude = 'root.a1';
		
		root.preorder(null, true, true);
		Visitor.c = 0;
		root.preorder(null, true, false);
		
		Visitor.c = 0;
		Visitor.order = ['root', 'root.a1', 'root.a1.b1', 'root.a1.b2', 'root.a3'];
		Visitor.exclude = 'root.a2';
		
		root.preorder(null, true, true);
		Visitor.c = 0;
		root.preorder(null, true, false);
		
		Visitor.c = 0;
		Visitor.order = [];
		Visitor.exclude = 'root';
		
		root.preorder(null, true, true);
		Visitor.c = 0;
		root.preorder(null, true, false);
	}
	
	function testPreOrder()
	{
		var root = new TreeNode<String>('root');
		var itr = root.getBuilder();
		
		itr.appendChild('root.a1');
		itr.appendChild('root.a2');
		itr.appendChild('root.a3');
		
		itr.childStart();
		itr.down();
		itr.appendChild('root.a1.b1');
		itr.appendChild('root.a1.b2');
		
		var order = ['root', 'root.a1', 'root.a1.b1', 'root.a1.b2', 'root.a2', 'root.a3'];
		var i = 0;
		
		var scope = this;
		var visit = function(x:TreeNode<String>, preflight:Bool, userData:Dynamic):Bool
		{
			scope.assertEquals(x.val, order[i++]);
			return true;
		}
		
		i = 0;
		root.preorder(visit, false, false);
		i = 0;
		root.preorder(visit, false, true);
		
		//visitable
		
		var root = new TreeNode<Visitor>(new Visitor('root'));
		var itr = root.getBuilder();
		itr.appendChild(new Visitor('root.a1'));
		itr.appendChild(new Visitor('root.a2'));
		itr.appendChild(new Visitor('root.a3'));
		itr.childStart();
		itr.down();
		itr.appendChild(new Visitor('root.a1.b1'));
		itr.appendChild(new Visitor('root.a1.b2'));
		
		Visitor.c = 0;
		Visitor.t = this;
		Visitor.order = order;
		
		root.preorder(null, false);
		
		assertEquals(root.size(), Visitor.c);
	}
	
	function testPostOrder()
	{
		var root = new TreeNode<String>('root');
		var itr = root.getBuilder();
		
		itr.appendChild('root.a1');
		itr.appendChild('root.a2');
		itr.appendChild('root.a3');
		
		itr.childStart();
		itr.down();
		itr.appendChild('root.a1.b1');
		itr.appendChild('root.a1.b2');
		
		var order = ['root.a1.b1', 'root.a1.b2', 'root.a1', 'root.a2', 'root.a3', 'root'];
		var i = 0;
		
		var scope = this;
		var visit = function(x:TreeNode<String>, userData:Dynamic):Bool
		{
			scope.assertEquals(x.val, order[i++]);
			return true;
		}
		
		i = 0;
		root.postorder(visit);
		i = 0;
		root.postorder(visit, true);
		
		//visitable
		
		var root = new TreeNode<Visitor>(new Visitor('root'));
		var itr = root.getBuilder();
		
		itr.appendChild(new Visitor('root.a1'));
		itr.appendChild(new Visitor('root.a2'));
		itr.appendChild(new Visitor('root.a3'));
		
		itr.childStart();
		itr.down();
		itr.appendChild(new Visitor('root.a1.b1'));
		itr.appendChild(new Visitor('root.a1.b2'));
		
		Visitor.c = 0;
		Visitor.t = this;
		Visitor.order = order;
		
		root.postorder(null, false);
		assertEquals(root.size(), Visitor.c);
	}
	
	function testCreate()
	{
		var root = new TreeNode<Int>(0);
		var child = new TreeNode<Int>(1, root);
		
		assertEquals(1, root.numChildren());
		assertEquals(child, root.children);
		
		var root = new TreeNode<Int>(0);
		var child = new TreeNode<Int>(1);
		
		assertEquals(0, root.numChildren());
		
		var builder = new TreeBuilder<Int>(root);
		builder.appendChild(1);
		
		assertEquals(1, root.numChildren());
	}
	
	function testFind()
	{
		var root = new TreeNode<String>('root');
		var itr = root.getBuilder();
		
		itr.appendChild('root.a1');
		itr.appendChild('root.a2');
		itr.appendChild('root.a3');
		
		itr.childStart();
		itr.down();
		itr.appendChild('root.a1.b1');
		itr.appendChild('root.a1.b2');
		
		assertEquals('root.a1', root.find('root.a1').val);
		assertEquals('root.a2', root.find('root.a2').val);
		assertEquals('root.a3', root.find('root.a3').val);
		assertEquals('root.a1.b1', root.find('root.a1.b1').val);
		assertEquals('root.a1.b2', root.find('root.a1.b2').val);
	}
	
	function testDepth()
	{
		var root = new TreeNode<String>('root');
		var itr = root.getBuilder();
		
		itr.appendChild('root.a1');
		itr.appendChild('root.a2');
		itr.appendChild('root.a3');
		
		itr.childStart();
		itr.down();
		itr.appendChild('root.a1.b1');
		itr.appendChild('root.a1.b2');
		
		itr.childStart();
		itr.down();
		itr.appendChild('root.a1.b1.c1');
		
		assertEquals(0, root.depth());
		assertEquals(1, root.children.depth());
		assertEquals(2, root.children.children.depth());
		assertEquals(3, root.children.children.children.depth());
	}
	
	function testChildIndex()
	{
		var root = new TreeNode<String>('root');
		var itr = root.getBuilder();
		
		itr.appendChild('root.a1');
		itr.appendChild('root.a2');
		itr.appendChild('root.a3');
		
		itr.childStart();
		itr.down();
		itr.appendChild('root.a1.b1');
		itr.appendChild('root.a1.b2');
		
		itr.childStart();
		itr.down();
		itr.appendChild('root.a1.b1.c1');
		
		assertEquals(0, root.getSiblingIndex());
		assertEquals(0, root.children.getSiblingIndex());
		assertEquals(1, root.children.next.getSiblingIndex());
		assertEquals(2, root.children.next.next.getSiblingIndex());
		assertEquals(0, root.children.children.getSiblingIndex());
	}
	
	function testHeight()
	{
		var root = new TreeNode<String>('root');
		var itr = root.getBuilder();
		
		itr.appendChild('root.a1');
		itr.appendChild('root.a2');
		itr.appendChild('root.a3');
		
		itr.childStart();
		itr.down();
		itr.appendChild('root.a1.b1');
		itr.appendChild('root.a1.b2');
		
		itr.childStart();
		itr.down();
		itr.appendChild('root.a1.b1.c1');
		
		assertEquals(4, root.height());
		assertEquals(3, root.children.height());
		assertEquals(2, root.children.children.height());
		assertEquals(1, root.children.children.children.height());
	}
	
	function testIteratorRemove()
	{
		var a = new TreeNode<String>('a');
		var itr = a.getBuilder();
		itr.appendChild('b');
		itr.appendChild('c');
		itr.childStart();
		itr.down();
		itr.appendChild('d');
		itr.appendChild('e');
		itr.up();
		itr.childEnd();
		itr.down();
		itr.appendChild('f');
		//['a', 'c', 'f', 'b', 'e', 'd'];
		var tree:TreeNode<String> = cast a.clone(true);
		
		var order = ['a'];
		var itr = tree.iterator();
		while (itr.hasNext())
		{
			var e = itr.next();
			assertEquals(e, order.shift());
			itr.remove();
		}
		assertEquals(0, order.length);
		
		var tree:TreeNode<String> = cast a.clone(true);
		var order = ['a', 'c', 'b', 'e', 'd'];
		var itr = tree.iterator();
		while (itr.hasNext())
		{
			var e = itr.next();
			assertEquals(e, order.shift());
			if (e == 'c')
				itr.remove();
		}
		assertEquals(0, order.length);
		
		var tree:TreeNode<String> = cast a.clone(true);
		var order = ['a', 'c', 'f', 'b'];
		var itr = tree.iterator();
		while (itr.hasNext())
		{
			var e = itr.next();
			assertEquals(e, order.shift());
			if (e == 'b')
				itr.remove();
		}
		assertEquals(0, order.length);
		
		var tree:TreeNode<String> = cast a.clone(true);
		var order = ['a', 'c', 'f', 'b', 'e', 'd'];
		var itr = tree.iterator();
		while (itr.hasNext())
		{
			var e = itr.next();
			assertEquals(e, order.shift());
			if (e == 'e')
				itr.remove();
		}
		assertEquals(0, order.length);
		
		var tree:TreeNode<String> = cast a.clone(true);
		var order = ['a', 'c', 'f', 'b', 'e', 'd'];
		var itr = tree.iterator();
		while (itr.hasNext())
		{
			var e = itr.next();
			assertEquals(e, order.shift());
			if (e == 'd')
				itr.remove();
		}
		assertEquals(0, order.length);
	}
	
	function testSort()
	{
		var root = new TreeNode<Int>(100);
		var data:Array<Int> = [2, 3, 4, 9, 5, 1, 7, 6, 8, 0];
		var builder = root.getBuilder();
		for (i in 0...10) builder.appendChild(i);
		root.sort(Compare.compareNumberRise, false);
		
		var c = 10;
		var node = root.getLastChild();
		while (node != null)
		{
			c--;
			assertEquals(node.val, c);
			node = node.prev;
		}
		assertEquals(0, c);
		
		var root = new TreeNode<SortableNode>(null);
		var data:Array<Int> = [2, 3, 4, 9, 5, 1, 7, 6, 8, 0];
		var builder = root.getBuilder();
		for (i in 0...10) builder.appendChild(new SortableNode(i));
		root.sort(null, false);
		
		var c = 0;
		var node = root.getLastChild();
		while (node != null)
		{
			assertEquals(node.val.id, c++);
			node = node.prev;
		}
		assertEquals(10, c);
		
		var root = new TreeNode<Int>(100);
		var builder = root.getBuilder();
		for (i in 0...10) builder.appendChild(i);
		
		root.sort(function(a, b) { return b - a; });
		var i = 9;
		var child = root.children;
		while (child != null)
		{
			assertEquals(i--, child.val);
			child = child.next;
		}
		
		root.sort(function(a, b) { return a - b; });
		var i = 0;
		var child = root.children;
		while (child != null)
		{
			assertEquals(i++, child.val);
			child = child.next;
		}
		
		root.sort(function(a, b) { return a - b; }, true);
		var i = 0;
		var child = root.children;
		while (child != null)
		{
			assertEquals(i++, child.val);
			child = child.next;
		}
		root.sort(function(a, b) { return b - a; }, true);
		var i = 9;
		var child = root.children;
		while (child != null)
		{
			assertEquals(i--, child.val);
			child = child.next;
		}
		
		for (i in 0...9) root.remove(i);
		root.sort(function(a, b) { return b - a; });
	}
	
	function test()
	{
		var rootNode:TreeNode<Int> = new TreeNode<Int>(0);
		
		var itr:TreeBuilder<Int> = new TreeBuilder<Int>(rootNode);
		assertTrue(itr.valid());
		
		itr.appendChild(0);
		itr.appendChild(1);
		itr.appendChild(2);
		itr.appendChild(3);
		itr.appendChild(4);
		
		itr.prependChild(9);
		itr.prependChild(8);
		itr.prependChild(7);
		itr.prependChild(6);
		itr.prependChild(5);
		
		itr.childStart();
		assertTrue(itr.childValid());
		for (i in 0...5)
		{
			assertEquals(i + 5, itr.getChildVal());
			itr.nextChild();
		}
		
		for (i in 0...5)
		{
			assertEquals(i, itr.getChildVal());
			itr.nextChild();
		}
		
		itr.childStart();
		while (itr.getChildVal() != 2)
			itr.nextChild();
	}
	
	function testClone()
	{
		var rootNode = new TreeNode<Int>(0);
		
		var itr:TreeBuilder<Int> = rootNode.getBuilder();
		assertTrue(itr.valid());
		
		itr.appendChild(0);
		itr.appendChild(1);
		itr.appendChild(2);
		itr.appendChild(3);
		
		itr.down();
		
		itr.appendChild(4);
		itr.appendChild(5);
		
		assertEquals(0, rootNode.children.val);
		assertEquals(1, rootNode.children.next.val);
		assertEquals(2, rootNode.children.next.next.val);
		assertEquals(3, rootNode.children.next.next.next.val);
		assertEquals(4, rootNode.children.next.next.next.children.val);
		assertEquals(5, rootNode.children.next.next.next.children.next.val);
		
		var copy:TreeNode<Int> = cast rootNode.clone(true);
		
		assertEquals(0, copy.children.val);
		assertEquals(1, copy.children.next.val);
		assertEquals(2, copy.children.next.next.val);
		assertEquals(3, copy.children.next.next.next.val);
		assertEquals(4, copy.children.next.next.next.children.val);
		assertEquals(5, copy.children.next.next.next.children.next.val);
	}
	
	function testAncestorDescendant()
	{
		var rootNode = new TreeNode<Int>(0);
		
		var itr:TreeBuilder<Int> = rootNode.getBuilder();
		assertTrue(itr.valid());
		
		var n0 = itr.appendChild(0);
		var n1 = itr.appendChild(1);
		var n2 = itr.appendChild(2);
		var n3 = itr.appendChild(3);
		
		itr.down();
		
		var n4 = itr.appendChild(4);
		var n5 = itr.appendChild(5);
		
		assertTrue(rootNode.isAncestor(n0));
		assertTrue(rootNode.isAncestor(n1));
		assertTrue(rootNode.isAncestor(n2));
		assertTrue(rootNode.isAncestor(n3));
		assertTrue(rootNode.isAncestor(n4));
		assertTrue(rootNode.isAncestor(n5));
		assertTrue(n3.isAncestor(n4));
		assertTrue(n5.isDescendant(rootNode));
		assertTrue(n5.isDescendant(n3));
	}
	
	function testSwapChildren()
	{
		var root = new TreeNode<Int>(100);
		var a = new TreeNode<Int>(1);
		var b = new TreeNode<Int>(2);
		root.appendNode(a);
		root.appendNode(b);
		
		root.swapChildren(a, b);
		assertEquals(2, root.children.val);
		assertEquals(1, root.children.next.val);
		
		var root = new TreeNode<Int>(100);
		var a = new TreeNode<Int>(1);
		var b = new TreeNode<Int>(2);
		root.appendNode(a);
		root.appendNode(b);
		
		root.swapChildren(b, a);
		assertEquals(2, root.children.val);
		assertEquals(1, root.children.next.val);
		
		var root = new TreeNode<Int>(100);
		var a = new TreeNode<Int>(1);
		var b = new TreeNode<Int>(2);
		var c = new TreeNode<Int>(3);
		root.appendNode(a);
		root.appendNode(b);
		root.appendNode(c);
		
		root.swapChildren(b, c);
		assertEquals(1, root.children.val);
		assertEquals(3, root.children.next.val);
		assertEquals(2, root.children.next.next.val);
	}
	
	function testSwapChildrenAt()
	{
		var root = new TreeNode<Int>(100);
		var a = new TreeNode<Int>(1);
		var b = new TreeNode<Int>(2);
		root.appendNode(a);
		root.appendNode(b);
		
		root.swapChildrenAt(0, 1);
		assertEquals(2, root.children.val);
		assertEquals(1, root.children.next.val);
		
		
		var root = new TreeNode<Int>(100);
		var a = new TreeNode<Int>(1);
		var b = new TreeNode<Int>(2);
		root.appendNode(a);
		root.appendNode(b);
		
		root.swapChildrenAt(1, 0);
		assertEquals(2, root.children.val);
		assertEquals(1, root.children.next.val);
	}
	
	function testRemoveChildAt()
	{
		var root = new TreeNode<Int>(100);
		var a = new TreeNode<Int>(1);
		root.appendNode(a);
		root.removeChildAt(0);
		
		assertEquals(1, root.size());
		assertEquals(null, root.children);
		
		var root = new TreeNode<Int>(100);
		var a = new TreeNode<Int>(1);
		var b = new TreeNode<Int>(2);
		root.appendNode(a);
		root.appendNode(b);
		root.removeChildAt(0);
		
		assertEquals(2, root.size());
		assertEquals(b, root.children);
		
		var root = new TreeNode<Int>(100);
		var a = new TreeNode<Int>(1);
		var b = new TreeNode<Int>(2);
		root.appendNode(a);
		root.appendNode(b);
		root.removeChildAt(1);
		
		assertEquals(2, root.size());
		assertEquals(a, root.children);
		
		var root = new TreeNode<Int>(100);
		var a = new TreeNode<Int>(1);
		var b = new TreeNode<Int>(2);
		var c = new TreeNode<Int>(2);
		root.appendNode(a);
		root.appendNode(b);
		root.appendNode(c);
		root.removeChildAt(1);
		
		assertEquals(3, root.size());
		assertEquals(a, root.children);
		assertEquals(c, root.children.next);
	}
	
	function testSetChildIndex()
	{
		var root = new TreeNode<Int>(100);
		var a = new TreeNode<Int>(1);
		root.appendNode(a);
		
		root.setChildIndex(a, 0);
		assertEquals(a, root.children);
		
		var root = new TreeNode<Int>(100);
		var a = new TreeNode<Int>(1);
		var b = new TreeNode<Int>(2);
		root.appendNode(a);
		root.appendNode(b);
		
		root.setChildIndex(b, 0);
		assertEquals(b, root.children);
		assertEquals(a, root.children.next);
		
		var root = new TreeNode<Int>(100);
		var a = new TreeNode<Int>(1);
		var b = new TreeNode<Int>(2);
		var c = new TreeNode<Int>(3);
		root.appendNode(a);
		root.appendNode(b);
		root.appendNode(c);
		
		root.setChildIndex(c, 1);
		assertEquals(a, root.children);
		assertEquals(c, root.children.next);
		assertEquals(b, root.children.next.next);
		
		var root = new TreeNode<String>('root');
		var a = new TreeNode<String>('a');
		var b = new TreeNode<String>('b');
		var c = new TreeNode<String>('c');
		root.appendNode(a);
		root.appendNode(b);
		root.appendNode(c);
		
		root.setChildIndex(a, 2);
		assertEquals(b, root.children);
		assertEquals(c, root.children.next);
		assertEquals(a, root.children.next.next);
		
		var root = new TreeNode<String>('root');
		var a = new TreeNode<String>('a');
		var b = new TreeNode<String>('b');
		var c = new TreeNode<String>('c');
		root.appendNode(a);
		root.appendNode(b);
		root.appendNode(c);
		
		root.setChildIndex(c, 0);
		assertEquals(c, root.children);
		assertEquals(a, root.children.next);
		assertEquals(b, root.children.next.next);
	}
	
	function testInsertChildAt()
	{
		var root = new TreeNode<String>('root');
		var a = new TreeNode<String>('a');
		root.insertChildAt(a, 0);
		assertEquals(a, root.children);
		
		var root = new TreeNode<String>('root');
		var a = new TreeNode<String>('a');
		var b = new TreeNode<String>('b');
		root.appendNode(a);
		root.insertChildAt(b, 1);
		assertEquals(a, root.children);
		assertEquals(b, root.children.next);
		
		var root = new TreeNode<String>('root');
		var a = new TreeNode<String>('a');
		var b = new TreeNode<String>('b');
		root.appendNode(a);
		root.insertChildAt(b, 0);
		assertEquals(b, root.children);
		assertEquals(a, root.children.next);
		
		var root = new TreeNode<String>('root');
		var a = new TreeNode<String>('a');
		var b = new TreeNode<String>('b');
		var c = new TreeNode<String>('c');
		root.appendNode(a);
		root.appendNode(b);
		root.insertChildAt(c, 0);
		assertEquals(c, root.children);
		assertEquals(a, root.children.next);
		assertEquals(b, root.children.next.next);
		
		var root = new TreeNode<String>('root');
		var a = new TreeNode<String>('a');
		var b = new TreeNode<String>('b');
		var c = new TreeNode<String>('c');
		root.appendNode(a);
		root.appendNode(b);
		root.insertChildAt(c, 2);
		assertEquals(a, root.children);
		assertEquals(b, root.children.next);
		assertEquals(c, root.children.next.next);
		
		var root = new TreeNode<String>('root');
		var a = new TreeNode<String>('a');
		var b = new TreeNode<String>('b');
		var c = new TreeNode<String>('c');
		root.appendNode(a);
		root.appendNode(b);
		root.insertChildAt(c, 1);
		assertEquals(a, root.children);
		assertEquals(c, root.children.next);
		assertEquals(b, root.children.next.next);
	}
	
	function testRemoveChildren()
	{
		var root = new TreeNode<String>('root');
		var a = new TreeNode<String>('a');
		root.appendNode(a);
		root.removeChildren();
		assertEquals(null, root.children);
		
		var root = new TreeNode<String>('root');
		var a = new TreeNode<String>('a');
		var b = new TreeNode<String>('b');
		root.appendNode(a);
		root.appendNode(b);
		root.removeChildren(1);
		assertEquals(a, root.children);
		
		var root = new TreeNode<String>('root');
		var a = new TreeNode<String>('a');
		var b = new TreeNode<String>('b');
		var c = new TreeNode<String>('c');
		root.appendNode(a);
		root.appendNode(b);
		root.appendNode(c);
		root.removeChildren(0, 2);
		assertEquals(c, root.children);
	}
	
	function testCollection()
	{
		var c:de.polygonal.ds.Collection<Int> = new TreeNode<Int>(0);
		assertEquals(true, true);
	}
	
	function testSerialization()
	{
		var a = new TreeNode<String>('a');
		var b = new TreeNode<String>('b');
		var c = new TreeNode<String>('c');
		var d = new TreeNode<String>('d');
		var e = new TreeNode<String>('e');
		var f = new TreeNode<String>('f');
		var g = new TreeNode<String>('g');
		var x = new TreeNode<String>('x');
		var y = new TreeNode<String>('y');
		
		a.appendNode(b);
		a.appendNode(c);
		a.appendNode(d);
		
		b.appendNode(e);
		b.appendNode(f);
		f.appendNode(g);
		
		d.appendNode(x);
		d.appendNode(y);
		
		var list = a.serialize();
		
		var s = new Serializer();
		s.serialize(list);
		
		var serialized = s.toString();
		
		var s2 = new Unserializer(serialized);
		var list = s2.unserialize();
		
		var output = new TreeNode<String>(null);
		output.unserialize(list);
		
		assertEquals('a', output.val);
		assertEquals('b', output.getChildAt(0).val);
		assertEquals('c', output.getChildAt(1).val);
		assertEquals('d', output.getChildAt(2).val);
		assertEquals('e', output.getChildAt(0).getChildAt(0).val);
		assertEquals('f', output.getChildAt(0).getChildAt(1).val);
		assertEquals('g', output.getChildAt(0).getChildAt(1).getChildAt(0).val);
		assertEquals('x', output.getChildAt(2).getChildAt(0).val);
		assertEquals('y', output.getChildAt(2).getChildAt(1).val);
		assertEquals(9, output.size());
	}
}

private class Visitor implements de.polygonal.ds.Visitable
{
	public static var exclude:String;
	public static var c:Int;
	public static var t:haxe.unit.TestCase;
	public static var order:Array<String>;
	
	public var id:String;
	public function new(id:String)
	{
		this.id = id;
	}
	
	public function visit(preflight:Bool, userData:Dynamic):Bool
	{
		if (preflight)
		{
			if (id == exclude)
				return false;
			return true;
		}
		
		t.assertEquals(order[c], id);
		c++;
		return true;
	}
}

private class SortableNode implements de.polygonal.ds.Comparable<SortableNode>
{
	public var id:Int;
	public function new(id:Int)
	{
		this.id = id;
	}
	
	public function compare(other:SortableNode):Int
	{
		return id - other.id;
	}
	
	public function toString():String
	{
		return '' + id;
	}
}