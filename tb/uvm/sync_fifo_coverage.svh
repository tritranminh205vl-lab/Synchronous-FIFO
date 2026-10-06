class sync_fifo_coverage extends uvm_subscriber #(sync_fifo_txn);
    `uvm_component_utils(sync_fifo_coverage)

    int pre_count;
    int occupancy_class;
    int operation_class;
    bit overflow_attempt;
    bit underflow_attempt;

    covergroup fifo_cg;
        option.per_instance = 1;

        cp_occupancy: coverpoint occupancy_class {
            bins empty  = {0};
            bins middle = {1};
            bins full   = {2};
        }

        cp_operation: coverpoint operation_class {
            bins idle = {0};
            bins push = {1};
            bins pop  = {2};
            bins both = {3};
        }

        cp_overflow_attempt: coverpoint overflow_attempt { bins hit = {1}; }
        cp_underflow_attempt: coverpoint underflow_attempt { bins hit = {1}; }

        cx_state_operation: cross cp_occupancy, cp_operation;
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        pre_count = 0;
        fifo_cg = new();
    endfunction

    function void write(sync_fifo_txn tr);
        // Classify requests from the occupancy at the beginning of the cycle.
        if (pre_count == 0) occupancy_class = 0;
        else if (pre_count == DEPTH) occupancy_class = 2;
        else occupancy_class = 1;

        case ({tr.push, tr.pop})
            2'b00: operation_class = 0;
            2'b10: operation_class = 1;
            2'b01: operation_class = 2;
            default: operation_class = 3;
        endcase

        overflow_attempt  = tr.push && (pre_count == DEPTH);
        underflow_attempt = tr.pop  && (pre_count == 0);
        fifo_cg.sample();

        pre_count = tr.count;
    endfunction
endclass
