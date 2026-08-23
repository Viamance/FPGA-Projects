# UART Transceiver on the Basys 3

A full-duplex UART link written from scratch in Verilog for the Digilent Basys 3 (Xilinx Artix-7 `XC7A35T`).

Type a key in a serial terminal and the FPGA receives the byte and shows it as two hex digits on the seven-segment display. Press the **up button** on the board and it transmits that byte back to the terminal.

**Frame format:** 115200 baud · 8 data bits · odd parity · 1 stop bit · no flow control

---

## How it works

**Receive.** The RX line is asynchronous to the 100 MHz clock, so it first passes through a two-flop synchroniser to avoid metastability. The FSM (`IDLE → START → DATA → PARITY → STOP → END`) arms on the falling edge of the start bit, waits half a bit period, then samples every `CLKS_PER_BIT` cycles — placing each sample mid-bit for maximum timing margin. Parity and stop bit are checked; a bad frame is flagged, discarded, and the FSM returns to `IDLE` ready for the next one.

**Transmit.** Pressing the up button drives a start bit, shifts out eight data bits LSB-first, appends generated odd parity, and returns to idle through the stop bit.

**Display.** The received byte is split into nibbles and multiplexed across the seven-segment digits as hexadecimal.

`CLKS_PER_BIT = 100_000_000 / 115_200 ≈ 868` is a parameter, so changing baud rate needs no FSM changes.

---

## Hardware setup

1. Connect the Basys 3 over USB and program the bitstream from Vivado.
2. Open a serial terminal on the board's COM port at **115200, 8 data bits, odd parity, 1 stop bit, no flow control**.
3. Type a character — its hex value appears on the display.
4. Press the up button — the byte is sent back to the terminal.

Parity must be set to **odd**. Leaving it at None was the cause of the one hardware bring-up bug: only bytes with even popcount displayed, which pointed at a parity mismatch rather than an RTL fault.

---

## Verification

- Directed tests on clean frames
- Negative tests for corrupted parity and invalid stop bits, confirming the FSM flags the error and still receives the next good frame
- Exhaustive 256-byte TX→RX loopback covering every data pattern

All testbenches are self-checking and report pass/fail per case.

```bash
iverilog -o sim.out tb_loopback.v uart_tx.v uart_rx.v
vvp sim.out
```

---

## Files

`uart_rx.v` · `uart_tx.v` · `seg7.v` · `top.v` · `tb_uart_rx.v` · `tb_loopback.v`

## Next

Configurable baud rate via board switches · RX FIFO

---

Verilog · Icarus Verilog · GTKWave · Vivado · Basys 3
