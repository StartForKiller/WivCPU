`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 18.11.2023 17:16:48
// Design Name:
// Module Name: hazards
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

import WivDefines::*;

module hazards(
    input i_clk,
    input i_reset,

    input         i_if_dependency,
    input         i_id_dependency,
    input         i_ex_dependency,
    input         i_mem_dependency,

    input ID_EX_t i_ID_EX,
    input EX_MEM_t i_EX_MEM,

    output        o_stall_if,
    output        o_stall_id,
    output        o_stall_ex,
    output        o_stall_mem,

    output        o_flush_ex,
    output        o_flush_mem
);

//TODO: Handle more cases
assign o_stall_if = ((i_id_dependency && !i_ID_EX.jmp) || o_stall_id) && !i_ID_EX.trap;
assign o_stall_id = i_ex_dependency || o_stall_ex;
assign o_stall_ex = i_mem_dependency || o_stall_mem;
assign o_stall_mem = 1'b0;

assign o_flush_ex = 1'b0;
assign o_flush_mem = 1'b0;

endmodule