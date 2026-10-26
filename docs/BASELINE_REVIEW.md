# Review of My Baseline Implementation

## What was already good

In my original RTL, I derived count changes from `write_accept` and `read_accept` rather than directly from raw `push`/`pop`. That means illegal requests at full/empty do not accidentally overflow or underflow the occupancy counter.

I also built the original testbench with self-checking behavior. It contains:

- an independent reference memory and pointers;
- directed corner-case tests;
- random stimulus;
- automatic checks for count/full/empty/dout;
- manual functional coverage;
- VCD waveform generation;
- a watchdog timeout.

My recorded baseline console evidence shows **948 PASS checks, 0 FAIL checks, and 12/12 manual coverage = 100%**. I preserved the original code under `baseline/` and the screenshots under `docs/evidence/`.

## What this revision changes

I reorganized the original two files into an RTL/DV repository with separate responsibilities:

```text
baseline/     original submitted code
rtl/          synthesizable DUT
synth/        Yosys synthesis sanity flow
tb/basic/     portable self-checking regression
tb/sva/       temporal assertions
tb/uvm/       UVM verification environment
docs/         specification, DV plan, traceability, GitHub guide
.github/      CI regression
```

I also updated the specification to explicitly define the two ambiguous simultaneous-operation boundary cases. This matters because different FIFO products may make different throughput choices at full or empty.

## Important distinction from the web reference

The linked tutorial describes the counter-based method using `count == 0` and `count == DEPTH`. I followed that architecture and implemented count updates from **accepted** operations. This makes behavior safe even when the environment asserts `push` while full or `pop` while empty.
