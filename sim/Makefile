TOP := top
RTL_DIR := ../rtl
SIM_DIR := .

RTL_SRCS := \
  $(RTL_DIR)/riscv_pkg.sv \
  $(RTL_DIR)/alu.sv \
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

# Program location
MEM ?= ../sw/out/rv64_test.memh

build:
	verilator -Wall --cc $(RTL_SRCS) --top-module $(TOP) \
		--exe $(SIM_DIR)/main.cpp --trace -Wno-UNUSEDSIGNAL -Wno-PINCONNECTEMPTY
	make -C obj_dir -f V$(TOP).mk

run: build
	./obj_dir/V$(TOP) +mem=$(MEM)

test_core_smoke: run

clean:
	rm -rf obj_dir dump.vcd