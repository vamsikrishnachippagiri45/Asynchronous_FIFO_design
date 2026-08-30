`timescale 1ns / 1ps

// Asynchronous FIFO Write Pointer and Full Flag
// Generates:
//   - Binary write pointer
//   - Gray-code write pointer
//   - Write address
//   - FIFO full flag
//
// ADDR_SIZE : Number of address bits
// FIFO depth = 2^ADDR_SIZE


module write_ptr_full #(
    parameter ADDR_SIZE = 4
)(
    output reg                  fifo_full,       // FIFO full flag
    output wire [ADDR_SIZE-1:0] write_addr,      // Write memory address
    output reg  [ADDR_SIZE:0]   write_ptr_gray,  // Write pointer in Gray code

    input wire [ADDR_SIZE:0]    read_ptr_gray_sync, // Synchronized read pointer
    input wire                  write_req,           // Write request
    input wire                  write_clk,
    input wire                  write_rst_n
);

    reg [ADDR_SIZE:0] write_ptr_bin;

    wire [ADDR_SIZE:0] write_ptr_bin_next;
    wire [ADDR_SIZE:0] write_ptr_gray_next;
    wire               fifo_full_next;


    // Write pointer update
    always @(posedge write_clk or negedge write_rst_n) begin
        if (!write_rst_n) begin
            write_ptr_bin  <= 0;
            write_ptr_gray <= 0;
        end
        else begin
            write_ptr_bin  <= write_ptr_bin_next;
            write_ptr_gray <= write_ptr_gray_next;
        end
    end


    // Write address
    assign write_addr = write_ptr_bin[ADDR_SIZE-1:0];

  
    // Increment binary pointer only when   write_req = 1 and  FIFO is not full
    assign write_ptr_bin_next = write_ptr_bin + (write_req & ~fifo_full);
   
    // Binary-to-Gray conversion
    assign write_ptr_gray_next = (write_ptr_bin_next >> 1) ^ write_ptr_bin_next;


    // Full condition : FIFO becomes full when the next write Gray pointer equals the synchronized read pointer with its two MSBs inverted.
    assign fifo_full_next = (write_ptr_gray_next == {~read_ptr_gray_sync[ADDR_SIZE:ADDR_SIZE-1], read_ptr_gray_sync[ADDR_SIZE-2:0]});

    // Full flag update
    always @(posedge write_clk or negedge write_rst_n) begin
        if (!write_rst_n)
            fifo_full <= 1'b0;
        else
            fifo_full <= fifo_full_next;
    end

endmodule
