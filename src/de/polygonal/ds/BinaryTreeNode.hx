/*
Copyright (c) 2008-2018 Michael Baczynski, http://www.polygonal.de

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
package de.polygonal.ds;

import de.polygonal.ds.tools.ArrayTools;
import de.polygonal.ds.tools.Assert.assert;
import de.polygonal.ds.tools.MathTools;

using de.polygonal.ds.tools.NativeArrayTools;

/**
	A binary tree
	
	A tree data structure in which each node has at most two child nodes.
	
	Example:
		var o = new de.polygonal.ds.BinaryTreeNode<Int>(0);
		o.setLeft(1);
		o.setRight(2);
		o.left.setLeft(3);
		o.left.left.setRight(4);
		trace(o); //outputs:
		
		[ BinaryTree val=0 size=5 depth=0 height=4
		  0
		  L---1
		  |   L---3
		  |   |   R---4
		  R---2
		]
**/
#if generic
@:generic
#end
class BinaryTreeNode<T> implements Collection<T>
{
	/**
		A unique identifier for this object.
		
		A hash table transforms this key into an index of an array element by using a hash function.
	**/
	public var key(default, null):Int = HashKey.next();
	
	/**
		The node's data.
	**/
	public var val:T;
	
	/**
		The parent node or null if this node has no parent.
	**/
	public var parent:BinaryTreeNode<T>;
	
	/**
		The left child node or null if this node has no left child.
	**/
	public var left:BinaryTreeNode<T>;
	
	/**
		The right child node or null if this node has no right child.
	**/
	public var right:BinaryTreeNode<T>;
	
	var mTimestamp:Int = 0;
	var mStack:NativeArray<BinaryTreeNode<T>> = null;
	
	#if debug
	var mBusy:Bool;
	#end
	
	/**
		Creates a new `BinaryTreeNode` object storing `val`.
	**/
	public function new(val:T)
	{
		this.val = val;
		parent = left = right = null;
		
		#if debug
		mBusy = false;
		#end
	}
	
	/**
		Performs a recursive _preorder_ traversal.
		
		A preorder traversal performs the following steps:
		
		1. Visit the node
		2. Traverse the left subtree of the node
		3. Traverse the right subtree of the node
		
		@param process a function that is invoked on every traversed node.
		If omitted, `element.visit()` is used instead.
		<br/>_In this case all elements have to implement `Visitable`._
		<br/>The first argument holds a reference to the current node, while the second argument stores custom data specified by the `userData` parameter (default is null).
		Once `process` returns false, the traversal stops immediately and no further nodes are examined.
		@param iterative if true, an iterative traversal is used (default traversal style is recursive).
		@param userData custom data that is passed to every visited node via `process` or `element.visit()`. If omitted, null is used.
	**/
	public function preorder(process:BinaryTreeNode<T>->Dynamic->Bool = null, iterative:Bool = false, userData:Dynamic = null)
	{
		if (iterative == false)
		{
			if (process == null)
			{
				var v:Visitable = cast val;
				var run = v.visit(false, userData);
				if (run && hasLeft()) run = preorderRecursiveVisitable(left, userData);
				if (run && hasRight()) preorderRecursiveVisitable(right, userData);
			}
			else
			{
				var run = process(this, userData);
				if (run && hasLeft()) run = preorderRecursive(left, process, userData);
				if (run && hasRight()) preorderRecursive(right, process, userData);
			}
		}
		else
		{
			var s = getStack();
			var top = 0;
			var max = NativeArrayTools.size(s);
			
			inline function pop() return s.get(--top);
			inline function push(x) s.set(top++, x);
			inline function reserve(n)
				if (n > max)
					s = resizeStack(max <<= 1);
			
			push(this);
			
			if (process == null)
			{
				var node, v:Dynamic;
				while (top != 0)
				{
					node = pop();
					v = node.val;
					if (!v.visit(false, userData)) return;
					
					reserve(top + 2);
					
					if (node.hasRight())
						s.set(top++, node.right);
					if (node.hasLeft())
						s.set(top++, node.left);
				}
			}
			else
			{
				var node;
				while (top != 0)
				{
					node = pop();
					if (!process(node, userData)) return;
					
					reserve(top + 2);
					
					if (node.hasRight())
						push(node.right);
					if (node.hasLeft())
						push(node.left);
				}
			}
		}
	}
	
