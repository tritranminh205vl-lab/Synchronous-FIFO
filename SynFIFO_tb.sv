`timescale 1ns/1ps


module tb_top;

    localparam integer DEPTH       = 8;
    localparam integer WIDTH       = 8;
    localparam integer COUNT_WIDTH = $clog2(DEPTH) + 1;
    localparam integer RANDOM_CYCLES = 200;

 
    reg                    clk;
    reg                    rst_n;
    reg                    push;
    reg                    pop;
    reg  [WIDTH-1:0]       din;

    wire [WIDTH-1:0]       dout;
    wire                   full;
    wire                   empty;
    wire [COUNT_WIDTH-1:0] count;

  
    reg [WIDTH-1:0] ref_mem [0:DEPTH-1];
    integer ref_wr_ptr;
    integer ref_rd_ptr;
    integer ref_count;
    reg [WIDTH-1:0] ref_dout;

  
    integer pass_count;
    integer fail_count;
    integer cycle_count;
    integer seed;

   
    integer cov_empty_state;
    integer cov_middle_state;
    integer cov_full_state;

    integer cov_idle;
    integer cov_push_only;
    integer cov_pop_only;
    integer cov_both;

    integer cov_push_when_full;
    integer cov_pop_when_empty;
    integer cov_both_mid_state;
    integer cov_both_when_empty;
    integer cov_both_when_full;

  
    sync_fifo #(
        .DEPTH (DEPTH),
        .WIDTH (WIDTH)
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

   
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task reset_reference_model;
        integer i;
        begin
            ref_wr_ptr = 0;
            ref_rd_ptr = 0;
            ref_count  = 0;
            ref_dout   = {WIDTH{1'b0}};

            for (i = 0; i < DEPTH; i = i + 1)
                ref_mem[i] = {WIDTH{1'b0}};
        end
    endtask

    task check_count_value;
        input integer expected;
        begin
            if (count !== expected[COUNT_WIDTH-1:0]) begin
                fail_count = fail_count + 1;
                $display("[%0t][FAIL] count=%0d expected=%0d",
                         $time, count, expected);
            end
            else begin
                pass_count = pass_count + 1;
            end
        end
    endtask

    task check_full_value;
        input expected;
        begin
            if (full !== expected) begin
                fail_count = fail_count + 1;
                $display("[%0t][FAIL] full=%0b expected=%0b",
                         $time, full, expected);
            end
            else begin
                pass_count = pass_count + 1;
            end
        end
    endtask

    task check_empty_value;
        input expected;
        begin
            if (empty !== expected) begin
                fail_count = fail_count + 1;
                $display("[%0t][FAIL] empty=%0b expected=%0b",
                         $time, empty, expected);
            end
            else begin
                pass_count = pass_count + 1;
            end
        end
    endtask

    task check_dout_value;
        input [WIDTH-1:0] expected;
        begin
            if (dout !== expected) begin
                fail_count = fail_count + 1;
                $display("[%0t][FAIL] dout=0x%0h expected=0x%0h",
                         $time, dout, expected);
            end
            else begin
                pass_count = pass_count + 1;
            end
        end
    endtask


    task reset_dut;
        begin
            // Drive reset away from the active clock edge.
            @(negedge clk);
            rst_n = 1'b0;
            push  = 1'b0;
            pop   = 1'b0;
            din   = {WIDTH{1'b0}};

            reset_reference_model();

            // DUT samples reset on rising edges.
            repeat (3) @(posedge clk);
            #1;

            check_count_value(0);
            check_empty_value(1'b1);
            check_full_value(1'b0);
            check_dout_value({WIDTH{1'b0}});

            @(negedge clk);
            rst_n = 1'b1;

            $display("[%0t][TB] Reset released", $time);
        end
    endtask

 
    task sample_manual_coverage;
        input push_i;
        input pop_i;
        input integer pre_count;
        begin
            if (pre_count == 0)
                cov_empty_state = 1;
            else if (pre_count == DEPTH)
                cov_full_state = 1;
            else
                cov_middle_state = 1;

            case ({push_i, pop_i})
                2'b00: cov_idle      = 1;
                2'b01: cov_pop_only  = 1;
                2'b10: cov_push_only = 1;
                2'b11: cov_both      = 1;
                default: ;
            endcase

            if (push_i && (pre_count == DEPTH))
                cov_push_when_full = 1;

            if (pop_i && (pre_count == 0))
                cov_pop_when_empty = 1;

            if (push_i && pop_i &&
                (pre_count > 0) && (pre_count < DEPTH))
                cov_both_mid_state = 1;

            if (push_i && pop_i && (pre_count == 0))
                cov_both_when_empty = 1;

            if (push_i && pop_i && (pre_count == DEPTH))
                cov_both_when_full = 1;
        end
    endtask

 
    task apply_cycle;
        input             push_i;
        input             pop_i;
        input [WIDTH-1:0] din_i;

        reg               write_accept;
        reg               read_accept;
        reg [WIDTH-1:0]   expected_dout;
        reg               expected_full;
        reg               expected_empty;
        integer           pre_count;
        integer           expected_count;
        integer           next_wr_ptr;
        integer           next_rd_ptr;

        begin
            @(negedge clk);
            push = push_i;
            pop  = pop_i;
            din  = din_i;

            pre_count = ref_count;
            sample_manual_coverage(push_i, pop_i, pre_count);

    
            write_accept = push_i && (pre_count < DEPTH);
            read_accept  = pop_i  && (pre_count > 0);

            expected_count = pre_count;
            expected_dout  = ref_dout;
            next_wr_ptr     = ref_wr_ptr;
            next_rd_ptr     = ref_rd_ptr;

            if (read_accept) begin
                expected_dout = ref_mem[ref_rd_ptr];

                if (ref_rd_ptr == DEPTH-1)
                    next_rd_ptr = 0;
                else
                    next_rd_ptr = ref_rd_ptr + 1;
            end

            if (write_accept) begin
                if (ref_wr_ptr == DEPTH-1)
                    next_wr_ptr = 0;
                else
                    next_wr_ptr = ref_wr_ptr + 1;
            end

            case ({write_accept, read_accept})
                2'b10: expected_count = pre_count + 1;
                2'b01: expected_count = pre_count - 1;
                default: expected_count = pre_count;
            endcase

            expected_full  = (expected_count == DEPTH);
            expected_empty = (expected_count == 0);

         
            @(posedge clk);
            #1;

            cycle_count = cycle_count + 1;

            $display("[%0t][CYCLE %0d] push=%0b pop=%0b din=0x%0h | dout=0x%0h count=%0d empty=%0b full=%0b",
                     $time, cycle_count, push_i, pop_i, din_i,
                     dout, count, empty, full);

            check_count_value(expected_count);
            check_full_value(expected_full);
            check_empty_value(expected_empty);
            check_dout_value(expected_dout);

            // Update the independent model after DUT comparison.
            if (read_accept)
                ref_rd_ptr = next_rd_ptr;

            if (write_accept) begin
                ref_mem[ref_wr_ptr] = din_i;
                ref_wr_ptr = next_wr_ptr;
            end

            ref_count = expected_count;
            ref_dout  = expected_dout;
        end
    endtask

   
    task print_coverage;
        integer hits;
        integer total;
        integer percentage;
        begin
            hits = cov_empty_state       +
                   cov_middle_state      +
                   cov_full_state        +
                   cov_idle              +
                   cov_push_only         +
                   cov_pop_only          +
                   cov_both              +
                   cov_push_when_full    +
                   cov_pop_when_empty    +
                   cov_both_mid_state    +
                   cov_both_when_empty   +
                   cov_both_when_full;

            total = 12;
            percentage = (hits * 100) / total;

            $display("============================================================");
            $display("MANUAL FUNCTIONAL COVERAGE");
            $display("empty state         : %0d", cov_empty_state);
            $display("middle state        : %0d", cov_middle_state);
            $display("full state          : %0d", cov_full_state);
            $display("idle                : %0d", cov_idle);
            $display("push only           : %0d", cov_push_only);
            $display("pop only            : %0d", cov_pop_only);
            $display("push + pop          : %0d", cov_both);
            $display("push when full      : %0d", cov_push_when_full);
            $display("pop when empty      : %0d", cov_pop_when_empty);
            $display("both in middle      : %0d", cov_both_mid_state);
            $display("both when empty     : %0d", cov_both_when_empty);
            $display("both when full      : %0d", cov_both_when_full);
            $display("Coverage            : %0d/%0d = %0d%%",
                     hits, total, percentage);
            $display("============================================================");
        end
    endtask

    // --------------------------------------------------------
    // Main stimulus
    // --------------------------------------------------------
    integer i;
    integer op_sel;
    integer random_value;
    reg [WIDTH-1:0] random_data;

    initial begin
        rst_n = 1'b0;
        push  = 1'b0;
        pop   = 1'b0;
        din   = {WIDTH{1'b0}};

        pass_count  = 0;
        fail_count  = 0;
        cycle_count = 0;
        seed        = 32'h1357_2468;

        cov_empty_state     = 0;
        cov_middle_state    = 0;
        cov_full_state      = 0;
        cov_idle            = 0;
        cov_push_only       = 0;
        cov_pop_only        = 0;
        cov_both            = 0;
        cov_push_when_full  = 0;
        cov_pop_when_empty  = 0;
        cov_both_mid_state  = 0;
        cov_both_when_empty = 0;
        cov_both_when_full  = 0;

        reset_reference_model();
        reset_dut();

        $display("\n================ DIRECTED TESTS ================");

        // 1. Idle and illegal pop while empty.
        apply_cycle(1'b0, 1'b0, {WIDTH{1'b0}});
        apply_cycle(1'b0, 1'b1, {WIDTH{1'b0}});

        // 2. Both asserted while empty: only push is accepted.
        apply_cycle(1'b1, 1'b1, 8'hE1);
        apply_cycle(1'b0, 1'b1, {WIDTH{1'b0}});

        // 3. Basic push/pop.
        apply_cycle(1'b1, 1'b0, 8'hA5);
        apply_cycle(1'b0, 1'b1, {WIDTH{1'b0}});

        // 4. Fill FIFO completely.
        for (i = 0; i < DEPTH; i = i + 1)
            apply_cycle(1'b1, 1'b0, 8'h10 + i);

        // 5. Push while full must be ignored.
        apply_cycle(1'b1, 1'b0, 8'hEE);

        // 6. Both asserted while full: only pop is accepted.
        apply_cycle(1'b1, 1'b1, 8'hEF);

        // Refill the one free slot, then drain everything.
        apply_cycle(1'b1, 1'b0, 8'h88);

        for (i = 0; i < DEPTH; i = i + 1)
            apply_cycle(1'b0, 1'b1, {WIDTH{1'b0}});

        // 7. Simultaneous push/pop in middle state.
        apply_cycle(1'b1, 1'b0, 8'hA1);
        apply_cycle(1'b1, 1'b0, 8'hB2);
        apply_cycle(1'b1, 1'b0, 8'hC3);
        apply_cycle(1'b1, 1'b1, 8'hD4);
        apply_cycle(1'b0, 1'b1, {WIDTH{1'b0}});
        apply_cycle(1'b0, 1'b1, {WIDTH{1'b0}});
        apply_cycle(1'b0, 1'b1, {WIDTH{1'b0}});

        // 8. Reset while FIFO contains data.
        apply_cycle(1'b1, 1'b0, 8'h55);
        apply_cycle(1'b1, 1'b0, 8'h66);
        reset_dut();

        $display("\n================ RANDOM TESTS ==================");

        for (i = 0; i < RANDOM_CYCLES; i = i + 1) begin
            random_value = $random(seed);

            if (random_value < 0)
                random_value = -random_value;

            op_sel = random_value % 100;
            random_data = $random(seed);

            if (op_sel < 10)
                apply_cycle(1'b0, 1'b0, random_data);
            else if (op_sel < 50)
                apply_cycle(1'b1, 1'b0, random_data);
            else if (op_sel < 80)
                apply_cycle(1'b0, 1'b1, random_data);
            else
                apply_cycle(1'b1, 1'b1, random_data);
        end

        // Return inputs to idle and verify one final stable cycle.
        apply_cycle(1'b0, 1'b0, {WIDTH{1'b0}});

        $display("\n============================================================");
        $display("FINAL SCOREBOARD REPORT");
        $display("PASS CHECKS : %0d", pass_count);
        $display("FAIL CHECKS : %0d", fail_count);
        $display("REF COUNT   : %0d", ref_count);
        $display("============================================================");

        print_coverage();

        if (fail_count == 0)
            $display("FINAL RESULT: TEST PASSED");
        else
            $display("FINAL RESULT: TEST FAILED");

        $finish;
    end

    // --------------------------------------------------------
    // Waveform dump
    // --------------------------------------------------------
    initial begin
        $dumpfile("fifo.vcd");
        $dumpvars(0, tb_top);
    end

    // --------------------------------------------------------
    // Watchdog
    // --------------------------------------------------------
    initial begin
        #100000;
        $display("[%0t][FATAL] Simulation timeout", $time);
        $finish;
    end

endmodule
