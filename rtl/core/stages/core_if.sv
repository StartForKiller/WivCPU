`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 18.11.2023 17:16:48
// Design Name:
// Module Name: core_if
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

module core_if(
    input i_clk,
    input i_reset,

    output IF_ID_t o_IF_ID,
    input  ID_EX_t i_ID_EX,

    //ICACHE Interface
    output [63:0] o_icache_addr,
    input  [31:0] i_icache_data,
    input         i_icache_data_ready,

    input  [63:0] i_mtvec,
    input  [63:0] i_mcause,

    input         i_stall,
    output        o_dependency,
    input         i_halt,
    input         i_halted,
    input  [63:0] i_dpc,

    output [63:0] o_debug_PC
);

IF_ID_t IF_ID;
assign o_IF_ID = IF_ID;

reg [63:0] PC;
reg [63:0] last_PC;
assign o_debug_PC = PC;

wire [1:0] trap_mode = i_mtvec[1:0];

reg state;
reg [15:0] saved_instruction_bottom;

reg halted_latch;

initial begin
    IF_ID.valid = 0;
    IF_ID.instruction = 0;

    PC = 64'h0;
    IF_ID.PC = 64'h0;
    state = 1'b0;
    saved_instruction_bottom = 16'h0;

    halted_latch = 1'b0;
end

assign o_dependency = 1'b0;

always @(posedge i_clk) begin
    halted_latch <= i_halted;
end

always @(posedge i_clk) begin
    if(i_reset) begin
        IF_ID.valid <= 1'b0;
        PC <= 64'h0;
        IF_ID.instruction <= 32'h0;
        state <= 1'b0;
        saved_instruction_bottom <= 16'h0;
    end
    else begin
        if(!i_stall) begin
            IF_ID.valid <= i_icache_data_ready && !i_ID_EX.jmp;

            IF_ID.instruction <= 32'h13;
            IF_ID.PC <= 64'h0;

            if(halted_latch && !i_halted) begin
                IF_ID.valid <= 1'b0;
                PC <= i_dpc;
                state <= 1'b0;
            end
            else if(i_ID_EX.trap) begin
                //Handle trap
                if(trap_mode == 0 || !i_mcause[63:63]) begin
                    PC <= {i_mtvec[63:2], 2'h0};
                end
                else begin
                    PC <= {i_mtvec[63:2], 2'h0} + {i_mcause[61:0], 2'h0};
                end
                state <= 1'b0;
                IF_ID.valid <= 1'b0;
            end
            else if(i_ID_EX.jmp) begin
                PC <= i_ID_EX.dat_b;
                state <= 1'b0;
                IF_ID.valid <= 1'b0;
            end
            else if(i_halt) begin
                IF_ID.valid <= 1'b0;
            end else begin
                if(state)
                    IF_ID.valid <= 1'b0;
                if(i_icache_data_ready) begin
                    if(state) begin
                        PC <= PC + 64'h2;
                        IF_ID.instruction <= {i_icache_data[15:0], saved_instruction_bottom};

                        state <= 1'b0;
                        IF_ID.valid <= 1'b1;
                    end else if(i_icache_data[1:0] == 2'b11) begin
                        if(PC[5:0] == 6'h3E && !state) begin
                            PC <= PC + 64'h2;
                            saved_instruction_bottom <= i_icache_data[15:0];

                            state <= 1'b1;
                            IF_ID.valid <= 1'b0;
                        end else begin
                            PC <= PC + 64'h4;
                            IF_ID.instruction <= i_icache_data;
                        end
                    end else begin
                        PC <= PC + 64'h2;
                        IF_ID.instruction <= {16'h0, i_icache_data[15:0]};
                    end

                    IF_ID.PC <= PC;
                end
            end
        end
    end
end

assign o_icache_addr = PC;

endmodule