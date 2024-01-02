# WIV64, thrid attempt on implementing RISC-V

WIV64 is a pipelined RISC-V CPU currently supporting `RV64IAC_Zicsr_Zifencei`

This is my third attempt to implement a RV64I ISA and learning in the process.
Keep in mind this is a hobby-like project so it can contain bugs on things outside the core itself.

Features:
- RV64IAC_Zicsr_Zifencei
- Instruction cache and data cache(4KB each)
- M-mode
- DM non-ISA extension conforming to the "Minimal RISC-V Debug Specification 1.0-STABLE"
- JTAG-TAP (DM can access all GPRs and CSRs and Abstract Access Memory when core is halted)

Sample implementation features:
- Onboard BRAM as RAM/ROM
- DDR3 controller interface for Xilinx MIG7
- Simple UART Tx
- Simple Spi controller (supports all modes)
- Test register, for riscv tests(not on implementation)
- Debug 7Seg outputting the state of the core

Unsupported fatures:
- `M` extension, converting it to RV64GC
- U-mode
- S-mode
- Convert caches to BRAM
- Maybe more things

# License
Copyright © 2024, Jesús Sanz del Rey

<p xmlns:cc="http://creativecommons.org/ns#" xmlns:dct="http://purl.org/dc/terms/"><a property="dct:title" rel="cc:attributionURL" href="https://github.com/StartForKiller/WivCPU">WIV64</a> by <a rel="cc:attributionURL dct:creator" property="cc:attributionName" href="https://www.linkedin.com/in/jes%C3%BAs-sanz-del-rey-138338257/">Jesús Sanz del Rey</a> is licensed under <a href="http://creativecommons.org/licenses/by-nc-sa/4.0/?ref=chooser-v1" target="_blank" rel="license noopener noreferrer" style="display:inline-block;">Attribution-NonCommercial-ShareAlike 4.0 International

<img style="height:22px!important;margin-left:3px;vertical-align:text-bottom;" src="https://mirrors.creativecommons.org/presskit/icons/cc.svg?ref=chooser-v1"><img style="height:22px!important;margin-left:3px;vertical-align:text-bottom;" src="https://mirrors.creativecommons.org/presskit/icons/by.svg?ref=chooser-v1"><img style="height:22px!important;margin-left:3px;vertical-align:text-bottom;" src="https://mirrors.creativecommons.org/presskit/icons/nc.svg?ref=chooser-v1"><img style="height:22px!important;margin-left:3px;vertical-align:text-bottom;" src="https://mirrors.creativecommons.org/presskit/icons/sa.svg?ref=chooser-v1"></a></p>

If another type of license is needed contact me directly.