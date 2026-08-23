Project Description:

Create a UART Receiver that receives a byte from the computer and displays it on the 7-Segment Displays. The UART receiver should operate at 115200 baud rate, 8 data bits, 1 odd parity, 1 stop bit, no flow control.

Specs:
- Displays two hexadecimal digits on 7-Segment Displays.
- Output digits only when stop + parity check are ok.
- If UART receiver does not see stop bit when intended, wait until stop bit is found before going back to IDLE state.

Notes: 
- My projects are done with the assumption of using the Digilent Basys 3 board. (100 Mhz clock)
- Baud rate of 115200 means that 115200 bits get sent per second.
