/*
Copyright (c) 2018 Michael Baczynski, http://www.polygonal.de

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
package ds;

import haxe.EnumFlags;
import haxe.ds.Vector;

/**
	C printf implementation
	
	@see https://github.com/polygonal/printf
 */
class Printf
{
	/**
		Number of digits to be printed after the decimal point; default is 6.
	**/
	public static var DEFAULT_PRECISION = 6;
	
	/**
		Number of digits to be printed for the exponent part; default is 2.
	**/
	public static var DEFAULT_NUM_EXP_DIGITS = 2;
	
	static var _initialized = false;
	
	inline static var PAD_0 = 0;
	inline static var PAD_SPACE = 20;
	static var _padChars:Vector<String>;
	
	static var _tmp:Vector<Int>;
	
	static function init()
	{
		_padChars = new Vector(40);
		for (i in 0...20) _padChars.set(i     , StringTools.rpad("", "0", i));
		for (i in 0...20) _padChars.set(i + 20, StringTools.rpad("", " ", i));
		_tmp = new Vector(64);
	}
	
	/**
		Writes formatted data to a string.
		
		Evaluation is done at run-time.
	**/
	public static function format(fmt:String, args:Array<Dynamic>):String
	{
		if (!_initialized)
		{
			_initialized = true;
			init();
		}
		
		var output = new StringBuf();
		var argIndex = 0;
		var tokens = []; //TODO buffer, watch for recursive calls
		for (i in 0...tokenize(fmt, tokens))
		{
			switch (tokens[i])
			{
				case Unknown(_, _):
					throw new PrintfError("Invalid format specifier.");
				
				case Raw(string):
					output.add(string);
				
				case Property(name):
					if (!Reflect.hasField(args[0], name))
						throw new PrintfError('no field named "$name" found');
					output.add(Std.string(Reflect.field(args[0], name)));
					argIndex++;
				
				case Tag(type, tagArgs):
					if (tagArgs.width == null)
					{
						if (!Std.is(args[argIndex], Int))
							throw new PrintfError("invalid 'width' argument");
						tagArgs.width = args[argIndex++];
					}
					
					if (tagArgs.precision == null)
					{
						if (!Std.is(args[argIndex], Int))
							throw new PrintfError("invalid 'precision' argument");
						tagArgs.precision = args[argIndex++];
					}
					
					var value:Dynamic;
					if (tagArgs.pos > -1)
					{
						if (tagArgs.pos > args.length - 1)
							throw new PrintfError("argument index out of range");
						value = args[tagArgs.pos];
					}
					else
						value = args[argIndex++];
					
					if (value == null) value = "null";
					
					switch (type)
					{
						case FmtFloat(floatType):
							switch (floatType)
							{
								case FNormal: formatFloat(value, tagArgs, output);
								case FScientific: formatScientific(value, tagArgs, output);
								case FNatural: formatNaturalFloat(value, tagArgs, output);
							}
						
						case FmtInt(intType):
							switch (intType)
							{
								case ICharacter: formatCharacter(value, tagArgs, output);
								case ISignedDecimal: formatSignedDecimal(value, tagArgs, output);
								case IUnsignedDecimal: formatUnsignedDecimal(value, tagArgs, output);
								case IOctal: formatOctal(value, tagArgs, output);
								case IHex: formatHexadecimal(value, tagArgs, output);
								case IBin: formatBinary(value, tagArgs, output);
							}
						
						case FmtString:
							formatString(value, tagArgs, output);
						
						case FmtPointer:
							throw new PrintfError("specifier 'p' is not supported");
						
						case FmtNothing:
							throw new PrintfError("specifier 'n' is not supported");
					};
			}
		}
		
		return output.toString();
	}
	