	/**
		Performs a recursive _inorder_ traversal.
		
		An inorder traversal performs the following steps:
		
		1. Traverse the left subtree of the node
		2. Visit the node
		3. Traverse the right subtree of the node
		
		@param process a function that is invoked on every traversed node.
		If omitted, `element.visit()` is used instead.
		<br/>_In this case all elements have to implement `Visitable`._
		<br/>The first argument holds a reference to the current node, while the second argument stores custom data specified by the userData parameter (default is null).
		Once `process` returns false, the traversal stops immediately and no further nodes are examined.
		@param iterative if true, an iterative traversal is used (default traversal style is recursive).
		@param userData custom data that is passed to every visited node via `process` or `element.visit()`. If omitted, null is used.
	**/
	public function inorder(process:BinaryTreeNode<T>->Dynamic->Bool = null, iterative:Bool = false, userData:Dynamic = null)
	{
		if (iterative == false)
		{
			if (process == null)
			{
				if (hasLeft())
					if (!inorderRecursiveVisitable(left, userData))
						return;
				
				var v:Visitable = cast val;
				if (!v.visit(false, userData)) return;
				if (hasRight())
					inorderRecursiveVisitable(right, userData);
			}
			else
			{
				if (hasLeft())
					if (!inorderRecursive(left, process, userData))
						return;
				if (!process(this, userData)) return;
				if (hasRight())
					inorderRecursive(right, process, userData);
			}
		}
		else
		{
			var s = getStack();
			var top = 0;
			var max = NativeArrayTools.size(s);
			
			inline function pop() return s.get(--top);
			inline function push(x) s.set(top++, x);
			inline function reserve(n)
				if (n > max)
					s = resizeStack(max <<= 1);
			
			var node = this;
			
			if (process == null)
			{
				while (node != null)
				{
					while (node != null)
					{
						reserve(top + 2);
						if (node.right != null)
							push(node.right);
						push(node);
						node = node.left;
					}
					
					var v:Dynamic;
					node = pop();
					while (top != 0 && node.right == null)
					{
						v = node.val;
						if (!v.visit(false, userData)) return;
						node = pop();
					}
					
					v = node.val;
					if (!v.visit(false, userData)) return;
					node = (top != 0) ? pop() : null;
				}
			}
			else
			{
				while (node != null)
				{
					while (node != null)
					{
						reserve(top + 2);
						if (node.right != null)
							push(node.right);
						push(node);
						node = node.left;
					}
					
					node = pop();
					while (top != 0 && node.right == null)
					{
						if (!process(node, userData)) return;
						node = pop();
					}
					
					if (!process(node, userData)) return;
					node = (top != 0) ? pop() : null;
				}
			}
		}
	}
	
