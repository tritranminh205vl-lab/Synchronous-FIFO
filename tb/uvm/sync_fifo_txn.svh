class sync_fifo_txn extends uvm_sequence_item;
    rand bit                  push;
    rand bit                  pop;
    rand bit [DATA_WIDTH-1:0] din;

    // Observed post-edge DUT state, filled by monitor.
    bit [DATA_WIDTH-1:0]      dout;
    bit                       empty;
    bit                       full;
    int unsigned              count;

    constraint c_operation_mix {
        {push, pop} dist {
            2'b00 := 10,
            2'b10 := 35,
            2'b01 := 35,
            2'b11 := 20
        };
    }

    `uvm_object_utils_begin(sync_fifo_txn)
        `uvm_field_int(push,  UVM_DEFAULT)
        `uvm_field_int(pop,   UVM_DEFAULT)
        `uvm_field_int(din,   UVM_HEX)
        `uvm_field_int(dout,  UVM_HEX | UVM_NOCOMPARE)
        `uvm_field_int(empty, UVM_DEFAULT | UVM_NOCOMPARE)
        `uvm_field_int(full,  UVM_DEFAULT | UVM_NOCOMPARE)
        `uvm_field_int(count, UVM_DEC | UVM_NOCOMPARE)
    `uvm_object_utils_end

    function new(string name = "sync_fifo_txn");
        super.new(name);
    endfunction
endclass
