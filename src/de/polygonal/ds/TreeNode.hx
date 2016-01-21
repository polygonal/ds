/*
Copyright (c) 2008-2014 Michael Baczynski, http://www.polygonal.de

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

import de.polygonal.ds.error.Assert.assert;

/**
	A tree structure
	
	See <a href="http://lab.polygonal.de/?p=184" target="mBlank">http://lab.polygonal.de/?p=184</a>
	
	_<o>Worst-case running time in Big O notation</o>_
**/
#if generic
@:generic
#end
class TreeNode<T> implements Collection<T>
{
	/**
		A unique identifier for this object.
		
		A hash table transforms this key into an index of an array element by using a hash function.
		
		<warn>This value should never be changed by the user.</warn>
	**/
	public var key:Int;
	
	/**
		The node's data.
	**/
	public var val:T;
	
	/**
		The node's parent or null if this node is a root node.
	**/
	public var parent:TreeNode<T>;
	
	/**
		The node's children or null if this node has no children.
		
		This is a doubly linked list of ``TreeNode`` objects and ``children`` points to the first child.
	**/
	public var children:TreeNode<T>;
	
	/**
		The node's previous sibling or null if such a sibling does not exist.
	**/
	public var prev:TreeNode<T>;
	
	/**
		The node's next sibling or null if such a sibling does not exist.
	**/
	public var next:TreeNode<T>;
	
	var mTail:TreeNode<T>;
	var mPrevInStack:TreeNode<T>;
	var mNextInStack:TreeNode<T>;
	var mExtraInfo:Int;
	
	#if debug
	var mBusy:Bool;
	#end
	
	/**
		Creates a ``TreeNode`` object storing the element `x`.
		@param parent if specified, this node is appended to the children of `parent`.
	**/
	public function new(x:T, parent:TreeNode<T> = null)
	{
		this.val = x;
		this.parent = parent;
		
		children = null;
		prev = null;
		next = null;
		mTail = null;
		mNextInStack = null;
		mPrevInStack = null;
		
		if (hasParent())
		{
			parent.incChildCount();
			
			if (parent.hasChildren())
			{
				var tail = parent.getLastChild();
				tail.next = this;
				this.prev = tail;
				next = null;
			}
			else
				parent.children = this;
			
			parent.mTail = this;
		}
		
		mExtraInfo = 0;
		
		#if debug
		mBusy = false;
		#end
		
		key = HashKey.next();
	}
	
	/**
		Returns true if this node is the root node of this tree.
		
		A root node has no parent node.
		<o>1</o>
	**/
	inline public function isRoot():Bool
	{
		return parent == null;
	}
	
	/**
		Returns true if this node is a leaf node of this tree.
		
		A leaf node has no children.
		<o>1</o>
	**/
	inline public function isLeaf():Bool
	{
		return children == null;
	}
	
	/**
		Returns true is this node is a child node of this tree.
		
		A child node has a parent node.
		<o>1</o>
	**/
	inline public function isChild():Bool
	{
		return valid(parent);
	}
	
	/**
		Returns true if this node is an ancestor of `x`.
	**/
	public function isAncestor(x:TreeNode<T>):Bool
	{
		var n = x.parent;
		while (n != null)
		{
			if (this == n) return true;
			n = n.parent;
		}
		return false;
	}
	
	/**
		Returns true if this node is an descendant of `x`.
	**/
	public function isDescendant(x:TreeNode<T>):Bool
	{
		var n = parent;
		while (n != null)
		{
			if (n == x) return true;
			n = n.parent;
		}
		return false;
	}
	
	/**
		Returns true if this node has a parent node.
		<o>1</o>
	**/
	inline public function hasParent():Bool
	{
		return isChild();
	}
	
	/**
		Returns true if this node has at least one child node.
		<o>1</o>
	**/
	inline public function hasChildren():Bool
	{
		return valid(children);
	}
	
	/**
		Returns true if this node has at least one sibling.
		<o>1</o>
	**/
	inline public function hasSiblings():Bool
	{
		if (valid(parent))
			return valid(prev) || valid(next);
		else
			return false;
	}
	
	/**
		Returns true if this node has a sibling to its right (``next`` != null).
		<o>1</o>
	**/
	inline public function hasNextSibling():Bool
	{
		return valid(next);
	}
	
	/**
		Returns true if this node has a sibling to its left (``prev`` != null).
		<o>1</o>
	**/
	inline public function hasPrevSibling():Bool
	{
		return valid(prev);
	}
	
	/**
		Returns the leftmost sibling of this node.
		<o>1</o>
	**/
	inline public function getFirstSibling():TreeNode<T>
	{
		return parent != null ? parent.children : null;
	}
	
	/**
		Returns the rightmost sibling of this node.
		<o>1</o>
	**/
	inline public function getLastSibling():TreeNode<T>
	{
		return parent != null ? parent.mTail : null;
	}
	
	/**
		Returns the sibling index of this node.
		
		The first sibling equals index 0, the last sibling equals index ``numChildren()`` - 1.
		<o>n</o>
	**/
	inline public function getSiblingIndex():Int
	{
		var c = 0;
		var node = prev;
		while (node != null)
		{
			c++;
			node = node.prev;
		}
		return c;
	}
	
	/**
		Swaps the child `a` with child `b` by swapping their values.
		<o>1</o>
		<assert>`a` and `b` are not siblings</assert>
		<assert>`a` equals `b`</assert>
		@return this node.
	**/
	public function swapChildren(a:TreeNode<T>, b:TreeNode<T>):TreeNode<T>
	{
		assert(a.parent == b.parent, "a and b are not siblings");
		assert(a != b, "a equals b");
		
		var tmp = a.val; a.val = b.val; b.val = tmp;
		
		return this;
	}
	
	/**
		Swaps the child at index `i` with the child at index `j` by swapping their values.
		<o>1</o>
		<assert>index `i` out of range</assert>
		<assert>index `j` out of range</assert>
		<assert>`i` equals `j`</assert>
		@return this node.
	**/
	public function swapChildrenAt(i:Int, j:Int):TreeNode<T>
	{
		assert(i >= 0 && i < numChildren(), 'the index i ($i) is out of range ${numChildren()}');
		assert(j >= 0 && j < numChildren(), 'the index j ($j) is out of range ${numChildren()}');
		assert(i != j, 'index i ($i) equals index j');
		
		var t = null;
		var c = 0;
		var n = children;
		while (n != null)
		{
			if (i == c)
			{
				if (t != null)
				{
					swapChildren(n, t);
					return this;
				}
				t = n;
			}
			else
			if (j == c)
			{
				if (t != null)
				{
					swapChildren(n, t);
					return this;
				}
				t = n;
			}
			c++;
			n = n.next;
		}
		
		return this;
	}
	
