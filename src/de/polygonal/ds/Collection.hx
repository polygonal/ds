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

/**
	A collection is an object that stores other objects (its elements)
**/
interface Collection<T> extends Hashable
{
	/**
		The total number of elements in this collection.
	**/
	var size(get, never):Int;
	
	/**
		Disposes this collection by explicitly nullifying all internal references for GC'ing used resources.
		
		Improves GC efficiency/performance (optional).
	**/
	function free():Void;
	
	/**
		Returns true if this collection contains `val`.
	**/
	function contains(val:T):Bool;
	
	/**
		Removes all occurrences of `val`.
		@return true if at least one occurrence of `val` was removed.
	**/
	function remove(val:T):Bool;
	
	/**
		Removes all elements from this collection.
		
		For performance reasons, elements are not nullified upon removal.
		
		This means that elements won't be available for the garbage collector immediately unless `gc` is true.
		@param gc if true, elements are nullifies upon removal (slower).
	**/
	function clear(gc:Bool = false):Void;
	
	/**
		Iterates over all elements in this collection.
		
		Example:
			var c = new ArrayList<String>();
			for (element in c) trace(element);
			
			//or
			var c = new ArrayList<String>();
			var itr = c.iterator();
			while (itr.hasNext()) trace(itr.next());
			
			//inline hasNext() and next()
			var c = new ArrayList<String>();
			var itr:ArrayListIterator<String> = cast c.iterator();
			while (itr.hasNext()) trace(itr.next());
		
		@see http://haxe.org/ref/iterators
	**/
	function iterator():Itr<T>;
	
	/**
		Returns true if this collection is empty.
	**/
	function isEmpty():Bool;
	
	/**
		Returns an array storing all elements in this collection.
	**/
	function toArray():Array<T>;
	
	/**
		Duplicates this collection.
		
		Supports shallow (structure only) and deep copies (structure & elements).
		
		Example:
			class Element implements de.polygonal.ds.Cloneable<Element> {
			    public var val:Int;
			    public function new(val:Int) {
			        this.val = val;
			    }
			    public function clone():Element {
			        return new Element(val);
			    }
			}
			
			...
			
			var c:Collection<Element> = new Array2<Element>(...);
			
			//shallow copy
			var o = c.clone(true);
			
			//deep copy
			var o = c.clone(false);
			
			//deep copy using a custom function
			var o = c.clone(false, function(x) return new Element(x.val));
		
		If `byRef` is true, primitive elements are copied by value whereas objects are copied by reference.
		
		If `byRef` is false, the `copier` function is used for copying elements. If omitted, `clone()` is called on each element assuming all elements implement `Cloneable`.
	**/
	function clone(byRef:Bool = true, copier:T->T = null):Collection<T>;
}