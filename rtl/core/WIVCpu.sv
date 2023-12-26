`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 18.11.2023 17:16:48
// Design Name:
// Module Name: WIVCpu
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

module WIVCpu(
    input i_clk,
    input i_reset,

    //WishBone Bus
    output [63:0] o_wb_adr,
    input  [63:0] i_wb_dat,
    output [63:0] o_wb_dat,
    output        o_wb_we,
    output [7:0]  o_wb_sel,
    output        o_wb_stb,
    input         i_wb_ack,
    output        o_wb_cyc,
    input         i_wb_stall,

    output [63:0]     o_mtime,
    output [63:0]     o_mtimecmp,
    input  [63:0]     i_mtime,
    input  [63:0]     i_mtimecmp,
    input             i_mtime_we,
    input             i_mtimecmp_we,

    //DMI-DM Bus
    input         i_dmi_req_valid,
    output        o_dmi_req_ready,
    input  [6:0]  i_dmi_req_address,
    input  [31:0] i_dmi_req_data,
    input  [1:0]  i_dmi_req_op,
    output        o_dmi_rsp_valid,
    input         i_dmi_rsp_ready,
    output [31:0] o_dmi_rsp_data,
    output [1:0]  o_dmi_rsp_op,

    output [23:0] o_debug
);

// - CACHE control signals
wire [63:0] icache_addr;
wire [31:0] icache_data;
wire        icache_data_ready;
wire        icache_invalidating;
wire [63:0] dcache_addr;
wire [63:0] dcache_idata;
wire [63:0] dcache_odata;
wire [7:0]  dcache_sel;
wire        dcache_st;
wire        dcache_ld;
wire        dcache_atomic;
wire        dcache_reserved;
wire        dcache_data_ready;
wire        dcache_ready;
wire        dcache_invalidating;

wire if_stall;
wire id_stall;
wire ex_stall;
wire mem_stall;
wire ex_flush;
wire mem_flush;
wire if_dependency;
wire id_dependency;
wire ex_dependency;
wire mem_dependency;
IF_ID_t IF_ID;
ID_EX_t ID_EX;
EX_MEM_t EX_MEM;
MEM_WB_t MEM_WB;

wire        core_halt;
wire        core_halted = !IF_ID.valid && !ID_EX.valid && !EX_MEM.valid && !MEM_WB.valid && core_halt;
wire        dm_reg_access;
wire        dm_reg_we;
wire [63:0] dm_reg_o_data;
wire [63:0] dm_reg_i_data;
wire [12:0] dm_reg_addr;

wire [63:0]    debug_PC;
wire [63:0]    mtvec;
wire [63:0]    mcause;
pmp_cfg_t      pmp_cfg[16];
logic [55:0]   pmp_addr[16];
logic [55:0]   pmp_req_addr_dcache;
logic [55:0]   pmp_req_addr[2];
pmp_req_type_t pmp_req_type_dcache;
pmp_req_type_t pmp_req_type[2];
logic          pmp_req_trap[2];

assign pmp_req_addr[0] = icache_addr[55:0];
assign pmp_req_addr[1] = pmp_req_addr_dcache;
assign pmp_req_type[0] = PMP_REQ_EXEC;
assign pmp_req_type[1] = pmp_req_type_dcache;

wire [63:0] dpc;

hazards core_hazards(
    .i_clk(i_clk),
    .i_reset(i_reset),

    .i_if_dependency(if_dependency),
    .i_id_dependency(id_dependency),
    .i_ex_dependency(ex_dependency),
    .i_mem_dependency(mem_dependency),

    .i_ID_EX(ID_EX),
    .i_EX_MEM(EX_MEM),

    .o_stall_if(if_stall),
    .o_stall_id(id_stall),
    .o_stall_ex(ex_stall),
    .o_stall_mem(mem_stall),

    .o_flush_ex(ex_flush),
    .o_flush_mem(mem_flush)
);

core_if cpu_if(
    .i_clk(i_clk),
    .i_reset(i_reset),

    .o_IF_ID(IF_ID),
    .i_ID_EX(ID_EX),

    .o_icache_addr(icache_addr),
    .i_icache_data(icache_data),
    .i_icache_data_ready(icache_data_ready),

    .i_mtvec(mtvec),
    .i_mcause(mcause),

    .i_stall(if_stall),
    .o_dependency(if_dependency),
    .i_halt(core_halt),
    .i_halted(core_halted),
    .i_dpc(dpc),
    .i_pmp_icache_trap(pmp_req_trap[0]),

    .o_debug_PC(debug_PC)
);

core_id cpu_id(
    .i_clk(i_clk),
    .i_reset(i_reset),

    .i_IF_ID(IF_ID),
    .o_ID_EX(ID_EX),
    .i_EX_MEM(EX_MEM),
    .i_MEM_WB(MEM_WB),

    .i_dcache_invalidating(dcache_invalidating),
    .i_icache_invalidating(icache_invalidating),

    .i_reg_access(dm_reg_access && core_halted),
    .i_reg_we(dm_reg_we),
    .i_reg_data(dm_reg_o_data),
    .o_reg_data(dm_reg_i_data),
    .i_reg_addr(dm_reg_addr),

    .i_stall(id_stall),
    .o_dependency(id_dependency),

    .i_debug_PC(debug_PC),
    .o_mtime(o_mtime),
    .o_mtimecmp(o_mtimecmp),
    .i_mtime(i_mtime),
    .i_mtimecmp(i_mtimecmp),
    .i_mtime_we(i_mtime_we),
    .i_mtimecmp_we(i_mtimecmp_we),
    .o_dpc(dpc),
    .i_halted(core_halted),

    .o_pmp_cfg(pmp_cfg),
    .o_pmp_addr(pmp_addr),
    .i_pmp_icache_trap(pmp_req_trap[0]),
    .o_pmp_dcache_addr(pmp_req_addr_dcache),
    .o_pmp_dcache_type(pmp_req_type_dcache),
    .i_pmp_dcache_trap(pmp_req_trap[1]),

    .o_mtvec(mtvec),
    .o_mcause(mcause)
);

core_ex cpu_ex(
    .i_clk(i_clk),
    .i_reset(i_reset),

    .i_ID_EX(ID_EX),
    .o_EX_MEM(EX_MEM),

    .i_stall(ex_stall),
    .i_flush(ex_flush),
    .o_dependency(ex_dependency)
);

core_mem cpu_mem(
    .i_clk(i_clk),
    .i_reset(i_reset),

    .i_EX_MEM(EX_MEM),
    .o_MEM_WB(MEM_WB),

    .o_dcache_addr(dcache_addr),
    .i_dcache_idata(dcache_odata),
    .o_dcache_odata(dcache_idata),
    .o_dcache_sel(dcache_sel),
    .o_dcache_st(dcache_st),
    .o_dcache_ld(dcache_ld),
    .o_dcache_atomic(dcache_atomic),
    .i_dcache_reserved(dcache_reserved),
    .i_dcache_data_ready(dcache_data_ready),
    .i_dcache_ready(dcache_ready),

    .i_stall(mem_stall),
    .i_flush(mem_flush),
    .o_dependency(mem_dependency)
);

pmp pmp_logic(
    .i_pmp_cfg(pmp_cfg),
    .i_pmp_addr(pmp_addr),

    .i_req_addr(pmp_req_addr),
    .i_req_type(pmp_req_type),
    .o_req_trap(pmp_req_trap)
);

// - DM Region
wire [63:0] dm_wb_adr;
wire [63:0] dm_wb_idat;
wire [63:0] dm_wb_odat;
wire        dm_wb_we;
wire [7:0]  dm_wb_sel;
wire        dm_wb_stb;
wire        dm_wb_ack;
wire        dm_wb_cyc;
wire        dm_wb_stall;
wire        dm_wb_rty;
wire        dm_wb_lock;

// - CACHE Region
wire [63:0] icache_wb_adr;
wire [63:0] icache_wb_idat;
wire [63:0] icache_wb_odat;
wire        icache_wb_we;
wire [7:0]  icache_wb_sel;
wire        icache_wb_stb;
wire        icache_wb_ack;
wire        icache_wb_cyc;
wire        icache_wb_stall;
wire        icache_wb_rty;
wire        icache_wb_lock;

icache wiv_icache(
    .i_clk(i_clk),
    .i_reset(i_reset),

    .o_wb_adr(icache_wb_adr),
    .i_wb_dat(icache_wb_idat),
    .o_wb_dat(icache_wb_odat),
    .o_wb_we(icache_wb_we),
    .o_wb_sel(icache_wb_sel),
    .o_wb_stb(icache_wb_stb),
    .i_wb_ack(icache_wb_ack),
    .o_wb_cyc(icache_wb_cyc),
    .i_wb_stall(icache_wb_stall),
    .i_wb_rty(icache_wb_rty),
    .o_wb_lock(icache_wb_lock),

    .i_enable(!pmp_req_trap[0]),
    .i_addr(icache_addr),
    .o_data(icache_data),

    .i_icache_invalidate(ID_EX.invalidate_icache),
    .o_icache_invalidating(icache_invalidating),

    .o_data_ready(icache_data_ready)
);

wire [63:0] dcache_wb_adr;
wire [63:0] dcache_wb_idat;
wire [63:0] dcache_wb_odat;
wire        dcache_wb_we;
wire [7:0]  dcache_wb_sel;
wire        dcache_wb_stb;
wire        dcache_wb_ack;
wire        dcache_wb_cyc;
wire        dcache_wb_stall;
wire        dcache_wb_rty;
wire        dcache_wb_lock;

dcache wiv_dcache(
    .i_clk(i_clk),
    .i_reset(i_reset),

    .o_wb_adr(dcache_wb_adr),
    .i_wb_dat(dcache_wb_idat),
    .o_wb_dat(dcache_wb_odat),
    .o_wb_we(dcache_wb_we),
    .o_wb_sel(dcache_wb_sel),
    .o_wb_stb(dcache_wb_stb),
    .i_wb_ack(dcache_wb_ack),
    .o_wb_cyc(dcache_wb_cyc),
    .i_wb_stall(dcache_wb_stall),
    .i_wb_rty(dcache_wb_rty),
    .o_wb_lock(dcache_wb_lock),

    .i_dcache_addr(dcache_addr),
    .o_dcache_odata(dcache_odata),
    .i_dcache_idata(dcache_idata),
    .i_dcache_sel(dcache_sel),
    .i_dcache_st(dcache_st),
    .i_dcache_ld(dcache_ld),
    .i_dcache_atomic(dcache_atomic),
    .o_dcache_reserved(dcache_reserved),
    .i_dcache_invalidate(ID_EX.invalidate_dcache),
    .o_dcache_data_ready(dcache_data_ready),
    .o_dcache_ready(dcache_ready),
    .o_dcache_invalidating(dcache_invalidating)
);

wire [1:0] device_working;
wb_intercon intercon(
    .i_clk(i_clk),
    .i_reset(i_reset),

    //Wb
    .o_wb_adr(o_wb_adr),
    .i_wb_dat(i_wb_dat),
    .o_wb_dat(o_wb_dat),
    .o_wb_we(o_wb_we),
    .o_wb_sel(o_wb_sel),
    .o_wb_stb(o_wb_stb),
    .i_wb_ack(i_wb_ack),
    .o_wb_cyc(o_wb_cyc),
    .i_wb_stall(i_wb_stall),

    //ICache
    .i_icache_wb_adr(icache_wb_adr),
    .o_icache_wb_dat(icache_wb_idat),
    .i_icache_wb_dat(icache_wb_odat),
    .i_icache_wb_we(icache_wb_we),
    .i_icache_wb_sel(icache_wb_sel),
    .i_icache_wb_stb(icache_wb_stb),
    .o_icache_wb_ack(icache_wb_ack),
    .i_icache_wb_cyc(icache_wb_cyc),
    .o_icache_wb_stall(icache_wb_stall),
    .o_icache_wb_rty(icache_wb_rty),
    .i_icache_wb_lock(icache_wb_lock),

    //DCache
    .i_dcache_wb_adr(dcache_wb_adr),
    .o_dcache_wb_dat(dcache_wb_idat),
    .i_dcache_wb_dat(dcache_wb_odat),
    .i_dcache_wb_we(dcache_wb_we),
    .i_dcache_wb_sel(dcache_wb_sel),
    .i_dcache_wb_stb(dcache_wb_stb),
    .o_dcache_wb_ack(dcache_wb_ack),
    .i_dcache_wb_cyc(dcache_wb_cyc),
    .o_dcache_wb_stall(dcache_wb_stall),
    .o_dcache_wb_rty(dcache_wb_rty),
    .i_dcache_wb_lock(dcache_wb_lock),

    //Debug Module
    .i_dm_wb_adr(dm_wb_adr),
    .o_dm_wb_dat(dm_wb_idat),
    .i_dm_wb_dat(dm_wb_odat),
    .i_dm_wb_we(dm_wb_we),
    .i_dm_wb_sel(dm_wb_sel),
    .i_dm_wb_stb(dm_wb_stb),
    .o_dm_wb_ack(dm_wb_ack),
    .i_dm_wb_cyc(dm_wb_cyc),
    .o_dm_wb_stall(dm_wb_stall),
    .o_dm_wb_rty(dm_wb_rty),
    .i_dm_wb_lock(dm_wb_lock),

    .o_device_working(device_working)
);

dm dm_module(
    .i_clk(i_clk),
    .i_reset(i_reset),

    .i_dmi_req_valid(i_dmi_req_valid),
    .o_dmi_req_ready(o_dmi_req_ready),
    .i_dmi_req_address(i_dmi_req_address),
    .i_dmi_req_data(i_dmi_req_data),
    .i_dmi_req_op(i_dmi_req_op),
    .o_dmi_rsp_valid(o_dmi_rsp_valid),
    .i_dmi_rsp_ready(i_dmi_rsp_ready),
    .o_dmi_rsp_data(o_dmi_rsp_data),
    .o_dmi_rsp_op(o_dmi_rsp_op),

    .o_halt(core_halt),
    .i_halted(core_halted),

    .o_reg_access(dm_reg_access),
    .o_reg_we(dm_reg_we),
    .o_reg_data(dm_reg_o_data),
    .i_reg_data(dm_reg_i_data),
    .o_reg_addr(dm_reg_addr),

    .o_wb_adr(dm_wb_adr),
    .i_wb_dat(dm_wb_idat),
    .o_wb_dat(dm_wb_odat),
    .o_wb_we(dm_wb_we),
    .o_wb_sel(dm_wb_sel),
    .o_wb_stb(dm_wb_stb),
    .i_wb_ack(dm_wb_ack),
    .o_wb_cyc(dm_wb_cyc),
    .i_wb_stall(dm_wb_stall),
    .i_wb_rty(dm_wb_rty),
    .o_wb_lock(dm_wb_lock)
);

assign o_debug = //{i_clk ? IF_ID.instruction[31:16] : IF_ID.instruction[15:0],
        //{i_clk ? EX_MEM.data[31:16] : EX_MEM.data[15:0],
        {debug_PC[15:0],
        device_working, mem_dependency, id_dependency, EX_MEM.valid, ID_EX.valid, IF_ID.valid, i_clk};

endmodule