	/**
		Removes the child at index `i` and returns the child.
		<o>n</o>
		<assert>index `i` is out of range</assert>
		@return this node.
	**/
	public function removeChildAt(i:Int):TreeNode<T>
	{
		assert(i >= 0 && i < numChildren(), 'the index $i is out of range ${numChildren()}');
		
		var j = 0;
		var n = children;
		while (j < i)
		{
			n = n.next;
			j++;
		}
		
		n.unlink();
		
		return n;
	}
	
	/**
		Removes `n` children starting at the specified index `i` in the range [`i`, `i` + `n`].
		
		If `n` is -1, `n` is set to ``numChildren()`` - `i`.
		<o>n</o>
		<assert>`i` or `n` out of range</assert>
		@return this node.
	**/
	public function removeChildren(i = 0, n = -1):TreeNode<T>
	{
		if (n == -1) n = numChildren() - i;
		
		if (n == 0) return this;
		
		assert(i >= 0 && i <= numChildren(), 'i index out of range ($i)');
		assert(n > 0 && n <= numChildren() && (i + n <= numChildren()), 'n out of range ($n)');
		
		var j = 0;
		var c = children;
		while (j < i)
		{
			c = c.next;
			j++;
		}
		j = 0;
		while (j < n)
		{
			var next = c.next;
			c.unlink();
			c = next;
			j++;
		}
		
		return this;
	}
	
	/**
		Changes the index of the child `x` to `i`.
		<o>n</o>
		<assert>index `i` is out of range</assert>
		@return this node.
	**/
	public function setChildIndex(x:TreeNode<T>, i:Int):TreeNode<T>
	{
		assert(i >= 0 && i < numChildren(), 'the index $i is out of range ${numChildren()}');
		
		var n = null;
		var k =-1;
		var j = 0;
		var c = children;
		while (c != null)
		{
			if (i == j)
			{
				n = c;
				if (k != -1)
				{
					if (k < i)
						insertAfterChild(n, x);
					else
					if (k > i)
						insertBeforeChild(n, x);
					return this;
				}
			}
			if (x == c)
			{
				k = j;
				if (n != null)
				{
					if (k < i)
						insertAfterChild(n, x);
					else
					if (k > i)
						insertBeforeChild(n, x);
					return this;
				}
			}
			j++;
			c = c.next;
		}
		return this;
	}
	
	/**
		The total number of child nodes (non-recursive).
		<o>1</o>
	**/
	inline public function numChildren():Int
	{
		return mExtraInfo >>> 16;
	}
	
	/**
		Counts the total number of siblings (excluding this).
		<o>n</o>
	**/
	inline public function numSiblings():Int
	{
		if (hasParent())
			return parent.numChildren() - 1;
		else
			return 0;
	}
	
	/**
		Counts the total number of preceding siblings (excluding this).
		<o>n</o>
	**/
	inline public function numPrevSiblings():Int
	{
		var c = 0;
		var node = prev;
		while (valid(node))
		{
			c++;
			node = node.prev;
		}
		
		return c;
	}
	
	/**
		Counts the total number of succeeding siblings (excluding this).
		<o>n</o>
	**/
	inline public function numNextSiblings():Int
	{
		var c = 0;
		var node = next;
		while (valid(node))
		{
			c++;
			node = node.next;
		}
		return c;
	}
	
	/**
		Calculates the depth of this node within this tree.
		
		The depth is defined as the length of the path from the root node to this node.
		
		The root node is at depth 0.
		<o>n</o>
	**/
	public function depth():Int
	{
		if (isRoot())
			return 0;
		else
		{
			var node = this;
			var c = 0;
			while (node.hasParent())
			{
				c++;
				node = node.parent;
			}
			return c;
		}
	}
	
	/**
		Calculates the height of this tree, assuming this is the root node of this tree.
		
		The height is defined as the length of the path from the root node to the deepest node in the tree.
		
		A tree with one node has a height of one.
		<o>n</o>
	**/
	public function height():Int
	{
		var h = 0;
		var node = children;
		while (node != null)
		{
			h = M.max(h, node.height());
			node = node.next;
		}
		return 1 + h;
	}
	
	/**
		Returns the root node of this tree.
		<o>n</o>
	**/
	inline public function getRoot():TreeNode<T>
	{
		var n = this;
		while (n.hasParent()) n = n.parent;
		return n;
	}
	
	/**
		Returns the leftmost child of this node or null if this node is a leaf node.
		<o>1</o>
	**/
	inline public function getFirstChild():TreeNode<T>
	{
		return children;
	}
	
	/**
		Returns the rightmost child of this node or null if this node is a leaf node.
		<o>1</o>
	**/
	inline public function getLastChild():TreeNode<T>
	{
		return mTail;
	}
	
	/**
		Returns the child at index `i` or null if the node has no children.
		<assert>`i` out of range</assert>
		<o>n</o>
	**/
	inline public function getChildAt(i:Int):TreeNode<T>
	{
		if (hasChildren())
		{
			assert(i >= 0 && i < numChildren(), 'index i out of range ($i)');
			
			var child = children;
			for (j in 0...i) child = child.next;
			return child;
		}
		else
			return null;
	}
	
	/**
		Returns the child index of this node.
	**/
	inline public function getChildIndex():Int
	{
		var i = 0;
		var n = this;
		while (n.prev != null)
		{
			i++;
			n = n.prev;
		}
		return i;
	}
	
	/**
		Unlinks this node.
		<o>1</o>
		@return a subtree rooted at this node.
	**/
	public function unlink():TreeNode<T>
	{
		if (parent != null)
		{
			if (parent.children == this)
				parent.children = next;
			if (parent.mTail == this)
				parent.mTail = prev;
			parent.decChildCount();
			
			parent = null;
		}
		if (hasPrevSibling()) prev.next = next;
		if (hasNextSibling()) next.prev = prev;
		next = prev = null;
		mNextInStack = null;
		mPrevInStack = null;
		
		return this;
	}
	