	static function tokenize(fmt:String, output:Array<FormatToken>):Int
	{
		var i = 0, c = 0, n = 0;
		
		inline function isDigit(x) return x >= 48 && x <= 57;
		inline function next() c = StringTools.fastCodeAt(fmt, i++);
		
		var buf = new StringBuf();
		var k = fmt.length;
		while (i < k)
		{
			next();
			if (c == "%".code)
			{
				next();
				if (c == "%".code)
				{
					buf.addChar(c);
					continue;
				}
				
				//flush last string
				if (buf.length > 0)
				{
					output[n++] = Raw(buf.toString());
					buf = new StringBuf();
				}
				
				var token:FormatToken;
				
				if (c == "(".code) //named parameter?
				{
					var endPos = fmt.indexOf(")", i);
					if (endPos == -1)
						token = Unknown("named parameter", i);
					else
					{
						var paramName = fmt.substr(i, endPos - i);
						i = endPos + 1;
						token = Property(paramName);
					}
				}
				else
				{
					var params:FormatArgs = { flags: EnumFlags.ofInt(0), pos: -1, width: -1, precision: -1 };
					
					//read flags: -+(space)#0
					while (c >= " ".code && c <= "0".code)
					{
						switch (c)
						{
							case "-".code: next(); params.flags.set(Minus);
							case "+".code: next(); params.flags.set(Plus);
							case "#".code: next(); params.flags.set(Sharp);
							case "0".code: next(); params.flags.set(Zero);
							case " ".code: next(); params.flags.set(Space);
							case _: break;
						}
					}
					
					//check for conflicting flags
					if (params.flags.has(Minus) && params.flags.has(Zero))
						params.flags.unset(Zero);
					if (params.flags.has(Space) && params.flags.has(Plus))
						params.flags.unset(Space);
					
					//read width: (number) or "*"
					if (c == "*".code)
					{
						params.width = null;
						next();
					}
					else
					if (isDigit(c))
					{
						var w = 0;
						while (isDigit(c))
						{
							w = c - "0".code + w * 10;
							next();
						}
						params.width = w;
						
						//check if number was a position, not a width
						if (c == "$".code)
						{
							params.pos = w - 1;
							params.width = -1;
							next();
							
							//re-check for width
							if (c == "*".code)
							{
								params.width = null;
								next();
							}
							else
							if (isDigit(c))
							{
								var w = 0;
								while (isDigit(c))
								{
									w = c - "0".code + w * 10;
									next();
								}
								params.width = w;
							}
						}
					}
					
					//read .precision: .(number) or ".*"
					if (c == ".".code)
					{
						next();
						if (c == "*".code)
						{
							params.precision = null;
							next();
						}
						else
						{
							var p = 0;
							if (isDigit(c))
							{
								while (isDigit(c))
								{
									p = c - "0".code + p * 10;
									next();
								}
							}
							params.precision = p;
						}
					}
					
					//read length: hlL
					while (c >= "L".code && c <= "l".code)
					{
						switch (c)
						{
							case "h".code: next(); params.flags.set(LengthH);
							case "l".code: next(); params.flags.set(LengthLowerCaseL);
							case "L".code: next(); params.flags.set(LengthUpperCaseL);
							case _: break;
						}
					}
					
					//read specifier: cdieEfgGosuxX
					if (c >= "E".code && c <= "x".code)
					{
						var type =
						switch (c)
						{
							case "i".code: FmtInt(ISignedDecimal);
							case "d".code: FmtInt(ISignedDecimal);
							case "u".code: FmtInt(IUnsignedDecimal);
							case "c".code: FmtInt(ICharacter);
							case "x".code: FmtInt(IHex);
							case "X".code: params.flags.set(UpperCase); FmtInt(IHex);
							case "o".code: FmtInt(IOctal);
							case "b".code: FmtInt(IBin);
							case "f".code: FmtFloat(FNormal);
							case "e".code: FmtFloat(FScientific);
							case "E".code: params.flags.set(UpperCase); FmtFloat(FScientific);
							case "g".code: FmtFloat(FNatural);
							case "G".code: params.flags.set(UpperCase); FmtFloat(FNatural);
							case "s".code: FmtString;
							case "p".code: FmtPointer;
							case "n".code: FmtNothing;
							case _: null;
						}
						
						token =
						if (type == null)
							Unknown(String.fromCharCode(c), i);
						else
							Tag(type, params);
					}
					else
						token = Unknown(String.fromCharCode(c), i);
				}
				output[n++] = token;
			}
			else
				buf.addChar(c);
		}
		
		if (buf.length > 0) output[n++] = Raw(buf.toString());
		return n;
	}
	
