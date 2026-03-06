# Debug

Note: only sticky bugs (>30 minutes) logged

## MS 4

### Issue 1: Verilator `UNOPTFLAT` circular combinational logic on `top.req_ready`

#### Date

2026-02-26

#### Description

- Verilator reported `UNOPTFLAT` and exited because it detected a circular combinational dependency with `top.req_ready`
- Reported path showed the loop crossing modules:
  - `top.req_ready` -> `lsu` (combinational) -> `control_fsm` signals (combinational) -> `top.req_addr` -> `soc` address decode/`ram_sel` (combinational) -> `soc.req_ready` -> `top.req_ready
- Root cause:
  - `req_ready` was computed combinationally based on address decode (`ram_sel` depends on `req_addr`), while `req_addr` was computed based on logic that depended on `req_ready`

#### Fix

- Originally thought issue was in `lsu` or `control_fsm`
  - Changes did not solve warning, only moved the loop somewhere else
- Final fix:
  - Make `req_ready` depend only on RAM ability to accept request, not on address decode
    - Was: `assign req_ready = (!unmapped_resp_valid) && (ram_sel ? ram_req_ready : 1'b1);`
    - Now: `assign req_ready = (!unmapped_resp_valid) && ram_req_ready;`
  - Verilator no longer flagged `UNOPTFLAT`

### Issue 2: Sim timeout with PC/IR mismatch

#### Date

2026-02-27

#### Description

- Tests timed out instead of halting
- `pc` and `ir` showed different insturction encoding at the same times
  - Mapping `pc` via `objdump` showed `addi` while `ir` showed a branch
- Root cause:
  - `pc_q` and `ir_q` can be different in stage/cycles
  - `EBREAK` is never reached
- Found out later that `MAX_CYCLES` in `main.cpp` was set too low
  - Multi-cycle CPU means test program instructions expand into far more cycles than expected

#### Fix

- Initially tried many prints to find issue
  - Preiodic prints showed PC advancement, core was not stuck
  - RAM prints show program loaded currently
- Tested a shorter program
  - It worked
- Final fix:
  - Remembered my `MAX_CYCLES` in `main.cpp` was only at 500
  - Increased it from 500 to 50000
  - Program halts normally now with correct behavior