	/**
		Unlinks `x` and appends `x` as a child to this node.
		<o>1</o>
		<assert>`x` is null</assert>
		@return this node.
	**/
	public function appendNode(x:TreeNode<T>):TreeNode<T>
	{
		assert(x != null, "x is null");
		
		x.unlink();
		x.parent = this;
		incChildCount();
		
		if (hasChildren())
		{
			mTail.next = x;
			x.prev = mTail;
			x.next = null;
			mTail = x;
		}
		else
		{
			mTail = x;
			children = x;
		}
		
		return this;
	}
	
	/**
		Unlinks `x` and prepends `x` as a child of this node.
		<o>1</o>
		@return this node.
	**/
	public function prependNode(x:TreeNode<T>):TreeNode<T>
	{
		x.unlink();
		x.parent = this;
		incChildCount();
		
		if (hasChildren())
		{
			var head = children;
			x.next = head;
			head.prev = x;
			x.prev = null;
		}
		else
			mTail = x;
		
		children = x;
		
		return this;
	}
	
	/**
		Unlinks `x` and appends `x` to the specified `child` node.
		<o>1</o>
		<assert>`child` node is not a child of this node</assert>
		@return this node.
	**/
	public function insertAfterChild(child:TreeNode<T>, x:TreeNode<T>):TreeNode<T>
	{
		assert(child.parent == this, "given child node is not a child of this node");
		
		x.unlink();
		x.parent = this;
		incChildCount();
		
		if (children == null)
		{
			children = x;
			return this;
		}
		
		if (child.hasNextSibling())
		{
			child.next.prev = x;
			x.next = child.next;
		}
		child.next = x;
		x.prev = child;
		
		if (child == mTail)
			mTail = x;
		
		return this;
	}
	
	/**
		Unlinks `x` and prepends `x` to the specified child `node`.
		<o>1</o>
		<assert>`child` node is not a child of this node</assert>
		@return this node.
	**/
	public function insertBeforeChild(child:TreeNode<T>, x:TreeNode<T>):TreeNode<T>
	{
		assert(child.parent == this, "given child node is not a child of this node");
		
		x.unlink();
		x.parent = this;
		incChildCount();
		
		if (children == null)
		{
			children = x;
			return this;
		}
		
		if (child == children) children = x;
		if (child.hasPrevSibling())
		{
			child.prev.next = x;
			x.prev = child.prev;
		}
		
		x.next = child;
		child.prev = x;
		
		return this;
	}
	
	/**
		Unlinks `x` and inserts `x` at the index position `i`.
		<o>1</o>
		<assert>index `i` out of range</assert>
		@return this node.
	**/
	public function insertChildAt(x:TreeNode<T>, i:Int):TreeNode<T>
	{
		assert(i >= 0 && i <= numChildren(), 'index $i out of range');
		
		if (i == 0)
			prependNode(x);
		else
		if (i == numChildren())
			appendNode(x);
		else
			insertBeforeChild(getChildAt(i), x);
		
		return this;
	}
	
	/**
		Successively swaps this node with previous siblings until it reached the head of the sibling list.
		<o>1</o>
		@return this node.
	**/
	public function setFirst():TreeNode<T>
	{
		if (hasSiblings())
		{
			var p = parent;
			unlink();
			p.prependNode(this);
		}
		
		return this;
	}
	
	/**
		Successively swaps this node with next siblings until it reached the tail of the sibling list.
		<o>1</o>
		@return this node.
	**/
	public function setLast():TreeNode<T>
	{
		if (hasSiblings())
		{
			var p = parent;
			unlink();
			p.appendNode(this);
		}
		
		return this;
	}
	
	/**
		Recursively finds the first occurrence of the node storing the element `x` in this tree.
		<o>n</o>
		@return the node storing the element `x` or null if such a node does not exist.
	**/
	public function find(x:T):TreeNode<T>
	{
		var top = this;
		while (top != null)
		{
			var node = top;
			top = popOffStack(top);
			if (node.val == x)
				return node;
			var n = node.children;
			if (n != null)
			{
				var c = node.mTail;
				while (c != null)
				{
					top = pushOnStack(top, c);
					c = c.prev;
				}
			}
		}
		
		return null;
	}
	
