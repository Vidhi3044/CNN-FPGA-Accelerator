
`timescale 1ns/1ps

module requantize_int8 #(
    parameter integer SHIFT = 8
)(
    input logic signed [31:0] accumulator,
    input logic signed [31:0] multiplier,
    input logic signed [7:0] zero_point,
    output logic signed [7:0] output_value
);

logic signed [63:0] product;
logic signed [63:0] rounded_product;
logic signed [63:0] scaled_value;

always_comb begin
    product = accumulator * multiplier;

    if (SHIFT > 0)
        rounded_product = product + (64'sd1 <<< (SHIFT - 1));
    else
        rounded_product = product;

    if (SHIFT > 0)
        scaled_value = rounded_product >>> SHIFT;
    else
        scaled_value = rounded_product;

    scaled_value = scaled_value + zero_point;

    if (scaled_value > 127)
        output_value = 8'sd127;
    else if (scaled_value < -128)
        output_value = -8'sd128;
    else
        output_value = scaled_value[7:0];
end

initial begin
    if (SHIFT < 0 || SHIFT > 31)
        $error("SHIFT must be between 0 and 31");
end

endmodule
