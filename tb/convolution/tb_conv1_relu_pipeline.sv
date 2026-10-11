`timescale 1ns/1ps

module tb_conv1_relu_pipeline;

parameter FILTER_COUNT = 16;

logic signed [7:0] inputs [0:26];
logic signed [7:0] weights [0:FILTER_COUNT-1][0:26];
logic signed [31:0] biases [0:FILTER_COUNT-1];

logic signed [31:0] conv_outputs [0:FILTER_COUNT-1];
logic signed [31:0] relu_outputs [0:FILTER_COUNT-1];

integer i;
integer j;

conv1_relu_pipeline #(
    .FILTER_COUNT(FILTER_COUNT)
) uut (
    .inputs(inputs),
    .weights(weights),
    .biases(biases),
    .conv_outputs(conv_outputs),
    .relu_outputs(relu_outputs)
);

initial begin
    $dumpfile("simulations/convolution/conv1_relu_pipeline.vcd");
    $dumpvars(0, tb_conv1_relu_pipeline);

    for (i = 0; i < 27; i = i + 1) begin
        inputs[i] = 8'sd1;
    end

    for (i = 0; i < FILTER_COUNT; i = i + 1) begin
        biases[i] = 32'sd0;

        for (j = 0; j < 27; j = j + 1) begin
            weights[i][j] = 8'sd1;
        end
    end

    #10;

    $display("First Conv1 and ReLU test");

    for (i = 0; i < FILTER_COUNT; i = i + 1) begin
        $display("Filter %0d: convolution %0d, ReLU %0d",
                 i, conv_outputs[i], relu_outputs[i]);
    end

    for (i = 0; i < 27; i = i + 1) begin
        inputs[i] = -8'sd1;
    end

    #10;

    $display("Second Conv1 and ReLU test");

    for (i = 0; i < FILTER_COUNT; i = i + 1) begin
        $display("Filter %0d: convolution %0d, ReLU %0d",
                 i, conv_outputs[i], relu_outputs[i]);
    end

    inputs[0] = 8'sd2;
    biases[0] = 32'sd5;

    #10;

    $display("Third Conv1 and ReLU test");

    $display("Filter 0: convolution %0d, ReLU %0d",
             conv_outputs[0], relu_outputs[0]);

    $finish;
end

endmodule