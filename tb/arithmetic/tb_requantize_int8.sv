
`timescale 1ns/1ps

module tb_requantize_int8;

logic signed [31:0] accumulator;
logic signed [31:0] multiplier;
logic signed [7:0] zero_point;
logic signed [7:0] output_value;

requantize_int8 #(
    .SHIFT(8)
) dut (
    .accumulator(accumulator),
    .multiplier(multiplier),
    .zero_point(zero_point),
    .output_value(output_value)
);

initial begin
    multiplier = 32'sd256;
    zero_point = 8'sd0;

    accumulator = 32'sd10;
    #1;
    if (output_value !== 8'sd10)
        $fatal(1, "Positive requantization failed");

    accumulator = -32'sd10;
    #1;
    if (output_value !== -8'sd10)
        $fatal(1, "Negative requantization failed");

    accumulator = 32'sd1000;
    #1;
    if (output_value !== 8'sd127)
        $fatal(1, "Positive saturation failed");

    accumulator = -32'sd1000;
    #1;
    if (output_value !== -8'sd128)
        $fatal(1, "Negative saturation failed");

    zero_point = 8'sd5;
    accumulator = 32'sd10;
    #1;
    if (output_value !== 8'sd15)
        $fatal(1, "Zero-point addition failed");

    $display("INT8 requantization test passed");
    $finish;
end

endmodule
