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
 * <p>An object that maps keys to values.</p>
 * <p>This map allows duplicate keys.</p>
 */
interface Map<K, T> extends Collection<T>
{
	/**
	 * Returns true if this map contains a mapping for the element <code>x</code>.
	 */
	function has(x:T):Bool;
	
	/**
	 * Returns true if this map contains <code>key</code>.
	 */
	function hasKey(key:K):Bool;
	
	/**
	 * Returns the element that is mapped to <code>key</code> or a special value (see implementation) indicating that <code>key</code> does not exist.
	 */
	function get(key:K):T;
	
	/**
	 * Maps the element <code>x</code> to <code>key</code>.
	 * @return true if <code>key</code> was added for the first time, false if this <code>key</code> is not unique.<br/>
	 * Multiple keys are stored in a First-In-First-Out (FIFO) order - there is no way to access keys which were added after the first <code>key</code>,
	 * other than removing the first <code>key</code> which unveals the second <code>key</code>.
	 */
	function set(key:K, x:T):Bool;
	
	/**
	 * Removes a <code>key</code>/value pair.
	 * @return true if <code>key</code> was successfully removed, false if <code>key</code> does not exist.
	 */
	function clr(key:K):Bool;
	
	/**
	 * Remaps the first occurrence of <code>key</code> to the element <code>x</code>.<br/>
	 * This is faster than <em>clr</em>(<code>key</code>) followed by <em>set</em>(<code>key</code>, <code>x</code>).
	 * @return true if the remapping was successful, false if <code>key</code> does not exist.
	 */
	function remap(key:K, x:T):Bool;
	
	/**
	 * Returns a set view of the elements contained in this map. 
	 */
	function toValSet():Set<T>;
	
	/**
	 * Returns a set view of the keys contained in this map. 
	 */
	function toKeySet():Set<K>;
	
	/**
	 * Creates and returns an iterator over all keys in this map.
	 * @see <a href="http://haxe.org/ref/iterators" target="_blank">http://haxe.org/ref/iterators</a>
	 */
	function keys():Itr<K>;
}