	static function formatBinary(value:Int, args:FormatArgs, buf:StringBuf)
	{
		inline function add(x) buf.add(x);
		
		var f = args.flags;
		var p = args.precision;
		var w = args.width;
		
		if (f.has(LengthH)) value &= 0xffff;
		
		if (value == 0)
		{
			if (p == 0) return;
			f.unset(Sharp);
		}
		
		if (p == -1) p = 1;
		
		var tmp = _tmp;
		var l = 0;
		do
		{
			tmp[l++] = value & 1;
			value >>>= 1;
		}
		while (value > 0);
		var m = l;
		
		if (f.has(Minus))
		{
			if (f.has(Sharp)) add("0b");
			if (p > l) for (i in 0...p - l) add("0");
			while (--m > -1) buf.addChar("0".code + tmp[m]);
			if (f.has(Sharp)) w -= 2;
			if (p > l) l = p;
			if (w > l) for (i in 0...w - l) add(" ");
		}
		else
		{
			var k = l;
			if (p > k) k = p;
			if (f.has(Sharp)) w -= 2;
			if (w > k)
			{
				if (f.has(Zero) && p == 1)
					for (i in 0...w - k) add("0");
				else
					for (i in 0...w - k) add(" ");
			}
			if (f.has(Sharp)) add("0b");
			if (p > l) for (i in 0...p - l) add("0");
			while (--m > -1) buf.addChar("0".code + tmp[m]);
		}
	}
	
	static function formatOctal(value:Int, args:FormatArgs, buf:StringBuf)
	{
		inline function add(x) buf.add(x);
		
		var f = args.flags;
		var p = args.precision;
		var w = args.width;
		
		if (f.has(LengthH)) value &= 0xffff;
		
		if (value == 0)
		{
			if (p == 0)
			{
				add(f.has(Sharp) ? "0" : "");
				return;
			}
			f.unset(Sharp);
		}
		
		var tmp = _tmp;
		var l = 0;
		do
		{
			tmp[l++] = value & 7;
			value >>>= 3;
		}
		while (value > 0);
		var m = l;
		
		if (p != -1)
		{
			if (f.has(Zero))
			{
				f.unset(Zero);
				f.set(Space);
			}
		}
		else
			p  = 1;
		
		if (f.has(Minus))
		{
			if (f.has(Sharp))
			{
				add("0");
				l++;
			}
			if (p > l) for (i in 0...p - l) add("0");
			
			while (--m > -1) add(String.fromCharCode("0".code + tmp[m]));
			
			if (p > l) l = p;
			if (w > l) for (i in 0...w - l) add(" ");
		}
		else
		{
			if (f.has(Sharp)) l++;
			
			var k = l;
			if (p > k) k = p;
			if (w > k)
			{
				if (f.has(Zero))
					for (i in 0...w - k) add("0");
				else
					for (i in 0...w - k) add(" ");
			}
			if (f.has(Sharp)) add("0");
			if (p > l) for (i in 0...p - l) add("0");
			
			while (--m > -1) add(String.fromCharCode("0".code + tmp[m]));
		}
	}
	
