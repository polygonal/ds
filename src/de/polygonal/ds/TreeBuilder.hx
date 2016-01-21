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
	A helper class for building tree structures
	
	The class manages two pointers: A "vertical" pointer and a "horizontal" pointer.
	
	The vertical pointer moves up and down the tree using the node's ``parent`` field, while the horizontal pointer moves left/right over the children using the ``prev`` and ``next`` fields.
	
	_<o>Worst-case running time in Big O notation</o>_
**/
#if generic
@:generic
#end
class TreeBuilder<T>
{
	var mNode:TreeNode<T>;
	var mChild:TreeNode<T>;
	
	/**
		Creates a ``TreeBuilder`` object pointing to `node`.
		<assert>node is null</assert>
	**/
	public function new(node:TreeNode<T>)
	{
		assert(node != null, "node is null");
		
		mNode = node;
		childStart();
	}
	
	/**
		Destroys this object by explicitly nullifying all pointers for GC'ing used resources.
		
		Improves GC efficiency/performance (optional).
		<o>1</o>
	**/
	public function free()
	{
		mNode = mChild = null;
	}
	
	/**
		Returns the data stored in the node that the tree builder is currently pointing at.
		<o>1</o>
		<assert>vertical pointer is null</assert>
	**/
	inline public function getVal():T
	{
		assert(valid(), "vertical pointer is null");
		
		return mNode.val;
	}
	
	/**
		Stores the element `x` in the node that the tree builder is currently pointing at.
		<o>1</o>
		<assert>vertical pointer is null</assert>
	**/
	inline public function setVal(x:T)
	{
		assert(valid(), "vertical pointer is null");
		
		mNode.val = x;
	}
	
	/**
		Returns the node that the tree builder is currently pointing at or null if invalid.
		<o>1</o>
	**/
	inline public function getNode():TreeNode<T>
	{
		return mNode;
	}
	
	/**
		Returns the child node that the tree builder is currently pointing at or null if invalid.
		<o>1</o>
	**/
	inline public function getChildNode():TreeNode<T>
	{
		return mChild;
	}
	
	/**
		Returns the data of the child pointer.
		<o>1</o>
		<assert>invalid child pointer</assert>
	**/
	inline public function getChildVal():T
	{
		assert(childValid(), "invalid child node");
		
		return mChild.val;
	}
	
	/**
		Returns true if the vertical pointer is valid.
		<o>1</o>
	**/
	inline public function valid():Bool
	{
		return mNode != null;
	}
	
	/**
		Moves the vertical pointer to the root of the tree.
		<o>n</o>
		<assert>invalid pointer</assert>
	**/
	public function root()
	{
		assert(valid(), "invalid vertical pointer");
		
		while (mNode.hasParent()) mNode = mNode.parent;
		reset();
	}
	
	/**
		Moves the vertical pointer one level up.
		<o>1</o>
		@return true if the vertical pointer was updated or false if the node has no parent.
	**/
	inline public function up():Bool
	{
		assert(valid(), "invalid vertical pointer");
		
		if (mNode.hasParent())
		{
			mNode = mNode.parent;
			reset();
			return true;
		}
		else
			return false;
	}
	
	/**
		Moves the vertical pointer one level down, so it points to the first child.
		<o>1</o>
		@return true if the vertical pointer was updated or false if the node has no children.
	**/
	inline public function down():Bool
	{
		assert(childValid(), "node has no children");
		
		if (mChild != null)
		{
			mNode = mChild;
			reset();
			return true;
		}
		else
			return false;
	}
	
	/**
		Returns true if the horizonal pointer has a next child.
		<o>1</o>
	**/
	inline public function hasNextChild():Bool
	{
		return childValid() && mChild.next != null;
	}
	
	/**
		Returns true if the horizonal pointer has a previous child.
		<o>1</o>
	**/
	inline public function hasPrevChild():Bool
	{
		return childValid() && mChild.prev != null;
	}
	
	/**
		Moves the horizontal pointer to the next child.
		<o>1</o>
		@return true if the horizontal pointer was updated or false if there is no next child.
	**/
	inline public function nextChild():Bool
	{
		if (hasNextChild())
		{
			mChild = mChild.next;
			return true;
		}
		else
			return false;
	}
	
	/**
		Moves the horizontal pointer to the previous child.
		<o>1</o>
		@return true if the horizontal pointer was updated or false if there is no previous child.
	**/
	inline public function prevChild():Bool
	{
		if (hasPrevChild())
		{
			mChild = mChild.prev;
			return true;
		}
		else
			return false;
	}
	
