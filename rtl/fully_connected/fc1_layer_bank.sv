`timescale 1ns/1ps

module fc1_layer_bank #(
    parameter INPUT_COUNT = 4,
    parameter NEURON_COUNT = 3
)(
    input signed [7:0] inputs [0:INPUT_COUNT-1],
    input signed [7:0] weights [0:NEURON_COUNT-1][0:INPUT_COUNT-1],
    input signed [31:0] biases [0:NEURON_COUNT-1],
    output reg signed [31:0] outputs [0:NEURON_COUNT-1]
);

integer neuron_index;
integer input_index;
reg signed [31:0] sum;

always @* begin
    for (neuron_index = 0; neuron_index < NEURON_COUNT; neuron_index = neuron_index + 1) begin
        sum = biases[neuron_index];

        for (input_index = 0; input_index < INPUT_COUNT; input_index = input_index + 1) begin
            sum = sum + ($signed(inputs[input_index]) * $signed(weights[neuron_index][input_index]));
        end

        outputs[neuron_index] = sum;
    end
end

endmodule