# Synchronous FIFO Design Verification Plan

## 1. Verification objective

Prove that the FIFO preserves ordering, never overflows or underflows, reports occupancy correctly, and follows the documented boundary policy for all combinations of `push`, `pop`, `empty`, and `full`.

The verification environment is deliberately split into two levels:

1. **Portable self-checking testbench** for fast regressions with Icarus/Questa/VCS/Xcelium.
2. **UVM environment** for transaction-level stimulus, monitor-based checking, functional coverage, and scalable regression structure.

Assertions independently check interface invariants and temporal behavior.

## 2. Verification architecture

```text
                +----------------+
sequence ------>| driver         |
                +-------+--------+
                        |
                        v
                +----------------+
                |      DUT       |
                +-------+--------+
                        |
                        v
                +----------------+
                | monitor        |
                +---+--------+---+
                    |        |
                    v        v
              scoreboard   coverage

Assertions observe DUT interface behavior independently.
```

The scoreboard does not receive expected results from the driver. It reconstructs expected FIFO behavior from transactions observed by the monitor.

## 3. Reference model

Reference model state:

- software queue / independent memory model;
- expected occupancy;
- expected held `dout` value.

For every sampled cycle:

```text
push_accept = push && (pre_count < DEPTH)
pop_accept  = pop  && (pre_count > 0)
```

If a pop is accepted, the model removes the queue head and predicts `dout`. If a push is accepted, the model appends `din`. The model then compares `count`, `empty`, `full`, and `dout` against the DUT.

## 4. Directed test matrix

| ID | Scenario | Main checks |
|---|---|---|
| FIFO-D01 | Reset from startup | count=0, empty=1, full=0, dout=0 |
| FIFO-D02 | Idle while empty | state stable |
| FIFO-D03 | Pop while empty | underflow blocked, dout stable |
| FIFO-D04 | Push one item | count increments, empty clears |
| FIFO-D05 | Push then pop | same data returned |
| FIFO-D06 | Multiple pushes then pops | FIFO order preserved |
| FIFO-D07 | Fill exactly to DEPTH | full asserts exactly at DEPTH |
| FIFO-D08 | Push while full | overflow blocked |
| FIFO-D09 | Drain exactly to zero | empty asserts exactly at zero |
| FIFO-D10 | Simultaneous push/pop in middle | count stable, ordering preserved |
| FIFO-D11 | Simultaneous push/pop while empty | push only accepted |
| FIFO-D12 | Simultaneous push/pop while full | pop only accepted |
| FIFO-D13 | Write pointer wrap | data remains ordered across wrap |
| FIFO-D14 | Read pointer wrap | data remains ordered across wrap |
| FIFO-D15 | Reset while non-empty | pointers/count/output return to reset state |
| FIFO-D16 | Long mixed traffic | scoreboard stays synchronized |

## 5. Random regression

The portable testbench runs 1000 pseudo-random cycles after directed testing. Traffic is biased to exercise:

- push-only;
- pop-only;
- simultaneous push/pop;
- idle cycles;
- illegal push while full;
- illegal pop while empty;
- transitions repeatedly through empty/middle/full occupancy.

The UVM random sequence uses a weighted constraint for the four request combinations and can be extended with additional sequence classes.

## 6. Assertions

`tb/sva/sync_fifo_sva.sv` checks:

- `count <= DEPTH`;
- `full == (count == DEPTH)`;
- `empty == (count == 0)`;
- `full` and `empty` never high together;
- accepted push increments occupancy;
- accepted pop decrements occupancy;
- simultaneous legal push/pop in the middle keeps count stable;
- empty+both follows push-only boundary policy;
- full+both follows pop-only boundary policy;
- overflow and underflow attempts do not corrupt occupancy;
- `dout` holds when a pop was not accepted.

Coverage properties also mark full, empty, simultaneous middle traffic, overflow attempts, and underflow attempts.

## 7. Functional coverage goals

Portable manual coverage tracks:

- occupancy: empty / middle / full;
- operation: idle / push / pop / both;
- occupancy x operation cross (12 bins);
- overflow attempt;
- underflow attempt;
- both at empty/middle/full;
- read pointer wrap;
- write pointer wrap;
- reset while non-empty.

UVM covergroups implement the main occupancy/operation cross and illegal request coverage. Commercial coverage tools can then add code coverage for statements, branches, expressions, toggles, and FSMs where applicable.

## 8. Exit criteria

A reasonable project-level signoff target is:

- zero scoreboard mismatches;
- zero assertion failures;
- all directed test IDs pass;
- 100% planned functional coverage bins or documented exclusions;
- no RTL lint errors;
- synthesis sanity check passes;
- regression passes in CI.

For real production signoff, project-specific code coverage and formal/static checks would also be reviewed with the design team.
