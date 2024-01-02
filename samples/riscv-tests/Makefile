OBJ_DIR := build

VPATH := $(SRC_DIRS)

# RV64I
TESTS := rv64ui/simple.S
TESTS += rv64ui/add.S
TESTS += rv64ui/addi.S
TESTS += rv64ui/addiw.S
TESTS += rv64ui/addw.S
TESTS += rv64ui/and.S
TESTS += rv64ui/andi.S
TESTS += rv64ui/auipc.S
TESTS += rv64ui/beq.S
TESTS += rv64ui/bge.S
TESTS += rv64ui/bgeu.S
TESTS += rv64ui/blt.S
TESTS += rv64ui/bltu.S
TESTS += rv64ui/bne.S
TESTS += rv64ui/jal.S
TESTS += rv64ui/jalr.S
TESTS += rv64ui/lb.S
TESTS += rv64ui/lbu.S
TESTS += rv64ui/ld.S
TESTS += rv64ui/lh.S
TESTS += rv64ui/lhu.S
TESTS += rv64ui/lui.S
TESTS += rv64ui/lw.S
TESTS += rv64ui/lwu.S
TESTS += rv64ui/or.S
TESTS += rv64ui/ori.S
TESTS += rv64ui/sb.S
TESTS += rv64ui/sd.S
TESTS += rv64ui/sh.S
TESTS += rv64ui/sll.S
TESTS += rv64ui/slli.S
TESTS += rv64ui/slliw.S
TESTS += rv64ui/sllw.S
TESTS += rv64ui/slt.S
TESTS += rv64ui/slti.S
TESTS += rv64ui/sltiu.S
TESTS += rv64ui/sltu.S
TESTS += rv64ui/sra.S
TESTS += rv64ui/srai.S
TESTS += rv64ui/sraiw.S
TESTS += rv64ui/sraw.S
TESTS += rv64ui/srl.S
TESTS += rv64ui/srli.S
TESTS += rv64ui/srliw.S
TESTS += rv64ui/srlw.S
TESTS += rv64ui/sub.S
TESTS += rv64ui/subw.S
TESTS += rv64ui/sw.S
TESTS += rv64ui/xor.S
TESTS += rv64ui/xori.S

# Zifencei
TESTS += rv64ui/fence_i.S

# C
TESTS += rv64uc/rvc.S

# A
TESTS += rv64ua/amoadd_d.S
TESTS += rv64ua/amoadd_w.S
TESTS += rv64ua/amoand_d.S
TESTS += rv64ua/amoand_w.S
TESTS += rv64ua/amomax_d.S
TESTS += rv64ua/amomax_w.S
TESTS += rv64ua/amomaxu_d.S
TESTS += rv64ua/amomaxu_w.S
TESTS += rv64ua/amomin_d.S
TESTS += rv64ua/amomin_w.S
TESTS += rv64ua/amominu_d.S
TESTS += rv64ua/amominu_w.S
TESTS += rv64ua/amoor_d.S
TESTS += rv64ua/amoor_w.S
TESTS += rv64ua/amoswap_d.S
TESTS += rv64ua/amoswap_w.S
TESTS += rv64ua/amoxor_d.S
TESTS += rv64ua/amoxor_w.S
TESTS += rv64ua/lrsc.S

# M-Mode
TESTS += rv64mi/access.S
TESTS += rv64mi/csr.S
TESTS += rv64mi/illegal.S
TESTS += rv64mi/ld-misaligned.S
TESTS += rv64mi/lh-misaligned.S
TESTS += rv64mi/lw-misaligned.S
TESTS += rv64mi/ma_addr.S
TESTS += rv64mi/ma_fetch.S
TESTS += rv64mi/mcsr.S
TESTS += rv64mi/sbreak.S
TESTS += rv64mi/scall.S
TESTS += rv64mi/sd-misaligned.S
TESTS += rv64mi/sh-misaligned.S
TESTS += rv64mi/sw-misaligned.S

OBJ += $(addprefix $(OBJ_DIR)/,$(addsuffix .hex.elf,$(basename $(TESTS))))
ROMS += $(addprefix $(OBJ_DIR)/,$(addsuffix .hex,$(basename $(TESTS))))

all: $(ROMS)

$(OBJ_DIR)/%.hex: riscv-tests/isa/%.S
	@mkdir -p $(dir $@)
	@riscv64-unknown-elf-gcc -march=rv64ia -mabi=lp64 -Iriscv-tests/env/p -Iriscv-tests/isa/macros/scalar -o $@.elf -nostartfiles -nodefaultlibs -nostdlib -Tlink.ld $<
	@riscv64-unknown-elf-objcopy -O verilog --verilog-data-width=8 $@.elf $@

clean_obj:
	@rm -f $(OBJ)
clean:
	@rm -f $(OBJ) $(ROMS)
