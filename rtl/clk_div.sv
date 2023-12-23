`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 13.11.2023 20:55:11
// Design Name:
// Module Name: top
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module clk_div
#(
    parameter CLK_DIV = 2
)
(
    input i_clk,

    output reg o_clk
);

reg [$clog2(CLK_DIV)-1:0] counter;

initial begin
    counter = 0;
end

always @(posedge i_clk) begin
    counter <= counter + 1;
    if(counter >= (CLK_DIV - 1))
        counter <= 0;
    o_clk <= (counter < (CLK_DIV / 2)) ? 1'b0 : 1'b1;
end

endmodule