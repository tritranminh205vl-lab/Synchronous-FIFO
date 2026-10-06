class sync_fifo_scoreboard extends uvm_component;
    `uvm_component_utils(sync_fifo_scoreboard)

    uvm_analysis_imp #(sync_fifo_txn, sync_fifo_scoreboard) analysis_export;

    bit [DATA_WIDTH-1:0] model_q[$];
    bit [DATA_WIDTH-1:0] expected_dout;
    int unsigned checks;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        analysis_export = new("analysis_export", this);
        expected_dout = '0;
    endfunction

    function void write(sync_fifo_txn tr);
        bit push_accept;
        bit pop_accept;
        int unsigned pre_count;
        int unsigned exp_count;
        bit exp_empty;
        bit exp_full;

        pre_count = model_q.size();
        push_accept = tr.push && (pre_count < DEPTH);
        pop_accept  = tr.pop  && (pre_count > 0);

        // Read old head before appending a simultaneous new tail.
        if (pop_accept)
            expected_dout = model_q.pop_front();

        if (push_accept)
            model_q.push_back(tr.din);

        exp_count = model_q.size();
        exp_empty = (exp_count == 0);
        exp_full  = (exp_count == DEPTH);

        checks += 4;

        if (tr.count != exp_count)
            `uvm_error("SCB", $sformatf("count=%0d expected=%0d", tr.count, exp_count))

        if (tr.empty != exp_empty)
            `uvm_error("SCB", $sformatf("empty=%0b expected=%0b", tr.empty, exp_empty))

        if (tr.full != exp_full)
            `uvm_error("SCB", $sformatf("full=%0b expected=%0b", tr.full, exp_full))

        if (tr.dout != expected_dout)
            `uvm_error("SCB", $sformatf("dout=0x%0h expected=0x%0h", tr.dout, expected_dout))

        if (exp_count > DEPTH)
            `uvm_fatal("SCB", "Reference model exceeded FIFO depth")
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SCB", $sformatf("Completed %0d scoreboard checks; final occupancy=%0d", checks, model_q.size()), UVM_LOW)
    endfunction
endclass
