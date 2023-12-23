`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 18.11.2023 17:16:48
// Design Name:
// Module Name: icache
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


module icache(
    input               i_clk,
    input               i_reset,

    //Wishbone interface
    output reg [63:0]   o_wb_adr,
    input [63:0]        i_wb_dat,
    output [63:0]       o_wb_dat,
    output reg          o_wb_we,
    output reg [7:0]    o_wb_sel,
    output reg          o_wb_stb,
    input               i_wb_ack,
    output reg          o_wb_cyc,
    input               i_wb_stall,
    input               i_wb_rty,
    output reg          o_wb_lock,

    input [63:0]        i_addr,
    output reg [31:0]   o_data,

    input               i_icache_invalidate,
    output              o_icache_invalidating,

    output o_data_ready
);

//Address mapping:
//  63         13 12 11          07 06 05               00
// |-------------|  |              |  |                   |
//  +-------------+  +--------------+  +-----------------+
//  | Tag address |  | Line address |  | Address on line |

// 50 bits for tag address
// 6 bits for line address -> 64 lines
// 6 bits for address on line -> 64 bytes/ 8 instructions

reg [511:0] cache[0:63];
wire [511:0] cacheline = cache[i_addr[11:6]];
reg [51:0] cache_tags [0:63];
reg valid [0:63];

initial begin
    static integer i = 0;
    for(i = 0; i < 64; i++) begin
        valid[i] = 1'b0;
    end
end

//Check if is a valid hit
wire tag_hit = (cache_tags[i_addr[11:6]] == i_addr[63:12]) && valid[i_addr[11:6]];

reg [1:0] state;
reg wb_data_ready;

assign o_data_ready = state == 2'b00 && tag_hit && !i_icache_invalidate;

reg [63:0] temp_addr;

assign o_data = (state == 2'b01 && o_wb_adr[5:3] == 3'b111 && temp_addr[63:6] == i_addr[63:6]) ?
                      32'((cache[temp_addr[11:6]] | 512'(512'(i_wb_dat) << {o_wb_adr[5:3], 6'h0})) >> {i_addr[5:0], 3'b0})
                    : 32'(cache[i_addr[11:6]] >> {i_addr[5:0], 3'b0});

reg [5:0] invalidate_counter;
assign o_icache_invalidating = i_icache_invalidate || state == 2'b10;

initial begin
    o_wb_lock = 1'b0;
    o_wb_cyc = 1'b0;
    o_wb_stb = 1'b0;

    invalidate_counter = 6'h0;
end

always @(posedge i_clk) begin
    if(i_reset) begin
        state <= 2'h0;
        o_wb_we <= 1'b0;
        o_wb_stb <= 1'b0;
        o_wb_cyc <= 1'b0;
        wb_data_ready <= 1'b0;
        o_wb_lock <= 1'b0;

        invalidate_counter <= 6'h0;
    end
    else begin
        case(state)
            2'b00: begin
                if(i_icache_invalidate) begin
                    state <= 2'b10;
                end
                else if(tag_hit) begin
                    //Output the data
                    state <= 2'b00;
                end
                else if(!i_wb_rty && !i_wb_ack) begin
                    o_wb_adr <= {i_addr[63:6], 6'h0};
                    o_wb_we <= 1'b0;
                    o_wb_cyc <= 1'b1;
                    o_wb_stb <= 1'b1;
                    o_wb_sel <= 8'hFF;
                    wb_data_ready <= 1'b0;

                    temp_addr <= i_addr;
                    cache[i_addr[11:6]] <= 512'h0; //Remove data from the cache(invalidate)
                    o_wb_lock <= 1'b1;

                    state <= 2'b01;
                end
            end
            2'b01: begin //CACHE MISS, receive data and write to the cacheline
                if(!i_wb_rty && i_wb_ack && !i_wb_stall) begin
                    cache[temp_addr[11:6]] <= cache[temp_addr[11:6]] | 512'(512'(i_wb_dat) << {o_wb_adr[5:3], 6'h0});
                    o_wb_adr <= o_wb_adr + 8;

                    if(o_wb_adr[5:3] == 3'b111) begin
                        state <= 2'b00;
                        o_wb_cyc <= 1'b0;
                        o_wb_stb <= 1'b0;
                        o_wb_lock <= 1'b0;

                        valid[temp_addr[11:6]] <= 1'b1;
                        cache_tags[temp_addr[11:6]] <= temp_addr[63:12];
                    end
                end
            end
            2'b10: begin
                valid[invalidate_counter] <= 1'b0;

                if(invalidate_counter == 6'h3F) begin
                    state <= 2'b00;
                    invalidate_counter <= 6'h0;
                end else
                    invalidate_counter <= invalidate_counter + 1;
            end
            default: begin

            end
        endcase
    end
end

endmodule