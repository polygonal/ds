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

import haxe.ds.StringMap;

/**
	A helper class for working with trees
**/
@:access(de.polygonal.ds.XmlNode)
class TreeUtil
{
	/**
		 Converts `xmlStr` to a ``Treenode`` structure.
	**/
	public static function ofXml(xmlStr:String):TreeNode<XmlNode>
	{
		var stack = new Array<Dynamic>();
		var top = 1;
		
		var xml = Xml.parse(xmlStr).firstElement();
		
		var info = new XmlNode(xml.nodeName);
		var tree = new TreeNode<XmlNode>(info);
		info.treeNode = tree;
		
		for (attr in xml.attributes())
			Reflect.setField(info.mAttributes, attr, xml.get(attr));
		
		stack.push(xml);
		stack.push(tree);
		
		while (top != 0)
		{
			--top;
			
			var t:TreeNode<XmlNode> = stack.pop();
			var e:Xml = stack.pop();
			
			for (i in e)
			{
				if (i.nodeType == Xml.Element)
				{
					var info = new XmlNode(i.nodeName);
					
					for (attr in i.attributes())
						Reflect.setField(info.mAttributes, attr, i.get(attr));
					
					var firstChild = i.firstChild();
					if (firstChild != null)
					{
						switch (firstChild.nodeType)
						{
							case Xml.CData, Xml.PCData:
								if (~/\S/.match(firstChild.nodeValue))
									info.data = firstChild.nodeValue;
							default:
						}
					}
					
					var node = new TreeNode<XmlNode>(info);
					info.treeNode = node;
					t.appendNode(node);
					
					stack.push(i);
					stack.push(node);
					top++;
				}
			}
		}
		
		return tree;
	}
}

/**
	An object containing the data of an xml node
**/
class XmlNode implements Dynamic<String>
{
	/**
		Node element name.
	**/
	public var name:String;
	
	/**
		PCDATA or CDATA (if any).
	**/
	public var data:String;
	
	/**
		The `TreeNode` instance storing this node.
	**/
	public var treeNode:TreeNode<XmlNode>;
	
	var mAttributes:Dynamic;
	
	public function new(name:String)
	{
		this.name = name;
		mAttributes = {};
	}
	
	public function firstChild():XmlNode
	{
		if (treeNode.hasChildren())
			return treeNode.getFirstChild().val;
		return null;
	}
	
	public function numChildren():Int
	{
		return treeNode.numChildren();
	}
	
	public function firstDescendantByName(name:String):XmlNode
	{
		return Lambda.find(treeNode, function(e) return e.name == name);
	}
	
	public function descendantsByName(name:String):Iterator<XmlNode>
	{
		return Lambda.filter(treeNode, function(e) return e.name == name).iterator();
	}
	
	public function childrenByName(name:String):Iterator<XmlNode>
	{
		var a = [];
		for (i in treeNode.childIterator())
			if (i.name == name)
				a.push(i);
		return a.iterator();
	}
	
	public function exists(name:String):Bool return Reflect.hasField(mAttributes, name);
	
	public function resolve(name:String):String
	{
		if (Reflect.hasField(mAttributes, name))
			return Reflect.field(mAttributes, name);
		else
			return null;
	}
}