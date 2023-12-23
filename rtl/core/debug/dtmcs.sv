`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 05.11.2023 21:13:51
// Design Name:
// Module Name: dtmcs
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

module dtmcs
(
    input i_tck,
    input i_capture,
    input i_shift,
    input i_update,
    input i_tdi,
    output reg o_tdo,

    input [1:0] i_dmi_op,
    output reg  o_dtm_reset,
    output reg  o_dtm_clear_sticky
);

reg [31:0] tapShiftReg;

initial begin
    o_dtm_reset = 1'b0;
    o_dtm_clear_sticky = 1'b0;
end

always @(posedge i_tck) begin
    o_dtm_reset <= 1'b0;
    o_dtm_clear_sticky <= 1'b0;

    if(i_capture) begin
        tapShiftReg <= {20'h0, i_dmi_op, 10'h71};
    end
    else if(i_shift) begin
        tapShiftReg[30:0] <= tapShiftReg[31:1];
        tapShiftReg[31] <= i_tdi;
    end
    else if(i_update) begin
        if(tapShiftReg[17]) o_dtm_reset <= 1'b1;
        if(tapShiftReg[16]) o_dtm_clear_sticky <= 1'b1;
    end
end

always @(negedge i_tck) begin
    o_tdo <= tapShiftReg[0];
end

endmodule