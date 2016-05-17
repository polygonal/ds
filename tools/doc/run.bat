@echo off
if not exist ..\..\haxelib.json (
	echo wrong working directory!
	pause
	exit
)

if exist haxe.txt (
	set /p HAXEPATH=<haxe.txt
)

haxelib install dox
haxe -x Main
if errorlevel 1 (
	echo ERROR
	pause
	exit
)

echo done
del Main.n
sleep 3