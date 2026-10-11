module int8_multiplier (
    input  signed [7:0] input_value,
    input  signed [7:0] weight_value,
    output signed [15:0] product
);

assign product = input_value * weight_value;

endmodule