`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// Synchronous FIFO
// -----------------------------------------------------------------------------
// Architecture:
//   - Single clock domain for both push and pop.
//   - Counter-based full/empty detection.
//   - Registered read data (dout updates only on an accepted pop).
//   - Synchronous, active-low reset.
//
// Boundary policy (intentional and verified):
//   * empty + push + pop : push is accepted, pop is rejected -> count becomes 1
//   * full  + push + pop : pop is accepted, push is rejected -> count becomes DEPTH-1
//
// This policy uses the FIFO state at the beginning of the cycle. It keeps the
// interface simple and deterministic. A higher-throughput FIFO could choose a
// different boundary policy, but that would be a different specification.
// -----------------------------------------------------------------------------
module sync_fifo #(
    parameter int unsigned DEPTH      = 8,
    parameter int unsigned DATA_WIDTH = 8
) (
    input  logic                              clk,
    input  logic                              rst_n,

    input  logic                              push,
    input  logic [DATA_WIDTH-1:0]             din,
    input  logic                              pop,

    output logic [DATA_WIDTH-1:0]             dout,
    output logic                              empty,
    output logic                              full,
    output logic [$clog2(DEPTH+1)-1:0]        count
);

    localparam int unsigned PTR_WIDTH = (DEPTH <= 1) ? 1 : $clog2(DEPTH);

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    logic [PTR_WIDTH-1:0]  wptr;
    logic [PTR_WIDTH-1:0]  rptr;

    logic push_accept;
    logic pop_accept;

    assign full  = (count == DEPTH);
    assign empty = (count == 0);

    // Accepted operations are based on the state before the active clock edge.
    assign push_accept = push && !full;
    assign pop_accept  = pop  && !empty;

`ifndef SYNTHESIS
    initial begin
        if (DEPTH < 1)
            $fatal(1, "sync_fifo: DEPTH must be >= 1");
        if (DATA_WIDTH < 1)
            $fatal(1, "sync_fifo: DATA_WIDTH must be >= 1");
    end
`endif

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            wptr  <= '0;
            rptr  <= '0;
            count <= '0;
            dout  <= '0;
        end else begin
            // Write side.
            if (push_accept) begin
                mem[wptr] <= din;

                if (wptr == DEPTH-1)
                    wptr <= '0;
                else
                    wptr <= wptr + 1'b1;
            end

            // Read side. Output is registered and holds its previous value when
            // no pop is accepted.
            if (pop_accept) begin
                dout <= mem[rptr];

                if (rptr == DEPTH-1)
                    rptr <= '0;
                else
                    rptr <= rptr + 1'b1;
            end

            // Occupancy changes only when exactly one accepted operation occurs.
            unique case ({push_accept, pop_accept})
                2'b10: count <= count + 1'b1;
                2'b01: count <= count - 1'b1;
                default: count <= count;
            endcase
        end
    end

endmodule
