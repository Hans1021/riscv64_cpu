TOP := top
RTL_DIR := ../rtl
SIM_DIR := .

RTL_SRCS := \
  $(RTL_DIR)/top.sv \
  $(RTL_DIR)/core_mc.sv \
  $(RTL_DIR)/decoder.sv \
  $(RTL_DIR)/regfile.sv \
  $(RTL_DIR)/alu.sv \
  $(RTL_DIR)/soc.sv \
  $(RTL_DIR)/ram.sv

# Program location
MEM ?= ../sw/m3_prog.hex

build:
	verilator -Wall --cc $(RTL_SRCS) --top-module $(TOP) \
		--exe $(SIM_DIR)/main.cpp --trace -Wno-UNUSEDSIGNAL
	make -C obj_dir -f V$(TOP).mk

run: build
	./obj_dir/V$(TOP) +mem=$(MEM)

test_core_smoke: run

clean:
	rm -rf obj_dir dump.vcd