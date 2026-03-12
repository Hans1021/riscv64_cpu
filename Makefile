.PHONY: c asm clean

c:
	$(MAKE) -C sw/bare_metal_c
	$(MAKE) -C sim run MEM=../sw/bare_metal_c/out/prog.memh

asm:
	$(MAKE) -C sw/asm
	$(MAKE) -C sim run MEM=../sw/asm/out/rv64_test.memh

clean:
	$(MAKE) -C sim clean
	$(MAKE) -C sw/bare_metal_c clean
	$(MAKE) -C sw/asm clean