import haxe.PosInfos;
import sys.FileSystem;
import sys.io.File;

/**
	@author Michael Baczynski
**/
class Import
{
	static var _verbose:Bool;
	static var _extension:EReg;
	static var _excludePackage:EReg = null;
	static var _include:EReg = null;
	
	static function println(x:Dynamic, ?posInfos:PosInfos) Sys.println(Std.string(x));
	
	static function usage()
	{
		println('Creates a .hx file with import statements.');
		println('');
		println('  Usage : Import <base directory> <output file> [options]');
		println('');
		println('  Options:');
		println('   -include package: includes a package or file');
		println('   -exclude package: excludes a package or file');
		println('   -exclude package: excludes a package or file');
		println('   -v: turn on verbose mode');
		println('');
		println('  Sample usage:');
		println('   neko Import.n ./src MyClass.hx -include a.b.c -include a/b/c/Class.hx -exclude a.b.c -exclude a/b/c/Class.hx');
	}
	
	public static function main():Void
	{
		var args = Sys.args();
		
		if (args.length < 2)
		{
			usage();
			return;
		}
		
		//base directory
		var dir = args.shift();
		if (dir == '-include' || dir == '-exclude')
		{
			println('Error: invalid base directory ' + args[0]);
			Sys.exit(-1);
			return;
		}
		
		if (dir.charAt(dir.length - 1) == '/' || dir.charAt(dir.length - 1) == '\\')
			dir = dir.substr(0, dir.length - 1);
		
		//output file
		var out = args.shift();
		if (dir == '-include' || dir == '-exclude')
		{
			println('Error: invalid output file ' + args[0]);
			Sys.exit(-1);
			return;
		}
		
		//create output directory if not exists
		var outputDir = FileSystem.fullPath(out);
		outputDir = outputDir.substr(0, outputDir.lastIndexOf('\\'));
		if (!FileSystem.exists(outputDir))
		{
			println('creating output directory: ' + outputDir);
			FileSystem.createDirectory(outputDir);
		}
		
		//read options
		var includePackages = new Array<String>();
		var includeFiles    = new Array<String>();
		var excludePackages = new Array<String>();
		var excludeFiles    = new Array<String>();
		while (args.length > 0)
		{
			var option = args.shift();
			if (option == '-include')
			{
				var name = args.shift();
				
				if (~/\\/g.match(name))
					name = ~/\\/g.replace(name, '/');
					
				//classes start with uppercase, packages with lowercase
				//a.b.c.Foo
				//a.b.c
				var last = name.substr(name.lastIndexOf('.') + 1);
				if (last.charAt(0) == last.charAt(0).toLowerCase())
				{
					//lowercase, package
					includePackages.push(name);
					if (_verbose) println('including package $name');
				}
				else
				{
					//uppercase, Class.hx
					var filePath = dir + '/' + StringTools.replace(name, '.', '/') + '.hx';
					includeFiles.push(filePath);
					if (_verbose) println('excluding class $name ($filePath)');
				}
			}
			else
			if (option == '-exclude')
			{
				var name = args.shift();
				
				if (~/\\/g.match(name))
					name = ~/\\/g.replace(name, '/');
				
				var last = name.substr(name.lastIndexOf('.') + 1);
				if (last.charAt(0) == last.charAt(0).toLowerCase())
				{
					excludePackages.push(name);
					if (_verbose) println('excluding package $name');
				}
				else
				{
					var filePath = dir + '/' + StringTools.replace(name, '.', '/') + '.hx';
					excludeFiles.push(filePath);
					if (_verbose) println('excluding class $name ($filePath)');
				}
			}
			else
			if (option == '-v')
				_verbose = true;
			else
			{
				println('Error: invalid option ' + option);
				Sys.exit(-1);
				return;
			}
		}
		
		try
		{
			var fileList = new Array<String>();
			if (includePackages.length > 0)
			{
				for (pkg in includePackages)
					dumpInclude(dir, fileList, pkg.split('.'), 0);
			}
			else
				dump(dir, fileList);
			
			var filteredFileList = new Array<String>();
			if (excludePackages.length > 0)
			{
				var t = excludePackages.join('|');
				t = ~/\./g.replace(t, '\\.');
				var exclude = new EReg(t, 'g');
				for (file in fileList)
				{
					var t = ~/\//g.replace(file, '.');
					if (!exclude.match(t))
						filteredFileList.push(file);
				}
			}
			else
				filteredFileList = fileList;
			
			for (file in includeFiles)
				filteredFileList.push(file);
			
			var tmp = new Array<String>();
			for (file in filteredFileList)
			{
				var exclude = false;
				for (e in excludeFiles)
				{
					if (file == e)
					{
						exclude = true;
						if (_verbose) println(' - ' + file);
						break;
					}
				}
				
				if (exclude) continue;
				
				if (_verbose) println(' + ' + file);
				tmp.push(file);
			}
			
			filteredFileList = tmp;
			
			var output = new Array<String>();
			
			for (i in 0...filteredFileList.length)
			{
				var s = filteredFileList[i];
				
				//remove source directory
				s = s.substr(dir.length + 1);
				
				//replace '/' in path with '.' and remove extension '.hx'
				s = ~/\//g.replace(s, '.');
				s = ~/\.hx/g.replace(s, '');
				if (_verbose) println('adding class: ' + s);
				output.push(s);
			}
			
			var s = '';
			for (i in output) s += 'import ' + i + ';\n';
			
			var className = out.substr(0, out.length - 3);
			
			if (className.indexOf('/') != -1)
				className = className.substr(className.indexOf('/') + 1);
			if (className.indexOf('\\') != -1)
				className = className.substr(className.indexOf('\\') + 1);
			
			s += 'class ' + className + ' {}'; //remove .hx
			
			var fout = File.write(out, false);
			fout.writeString(s);
			fout.close();
			
			var count = filteredFileList.length;
			println('Created class $out with $count import statements.');
		}
		catch (e:Dynamic)
		{
			Sys.exit(-1);
		}
	}
	
	static function dump(dir:String, files:Array<String>):Void
	{
		var a = FileSystem.readDirectory(dir);
		for (i in 0...a.length)
		{
			var name = a[i];
			var path = dir + '/' + name;
			
			if (FileSystem.isDirectory(path))
			{
				if (!isSvn(path))
					dump(path, files);
			}
			else
			{
				if (isHx(path) && !isSvn(path))
				{
					files.push(path);
				}
			}
		}
	}
	
	static function dumpInclude(dir:String, files:Array<String>, pkg:Array<String>, level:Int):Void
	{
		var a = FileSystem.readDirectory(dir);
		for (i in 0...a.length)
		{
			var name = a[i];
			var path = dir + '/' + name;
			
			if (FileSystem.isDirectory(path))
			{
				if (!isSvn(path))
				{
					if (name != pkg[level] && level < pkg.length) continue;
					dumpInclude(path, files, pkg, level + 1);
				}
			}
			else
			{
				if (isHx(path) && !isSvn(path))
				{
					if (level >= pkg.length) files.push(path);
				}
			}
		}
	}
	
	inline static function isHx(x:String):Bool
	{
		return ~/\.hx/g.match(x);
	}
	
	inline static function isSvn(x:String):Bool
	{
		return ~/\.svn/g.match(x);
	}
}