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
 * <p>A binary search tree (BST).</p>
 * <p>A BST automatically arranges <em>BinaryTreeNode</em> objects so the resulting tree is a valid BST.</p>
 * <p><o>Worst-case running time in Big O notation</o></p>
 */
#if generic
@:generic
#end
class BST<T:Comparable<T>> implements Collection<T>
{
	/**
	 * A unique identifier for this object.<br/>
	 * A hash table transforms this key into an index of an array element by using a hash function.<br/>
	 * <warn>This value should never be changed by the user.</warn>
	 */
	public var key:Int;
	
	/**
	 * If true, reuses the iterator object instead of allocating a new one when calling <code>iterator()</code>.<br/>
	 * The default is false.<br/>
	 * <warn>If true, nested iterations are likely to fail as only one iteration is allowed at a time.</warn>
	 */
	public var reuseIterator:Bool;
	
	var mSize:Int;
	var mRoot:BinaryTreeNode<T>;
	var mIterator:BSTIterator<T>;
	
	public function new()
	{
		mRoot = null;
		mIterator = null;
		mSize = 0;
		key = HashKey.next();
		reuseIterator = false;
	}
	
	/**
	 * The root node or null if no root exists.
	 * <o>1</o>
	 */
	public function root():BinaryTreeNode<T>
	{
		return mRoot;
	}
	
