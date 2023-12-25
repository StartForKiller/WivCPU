`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 18.11.2023 17:16:48
// Design Name:
// Module Name: dcache
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


module dcache(
    input               i_clk,
    input               i_reset,

    //Wishbone interface
    output reg [63:0]   o_wb_adr,
    input [63:0]        i_wb_dat,
    output reg [63:0]   o_wb_dat,
    output reg          o_wb_we,
    output reg [7:0]    o_wb_sel,
    output reg          o_wb_stb,
    input               i_wb_ack,
    output reg          o_wb_cyc,
    input               i_wb_stall,
    input               i_wb_rty,
    output reg          o_wb_lock,

    input [63:0]      i_dcache_addr,
    output [63:0]     o_dcache_odata,
    input [63:0]      i_dcache_idata,
    input [7:0]       i_dcache_sel,
    input             i_dcache_st,
    input             i_dcache_ld,
    input             i_dcache_atomic,
    output            o_dcache_reserved,
    input             i_dcache_invalidate,
    output            o_dcache_data_ready,
    output            o_dcache_ready,
    output            o_dcache_invalidating
);

//Address mapping:
//  63         13 12 11          07 06 05               00
// |-------------|  |              |  |                   |
//  +-------------+  +--------------+  +-----------------+
//  | Tag address |  | Line address |  | Address on line |

// 52 bits for tag address
// 6 bits for line address -> 64 lines
// 6 bits for address on line -> 64 bytes

reg [511:0] cache[0:63];
wire [511:0] cacheline = cache[i_dcache_addr[11:6]];
reg [51:0] cache_tags [0:63];
reg valid [0:63];

reg [5:0] invalidate_counter;

initial begin
    static integer i = 0;
    for(i = 0; i < 64; i++) begin
        valid[i] = 1'b0;
    end
end

reg [2:0] state;

//Check if is a valid hit
wire tag_hit = (cache_tags[i_dcache_addr[11:6]] == i_dcache_addr[63:12]) && valid[i_dcache_addr[11:6]];

wire uncached_hit = i_dcache_addr[63:32] != 0;  //Higher 32 bits of addressing are uncached for now

assign o_dcache_data_ready = state == 3'h0 && (tag_hit == 1'b1 || (uncached_hit == 1'b1 && i_dcache_ld == 1'b0));
assign o_dcache_ready = state == 3'h0 && !i_dcache_ld && !i_dcache_st;

reg [63:0] temp_addr;
reg [63:0] temp_addr_secodary;
reg [63:0] temp_data;
reg [7:0]  temp_sel;
reg store_after_load;

reg invalidating;
assign o_dcache_invalidating = invalidating;

//Used on cache write last term
wire [511:0] cache_temp_line = cache[temp_addr[11:6]] | 512'(512'(i_wb_dat) << {o_wb_adr[5:3], 6'h0});/*((cache[temp_addr[11:6]] | 512'(512'(i_wb_dat) << {o_wb_adr[5:3], 6'h0})) &
                                                                                    512'(~(512'({ 8'($signed(temp_sel[7:7])), 8'($signed(temp_sel[6:6])), 8'($signed(temp_sel[5:5])), 8'($signed(temp_sel[4:4])),
                                                                                                  8'($signed(temp_sel[3:3])), 8'($signed(temp_sel[2:2])), 8'($signed(temp_sel[1:1])), 8'($signed(temp_sel[0:0])) }) << {temp_addr[5:0], 3'h0}))) |
                                                          512'(512'(512'(temp_data) & 512'({ 8'($signed(temp_sel[7:7])), 8'($signed(temp_sel[6:6])), 8'($signed(temp_sel[5:5])), 8'($signed(temp_sel[4:4])),
                                                                                             8'($signed(temp_sel[3:3])), 8'($signed(temp_sel[2:2])), 8'($signed(temp_sel[1:1])), 8'($signed(temp_sel[0:0])) })) << {temp_addr[5:0], 3'h0});*/

wire [63:0] next_wb_adr = o_wb_adr + 8;

reg [63:0] dcache_odata;
assign o_dcache_odata = uncached_hit ? dcache_odata :
                        (
                            (state == 3'h1 && o_wb_adr[5:3] == 3'b111 && temp_addr[63:6] == i_dcache_addr[63:6]) ?
                                (64'(cache_temp_line >> {i_dcache_addr[5:0], 3'b0})) &
                                    ({ 8'($signed(temp_sel[7:7])), 8'($signed(temp_sel[6:6])), 8'($signed(temp_sel[5:5])), 8'($signed(temp_sel[4:4])),
                                       8'($signed(temp_sel[3:3])), 8'($signed(temp_sel[2:2])), 8'($signed(temp_sel[1:1])), 8'($signed(temp_sel[0:0])) })
                            :   (64'(cache[i_dcache_addr[11:6]] >> {i_dcache_addr[5:0], 3'b0})) & ({ 8'($signed(i_dcache_sel[7:7])), 8'($signed(i_dcache_sel[6:6])), 8'($signed(i_dcache_sel[5:5])), 8'($signed(i_dcache_sel[4:4])),
                                                                                                     8'($signed(i_dcache_sel[3:3])), 8'($signed(i_dcache_sel[2:2])), 8'($signed(i_dcache_sel[1:1])), 8'($signed(i_dcache_sel[0:0])) })
                        );

reg [63:0] reserved_addresses [0:0];
reg        reserved_counter;
reg [7:0]  reserved_size      [0:0];
reg        reserved_valid     [0:0];

function bit check_reserved(input int index);
    return reserved_addresses[index] == i_dcache_addr && reserved_size[index] == i_dcache_sel && reserved_valid[index];
endfunction

assign o_dcache_reserved = check_reserved(0);

initial begin
    o_wb_lock = 1'b0;

    reserved_counter = 1'b0;
    reserved_valid[0] = 1'b0;
    //reserved_valid[1] = 1'b0;
end

always @(posedge i_clk) begin
    if(i_reset) begin
        state <= 3'h0;
        o_wb_we <= 1'b0;
        o_wb_stb <= 1'b0;
        o_wb_cyc <= 1'b0;
        temp_addr <= 64'h0;
        temp_addr_secodary <= 64'h0;
        temp_data <= 64'h0;
        temp_sel <= 8'h0;
        store_after_load <= 1'b0;
        dcache_odata <= 64'h0;
        invalidate_counter <= 6'h0;
        invalidating <= 1'b0;
        o_wb_lock <= 1'b0;

        reserved_counter <= 1'b0;
    end else begin
        case(state)
            3'h0: begin
                if(i_dcache_invalidate) begin
                    //Flush all the valid entries to the memory
                    state <= 3'h5;
                end
                else if(uncached_hit) begin
                    if(i_dcache_ld) begin
                        o_wb_adr <= i_dcache_addr;
                        o_wb_we <= 1'b0;
                        o_wb_cyc <= 1'b1;
                        o_wb_stb <= 1'b1;
                        o_wb_sel <= i_dcache_sel << i_dcache_addr[2:0];
                        o_wb_lock <= 1'b1;

                        state <= 3'h3;
                    end else if(i_dcache_st) begin
                        o_wb_adr <= i_dcache_addr;
                        o_wb_we <= 1'b1;
                        o_wb_cyc <= 1'b1;
                        o_wb_stb <= 1'b1;
                        o_wb_sel <= i_dcache_sel << i_dcache_addr[2:0];
                        o_wb_dat <= i_dcache_idata << {i_dcache_addr[2:0], 3'h0};
                        o_wb_lock <= 1'b1;

                        state <= 3'h4;
                    end
                end else begin
                    if(i_dcache_ld && i_dcache_atomic) begin
                        reserved_addresses[reserved_counter] <= i_dcache_addr;
                        reserved_size[reserved_counter] <= i_dcache_sel;
                        reserved_valid[reserved_counter] <= 1'b1;
                    end
                    if(i_dcache_ld || (!i_dcache_st && tag_hit)) begin
                        if(!tag_hit && !i_wb_rty) begin
                            temp_sel <= i_dcache_sel;

                            if(!valid[i_dcache_addr[11:6]]) begin //CACHE MISS, but no data was stored before on this cacheline, so just read the new cacheline
                                o_wb_adr <= {i_dcache_addr[63:6], 6'h0};
                                o_wb_we <= 1'b0;
                                o_wb_cyc <= 1'b1;
                                o_wb_stb <= 1'b1;
                                o_wb_sel <= 8'hFF;

                                temp_addr <= i_dcache_addr;

                                cache[i_dcache_addr[11:6]] <= 512'h0; //Remove data from the cache(invalidate)
                                o_wb_lock <= 1'b1;

                                state <= 3'h1;
                            end else begin //CACHE MISS, but data was actually stored on this cache line, flush it
                                o_wb_adr <= {cache_tags[i_dcache_addr[11:6]], i_dcache_addr[11:6], 6'h0};
                                o_wb_we <= 1'b1;
                                o_wb_cyc <= 1'b1;
                                o_wb_stb <= 1'b1;
                                o_wb_sel <= 8'hFF;

                                o_wb_dat <= 64'(cache[i_dcache_addr[11:6]]);

                                valid[i_dcache_addr[11:6]] <= 1'b0;

                                temp_addr <= {cache_tags[i_dcache_addr[11:6]], i_dcache_addr[11:6], 6'h0};
                                temp_addr_secodary <= i_dcache_addr;
                                o_wb_lock <= 1'b1;

                                state <= 3'h2;
                            end
                            store_after_load <= 1'b0;
                        end
                    end else if(i_dcache_st && !(i_dcache_atomic && !o_dcache_reserved)) begin
                        if(tag_hit) begin
                            cache[i_dcache_addr[11:6]] <= (cache[i_dcache_addr[11:6]] & 512'(~(512'({ 8'($signed(i_dcache_sel[7:7])), 8'($signed(i_dcache_sel[6:6])), 8'($signed(i_dcache_sel[5:5])), 8'($signed(i_dcache_sel[4:4])),
                                                                                                      8'($signed(i_dcache_sel[3:3])), 8'($signed(i_dcache_sel[2:2])), 8'($signed(i_dcache_sel[1:1])), 8'($signed(i_dcache_sel[0:0])) }) << {i_dcache_addr[5:0], 3'h0}))) |
                                                    512'(512'(512'(i_dcache_idata) & 512'({ 8'($signed(i_dcache_sel[7:7])), 8'($signed(i_dcache_sel[6:6])), 8'($signed(i_dcache_sel[5:5])), 8'($signed(i_dcache_sel[4:4])),
                                                                                            8'($signed(i_dcache_sel[3:3])), 8'($signed(i_dcache_sel[2:2])), 8'($signed(i_dcache_sel[1:1])), 8'($signed(i_dcache_sel[0:0])) })) << {i_dcache_addr[5:0], 3'h0});
                        end else begin
                            temp_data <= i_dcache_idata;
                            temp_sel <= i_dcache_sel;
                            store_after_load <= 1'b1;

                            if(!valid[i_dcache_addr[11:6]]) begin //CACHE MISS, but no data was stored before on this cacheline, so just read the new cacheline
                                o_wb_adr <= {i_dcache_addr[63:6], 6'h0};
                                o_wb_we <= 1'b0;
                                o_wb_cyc <= 1'b1;
                                o_wb_stb <= 1'b1;
                                o_wb_sel <= 8'hFF;

                                temp_addr <= i_dcache_addr;
                                cache[i_dcache_addr[11:6]] <= 512'h0; //Remove data from the cache(invalidate)
                                o_wb_lock <= 1'b1;

                                state <= 3'h1;
                            end else begin //CACHE MISS, but data was actually stored on this cache line, flush it
                                o_wb_adr <= {cache_tags[i_dcache_addr[11:6]], i_dcache_addr[11:6], 6'h0};
                                o_wb_we <= 1'b1;
                                o_wb_cyc <= 1'b1;
                                o_wb_stb <= 1'b1;
                                o_wb_sel <= 8'hFF;

                                o_wb_dat <= 64'(cache[i_dcache_addr[11:6]]);

                                valid[i_dcache_addr[11:6]] <= 1'b0;

                                temp_addr <= {cache_tags[i_dcache_addr[11:6]], i_dcache_addr[11:6], 6'h0};
                                temp_addr_secodary <= i_dcache_addr;
                                o_wb_lock <= 1'b1;

                                state <= 3'h2;
                            end
                        end
                    end
                end
            end
            3'h1: begin //CACHE MISS, READ, receive data and write to the cacheline
                if(!i_wb_rty && i_wb_ack && !i_wb_stall) begin
                    o_wb_adr <= o_wb_adr + 8;

                    if(o_wb_adr[5:3] == 3'b111) begin
                        state <= 3'h0;
                        o_wb_cyc <= 1'b0;
                        o_wb_stb <= 1'b0;
                        o_wb_lock <= 1'b0;
                        //TODO select bits

                        valid[temp_addr[11:6]] <= 1'b1;
                        cache_tags[temp_addr[11:6]] <= temp_addr[63:12];

                        if(store_after_load) begin
                            cache[temp_addr[11:6]] <= (cache_temp_line & 512'(~(512'({ 8'($signed(temp_sel[7:7])), 8'($signed(temp_sel[6:6])), 8'($signed(temp_sel[5:5])), 8'($signed(temp_sel[4:4])),
                                                                                       8'($signed(temp_sel[3:3])), 8'($signed(temp_sel[2:2])), 8'($signed(temp_sel[1:1])), 8'($signed(temp_sel[0:0])) }) << {temp_addr[5:0], 3'h0}))) |
                                                      512'(512'(512'(temp_data) & 512'({ 8'($signed(temp_sel[7:7])), 8'($signed(temp_sel[6:6])), 8'($signed(temp_sel[5:5])), 8'($signed(temp_sel[4:4])),
                                                                                         8'($signed(temp_sel[3:3])), 8'($signed(temp_sel[2:2])), 8'($signed(temp_sel[1:1])), 8'($signed(temp_sel[0:0])) })) << {temp_addr[5:0], 3'h0});
                        end else begin
                            cache[temp_addr[11:6]] <= cache[temp_addr[11:6]] | 512'(512'(i_wb_dat) << {o_wb_adr[5:3], 6'h0});
                        end
                    end else begin
                        cache[temp_addr[11:6]] <= cache[temp_addr[11:6]] | 512'(512'(i_wb_dat) << {o_wb_adr[5:3], 6'h0});
                    end
                end
            end
            3'h2: begin
                if(!i_wb_rty && i_wb_ack && !i_wb_stall) begin
                    o_wb_dat <= 64'(cache[temp_addr[11:6]] >> {next_wb_adr[5:0], 3'b0});

                    if(o_wb_adr[5:3] == 3'b111) begin
                        if(invalidating)
                            state <= 3'h5; //Go back to the invalidate state
                        else
                            state <= 3'h1; //Fetch the cacheline

                        o_wb_adr <= {temp_addr_secodary[63:6], 6'h0};
                        o_wb_we <= 1'b0;
                        o_wb_cyc <= 1'b1;
                        o_wb_stb <= 1'b1;
                        o_wb_sel <= 8'hFF;
                        o_wb_lock <= 1'b1;

                        cache[temp_addr[11:6]] <= 512'h0; //Remove data from the cache(invalidate)
                        valid[temp_addr[11:6]] <= 1'b0; //Invalidate the cache

                        temp_addr <= temp_addr_secodary;
                        temp_addr_secodary <= 64'h0;
                    end else begin
                        o_wb_adr <= next_wb_adr;
                    end
                end
            end
            3'h3: begin //Uncached load
                if(!i_wb_rty && i_wb_ack && !i_wb_stall) begin
                    dcache_odata <= i_wb_dat >> {o_wb_adr[2:0], 3'h0};
                    state <= 3'h0;
                    o_wb_cyc <= 1'b0;
                    o_wb_stb <= 1'b0;
                    o_wb_lock <= 1'b0;
                end
            end
            3'h4: begin //Uncached store
                if(!i_wb_rty && i_wb_ack && !i_wb_stall) begin
                    state <= 3'h0;
                    o_wb_cyc <= 1'b0;
                    o_wb_stb <= 1'b0;
                    o_wb_lock <= 1'b0;
                    o_wb_we <= 1'b0;
                end
            end
            3'h5: begin //Invalidate all
                if(valid[invalidate_counter] == 1'b1) begin
                    o_wb_adr <= {cache_tags[invalidate_counter], invalidate_counter, 6'h0};
                    o_wb_we <= 1'b1;
                    o_wb_cyc <= 1'b1;
                    o_wb_stb <= 1'b1;
                    o_wb_sel <= 8'hFF;

                    o_wb_dat <= 64'(cache[invalidate_counter]);

                    temp_addr <= {cache_tags[invalidate_counter], invalidate_counter, 6'h0};
                    temp_addr_secodary <= {cache_tags[invalidate_counter], invalidate_counter, 6'h0};
                    o_wb_lock <= 1'b1;

                    state <= 3'h2;
                end

                if(invalidate_counter == 6'h3F) begin
                    state <= 3'h0;
                    invalidating <= 1'b0;
                    o_wb_lock <= 1'b0;
                    invalidate_counter <= 6'h0;
                end else begin
                    invalidating <= 1'b1;
                    invalidate_counter <= invalidate_counter + 1;
                end
            end
            default: state <= 3'h0;
        endcase
    end
end

endmodule