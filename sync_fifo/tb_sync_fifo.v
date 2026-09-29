// Edge test cases
// 1. wr_en high while full : Write is ignored, no change in any values in memory
// 2. rd_en high while empty : Read is ignored, rd_data holds previous value
// 3. wr_en and rd_en both high, FIFO not full, not empty
// 4. check that write succeeds, read ignored when both high, FIFO empty
// 5. Now check that read succeeds, write ignored when both high, FIFO full

`timescale 1ns/1ps

module tb();

parameter WIDTH = 8, DEPTH = 4;   // small depth makes wraparound quick

reg clk, rst, wr_en, rd_en;
reg [WIDTH-1:0] wr_data;

wire [WIDTH-1:0] rd_data;
wire full, empty;

initial clk = 0;
always #5 clk = ~clk;

initial begin
    #100000;
    $display("[%0t TIMEOUT]", $time);
    $finish;
end

sync_fifo #(.WIDTH(WIDTH), .DEPTH(DEPTH)) dut (
    .clk(clk), .rst(rst), .wr_en(wr_en), .rd_en(rd_en),
    .wr_data(wr_data), .rd_data(rd_data),
    .full(full), .empty(empty)
);

task write (input [WIDTH-1:0] data);
    begin
        @(negedge clk);
        wr_en = 1;
        wr_data = data;
        @(negedge clk);
        wr_en = 0;
        wr_data = 0;      // Bad write check  
    end
endtask

task read (input [WIDTH-1:0] expected_read);
    begin
        @(negedge clk);
        rd_en = 1;
        $display("rd_ptr location=%1h", dut.rd_ptr[dut.ptr_size-1:0]);
        @(negedge clk);
        rd_en = 0;
        @(posedge clk);
        if (rd_data != expected_read) begin
            $display("FAIL: Actual read data is different from expected read data!");
            $finish;
        end       
        $display("data read=%2h", dut.rd_data);
    end
endtask

task write_and_read(input [WIDTH-1:0] data);
    begin
        @(negedge clk);
        rd_en = 1;
        wr_en = 1;
        wr_data = data;
        $display("rd_ptr location=%1h, wr_ptr location=%1h", dut.rd_ptr[dut.ptr_size-1:0], dut.wr_ptr[dut.ptr_size-1:0]);
        @(negedge clk);
        rd_en = 0;
        wr_en = 0;
        $display("rd_ptr location=%1h, wr_ptr location=%1h", dut.rd_ptr[dut.ptr_size-1:0], dut.wr_ptr[dut.ptr_size-1:0]);
        $display("mem[0] = %2h, mem[1]=%2h, data read=%2h", dut.mem[0], dut.mem[1], rd_data);

    end
endtask

always @(posedge clk) begin
    if (full && empty) begin
        $display("FAIL: FULL AND EMPTY ARE HIGH!!!!");
        $finish;
    end
end

initial begin
        $dumpfile("fifo.vcd"); 
        $dumpvars(0, tb);

        rst = 1; 
        wr_en = 0; 
        rd_en = 0; 
        
        wr_data = 0;
        repeat (3) @(posedge clk);
        @(negedge clk); 
        rst = 0;
        // Check that FIFO is empty after reset
        $display("Status of FIFO: full = %1h, empty = %1h", full, empty);
        // Write until FIFO is full
        write(8'h33);
        write(8'h67);
        write(8'ha4);
        write(8'haF);

        for (integer i = 0; i < DEPTH; i = i + 1)
            $display("mem[%2h]=%2h", i, dut.mem[i]);

        // Now check that FIFO stops writing when full, check dut.mem[0] as there is a wraparound (case 1)
        write(8'h6f);

        $display("Check for overwrite to full FIFO: mem[0]=%2h, wr_ptr=%2h", dut.mem[0], dut.wr_ptr[dut.ptr_size-1:0]);

        if (dut.mem[0] == 8'h6f) begin
            $display("Failed: Wrote onto full buffer");
            $finish;
        end

        $display("Successful: No writing to full FIFO");
        $display("Status of FIFO: full = %1h, empty = %1h", full, empty);
        
        // Now check that FIFO is reading properly
        read(8'h33);
        read(8'h67);
        read(8'ha4);
        read(8'haF);
        $display("Status of FIFO: full = %1h, empty = %1h", full, empty);

        // Now check that FIFO does not read from an empty fifo (case 2)
        read(8'haF);  // Data read should be previous data read.


        // Now check that both write and read happens when not empty and not full (case 3)
        $display("rd_ptr location=%1h, wr_ptr location=%1h", dut.rd_ptr[dut.ptr_size-1:0], dut.wr_ptr[dut.ptr_size-1:0]);
        write(8'h54);   // Located at mem[0]
        write_and_read(8'hb4);   // Check that reading from mem[0] while writing to mem[1]

        if (dut.rd_data != 8'h54) begin
            $display("FAIL: Actual read data is different from expected read data!");
            $finish;
        end

        if (dut.mem[1] != 8'hb4) begin
            $display("FAIL: Data is not written properly");
            $finish;
        end


        // Now check that write succeeds, read ignored when both high, FIFO empty (case 4)
        @(negedge clk);
        rst = 1;
        repeat (3) @(posedge clk);
        @(negedge clk);
        rst = 0;
        write_and_read(8'h3a);

        if (dut.rd_data != 8'h00) begin
            $display("FAIL: Actual read data is different from expected read data!");
            $finish;
        end

        if (dut.mem[0] != 8'h3a) begin
            $display("FAIL: Data is not written properly");
            $finish;
        end


        // Now check that read succeeds, write ignored when both high, FIFO full (case 5)
        @(negedge clk);
        rst = 1;
        repeat (3) @(posedge clk);
        @(negedge clk);
        rst = 0;
        write(8'h33);
        write(8'h67);
        write(8'ha4);
        write(8'haF);

        write_and_read(8'he4);   // Should read mem[0] == 8'h33 in this case

        if (dut.rd_data != 8'h33) begin
            $display("FAIL: Actual data read is different from expected read data!");
            $finish;
        end

        for (integer i = 0; i < DEPTH; i = i + 1) begin
            $display("mem[%2h]=%2h", i, dut.mem[i]);  // Check that no output is overwritten
            if (dut.mem[i] == 8'he4) begin
                $display("FAIL: Overwritten to a full FIFO!");
                $finish;
            end
        end


        $display("ALL TEST CASES PASSED!!!");
        $finish;

end


endmodule