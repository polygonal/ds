/*
 *                            _/                                                    _/
 *       _/_/_/      _/_/    _/  _/    _/    _/_/_/    _/_/    _/_/_/      _/_/_/  _/
 *      _/    _/  _/    _/  _/  _/    _/  _/    _/  _/    _/  _/    _/  _/    _/  _/
 *     _/    _/  _/    _/  _/  _/    _/  _/    _/  _/    _/  _/    _/  _/    _/  _/
 *    _/_/_/      _/_/    _/    _/_/_/    _/_/_/    _/_/    _/    _/    _/_/_/  _/
 *   _/                            _/        _/
 *  _/                        _/_/      _/_/
 *
 * POLYGONAL - A HAXE LIBRARY FOR GAME DEVELOPERS
 * Copyright (c) 2009 Michael Baczynski, http://www.polygonal.de
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */
package de.polygonal.ds;

import de.polygonal.core.fmt.Sprintf;
import de.polygonal.core.util.Assert;

using de.polygonal.core.math.Mathematics;

/**
 * <p>A tree structure.</p>
 * <p>See <a href="http://lab.polygonal.de/?p=184" target="_blank">http://lab.polygonal.de/?p=184</a></p>
 * <p><o>Worst-case running time in Big O notation</o></p>
 */
#if generic
@:generic
#end
class TreeNode<T> implements Collection<T>
{
	/**
	 * A unique identifier for this object.<br/>
	 * A hash table transforms this key into an index of an array element by using a hash function.<br/>
	 * <warn>This value should never be changed by the user.</warn>
	 */
	public var key:Int;
	
	/**
	 * The node's data.
	 */
	public var val:T;
	
	/**
	 * The node's parent or null if this node is a root node.
	 */
	public var parent:TreeNode<T>;
	
	/**
	 * The node's children or null if this node has no children.<br/>
	 * This is a doubly linked list of <em>TreeNode</em> objects and <em>children</em> points to the first child.<br/>
	 */
	public var children:TreeNode<T>;
	
	/**
	 * The node's previous sibling or null if such a sibling does not exist.
	 */
	public var prev:TreeNode<T>;
	
	/**
	 * The node's next sibling or null if such a sibling does not exist.
	 */
	public var next:TreeNode<T>;
	
	var _tail:TreeNode<T>;
	var _numChildren:Int;
	var _timestamp:Int;
	var _stack:Array<TreeNode<T>>;
	
	#if debug
	var _busy:Bool;
	#end
	
	/**
	 * Creates a <em>TreeNode</em> object storing the element <code>x</code>.<br/>
	 * @param x the element to store in this node.
	 * @param parent if specified, this node is appended to the children of <em>parent</em>.
	 */
	public function new(x:T, parent:TreeNode<T> = null)
	{
		this.val = x;
		this.parent = parent;
		
		children = null;
		prev     = null;
		next     = null;
		_tail    = null;
		_stack   = null;
		
		if (hasParent())
		{
			parent._numChildren++;
			
			if (parent.hasChildren())
			{
				var tail = parent.getLastChild();
				tail.next = this;
				this.prev = tail;
				next = null;
			}
			else
				parent.children = this;
			
			parent._tail = this;
		}
		
		_numChildren = 0;
		_timestamp = 0;
		
		#if debug
		_busy = false;
		#end
		
		key = HashKey.next();
	}
	
	/**
	 * Returns true if this node is the root node of this tree.<br/>
	 * A root node has no parent node.
	 * <o>1</o>
	 */
	inline public function isRoot():Bool
	{
		return parent == null;
	}
	
	/**
	 * Returns true if this node is a leaf node of this tree.<br/>
	 * A leaf node has no children.
	 * <o>1</o>
	 */
	inline public function isLeaf():Bool
	{
		return children == null;
	}
	
	/**
	 * Returns true is this node is a child node of this tree.<br/>
	 * A child node has a parent node.
	 * <o>1</o>
	 */
	inline public function isChild():Bool
	{
		return _valid(parent);
	}
	
	/**
	 * Returns true if this node is an ancestor of <code>x</code>.
	 */
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
	 * Returns true if this node is an descendant of <code>x</code>.
	 */
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
	 * Returns true if this node has a parent node.
	 * <o>1</o>
	 */
	inline public function hasParent():Bool
	{
		return isChild();
	}
	
	/**
	 * Returns true if this node has at least one child node.
	 * <o>1</o>
	 */
	inline public function hasChildren():Bool
	{
		return _valid(children);
	}
	
	/**
	 * Returns true if this node has at least one sibling.
	 * <o>1</o>
	 */
	inline public function hasSiblings():Bool
	{
		if (_valid(parent))
			return _valid(prev) || _valid(next);
		else
			return false;
	}
	
	/**
	 * Returns true if this node has a sibling to its right (<em>next</em> != null).
	 * <o>1</o>
	 */
	inline public function hasNextSibling():Bool
	{
		return _valid(next);
	}
	
	/**
	 * Returns true if this node has a sibling to its left (<em>prev</em> != null).
	 * <o>1</o>
	 */
	inline public function hasPrevSibling():Bool
	{
		return _valid(prev);
	}
	
	/**
	 * Returns the leftmost sibling of this node.
	 * <o>1</o>
	 */
	inline public function getFirstSibling():TreeNode<T>
	{
		return parent != null ? parent.children : null;
	}
	
	/**
	 * Returns the rightmost sibling of this node.
	 * <o>1</o>
	 */
	inline public function getLastSibling():TreeNode<T>
	{
		return parent != null ? parent._tail : null;
	}
	