	static function formatHexadecimal(value:Int, args:FormatArgs, buf:StringBuf)
	{
		inline function add(x) buf.add(x);
		
		var f = args.flags;
		var p = args.precision;
		var w = args.width;
		
		if (f.has(LengthH)) value &= 0xffff;
		
		if (value == 0)
		{
			if (p == 0) return;
			f.unset(Sharp);
		}
		
		if (p == -1) p = 1;
		
		var tmp = _tmp;
		var l = 0;
		do
		{
			tmp[l++] = value & 15;
			value >>>= 4;
		}
		while (value > 0);
		var m = l;
		
		inline function addNumber()
		{
			var a = f.has(UpperCase) ? "A".code : "a".code;
			while (--m > -1)
			{
				var v = tmp[m];
				if (v < 10)
					add(String.fromCharCode("0".code + v));
				else
					add(String.fromCharCode(a + (v - 10)));
			}
		}
		
		if (f.has(Minus))
		{
			if (f.has(Sharp))
			{
				if (f.has(UpperCase))
					add("0X");
				else
					add("0x");
			}
			
			if (p > l) for (i in 0...p - l) add("0");
			
			addNumber();
			
			if (f.has(Sharp)) w -= 2;
			if (p > l) l = p;
			if (w > l) for (i in 0...w - l) add(" ");
		}
		else
		{
			var k = l;
			if (p > k) k = p;
			
			if (f.has(Sharp)) w -= 2;
			
			if (w > k)
			{
				if (f.has(Zero) && p == 1)
					for (i in 0...w - k) add("0");
				else
					for (i in 0...w - k) add(" ");
			}
			
			if (f.has(Sharp))
			{
				if (f.has(UpperCase))
					add("0X");
				else
					add("0x");
			}
			
			if (p > l) for (i in 0...p - l) add("0");
			
			addNumber();
		}
	}
	
	static function formatSignedDecimal(value:Int, args:FormatArgs, buf:StringBuf)
	{
		inline function add(x) buf.add(x);
		
		var f = args.flags;
		var p = args.precision;
		var w = args.width;
		if (p == 0 && value == 0) return;
		
		if (f.has(LengthH)) value &= 0xffff;
		var s = Std.string(iabs(value));
		var l = s.length;
		var sign =
		if (value < 0)
			"-";
		else
		{
			if (f.has(Plus))
				"+";
			else
			if (f.has(Space))
				" ";
			else
				null;
		}
		
		var hasSign = sign != null;
		
		if (f.has(Minus))
		{
			if (hasSign) add(sign);
			if (p > l) for (i in 0...p - l) add("0");
			
			add(s);
			
			if (p > l) l = p;
			l += (hasSign ? 1 : 0);
			if (w > l) for (i in 0...w - l) add(" ");
		}
		else
		{
			var k = l + (hasSign ? 1 : 0);
			if (p > k) k = p;
			if (w > k)
			{
				if (f.has(Zero))
				{
					if (hasSign) add(sign);
					for (i in 0...w - k) add("0");
				}
				else
					for (i in 0...w - k) add(" ");
			}
			
			if (hasSign && !f.has(Zero))
				add(sign);
			
			if (p > l) for (i in 0...p - l) add("0");
			add(s);
		}
	}
	
	static function formatUnsignedDecimal(value:Int, args:FormatArgs, buf:StringBuf)
	{
		inline function add(x) buf.add(x);
		
		if (value >= 0)
		{
			formatSignedDecimal(value, args, buf);
			return;
		}
		
		var s = haxe.Int64.toStr(haxe.Int64.make(0, value));
		var l = s.length;
		
		var f = args.flags;
		var p = args.precision;
		var w = args.width;
		
		if (f.has(Minus))
		{
			if (p > l) for (i in 0...p - l) add("0");
			add(s);
			if (p > l) l = p;
			if (w > l) for (i in 0...w - l) add(" ");
		}
		else
		{
			var k = l;
			if (p > k) k = p;
			if (w > k)
			{
				if (f.has(Zero))
					for (i in 0...w - k) add("0");
				else
					for (i in 0...w - k) add(" ");
			}
			if (p > l) for (i in 0...p - l) add("0");
			add(s);
		}
	}
	
