#include <stdint.h>

static volatile uint64_t data[4];

__attribute__((noinline))
static uint64_t compute(uint64_t a, uint64_t b) {
    uint64_t x = a * b;
    uint64_t y = x + 17;
    uint64_t z = y / 3;
    return z;
}

int main(void) {
    uint64_t a = 6;
    uint64_t b = 7;

    uint64_t r0 = compute(a, b);
    uint64_t r1 = compute(r0, 5);

    data[0] = a;
    data[1] = b;
    data[2] = r0;
    data[3] = r1;

    /*
    Expected:

    r0 = (6 * 7 + 17) / 3 = 19

    r1 = (19 * 5 + 17) / 3 = 37
    
    */

    if (data[0] != 6)
        return 1;

    if (data[1] != 7)
        return 1;

    if (data[2] != 19)
        return 1;

    if (data[3] != 37)
        return 1;

    return 0;
}