`timescale 1ns/1ps

// Interface-level assertions for the specified synchronous FIFO behavior.
module sync_fifo_sva #(
    parameter int unsigned DEPTH      = 8,
    parameter int unsigned DATA_WIDTH = 8
) (
    input logic                         clk,
    input logic                         rst_n,
    input logic                         push,
    input logic                         pop,
    input logic [DATA_WIDTH-1:0]        din,
    input logic [DATA_WIDTH-1:0]        dout,
    input logic                         empty,
    input logic                         full,
    input logic [$clog2(DEPTH+1)-1:0]  count
);

    default clocking cb @(posedge clk); endclocking

    // Structural invariants.
    ap_count_in_range:
        assert property (disable iff (!rst_n) count <= DEPTH)
        else $error("FIFO count exceeded DEPTH");

    ap_full_matches_count:
        assert property (disable iff (!rst_n) full == (count == DEPTH))
        else $error("full flag inconsistent with count");

    ap_empty_matches_count:
        assert property (disable iff (!rst_n) empty == (count == 0))
        else $error("empty flag inconsistent with count");

    ap_not_full_and_empty:
        assert property (disable iff (!rst_n) !(full && empty))
        else $error("full and empty asserted together");

    // A legal push with no legal pop increments occupancy.
    ap_push_only_increments:
        assert property (disable iff (!rst_n)
            (push && !full && !(pop && !empty))
            |=> (count == ($past(count) + 1'b1)))
        else $error("accepted push did not increment count");

    // A legal pop with no legal push decrements occupancy.
    ap_pop_only_decrements:
        assert property (disable iff (!rst_n)
            (pop && !empty && !(push && !full))
            |=> (count == ($past(count) - 1'b1)))
        else $error("accepted pop did not decrement count");

    // Both operations accepted in a middle occupancy state -> count is stable.
    ap_both_middle_count_stable:
        assert property (disable iff (!rst_n)
            (push && pop && !full && !empty)
            |=> (count == $past(count)))
        else $error("simultaneous accepted push/pop changed count");

    // Boundary policy defined by this project.
    ap_both_empty_push_wins:
        assert property (disable iff (!rst_n)
            (empty && push && pop)
            |=> (count == 1))
        else $error("empty + push + pop policy violated");

    ap_both_full_pop_wins:
        assert property (disable iff (!rst_n)
            (full && push && pop)
            |=> (count == DEPTH-1))
        else $error("full + push + pop policy violated");

    ap_overflow_blocked:
        assert property (disable iff (!rst_n)
            (full && push && !pop)
            |=> (count == $past(count)))
        else $error("push while full changed occupancy");

    ap_underflow_blocked:
        assert property (disable iff (!rst_n)
            (empty && pop && !push)
            |=> (count == $past(count)))
        else $error("pop while empty changed occupancy");

    // Registered output must hold when no pop was accepted.
    ap_dout_holds_without_pop:
        assert property (disable iff (!rst_n)
            !(pop && !empty)
            |=> $stable(dout))
        else $error("dout changed without an accepted pop");

    // Useful cover properties for wave/debug evidence.
    cp_reach_full:       cover property (disable iff (!rst_n) full);
    cp_reach_empty:      cover property (disable iff (!rst_n) empty);
    cp_both_middle:      cover property (disable iff (!rst_n) push && pop && !full && !empty);
    cp_overflow_attempt: cover property (disable iff (!rst_n) push && full);
    cp_underflow_attempt:cover property (disable iff (!rst_n) pop && empty);

endmodule
