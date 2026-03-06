#include <stdint.h>

static inline void ebreak(void) {
  __asm__ volatile ("ebreak");
}

static inline void fence(void) {
  __asm__ volatile ("fence" ::: "memory");
}

__attribute__((noreturn)) static void fail(int n) {
  (void)n;
  ebreak();
  for (;;) {}
}

__attribute__((noreturn)) static void pass(void) {
  fence(); // PASS marker
  ebreak();
  for (;;) {}
}

#define CHECK(cond, n) do { if (!(cond)) fail(n); } while (0)

static volatile uint64_t data[4];

static uint64_t auipc_probe(void) {
  uintptr_t x;
  __asm__ volatile ("auipc %0, 0" : "=r"(x));
  return (uint64_t)x;
}

int main(void) {
  // ---------- Basic setup ----------
  uint64_t x1 = 5;
  uint64_t x2 = 7;

  // ---------- OP ----------
  CHECK((x1 + x2) == 12, 1);
  CHECK((x2 - x1) == 2, 2);
  CHECK((x1 & x2) == 5, 3);
  CHECK((x1 | x2) == 7, 4);
  CHECK((x1 ^ x2) == 2, 5);

  // shifts
  CHECK(((uint64_t)1 << 3) == 8, 6);
  CHECK(((uint64_t)32 >> 2) == 8, 7);
  CHECK(((int64_t)-8 >> 1) == -4, 8);

  // slt / sltu equivalents
  CHECK(((int64_t)-1 < (int64_t)0) == 1, 9);
  CHECK(((uint64_t)-1 < (uint64_t)0) == 0, 10);

  // ---------- OP-IMM ----------
  CHECK((x1 + 9) == 14, 11);
  CHECK((x2 & 3) == 3, 12);
  CHECK(((uint64_t)0x55) == 0x55, 13);
  CHECK((((uint64_t)0x55) ^ 0x0FULL) == 0x5A, 14);

  CHECK(((int64_t)-1 < (int64_t)0) == 1, 15);
  CHECK(((uint64_t)-1 < (uint64_t)0) == 0, 16);

  CHECK(((uint64_t)1 << 5) == 32, 17);
  CHECK(((uint64_t)32 >> 2) == 8, 18);
  CHECK(((int64_t)-8 >> 1) == -4, 19);

  // ---------- LUI / AUIPC ----------
  uint64_t lui_x = 0x12345ULL << 12;
  CHECK(lui_x == (0x12345ULL << 12), 20);

  // auipc: two successive reads should differ by a small constant
  uint64_t a0 = auipc_probe();
  uint64_t a1 = auipc_probe();
  CHECK((a1 - a0) != 0, 21); // compiler may reorder unless volatile asm (it is)

  // ---------- Branches ----------
  {
    uint64_t a = 1, b = 1;
    if (a == b) {
      // ok
    } else {
      fail(22);
    }

    b = 2;
    if (a != b) {
      // ok
    } else {
      fail(23);
    }

    int64_t s = -1;
    if (s < 0) {
      // ok
    } else {
      fail(24);
    }

    if (0 >= 0) {
      // ok
    } else {
      fail(25);
    }

    if ((uint64_t)0 < (uint64_t)-1) {
      // ok
    } else {
      fail(26);
    }

    if ((uint64_t)-1 >= (uint64_t)0) {
      // ok
    } else {
      fail(27);
    }
  }

  // ---------- Loads/Stores ----------
  {
    volatile uint8_t  *p8  = (volatile uint8_t*) data;
    volatile uint16_t *p16 = (volatile uint16_t*)data;
    volatile uint32_t *p32 = (volatile uint32_t*)data;
    volatile uint64_t *p64 = (volatile uint64_t*)data;

    uint64_t pat = 0x1122334455667788ULL;
    p64[0] = pat;
    CHECK(p64[0] == pat, 28);

    // byte sign/zero extension
    p8[8] = 0x80;
    int8_t  lb  = *(volatile int8_t*)&p8[8];
    uint8_t lbu = p8[8];
    CHECK(lbu == 0x80, 29);
    CHECK(lb  == (int8_t)0x80, 30);

    // halfword sign/zero extension
    p16[5] = 0x0801;           // offset 10 bytes
    int16_t  lh  = *(volatile int16_t*)&p16[5];
    uint16_t lhu = p16[5];
    CHECK(lhu == 0x0801, 31);
    (void)lh;

    // word sign/zero extension
    p32[3] = 0x80000001U;      // offset 12 bytes
    int32_t  lw  = *(volatile int32_t*)&p32[3];
    uint32_t lwu = p32[3];
    CHECK((uint64_t)lwu == 0x0000000080000001ULL, 32);
    CHECK((int64_t)lw  == (int64_t)0xFFFFFFFF80000001ULL, 33);
  }

  // ---------- JAL / JALR equivalent (function call/return) ----------
  {
    uint64_t func_ret = 0x5A;
    // Use a real function so compiler must call/return
    extern uint64_t test_func(void);
    uint64_t v = test_func();
    CHECK(v == func_ret, 34);
  }

  // ---------- OP-IMM-32 / OP-32 semantics ----------
  {
    int64_t  x = -1;
    int64_t  y = (int32_t)x + 1;              // addiw semantics: 32-bit add then sign-extend
    CHECK(y == 0, 35);

    int64_t slliw = (int64_t)(int32_t)(1U << 31); // 0x80000000 sign-extended
    CHECK((uint64_t)slliw == 0xFFFFFFFF80000000ULL, 36);

    uint32_t srliw = ((uint32_t)slliw) >> 31;
    CHECK(srliw == 1, 37);

    int32_t sraiw = ((int32_t)slliw) >> 31;
    CHECK(sraiw == -1, 38);

    int32_t a = 5, b = 7;
    int32_t addw = a + b;
    CHECK(addw == 12, 39);

    int32_t subw = b - a;
    CHECK(subw == 2, 40);

    uint32_t shamt = 33; // uses low 5 bits effectively in RV64 W-shifts; this tests semantics
    uint32_t sllw = (uint32_t)1 << (shamt & 31);
    CHECK(sllw == 2, 41);

    uint32_t srlw = sllw >> (shamt & 31);
    CHECK(srlw == 1, 42);

    int32_t sraw = (int32_t)0x80000000 >> 1;
    CHECK((uint64_t)(int64_t)sraw == 0xFFFFFFFFC0000000ULL, 43);
  }

  pass();
}

// Prevent inlining so the compiler emits a call/return path (jal/jalr)
__attribute__((noinline)) uint64_t test_func(void) {
  return 0x5A;
}