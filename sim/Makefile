TOP=top
RTL_DIR=../rtl
SIM_DIR=.

RTL_SRCS := $(wildcard $(RTL_DIR)/*.sv)

build:
	verilator -Wall --cc $(RTL_SRCS) --top-module $(TOP) \
		--exe $(SIM_DIR)/main.cpp --trace
	make -C obj_dir -f V$(TOP).mk

run: build
	./obj_dir/V$(TOP)

clean:
	rm -rf obj_dir dump.vcd
