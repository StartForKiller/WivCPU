`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 18.11.2023 17:16:48
// Design Name:
// Module Name: regfile
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

module regfile(
    input i_clk,
    input i_reset,

    input [4:0]   i_sel_a,
    input [4:0]   i_sel_b,
    output [63:0] o_dat_a,
    output [63:0] o_dat_b,
    input [4:0]   i_sel_w,
    input [63:0]  i_dat_w,
    input         i_we
);

reg [63:0] Regs[31:0];

initial begin
    integer i;
    for(i = 0; i < 32; i = i + 1) begin
        Regs[i] = 64'h0;
    end
end

assign o_dat_a = (i_we && i_sel_w == i_sel_a && i_sel_a != 0) ?
                    i_dat_w :
                    Regs[i_sel_a];
assign o_dat_b = (i_sel_a == i_sel_b) ?
                    o_dat_a :
                    ((i_we && i_sel_w == i_sel_b && i_sel_b != 0) ?
                        i_dat_w :
                        Regs[i_sel_b]
                    );

always @(posedge i_clk) begin
    if(i_reset) begin
        integer i;
        for(i = 0; i < 32; i = i + 1) begin
            Regs[i] <= 64'h0;
        end
    end else if(i_we && i_sel_w != 5'h0) begin
        Regs[i_sel_w] <= i_dat_w;
    end
end

endmodule