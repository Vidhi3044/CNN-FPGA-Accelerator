module conv3x3_rgb_mac (
    input signed [7:0] input_0,
    input signed [7:0] input_1,
    input signed [7:0] input_2,
    input signed [7:0] input_3,
    input signed [7:0] input_4,
    input signed [7:0] input_5,
    input signed [7:0] input_6,
    input signed [7:0] input_7,
    input signed [7:0] input_8,

    input signed [7:0] input_9,
    input signed [7:0] input_10,
    input signed [7:0] input_11,
    input signed [7:0] input_12,
    input signed [7:0] input_13,
    input signed [7:0] input_14,
    input signed [7:0] input_15,
    input signed [7:0] input_16,
    input signed [7:0] input_17,

    input signed [7:0] input_18,
    input signed [7:0] input_19,
    input signed [7:0] input_20,
    input signed [7:0] input_21,
    input signed [7:0] input_22,
    input signed [7:0] input_23,
    input signed [7:0] input_24,
    input signed [7:0] input_25,
    input signed [7:0] input_26,

    input signed [7:0] weight_0,
    input signed [7:0] weight_1,
    input signed [7:0] weight_2,
    input signed [7:0] weight_3,
    input signed [7:0] weight_4,
    input signed [7:0] weight_5,
    input signed [7:0] weight_6,
    input signed [7:0] weight_7,
    input signed [7:0] weight_8,

    input signed [7:0] weight_9,
    input signed [7:0] weight_10,
    input signed [7:0] weight_11,
    input signed [7:0] weight_12,
    input signed [7:0] weight_13,
    input signed [7:0] weight_14,
    input signed [7:0] weight_15,
    input signed [7:0] weight_16,
    input signed [7:0] weight_17,

    input signed [7:0] weight_18,
    input signed [7:0] weight_19,
    input signed [7:0] weight_20,
    input signed [7:0] weight_21,
    input signed [7:0] weight_22,
    input signed [7:0] weight_23,
    input signed [7:0] weight_24,
    input signed [7:0] weight_25,
    input signed [7:0] weight_26,

    input signed [31:0] bias,
    output signed [31:0] output_value
);

wire signed [31:0] channel_0_sum;
wire signed [31:0] channel_1_sum;
wire signed [31:0] channel_2_sum;

wire signed [31:0] channel_sum;

conv3x3_mac channel_0_mac (
    .input_0(input_0),
    .input_1(input_1),
    .input_2(input_2),
    .input_3(input_3),
    .input_4(input_4),
    .input_5(input_5),
    .input_6(input_6),
    .input_7(input_7),
    .input_8(input_8),

    .weight_0(weight_0),
    .weight_1(weight_1),
    .weight_2(weight_2),
    .weight_3(weight_3),
    .weight_4(weight_4),
    .weight_5(weight_5),
    .weight_6(weight_6),
    .weight_7(weight_7),
    .weight_8(weight_8),

    .bias(32'sd0),
    .output_value(channel_0_sum)
);

conv3x3_mac channel_1_mac (
    .input_0(input_9),
    .input_1(input_10),
    .input_2(input_11),
    .input_3(input_12),
    .input_4(input_13),
    .input_5(input_14),
    .input_6(input_15),
    .input_7(input_16),
    .input_8(input_17),

    .weight_0(weight_9),
    .weight_1(weight_10),
    .weight_2(weight_11),
    .weight_3(weight_12),
    .weight_4(weight_13),
    .weight_5(weight_14),
    .weight_6(weight_15),
    .weight_7(weight_16),
    .weight_8(weight_17),

    .bias(32'sd0),
    .output_value(channel_1_sum)
);

conv3x3_mac channel_2_mac (
    .input_0(input_18),
    .input_1(input_19),
    .input_2(input_20),
    .input_3(input_21),
    .input_4(input_22),
    .input_5(input_23),
    .input_6(input_24),
    .input_7(input_25),
    .input_8(input_26),

    .weight_0(weight_18),
    .weight_1(weight_19),
    .weight_2(weight_20),
    .weight_3(weight_21),
    .weight_4(weight_22),
    .weight_5(weight_23),
    .weight_6(weight_24),
    .weight_7(weight_25),
    .weight_8(weight_26),

    .bias(32'sd0),
    .output_value(channel_2_sum)
);

assign channel_sum =
    channel_0_sum +
    channel_1_sum +
    channel_2_sum;

assign output_value = channel_sum + bias;

endmodule