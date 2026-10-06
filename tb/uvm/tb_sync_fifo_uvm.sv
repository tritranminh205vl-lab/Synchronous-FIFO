`timescale 1ns/1ps

module tb_sync_fifo_uvm;
    import uvm_pkg::*;
    import sync_fifo_pkg::*;

    logic clk;
    sync_fifo_if #(DEPTH, DATA_WIDTH) vif(clk);

    sync_fifo #(
        .DEPTH      (DEPTH),
        .DATA_WIDTH (DATA_WIDTH)
    ) dut (
        .clk   (clk),
        .rst_n (vif.rst_n),
        .push  (vif.push),
        .din   (vif.din),
        .pop   (vif.pop),
        .dout  (vif.dout),
        .empty (vif.empty),
        .full  (vif.full),
        .count (vif.count)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        vif.rst_n = 1'b0;
        vif.push  = 1'b0;
        vif.pop   = 1'b0;
        vif.din   = '0;
        repeat (4) @(posedge clk);
        @(negedge clk);
        vif.rst_n = 1'b1;
    end

    initial begin
        uvm_config_db#(virtual sync_fifo_if #(DEPTH, DATA_WIDTH))::set(null, "*", "vif", vif);
        run_test("sync_fifo_test");
    end

    initial begin
        $dumpfile("sync_fifo_uvm.vcd");
        $dumpvars(0, tb_sync_fifo_uvm);
    end
endmodule
