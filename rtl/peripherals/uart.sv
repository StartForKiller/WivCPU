`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 18.11.2023 17:16:48
// Design Name:
// Module Name: uart
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


module uart
#(
    parameter [63:0] MAPPED_ADDRESS = 64'h100000000
)
(
    input               i_clk,
    input               i_uart_clk,
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

    input               i_uart_rx,
    output reg          o_uart_tx
);

/* verilator lint_off UNSIGNED */
wire addr_match = i_wb_adr >= MAPPED_ADDRESS && i_wb_adr < (MAPPED_ADDRESS + 4*8);
/* verilator lint_on UNSIGNED */

reg [63:0] o_wb_data_latch;
reg o_wb_ack_latch;
assign o_wb_dat = addr_match ? (o_wb_data_latch & { 8'($signed(i_wb_sel[7:7])), 8'($signed(i_wb_sel[6:6])), 8'($signed(i_wb_sel[5:5])), 8'($signed(i_wb_sel[4:4])),
                                               8'($signed(i_wb_sel[3:3])), 8'($signed(i_wb_sel[2:2])), 8'($signed(i_wb_sel[1:1])), 8'($signed(i_wb_sel[0:0])) }) : 64'hz;
assign o_wb_ack = addr_match ? o_wb_ack_latch : 1'bz;
assign o_wb_stall = (addr_match && i_wb_cyc && i_wb_stb) ? 1'b0 : 1'bz;

reg [7:0] rx_reg_shift;
reg [7:0] tx_reg_shift;
reg [7:0] tx_reg;
reg [3:0] state;
reg send;

initial begin
    o_wb_ack_latch = 1'b0;
    o_wb_data_latch = 64'h0;
    o_uart_tx = 1'b1;
    state = 4'h0;
    send = 1'b0;
end

//TODO: Add clock divider modificable
always @(negedge i_clk) begin
    if(i_reset) begin
        send <= 1'b0;
    end
    else begin
        if(state != 0)
            send <= 1'b0;

        if(addr_match && i_wb_stb && i_wb_cyc) begin
            if(i_wb_we) begin
                //Write
                tx_reg <= i_wb_dat[7:0];
                if(state == 0)
                    send <= 1'b1;
            end else begin
                //Read
                o_wb_data_latch <= {63'h0, state == 0 && send == 0};
            end
        end
    end
end

always @(negedge i_clk) begin
    if(i_reset) begin
        o_wb_ack_latch <= 1'b0;
    end
    else if(addr_match) begin
        if(i_wb_stb && i_wb_cyc) begin
            o_wb_ack_latch <= 1;
        end else begin
            o_wb_ack_latch <= 0;
        end
    end
end

//State machine
always @(posedge i_uart_clk) begin
    if(i_reset) begin
        state <= 4'h0;
        o_uart_tx <= 1'b1;
    end
    else begin
        case(state)
            4'h0: begin
                o_uart_tx <= 1'b1;
                if(send) begin
                    o_uart_tx <= 1'b0;
                    state <= 4'h1;
                    tx_reg_shift <= tx_reg;
                end
            end
            4'h1, 4'h2, 4'h3, 4'h4, 4'h5, 4'h6, 4'h7,
            4'h8: begin
                o_uart_tx <= tx_reg_shift[0:0];
                state <= state + 1;
                tx_reg_shift <= {1'b0, tx_reg_shift[7:1]};
            end
            4'h9: begin
                if(!send)
                    state <= 4'h0;
                o_uart_tx <= 1'b1;
            end
            default: state <= 4'h0;
        endcase
    end
end

endmodule