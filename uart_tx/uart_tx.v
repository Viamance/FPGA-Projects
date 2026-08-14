module uart_tx(
    input clk,
    input rst,
    input tx_start,
    input [7:0] tx_byte,
    output reg tx_bit,
    output reg tx_active,
    output reg tx_done
);

localparam IDLE=0, START=1, DATA=2, PARITY=3, STOP=4, END=5;
parameter CLKS_PER_BIT = 868;  //     100 000 000 (100 Mhz of basys 3) / 115 200 (baud rate)  = 868, hence we see each bit for 868 cycles.

reg [9:0] clk_count;    // needs to reach 867 -> 10 bits
reg [3:0] bit_ctr;    // to assign correct bit of tx_byte to tx_start
reg [2:0] state;
reg [7:0] tx_data;    // Capture input data

always @(posedge clk) begin
    if (rst) begin
        state <= IDLE;
        clk_count <= 0;
        bit_ctr <= 0;
        tx_active <= 0;
        tx_done <= 0;
        tx_bit <= 1;
    end
    else begin
        case (state)
            IDLE: begin
                tx_done <= 0;
                tx_active <= 0;
                bit_ctr <= 0;
                clk_count <= 0;
                if (tx_start) begin
                    state <= START;
                    tx_active <= 1;
                    tx_data <= tx_byte;
                end
            end
            START: begin
                tx_bit <= 0;
                if (clk_count == CLKS_PER_BIT-1) begin
                    state <= DATA;
                    clk_count <= 0;
                end
                else begin
                    clk_count <= clk_count + 1;
                end
            end
            DATA: begin
                if (bit_ctr < 8) begin
                    tx_bit <= tx_data[bit_ctr];
                end
                if (clk_count == CLKS_PER_BIT-1) begin
                    if (bit_ctr < 8) begin
                        clk_count <= 0;
                        bit_ctr <= bit_ctr + 1;
                    end
                    else begin
                        clk_count <= 0;
                        bit_ctr <= 0;
                        state <= PARITY;
                    end
                end
                else begin
                    clk_count <= clk_count + 1;
                end
            end
            PARITY: begin
                tx_bit <= ~^tx_data;
                if (clk_count == CLKS_PER_BIT-1) begin
                    clk_count <= 0;
                    state <= STOP;
                end
                else begin
                    clk_count <= clk_count + 1;
                end
            end
            STOP: begin
                tx_bit <= 1;
                if (clk_count == CLKS_PER_BIT-1) begin
                    clk_count <= 0;
                    state <= END;
                end
                else begin
                    clk_count <= clk_count + 1;
                end
            end
            END: begin
                tx_done <= 1;
                state <= IDLE;
            end
        endcase
    end
end

endmodule