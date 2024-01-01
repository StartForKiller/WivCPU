`timescale 10ns / 10ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 18.11.2023 17:16:48
// Design Name:
// Module Name: ddr3
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


module ddr3
#(
    parameter [63:0] MAPPED_ADDRESS = 64'h0,
    parameter        ADDR_BITS = 28
)
(
    input               i_clk,
    input               i_sys_clk,
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

    output [15:0] o_debug
);

wire finish_configure;

reg  [27:0] app_addr = 0;
reg  [2:0]  app_cmd = 0;
reg  app_en = 1'b0;
wire app_rdy;

reg  [127:0] app_wdf_data;
wire app_wdf_end = 1;
reg  app_wdf_wren = 1'b0;
wire app_wdf_rdy;

wire [127:0] app_rd_data;
reg [15:0] app_wdf_mask = 16'h0000;
wire app_rd_data_end;
wire app_rd_data_valid;

wire app_sr_req = 0;
wire app_ref_req = 0;
wire app_zq_req = 0;
wire app_sr_active;
wire app_ref_ack;
wire app_zq_ack;

wire ui_clk;
wire ui_clk_sync_rst;

wire sys_clk_i;

// Power-on-reset generator circuit.
// Asserts resetn for 1023 cycles, then deasserts
// `resetn` is Active low reset
reg [14:0] por_counter = 1023;
always @ (posedge i_sys_clk) begin
    if (por_counter) begin
        por_counter <= por_counter - 1 ;
    end
end

 wire resetn = (por_counter == 0);

// Clock Wizard
// DDR3 core requires 200MHz input clock
// We generate this clock using Xilinx Clocking Wizard IP Core
clk_wiz clk_wiz (
   .clk_in (i_sys_clk),
   .clk_200 (sys_clk_i),
   .resetn (resetn)
 );

ddr3_mig
mem (
   // DDR3 Physical interface ports
   .ddr3_addr   (ddr3_addr),
   .ddr3_ba     (ddr3_ba),
   .ddr3_cas_n  (ddr3_cas_n),
   .ddr3_ck_n   (ddr3_ck_n),
   .ddr3_ck_p   (ddr3_ck_p),
   .ddr3_cke    (ddr3_cke),
   .ddr3_ras_n  (ddr3_ras_n),
   .ddr3_reset_n(ddr3_reset_n),
   .ddr3_we_n   (ddr3_we_n),
   .ddr3_dq     (ddr3_dq),
   .ddr3_dqs_n  (ddr3_dqs_n),
   .ddr3_dqs_p  (ddr3_dqs_p),
   .ddr3_cs_n   (ddr3_cs_n),
   .ddr3_dm     (ddr3_dm),
   .ddr3_odt    (ddr3_odt),

   .init_calib_complete (finish_configure),

   // User interface ports
   .app_addr    (app_addr),
   .app_cmd     (app_cmd),
   .app_en      (app_en),
   .app_wdf_data(app_wdf_data),
   .app_wdf_end (app_wdf_end),
   .app_wdf_wren(app_wdf_wren),
   .app_rd_data (app_rd_data),
   .app_rd_data_end (app_rd_data_end),
   .app_rd_data_valid (app_rd_data_valid),
   .app_rdy     (app_rdy),
   .app_wdf_rdy (app_wdf_rdy),
   .app_sr_req  (app_sr_req),
   .app_ref_req (app_ref_req),
   .app_zq_req  (app_zq_req),
   .app_sr_active(app_sr_active),
   .app_ref_ack (app_ref_ack),
   .app_zq_ack  (app_zq_ack),
   .ui_clk      (ui_clk),
   .ui_clk_sync_rst (ui_clk_sync_rst),
   .app_wdf_mask(app_wdf_mask),
   // Clock and Reset input ports
   .sys_clk_i (sys_clk_i),
   .sys_rst (resetn)
);

/* verilator lint_off UNSIGNED */
wire addr_match = i_wb_adr >= MAPPED_ADDRESS && i_wb_adr < (MAPPED_ADDRESS + (2**ADDR_BITS));
/* verilator lint_on UNSIGNED */

reg [63:0] o_wb_data_latch;
reg o_wb_ack_latch;
assign o_wb_dat = addr_match ? (o_wb_data_latch & { 8'($signed(i_wb_sel[7:7])), 8'($signed(i_wb_sel[6:6])), 8'($signed(i_wb_sel[5:5])), 8'($signed(i_wb_sel[4:4])),
                                               8'($signed(i_wb_sel[3:3])), 8'($signed(i_wb_sel[2:2])), 8'($signed(i_wb_sel[1:1])), 8'($signed(i_wb_sel[0:0])) }) : 64'hz;
assign o_wb_ack = addr_match ? o_wb_ack_latch : 1'bz;
assign o_wb_stall = (addr_match && i_wb_cyc && i_wb_stb) ? 1'b0 : 1'bz;

reg [1:0] state;
reg       app_rd_data_valid_latch;
reg       send_app_en;
reg       send_app_wdf_wren;
reg       send_app_en_latch;
reg       send_app_wdf_wren_latch;

initial begin
    o_wb_ack_latch = 1'b0;
    o_wb_data_latch = 64'h0;

    state = 2'h0;
    app_rd_data_valid_latch = 1'b0;
    send_app_en = 1'b0;
    send_app_wdf_wren = 1'b0;
    send_app_en_latch = 1'b0;
    send_app_wdf_wren_latch = 1'b0;
end

//assign o_wb_data_latch = mem[i_wb_adr[14:3]] & { 8'($signed(i_wb_sel[7:7])), 8'($signed(i_wb_sel[6:6])), 8'($signed(i_wb_sel[5:5])), 8'($signed(i_wb_sel[4:4])),
//                                                 8'($signed(i_wb_sel[3:3])), 8'($signed(i_wb_sel[2:2])), 8'($signed(i_wb_sel[1:1])), 8'($signed(i_wb_sel[0:0])) };

always @(posedge ui_clk) begin
    send_app_en_latch <= send_app_en;
    send_app_wdf_wren_latch <= send_app_wdf_wren;

    if(app_rd_data_valid && state == 2'h2) begin
        o_wb_data_latch <= app_rd_data[63:0];
        app_rd_data_valid_latch <= 1'b1;
    end else if(!app_rd_data_valid && state != 2'h2) begin
        app_rd_data_valid_latch <= 1'b0;
    end

    if(!send_app_en_latch && send_app_en)
        app_en <= 1'b1;

    if(!send_app_wdf_wren_latch && send_app_wdf_wren)
        app_wdf_wren <= 1'b1;
    else if(state == 2'h1)
        app_wdf_wren <= 1'b0;

    if(app_rdy && app_en) app_en <= 1'b0;
    if(app_wdf_rdy && app_wdf_wren) app_wdf_wren <= 1'b0;
end

integer i;
always @(negedge i_clk) begin
    o_wb_ack_latch <= 0;

    case(state)
        2'h0: begin
            if(i_wb_stb && i_wb_cyc) begin
                if(addr_match) begin
                    if(i_wb_we && app_rdy && app_wdf_rdy) begin
                        //Can write
                        send_app_en <= 1'b1;
                        send_app_wdf_wren <= 1'b1;
                        app_addr <= {1'b0, i_wb_adr[27:4], 3'h0};
                        case(i_wb_adr[3:0])
                            4'h0: app_wdf_mask <= 16'hFF00 | {8'h0, ~i_wb_sel};
                            4'h1: app_wdf_mask <= 16'hFC00 | {7'h0, ~i_wb_sel,  1'h1};
                            4'h2: app_wdf_mask <= 16'hF800 | {6'h0, ~i_wb_sel,  2'h3};
                            4'h3: app_wdf_mask <= 16'hF000 | {5'h0, ~i_wb_sel,  3'h7};
                            4'h4: app_wdf_mask <= 16'hE000 | {4'h0, ~i_wb_sel,  4'hF};
                            4'h5: app_wdf_mask <= 16'hC000 | {3'h0, ~i_wb_sel,  5'h1F};
                            4'h6: app_wdf_mask <= 16'h8000 | {2'h0, ~i_wb_sel,  6'h3F};
                            4'h7: app_wdf_mask <= 16'h0000 | {1'h0, ~i_wb_sel,  7'h7F};
                            4'h8: app_wdf_mask <= {      ~i_wb_sel,  8'hFF};
                            4'h9: app_wdf_mask <= { ~i_wb_sel[6:0],  9'h1FF};
                            4'hA: app_wdf_mask <= { ~i_wb_sel[5:0], 10'h3FF};
                            4'hB: app_wdf_mask <= { ~i_wb_sel[4:0], 11'h7FF};
                            4'hC: app_wdf_mask <= { ~i_wb_sel[3:0], 12'hFFF};
                            4'hD: app_wdf_mask <= { ~i_wb_sel[2:0], 13'h1FFF};
                            4'hE: app_wdf_mask <= { ~i_wb_sel[1:0], 14'h3FFF};
                            4'hF: app_wdf_mask <= { ~i_wb_sel[0:0], 15'h7FFF};
                        endcase
                        app_cmd <= 3'h0;
                        app_wdf_data <= 128'(i_wb_dat) << {i_wb_adr[3:0], 3'h0};
                        state <= 2'h1;

                        o_wb_ack_latch <= 1;
                    end else if(!i_wb_we && app_rdy) begin
                        //Can read
                        send_app_en <= 1'b1;
                        app_addr <= {1'b0, i_wb_adr[27:1]};
                        app_cmd <= 3'h1;
                        state <= 2'h2;

                        //o_wb_ack_latch <= 1;
                    end
                end
            end
        end
        2'h1: begin
            send_app_wdf_wren <= 1'b0;
            send_app_en <= 1'b0;
            if(~app_en && ~app_wdf_wren) state <= 2'h0;
        end
        2'h2: begin
            send_app_en <= 1'b0;
            if(app_rd_data_valid_latch) begin
                //o_wb_data_latch <= app_rd_data[63:0];

                o_wb_ack_latch <= 1;
                state <= 2'h0;
            end
        end
    endcase
end

assign o_debug = {8'h0, 2'h0, state, 1'h0, app_wdf_rdy, app_rdy, finish_configure};

endmodule