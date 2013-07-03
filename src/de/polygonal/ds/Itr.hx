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
 * <p>An iterator over a collection.</p>
 * Same as typedef <em>Iterator</em>&lt;T&gt; but augmented with a <em>reset()</em> method.
 */
interface Itr<T>
{
	/**
	 * Returns true if this iteration has more elements.
	 * @see <a href="http://haxe.org/api/iterator" target="_blank">http://haxe.org/api/iterator</a>
	 */
	function hasNext():Bool;
	
	/**
	 * Returns the next element in this iteration.
	 * @see <a href="http://haxe.org/api/iterator" target="_blank">http://haxe.org/api/iterator</a>
	 */
	function next():T;
	
	/**
	 * Removes the last element returned by the iterator from the collection.
	 * Example:<br/>
	 * <pre class="prettyprint">
	 * var c:Collection&lt;String&gt; = new *&lt;String&gt;(...);
	 * var itr = c.iterator();
	 * while (itr.hasNext()) {
	 *     var value = itr.next();
	 *     itr.remove(); //removes value
	 * }
	 * trace(c.isEmpty()); //true
	 * </pre>
	 */
	function remove():Void;
	
	/**
	 * Resets this iteration so the iterator points to the first element in the collection.<br/>
	 * Improves performance if an iterator is frequently used.<br/>
	 * Example:<br/>
	 * <pre class="prettyprint">
	 * var c:Collection&lt;String&gt; = new *&lt;String&gt;(...);
	 * var itr = c.iterator();
	 * for (i in 0...100) {
	 *     itr.reset();
	 *     for (element in itr) {
	 *         trace(element);
	 *     }
	 * }
	 * </pre>
	 */
	function reset():Itr<T>;
}