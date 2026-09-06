#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vtop.h"

#include <cstdint>
#include <cstdlib>
#include <cstring>

static void tick(Vtop* dut, VerilatedVcdC* tfp, vluint64_t& t) {
    dut->clk = 0;
    dut->eval();
    if (tfp) tfp->dump(t++);

    dut->clk = 1;
    dut->eval();
    if (tfp) tfp->dump(t++);
}

static bool get_plusarg_u64(
    int argc,
    char** argv,
    const char* name,
    uint64_t& value
) {
    const size_t name_len = std::strlen(name);

    for (int i = 1; i < argc; i++) {
        if (std::strncmp(argv[i], name, name_len) == 0) {
            value = std::strtoull(argv[i] + name_len, nullptr, 0);
            return true;
        }
    }

    return false;
}

static void cleanup(Vtop* dut, VerilatedVcdC* tfp) {
    tfp->close();
    delete tfp;
    delete dut;
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    uint64_t pass_pc = 0;
    uint64_t fail_pc = 0;

    const bool have_pass =
        get_plusarg_u64(argc, argv, "+pass=", pass_pc);

    const bool have_fail =
        get_plusarg_u64(argc, argv, "+fail=", fail_pc);

    if (have_pass) {
        VL_PRINTF(
            "PASS address: 0x%016llx\n",
            (unsigned long long)pass_pc
        );
    }

    if (have_fail) {
        VL_PRINTF(
            "FAIL address: 0x%016llx\n",
            (unsigned long long)fail_pc
        );
    }

    Vtop* dut = new Vtop;

    // VCD
    Verilated::traceEverOn(true);

    VerilatedVcdC* tfp = new VerilatedVcdC;
    dut->trace(tfp, 99);
    tfp->open("dump.vcd");

    vluint64_t t = 0;

    // Reset
    dut->reset = 1;
    for (int i = 0; i < 5; i++) {
        tick(dut, tfp, t);
    }
    dut->reset = 0;

    const int MAX_CYCLES = 50000;

    for (int i = 0; i < MAX_CYCLES; i++) {
        tick(dut, tfp, t);

        if ((i % 50) == 0) {
            VL_PRINTF(
                "i=%d pc=0x%016llx ir=0x%08x state=%u halted=%u\n",
                i,
                (unsigned long long)dut->dbg_pc,
                (unsigned)dut->dbg_ir,
                (unsigned)dut->dbg_state,
                (unsigned)dut->halted
            );
        }

        // Automatic pass detection
        if (have_pass && dut->dbg_pc == pass_pc) {
            VL_PRINTF(
                "PASS at cycle %d pc=0x%016llx\n",
                i,
                (unsigned long long)dut->dbg_pc
            );

            cleanup(dut, tfp);
            return 0;
        }

        // Automatic fail detection
        if (have_fail && dut->dbg_pc == fail_pc) {
            VL_PRINTF(
                "FAIL at cycle %d pc=0x%016llx\n",
                i,
                (unsigned long long)dut->dbg_pc
            );

            cleanup(dut, tfp);
            return 1;
        }

        // Preserve original halt behavior
        if (dut->halted) {
            VL_PRINTF(
                "HALT at pc=0x%016llx ir=0x%08x state=%u\n",
                (unsigned long long)dut->dbg_pc,
                (unsigned)dut->dbg_ir,
                (unsigned)dut->dbg_state
            );

            cleanup(dut, tfp);
            return 0;
        }
    }

    VL_PRINTF(
        "TIMEOUT: did not halt or reach PASS/FAIL. "
        "pc=0x%016llx ir=0x%08x state=%u\n",
        (unsigned long long)dut->dbg_pc,
        (unsigned)dut->dbg_ir,
        (unsigned)dut->dbg_state
    );

    cleanup(dut, tfp);
    return 1;
}