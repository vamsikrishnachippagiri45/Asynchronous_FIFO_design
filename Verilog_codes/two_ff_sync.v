`timescale 1ns / 1ps
module two_ff_sync #(parameter SIZE = 4)(
    output reg [SIZE-1:0] sync_out,    // Output of the second synchronizer stage
    input      [SIZE-1:0] async_in,     // Asynchronous input data
    input                 clk,
    input                 rst_n
);

    reg [SIZE-1:0] sync_ff1;           // First synchronizer stage

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            begin 
                sync_out <= 0 ;
                sync_ff1<= 0;
            end 
        else
            begin 
                sync_out <= sync_ff1;
                sync_ff1 <= async_in;
            end
    end

endmodule
