module conv1_relu_pipeline #(
    parameter FILTER_COUNT = 16
)(
    input logic signed [7:0] inputs [0:26],
    input logic signed [7:0] weights [0:FILTER_COUNT-1][0:26],
    input logic signed [31:0] biases [0:FILTER_COUNT-1],

    output logic signed [31:0] conv_outputs [0:FILTER_COUNT-1],
    output logic signed [31:0] relu_outputs [0:FILTER_COUNT-1]
);

conv1_filter_bank #(
    .FILTER_COUNT(FILTER_COUNT)
) conv1_filters (
    .inputs(inputs),
    .weights(weights),
    .biases(biases),
    .outputs(conv_outputs)
);

relu_bank #(
    .FILTER_COUNT(FILTER_COUNT)
) relu_stage (
    .input_values(conv_outputs),
    .output_values(relu_outputs)
);

endmodule