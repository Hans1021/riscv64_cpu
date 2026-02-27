#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vtop.h"

static void tick(Vtop* dut, VerilatedVcdC* tfp, vluint64_t& t) {
    dut->clk = 0;
    dut->eval();
    if (tfp) tfp->dump(t++);

    dut->clk = 1;
    dut->eval();
    if (tfp) tfp->dump(t++);
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    Vtop* dut = new Vtop;

    // VCD
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    dut->trace(tfp, 99);
    tfp->open("dump.vcd");

    vluint64_t t = 0;

    // Reset
    dut->reset = 1;
    for (int i = 0; i < 5; i++) tick(dut, tfp, t);
    dut->reset = 0;

    const int MAX_CYCLES = 50000;
    for (int i = 0; i < MAX_CYCLES; i++) {
        tick(dut, tfp, t);

        if ((i % 50) == 0) {
        VL_PRINTF("i=%d pc=0x%016llx ir=0x%08x state=%u halted=%u\n",
              i,
              (unsigned long long)dut->dbg_pc,
              (unsigned)dut->dbg_ir,
              (unsigned)dut->dbg_state,
              (unsigned)dut->halted);
        }

        if (dut->halted) {
            VL_PRINTF("HALT at pc=0x%016llx ir=0x%08x state=%u\n",
                        (unsigned long long)dut->dbg_pc,
                        (unsigned)dut->dbg_ir,
                        (unsigned)dut->dbg_state);

            tfp->close();
            delete tfp;
            delete dut;
            return 0;
        }
    }

    VL_PRINTF("TIMEOUT: did not halt. pc=0x%016llx ir=0x%08x state=%u\n",
                (unsigned long long)dut->dbg_pc,
                (unsigned)dut->dbg_ir,
                (unsigned)dut->dbg_state);

    tfp->close();
    delete tfp;
    delete dut;
    return 1;
}