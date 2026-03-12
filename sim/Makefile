TOP := top
RTL_DIR := ../rtl
SIM_DIR := .
MEM ?= ../sw/bare_metal_c/out/prog.memh

RTL_SRCS := \
  $(RTL_DIR)/riscv_pkg.sv \
  $(RTL_DIR)/alu.sv \
  $(RTL_DIR)/muldiv.sv \
  $(RTL_DIR)/control_fsm.sv \
  $(RTL_DIR)/core_top.sv \
  $(RTL_DIR)/decoder.sv \
  $(RTL_DIR)/exu.sv \
  $(RTL_DIR)/frontend.sv \
  $(RTL_DIR)/lsu.sv \
  $(RTL_DIR)/ram.sv \
  $(RTL_DIR)/regfile.sv \
  $(RTL_DIR)/soc.sv \
  $(RTL_DIR)/top.sv

build:
	verilator -Wall --cc $(RTL_SRCS) --top-module $(TOP) \
		--exe $(SIM_DIR)/main.cpp --trace -Wno-UNUSEDSIGNAL -Wno-PINCONNECTEMPTY
	$(MAKE) -C obj_dir -f V$(TOP).mk

run: build
	./obj_dir/V$(TOP) +mem=$(MEM)

clean:
	rm -rf obj_dir dump.vcd