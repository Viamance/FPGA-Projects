module uart_rx(
    input clk,
    input rst, 
    input rx,
    output reg [7:0] rx_byte,
    output reg rx_done, parity_ok, frame_ok
);

localparam IDLE=0, START=1, DATA=2, PARITY=3, STOP=4, END=5;
parameter CLKS_PER_BIT = 868;  //     100 000 000 (100 Mhz of basys 3) / 115 200 (baud rate)  = 868, hence we see each bit for 868 cycles.

reg rx_meta;
reg rx_stable;

reg [9:0] clk_count;    // needs to reach 867 -> 10 bits
reg [2:0] bit_ctr;    // 0 to 7 -> 3 bits
reg [2:0] state;

always @(posedge clk) begin
    rx_meta <= rx;
    rx_stable <= rx_meta;      // stabilize the input signal to avoid metastability issues
end

always @(posedge clk) begin
    if (rst) begin
        state <= IDLE;
        clk_count <= 0;
        bit_ctr <= 0;
        rx_byte <= 8'b0;
        rx_done <= 1'b0;
        parity_ok <= 1'b0;
        frame_ok <= 1'b0;
    end
    else begin    
        case (state)
            IDLE: begin
                rx_done <= 1'b0;
                clk_count <= 0;
                bit_ctr <= 0;
                parity_ok <= 1'b0;
                frame_ok <= 1'b0;
                if (rx_stable == 1'b0) begin
                    state <= START;
                end
            end
            START: begin
                if (clk_count == (CLKS_PER_BIT-1)/2) begin  // Since we see each bit for 868 clock cycles, we go thru 434 cycles to check the middle of the input bit.
                    if (rx_stable == 1'b0) begin
                        clk_count <= 0;
                        state <= DATA;
                    end
                    else begin
                        state <= IDLE;
                    end
                end
                else begin
                    clk_count <= clk_count + 1;
                end
            end
            DATA: begin
                if (clk_count == CLKS_PER_BIT-1) begin  // Since previous sampling was at halfway point of start bit, we count 1 full bit cycle to reach the middle of bit 0.
                    rx_byte[bit_ctr] <= rx_stable;
                    if (bit_ctr < 7) begin
                        clk_count <= 0;
                        bit_ctr <= bit_ctr + 1;
                    end
                    else begin
                        clk_count <= 0;                    
                        state <= PARITY;
                    end
                end
                else begin
                    clk_count <= clk_count + 1;
                end
            end
            PARITY: begin
                if (clk_count == CLKS_PER_BIT-1) begin         // Parity bit ensures that 8 bit input + parity bit (Total 9 bits) is odd number of '1'. 
                    parity_ok <= (rx_stable == ~^rx_byte);     // Check that the arriving parity bit is correct, parity_ok is 1 if correct.
                    clk_count <= 0;
                    state <= STOP;
                end
                else begin
                    clk_count <= clk_count + 1;
                end
            end
            STOP: begin
                if (clk_count == CLKS_PER_BIT-1) begin      
                    if (rx_stable) begin                    // Check that stop bit is '1'.
                        frame_ok <= 1'b1;
                        clk_count <= 0;
                        state <= END;
                    end
                    else begin
                        state <= END;
                    end
                end
                else begin
                    clk_count <= clk_count + 1;
                end
            end
            END: begin
                rx_done <= parity_ok & frame_ok;
                if (rx_stable) begin                  // If stop bit is bad, wait until input is 1 before going back to idle to prevent possible triggering of start bit.
                    state <= IDLE;
                end                   
            end
        endcase
    end
end
          
endmodule