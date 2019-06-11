/*
Copyright (c) 2008-2019 Michael Baczynski, http://www.polygonal.de

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
package polygonal.ds;

import polygonal.ds.tools.ArrayTools;
import polygonal.ds.tools.Assert.assert;

/**
	A binary search tree (BST)
	
	A BST automatically arranges `BinaryTreeNode` objects so the resulting tree is a valid BST.
	
	Example:
		class Element implements polygonal.ds.Comparable<Element> {
		    var i:Int;
		    public function new(i:Int) {
		        this.i = i;
		    }
		    public function compare(other:Element):Int {
		        return other.i - i;
		    }
		    public function toString():String {
		        return Std.string(i);
		    }
		}
		
		...
		
		var o = new polygonal.ds.Bst<Element>();
		o.insert(new Element(1));
		o.insert(new Element(0));
		o.insert(new Element(2));
		o.insert(new Element(7));
		trace(o); //outputs:
		
		[ Bst size=4
		  7
		  2
		  1
		  0
		]
**/
#if generic
@:generic
#end
class Bst<T:Comparable<T>> implements Collection<T>
{
	/**
		A unique identifier for this object.
		
		A hash table transforms this key into an index of an array element by using a hash function.
	**/
	public var key(default, null):Int = HashKey.next();
	
	/**
		If true, reuses the iterator object instead of allocating a new one when calling `this.iterator()`.
		
		The default is false.
		
		_If this value is true, nested iterations will fail as only one iteration is allowed at a time._
	**/
	public var reuseIterator:Bool = false;
	
	var mSize:Int = 0;
	var mRoot:BinaryTreeNode<T> = null;
	var mIterator:BstIterator<T> = null;
	
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
		Inserts `val` into the binary search tree.
		@return the inserted node storing `val`.
	**/
	public function insert(val:T):BinaryTreeNode<T>
	{
		assert(val != null, "element is null");
		
		mSize++;
		if (mRoot == null)
		{
			mRoot = new BinaryTreeNode<T>(val);
			return mRoot;
		}
		else
		{
			var t:BinaryTreeNode<T> = null;
			var node = mRoot;
			while (node != null)
			{
				if (val.compare(node.val) < 0)
				{
					if (node.left != null)
						node = node.left;
					else
					{
						node.setLeft(val);
						t = node.left;
						break;
					}
				}
				else
				{
					if (node.right != null)
						node = node.right;
					else
					{
						node.setRight(val);
						t = node.right;
						break;
					}
				}
			}
			return t;
		}
	}
	
	/**
		Finds the node that stores `val`.
		@return the node storing `val` or null if `val` does not exist.
	**/
	public function find(val:T):BinaryTreeNode<T>
	{
		assert(mRoot != null, "tree is empty");
		assert(val != null, "element is null");
		
		var node = mRoot;
		while (node != null)
		{
			var i = val.compare(node.val);
			if (i == 0) break;
			node = i < 0 ? node.left : node.right;
		}
		return node;
	}
	
	/**
		Removes `node`.
		@return true if `node` was successfully removed.
	**/
	public function removeNode(node:BinaryTreeNode<T>):Bool
	{
		assert(node != null, "element is null");
		
		if (node.left == null || node.right == null)
		{
			var child:BinaryTreeNode<T> = null;
			if (node.left != null) child = node.left;
			if (node.right != null) child = node.right;
			if (node.parent == null)
				mRoot = child;
			else
			{
				if (node == node.parent.left)
					node.parent.left = child;
				else
					node.parent.right = child;
			}
			
			if (child != null) child.parent = node.parent;
			node.left = null;
			node.right = null;
			node = null;
		}
		else
		{
			var l = node.left;
			while (l.right != null) l = l.right;
			
			if (node.left == l)
			{
				l.right = node.right;
				l.right.parent = l;
			}
			else
			{
				l.parent.right = l.left;
				if (l.left != null) l.left.parent = l.parent;
				l.left = node.left;
				l.left.parent = l;
				l.right = node.right;
				l.right.parent = l;
			}
			
			if (node.parent == null)
				mRoot = l;
			else
			{
				if (node == node.parent.left)
					node.parent.left = l;
				else
					node.parent.right = l;
			}
			
			l.parent = node.parent;
			node.left = null;
			node.right = null;
			node = null;
		}
		
		if (--mSize == 0) mRoot = null;
		return true;
	}
	
	/**
		Prints out all elements.
	**/
	#if !no_tostring
	public function toString():String
	{
		var b = new StringBuf();
		b.add('[ Bst size=$size');
		if (isEmpty())
		{
			b.add(" ]");
			return b.toString();
		}
		b.add("\n");
		mRoot.inorder(function(node:BinaryTreeNode<T>, _):Bool
		{
			b.add("  ");
			b.add(Std.string(node.val));
			b.add("\n");
			return true;
		});
		b.add("]");
		return b.toString();
	}
	#end
	
	/* INTERFACE Collection */
	
	/**
		The total number of nodes.
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
		Returns true if this BST contains `val`.
	**/
	public inline function contains(val:T):Bool
	{
		return size > 0 && (find(val) != null);
	}
	
	/**
		Removes all nodes containing `val`.
		@return true if at least one occurrence of `val` is nullified.
	**/
	public function remove(val:T):Bool
	{
		assert(val != null, "element is null");
		
		if (size == 0) return false;
		
		var s = mRoot.size;
		var found = false;
		while (s > 0)
		{
			var node = find(val);
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
		Returns a new *BstIterator* object to iterate over all elements contained in this BST.
		
		The elements are visited by using a preorder traversal.
		
		@see http://haxe.org/ref/iterators
	**/
	public function iterator():Itr<T>
	{
		if (reuseIterator)
		{
			if (mIterator == null)
				mIterator = new BstIterator<T>(mRoot);
			else
				mIterator.reset();
			return mIterator;
		}
		else
			return new BstIterator<T>(mRoot);
	}
	
	/**
		Returns true only if `this.size` is 0.
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
		Creates and returns a shallow copy (structure only - default) or deep copy (structure & elements) of this binary search tree.
		
		If `byRef` is true, primitive elements are copied by value whereas objects are copied by reference.
		
		If `byRef` is false, the `copier` function is used for copying elements. If omitted, `clone()` is called on each element assuming all elements implement `Cloneable`.
	**/
	public function clone(byRef:Bool = true, copier:T->T = null):Collection<T>
	{
		var copy = new Bst<T>();
		copy.mRoot = cast mRoot.clone(byRef, copier);
		copy.mSize = size;
		return copy;
	}
}

#if generic
@:generic
#end
@:dox(hide)
class BstIterator<T> implements polygonal.ds.Itr<T>
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
		if (node.hasLeft())
		{
			mC++;
			mStack[mTop++] = node.left;
		}
		if (node.hasRight())
		{
			mC++;
			mStack[mTop++] = node.right;
		}
		return node.val;
	}
	
	public function remove()
	{
		mTop -= mC;
	}
}