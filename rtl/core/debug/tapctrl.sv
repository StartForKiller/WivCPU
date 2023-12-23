`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 05.11.2023 21:13:51
// Design Name:
// Module Name: tapctrl
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


module tapctrl(
    input  i_clk,
    input  i_reset,

    input  i_tck,
    input  i_tms,
    input  i_tdi,
    output reg o_tdo,

    //DMI-DM Bus
    output        o_dmi_req_valid,
    input         i_dmi_req_ready,
    output [6:0]  o_dmi_req_address,
    output [31:0] o_dmi_req_data,
    output [1:0]  o_dmi_req_op,
    input         i_dmi_rsp_valid,
    output        o_dmi_rsp_ready,
    input  [31:0] i_dmi_rsp_data,
    input  [1:0]  i_dmi_rsp_op
);

reg [3:0] tap_state;
localparam STATE_TEST_LOGIC_RESET = 4'h0;
localparam STATE_RUN_TEST_IDLE    = 4'h1;
localparam STATE_SELECT_DR_SCAN   = 4'h2;
localparam STATE_SELECT_IR_SCAN   = 4'h3;
localparam STATE_CAPTURE_IR       = 4'h4;
localparam STATE_SHIFT_IR         = 4'h5;
localparam STATE_EXIT_1_IR        = 4'h6;
localparam STATE_PAUSE_IR         = 4'h7;
localparam STATE_EXIT_2_IR        = 4'h8;
localparam STATE_UPDATE_IR        = 4'h9;
localparam STATE_CAPTURE_DR       = 4'hA;
localparam STATE_SHIFT_DR         = 4'hB;
localparam STATE_EXIT_1_DR        = 4'hC;
localparam STATE_PAUSE_DR         = 4'hD;
localparam STATE_EXIT_2_DR        = 4'hE;
localparam STATE_UPDATE_DR        = 4'hF;

always @(posedge i_tck) begin
    if(i_reset) begin
        tap_state <= STATE_TEST_LOGIC_RESET;
    end else
        case(tap_state)
            STATE_TEST_LOGIC_RESET: begin
                tap_state <= (i_tms == 1) ? STATE_TEST_LOGIC_RESET : STATE_RUN_TEST_IDLE;
            end
            STATE_RUN_TEST_IDLE: begin
                tap_state <= (i_tms == 1) ? STATE_SELECT_DR_SCAN : STATE_RUN_TEST_IDLE;
            end
            STATE_SELECT_DR_SCAN: begin
                tap_state <= (i_tms == 1) ? STATE_SELECT_IR_SCAN : STATE_CAPTURE_DR;
            end
            STATE_SELECT_IR_SCAN: begin
                tap_state <= (i_tms == 1) ? STATE_TEST_LOGIC_RESET : STATE_CAPTURE_IR;
            end
            STATE_CAPTURE_IR: begin
                tap_state <= (i_tms == 1) ? STATE_EXIT_1_IR : STATE_SHIFT_IR;
            end
            STATE_SHIFT_IR: begin
                tap_state <= (i_tms == 1) ? STATE_EXIT_1_IR : STATE_SHIFT_IR;
            end
            STATE_EXIT_1_IR: begin
                tap_state <= (i_tms == 1) ? STATE_UPDATE_IR : STATE_PAUSE_IR;
            end
            STATE_PAUSE_IR: begin
                tap_state <= (i_tms == 1) ? STATE_EXIT_2_IR : STATE_PAUSE_IR;
            end
            STATE_EXIT_2_IR: begin
                tap_state <= (i_tms == 1) ? STATE_UPDATE_IR : STATE_SHIFT_IR;
            end
            STATE_UPDATE_IR: begin
                tap_state <= (i_tms == 1) ? STATE_SELECT_DR_SCAN : STATE_RUN_TEST_IDLE;
            end
            STATE_CAPTURE_DR: begin
                tap_state <= (i_tms == 1) ? STATE_EXIT_1_DR : STATE_SHIFT_DR;
            end
            STATE_SHIFT_DR: begin
                tap_state <= (i_tms == 1) ? STATE_EXIT_1_DR : STATE_SHIFT_DR;
            end
            STATE_EXIT_1_DR: begin
                tap_state <= (i_tms == 1) ? STATE_UPDATE_DR : STATE_PAUSE_DR;
            end
            STATE_PAUSE_DR: begin
                tap_state <= (i_tms == 1) ? STATE_EXIT_2_DR : STATE_PAUSE_DR;
            end
            STATE_EXIT_2_DR: begin
                tap_state <= (i_tms == 1) ? STATE_UPDATE_DR : STATE_SHIFT_DR;
            end
            STATE_UPDATE_DR: begin
                tap_state <= (i_tms == 1) ? STATE_SELECT_DR_SCAN : STATE_RUN_TEST_IDLE;
            end
        endcase
end

localparam IR_IDCODE  = 5'h01;
localparam IR_DTMCS   = 5'h10;
localparam IR_DMI     = 5'h11;


wire IR_capture = tap_state == STATE_CAPTURE_IR;
wire IR_shift = tap_state == STATE_SHIFT_IR;
wire IR_update = tap_state == STATE_UPDATE_IR;
wire [4:0] IR_value;
wire IR_tdo;
tap_reg #(
    .REG_WIDTH(5),
    .INITIAL_VALUE(IR_IDCODE)
)
IR_Reg(
    .i_tck(i_tck),
    .i_capture(IR_capture),
    .i_shift(IR_shift),
    .i_update(IR_update),
    .i_tdi(i_tdi),
    .o_tdo(IR_tdo),
    .i_reset(tap_state == STATE_TEST_LOGIC_RESET),

    .o_debug(IR_value)
);

wire DR_capture = tap_state == STATE_CAPTURE_DR;
wire DR_shift   = tap_state == STATE_SHIFT_DR;
wire DR_update  = tap_state == STATE_UPDATE_DR;

wire BYPASS_selected = IR_value >= 5'h12 || IR_value == 5'h0;
wire BYPASS_capture  = BYPASS_selected && DR_capture;
wire BYPASS_shift    = BYPASS_selected && DR_shift;
wire BYPASS_update   = BYPASS_selected && DR_update;
wire BYPASS_tdo;

tap_reg #(
    .REG_WIDTH(1)
)
BYPASS_Reg(
    .i_tck(i_tck),
    .i_capture(BYPASS_capture),
    .i_shift(BYPASS_shift),
    .i_update(BYPASS_update),
    .i_tdi(i_tdi),
    .o_tdo(BYPASS_tdo),
    .i_reset(tap_state == STATE_TEST_LOGIC_RESET),

    .o_debug()
);

wire IDCODE_selected = IR_value == IR_IDCODE;
wire IDCODE_capture  = IDCODE_selected && DR_capture;
wire IDCODE_shift    = IDCODE_selected && DR_shift;
wire IDCODE_tdo;
tap_reg #(
    .REG_WIDTH(32),
    .INITIAL_VALUE(32'h0B1B0001)
)
IDCODE_Reg(
    .i_tck(i_tck),
    .i_capture(IDCODE_capture),
    .i_shift(IDCODE_shift),
    .i_update(1'b0),
    .i_tdi(i_tdi),
    .o_tdo(IDCODE_tdo),
    .i_reset(tap_state == STATE_TEST_LOGIC_RESET),

    .o_debug()
);

wire DMI_selected = IR_value == IR_DMI;
wire DMI_capture  = DMI_selected && DR_capture;
wire DMI_shift    = DMI_selected && DR_shift;
wire DMI_update   = DMI_selected && DR_update;
wire DMI_tdo;

wire dtm_reset;
wire dtm_clear_sticky;
dmi DMI_Reg(
    .i_tck(i_tck),
    .i_capture(DMI_capture),
    .i_shift(DMI_shift),
    .i_update(DMI_update),
    .i_tdi(i_tdi),
    .o_tdo(DMI_tdo),

    .i_reset(dtm_reset),
    .i_clear_sticky(dtm_clear_sticky),

    .o_dmi_req_valid(o_dmi_req_valid),
    .i_dmi_req_ready(i_dmi_req_ready),
    .o_dmi_req_address(o_dmi_req_address),
    .o_dmi_req_data(o_dmi_req_data),
    .o_dmi_req_op(o_dmi_req_op),
    .i_dmi_rsp_valid(i_dmi_rsp_valid),
    .o_dmi_rsp_ready(o_dmi_rsp_ready),
    .i_dmi_rsp_data(i_dmi_rsp_data),
    .i_dmi_rsp_op(i_dmi_rsp_op)
);

wire DTMCS_selected = IR_value == IR_DTMCS;
wire DTMCS_capture  = DTMCS_selected && DR_capture;
wire DTMCS_shift    = DTMCS_selected && DR_shift;
wire DTMCS_update   = DTMCS_selected && DR_update;
wire DTMCS_tdo;
dtmcs DTMCS_Reg(
    .i_tck(i_tck),
    .i_capture(DTMCS_capture),
    .i_shift(DTMCS_shift),
    .i_update(DTMCS_update),
    .i_tdi(i_tdi),
    .o_tdo(DTMCS_tdo),

    .i_dmi_op(o_dmi_req_op),
    .o_dtm_reset(dtm_reset),
    .o_dtm_clear_sticky(dtm_clear_sticky)
);

always @ * begin
    if(tap_state < STATE_CAPTURE_DR)
        o_tdo = IR_tdo;
    else
        case(IR_value)
            IR_IDCODE:  o_tdo = IDCODE_tdo;
            IR_DTMCS :  o_tdo = DTMCS_tdo ;
            IR_DMI   :  o_tdo = DMI_tdo   ;
            default: o_tdo = BYPASS_tdo;
        endcase
end

endmodule
