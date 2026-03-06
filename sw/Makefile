RISCV_PREFIX ?= riscv64-unknown-elf-
CC      := $(RISCV_PREFIX)gcc
AS      := $(RISCV_PREFIX)as
LD      := $(RISCV_PREFIX)ld
OBJCOPY := $(RISCV_PREFIX)objcopy
OBJDUMP := $(RISCV_PREFIX)objdump

OUTDIR  := out
PROG    ?= prog

RESET_PC ?= 0x80000000

CRT0    := crt0.S
MAIN_C  := main.c
LDS     := link.ld

CRT0_O  := $(OUTDIR)/crt0.o
MAIN_O  := $(OUTDIR)/main.o
ELF     := $(OUTDIR)/$(PROG).elf
MEMH    := $(OUTDIR)/$(PROG).memh
DIS     := $(OUTDIR)/$(PROG).dis

CFLAGS  := -march=rv64i -mabi=lp64 -mcmodel=medany -msmall-data-limit=0 \
          -ffreestanding -fno-builtin -nostdlib -O2
ASFLAGS := -march=rv64i -mabi=lp64
LDFLAGS := -T $(LDS) -Map=$(OUTDIR)/$(PROG).map

run: $(MEMH) $(DIS)

$(OUTDIR):
	mkdir -p $(OUTDIR)

# Assemble crt0.S
$(CRT0_O): $(CRT0) | $(OUTDIR)
	$(CC) $(CFLAGS) -c $< -o $@

# Compile main.c -> main.o
$(MAIN_O): $(MAIN_C) | $(OUTDIR)
	$(CC) $(CFLAGS) -c $< -o $@

# Link using linker script
$(ELF): $(CRT0_O) $(MAIN_O) $(LDS)
	$(LD) $(LDFLAGS) $(CRT0_O) $(MAIN_O) -o $@

# Convert ELF -> Verilog mem file rebased to 0
$(MEMH): $(ELF)
	$(OBJCOPY) -O verilog --verilog-data-width=8 --adjust-vma=-$(RESET_PC) $< $@

# Disassembly listing
$(DIS): $(ELF) | $(OUTDIR)
	$(OBJDUMP) -d $< > $@

clean:
	rm -rf $(OUTDIR)