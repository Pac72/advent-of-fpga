TOP_MODULE      := tb_part1
VERILOG_FILES   := $(wildcard *.sv)
CXX_SOURCES     := sim_main.cpp
OBJ_DIR         := obj_dir

EXECUTABLE      := $(OBJ_DIR)/V$(TOP_MODULE)

.PHONY: all run clean waves diagrams

all: run

run: $(EXECUTABLE)
	./$(EXECUTABLE)

# Rule to build the simulation executable from the Verilog files.
$(EXECUTABLE): $(VERILOG_FILES) $(CXX_SOURCES)
	verilator --build -j 0 -Wall --trace --timing --cc --exe \
		--top-module $(TOP_MODULE) $(VERILOG_FILES) $(CXX_SOURCES)

waveform.vcd: run

waves: waveform.vcd
	gtkwave waveform.vcd -a part1.gtkw > /dev/null 2>&1 &

diagrams: part1-fsm.svg part1-fsm.png

part1-fsm.svg: part1-fsm.puml
	plantuml -tsvg part1-fsm.puml

part1-fsm.png: part1-fsm.puml
	plantuml -tpng part1-fsm.puml

# Clean up all generated files.
clean:
	-rm -rf $(OBJ_DIR)
	-rm -f waveform.vcd
	-rm -f part1-fsm.svg part1-fsm.png
