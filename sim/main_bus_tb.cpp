#include <cstdio>
#include <cstdint>
#include <cstdlib>

#include "verilated.h"
#include "verilated_vcd_c.h"
#include "Vtop.h"

// Split tick into low/high to sample combinational "ready" in clk=0 phase.
static inline void tick_lo(Vtop* dut, VerilatedVcdC* tfp, vluint64_t& t) {
    dut->clk = 0;
    dut->eval();
    if (tfp) tfp->dump(t++);
}

static inline void tick_hi(Vtop* dut, VerilatedVcdC* tfp, vluint64_t& t) {
    dut->clk = 1;
    dut->eval();
    if (tfp) tfp->dump(t++);
}

static inline void tick(Vtop* dut, VerilatedVcdC* tfp, vluint64_t& t) {
    tick_lo(dut, tfp, t);
    tick_hi(dut, tfp, t);
}

static void die_state(Vtop* dut, const char* msg, vluint64_t t) {
    std::fprintf(stderr,
        "TIMEOUT: %s at t=%llu\n"
        " reset=%d\n"
        " req_valid=%d req_ready=%d req_addr=0x%016llx req_is_write=%d req_wdata=0x%016llx wstrb=0x%02x\n"
        " resp_valid=%d resp_ready=%d resp_err=%d resp_rdata=0x%016llx\n",
        msg, (unsigned long long)t,
        (int)dut->reset,
        (int)dut->req_valid, (int)dut->req_ready, (unsigned long long)dut->req_addr,
        (int)dut->req_is_write, (unsigned long long)dut->req_wdata, (unsigned)dut->req_wstrb,
        (int)dut->resp_valid, (int)dut->resp_ready, (int)dut->resp_err,
        (unsigned long long)dut->resp_rdata
    );
    std::exit(1);
}

// Accept request:
// - Drive req_valid/data stable
// - Wait until req_ready HIGH during clk=0 phase
// - Then take rising edge to fire handshake
static void accept_req(Vtop* dut, VerilatedVcdC* tfp, vluint64_t& t, const char* where) {
    const uint64_t LIMIT = 200000;
    for (uint64_t i = 0; i < LIMIT; i++) {
        tick_lo(dut, tfp, t);              // evaluate combinational ready
        if (dut->req_ready) {
            tick_hi(dut, tfp, t);          // handshake occurs on this posedge
            return;
        }
        tick_hi(dut, tfp, t);
    }
    die_state(dut, where, t);
}

static void wait_resp_valid(Vtop* dut, VerilatedVcdC* tfp, vluint64_t& t, const char* where) {
    const uint64_t LIMIT = 200000;
    for (uint64_t i = 0; i < LIMIT; i++) {
        if (dut->resp_valid) return;
        tick(dut, tfp, t);
    }
    die_state(dut, where, t);
}

static void reset_dut(Vtop* dut, VerilatedVcdC* tfp, vluint64_t& t, int cycles=5) {
    dut->reset = 1;

    dut->req_valid = 0;
    dut->req_addr = 0;
    dut->req_is_write = 0;
    dut->req_wdata = 0;
    dut->req_wstrb = 0;

    dut->resp_ready = 0;

    for (int i = 0; i < cycles; i++) tick(dut, tfp, t);

    dut->reset = 0;
    tick(dut, tfp, t);
}

static bool do_write(Vtop* dut, VerilatedVcdC* tfp, vluint64_t& t,
                     uint64_t addr, uint64_t wdata, uint8_t wstrb, bool* err_out=nullptr) {
    // Drive request
    dut->req_addr     = addr;
    dut->req_is_write = 1;
    dut->req_wdata    = wdata;
    dut->req_wstrb    = wstrb;
    dut->req_valid    = 1;

    // Don't accept responses until after request is accepted
    dut->resp_ready   = 0;

    // Accept the request
    accept_req(dut, tfp, t, "waiting for req_ready (write)");

    // Drop req_valid after acceptance
    dut->req_valid = 0;

    // Now wait for response and consume it
    dut->resp_ready = 1;
    wait_resp_valid(dut, tfp, t, "waiting for resp_valid (write)");

    bool err = dut->resp_err ? true : false;

    // Consume response (resp_valid && resp_ready) on next cycle
    tick(dut, tfp, t);
    dut->resp_ready = 0;

    if (err_out) *err_out = err;
    return !err;
}

