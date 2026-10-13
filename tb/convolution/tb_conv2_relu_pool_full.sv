
`timescale 1ns/1ps

module tb_conv2_relu_pool_full;

localparam integer FILTER_COUNT = 32;
localparam integer INPUT_COUNT = 144;
localparam integer INPUT_VALUES = 3600;
localparam integer CONV_VALUES = 5408;
localparam integer POOL_VALUES = 1152;

reg signed [7:0] image_data [0:INPUT_VALUES-1];
reg signed [7:0] flat_weights [0:FILTER_COUNT*INPUT_COUNT-1];
reg signed [7:0] weights [0:FILTER_COUNT-1][0:INPUT_COUNT-1];
reg signed [31:0] biases [0:FILTER_COUNT-1];

reg signed [31:0] expected_relu [0:CONV_VALUES-1];
reg signed [31:0] expected_pool [0:POOL_VALUES-1];
reg signed [31:0] relu_map [0:CONV_VALUES-1];

reg signed [7:0] patch [0:INPUT_COUNT-1];
wire signed [31:0] conv_outputs [0:FILTER_COUNT-1];

reg signed [31:0] relu_inputs [0:FILTER_COUNT-1];
wire signed [31:0] relu_outputs [0:FILTER_COUNT-1];

reg signed [31:0] pool_inputs [0:3][0:FILTER_COUNT-1];
wire signed [31:0] pool_outputs [0:FILTER_COUNT-1];

integer f;
integer c;
integer y;
integer x;
integer row;
integer column;
integer channel;
integer q;
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
    $readmemh("FPGA_Parameters/mem_files/conv2_relu_pool_test/conv2_relu_expected.mem", expected_relu);
    $readmemh("FPGA_Parameters/mem_files/conv2_relu_pool_test/conv2_pool_expected.mem", expected_pool);

    for (f = 0; f < FILTER_COUNT; f = f + 1) begin
        for (c = 0; c < INPUT_COUNT; c = c + 1) begin
            weights[f][c] = flat_weights[f*INPUT_COUNT+c];
        end
    end

    for (y = 0; y < 13; y = y + 1) begin
        for (x = 0; x < 13; x = x + 1) begin
            load_patch(y, x);
            #1;

            for (f = 0; f < FILTER_COUNT; f = f + 1)
                relu_inputs[f] = conv_outputs[f];

            #1;

            for (f = 0; f < FILTER_COUNT; f = f + 1) begin
                idx = f*169 + y*13 + x;
                relu_map[idx] = relu_outputs[f];

                if (relu_outputs[f] !== expected_relu[idx]) begin
                    if (shown < 10) begin
                        $display("RELU MISMATCH filter=%0d y=%0d x=%0d RTL=%0d expected=%0d",
                            f, y, x, relu_outputs[f], expected_relu[idx]);
                        shown = shown + 1;
                    end
                    errors = errors + 1;
                end
            end
        end
    end

    for (y = 0; y < 6; y = y + 1) begin
        for (x = 0; x < 6; x = x + 1) begin
            for (q = 0; q < 4; q = q + 1) begin
                for (f = 0; f < FILTER_COUNT; f = f + 1) begin
                    case (q)
                        0: idx = f*169 + (2*y)*13 + (2*x);
                        1: idx = f*169 + (2*y)*13 + (2*x+1);
                        2: idx = f*169 + (2*y+1)*13 + (2*x);
                        3: idx = f*169 + (2*y+1)*13 + (2*x+1);
                    endcase

                    pool_inputs[q][f] = relu_map[idx];
                end
            end

            #1;

            for (f = 0; f < FILTER_COUNT; f = f + 1) begin
                idx = f*36 + y*6 + x;

                if (pool_outputs[f] !== expected_pool[idx]) begin
                    if (shown < 10) begin
                        $display("POOL MISMATCH filter=%0d y=%0d x=%0d RTL=%0d expected=%0d",
                            f, y, x, pool_outputs[f], expected_pool[idx]);
                        shown = shown + 1;
                    end
                    errors = errors + 1;
                end
            end
        end
    end

    $display("Conv2 ReLU outputs checked: %0d", CONV_VALUES);
    $display("Conv2 pooled outputs checked: %0d", POOL_VALUES);
    $display("Total mismatches: %0d", errors);

    if (errors == 0)
        $display("CONV2 RELU POOL FULL IMAGE TEST PASSED");
    else
        $display("CONV2 RELU POOL FULL IMAGE TEST FAILED");

    $finish;
end

endmodule
