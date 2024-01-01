`timescale 10ns / 10ps
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


module top(
    input i_clk,
    input i_reset,

    input        i_uart_rx,
    output       o_uart_tx,

    output       o_sd_clk,
    output       o_sd_cs,
    input        i_sd_miso,
    output       o_sd_mosi,
    output       o_sd_rsv,

    input        i_tck,
    input        i_tms,
    input        i_tdi,
    output       o_tdo,

    // DDR3 Physical Interface Signals
    //Inouts
    inout  [15:0] ddr3_dq,
    inout  [1:0]  ddr3_dqs_n,
    inout  [1:0]  ddr3_dqs_p,
    // Outputs
    output [13:0] ddr3_addr,
    output [2:0]  ddr3_ba,
    output ddr3_ras_n,
    output ddr3_cas_n,
    output ddr3_we_n,
    output ddr3_reset_n,
    output [0:0] ddr3_ck_p,
    output [0:0] ddr3_ck_n,
    output [0:0] ddr3_cke,
    output [0:0] ddr3_cs_n,
    output [1:0] ddr3_dm,
    output [0:0] ddr3_odt,

    output [7:0] o_debug_leds,
    output [7:0] o_seg,
    output [3:0] o_seg_sel,
    input        i_clk_manual_switch,
    input        i_clk_manual
);

wire clk_400khz;
`ifdef VERILATOR
    assign clk_400khz = i_clk;
`elsif XILINX_SIMULATOR
    assign clk_400khz = i_clk;
`else
    clk_div #(.CLK_DIV(250))
    clk_100k(
        .i_clk(i_clk),
        .o_clk(clk_400khz)
    );
