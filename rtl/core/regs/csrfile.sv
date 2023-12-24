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
        12'hB03, 12'hB04, 12'hB05, 12'hB06, 12'hB07, 12'hB08,
        12'hB09, 12'hB0A, 12'hB0B, 12'hB0C, 12'hB0D, 12'hB0E,
        12'hB0F: begin end
        12'h7B0: begin if(!i_halted) o_trap <= 1'b1; end
        12'h7B1: begin if(!i_halted) o_trap <= 1'b1; end
        default: begin
            o_trap <= 1'b1;
        end
    endcase
end

always @(negedge i_clk) begin
    if(i_reset) begin
        mstatus_mie <= 1'b0;
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
            12'h300: o_data <= {56'h0, mstatus_mpie, 3'h0, mstatus_mie, 3'h0};
            12'h301: o_data <= 64'h8000000000000104;
            12'h304: o_data <= {56'h0, mtie, 7'h0};
            12'h305: o_data <= mtvec;
            12'h340: o_data <= mscratch;
            12'h341: o_data <= mepc;
            12'h342: o_data <= mcause;
            12'h343: o_data <= mtval;
            12'h344: o_data <= {56'h0, mtip, 7'h0};
            12'h7B0: o_data <= {32'h0, 4'h4, 19'h0, dcsr_cause, 3'h0, dcsr_step, 2'h3};
            12'h7B1: o_data <= dpc_value;
            default: begin end
        endcase
    end
end

endmodule