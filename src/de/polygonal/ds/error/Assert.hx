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
package de.polygonal.ds.error;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/**
	Assertion macro injects an assertion statement.
	
	An assertion specifies a condition that you expect to be true at a point in your program.
	
	If that condition is not true, the assertion fails, throwing an instance of the `AssertError` class.
**/
class Assert
{
	macro public static function assert(predicate:Expr, ?info:Expr):Expr
	{
		if (!Context.defined("debug")) return macro {};
		
		var error = false;
		switch (Context.typeof(predicate))
		{
			case TAbstract(_, _):
			case _: error = true;
		}
		
		if (error) Context.error("predicate should be a boolean", predicate.pos);
		
		var hasInfo = true;
		switch (Context.typeof(info))
		{
			case TMono(t):
				error = t.get() != null;
				hasInfo = false;
				
			case TInst(t, _):
				error = t.get().name != "String";
			case _: error = true;
		}
		
		if (error) Context.error("info should be a string", info.pos);
		
		var p = Context.currentPos();
		
		var infoStr =
		if (hasInfo)
			EBinop(OpAdd, info, {expr: EConst(CString(" (" + new haxe.macro.Printer().printExpr(predicate) + ")")), pos: p});
		else
			EConst(CString(new haxe.macro.Printer().printExpr(predicate)));
		
		var eif = {expr: EThrow({expr: ENew({name: "AssertError", pack: ["de", "polygonal", "ds", "error"], params: []}, [{expr: infoStr, pos: p}]), pos: p}), pos: p};
		var econd = {expr: EBinop(OpNotEq, {expr: EConst(CIdent("true")), pos: p}, predicate), pos: p};
		return {expr: EIf(econd, eif, null), pos: p};
	}
}