`timescale 1ns/1ps

module tb_conv1_filter_bank;

localparam FILTER_COUNT = 16;

reg signed [7:0] inputs [0:26];
reg signed [7:0] weights [0:FILTER_COUNT-1][0:26];
reg signed [31:0] biases [0:FILTER_COUNT-1];

wire signed [31:0] outputs [0:FILTER_COUNT-1];

integer i;
integer j;

conv1_filter_bank #(
    .FILTER_COUNT(FILTER_COUNT)
) uut (
    .inputs(inputs),
    .weights(weights),
    .biases(biases),
    .outputs(outputs)
);

initial begin
    $dumpfile("simulations/convolution/conv1_filter_bank.vcd");
    $dumpvars(0, tb_conv1_filter_bank);

    for (i = 0; i < 27; i = i + 1) begin
        inputs[i] = i + 1;
    end

    for (i = 0; i < FILTER_COUNT; i = i + 1) begin
        biases[i] = 0;

        for (j = 0; j < 27; j = j + 1) begin
            if ((j == 0) ||
                (j == 2) ||
                (j == 4) ||
                (j == 6) ||
                (j == 8) ||
                (j == 9) ||
                (j == 11) ||
                (j == 13) ||
                (j == 15) ||
                (j == 17) ||
                (j == 18) ||
                (j == 20) ||
                (j == 22) ||
                (j == 24) ||
                (j == 26)) begin
                weights[i][j] = 1;
            end
            else begin
                weights[i][j] = 0;
            end
        end
    end

    #10;

    for (i = 0; i < FILTER_COUNT; i = i + 1) begin
        $display("Filter %0d output %0d", i, outputs[i]);
    end

    biases[0] = 5;

    #10;

    $display("Filter 0 output with bias %0d", outputs[0]);

    $finish;
end

endmodule