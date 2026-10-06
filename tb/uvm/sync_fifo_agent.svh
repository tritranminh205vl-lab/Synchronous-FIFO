class sync_fifo_agent extends uvm_agent;
    `uvm_component_utils(sync_fifo_agent)

    sync_fifo_sequencer seqr;
    sync_fifo_driver    drv;
    sync_fifo_monitor   mon;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        seqr = sync_fifo_sequencer::type_id::create("seqr", this);
        drv  = sync_fifo_driver::type_id::create("drv", this);
        mon  = sync_fifo_monitor::type_id::create("mon", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        drv.seq_item_port.connect(seqr.seq_item_export);
    endfunction
endclass
