# QuestaSim SVA regression result — 2026-10-16

## Result

I ran my basic self-checking FIFO testbench successfully with the SVA module loaded and no reported assertion or simulation errors.

| Item | Observed result |
| --- | --- |
| Platform | EDA Playground |
| Simulator | QuestaSim-64 2025.2, Linux x86-64 (May 31, 2025) |
| Run timestamp | 2026-10-16 07:38:46 UTC / 14:38:46 Vietnam time |
| Top module | `tb_sync_fifo` |
| SVA module loaded | `work.sync_fifo_sva(fast)` |
| Testbench cycles | 1,073 |
| Passed scoreboard checks | 6,450 |
| Failed scoreboard checks | 0 |
| Final reference occupancy | 0 |
| Manual functional coverage | 27/27 buckets (100%) |
| Simulation finish time | 10,816 ns |
| Tool errors | 0 |
| Tool warnings | 2 (one compiler, one optimizer) |
| Testbench result | `FINAL RESULT: TEST PASSED` |

## Evidence provenance and scope

I recorded this report from my EDA Playground console output. It documents that run rather than a new CI execution or an independent rerun. I did not retain the browser source snapshot, playground URL, random seed, or source commit SHA with the output, so I cannot pin this evidence to an exact repository revision.

This run covers the basic testbench with SVA, **not the UVM testbench**. No successful UVM simulation result is recorded here.

The reported 100% is the testbench's manual functional coverage bucket score. It is not assertion coverage, code coverage, or UVM covergroup coverage. The SVA module was loaded and no assertion failures were reported. I have not recorded an intentional assertion-failure control run or a per-property coverage report.

## Command recorded by EDA Playground

```sh
qrun -batch -access=rw+/. '-timescale' '1ns/1ns' -mfcu design.sv testbench.sv '-voptargs=+acc=npr' -do " run -all; exit"
```

The two browser files contain the RTL, basic testbench, SVA module, and bind declaration. The top module in my recorded log is `tb_sync_fifo`.

## Console excerpts

I retained the following selected console excerpts from my run; they are not a complete raw transcript.

```text
# Loading work.design_sv_unit(fast)
# Loading work.tb_sync_fifo(fast)
# Loading work.sync_fifo(fast)
# Loading work.sync_fifo_sva(fast)
#
# run -all
# [40000][TB] Reset released
#
# ================ DIRECTED REGRESSION ================
# [490000][TB] Reset released
#
# ================ RANDOM REGRESSION =================
#
# ============================================================
# FINAL SCOREBOARD REPORT
# CYCLES      : 1073
# PASS CHECKS : 6450
# FAIL CHECKS : 0
# REF COUNT   : 0
# ============================================================
# ============================================================
# MANUAL FUNCTIONAL COVERAGE
# occupancy empty/middle/full : 1 1 1
# idle/push/pop/both           : 1 1 1 1
# overflow/underflow attempts : 1 1
# both@empty/middle/full      : 1 1 1
# write/read pointer wrap     : 1 1
# reset while non-empty       : 1
# state x operation cross:
#   state[0] = idle:1 push:1 pop:1 both:1
#   state[1] = idle:1 push:1 pop:1 both:1
#   state[2] = idle:1 push:1 pop:1 both:1
# Coverage bucket score       : 27/27 = 100%
# ============================================================
# FINAL RESULT: TEST PASSED
# ** Note: $finish    : design.sv(587)
#    Time: 10816 ns  Iteration: 0  Instance: /tb_sync_fifo
# End time: 03:38:48 on Oct 16,2026, Elapsed time: 0:00:01
# Errors: 0, Warnings: 0
End time: 03:38:48 on Oct 16,2026, Elapsed time: 0:00:02
*** Summary *********************************************
    qrun: Errors:   0, Warnings:   0
    vlog: Errors:   0, Warnings:   1
    vopt: Errors:   0, Warnings:   1
    vsim: Errors:   0, Warnings:   0
  Totals: Errors:   0, Warnings:   2
Done
```

The simulator's internal clock timestamps differ from the EDA Playground UTC header; the run timestamp above uses the explicit UTC header.

## Warnings observed

- `vlog-2650`: a compilation-unit-scope `bind` was found; the compiler recommends `-mfcu -cuname` to ensure elaboration. In this run, the elaboration and simulation logs explicitly show `sync_fifo_sva` loaded.
- `vopt-10587`: `+acc` disables some optimizations and may slow simulation; the tool recommends `-access/-debug` for visibility.

Neither warning prevented this simulation from completing.

## Follow-up verification

- I plan to run a deliberate failing assertion to confirm error detection, restore the original property, then rerun and retain both logs.
- I recorded the separate `tb_sync_fifo_uvm` run with UVM 1.2 in the [UVM + SVA report](questa_uvm_2026-10-16.md), including scoreboard activity and reported error counts.
