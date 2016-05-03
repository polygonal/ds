/*
Copyright (c) 2008-2016 Michael Baczynski, http://www.polygonal.de

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
import de.polygonal.ds.tools.NativeArrayTools;

/**
	A binary search tree (BST)
	
	A BST automatically arranges `BinaryTreeNode` objects so the resulting tree is a valid BST.
**/
#if generic
@:generic
#end
class Bst<T:Comparable<T>> implements Collection<T>
{
	/**
		A unique identifier for this object.
		
		A hash table transforms this key into an index of an array element by using a hash function.
		
		<warn>This value should never be changed by the user.</warn>
	**/
	public var key(default, null):Int = HashKey.next();
	
	/**
		If true, reuses the iterator object instead of allocating a new one when calling `iterator()`.
		
		The default is false.
		
		<warn>If true, nested iterations are likely to fail as only one iteration is allowed at a time.</warn>
	**/
	public var reuseIterator:Bool = false;
	
	var mSize:Int = 0;
	var mRoot:BinaryTreeNode<T> = null;
	var mIterator:BSTIterator<T> = null;
	
	public function new()
	{
	}
	
	/**
		The root node or null if no root exists.
	**/
	public function root():BinaryTreeNode<T>
	{
		return mRoot;
	}
	
	/**
		Inserts the element `x` into the binary search tree.
		@return the inserted node storing the element `x`.
	**/
	public function insert(x:T):BinaryTreeNode<T>
	{
		assert(x != null, "element is null");
		
		mSize++;
		if (mRoot == null)
		{
			mRoot = new BinaryTreeNode<T>(x);
			return mRoot;
		}
		else
		{
			var t:BinaryTreeNode<T> = null;
			var node = mRoot;
			while (node != null)
			{
				if (x.compare(node.val) < 0)
				{
					if (node.l != null)
						node = node.l;
					else
					{
						node.setL(x);
						t = node.l;
						break;
					}
				}
				else
				{
					if (node.r != null)
						node = node.r;
					else
					{
						node.setR(x);
						t = node.r;
						break;
					}
				}
			}
			return t;
		}
	}
	
	/**
		Finds the node that stores the element `x`.
		@return the node storing `x` or null if `x` does not exist.
	**/
	public function find(x:T):BinaryTreeNode<T>
	{
		assert(mRoot != null, "tree is empty");
		assert(x != null, "element is null");
		
		var node = mRoot;
		while (node != null)
		{
			var i = x.compare(node.val);
			if (i == 0) break;
			node = i < 0 ? node.l : node.r;
		}
		return node;
	}
	
	/**
		Removes the node storing the element `x`.
		@return true if `x` was successfully removed.
	**/
	public function removeNode(x:BinaryTreeNode<T>):Bool
	{
		assert(x != null, "element is null");
		
		if (x.l == null || x.r == null)
		{
			var child:BinaryTreeNode<T> = null;
			if (x.l != null) child = x.l;
			if (x.r != null) child = x.r;
			if (x.p == null)
				mRoot = child;
			else
			{
				if (x == x.p.l)
					x.p.l = child;
				else
					x.p.r = child;
			}
			
			if (child != null) child.p = x.p;
			x.l = null;
			x.r = null;
			x = null;
		}
		else
		{
			var l = x.l;
			while (l.r != null) l = l.r;
			
			if (x.l == l)
			{
				l.r = x.r;
				l.r.p = l;
			}
			else
			{
				l.p.r = l.l;
				if (l.l != null) l.l.p = l.p;
				l.l = x.l;
				l.l.p = l;
				l.r = x.r;
				l.r.p = l;
			}
			
			if (x.p == null)
				mRoot = l;
			else
			{
				if (x == x.p.l)
					x.p.l = l;
				else
					x.p.r = l;
			}
			
			l.p = x.p;
			x.l = null;
			x.r = null;
			x = null;
		}
		
		if (--mSize == 0) mRoot = null;
		return true;
	}
	
