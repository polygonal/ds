/*
Copyright (c) 2008-2018 Michael Baczynski, http://www.polygonal.de

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

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/**
	Assertion macro injecting assertion statements
	
	An assertion specifies a condition that you expect to be true at a point in your program.
**/
class Assert
{
	#if runtime_assert
		#if debug
		public static function assert(predicateExpr:Bool, ?msg:String)
		{
			#if js
			js.Browser.console.assert(predicateExpr, msg);
			#else
			if (!predicateExpr) throw 'Assertion failed: $msg';
			#end
		}
		#else
		@:extern public static inline function assert(predicateExpr:Bool, ?msg:String) {}
		#end
	#else
	macro public static function assert(predicateExpr:Expr, ?msgExpr:Expr):Expr
	{
		if (Context.defined("display")) return macro {};
		if (!Context.defined("debug")) return macro {};
		
		switch (Context.typeof(predicateExpr))
		{
			case TAbstract(_, _):
			case _: Context.error("`predicateExpr` should be a boolean", predicateExpr.pos);
		}
		
		var p = Context.currentPos();
		var location = haxe.macro.PositionTools.toLocation(p);
		var locationInfos = " (in file " +  location.file + ", line " + location.range.start.line + ")";
		
		var extra = false;
		var error = false;
		switch (Context.typeof(msgExpr))
		{
			case TMono(t):
				error = t.get() != null;
			
			case TInst(t, _):
				error = t.get().name != "String";
				extra = true;
			
			case _:
				error = true;
		}
		if (error) Context.error("`msgExpr` should be a string", msgExpr.pos);
		
		var predicate = new haxe.macro.Printer().printExpr(predicateExpr);
		
		var infos =
		if (extra)
			macro ${msgExpr} + $v{" [" + predicate + "]"} + $v{locationInfos};
		else
			macro $v{predicate} + $v{locationInfos};
		
		return
		if (Context.defined("js"))
		{
			{expr: ECall(
				{pos: p, expr: EField(macro $p{["js", "Syntax"]}, "code")},
				[
					macro $v{"console.assert({0}, {1})"},
					predicateExpr,
					infos
				]), pos: p};
		}
		else
		{
			{expr: EIf(
				{expr: EBinop(OpNotEq, macro $i{"true"}, predicateExpr), pos: p},
				{expr: EThrow(macro $v{"Assertion failed:"} + ${infos}), pos: p}, null),
				pos: p};
		}
	}
	#end
}