	/**
		Performs a recursive preorder traversal.
		
		A preorder traversal performs the following steps:
		
		1. Visit the node
		2. Traverse the left subtree of the node
		3. Traverse the right subtree of the node
		
		@param process a function that is invoked on every traversed node.
		The first argument holds a reference to the current node, the second arguments stores the preflight flag and the third argument stores custom data specified by the `userData` parameter (default is null).
		Once `process` returns false, the traversal stops immediately and no further nodes are examined.
		If omitted, ``element::visit()`` is used instead.
		@param userData custom data that is passed to every visited node via `process` or ``element::visit()``.
		@param preflight if true, an extra traversal is performed before the actual traversal runs.
		The first pass visits all elements and calls ``element::visit()`` with the `preflight` parameter set to true.
		In this pass the return value determines whether the element (and all its children) will be processed (true) or
		excluded (false) from the final traversal, which is the second pass (`preflight` parameter set to false).
		The same applies when using a `process` function.
		<warn>In this case all elements have to implement `Visitable`.</warn>
		@param iterative if true, an iterative traversal is used (default traversal style is recursive).
		@return this node.
	**/
	public function preorder(process:TreeNode<T>->Bool->Dynamic->Bool, userData:Dynamic, preflight:Bool = false, iterative:Bool = false):TreeNode<T>
	{
		inline function asVisitable(value:Dynamic):Visitable
		{
			return
			#if flash
			flash.Lib.as(value, Visitable);
			#else
			
			#if (cpp && generic)
			cast(value, Visitable);
			#else
			cast value;
			#end
			#end
		}
		
		if (parent == null && children == null)
		{
			if (process == null)
			{
				assert(Std.is(val, Visitable), "element is not of type Visitable");
				
				var v = asVisitable(val);
				if (preflight)
				{
					if (v.visit(true, userData))
						v.visit(false, userData);
				}
				else
					v.visit(false, userData);
			}
			else
			{
				if (preflight)
				{
					if (process(this, true, userData))
						process(this, false, userData);
				}
				else
					process(this, false, userData);
			}
			return this;
		}
		
		if (iterative == false)
		{
			if (process == null)
			{
				assert(Std.is(val, Visitable), "element is not of type Visitable");
				
				if (preflight)
				{
					var v = asVisitable(val);
					
					if (v.visit(true, userData))
					{
						if (v.visit(false, userData))
						{
							var child = children, hook;
							while (child != null)
							{
								hook = child.next;
								if (!preOrderInternalVisitablePreflight(child, userData)) return this;
								child = hook;
							}
						}
					}
				}
				else
				{
					var v = asVisitable(val);
					if (v.visit(false, userData))
					{
						var child = children, hook;
						while (child != null)
						{
							hook = child.next;
							if (!preOrderInternalVisitable(child, userData)) return this;
							child = hook;
						}
					}
				}
			}
			else
			{
				if (preflight)
				{
					if (process(this, true, userData))
					{
						if (process(this, false, userData))
						{
							var child = children, hook;
							while (child != null)
							{
								hook = child.next;
								if (!preOrderInternalPreflight(child, process, userData)) return this;
								child = hook;
							}
						}
					}
				}
				else
				{
					if (process(this, false, userData))
					{
						var child = children, hook;
						while (child != null)
						{
							hook = child.next;
							if (!preOrderInternal(child, process, userData)) return this;
							child = hook;
						}
					}
				}
			}
		}
		else
		{
			var top = this;
			
			assert(mPrevInStack == null);
			assert(mNextInStack == null);
			
			if (process == null)
			{
				if (preflight)
				{
					while (top != null)
					{
						var node = top;
						#if debug
						if (node != null)
							assert(node.mNextInStack == null);
						#end
						
						top = popOffStack(top);
						
						#if debug
						if (top != null)
							assert(top.mNextInStack == null);
						#end
						
						assert(Std.is(node.val, Visitable), "element is not of type Visitable");
						
						var v = asVisitable(node.val);
						
						if (!v.visit(true, userData)) continue;
						if (!v.visit(false, userData)) return this;
						
						var n = node.children;
						if (n != null)
						{
							var c = node.mTail;
							while (c != null)
							{
								#if debug
								if (top != null)
									assert(top.mNextInStack == null);
								#end
								
								top = pushOnStack(top, c);
								
								#if debug
								if (top != null)
									assert(top.mNextInStack == null);
								#end
								
								c = c.prev;
							}
						}
					}
				}
				else
				{
					while (top != null)
					{
						var node = top;
						top = popOffStack(top);
						
						assert(Std.is(node.val, Visitable), "element is not of type Visitable");
						
						var v = asVisitable(node.val);
						if (!v.visit(false, userData)) return this;
						
						var n = node.children;
						if (n != null)
						{
							var c = node.mTail;
							while (c != null)
							{
								top = pushOnStack(top, c);
								c = c.prev;
							}
						}
					}
				}
			}
			else
			{
				if (preflight)
				{
					while (top != null)
					{
						var node = top;
						top = popOffStack(top);
						
						if (!process(node, true, userData)) continue;
						if (!process(node, false, userData)) return this;
						
						var n = node.children;
						if (n != null)
						{
							var c = node.mTail;
							while (c != null)
							{
								top = pushOnStack(top, c);
								c = c.prev;
							}
						}
					}
				}
				else
				{
					while (top != null)
					{
						var node = top;
						top = popOffStack(top);
						
						if (!process(node, false, userData)) return this;
						var n = node.children;
						if (n != null)
						{
							var c = node.mTail;
							while (c != null)
							{
								top = pushOnStack(top, c);
								c = c.prev;
							}
						}
					}
				}
			}
		}
		
		return this;
	}
	
	/**
		Performs a recursive postorder traversal.
		A postorder traversal performs the following steps:
		
		1. Traverse the left subtree of the node
		2. Traverse the right subtree of the node
		3. Visit the node
		
		@param process a function that is invoked on every traversed node.
		The first argument holds a reference to the current node, while the second argument stores custom data specified by the `userData` parameter (default is null).
		Once `process` returns false, the traversal stops immediately and no further nodes are examined.
		If omitted, ``element::visit()`` is used instead.
		<warn>In this case all elements have to implement `Visitable`.</warn>
		@param userData custom data that is passed to every visited node via `process` or ``element::visit()``.
		@param iterative if true, an iterative traversal is used (default traversal style is recursive).
		@return this node.
	**/
	public function postorder(process:TreeNode<T>->Dynamic->Bool, userData:Dynamic, iterative = false):TreeNode<T>
	{
		if (parent == null && children == null)
		{
			if (process == null)
			{
				assert(Std.is(val, Visitable), "element is not of type Visitable");
				
				cast(val, Visitable).visit(false, userData);
			}
			else
				process(this, userData);
			return this;
		}
		
		if (iterative == false)
		{
			if (process == null)
			{
				var child = children, hook;
				while (child != null)
				{
					hook = child.next;
					if (!postOrderInternalVisitable(child, userData)) return this;
					child = hook;
				}
				
				assert(Std.is(val, Visitable), "element is not of type Visitable");
				
				cast(val, Visitable).visit(false, userData);
			}
			else
			{
				var child = children, hook;
				while (child != null)
				{
					hook = child.next;
					if (!postOrderInternal(child, process, userData)) return this;
					child = hook;
				}
				process(this, userData);
			}
		}
		else
		{
			#if debug
			assert(mBusy == false, "recursive call to iterative postorder");
			mBusy = true;
			#end
			
			var time = getTimeStamp() + 1;
			var top = this;
			
			if (process == null)
			{
				while (top != null)
				{
					var node = top;
					if (node.hasChildren())
					{
						var found = false;
						var c = node.mTail;
						while (c != null)
						{
							if (c.getTimeStamp() < time)
							{
								c.incTimeStamp();
								top = pushOnStack(top, c);
								
								found = true;
							}
							c = c.prev;
						}
						
						if (!found)
						{
							assert(Std.is(node.val, Visitable), "element is not of type Visitable");
							
							var v = cast(node.val, Visitable);
							if (!v.visit(false, userData))
							{
								#if debug
								mBusy = false;
								#end
								return this;
							}
							top = popOffStack(top);
						}
					}
					else
					{
						assert(Std.is(node.val, Visitable), "element is not of type Visitable");
						
						var v = cast(node.val, Visitable);
						if (!v.visit(false, userData))
						{
							#if debug
							mBusy = false;
							#end
							return this;
						}
						node.incTimeStamp();
						top = popOffStack(top);
					}
				}
			}
			else
			{
				while (top != null)
				{
					//var node = stack[top - 1];
					var node = top;
					
					if (node.hasChildren())
					{
						var found = false;
						var c = node.mTail;
						while (c != null)
						{
							if (c.getTimeStamp() < time)
							{
								c.incTimeStamp();
								top = pushOnStack(top, c);
								found = true;
							}
							c = c.prev;
						}
						
						if (!found)
						{
							if (!process(node, userData))
							{
								#if debug
								mBusy = false;
								#end
								return this;
							}
							top = popOffStack(top);
						}
					}
					else
					{
						if (!process(node, userData))
						{
							#if debug
							mBusy = false;
							#end
							return this;
						}
						node.incTimeStamp();
						top = popOffStack(top);
					}
				}
			}
			#if debug
			mBusy = false;
			#end
		}
		
		return this;
	}
	