	/**
		Moves the horizontal pointer to the first child of the node referenced by the vertical pointer.
		<o>1</o>
		@return true if the horizontal pointer was updated or false if there are no children.
	**/
	inline public function childStart():Bool
	{
		if (valid())
		{
			mChild = mNode.children;
			return true;
		}
		else
			return false;
	}
	
	/**
		Moves the horizontal pointer to the first child of the node referenced by the vertical pointer.
		<o>1</o>
		@return true if the horizontal pointer was updated or false if there are no children.
	**/
	inline public function childEnd():Bool
	{
		if (childValid())
		{
			mChild = mNode.getLastChild();
			return true;
		}
		else
			return false;
	}
	
	/**
		Returns true if the horizontal pointer is valid.
		<o>1</o>
	**/
	inline public function childValid():Bool
	{
		return mChild != null;
	}
	
	/**
		Appends a child node storing `x` to the children of the vertical pointer.
		<o>1</o>
		<assert>invalid vertical pointer</assert>
	**/
	public function appendChild(x:T):TreeNode<T>
	{
		assert(valid(), "invalid vertical pointer");
		
		mChild = createChildNode(x, true);
		return mChild;
	}
	
	/**
		Prepends a child node storing `x` to the children of the vertical pointer.
		<o>1</o>
		<assert>invalid vertical pointer</assert>
	**/
	public function prependChild(x:T):TreeNode<T>
	{
		assert(valid(), "invalid vertical pointer");
		
		var childNode = createChildNode(x, false);
		if (childValid())
		{
			childNode.next = mNode.children;
			mNode.children.prev = childNode;
			mNode.children = childNode;
		}
		else
			mNode.children = childNode;
		mChild = childNode;
		return childNode;
	}
	
	/**
		Prepends a child node storing `x` to the child node referenced by the horizontal pointer.
		<o>1</o>
		<assert>invalid vertical pointer</assert>
	**/
	public function insertBeforeChild(x:T):TreeNode<T>
	{
		assert(valid(), "invalid vertical pointer");
		
		if (childValid())
		{
			var childNode = createChildNode(x, false);
			
			childNode.next = mChild;
			childNode.prev = mChild.prev;
			
			if (mChild.hasPrevSibling())
				mChild.prev.next = childNode;
			
			mChild.prev = childNode;
			mChild = childNode;
			
			return childNode;
		}
		else
			return appendChild(x);
	}
	
	/**
		Appends a child node storing `x` to the node referenced by the vertical pointer.
		<o>1</o>
		<assert>invalid vertical pointer</assert>
	**/
	public function insertAfterChild(x:T):TreeNode<T>
	{
		assert(valid(), "invalid vertical pointer");
		
		if (childValid())
		{
			var childNode = createChildNode(x, false);
			
			childNode.prev = mChild;
			childNode.next = mChild.next;
			
			if (mChild.hasNextSibling())
				mChild.next.prev = childNode;
			
			mChild.next = childNode;
			mChild = childNode;
			
			return childNode;
		}
		else
			return appendChild(x);
	}
	
	/**
		Removes the child node referenced by the horizontal pointer and moves the horizontal pointer to the next child.
		<o>1</o>
		@return true if the child node was successfully removed.
	**/
	public function removeChild():Bool
	{
		if (valid() && childValid())
		{
			mChild.parent = null;
			
			var node = mChild;
			mChild = node.next;
			
			if (mNode.children == node)
				mNode.children = mChild;
			
			if (node.hasPrevSibling()) node.prev.next = node.next;
			if (node.hasNextSibling()) node.next.prev = node.prev;
			node.parent = node.next = node.prev = null;
			return true;
		}
		else
			return false;
	}
	
	/**
		Returns a string representing the current object.
	**/
	public function toString():String
	{
		return "{ TreeBuilder V: " + (valid() ? mNode.val : cast null) + ", H: " + (childValid() ? mChild.val : cast null) + " }";
	}
	
	function reset()
	{
		if (valid()) mChild = mNode.children;
	}
	
	function createChildNode(x:T, append:Bool)
	{
		if (append)
			return new TreeNode<T>(x, mNode);
		else
		{
			var node = new TreeNode<T>(x);
			node.parent = mNode;
			return node;
		}
	}
	
	function getTail(node:TreeNode<T>):TreeNode<T>
	{
		var tail = node;
		while (tail.hasNextSibling()) tail.next;
		return tail;
	}
}