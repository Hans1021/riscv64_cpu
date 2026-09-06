RISCV_PREFIX := riscv64-unknown-elf-
AS      := $(RISCV_PREFIX)as
LD      := $(RISCV_PREFIX)ld
OBJCOPY := $(RISCV_PREFIX)objcopy
OBJDUMP := $(RISCV_PREFIX)objdump
NM      := $(RISCV_PREFIX)nm

ISA := rv64im_zicsr

OUTDIR := out
PROG   ?= rv64_test

RESET_PC := 0x80000000

SRC  := $(PROG).S
OBJ  := $(OUTDIR)/$(PROG).o
ELF  := $(OUTDIR)/$(PROG).elf
MEMH := $(OUTDIR)/$(PROG).memh
DIS  := $(OUTDIR)/$(PROG).dis

ASFLAGS := -march=$(ISA) -mabi=lp64
LDFLAGS := -Ttext=$(RESET_PC)

TESTS := \
	csr_test \
	trap_test \
	invalid_csr_test \
	mstatus_test \
	rv64_test

.PHONY: all test regression clean

all: $(MEMH) $(DIS)

$(OUTDIR):
	mkdir -p $(OUTDIR)

$(OBJ): $(SRC) | $(OUTDIR)
	$(AS) $(ASFLAGS) $< -o $@

$(ELF): $(OBJ)
	$(LD) $(LDFLAGS) $< -o $@

$(MEMH): $(ELF)
	$(OBJCOPY) -O verilog \
		--verilog-data-width=8 \
		--adjust-vma=-$(RESET_PC) \
		$< $@

$(DIS): $(ELF)
	$(OBJDUMP) -d $< > $@

test: $(MEMH) $(DIS)
	@PASS_PC=$$($(NM) $(ELF) | awk '$$3 == "pass" {print "0x" $$1}'); \
	FAIL_PC=$$($(NM) $(ELF) | awk '$$3 == "fail" {print "0x" $$1}'); \
	if [ -z "$$PASS_PC" ]; then \
		echo "ERROR: no 'pass' label found in $(PROG).S"; \
		exit 1; \
	fi; \
	if [ -z "$$FAIL_PC" ]; then \
		echo "ERROR: no 'fail' label found in $(PROG).S"; \
		exit 1; \
	fi; \
	echo "Running $(PROG)"; \
	echo "PASS_PC=$$PASS_PC"; \
	echo "FAIL_PC=$$FAIL_PC"; \
	$(MAKE) -C ../../sim run \
		MEM=../sw/asm/$(MEMH) \
		PASS_PC=$$PASS_PC \
		FAIL_PC=$$FAIL_PC

regression:
	@set -e; \
	for test in $(TESTS); do \
		echo ""; \
		echo "========================================"; \
		echo "Running $$test"; \
		echo "========================================"; \
		$(MAKE) test PROG=$$test; \
	done; \
	echo ""; \
	echo "========================================"; \
	echo "ALL REGRESSION TESTS PASSED"; \
	echo "========================================"

clean:
	rm -rf $(OUTDIR)