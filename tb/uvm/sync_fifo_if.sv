`timescale 1ns/1ps

interface sync_fifo_if #(
    parameter int unsigned DEPTH      = 8,
    parameter int unsigned DATA_WIDTH = 8
) (input logic clk);

    logic rst_n;
    logic push;
    logic pop;
    logic [DATA_WIDTH-1:0] din;

    logic [DATA_WIDTH-1:0] dout;
    logic empty;
    logic full;
    logic [$clog2(DEPTH+1)-1:0] count;

endinterface
