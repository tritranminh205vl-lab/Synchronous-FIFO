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
