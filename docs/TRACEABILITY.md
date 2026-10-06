# Requirement-to-Verification Traceability

| Requirement | RTL implementation | Verification |
|---|---|---|
| Same clock for read/write | single `always_ff @(posedge clk)` | all tests use common `clk` |
| Write only when space exists | `push_accept = push && !full` | FIFO-D07/D08 + scoreboard + assertion |
| Read only when data exists | `pop_accept = pop && !empty` | FIFO-D03/D09 + scoreboard + assertion |
| Empty when occupancy is 0 | `empty = (count == 0)` | scoreboard + `ap_empty_matches_count` |
| Full when occupancy is DEPTH | `full = (count == DEPTH)` | scoreboard + `ap_full_matches_count` |
| FIFO ordering | memory + independent r/w pointers | FIFO-D05/D06/D13/D14 + scoreboard |
| Registered output | `dout` updated on accepted pop | scoreboard + `ap_dout_holds_without_pop` |
| Push-only increments | count case logic | directed/random + `ap_push_only_increments` |
| Pop-only decrements | count case logic | directed/random + `ap_pop_only_decrements` |
| Both in middle keeps count | count case default | FIFO-D10 + assertion |
| Both at empty = push only | accepts derived from pre-state | FIFO-D11 + assertion |
| Both at full = pop only | accepts derived from pre-state | FIFO-D12 + assertion |
| No overflow | full blocks write | FIFO-D08 + assertion + coverage |
| No underflow | empty blocks read | FIFO-D03 + assertion + coverage |
| Reset clears logical state | reset branch | FIFO-D01/D15 |
| Pointer wrap works | explicit `DEPTH-1 -> 0` | FIFO-D13/D14 + coverage |
