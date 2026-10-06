class sync_fifo_driver extends uvm_driver #(sync_fifo_txn);
    `uvm_component_utils(sync_fifo_driver)

    virtual sync_fifo_if #(DEPTH, DATA_WIDTH) vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual sync_fifo_if #(DEPTH, DATA_WIDTH))::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "sync_fifo_if was not supplied to driver")
    endfunction

    task run_phase(uvm_phase phase);
        sync_fifo_txn tr;

        vif.push <= 1'b0;
        vif.pop  <= 1'b0;
        vif.din  <= '0;

        wait (vif.rst_n === 1'b1);

        forever begin
            seq_item_port.get_next_item(tr);
            @(negedge vif.clk);
            vif.push <= tr.push;
            vif.pop  <= tr.pop;
            vif.din  <= tr.din;
            seq_item_port.item_done();
        end
    endtask
endclass
