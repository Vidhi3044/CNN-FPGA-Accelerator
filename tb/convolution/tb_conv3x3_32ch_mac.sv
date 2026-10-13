
`timescale 1ns/1ps

module tb_conv3x3_32ch_mac;

localparam integer INPUT_COUNT = 288;

logic signed [7:0] inputs [0:INPUT_COUNT-1];
logic signed [7:0] weights [0:INPUT_COUNT-1];
logic signed [31:0] bias;
logic signed [31:0] output_value;

integer i;

conv3x3_16ch_mac #(
    .INPUT_COUNT(INPUT_COUNT)
) dut (
    .inputs(inputs),
    .weights(weights),
    .bias(bias),
    .output_value(output_value)
);

initial begin
    bias = 32'sd0;

    for (i = 0; i < INPUT_COUNT; i = i + 1) begin
        inputs[i] = 8'sd1;
        weights[i] = 8'sd1;
    end

    #1;
    if (output_value !== 32'sd288)
        $fatal(1, "Conv3 MAC positive test failed");

    bias = 32'sd10;
    #1;
    if (output_value !== 32'sd298)
        $fatal(1, "Conv3 MAC bias test failed");

    for (i = 0; i < INPUT_COUNT; i = i + 1)
        inputs[i] = -8'sd1;

    bias = 32'sd0;
    #1;
    if (output_value !== -32'sd288)
        $fatal(1, "Conv3 MAC negative test failed");

    $display("Conv3 32-channel MAC test passed");
    $finish;
end

endmodule
