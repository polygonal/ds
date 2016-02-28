@echo off
if not exist ..\..\haxelib.json (
	echo wrong working directory!
	pause
	exit
)

if exist Import.n (
	del Import.n
)

if exist bin (
	rmdir bin /S /Q
)