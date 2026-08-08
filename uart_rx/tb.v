`timescale 1ns/1ps

module tb();

    localparam CLKS_PER_BIT = 8;

    reg clk, rst, rx;
    wire [7:0] rx_byte;
    wire rx_done, parity_ok, frame_ok;

    task idle(input integer bits);
        begin
            rx = 1'b1;
            repeat (bits*CLKS_PER_BIT) @(posedge clk);
        end
    endtask

    task send_bit(input b);
        begin
            rx = b;
            repeat (CLKS_PER_BIT) @(negedge clk);
        end
    endtask

    task send_byte (input [7:0] data, input stop);
        integer i;
        begin
            send_bit(1'b0);      // start bit
            for (i = 0; i < 8; i = i + 1)
                send_bit(data[i]);
            send_bit(~^data);    // odd parity, use ^data if want to corrupt parity bit.
            send_bit(stop);         // stop bit
        end
    endtask

    uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) dut (
        .clk(clk), .rst(rst), .rx(rx),
        .rx_byte(rx_byte), .rx_done(rx_done),
        .parity_ok(parity_ok), .frame_ok(frame_ok)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin                       // watchdog
        #100000;
        $display("[%0t] TIMEOUT", $time);
        $finish;
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb);

        rx = 1;
        rst = 1;

        repeat (3) @(posedge clk);   
        @(negedge clk);
        rst = 0;              

        idle(2);
        send_byte(8'hc9, 1'b0);
        idle(2);
        send_byte(8'h91, 1'b1);
        idle(2);
        send_byte(8'h33, 1'b1);
        idle(2);

        $finish;

    end

endmodule
        
