module conv3x3_mac (
    input signed [7:0] input_0,
    input signed [7:0] input_1,
    input signed [7:0] input_2,
    input signed [7:0] input_3,
    input signed [7:0] input_4,
    input signed [7:0] input_5,
    input signed [7:0] input_6,
    input signed [7:0] input_7,
    input signed [7:0] input_8,

    input signed [7:0] weight_0,
    input signed [7:0] weight_1,
    input signed [7:0] weight_2,
    input signed [7:0] weight_3,
    input signed [7:0] weight_4,
    input signed [7:0] weight_5,
    input signed [7:0] weight_6,
    input signed [7:0] weight_7,
    input signed [7:0] weight_8,

    input signed [31:0] bias,
    output signed [31:0] output_value
);

wire signed [15:0] product_0;
wire signed [15:0] product_1;
wire signed [15:0] product_2;
wire signed [15:0] product_3;
wire signed [15:0] product_4;
wire signed [15:0] product_5;
wire signed [15:0] product_6;
wire signed [15:0] product_7;
wire signed [15:0] product_8;

wire signed [31:0] sum_products;

int8_multiplier multiplier_0 (
    .input_value(input_0),
    .weight_value(weight_0),
    .product(product_0)
);

int8_multiplier multiplier_1 (
    .input_value(input_1),
    .weight_value(weight_1),
    .product(product_1)
);

int8_multiplier multiplier_2 (
    .input_value(input_2),
    .weight_value(weight_2),
    .product(product_2)
);

int8_multiplier multiplier_3 (
    .input_value(input_3),
    .weight_value(weight_3),
    .product(product_3)
);

int8_multiplier multiplier_4 (
    .input_value(input_4),
    .weight_value(weight_4),
    .product(product_4)
);

int8_multiplier multiplier_5 (
    .input_value(input_5),
    .weight_value(weight_5),
    .product(product_5)
);

int8_multiplier multiplier_6 (
    .input_value(input_6),
    .weight_value(weight_6),
    .product(product_6)
);

int8_multiplier multiplier_7 (
    .input_value(input_7),
    .weight_value(weight_7),
    .product(product_7)
);

int8_multiplier multiplier_8 (
    .input_value(input_8),
    .weight_value(weight_8),
    .product(product_8)
);

assign sum_products =
    {{16{product_0[15]}}, product_0} +
    {{16{product_1[15]}}, product_1} +
    {{16{product_2[15]}}, product_2} +
    {{16{product_3[15]}}, product_3} +
    {{16{product_4[15]}}, product_4} +
    {{16{product_5[15]}}, product_5} +
    {{16{product_6[15]}}, product_6} +
    {{16{product_7[15]}}, product_7} +
    {{16{product_8[15]}}, product_8};

assign output_value = sum_products + bias;

endmodule