	/**
		Performs a queue-based, iterative level-order traversal.
		In a level-order traversal all nodes of a tree are processed by depth: first the root, then the children of the root, etc.
		@param process a function that is invoked on every traversed node.
		The first argument holds a reference to the current node, while the second argument stores custom data specified by the `userData` parameter (default is null).
		Once `process` returns false, the traversal stops immediately and no further nodes are examined.
		If omitted, ``element::visit()`` is used instead.
		<warn>In this case all elements have to implement `Visitable`.</warn>
		@param userData custom data that is passed to every visited node via `process` or ``element::visit()``.
		@return this node.
	**/
	public function levelorder(process:TreeNode<T>->Dynamic->Bool, userData:Dynamic):TreeNode<T>
	{
		if (children == null)
		{
			if (process == null)
			{
				assert(Std.is(val, Visitable), "element is not of type Visitable");
				
				cast(val, Visitable).visit(false, userData);
			}
			else
				process(this, userData);
			return this;
		}
		
		var i = 0;
		var s = 1;
		var child;
		var nodeHead = this;
		var nodeTail = this;
		nodeHead.mNextInStack = null;
		
		if (process == null)
		{
			while (i < s)
			{
				i++;
				
				assert(Std.is(nodeHead.val, Visitable), "element is not of type Visitable");
				
				if (!cast(nodeHead.val, Visitable).visit(false, userData))
					return this;
				
				child = nodeHead.children;
				while (child != null)
				{
					s++;
					nodeTail = nodeTail != null ? nodeTail.mNextInStack = child : child;
					child = child.next;
				}
				nodeHead = nodeHead.mNextInStack;
			}
		}
		else
		{
			while (i < s)
			{
				i++;
				
				if (!process(nodeHead, userData))
					return this;
				
				child = nodeHead.children;
				while (child != null)
				{
					s++;
					nodeTail = nodeTail != null ? nodeTail.mNextInStack = child : child;
					child = child.next;
				}
				nodeHead = nodeHead.mNextInStack;
			}
		}
		
		return this;
	}
	
	/**
		Sorts the children of this node using the merge sort algorithm.
		<o>n log n for merge sort and n&sup2; for insertion sort</o>
		<assert>element does not implement `Comparable`</assert>
		@param compare a comparison function.
		If null, the elements are compared using element.`compare()`.
		<warn>In this case all elements have to implement `Comparable`.</warn>
		@param useInsertionSort if true, the dense array is sorted using the insertion sort algorithm.
		This is faster for nearly sorted lists.
		@return this node.
	**/
	public function sort(compare:T->T->Int, useInsertionSort = false):TreeNode<T>
	{
		if (hasChildren())
		{
			if (compare == null)
				children = useInsertionSort ? insertionSortComparable(children) : mergeSortComparable(children);
			else
				children = useInsertionSort ? insertionSort(children, compare) : mergeSort(children, compare);
		}
		
		return this;
	}
	
	/**
		Returns a string representing the current object.
		
		Example:
		<pre class="prettyprint">
		var root = new de.polygonal.ds.TreeNode<Int>(0); //create the root of the tree
		var builder = new de.polygonal.ds.TreeBuilder<Int>(root);
		builder.appendChild(1);
		builder.down();
		builder.appendChild(2);
		builder.up();
		builder.appendChild(3);
		trace(root);</pre>
		<pre class="console">
		{TreeNode (root), children: 2, depth:0, value: 0}
		+---{TreeNode (child), children: 1, depth:1, value: 1}
		|   +---{TreeNode (leaf+child), depth:2, value: 2}
		+---{TreeNode (leaf+child), depth:1, value: 3}</pre>
	**/
	public function toString():String
	{
		if (children == null)
			return '{ TreeNode ${print()} }';
		
		var s = "";
		preorder(function(node:TreeNode<T>, preflight:Bool, userData:Dynamic):Bool
		{
			var d = node.depth();
			for (i in 0...d)
			{
				if (i == d - 1)
					s += "+--- ";
				else
					s += "|    ";
			}
			s += "{ " + node.print() + " }\n";
			return true;
		}, null);
		return s;
	}
	
	/**
		Creates and returns a ``TreeBuilder`` object pointing to this node.
		<o>1</o>
	**/
	public function getBuilder():TreeBuilder<T>
	{
		return new TreeBuilder<T>(this);
	}
	
	/**
		Returns a new ``ChildTreeIterator`` object to iterate over all direct children (excluding this node).
		
		<warn>In contrast to ``iterator()``, this method is not recursive.</warn>
		
		See <a href="http://haxe.org/ref/iterators" target="mBlank">http://haxe.org/ref/iterators</a>
	**/
	public function childIterator():Itr<T>
	{
		return new ChildTreeIterator<T>(this);
	}
	
	function print():String
	{
		var flags = "";
		if (isRoot())  flags += ", root";
		if (isLeaf())  flags += ", leaf";
		if (isChild()) flags += ", child";
		return 'val: $val, children: ${numChildren()}, depth: ${depth()}$flags';
	}
	
	function preOrderInternal(node:TreeNode<T>, process:TreeNode<T>->Bool->Dynamic->Bool, userData:Dynamic):Bool
	{
		if (process(node, false, userData))
		{
			if (node.hasChildren())
			{
				var walker = node.children;
				while (walker != null)
				{
					if (!preOrderInternal(walker, process, userData)) return false;
					walker = walker.next;
				}
			}
			return true;
		}
		return false;
	}
	
