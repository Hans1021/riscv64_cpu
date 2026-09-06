RISCV_PREFIX := riscv64-unknown-elf-

CC      := $(RISCV_PREFIX)gcc
LD      := $(RISCV_PREFIX)ld
OBJCOPY := $(RISCV_PREFIX)objcopy
OBJDUMP := $(RISCV_PREFIX)objdump
NM      := $(RISCV_PREFIX)nm

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

CFLAGS := \
	-march=$(ISA) \
	-mabi=lp64 \
	-mcmodel=medany \
	-msmall-data-limit=0 \
	-ffreestanding \
	-fno-builtin \
	-nostdlib \
	-O2

LDFLAGS := -T $(LDS)

.PHONY: all test clean

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
	$(OBJCOPY) \
		-O verilog \
		--verilog-data-width=8 \
		--adjust-vma=-$(RESET_PC) \
		$< $@

$(DIS): $(ELF)
	$(OBJDUMP) -d $< > $@

test: $(MEMH) $(DIS)
	@PASS_PC=$$($(NM) $(ELF) | awk '$$3 == "pass" {print "0x" $$1}'); \
	FAIL_PC=$$($(NM) $(ELF) | awk '$$3 == "fail" {print "0x" $$1}'); \
	if [ -z "$$PASS_PC" ]; then \
		echo "ERROR: no 'pass' symbol found"; \
		exit 1; \
	fi; \
	if [ -z "$$FAIL_PC" ]; then \
		echo "ERROR: no 'fail' symbol found"; \
		exit 1; \
	fi; \
	echo "Running bare-metal C test"; \
	echo "PASS_PC=$$PASS_PC"; \
	echo "FAIL_PC=$$FAIL_PC"; \
	$(MAKE) -C ../../sim run \
		MEM=../sw/bare_metal_c/$(MEMH) \
		PASS_PC=$$PASS_PC \
		FAIL_PC=$$FAIL_PC

clean:
	rm -rf $(OUTDIR)