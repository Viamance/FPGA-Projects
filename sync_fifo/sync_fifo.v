module sync_fifo #(
    parameter WIDTH = 8,          // Size of each element, 8 bits in this case.
    parameter DEPTH = 16          // Number of elements, 16 in this case, each having 8 bits. Assume a power of two for depth.
)(
    input clk,
    input rst,

    input wr_en,
    input [WIDTH-1:0] wr_data,

    input rd_en,
    output reg [WIDTH-1:0] rd_data,

    output full,
    output empty,
);
    localparam ptr_size = $clog2(DEPTH);

    reg [ptr_size:0] wr_ptr;     // Select which element in the space to write, additional bit for overflow
    reg [ptr_size:0] rd_ptr;     // Select which element in the space to read. additional bit for overflow
    reg [WIDTH-1:0] mem [0:DEPTH-1];

    always @(posedge clk) begin         // Write Sequence
        if (rst) begin
            wr_ptr <= 0;
        end
        else if (wr_en & !full) begin
            mem[wr_ptr[ptr_size-1:0]] <= wr_data;
            wr_ptr++;
        end
    end   

    always @(posedge clk) begin         // Read Sequence
        if (rst) begin
            rd_ptr <= 0;
        end
        else if (rd_en & !empty) begin
            rd_data <= mem[rd_ptr[ptr_size-1:0]];
            rd_ptr++;
        end
    end

    assign empty = (wr_ptr == rd_ptr);
    assign full = ((wr_ptr[ptr_size] != rd_ptr[ptr_size]) && (wr_ptr[ptr_size-1:0] == rd_ptr[ptr_size-1:0]) )

endmodule