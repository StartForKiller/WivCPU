`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 18.11.2023 17:16:48
// Design Name:
// Module Name: wb_intercon
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


module wb_intercon(
    input i_clk,
    input i_reset,

    //Wb
    output [63:0] o_wb_adr,
    input [63:0]  i_wb_dat,
    output [63:0] o_wb_dat,
    output        o_wb_we,
    output [7:0]  o_wb_sel,
    output        o_wb_stb,
    input         i_wb_ack,
    output        o_wb_cyc,
    input         i_wb_stall,

    //ICache
    input [63:0]  i_icache_wb_adr,
    output [63:0] o_icache_wb_dat,
    input [63:0]  i_icache_wb_dat,
    input         i_icache_wb_we,
    input [7:0]   i_icache_wb_sel,
    input         i_icache_wb_stb,
    output        o_icache_wb_ack,
    input         i_icache_wb_cyc,
    output        o_icache_wb_stall,
    output        o_icache_wb_rty,
    input         i_icache_wb_lock,

    //DCache
    input [63:0]  i_dcache_wb_adr,
    output [63:0] o_dcache_wb_dat,
    input [63:0]  i_dcache_wb_dat,
    input         i_dcache_wb_we,
    input [7:0]   i_dcache_wb_sel,
    input         i_dcache_wb_stb,
    output        o_dcache_wb_ack,
    input         i_dcache_wb_cyc,
    output        o_dcache_wb_stall,
    output        o_dcache_wb_rty,
    input         i_dcache_wb_lock,

    //Debug Module
    input [63:0]  i_dm_wb_adr,
    output [63:0] o_dm_wb_dat,
    input [63:0]  i_dm_wb_dat,
    input         i_dm_wb_we,
    input [7:0]   i_dm_wb_sel,
    input         i_dm_wb_stb,
    output        o_dm_wb_ack,
    input         i_dm_wb_cyc,
    output        o_dm_wb_stall,
    output        o_dm_wb_rty,
    input         i_dm_wb_lock,

    output [1:0]  o_device_working
);

wire [1:0] device_working;
assign o_device_working = device_working;

assign device_working = (i_icache_wb_cyc && i_icache_wb_lock) ? 2'h1 : ((i_dcache_wb_cyc && i_dcache_wb_lock) ? 2'h2 : ((i_dm_wb_cyc && i_dm_wb_lock) ? 2'h3 : 2'h0));

/*always @(i_icache_wb_lock or i_dcache_wb_lock or i_icache_wb_cyc or i_dcache_wb_cyc or i_reset or device_working) begin
    if(i_reset) device_working <= 2'h0;
    else begin
        if(device_working == 2'h0) begin
            if(i_icache_wb_cyc && i_icache_wb_lock) begin //ICache
                device_working <= 2'h1;
            end
            else if(i_dcache_wb_cyc && i_dcache_wb_lock) begin //DCache
                device_working <= 2'h2;
            end
        end

        if(device_working == 2'h1 && (!i_icache_wb_lock || !i_icache_wb_cyc)) begin //ICache
            if(i_dcache_wb_lock) device_working <= 2'h2;
            else device_working <= 2'h0;
        end
        else if(device_working == 2'h2 && (!i_dcache_wb_lock || !i_dcache_wb_cyc)) begin //DCache
            if(i_icache_wb_lock) device_working <= 2'h1;
            else device_working <= 2'h0;
        end
    end
end*/

assign o_wb_adr = device_working == 2'h3 ? (i_dm_wb_adr) : (device_working == 2'h2 ? (i_dcache_wb_adr) : (device_working == 2'h1 ? (i_icache_wb_adr) : (64'h0)));
assign o_wb_dat = device_working == 2'h3 ? (i_dm_wb_dat) : (device_working == 2'h2 ? (i_dcache_wb_dat) : (device_working == 2'h1 ? (i_icache_wb_dat) : (64'h0)));
assign o_wb_we  = device_working == 2'h3 ? (i_dm_wb_we)  : (device_working == 2'h2 ? (i_dcache_wb_we)  : (device_working == 2'h1 ? (i_icache_wb_we)  : (1'b0) ));
assign o_wb_sel = device_working == 2'h3 ? (i_dm_wb_sel) : (device_working == 2'h2 ? (i_dcache_wb_sel) : (device_working == 2'h1 ? (i_icache_wb_sel) : (8'h0) ));
assign o_wb_stb = device_working == 2'h3 ? (i_dm_wb_stb) : (device_working == 2'h2 ? (i_dcache_wb_stb) : (device_working == 2'h1 ? (i_icache_wb_stb) : (1'b0) ));
assign o_wb_cyc = device_working == 2'h3 ? (i_dm_wb_cyc) : (device_working == 2'h2 ? (i_dcache_wb_cyc) : (device_working == 2'h1 ? (i_icache_wb_cyc) : (1'b0) ));

assign o_icache_wb_dat   = device_working == 2'h1 ? (i_wb_dat)   : (64'h0);
assign o_icache_wb_ack   = device_working == 2'h1 ? (i_wb_ack)   : (1'b0);
assign o_icache_wb_rty   = device_working == 2'h1 ? (1'b0)       : (i_icache_wb_lock);
assign o_icache_wb_stall = device_working == 2'h1 ? (i_wb_stall) : (1'b0);

assign o_dcache_wb_dat   = device_working == 2'h2 ? (i_wb_dat)   : (64'h0);
assign o_dcache_wb_ack   = device_working == 2'h2 ? (i_wb_ack)   : (1'b0);
assign o_dcache_wb_rty   = device_working == 2'h2 ? (1'b0)       : (i_dcache_wb_lock);
assign o_dcache_wb_stall = device_working == 2'h2 ? (i_wb_stall) : (1'b0);

assign o_dm_wb_dat       = device_working == 2'h3 ? (i_wb_dat)   : (64'h0);
assign o_dm_wb_ack       = device_working == 2'h3 ? (i_wb_ack)   : (1'b0);
assign o_dm_wb_rty       = device_working == 2'h3 ? (1'b0)       : (i_dm_wb_lock);
assign o_dm_wb_stall     = device_working == 2'h3 ? (i_wb_stall) : (1'b0);

endmodule