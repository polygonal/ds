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

/**
 * <p>A collection is an object that stores other objects (its elements).</p>
 */
interface Collection<T> extends Hashable
{
	/**
	 * Deconstructs this collection by explicitly nullifying all internal references for GC'ing used resources.<br/>
	 * Improves GC efficiency/performance (optional).
	 */
	function free():Void;
	
	/**
	 * Returns true if this collection contains the element <code>x</code>. 
	 */
	function contains(x:T):Bool;
	
	/**
	 * Removes all occurrences of the element <code>x</code>.
	 * @return true if at least one occurrence of <code>x</code> was removed.
	 */
	function remove(x:T):Bool;
	
	/**
	 * Removes all elements from this collection.<br/>
	 * For performance reasons, elements are not nullified upon removal.<br/>
	 * This means that elements won't be available for the garbage collector immediately unless <code>purge</code> is true.
	 * @param purge if true, elements are nullifies upon removal (slower).
	 */
	function clear(purge:Bool = false):Void;
	
	/**
	 * Iterates over all elements in this collection.<br/>
	 * Example:<br/>
	 * <pre class="prettyprint">
	 * //Haxe
	 * var c:Collection&lt;String&gt; = new *&lt;String&gt;(...);
	 * for (element in c) {
	 *     trace(element);
	 * }
	 * 
	 * //ActionScript 3.0:
	 * var c:Collection = new *(...);
	 * var itr:Itr = c.iterator();
	 * while (itr.hasNext()) {
	 *     var element:* = itr.next();
	 *     trace(element);
	 * }</pre>
	 * @see <a href="http://haxe.org/ref/iterators" target="_blank">http://haxe.org/ref/iterators</a>
	 */
	function iterator():Itr<T>;
	
	/**
	 * Returns true if this collection is empty. 
	 */
	function isEmpty():Bool;
	
	/**
	 * Returns the total number of elements in this collection. 
	 */
	function size():Int;
	
	/**
	 * Returns an array storing all elements in this collection. 
	 */
	function toArray():Array<T>;
	
	#if flash10
	/**
	 * Returns a Vector.&lt;T&gt; object storing all elements in this collection. 
	 */
	function toVector():flash.Vector<Dynamic>;
	#end
	
	/**
	 * Duplicates this collection. Supports shallow (structure only) and deep copies (structure & elements).<br/>
	 * Example:<br/>
	 * <pre class="prettyprint">
	 * class Foo implements de.polygonal.ds.Cloneable&lt;Foo&gt;
	 * {
	 *     public var value:Int;
	 *     
	 *     public function new(value:Int) {
	 *         this.value = value;
	 *     }
	 *     
	 *     public function clone():Foo {
	 *         return new Foo(value);
	 *     }
	 * }
	 * 
	 * class Main
	 * {
	 *     var c:Collection&lt;Foo&gt; = new *&lt;Foo&gt;(...);
	 * 
	 *     //shallow copy
	 *     var clone = c.clone(true);
	 * 
	 *     //deep copy
	 *     var clone = c.clone(false);
	 * 
	 *     //deep copy using a custom function to do the actual work
	 *     var clone = c.clone(false, function(existingValue:Foo) { return new Foo(existingValue.value); })
	 * }</pre>
	 * @param assign if true, the <code>copier</code> parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.<br/>
	 * If false, the <em>clone()</em> method is called on each element. <warn>In this case all elements have to implement <em>Cloneable</em>.</warn>
	 * @param copier a custom function for copying elements. Replaces element.<em>clone()</em> if <code>assign</code> is false.
	 */
	function clone(assign:Bool = true, copier:T->T = null):Collection<T>;
}