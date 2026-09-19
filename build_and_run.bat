@echo off
setlocal enabledelayedexpansion

set output_nes_name=TheGetaway

js65 build
if !errorlevel! neq 0 exit /b !errorlevel!
start "mesen" "build/!output_nes_name!.nes"