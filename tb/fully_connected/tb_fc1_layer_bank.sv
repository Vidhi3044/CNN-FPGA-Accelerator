`timescale 1ns/1ps

module tb_fc1_layer_bank;

localparam INPUT_COUNT = 4;
localparam NEURON_COUNT = 3;

reg signed [7:0] inputs [0:INPUT_COUNT-1];
reg signed [7:0] weights [0:NEURON_COUNT-1][0:INPUT_COUNT-1];
reg signed [31:0] biases [0:NEURON_COUNT-1];

wire signed [31:0] outputs [0:NEURON_COUNT-1];

integer i;
integer j;

fc1_layer_bank #(
    .INPUT_COUNT(INPUT_COUNT),
    .NEURON_COUNT(NEURON_COUNT)
) uut (
    .inputs(inputs),
    .weights(weights),
    .biases(biases),
    .outputs(outputs)
);

initial begin
    $dumpfile("simulations/fully_connected/fc1_layer_bank.vcd");
    $dumpvars(0, tb_fc1_layer_bank);

    inputs[0] = 8'sd1;
    inputs[1] = 8'sd2;
    inputs[2] = 8'sd3;
    inputs[3] = 8'sd4;

    weights[0][0] = 8'sd1;
    weights[0][1] = 8'sd1;
    weights[0][2] = 8'sd1;
    weights[0][3] = 8'sd1;

    weights[1][0] = 8'sd2;
    weights[1][1] = 8'sd2;
    weights[1][2] = 8'sd2;
    weights[1][3] = 8'sd2;

    weights[2][0] = 8'sd1;
    weights[2][1] = -8'sd1;
    weights[2][2] = 8'sd1;
    weights[2][3] = -8'sd1;

    biases[0] = 32'sd10;
    biases[1] = -32'sd5;
    biases[2] = 32'sd0;

    #10;

    $display("Neuron 0 output %0d", outputs[0]);
    $display("Neuron 1 output %0d", outputs[1]);
    $display("Neuron 2 output %0d", outputs[2]);

    inputs[0] = -8'sd1;
    inputs[1] = -8'sd1;
    inputs[2] = -8'sd1;
    inputs[3] = -8'sd1;

    biases[0] = 32'sd0;
    biases[1] = 32'sd0;
    biases[2] = 32'sd0;

    #10;

    $display("Neuron 0 negative output %0d", outputs[0]);
    $display("Neuron 1 negative output %0d", outputs[1]);
    $display("Neuron 2 negative output %0d", outputs[2]);

    $finish;
end

endmodule