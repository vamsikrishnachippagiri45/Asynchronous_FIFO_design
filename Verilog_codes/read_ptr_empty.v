`timescale 1ns / 1ps

// Asynchronous FIFO Read Pointer and Empty Flag
// Generates:
//   - Binary read pointer
//   - Gray-code read pointer
//   - Read address
//   - FIFO empty flag
//
// ADDR_SIZE : Number of address bits
// FIFO depth = 2^ADDR_SIZE


module read_ptr_empty #(
    parameter ADDR_SIZE = 4
)(
    output reg                  fifo_empty,      // FIFO empty flag
    output wire [ADDR_SIZE-1:0] read_addr,       // Read memory address
    output reg  [ADDR_SIZE:0]   read_ptr_gray,   // Read pointer in Gray code

    input wire [ADDR_SIZE:0]    write_ptr_gray_sync, // Synchronized write pointer
    input wire                  read_req,             // Read request
    input wire                  read_clk,
    input wire                  read_rst_n
);

    reg [ADDR_SIZE:0] read_ptr_bin;

    wire [ADDR_SIZE:0] read_ptr_bin_next;
    wire [ADDR_SIZE:0] read_ptr_gray_next;
    wire               fifo_empty_next;


    // Read pointer update
    always @(posedge read_clk or negedge read_rst_n) begin
        if (!read_rst_n) begin
            read_ptr_bin  <= 0;
            read_ptr_gray <= 0;
        end
        else begin
            read_ptr_bin  <= read_ptr_bin_next;
            read_ptr_gray <= read_ptr_gray_next;
        end
    end

   
    // Read address
    assign read_addr = read_ptr_bin[ADDR_SIZE-1:0];

  
    // Increment binary pointer only when: read_req = 1 and  FIFO is not empty
    assign read_ptr_bin_next = read_ptr_bin + (read_req & ~fifo_empty);


    // Binary-to-Gray conversion
    assign read_ptr_gray_next = (read_ptr_bin_next >> 1) ^ read_ptr_bin_next;

  
    // Empty condition : FIFO is empty when the next read pointer equals the synchronized write pointer.
    assign fifo_empty_next = (read_ptr_gray_next == write_ptr_gray_sync);

  
    // Empty flag update
    always @(posedge read_clk or negedge read_rst_n) begin
        if (!read_rst_n)
            fifo_empty <= 1'b1;
        else
            fifo_empty <= fifo_empty_next;
    end

endmodule
