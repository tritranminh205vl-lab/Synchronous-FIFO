class sync_fifo_test extends uvm_test;
    `uvm_component_utils(sync_fifo_test)

    sync_fifo_env env;
    virtual sync_fifo_if #(DEPTH, DATA_WIDTH) vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = sync_fifo_env::type_id::create("env", this);
        if (!uvm_config_db#(virtual sync_fifo_if #(DEPTH, DATA_WIDTH))::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "sync_fifo_if was not supplied to test")
    endfunction

    task run_phase(uvm_phase phase);
        sync_fifo_directed_seq directed;
        sync_fifo_random_seq random_seq;

        phase.raise_objection(this);
        wait (vif.rst_n === 1'b1);

        directed = sync_fifo_directed_seq::type_id::create("directed");
        directed.start(env.agent.seqr);

        random_seq = sync_fifo_random_seq::type_id::create("random_seq");
        random_seq.n_items = 1000;
        random_seq.start(env.agent.seqr);

        repeat (3) @(posedge vif.clk);
        phase.drop_objection(this);
    endtask
endclass
