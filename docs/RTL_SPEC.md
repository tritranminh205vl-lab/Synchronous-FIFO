# Synchronous FIFO RTL Specification

## 1. Purpose

This block is a single-clock FIFO used to buffer data between a producer and a consumer that operate in the same clock domain.

The reference material describes synchronous FIFO read and write operations using the same clock, and presents a counter-based implementation where `empty` is detected with `count == 0` and `full` with `count == DEPTH`. This project uses that counter-based architecture while defining the boundary behavior more explicitly.

## 2. Interface

| Signal | Direction | Width | Meaning |
|---|---|---:|---|
| `clk` | input | 1 | Common FIFO clock |
| `rst_n` | input | 1 | Synchronous active-low reset |
| `push` | input | 1 | Request to enqueue `din` |
| `din` | input | `DATA_WIDTH` | Write data |
| `pop` | input | 1 | Request to dequeue the oldest item |
| `dout` | output | `DATA_WIDTH` | Registered read data |
| `empty` | output | 1 | FIFO has zero valid entries |
| `full` | output | 1 | FIFO has `DEPTH` valid entries |
| `count` | output | `$clog2(DEPTH+1)` | Current occupancy |

## 3. Parameters

- `DEPTH`: number of storage entries. Default: 8.
- `DATA_WIDTH`: width of each stored entry. Default: 8 bits.
- `PTR_WIDTH = max(1, $clog2(DEPTH))` internally.

The explicit pointer wrap logic allows non-power-of-two depths as well as power-of-two depths.

## 4. Accepted operations

The FIFO decides whether a request is accepted from the state at the **start of the active clock edge**:

```text
push_accept = push && !full
pop_accept  = pop  && !empty
```

This prevents overflow and underflow even when the environment asserts an illegal request.

## 5. State update rules

| Pre-state | `push` | `pop` | Accepted operation | Next count |
|---|---:|---:|---|---:|
| empty | 0 | 0 | none | 0 |
| empty | 0 | 1 | none | 0 |
| empty | 1 | 0 | push | 1 |
| empty | 1 | 1 | push only | 1 |
| middle | 0 | 0 | none | unchanged |
| middle | 0 | 1 | pop | count - 1 |
| middle | 1 | 0 | push | count + 1 |
| middle | 1 | 1 | push + pop | unchanged |
| full | 0 | 0 | none | DEPTH |
| full | 1 | 0 | none | DEPTH |
| full | 0 | 1 | pop | DEPTH - 1 |
| full | 1 | 1 | pop only | DEPTH - 1 |

The two boundary cases are an intentional project specification:

- **empty + push + pop:** push wins because there was no valid data to pop at the beginning of the cycle.
- **full + push + pop:** pop wins because the FIFO was already full at the beginning of the cycle, so the new write request is rejected.

A throughput-optimized FIFO could choose a different policy, such as allowing a simultaneous pop to make room for a push while full. That is a different interface contract and is not used in this project.

## 6. Data ordering

The FIFO guarantees first-in, first-out order for all accepted operations. `dout` is registered:

- on an accepted pop, `dout` becomes the oldest queued element;
- without an accepted pop, `dout` holds its previous value;
- after reset, `dout = 0`.

## 7. Reset

`rst_n` is sampled synchronously on `posedge clk`.

When `rst_n == 0` at the active edge:

- write pointer = 0;
- read pointer = 0;
- count = 0;
- `dout = 0`;
- therefore `empty = 1`, `full = 0`.

The memory array itself is not cleared because its contents are invalid whenever `count == 0`. This is normally more synthesis-friendly than resetting every memory bit.

## 8. Architecture

```text
                    +-------------------------+
push/din ---------->| write accept + wptr     |
                    |                         |
                    |      FIFO memory        |----> registered dout
pop ---------------->| read accept + rptr      |
                    |                         |
                    | occupancy counter       |
                    +------------+------------+
                                 |
                          +------+------+
                          |             |
                      count==0       count==DEPTH
                          |             |
                        empty           full
```

## 9. Design improvements over the baseline

The uploaded baseline already uses the stronger idea of counting **accepted** reads/writes rather than raw requests. The revised RTL keeps that behavior and improves project quality by:

- using SystemVerilog `logic` / `always_ff`;
- making the specification for simultaneous operations explicit;
- using `$clog2(DEPTH+1)` for occupancy width;
- preserving support for non-power-of-two depths with explicit pointer wrap;
- adding parameter sanity checks for simulation;
- separating RTL, assertions, verification, synthesis scripts, and documentation.
