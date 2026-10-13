
`timescale 1ns/1ps

module tb_conv3_filter_bank;

localparam integer FILTER_COUNT = 64;
localparam integer INPUT_COUNT = 288;

logic signed [7:0] inputs [0:INPUT_COUNT-1];
logic signed [7:0] weights [0:FILTER_COUNT-1][0:INPUT_COUNT-1];
logic signed [31:0] biases [0:FILTER_COUNT-1];
wire signed [31:0] outputs [0:FILTER_COUNT-1];

integer i;
integer j;

conv3_filter_bank #(
    .FILTER_COUNT(FILTER_COUNT),
    .INPUT_COUNT(INPUT_COUNT)
) dut (
    .inputs(inputs),
    .weights(weights),
    .biases(biases),
    .outputs(outputs)
);

initial begin
    for (i = 0; i < INPUT_COUNT; i = i + 1)
        inputs[i] = 8'sd1;

    for (i = 0; i < FILTER_COUNT; i = i + 1) begin
        biases[i] = i;

        for (j = 0; j < INPUT_COUNT; j = j + 1)
            weights[i][j] = 8'sd1;
    end

    #10;

    for (i = 0; i < FILTER_COUNT; i = i + 1) begin
        if (outputs[i] !== 32'sd288 + i)
            $fatal(1, "Filter output mismatch at filter %0d", i);
    end

    $display("Conv3 filter bank test passed");
    $finish;
end

endmodule
