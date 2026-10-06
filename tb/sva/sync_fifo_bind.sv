`timescale 1ns/1ps

bind sync_fifo sync_fifo_sva #(
    .DEPTH      (DEPTH),
    .DATA_WIDTH (DATA_WIDTH)
) u_sync_fifo_sva (
    .clk   (clk),
    .rst_n (rst_n),
    .push  (push),
    .pop   (pop),
    .din   (din),
    .dout  (dout),
    .empty (empty),
    .full  (full),
    .count (count)
);
