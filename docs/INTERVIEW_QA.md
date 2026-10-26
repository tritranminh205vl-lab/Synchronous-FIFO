# My FIFO RTL/DV Design Decisions

I use these questions and answers to explain the choices I made in this project.

## Why is this called a synchronous FIFO?

Read and write requests are both sampled in the same clock domain on the same `clk` edge. An asynchronous FIFO instead has independent write and read clocks and therefore needs clock-domain-crossing techniques such as Gray-coded pointers and synchronizers.

## Why use `count` for full/empty?

I chose the counter method: empty is `count == 0` and full is `count == DEPTH`. This allows all `DEPTH` entries to be used and makes occupancy directly visible for debug and verification.

## Why must count be based on accepted operations?

Raw `push` and `pop` are requests, not proof that an operation happened. A push at full or pop at empty must be rejected. Updating count from accepted operations prevents underflow/overflow corruption.

## What happens if push and pop are both 1?

In a middle state, both are accepted: the oldest item is popped and a new item is pushed, so count stays unchanged. At empty, only push is accepted. At full, only pop is accepted. I explicitly specified those last two behaviors as project requirements.

## Could full + push + pop accept both instead?

Yes, a different microarchitecture could allow the pop to free a slot and accept the push in the same cycle. That improves throughput, but it changes the interface contract and the scoreboard/assertions must be updated accordingly.

## Why did I leave the memory array unreset?

After reset, count is zero, so every memory location is logically invalid. Resetting the array can prevent efficient RAM inference or add unnecessary reset logic. Resetting pointers, count, and output is enough for this architecture.

## What does my scoreboard check?

I built it to maintain an independent FIFO model and compare the DUT's output data, occupancy, and flags on every cycle. It verifies behavior rather than only printing waveforms.

## Why did I add assertions alongside my scoreboard?

I use assertions to catch local temporal and invariant failures close to the cause, for example count exceeding depth or flags disagreeing with count. The scoreboard focuses on end-to-end functional behavior and ordering. They complement each other.

## What is functional coverage proving?

It shows whether planned scenarios actually occurred, such as all occupancy states, all request combinations, overflow/underflow attempts, simultaneous operations, and pointer wrap. It does not by itself prove correctness.

## What is the most important corner case?

Simultaneous push/pop near boundaries. Many FIFO bugs appear when the design reaches empty or full and both requests are asserted. The specification, RTL, scoreboard, assertions, and coverage must all agree on that policy.
