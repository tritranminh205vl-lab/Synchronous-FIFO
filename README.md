# Synchronous FIFO — RTL + Design Verification Project

I developed this SystemVerilog project for a parameterized **single-clock synchronous FIFO**. I expanded my original RTL and self-checking testbench into a structured repository covering RTL design, verification, assertions, synthesis checks, and documentation.

I implemented the design using the counter-based synchronous FIFO architecture: one common clock is used for read and write, writes occur only when the FIFO is not full, reads occur only when it is not empty, and `count` determines the `full`/`empty` conditions.

## Architecture

```text
                       COMMON CLOCK
                           |
           +---------------+---------------+
           |                               |
      push / din                         pop
           |                               |
           v                               v
    +--------------+                +--------------+
    | Write logic  |                | Read logic   |
    | + write ptr  |                | + read ptr   |
    +------+-------+                +------+-------+
           |                               |
           +----------+  FIFO  +-----------+
                      | memory |
                      +---+----+
                          |
                          v
                         dout

                occupancy counter
                  /           \
          count == 0       count == DEPTH
              |                 |
            empty              full
```

Default configuration:

```text
DEPTH      = 8 entries
DATA_WIDTH = 8 bits
COUNT_WIDTH = clog2(DEPTH+1) = 4 bits
Reset      = synchronous active-low
Read data  = registered
```

## Boundary behavior

I explicitly defined the behavior of simultaneous requests:

| FIFO state before edge | push | pop | Result |
|---|---:|---:|---|
| Empty | 1 | 1 | push accepted, pop rejected |
| Middle | 1 | 1 | both accepted, count unchanged |
| Full | 1 | 1 | pop accepted, push rejected |

I retained the accepted-operation policy from my baseline implementation so that the RTL and testbench use the same boundary expectations.

## Project structure

```text
sync_fifo_rtl_dv_project/
├── baseline/
│   ├── SynFIFO_original.v
│   └── SynFIFO_tb_original.v
├── rtl/
│   ├── sync_fifo.sv
│   └── files.f
├── tb/
│   ├── basic/
│   │   ├── tb_sync_fifo.sv
│   │   └── files.f
│   ├── sva/
│   │   ├── sync_fifo_sva.sv
│   │   └── sync_fifo_bind.sv
│   └── uvm/
│       ├── sync_fifo_if.sv
│       ├── sync_fifo_pkg.sv
│       ├── sync_fifo_txn.svh
│       ├── sync_fifo_driver.svh
│       ├── sync_fifo_monitor.svh
│       ├── sync_fifo_scoreboard.svh
│       ├── sync_fifo_coverage.svh
│       ├── sync_fifo_agent.svh
│       ├── sync_fifo_sequences.svh
│       ├── sync_fifo_env.svh
│       ├── sync_fifo_test.svh
│       ├── tb_sync_fifo_uvm.sv
│       └── files.f
├── synth/
│   └── sync_fifo.ys
├── docs/
│   ├── RTL_SPEC.md
│   ├── DV_PLAN.md
│   ├── TRACEABILITY.md
│   ├── BASELINE_REVIEW.md
│   ├── INTERVIEW_QA.md
│   ├── GITHUB_GUIDE.md
│   └── evidence/
├── scripts/
│   ├── run_basic.sh
│   ├── run_basic.bat
│   └── run_yosys.bat
├── .github/workflows/rtl-regression.yml
├── .gitignore
├── Makefile
└── README.md
```

## How I developed the project

My original implementation included a portable self-checking testbench with reference memory, directed cases, random traffic, waveform dumping, and manual coverage. I retained those features and expanded the project with:

- synthesizable SystemVerilog RTL separated from verification code;
- explicit specification and boundary policy;
- independent cycle-by-cycle scoreboard;
- 1000-cycle random regression after directed tests;
- state x operation coverage matrix;
- pointer-wrap and reset-while-nonempty coverage;
- SVA assertions for invariants and temporal behavior;
- UVM driver/monitor/scoreboard/coverage architecture;
- Yosys synthesis sanity script;
- GitHub Actions simulation/lint/synthesis CI;
- requirement-to-verification traceability.

