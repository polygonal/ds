@echo off
if not exist ..\..\haxelib.json (
	echo wrong working directory!
	pause
	exit
)

if exist haxe.txt (
	set /p HAXEPATH=<haxe.txt
)

haxe -x Main
if errorlevel 1 (
	echo ERROR
	pause
	exit
)

del Main.n
sleep 3