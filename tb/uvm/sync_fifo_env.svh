class sync_fifo_env extends uvm_env;
    `uvm_component_utils(sync_fifo_env)

    sync_fifo_agent      agent;
    sync_fifo_scoreboard scb;
    sync_fifo_coverage   cov;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent = sync_fifo_agent::type_id::create("agent", this);
        scb   = sync_fifo_scoreboard::type_id::create("scb", this);
        cov   = sync_fifo_coverage::type_id::create("cov", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.mon.ap.connect(scb.analysis_export);
        agent.mon.ap.connect(cov.analysis_export);
    endfunction
endclass
