`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 05.11.2023 21:13:51
// Design Name:
// Module Name: tap_reg
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

module tap_reg
#(
    parameter REG_WIDTH,
    parameter INITIAL_VALUE = 0
)
(
    input i_tck,
    input i_capture,
    input i_shift,
    input i_update,
    input i_tdi,
    output reg o_tdo,
    input i_reset,

    output [REG_WIDTH-1:0] o_debug
);

reg [REG_WIDTH-1:0] tapReg;
reg [REG_WIDTH-1:0] tapShiftReg;

initial begin
    tapReg = INITIAL_VALUE;
end

generate
    if(REG_WIDTH > 1)
        always @(posedge i_tck) begin
            if(i_reset) tapReg <= INITIAL_VALUE;
            else if(i_capture) begin
                tapShiftReg <= tapReg;
            end
            else if(i_shift) begin
                    tapShiftReg[REG_WIDTH-2:0] <= tapShiftReg[REG_WIDTH-1:1];
                    tapShiftReg[REG_WIDTH-1] <= i_tdi;
            end
            else if(i_update) begin
                tapReg <= tapShiftReg;
            end
        end
    else
        always @(posedge i_tck) begin
            if(i_reset) tapReg <= INITIAL_VALUE;
            else if(i_capture) begin
                tapShiftReg <= tapReg;
            end
            else if(i_shift) begin
                    tapShiftReg[REG_WIDTH-1] <= i_tdi;
            end
            else if(i_update) begin
                tapReg <= tapShiftReg;
            end
        end
endgenerate

always @(negedge i_tck) begin
    o_tdo <= tapShiftReg[0];
end

assign o_debug = tapReg;

endmodule