@echo off
rem EXP-005 combat feedback effects prototype. Set GODOT to override the engine path.
if "%GODOT%"=="" set "GODOT=D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe"
start "" "%GODOT%" --path "%~dp0..\.." res://prototypes/EXP-005/preview.tscn
