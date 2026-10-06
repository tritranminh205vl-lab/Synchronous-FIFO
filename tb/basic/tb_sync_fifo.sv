`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// Self-checking, simulator-light testbench.
// Intended for Icarus Verilog (-g2012), Questa, VCS, Xcelium, etc.
//
// Verification strategy:
//   1. Directed corner cases.
//   2. Independent reference model.
//   3. Cycle-by-cycle scoreboard.
//   4. Protocol/invariant checks.
//   5. Constrained pseudo-random traffic.
//   6. Manual functional coverage for open-source simulator portability.
// -----------------------------------------------------------------------------
module tb_sync_fifo;

    localparam int unsigned DEPTH         = 8;
    localparam int unsigned DATA_WIDTH    = 8;
    localparam int unsigned COUNT_WIDTH   = $clog2(DEPTH + 1);
    localparam int unsigned RANDOM_CYCLES = 1000;

    logic                      clk;
    logic                      rst_n;
    logic                      push;
    logic [DATA_WIDTH-1:0]     din;
    logic                      pop;

    logic [DATA_WIDTH-1:0]     dout;
    logic                      empty;
    logic                      full;
    logic [COUNT_WIDTH-1:0]    count;

    // Reference model storage. This is deliberately independent from DUT
    // pointers/count so bugs in the RTL do not automatically reproduce here.
    logic [DATA_WIDTH-1:0] ref_mem [0:DEPTH-1];
    int ref_wr_ptr;
    int ref_rd_ptr;
    int ref_count;
    logic [DATA_WIDTH-1:0] ref_dout;

    int pass_count;
    int fail_count;
    int cycle_count;
    int unsigned seed;

    // Coverage buckets.
    bit cov_occ_empty;
    bit cov_occ_middle;
    bit cov_occ_full;
    bit cov_idle;
    bit cov_push_only;
    bit cov_pop_only;
    bit cov_both;
    bit cov_overflow_attempt;
    bit cov_underflow_attempt;
    bit cov_both_empty;
    bit cov_both_middle;
    bit cov_both_full;
    bit cov_wrap_write;
    bit cov_wrap_read;
    bit cov_reset_nonempty;

    // 3 occupancy classes x 4 request combinations.
    bit cov_cross[0:2][0:3];

    sync_fifo #(
        .DEPTH      (DEPTH),
        .DATA_WIDTH (DATA_WIDTH)
    ) dut (
        .clk   (clk),
        .rst_n (rst_n),
        .push  (push),
        .din   (din),
        .pop   (pop),
        .dout  (dout),
        .empty (empty),
        .full  (full),
        .count (count)
    );

    // 100 MHz clock.
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task automatic model_reset;
        int i;
        begin
            ref_wr_ptr = 0;
            ref_rd_ptr = 0;
            ref_count  = 0;
            ref_dout   = '0;
            for (i = 0; i < DEPTH; i++)
                ref_mem[i] = '0;
        end
    endtask

    task automatic fail(input string message);
        begin
            fail_count++;
            $display("[%0t][FAIL] %s", $time, message);
        end
    endtask

    task automatic check_post_state(
        input int expected_count,
        input logic [DATA_WIDTH-1:0] expected_dout
    );
        logic exp_empty;
        logic exp_full;
        begin
            exp_empty = (expected_count == 0);
            exp_full  = (expected_count == DEPTH);

            if (count !== expected_count[COUNT_WIDTH-1:0])
                fail($sformatf("count=%0d expected=%0d", count, expected_count));
            else
                pass_count++;

            if (empty !== exp_empty)
                fail($sformatf("empty=%0b expected=%0b", empty, exp_empty));
            else
                pass_count++;

            if (full !== exp_full)
                fail($sformatf("full=%0b expected=%0b", full, exp_full));
            else
                pass_count++;

            if (dout !== expected_dout)
                fail($sformatf("dout=0x%0h expected=0x%0h", dout, expected_dout));
            else
                pass_count++;

            // General invariants independent from the reference queue content.
            if (count > DEPTH)
                fail($sformatf("count out of range: %0d > DEPTH=%0d", count, DEPTH));
            else
                pass_count++;

            if (full && empty)
                fail("full and empty asserted simultaneously");
            else
                pass_count++;
        end
    endtask

    function automatic int occupancy_class(input int c);
        if (c == 0)
            occupancy_class = 0;
        else if (c == DEPTH)
            occupancy_class = 2;
        else
            occupancy_class = 1;
    endfunction

    function automatic int op_class(input logic push_i, input logic pop_i);
        case ({push_i, pop_i})
            2'b00: op_class = 0;
            2'b10: op_class = 1;
            2'b01: op_class = 2;
            default: op_class = 3;
        endcase
    endfunction

    task automatic sample_coverage(
        input logic push_i,
        input logic pop_i,
        input int pre_count,
        input int pre_wptr,
        input int pre_rptr
    );
        int occ;
        int op;
        begin
            occ = occupancy_class(pre_count);
            op  = op_class(push_i, pop_i);
            cov_cross[occ][op] = 1'b1;

            if (pre_count == 0) cov_occ_empty = 1'b1;
            else if (pre_count == DEPTH) cov_occ_full = 1'b1;
            else cov_occ_middle = 1'b1;

            case ({push_i, pop_i})
                2'b00: cov_idle      = 1'b1;
                2'b10: cov_push_only = 1'b1;
                2'b01: cov_pop_only  = 1'b1;
                2'b11: cov_both      = 1'b1;
            endcase

            if (push_i && pre_count == DEPTH) cov_overflow_attempt = 1'b1;
            if (pop_i  && pre_count == 0)     cov_underflow_attempt = 1'b1;

            if (push_i && pop_i && pre_count == 0) cov_both_empty = 1'b1;
            if (push_i && pop_i && pre_count > 0 && pre_count < DEPTH) cov_both_middle = 1'b1;
            if (push_i && pop_i && pre_count == DEPTH) cov_both_full = 1'b1;

            if (push_i && pre_count < DEPTH && pre_wptr == DEPTH-1) cov_wrap_write = 1'b1;
            if (pop_i  && pre_count > 0     && pre_rptr == DEPTH-1) cov_wrap_read  = 1'b1;
        end
    endtask

    task automatic reset_dut;
        begin
            @(negedge clk);
            if (ref_count != 0)
                cov_reset_nonempty = 1'b1;

            rst_n = 1'b0;
            push  = 1'b0;
            pop   = 1'b0;
            din   = '0;
            model_reset();

            repeat (3) @(posedge clk);
            #1;
            check_post_state(0, '0);

            @(negedge clk);
            rst_n = 1'b1;
            $display("[%0t][TB] Reset released", $time);
        end
    endtask

    task automatic apply_cycle(
        input logic push_i,
        input logic pop_i,
        input logic [DATA_WIDTH-1:0] din_i
    );
        logic write_accept;
        logic read_accept;
        logic [DATA_WIDTH-1:0] expected_dout;
        int expected_count;
        int pre_count;
        int pre_wptr;
        int pre_rptr;
        int next_wptr;
        int next_rptr;
        begin
            @(negedge clk);
            push = push_i;
            pop  = pop_i;
            din  = din_i;

            pre_count = ref_count;
            pre_wptr  = ref_wr_ptr;
            pre_rptr  = ref_rd_ptr;
            sample_coverage(push_i, pop_i, pre_count, pre_wptr, pre_rptr);

            write_accept = push_i && (pre_count < DEPTH);
            read_accept  = pop_i  && (pre_count > 0);

            expected_count = pre_count;
            expected_dout  = ref_dout;
            next_wptr      = ref_wr_ptr;
            next_rptr      = ref_rd_ptr;

            if (read_accept) begin
                expected_dout = ref_mem[ref_rd_ptr];
                next_rptr = (ref_rd_ptr == DEPTH-1) ? 0 : ref_rd_ptr + 1;
            end

            if (write_accept)
                next_wptr = (ref_wr_ptr == DEPTH-1) ? 0 : ref_wr_ptr + 1;

            case ({write_accept, read_accept})
                2'b10: expected_count = pre_count + 1;
                2'b01: expected_count = pre_count - 1;
                default: expected_count = pre_count;
            endcase

            @(posedge clk);
            #1;
            cycle_count++;

            check_post_state(expected_count, expected_dout);

            // Commit the model only after checking the DUT.
            if (read_accept)
                ref_rd_ptr = next_rptr;

            if (write_accept) begin
                ref_mem[ref_wr_ptr] = din_i;
                ref_wr_ptr = next_wptr;
            end

            ref_count = expected_count;
            ref_dout  = expected_dout;
        end
    endtask

    task automatic print_coverage;
        int hits;
        int total;
        int i;
        int j;
        begin
            hits = 0;
            total = 15 + 12;

            hits += cov_occ_empty + cov_occ_middle + cov_occ_full;
            hits += cov_idle + cov_push_only + cov_pop_only + cov_both;
            hits += cov_overflow_attempt + cov_underflow_attempt;
            hits += cov_both_empty + cov_both_middle + cov_both_full;
            hits += cov_wrap_write + cov_wrap_read + cov_reset_nonempty;

            for (i = 0; i < 3; i++)
                for (j = 0; j < 4; j++)
                    hits += cov_cross[i][j];

            $display("============================================================");
            $display("MANUAL FUNCTIONAL COVERAGE");
            $display("occupancy empty/middle/full : %0d %0d %0d", cov_occ_empty, cov_occ_middle, cov_occ_full);
            $display("idle/push/pop/both           : %0d %0d %0d %0d", cov_idle, cov_push_only, cov_pop_only, cov_both);
            $display("overflow/underflow attempts : %0d %0d", cov_overflow_attempt, cov_underflow_attempt);
            $display("both@empty/middle/full      : %0d %0d %0d", cov_both_empty, cov_both_middle, cov_both_full);
            $display("write/read pointer wrap     : %0d %0d", cov_wrap_write, cov_wrap_read);
            $display("reset while non-empty       : %0d", cov_reset_nonempty);
            $display("state x operation cross:");
            for (i = 0; i < 3; i++)
                $display("  state[%0d] = idle:%0d push:%0d pop:%0d both:%0d",
                         i, cov_cross[i][0], cov_cross[i][1], cov_cross[i][2], cov_cross[i][3]);
            $display("Coverage bucket score       : %0d/%0d = %0d%%", hits, total, (hits*100)/total);
            $display("============================================================");
        end
    endtask

    int i;
    int op_sel;
    int unsigned rnd;
    logic [DATA_WIDTH-1:0] random_data;

    initial begin
        rst_n = 1'b0;
        push  = 1'b0;
        pop   = 1'b0;
        din   = '0;

        pass_count  = 0;
        fail_count  = 0;
        cycle_count = 0;
        seed        = 32'h1357_2468;

        model_reset();
        reset_dut();

        $display("\n================ DIRECTED REGRESSION ================");

        // Idle and underflow protection.
        apply_cycle(0, 0, '0);
        apply_cycle(0, 1, '0);

        // Both at empty: specified policy accepts push only.
        apply_cycle(1, 1, 8'hE1);
        apply_cycle(0, 1, '0);

        // Basic ordering.
        apply_cycle(1, 0, 8'hA5);
        apply_cycle(1, 0, 8'h5A);
        apply_cycle(0, 1, '0);
        apply_cycle(0, 1, '0);

        // Fill completely and attempt overflow.
        for (i = 0; i < DEPTH; i++)
            apply_cycle(1, 0, 8'h10 + i);
        apply_cycle(1, 0, 8'hEE);

        // Both at full: specified policy accepts pop only.
        apply_cycle(1, 1, 8'hEF);

        // Refill then drain; this forces pointer wrap coverage.
        apply_cycle(1, 0, 8'h88);
        for (i = 0; i < DEPTH; i++)
            apply_cycle(0, 1, '0);

        // Simultaneous push/pop in middle keeps occupancy constant while
        // preserving FIFO order.
        apply_cycle(1, 0, 8'hA1);
        apply_cycle(1, 0, 8'hB2);
        apply_cycle(1, 0, 8'hC3);
        repeat (6)
            apply_cycle(1, 1, $urandom(seed));
        repeat (3)
            apply_cycle(0, 1, '0);

        // Reset while data is present.
        apply_cycle(1, 0, 8'h55);
        apply_cycle(1, 0, 8'h66);
        reset_dut();

        // Explicitly close all occupancy x operation coverage bins.
        // Empty x {idle,push,pop,both}
        apply_cycle(0,0,'0);
        apply_cycle(0,1,'0);
        apply_cycle(1,1,8'h71); // leaves one item
        apply_cycle(0,1,'0);    // empty again
        apply_cycle(1,0,8'h72); // push from empty -> middle

        // Middle x {idle,push,pop,both}
        apply_cycle(0,0,'0);
        apply_cycle(1,0,8'h73);
        apply_cycle(0,1,'0);
        apply_cycle(1,1,8'h74);

        // Fill to full.
        while (ref_count < DEPTH)
            apply_cycle(1,0,$urandom(seed));

        // Full x {idle,push,pop,both}; rebuild full as needed.
        apply_cycle(0,0,'0);
        apply_cycle(1,0,8'h75);
        apply_cycle(1,1,8'h76); // full -> middle
        apply_cycle(1,0,8'h77); // middle -> full
        apply_cycle(0,1,'0);    // full -> middle
        apply_cycle(1,0,8'h78); // middle -> full
        apply_cycle(0,0,'0);

        // Full x pop was covered above; full x both covered too. Drain before random.
        while (ref_count > 0)
            apply_cycle(0,1,'0);

        $display("\n================ RANDOM REGRESSION =================");
        for (i = 0; i < RANDOM_CYCLES; i++) begin
            rnd = $urandom(seed);
            op_sel = rnd % 100;
            random_data = $urandom(seed);

            // Bias traffic to hit boundaries frequently.
            if (ref_count == 0) begin
                case (op_sel % 4)
                    0: apply_cycle(0,0,random_data);
                    1: apply_cycle(1,0,random_data);
                    2: apply_cycle(0,1,random_data);
                    3: apply_cycle(1,1,random_data);
                endcase
            end else if (ref_count == DEPTH) begin
                case (op_sel % 4)
                    0: apply_cycle(0,0,random_data);
                    1: apply_cycle(1,0,random_data);
                    2: apply_cycle(0,1,random_data);
                    3: apply_cycle(1,1,random_data);
                endcase
            end else begin
                if (op_sel < 10)      apply_cycle(0,0,random_data);
                else if (op_sel < 45) apply_cycle(1,0,random_data);
                else if (op_sel < 80) apply_cycle(0,1,random_data);
                else                  apply_cycle(1,1,random_data);
            end
        end

        apply_cycle(0,0,'0);

        $display("\n============================================================");
        $display("FINAL SCOREBOARD REPORT");
        $display("CYCLES      : %0d", cycle_count);
        $display("PASS CHECKS : %0d", pass_count);
        $display("FAIL CHECKS : %0d", fail_count);
        $display("REF COUNT   : %0d", ref_count);
        $display("============================================================");
        print_coverage();

        if (fail_count == 0)
            $display("FINAL RESULT: TEST PASSED");
        else
            $display("FINAL RESULT: TEST FAILED");

        if (fail_count != 0)
            $fatal(1, "Regression failed with %0d checks", fail_count);
        $finish;
    end

    initial begin
        $dumpfile("sync_fifo.vcd");
        $dumpvars(0, tb_sync_fifo);
    end

    initial begin
        #200000;
        $fatal(1, "Simulation timeout");
    end

endmodule
