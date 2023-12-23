`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 18.11.2023 17:16:48
// Design Name:
// Module Name: core_id
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

module core_id(
    input i_clk,
    input i_reset,

    input  IF_ID_t  i_IF_ID,
    output ID_EX_t  o_ID_EX,
    input  EX_MEM_t i_EX_MEM,
    input  MEM_WB_t i_MEM_WB,

    input           i_dcache_invalidating,
    input           i_icache_invalidating,

    //Debug module
    input         i_reg_access,
    input         i_reg_we,
    input  [63:0] i_reg_data,
    output [63:0] o_reg_data,
    input  [12:0] i_reg_addr,

    input  i_stall,
    output o_dependency,

    input  [63:0] i_debug_PC,
    output [63:0] o_mtime,
    output [63:0] o_mtimecmp,
    input  [63:0] i_mtime,
    input  [63:0] i_mtimecmp,
    input         i_mtime_we,
    input         i_mtimecmp_we,
    output [63:0] o_dpc,
    input         i_halted,

    output [63:0]     o_mtvec,
    output [63:0]     o_mcause
);

ID_EX_t ID_EX;
assign o_ID_EX = ID_EX;

wire [31:0] instruction = i_IF_ID.instruction;

//Instruction defines
wire [6:0] opcode = instruction[6:0];
wire [4:0] rd = instruction[11:7];
wire [2:0] funct3 = instruction[14:12];
wire [4:0] rs1 = instruction[19:15];
wire [4:0] rs2 = instruction[24:20];
wire [6:0] funct7 = instruction[31:25];
wire [63:0] imm_i = {{53{instruction[31:31]}}, instruction[30:20]};
wire [63:0] imm_s = {{53{instruction[31:31]}}, instruction[30:25], instruction[11:7]};
wire [63:0] imm_b = {{52{instruction[31:31]}}, instruction[7:7], instruction[30:25], instruction[11:8], 1'b0};
wire [63:0] imm_u = {{33{instruction[31:31]}}, instruction[30:12], 12'h0};
wire [63:0] imm_j = {{44{instruction[31:31]}}, instruction[19:12], instruction[20:20], instruction[30:21], 1'b0};

//compressed data
wire [1:0]  cop       = instruction[1:0];
wire is_compressed    = cop != 2'b11;
wire [1:0]  cfunct2   = instruction[6:5];
wire [2:0]  cfunct3   = instruction[15:13];
wire [3:0]  cfunct4   = instruction[15:12];
wire [5:0]  cfunct6   = instruction[15:10];
wire [4:0]  crs1      = instruction[11:7];
wire [4:0]  crs1p     = {2'b01, instruction[9:7]};
wire [4:0]  crs2      = instruction[6:2];
wire [4:0]  crs2p     = {2'b01, instruction[4:2]};
wire [5:0]  imm_ci    = {instruction[12:12], instruction[6:2]};
wire [5:0]  imm_css   = instruction[12:7];
wire [7:0]  imm_ciw   = instruction[12:5];
wire [4:0]  imm_cl_cs = {instruction[12:10], instruction[6:5]};
wire [7:0]  imm_cb    = {instruction[12:10], instruction[6:2]};
wire [10:0] imm_cj    = {instruction[12:2]};

//csr
wire [11:0] csr_addr = !i_reg_access ? instruction[31:20] : i_reg_addr[11:0];
wire        csr_ld   = ((opcode == SYSTEM) && !((funct3 == CSRRW || funct3 == CSRRWI) && (rd == 0))) || (i_reg_access && !i_reg_addr[12:12] && !i_reg_we);
wire [63:0] csr_data;
wire        csr_trap;
wire [63:0] mepc;
reg  [63:0] mepc_data;
reg         mepc_we;
reg  [63:0] mcause_data;
reg         mcause_we;

wire [4:0]  sel_a = !i_reg_access ?
                    (!is_compressed ? rs1 : (((cop == C1 &&
                                                (cfunct3 == C_LI    ||
                                                 cfunct3 == C_LUI   ||
                                                 cfunct3 == C_ADDI  ||
                                                 cfunct3 == C_ADDIW)) ||
                                            (cop == C2 &&
                                                (cfunct3 == C_SLLI    ||
                                                 cfunct3 == C_SPECIAL))) ?
                                                    crs1 : (((cop == C2 && (
                                                        cfunct3 == C_SWSP ||
                                                        cfunct3 == C_SDSP ||
                                                        cfunct3 == C_LWSP ||
                                                        cfunct3 == C_LDSP
                                                    )) || (cop == C0 && cfunct3 == C_ADDI4SPN)) ? 5'h2 : crs1p))) :
                    i_reg_addr[4:0];
wire [4:0]  sel_b = !is_compressed ? rs2 : (cop == C2 ? crs2 : crs2p);
wire [63:0] dat_a;
wire [63:0] dat_b;
wire dat_equal = dat_a == dat_b;
wire dat_less = $signed(dat_a) < $signed(dat_b);
wire dat_less_unsigned = dat_a < dat_b;

wire load_misaligned = ((funct3 == LH_SH || funct3 == LHU) && (dat_a[0:0] ^ imm_i[0:0])) ||
                       ((funct3 == LW_SW || funct3 == LWU) && (2'(dat_a[1:0] + imm_i[1:0]) != 2'h0)) ||
                       (funct3 == LD_SD && (3'(dat_a[2:0] + imm_i[2:0]) != 3'h0));
wire store_misaligned = (funct3 == LH_SH && (dat_a[0:0] ^ imm_s[0:0])) ||
                        (funct3 == LW_SW && (2'(dat_a[1:0] + imm_s[1:0]) != 2'h0)) ||
                        (funct3 == LD_SD && (3'(dat_a[2:0] + imm_s[2:0]) != 3'h0));

regfile regs(
    .i_clk(i_clk),
    .i_reset(i_reset),

    .i_sel_a(sel_a),
    .i_sel_b(sel_b),
    .o_dat_a(dat_a),
    .o_dat_b(dat_b),
    .i_sel_w(i_MEM_WB.rd),
    .i_dat_w(!i_reg_access ? i_MEM_WB.data : i_reg_data),
    .i_we(i_MEM_WB.we || (i_reg_access && i_reg_addr[12:12] && i_reg_we))
);

wire [63:0] mie;
wire [63:0] mip;
wire        mstatus_mie;
reg         mie_clear;
reg         restore_mie;
csrfile csrs(
    .i_clk(i_clk),
    .i_reset(i_reset),

    .i_ld_csr(csr_addr),
    .i_st_csr(!i_reg_access ? i_EX_MEM.csr : i_reg_addr[11:0]),
    .i_data(!i_reg_access ? i_EX_MEM.csr_data : i_reg_data),
    .o_data(csr_data),
    .i_ld(csr_ld),
    .i_st(i_EX_MEM.csr_st || (i_reg_access && !i_reg_addr[12:12] && i_reg_we)),

    .o_trap(csr_trap),

    .o_mtvec(o_mtvec),
    .o_mcause(o_mcause),
    .o_mepc(mepc),
    .i_mepc_data(mepc_data),
    .i_mepc_we(mepc_we),
    .i_mcause_data(mcause_data),
    .i_mcause_we(mcause_we),
    .o_mie(mie),
    .o_mstatus_mie(mstatus_mie),
    .o_mip(mip),
    .i_mie_clear(mie_clear),
    .i_mie_restore(restore_mie),
    .o_mtime(o_mtime),
    .o_mtimecmp(o_mtimecmp),
    .i_mtime(i_mtime),
    .i_mtimecmp(i_mtimecmp),
    .i_mtime_we(i_mtime_we),
    .i_mtimecmp_we(i_mtimecmp_we),

    .i_debug_PC(i_debug_PC),
    .o_dpc(o_dpc),
    .i_halted(i_halted)
);

assign o_reg_data = i_reg_addr[12:12] ? dat_a : csr_data;

reg [1:0] invalidating_state;

initial begin
    ID_EX.valid = 0;
    ID_EX.PC = 64'h0;

    ID_EX.dat_a = 64'h0;
    ID_EX.dat_b = 64'h0;
    ID_EX.rd = 5'h0;
    ID_EX.we = 1'b0;
    ID_EX.ld = 1'b0;
    ID_EX.st = 1'b0;
    ID_EX.funct3 = 3'h0;
    ID_EX.funct7 = 7'h0;
    ID_EX.opcode = 7'h0;
    ID_EX.jmp = 1'b0;
    ID_EX.invalidate_icache = 1'b0;
    ID_EX.invalidate_dcache = 1'b0;
    ID_EX.csr = 12'h0;
    ID_EX.csr_st = 1'b0;
    ID_EX.trap = 1'b0;

    mepc_data = 64'h0;
    mepc_we = 1'b0;
    mie_clear = 1'b0;
    mie_clear = 1'b0;
    restore_mie = 1'b0;

    invalidating_state = 2'h0;
end

wire same_rs1 = sel_a != 5'h0 &&
                ((ID_EX.we    && ID_EX.rd == sel_a   ) ||
                ( i_EX_MEM.we && i_EX_MEM.rd == sel_a) ||
                ( i_MEM_WB.we && i_MEM_WB.rd == sel_a));
wire same_rs2 = sel_b != 5'h0 &&
                ((ID_EX.we    && ID_EX.rd == sel_b   ) ||
                ( i_EX_MEM.we && i_EX_MEM.rd == sel_b) ||
                ( i_MEM_WB.we && i_MEM_WB.rd == sel_b));
wire same_csr = (csr_ld &&
                ((ID_EX.csr_st     && ID_EX.csr == csr_addr   ) ||
                ( i_EX_MEM.csr_st  && i_EX_MEM.csr == csr_addr))
                ) ||
                ((ID_EX.csr_st     && ID_EX.csr == 12'h341   ) || //Quick patch to be able to wait until mepc is ready with data
                ( i_EX_MEM.csr_st  && i_EX_MEM.csr == 12'h341));

wire hazards = (same_rs1 &&
                    (opcode == OP        ||
                     opcode == OP_32     ||
                     opcode == OP_IMM    ||
                     opcode == OP_IMM_32 ||
                     opcode == BRANCH    ||
                     opcode == JALR      ||
                     opcode == LOAD      ||
                     opcode == STORE     ||
                    (opcode == SYSTEM && funct3 != 3'h0 && funct3 != 3'h4) ||
                    (is_compressed &&
                    (
                        (cop == C0 && funct3 != 0) ||
                        (cop == C1 &&
                        (
                            (cfunct3 == C_ADDI && crs1 != 0 && imm_ci != 0) ||
                            cfunct3 == C_ADDIW ||
                            cfunct3 == C_BEQZ ||
                            cfunct3 == C_BNEZ ||
                            cfunct3 == C_ALU
                        )) ||
                        (cop == C2 &&
                        (
                            cfunct3 == C_SLLI ||
                            cfunct3 == C_SPECIAL
                        ))
                    )))) ||
               (same_rs2 &&
                    (opcode == OP        ||
                     opcode == OP_32     ||
                     opcode == BRANCH    ||
                     opcode == STORE ||
                     (is_compressed &&
                     (
                        (cop == C2 &&
                        (
                            cfunct3 == C_SPECIAL ||
                            cfunct3 == C_SWSP ||
                            cfunct3 == C_SDSP
                        ))
                     )))) ||
               (same_csr &&
                    (opcode == SYSTEM));

wire branch_taken = (funct3[2:1] == 2'h0) ?
                        (dat_equal ^ funct3[0:0]) :
                        ((funct3[2:2]) ?
                            ((funct3[1:1]) ?
                                dat_less_unsigned ^ funct3[0:0] :
                                dat_less ^ funct3[0:0])
                            : 1'b0);

//JAL and JALR makes if to not push next instruction and jump instead
assign o_dependency = hazards ||
                        (opcode == JAL  ||
                         opcode == JALR ||
                         (opcode == BRANCH && branch_taken) ||
                         (opcode == MISC_MEM && funct3 == FENCE_I && invalidating_state != 2'h3));

always @(posedge i_clk) begin
    if(i_reset) begin
        ID_EX.valid <= 1'b0;
        ID_EX.PC <= 64'h0;

        ID_EX.dat_a <= 64'h0;
        ID_EX.dat_b <= 64'h0;
        ID_EX.rd <= 5'h0;
        ID_EX.we <= 1'b0;
        ID_EX.ld <= 1'b0;
        ID_EX.st <= 1'b0;
        ID_EX.funct3 <= 3'h0;
        ID_EX.funct7 <= 7'h0;
        ID_EX.opcode <= 7'h0;
        ID_EX.jmp <= 1'b0;
        ID_EX.invalidate_icache <= 1'b0;
        ID_EX.invalidate_dcache <= 1'b0;
        ID_EX.csr <= 12'h0;
        ID_EX.csr_st <= 1'b0;
        ID_EX.trap <= 1'b0;

        mepc_data <= 64'h0;
        mepc_we <= 1'b0;
        mcause_data <= 64'h0;
        mcause_we <= 1'b0;
        mie_clear <= 1'b0;
        restore_mie <= 1'b0;

        invalidating_state <= 2'h0;
    end
    else begin
        if(!i_stall) begin
            ID_EX.valid <= !hazards && i_IF_ID.valid && !ID_EX.trap && !ID_EX.jmp && !i_stall;

            ID_EX.funct3 <= 3'h0;
            ID_EX.funct7 <= 7'h0;
            ID_EX.opcode <= 7'h0;
            ID_EX.dat_a <= 64'h0;
            ID_EX.dat_b <= 64'h0;
            ID_EX.rd <= 5'h0;
            ID_EX.we <= 1'b0;
            ID_EX.ld <= 1'b0;
            ID_EX.st <= 1'b0;
            ID_EX.jmp <= 1'b0;
            ID_EX.csr <= 12'h0;
            ID_EX.csr_st <= 1'b0;

            if(ID_EX.trap)
                ID_EX.trap <= (ID_EX.csr_st || i_EX_MEM.csr_st) && (ID_EX.csr == 12'h305 || i_EX_MEM.csr == 12'h305);

            mepc_data <= 64'h0;
            mepc_we <= 1'b0;
            mcause_data <= 64'h0;
            mcause_we <= 1'b0;
            mie_clear <= 1'b0;
            restore_mie <= 1'b0;

            invalidating_state <= 2'h0;

            if(i_IF_ID.valid && !hazards && !ID_EX.trap && !ID_EX.jmp) begin
                ID_EX.funct7 <= funct7;

                ID_EX.opcode <= opcode;

                if((mie & mip) != 0 && mstatus_mie) begin
                    ID_EX.valid <= 1'b0;
                    ID_EX.trap <= 1'b1;
                    mepc_data <= i_IF_ID.PC;
                    mepc_we <= 1'b1;
                    mcause_data <= {1'b1, mip[62:0]};
                    mcause_we <= 1'b1;
                    mie_clear <= 1'b1;
                end
                else if(is_compressed) begin
                    ID_EX.funct3 <= cfunct3;

                    case(cop)
                        C0: begin
                            case(cfunct3)
                                C_LW: begin
                                    ID_EX.dat_b <= dat_a + {57'h0, imm_cl_cs[0:0], imm_cl_cs[4:1], 2'h0};
                                    ID_EX.rd <= crs1;
                                    ID_EX.we <= 1'b1;
                                    ID_EX.ld <= 1'b1;
                                end
                                C_LD: begin
                                    ID_EX.dat_b <= dat_a + {56'h0, imm_cl_cs[1:0], imm_cl_cs[4:2], 3'h0};
                                    ID_EX.rd <= crs1;
                                    ID_EX.we <= 1'b1;
                                    ID_EX.ld <= 1'b1;
                                end
                                C_SW: begin
                                    ID_EX.dat_a <= dat_b;
                                    ID_EX.dat_b <= dat_a + {57'h0, imm_cl_cs[0:0], imm_cl_cs[4:1], 2'h0};
                                    ID_EX.st <= 1'b1;
                                end
                                C_SD: begin
                                    ID_EX.dat_a <= dat_b;
                                    ID_EX.dat_b <= dat_a + {56'h0, imm_cl_cs[1:0], imm_cl_cs[4:2], 3'h0};
                                    ID_EX.st <= 1'b1;
                                end
                                C_ADDI4SPN: begin
                                    if(imm_ciw != 0) begin
                                        ID_EX.dat_a <= dat_a;
                                        ID_EX.dat_b <= {54'h0, imm_ciw[4:2], imm_ciw[7:5], imm_ciw[0:0], imm_ciw[1:1], 2'h0};
                                        ID_EX.rd <= crs2p;
                                        ID_EX.we <= 1'b1;
                                    end else begin
                                        ID_EX.valid <= 1'b0;
                                        ID_EX.trap <= 1'b1;
                                        mepc_data <= i_IF_ID.PC;
                                        mepc_we <= 1'b1;
                                        mcause_data <= 64'h2;
                                        mcause_we <= 1'b1;
                                    end
                                end
                                default: begin
                                    ID_EX.valid <= 1'b0;
                                    ID_EX.trap <= 1'b1;
                                    mepc_data <= i_IF_ID.PC;
                                    mepc_we <= 1'b1;
                                    mcause_data <= 64'h2;
                                    mcause_we <= 1'b1;
                                end
                            endcase
                        end
                        C1: begin
                            case(cfunct3)
                                C_LI: begin
                                    if(crs1 != 0) begin //Invalid C.LI
                                        ID_EX.dat_a <= {{59{imm_ci[5:5]}}, imm_ci[4:0]};
                                        ID_EX.dat_b <= 64'h0;
                                        ID_EX.rd <= crs1;
                                        ID_EX.we <= 1'b1;
                                    end
                                end
                                C_LUI: begin
                                    if(crs1 == 2) begin
                                        //TODO: C.ADDI16SP
                                        ID_EX.dat_a <= dat_a;
                                        ID_EX.dat_b <= {{55{imm_ci[5:5]}}, imm_ci[2:1], imm_ci[3:3], imm_ci[0:0], imm_ci[4:4], 4'h0};
                                    end else if (crs1 != 0) begin
                                        ID_EX.dat_a <= {{47{imm_ci[5:5]}}, imm_ci[4:0], 12'h0};
                                        ID_EX.dat_b <= 64'h0;
                                        ID_EX.rd <= crs1;
                                        ID_EX.we <= 1'b1;
                                    end

                                    if(imm_ci == 0) begin //Invalid C.LI
                                        ID_EX.valid <= 1'b0;
                                        ID_EX.trap <= 1'b1;
                                        mepc_data <= i_IF_ID.PC;
                                        mepc_we <= 1'b1;
                                        mcause_data <= 64'h2;
                                        mcause_we <= 1'b1;
                                    end
                                end
                                C_ADDI: begin
                                    if(imm_ci != 0 && crs1 != 0) begin
                                        ID_EX.dat_a <= dat_a;
                                        ID_EX.dat_b <= {{59{imm_ci[5:5]}}, imm_ci[4:0]};
                                        ID_EX.rd <= crs1;
                                        ID_EX.we <= 1'b1;
                                    end
                                end
                                C_ADDIW: begin
                                    if(crs1 != 0) begin
                                        ID_EX.dat_a <= dat_a;
                                        ID_EX.dat_b <= {{59{imm_ci[5:5]}}, imm_ci[4:0]};
                                        ID_EX.rd <= crs1;
                                        ID_EX.we <= 1'b1;
                                    end else begin
                                        ID_EX.valid <= 1'b0;
                                        ID_EX.trap <= 1'b1;
                                        mepc_data <= i_IF_ID.PC;
                                        mepc_we <= 1'b1;
                                        mcause_data <= 64'h2;
                                        mcause_we <= 1'b1;
                                    end
                                end
                                C_J: begin
                                    ID_EX.dat_b <= {{53{imm_cj[10:10]}}, imm_cj[6:6], imm_cj[8:7], imm_cj[4:4], imm_cj[5:5], imm_cj[0:0], imm_cj[9:9], imm_cj[3:1], 1'b0} + i_IF_ID.PC;
                                    ID_EX.jmp <= 1'b1;
                                end
                                C_BEQZ: begin
                                    ID_EX.dat_b <= {{56{imm_cb[7:7]}}, imm_cb[4:3], imm_cb[0:0], imm_cb[6:5], imm_cb[2:1], 1'b0} + i_IF_ID.PC;
                                    ID_EX.jmp <= dat_a == 0;
                                end
                                C_BNEZ: begin
                                    ID_EX.dat_b <= {{56{imm_cb[7:7]}}, imm_cb[4:3], imm_cb[0:0], imm_cb[6:5], imm_cb[2:1], 1'b0} + i_IF_ID.PC;
                                    ID_EX.jmp <= dat_a != 0;
                                end
                                C_ALU: begin
                                    ID_EX.funct7 <= {2'h0, instruction[12:12], instruction[6:5], cfunct2};
                                    if(cfunct2 != 2'b11) begin
                                        ID_EX.dat_a <= dat_a;
                                        ID_EX.dat_b <= {58'h0, imm_ci};
                                        ID_EX.rd <= crs1p;
                                        ID_EX.we <= 1'b1;
                                    end else begin
                                        if(instruction[12:12] && instruction[6:6]) begin //Reserved
                                            ID_EX.valid <= 1'b0;
                                            ID_EX.trap <= 1'b1;
                                            mepc_data <= i_IF_ID.PC;
                                            mepc_we <= 1'b1;
                                            mcause_data <= 64'h2;
                                            mcause_we <= 1'b1;
                                        end else begin
                                            ID_EX.dat_a <= dat_a;
                                            ID_EX.dat_b <= dat_b;
                                            ID_EX.rd <= crs1p;
                                            ID_EX.we <= 1'b1;
                                        end
                                    end
                                end
                                default: begin
                                    ID_EX.valid <= 1'b0;
                                    ID_EX.trap <= 1'b1;
                                    mepc_data <= i_IF_ID.PC;
                                    mepc_we <= 1'b1;
                                    mcause_data <= 64'h2;
                                    mcause_we <= 1'b1;
                                end
                            endcase
                        end
                        C2: begin
                            case(cfunct3)
                                C_LWSP: begin
                                    ID_EX.dat_b <= dat_a + {56'h0, imm_ci[1:0], imm_ci[5:2], 2'h0};
                                    ID_EX.rd <= crs1;
                                    ID_EX.we <= 1'b1;
                                    ID_EX.ld <= 1'b1;
                                end
                                C_LDSP: begin
                                    ID_EX.dat_b <= dat_a + {55'h0, imm_ci[2:0], imm_ci[5:3], 3'h0};
                                    ID_EX.rd <= crs1;
                                    ID_EX.we <= 1'b1;
                                    ID_EX.ld <= 1'b1;
                                end
                                C_SWSP: begin
                                    ID_EX.dat_a <= dat_b;
                                    ID_EX.dat_b <= dat_a + {56'h0, imm_css[1:0], imm_css[5:2], 2'h0};
                                    ID_EX.st <= 1'b1;
                                end
                                C_SDSP: begin
                                    ID_EX.dat_a <= dat_b;
                                    ID_EX.dat_b <= dat_a + {55'h0, imm_css[2:0], imm_css[5:3], 3'h0};
                                    ID_EX.st <= 1'b1;
                                end
                                C_SPECIAL: begin
                                    if(instruction[12:12]) begin
                                        if(crs1 == 0) begin
                                            if(crs2 != 0) begin //Invalid C.EBREAK or C.JALR or C.ADD
                                                ID_EX.valid <= 1'b0;
                                                ID_EX.trap <= 1'b1;
                                                mepc_data <= i_IF_ID.PC;
                                                mepc_we <= 1'b1;
                                                mcause_data <= 64'h2;
                                                mcause_we <= 1'b1;
                                            end else begin // C.EBREAK
                                                ID_EX.valid <= 1'b0;
                                                ID_EX.trap <= 1'b1;
                                                mepc_data <= i_IF_ID.PC;
                                                mepc_we <= 1'b1;
                                                mcause_data <= 64'h3;
                                                mcause_we <= 1'b1;
                                            end
                                        end else if(crs2 == 0) begin
                                            ID_EX.dat_a <= i_IF_ID.PC + 2;
                                            ID_EX.dat_b <= dat_a;
                                            ID_EX.rd <= 5'h1;
                                            ID_EX.we <= 1'b1;
                                            ID_EX.jmp <= 1'b1;
                                        end else begin // C.ADD
                                            ID_EX.dat_a <= dat_a + dat_b;
                                            ID_EX.rd <= crs1;
                                            ID_EX.we <= 1'b1;
                                        end
                                    end else begin
                                        if(crs1 == 0) begin //Invalid C.JR or C.MV
                                            ID_EX.valid <= 1'b0;
                                            ID_EX.trap <= 1'b1;
                                            mepc_data <= i_IF_ID.PC;
                                            mepc_we <= 1'b1;
                                            mcause_data <= 64'h2;
                                            mcause_we <= 1'b1;
                                        end else if(crs2 == 0) begin // C.JR
                                            ID_EX.dat_b <= dat_a;
                                            ID_EX.jmp <= 1'b1;
                                        end else begin // C.MV
                                            ID_EX.dat_a <= dat_b;
                                            ID_EX.rd <= crs1;
                                            ID_EX.we <= 1'b1;
                                        end
                                    end
                                end
                                C_SLLI: begin
                                    ID_EX.dat_a <= dat_a;
                                    ID_EX.dat_b <= {58'h0, imm_ci};
                                    ID_EX.rd <= crs1;
                                    ID_EX.we <= 1'b1;
                                end
                                default: begin
                                    ID_EX.valid <= 1'b0;
                                    ID_EX.trap <= 1'b1;
                                    mepc_data <= i_IF_ID.PC;
                                    mepc_we <= 1'b1;
                                    mcause_data <= 64'h2;
                                    mcause_we <= 1'b1;
                                end
                            endcase
                        end
                        default: begin
                            ID_EX.valid <= 1'b0;
                            ID_EX.trap <= 1'b1;
                            mepc_data <= i_IF_ID.PC;
                            mepc_we <= 1'b1;
                            mcause_data <= 64'h2;
                            mcause_we <= 1'b1;
                        end
                    endcase
                end
                else begin
                    ID_EX.funct3 <= funct3;

                    case(opcode)
                        LUI: begin
                            ID_EX.dat_a <= imm_u;
                            ID_EX.dat_b <= 64'h0;
                            ID_EX.rd <= rd;
                            ID_EX.we <= 1'b1;
                        end
                        AUIPC: begin
                            ID_EX.dat_a <= imm_u;
                            ID_EX.dat_b <= i_IF_ID.PC;
                            ID_EX.rd <= rd;
                            ID_EX.we <= 1'b1;
                        end
                        OP_IMM_32,
                        OP_IMM: begin
                            ID_EX.dat_a <= dat_a;
                            ID_EX.dat_b <= imm_i;
                            ID_EX.rd <= rd;
                            ID_EX.we <= 1'b1;
                        end
                        OP_32,
                        OP: begin
                            ID_EX.dat_a <= dat_a;
                            ID_EX.dat_b <= dat_b;
                            ID_EX.rd <= rd;
                            ID_EX.we <= 1'b1;
                        end
                        JAL: begin
                            ID_EX.dat_a <= i_IF_ID.PC + 4;
                            ID_EX.dat_b <= imm_j + i_IF_ID.PC;
                            ID_EX.rd <= rd;
                            ID_EX.we <= 1'b1;
                            ID_EX.jmp <= 1'b1;
                        end
                        JALR: begin
                            ID_EX.dat_a <= i_IF_ID.PC + 4;
                            ID_EX.dat_b <= imm_i + dat_a;
                            ID_EX.rd <= rd;
                            ID_EX.we <= 1'b1;
                            ID_EX.jmp <= 1'b1;
                        end
                        LOAD: begin
                            if(load_misaligned) begin
                                mepc_data <= i_IF_ID.PC;
                                mepc_we <= 1'b1;
                                mcause_data <= 64'h4;
                                mcause_we <= 1'b1;
                            end else begin
                                ID_EX.dat_b <= dat_a + imm_i;
                                ID_EX.rd <= rd;
                                ID_EX.we <= 1'b1;
                                ID_EX.ld <= 1'b1;
                            end
                        end
                        STORE: begin
                            if(store_misaligned) begin
                                mepc_data <= i_IF_ID.PC;
                                mepc_we <= 1'b1;
                                mcause_data <= 64'h6;
                                mcause_we <= 1'b1;
                            end else begin
                                ID_EX.dat_a <= dat_b;
                                ID_EX.dat_b <= dat_a + imm_s;
                                ID_EX.st <= 1'b1;
                            end
                        end
                        BRANCH: begin
                            ID_EX.dat_b <= imm_b + i_IF_ID.PC;

                            if(funct3[2:1] == 2'b01) begin
                                ID_EX.valid <= 1'b0;
                                ID_EX.trap <= 1'b1;
                                mepc_data <= i_IF_ID.PC;
                                mepc_we <= 1'b1;
                                mcause_data <= 64'h2;
                                mcause_we <= 1'b1;
                            end else
                                ID_EX.jmp <= branch_taken;
                        end
                        MISC_MEM: begin
                            case(funct3)
                                FENCE_I: begin
                                    invalidating_state <= invalidating_state;

                                    if(!i_dcache_invalidating && invalidating_state == 2'h0) begin
                                        invalidating_state <= 2'h1;
                                        ID_EX.invalidate_dcache <= 1'b1;
                                    end
                                    if(!i_dcache_invalidating && ID_EX.invalidate_dcache) begin

                                    end else if(i_dcache_invalidating && ID_EX.invalidate_dcache) begin
                                        ID_EX.invalidate_dcache <= 1'b0;
                                    end else if(!i_dcache_invalidating && invalidating_state == 2'h1) begin
                                        invalidating_state <= 2'h2;
                                        ID_EX.invalidate_icache <= 1'b1;
                                    end

                                    if(!i_icache_invalidating && ID_EX.invalidate_icache) begin

                                    end else if(i_icache_invalidating && ID_EX.invalidate_icache) begin
                                        ID_EX.invalidate_icache <= 1'b0;
                                    end else if(!i_icache_invalidating && invalidating_state == 2'h2) begin
                                        invalidating_state <= 2'h3;
                                    end
                                end
                                default: begin
                                    ID_EX.valid <= 1'b0;
                                    ID_EX.trap <= 1'b1;
                                    mepc_data <= i_IF_ID.PC;
                                    mepc_we <= 1'b1;
                                    mcause_data <= 64'h2;
                                    mcause_we <= 1'b1;
                                end
                            endcase
                        end
                        SYSTEM: begin
                            case(funct3)
                                PRIV: begin
                                    case(imm_i[11:0])
                                        MRET: begin
                                            ID_EX.dat_b <= mepc;
                                            ID_EX.jmp <= 1'b1;
                                            restore_mie <= 1'b1;
                                        end
                                        ECALL: begin
                                            ID_EX.valid <= 1'b0;
                                            ID_EX.trap <= 1'b1;
                                            mepc_data <= i_IF_ID.PC;
                                            mepc_we <= 1'b1;
                                            mcause_data <= 64'hB;
                                            mcause_we <= 1'b1;
                                        end
                                        EBREAK: begin
                                            ID_EX.valid <= 1'b0;
                                            ID_EX.trap <= 1'b1;
                                            mepc_data <= i_IF_ID.PC;
                                            mepc_we <= 1'b1;
                                            mcause_data <= 64'h3;
                                            mcause_we <= 1'b1;
                                        end
                                        default: begin
                                            ID_EX.valid <= 1'b0;
                                            ID_EX.trap <= 1'b1;
                                            mepc_data <= i_IF_ID.PC;
                                            mepc_we <= 1'b1;
                                            mcause_data <= 64'h2;
                                            mcause_we <= 1'b1;
                                        end
                                    endcase
                                end
                                CSRRW, CSRRC, CSRRS: begin
                                    ID_EX.dat_a <= dat_a;
                                    ID_EX.dat_b <= csr_data;

                                    ID_EX.csr <= csr_addr;
                                    ID_EX.csr_st <= 1'b0;

                                    ID_EX.rd <= rd;
                                    ID_EX.we <= 1'b1;

                                    if(csr_ld && csr_addr[11:10] == 2'b11) begin
                                        ID_EX.valid <= 1'b0;
                                        ID_EX.trap <= 1'b1;
                                        mepc_data <= i_IF_ID.PC;
                                        mepc_we <= 1'b1;
                                        mcause_data <= 64'h2;
                                        mcause_we <= 1'b1;
                                    end
                                    if(!(funct3 != CSRRW && rs1 == 0)) begin
                                        if(!csr_trap) begin
                                            ID_EX.csr_st <= 1'b1;
                                        end else begin
                                            ID_EX.valid <= 1'b0;
                                            ID_EX.trap <= 1'b1;
                                            mepc_data <= i_IF_ID.PC;
                                            mepc_we <= 1'b1;
                                            mcause_data <= 64'h2;
                                            mcause_we <= 1'b1;
                                        end
                                    end
                                end
                                CSRRWI, CSRRCI, CSRRSI: begin
                                    ID_EX.dat_a <= dat_a;
                                    ID_EX.dat_b <= 64'(rs1);

                                    ID_EX.csr <= csr_addr;
                                    ID_EX.csr_st <= 1'b0;

                                    ID_EX.rd <= rd;
                                    ID_EX.we <= 1'b1;

                                    if(csr_ld && csr_addr[11:10] == 2'b11) begin
                                        ID_EX.valid <= 1'b0;
                                        ID_EX.trap <= 1'b1;
                                        mepc_data <= i_IF_ID.PC;
                                        mepc_we <= 1'b1;
                                        mcause_data <= 64'h2;
                                        mcause_we <= 1'b1;
                                    end
                                    else if(!(funct3 != CSRRWI && rs1 == 0)) begin
                                        if(!csr_trap) begin
                                            ID_EX.csr_st <= 1'b1;
                                        end else begin
                                            ID_EX.valid <= 1'b0;
                                            ID_EX.trap <= 1'b1;
                                            mepc_data <= i_IF_ID.PC;
                                            mepc_we <= 1'b1;
                                            mcause_data <= 64'h2;
                                            mcause_we <= 1'b1;
                                        end
                                    end
                                end
                                default: begin
                                    ID_EX.valid <= 1'b0;
                                    ID_EX.trap <= 1'b1;
                                    mepc_data <= i_IF_ID.PC;
                                    mepc_we <= 1'b1;
                                    mcause_data <= 64'h2;
                                    mcause_we <= 1'b1;
                                end
                            endcase
                        end
                        default: begin
                            ID_EX.valid <= 1'b0; //TODO: Illegal OPCODE
                            ID_EX.trap <= 1'b1;
                            mepc_data <= i_IF_ID.PC;
                            mepc_we <= 1'b1;
                            mcause_data <= 64'h2;
                            mcause_we <= 1'b1;
                        end
                    endcase
                end

                ID_EX.PC <= i_IF_ID.PC;
            end
        end
    end
end

endmodule