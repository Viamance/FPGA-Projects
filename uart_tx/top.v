module top(
    input clk,
    input btnC,   // Reset
    input btnU,   // Start transmit
    input RsRx,   // Data from PC to receiver (Basys 3)
    output RsTx, // Data from transmitter (Basys 3) to PC 
    output dp,
    output [6:0] seg,
    output [3:0] an
);

    wire [7:0] rx_byte;
    wire rx_done, parity_ok, frame_ok;
    reg  [7:0] display_byte;

    uart_rx #(.CLKS_PER_BIT(868)) receive (
        .clk(clk), .rst(btnC), .rx(RsRx),
        .rx_byte(rx_byte), .rx_done(rx_done),
        .parity_ok(parity_ok), .frame_ok(frame_ok)
    );

    uart_tx #(.CLKS_PER_BIT(868)) transmitter (
        .clk(clk),
        .rst(btnC),
        .tx_start(btnU),
        .tx_byte(rx_byte),
        .tx_bit(RsTx),
        .tx_active(tx_active),
        .tx_done(tx_done)
    );

    always @(posedge clk) begin
        if (btnC) begin
            display_byte <= 8'h00;             
        end
        else if (rx_done) begin
            display_byte <= rx_byte;            // Hold current byte until next byte comes
        end
    end

    seg7 display (
        .clk(clk), .rst(btnC), .value(display_byte),
        .seg(seg), .an(an)
    );

    assign dp = 1'b1;

endmodule