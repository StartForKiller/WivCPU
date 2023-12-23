`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 18.11.2023 17:16:48
// Design Name:
// Module Name: timer
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


module timer
#(
    parameter [63:0] MAPPED_ADDRESS = 64'h100002000
)
(
    input               i_clk,
    input               i_reset,

    input [63:0]        i_wb_adr,
    input [63:0]        i_wb_dat,
    inout [63:0]        o_wb_dat,
    input               i_wb_we,
    input [7:0]         i_wb_sel,
    input               i_wb_stb,
    inout               o_wb_ack,
    inout               o_wb_stall,
    input               i_wb_cyc,

    input [63:0]        i_mtime,
    input [63:0]        i_mtimecmp,
    output reg          o_mtime_we,
    output reg          o_mtimecmp_we,
    output [63:0]       o_timer_data
);

/* verilator lint_off UNSIGNED */
wire addr_match = i_wb_adr >= MAPPED_ADDRESS && i_wb_adr < (MAPPED_ADDRESS + 16);
/* verilator lint_on UNSIGNED */

reg [63:0] o_wb_data_latch;
reg o_wb_ack_latch;
assign o_wb_dat = addr_match ? (o_wb_data_latch & { 8'($signed(i_wb_sel[7:7])), 8'($signed(i_wb_sel[6:6])), 8'($signed(i_wb_sel[5:5])), 8'($signed(i_wb_sel[4:4])),
                                               8'($signed(i_wb_sel[3:3])), 8'($signed(i_wb_sel[2:2])), 8'($signed(i_wb_sel[1:1])), 8'($signed(i_wb_sel[0:0])) }) : 64'hz;
assign o_wb_ack = addr_match ? o_wb_ack_latch : 1'bz;
assign o_wb_stall = (addr_match && i_wb_cyc && i_wb_stb) ? 1'b0 : 1'bz;

reg [63:0] timer_data;
assign o_timer_data = timer_data;

initial begin
    o_mtime_we = 1'b0;
    o_mtimecmp_we = 1'b0;

    timer_data = 64'h0;

    o_wb_ack_latch = 1'b0;
    o_wb_data_latch = 64'h0;
end

integer i;
always @(negedge i_clk) begin
    o_mtime_we <= 1'b0;
    o_mtimecmp_we <= 1'b0;

    if(addr_match && i_wb_stb && i_wb_cyc) begin
        if(i_wb_we) begin
            timer_data <= i_wb_dat;
            if(i_wb_adr == MAPPED_ADDRESS)
                o_mtime_we <= 1'b1;
            else
                o_mtimecmp_we <= 1'b1;
        end
        else if(i_wb_adr == MAPPED_ADDRESS)
            o_wb_data_latch <= i_mtime;
        else
            o_wb_data_latch <= i_mtimecmp;
    end
end

always @(negedge i_clk) begin
    if(i_reset) begin
        o_wb_ack_latch <= 1'b0;
    end
    else if(addr_match) begin
        if(i_wb_stb && i_wb_cyc) begin
            o_wb_ack_latch <= 1;
        end else begin
            o_wb_ack_latch <= 0;
        end
    end
end

endmodule