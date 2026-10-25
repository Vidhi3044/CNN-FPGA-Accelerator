# ==============================================================================
# Vivado Synthesis & Implementation Script for CNN Accelerator on Arty A7-100T
# Target Device: Xilinx Artix-7 XC7A100TCSG324-1
# ==============================================================================

set PROJECT_NAME "cnn_fpga_accelerator"
set TOP_MODULE   "arty_a7_cnn_top"
set PART         "xc7a100tcsg324-1"
set OUTPUT_DIR   "vivado/reports"

file mkdir $OUTPUT_DIR

puts "=========================================================================="
puts "Starting Vivado Flow for $TOP_MODULE on Part $PART"
puts "=========================================================================="

# Create in-memory project
create_project -in_memory -part $PART

# Read Verilog / SystemVerilog source files
read_verilog -sv rtl/arithmetic/int8_multiplier.v
read_verilog -sv rtl/convolution/conv3x3_mac.v
read_verilog -sv rtl/convolution/conv3x3_rgb_mac.v
read_verilog -sv rtl/convolution/conv1_filter_bank.sv
read_verilog -sv rtl/activation/relu.v
read_verilog -sv rtl/activation/relu_bank.sv
read_verilog -sv rtl/pooling/maxpool2x2.v
read_verilog -sv rtl/pooling/maxpool2x2_bank.sv
read_verilog -sv rtl/arithmetic/requantize_int8.sv
read_verilog -sv rtl/classifier/argmax.sv
read_verilog -sv rtl/cnn_top.sv
read_verilog -sv rtl/arty_a7_cnn_top.sv

# Read XDC Physical Constraints
read_xdc vivado/arty_a7_100t.xdc

# 1. Synthesis
puts "\n[VIVADO] Running RTL Synthesis..."
synth_design -top $TOP_MODULE -part $PART -directive AreaOptimized_high

puts "\n[VIVADO] Generating Synthesis Reports..."
report_utilization -file "$OUTPUT_DIR/utilization_synth.rpt" -pb "$OUTPUT_DIR/utilization_synth.pb"
report_timing_summary -file "$OUTPUT_DIR/timing_synth.rpt"

# 2. Optimization and Placement
puts "\n[VIVADO] Running Design Optimization..."
opt_design

puts "\n[VIVADO] Running Placement..."
place_design
report_utilization -file "$OUTPUT_DIR/utilization_placed.rpt"

puts "\n[VIVADO] Running Physical Logic Optimization..."
phys_opt_design

# 3. Routing
puts "\n[VIVADO] Running Routing..."
route_design

puts "\n[VIVADO] Generating Implementation Reports..."
report_utilization -file "$OUTPUT_DIR/utilization_route.rpt"
report_timing_summary -file "$OUTPUT_DIR/timing_summary.rpt"
report_power -file "$OUTPUT_DIR/power.rpt"
report_drc -file "$OUTPUT_DIR/drc.rpt"

# 4. Generate Bitstream
puts "\n[VIVADO] Generating Bitstream..."
write_bitstream -force "vivado/${TOP_MODULE}.bit"

puts "=========================================================================="
puts "Vivado Flow Complete!"
puts "Bitstream generated at: vivado/${TOP_MODULE}.bit"
puts "Reports generated in:   $OUTPUT_DIR/"
puts "=========================================================================="