	/**
		Prints out all elements.
	**/
	public function toString():String
	{
		#if no_tostring
		return Std.string(this);
		#else
		var b = new StringBuf();
		b.add('{ Bst size: ${size} }');
		if (isEmpty()) return b.toString();
		b.add("\n[\n");
		var dumpNode = function(node:BinaryTreeNode<T>, userData:Dynamic):Bool
		{
			b.add('  ${Std.string(node.val)}\n');
			return true;
		};
		mRoot.inorder(dumpNode);
		b.add("]");
		return b.toString();
		#end
	}
	
	/* INTERFACE Collection */
	
	/**
		The total number of elements.
	**/
	public var size(get, never):Int;
	inline function get_size():Int
	{
		return mSize;
	}
	
	/**
		Destroys this object by explicitly nullifying all nodes, pointers and elements for GC'ing used resources.
		
		Improves GC efficiency/performance (optional).
	**/
	public function free()
	{
		mRoot.free();
		mRoot = null;
		if (mIterator != null)
		{
			mIterator.free();
			mIterator = null;
		}
	}
	
	/**
		Returns true if this BST contains the element `x`.
	**/
	public inline function contains(x:T):Bool
	{
		return size > 0 && (find(x) != null);
	}
	
	/**
		Removes all nodes containing the element `x`.
		@return true if at least one occurrence of `x` is nullified.
	**/
	public function remove(x:T):Bool
	{
		assert(x != null, "element is null");
		
		if (size == 0) return false;
		
		var s = mRoot.size;
		var found = false;
		while (s > 0)
		{
			var node = find(x);
			if (node == null) break;
			if (!removeNode(node)) break;
			found = true;
			s--;
		}
		return found;
	}
	
	/**
		Removes all elements.
		
		@param gc if true, elements are nullified upon removal so the garbage collector can reclaim used memory.
	**/
	public function clear(gc:Bool = false)
	{
		if (gc)
		{
			if (mRoot != null)
				mRoot.clear(gc);
		}
		
		mRoot = null;
		mSize = 0;
	}
	
	/**
		Returns a new `BSTIterator` object to iterate over all elements contained in this BST.
		
		The elements are visited by using a preorder traversal.
		
		@see http://haxe.org/ref/iterators
	**/
	public function iterator():Itr<T>
	{
		if (reuseIterator)
		{
			if (mIterator == null)
				mIterator = new BSTIterator<T>(mRoot);
			else
				mIterator.reset();
			return mIterator;
		}
		else
			return new BSTIterator<T>(mRoot);
	}
	
	/**
		Returns true if this BST is empty.
	**/
	public function isEmpty():Bool
	{
		return size == 0;
	}
	
	/**
		Returns an array containing all elements in this BST.
		
		The elements are added by applying a preorder traversal.
	**/
	public function toArray():Array<T>
	{
		if (isEmpty()) return [];
		
		var out = ArrayTools.alloc(size);
		var i = 0;
		mRoot.preorder(function(node:BinaryTreeNode<T>, _):Bool { out[i++] = node.val; return true; });
		return out;
	}
	
	/**
		Duplicates this subtree. Supports shallow (structure only) and deep copies (structure & elements).
		@param assign if true, the `copier` parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.
		If false, the `clone()` method is called on each element. <warn>In this case all elements have to implement `Cloneable`.</warn>
		@param copier a custom function for copying elements. Replaces `element->clone()` if `assign` is false.
	**/
	public function clone(assign:Bool = true, copier:T->T = null):Collection<T>
	{
		var copy = new Bst<T>();
		copy.mRoot = cast mRoot.clone(assign, copier);
		copy.mSize = size;
		return copy;
	}
}

#if generic
@:generic
#end
@:dox(hide)
class BSTIterator<T> implements de.polygonal.ds.Itr<T>
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
	
	public function free()
	{
		mObject = null;
		mStack = null;
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
		if (node.hasL())
		{
			mC++;
			mStack[mTop++] = node.l;
		}
		if (node.hasR())
		{
			mC++;
			mStack[mTop++] = node.r;
		}
		return node.val;
	}
	
	public function remove()
	{
		mTop -= mC;
	}
}