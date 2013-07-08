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

import de.polygonal.ds.error.Assert.assert;

/**
 * <p>A simple set using an array.</p>
 * <p><o>Worst-case running time in Big O notation</o></p>
 */
class ListSet<T> implements Set<T>
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
	
	var _a:DA<T>;
	
	public function new()
	{
		_a = new DA<T>();
		key = HashKey.next();
		reuseIterator = false;
	}
	
	/**
	 * Returns a string representing the current object.<br/>
	 * Example:<br/>
	 * <pre class="prettyprint">
	 * var set = new de.polygonal.ds.ListSet&lt;String&gt;();
	 * set.set("val1");
	 * set.set("val2");
	 * trace(set);</pre>
	 * <pre class="console">
	 * { ListSet size: 2 }
	 * [
	 *   val1
	 *   val2
	 * ]</pre>
	 */
	public function toString():String
	{
		var s = '{ ListSet size: ${size()} }';
		if (isEmpty()) return s;
		s += "\n[\n";
		for (i in 0...size())
			s += '  ${Std.string(_a.get(i))}\n';
		s += "]";
		return s;
	}
	
	/*///////////////////////////////////////////////////////
	// set
	///////////////////////////////////////////////////////*/
	
	/**
	 * Returns true if this set contains the element <code>x</code>.
	 * <o>n</o>
	 */
	public function has(x:T):Bool
	{
		return _a.contains(x);
	}
	
	/**
	 * Adds the element <code>x</code> to this set if possible.
	 * <o>n</o>
	 * @return true if <code>x</code> was added to this set, false if <code>x</code> already exists.
	 */
	public function set(x:T):Bool
	{
		if (_a.contains(x))
			return false;
		else
		{
			_a.pushBack(x);
			return true;
		}
	}
	
	/**
	 * Adds all elements of the set <code>x</code> to this set.
	 * <o>n</o>
	 * @param assign if true, the <code>copier</code> parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.<br/>
	 * If false, the <em>clone()</em> method is called on each element. <warn>In this case all elements have to implement <em>Cloneable</em>.</warn>
	 * @param copier a custom function for copying elements. Replaces element.<em>clone()</em> if <code>assign</code> is false.
	 * @throws de.polygonal.ds.error.AssertError element is not of type <em>Cloneable</em> (debug only).
	 */
	public function merge(x:Set<T>, assign:Bool, copier:T->T = null)
	{
		if (assign)
		{
			for (val in x) set(val);
		}
		else
		{
			if (copier != null)
			{
				for (val in x)
					set(copier(val));
			}
			else
			{
				for (val in x)
				{
					#if debug
					assert(Std.is(val, Cloneable), 'element is not of type Cloneable ($val)');
					#end
					
					set(untyped val.clone());
				}
			}
		}
		
	}
	
	/*///////////////////////////////////////////////////////
	// collection
	///////////////////////////////////////////////////////*/
	
	/**
	 * Destroys this object by explicitly nullifying all elements.<br/>
	 * Improves GC efficiency/performance (optional).
	 * <o>n</o>
	 */
	public function free()
	{
		_a.free();
		_a = null;
	}
	
	/**
	 * Same as <em>has()</em>.
	 * <o>n</o>
	 */
	public function contains(x:T):Bool
	{
		return _a.contains(x);
	}
	
	/**
	 * Removes the element <code>x</code>.
	 * <o>n</o>
	 * @return true if <code>x</code> was successfully removed.
	 */
	public function remove(x:T):Bool
	{
		return _a.remove(x);
	}
	
	/**
	 * Removes all elements.
	 * <o>1 or n if <code>purge</code> is true</o>
	 * @param purge if true, nullifies references upon removal.
	 */
	public function clear(purge = false)
	{
		_a.clear(purge);
	}
	
	/**
	 * Iterates over all elements contained in this set.<br/>
	 * The elements are visited in a random order.
	 * @see <a href="http://haxe.org/ref/iterators" target="_blank">http://haxe.org/ref/iterators</a>
	 */
	public function iterator():Itr<T>
	{
		_a.reuseIterator = reuseIterator;
		return _a.iterator();
	}
	
	/**
	 * Returns true if this set is empty.
	 * <o>1</o>
	 */
	public function isEmpty():Bool
	{
		return _a.isEmpty();
	}
	
	/**
	 * The total number of elements.
	 * <o>1</o>
	 */
	public function size():Int
	{
		return _a.size();
	}
	
	/**
	 * Returns an unordered array containing all elements in this set.
	 */
	public function toArray():Array<T>
	{
		return _a.toArray();
	}
	
	#if flash10
	/**
	 * Returns a Vector.&lt;T&gt; object containing all elements in this set.
	 */
	public function toVector():flash.Vector<Dynamic>
	{
		return _a.toVector();
	}
	#end
	
	/**
	 * Duplicates this set. Supports shallow (structure only) and deep copies (structure & elements).
	 * @param assign if true, the <code>copier</code> parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.<br/>
	 * If false, the <em>clone()</em> method is called on each element. <warn>In this case all elements have to implement <em>Cloneable</em>.</warn>
	 * @param copier a custom function for copying elements. Replaces element.<em>clone()</em> if <code>assign</code> is false.
	 * @throws de.polygonal.ds.error.AssertError element is not of type <em>Cloneable</em> (debug only).
	 */
	public function clone(assign = true, copier:T->T = null):Collection<T>
	{
		var copy = Type.createEmptyInstance(ListSet);
		copy.key = HashKey.next();
		copy._a = cast _a.clone(assign, copier);
		return copy;
	}
}