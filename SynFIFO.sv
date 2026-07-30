`timescale 1ns/1ps

module sync_fifo #(
    parameter integer DEPTH = 8,
    parameter integer WIDTH = 8
)(
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     push,
    input  wire [WIDTH-1:0]         din,
    input  wire                     pop,
    output reg  [WIDTH-1:0]         dout,
    output wire                     empty,
    output wire                     full,
    output reg  [$clog2(DEPTH):0]   count
);

    localparam integer PTR_WIDTH = (DEPTH <= 1) ? 1 : $clog2(DEPTH);

    reg [WIDTH-1:0] fifo [0:DEPTH-1];
    reg [PTR_WIDTH-1:0] wptr;
    reg [PTR_WIDTH-1:0] rptr;

    wire write_accept;
    wire read_accept;

    assign full  = (count == DEPTH);
    assign empty = (count == 0);

    assign write_accept = push && !full;
    assign read_accept  = pop  && !empty;

    always @(posedge clk) begin
        if (!rst_n) begin
            wptr  <= {PTR_WIDTH{1'b0}};
            rptr  <= {PTR_WIDTH{1'b0}};
            count <= 0;
            dout  <= {WIDTH{1'b0}};
        end
        else begin
            if (write_accept) begin
                fifo[wptr] <= din;

                if (wptr == DEPTH-1)
                    wptr <= {PTR_WIDTH{1'b0}};
                else
                    wptr <= wptr + 1'b1;
            end

            if (read_accept) begin
                dout <= fifo[rptr];

                if (rptr == DEPTH-1)
                    rptr <= {PTR_WIDTH{1'b0}};
                else
                    rptr <= rptr + 1'b1;
            end

            case ({write_accept, read_accept})
                2'b10: count <= count + 1'b1;
                2'b01: count <= count - 1'b1;
                default: count <= count;
            endcase
        end
    end

endmodule
