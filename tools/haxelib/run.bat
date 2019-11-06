@echo off
if not exist ..\..\haxelib.json (
	echo wrong working directory!
	pause
	exit
)

::create temporary output folders
rmdir tmp /S /Q
mkdir tmp
mkdir tmp\git
mkdir tmp\zip

::glone git repository
git clone -b master https://github.com/polygonal/ds.git tmp/git

::make changes
haxe -neko main.n -main Changes
neko main.n tmp/git/README.md ./tmp/zip/CHANGES
if errorlevel 1 (
	echo ERROR
	pause
	exit
)

::copy git files
xcopy tmp\git tmp\zip /E /exclude:exclude.txt

::make haxelib
haxe -neko main.n -main Zip -lib format
neko main.n tmp/zip polygonal-ds.zip

::clean
rmdir tmp /S /Q
del main.n

echo done
timeout /t 3