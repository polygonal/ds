import sys.FileSystem;
import sys.io.File;
import sys.io.FileOutput;

class Changes 
{
	static function main() 
	{
		try
		{
			var src = Sys.args()[0];
			var dst = Sys.args()[1];
			var s = File.getContent(src);
			s = s.substr(s.indexOf("## Changelog"));
			s = StringTools.replace(s, "\r", "");
			s = StringTools.replace(s, "### ", "");
			s = StringTools.replace(s, "## Changelog", "Changelog");
			if (FileSystem.exists(dst)) FileSystem.deleteFile(dst);
			File.saveContent(dst, s);
		}
		catch(error:Dynamic)
		{
			Sys.println('ERROR: $error');
			Sys.exit(1);
		}
	}
}