BUILD := build
IVERILOG ?= iverilog
VVP ?= vvp
VERILATOR ?= verilator

.PHONY: basic lint clean synth uvm-questa

basic:
	mkdir -p $(BUILD)
	$(IVERILOG) -g2012 -Wall -s tb_sync_fifo -o $(BUILD)/sync_fifo_basic.vvp \
		rtl/sync_fifo.sv tb/basic/tb_sync_fifo.sv
	$(VVP) $(BUILD)/sync_fifo_basic.vvp

lint:
	$(VERILATOR) --lint-only -Wall --Wno-fatal rtl/sync_fifo.sv

synth:
	mkdir -p $(BUILD)
	yosys -s synth/sync_fifo.ys

# Commercial simulator target. Set UVM_HOME to your UVM source directory.
uvm-questa:
	@test -n "$(UVM_HOME)" || (echo "Set UVM_HOME first" && exit 1)
	mkdir -p $(BUILD)/questa
	cd $(BUILD)/questa && vlib work
	cd $(BUILD)/questa && vlog -sv +incdir+../../tb/uvm +incdir+$(UVM_HOME)/src \
		$(UVM_HOME)/src/uvm_pkg.sv \
		../../rtl/sync_fifo.sv \
		../../tb/uvm/sync_fifo_if.sv \
		../../tb/uvm/sync_fifo_pkg.sv \
		../../tb/sva/sync_fifo_sva.sv \
		../../tb/sva/sync_fifo_bind.sv \
		../../tb/uvm/tb_sync_fifo_uvm.sv
	cd $(BUILD)/questa && vsim -c tb_sync_fifo_uvm -do "run -all; quit -f"

clean:
	rm -rf $(BUILD) *.vcd transcript work
