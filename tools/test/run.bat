@echo off
if not exist ..\..\haxelib.json (
	echo wrong working directory!
	pause
	exit
)
haxe compile.hxml
if errorlevel 1 (
	echo ERROR
	pause
	exit
)

if not exist flashplayer.txt (
	echo {absolute_path_to_flash_player_executable} > flashplayer.txt
	echo please set path to flashplayer.exe in flashplayer.txt
	echo also add output folder to trusted paths to prevent SecurityError: Error #2017 ^(Only trusted local files may cause the Flash Player to exit.^)
	pause
	exit
)

set /p FLASHPLAYER=<flashplayer.txt

if exist haxe.txt (
	set /p HAXEPATH=<haxe.txt
)

set CWD=%CD%

cd ..\..\

neko %CWD%\RunTests.n ^
-dst %CWD%\bin ^
-swf default,generic,noinline,debug,debug+noinline,debug+generic,debug+generic+noinline,alchemy,alchemy+generic ^
-js default,noinline,debug,debug+noinline ^
-neko default,noinline,debug,debug+noinline ^
-python default,noinline,debug,debug+noinline ^
-cpp default,noinline,debug,generc,noinline+debug,generic+debug,generic+debug+noinline,generic+noinline ^
-java default

cd %CWD%
del RunTests.n
pause