`endif

wire clk_50hz;
clk_div #(.CLK_DIV(8000))
clk_50(
    .i_clk(clk_400khz),
    .o_clk(clk_50hz)
);

reg reset_debounced;
reg clk_manual_debounced;
reg clk_manual;
always @(posedge clk_50hz) begin
    clk_manual_debounced <= ~i_clk_manual;
    reset_debounced <= i_reset;

    if(clk_manual_debounced == 1'b0 && ~i_clk_manual == 1'b1) clk_manual <= ~clk_manual;
end

wire core_clk = /*i_clk_manual_switch ? */clk_400khz/* : clk_manual*/;

wire [63:0] wb_adr;
wire [63:0] wb_idat;
wire [63:0] wb_odat;
wire        wb_we;
wire [7:0]  wb_sel;
wire        wb_stb;
wire        wb_ack;
wire        wb_cyc;
wire        wb_stall;

wire [63:0] mtime;
wire [63:0] mtimecmp;
wire        mtime_we;
wire        mtimecmp_we;
wire [63:0] timer_data;

//DMI Bus
wire        dmi_req_valid;
wire        dmi_req_ready;
wire [6:0]  dmi_req_address;
wire [31:0] dmi_req_data;
wire [1:0]  dmi_req_op;
wire        dmi_rsp_valid;
wire        dmi_rsp_ready;
wire [31:0] dmi_rsp_data;
wire [1:0]  dmi_rsp_op;

wire [23:0] core_debug;
WIVCpu wiv_core(
    .i_clk(core_clk),
    .i_reset(i_clk_manual_switch ? i_reset : reset_debounced),

    .o_wb_adr(wb_adr),
    .i_wb_dat(wb_idat),
    .o_wb_dat(wb_odat),
    .o_wb_we(wb_we),
    .o_wb_sel(wb_sel),
    .o_wb_stb(wb_stb),
    .i_wb_ack(wb_ack),
    .o_wb_cyc(wb_cyc),
    .i_wb_stall(wb_stall),

    .o_mtime(mtime),
    .o_mtimecmp(mtimecmp),
    .i_mtime(timer_data),
    .i_mtimecmp(timer_data),
    .i_mtime_we(mtime_we),
    .i_mtimecmp_we(mtimecmp_we),

    .i_dmi_req_valid(dmi_req_valid),
    .o_dmi_req_ready(dmi_req_ready),
    .i_dmi_req_address(dmi_req_address),
    .i_dmi_req_data(dmi_req_data),
    .i_dmi_req_op(dmi_req_op),
    .o_dmi_rsp_valid(dmi_rsp_valid),
    .i_dmi_rsp_ready(dmi_rsp_ready),
    .o_dmi_rsp_data(dmi_rsp_data),
    .o_dmi_rsp_op(dmi_rsp_op),

    .o_debug(core_debug)
);

tapctrl tap_ctrl(
    .i_clk(i_clk),
    .i_reset(i_reset),

    .i_tck(i_tck),
    .i_tms(i_tms),
    .i_tdi(i_tdi),
    .o_tdo(o_tdo),

    .o_dmi_req_valid(dmi_req_valid),
    .i_dmi_req_ready(dmi_req_ready),
    .o_dmi_req_address(dmi_req_address),
    .o_dmi_req_data(dmi_req_data),
    .o_dmi_req_op(dmi_req_op),
    .i_dmi_rsp_valid(dmi_rsp_valid),
    .o_dmi_rsp_ready(dmi_rsp_ready),
    .i_dmi_rsp_data(dmi_rsp_data),
    .i_dmi_rsp_op(dmi_rsp_op)
);

bios #(.MAPPED_ADDRESS(64'h0))
memory(
    .i_clk(core_clk),
    .i_reset(i_reset),

    .i_wb_adr(wb_adr),
    .i_wb_dat(wb_odat),
    .o_wb_dat(wb_idat),
    .i_wb_we(wb_we),
    .i_wb_sel(wb_sel),
    .i_wb_stb(wb_stb),
    .o_wb_ack(wb_ack),
    .o_wb_stall(wb_stall),
    .i_wb_cyc(wb_cyc)
);

timer #(.MAPPED_ADDRESS(64'h100002000))
cpu_timer(
    .i_clk(core_clk),
    .i_reset(i_reset),

    .i_wb_adr(wb_adr),
    .i_wb_dat(wb_odat),
    .o_wb_dat(wb_idat),
    .i_wb_we(wb_we),
    .i_wb_sel(wb_sel),
    .i_wb_stb(wb_stb),
    .o_wb_ack(wb_ack),
    .o_wb_stall(wb_stall),
    .i_wb_cyc(wb_cyc),

    .i_mtime(mtime),
    .i_mtimecmp(mtimecmp),
    .o_mtime_we(mtime_we),
    .o_mtimecmp_we(mtimecmp_we),
    .o_timer_data(timer_data)
);

wire uart_clk;
clk_div #(.CLK_DIV(868))
clk_uart(
    .i_clk(i_clk),
    .o_clk(uart_clk)
);

uart #(.MAPPED_ADDRESS(64'h100000000))
uart_dev(
    .i_clk(core_clk),
    .i_uart_clk(uart_clk),
    .i_reset(i_reset),

    .i_wb_adr(wb_adr),
    .i_wb_dat(wb_odat),
    .o_wb_dat(wb_idat),
    .i_wb_we(wb_we),
    .i_wb_sel(wb_sel),
    .i_wb_stb(wb_stb),
    .o_wb_ack(wb_ack),
    .o_wb_stall(wb_stall),
    .i_wb_cyc(wb_cyc),

    .i_uart_rx(i_uart_rx),
    .o_uart_tx(o_uart_tx)
);

wire       spi_sck;
wire       spi_mosi;
wire       spi_miso;
wire [7:0] spi_cs;

spi #(.MAPPED_ADDRESS(64'h100001000))
spi_dev(
    .i_clk(core_clk),
    .i_reset(i_reset),

    .i_wb_adr(wb_adr),
    .i_wb_dat(wb_odat),
    .o_wb_dat(wb_idat),
    .i_wb_we(wb_we),
    .i_wb_sel(wb_sel),
    .i_wb_stb(wb_stb),
    .o_wb_ack(wb_ack),
    .o_wb_stall(wb_stall),
    .i_wb_cyc(wb_cyc),

    .o_sck(spi_sck),
    .o_mosi(spi_mosi),
    .i_miso(spi_miso),
    .o_select(spi_cs)
);

`ifndef VERILATOR
wire [15:0] ddr3_debug;
ddr3 #(.MAPPED_ADDRESS(64'h010000000))
ddr3_dev(
    .i_clk(core_clk),
    .i_sys_clk(i_clk),
    .i_reset(i_reset),

    .i_wb_adr(wb_adr),
    .i_wb_dat(wb_odat),
    .o_wb_dat(wb_idat),
    .i_wb_we(wb_we),
    .i_wb_sel(wb_sel),
    .i_wb_stb(wb_stb),
    .o_wb_ack(wb_ack),
    .o_wb_stall(wb_stall),
    .i_wb_cyc(wb_cyc),

    .ddr3_dq(ddr3_dq),
    .ddr3_dqs_n(ddr3_dqs_n),
    .ddr3_dqs_p(ddr3_dqs_p),
    .ddr3_addr(ddr3_addr),
    .ddr3_ba(ddr3_ba),
    .ddr3_ras_n(ddr3_ras_n),
    .ddr3_cas_n(ddr3_cas_n),
    .ddr3_we_n(ddr3_we_n),
    .ddr3_reset_n(ddr3_reset_n),
    .ddr3_ck_p(ddr3_ck_p),
    .ddr3_ck_n(ddr3_ck_n),
    .ddr3_cke(ddr3_cke),
    .ddr3_cs_n(ddr3_cs_n),
    .ddr3_dm(ddr3_dm),
    .ddr3_odt(ddr3_odt),

    .o_debug(ddr3_debug)
);
`endif

seg7 seg_7(
    .i_clk(clk_400khz),
    .i_data(i_clk_manual_switch ? ddr3_debug : core_debug[23:8]),
    .o_seg(o_seg),
    .o_sel(o_seg_sel)
);

assign o_sd_clk = spi_sck;
assign o_sd_cs = spi_cs[0:0];
assign spi_miso = spi_cs[0:0] ? 1'bz : i_sd_miso;
assign o_sd_mosi = spi_mosi;
assign o_sd_rsv = 1'b1; //Pull up

assign o_debug_leds = core_debug[7:0];

endmodule
