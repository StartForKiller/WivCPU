`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 18.11.2023 17:16:48
// Design Name:
// Module Name: spi
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


module spi
#(
    parameter [63:0] MAPPED_ADDRESS = 64'h100001000
)
(
    input               i_clk,
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

    output              o_sck,
    output reg          o_mosi,
    input               i_miso,
    output [7:0]        o_select
);

/* verilator lint_off UNSIGNED */
wire addr_match = i_wb_adr >= MAPPED_ADDRESS && i_wb_adr < (MAPPED_ADDRESS + 8*4);
/* verilator lint_on UNSIGNED */

reg [63:0] o_wb_data_latch;
reg o_wb_ack_latch;
assign o_wb_dat = addr_match ? (o_wb_data_latch & { 8'($signed(i_wb_sel[7:7])), 8'($signed(i_wb_sel[6:6])), 8'($signed(i_wb_sel[5:5])), 8'($signed(i_wb_sel[4:4])),
                                               8'($signed(i_wb_sel[3:3])), 8'($signed(i_wb_sel[2:2])), 8'($signed(i_wb_sel[1:1])), 8'($signed(i_wb_sel[0:0])) }) : 64'hz;
assign o_wb_ack = addr_match ? o_wb_ack_latch : 1'bz;
assign o_wb_stall = (addr_match && i_wb_cyc && i_wb_stb) ? 1'b0 : 1'bz;

reg [1:0] state;
reg [7:0] control_register;
reg [7:0] out_buffer;
reg [7:0] in_buffer;
reg [7:0] temp_out_buffer;
reg [7:0] manually_select_lines;
reg [7:0] select_lines_register;
reg buffer_full;

reg sck;
reg [4:0] spi_counter;
reg [3:0] spi_shift;
reg [3:0] spi_shifted;
reg [3:0] spi_sampled;

wire cpha = control_register[0:0];
wire cpol = control_register[1:1];
wire [4:0] frequency_divider = control_register[7:3];

wire leadingEdge = spi_counter == frequency_divider && !sck && state == 2'h2;
wire trailingEdge = spi_counter == frequency_divider && sck && state == 2'h2;

assign o_sck = state == 2'h2 ? (cpol ? ~sck : sck) : cpol;
assign o_select = ~((manually_select_lines == 8'h0) ? (state != 2'h0 ? (1 << select_lines_register) : 8'h0) : manually_select_lines);

initial begin
    o_wb_ack_latch = 1'b0;
    o_wb_data_latch = 64'h0;

    state = 2'h0;
    control_register = 8'h0;

    out_buffer = 8'h0;
    in_buffer = 8'h0;
    temp_out_buffer = 8'h0;
    buffer_full = 1'b0;

    manually_select_lines = 8'h0;
    select_lines_register = 8'h0;

    spi_counter = 5'h0;
    spi_shift = 4'h0;
    spi_shifted = 4'h0;
    spi_sampled = 4'h0;
    sck = 1'b0;
end

//TODO: Add clock divider modificable
always @(negedge i_clk) begin
    if(i_reset) begin
        state <= 2'h0;
        control_register <= 8'h0;

        out_buffer <= 8'h0;
        buffer_full <= 1'b0;

        manually_select_lines <= 8'h0;
        select_lines_register <= 8'h0;
    end
    else begin
        if(addr_match && i_wb_stb && i_wb_cyc) begin
            if(i_wb_we) begin
                //Write
                case(i_wb_adr[4:3])
                    2'h0: if(state == 2'h0) begin
                        control_register <= {i_wb_dat[7:3], 1'h0, i_wb_dat[1:0]};
                        state <= i_wb_dat[2:2] ? 2'h1 : 2'h0;
                    end
                    2'h1: if(state == 2'h0) manually_select_lines <= i_wb_dat[7:0];
                    2'h2: if(state == 2'h0) out_buffer <= i_wb_dat[7:0];
                    2'h3: if(state == 2'h0) select_lines_register <= i_wb_dat[7:0];
                    default: begin end
                endcase
            end else begin
                //Read
                case(i_wb_adr[4:3])
                    2'h0: o_wb_data_latch <= 64'(control_register);
                    2'h1: o_wb_data_latch <= 64'({6'h0, buffer_full, state != 0});
                    2'h2: begin
                        buffer_full <= 1'b0;
                        o_wb_data_latch <= 64'(in_buffer);
                    end
                    2'h3: o_wb_data_latch <= 64'(select_lines_register);
                    default: begin end
                endcase
            end
        end

        if(state == 2'h2 && spi_shift == 4'h8 && spi_sampled == 4'h8 && spi_shifted == 4'h8) begin
            state <= 2'h0;
        end
        else if(state == 2'h1) begin
            state <= 2'h2;
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

always @(posedge i_clk) begin
    if(i_reset) begin
        in_buffer <= 8'h0;
        temp_out_buffer <= 8'h0;

        spi_counter <= 5'h0;
        spi_shift <= 4'h0;
        spi_shifted <= 4'h0;
        spi_sampled <= 4'h0;
        sck <= 1'b0;
    end else begin
        if(state == 2'h1)
            sck <= 1'b0;
        else if(state == 2'h2 || (cpol != o_sck))
            if(spi_counter == frequency_divider) begin
                spi_counter <= 5'h0;
                sck <= ~sck;
                //$display("Written");
            end else begin
                spi_counter <= spi_counter + 1;
            end
        else begin
            spi_counter <= 5'h0;
        end

        case(state)
            2'h1: begin //Start phase
                spi_shift   <= 4'h0;
                spi_sampled <= 4'h0;

                if(!cpha) begin
                    temp_out_buffer <= {out_buffer[6:0], 1'b0};
                    o_mosi <= out_buffer[7:7];
                    //$display("Shift");

                    spi_shifted <= 4'h1;
                end else begin
                    spi_shifted <= 4'h0;
                    temp_out_buffer <= out_buffer;
                end
            end
            2'h2: begin
                if((cpha && leadingEdge) || (!cpha && trailingEdge)) begin
                    if(spi_shifted != 4'h8) begin
                        temp_out_buffer <= {temp_out_buffer[6:0], 1'b0};
                        o_mosi <= temp_out_buffer[7:7];

                        spi_shifted <= spi_shifted + 1;
                        //$display("Shift");
                    end
                end
                else if((!cpha && leadingEdge) || (cpha && trailingEdge)) begin
                    if(spi_sampled != 4'h8) begin
                        in_buffer <= {in_buffer[6:0], i_miso};

                        spi_sampled <= spi_sampled + 1;
                        //$display("Sample");
                    end
                end

                if(trailingEdge && !(cpol && spi_shifted < 4'h2)) spi_shift <= spi_shift + 1;
            end
            default: begin

            end
        endcase
    end
end

endmodule