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

import de.polygonal.ds.tools.Assert.assert;

/**
	A helper class for building tree structures
	
	The class manages two pointers: A "vertical" pointer and a "horizontal" pointer.
	
	The vertical pointer moves up and down the tree using the node's `TreeNode.parent` field, while the horizontal pointer moves left/right over the children using the `TreeNode.prev` and `TreeNode.next` fields.
**/
#if generic
@:generic
#end
class TreeBuilder<T>
{
	var mNode:TreeNode<T>;
	var mChild:TreeNode<T>;
	
	/**
		Creates a `TreeBuilder` object pointing to `node`.
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
	**/
	public function free()
	{
		mNode = mChild = null;
	}
	
	/**
		Returns the data stored in the node that the tree builder is currently pointing at.
	**/
	public inline function getVal():T
	{
		assert(valid(), "vertical pointer is null");
		
		return mNode.val;
	}
	
	/**
		Stores `val` in the node that the tree builder is currently pointing at.
	**/
	public inline function setVal(val:T):TreeBuilder<T>
	{
		assert(valid(), "vertical pointer is null");
		
		mNode.val = val;
		return this;
	}
	
	/**
		Returns the node that the tree builder is currently pointing at or null if invalid.
	**/
	public inline function getNode():TreeNode<T>
	{
		return mNode;
	}
	
	/**
		Returns the child node that the tree builder is currently pointing at or null if invalid.
	**/
	public inline function getChildNode():TreeNode<T>
	{
		return mChild;
	}
	
	/**
		Returns the data of the child pointer.
	**/
	public inline function getChildVal():T
	{
		assert(childValid(), "invalid child node");
		
		return mChild.val;
	}
	
	/**
		Returns true if the vertical pointer is valid.
	**/
	public inline function valid():Bool
	{
		return mNode != null;
	}
	
	/**
		Moves the vertical pointer to the root of the tree.
	**/
	public function root():TreeBuilder<T>
	{
		assert(valid(), "invalid vertical pointer");
		
		while (mNode.hasParent()) mNode = mNode.parent;
		reset();
		return this;
	}
	
	/**
		Moves the vertical pointer one level up.
		@return true if the vertical pointer was updated or false if the node has no parent.
	**/
	public inline function up():Bool
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
		@return true if the vertical pointer was updated or false if the node has no children.
	**/
	public inline function down():Bool
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
		Returns true if the horizontal pointer has a next child.
	**/
	public inline function hasNextChild():Bool
	{
		return childValid() && mChild.next != null;
	}
	
	/**
		Returns true if the horizontal pointer has a previous child.
	**/
	public inline function hasPrevChild():Bool
	{
		return childValid() && mChild.prev != null;
	}
	
	/**
		Moves the horizontal pointer to the next child.
		@return true if the horizontal pointer was updated or false if there is no next child.
	**/
	public inline function nextChild():Bool
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
		@return true if the horizontal pointer was updated or false if there is no previous child.
	**/
	public inline function prevChild():Bool
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
		@return true if the horizontal pointer was updated or false if there are no children.
	**/
	public inline function childStart():Bool
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
		@return true if the horizontal pointer was updated or false if there are no children.
	**/
	public inline function childEnd():Bool
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
	**/
	public inline function childValid():Bool
	{
		return mChild != null;
	}
	
	/**
		Appends a child node storing `val` to the children of the vertical pointer.
	**/
	public function appendChild(val:T):TreeNode<T>
	{
		assert(valid(), "invalid vertical pointer");
		
		mChild = createChildNode(val, true);
		return mChild;
	}
	
	/**
		Prepends a child node storing `val` to the children of the vertical pointer.
	**/
	public function prependChild(val:T):TreeNode<T>
	{
		assert(valid(), "invalid vertical pointer");
		
		var childNode = createChildNode(val, false);
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
		Prepends a child node storing `val` to the child node referenced by the horizontal pointer.
	**/
	public function insertBeforeChild(val:T):TreeNode<T>
	{
		assert(valid(), "invalid vertical pointer");
		
		if (childValid())
		{
			var childNode = createChildNode(val, false);
			
			childNode.next = mChild;
			childNode.prev = mChild.prev;
			
			if (mChild.hasPrevSibling())
				mChild.prev.next = childNode;
			
			mChild.prev = childNode;
			mChild = childNode;
			return childNode;
		}
		else
			return appendChild(val);
	}
	
	/**
		Appends a child node storing `val` to the node referenced by the vertical pointer.
	**/
	public function insertAfterChild(val:T):TreeNode<T>
	{
		assert(valid(), "invalid vertical pointer");
		
		if (childValid())
		{
			var childNode = createChildNode(val, false);
			
			childNode.prev = mChild;
			childNode.next = mChild.next;
			
			if (mChild.hasNextSibling())
				mChild.next.prev = childNode;
			
			mChild.next = childNode;
			mChild = childNode;
			return childNode;
		}
		else
			return appendChild(val);
	}
	
	/**
		Removes the child node referenced by the horizontal pointer and moves the horizontal pointer to the next child.
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
		Prints out all elements.
	**/
	#if !no_tostring
	public function toString():String
	{
		return "{ TreeBuilder V: " + (valid() ? mNode.val : cast null) + ", H: " + (childValid() ? mChild.val : cast null) + " }";
	}
	#end
	
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