	/**
	 * Returns the sibling index of this node.<br/>
	 * The first sibling equals index 0, the last sibling equals index <em>numChildren()</em> - 1.
	 * <o>n</o>
	 */
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
	 * Swaps the child <code>a</code> with child <code>b</code> by swapping their values.
	 * @throws de.polygonal.core.util.AssertError <code>a</code> and <code>b</code> are not siblings (debug only).
	 * @throws de.polygonal.core.util.AssertError <code>a</code> equals <code>b</code> (debug only).
	 * <o>1</o>
	 */
	public function swapChildren(a:TreeNode<T>, b:TreeNode<T>):Void
	{
		#if debug
		D.assert(a.parent == b.parent, 'a and b are not siblings');
		D.assert(a != b, 'a equals b');
		#end
		
		var tmp = a.val; a.val = b.val; b.val = tmp;
	}
	
	/**
	 * Swaps the child at index <code>i</code> with the child at index <code>j</code> by swapping their values.
	 * @throws de.polygonal.core.util.AssertError index <code>i</code> out of range (debug only).
	 * @throws de.polygonal.core.util.AssertError index <code>j</code> out of range (debug only).
	 * @throws de.polygonal.core.util.AssertError <code>i</code> equals <code>j</code> (debug only).
	 * <o>1</o>
	 */
	public function swapChildrenAt(i:Int, j:Int):Void
	{
		#if debug
		D.assert(i >= 0 && i < numChildren(), Sprintf.format('the index i (%d) is out of range %d', [i, numChildren()]));
		D.assert(j >= 0 && j < numChildren(), Sprintf.format('the index j (%d) is out of range %d', [j, numChildren()]));
		D.assert(i != j, 'index i equals index j');
		#end
		
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
					return;
				}
				t = n;
			}
			else
			if (j == c)
			{
				if (t != null)
				{
					swapChildren(n, t);
					return;
				}
				t = n;
			}
			c++;
			n = n.next;
		}
	}
	
	/**
	 * Removes the child at index <code>i</code>.
	 * @throws de.polygonal.core.util.AssertError index <code>i</code> is out of range (debug only).
	 * <o>n</o>
	 */
	public function removeChildAt(i:Int):Void
	{
		#if debug
		D.assert(i >= 0 && i < numChildren(), Sprintf.format('the index %d is out of range %d', [i, numChildren()]));
		#end
		
		var j = 0;
		var n = children;
		while (j < i)
		{
			n = n.next;
			j++;
		}
		
		n.unlink();
	}
	
	/**
	 * Removes <code>n</code> children starting at the specified index <code>i</code> in the range &#091;<code>i</code>, <code>i</code> + <code>n</code>&#093;.<br/>
	 * If <code>n</code> is -1, <code>n</code> is set to <code>numChildren()</code> - <code>i</code>.
	 * @throws de.polygonal.core.util.AssertError <code>i</code> or <code>n</code> out of range (debug only).
	 * <o>n</o>
	 */
	public function removeChildren(i = 0, n = -1):Void
	{
		if (n == -1) n = _numChildren - i;
		
		if (n == 0) return;
		
		#if debug
		D.assert(i >= 0 && i <= _numChildren, Sprintf.format('i index out of range (%d)', [i]));
		D.assert(n > 0 && n <= _numChildren && (i + n <= _numChildren), Sprintf.format('n out of range (%d)', [n]));
		#end
		
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
	}
	
	/**
	 * Changes the index of the child <code>x</code> to <code>i</code>.
	 * @throws de.polygonal.core.util.AssertError index <code>i</code> is out of range (debug only).
	 * <o>n</o>
	 */
	public function setChildIndex(x:TreeNode<T>, i:Int):Void
	{
		#if debug
		D.assert(i >= 0 && i < numChildren(), Sprintf.format('the index %d is out of range %d', [i, numChildren()]));
		#end
		
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
					return;
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
					return;
				}
			}
			j++;
			c = c.next;
		}
	}
	
	/**
	 * Assigns a reuses a stack for iterative preorder, postorder and levelorder traversals.<br/>
	 * <o>1</o>
	 */
	public function setStack(stack:Array<TreeNode<T>>):Void
	{
		_stack = stack;
	}
	
	/**
	 * The total number of child nodes (non-recursive).
	 * <o>1</o>
	 */
	inline public function numChildren():Int
	{
		return _numChildren;
	}
	
	/**
	 * Counts the total number of siblings (excluding this).
	 * <o>n</o>
	 */
	inline public function numSiblings():Int
	{
		if (hasParent())
			return parent._numChildren - 1;
		else
			return 0;
	}
	
	/**
	 * Counts the total number of preceding siblings (excluding this).
	 * <o>n</o>
	 */
	inline public function numPrevSiblings():Int
	{
		var c = 0;
		var node = prev;
		while (_valid(node))
		{
			c++;
			node = node.prev;
		}
		
		return c;
	}
	
	/**
	 * Counts the total number of succeeding siblings (excluding this).
	 * <o>n</o>
	 */
	inline public function numNextSiblings():Int
	{
		var c = 0;
		var node = next;
		while (_valid(node))
		{
			c++;
			node = node.next;
		}
		return c;
	}
	
	/**
	 * Calculates the depth of this node within this tree.<br/>
	 * The depth is defined as the length of the path from the root node to this node.<br/>
	 * The root node is at depth 0.
	 * <o>n</o>
	 */
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
	 * Calculates the height of this tree, assuming this is the root node of this tree.<br/>
	 * The height is defined as the length of the path from the root node to the deepest node in the tree.<br/>
	 * A tree with one node has a height of one.
	 * <o>n</o>
	 */
	public function height():Int
	{
		var h = 0;
		var node = children;
		while (node != null)
		{
			h = h.max(node.height());
			node = node.next;
		}
		return 1 + h;
	}
	
	/**
	 * Returns the root node of this tree.
	 * <o>n</o>
	 */
	inline public function getRoot():TreeNode<T>
	{
		var n = this;
		while (n.hasParent()) n = n.parent;
		return n;
	}
	
	/**
	 * Returns the leftmost child of this node or null if this node is a leaf node.
	 * <o>1</o>
	 */
	inline public function getFirstChild():TreeNode<T>
	{
		return children;
	}
	
	/**
	 * Returns the rightmost child of this node or null if this node is a leaf node.
	 * <o>1</o>
	 */
	inline public function getLastChild():TreeNode<T>
	{
		return _tail;
	}
	
	/**
	 * Returns the child at index <code>i</code> or null if the node has no children.
	 * @throws de.polygonal.core.util.AssertError child index out of range (debug only).
	 * <o>n</o>
	 */
	inline public function getChildAt(i:Int):TreeNode<T>
	{
		if (hasChildren())
		{
			#if debug
			D.assert(i >= 0 && i < numChildren(), Sprintf.format('index out of range (%d)', [i]));
			#end
			
			var child = children;
			for (j in 0...i) child = child.next;
			return child;
		}
		else
			return null;
	}
	
	/**
	 * Returns the child index of this node.
	 */
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
	 * Unlinks this node.<br/>
	 * <o>1</o>
	 * @return a subtree rooted at this node.
	 */
	inline public function unlink():TreeNode<T>
	{
		if (parent != null)
		{
			if (parent.children == this)
				parent.children = next;
			if (parent._tail == this)
				parent._tail = prev;
			parent._numChildren--;
			parent = null;
		}
		if (hasPrevSibling()) prev.next = next;
		if (hasNextSibling()) next.prev = prev;
		next = prev = null;
		return this;
	}
	
	/**
	 * Unlinks <code>x</code> and appends <code>x</code> as a child to this node.
	 * @throws de.polygonal.core.util.AssertError <code>x</code> is null (debug only).
	 * <o>1</o>
	 */
	public function appendNode(x:TreeNode<T>):Void
	{
		#if debug
		D.assert(x != null, 'x is null');
		#end
		
		x.unlink();
		x.parent = this;
		_numChildren++;
		
		if (hasChildren())
		{
			_tail.next = x;
			x.prev = _tail;
			x.next = null;
			_tail = x;
		}
		else
		{
			_tail = x;
			children = x;
		}
	}
	
	/**
	 * Unlinks <code>x</code> and prepends <code>x</code> as a child of this node.
	 * <o>1</o>
	 */
	public function prependNode(x:TreeNode<T>):Void
	{
		x.unlink();
		x.parent = this;
		_numChildren++;
		
		if (hasChildren())
		{
			var head = children;
			x.next = head;
			head.prev = x;
			x.prev = null;
		}
		else
			_tail = x;
		
		children = x;
	}
	
	/**
	 * Unlinks <code>x</code> and appends <code>x</code> to the specified code>child</code> node.
	 * <o>1</o>
	 * @throws de.polygonal.core.util.AssertError <code>child</code> node is not a child of this node (debug only).
	 */
	public function insertAfterChild(child:TreeNode<T>, x:TreeNode<T>):Void
	{
		#if debug
		D.assert(child.parent == this, 'given child node is not a child of this node');
		#end
		
		x.unlink();
		x.parent = this;
		_numChildren++;
		
		if (children == null)
		{
			children = x;
			return;
		}
		
		if (child.hasNextSibling())
		{
			child.next.prev = x;
			x.next = child.next;
		}
		child.next = x;
		x.prev = child;
		
		if (child == _tail)
			_tail = x;
	}
	
	/**
	 * Unlinks <code>x</code> and prepends <code>x</code> to the specified child <code>node</code>.
	 * <o>1</o>
	 * @throws de.polygonal.core.util.AssertError <code>child</code> node is not a child of this node (debug only).
	 */
	public function insertBeforeChild(child:TreeNode<T>, x:TreeNode<T>):Void
	{
		#if debug
		D.assert(child.parent == this, 'given child node is not a child of this node');
		#end
		
		x.unlink();
		x.parent = this;
		_numChildren++;
		
		if (children == null)
		{
			children = x;
			return;
		}
		
		if (child == children) children = x;
		if (child.hasPrevSibling())
		{
			child.prev.next = x;
			x.prev = child.prev;
		}
		
		x.next = child;
		child.prev = x;
	}
	
	/**
	 * Unlinks <code>x</code> and inserts <code>x</code> at the index position <code>i</code>.
	 * @throws de.polygonal.core.util.AssertError index <code>i</code> out of range (debug only).
	 * <o>1</o>
	 */
	public function insertChildAt(x:TreeNode<T>, i:Int):Void
	{
		#if debug
		D.assert(i >= 0 && i <= numChildren(), Sprintf.format('index %d out of range', [i]));
		#end
		
		if (i == 0)
			prependNode(x);
		else
		if (i == _numChildren)
			appendNode(x);
		else
			insertBeforeChild(getChildAt(i), x);
	}
	
	/**
	 * Successively swaps this node with previous siblings until it reached the head of the sibling list.
	 * <o>1</o>
	 */
	public function setFirst():Void
	{
		if (hasSiblings())
		{
			var p = parent;
			unlink();
			p.prependNode(this);
		}
	}
	
	/**
	 * Successively swaps this node with next siblings until it reached the tail of the sibling list.
	 * <o>1</o>
	 */
	public function setLast():Void
	{
		if (hasSiblings())
		{
			var p = parent;
			unlink();
			p.appendNode(this);
		}
	}
	
	/**
	 * Recursively finds the first occurrence of the node storing the element <code>x</code> in this tree.
	 * <o>n</o>
	 * @return the node storing the element <code>x</code> or null if such a node does not exist.
	 */
	public function find(x:T):TreeNode<T>
	{
		var stack = _stack == null ? new Array<TreeNode<T>>() : _stack;
		var top = 1;
		var max = 1;
		stack[0] = this;
		
		while (top != 0)
		{
			var node = stack[--top];
			if (node.val == x)
				return node;
			var n = node.children;
			if (n != null)
			{
				var c = node._tail;
				while (c != null)
				{
					stack[top++] = c;
					if (top > max) max = top;
					c = c.prev;
				}
			}
		}
		
		for (i in 0...max) stack[i] = null;
		return null;
	}
	
	/**
	 * Performs a recursive preorder traversal.<br/>
	 * A preorder traversal performs the following steps:<br/>
	 * <ul>
	 * <li>Visit the node.</li>
	 * <li>Traverse the left subtree of the node.</li>
	 * <li>Traverse the right subtree of the node.</li>
	 * </ul><br/>
	 * @param process a function that is invoked on every traversed node.<br/>
	 * The first argument holds a reference to the current node, the second arguments stores the preflight flag and the third argument stores custom data specified by the <code>userData</code> parameter (default is null).
	 * Once <code>process</code> returns false, the traversal stops immediately and no further nodes are examined.<br/>
	 * If omitted, element.<em>visit()</em> is used instead.<br/>
	 * @param preflight if true, an extra traversal is performed before the actual traversal runs.
	 * The first pass visits all elements and calls element.<em>visit()</em> with the <code>preflight</code> parameter set to true.
	 * In this pass the return value determines whether the element (and all its children) will be processed (true) or
	 * excluded (false) from the final traversal, which is the second pass (<code>preflight</code> parameter set to false).<br/>
	 * The same applies when using a <code>process</code> function.<br/>
	 * <warn>In this case all elements have to implement <em>Visitable</em>.</warn>
	 * @param iterative if true, an iterative traversal is used (default traversal style is recursive).
	 * @param userData custom data that is passed to every visited node via <code>process</code> or element.<em>visit()</em>. If omitted, null is used.
	 */
	public function preorder(process:TreeNode<T>->Bool->Dynamic->Bool = null, preflight = false, iterative = false, userData:Dynamic = null):Void
	{
		if (parent == null && children == null)
		{
			if (process == null)
			{
				#if debug
				D.assert(Std.is(val, Visitable), 'element is not of type Visitable');
				#end
				
				var v = cast(val, Visitable);
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
			return;
		}
		
		if (iterative == false)
		{
			if (process == null)
			{
				#if debug
				D.assert(Std.is(val, Visitable), 'element is not of type Visitable');
				#end
				
				if (preflight)
				{
					var v = cast(val, Visitable);
					
					if (v.visit(true, userData))
					{
						if (v.visit(false, userData))
						{
							var child = children, hook;
							while (child != null)
							{
								hook = child.next;
								if (!_preOrderInternalVisitablePreflight(child, userData)) return;
								child = hook;
							}
						}
					}
				}
				else
				{
					var v = cast(val, Visitable);
					if (v.visit(false, userData))
					{
						var child = children, hook;
						while (child != null)
						{
							hook = child.next;
							if (!_preOrderInternalVisitable(child, userData)) return;
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
								if (!_preOrderInternalPreflight(child, process, userData)) return;
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
							if (!_preOrderInternal(child, process, userData)) return;
							child = hook;
						}
					}
				}
			}
		}
		else
		{
			var stack = _stack == null ? new Array<TreeNode<T>>() : _stack;
			var max = 1;
			var top = 1;
			stack[0] = this;
			
			if (process == null)
			{
				if (preflight)
				{
					while (top != 0)
					{
						var node = stack[--top];
						
						#if debug
						D.assert(Std.is(node.val, Visitable), 'element is not of type Visitable');
						#end
						
						var v = cast(node.val, Visitable);
						
						if (!v.visit(true, userData)) continue;
						if (!v.visit(false, userData))
							return;
						var n = node.children;
						if (n != null)
						{
							var c = node._tail;
							while (c != null)
							{
								stack[top++] = c;
								if (top > max) max = top;
								c = c.prev;
							}
						}
					}
				}
				else
				{
					while (top != 0)
					{
						var node = stack[--top];
						
						#if debug
						D.assert(Std.is(node.val, Visitable), 'element is not of type Visitable');
						#end
						
						var v = cast(node.val, Visitable);
						
						if (!v.visit(false, userData))
							return;
						var n = node.children;
						if (n != null)
						{
							var c = node._tail;
							while (c != null)
							{
								stack[top++] = c;
								if (top > max) max = top;
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
					while (top != 0)
					{
						var node = stack[--top];
						
						if (!process(node, true, userData)) continue;
						if (!process(node, false, userData))
							return;
						var n = node.children;
						if (n != null)
						{
							var c = node._tail;
							while (c != null)
							{
								stack[top++] = c;
								if (top > max) max = top;
								c = c.prev;
							}
						}
					}
				}
				else
				{
					while (top != 0)
					{
						var node = stack[--top];
						if (!process(node, false, userData))
							return;
						var n = node.children;
						if (n != null)
						{
							var c = node._tail;
							while (c != null)
							{
								stack[top++] = c;
								if (top > max) max = top;
								c = c.prev;
							}
						}
					}
				}
			}
			
			for (i in 0...max) stack[i] = null;
		}
	}
	
	/**
	 * Performs a recursive postorder traversal.<br/>
	 * A preorder traversal performs the following steps:<br/>
	  * <ul>
	 * <li>Traverse the left subtree of the node.</li>
	 * <li>Traverse the right subtree of the node.</li>
	 * <li>Visit the node.</li>
	 * </ul><br/>
	 * @param process a function that is invoked on every traversed node.<br/>
	 * The first argument holds a reference to the current node, while the second argument stores custom data specified by the <code>userData</code> parameter (default is null).
	 * Once <code>process</code> returns false, the traversal stops immediately and no further nodes are examined.<br/>
	 * If omitted, element.<em>visit()</em> is used instead.<br/>
	 * <warn>In this case all elements have to implement <em>Visitable</em>.</warn>
	 * @param iterative if true, an iterative traversal is used (default traversal style is recursive).
	 * @param userData custom data that is passed to every visited node via <code>process</code> or element.<em>visit()</em>. If omitted, null is used.
	 */
	public function postorder(process:TreeNode<T>->Dynamic->Bool = null, iterative = false, userData:Dynamic = null):Void
	{
		if (parent == null && children == null)
		{
			if (process == null)
			{
				#if debug
				D.assert(Std.is(val, Visitable), 'element is not of type Visitable');
				#end
				
				cast(val, Visitable).visit(false, userData);
			}
			else
				process(this, userData);
			return;
		}
		
		if (iterative == false)
		{
			if (process == null)
			{
				var child = children, hook;
				while (child != null)
				{
					hook = child.next;
					if (!_postOrderInternalVisitable(child, userData)) return;
					child = hook;
				}
				
				#if debug
				D.assert(Std.is(val, Visitable), 'element is not of type Visitable');
				#end
				
				cast(val, Visitable).visit(false, userData);
			}
			else
			{
				var child = children, hook;
				while (child != null)
				{
					hook = child.next;
					if (!_postOrderInternal(child, process, userData)) return;
					child = hook;
				}
				process(this, userData);
			}
		}
		else
		{
			#if debug
			D.assert(_busy == false, 'recursive call to iterative postorder');
			_busy = true;
			#end
			
			var time = _timestamp + 1;
			var stack = _stack == null ? new Array<TreeNode<T>>() : _stack;
			var top = 1;
			var max = 1;
			stack[0] = this;
			
			if (process == null)
			{
				while (top != 0)
				{
					var node = stack[top - 1];
					if (node.hasChildren())
					{
						var found = false;
						var c = node._tail;
						while (c != null)
						{
							if (c._timestamp < time)
							{
								c._timestamp++;
								stack[top++] = c;
								if (top > max) max = top;
								found = true;
							}
							c = c.prev;
						}
						
						if (!found)
						{
							#if debug
							D.assert(Std.is(node.val, Visitable), 'element is not of type Visitable');
							#end
							
							var v = cast(node.val, Visitable);
							if (!v.visit(false, userData))
							{
								#if debug
								_busy = false;
								#end
								return;
							}
							top--;
						}
					}
					else
					{
						#if debug
						D.assert(Std.is(node.val, Visitable), 'element is not of type Visitable');
						#end
						
						var v = cast(node.val, Visitable);
						if (!v.visit(false, userData))
						{
							#if debug
							_busy = false;
							#end
							return;
						}
						node._timestamp++;
						top--;
					}
				}
			}
			else
			{
				while (top != 0)
				{
					var node = stack[top - 1];
					if (node.hasChildren())
					{
						var found = false;
						var c = node._tail;
						while (c != null)
						{
							if (c._timestamp < time)
							{
								c._timestamp++;
								stack[top++] = c;
								if (top > max) max = top;
								found = true;
							}
							c = c.prev;
						}
						
						if (!found)
						{
							if (!process(node, userData))
							{
								#if debug
								_busy = false;
								#end
								return;
							}
							top--;
						}
					}
					else
					{
						if (!process(node, userData))
						{
							#if debug
							_busy = false;
							#end
							return;
						}
						node._timestamp++;
						top--;
					}
				}
			}
			for (i in 0...max) stack[i] = null;
			#if debug
			_busy = false;
			#end
		}
	}
	
	/**
	 * Performs a queue-based, iterative level-order traversal.<br/>
	 * In a level-order traversal all nodes of a tree are processed by depth: first the root, then the children of the root, etc.
	 * @param process a function that is invoked on every traversed node.<br/>
	 * The first argument holds a reference to the current node, while the second argument stores custom data specified by the <code>userData</code> parameter (default is null).
	 * Once <code>process</code> returns false, the traversal stops immediately and no further nodes are examined.<br/>
	 * If omitted, element.<em>visit()</em> is used instead.<br/>
	 * <warn>In this case all elements have to implement <em>Visitable</em>.</warn>
	 * @param userData custom data that is passed to every visited node via <code>process</code> or element.<em>visit()</em>. If omitted, null is used.
	 */
	public function levelorder(process:TreeNode<T>->Dynamic->Bool = null, userData:Dynamic = null):Void
	{
		if (children == null)
		{
			if (process == null)
			{
				#if debug
				D.assert(Std.is(val, Visitable), 'element is not of type Visitable');
				#end
				cast(val, Visitable).visit(false, userData);
			}
			else
				process(this, userData);
			return;
		}
		
		var q = _stack == null ? new Array<TreeNode<T>>() : _stack;
		q[0] = this;
		var i = 0;
		var s = 1;
		var max = 0;
		var node, child;
		
		if (process == null)
		{
			while (i < s)
			{
				node = q[i++];
				
				#if debug
				D.assert(Std.is(node.val, Visitable), 'element is not of type Visitable');
				#end
				
				if (!cast(node.val, Visitable).visit(false, userData))
					return;
				var child = node.children;
				while (child != null)
				{
					q[s++] = child;
					if (s > max) max = s;
					child = child.next;
				}
			}
		}
		else
		{
			while (i < s)
			{
				node = q[i++];
				
				if (!process(node, userData))
					return;
				
				child = node.children;
				while (child != null)
				{
					q[s++] = child;
					if (s > max) max = s;
					child = child.next;
				}
			}
		}
		
		for (i in 0...max) q[i] = null;
	}
	
	/**
	 * Sorts the children of this node using the merge sort algorithm.
	 * <o>n log n for merge sort and n&sup2; for insertion sort</o>
	 * @param compare a comparison function.<br/>
	 * If null, the elements are compared using element.<em>compare()</em>.<br/>
	 * <warn>In this case all elements have to implement <em>Comparable</em>.</warn>
	 * @param useInsertionSort if true, the dense array is sorted using the insertion sort algorithm.
	 * This is faster for nearly sorted lists.
	 * @throws de.polygonal.core.util.AssertError element does not implement <em>Comparable</em> (debug only).
	 */
	public function sort(compare:T->T->Int, useInsertionSort = false):Void
	{
		if (hasChildren())
		{
			if (compare == null)
				children = useInsertionSort ? _insertionSortComparable(children) : _mergeSortComparable(children);
			else
				children = useInsertionSort ? _insertionSort(children, compare) : _mergeSort(children, compare);
		}
	}
	
	/**
	 * Returns a string representing the current object.<br/>
	 * Example:<br/>
	 * <pre class="prettyprint">
	 * var root = new de.polygonal.ds.TreeNode&lt;Int&gt;(0); //create the root of the tree
	 * var builder = new de.polygonal.ds.TreeBuilder&lt;Int&gt;(root);
	 * builder.appendChild(1);
	 * builder.down();
	 * builder.appendChild(2);
	 * builder.up();
	 * builder.appendChild(3);
	 * trace(root);</pre>
	 * <pre class="console">
	 * {TreeNode (root), children: 2, depth:0, value: 0}
	 * +---{TreeNode (child), children: 1, depth:1, value: 1}
	 * |   +---{TreeNode (leaf+child), depth:2, value: 2}
	 * +---{TreeNode (leaf+child), depth:1, value: 3}</pre>
	 */
	public function toString():String
	{
		var s = '';
		preorder(function(node:TreeNode<T>, preflight:Bool, userData:Dynamic):Bool
		{
			var d = node.depth();
			for (i in 0...d)
			{
				if (i == d - 1)
					s += '+---';
				else
					s += '|   ';
			}
			s += node._describe() + '\n';
			return true;
		});
		return s;
	}
	
	/**
	 * Creates and returns a <em>TreeBuilder</em> object pointing to this node.
	 * <o>1</o>
	 */
	public function getBuilder():TreeBuilder<T>
	{
		return new TreeBuilder<T>(this);
	}
	
	/**
	 * Returns a new <em>ChildTreeIterator</em> object to iterate over all direct children (excluding this node).<br/>
	 * <warn>In contrast to <code>iterator()</code>, this method is not recursive</warn>
	 * @see <a href="http://haxe.org/ref/iterators" target="_blank">http://haxe.org/ref/iterators</a>
	 */
	public function childIterator():Itr<T>
	{
		return new ChildTreeIterator<T>(this);
	}
	
	function _describe():String
	{
		var s = '{TreeNode';
		var flags = new Array<String>();
		if (isRoot())  flags.push('root');
		if (isLeaf())  flags.push('leaf');
		if (isChild()) flags.push('child');
		s += ' (' + flags.join('|') + ')';
		if (numChildren() > 0)
			s += ', children: ' + numChildren();
		s += ', depth: ' + depth();
		s += ', value: ' + val;
		s += '}';
		return s;
	}
	
	function _preOrderInternal(node:TreeNode<T>, process:TreeNode<T>->Bool->Dynamic->Bool, userData:Dynamic):Bool
	{
		if (process(node, false, userData))
		{
			if (node.hasChildren())
			{
				var walker = node.children;
				while (walker != null)
				{
					if (!_preOrderInternal(walker, process, userData)) return false;
					walker = walker.next;
				}
			}
			return true;
		}
		return false;
	}
	
	function _preOrderInternalPreflight(node:TreeNode<T>, process:TreeNode<T>->Bool->Dynamic->Bool, userData:Dynamic):Bool
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
						if (!_preOrderInternalPreflight(walker, process, userData)) return false;
						walker = walker.next;
					}
				}
				return true;
			}
		}
		return false;
	}
	
	function _preOrderInternalVisitable(node:TreeNode<T>, userData:Dynamic):Bool
	{
		#if debug
		D.assert(Std.is(node.val, Visitable), 'element is not of type Visitable');
		#end
		
		var v = cast(node.val, Visitable);
		if (v.visit(false, userData))
		{
			if (node.hasChildren())
			{
				var walker = node.children, hook;
				while (walker != null)
				{
					hook = walker.next;
					if (!_preOrderInternalVisitable(walker, userData)) return false;
					walker = hook;
				}
			}
			return true;
		}
		return false;
	}
	
	function _preOrderInternalVisitablePreflight(node:TreeNode<T>, userData:Dynamic):Bool
	{
		#if debug
		D.assert(Std.is(node.val, Visitable), 'element is not of type Visitable');
		#end
		
		var v = cast(node.val, Visitable);
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
						if (!_preOrderInternalVisitablePreflight(walker, userData)) return false;
						walker = hook;
					}
				}
				return true;
			}
		}
		return false;
	}
	
	function _postOrderInternal(node:TreeNode<T>, process:TreeNode<T>->Dynamic->Bool, userData:Dynamic):Bool
	{
		if (node.hasChildren())
		{
			var walker = node.children, hook;
			while (walker != null)
			{
				hook = walker.next;
				if (!_postOrderInternal(walker, process, userData)) return false;
				walker = hook;
			}
		}
		return process(node, userData);
	}
	
	function _postOrderInternalVisitable(node:TreeNode<T>, userData:Dynamic):Bool
	{
		if (node.hasChildren())
		{
			var walker = node.children, hook;
			while (walker != null)
			{
				hook = walker.next;
				if (!_postOrderInternalVisitable(walker, userData)) return false;
				walker = hook;
			}
		}
		
		#if debug
		D.assert(Std.is(node.val, Visitable), 'element is not of type Visitable');
		#end
		
		return cast(node.val, Visitable).visit(false, userData);
	}
	
	function _insertionSortComparable(node:TreeNode<T>):TreeNode<T>
	{
		var h = node;
		var n = h.next;
		while (_valid(n))
		{
			var m = n.next;
			var p = n.prev;
			var v = n.val;
			
			#if debug
			D.assert(Std.is(p.val, Comparable), Sprintf.format('element is not of type Comparable (%s)', [p.val]));
			#end
			
			if (cast(p.val, Comparable<Dynamic>).compare(v) < 0)
			{
				var i = p;
				
				while (i.hasPrevSibling())
				{
					#if debug
					D.assert(Std.is(i.prev.val, Comparable), Sprintf.format('element is not of type Comparable (%s)', [i.prev.val]));
					#end
					
					if (cast(i.prev.val, Comparable<Dynamic>).compare(v) < 0)
						i = i.prev;
					else
						break;
				}
				if (_valid(m))
				{
					p.next = m;
					m.prev = p;
				}
				else
				{
					p.next = null;
					_tail = p;
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
	
	function _insertionSort(node:TreeNode<T>, cmp:T->T->Int):TreeNode<T>
	{
		var h = node;
		var n = h.next;
		while (_valid(n))
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
				if (_valid(m))
				{
					p.next = m;
					m.prev = p;
				}
				else
				{
					p.next = null;
					_tail = p;
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
	
	function _mergeSortComparable(node:TreeNode<T>):TreeNode<T>
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
			
			while (_valid(p))
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
				
				while (psize > 0 || (qsize > 0 && _valid(q)))
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
						#if debug
						D.assert(Std.is(p.val, Comparable), Sprintf.format('element is not of type Comparable (%s)', [p.val]));
						#end
						
						if (cast(p.val, Comparable<Dynamic>).compare(q.val) >= 0)
						{
							e = p; p = p.next; psize--;
						}
						else
						{
							e = q; q = q.next; qsize--;
						}
					}
					
					if (_valid(tail))
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
		_tail = tail;
		
		return h;
	}
	
	function _mergeSort(node:TreeNode<T>, cmp:T->T->Int):TreeNode<T>
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
			
			while (_valid(p))
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
				
				while (psize > 0 || (qsize > 0 && _valid(q)))
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
					
					if (_valid(tail))
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
		this._tail = tail;
		
		return h;
	}
	
	inline function _valid(node:TreeNode<T>):Bool
	{
		return node != null;
	}
	
	inline function _findHead(node:TreeNode<T>):TreeNode<T>
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
	
	inline function _findTail(node:TreeNode<T>):TreeNode<T>
	{
		if (node.parent != null)
			return node.parent._tail;
		else
		{
			var t = node;
			while (t.next != null) t = t.next;
			return t;
		}
	}
	
	/**
	 * Serializes this tree.
	 * The tree can be rebuild by calling <em>unserialize()</em>.
	 * @see <a href="http://eli.thegreenplace.net/2011/09/29/an-interesting-tree-serialization-algorithm-from-dwarf/" target="_blank">An interesting tree serialization algorithm from DWARF</a>
	 * @param node the root of the tree.
	 * @return a flattened tree.
	 */
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
	 * Unserializes a given <code>list</code> into a TreeNode structure.<br/>
	 * First create a dummy node which will be the root of the unserialized tree, then call <code>unserialize()</code>.
	 * Example:<br/>
	 * <pre class="prettyprint">
	 * var root = new de.polygonal.ds.TreeNode&lt;String&gt;(null);
	 * root.unserialize(mySerializedTree);
	 * </pre>
	 * @param list the flattened tree
	 * @return the root of the tree.
	 */
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
	 * Destroys this object by explicitly nullifying all nodes, pointers and elements for GC'ing used resources.<br/>
	 * Improves GC efficiency/performance (optional).
	 * <o>n</o>
	 */
	public function free():Void
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
		
		val      = cast null;
		prev     = null;
		next     = null;
		children = null;
		parent   = null;
		_tail    = null;
	}
	
	/**
	 * Returns true if this tree contains the element <code>x</code>.
	 * <o>n</o>
	 */
	public function contains(x:T):Bool
	{
		var found = false;
		preorder(function(node:TreeNode<T>, preflight:Bool, userData:Dynamic):Bool
		{
			if (node.val == x)
			{
				found = true;
				return false;
			}
			return true;
		});
		return found;
	}
	
	/**
	 * Runs a recursive preorder traversal that removes all nodes storing the element <code>x</code>.<br/>
	 * Tree nodes are not rearranged, so if a node stores <code>x</code>, the complete subtree rooted at that node is unlinked.
	 * <o>n</o>
	  * @return true if at least one occurrence of <code>x</code> was removed.
	 */
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
	 * Removes all child nodes.
	 * <o>1 or n if <code>purge</code> is true</o>
	 * @param purge if true, recursively nullifies this subtree.
	 */
	public function clear(purge = false):Void
	{
		if (purge)
		{
			var node = children;
			while (_valid(node))
			{
				var hook = node.next;
				node.prev = null;
				node.next = null;
				node.clear(purge);
				node = hook;
			}
			
			val      = cast null;
			parent   = null;
			children = null;
			_tail    = null;
		}
		else
			children = null;
		_numChildren = 0;
	}
	
	/**
	 * Returns a new <em>TreeIterator</em> object to iterate over all elements contained in the nodes of this subtree (including this node).<br/>
	 * The elements are visited by using a preorder traversal.
	 * @see <a href="http://haxe.org/ref/iterators" target="_blank">http://haxe.org/ref/iterators</a>
	 */
	public function iterator():Itr<T>
	{
		return new TreeIterator<T>(this);
	}
	
	/**
	 * The total number of nodes in the tree rooted at this node.
	 * <o>n</o>
	 */
	public function size():Int
	{
		var c = 1;
		var node = children;
		while (_valid(node))
		{
			c += node.size();
			node = node.next;
		}
		return c;
	}
	
	/**
	 * Returns true if this tree is empty.
	 * <o>1</o>
	 */
	public function isEmpty():Bool
	{
		return !hasChildren();
	}
	
	/**
	 * Returns an array containing all elements in the tree rooted at this node.<br/>
	 * The elements are collected using a preorder traversal.
	 */
	public function toArray():Array<T>
	{
		var a:Array<T> = ArrayUtil.alloc(size());
		var i = 0;
		preorder(function(node:TreeNode<T>, preflight:Bool, userData:Dynamic):Bool { a[i++] = node.val; return true; });
		return a;
	}
	
	#if flash10
	/**
	 * Returns a Vector.&lt;T&gt; object containing all elements in the tree rooted at this node.<br/>
	 * The elements are collected using a preorder traversal.
	 */
	public function toVector():flash.Vector<Dynamic>
	{
		var a = new flash.Vector<Dynamic>(size());
		var i = 0;
		preorder(function(node:TreeNode<T>, preflight:Bool, userData:Dynamic):Bool { a[i++] = node.val; return true; });
		return a;
	}
	#end
	
	/**
	 * Duplicates this subtree. Supports shallow (structure only) and deep copies (structure & elements).
	 * @param assign if true, the <code>copier</code> parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.<br/>
	 * If false, the <em>clone()</em> method is called on each element. <warn>In this case all elements have to implement <em>Cloneable</em>.</warn>
	 * @param copier a custom function for copying elements. Replaces element.<em>clone()</em> if <code>assign</code> is false.
	 * @throws de.polygonal.core.util.AssertError element is not of type <em>Cloneable</em> (debug only).
	 */
	public function clone(assign = true, copier:T->T = null):Collection<T>
	{
		var stack = _stack == null ? new Array<TreeNode<T>>() : _stack;
		var copy = new TreeNode<T>(copier != null ? copier(val) : val);
		
		stack[0] = this;
		stack[1] = copy;
		var i = 2;
		while (i > 0)
		{
			var c = stack[--i];
			var n = stack[--i];
			
			c._numChildren = n._numChildren;
			
			if (n.hasChildren())
			{
				var nchild = n.children;
				
				var x:T;
				if (assign)
					x = nchild.val;
				else
				if (copier == null)
				{
					#if debug
					D.assert(Std.is(nchild.val, Cloneable), Sprintf.format('element is not of type Cloneable (%s)', [nchild.val]));
					#end
					
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
					
					c._tail = cchild;
					
					stack[i++] = nchild;
					stack[i++] = cchild;
					
					nchild = nchild.next;
				}
			}
		}
		return copy;
	}
}

#if generic
@:generic
#end
#if doc
private
#end
class TreeIterator<T> implements de.polygonal.ds.Itr<T>
{
	var _node:TreeNode<T>;
	var _stack:Array<TreeNode<T>>;
	var _top:Int;
	var _c:Int;
	
	public function new(node:TreeNode<T>)
	{
		_node = node;
		_stack = new Array<TreeNode<T>>();
		reset();
	}
	
	inline public function reset():Itr<T>
	{
		_stack[0] = _node;
		_top = 1;
		_c = 0;
		return this;
	}
	
	inline public function hasNext():Bool
	{
		return _top > 0;
	}
	
	inline public function next():T
	{
		var node = _stack[--_top];
		var walker = node.children;
		_c = 0;
		while (walker != null)
		{
			_stack[_top++] = walker;
			_c++;
			walker = walker.next;
		}
		return node.val;
	}
	
	inline public function remove():Void
	{
		_top -= _c;
	}
}

#if generic
@:generic
#end
#if doc
private
#end
class ChildTreeIterator<T> implements de.polygonal.ds.Itr<T>
{
	var _f:TreeNode<T>;
	var _walker:TreeNode<T>;
	var _hook:TreeNode<T>;
	
	public function new(f:TreeNode<T>)
	{
		_f = f;
		reset();
	}
	
	inline public function reset():Itr<T>
	{
		_walker = _f.children;
		_hook = null;
		return this;
	}
	
	inline public function hasNext():Bool
	{
		return _walker != null;
	}
	
	inline public function next():T
	{
		var x = _walker.val;
		_hook = _walker;
		_walker = _walker.next;
		return x;
	}
	
	inline public function remove():Void
	{
		#if debug
		D.assert(_hook != null, 'call next() before removing an element');
		#end
		
		_hook.unlink();
	}
}