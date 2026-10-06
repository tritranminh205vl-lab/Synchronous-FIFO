@echo off
setlocal
cd /d %~dp0\..
if not exist build mkdir build
yosys -s synth\sync_fifo.ys
endlocal