static uint64_t do_read(Vtop* dut, VerilatedVcdC* tfp, vluint64_t& t,
                        uint64_t addr, bool* err_out=nullptr) {
    // Drive request
    dut->req_addr     = addr;
    dut->req_is_write = 0;
    dut->req_wdata    = 0;
    dut->req_wstrb    = 0;
    dut->req_valid    = 1;

    dut->resp_ready   = 0;

    // Accept the request
    accept_req(dut, tfp, t, "waiting for req_ready (read)");

    // Drop req_valid after acceptance
    dut->req_valid = 0;

    // Wait for response, sample, then consume
    dut->resp_ready = 1;
    wait_resp_valid(dut, tfp, t, "waiting for resp_valid (read)");

    uint64_t rdata = (uint64_t)dut->resp_rdata;
    bool err = dut->resp_err ? true : false;

    // Consume
    tick(dut, tfp, t);
    dut->resp_ready = 0;

    if (err_out) *err_out = err;
    return rdata;
}

static void expect_eq_u64(const char* what, uint64_t got, uint64_t exp) {
    if (got != exp) {
        std::fprintf(stderr, "FAIL: %s got=0x%016llx exp=0x%016llx\n",
                     what,
                     (unsigned long long)got,
                     (unsigned long long)exp);
        std::exit(1);
    }
}

static void expect_true(const char* what, bool cond) {
    if (!cond) {
        std::fprintf(stderr, "FAIL: %s\n", what);
        std::exit(1);
    }
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    Vtop* dut = new Vtop;

    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    dut->trace(tfp, 99);
    tfp->open("dump.vcd");

    vluint64_t t = 0;
    reset_dut(dut, tfp, t);

    const uint64_t RAM_BASE = 0x0000000080000000ULL;

    // 1) Basic aligned write/read
    {
        bool err = false;
        expect_true("write aligned should succeed",
                    do_write(dut, tfp, t, RAM_BASE + 0x00, 0x1122334455667788ULL, 0xFF, &err));
        expect_true("write aligned err==0", !err);

        uint64_t r = do_read(dut, tfp, t, RAM_BASE + 0x00, &err);
        expect_true("read aligned err==0", !err);
        expect_eq_u64("readback full word", r, 0x1122334455667788ULL);
    }

    // 2) Byte-lane write strobe test
    {
        bool err = false;
        expect_true("init write",
                    do_write(dut, tfp, t, RAM_BASE + 0x08, 0x0000000000000000ULL, 0xFF, &err));
        expect_true("init write err==0", !err);

        expect_true("partial write low 4 bytes",
                    do_write(dut, tfp, t, RAM_BASE + 0x08, 0x00000000AABBCCDDULL, 0x0F, &err));
        expect_true("partial write err==0", !err);

        uint64_t r = do_read(dut, tfp, t, RAM_BASE + 0x08, &err);
        expect_true("partial read err==0", !err);
        expect_eq_u64("partial write result", r, 0x00000000AABBCCDDULL);
    }

    // 3) Misaligned access should error
    {
        bool err = false;
        (void)do_read(dut, tfp, t, RAM_BASE + 0x03, &err);
        expect_true("misaligned read should set err", err);

        err = false;
        (void)do_write(dut, tfp, t, RAM_BASE + 0x05, 0xDEADBEEFCAFEBABEULL, 0xFF, &err);
        expect_true("misaligned write should set err", err);
    }

    // 4) Unmapped access should error (SoC-generated error response)
    {
        bool err = false;
        (void)do_read(dut, tfp, t, 0x0000000000001000ULL, &err);
        expect_true("unmapped read should set err", err);
    }

    // 5) Basic progress check if top exposes it
    expect_true("cycle_count should be nonzero", ((uint64_t)dut->cycle_count) > 0);

    tfp->close();
    delete tfp;
    delete dut;

    std::printf("PASS\n");
    return 0;
}
