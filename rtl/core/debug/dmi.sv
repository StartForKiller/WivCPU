`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 05.11.2023 21:13:51
// Design Name:
// Module Name: dmi
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

module dmi
(
    input i_tck,
    input i_capture,
    input i_shift,
    input i_update,
    input i_tdi,
    output reg o_tdo,

    input i_reset,
    input i_clear_sticky,

    //DMI-DM Bus
    output reg    o_dmi_req_valid,
    input         i_dmi_req_ready,
    output [6:0]  o_dmi_req_address,
    output [31:0] o_dmi_req_data,
    output [1:0]  o_dmi_req_op,
    input         i_dmi_rsp_valid,
    output reg    o_dmi_rsp_ready,
    input  [31:0] i_dmi_rsp_data,
    input  [1:0]  i_dmi_rsp_op
);

reg [40:0] tapReg;
reg [40:0] tapShiftReg;

assign o_dmi_req_address = tapReg[40:34];
assign o_dmi_req_data    = tapReg[33:2];
assign o_dmi_req_op      = tapReg[1:0];

reg sticky;

initial begin
    tapReg = 41'h0;
    sticky = 1'b0;
    o_dmi_req_valid = 1'b0;
    o_dmi_rsp_ready = 1'b0;
end

always @(posedge i_tck) begin
    if(i_reset) begin
        tapReg <= 41'h0;
        sticky <= 1'b0;
        o_dmi_req_valid <= 1'b0;
        o_dmi_rsp_ready <= 1'b0;
    end
    else if(i_clear_sticky) begin
        sticky <= 1'b0;
    end
    else if(i_capture) begin
        if(!o_dmi_req_valid) begin
            tapShiftReg <= tapReg;
        end
        else if(i_dmi_rsp_valid && !sticky) begin
            tapReg <= {tapReg[40:34], i_dmi_rsp_data, i_dmi_rsp_op};
            tapShiftReg <= {tapReg[40:34], i_dmi_rsp_data, i_dmi_rsp_op};
            if(i_dmi_rsp_op == 2'h2)
                sticky <= 1'b1;
        end else begin
            tapReg <= {tapReg[40:2], 2'h3};
            tapShiftReg <= {tapReg[40:2], 2'h3};
            sticky <= 1'b1;
        end

        o_dmi_req_valid <= 1'b0;
        o_dmi_rsp_ready <= 1'b0;
    end
    else if(i_shift) begin
            tapShiftReg[39:0] <= tapShiftReg[40:1];
            tapShiftReg[40] <= i_tdi;
    end
    else if(i_update) begin
        if(!sticky) begin
            if(!i_dmi_req_ready) begin
                tapReg <= {tapShiftReg[40:2], 2'h3};
                sticky <= 1'b1;
            end else if(tapShiftReg[1:0] != 2'h0) begin
                tapReg <= tapShiftReg;
                o_dmi_req_valid <= 1'b1;
                o_dmi_rsp_ready <= 1'b1;
            end else begin
                tapReg <= tapShiftReg;
            end
        end
    end
end

always @(negedge i_tck) begin
    o_tdo <= tapShiftReg[0];
end

endmodule