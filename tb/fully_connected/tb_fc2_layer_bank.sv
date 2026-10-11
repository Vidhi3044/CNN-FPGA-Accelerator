`timescale 1ns/1ps

module tb_fc2_layer_bank;

localparam INPUT_COUNT = 128;
localparam NEURON_COUNT = 3;

reg signed [31:0] inputs [0:INPUT_COUNT-1];
reg signed [7:0] weights [0:NEURON_COUNT-1][0:INPUT_COUNT-1];
reg signed [31:0] biases [0:NEURON_COUNT-1];

wire signed [31:0] outputs [0:NEURON_COUNT-1];

integer i;
integer j;

fc2_layer_bank #(
    .INPUT_COUNT(INPUT_COUNT),
    .NEURON_COUNT(NEURON_COUNT)
) uut (
    .inputs(inputs),
    .weights(weights),
    .biases(biases),
    .outputs(outputs)
);

initial begin

    $dumpfile("simulations/fully_connected/fc2_layer_bank.vcd");
    $dumpvars(0, tb_fc2_layer_bank);

    for (i = 0; i < INPUT_COUNT; i = i + 1) begin
        inputs[i] = 32'sd1;
    end

    for (j = 0; j < NEURON_COUNT; j = j + 1) begin
        for (i = 0; i < INPUT_COUNT; i = i + 1) begin
            weights[j][i] = 8'sd0;
        end
    end

    for (i = 0; i < INPUT_COUNT; i = i + 1) begin
        weights[0][i] = 8'sd1;
        weights[1][i] = 8'sd2;
        weights[2][i] = -8'sd1;
    end

    biases[0] = 32'sd10;
    biases[1] = 32'sd20;
    biases[2] = 32'sd30;

    #10;

    $display("FC2 Output 0 %0d", outputs[0]);
    $display("FC2 Output 1 %0d", outputs[1]);
    $display("FC2 Output 2 %0d", outputs[2]);

    for (i = 0; i < INPUT_COUNT; i = i + 1) begin
        inputs[i] = -32'sd1;
    end

    #10;

    $display("FC2 Negative Input Output 0 %0d", outputs[0]);
    $display("FC2 Negative Input Output 1 %0d", outputs[1]);
    $display("FC2 Negative Input Output 2 %0d", outputs[2]);

    $finish;

end

endmodule