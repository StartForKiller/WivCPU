`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 03.11.2023 14:52:13
// Design Name:
// Module Name: rom
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


module seg7(
    input        i_clk,
    input [15:0] i_data,
    output [7:0] o_seg,
    output [3:0] o_sel
);

localparam data_0 = 8'b00111111;
localparam data_1 = 8'b00000110;
localparam data_2 = 8'b01011011;
localparam data_3 = 8'b01001111;
localparam data_4 = 8'b01100110;
localparam data_5 = 8'b01101101;
localparam data_6 = 8'b01111101;
localparam data_7 = 8'b00000111;
localparam data_8 = 8'b01111111;
localparam data_9 = 8'b01101111;
localparam data_A = 8'b01110111;
localparam data_B = 8'b01111100;
localparam data_C = 8'b00111001;
localparam data_D = 8'b01011110;
localparam data_E = 8'b01111001;
localparam data_F = 8'b01110001;

reg [1:0] count;
always @(posedge i_clk) begin
    count <= count + 1;
end

assign o_sel = ~((count != 0) ? ((count != 1) ? ((count != 2) ? 4'b1000 : 4'b0100) : 4'b0010) : 4'b0001);

function [7:0] segment_sel(input [3:0] code);
    case(code)
        4'h0: segment_sel = ~data_0;
        4'h1: segment_sel = ~data_1;
        4'h2: segment_sel = ~data_2;
        4'h3: segment_sel = ~data_3;
        4'h4: segment_sel = ~data_4;
        4'h5: segment_sel = ~data_5;
        4'h6: segment_sel = ~data_6;
        4'h7: segment_sel = ~data_7;
        4'h8: segment_sel = ~data_8;
        4'h9: segment_sel = ~data_9;
        4'hA: segment_sel = ~data_A;
        4'hB: segment_sel = ~data_B;
        4'hC: segment_sel = ~data_C;
        4'hD: segment_sel = ~data_D;
        4'hE: segment_sel = ~data_E;
        4'hF: segment_sel = ~data_F;
    endcase
endfunction

wire [15:0] i_data_formatted = (i_data >> {count, 2'h0});
assign o_seg = segment_sel(i_data_formatted[3:0]);

endmodule
