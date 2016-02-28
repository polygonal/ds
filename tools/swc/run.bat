@echo off
if not exist ..\..\haxelib.json (
	echo wrong working directory!
	pause
	exit
)

haxe -neko Import.n -main Import
neko Import.n ../../src Includes.hx -exclude de.polygonal.ds.mem
haxe compile.hxml

del Import.n
del Includes.hx