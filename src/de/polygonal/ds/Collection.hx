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
	A collection is an object that stores other objects (its elements)
**/
interface Collection<T> extends Hashable
{
	/**
		Deconstructs this collection by explicitly nullifying all internal references for GC'ing used resources.
		
		Improves GC efficiency/performance (optional).
	**/
	function free():Void;
	
	/**
		Returns true if this collection contains the element `x`.
	**/
	function contains(x:T):Bool;
	
	/**
		Removes all occurrences of the element `x`.
		@return true if at least one occurrence of `x` was removed.
	**/
	function remove(x:T):Bool;
	
	/**
		Removes all elements from this collection.
		
		For performance reasons, elements are not nullified upon removal.
		
		This means that elements won't be available for the garbage collector immediately unless `purge` is true.
		@param purge if true, elements are nullifies upon removal (slower).
	**/
	function clear(purge:Bool = false):Void;
	
	/**
		Iterates over all elements in this collection.
		
		Example:
		<pre class="prettyprint">
		var c:Collection<String> = new Array2<String>(...);
		for (element in c) {
		    trace(element);
		}
		//or
		var c:Collection = new Array2<String>(...);
		var itr:Itr = c.iterator();
		while (itr.hasNext()) {
		    var element:String = itr.next();
		    trace(element);
		}</pre>
		
		See <a href="http://haxe.org/ref/iterators" target="mBlank">http://haxe.org/ref/iterators</a>
	**/
	function iterator():Itr<T>;
	
	/**
		Returns true if this collection is empty.
	**/
	function isEmpty():Bool;
	
	/**
		Returns the total number of elements in this collection.
	**/
	function size():Int;
	
	/**
		Returns an array storing all elements in this collection.
	**/
	function toArray():Array<T>;
	
	/**
		Returns a `Vector<T>` object storing all elements in this collection.
	**/
	function toVector():Vector<T>;
	
	/**
		Duplicates this collection. Supports shallow (structure only) and deep copies (structure & elements).
		
		Example:
		<pre class="prettyprint">
		class Foo implements de.polygonal.ds.Cloneable<Foo>
		{
		    public var value:Int;
		    public function new(value:Int) {
		        this.value = value;
		    }
		    public function clone():Foo {
		        return new Foo(value);
		    }
		}
		class Main
		{
		    var c:Collection<Foo> = new Array2<Foo>(...);
		    //shallow copy
		    var clone = c.clone(true);
		    //deep copy
		    var clone = c.clone(false);
		    //deep copy using a custom function to do the actual work
		    var clone = c.clone(false, function(existingValue:Foo) { return new Foo(existingValue.value); })
		}</pre>
		@param assign if true, the `copier` parameter is ignored and primitive elements are copied by value whereas objects are copied by reference.
		If false, the ``clone()`` method is called on each element. <warn>In this case all elements have to implement `Cloneable`.</warn>
		@param copier a custom function for copying elements. Replaces ``element::clone()`` if `assign` is false.
	**/
	function clone(assign:Bool = true, copier:T->T = null):Collection<T>;
}