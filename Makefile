# ==============================================================================
# Makefile for Resource-Efficient CNN Accelerator on FPGA
# Target: Digilent Arty A7-100T (Xilinx Artix-7 XC7A100T)
# ==============================================================================

.PHONY: all test test_units vectors reference vivado_batch vivado_gui clean wave help

all: test

test:
	@chmod +x scripts/run_simulation.sh
	@./scripts/run_simulation.sh

vectors:
	@python3 scripts/generate_test_vectors.py

reference:
	@python3 scripts/cnn_reference.py

test_units:
	@echo "Running Conv1 unit tests..."
	@iverilog -g2012 -o simulations/tb_conv1_full_sim \
		rtl/arithmetic/int8_multiplier.v rtl/convolution/conv3x3_mac.v rtl/convolution/conv3x3_rgb_mac.v \
		rtl/convolution/conv1_filter_bank.sv tb/convolution/tb_conv1_full_image.sv && vvp simulations/tb_conv1_full_sim
	@echo "Running Conv2 unit tests..."
	@iverilog -g2012 -o simulations/tb_conv2_full_sim \
		rtl/convolution/conv3x3_16ch_mac.sv rtl/convolution/conv2_filter_bank.sv tb/convolution/tb_conv2_full_image.sv && vvp simulations/tb_conv2_full_sim
	@echo "Running Conv3 unit tests..."
	@iverilog -g2012 -o simulations/tb_conv3_full_sim \
		rtl/convolution/conv3x3_16ch_mac.sv rtl/convolution/conv3_filter_bank.sv tb/convolution/tb_conv3_full_image.sv && vvp simulations/tb_conv3_full_sim
	@echo "Running FC2 unit tests..."
	@iverilog -g2012 -o simulations/tb_fc2_sim \
		rtl/fully_connected/fc2_layer_bank.sv tb/fully_connected/tb_fc2_trained.sv && vvp simulations/tb_fc2_sim
	@echo "Running Argmax unit tests..."
	@iverilog -g2012 -o simulations/tb_argmax_sim \
		rtl/classifier/argmax.sv tb/classifier/tb_argmax_fc2.sv && vvp simulations/tb_argmax_sim
	@echo "All unit tests completed successfully!"

vivado_batch:
	@if command -v vivado >/dev/null 2>&1; then \
		vivado -mode batch -source vivado/build_vivado.tcl; \
	else \
		echo "Vivado is not available on this machine (macOS). Run this on the lab workstation or remote Linux server with Vivado installed."; \
	fi

vivado_gui:
	@if command -v vivado >/dev/null 2>&1; then \
		vivado -mode gui -source vivado/create_project.tcl; \
	else \
		echo "Vivado is not available on this machine (macOS). Run this on the lab workstation or remote Linux server with Vivado installed."; \
	fi

wave:
	@if command -v gtkwave >/dev/null 2>&1; then \
		gtkwave simulations/cnn_top.vcd & \
	else \
		echo "GTKWave not found in PATH. Install with: brew install --cask gtkwave"; \
	fi

clean:
	@rm -rf simulations/*.sim simulations/*.log /tmp/*_sim /tmp/*_test vivado/reports vivado/project vivado/*.bit vivado/*.jou vivado/*.log
	@echo "Cleaned build and simulation artifacts."

help:
	@echo "Available targets:"
	@echo "  make test          - Run full end-to-end simulation on 4 test cases"
	@echo "  make test_units    - Run individual layer unit tests"
	@echo "  make vectors       - Regenerate test vectors using Python reference"
	@echo "  make reference     - Run Python FP32 and integer reference model"
	@echo "  make vivado_batch  - Run Vivado synthesis & implementation in batch mode"
	@echo "  make vivado_gui    - Generate and open Vivado project GUI"
	@echo "  make wave          - Open GTKWave with simulation waveform"
	@echo "  make clean         - Remove generated simulation files"
