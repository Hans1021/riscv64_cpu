RISCV_PREFIX := riscv64-unknown-elf-
CC      := $(RISCV_PREFIX)gcc
LD      := $(RISCV_PREFIX)ld
OBJCOPY := $(RISCV_PREFIX)objcopy
OBJDUMP := $(RISCV_PREFIX)objdump

ISA := rv64im

OUTDIR := out
PROG   := prog

RESET_PC := 0x80000000

CRT0 := crt0.S
MAIN := main.c
LDS  := link.ld

CRT0_O := $(OUTDIR)/crt0.o
MAIN_O := $(OUTDIR)/main.o
ELF    := $(OUTDIR)/$(PROG).elf
MEMH   := $(OUTDIR)/$(PROG).memh
DIS    := $(OUTDIR)/$(PROG).dis

CFLAGS  := -march=$(ISA) -mabi=lp64 -mcmodel=medany -msmall-data-limit=0 -ffreestanding -fno-builtin -nostdlib -O2
LDFLAGS := -T $(LDS)

all: $(MEMH) $(DIS)

$(OUTDIR):
	mkdir -p $(OUTDIR)

$(CRT0_O): $(CRT0) | $(OUTDIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(MAIN_O): $(MAIN) | $(OUTDIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(ELF): $(CRT0_O) $(MAIN_O) $(LDS)
	$(LD) $(LDFLAGS) $(CRT0_O) $(MAIN_O) -o $@

$(MEMH): $(ELF)
	$(OBJCOPY) -O verilog --verilog-data-width=8 --adjust-vma=-$(RESET_PC) $< $@

$(DIS): $(ELF)
	$(OBJDUMP) -d $< > $@

clean:
	rm -rf $(OUTDIR)
