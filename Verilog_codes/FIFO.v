`timescale 1ns / 1ps


// Asynchronous FIFO
// Features:
//   - Independent write and read clocks
//   - Gray-coded write/read pointers
//   - 2-flop clock-domain synchronizers
//   - Full flag in write-clock domain
//   - Empty flag in read-clock domain
//
// DATA_SIZE : Width of FIFO data
// ADDR_SIZE : Number of address bits
//             FIFO depth = 2^ADDR_SIZE
//
// Example:
//   DATA_SIZE = 8
//   ADDR_SIZE = 4
//   FIFO width = 8 bits
//   FIFO depth = 16 words


module FIFO #(
    parameter DATA_SIZE = 8,
    parameter ADDR_SIZE = 4
)(
    
    // Write interface
    input  wire [DATA_SIZE-1:0] write_data,
    input  wire                 write_req,
    input  wire                 write_clk,
    input  wire                 write_rst_n,

    output wire                 fifo_full,

    // Read interface
    output wire [DATA_SIZE-1:0] read_data,
    input  wire                 read_req,
    input  wire                 read_clk,
    input  wire                 read_rst_n,

    output wire                 fifo_empty
);

    // Internal signals

    // Write pointer
    wire [ADDR_SIZE:0] write_ptr_gray;

    // Read pointer
    wire [ADDR_SIZE:0] read_ptr_gray;

    // Memory addresses
    wire [ADDR_SIZE-1:0] write_addr;
    wire [ADDR_SIZE-1:0] read_addr;

    // Synchronized pointers
    wire [ADDR_SIZE:0] read_ptr_gray_sync;
    wire [ADDR_SIZE:0] write_ptr_gray_sync;


    // 1. WRITE POINTER + FULL FLAG
    // Operates in write clock domain.
    // Uses synchronized read pointer to determine FULL.

    write_ptr_full #(
        .ADDR_SIZE(ADDR_SIZE)
    ) write_pointer_inst (
        .fifo_full          (fifo_full),
        .write_addr         (write_addr),
        .write_ptr_gray     (write_ptr_gray),

        .read_ptr_gray_sync (read_ptr_gray_sync),
        .write_req          (write_req),
        .write_clk          (write_clk),
        .write_rst_n        (write_rst_n)
    );


  
    // 2. READ POINTER + EMPTY FLAG
    // Operates in read clock domain.
    // Uses synchronized write pointer to determine EMPTY.

    read_ptr_empty #(
        .ADDR_SIZE(ADDR_SIZE)
    ) read_pointer_inst (
        .fifo_empty          (fifo_empty),
        .read_addr           (read_addr),
        .read_ptr_gray       (read_ptr_gray),

        .write_ptr_gray_sync (write_ptr_gray_sync),
        .read_req            (read_req),
        .read_clk            (read_clk),
        .read_rst_n          (read_rst_n)
    );


    // 3. READ POINTER SYNCHRONIZER
    // read_ptr_gray is generated in the READ clock domain.
    // It must be synchronized before being used in the WRITE clock domain.
   

    two_ff_sync #(
        .SIZE(ADDR_SIZE + 1)
    ) read_ptr_sync_inst (
        .sync_out (read_ptr_gray_sync),
        .async_in (read_ptr_gray),
        .clk      (write_clk),
        .rst_n    (write_rst_n)
    );


    // 4. WRITE POINTER SYNCHRONIZER
    // write_ptr_gray is generated in the WRITE clock domain.
    // It must be synchronized before being used in the READ clock domain.
   
    two_ff_sync #(
        .SIZE(ADDR_SIZE + 1)
    ) write_ptr_sync_inst (
        .sync_out (write_ptr_gray_sync),
        .async_in (write_ptr_gray),
        .clk      (read_clk),
        .rst_n    (read_rst_n)
    );


    
    // 5. FIFO MEMORY
    // Write occurs using write_clk.
    // Read is asynchronous using read_addr.

    fifo_memory #(
        .DATA_SIZE(DATA_SIZE),
        .ADDR_SIZE(ADDR_SIZE)
    ) memory_inst (
        .read_data   (read_data),
        .write_data  (write_data),

        .write_addr  (write_addr),
        .read_addr   (read_addr),

        .write_enable(write_req),
        .fifo_full   (fifo_full),
        .write_clk   (write_clk)
    );

endmodule