	function preOrderInternalPreflight(node:TreeNode<T>, process:TreeNode<T>->Bool->Dynamic->Bool, userData:Dynamic):Bool
	{
		if (process(node, true, userData))
		{
			if (process(node, false, userData))
			{
				if (node.hasChildren())
				{
					var walker = node.children;
					while (walker != null)
					{
						if (!preOrderInternalPreflight(walker, process, userData)) return false;
						walker = walker.next;
					}
				}
				return true;
			}
		}
		return false;
	}
	
	function preOrderInternalVisitable(node:TreeNode<T>, userData:Dynamic):Bool
	{
		assert(Std.is(node.val, Visitable), "element is not of type Visitable");
		
		inline function asVisitable(value:Dynamic):Visitable
		{
			return
			#if flash
			flash.Lib.as(value, Visitable);
			#else
			
			#if (cpp && generic)
			cast(value, Visitable);
			#else
			cast value;
			#end
			#end
		}
		
		var v = asVisitable(node.val);
		if (v.visit(false, userData))
		{
			if (node.hasChildren())
			{
				var walker = node.children, hook;
				while (walker != null)
				{
					hook = walker.next;
					if (!preOrderInternalVisitable(walker, userData)) return false;
					walker = hook;
				}
			}
			return true;
		}
		return false;
	}
	
	function preOrderInternalVisitablePreflight(node:TreeNode<T>, userData:Dynamic):Bool
	{
		assert(Std.is(node.val, Visitable), "element is not of type Visitable");
		
		inline function asVisitable(value:Dynamic):Visitable
		{
			return
			#if flash
			flash.Lib.as(value, Visitable);
			#else
			
			#if (cpp && generic)
			cast(value, Visitable);
			#else
			cast value;
			#end
			#end
		}
		
		var v = asVisitable(node.val);
		if (v.visit(true, userData))
		{
			if (v.visit(false, userData))
			{
				if (node.hasChildren())
				{
					var walker = node.children, hook;
					while (walker != null)
					{
						hook = walker.next;
						if (!preOrderInternalVisitablePreflight(walker, userData)) return false;
						walker = hook;
					}
				}
				return true;
			}
		}
		return false;
	}
	
	function postOrderInternal(node:TreeNode<T>, process:TreeNode<T>->Dynamic->Bool, userData:Dynamic):Bool
	{
		if (node.hasChildren())
		{
			var walker = node.children, hook;
			while (walker != null)
			{
				hook = walker.next;
				if (!postOrderInternal(walker, process, userData)) return false;
				walker = hook;
			}
		}
		return process(node, userData);
	}
	
	function postOrderInternalVisitable(node:TreeNode<T>, userData:Dynamic):Bool
	{
		if (node.hasChildren())
		{
			var walker = node.children, hook;
			while (walker != null)
			{
				hook = walker.next;
				if (!postOrderInternalVisitable(walker, userData)) return false;
				walker = hook;
			}
		}
		
		assert(Std.is(node.val, Visitable), "element is not of type Visitable");
		
		return cast(node.val, Visitable).visit(false, userData);
	}
	
	function insertionSortComparable(node:TreeNode<T>):TreeNode<T>
	{
		var h = node;
		var n = h.next;
		while (valid(n))
		{
			var m = n.next;
			var p = n.prev;
			var v = n.val;
			
			assert(Std.is(p.val, Comparable), 'element is not of type Comparable (${p.val})');
			
			if (cast(p.val, Comparable<Dynamic>).compare(v) < 0)
			{
				var i = p;
				
				while (i.hasPrevSibling())
				{
					assert(Std.is(i.prev.val, Comparable), 'element is not of type Comparable (${i.prev.val})');
					
					if (cast(i.prev.val, Comparable<Dynamic>).compare(v) < 0)
						i = i.prev;
					else
						break;
				}
				if (valid(m))
				{
					p.next = m;
					m.prev = p;
				}
				else
				{
					p.next = null;
					mTail = p;
				}
				
				if (i == h)
				{
					n.prev = null;
					n.next = i;
					
					i.prev = n;
					h = n;
				}
				else
				{
					n.prev = i.prev;
					i.prev.next = n;
					
					n.next = i;
					i.prev = n;
				}
			}
			n = m;
		}
		
		return h;
	}
	
	function insertionSort(node:TreeNode<T>, cmp:T->T->Int):TreeNode<T>
	{
		var h = node;
		var n = h.next;
		while (valid(n))
		{
			var m = n.next;
			var p = n.prev;
			var v = n.val;
			
			if (cmp(v, p.val) < 0)
			{
				var i = p;
				
				while (i.hasPrevSibling())
				{
					if (cmp(v, i.prev.val) < 0)
						i = i.prev;
					else
						break;
				}
				if (valid(m))
				{
					p.next = m;
					m.prev = p;
				}
				else
				{
					p.next = null;
					mTail = p;
				}
				
				if (i == h)
				{
					n.prev = null;
					n.next = i;
					
					i.prev = n;
					h = n;
				}
				else
				{
					n.prev = i.prev;
					i.prev.next = n;
					
					n.next = i;
					i.prev = n;
				}
			}
			n = m;
		}
		
		return h;
	}
	
	function mergeSortComparable(node:TreeNode<T>):TreeNode<T>
	{
		var h = node;
		var p, q, e, tail = null;
		var insize = 1;
		var nmerges, psize, qsize, i;
		
		while (true)
		{
			p = h;
			h = tail = null;
			nmerges = 0;
			
			while (valid(p))
			{
				nmerges++;
				
				psize = 0; q = p;
				for (i in 0...insize)
				{
					psize++;
					q = q.next;
					if (q == null) break;
				}
				
				qsize = insize;
				
				while (psize > 0 || (qsize > 0 && valid(q)))
				{
					if (psize == 0)
					{
						e = q; q = q.next; qsize--;
					}
					else
					if (qsize == 0 || q == null)
					{
						e = p; p = p.next; psize--;
					}
					else
					{
						assert(Std.is(p.val, Comparable), 'element is not of type Comparable (${p.val})');
						
						if (cast(p.val, Comparable<Dynamic>).compare(q.val) >= 0)
						{
							e = p; p = p.next; psize--;
						}
						else
						{
							e = q; q = q.next; qsize--;
						}
					}
					
					if (valid(tail))
						tail.next = e;
					else
						h = e;
					
					e.prev = tail;
					tail = e;
				}
				p = q;
			}
			
			tail.next = null;
			if (nmerges <= 1) break;
			insize <<= 1;
		}
		
		h.prev = null;
		mTail = tail;
		
		return h;
	}
	
