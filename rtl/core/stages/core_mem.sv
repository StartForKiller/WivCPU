`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 18.11.2023 17:16:48
// Design Name:
// Module Name: core_mem
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

module core_mem(
    input i_clk,
    input i_reset,

    input  EX_MEM_t i_EX_MEM,
    output MEM_WB_t o_MEM_WB,

    output reg [63:0] o_dcache_addr,
    input      [63:0] i_dcache_idata,
    output reg [63:0] o_dcache_odata,
    output reg [7:0]  o_dcache_sel,
    output reg        o_dcache_st,
    output reg        o_dcache_ld,
    input             i_dcache_data_ready,
    input             i_dcache_ready,

    input  i_stall,
    input  i_flush,
    output o_dependency
);

MEM_WB_t MEM_WB;
assign o_MEM_WB = MEM_WB;

reg [1:0] state;

initial begin
    MEM_WB.valid = 0;
    MEM_WB.PC = 64'h0;
    MEM_WB.data = 64'h0;
    MEM_WB.rd = 5'h0;
    MEM_WB.we = 1'b0;
    o_dcache_addr = 64'h0;
    o_dcache_odata = 64'h0;
    o_dcache_sel = 8'h0;
    o_dcache_st = 1'b0;
    o_dcache_ld = 1'b0;
    state = 2'h0;
end

assign o_dependency = (state == 2'h0 ?
                            ((i_EX_MEM.st && !i_dcache_ready) || i_EX_MEM.ld) :
                            (state == 2'h1 ?
                                !i_dcache_data_ready :
                                (state == 2'h2 ?
                                    !i_dcache_ready :
                                    1'b1)));

always @(posedge i_clk) begin
    if(i_reset) begin
        MEM_WB.valid <= 1'b0;
        MEM_WB.PC <= 64'h0;
        MEM_WB.data <= 64'h0;
        MEM_WB.rd <= 5'h0;
        MEM_WB.we <= 1'b0;
        o_dcache_addr <= 64'h0;
        o_dcache_odata <= 64'h0;
        o_dcache_sel <= 8'h0;
        o_dcache_st <= 1'b0;
        o_dcache_ld <= 1'b0;
        state <= 2'h0;
    end
    else if(i_flush) begin
        MEM_WB.valid <= 1'b0;
        MEM_WB.PC <= 64'h0;
        MEM_WB.data <= 64'h0;
        MEM_WB.rd <= 5'h0;
        MEM_WB.we <= 1'b0;
        o_dcache_addr <= 64'h0;
        o_dcache_odata <= 64'h0;
        o_dcache_sel <= 8'h0;
        o_dcache_st <= 1'b0;
        o_dcache_ld <= 1'b0;
        state <= 2'h0;
    end
    else begin
        if(!i_stall) begin
            MEM_WB.valid <= i_EX_MEM.valid && !i_stall;

            MEM_WB.rd <= 5'h0;
            MEM_WB.we <= 1'b0;
            MEM_WB.data <= 64'h0;
            MEM_WB.PC <= 64'h0;

            if(i_EX_MEM.valid) begin
                case(state)
                    2'h0: begin
                        if(i_EX_MEM.ld || i_EX_MEM.st) begin
                            case(i_EX_MEM.funct3)
                                LBU, LB_SB: o_dcache_sel <= 8'h01;
                                LHU, LH_SH: o_dcache_sel <= 8'h03;
                                LWU, LW_SW: o_dcache_sel <= 8'h0F;
                                LD_SD:      o_dcache_sel <= 8'hFF;
                                default:    o_dcache_sel <= 8'h00;
                            endcase
                        end else begin
                            MEM_WB.data <= i_EX_MEM.data;
                            MEM_WB.rd <= i_EX_MEM.rd;
                            MEM_WB.we <= i_EX_MEM.we;
                            MEM_WB.PC <= i_EX_MEM.PC;
                        end

                        if(i_EX_MEM.ld) begin
                            if(!i_dcache_ready) begin
                                state <= 2'h3;
                                o_dcache_ld <= 1'b0;
                            end else begin
                                state <= 2'h1;
                                o_dcache_ld <= 1'b1;
                                o_dcache_addr <= i_EX_MEM.addr;
                            end
                            o_dcache_st <= 1'b0;
                        end else if(i_EX_MEM.st) begin
                            if(!i_dcache_ready) begin
                                state <= 2'h2;
                                o_dcache_st <= 1'b0;
                            end else begin
                                o_dcache_addr <= i_EX_MEM.addr;
                                o_dcache_odata <= i_EX_MEM.data;
                                o_dcache_st <= 1'b1;

                                MEM_WB.data <= i_EX_MEM.data;
                                MEM_WB.rd <= i_EX_MEM.rd;
                                MEM_WB.we <= i_EX_MEM.we;
                                MEM_WB.PC <= i_EX_MEM.PC;
                            end
                            o_dcache_ld <= 1'b0;
                        end else begin
                            o_dcache_ld <= 1'b0;
                            o_dcache_st <= 1'b0;
                        end
                    end
                    2'h1: begin
                        if(i_dcache_data_ready) begin
                            case(i_EX_MEM.funct3)
                                LB_SB:      MEM_WB.data <= 64'($signed(i_dcache_idata[7:0]));
                                LH_SH:      MEM_WB.data <= 64'($signed(i_dcache_idata[15:0]));
                                LW_SW:      MEM_WB.data <= 64'($signed(i_dcache_idata[31:0]));
                                LD_SD:      MEM_WB.data <= i_dcache_idata;
                                LBU:        MEM_WB.data <= 64'(i_dcache_idata[7:0]);
                                LHU:        MEM_WB.data <= 64'(i_dcache_idata[15:0]);
                                LWU:        MEM_WB.data <= 64'(i_dcache_idata[31:0]);
                                default:    MEM_WB.data <= 64'h0;
                            endcase

                            o_dcache_addr <= 64'h0;

                            state <= 2'h0;
                            MEM_WB.rd <= i_EX_MEM.rd;
                            MEM_WB.we <= i_EX_MEM.we;
                            MEM_WB.PC <= i_EX_MEM.PC;
                        end
                        o_dcache_ld <= 1'b0;
                    end
                    2'h2: begin
                        if(i_dcache_ready) begin
                            o_dcache_st <= 1'b1;

                            o_dcache_addr <= i_EX_MEM.addr;
                            o_dcache_odata <= i_EX_MEM.data;

                            state <= 2'h0;
                            MEM_WB.data <= i_EX_MEM.data;
                            MEM_WB.rd <= i_EX_MEM.rd;
                            MEM_WB.we <= i_EX_MEM.we;
                            MEM_WB.PC <= i_EX_MEM.PC;
                        end
                    end
                    2'h3: begin
                        if(i_dcache_ready) begin
                            state <= 2'h1;
                            o_dcache_ld <= 1'b1;
                            o_dcache_addr <= i_EX_MEM.addr;
                        end
                    end
                endcase
            end
        end
    end
end

endmodule