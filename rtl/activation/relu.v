module relu (
    input signed [31:0] input_value,
    output signed [31:0] output_value
);

assign output_value = input_value[31] ? 32'sd0 : input_value;

endmodule