	function mergeSort(node:TreeNode<T>, cmp:T->T->Int):TreeNode<T>
	{
		var h = node;
		var p, q, e, tail = null;
		var insize = 1;
		var nmerges, psize, qsize, i;
		
		while (true)
		{
			p = h;
			h = tail = null;
			nmerges = 0;
			
			while (valid(p))
			{
				nmerges++;
				
				psize = 0; q = p;
				for (i in 0...insize)
				{
					psize++;
					q = q.next;
					if (q == null) break;
				}
				
				qsize = insize;
				
				while (psize > 0 || (qsize > 0 && valid(q)))
				{
					if (psize == 0)
					{
						e = q; q = q.next; qsize--;
					}
					else
					if (qsize == 0 || q == null)
					{
						e = p; p = p.next; psize--;
					}
					else
					if (cmp(q.val, p.val) >= 0)
					{
						e = p; p = p.next; psize--;
					}
					else
					{
						e = q; q = q.next; qsize--;
					}
					
					if (valid(tail))
						tail.next = e;
					else
						h = e;
					
					e.prev = tail;
					tail = e;
				}
				p = q;
			}
			
			tail.next = null;
			if (nmerges <= 1) break;
			insize <<= 1;
		}
		
		h.prev = null;
		this.mTail = tail;
		
		return h;
	}
	
	inline function valid(node:TreeNode<T>):Bool
	{
		return node != null;
	}
	
	inline function findHead(node:TreeNode<T>):TreeNode<T>
	{
		if (node.parent != null)
			return node.parent.children;
		else
		{
			while (node.prev != null)
				node = node.prev;
			return node;
		}
	}
	
	inline function findTail(node:TreeNode<T>):TreeNode<T>
	{
		if (node.parent != null)
			return node.parent.mTail;
		else
		{
			var t = node;
			while (t.next != null) t = t.next;
			return t;
		}
	}
	
	/**
		Serializes this tree.
		
		The tree can be rebuild by calling ``unserialize()``.
		
		See <a href="http://eli.thegreenplace.net/2011/09/29/an-interesting-tree-serialization-algorithm-from-dwarf/" target="mBlank">An interesting tree serialization algorithm from DWARF</a>
		@param node the root of the tree.
		@return a flattened tree.
	**/
	public function serialize(node:TreeNode<T> = null, list:Array<{v: T, c:Bool}> = null):Array<{v: T, c:Bool}>
	{
		if (node == null) node = this;
		if (list == null) list = new Array<{v: T, c:Bool}>();
		
		if (node.children != null)
		{
			list.push({v: node.val, c: true});
			var c = node.children;
			while (c != null)
			{
				serialize(c, list);
				c = c.next;
			}
			list.push(null);
		}
		else
			list.push({v: node.val, c: false});
		
		return list;
	}
	
	/**
		Unserializes a given `list` into a TreeNode structure.
		
		First create a dummy node which will be the root of the unserialized tree, then call ``unserialize()``.
		
		Example:
		<pre class="prettyprint">
		var root = new de.polygonal.ds.TreeNode<String>(null);
		root.unserialize(mySerializedTree);
		</pre>
		@param list the flattened tree
		@return the root of the tree.
	**/
	public function unserialize(list:Array<{v: T, c:Bool}>):TreeNode<T>
	{
		var root = this;
		root.val = list[0].v;
		var parentStack:Array<TreeNode<T>> = [root];
		var s = 1;
		
		for (i in 1...list.length)
		{
			var item = list[i];
			if (item != null)
			{
				var node = new TreeNode<T>(item.v);
				parentStack[s - 1].appendNode(node);
				if (item.c) parentStack[s++] = node;
			}
			else
				s--;
		}
		
		return root;
	}
	
	/*///////////////////////////////////////////////////////
	// collection
	///////////////////////////////////////////////////////*/
	
	/**
		Destroys this object by explicitly nullifying all nodes, pointers and elements for GC'ing used resources.
		
		Improves GC efficiency/performance (optional).
		<o>n</o>
	**/
	public function free()
	{
		if (hasChildren())
		{
			var n = children;
			while (n != null)
			{
				var next = n.next;
				n.free();
				n = next;
			}
		}
		
		val = cast null;
		prev = null;
		next = null;
		children = null;
		parent = null;
		mTail = null;
		mNextInStack = null;
		mPrevInStack = null;
	}
	
	/**
		Returns true if this tree contains the element `x`.
		<o>n</o>
	**/
	public function contains(x:T):Bool
	{
		var top = this;
		while (top != null)
		{
			var node = top;
			top = popOffStack(top);
			if (node.val == x) return true;
			var n = node.children;
			if (n != null)
			{
				var c = node.mTail;
				while (c != null)
				{
					top = pushOnStack(top, c);
					c = c.prev;
				}
			}
		}
		
		return false;
	}
	
	/**
		Runs a recursive preorder traversal that removes all nodes storing the element `x`.
		
		Tree nodes are not rearranged, so if a node stores `x`, the complete subtree rooted at that node is unlinked.
		<o>n</o>
		@return true if at least one occurrence of `x` was removed.
	**/
	public function remove(x:T):Bool
	{
		var found = false;
		if (val == x)
		{
			unlink();
			found = true;
		}
		
		var child = children;
		while (child != null)
		{
			var next = child.next;
			found = found || child.remove(x);
			child = next;
		}
		
		return found;
	}
	
	/**
		Removes all child nodes.
		<o>1 or n if `purge` is true</o>
		@param purge if true, recursively nullifies this subtree.
	**/
	public function clear(purge = false)
	{
		if (purge)
		{
			var node = children;
			while (valid(node))
			{
				var hook = node.next;
				node.prev = null;
				node.next = null;
				node.clear(purge);
				node = hook;
			}
			
			val = cast null;
			parent = null;
			children = null;
			mTail = null;
		}
		else
			children = null;
		setChildCount(0);
	}
	
	/**
		Returns a new ``TreeIterator`` object to iterate over all elements contained in the nodes of this subtree (including this node).
		
		The elements are visited by using a preorder traversal.
		
		See <a href="http://haxe.org/ref/iterators" target="mBlank">http://haxe.org/ref/iterators</a>
	**/
	public function iterator():Itr<T>
	{
		return new TreeIterator<T>(this);
	}
	
