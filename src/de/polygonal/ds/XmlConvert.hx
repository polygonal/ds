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

import de.polygonal.ds.TreeNode;
import haxe.ds.StringMap;

/**
 * <p>Helper class for converting xml data to various trees.</p>
 */
class XmlConvert
{
	/**
	 * Converts <code>xmlData</code> to a <code>TreeNode<code> structure.
	 */
	public static function toTreeNode(xmlData:String):TreeNode<XmlNodeData>
	{
		var stack = new Array<Dynamic>();
		var top = 1;
		
		var xml = Xml.parse(xmlData).firstElement();
		
		var info = new XmlNodeData(xml.nodeName);
		var tree = new TreeNode<XmlNodeData>(info);
		info.treeNode = tree;
		
		for (attr in xml.attributes())
		{
			if (attr != null)
			{
				if (info.attributes == null)
					info.attributes = new StringMap<String>();
				info.attributes.set(attr, xml.get(attr));
			}
		}
		
		stack.push(xml);
		stack.push(tree);
		
		while (top != 0)
		{
			--top;
			
			var t:TreeNode<XmlNodeData> = stack.pop();
			var e:Xml = stack.pop();
			
			for (i in e)
			{
				if (i.nodeType == Xml.Element)
				{
					var info = new XmlNodeData(i.nodeName);
					
					for (attr in i.attributes())
					{
						if (attr != null)
						{
							if (info.attributes == null)
								info.attributes = new StringMap<String>();
							info.attributes.set(attr, i.get(attr));
						}
					}
					
					var firstChild = i.firstChild();
					if (firstChild != null)
					{
						switch (firstChild.nodeType)
						{
							case Xml.CData, Xml.PCData:
								if (~/\S/.match(firstChild.nodeValue))
									info.value = firstChild.nodeValue;
							default:
						}
					}
					
					var node = new TreeNode<XmlNodeData>(info);
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
 * An object containing the data of an xml node.
 */
class XmlNodeData
{
	public var treeNode:TreeNode<XmlNodeData>;
	public var name:String;
	public var value:String;
	public var attributes:StringMap<String>;
	
	public function new(name:String)
	{
		this.name = name;
		this.value = null;
		attributes = null;
	}
	
	public function toString():String
	{
		if (value != null)
			return name + ":" + value;
		return name;
	}
}