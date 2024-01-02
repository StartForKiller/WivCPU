`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 18.11.2023 18:04:23
// Design Name:
// Module Name:
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

package WivDefines;

typedef struct packed {
    bit valid;
    bit [63:0] PC;
    bit [31:0] instruction;
} IF_ID_t;

typedef struct packed {
    bit        valid;
    bit [63:0] PC;
    bit [6:0]  opcode;
    bit [2:0]  funct3;
    bit [6:0]  funct7;
    bit [63:0] dat_a;
    bit [63:0] dat_b;
    bit [4:0]  rd;
    bit [11:0] csr;
    bit        we;
    bit        ld;
    bit        st;
    bit        jmp;
    bit        invalidate_icache;
    bit        invalidate_dcache;
    bit        csr_st;
    bit        amo;
    bit        trap;
} ID_EX_t;

typedef struct packed {
    bit        valid;
    bit [63:0] PC;
    bit [2:0]  funct3;
    bit [4:0]  funct5;
    bit [63:0] data;
    bit [63:0] addr;
    bit [4:0]  rd;
    bit [11:0] csr;
    bit [63:0] csr_data;
    bit        we;
    bit        ld;
    bit        st;
    bit        csr_st;
    bit        amo;
} EX_MEM_t;

typedef struct packed {
    bit        valid;
    bit [63:0] PC;
    bit [63:0] data;
    bit [4:0]  rd;
    bit        we;
} MEM_WB_t;

typedef enum bit [6:0] {
    LOAD      = 7'h3,
    LOAD_FP   = 7'h7,
    CUSTOM_0  = 7'hB,
    MISC_MEM  = 7'hF,
    OP_IMM    = 7'h13,
    AUIPC     = 7'h17,
    OP_IMM_32 = 7'h1B,
    RESERVED0 = 7'h1F,
    STORE     = 7'h23,
    STORE_FP  = 7'h27,
    CUSTOM_1  = 7'h2B,
    AMO       = 7'h2F,
    OP        = 7'h33,
    LUI       = 7'h37,
    OP_32     = 7'h3B,
    RESERVED1 = 7'h3F,
    MADD      = 7'h43,
    MSUB      = 7'h47,
    NMSUB     = 7'h4B,
    NMADD     = 7'h4F,
    OP_FP     = 7'h53,
    RESERVED2 = 7'h57,
    CUSTOM_2  = 7'h5B,
    RESERVED3 = 7'h5F,
    BRANCH    = 7'h63,
    JALR      = 7'h67,
    RESERVED4 = 7'h6B,
    JAL       = 7'h6F,
    SYSTEM    = 7'h73,
    RESERVED5 = 7'h77,
    CUSTOM_3  = 7'h7B,
    RESERVED6 = 7'h7F
} opcode_type_t;

typedef enum bit [1:0] {
    C0        = 2'h0,
    C1        = 2'h1,
    C2        = 2'h2
} cop_type_t;

typedef enum bit [2:0] {
    C_ADDI4SPN= 3'h0,
    C_FLD     = 3'h1,
    C_LW      = 3'h2,
    C_LD      = 3'h3,
    C_RESERVED= 3'h4,
    C_FSD     = 3'h5,
    C_SW      = 3'h6,
    C_SD      = 3'h7
} cfunct3_c0_type_t;

typedef enum bit [2:0] {
    C_ADDI    = 3'h0,
    C_ADDIW   = 3'h1,
    C_LI      = 3'h2,
    C_LUI     = 3'h3,
    C_ALU     = 3'h4,
    C_J       = 3'h5,
    C_BEQZ    = 3'h6,
    C_BNEZ    = 3'h7
} cfunct3_c1_type_t;

typedef enum bit [2:0] {
    C_SLLI    = 3'h0,
    C_FLDSP   = 3'h1,
    C_LWSP    = 3'h2,
    C_LDSP    = 3'h3,
    C_SPECIAL = 3'h4,
    C_FSDSP   = 3'h5,
    C_SWSP    = 3'h6,
    C_SDSP    = 3'h7
} cfunct3_c2_type_t;

typedef enum bit [2:0] {
    ADDI      = 3'h0,
    SLLI      = 3'h1,
    SLTI      = 3'h2,
    SLTIU     = 3'h3,
    XORI      = 3'h4,
    SRLI_SRAI = 3'h5,
    ORI       = 3'h6,
    ANDI      = 3'h7
} funct3_type_t;

typedef enum bit [2:0] {
    LB_SB     = 3'h0,
    LH_SH     = 3'h1,
    LW_SW     = 3'h2,
    LD_SD     = 3'h3,
    LBU       = 3'h4,
    LHU       = 3'h5,
    LWU       = 3'h6
} funct3_ld_type_t;

typedef enum bit [2:0] {
    FENCE     = 3'h0,
    FENCE_I   = 3'h1
} funct3_misc_mem_type_t;

typedef enum bit [2:0] {
    PRIV      = 3'h0,
    CSRRW     = 3'h1,
    CSRRS     = 3'h2,
    CSRRC     = 3'h3,
    CSRRWI    = 3'h5,
    CSRRSI    = 3'h6,
    CSRRCI    = 3'h7
} funct3_system_type_t;

typedef enum bit [11:0] {
    ECALL      = 12'h000,
    EBREAK     = 12'h001,
    MRET       = 12'h302
} funct12_system_type_t;

typedef enum bit [4:0] {
    AMOADD     = 5'h00,
    AMOSWAP    = 5'h01,
    LR         = 5'h02,
    SC         = 5'h03,
    AMOXOR     = 5'h04,
    AMOOR      = 5'h08,
    AMOAND     = 5'h0C,
    AMOMIN     = 5'h10,
    AMOMAX     = 5'h14,
    AMOMINU    = 5'h18,
    AMOMAXU    = 5'h1C
} funct5_amo_type_t;

typedef enum bit [1:0] {
    PMP_MODE_OFF    = 2'h0,
    PMP_MODE_TOR    = 2'h1,
    PMP_MODE_NA4    = 2'h2,
    PMP_MODE_NAPOT  = 2'h3
} pmp_cfg_mode_t;

typedef struct packed {
    bit             lock;
    pmp_cfg_mode_t  mode;
    bit             exec;
    bit             write;
    bit             read;
} pmp_cfg_t;

typedef enum bit [1:0] {
    PMP_REQ_EXEC    = 2'h0,
    PMP_REQ_READ    = 2'h1,
    PMP_REQ_WRITE   = 2'h2
} pmp_req_type_t;

endpackage: WivDefines
