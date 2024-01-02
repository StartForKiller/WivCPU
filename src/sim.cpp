#include <verilated.h>

#include "Vtop.h"
#include "testbench.h"

#define JTAG_DTMCS 0x10
#define JTAG_DMI 0x11

class VTopTestBench : public TESTBENCH<Vtop> {
private:
    uint8_t current_ir = 0x1E;
public:
    VTopTestBench() {
        Core->i_clk_manual_switch = 1;
    }

    virtual void tick() {
        TESTBENCH<Vtop>::tick();
    }

    uint64_t testValue() {
        return Core->o_test;
    }

    void clockJTag() {
        Core->i_tck = 1;
        tick();
        Core->i_tck = 0;
        tick();
    }

    void resetJTag() {
        Core->i_tms = 1;
        for(int i = 0; i < 5; i++)
            clockJTag();

        Core->i_tms = 0;
        clockJTag();
    }

    void setJTagIR(uint8_t IR) {
        if(IR == current_ir) return;

        Core->i_tms = 1;
        clockJTag();
        clockJTag();
        Core->i_tms = 0;
        clockJTag();
        clockJTag();
        for(int i = 0; i < 5; i++) {
            Core->i_tdi = IR & 0x1;
            IR >>= 1;

            if(i == 4) {
                Core->i_tms = 1;
            }
            clockJTag();
        }
        clockJTag();
        Core->i_tms = 0;
        clockJTag();

        current_ir = IR;
    }

    void sendJTagCommand(uint8_t address, uint32_t data, uint8_t op, bool print = false) {
        if(print)
            printf("DMI Request  [Address: 0x%02X, Data: 0x%08X, Oper: %s]\n",
                address, data, op == 0 ? "Nop" : (op == 1 ? "Read" : (op == 2 ? "Write" : "Reserved")));

        uint64_t jtagData = ((uint64_t)address << 34) | ((uint64_t)data << 2) | op;

        setJTagIR(JTAG_DMI);
        Core->i_tms = 1;
        clockJTag();
        Core->i_tms = 0;
        clockJTag();
        clockJTag();
        for(int i = 0; i < 41; i++) {
            Core->i_tdi = jtagData & 0x1;
            jtagData >>= 1;

            if(i == 40) {
                Core->i_tms = 1;
            }
            clockJTag();
        }
        clockJTag();
        Core->i_tms = 0;
        clockJTag();
    }

    uint64_t readJTagCommand() {
        uint64_t jtagData = 0;

        setJTagIR(JTAG_DMI);
        Core->i_tms = 1;
        clockJTag();
        Core->i_tms = 0;
        clockJTag();
        clockJTag();
        for(int i = 0; i < 41; i++) {
            Core->i_tdi = 0;
            jtagData >>= 1;
            jtagData |= (uint64_t)Core->o_tdo << 40;

            if(i == 40) {
                Core->i_tms = 1;
            }
            clockJTag();
        }
        clockJTag();
        Core->i_tms = 0;
        clockJTag();

        return jtagData;
    }

    uint32_t readJTagStatus() {
        uint32_t jtagData = 0;

        setJTagIR(JTAG_DTMCS);
        Core->i_tms = 1;
        clockJTag();
        Core->i_tms = 0;
        clockJTag();
        clockJTag();
        for(int i = 0; i < 32; i++) {
            Core->i_tdi = 0;
            jtagData >>= 1;
            jtagData |= (uint32_t)Core->o_tdo << 31;

            if(i == 31) {
                Core->i_tms = 1;
            }
            clockJTag();
        }
        clockJTag();
        Core->i_tms = 0;
        clockJTag();

        return jtagData;
    }

    void sendJTagControl(bool hard_reset, bool reset) {
        uint32_t jtagData = ((uint32_t)hard_reset << 17) | ((uint32_t)reset << 16);

        setJTagIR(JTAG_DTMCS);
        Core->i_tms = 1;
        clockJTag();
        Core->i_tms = 0;
        clockJTag();
        clockJTag();
        for(int i = 0; i < 32; i++) {
            Core->i_tdi = jtagData & 0x1;
            jtagData >>= 1;

            if(i == 31) {
                Core->i_tms = 1;
            }
            clockJTag();
        }
        clockJTag();
        Core->i_tms = 0;
        clockJTag();
    }
};

void printDMIResponse(uint64_t response) {
    uint8_t address = response >> 34;
    uint32_t data = response >> 2;
    uint8_t state = response & 0x3;
    printf("DMI Response [Address: 0x%02X, Data: 0x%08X, State: %s]\n",
        address, data, state == 0 ? "Success" : (state == 1 ? "Reserved" : (state == 2 ? "Fail" : "Busy")));
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    VTopTestBench *tb = new VTopTestBench;
    tb->opentrace("/mnt/c/Users/jesus/Documents/Vivado/WivCPU/tracefiles/trace.vcd");

    tb->setMaxTicks(10000);

    tb->reset();
    tb->resetJTag();

    bool failed = true;
    while(!tb->done()) {
        tb->tick();

        uint64_t testValue = tb->testValue();
        if((testValue & 0x539) == 0x539) {
            printf("Other exception found\n");
            break;
        } else if(testValue != 0) {
            if(testValue != 1) {
                if(testValue & 0x1)
                    printf("Test %lu failed\n", (testValue >> 1));
                else
                    printf("Unknown test value %lu\n", testValue);
            } else {
                printf("Test success\n");
                failed = false;
            }
            break;
        }
    }

    tb->close();

    if(failed)
        printf("Test failed or stalled\n");
    return failed ? -1 : 0;
}