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
	A bit field packs up to 32 TRUE/FALSE flags in a single 32-bit integer.
	
	Bits are in the range __[0,31]__, where __0=first bit__ (0x01) and __31=last bit__ (0x80000000).
	
	Example:
		var b:BitField = 0; // create empty bit field
		b[0] = true; // set first bit
		b[0] = 1; // 1 or 0 is also accepted
		b[0] = 0; // unset first bit
		b[31] = true; // set last bit
		
		// test if the bit field contains at least one of the given bits:
		var b:Bitfield = 1 | 2; // set first two bits: 0b11
		b.any(0, 3, 4); // true
		
		// test if the bit field contains all of the given bits:
		var b:Bitfield = 1 | 2; // set first two bits: 0b11
		b.all(0, 2); // false
		b.all(0, 1); // true
		
		// flip bits:
		var b:Bitfield = 1 | 4; // set first and third bit: 0b101
		b.flip(1); // 0b111
		b.flip(0, 2); // 0b010
**/
abstract Bitfield(Int) to Int from Int
{
	public inline function new() this = 0;
	
	#if macro
	static function foldArgs(rest:Array<haxe.macro.Expr>):haxe.macro.Expr
	{
		return
		if (rest.length == 1)
			macro 1 << $e{rest[0]};
		else
		{
			Lambda.fold([for (i in rest) macro 1 << $e{i}],
				(a, b) -> macro $e{a} | ${b}, macro 0);
		}
	}
	#end
	
	macro public function set(inst_expr:haxe.macro.Expr, rest:Array<haxe.macro.Expr>)
	{
		/* trace('set' + rest[0]);
		switch (rest[0].expr)
		{
			case EConst(a):
				switch (a)
				{
					case CIdent(b):
						trace(b);
					case _:
				}
			case _:
				trace('unknown ' + rest[0]);
		} 
		return macro { $e{inst_expr} |= $e{foldArgs(rest)}; trace($e{rest[0]}); }
		*/
		
		return macro $e{inst_expr} |= $e{foldArgs(rest)};
	}
	
	macro public function unset(inst_expr:haxe.macro.Expr, rest:Array<haxe.macro.Expr>)
	{
		return macro $e{inst_expr} &= ~$e{foldArgs(rest)};
	}
	
	macro public function any(inst_expr:haxe.macro.Expr, rest:Array<haxe.macro.Expr>)
	{
		return macro $e{inst_expr} & $e{foldArgs(rest)} != 0;
	}
	
	macro public function all(inst_expr:haxe.macro.Expr, rest:Array<haxe.macro.Expr>)
	{
		return macro ($e{inst_expr} & $e{foldArgs(rest)}) == ($e{foldArgs(rest)});
	}
	
	macro public function flip(inst_expr:haxe.macro.Expr, rest:Array<haxe.macro.Expr>)
	{
		return macro $e{inst_expr} ^= $e{foldArgs(rest)};
	}
	
	@:noCompletion
	@:op(A += B) public inline function addAssign(rhs:Bitfield):Bitfield
	{
		return this |= rhs;
	}
	
	@:noCompletion
	@:op(A -= B) public inline function subAssign(rhs:Bitfield):Bitfield
	{
		this &= ~rhs;
		return this;
	}
	
	@:noCompletion
	@:op([]) public inline function arrayRead(i:Int):Bool
	{
		return this & (1 << i) != 0;
	}
	
	@:noCompletion
	@:op([]) public inline function arrayWriteBool(i:Int, b:Bool):Bitfield
	{
		return this = (this & ~(1 << i)) | ((b ? 1 : 0) << i);
	}
	
	@:noCompletion
	@:op([]) public inline function arrayWriteInt(i:Int, b:Int):Bitfield
	{
		return this = (this & ~(1 << i)) | (b << i);
	}
}