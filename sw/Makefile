RISCV_PREFIX ?= riscv64-unknown-elf-
AS      := $(RISCV_PREFIX)as
LD      := $(RISCV_PREFIX)ld
OBJCOPY := $(RISCV_PREFIX)objcopy

PROG    ?= rv64_test
SRC     := $(PROG).S

OUTDIR  := out
RESET_PC ?= 0x80000000

OBJ     := $(OUTDIR)/$(PROG).o
ELF     := $(OUTDIR)/$(PROG).elf
MEMH    := $(OUTDIR)/$(PROG).memh

all: $(MEMH)

$(OUTDIR):
	mkdir -p $(OUTDIR)

$(OBJ): $(SRC) | $(OUTDIR)
	$(AS) -march=rv64i -mabi=lp64 $< -o $@

$(ELF): $(OBJ)
	$(LD) -Ttext=$(RESET_PC) $< -o $@

$(MEMH): $(ELF)
	$(OBJCOPY) -O verilog --verilog-data-width=8 --adjust-vma=-$(RESET_PC) $< $@

clean:
	rm -rf $(OUTDIR)

.PHONY: all clean