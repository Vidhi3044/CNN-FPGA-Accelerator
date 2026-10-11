module maxpool2x2 (
    input signed [31:0] input_a,
    input signed [31:0] input_b,
    input signed [31:0] input_c,
    input signed [31:0] input_d,
    output signed [31:0] output_value
);

wire signed [31:0] max_ab;
wire signed [31:0] max_cd;

assign max_ab = (input_a > input_b) ? input_a : input_b;
assign max_cd = (input_c > input_d) ? input_c : input_d;

assign output_value = (max_ab > max_cd) ? max_ab : max_cd;

endmodule