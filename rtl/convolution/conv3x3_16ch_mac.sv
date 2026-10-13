
`timescale 1ns/1ps

module conv3x3_16ch_mac #(
    parameter integer INPUT_COUNT = 144
)(
    input logic signed [7:0] inputs [0:INPUT_COUNT-1],
    input logic signed [7:0] weights [0:INPUT_COUNT-1],
    input logic signed [31:0] bias,
    output logic signed [31:0] output_value
);

integer i;
logic signed [31:0] accumulator;

always_comb begin
    accumulator = bias;

    for (i = 0; i < INPUT_COUNT; i = i + 1)
        accumulator = accumulator + inputs[i] * weights[i];

    output_value = accumulator;
end

initial begin
    if (INPUT_COUNT < 1)
        $error("INPUT_COUNT must be positive");
end

endmodule