	/**
		Performs a recursive _postorder_ traversal.
		
		A postorder traversal performs the following steps:
		
		1. Traverse the left subtree of the node
		2. Traverse the right subtree of the node
		3. Visit the node
		
		@param process a function that is invoked on every traversed node.
		If omitted, `element.visit()` is used instead.
		<br/>_In this case all elements have to implement `Visitable`._
		<br/>The first argument holds a reference to the current node, while the second argument stores custom data specified by the userData parameter (default is null).
		Once `process` returns false, the traversal stops immediately and no further nodes are examined.
		@param iterative if true, an iterative traversal is used (default traversal style is recursive).
		@param userData custom data that is passed to every visited node via `process` or `element.visit()`. If omitted, null is used.
	**/
	public function postorder(process:BinaryTreeNode<T>->Dynamic->Bool = null, iterative:Bool = false, userData:Dynamic = null)
	{
		if (iterative == false)
		{
			if (process == null)
			{
				if (hasLeft())
					if (!postorderRecursiveVisitable(left, userData))
						return;
				if (hasRight())
					if (!postorderRecursiveVisitable(right, userData))
						return;
				
				var v:Visitable = cast val;
				v.visit(false, userData);
			}
			else
			{
				if (hasLeft())
					if (!postorderRecursive(left, process, userData))
						return;
				if (hasRight())
					if (!postorderRecursive(right, process, userData))
						return;
				process(this, userData);
			}
		}
		else
		{
			#if debug
			assert(mBusy == false, "recursive call to iterative postorder");
			mBusy = true;
			#end
			
			var s = getStack();
			var top = 0;
			var max = NativeArrayTools.size(s);
			
			inline function push(x) s.set(top++, x);
			inline function reserve(n)
				if (n > max)
					s = resizeStack(max <<= 1);
			
			var time = mTimestamp + 1;
			
			push(this);
			
			if (process == null)
			{
				var node, v:Visitable;
				while (top != 0)
				{
					reserve(top + 1);
					
					node = s.get(top - 1);
					if ((node.left != null) && (node.left.mTimestamp < time))
						push(node.left);
					else
					{
						if ((node.right != null) && (node.right.mTimestamp < time))
							push(node.right);
						else
						{
							v = cast node.val;
							if (!v.visit(false, userData))
							{
								#if debug
								mBusy = false;
								#end
								return;
							}
							node.mTimestamp++;
							top--;
						}
					}
				}
			}
			else
			{
				var node;
				while (top != 0)
				{
					reserve(top + 1);
					
					node = s.get(top - 1);
					if ((node.left != null) && (node.left.mTimestamp < time))
						push(node.left);
					else
					{
						if ((node.right != null) && (node.right.mTimestamp < time))
							push(node.right);
						else
						{
							if (!process(node, userData))
							{
								#if debug
								mBusy = false;
								#end
								return;
							}
							node.mTimestamp++;
							top--;
						}
					}
				}
			}
			
			#if debug
			mBusy = false;
			#end
		}
	}
	
	/**
		Returns true if this node has a left child node.
	**/
	@:extern public inline function hasLeft():Bool
	{
		return left != null;
	}
	
	/**
		Adds a left child node storing `val`.
		
		If a left child exists, only the element is updated to `val`.
	**/
	public inline function setLeft(val:T):BinaryTreeNode<T>
	{
		if (left == null)
		{
			left = new BinaryTreeNode<T>(val);
			left.parent = this;
		}
		else
			left.val = val;
		return this;
	}
	
	/**
		Returns true if this node has a right child node.
	**/
	@:extern public inline function hasRight():Bool
	{
		return right != null;
	}
	
	/**
		Adds a right child node storing `val`.
		
		If a right child exists, only the element is updated to `val`.
	**/
	public inline function setRight(val:T):BinaryTreeNode<T>
	{
		if (right == null)
		{
			right = new BinaryTreeNode<T>(val);
			right.parent = this;
		}
		else
			right.val = val;
		return this;
	}
	
	/**
		Returns true if this node is a left child as seen from its parent node.
	**/
	@:extern public inline function isLeft():Bool
	{
		if (parent == null)
			return false;
		else
			return parent.left == this;
	}
	
	/**
		Returns true if this node is a right child as seen from its parent node.
	**/
	@:extern public inline function isRight():Bool
	{
		if (parent == null)
			return false;
		else
			return parent.right == this;
	}
	
	/**
		Returns true if this node is a leaf node (`this.left` and `this.right` are both null).
	**/
	@:extern public inline function isLeaf():Bool
	{
		return left == null && right == null;
	}
	
	/**
		Returns true if this node is a root node (`this.parent` is null).
	**/
	@:extern public inline function isRoot():Bool
	{
		return parent == null;
	}
	
