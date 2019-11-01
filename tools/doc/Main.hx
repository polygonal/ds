import sys.FileSystem;
import sys.io.File;

class Main
{
	public static function main()
	{
		function error(?message:String)
		{
			Sys.print("\nERROR");
			if (message != null) Sys.print(': $message');
			Sys.print("\n");
			Sys.println("\nPress space to continue ...");
			while (Sys.getChar(true) != 32) {}
			Sys.exit(1);
		}
		
		function rmdir(path:String)
		{
			if (!FileSystem.exists(path)) return;
			for (i in FileSystem.readDirectory(path))
			{
				var j = '$path/$i';
				if (FileSystem.isDirectory(j))
				{
					rmdir(j);
					FileSystem.deleteDirectory(j);
				}
				else
					FileSystem.deleteFile(j);
			}
		}
		
		function scan(path:String, output:Array<String>):Array<String>
		{
			if (!FileSystem.exists(path)) return output;
			for (i in FileSystem.readDirectory(path))
			{
				var j = '$path/$i';
				output.push(j);
				if (FileSystem.isDirectory(j))
					scan(j, output);
			}
			return output;
		}
		
		function cp(src:String, dst:String)
		{
			src = ~/\\/g.replace(src, "/");
			dst = ~/\\/g.replace(dst, "/");
			var r = new EReg('$src', "g");
			for (i in scan(src, []))
			{
				var j = r.replace(i, dst);
				if (FileSystem.isDirectory(i))
					FileSystem.createDirectory(j);
				else
					File.copy(i, j);
			}
		}
		
		var cwd = ~/\\/g.replace(Sys.getCwd(), "/");
		if (!~/ds\/tools\/doc\//.match(cwd)) error('wrong working directory: $cwd');
		rmdir("./output");
		
		function patchHaxe()
		{
			function fixIntervals(s:String):String
			{
				function docs(s:String):Array<Int>
				{
					var indices = [];
					var state = 0;
					var k = s.length, i = 0, c;
					var first = -1;
					while (i < k)
					{
						c = s.charCodeAt(i++);
						switch (state)
						{
							case 0:
								if (c == "/".code) state++;
							case 1:
								if (c == "*".code) state++;
							case 2:
								if (c == "*".code)
								{
									state++;
									first = i;
								}
								else
									state = 0;
							case 3:
								if (c == "*".code) state++;
							case 4:
								if (c == "*".code)
									state++;
								else
									state--;
							case 5:
								if (c == "/".code)
								{
									indices.push(first);
									indices.push(i - 3);
									state = 0;
								}
								else
									state = 3;
						}
					}
					return indices;
				}
				
				function replace(min:Int, max:Int, s:String)
				{
					var t = s.substring(min, max);
					if (t.indexOf("Example:") > -1) return s;
					
					var indices = [], state = 0, first = 0;
					while (min < max)
					{
						var c = s.charCodeAt(min++);
						switch (state)
						{
							case 0:
								if (c == "[".code || c == "(".code)
								{
									state++;
									first = min - 1;
								}
							
							case 1:
								if (c == "]".code || c == ")".code)
								{
									state--;
									if (s.charCodeAt(first) == "(".code && c == ")".code)
										continue;
									indices.push(first);
									indices.push(min - 1);
								}
						}
					}
					
					var lut = [];
					lut["[".code] = "&#91;";
					lut["]".code] = "&#93;";
					lut["(".code] = "&#40;";
					lut[")".code] = "&#41;";
					while (indices.length > 0)
					{
						var i = indices.pop();
						var a = s.substring(0, i);
						var b = s.substr(i + 1);
						s = a + lut[s.charCodeAt(i)] + b;
					}
					return s;
				}
				
				var out = docs(s);
				var i = out.length - 1;
				while (i > 0)
				{
					var max = out[i--];
					var min = out[i--];
					s = replace(min, max, s);
				}
				return s;
			}
			
			function fixComments(s:String):String
			{
				var out = null;
				if (~/[\[\]\(\)]/g.match(s))
					out = fixIntervals(s);
				return out;
			}
			
			if (!FileSystem.exists("./src"))
				FileSystem.createDirectory("./src");
			else
				rmdir("./src");
			
			cp(FileSystem.fullPath('$cwd../../src'), "./src");
			
			for (path in scan("./src", []))
			{
				if (FileSystem.isDirectory(path))
					continue;
				try
				{
					var s = File.getContent(path);
					s = fixComments(s);
					if (s != null) File.saveContent(path, s);
				}
				catch(error:Dynamic)
				{
					error(error);
				}
			}
		}
		
		patchHaxe();
		
		function compile()
		{
			rmdir("./xml");
			var args = ["--macro", "include('polygonal.ds', true)", "-swf", "tmp.swf", "--no-output", "-xml", "xml/swf.xml", "-cp", "./src", "-lib", "polygonal-printf"];
			var out = Sys.command("haxe", args);
			if (out > 0) error();
		}
		
		compile();
		
		function dox()
		{
			rmdir("../../api");
			Sys.command("haxelib",
				[
					"run", "dox",
					"-o", "../../api",
					"-i", "xml",
					"--title", "polygonal ds",
					"-D", "version", "2.0.0-beta",
					"-D", "website", "https://github.com/polygonal/ds",
					"-D", "description", "data structures for games",
					"-in", "polygonal\\.ds",
					"-in", "Math",
					"-in", "Array",
					"-ex", "flash.utils.ByteArray",
					"-res", "./res"
				]);
			rmdir("./src");
			rmdir("./xml");
			FileSystem.deleteDirectory("./src");
			FileSystem.deleteDirectory("./xml");
		}
		
		dox();
	}
}