# Synchronous FIFO — RTL Design & Verification

A complete RTL-to-verification project implementing a parameterizable synchronous FIFO in SystemVerilog, verified with a structured testbench featuring a scoreboard, manual functional coverage, and assertions.

**Author:** Trần Minh Trí (Student ID: 232071187)

## Table of Contents
- [Overview](#overview)
- [Project Structure](#project-structure)
- [RTL Design](#rtl-design)
- [Testbench Architecture](#testbench-architecture)
- [Verification Plan](#verification-plan)
- [Simulation Results](#simulation-results)
- [How to Run](#how-to-run)

---

## Overview

| Item | Detail |
| :--- | :--- |
| **Module** | `fifo_sync` |
| **Language** | SystemVerilog (IEEE 1800-2017) |
| **Default Config** | Depth = 8, Width = 8-bit |
| **Reset** | Asynchronous, active-low (`rst_n`) |
| **Output** | Registered (`r_data` valid 1 cycle after `r_en`) |

---

## Project Structure

```text
.
├── design/
│   └── fifo_sync.sv
├── tb/
│   ├── fifo_if.sv
│   ├── fifo_top.sv
│   └── ...
├── fifo_sync_spec.pdf
└── README.md

---

## RTL Design

### Parameters

| Parameter | Default | Description                           |
| --------- | ------: | ------------------------------------- |
| `DEPTH`   |       8 | Number of entries in the FIFO         |
| `WIDTH`   |       8 | Width of each FIFO data entry in bits |

### Port List

| Port    | Direction | Width                   | Description                                      |
| ------- | --------- | ----------------------- | ------------------------------------------------ |
| `clk`   | Input     | 1                       | System clock                                     |
| `rst_n` | Input     | 1                       | Active-low reset                                 |
| `push`  | Input     | 1                       | Request to write data into the FIFO              |
| `pop`   | Input     | 1                       | Request to read data from the FIFO               |
| `din`   | Input     | `[WIDTH-1:0]`           | Input data                                       |
| `dout`  | Output    | `[WIDTH-1:0]`           | Registered FIFO output data                      |
| `empty` | Output    | 1                       | Asserted when the FIFO contains no valid entries |
| `full`  | Output    | 1                       | Asserted when the FIFO reaches `DEPTH` entries   |
| `count` | Output    | `[$clog2(DEPTH+1)-1:0]` | Current number of entries stored in the FIFO     |

### FIFO Architecture

The design contains:

* A memory array used to store FIFO data.
* A circular write pointer used to select the next write location.
* A circular read pointer used to select the next read location.
* An occupancy counter used to generate the `full` and `empty` flags.
* Logic for handling independent and simultaneous push/pop requests.

A write operation is accepted when:

```systemverilog
push && !full
```

A read operation is accepted when:

```systemverilog
pop && !empty
```

For a valid simultaneous push and pop while the FIFO is partially filled, one item is written and one item is removed during the same cycle, therefore the FIFO occupancy remains unchanged.

---

## Testbench Architecture

The verification environment is implemented as a **self-checking SystemVerilog testbench** without UVM.

The main verification flow is:

```text
Stimulus
   |
   v
apply_cycle()
   |
   +------> DUT
   |
   +------> Reference Model
                |
                v
          Expected Result
                |
                v
             Scoreboard
                |
          PASS / FAIL Check
```

### Main Components

| Component          | Description                                                               |
| ------------------ | ------------------------------------------------------------------------- |
| Stimulus Generator | Generates directed and randomized `push`, `pop`, and `din` transactions   |
| `apply_cycle` Task | Drives one complete FIFO transaction and calculates the expected behavior |
| Reference Memory   | Stores expected FIFO data independently from the DUT                      |
| Reference Pointers | Track expected read and write positions                                   |
| Reference Counter  | Tracks the expected FIFO occupancy                                        |
| Scoreboard         | Compares DUT outputs against expected values                              |
| Manual Coverage    | Tracks whether important FIFO states and corner cases have been exercised |

---

## Reference Model

The testbench maintains an independent FIFO model using:

```systemverilog
ref_mem
ref_wr_ptr
ref_rd_ptr
ref_count
ref_dout
```

For each test cycle, the reference model first determines whether the requested operations should be accepted:

```systemverilog
write_accept = push_i && (pre_count < DEPTH);
read_accept  = pop_i  && (pre_count > 0);
```

The expected FIFO occupancy is then calculated from the accepted operations:

```systemverilog
case ({write_accept, read_accept})
    2'b10: expected_count = pre_count + 1;
    2'b01: expected_count = pre_count - 1;
    default: expected_count = pre_count;
endcase
```

This reference model does **not** rely on the DUT `full` or `empty` outputs when deciding whether an operation should succeed. This allows incorrect DUT status flags to be detected by the scoreboard.

---

## Scoreboard

After each positive clock edge, the testbench waits for the RTL nonblocking assignments to update and then checks:

```text
count
full
empty
dout
```

The following checking tasks are used:

```systemverilog
check_count_value(expected_count);
check_full_value(expected_full);
check_empty_value(expected_empty);
check_dout_value(expected_dout);
```

Each successful comparison increments the pass counter. Any mismatch increments the failure counter and prints diagnostic information to the simulation log.

---

## Verification Plan

The following scenarios are verified.

| Test Case               | Description                                                     | Priority |
| ----------------------- | --------------------------------------------------------------- | -------- |
| Reset                   | Verify FIFO returns to its initial empty state                  | Critical |
| Basic Push              | Write one item and verify occupancy increases                   | High     |
| Basic Pop               | Read one item and verify correct output data                    | High     |
| FIFO Full               | Fill the FIFO and verify `full` assertion                       | High     |
| FIFO Empty              | Drain the FIFO and verify `empty` assertion                     | High     |
| Push When Full          | Verify a write request is rejected when full                    | Critical |
| Pop When Empty          | Verify a read request is rejected when empty                    | Critical |
| Simultaneous Push + Pop | Verify concurrent read/write behavior                           | High     |
| Fill Then Drain         | Verify FIFO data ordering across a complete fill/drain sequence | High     |
| Pointer Wraparound      | Verify read/write pointers correctly wrap from `DEPTH-1` to `0` | High     |
| Random Push/Pop         | Exercise different occupancy levels with randomized operations  | High     |
| Boundary Conditions     | Verify simultaneous push/pop at empty and full states           | Critical |

---

## Important Corner Cases

### Push When FIFO Is Full

When:

```text
count = DEPTH
push  = 1
```

the write request must be rejected.

Expected behavior:

```text
count remains DEPTH
full remains asserted
stored FIFO data is not overwritten
```

### Pop When FIFO Is Empty

When:

```text
count = 0
pop   = 1
```

the read request must be rejected.

Expected behavior:

```text
count remains 0
empty remains asserted
dout remains unchanged
```

### Push and Pop in the Middle State

For:

```text
0 < count < DEPTH
push = 1
pop  = 1
```

both operations are accepted.

Expected behavior:

```text
one item is removed
one item is inserted
count remains unchanged
FIFO ordering is preserved
```

### Push and Pop While Empty

For:

```text
count = 0
push = 1
pop  = 1
```

the reference model treats:

```text
write_accept = 1
read_accept  = 0
```

Therefore the new item is written and the occupancy becomes `1`.

### Push and Pop While Full

For:

```text
count = DEPTH
push = 1
pop  = 1
```

the reference model treats:

```text
write_accept = 0
read_accept  = 1
```

Therefore one item is read and the occupancy decreases to `DEPTH-1`.

---

## Manual Functional Coverage

Because the project is designed to run with **Icarus Verilog**, manual functional coverage counters are used instead of SystemVerilog `covergroup`.

The following coverage points are tracked:

| Coverage Bin      | Description                               | Goal |
| ----------------- | ----------------------------------------- | ---: |
| `empty state`     | FIFO occupancy is exactly `0`             |    1 |
| `middle state`    | FIFO occupancy is between `0` and `DEPTH` |    1 |
| `full state`      | FIFO occupancy is exactly `DEPTH`         |    1 |
| `idle`            | Neither push nor pop is requested         |    1 |
| `push only`       | Push without pop                          |    1 |
| `pop only`        | Pop without push                          |    1 |
| `push + pop`      | Push and pop requested simultaneously     |    1 |
| `push when full`  | Push request while FIFO is full           |    1 |
| `pop when empty`  | Pop request while FIFO is empty           |    1 |
| `both in middle`  | Push and pop while partially filled       |    1 |
| `both when empty` | Push and pop while FIFO is empty          |    1 |
| `both when full`  | Push and pop while FIFO is full           |    1 |

Maximum manual functional coverage:

```text
12 / 12 = 100%
```

---

## Simulation Timing Strategy

The testbench drives DUT inputs at the **falling edge** of the clock:

```systemverilog
@(negedge clk);

push = push_i;
pop  = pop_i;
din  = din_i;
```

This gives the input signals sufficient time to settle before the DUT samples them at the next positive edge.

The DUT is evaluated at:

```systemverilog
@(posedge clk);
```

The testbench then waits:

```systemverilog
#1;
```

before checking the outputs.

This delay allows nonblocking assignments inside the RTL to complete before scoreboard comparison and helps avoid simulation race conditions.

---

## How to Run

The project can be simulated directly in the browser using **EDA Playground**.

### EDA Playground Configuration

Use the following settings:

```text
Language:
SystemVerilog / Verilog

Simulator:
Icarus Verilog
```

Recommended option:

```text
Open EPWave after run
```

### Files

Place the RTL in the **Design** window:

```text
SynFIFO.sv
```

Place the testbench in the **Testbench** window:

```text
SynFIFO_tb.sv
```

No UVM library is required.

No UVM checkbox is required.

No `+UVM_TESTNAME` option is required.

---

## Run the Simulation

Click:

```text
Run
```

The simulation console will show every FIFO transaction.

Example:

```text
[46000][CYCLE 1] push=0 pop=0 din=0x00 | dout=0x00 count=0 empty=1 full=0
[56000][CYCLE 2] push=1 pop=0 din=0xA5 | dout=0x00 count=1 empty=0 full=0
[66000][CYCLE 3] push=0 pop=1 din=0x00 | dout=0xA5 count=0 empty=1 full=0
```

---

## Expected Final Report

A successful simulation should end with a report similar to:

```text
========================================
FINAL SCOREBOARD REPORT
========================================
PASS CHECKS : <number of successful checks>
FAIL CHECKS : 0
REF COUNT   : <final reference count>
========================================

========================================
MANUAL FUNCTIONAL COVERAGE
========================================
empty state        : 1
middle state       : 1
full state         : 1
idle               : 1
push only          : 1
pop only           : 1
push + pop         : 1
push when full     : 1
pop when empty     : 1
both in middle     : 1
both when empty    : 1
both when full     : 1

Coverage           : 12/12 = 100%
========================================

FINAL RESULT: TEST PASSED
```

The exact number of `PASS CHECKS` depends on the number of directed and randomized test cycles executed.

The important acceptance criteria are:

```text
FAIL CHECKS = 0
Coverage    = 12/12 = 100%
FINAL RESULT: TEST PASSED
```

---

## Waveform Analysis

The testbench generates a VCD waveform file that can be opened using **EPWave**.

Recommended signals:

```text
clk
rst_n
push
pop
din
dout
count
empty
full
```

The waveform should be used to visually confirm:

* Reset behavior
* Basic push operation
* Basic pop operation
* FIFO full condition
* FIFO empty condition
* Push while full
* Pop while empty
* Simultaneous push and pop
* Pointer wraparound
* FIFO fill and drain sequence

---

## Verification Strategy Summary

This project uses a lightweight verification methodology suitable for learning RTL verification concepts without requiring a commercial UVM simulator.

The verification environment demonstrates several important Design Verification concepts:

* Directed testing
* Randomized stimulus
* Independent reference modeling
* Self-checking scoreboard
* Functional coverage
* Corner-case testing
* Boundary-condition verification
* Waveform debugging
* Automated PASS/FAIL reporting

These concepts provide a foundation for more advanced SystemVerilog and UVM-based verification environments.
