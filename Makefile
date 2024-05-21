SCRIPTS_PATH=./scripts
TMP_PATH=./tmp

GUI=0

.PHONY: all clean

all: sim

sim: clean
	vivado -mode tcl -nolog -nojournal -source $(SCRIPTS_PATH)/sim.tcl -tclargs $(TEST) $(GUI)
	
clean:
ifeq ($(OS), Windows_NT)
	rmdir /Q /S $(TMP_PATH)
	rmdir /Q /S .Xil
else
	rm -fr $(TMP_PATH)
	rm -fr /Q /S .Xil
endif
