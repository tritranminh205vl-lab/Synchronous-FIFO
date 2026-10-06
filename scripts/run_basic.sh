#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
iverilog -g2012 -Wall -s tb_sync_fifo -o build/sync_fifo_basic.vvp \
  rtl/sync_fifo.sv tb/basic/tb_sync_fifo.sv
vvp build/sync_fifo_basic.vvp