	/**
		Calculates the depth of this node.
		
		The depth is defined as the length of the path from the root node to this node.
		
		The root node is at depth 0.
	**/
	public inline function depth():Int
	{
		var node = parent;
		var c = 0;
		while (node != null)
		{
			node = node.parent;
			c++;
		}
		return c;
	}
	
	/**
		Computes the height of this subtree.
		
		The height is defined as the path from the root node to the deepest node in a tree.
		
		A tree with only a root node has a height of one.
	**/
	public function height():Int
	{
		return 1 + MathTools.max((left != null ? left.height() : 0), right != null ? right.height() : 0);
	}
	
	/**
		Calls 'f` on all elements in preorder.
	**/
	public inline function iter(f:T->Void, ?tmpStack:Array<BinaryTreeNode<T>>):BinaryTreeNode<T>
	{
		assert(f != null);
		
		var stack = tmpStack;
		if (stack == null) stack = [];
		stack[0] = this;
		
		var top = 1;
		while (top > 0)
		{
			var n = stack[--top];
			if (n.hasLeft()) stack[top++] = n.left;
			if (n.hasRight()) stack[top++] = n.right;
			f(n.val);
		}
		return this;
	}
	
	/**
		Disconnects this node from this subtree.
	**/
	public inline function unlink():BinaryTreeNode<T>
	{
		if (parent != null)
		{
			if (isLeft()) parent.left = null;
			else
			if (isRight()) parent.right = null;
			parent = null;
		}
		left = right = null;
		return this;
	}
	
	/**
		Prints out all elements.
	**/
	#if !no_tostring
	public function toString():String
	{
		var b = new StringBuf();
		b.add('[ BinaryTree val=${Std.string(val)} size=$size depth=${depth()} height=${height()}');
		if (size == 1)
		{
			b.add(" ]");
			return b.toString();
		}
		b.add("\n");
		var f = function(node:BinaryTreeNode<T>, userData:Dynamic):Bool
		{
			var d = node.depth();
			var t = "";
			for (i in 0...d)
			{
				if (i == d - 1)
					t += (node.isLeft() ? "L" : "R") + "---";
				else
					t += "|   ";
			}
			
			t = "  " + t;
			b.add(t + node.val + "\n");
			return true;
		}
		preorder(f);
		b.add("]");
		return b.toString();
	}
	#end
	
	function preorderRecursive(node:BinaryTreeNode<T>, process:BinaryTreeNode<T>->Dynamic->Bool, userData:Dynamic):Bool
	{
		var run = process(node, userData);
		if (run && node.hasLeft()) run = preorderRecursive(node.left, process, userData);
		if (run && node.hasRight()) run = preorderRecursive(node.right, process, userData);
		return run;
	}
	
	function preorderRecursiveVisitable(node:BinaryTreeNode<T>, userData:Dynamic):Bool
	{
		var v:Visitable = cast node.val;
		var run = v.visit(false, userData);
		if (run && node.hasLeft()) run = preorderRecursiveVisitable(node.left, userData);
		if (run && node.hasRight()) run = preorderRecursiveVisitable(node.right, userData);
		return run;
	}
	
	function inorderRecursive(node:BinaryTreeNode<T>, process:BinaryTreeNode<T>->Dynamic->Bool, userData:Dynamic):Bool
	{
		if (node.hasLeft())
			if (!inorderRecursive(node.left, process, userData))
				return false;
		if (!process(node, userData)) return false;
		if (node.hasRight())
			if (!inorderRecursive(node.right, process, userData))
				return false;
		return true;
	}
	
	function inorderRecursiveVisitable(node:BinaryTreeNode<T>, userData:Dynamic):Bool
	{
		if (node.hasLeft())
			if (!inorderRecursiveVisitable(node.left, userData))
				return false;
		var v:Visitable = cast node.val;
		if (!v.visit(false, userData))
			return false;
		if (node.hasRight())
			if (!inorderRecursiveVisitable(node.right, userData))
				return false;
		return true;
	}
	
