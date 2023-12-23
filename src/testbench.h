#pragma once

#include <verilated.h>
#include <verilated_vcd_c.h>

template<class MODULE> class TESTBENCH {
protected:
    unsigned long TickCount;
    unsigned long MaxTickCount;
    MODULE *Core;

    VerilatedVcdC *Trace = nullptr;
    bool TraceEnabled;

public:
    TESTBENCH() {
        Verilated::traceEverOn(true);

        Core = new MODULE;
        TickCount = 0;
        MaxTickCount = 0;
        TraceEnabled = true;
    }

    virtual ~TESTBENCH() {
        delete Core;
        Core = nullptr;
    }

    virtual void opentrace(const char *vcdname) {
        if(Trace == nullptr) {
            Trace = new VerilatedVcdC();
            Core->trace(Trace, 99);
            Trace->open(vcdname);
        }
    }

    virtual void close() {
        if(Trace != nullptr) {
            Trace->close();
            Trace = nullptr;
        }
    }

    virtual void reset() {
        Core->i_reset = 1;
        this->tick();
        Core->i_reset = 0;
    }

    virtual void tick() {
        TickCount++;

        Core->i_clk = 0;
        Core->eval();

        if(Trace != nullptr && TraceEnabled) Trace->dump(10*TickCount - 2);

        Core->i_clk = 1;
        Core->eval();
        if(Trace != nullptr && TraceEnabled) Trace->dump(10*TickCount);

        Core->i_clk = 0;
        Core->eval();
        if(Trace != nullptr && TraceEnabled) {
            Trace->dump(10*TickCount + 5);
            Trace->flush();
        }
    }

    virtual void setMaxTicks(unsigned long ticks) {
        MaxTickCount = ticks;
    }

    virtual bool done() { return Verilated::gotFinish() || (MaxTickCount != 0 && MaxTickCount <= TickCount); }
};