	/**
	 * Inserts the element <code>x</code> into the binary search tree.
	 * <o>n</o>
	 * @return the inserted node storing the element <code>x</code>.
	 * @throws de.polygonal.ds.error.AssertError <code>x</code> is null (debug only).
	 */
	public function insert(x:T):BinaryTreeNode<T>
	{
		#if debug
		assert(x != null, "element is null");
		#end
		
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
	 * Finds the node that stores the element <code>x</code>.
	 * <o>n</o>
	 * @return the node storing <code>x</code> or null if <code>x</code> does not exist.
	 * @throws de.polygonal.ds.error.AssertError tree is empty (debug only).
	 * @throws de.polygonal.ds.error.AssertError <code>x</code> is null (debug only).
	 */
	public function find(x:T):BinaryTreeNode<T>
	{
		#if debug
		assert(mRoot != null, "tree is empty");
		assert(x != null, "element is null");
		#end
		
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
	 * Removes the node storing the element <code>x</code>.
	 * <o>n</o>
	 * @return true if <code>x</code> was successfully removed.
	 * @throws de.polygonal.ds.error.AssertError <code>x</code> is invalid (debug only).
	 */
	public function removeNode(x:BinaryTreeNode<T>):Bool
	{
		#if debug
		assert(x != null, "element is null");
		#end
		
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
	 * Returns a string representing the current object.<br/>
	 * Example:<br/>
	 * <pre class="prettyprint">
	 * class Foo implements de.polygonal.ds.Comparable&lt;Foo&gt;
	 * {
	 *     var i:Int;
	 *
	 *     public function new(i:Int) {
	 *         this.i = i;
	 *     }
	 *
	 *     public function compare(other:Foo):Int {
	 *         return other.i - i;
	 *     }
	 *
	 *     public function toString():String {
	 *         return "{Foo " + i + "}";
	 *     }
	 * }
	 *
	 * class Main
	 * {
	 *     static function main() {
	 *         var BST = new de.polygonal.ds.BST&lt;Foo&gt;();
	 *         BST.insert(new Foo(1));
	 *         BST.insert(new Foo(0));
	 *         BST.insert(new Foo(2));
	 *         BST.insert(new Foo(7));
	 *         trace(BST);
	 *     }
	 * }</pre>
	 * <pre class="console">
	 * { BST size: 4 }
	 * [
	 *   {Foo 7}
	 *   {Foo 2}
	 *   {Foo 1}
	 *   {Foo 0}
	 * ]</pre>
	 */
	public function toString():String
	{
		var s = '{ BST size: ${size()} }';
		if (isEmpty()) return s;
		s += "\n[\n";
		var dumpNode = function(node:BinaryTreeNode<T>, userData:Dynamic):Bool
		{
			s += '  ${Std.string(node.val)}\n';
			return true;
		};
		
		mRoot.inorder(dumpNode);
		s += "]";
		return s;
	}
	
	/*///////////////////////////////////////////////////////
	// collection
	///////////////////////////////////////////////////////*/
	
	/**
	 * Destroys this object by explicitly nullifying all nodes, pointers and elements for GC'ing used resources.<br/>
	 * Improves GC efficiency/performance (optional).
	 * <o>n</o>
	 */
	public function free()
	{
		mRoot.free();
		mRoot = null;
		mIterator = null;
	}
	
	/**
	 * Returns true if this BST contains the element <code>x</code>.
	 * <o>n</o>
	 */
	inline public function contains(x:T):Bool
	{
		return mSize > 0 && (find(x) != null);
	}
	
	/**
	 * Removes all nodes containing the element <code>x</code>.
	 * <o>n</o>
	 * @return true if at least one occurrence of <code>x</code> is nullified.
	 * @throws de.polygonal.ds.error.AssertError <code>x</code> is invalid (debug only).
	 */
	public function remove(x:T):Bool
	{
		#if debug
		assert(x != null, "element is null");
		#end
		
		if (size() == 0) return false;
		
		var s = mRoot.size();
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
	 * Removes all elements.
	 * <o>1 or n if <code>purge</code> is true</o>
	 * @param purge if true, elements are nullified upon removal.
	 */
	public function clear(purge = false)
	{
		if (purge)
		{
			if (mRoot != null)
				mRoot.clear(purge);
		}
		
		mRoot = null;
		mSize = 0;
	}
	
	/**
	 * Returns a new <em>BSTIterator</em> object to iterate over all elements contained in this BST.<br/>
	 * The elements are visited by using a preorder traversal.
	 * @see <a href="http://haxe.org/ref/iterators" target="mBlank">http://haxe.org/ref/iterators</a>
	 */
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
	 * The total number of elements.
	 * <o>n</o>
	 */
	public function size():Int
	{
		return mSize;
	}
	
	/**
	 * Returns true if this BST is empty.
	 * <o>1</o>
	 */
	public function isEmpty():Bool
	{
		return mSize == 0;
	}
	
	/**
	 * Returns an array containing all elements in this BST.<br/>
	 * The elements are added by applying a preorder traversal.
	 */
	public function toArray():Array<T>
	{
		var a:Array<T> = ArrayUtil.alloc(size());
		var i = 0;
		mRoot.preorder(function(node:BinaryTreeNode<T>, userData:Dynamic):Bool { a[i++] = node.val; return true; });
		return a;
	}
	
	/**
	 * Returns a Vector.&lt;T&gt; object containing all elements in this BST.<br/>
	 * The elements are added by applying a preorder traversal.
	 */
	public function toVector():Vector<T>
	{
		var v = new Vector<T>(size());
		var i = 0;
		mRoot.preorder(function(node:BinaryTreeNode<T>, userData:Dynamic):Bool { v[i++] = node.val; return true; });
		return v;
	}
	
	/**
	 * Duplicates this subtree. Supports shallow (structure only) and deep copies (structure & elements).
	 * @param assign if true, the <code>copier</code> parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.<br/>
	 * If false, the <em>clone()</em> method is called on each element. <warn>In this case all elements have to implement <em>Cloneable</em>.</warn>
	 * @param copier a custom function for copying elements. Replaces element.<em>clone()</em> if <code>assign</code> is false.
	 * @throws de.polygonal.ds.error.AssertError element is not of type <em>Cloneable</em> (debug only).
	 */
	public function clone(assign = true, copier:T->T = null):Collection<T>
	{
		var copy = new BST<T>();
		copy.mRoot = cast mRoot.clone(assign, copier);
		copy.mSize = mSize;
		return copy;
	}
}

#if generic
@:generic
#end
#if doc
private
#end
class BSTIterator<T> implements de.polygonal.ds.Itr<T>
{
	var mNode:BinaryTreeNode<T>;
	var mStack:Array<BinaryTreeNode<T>>;
	var mTop:Int;
	var mC:Int;
	
	public function new(node:BinaryTreeNode<T>)
	{
		mNode = node;
		mStack = new Array<BinaryTreeNode<T>>();
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
	
	inline public function remove()
	{
		mTop -= mC;
	}
}