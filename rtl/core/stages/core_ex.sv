`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 18.11.2023 17:16:48
// Design Name:
// Module Name: core_ex
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

module core_ex(
    input i_clk,
    input i_reset,

    input  ID_EX_t  i_ID_EX,
    output EX_MEM_t o_EX_MEM,

    input  i_stall,
    input  i_flush,
    output o_dependency
);

EX_MEM_t EX_MEM;
assign o_EX_MEM = EX_MEM;
wire [6:0] opcode = i_ID_EX.opcode;
wire is_compressed = opcode[1:0] != 2'b11;
wire [63:0] dat_a = i_ID_EX.dat_a;
wire [63:0] dat_b = i_ID_EX.dat_b;
wire op_32bit = opcode == OP_32 || opcode == OP_IMM_32;

initial begin
    EX_MEM.valid = 0;
    EX_MEM.PC = 64'h0;
    EX_MEM.funct3 = 3'h0;
    EX_MEM.funct5 = 5'h0;
    EX_MEM.data = 64'h0;
    EX_MEM.addr = 64'h0;
    EX_MEM.rd = 5'h0;
    EX_MEM.we = 1'b0;
    EX_MEM.ld = 1'b0;
    EX_MEM.st = 1'b0;
    EX_MEM.csr = 12'h0;
    EX_MEM.csr_data = 64'h0;
    EX_MEM.csr_st = 1'b0;
    EX_MEM.amo = 1'b0;
end

assign o_dependency = 1'b0;

always @(posedge i_clk) begin
    if(i_reset) begin
        EX_MEM.valid <= 1'b0;
        EX_MEM.PC <= 64'h0;
        EX_MEM.funct3 <= 3'h0;
        EX_MEM.funct5 <= 5'h0;
        EX_MEM.data <= 64'h0;
        EX_MEM.addr <= 64'h0;
        EX_MEM.rd <= 5'h0;
        EX_MEM.we <= 1'b0;
        EX_MEM.ld <= 1'b0;
        EX_MEM.st <= 1'b0;
        EX_MEM.csr <= 12'h0;
        EX_MEM.csr_data <= 64'h0;
        EX_MEM.csr_st <= 1'b0;
        EX_MEM.amo <= 1'b0;
    end
    else if(i_flush) begin
        EX_MEM.valid <= 1'b0;
        EX_MEM.PC <= 64'h0;
        EX_MEM.funct3 <= 3'h0;
        EX_MEM.funct5 <= 5'h0;
        EX_MEM.data <= 64'h0;
        EX_MEM.addr <= 64'h0;
        EX_MEM.rd <= 5'h0;
        EX_MEM.we <= 1'b0;
        EX_MEM.ld <= 1'b0;
        EX_MEM.st <= 1'b0;
        EX_MEM.csr <= 12'h0;
        EX_MEM.csr_data <= 64'h0;
        EX_MEM.csr_st <= 1'b0;
        EX_MEM.amo <= 1'b0;
    end
    else begin
        if(!i_stall) begin
            EX_MEM.valid <= i_ID_EX.valid && !i_stall;

            EX_MEM.rd <= 5'h0;
            EX_MEM.we <= 1'b0;
            EX_MEM.funct3 <= 3'h0;
            EX_MEM.funct5 <= 5'h0;
            EX_MEM.data <= 64'h0;
            EX_MEM.addr <= 64'h0;
            EX_MEM.ld <= 1'b0;
            EX_MEM.st <= 1'b0;
            EX_MEM.csr <= 12'h0;
            EX_MEM.csr_data <= 64'h0;
            EX_MEM.csr_st <= 1'b0;
            EX_MEM.amo <= 1'b0;

            if(i_ID_EX.valid) begin
                if(opcode == OP_IMM || opcode == OP || opcode == OP_IMM_32 || opcode == OP_32) begin
                    case(i_ID_EX.funct3)
                        ADDI: begin
                            if(!op_32bit)
                                if(opcode == OP && i_ID_EX.funct7[5:5])
                                    EX_MEM.data <= dat_a - dat_b;
                                else
                                    EX_MEM.data <= dat_a + dat_b;
                            else //ADDIW
                                if(opcode == OP && i_ID_EX.funct7[5:5])
                                    EX_MEM.data <= 64'($signed(dat_a[31:0] - dat_b[31:0]));
                                else
                                    EX_MEM.data <= 64'($signed(dat_a[31:0] + dat_b[31:0]));
                        end
                        SLTI:   EX_MEM.data <= ($signed(dat_a) < $signed(dat_b)) ? 64'h1 : 64'h0;
                        SLTIU:  EX_MEM.data <= (dat_a < dat_b) ? 64'h1 : 64'h0;
                        ANDI:   EX_MEM.data <= dat_a & dat_b;
                        ORI:    EX_MEM.data <= dat_a | dat_b;
                        XORI:   EX_MEM.data <= dat_a ^ dat_b;
                        SLLI:   EX_MEM.data <= dat_a << dat_b[5:0];
                        SRLI_SRAI: begin
                            if(!op_32bit) //SRAI
                                if(i_ID_EX.funct7[5:5])
                                    EX_MEM.data <= $signed(dat_a) >>> dat_b[5:0];
                                else
                                    EX_MEM.data <= dat_a >> dat_b[5:0];
                            else
                                if(i_ID_EX.funct7[5:5]) //SRAIW
                                    EX_MEM.data <= 64'($signed($signed(dat_a[31:0]) >>> dat_b[4:0]));
                                else
                                    EX_MEM.data <= 64'($signed(dat_a[31:0] >> dat_b[5:0]));
                        end
                        default: begin
                            EX_MEM.valid <= 1'b0;
                        end
                    endcase
                //TODO: FP Operations
                end else if(opcode == SYSTEM) begin
                    EX_MEM.data <= dat_b;

                    case(i_ID_EX.funct3)
                        CSRRW, CSRRWI: begin
                            EX_MEM.csr_data <= dat_a;
                        end
                        CSRRC, CSRRCI: begin
                            EX_MEM.csr_data <= dat_b & ~dat_a;
                        end
                        CSRRS, CSRRSI: begin
                            EX_MEM.csr_data <= dat_b | dat_a;
                        end
                        default: begin
                            EX_MEM.csr_data <= dat_a + dat_b;
                        end
                    endcase
                end else if(is_compressed) begin
                    EX_MEM.data <= dat_a;

                    case(opcode[1:0])
                        C1: begin
                            if(i_ID_EX.funct3 == C_ADDIW)
                                EX_MEM.data <= 64'($signed(dat_a[31:0] + dat_b[31:0]));
                            else if(i_ID_EX.funct3 == C_ALU) begin
                                if(i_ID_EX.funct7[1:0] != 2'b11) begin
                                    case(i_ID_EX.funct7[1:0])
                                        2'b00: EX_MEM.data <= dat_a >> dat_b[5:0];
                                        2'b01: EX_MEM.data <= $signed(dat_a) >>> dat_b[5:0];
                                        2'b10: EX_MEM.data <= dat_a & dat_b;
                                        default: EX_MEM.data <= 64'h0;
                                    endcase
                                end else begin
                                    case(i_ID_EX.funct7[4:2])
                                        3'b000: EX_MEM.data <= dat_a - dat_b;
                                        3'b001: EX_MEM.data <= dat_a ^ dat_b;
                                        3'b010: EX_MEM.data <= dat_a | dat_b;
                                        3'b011: EX_MEM.data <= dat_a & dat_b;
                                        3'b100: EX_MEM.data <= 64'($signed(dat_a[31:0] - dat_b[31:0]));
                                        3'b101: EX_MEM.data <= 64'($signed(dat_a[31:0] + dat_b[31:0]));
                                        default: EX_MEM.data <= 64'h0;
                                    endcase
                                end
                            end
                            else
                                EX_MEM.data <= dat_a + dat_b;
                        end
                        C2: begin
                            case(i_ID_EX.funct3)
                                C_SLLI: begin
                                    EX_MEM.data <= dat_a << dat_b[5:0];
                                end
                                default: begin
                                    EX_MEM.data <= dat_a;
                                end
                            endcase
                        end
                        default: begin end
                    endcase
                end else if(opcode != STORE && opcode != LOAD && opcode != JALR && opcode != JAL && opcode != AMO) begin
                    EX_MEM.data <= dat_a + dat_b;
                end else begin
                    EX_MEM.data <= dat_a;
                end

                EX_MEM.funct3 <= i_ID_EX.funct3;
                EX_MEM.funct5 <= i_ID_EX.funct7[6:2];
                if(is_compressed && (EX_MEM.ld || EX_MEM.st)) begin
                    case(i_ID_EX.funct3)
                        C_SWSP,
                        C_LWSP: EX_MEM.funct3 <= LW_SW;
                        C_SDSP,
                        C_LDSP: EX_MEM.funct3 <= LD_SD;
                        default: begin end
                    endcase
                end
                EX_MEM.addr <= i_ID_EX.dat_b;
                EX_MEM.rd <= i_ID_EX.rd;
                EX_MEM.we <= i_ID_EX.we;
                EX_MEM.ld <= i_ID_EX.ld;
                EX_MEM.st <= i_ID_EX.st;
                EX_MEM.csr <= i_ID_EX.csr;
                EX_MEM.csr_st <= i_ID_EX.csr_st;
                EX_MEM.amo <= i_ID_EX.amo;

                EX_MEM.PC <= i_ID_EX.PC;
            end
        end
    end
end

endmodule