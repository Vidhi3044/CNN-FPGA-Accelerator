
`timescale 1ns/1ps

module tb_conv1_relu_pool_full;

localparam integer FILTER_COUNT = 16;
localparam integer IMAGE_SIZE = 32;
localparam integer INPUT_COUNT = 3072;
localparam integer OUTPUT_COUNT = 14400;
localparam integer POOL_COUNT = 3600;

reg signed [7:0] image_data [0:INPUT_COUNT-1];
reg signed [7:0] flat_weights [0:FILTER_COUNT*27-1];
reg signed [7:0] weights [0:FILTER_COUNT-1][0:26];
reg signed [31:0] biases [0:FILTER_COUNT-1];

reg signed [7:0] patch [0:26];
wire signed [31:0] conv_outputs [0:FILTER_COUNT-1];

reg signed [31:0] relu_inputs [0:FILTER_COUNT-1];
wire signed [31:0] relu_outputs [0:FILTER_COUNT-1];

reg signed [31:0] pool_inputs [0:3][0:FILTER_COUNT-1];
wire signed [31:0] pool_outputs [0:FILTER_COUNT-1];

reg signed [31:0] expected_relu [0:OUTPUT_COUNT-1];
reg signed [31:0] expected_pool [0:POOL_COUNT-1];

integer i;
integer j;
integer c;
integer ky;
integer kx;
integer f;
integer py;
integer px;
integer quadrant;
integer errors;
integer output_index;
integer mismatches_printed;

conv1_filter_bank #(
    .FILTER_COUNT(FILTER_COUNT)
) conv1 (
    .inputs(patch),
    .weights(weights),
    .biases(biases),
    .outputs(conv_outputs)
);

generate
    genvar g;
    for (g = 0; g < FILTER_COUNT; g = g + 1) begin : relu_units
        relu relu_inst (
            .input_value(relu_inputs[g]),
            .output_value(relu_outputs[g])
        );
    end
endgenerate

maxpool2x2_bank #(
    .FILTER_COUNT(FILTER_COUNT)
) pool_bank (
    .input_values(pool_inputs),
    .output_values(pool_outputs)
);

task load_patch;
    input integer start_y;
    input integer start_x;
    integer channel;
    integer row;
    integer column;
    begin
        for (channel = 0; channel < 3; channel = channel + 1) begin
            for (row = 0; row < 3; row = row + 1) begin
                for (column = 0; column < 3; column = column + 1) begin
                    patch[channel*9 + row*3 + column] =
                        image_data[channel*1024 +
                                   (start_y+row)*32 +
                                   (start_x+column)];
                end
            end
        end
    end
endtask

initial begin
    errors = 0;
    mismatches_printed = 0;

    $readmemh("FPGA_Parameters/mem_files/conv1_full_test/conv1_input.mem", image_data);
    $readmemh("FPGA_Parameters/mem_files/conv1_full_test/conv1_weights.mem", flat_weights);
    $readmemh("FPGA_Parameters/mem_files/conv1_full_test/conv1_biases.mem", biases);
    $readmemh("FPGA_Parameters/mem_files/conv1_relu_pool_test/conv1_relu_expected.mem", expected_relu);
    $readmemh("FPGA_Parameters/mem_files/conv1_relu_pool_test/conv1_pool_expected.mem", expected_pool);

    for (i = 0; i < FILTER_COUNT; i = i + 1) begin
        for (j = 0; j < 27; j = j + 1) begin
            weights[i][j] = flat_weights[i*27+j];
        end
    end

    for (py = 0; py < 15; py = py + 1) begin
        for (px = 0; px < 15; px = px + 1) begin
            for (quadrant = 0; quadrant < 4; quadrant = quadrant + 1) begin
                load_patch(
                    py*2 + quadrant/2,
                    px*2 + quadrant%2
                );

                #1;

                for (f = 0; f < FILTER_COUNT; f = f + 1)
                    relu_inputs[f] = conv_outputs[f];

                #1;

                for (f = 0; f < FILTER_COUNT; f = f + 1) begin
                    output_index =
                        f*900 +
                        (py*2 + quadrant/2)*30 +
                        (px*2 + quadrant%2);

                    if (relu_outputs[f] !== expected_relu[output_index]) begin
                        if (mismatches_printed < 10) begin
                            $display("RELU MISMATCH filter=%0d y=%0d x=%0d RTL=%0d expected=%0d",
                                f, py*2+quadrant/2, px*2+quadrant%2,
                                relu_outputs[f], expected_relu[output_index]);
                            mismatches_printed = mismatches_printed + 1;
                        end
                        errors = errors + 1;
                    end

                    pool_inputs[quadrant][f] = relu_outputs[f];
                end
            end

            #1;

            for (f = 0; f < FILTER_COUNT; f = f + 1) begin
                output_index = f*225 + py*15 + px;

                if (pool_outputs[f] !== expected_pool[output_index]) begin
                    if (mismatches_printed < 10) begin
                        $display("POOL MISMATCH filter=%0d y=%0d x=%0d RTL=%0d expected=%0d",
                            f, py, px, pool_outputs[f],
                            expected_pool[output_index]);
                        mismatches_printed = mismatches_printed + 1;
                    end
                    errors = errors + 1;
                end
            end
        end
    end

    $display("ReLU outputs checked: %0d", OUTPUT_COUNT);
    $display("Pooled outputs checked: %0d", POOL_COUNT);
    $display("Total mismatches: %0d", errors);

    if (errors == 0)
        $display("CONV1 RELU POOL FULL IMAGE TEST PASSED");
    else
        $display("CONV1 RELU POOL FULL IMAGE TEST FAILED");

    $finish;
end

endmodule
