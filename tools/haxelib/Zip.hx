import format.zip.Tools;
import haxe.crypto.Crc32;
import haxe.io.Bytes;
import haxe.io.BytesOutput;
import haxe.zip.Entry.ExtraField;
import sys.FileSystem;
import sys.io.File;

typedef Resource = { fileName:String, filePath:String }

class Zip
{
	public static function main()
	{
		try
		{
			var srcPath = Sys.args()[0];
			var dstFile = Sys.args()[1];
			
			function writeBytesToFile(bytes:Bytes, file:String):Void
			{
				var fout = File.write(file, true);
				fout.writeBytes(bytes, 0, bytes.length);
				fout.close();
			}
			
			function readContents(path:String, entries:Array<Resource>, inset:String)
			{
				for (item in FileSystem.readDirectory(path))
				{
					if (FileSystem.isDirectory('$path/$item'))
					{
						Sys.println('${inset}read directory $path/$item');
						
						readContents('$path/$item', entries, inset + '  ');
						continue;
					}
					
					var fileName = item;
					
					//remove input path
					var zipPath = path;
					zipPath = zipPath.substr(srcPath.length);
					if (zipPath.charAt(0) == '/')
					{
						zipPath = zipPath.substr(1);
						fileName = '$zipPath/$item';
					}
					
					Sys.println('${inset}add file $fileName');
					
					entries.push({fileName: fileName, filePath: '$path/$item'});
				}
			}
			
			function zipAssets(entries:Array<Resource>)
			{
				function createZipEntry(resource:Resource)
				{
					var fin = File.read(resource.filePath, true);
					var bytes = fin.readAll();
					fin.close();
					return
					{
						fileName: resource.fileName,
						fileSize: bytes.length,
						fileTime: FileSystem.stat(resource.filePath).ctime,
						compressed: false,
						dataSize: 0,
						data: bytes,
						crc32: Crc32.make(bytes),
						extraFields: new List<ExtraField>()
					}
				}
				
				var list = new List();
				for (e in entries) list.add(createZipEntry(e));
				
				var output = new BytesOutput();
				var writer = new format.zip.Writer(output);
				
				for (i in list) Tools.compress(i, 9);
				writer.write(list);
				writeBytesToFile(output.getBytes(), dstFile);
			}
			
			var entries = [];
			readContents(srcPath, entries, '');
			zipAssets(entries);
		}
		catch(error:Dynamic)
		{
			Sys.println('ERROR: $error');
			Sys.exit(1);
		}
	}
}