# Waveform Debug Guide

I use this checklist when inspecting `sync_fifo.vcd` in GTKWave, Surfer, EPWave, or another viewer.

I arrange the interface signals in this order:

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

When the simulator exposes internal DUT signals, I also add:

```text
dut.push_accept
dut.pop_accept
dut.wptr
dut.rptr
```

## Reset

At a rising edge where `rst_n=0`, the logical state resets. I expect the following state after the edge:

```text
count = 0
empty = 1
full  = 0
dout  = 0
```

Because reset is synchronous, changing `rst_n` between edges does not immediately reset the FIFO.

## Normal push

Before edge:

```text
push=1
full=0
```

After edge:

```text
count increases by 1
new din is stored at the write pointer
```

`dout` does not change unless a pop was also accepted.

## Normal pop

Before edge:

```text
pop=1
empty=0
```

After edge:

```text
count decreases by 1
dout becomes the oldest queued item
```

## Both in the middle

Before edge:

```text
0 < count < DEPTH
push=1
pop=1
```

After edge:

```text
count unchanged
dout = old queue head
new din appended to queue tail
```

I include this scenario when explaining simultaneous FIFO operations.

## Push while full

Before edge:

```text
full=1
push=1
pop=0
```

After edge:

```text
count remains DEPTH
write pointer does not advance
```

## Pop while empty

Before edge:

```text
empty=1
pop=1
push=0
```

After edge:

```text
count remains 0
read pointer does not advance
dout holds its old value
```

## Both while empty

Project policy:

```text
push accepted
pop rejected
count: 0 -> 1
```

## Both while full

Project policy:

```text
pop accepted
push rejected
count: DEPTH -> DEPTH-1
```

## Pointer wrap

With `DEPTH=8`, after an accepted operation at pointer 7, the corresponding pointer returns to 0. The scoreboard verifies that data order remains correct across this wrap.

## What a good screenshot should show

For my project presentation, I use focused waveform views to explain the following scenarios:

1. reset + first push;
2. FIFO reaching full + blocked overflow;
3. FIFO reaching empty + blocked underflow;
4. simultaneous push/pop in a middle state;
5. both-at-empty and both-at-full boundary policy;
6. console ending with zero failures and coverage report.
