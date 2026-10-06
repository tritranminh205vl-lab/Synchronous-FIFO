# Synchronous FIFO — RTL + Design Verification Project

A portfolio-style SystemVerilog project for a parameterized **single-clock synchronous FIFO**, upgraded from the original submitted RTL/testbench into a structured RTL-DV repository.

The design follows the counter-based synchronous FIFO architecture: one common clock is used for read and write, writes occur only when the FIFO is not full, reads occur only when it is not empty, and `count` determines the `full`/`empty` conditions.

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

This repository makes simultaneous-request behavior explicit:

| FIFO state before edge | push | pop | Result |
|---|---:|---:|---|
| Empty | 1 | 1 | push accepted, pop rejected |
| Middle | 1 | 1 | both accepted, count unchanged |
| Full | 1 | 1 | pop accepted, push rejected |

This matches the baseline project's accepted-operation philosophy and avoids ambiguous testbench expectations.

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

## What was improved

Your original project already had a strong portable self-checking testbench with reference memory, directed cases, random traffic, waveform dumping, and manual coverage. This revision keeps those strengths but makes the project more suitable for an RTL/DV portfolio:

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

Open it in GTKWave or another waveform viewer.

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

You can adapt the same file list for VCS or Xcelium.

## Verification philosophy

The project does **not** use waveform inspection as the primary pass/fail method. A waveform is debug evidence. Correctness is judged by:

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

## Documents to read in order

1. `docs/RTL_SPEC.md` — exact FIFO behavior.
2. `docs/DV_PLAN.md` — verification strategy and test matrix.
3. `docs/TRACEABILITY.md` — requirement-to-check mapping.
4. `docs/BASELINE_REVIEW.md` — what changed from the original project.
5. `docs/WAVEFORM_GUIDE.md` — what to inspect in simulation.
6. `docs/INTERVIEW_QA.md` — questions you should be able to answer yourself.
7. `docs/GITHUB_GUIDE.md` — publish and maintain the project correctly.

## Reference basis

The architecture was based on the linked VLSI Verify synchronous FIFO material, especially its discussion of synchronous operation and the counter-based Method 3. This repository does not copy that tutorial implementation; it defines a stricter accepted-operation policy and adds a full verification structure around the design.

Reference: `https://vlsiverify.com/verilog/verilog-codes/synchronous-fifo/`
