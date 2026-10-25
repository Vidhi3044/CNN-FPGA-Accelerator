#!/bin/bash
# ==============================================================================
# Automated Simulation Runner for CNN FPGA Accelerator
# ==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}       CNN FPGA ACCELERATOR: AUTOMATED VERIFICATION FLOW        ${NC}"
echo -e "${BLUE}       Target: Digilent Arty A7-100T (Artix-7 XC7A100T)         ${NC}"
echo -e "${BLUE}================================================================${NC}"

# Check for iverilog and vvp
if ! command -v iverilog &> /dev/null; then
    echo -e "${RED}[ERROR] iverilog not found in PATH! Please install Icarus Verilog.${NC}"
    exit 1
fi

if ! command -v vvp &> /dev/null; then
    echo -e "${RED}[ERROR] vvp not found in PATH! Please install vvp.${NC}"
    exit 1
fi

mkdir -p simulations

SIM_BIN="simulations/tb_cnn_top_sim"

echo -e "\n${YELLOW}[1/3] Compiling RTL and End-to-End Testbench...${NC}"
iverilog -g2012 -s tb_cnn_top -o "$SIM_BIN" \
    rtl/arithmetic/int8_multiplier.v \
    rtl/convolution/conv3x3_mac.v \
    rtl/convolution/conv3x3_rgb_mac.v \
    rtl/convolution/conv1_filter_bank.sv \
    rtl/activation/relu.v \
    rtl/activation/relu_bank.sv \
    rtl/pooling/maxpool2x2.v \
    rtl/pooling/maxpool2x2_bank.sv \
    rtl/arithmetic/requantize_int8.sv \
    rtl/classifier/argmax.sv \
    rtl/cnn_top.sv \
    tb/tb_cnn_top.sv

echo -e "${GREEN}[SUCCESS] Compilation complete: $SIM_BIN${NC}"

echo -e "\n${YELLOW}[2/3] Running Simulation with Real Model Test Vectors...${NC}"
vvp "$SIM_BIN" | tee simulations/simulation.log

echo -e "\n${YELLOW}[3/3] Analyzing Simulation Output...${NC}"
if grep -q "ALL END-TO-END TESTS PASSED SUCCESSFULLY" simulations/simulation.log; then
    echo -e "${GREEN}================================================================${NC}"
    echo -e "${GREEN}  VERIFICATION PASSED: 100% Bit-Exact Match Across All Classes! ${NC}"
    echo -e "${GREEN}  Waveform saved to: simulations/cnn_top.vcd                     ${NC}"
    echo -e "${GREEN}================================================================${NC}"
    exit 0
else
    echo -e "${RED}================================================================${NC}"
    echo -e "${RED}  VERIFICATION FAILED: Check simulations/simulation.log for mismatches.${NC}"
    echo -e "${RED}================================================================${NC}"
    exit 1
fi
