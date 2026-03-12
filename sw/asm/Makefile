RISCV_PREFIX := riscv64-unknown-elf-
AS      := $(RISCV_PREFIX)as
LD      := $(RISCV_PREFIX)ld
OBJCOPY := $(RISCV_PREFIX)objcopy
OBJDUMP := $(RISCV_PREFIX)objdump

ISA := rv64im

OUTDIR := out
PROG   := rv64_test

RESET_PC := 0x80000000

SRC  := $(PROG).S
OBJ  := $(OUTDIR)/$(PROG).o
ELF  := $(OUTDIR)/$(PROG).elf
MEMH := $(OUTDIR)/$(PROG).memh
DIS  := $(OUTDIR)/$(PROG).dis

ASFLAGS := -march=$(ISA) -mabi=lp64
LDFLAGS := -Ttext=$(RESET_PC)

all: $(MEMH) $(DIS)

$(OUTDIR):
	mkdir -p $(OUTDIR)

$(OBJ): $(SRC) | $(OUTDIR)
	$(AS) $(ASFLAGS) $< -o $@

$(ELF): $(OBJ)
	$(LD) $(LDFLAGS) $< -o $@

$(MEMH): $(ELF)
	$(OBJCOPY) -O verilog --verilog-data-width=8 --adjust-vma=-$(RESET_PC) $< $@

$(DIS): $(ELF)
	$(OBJDUMP) -d $< > $@

clean:
	rm -rf $(OUTDIR)
