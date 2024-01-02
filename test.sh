#/bin/sh
make -C samples/riscv-tests --no-print-directory

tests=("rv64ui/simple.hex"
       "rv64ui/add.hex"
       "rv64ui/simple.hex"
       "rv64ui/add.hex"
       "rv64ui/addi.hex"
       "rv64ui/addiw.hex"
       "rv64ui/addw.hex"
       "rv64ui/and.hex"
       "rv64ui/andi.hex"
       "rv64ui/auipc.hex"
       "rv64ui/beq.hex"
       "rv64ui/bge.hex"
       "rv64ui/bgeu.hex"
       "rv64ui/blt.hex"
       "rv64ui/bltu.hex"
       "rv64ui/bne.hex"
       "rv64ui/fence_i.hex"
       "rv64ui/jal.hex"
       "rv64ui/jalr.hex"
       "rv64ui/lb.hex"
       "rv64ui/lbu.hex"
       "rv64ui/ld.hex"
       "rv64ui/lh.hex"
       "rv64ui/lhu.hex"
       "rv64ui/lui.hex"
       "rv64ui/lw.hex"
       "rv64ui/lwu.hex"
       "rv64ui/or.hex"
       "rv64ui/ori.hex"
       "rv64ui/sb.hex"
       "rv64ui/sd.hex"
       "rv64ui/sh.hex"
       "rv64ui/sll.hex"
       "rv64ui/slli.hex"
       "rv64ui/slliw.hex"
       "rv64ui/sllw.hex"
       "rv64ui/slt.hex"
       "rv64ui/slti.hex"
       "rv64ui/sltiu.hex"
       "rv64ui/sltu.hex"
       "rv64ui/sra.hex"
       "rv64ui/srai.hex"
       "rv64ui/sraiw.hex"
       "rv64ui/sraw.hex"
       "rv64ui/srl.hex"
       "rv64ui/srli.hex"
       "rv64ui/srliw.hex"
       "rv64ui/srlw.hex"
       "rv64ui/sub.hex"
       "rv64ui/subw.hex"
       "rv64ui/sw.hex"
       "rv64ui/xor.hex"
       "rv64ui/xori.hex"

       "rv64mi/access.hex"
       "rv64mi/csr.hex"
       "rv64mi/illegal.hex"
       "rv64mi/ld-misaligned.hex"
       "rv64mi/lh-misaligned.hex"
       "rv64mi/lw-misaligned.hex"
       "rv64mi/ma_addr.hex"
       "rv64mi/ma_fetch.hex"
       "rv64mi/mcsr.hex"
       "rv64mi/sbreak.hex"
       "rv64mi/scall.hex"
       "rv64mi/sd-misaligned.hex"
       "rv64mi/sh-misaligned.hex"
       "rv64mi/sw-misaligned.hex"

       "rv64uc/rvc.hex"

       "rv64ua/amoadd_d.hex"
       "rv64ua/amoadd_w.hex"
       "rv64ua/amoand_d.hex"
       "rv64ua/amoand_w.hex"
       "rv64ua/amomax_d.hex"
       "rv64ua/amomax_w.hex"
       "rv64ua/amomaxu_d.hex"
       "rv64ua/amomaxu_w.hex"
       "rv64ua/amomin_d.hex"
       "rv64ua/amomin_w.hex"
       "rv64ua/amominu_d.hex"
       "rv64ua/amominu_w.hex"
       "rv64ua/amoor_d.hex"
       "rv64ua/amoor_w.hex"
       "rv64ua/amoswap_d.hex"
       "rv64ua/amoswap_w.hex"
       "rv64ua/amoxor_d.hex"
       "rv64ua/amoxor_w.hex"
       "rv64ua/lrsc.hex"
      )

for str in ${tests[@]}; do
    echo "Running test: $str"
    cp samples/riscv-tests/build/$str samples/program.hex
    ./build/wivcpu
done