	function postorderRecursive(node:BinaryTreeNode<T>, process:BinaryTreeNode<T>->Dynamic->Bool, userData:Dynamic):Bool
	{
		if (node.hasLeft())
			if (!postorderRecursive(node.left, process, userData))
				return false;
		if (node.hasRight())
			if (!postorderRecursive(node.right, process, userData))
				return false;
		return process(node, userData);
	}
	
	function postorderRecursiveVisitable(node:BinaryTreeNode<T>, userData:Dynamic):Bool
	{
		if (node.hasLeft())
			if (!postorderRecursiveVisitable(node.left, userData))
				return false;
		if (node.hasRight())
			if (!postorderRecursiveVisitable(node.right, userData))
				return false;
		var v:Visitable = cast node.val;
		return v.visit(false, userData);
	}
	
	function heightRecursive(node:BinaryTreeNode<T>):Int
	{
		var cl = -1;
		var cr = -1;
		if (node.hasLeft())
			cl = heightRecursive(node.left);
		if (node.hasRight())
			cr = heightRecursive(node.right);
		return MathTools.max(cl, cr) + 1;
	}
	
	/* INTERFACE Collection */
	
	/**
		Recursively counts the number of nodes in this subtree (including this node).
	**/
	public var size(get, never):Int;
	function get_size():Int
	{
		var c = 1;
		if (hasLeft()) c += left.size;
		if (hasRight()) c += right.size;
		return c;
	}
	
	/**
		Destroys this object by explicitly nullifying all nodes, pointers and elements for GC'ing used resources.
		
		Improves GC efficiency/performance (optional).
	**/
	public function free()
	{
		if (hasLeft()) left.free();
		if (hasRight()) right.free();
		
		val = cast null;
		right = left = parent = null;
		mStack = null;
	}
	
	/**
		Returns true if the subtree rooted at this node contains `val`.
	**/
	public function contains(val:T):Bool
	{
		var stack = new Array<BinaryTreeNode<T>>();
		stack[0] = this;
		var c = 1;
		var found = false;
		while (c > 0)
		{
			var node = stack[--c];
			if (node.val == val)
			{
				found = true;
				break;
			}
			if (node.hasLeft()) stack[c++] = node.left;
			if (node.hasRight()) stack[c++] = node.right;
		}
		return found;
	}
	
	/**
		Runs a recursive preorder traversal that removes all occurrences of `val`.
		
		Tree nodes are not rearranged, so if a node storing `val` is removed, the subtree rooted at that node is unlinked and lost.
		@return true if at least one occurrence of `val` was removed.
	**/
	public function remove(val:T):Bool
	{
		var found = false;
		if (this.val == val)
		{
			unlink();
			found = true;
		}
		
		if (hasLeft()) found = found || left.remove(val);
		if (hasRight()) found = found || right.remove(val);
		return found;
	}
	
	/**
		Removes all child nodes.
		
		@param gc if true, all nodes and elements of this subtree are recursively nullified so the garbage collector can reclaim used memory.
	**/
	public function clear(gc:Bool = false)
	{
		if (gc)
		{
			if (hasLeft()) left.clear(gc);
			if (hasRight()) right.clear(gc);
			left = right = parent = null;
			val = cast null;
		}
		else
			left = right = null;
	}
	
	/**
		Returns a new *BinaryTreeNodeIterator* object to iterate over all elements contained in the nodes of this subtree (including this node).
		
		The elements are visited by using a preorder traversal.
		
		@see http://haxe.org/ref/iterators
	**/
	public function iterator():Itr<T>
	{
		return new BinaryTreeNodeIterator<T>(this);
	}
	
	/**
		Unsupported operation; always returns false.
	**/
	public inline function isEmpty():Bool
	{
		return false;
	}
	
	/**
		Returns an array containing all elements in this subtree.
		
		The elements are added by applying a preorder traversal.
	**/
	public function toArray():Array<T>
	{
		if (isEmpty()) return [];
		
		var out = ArrayTools.alloc(size);
		var i = 0;
		preorder(function(node:BinaryTreeNode<T>, userData:Dynamic):Bool { out[i++] = node.val; return true; });
		return out;
	}
	
