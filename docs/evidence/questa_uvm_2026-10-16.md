# QuestaSim UVM + SVA regression — 2026-10-16

## Result

**PASS for my recorded simulation run:** the UVM test completed with 4,176 scoreboard checks, zero UVM errors/fatals, and no reported assertion failures.

| Item | Observed result |
| --- | --- |
| Platform | EDA Playground |
| Simulator | QuestaSim-64 2025.2 |
| UVM library | UVM 1.2 |
| Run timestamp | 2026-10-16 07:50:44 UTC / 14:50:44 Vietnam time |
| Top module | `tb_sync_fifo_uvm` |
| Test | `sync_fifo_test` |
| Scoreboard checks | 4,176 |
| UVM warnings / errors / fatals | 0 / 0 / 0 |
| Final reference occupancy | 2 |
| SVA module loaded | `work.sync_fifo_sva(fast)` |
| Simulation finish time | 10,485 ns |
| Tool errors / warnings | 0 / 2 |

Final occupancy 2 is not a failure: the random sequence ends with an idle transaction and does not require the FIFO to be drained.

## Evidence provenance

I ran this simulation on EDA Playground and recorded the console transcript. This report documents my run rather than a fresh CI execution or an independently reproduced simulation.

I combined my UVM components, SVA module, and bind declaration into one browser testbench file. I renamed the coverage subscriber's `write` argument from `tr` to `t` to match the UVM base-class declaration. I therefore do not treat this run as verification of the unmodified repository sources. I did not retain the exact browser source snapshot, source commit, playground URL, or random seed with the transcript.

## Testbench scope

The prepared testbench contains:

- Interface and transaction class.
- Sequencer, driver, monitor, and agent.
- Queue-based reference scoreboard comparing `count`, `empty`, `full`, and `dout`.
- Functional coverage subscriber for occupancy, operation, overflow/underflow attempts, and state-operation cross coverage.
- Environment and test coordinating directed sequences followed by 1,000 random transactions.
- Clock/reset generation, DUT instantiation, virtual-interface configuration, and `run_test("sync_fifo_test")`.
- SVA properties and bind for count bounds, flags, accepted-operation occupancy changes, boundary behavior, and output stability without an accepted pop.

Directed scenarios include empty reads, simultaneous push/pop at empty, FIFO data ordering, filling to full, overflow attempts, simultaneous operations at full and middle occupancy, and draining.

## Recorded command

```sh
qrun -batch -access=rw+/. -uvmhome uvm-1.2 '-timescale' '1ns/1ns' -mfcu design.sv testbench.sv '-voptargs=+acc=npr' -do " run -all; exit"
```

## Selected console excerpts

These are excerpts, not the complete raw transcript.

```text
# Loading work.tb_sync_fifo_uvm(fast)
# Loading work.sync_fifo(fast)
# Loading work.sync_fifo_sva(fast)
# UVM_INFO @ 0: reporter [RNTST] Running test sync_fifo_test...
# UVM_INFO testbench.sv(210) @ 10485000: uvm_test_top.env.scb [SCB] Completed 4176 scoreboard checks; final occupancy=2
# --- UVM Report Summary ---
# ** Report counts by severity
# UVM_INFO :    6
# UVM_WARNING :    0
# UVM_ERROR :    0
# UVM_FATAL :    0
# ** Report counts by id
# [Questa UVM]     2
# [RNTST]     1
# [SCB]     1
# [TEST_DONE]     1
# [UVM/RELNOTES]     1
# ** Note: $finish    : /usr/share/questa/questasim/verilog_src/uvm-1.2/src/base/uvm_root.svh(517)
#    Time: 10485 ns  Iteration: 69  Instance: /tb_sync_fifo_uvm
# Errors: 0, Warnings: 0
*** Summary *********************************************
    qrun: Errors:   0, Warnings:   0
    vlog: Errors:   0, Warnings:   1
    vopt: Errors:   0, Warnings:   1
    vsim: Errors:   0, Warnings:   0
  Totals: Errors:   0, Warnings:   2
Done
```

## Warnings and limits

- `vlog-2650` recommends `-mfcu -cuname` for compilation-unit-scope bind declarations. My recorded run nevertheless explicitly loaded the SVA module.
- `vopt-10587` warns that `+acc` reduces optimization and recommends `-access/-debug` for visibility.
- These two tool warnings are separate from the zero UVM warning count.
- I did not record a functional covergroup percentage, assertion coverage, or code coverage report, so I make no claim of 100% coverage for this run.
- I have not recorded an intentional assertion-failure control run.
- The UVM test applies initial reset; reset during active traffic is not covered by this test.
- Passing this run does not establish correctness for all seeds, parameter configurations, or untested scenarios.

The earlier [basic testbench + SVA result](questa_sva_2026-10-16.md) records a separate simulation and its manual coverage.
