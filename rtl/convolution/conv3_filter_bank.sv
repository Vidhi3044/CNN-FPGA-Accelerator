
`timescale 1ns/1ps

module conv3_filter_bank #(
    parameter integer FILTER_COUNT = 64,
    parameter integer INPUT_COUNT = 288
)(
    input logic signed [7:0] inputs [0:INPUT_COUNT-1],
    input logic signed [7:0] weights [0:FILTER_COUNT-1][0:INPUT_COUNT-1],
    input logic signed [31:0] biases [0:FILTER_COUNT-1],
    output wire signed [31:0] outputs [0:FILTER_COUNT-1]
);

genvar filter_index;
genvar weight_index;

generate
    for (filter_index = 0; filter_index < FILTER_COUNT; filter_index = filter_index + 1) begin : filter_instances

        wire signed [7:0] local_weights [0:INPUT_COUNT-1];

        for (weight_index = 0; weight_index < INPUT_COUNT; weight_index = weight_index + 1) begin : weight_connections
            assign local_weights[weight_index] = weights[filter_index][weight_index];
        end

        conv3x3_16ch_mac #(
            .INPUT_COUNT(INPUT_COUNT)
        ) filter_mac (
            .inputs(inputs),
            .weights(local_weights),
            .bias(biases[filter_index]),
            .output_value(outputs[filter_index])
        );

    end
endgenerate

endmodule
