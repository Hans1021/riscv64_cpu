.PHONY: c asm clean

c:
	$(MAKE) -C sw/bare_metal_c test

asm:
	$(MAKE) -C sw/asm regression

clean:
	$(MAKE) -C sim clean
	$(MAKE) -C sw/bare_metal_c clean
	$(MAKE) -C sw/asm clean