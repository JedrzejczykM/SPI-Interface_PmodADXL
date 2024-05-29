# ---------------------------------------------------------
# University: Warsaw University of Technology
# Author:     Wiktor Chocianowicz
# ---------------------------------------------------------
# Create Date:    13/01/2024
# Description:    Makefile for compiling PUF project.
# ---------------------------------------------------------

MODULES=debouncer.vhd SPImaster.vhd SPIconverter.vhd PmodACL.vhd
TOP=top.vhd
TESTBENCH=testbench.vhd

.PHONY: waves clean

$(patsubst %.vhd,%.vcd,$(TESTBENCH)): $(patsubst %.vhd,%,$(TESTBENCH)) 
	@echo "Remaking $@"
	@./$< --vcd=$@

$(patsubst %.vhd,%,$(TESTBENCH)): $(patsubst %.vhd,%.o,$(TESTBENCH))
	@echo "Remaking $@"
	@ghdl -e --std=08 -fsynopsys $@

$(patsubst %.vhd,%.o,$(TESTBENCH)): $(patsubst %.vhd,%.o,$(TOP)) TESTBENCH/$(TESTBENCH)
	@echo "Remaking $@"
	@ghdl -a --std=08 -fsynopsys TESTBENCH/$(TESTBENCH)

$(patsubst %.vhd,%.o,$(TOP)): $(patsubst %.vhd,%.o,$(MODULES)) TOP/$(TOP)
	@echo "Remaking $@"
	@ghdl -a --std=08 -fsynopsys TOP/$(TOP)

$(patsubst %.vhd,%.o,$(MODULES)): %.o: MODULES/%.vhd
	@echo "Remaking $@"
	@ghdl -a --std=08 -fsynopsys $<

waves: $(patsubst %.vhd,%.vcd,$(TESTBENCH))
	@echo "Wave'ing $<"
	@gtkwave -o $(patsubst %.vhd,%.vcd,$(TESTBENCH)) 2> /tmp/gtkwave

clean:
	@echo "Cleaning up..."
	@rm -f *.o testbench *.vcd work*.cf *.vcd.fst
