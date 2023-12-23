`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 05.11.2023 21:13:51
// Design Name:
// Module Name: dmi
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

module dm
(
    input i_clk,
    input i_reset,

    //DMI Bus
    input            i_dmi_req_valid,
    output           o_dmi_req_ready,
    input  [6:0]     i_dmi_req_address,
    input  [31:0]    i_dmi_req_data,
    input  [1:0]     i_dmi_req_op,
    output reg       o_dmi_rsp_valid,
    input            i_dmi_rsp_ready,
    output [31:0]    o_dmi_rsp_data,
    output reg [1:0] o_dmi_rsp_op,

    output reg       o_halt,
    input            i_halted,

    output reg    o_reg_access,
    output reg    o_reg_we,
    output [63:0] o_reg_data,
    input [63:0]  i_reg_data,
    output [12:0] o_reg_addr,

    //Wishbone interface
    output [63:0]    o_wb_adr,
    input [63:0]     i_wb_dat,
    output [63:0]    o_wb_dat,
    output reg       o_wb_we,
    output reg [7:0] o_wb_sel,
    output reg       o_wb_stb,
    input            i_wb_ack,
    output reg       o_wb_cyc,
    input            i_wb_stall,
    input            i_wb_rty,
    output reg       o_wb_lock
);

reg [1:0] dmi_state;
assign o_dmi_req_ready = dmi_state == 2'h0;

reg [6:0]  req_addr;
reg [31:0] req_data;
assign o_dmi_rsp_data = req_data;

//---Internal registers---//
reg [31:0] reg_data0;
reg [31:0] reg_data1;
reg [31:0] reg_data2;
reg [31:0] reg_data3;

//dmcontrol
reg resumereq;
reg resume_ack;
reg keepalive;

//abstractcs
reg [3:0] abstractcs;
wire       abstractcs_busy      = abstractcs[3:3];
wire [2:0] abstractcs_cmderr    = abstractcs[2:0];

//command
reg [31:0] command;

//------------------------//

//----
reg [1:0] command_state;
reg command_start;
reg [31:0] saved_arg0;

reg i_dmi_req_valid_last;

assign o_reg_data = {reg_data1, reg_data0};
assign o_reg_addr = command[12:0];

assign o_wb_adr = {reg_data3, reg_data2[31:3], 3'h0};
assign o_wb_dat = 64'({reg_data1, reg_data0} << {reg_data2[2:0], 3'h0});

wire [63:0] received_data = i_wb_dat >> {reg_data2[2:0], 3'h0};
wire [63:0] wb_adr_plus_aamsize = o_wb_adr + (64'h1 << command[22:20]);

initial begin
    dmi_state = 2'h0;
    command_state = 2'h0;

    req_addr = 7'h0;
    req_data = 32'h0;

    saved_arg0 = 32'h0;

    reg_data0 = 32'h0;
    reg_data1 = 32'h0;
    reg_data2 = 32'h0;
    reg_data3 = 32'h0;

    o_halt = 1'b0;
    resumereq = 1'b0;
    resume_ack = 1'b0;
    keepalive = 1'b0;

    abstractcs = 4'h0;

    command = 32'h0;

    o_dmi_rsp_op = 2'h0;
    o_dmi_rsp_valid = 1'b0;
    i_dmi_req_valid_last = 1'b0;

    o_reg_access = 1'b0;
    o_reg_we = 1'b0;

    o_wb_lock = 1'b0;
    o_wb_cyc = 1'b0;
    o_wb_stb = 1'b0;
end

always @(posedge i_clk) begin
    dmi_state <= 2'h0;
    command_start <= 1'b0;

    if(i_reset) begin
        i_dmi_req_valid_last <= 1'b0;
        resume_ack <= 1'b0;
    end else begin
        if(!i_halted && !o_halt)
            resume_ack <= 1'b1;

        case (dmi_state)
            2'h0: begin
                if(!i_dmi_req_valid_last && i_dmi_req_valid && i_dmi_req_op != 0) begin
                    req_addr <= i_dmi_req_address;
                    req_data <= i_dmi_req_data;

                    o_dmi_rsp_op <= 2'h0;
                    o_dmi_rsp_valid <= 1'b0;

                    dmi_state <= i_dmi_req_op;
                end
            end
            2'h1: begin //Read
                if(i_dmi_rsp_ready) begin
                    case(req_addr)
                        7'h04: req_data <= reg_data0;
                        7'h05: req_data <= reg_data1;
                        7'h06: req_data <= reg_data2;
                        7'h07: req_data <= reg_data3;
                        7'h10: req_data <= {o_halt, 31'h1};
                        7'h11: req_data <= {14'h0, resume_ack, resume_ack, 4'h0, !i_halted, !i_halted, i_halted, i_halted, 1'b1, 3'h0, 4'h3};
                        7'h12: req_data <= 32'h0;
                        7'h16: req_data <= {19'h0, abstractcs_busy, 1'b0, abstractcs_cmderr, 8'h02};
                        7'h17: req_data <= command;
                        7'h1D: req_data <= 32'h0;
                        7'h38: req_data <= {3'h1, 9'h0, 3'h2, 5'h0, 7'd64, 5'h8};
                        default: begin
                            o_dmi_rsp_op <= 2'h2;
                        end
                    endcase
                    o_dmi_rsp_valid <= 1'b1;
                end else if(i_dmi_req_valid)
                    dmi_state <= 2'h1;
            end
            2'h2: begin //Write
                if(i_dmi_rsp_ready) begin
                    case(req_addr)
                        7'h04: begin end
                        7'h05: begin end
                        7'h06: begin end
                        7'h07: begin end
                        7'h10: begin
                            o_halt <= req_data[31:31] || (req_data[30:30] ? 1'b0 : i_halted);
                            resumereq <= req_data[30:30] ? 1'b1 : resumereq;
                            resume_ack <= 1'b0;
                            keepalive <= req_data[4:4] ? 1'b0 : (req_data[5:5] ? 1'b1 : keepalive);
                        end
                        7'h11,
                        7'h12: begin

                        end
                        7'h16: begin end
                        7'h17: begin
                            command <= req_data;
                            command_start <= 1'b1;
                        end
                        7'h1D: begin end
                        7'h38: begin end
                        default: begin
                            o_dmi_rsp_op <= 2'h2;
                        end
                    endcase
                    o_dmi_rsp_valid <= 1'b1;
                end else if(i_dmi_req_valid)
                    dmi_state <= 2'h2;
            end
            default: begin end
        endcase

        i_dmi_req_valid_last <= i_dmi_req_valid;
    end
end

wire [7:0] abs_cmd_cmdtype = command[31:24];
always @(posedge i_clk) begin
    if(i_reset) begin
        reg_data0 <= 32'h0;
        reg_data1 <= 32'h0;
        reg_data2 <= 32'h0;
        reg_data3 <= 32'h0;
        command_state <= 2'h0;
        saved_arg0 <= 32'h0;

        o_wb_we <= 1'b0;
        o_wb_stb <= 1'b0;
        o_wb_cyc <= 1'b0;
        o_wb_lock <= 1'b0;
    end else begin
        if(dmi_state == 2'h2) begin
            case(req_addr)
                7'h04: reg_data0 <= req_data;
                7'h05: reg_data1 <= req_data;
                7'h06: reg_data2 <= req_data;
                7'h07: reg_data3 <= req_data;
                7'h16: abstractcs[2:0] <= abstractcs[2:0] ^ req_data[10:8];
                default: begin end
            endcase
        end

        if(command_state != 0) begin
            if(abstractcs[3:3] && command_start && abstractcs_cmderr == 3'h0)
                abstractcs[2:0] <= 3'h1;
        end
        case(command_state)
            2'h0: begin
                abstractcs[3:3] <= 1'b0;
                if(command_start && abstractcs_cmderr == 3'h0) begin
                    //Start write
                    abstractcs[3:3] <= 1'b1;

                    saved_arg0 <= reg_data0;

                    command_state <= 2'h1;
                end
            end
            2'h1: begin
                case(abs_cmd_cmdtype)
                    8'h0: begin
                        if(!i_halted) begin
                            abstractcs[2:0] <= 3'h4;
                            command_state <= 2'h0;
                        end
                        else if(command[17:17]) begin
                            o_reg_access <= 1'b1;

                            o_reg_we <= command[16:16];
                            command_state <= 2'h2;
                        end else begin
                            command_state <= 2'h0;
                        end
                    end
                    8'h2: begin
                        if(!i_halted) begin //TODO: Make avilable to do mem operation while core is not halted
                            abstractcs[2:0] <= 3'h4;
                            command_state <= 2'h0;
                        end
                        else begin
                            if(command[22:20] < 3'h4)
                                command_state <= 2'h2;
                            else begin
                                abstractcs[2:0] <= 3'h2;
                                command_state <= 2'h0;
                            end
                        end
                    end
                    default: begin
                        abstractcs[2:0] <= 3'h2;
                        command_state <= 2'h0;
                    end
                endcase
            end
            2'h2: begin
                case(abs_cmd_cmdtype)
                    8'h0: begin
                        if(!o_reg_we) begin
                            reg_data0 <= i_reg_data[31:0];
                            reg_data1 <= i_reg_data[63:32];
                        end

                        o_reg_access <= 1'b0;
                        o_reg_we <= 1'b0;
                        command_state <= 2'h0;
                    end
                    8'h2: begin
                        if(!i_wb_rty && !i_wb_ack) begin
                            o_wb_we <= command[16:16];
                            o_wb_cyc <= 1'b1;
                            o_wb_stb <= 1'b1;
                            case(command[22:20])
                                3'h0: o_wb_sel <= 8'h01 << reg_data2[2:0];
                                3'h1: o_wb_sel <= 8'h03 << reg_data2[2:0];
                                3'h2: o_wb_sel <= 8'h0F << reg_data2[2:0];
                                default: o_wb_sel <= 8'hFF;
                            endcase

                            o_wb_lock <= 1'b1;

                            command_state <= 2'h3;
                        end else begin
                            command_state <= 2'h2;
                        end
                    end
                    default: begin
                        abstractcs[2:0] <= 3'h2;
                        command_state <= 2'h0;
                    end
                endcase
            end
            2'h3: begin
                case(abs_cmd_cmdtype)
                    8'h2: begin
                        if(!i_wb_rty && i_wb_ack && !i_wb_stall) begin
                            o_wb_cyc <= 1'b0;
                            o_wb_stb <= 1'b0;
                            o_wb_lock <= 1'b0;

                            if(!command[16:16]) begin
                                reg_data0 <= received_data[31:0];
                                reg_data1 <= received_data[63:32];
                            end
                            if(command[19:19]) begin
                                reg_data2 <= wb_adr_plus_aamsize[31:0];
                                reg_data3 <= wb_adr_plus_aamsize[63:32];
                            end

                            command_state <= 2'h0;
                        end else begin
                            command_state <= 2'h3;
                        end
                    end
                    default: begin
                        abstractcs[2:0] <= 3'h2;
                        command_state <= 2'h0;
                    end
                endcase
            end
            default: command_state <= 2'h0;
        endcase
    end
end

endmodule