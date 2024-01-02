`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 02.12.2023 17:44:00
// Design Name:
// Module Name: csrfile
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

module csrfile(
    input i_clk,
    input i_reset,

    input [11:0]      i_ld_csr,
    input [11:0]      i_st_csr,
    input [63:0]      i_data,
    output reg [63:0] o_data,
    input             i_ld,
    input             i_st,

    output reg        o_trap,

    output [63:0]     o_mtvec,
    output [63:0]     o_mcause,
    output [63:0]     o_mepc,
    input  [63:0]     i_mepc_data,
    input             i_mepc_we,
    input  [63:0]     i_mcause_data,
    input             i_mcause_we,
    output [63:0]     o_mie,
    output            o_mstatus_mie,
    output [63:0]     o_mip,
    input             i_mie_clear,
    input             i_mie_restore,
    output [63:0]     o_mtime,
    output [63:0]     o_mtimecmp,
    input  [63:0]     i_mtime,
    input  [63:0]     i_mtimecmp,
    input             i_mtime_we,
    input             i_mtimecmp_we,

    output pmp_cfg_t  o_pmp_cfg[16],
    output [55:0]     o_pmp_addr[16],

    //Debug Mode
    input  [63:0]     i_debug_PC,
    output [63:0]     o_dpc,
    input             i_halted
);

reg [63:0] mtvec;
reg [63:0] mscratch;
reg [63:0] mepc;
reg [63:0] mcause;
reg [63:0] mtval;

reg [63:0] mtime;
reg [63:0] mtimecmp;
assign o_mtime = mtime;
assign o_mtimecmp = mtimecmp;

//Debug Mode
reg [2:0] dcsr_cause;
reg       dcsr_step;

reg halted_latch;

reg [63:0] dpc_value;
assign o_dpc = dpc_value;

reg mstatus_mpie;
reg mstatus_mie;
assign o_mstatus_mie = mstatus_mie;

wire mtip = mtime >= mtimecmp;
reg mtie;

assign o_mie = {56'h0, mtie, 7'h0};
assign o_mip = {56'h0, mtip, 7'h0};

assign o_mtvec = mtvec;
assign o_mepc = mepc;
assign o_mcause = mcause;


pmp_cfg_t  pmp_cfg[16];
assign o_pmp_cfg = pmp_cfg;
reg [55:0] pmp_addr[16];
assign o_pmp_addr = pmp_addr;

initial begin
    o_trap = 1'b0;
    o_data = 64'h0;

    mtie = 1'b0;

    mtvec       = 64'h0;
    mscratch    = 64'h0;
    mepc        = 64'h0;
    mcause      = 64'h0;
    mtval       = 64'h0;
    mtime       = 64'h0;
    mtimecmp    = 64'h0;

    dcsr_step = 1'h0;
    dcsr_cause = 3'h0;

    dpc_value = 64'h0;
    halted_latch = 1'b0;

    mstatus_mpie = 1'b0;
    mstatus_mie = 1'b0;

    for(int i = 0; i < 16; i++) begin
        pmp_cfg[i].lock = 1'b0;
        pmp_cfg[i].mode = PMP_MODE_OFF;
        pmp_cfg[i].exec = 1'b0;
        pmp_cfg[i].write = 1'b0;
        pmp_cfg[i].read = 1'b0;

        pmp_addr[i] = 56'h0;
    end
end

always @(i_ld_csr) begin
    o_trap <= 1'b0;

    case(i_ld_csr)
        12'h300: begin end
        12'h301: begin end
        12'h304: begin end
        12'h305: begin end
        12'h323, 12'h324, 12'h325, 12'h326, 12'h327, 12'h328,
        12'h329, 12'h32A, 12'h32B, 12'h32C, 12'h32D, 12'h32E,
        12'h32F: begin end
        12'h340: begin end
        12'h341: begin end
        12'h342: begin end
        12'h343: begin end
        12'h344: begin end
        12'h3A0,
        12'h3A2: begin end
        12'h3B0, 12'h3B1, 12'h3B2, 12'h3B3, 12'h3B4, 12'h3B5, 12'h3B6, 12'h3B7,
        12'h3B8, 12'h3B9, 12'h3BA, 12'h3BB, 12'h3BC, 12'h3BD, 12'h3BE,
        12'h3BF: begin end
        12'hB03, 12'hB04, 12'hB05, 12'hB06, 12'hB07, 12'hB08,
        12'hB09, 12'hB0A, 12'hB0B, 12'hB0C, 12'hB0D, 12'hB0E,
        12'hB0F: begin end
        12'h7B0: begin if(!i_halted) o_trap <= 1'b1; end
        12'h7B1: begin if(!i_halted) o_trap <= 1'b1; end
        12'hF11, 12'hF12, 12'hF13, 12'hF14,
        12'hF15: begin end
        default: begin
            o_trap <= 1'b1;
        end
    endcase
end

always @(negedge i_clk) begin
    if(i_reset) begin
        mstatus_mie <= 1'b0;
        pmp_cfg[ 0] <= pmp_cfg_t'(6'h0); pmp_cfg[ 1] <= pmp_cfg_t'(6'h0); pmp_cfg[ 2] <= pmp_cfg_t'(6'h0); pmp_cfg[ 3] <= pmp_cfg_t'(6'h0);
        pmp_cfg[ 4] <= pmp_cfg_t'(6'h0); pmp_cfg[ 5] <= pmp_cfg_t'(6'h0); pmp_cfg[ 6] <= pmp_cfg_t'(6'h0); pmp_cfg[ 7] <= pmp_cfg_t'(6'h0);
        pmp_cfg[ 8] <= pmp_cfg_t'(6'h0); pmp_cfg[ 9] <= pmp_cfg_t'(6'h0); pmp_cfg[10] <= pmp_cfg_t'(6'h0); pmp_cfg[11] <= pmp_cfg_t'(6'h0);
        pmp_cfg[12] <= pmp_cfg_t'(6'h0); pmp_cfg[13] <= pmp_cfg_t'(6'h0); pmp_cfg[14] <= pmp_cfg_t'(6'h0); pmp_cfg[15] <= pmp_cfg_t'(6'h0);
        //TODO: Add more regs here
    end else begin
        if(i_st) begin //Update outputs on store request
            case(i_st_csr)
                12'h300: begin
                    mstatus_mie <= i_data[3:3];
                    mstatus_mpie <= i_data[7:7];
                end
                12'h304: mtie       <= i_data[7:7];
                12'h305: mtvec      <= i_data;
                12'h340: mscratch   <= i_data;
                12'h341: mepc       <= {i_data[63:1], 1'h0};
                12'h342: mcause     <= i_data;
                12'h343: mtval      <= i_data;
                12'h3A0: begin
                    if(!pmp_cfg[0].lock) begin pmp_cfg[0].lock  <= i_data[ 7: 7]; pmp_cfg[0].mode  <= pmp_cfg_mode_t'(i_data[ 4: 3]); pmp_cfg[0].exec  <= i_data[ 2: 2]; pmp_cfg[0].write <= i_data[ 1: 1]; pmp_cfg[0].read  <= i_data[ 0: 0]; end
                    if(!pmp_cfg[1].lock) begin pmp_cfg[1].lock  <= i_data[15:15]; pmp_cfg[1].mode  <= pmp_cfg_mode_t'(i_data[12:11]); pmp_cfg[1].exec  <= i_data[10:10]; pmp_cfg[1].write <= i_data[ 9: 9]; pmp_cfg[1].read  <= i_data[ 8: 8]; end
                    if(!pmp_cfg[2].lock) begin pmp_cfg[2].lock  <= i_data[23:23]; pmp_cfg[2].mode  <= pmp_cfg_mode_t'(i_data[20:19]); pmp_cfg[2].exec  <= i_data[18:18]; pmp_cfg[2].write <= i_data[17:17]; pmp_cfg[2].read  <= i_data[16:16]; end
                    if(!pmp_cfg[3].lock) begin pmp_cfg[3].lock  <= i_data[31:31]; pmp_cfg[3].mode  <= pmp_cfg_mode_t'(i_data[28:27]); pmp_cfg[3].exec  <= i_data[26:26]; pmp_cfg[3].write <= i_data[25:25]; pmp_cfg[3].read  <= i_data[24:24]; end
                    if(!pmp_cfg[4].lock) begin pmp_cfg[4].lock  <= i_data[39:39]; pmp_cfg[4].mode  <= pmp_cfg_mode_t'(i_data[36:35]); pmp_cfg[4].exec  <= i_data[34:34]; pmp_cfg[4].write <= i_data[33:33]; pmp_cfg[4].read  <= i_data[32:32]; end
                    if(!pmp_cfg[5].lock) begin pmp_cfg[5].lock  <= i_data[47:47]; pmp_cfg[5].mode  <= pmp_cfg_mode_t'(i_data[44:43]); pmp_cfg[5].exec  <= i_data[42:42]; pmp_cfg[5].write <= i_data[41:41]; pmp_cfg[5].read  <= i_data[40:40]; end
                    if(!pmp_cfg[6].lock) begin pmp_cfg[6].lock  <= i_data[55:55]; pmp_cfg[6].mode  <= pmp_cfg_mode_t'(i_data[52:51]); pmp_cfg[6].exec  <= i_data[50:50]; pmp_cfg[6].write <= i_data[49:49]; pmp_cfg[6].read  <= i_data[48:48]; end
                    if(!pmp_cfg[7].lock) begin pmp_cfg[7].lock  <= i_data[63:63]; pmp_cfg[7].mode  <= pmp_cfg_mode_t'(i_data[60:59]); pmp_cfg[7].exec  <= i_data[58:58]; pmp_cfg[7].write <= i_data[57:57]; pmp_cfg[7].read  <= i_data[56:56]; end
                end
                12'h3A2: begin
                    if(!pmp_cfg[ 8].lock) begin pmp_cfg[ 8].lock  <= i_data[ 7: 7]; pmp_cfg[ 8].mode  <= pmp_cfg_mode_t'(i_data[ 4: 3]); pmp_cfg[ 8].exec  <= i_data[ 2: 2]; pmp_cfg[ 8].write <= i_data[ 1: 1]; pmp_cfg[ 8].read  <= i_data[ 0: 0]; end
                    if(!pmp_cfg[ 9].lock) begin pmp_cfg[ 9].lock  <= i_data[15:15]; pmp_cfg[ 9].mode  <= pmp_cfg_mode_t'(i_data[12:11]); pmp_cfg[ 9].exec  <= i_data[10:10]; pmp_cfg[ 9].write <= i_data[ 9: 9]; pmp_cfg[ 9].read  <= i_data[ 8: 8]; end
                    if(!pmp_cfg[10].lock) begin pmp_cfg[10].lock  <= i_data[23:23]; pmp_cfg[10].mode  <= pmp_cfg_mode_t'(i_data[20:19]); pmp_cfg[10].exec  <= i_data[18:18]; pmp_cfg[10].write <= i_data[17:17]; pmp_cfg[10].read  <= i_data[16:16]; end
                    if(!pmp_cfg[11].lock) begin pmp_cfg[11].lock  <= i_data[31:31]; pmp_cfg[11].mode  <= pmp_cfg_mode_t'(i_data[28:27]); pmp_cfg[11].exec  <= i_data[26:26]; pmp_cfg[11].write <= i_data[25:25]; pmp_cfg[11].read  <= i_data[24:24]; end
                    if(!pmp_cfg[12].lock) begin pmp_cfg[12].lock  <= i_data[39:39]; pmp_cfg[12].mode  <= pmp_cfg_mode_t'(i_data[36:35]); pmp_cfg[12].exec  <= i_data[34:34]; pmp_cfg[12].write <= i_data[33:33]; pmp_cfg[12].read  <= i_data[32:32]; end
                    if(!pmp_cfg[13].lock) begin pmp_cfg[13].lock  <= i_data[47:47]; pmp_cfg[13].mode  <= pmp_cfg_mode_t'(i_data[44:43]); pmp_cfg[13].exec  <= i_data[42:42]; pmp_cfg[13].write <= i_data[41:41]; pmp_cfg[13].read  <= i_data[40:40]; end
                    if(!pmp_cfg[14].lock) begin pmp_cfg[14].lock  <= i_data[55:55]; pmp_cfg[14].mode  <= pmp_cfg_mode_t'(i_data[52:51]); pmp_cfg[14].exec  <= i_data[50:50]; pmp_cfg[14].write <= i_data[49:49]; pmp_cfg[14].read  <= i_data[48:48]; end
                    if(!pmp_cfg[15].lock) begin pmp_cfg[15].lock  <= i_data[63:63]; pmp_cfg[15].mode  <= pmp_cfg_mode_t'(i_data[60:59]); pmp_cfg[15].exec  <= i_data[58:58]; pmp_cfg[15].write <= i_data[57:57]; pmp_cfg[15].read  <= i_data[56:56]; end
                end
                12'h3B0, 12'h3B1, 12'h3B2, 12'h3B3, 12'h3B4, 12'h3B5, 12'h3B6, 12'h3B7,
                12'h3B8, 12'h3B9, 12'h3BA, 12'h3BB, 12'h3BC, 12'h3BD, 12'h3BE,
                12'h3BF: begin
                    pmp_addr[i_st_csr[3:0]] <= {i_data[53:0], 2'h0};
                end
                12'h7B0: begin
                    if(i_halted) dcsr_step <= i_data[2:2];
                end
                12'h7B1: begin
                    if(i_halted) dpc_value <= i_data;
                end
                default: begin

                end
            endcase
        end

        if(!halted_latch && i_halted) begin
            dcsr_cause <= 3'h3;
            dpc_value <= i_debug_PC;
        end
        halted_latch <= i_halted;

        if(i_mepc_we) begin
            mepc <= i_mepc_data;
        end
        if(i_mcause_we) begin
            mcause <= i_mcause_data;
        end

        if(i_mtimecmp_we)
            mtimecmp <= i_mtimecmp;

        if(i_mtime_we) begin
            mtime <= i_mtime;
        end else begin
            mtime <= mtime + 1;
        end

        if(i_mie_clear) begin
            mstatus_mie <= 1'b0;
            mstatus_mpie <= mstatus_mie;
        end else if(i_mie_restore) begin
            mstatus_mie <= mstatus_mpie;
        end
    end
end

always @(negedge i_clk) begin
    if(i_ld) begin //Update outputs on load request
        o_data <= 64'h0;

        case(i_ld_csr)
            12'h300: o_data <= {51'h0, 2'h3, 3'h0, mstatus_mpie, 3'h0, mstatus_mie, 3'h0};
            12'h301: o_data <= 64'h8000000000000104;
            12'h304: o_data <= {56'h0, mtie, 7'h0};
            12'h305: o_data <= mtvec;
            12'h340: o_data <= mscratch;
            12'h341: o_data <= mepc;
            12'h342: o_data <= mcause;
            12'h343: o_data <= mtval;
            12'h344: o_data <= {56'h0, mtip, 7'h0};
            12'h3A0: begin
                o_data[ 7: 7] <= pmp_cfg[0].lock; o_data[ 4: 3] <= pmp_cfg[0].mode; o_data[ 2: 2] <= pmp_cfg[0].exec; o_data[ 1: 1] <= pmp_cfg[0].write; o_data[ 0: 0] <= pmp_cfg[0].read;
                o_data[15:15] <= pmp_cfg[1].lock; o_data[12:11] <= pmp_cfg[1].mode; o_data[10:10] <= pmp_cfg[1].exec; o_data[ 9: 9] <= pmp_cfg[1].write; o_data[ 8: 8] <= pmp_cfg[1].read;
                o_data[23:23] <= pmp_cfg[2].lock; o_data[20:19] <= pmp_cfg[2].mode; o_data[18:18] <= pmp_cfg[2].exec; o_data[17:17] <= pmp_cfg[2].write; o_data[16:16] <= pmp_cfg[2].read;
                o_data[31:31] <= pmp_cfg[3].lock; o_data[28:27] <= pmp_cfg[3].mode; o_data[26:26] <= pmp_cfg[3].exec; o_data[25:25] <= pmp_cfg[3].write; o_data[24:24] <= pmp_cfg[3].read;
                o_data[39:39] <= pmp_cfg[4].lock; o_data[36:35] <= pmp_cfg[4].mode; o_data[34:34] <= pmp_cfg[4].exec; o_data[33:33] <= pmp_cfg[4].write; o_data[32:32] <= pmp_cfg[4].read;
                o_data[47:47] <= pmp_cfg[5].lock; o_data[44:43] <= pmp_cfg[5].mode; o_data[42:42] <= pmp_cfg[5].exec; o_data[41:41] <= pmp_cfg[5].write; o_data[40:40] <= pmp_cfg[5].read;
                o_data[55:55] <= pmp_cfg[6].lock; o_data[52:51] <= pmp_cfg[6].mode; o_data[50:50] <= pmp_cfg[6].exec; o_data[49:49] <= pmp_cfg[6].write; o_data[48:48] <= pmp_cfg[6].read;
                o_data[63:63] <= pmp_cfg[7].lock; o_data[60:59] <= pmp_cfg[7].mode; o_data[58:58] <= pmp_cfg[7].exec; o_data[57:57] <= pmp_cfg[7].write; o_data[56:56] <= pmp_cfg[7].read;
            end
            12'h3A2: begin
                o_data[ 7: 7] <= pmp_cfg[ 8].lock; o_data[ 4: 3] <= pmp_cfg[ 8].mode; o_data[ 2: 2] <= pmp_cfg[ 8].exec; o_data[ 1: 1] <= pmp_cfg[ 8].write; o_data[ 0: 0] <= pmp_cfg[ 8].read;
                o_data[15:15] <= pmp_cfg[ 9].lock; o_data[12:11] <= pmp_cfg[ 9].mode; o_data[10:10] <= pmp_cfg[ 9].exec; o_data[ 9: 9] <= pmp_cfg[ 9].write; o_data[ 8: 8] <= pmp_cfg[ 9].read;
                o_data[23:23] <= pmp_cfg[10].lock; o_data[20:19] <= pmp_cfg[10].mode; o_data[18:18] <= pmp_cfg[10].exec; o_data[17:17] <= pmp_cfg[10].write; o_data[16:16] <= pmp_cfg[10].read;
                o_data[31:31] <= pmp_cfg[11].lock; o_data[28:27] <= pmp_cfg[11].mode; o_data[26:26] <= pmp_cfg[11].exec; o_data[25:25] <= pmp_cfg[11].write; o_data[24:24] <= pmp_cfg[11].read;
                o_data[39:39] <= pmp_cfg[12].lock; o_data[36:35] <= pmp_cfg[12].mode; o_data[34:34] <= pmp_cfg[12].exec; o_data[33:33] <= pmp_cfg[12].write; o_data[32:32] <= pmp_cfg[12].read;
                o_data[47:47] <= pmp_cfg[13].lock; o_data[44:43] <= pmp_cfg[13].mode; o_data[42:42] <= pmp_cfg[13].exec; o_data[41:41] <= pmp_cfg[13].write; o_data[40:40] <= pmp_cfg[13].read;
                o_data[55:55] <= pmp_cfg[14].lock; o_data[52:51] <= pmp_cfg[14].mode; o_data[50:50] <= pmp_cfg[14].exec; o_data[49:49] <= pmp_cfg[14].write; o_data[48:48] <= pmp_cfg[14].read;
                o_data[63:63] <= pmp_cfg[15].lock; o_data[60:59] <= pmp_cfg[15].mode; o_data[58:58] <= pmp_cfg[15].exec; o_data[57:57] <= pmp_cfg[15].write; o_data[56:56] <= pmp_cfg[15].read;
            end
            12'h3B0, 12'h3B1, 12'h3B2, 12'h3B3, 12'h3B4, 12'h3B5, 12'h3B6, 12'h3B7,
            12'h3B8, 12'h3B9, 12'h3BA, 12'h3BB, 12'h3BC, 12'h3BD, 12'h3BE,
            12'h3BF: begin
                o_data <= {10'h0, pmp_addr[i_st_csr[3:0]][55:2]};
            end
            12'h7B0: o_data <= {32'h0, 4'h4, 19'h0, dcsr_cause, 3'h0, dcsr_step, 2'h3};
            12'h7B1: o_data <= dpc_value;
            12'hF12: o_data <= 64'h26; //Temp value, needs to be approved
            12'hF13: o_data <= {32'h1, 32'h0}; //High 32: Version, Low 32: Sub-version(fixes o minimal changes)
            default: begin end
        endcase
    end
end

endmodule