@echo off
iverilog -o sim %*
if errorlevel 1 exit /b
vvp sim
gtkwave dump.vcd