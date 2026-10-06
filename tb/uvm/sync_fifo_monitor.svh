class sync_fifo_monitor extends uvm_component;
    `uvm_component_utils(sync_fifo_monitor)

    virtual sync_fifo_if #(DEPTH, DATA_WIDTH) vif;
    uvm_analysis_port #(sync_fifo_txn) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual sync_fifo_if #(DEPTH, DATA_WIDTH))::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "sync_fifo_if was not supplied to monitor")
    endfunction

    task run_phase(uvm_phase phase);
        sync_fifo_txn tr;

        forever begin
            @(posedge vif.clk);
            if (vif.rst_n !== 1'b1)
                continue;

            // Sample after NBA updates. The request itself has been stable since
            // the preceding negedge, while outputs now represent this transfer.
            #1ps;
            tr = sync_fifo_txn::type_id::create("tr", this);
            tr.push  = vif.push;
            tr.pop   = vif.pop;
            tr.din   = vif.din;
            tr.dout  = vif.dout;
            tr.empty = vif.empty;
            tr.full  = vif.full;
            tr.count = vif.count;
            ap.write(tr);
        end
    endtask
endclass
