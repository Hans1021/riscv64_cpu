TOP=top
RTL_DIR=../rtl

build:
	verilator -Wall --cc $(RTL_DIR)/$(TOP).sv --top-module $(TOP) \
		--exe main.cpp --trace
	make -C obj_dir -f V$(TOP).mk

run: build
	./obj_dir/V$(TOP)

clean:
	rm -rf obj_dir dump.vcd