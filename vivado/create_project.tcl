# ==============================================================================
# Vivado GUI Project Generator for Digilent Arty A7-100T
# Usage: vivado -mode gui -source vivado/create_project.tcl
# ==============================================================================

set PROJECT_NAME "cnn_fpga_arty_a7"
set PROJECT_DIR  "vivado/project"
set PART         "xc7a100tcsg324-1"

file mkdir $PROJECT_DIR

create_project -force $PROJECT_NAME $PROJECT_DIR -part $PART

# Add Source Files
add_files -norecurse {
    rtl/arithmetic/int8_multiplier.v
    rtl/convolution/conv3x3_mac.v
    rtl/convolution/conv3x3_rgb_mac.v
    rtl/convolution/conv1_filter_bank.sv
    rtl/activation/relu.v
    rtl/activation/relu_bank.sv
    rtl/pooling/maxpool2x2.v
    rtl/pooling/maxpool2x2_bank.sv
    rtl/arithmetic/requantize_int8.sv
    rtl/classifier/argmax.sv
    rtl/cnn_top.sv
    rtl/arty_a7_cnn_top.sv
}

# Add Constraints
add_files -fileset constrs_1 -norecurse vivado/arty_a7_100t.xdc

# Add Simulation Files
add_files -fileset sim_1 -norecurse tb/tb_cnn_top.sv

# Set Top Modules
set_property top arty_a7_cnn_top [current_fileset]
set_property top tb_cnn_top [get_filesets sim_1]

puts "\n[SUCCESS] Project created successfully at $PROJECT_DIR/${PROJECT_NAME}.xpr"
puts "Ready for Synthesis, Implementation, and Bitstream Generation in Vivado GUI!"
