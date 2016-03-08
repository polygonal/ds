@echo off
if not exist ..\..\haxelib.json (
	echo wrong working directory!
	pause
	exit
)

:create temporary output folders
rmdir tmp /S /Q
mkdir tmp
mkdir tmp\git
mkdir tmp\zip

:glone git repository
git clone -b master https://github.com/polygonal/ds.git tmp/git

:make changes
haxe -neko changes.n -main Changes
neko changes.n tmp/git/README.md tmp/zip/CHANGES
del changes.n

:copy git files
xcopy tmp\git tmp\zip /E /exclude:exclude.txt

:make haxelib
haxe -neko zip.n -main Zip -lib format
neko zip.n tmp/zip polygonal-ds.zip
del zip.n

:clean up
rmdir tmp /S /Q

pause