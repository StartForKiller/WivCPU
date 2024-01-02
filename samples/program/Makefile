OBJ_DIR := build

SRC_C := $(wildcard src/*/*.c) $(wildcard src/*.c) $(wildcard src/*/*/*.c) $(wildcard src/*/*/*/*.c)
SRC_ASM := $(wildcard src/*/*.s) $(wildcard src/*.s) $(wildcard src/*/*/*.s) $(wildcard src/*/*/*/*.s)
OBJ := $(addprefix $(OBJ_DIR)/,$(addsuffix .o,$(notdir $(basename $(SRC_C)))))
OBJ += $(addprefix $(OBJ_DIR)/,$(addsuffix .o,$(notdir $(basename $(SRC_ASM)))))

SRC_DIRS := $(sort $(dir $(SRC_C)))
SRC_DIRS += $(sort $(dir $(SRC_ASM)))

VPATH := $(SRC_DIRS)

all: prog.bin prog.list prog.hex

$(OBJ_DIR)/%.o: %.c
	@riscv64-unknown-elf-gcc -O2 -march=rv64ifd -Wall -Wextra -ffreestanding -mcmodel=medany $< -c  -o $@
$(OBJ_DIR)/%.o: %.s
	@riscv64-unknown-elf-as -march=rv64iafdc $< -c -o $@
prog.elf: $(OBJ)
	@echo "[Bulding]"
	@riscv64-unknown-elf-ld -Tlink.ld $^ -o build/$@
%.bin: %.elf
	@riscv64-unknown-elf-objcopy build/$< -O binary build/$@
%.list: %.elf
	@riscv64-unknown-elf-objdump -D build/$< > build/$@
%.hex: %.elf
	@/opt/riscv/bin/riscv64-unknown-elf-objcopy -O verilog --verilog-data-width=8 build/$< build/$@
clean:
	@rm -f $(OBJ_DIR)/*.bin $(OBJ_DIR)/*.list $(OBJ_DIR)/*.o $(OBJ_DIR)/*.elf $(OBJ_DIR)/*.dep *.dep

-include *.dep