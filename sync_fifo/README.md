# Synchronous FIFO

A parameterisable synchronous FIFO in Verilog, with `full` and `empty` derived
purely from the read and write pointers (no occupancy counter). Verified with a
directed, self-checking testbench in Icarus Verilog.

## Interface

```verilog
module sync_fifo #(
    parameter WIDTH = 8,     // bits per entry
    parameter DEPTH = 16     // number of entries, must be a power of two
)(
    input                  clk,
    input                  rst,      // synchronous, active high
    input                  wr_en,
    input      [WIDTH-1:0] wr_data,
    input                  rd_en,
    output reg [WIDTH-1:0] rd_data,
    output                 full,
    output                 empty
);
```

| Signal    | Direction | Description |
|-----------|-----------|-------------|
| `clk`     | in  | Single clock shared by both sides |
| `rst`     | in  | Synchronous reset, active high. Clears both pointers and `rd_data` |
| `wr_en`   | in  | Write request. Accepted on a rising edge when the FIFO is not full |
| `wr_data` | in  | Data to write |
| `rd_en`   | in  | Read request. Accepted on a rising edge when the FIFO is not empty |
| `rd_data` | out | Oldest entry, registered (valid the cycle after the read) |
| `full`    | out | High when all `DEPTH` entries are occupied |
| `empty`   | out | High when no entries are occupied |

## How it works

The memory is used as a circular buffer: a write pointer and a read pointer each
advance by one on an accepted operation and wrap back to 0 after the last slot.

When the FIFO is completely empty and when it is completely full, both pointers
index the same memory slot, so comparing addresses alone cannot tell the two
states apart. Each pointer is therefore one bit wider than the address it needs.
The low bits index memory; the extra top bit flips every time that pointer wraps.

```
empty = (wr_ptr == rd_ptr)                              // same slot, same lap
full  = (wr_ptr[MSB] != rd_ptr[MSB]) &&
        (wr_ptr[MSB-1:0] == rd_ptr[MSB-1:0])            // same slot, one lap apart
```

This is the same technique used in asynchronous (clock-domain-crossing) FIFOs,
where the two sides cannot share an occupancy counter.

## Behaviour

| Situation | Behaviour |
|-----------|-----------|
| Reset | `empty = 1`, `full = 0`, `rd_data = 0`. Memory contents are not cleared |
| Write while not full | Data stored at the write pointer, pointer advances |
| Write while full | Ignored. Memory and write pointer unchanged |
| Read while not empty | Oldest entry appears on `rd_data` the following cycle, pointer advances |
| Read while empty | Ignored. `rd_data` holds its previous value |
| Read + write, neither full nor empty | Both happen |
| Read + write while empty | Write accepted, read ignored |
| Read + write while full | Read accepted, **write dropped** (flags are evaluated from the pre-edge pointers) |
| `full` and `empty` together | Never occurs |

**Read latency:** one cycle. `rd_data` is registered, so the value appears after
the rising edge that accepted the read.

## Files

| File | Contents |
|------|----------|
| `sync_fifo.v` | The FIFO |
| `tb_sync_fifo.v` | Directed self-checking testbench |

## Running the testbench

The testbench uses an inline loop-variable declaration (`for (integer i = ...)`),
so compile with SystemVerilog-2012 support enabled:

```
iverilog -g2012 -o fifo_sim sync_fifo.v tb_sync_fifo.v
vvp fifo_sim
gtkwave fifo.vcd
```

The testbench stops at the first failure with a `FAIL:` message.

## Verification

The testbench runs at `WIDTH = 8`, `DEPTH = 4` so wraparound is reached quickly,
and checks results against the DUT's internal state (`dut.mem`, `dut.rd_data`)
rather than the stimulus it drove.

| # | Test | Check |
|---|------|-------|
| — | Fill and drain | Four entries read back in the order written |
| 1 | Write while full | Rejected write does not appear in memory |
| 2 | Read while empty | `rd_data` holds the last value read |
| 3 | Read + write, partially full | Read returns the oldest entry; write lands in the next slot |
| 4 | Read + write while empty | Read ignored (`rd_data` stays 0); write accepted |
| 5 | Read + write while full | Read returns the oldest entry; write rejected |

A continuous assertion checks every cycle that `full` and `empty` are never high
at the same time.

## Limitations and next steps

- `DEPTH` must be a power of two, so the pointers wrap for free on overflow.
- Single clock only. An asynchronous version would need Gray-coded pointers
  synchronised across the clock domains.
- Verification is directed only. Planned next: a behavioural reference model
  driven by randomised `wr_en`/`rd_en` for several thousand cycles, to exercise
  wraparound coinciding with simultaneous reads and writes.
