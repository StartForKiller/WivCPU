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
    output reg        o_dcache_atomic,
    input             i_dcache_reserved,
    input             i_dcache_data_ready,
    input             i_dcache_ready,

    input  i_stall,
    input  i_flush,
    output o_dependency
);

MEM_WB_t MEM_WB;
assign o_MEM_WB = MEM_WB;

wire [4:0] funct5 = i_EX_MEM.funct5;
wire amo = i_EX_MEM.amo;
wire amo_lr_sc = i_EX_MEM.amo && (funct5 == LR || funct5 == SC);

reg [63:0] temp_data;

reg [2:0] state;

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
    o_dcache_atomic = 1'b0;

    temp_data = 64'h0;

    state = 3'h0;
end

assign o_dependency = (state == 3'h0 ?
                            ((i_EX_MEM.st && !i_dcache_ready) || i_EX_MEM.ld || i_EX_MEM.amo) :
                            (state == 3'h1 ?
                                (!i_dcache_data_ready || (amo && !amo_lr_sc)) :
                                (state == 3'h2 ?
                                    !i_dcache_ready :
                                    (state != 3'h4))));

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
        o_dcache_atomic <= 1'b0;

        temp_data <= 64'h0;

        state <= 3'h0;
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
        o_dcache_atomic <= 1'b0;

        temp_data <= 64'h0;

        state <= 3'h0;
    end
    else begin
        if(!i_stall) begin
            MEM_WB.valid <= i_EX_MEM.valid && !i_stall;

            MEM_WB.rd <= 5'h0;
            MEM_WB.we <= 1'b0;
            MEM_WB.data <= 64'h0;
            MEM_WB.PC <= 64'h0;
            o_dcache_atomic <= 1'b0;

            if(state == 3'h0) begin
                o_dcache_ld <= 1'b0;
                o_dcache_st <= 1'b0;
            end

            if(i_EX_MEM.valid) begin
                case(state)
                    3'h0: begin
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
                                state <= 3'h3;
                                o_dcache_ld <= 1'b0;
                            end else begin
                                state <= 3'h1;
                                o_dcache_ld <= 1'b1;
                                o_dcache_addr <= i_EX_MEM.addr;
                                o_dcache_atomic <= amo_lr_sc;
                            end
                            o_dcache_st <= 1'b0;
                        end else if(i_EX_MEM.st) begin
                            if(!i_dcache_ready) begin
                                state <= 3'h2;
                                o_dcache_st <= 1'b0;
                                temp_data <= i_EX_MEM.data;
                            end else begin
                                o_dcache_addr <= i_EX_MEM.addr;
                                o_dcache_odata <= i_EX_MEM.data;
                                o_dcache_st <= 1'b1;
                                o_dcache_atomic <= amo_lr_sc;
                                if(amo_lr_sc) state <= 3'h4;
                                else begin
                                    MEM_WB.data <= i_EX_MEM.data;
                                    MEM_WB.rd <= i_EX_MEM.rd;
                                    MEM_WB.we <= i_EX_MEM.we;
                                    MEM_WB.PC <= i_EX_MEM.PC;
                                end
                            end
                            o_dcache_ld <= 1'b0;
                        end else begin
                            o_dcache_ld <= 1'b0;
                            o_dcache_st <= 1'b0;
                        end
                    end
                    3'h1: begin
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

                            if(i_EX_MEM.amo && !amo_lr_sc) begin
                                state <= 3'h5;
                            end else begin
                                state <= 3'h0;
                                MEM_WB.rd <= i_EX_MEM.rd;
                                MEM_WB.we <= i_EX_MEM.we;
                                MEM_WB.PC <= i_EX_MEM.PC;
                            end
                        end
                        o_dcache_ld <= 1'b0;
                    end
                    3'h2: begin
                        if(i_dcache_ready) begin
                            o_dcache_st <= 1'b1;

                            o_dcache_addr <= i_EX_MEM.addr;
                            o_dcache_odata <= temp_data;

                            o_dcache_atomic <= amo_lr_sc;
                            if(amo_lr_sc) state <= 3'h4;
                            else state <= 3'h0;

                            MEM_WB.data <= amo ? MEM_WB.data : temp_data;
                            MEM_WB.rd <= i_EX_MEM.rd;
                            MEM_WB.we <= i_EX_MEM.we;
                            MEM_WB.PC <= i_EX_MEM.PC;
                        end
                    end
                    3'h3: begin
                        if(i_dcache_ready) begin
                            state <= 3'h1;
                            o_dcache_ld <= 1'b1;
                            o_dcache_atomic <= amo_lr_sc;
                            o_dcache_addr <= i_EX_MEM.addr;
                        end
                    end
                    3'h4: begin
                        MEM_WB.data <= i_dcache_reserved ? 64'h0 : 64'h1;
                        MEM_WB.rd <= i_EX_MEM.rd;
                        MEM_WB.we <= i_EX_MEM.we;
                        MEM_WB.PC <= i_EX_MEM.PC;

                        state <= 3'h0;
                        o_dcache_st <= 1'b0;
                    end
                    3'h5: begin
                        MEM_WB.data <= MEM_WB.data;

                        if(i_EX_MEM.funct3 == 3'h3) begin
                            temp_data <= i_EX_MEM.data;
                            case(funct5)
                                AMOSWAP: temp_data <= i_EX_MEM.data;
                                AMOADD : temp_data <= MEM_WB.data + i_EX_MEM.data;
                                AMOAND : temp_data <= MEM_WB.data & i_EX_MEM.data;
                                AMOOR  : temp_data <= MEM_WB.data | i_EX_MEM.data;
                                AMOXOR : temp_data <= MEM_WB.data ^ i_EX_MEM.data;
                                AMOMAX : if($signed(MEM_WB.data) > $signed(i_EX_MEM.data)) temp_data <= MEM_WB.data;
                                AMOMIN : if($signed(MEM_WB.data) < $signed(i_EX_MEM.data)) temp_data <= MEM_WB.data;
                                AMOMAXU: if(MEM_WB.data > i_EX_MEM.data) temp_data <= MEM_WB.data;
                                AMOMINU: if(MEM_WB.data < i_EX_MEM.data) temp_data <= MEM_WB.data;
                                default: begin end
                            endcase
                        end else begin
                            temp_data <= 64'($signed(i_EX_MEM.data[31:0]));
                            case(funct5)
                                AMOSWAP: temp_data <= 64'($signed(i_EX_MEM.data[31:0]));
                                AMOADD : temp_data <= 64'($signed(MEM_WB.data[31:0] + i_EX_MEM.data[31:0]));
                                AMOAND : temp_data <= 64'($signed(MEM_WB.data[31:0] & i_EX_MEM.data[31:0]));
                                AMOOR  : temp_data <= 64'($signed(MEM_WB.data[31:0] | i_EX_MEM.data[31:0]));
                                AMOXOR : temp_data <= 64'($signed(MEM_WB.data[31:0] ^ i_EX_MEM.data[31:0]));
                                AMOMAX : if($signed(MEM_WB.data[31:0]) > $signed(i_EX_MEM.data[31:0])) temp_data <= 64'($signed(MEM_WB.data[31:0]));
                                AMOMIN : if($signed(MEM_WB.data[31:0]) < $signed(i_EX_MEM.data[31:0])) temp_data <= 64'($signed(MEM_WB.data[31:0]));
                                AMOMAXU: if(MEM_WB.data[31:0] > i_EX_MEM.data[31:0]) temp_data <= 64'($signed(MEM_WB.data[31:0]));
                                AMOMINU: if(MEM_WB.data[31:0] < i_EX_MEM.data[31:0]) temp_data <= 64'($signed(MEM_WB.data[31:0]));
                                default: begin end
                            endcase
                        end
                        state <= 3'h2;
                    end
                    default: state <= 3'h0;
                endcase
            end
        end
    end
end

endmodule