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
package polygonal.ds.tools;

import polygonal.ds.tools.Assert.assert;
import haxe.ds.StringMap;

/**
	A helper class for working with trees.
**/
@:access(polygonal.ds.XmlNode)
class TreeTools
{
	/**
		Creates a tree structure from an XML string.
	**/
	public static function ofXml(string:String):TreeNode<XmlNode>
	{
		var xml = Xml.parse(string).firstElement();
		
		var node = XmlNode.of(xml);
		var root = new TreeNode<XmlNode>(node);
		node.arbiter = root;
		
		var p:TreeNode<XmlNode>, c:TreeNode<XmlNode>;
		var stack:Array<Dynamic> = [xml, root];
		var top = 1;
		while (top-- != 0)
		{
			p = stack.pop();
			
			for (e in (stack.pop() : Xml))
			{
				if (e.nodeType != Xml.Element) continue;
				
				node = XmlNode.of(e);
				c = new TreeNode<XmlNode>(node);
				node.arbiter = c;
				p.appendNode(c);
				
				stack.push(e);
				stack.push(c);
				top++;
			}
		}
		return root;
	}
	
	/**
		Creates a tree structure from an indented list.
	**/
	public static function ofIndentedList<T>(list:String, getValue:String->T, indent = "\t"):TreeNode<T>
	{
		var r = new EReg('^([$indent]*)(.*)$', "g");
		var indentSize = indent.length;
		var stack = [];
		var line = 0;
		var lines = list.split("\n");
		var lut:Array<TreeNode<T>> = [for (i in 0...lines.length) null];
		var getDepth = function(x:{line:Int, value:String}):Int
		{
			r.match(x.value);
			assert(r.matched(1).length % indentSize == 0, "malformed indentation");
			return r.matched(1).length;
		}
		var getNode = function(x:{line:Int, value:String}):TreeNode<T>
		{
			r.match(x.value);
			var value = r.matched(2);
			var item = lut[x.line];
			if (item == null) item = lut[x.line] = new TreeNode<T>(getValue(value));
			return item;
		}
		var top = 0;
		stack[top++] = {line: line++, value: lines.shift()};
		while (lines.length > 0)
		{
			var s1 = stack[top - 1];
			var s2 = {line: line++, value: lines.shift()};
			if (getDepth(s1) < getDepth(s2))
			{
				getNode(s1).appendNode(getNode(s2));
				getNode(s2).parent = getNode(s1);
				stack[top++] = s2;
			}
			else
			{
				while (getDepth(s1) >= getDepth(s2) && stack.length > 1)
				{
					stack.pop();
					top--;
					s1 = stack[top - 1];
				}
				getNode(s1).appendNode(getNode(s2));
				getNode(s2).parent = getNode(s1);
				stack[top++] = s2;
			}
		}
		return getNode(stack[0]);
	}
	
	/**
		Creates a random tree structure.
		
		`getValue()` is called for every tree node; the signature is: `getValue(currentDepth, currentChildIndex):T`
	**/
	public static function randomTree<T>(
		getValue:(currentDepth:Int, currentChildIndex:Int)->T,
		maxDepth:Int,
		minChildCount:Int,
		maxChildCount:Int,
		?rand:()->Float):TreeNode<T>
	{
		assert(maxDepth >= 0);
		assert(minChildCount > 0);
		assert(maxChildCount >= minChildCount);
		
		if (rand == null) rand = Math.random;
		
		inline function randRange(min:Int, max:Int) return min + Std.int(rand() * ((max - min) + 1));
		
		var tree = new TreeNode<T>(getValue(0, 0));
		
		var build:TreeNode<T>->Int->Void = null;
		
		build = function(treeNode:TreeNode<T>, depth:Int)
		{
			if (depth < maxDepth)
			{
				var i = randRange(minChildCount, maxChildCount);
				var j = 0;
				while (j < i)
				{
					var childNode = new TreeNode<T>(getValue(depth + 1, j), treeNode);
					build(childNode, depth + 1);
					j++;
				}
			}
		}
		build(tree, 0);
		return tree;
	}
}

/**
	An object containing the data of a XML node.
**/
@:publicFields
class XmlNode
{
	static function of(xml:Xml):XmlNode
	{
		var node = new XmlNode();
		node.name = xml.nodeName;
		var firstChild = xml.firstChild();
		if (firstChild != null)
		{
			if (firstChild.nodeType == Xml.CData || firstChild.nodeType == Xml.PCData)
			{
				if (~/\S/.match(firstChild.nodeValue))
					node.data = firstChild.nodeValue;
			}
		}
		node.xml = xml;
		return node;
	}
	
	/**
		Node element name.
	**/
	var name:String;
	
	/**
		PCDATA or CDATA (if any).
	**/
	var data:String;
	
	/**
		XML Attributes (if any).
	**/
	public var attributes(get, never):AttrAccess;
	inline function get_attributes():AttrAccess return xml;
	
	/**
		The `TreeNode` instance which owns this node.
	**/
	var arbiter:TreeNode<XmlNode>;
	
	@:noCompletion
	var xml:Xml;
	
	public function new() {}
	
	public function iterator():Iterator<XmlNode>
	{
		var n = arbiter.children;
		return
		{
			hasNext: function() return n != null,
			next: function()
			{
				var t = n;
				n = n.next;
				return t.val;
			}
		}
	}
	
	public function firstDescendant(name:String, deep:Bool = true):XmlNode
	{
		if (arbiter.hasChildren())
		{
			var first = arbiter.getFirstChild().val;
			if (first.name == name)
				return first;
		}
		
		var out = null;
		
		if (deep)
		{
			arbiter.preorder(
				function(x:TreeNode<XmlNode>, userData, preflight)
				{
					if (x.val.name == name)
					{
						out = x.val;
						return false;
					}
					return true;
				}, null);
			return out;
		}
		else
		{
			var c = arbiter.children;
			while (c.hasNextSibling())
			{
				if (c.val.name == name)
				{
					out = c.val;
					break;
				}
				c = c.next;
			}
		}
		return out;
	}
	
	public function descendants(name:String, deep:Bool = true):Array<XmlNode>
	{
		var out = [];
		
		if (deep)
		{
			arbiter.preorder(
				function(x:TreeNode<XmlNode>, userData, preflight)
				{
					if (x.val.name == name)
						out.push(x.val);
					return true;
				}, null);
		}
		else
		{
			var c = arbiter.children;
			while (c.hasNextSibling())
			{
				if (c.val.name == name)
					out.push(c.val);
				c = c.next;
			}
		}
		return out;
	}
	
	#if !no_tostring
	public function toString():String
	{
		return '{ XmlNode: name=$name }';
	}
	#end
}

private abstract AttrAccess(Xml) from Xml
{
	@:op(a.b)
	@:access(Xml)
	public function resolve(name:String):String
		return (this.attributeMap:StringMap<String>).get(name);
}