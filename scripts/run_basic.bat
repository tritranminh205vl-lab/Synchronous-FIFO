@echo off
setlocal
cd /d %~dp0\..
if not exist build mkdir build
iverilog -g2012 -Wall -s tb_sync_fifo -o build\sync_fifo_basic.vvp rtl\sync_fifo.sv tb\basic\tb_sync_fifo.sv
if errorlevel 1 exit /b 1
vvp build\sync_fifo_basic.vvp
if errorlevel 1 exit /b 1
endlocal
