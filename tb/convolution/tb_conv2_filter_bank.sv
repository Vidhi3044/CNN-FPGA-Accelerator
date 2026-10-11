`timescale 1ns/1ps

module tb_conv2_filter_bank;

localparam FILTER_COUNT = 32;

reg signed [7:0] inputs [0:143];

reg signed [7:0] weights [0:FILTER_COUNT-1][0:143];

reg signed [31:0] biases [0:FILTER_COUNT-1];

wire signed [31:0] outputs [0:FILTER_COUNT-1];

integer i;
integer j;

conv2_filter_bank #(
    .FILTER_COUNT(FILTER_COUNT)
) uut (

    .inputs(inputs),

    .weights(weights),

    .biases(biases),

    .outputs(outputs)

);

initial begin

    $dumpfile("simulations/convolution/conv2_filter_bank.vcd");

    $dumpvars(0, tb_conv2_filter_bank);

    for (i = 0; i < 144; i = i + 1) begin
        inputs[i] = 8'sd1;
    end

    for (i = 0; i < FILTER_COUNT; i = i + 1) begin

        biases[i] = 32'sd0;

        for (j = 0; j < 144; j = j + 1) begin
            weights[i][j] = 8'sd1;
        end

    end

    #10;

    for (i = 0; i < FILTER_COUNT; i = i + 1) begin
        $display("Filter %0d output %0d", i, outputs[i]);
    end

    biases[0] = 32'sd5;

    #10;

    $display("Filter 0 output with bias %0d", outputs[0]);

    for (i = 0; i < 144; i = i + 1) begin
        inputs[i] = -8'sd1;
    end

    biases[0] = 32'sd0;

    #10;

    $display("Filter 0 negative input output %0d", outputs[0]);

    $finish;

end

endmodule