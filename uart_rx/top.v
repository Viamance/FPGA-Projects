module top(
    input  clk,
    input  btnC,   // Reset
    input  RsRx,
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