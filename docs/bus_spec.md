# Bus Spec

## Request Signals (master to SoC)

- `req_valid`: master is making a request
- `req_ready`: SoC can accept
- `req_addr[63:0]`: address
- `req_is_write`: 1 = write, 0 = read
- `req_wdata[63:0]`: write data
- `req_wstrb[7:0]`: which bytes are written (byte enables)

## Reponse signals (SoC to master)

- `resp_valid`: response is ready
- `resp_ready`: master can accept
- `resp_rdata[63:0]`: read data
- `resp_err`: error indicator

Instruction fetch behavior: 64-bit aligned read + halfway select
