module seg7(
    input clk,
    input rst,
    input [7:0] value,
    output reg [6:0] seg,      // segment cathodes, active on low
    output reg [3:0] an        // digit anodes, active on low
);

    reg [19:0] refresh_counter;   
    wire [1:0] digit_sel;    // choose which of 4 digits to light up

    always @(posedge clk) begin
        if (rst) begin
            refresh_counter <= 0;
        end
        else begin   
            refresh_counter <= refresh_counter + 1;
        end
    end

    assign digit_sel = refresh_counter[19:18];   // Cycles per selector value = 2^18 = 262,144. Time for each digit = 2.62 ms. Time per full pass 10.49ms.

    // Select which digit to light up
    always @(*) begin
        case (digit_sel)
            2'b00: begin 
                an = 4'b1110;
                case(value[3:0])
                    4'h0: seg = 7'b1000000; // 0
                    4'h1: seg = 7'b1111001; // 1
                    4'h2: seg = 7'b0100100; // 2
                    4'h3: seg = 7'b0110000; // 3
                    4'h4: seg = 7'b0011001; // 4
                    4'h5: seg = 7'b0010010; // 5
                    4'h6: seg = 7'b0000010; // 6
                    4'h7: seg = 7'b1111000; // 7
                    4'h8: seg = 7'b0000000; // 8
                    4'h9: seg = 7'b0010000; // 9
                    4'hA: seg = 7'b0001000; // A
                    4'hB: seg = 7'b0000011; // b
                    4'hC: seg = 7'b1000110; // C
                    4'hD: seg = 7'b0100001; // d
                    4'hE: seg = 7'b0000110; // E
                    4'hF: seg = 7'b0001110; // F
                    default: seg = 7'b1000000; // "0"
                endcase
            end

            2'b01: begin
                an = 4'b1101;
                    case(value[7:4])
                        4'h0: seg = 7'b1000000; // 0
                        4'h1: seg = 7'b1111001; // 1
                        4'h2: seg = 7'b0100100; // 2
                        4'h3: seg = 7'b0110000; // 3
                        4'h4: seg = 7'b0011001; // 4
                        4'h5: seg = 7'b0010010; // 5
                        4'h6: seg = 7'b0000010; // 6
                        4'h7: seg = 7'b1111000; // 7
                        4'h8: seg = 7'b0000000; // 8
                        4'h9: seg = 7'b0010000; // 9
                        4'hA: seg = 7'b0001000; // A
                        4'hB: seg = 7'b0000011; // b
                        4'hC: seg = 7'b1000110; // C
                        4'hD: seg = 7'b0100001; // d
                        4'hE: seg = 7'b0000110; // E
                        4'hF: seg = 7'b0001110; // F
                        default: seg = 7'b1000000; // "0"
                endcase
            end

            2'b10: begin
                an = 4'b1011;
                seg = 7'b1111111;
            end

            2'b11: begin
                an = 4'b0111;
                seg = 7'b1111111;
            end
            default: begin 
                an = 4'b1111; 
                seg = 7'b1111111;
            end
        endcase
    end

endmodule