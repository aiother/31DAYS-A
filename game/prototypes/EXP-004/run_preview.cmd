@echo off
rem EXP-004 dialogue and enemy card prototype. Set GODOT to override the engine path.
if "%GODOT%"=="" set "GODOT=D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe"
start "" "%GODOT%" --path "%~dp0..\.." res://prototypes/EXP-004/preview.tscn
