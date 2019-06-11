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

/**
	An assertion specifies a condition that you expect to be true at a point in your program.
**/
class Assert
{
	#if (!debug || no_debug_assert)
	
		#if no_macro_assert
		extern public static inline function assert(predicate:Bool, ?message:String) {}
		#else
		macro public static inline function assert(predicate:haxe.macro.Expr, rest:Array<haxe.macro.Expr>) return macro {}
		#end
	
	#else
	
		#if no_macro_assert
		public static inline function assert(predicate:Bool, ?message:String, ?pos:haxe.PosInfos) _assert(predicate, message, pos);
		#else
		macro public static inline function assert(predicateExpr:haxe.macro.Expr, ?message:haxe.macro.Expr)
		{
			var predicate  = new haxe.macro.Printer().printExpr(predicateExpr);
			var p          = haxe.macro.Context.currentPos();
			var location   = haxe.macro.PositionTools.toLocation(p);
			var methodName = haxe.macro.Context.getLocalMethod();
			var className  = haxe.macro.Context.getLocalClass().toString();
			var infos      = macro {fileName: $v{location.file}, lineNumber: $v{location.range.start.line}, className: $v{className}, methodName: $v{methodName}};
			if (message.expr.match(EConst(CIdent("null"))))
				return macro untyped polygonal.ds.tools.Assert._assert($e{predicateExpr}, $v{predicate}, $e{infos});
			return macro untyped polygonal.ds.tools.Assert._assert($e{predicateExpr}, ${message} + "(" + $v{predicate} + ")", $e{infos});
		}
		#end
		
		static function _assert(predicate:Bool, message:String, pos:haxe.PosInfos)
		{
			if (!predicate)
			{
				var locationInfos = 'in file ${pos.fileName}, line ${pos.lineNumber}';
				var s = message == null ? locationInfos : '$message ($locationInfos)';
				s = 'Assertion failed' + (message != null ? ": " : " ") + s;
				
				#if js
				throw new js.Error(s);
				#else
				throw s;
				#end
			}
		}
	
	#end
}