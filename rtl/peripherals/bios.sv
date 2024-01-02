`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 18.11.2023 17:16:48
// Design Name:
// Module Name: bios
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


module bios
#(
    parameter [63:0] MAPPED_ADDRESS = 64'h0,
    parameter        ADDR_BITS = 17
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
    input               i_wb_cyc
);

reg [63:0] mem[0:(2**(ADDR_BITS-3))-1];
initial begin
    `ifdef VERILATOR
        $readmemh("./samples/program.hex", mem);
    `else
        $readmemh("C:/Users/jesus/Documents/Vivado/WivCPU/samples/program.hex", mem);
    `endif
end

/* verilator lint_off UNSIGNED */
wire addr_match = i_wb_adr >= MAPPED_ADDRESS && i_wb_adr < (MAPPED_ADDRESS + (2**ADDR_BITS));
/* verilator lint_on UNSIGNED */

reg [63:0] o_wb_data_latch;
reg o_wb_ack_latch;
assign o_wb_dat = addr_match ? (o_wb_data_latch & { 8'($signed(i_wb_sel[7:7])), 8'($signed(i_wb_sel[6:6])), 8'($signed(i_wb_sel[5:5])), 8'($signed(i_wb_sel[4:4])),
                                               8'($signed(i_wb_sel[3:3])), 8'($signed(i_wb_sel[2:2])), 8'($signed(i_wb_sel[1:1])), 8'($signed(i_wb_sel[0:0])) }) : 64'hz;
assign o_wb_ack = addr_match ? o_wb_ack_latch : 1'bz;
assign o_wb_stall = (addr_match && i_wb_cyc && i_wb_stb) ? 1'b0 : 1'bz;

initial begin
    o_wb_ack_latch = 1'b0;
    o_wb_data_latch = 64'h0;
end

//assign o_wb_data_latch = mem[i_wb_adr[14:3]] & { 8'($signed(i_wb_sel[7:7])), 8'($signed(i_wb_sel[6:6])), 8'($signed(i_wb_sel[5:5])), 8'($signed(i_wb_sel[4:4])),
//                                                 8'($signed(i_wb_sel[3:3])), 8'($signed(i_wb_sel[2:2])), 8'($signed(i_wb_sel[1:1])), 8'($signed(i_wb_sel[0:0])) };

integer i;
always @(negedge i_clk) begin
    if(addr_match && i_wb_stb && i_wb_cyc && i_wb_we) begin
        for(i = 0; i < 8; i = i + 1) begin
            if(i_wb_sel[i])
                mem[i_wb_adr[(ADDR_BITS-1):3]][i*8 +: 8] <= i_wb_dat[i*8 +: 8];
        end
    end

    o_wb_data_latch <= mem[i_wb_adr[(ADDR_BITS-1):3]];
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