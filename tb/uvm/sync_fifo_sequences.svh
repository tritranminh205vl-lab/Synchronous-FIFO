class sync_fifo_base_seq extends uvm_sequence #(sync_fifo_txn);
    `uvm_object_utils(sync_fifo_base_seq)

    function new(string name = "sync_fifo_base_seq");
        super.new(name);
    endfunction

    task automatic send(bit push_i, bit pop_i, bit [DATA_WIDTH-1:0] data_i);
        sync_fifo_txn tr;
        tr = sync_fifo_txn::type_id::create("tr");
        start_item(tr);
        tr.push = push_i;
        tr.pop  = pop_i;
        tr.din  = data_i;
        finish_item(tr);
    endtask
endclass

class sync_fifo_directed_seq extends sync_fifo_base_seq;
    `uvm_object_utils(sync_fifo_directed_seq)

    function new(string name = "sync_fifo_directed_seq");
        super.new(name);
    endfunction

    task body();
        int i;

        // Empty corner cases.
        send(0,0,'0);
        send(0,1,'0);       // underflow attempt
        send(1,1,8'hE1);     // both at empty -> push only by spec
        send(0,1,'0);

        // Basic ordering.
        send(1,0,8'hA5);
        send(1,0,8'h5A);
        send(0,1,'0);
        send(0,1,'0);

        // Fill to full.
        for (i = 0; i < DEPTH; i++)
            send(1,0,8'h10 + i);

        send(1,0,8'hEE);     // overflow attempt
        send(1,1,8'hEF);     // both at full -> pop only by spec
        send(1,0,8'h88);     // refill

        // Drain.
        for (i = 0; i < DEPTH; i++)
            send(0,1,'0);

        // Simultaneous middle traffic.
        send(1,0,8'h11);
        send(1,0,8'h22);
        send(1,0,8'h33);
        repeat (8)
            send(1,1,$urandom());
        repeat (3)
            send(0,1,'0);
    endtask
endclass

class sync_fifo_random_seq extends uvm_sequence #(sync_fifo_txn);
    `uvm_object_utils(sync_fifo_random_seq)

    rand int unsigned n_items = 1000;

    function new(string name = "sync_fifo_random_seq");
        super.new(name);
    endfunction

    task body();
        sync_fifo_txn tr;
        repeat (n_items) begin
            tr = sync_fifo_txn::type_id::create("tr");
            start_item(tr);
            if (!tr.randomize())
                `uvm_fatal("RAND", "Could not randomize FIFO transaction")
            finish_item(tr);
        end

        // Leave the interface in idle so the driver does not hold a final
        // push/pop request after the sequence has ended.
        tr = sync_fifo_txn::type_id::create("idle_tr");
        start_item(tr);
        tr.push = 1'b0;
        tr.pop  = 1'b0;
        tr.din  = '0;
        finish_item(tr);
    endtask
endclass