	/**
		The total number of nodes in the tree rooted at this node.
		<o>n</o>
	**/
	public function size():Int
	{
		var c = 1;
		var node = children;
		while (valid(node))
		{
			c += node.size();
			node = node.next;
		}
		return c;
	}
	
	/**
		Returns true if this tree is empty.
		<o>1</o>
	**/
	public function isEmpty():Bool
	{
		return !hasChildren();
	}
	
	/**
		Returns an array containing all elements in the tree rooted at this node.
		
		The elements are collected using a preorder traversal.
	**/
	public function toArray():Array<T>
	{
		var a:Array<T> = ArrayUtil.alloc(size());
		var i = 0;
		preorder(function(node:TreeNode<T>, _, _):Bool { a[i++] = node.val; return true; }, null);
		return a;
	}
	
	/**
		Returns a `Vector<T>` object containing all elements in the tree rooted at this node.
		
		The elements are collected using a preorder traversal.
	**/
	public function toVector():Vector<T>
	{
		var v = new Vector<T>(size());
		var i = 0;
		preorder(function(node:TreeNode<T>, _, _):Bool { v[i++] = node.val; return true; }, null);
		return v;
	}
	
	/**
		Duplicates this subtree. Supports shallow (structure only) and deep copies (structure & elements).
		<assert>element is not of type `Cloneable`</assert>
		@param assign if true, the `copier` parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.
		If false, the ``clone()`` method is called on each element. <warn>In this case all elements have to implement `Cloneable`.</warn>
		@param copier a custom function for copying elements. Replaces ``element::clone()`` if `assign` is false.
	**/
	public function clone(assign = true, copier:T->T = null):Collection<T>
	{
		var stack = new Array<TreeNode<T>>();
		var copy = new TreeNode<T>(copier != null ? copier(val) : val);
		
		stack[0] = this;
		stack[1] = copy;
		var i = 2;
		while (i > 0)
		{
			var c = stack[--i];
			var n = stack[--i];
			
			c.setChildCount(n.numChildren());
			
			if (n.hasChildren())
			{
				var nchild = n.children;
				
				var x:T;
				if (assign)
					x = nchild.val;
				else
				if (copier == null)
				{
					assert(Std.is(nchild.val, Cloneable), "element is not of type Cloneable ({nchild.val})");
					
					x = cast(nchild.val, Cloneable<Dynamic>).clone();
				}
				else
					x = copier(nchild.val);
				
				var cchild = c.children = new TreeNode<T>(x, c);
				
				stack[i++] = nchild;
				stack[i++] = cchild;
				
				nchild = nchild.next;
				while (nchild != null)
				{
					var x:T;
					if (assign)
						x = nchild.val;
					else
					if (copier == null)
					{
						x = cast(nchild.val, Cloneable<Dynamic>).clone();
					}
					else
						x = copier(nchild.val);
					
					cchild.next = new TreeNode<T>(x, c);
					cchild = cchild.next;
					
					c.mTail = cchild;
					
					stack[i++] = nchild;
					stack[i++] = cchild;
					
					nchild = nchild.next;
				}
			}
		}
		return copy;
	}
	
	inline function popOffStack(top:TreeNode<T>):TreeNode<T>
	{
		var tmp = top;
		top = top.mPrevInStack;
		if (top != null) top.mNextInStack = null;
		tmp.mPrevInStack = null;
		return top;
	}
	
	inline function pushOnStack(top:TreeNode<T>, x:TreeNode<T>):TreeNode<T>
	{
		if (top != null)
		{
			top.mNextInStack = x;
			x.mPrevInStack = top;
		}
		return x;
	}
	
	inline function incChildCount()
	{
		mExtraInfo = (mExtraInfo & 0x0000FFFF) | ((numChildren() + 1) << 16);
	}
	
	inline function decChildCount()
	{
		mExtraInfo = (mExtraInfo & 0x0000FFFF) | ((numChildren() - 1) << 16);
	}
	
	inline function setChildCount(x:Int)
	{
		mExtraInfo = (mExtraInfo & 0x0000FFFF) | (x << 16);
	}
	
	inline function setTimeStamp(x:Int)
	{
		mExtraInfo = (mExtraInfo & 0xFFFF0000) | x;
	}
	
	inline function getTimeStamp():Int
	{
		return mExtraInfo & 0xFFFF;
	}
	
	inline function incTimeStamp()
	{
		mExtraInfo = (mExtraInfo & 0xFFFF0000) | (getTimeStamp() + 1);
	}
}

#if generic
@:generic
#end
@:dox(hide)
class TreeIterator<T> implements de.polygonal.ds.Itr<T>
{
	var mNode:TreeNode<T>;
	var mStack:Array<TreeNode<T>>;
	var mTop:Int;
	var mC:Int;
	
	public function new(node:TreeNode<T>)
	{
		mNode = node;
		mStack = new Array<TreeNode<T>>();
		reset();
	}
	
	inline public function reset():Itr<T>
	{
		mStack[0] = mNode;
		mTop = 1;
		mC = 0;
		return this;
	}
	
	inline public function hasNext():Bool
	{
		return mTop > 0;
	}
	
	inline public function next():T
	{
		var node = mStack[--mTop];
		var walker = node.children;
		mC = 0;
		while (walker != null)
		{
			mStack[mTop++] = walker;
			mC++;
			walker = walker.next;
		}
		return node.val;
	}
	
	inline public function remove()
	{
		mTop -= mC;
	}
}

#if generic
@:generic
#end
@:dox(hide)
class ChildTreeIterator<T> implements de.polygonal.ds.Itr<T>
{
	var mF:TreeNode<T>;
	var mWalker:TreeNode<T>;
	var mHook:TreeNode<T>;
	
	public function new(f:TreeNode<T>)
	{
		mF = f;
		reset();
	}
	
	inline public function reset():Itr<T>
	{
		mWalker = mF.children;
		mHook = null;
		return this;
	}
	
	inline public function hasNext():Bool
	{
		return mWalker != null;
	}
	
	inline public function next():T
	{
		var x = mWalker.val;
		mHook = mWalker;
		mWalker = mWalker.next;
		return x;
	}
	
	inline public function remove()
	{
		assert(mHook != null, "call next() before removing an element");
		
		mHook.unlink();
	}
}