	static function formatNaturalFloat(value:Float, args:FormatArgs, buf:StringBuf)
	{
		inline function add(x) buf.add(x);
		
		//TODO: precompute lengths
		// args.precision = 0;
		
		var tmp:StringBuf;
		
		tmp = new StringBuf();
		formatFloat(value, args, tmp);
		var formatedFloat = tmp.toString();
		trace('formatedFloat ' + formatedFloat);
		
		tmp = new StringBuf();
		formatScientific(value, args, tmp);
		var formatedScientific = tmp.toString();
		
		trace('formatedScientific ' + formatedScientific);
		
		var s = (formatedFloat.length <= formatedScientific.length) ? formatedFloat : formatedScientific;
		
		add(s);
	}
	
	static function formatScientific(value:Float, args:FormatArgs, buf:StringBuf)
	{
		inline function add(x) buf.add(x);
		
		var f = args.flags;
		var p = args.precision;
		if (p == -1) p = DEFAULT_PRECISION;
		
		var sign:Int, exponent:Int;
		
		var s = "";
		
		if (value == 0)
		{
			sign = 0;
			exponent = 0;
			s += "0";
			if (p > 0)
			{
				s += ".";
				for (i in 0...p) s += "0";
			}
		}
		else
		{
			var m = Math;
			sign = (value > 0.) ? 1 : (value < 0. ? -1 : 0);
			value = m.abs(value);
			exponent = m.floor(Math.log(value) / 2.302585092994046); //LN10
			value = value / m.pow(10, exponent);
			value = roundTo(value, m.pow(0.1, p));
		}
		
		if (value != 0)
			s += Std.string(value).substr(0, p + 2);
		
		s += f.has(UpperCase) ? "E" : "e";
		s += exponent >= 0 ? "+" : "-";
		s += pad(Std.string(iabs(exponent)), DEFAULT_NUM_EXP_DIGITS, PAD_0, -1);
		
		var printSign = sign == -1 || (f.has(Plus) || f.has(Space));
		if (printSign && !f.has(Zero))
			s = (sign == -1 ? "-" : (f.has(Plus) ? "+" : " ")) + s;
		
		if (args.width > 0)
		{
			var w = args.width;
			if (printSign && f.has(Zero)) w--;
			s = pad(s, w, f.has(Zero) ? PAD_0 : PAD_SPACE, -1);
		}
		
		if (printSign && f.has(Zero))
			s = (sign == -1 ? "-" : (f.has(Plus) ? "+" : " ")) + s;
		
		add(s);
	}
	
	static function formatFloat(value:Float, args:FormatArgs, buf:StringBuf)
	{
		inline function add(x) buf.add(x);
		
		var f = args.flags;
		var p = args.precision;
		if (p == -1) p = DEFAULT_PRECISION;
		var w = args.width;
		
		var isNegative = value < 0;
		
		var s;
		if (p == 0)
		{
			s = Std.string(Math.round(value));
			if (f.has(Sharp)) s += ".";
		}
		else
		{
			#if (flash || js)
			s = untyped value.toFixed(p);
			#elseif php
			s = untyped __call__("number_format", value, p, ".", "");
			#elseif jvm
			s = java.NativeString.format(java.util.Locale.US, '%.${p}f', value);
			#elseif java
			s = untyped __java__("String.format({0}, {1})", '%.${p}f', value);
			s = ~/,/.replace(s, ".");
			#elseif cs
			var separator:String = untyped __cs__("System.Globalization.CultureInfo.CurrentCulture.NumberFormat.NumberGroupSeparator");
			untyped __cs__("System.Globalization.CultureInfo.CurrentCulture.NumberFormat.NumberGroupSeparator = \"\"");
			s = untyped value.ToString("N" + p);
			untyped __cs__("System.Globalization.CultureInfo.CurrentCulture.NumberFormat.NumberGroupSeparator = separator");
			#else
			value = roundTo(value, Math.pow(.1, p));
			if (Math.isNaN(value))
				s = "NaN";
			else
			{
				var t = Std.int(Math.pow(10, p));
				s = Std.string(Std.int(value * t) / t);
				var i = s.indexOf(".");
				if (i != -1)
				{
					for (i in s.substr(i + 1).length...p)
						s += "0";
				}
				else
				{
					s += ".";
					for (i in 0...p)
						s += "0";
				}
			}
			#end
		}
		
		//string length includes minus sign
		var l = s.length;
		
		//remove minus sign, add later in case of zero-padding
		if (isNegative && s.indexOf("-") > -1) s = s.substr(1);
		
		var sign = null;
		if (f.has(Plus) && !isNegative)
		{
			sign = "+";
			l++;
		}
		else
		if (f.has(Space))
		{
			sign = " ";
			l++;
		}
		else
		if (isNegative)
			sign = "-";
		
		var hasSign = sign != null;
		if (f.has(Minus))
		{
			if (hasSign) add(sign);
			add(s);
			if (w > l) for (i in 0...w - l) add(" ");
		}
		else
		{
			if (w > l)
			{
				if (f.has(Zero))
				{
					if (hasSign)
					{
						add(sign);
						hasSign = false;
					}
					for (i in 0...w - l) add("0");
				}
				else
					for (i in 0...w - l) add(" ");
			}
			
			if (hasSign) add(sign);
			add(s);
		}
	}
	