	/**
		Creates and returns a shallow copy (structure only - default) or deep copy (structure & elements) of this node and its subtree.
		
		If `byRef` is true, primitive elements are copied by value whereas objects are copied by reference.
		
		If `byRef` is false, the `copier` function is used for copying elements. If omitted, `clone()` is called on each element assuming all elements implement `Cloneable`.
	**/
	public function clone(byRef:Bool = true, copier:T->T = null):Collection<T>
	{
		var stack = new Array<BinaryTreeNode<T>>();
		var copy = new BinaryTreeNode<T>(copier != null ? copier(val) : val);
		stack[0] = this;
		stack[1] = copy;
		var top = 2;
		
		if (byRef)
		{
			while (top > 0)
			{
				var c = stack[--top];
				var n = stack[--top];
				if (n.hasRight())
				{
					c.setRight(n.right.val);
					stack[top++] = n.right;
					stack[top++] = c.right;
				}
				if (n.hasLeft())
				{
					c.setLeft(n.left.val);
					stack[top++] = n.left;
					stack[top++] = c.left;
				}
			}
		}
		else
		if (copier == null)
		{
			while (top > 0)
			{
				var c = stack[--top];
				var n = stack[--top];
				if (n.hasRight())
				{
					assert(Std.is(n.right.val, Cloneable), "element is not of type Cloneable");
					
					c.setRight(cast(n.right.val, Cloneable<Dynamic>).clone());
					stack[top++] = n.right;
					stack[top++] = c.right;
				}
				if (n.hasLeft())
				{
					assert(Std.is(n.left.val, Cloneable), "element is not of type Cloneable");
					
					c.setLeft(cast(n.left.val, Cloneable<Dynamic>).clone());
					stack[top++] = n.left;
					stack[top++] = c.left;
				}
			}
		}
		else
		{
			while (top > 0)
			{
				var c = stack[--top];
				var n = stack[--top];
				if (n.hasRight())
				{
					c.setRight(copier(n.right.val));
					stack[top++] = n.right;
					stack[top++] = c.right;
				}
				if (n.hasLeft())
				{
					c.setLeft(copier(n.left.val));
					stack[top++] = n.left;
					stack[top++] = c.left;
				}
			}
		}
		return copy;
	}
	
	function getStack():NativeArray<BinaryTreeNode<T>>
	{
		if (mStack == null)
		{
			var n = parent;
			while (n != null)
			{
				if (n.mStack != null)
				{
					mStack = n.mStack;
					break;
				}
				n = n.parent;
			}
			if (mStack == null)
				mStack = NativeArrayTools.alloc(2);
		}
		return mStack;
	}
	
	function resizeStack(newSize:Int):NativeArray<BinaryTreeNode<T>>
	{
		var t = NativeArrayTools.alloc(newSize);
		mStack.blit(0, t, 0, mStack.size());
		return mStack = t;
	}
}

#if generic
@:generic
#end
@:dox(hide)
class BinaryTreeNodeIterator<T> implements de.polygonal.ds.Itr<T>
{
	var mObject:BinaryTreeNode<T>;
	var mStack:Array<BinaryTreeNode<T>>;
	var mTop:Int;
	var mC:Int;
	
	public function new(x:BinaryTreeNode<T>)
	{
		mObject = x;
		mStack = new Array<BinaryTreeNode<T>>();
		reset();
	}
	
	public inline function reset():Itr<T>
	{
		mStack[0] = mObject;
		mTop = 1;
		mC = 0;
		return this;
	}
	
	public inline function hasNext():Bool
	{
		return mTop > 0;
	}
	
	public inline function next():T
	{
		var node = mStack[--mTop];
		mC = 0;
		if (node.hasLeft())
		{
			mStack[mTop++] = node.left;
			mC++;
		}
		if (node.hasRight())
		{
			mStack[mTop++] = node.right;
			mC++;
		}
		return node.val;
	}
	
	public function remove()
	{
		mTop -= mC;
	}
}
