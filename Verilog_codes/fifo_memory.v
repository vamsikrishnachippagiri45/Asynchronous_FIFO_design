`timescale 1ns / 1ps

// Asynchronous FIFO Memory
// Stores FIFO data and provides:
//   - Write operation in the write clock domain
//   - Read operation using the read address
//
// DATA_SIZE : Width of each data word
// ADDR_SIZE : Number of address bits
// FIFO depth = 2^ADDR_SIZE


module fifo_memory #(
    parameter DATA_SIZE = 8,
    parameter ADDR_SIZE = 4
)(
    output wire [DATA_SIZE-1:0] read_data,    // Data read from FIFO

    input  wire [DATA_SIZE-1:0] write_data,  // Data to be written

    input  wire [ADDR_SIZE-1:0] write_addr,   // Write address
    input  wire [ADDR_SIZE-1:0] read_addr,    // Read address

    input  wire write_enable,                 // Write request
    input  wire fifo_full,                    // FIFO full flag
    input  wire write_clk                     // Write clock
);

    // FIFO depth = 2^ADDR_SIZE
    localparam DEPTH = (1 << ADDR_SIZE);

    // FIFO memory array
    reg [DATA_SIZE-1:0] memory [0:DEPTH-1];

    // Asynchronous read
    assign read_data = memory[read_addr];

    // Synchronous write
    always @(posedge write_clk) begin
        if (write_enable && !fifo_full)
            memory[write_addr] <= write_data;
    end

endmodule
