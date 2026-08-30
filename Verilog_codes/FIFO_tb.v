`timescale 1ns / 1ps

module FIFO_tb;

    parameter DATA_SIZE = 8;
    parameter ADDR_SIZE = 3;
    parameter DEPTH = 1 << ADDR_SIZE;

    reg  [DATA_SIZE-1:0] write_data;
    wire [DATA_SIZE-1:0] read_data;

    reg write_req, read_req;
    reg write_clk, read_clk;
    reg write_rst_n, read_rst_n;

    wire fifo_full, fifo_empty;

    integer i;


   FIFO #(
        .DATA_SIZE(DATA_SIZE),
        .ADDR_SIZE(ADDR_SIZE)
    ) dut (
        .write_data  (write_data),
        .write_req   (write_req),
        .write_clk   (write_clk),
        .write_rst_n (write_rst_n),
        .fifo_full   (fifo_full),

        .read_data   (read_data),
        .read_req    (read_req),
        .read_clk    (read_clk),
        .read_rst_n  (read_rst_n),
        .fifo_empty  (fifo_empty)
    );


    always #5 write_clk = ~write_clk;
    always #8 read_clk  = ~read_clk;

    initial begin

        write_clk  = 0;
        read_clk   = 0;

        write_rst_n = 0;
        read_rst_n  = 0;

        write_req  = 0;
        read_req   = 0;
        write_data = 0;

        // Reset
        #30;
        write_rst_n = 1;
        read_rst_n  = 1;

        // Write data
        for (i = 0; i < DEPTH; i = i + 1) begin
            @(negedge write_clk);
            write_data = i;
            write_req  = 1;
        end

        @(negedge write_clk);
        write_req = 0;

        // Try writing when FIFO is full
        @(negedge write_clk);
        write_data = 8'hFF;
        write_req  = 1;

        #30;
        write_req = 0;


    
        // Read data
        for (i = 0; i < DEPTH; i = i + 1) begin
            @(negedge read_clk);
            read_req = 1;

            @(posedge read_clk);
            #1;

            $display("Read data = %h", read_data);
        end

        read_req = 0;

        // Try reading when FIFO is empty
        #30;
        read_req = 1;

        #30;

        read_req = 0;

        $finish;

    end

endmodule
