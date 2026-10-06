`timescale 1ns/1ps

package sync_fifo_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    parameter int unsigned DEPTH      = 8;
    parameter int unsigned DATA_WIDTH = 8;

    `include "sync_fifo_txn.svh"
    `include "sync_fifo_sequencer.svh"
    `include "sync_fifo_driver.svh"
    `include "sync_fifo_monitor.svh"
    `include "sync_fifo_scoreboard.svh"
    `include "sync_fifo_coverage.svh"
    `include "sync_fifo_agent.svh"
    `include "sync_fifo_sequences.svh"
    `include "sync_fifo_env.svh"
    `include "sync_fifo_test.svh"
endpackage
