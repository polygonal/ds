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
 * <p>Helper functions for serializing data structures.</p>
 */
class Serialization 
{
	/**
	 * Serializes a TreeNode structure.
	 * The tree can be rebuild by calling <em>unserializeTree()</em>.
	 * @see <a href="http://eli.thegreenplace.net/2011/09/29/an-interesting-tree-serialization-algorithm-from-dwarf/" target="_blank">An interesting tree serialization algorithm from DWARF</a>
	 * @param node the root of the tree.
	 * @return a flattened tree.
	 */
	public static function serializeTree<T>(node:TreeNode<T>, list:Array<{v: T, c:Bool}> = null):Array<{v: T, c:Bool}>
	{
		if (list == null) list = new Array<{v: T, c:Bool}>();
		
		if (node.children != null)
		{
			list.push({v: node.val, c: true});
			var c = node.children;
			while (c != null)
			{
				serializeTree(c, list);
				c = c.next;
			}
            list.push(null);
		}
		else
			list.push({v: node.val, c: false});
		
		return list;
	}
	
	/**
	 * Unserializes a given <code>list</code> into a TreeNode structure.
	 * @param list the flattened tree
	 * @return the root of the tree.
	 */
	public static function unserializeTree<T>(list:Array<{v: T, c:Bool}>):TreeNode<T>
	{
		var root = new TreeNode<T>(list[0].v);
		var parentStack:Array<TreeNode<T>> = [root];
		var s = 1;
		
		for (i in 1...list.length)
		{
			var item = list[i];
			if (item != null)
			{
				var node = new TreeNode<T>(item.v);
				parentStack[s - 1].appendNode(node);
				if (item.c) parentStack[s++] = node;
			}
			else
				s--;
		}
		
		return root;
	}
}