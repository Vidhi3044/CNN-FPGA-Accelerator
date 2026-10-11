`timescale 1ns/1ps

module fc2_layer_bank #(
    parameter INPUT_COUNT = 128,
    parameter NEURON_COUNT = 3
)(
    input signed [31:0] inputs [0:INPUT_COUNT-1],
    input signed [7:0] weights [0:NEURON_COUNT-1][0:INPUT_COUNT-1],
    input signed [31:0] biases [0:NEURON_COUNT-1],
    output logic signed [31:0] outputs [0:NEURON_COUNT-1]
);

logic signed [63:0] sums [0:NEURON_COUNT-1];

integer i;
integer j;

always @* begin

    for (j = 0; j < NEURON_COUNT; j = j + 1) begin

        sums[j] = biases[j];

        for (i = 0; i < INPUT_COUNT; i = i + 1) begin
            sums[j] = sums[j] + (inputs[i] * weights[j][i]);
        end

        outputs[j] = sums[j][31:0];

    end

end

endmodule