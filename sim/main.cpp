#include <cstdio>
#include <cstdint>
#include "verilated.h"
#include "verilated_vcd_c.h"
#include "Vtop.h"

static void tick(Vtop* dut, VerilatedVcdC* tfp, vluint64_t& t) {
    dut->clk = 0; dut->eval(); tfp->dump(t++);
    dut->clk = 1; dut->eval(); tfp->dump(t++);
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    Vtop* dut = new Vtop;

    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    dut->trace(tfp, 99);
    tfp->open("dump.vcd");

    vluint64_t t = 0;

    // reset for 5 cycles
    dut->reset = 1;
    for (int i = 0; i < 5; i++) tick(dut, tfp, t);

    // run 20 cycles
    dut->reset = 0;
    for (int i = 0; i < 20; i++) tick(dut, tfp, t);

    const uint64_t got = (uint64_t)dut->cycle_count;
    const uint64_t expected = 20;

    tfp->close();
    delete tfp;
    delete dut;

    if (got != expected) {
        std::fprintf(stderr, "FAIL: cycle_count=%llu expected=%llu\n",
            (unsigned long long)got, (unsigned long long)expected);
        return 1;
    }

    std::printf("PASS: cycle_count=%llu\n", (unsigned long long)got);
    return 0;
}
