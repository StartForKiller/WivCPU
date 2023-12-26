`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 18.11.2023 17:16:48
// Design Name:
// Module Name: pmp
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

module pmp #(
    parameter int unsigned REGION_COUNT = 16
)
(
    input pmp_cfg_t      i_pmp_cfg[REGION_COUNT],
    input [55:0]         i_pmp_addr[REGION_COUNT],

    input [55:0]         i_req_addr[2],
    input pmp_req_type_t i_req_type[2],
    output logic         o_req_trap[2]
);

logic [55:0] region_start_addr[REGION_COUNT];
logic [55:2] region_addr_mask[REGION_COUNT];
logic [1:0][REGION_COUNT-1:0] region_eq;
logic [1:0][REGION_COUNT-1:0] region_gt;
logic [1:0][REGION_COUNT-1:0] region_lt;
logic [1:0][REGION_COUNT-1:0] region_match;
logic [1:0][REGION_COUNT-1:0] region_type_check;
logic [1:0][REGION_COUNT-1:0] region_perm_check;

function automatic logic perm_check(logic pmp_cfg_lock, logic permission_check);
    return (~pmp_cfg_lock | permission_check);
endfunction

for(genvar i = 0; i < REGION_COUNT; i++) begin
    if(i == 0) begin
        assign region_start_addr[i] = (i_pmp_cfg[i].mode == PMP_MODE_TOR) ? 56'h00000000000 : i_pmp_addr[i];
    end else begin
        assign region_start_addr[i] = (i_pmp_cfg[i].mode == PMP_MODE_TOR) ? i_pmp_addr[i-1] : i_pmp_addr[i];
    end

    for(genvar j = 2; j < 56; j++) begin
        if(j == 2) assign region_addr_mask[i][j] = (i_pmp_cfg[i].mode != PMP_MODE_NAPOT);
        else       assign region_addr_mask[i][j] = (i_pmp_cfg[i].mode != PMP_MODE_NAPOT) | ~&i_pmp_addr[i][j-1:2];
    end
end

function automatic logic fault_check(logic [REGION_COUNT-1:0] match, logic [REGION_COUNT-1:0] perm_check);
    logic access_fault = 1'b0;
    logic matched = 1'b0;

    for(int i = 0; i < REGION_COUNT; i++) begin
        if(!matched && match[i]) begin
            access_fault = ~perm_check[i];
            matched = 1'b1;
        end
    end

    return access_fault;
endfunction

for(genvar i = 0; i < 2; i++) begin
    for(genvar j = 0; j < REGION_COUNT; j++) begin
        assign region_eq[i][j] = (i_req_addr[i][55:2] & region_addr_mask[j]) == (region_start_addr[j][55:2] &  region_addr_mask[j]);
        assign region_gt[i][j] = i_req_addr[i][55:2] > region_start_addr[j][55:2];
        assign region_lt[i][j] = i_req_addr[i][55:2] < i_pmp_addr[j][55:2];

        always_comb begin
            region_match[i][j] = 1'b0;
            unique case(i_pmp_cfg[j].mode)
                PMP_MODE_OFF:   region_match[i][j] = 1'b0;
                PMP_MODE_NA4:   region_match[i][j] = region_eq[i][j];
                PMP_MODE_NAPOT: region_match[i][j] = region_eq[i][j];
                PMP_MODE_TOR: begin
                    region_match[i][j] = (region_eq[i][j] | region_gt[i][j]) & region_lt[i][j];
                end
                default:        region_match[i][j] = 1'b0;
            endcase
        end

        assign region_type_check[i][j] = ((i_req_type[i] == PMP_REQ_EXEC) & i_pmp_cfg[j].exec) |
                                         ((i_req_type[i] == PMP_REQ_READ) & i_pmp_cfg[j].read) |
                                         ((i_req_type[i] == PMP_REQ_WRITE) & i_pmp_cfg[j].write);

        assign region_perm_check[i][j] = perm_check(i_pmp_cfg[j].lock, region_type_check[i][j]);
    end

    assign o_req_trap[i] = fault_check(region_match[i], region_perm_check[i]);
end

endmodule