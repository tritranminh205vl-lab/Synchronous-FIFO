# Review of the Uploaded Baseline

## What was already good

The original RTL is substantially better than a minimal tutorial FIFO because it derives count changes from `write_accept` and `read_accept`, not directly from raw `push`/`pop`. That means illegal requests at full/empty do not accidentally overflow or underflow the occupancy counter.

The original testbench is also already self-checking. It contains:

- an independent reference memory and pointers;
- directed corner-case tests;
- random stimulus;
- automatic checks for count/full/empty/dout;
- manual functional coverage;
- VCD waveform generation;
- a watchdog timeout.

Your uploaded console evidence shows a run with **948 PASS checks, 0 FAIL checks, and 12/12 manual coverage = 100%**. That is a useful baseline and is kept under `baseline/` plus screenshots under `docs/evidence/`.

## What this revision changes

The project is reorganized so it looks more like a small RTL/DV repository rather than two standalone files:

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

The revised specification also explicitly defines the two ambiguous simultaneous-operation boundary cases. This matters because different FIFO products may make different throughput choices at full or empty.

## Important distinction from the web reference

The linked tutorial describes the counter-based method using `count == 0` and `count == DEPTH`. The project follows that architecture, but the production-style implementation updates count from **accepted** operations. This makes behavior safe even when the environment asserts `push` while full or `pop` while empty.
