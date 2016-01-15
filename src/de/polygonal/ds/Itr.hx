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

/**
	An iterator over a collection
	
	Same as typedef Iterator<T> but augmented with a ``reset()`` method.
**/
interface Itr<T>
{
	/**
		Returns true if this iteration has more elements.
		
		See <a href="http://haxe.org/api/iterator" target="mBlank">http://haxe.org/api/iterator</a>
	**/
	function hasNext():Bool;
	
	/**
		Returns the next element in this iteration.
		
		See <a href="http://haxe.org/api/iterator" target="mBlank">http://haxe.org/api/iterator</a>
	**/
	function next():T;
	
	/**
		Removes the last element returned by the iterator from the collection.
		
		Example:
		<pre class="prettyprint">
		var c:Collection<String> = new Array2<String>(...);
		var itr = c.iterator();
		while (itr.hasNext()) {
		    var value = itr.next();
		    itr.remove(); //removes value
		}
		trace(c.isEmpty()); //true
		</pre>
	**/
	function remove():Void;
	
	/**
		Resets this iteration so the iterator points to the first element in the collection.
		
		Improves performance if an iterator is frequently used.
		
		Example:
		<pre class="prettyprint">
		var c:Collection<String> = new Array2<String>(...);
		var itr = c.iterator();
		for (i in 0...100) {
		    itr.reset();
		    for (element in itr) {
		        trace(element);
		    }
		}
		</pre>
	**/
	function reset():Itr<T>;
}