## Recorded verification result

On **2026-10-16**, I ran the basic testbench on EDA Playground using **QuestaSim 2025.2**. The run completed with the SVA module loaded: **1,073 cycles, 6,450 passed scoreboard checks, 0 failed checks**, and no reported assertion failures. Manual functional coverage reached **27/27 buckets (100%)**; this is not assertion or UVM covergroup coverage.

See the [basic + SVA run report](docs/evidence/questa_sva_2026-10-16.md) for provenance, warnings, and scope.

I also ran a separate **UVM 1.2 + SVA** simulation on the same day. It completed `sync_fifo_test` with **4,176 scoreboard checks**, **0 UVM warnings/errors/fatals**, and no reported assertion failures. Simulation finished at **10,485 ns**, with final reference occupancy **2** (the test does not require a final drain). See the [UVM run report and console excerpts](docs/evidence/questa_uvm_2026-10-16.md).

I recorded both results from my EDA Playground runs. Neither run was a CI execution pinned to an exact source commit. My UVM browser testbench includes a coverage-subscriber argument-name fix, so I do not treat that result as a pass for the unmodified repository sources. I have not recorded a UVM covergroup or assertion coverage percentage.

## Run the portable regression

### Linux / Git Bash with Make

```bash
make basic
```

Equivalent manual commands:

```bash
mkdir -p build
iverilog -g2012 -Wall -s tb_sync_fifo \
  -o build/sync_fifo_basic.vvp \
  rtl/sync_fifo.sv tb/basic/tb_sync_fifo.sv
vvp build/sync_fifo_basic.vvp
```

### Windows without Make

```bat
scripts\run_basic.bat
```

The testbench writes:

```text
sync_fifo.vcd
```

I use GTKWave or another waveform viewer to inspect this file.

A clean run should end with a zero failure count and:

```text
FINAL RESULT: TEST PASSED
```

## Run lint

With Verilator installed:

```bash
make lint
```

## Run synthesis sanity check

With Yosys installed:

```bash
make synth
```

On Windows:

```bat
scripts\run_yosys.bat
```

This is not physical implementation or timing signoff; it is a fast check that the RTL can be elaborated/synthesized by an open-source synthesis flow.

## UVM

The `tb/uvm/` environment contains:

```text
sequence -> sequencer -> driver -> DUT
                             |
                         monitor
                         /     \
                 scoreboard   coverage
```

For Questa with a source UVM installation:

```bash
make uvm-questa UVM_HOME=/path/to/uvm
```

I keep the file list available for adaptation to VCS or Xcelium.

## Verification philosophy

I use waveforms for debugging. To judge correctness, I rely on:

```text
independent reference model
        +
scoreboard comparisons
        +
assertions
        +
functional coverage
        +
repeatable regression
```

## How I organized the documentation

1. `docs/RTL_SPEC.md` — exact FIFO behavior.
2. `docs/DV_PLAN.md` — verification strategy and test matrix.
3. `docs/TRACEABILITY.md` — requirement-to-check mapping.
4. `docs/BASELINE_REVIEW.md` — what changed from the original project.
5. `docs/WAVEFORM_GUIDE.md` — what to inspect in simulation.
6. `docs/INTERVIEW_QA.md` — my explanations of design and verification decisions.
7. `docs/GITHUB_GUIDE.md` — my workflow for publishing and maintaining the project.

## Reference basis

I used the VLSI Verify synchronous FIFO material as an architectural reference, particularly its explanation of synchronous operation and counter-based Method 3. I implemented my own RTL with an explicit accepted-operation policy and built the verification structure around it.

Reference: `https://vlsiverify.com/verilog/verilog-codes/synchronous-fifo/`
