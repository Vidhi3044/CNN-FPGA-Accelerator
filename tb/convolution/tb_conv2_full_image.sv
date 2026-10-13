
`timescale 1ns/1ps

module tb_conv2_full_image;

localparam integer FILTER_COUNT = 32;
localparam integer INPUT_COUNT = 144;
localparam integer INPUT_VALUES = 3600;
localparam integer OUTPUT_VALUES = 5408;

reg signed [7:0] image_data [0:INPUT_VALUES-1];
reg signed [7:0] flat_weights [0:FILTER_COUNT*INPUT_COUNT-1];
reg signed [7:0] weights [0:FILTER_COUNT-1][0:INPUT_COUNT-1];
reg signed [31:0] biases [0:FILTER_COUNT-1];
reg signed [31:0] expected [0:OUTPUT_VALUES-1];

reg signed [7:0] patch [0:INPUT_COUNT-1];
wire signed [31:0] outputs [0:FILTER_COUNT-1];

integer f;
integer c;
integer ky;
integer kx;
integer y;
integer x;
integer idx;
integer errors;
integer shown;

conv2_filter_bank #(
    .FILTER_COUNT(FILTER_COUNT),
    .INPUT_COUNT(INPUT_COUNT)
) conv2 (
    .inputs(patch),
    .weights(weights),
    .biases(biases),
    .outputs(outputs)
);

task load_patch;
    input integer start_y;
    input integer start_x;
    integer channel;
    integer row;
    integer column;
    begin
        for (channel = 0; channel < 16; channel = channel + 1) begin
            for (row = 0; row < 3; row = row + 1) begin
                for (column = 0; column < 3; column = column + 1) begin
                    patch[channel*9 + row*3 + column] =
                        image_data[channel*225 +
                                   (start_y+row)*15 +
                                   (start_x+column)];
                end
            end
        end
    end
endtask

initial begin
    errors = 0;
    shown = 0;

    $readmemh("FPGA_Parameters/mem_files/conv2_integer_test/conv2_input.mem", image_data);
    $readmemh("FPGA_Parameters/mem_files/weights/features_3_weight.mem", flat_weights);
    $readmemh("FPGA_Parameters/mem_files/conv2_integer_test/conv2_bias_int32.mem", biases);
    $readmemh("FPGA_Parameters/mem_files/conv2_integer_test/conv2_acc_expected.mem", expected);

    for (f = 0; f < FILTER_COUNT; f = f + 1)
        for (c = 0; c < INPUT_COUNT; c = c + 1)
            weights[f][c] = flat_weights[f*INPUT_COUNT+c];

    for (y = 0; y < 13; y = y + 1) begin
        for (x = 0; x < 13; x = x + 1) begin
            load_patch(y, x);
            #1;

            for (f = 0; f < FILTER_COUNT; f = f + 1) begin
                idx = f*169 + y*13 + x;

                if (outputs[f] !== expected[idx]) begin
                    if (shown < 10) begin
                        $display("MISMATCH filter=%0d y=%0d x=%0d RTL=%0d expected=%0d",
                            f, y, x, outputs[f], expected[idx]);
                        shown = shown + 1;
                    end
                    errors = errors + 1;
                end
            end
        end
    end

    $display("Conv2 outputs checked: %0d", OUTPUT_VALUES);
    $display("Total mismatches: %0d", errors);

    if (errors == 0)
        $display("CONV2 FULL IMAGE TEST PASSED");
    else
        $display("CONV2 FULL IMAGE TEST FAILED");

    $finish;
end

endmodule