	static function formatCharacter(x:Int, args:FormatArgs, buf:StringBuf)
	{
		inline function add(x) buf.add(x);
		
		if (args.flags.has(Minus))
		{
			add(String.fromCharCode(x));
			for (i in 0...args.width - 1) add(" ");
		}
		else
		{
			for (i in 0...args.width - 1) add(" ");
			add(String.fromCharCode(x));
		}
	}
	
	static function formatString(value:String, args:FormatArgs, buf:StringBuf)
	{
		inline function add(x) buf.add(x);
		inline function addSub(x, p, l) buf.addSub(x, p, l);
		
		var l = value.length;
		
		var p = args.precision;
		
		if (args.flags.has(Minus))
		{
			if (p != -1)
			{
				addSub(value, 0, p);
				l = p;
			}
			else
				add(value);
			for (i in 0...args.width - l) add(" ");
		}
		else
		{
			if (p != -1) l = p;
			for (i in 0...args.width - l) add(" ");
			if (p != -1)
				addSub(value, 0, p);
			else
				add(value);
		}
	}
	
	static inline function pad(s:String, l:Int, type:Int, dir:Int):String
	{
		var c = l - s.length;
		return
		if (c < 1) s;
		else
		{
			var t;
			if (c > 30)
			{
				var char = type == PAD_0 ? "0" : " ";
				t = char;
				for (i in 0...c - 1) t += char;
			}
			else
				t = _padChars[type + c];
			
			return dir > 0 ? s + t : t + s;
		}
	}
	
	//TODO static inline function max(a:Int, b:Int) return a < b ? a : b;
	
	extern static inline function roundTo(x:Float, y:Float):Float
		return Math.round(x / y) * y;
	
	extern static inline function iabs(x:Int):Int
		return x < 0 ? -x : x;
}

class PrintfError
{
	public var message:String;
	
	public function new(message:String) 
	{
		this.message = message;
	}
	
	public function toString():String
	{
		return message;
	}
}

@:publicFields
@:structInit
private class FormatArgs
{
	var flags:EnumFlags<FormatFlag>;
	var pos:Int;
	var width:Null<Int>;
	var precision:Null<Int>;
}

private enum FormatFlag
{
	Minus;
	Plus;
	Space;
	Sharp;
	Zero;
	LengthH;
	LengthUpperCaseL;
	LengthLowerCaseL;
	UpperCase;
}

private enum FormatToken
{
	Raw(string:String);
	Tag(type:FormatDataType, args:FormatArgs);
	Property(name:String);
	Unknown(string:String, pos:Int);
}

private enum FormatDataType
{
	FmtInt(type:IntType);
	FmtFloat(floatType:FloatType);
	FmtString;
	FmtPointer;
	FmtNothing;
}

private enum IntType
{
	ICharacter;
	ISignedDecimal;
	IUnsignedDecimal;
	IOctal;
	IHex;
	IBin;
}

private enum FloatType
{
	FNormal;
	FScientific;
	FNatural;
}