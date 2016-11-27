import haxe.ds.StringMap;
import sys.FileSystem;

using Sys;

/**
	@author Michael Baczynski
**/
class Main
{
	public static function main()
	{
		var args = Sys.args();
		
		var directivesLut = new StringMap<Array<Array<String>>>();
		var dstPath:String = null;
		
		var targets = [];
		var fail = false;
		
		function addTarget(target:String, directives:String)
		{
			function getCompileDirectives(x:String):Array<Array<String>>
			{
				var tmp:Array<String> = x.split(",");
				var out = [];
				for (i in tmp)
				{
					if (i.indexOf("+") > -1)
						out.push(i.split("+"));
					else
						out.push([i]);
				}
				return out;
			}
			
			targets.push(target);
			directivesLut.set(target, getCompileDirectives(directives));
		}
		
		var argHandler = hxargs.Args.generate
		([
			["-swf"] => function(x:String) addTarget("swf", x),
			["-js"] => function(x:String) addTarget("js", x),
			["-neko"] => function(x:String) addTarget("neko", x),
			["-python"] => function(x:String) addTarget("python", x),
			["-cpp"] => function(x:String) addTarget("cpp", x),
			["-java"] => function(x:String) addTarget("java", x),
			["-cs"] => function(x:String) addTarget("cs", x),
			["-dst"] => function(path:String) dstPath = path,
			_ => function(arg:String) throw 'Unknown command: $arg'
		]);
		
		if (args.length == 0)
		{
			Sys.println(argHandler.getDoc());
			Sys.exit(1);
		}
		
		argHandler.parse(args);
		
		if (dstPath == null || Lambda.count(targets) == 0)
		{
			Sys.println("Insufficient arguments");
			Sys.println(argHandler.getDoc());
			Sys.exit(1);
		}
		
		dstPath = ~/\\/g.replace(dstPath, "/");
		dstPath = ~/\/$/g.replace(dstPath, "");
		
		if (!FileSystem.exists(dstPath)) 'creating output directory: $dstPath'.println();
		
		var defines = new StringMap<String>();
		defines.set("default", "");
		defines.set("debug", "-debug");
		defines.set("noinline", "--no-inline");
		defines.set("generic", "-D generic");
		defines.set("alchemy", "-D alchemy");
		
		var extLut = new StringMap<String>();
		extLut.set("swf", "swf");
		extLut.set("js", "js");
		extLut.set("neko", "n");
		extLut.set("python", "py");
		
		function toFileName(directives:Array<String>, target:String):String
		{
			var a = directives.length > 0 ? "-" + directives.join("-") : "";
			
			if (directives[0] == "default") a = "";
			
			var b = extLut.exists(target) ? "." + extLut.get(target) : "";
			return '$dstPath/$target/test$a$b';
		}
		
		function toArgs(directives:Array<String>)
		{
			var s = Lambda.map(directives, function(e) return defines.get(e)).join(" ");
			return s.length == 1 ? "" : " " + s;
		}
		
		var platformArgs = new StringMap<String>();
		platformArgs.set("swf", "-swf-version 10 -swf-header 800:600:30:FFFFFF -D swf-script-timeout=60");
		
		function error()
		{
			'\nERROR\n'.println();
			"\nPress space to continue ...".println();
			while (Sys.getChar(true) != 32) {}
			fail = true;
		}
		
		function compile(target:String):Array<String>
		{
			var files = [];
			for (directives in directivesLut.get(target))
			{
				if (directives.length == 0) continue;
				
				var output = toFileName(directives, target);
				
				var args = '-main UnitTest -cp test -cp src -lib polygonal-printf -$target $output${toArgs(directives)}' + (platformArgs.exists(target) ? (" " + platformArgs.get(target)) : "");
				'compiling $target: $output ...'.println();
				
				var tmp = [];
				for (arg in args.split(" "))
				{
					if (!~/\S/.match(arg)) continue;
					tmp.push(arg);
				}
				var args = tmp;
				var out = Sys.command(Sys.getEnv("HAXEPATH") + "\\haxe.exe", args);
				if (out == 1)
				{
					error();
					continue;
				}
				
				files.push(output);
			}
			return files;
		}
		
		function run(cmd:String, ?args:Array<String>, expected:Int = 0)
		{
			var out = Sys.command(cmd, args);
			if (out == expected)
			{
				"PASS".println();
			}
			else
			{
				"FAIL".println();
				error();
			}
		}
		
		var cwd = Sys.getCwd();
		
		var p = new sys.io.Process(Sys.getEnv("HAXEPATH") + "/haxe.exe", []);
		var s = p.stderr.readAll().toString();
		p.close();
		var r = ~/(\d\.\d.\d)/g;
		r.match(s);
		'Using HAXE COMPILER: ${Sys.getEnv("HAXEPATH")} (v${r.matched(1)})'.println();
		
		for (target in targets)
		{
			'\nTESTING -$target ...\n'.println();
			
			if (!FileSystem.exists('$dstPath/$target')) FileSystem.createDirectory('$dstPath/$target');
			
			Sys.setCwd(cwd);
			
			var files = compile(target);
			
			for (file in files)
			{
				'testing $target: $file ... '.print();
				
				switch (target)
				{
					case "swf":
						if (!FileSystem.exists(Sys.getEnv("FLASHPLAYER")))
						{
							"flash player not found, please set FLASHPLAYER environment variable".println();
							error();
							Sys.exit(1);
						}
						run(Sys.getEnv("FLASHPLAYER"), [file], 2);
					
					case "js":
						run("node", [file]);
					
					case "neko":
						run("neko", [file]);
					
					case "python":
						run("python", [file]);
					
					case "cpp":
						Sys.setCwd(cwd);
						Sys.setCwd(file);
						var exe = "UnitTest.exe";
						if (file.indexOf("debug") > -1) exe = "UnitTest-debug.exe";
						trace( "file : " + file );
						run(exe, []);
					
					case "java":
						Sys.setCwd(cwd);
						Sys.setCwd(file);
						var exe = "UnitTest.jar";
						if (file.indexOf("debug") > -1) exe = "UnitTest-debug.jar";
						run("java", ["-jar", '$file/$exe']);
					
					case "cs":
						Sys.setCwd(cwd);
						Sys.setCwd(file);
						var exe = "bin/UnitTest.exe";
						if (file.indexOf("debug") > -1) exe = "UnitTest-debug.exe";
						run(exe, []);
				}
			}
		}
		
		if (!fail) "\nALL TESTS PASSED".println();
		
		Sys.exit(fail ? 1 : 0);
	}
}