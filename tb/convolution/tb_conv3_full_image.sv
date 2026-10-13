`timescale 1ns/1ps

module tb_conv3_full_image;

localparam integer FILTER_COUNT = 64;
localparam integer INPUT_CHANNELS = 32;
localparam integer INPUT_SIZE = 6;
localparam integer OUTPUT_SIZE = 4;
localparam integer INPUT_COUNT = 288;
localparam integer INPUT_VALUES = 1152;
localparam integer WEIGHT_VALUES = 18432;
localparam integer OUTPUT_VALUES = 1024;

reg signed [7:0] pooled_input [0:INPUT_VALUES-1];
reg signed [7:0] flat_weights [0:WEIGHT_VALUES-1];
reg signed [31:0] biases [0:FILTER_COUNT-1];
reg signed [31:0] expected_outputs [0:OUTPUT_VALUES-1];

reg signed [7:0] patch [0:INPUT_COUNT-1];
reg signed [7:0] filter_weights [0:INPUT_COUNT-1];
reg signed [31:0] filter_bias;
wire signed [31:0] actual_output;

integer f;
integer y;
integer x;
integer c;
integer ky;
integer kx;
integer i;
integer idx;
integer errors;
integer shown;

conv3x3_16ch_mac #(
    .INPUT_COUNT(INPUT_COUNT)
) conv3_mac (
    .inputs(patch),
    .weights(filter_weights),
    .bias(filter_bias),
    .output_value(actual_output)
);

initial begin
    errors = 0;
    shown = 0;

    $readmemh("FPGA_Parameters/mem_files/conv3_integer_test/conv3_input.mem", pooled_input);
    $readmemh("FPGA_Parameters/mem_files/weights/features_6_weight.mem", flat_weights);
    $readmemh("FPGA_Parameters/mem_files/biases/features_6_bias.mem", biases);
    $readmemh("FPGA_Parameters/mem_files/conv3_integer_test/conv3_acc_expected.mem", expected_outputs);

    for (f = 0; f < FILTER_COUNT; f = f + 1) begin
        filter_bias = biases[f];

        for (i = 0; i < INPUT_COUNT; i = i + 1)
            filter_weights[i] = flat_weights[f*INPUT_COUNT+i];

        for (y = 0; y < OUTPUT_SIZE; y = y + 1) begin
            for (x = 0; x < OUTPUT_SIZE; x = x + 1) begin

                for (c = 0; c < INPUT_CHANNELS; c = c + 1) begin
                    for (ky = 0; ky < 3; ky = ky + 1) begin
                        for (kx = 0; kx < 3; kx = kx + 1) begin
                            patch[c*9+ky*3+kx] =
                                pooled_input[c*INPUT_SIZE*INPUT_SIZE+
                                             (y+ky)*INPUT_SIZE+
                                             (x+kx)];
                        end
                    end
                end

                #1;

                idx = f*OUTPUT_SIZE*OUTPUT_SIZE+y*OUTPUT_SIZE+x;

                if (actual_output !== expected_outputs[idx]) begin
                    if (shown < 10) begin
                        $display("MISMATCH filter=%0d y=%0d x=%0d actual=%0d expected=%0d",
                            f, y, x, actual_output, expected_outputs[idx]);
                        shown = shown + 1;
                    end
                    errors = errors + 1;
                end

            end
        end
    end

    $display("Conv3 outputs checked: %0d", OUTPUT_VALUES);
    $display("Total mismatches: %0d", errors);

    if (errors == 0)
        $display("CONV3 FULL IMAGE TEST PASSED");
    else
        $display("CONV3 FULL IMAGE TEST FAILED");

    $finish;
end

endmodule