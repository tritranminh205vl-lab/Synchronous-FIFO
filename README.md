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


## RTL Design

### Parameters

| Parameter | Default | Description |
| :--- | :--- | :--- |
| **Depth** | 8 | Number of FIFO entries. Must be a power of 2. |
| **Width** | 8 | Data bus width in bits. |

### Port List

| Port | Direction | Width | Description |
| :--- | :--- | :--- | :--- |
| `clk` | Input | 1 | Clock — all ops on `posedge` |
| `rst_n` | Input | 1 | Async active-low reset |
| `w_en` | Input | 1 | Write enable |
| `r_en` | Input | 1 | Read enable |
| `w_data` | Input | `[Width-1:0]` | Write data |
| `r_data` | Output | `[Width-1:0]` | Read data (registered) |
| `full` | Output | 1 | FIFO full flag |
| `empty` | Output | 1 | FIFO empty flag |

---

## Testbench Architecture

**Key Design Decisions:**
* **Dual clocking blocks:** Separated in the interface to cleanly isolate stimulus from observation, preventing race conditions between the driver and monitor.
* **Self-checking scoreboard:** Uses a SystemVerilog queue as a golden model. On every monitored write (`w_en` && !`full`), data is pushed. On every read (`r_en` && !`empty`), expected data is popped and compared against the actual `r_data`.

---

## Verification Plan

The test runs in multiple sequential stages to ensure robust corner-case handling:
1. **READ_EMPTY:** Verify underflow protection — reads on an empty FIFO are ignored.
2. **WRITE_FULL:** Verify overflow protection — writes on a full FIFO are ignored.
3. **DATA_STRESS:** Fill FIFO completely, then drain completely.
4. **RANDOM:** Randomized `w_en`/`r_en` traffic for broad functional coverage.
5. **CONCURRENT OP:** Both push and pop asserted simultaneously in different FIFO states.

---

## Simulation Results

Coverage is tracked manually to ensure all critical states and transitions of the FIFO are hit during simulation. 

### Manual Functional Coverage Plan

| Coverage Bin | Description | Goal |
| :--- | :--- | :--- |
| **empty state** | FIFO occupancy is exactly 0 | 1 |
| **middle state** | FIFO occupancy is > 0 and < Depth | 1 |
| **full state** | FIFO occupancy is exactly Depth | 1 |
| **idle** | No push or pop operations | 1 |
| **push only** | Write without reading | 1 |
| **pop only** | Read without writing | 1 |
| **push + pop** | Simultaneous read and write | 1 |
| **push when full** | Attempting to write to a full FIFO | 1 |
| **pop when empty** | Attempting to read from an empty FIFO | 1 |
| **both in middle** | Simultaneous read/write while partially filled | 1 |
| **both when empty** | Simultaneous read/write on empty FIFO | 1 |
| **both when full** | Simultaneous read/write on full FIFO | 1 |

### Final Console Output

```text
FINAL SCOREBOARD REPORT
PASS CHECKS : 948
FAIL CHECKS : 0
REF COUNT   : 5
========================================
========================================
MANUAL FUNCTIONAL COVERAGE
empty state      : 1
middle state     : 1
full state       : 1
idle             : 1
push only        : 1
pop only         : 1
push + pop       : 1
push when full   : 1
pop when empty   : 1
both in middle   : 1
both when empty  : 1
both when full   : 1
Coverage         : 12/12 = 100%


How to Run
Clone the repository to your local machine.

Ensure you have a SystemVerilog-compatible simulator installed (e.g., ModelSim, Questa, VCS, or Riviera-PRO).

Compile the design and testbench files:

Bash
vlog design/fifo_sync.sv tb/*.sv
Run the simulation:

Bash
vsim -c fifo_top -do "run -all; exit"
