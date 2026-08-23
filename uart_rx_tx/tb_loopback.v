// Feed data into tx, tx then transmits data which is received by rx.


`timescale 1ns/1ps

module tb_loopback();

    localparam CLKS_PER_BIT = 8;

    reg clk, rst;
    reg [7:0] tx_byte;
    reg tx_start;

    wire tx_rx;                          // Send data from tx to rx
    wire tx_active, tx_done;
    wire [7:0] rx_byte;
    wire rx_done, parity_ok, frame_ok;

    uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) transmitter (
        .clk(clk),
        .rst(rst),
        .tx_start(tx_start),
        .tx_byte(tx_byte),
        .tx_bit(tx_rx),
        .tx_active(tx_active),
        .tx_done(tx_done)
    );

    uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) receiver (
        .clk(clk), 
        .rst(rst), 
        .rx(tx_rx),
        .rx_byte(rx_byte), 
        .rx_done(rx_done),
        .parity_ok(parity_ok), 
        .frame_ok(frame_ok)
    );

    task send_byte (input [7:0] data);
        begin
            @(negedge clk);
            tx_start = 1'b1;
            tx_byte = data;
            @(negedge clk);
            tx_start = 1'b0;

            wait (rx_done);

            @(negedge clk);

            if (rx_byte !== data) begin                               
                $display("[%0t] FAIL: sent %02h, received %02h",
                         $time, data, rx_byte);
            end
            else if (!parity_ok || !frame_ok) begin
                $display("[%0t] FAIL %02h: parity_ok=%b frame_ok=%b",
                         $time, data, parity_ok, frame_ok);
            end else begin
                $display("[%0t] PASS: data: %02h = rx_byte: %02h", $time, data, rx_byte);
            end

            wait (!tx_active);          // let the transmitter finish and go back to idle
        end
    endtask

    task idle(input integer bits);
        begin
            repeat (bits*CLKS_PER_BIT) @(posedge clk);
        end
    endtask

    initial clk = 0;
    always #5 clk = ~clk;


    initial begin
        $dumpfile("loopback.vcd");
        $dumpvars(0, tb_loopback);


        tx_start = 1'b0;
        tx_byte = 8'h00;
        rst = 1;

        repeat (3) @(posedge clk);
        @(negedge clk);
        rst = 0;

        idle(2);
        send_byte(8'h91);
        idle(2);
        send_byte(8'hc9);
        idle(2);
        send_byte(8'h33);
        idle(2);
        send_byte(8'hff);
        idle(2);

        $finish;
    end



    initial begin                       // watchdog
        #500000;
        $display("[%0t] TIMEOUT", $time);
        $finish;
    end

endmodule