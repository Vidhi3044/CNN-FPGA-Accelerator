`timescale 1ns/1ps

module tb_conv3x3_rgb_mac;

reg signed [7:0] input_0;
reg signed [7:0] input_1;
reg signed [7:0] input_2;
reg signed [7:0] input_3;
reg signed [7:0] input_4;
reg signed [7:0] input_5;
reg signed [7:0] input_6;
reg signed [7:0] input_7;
reg signed [7:0] input_8;

reg signed [7:0] input_9;
reg signed [7:0] input_10;
reg signed [7:0] input_11;
reg signed [7:0] input_12;
reg signed [7:0] input_13;
reg signed [7:0] input_14;
reg signed [7:0] input_15;
reg signed [7:0] input_16;
reg signed [7:0] input_17;

reg signed [7:0] input_18;
reg signed [7:0] input_19;
reg signed [7:0] input_20;
reg signed [7:0] input_21;
reg signed [7:0] input_22;
reg signed [7:0] input_23;
reg signed [7:0] input_24;
reg signed [7:0] input_25;
reg signed [7:0] input_26;

reg signed [7:0] weight_0;
reg signed [7:0] weight_1;
reg signed [7:0] weight_2;
reg signed [7:0] weight_3;
reg signed [7:0] weight_4;
reg signed [7:0] weight_5;
reg signed [7:0] weight_6;
reg signed [7:0] weight_7;
reg signed [7:0] weight_8;

reg signed [7:0] weight_9;
reg signed [7:0] weight_10;
reg signed [7:0] weight_11;
reg signed [7:0] weight_12;
reg signed [7:0] weight_13;
reg signed [7:0] weight_14;
reg signed [7:0] weight_15;
reg signed [7:0] weight_16;
reg signed [7:0] weight_17;

reg signed [7:0] weight_18;
reg signed [7:0] weight_19;
reg signed [7:0] weight_20;
reg signed [7:0] weight_21;
reg signed [7:0] weight_22;
reg signed [7:0] weight_23;
reg signed [7:0] weight_24;
reg signed [7:0] weight_25;
reg signed [7:0] weight_26;

reg signed [31:0] bias;
wire signed [31:0] output_value;

conv3x3_rgb_mac uut (
    .input_0(input_0),
    .input_1(input_1),
    .input_2(input_2),
    .input_3(input_3),
    .input_4(input_4),
    .input_5(input_5),
    .input_6(input_6),
    .input_7(input_7),
    .input_8(input_8),

    .input_9(input_9),
    .input_10(input_10),
    .input_11(input_11),
    .input_12(input_12),
    .input_13(input_13),
    .input_14(input_14),
    .input_15(input_15),
    .input_16(input_16),
    .input_17(input_17),

    .input_18(input_18),
    .input_19(input_19),
    .input_20(input_20),
    .input_21(input_21),
    .input_22(input_22),
    .input_23(input_23),
    .input_24(input_24),
    .input_25(input_25),
    .input_26(input_26),

    .weight_0(weight_0),
    .weight_1(weight_1),
    .weight_2(weight_2),
    .weight_3(weight_3),
    .weight_4(weight_4),
    .weight_5(weight_5),
    .weight_6(weight_6),
    .weight_7(weight_7),
    .weight_8(weight_8),

    .weight_9(weight_9),
    .weight_10(weight_10),
    .weight_11(weight_11),
    .weight_12(weight_12),
    .weight_13(weight_13),
    .weight_14(weight_14),
    .weight_15(weight_15),
    .weight_16(weight_16),
    .weight_17(weight_17),

    .weight_18(weight_18),
    .weight_19(weight_19),
    .weight_20(weight_20),
    .weight_21(weight_21),
    .weight_22(weight_22),
    .weight_23(weight_23),
    .weight_24(weight_24),
    .weight_25(weight_25),
    .weight_26(weight_26),

    .bias(bias),
    .output_value(output_value)
);

initial begin
    $dumpfile("simulations/convolution/conv3x3_rgb_mac.vcd");
    $dumpvars(0, tb_conv3x3_rgb_mac);

    input_0 = 8'sd1;
    input_1 = 8'sd2;
    input_2 = 8'sd3;
    input_3 = 8'sd4;
    input_4 = 8'sd5;
    input_5 = 8'sd6;
    input_6 = 8'sd7;
    input_7 = 8'sd8;
    input_8 = 8'sd9;

    input_9 = 8'sd1;
    input_10 = 8'sd2;
    input_11 = 8'sd3;
    input_12 = 8'sd4;
    input_13 = 8'sd5;
    input_14 = 8'sd6;
    input_15 = 8'sd7;
    input_16 = 8'sd8;
    input_17 = 8'sd9;

    input_18 = 8'sd1;
    input_19 = 8'sd2;
    input_20 = 8'sd3;
    input_21 = 8'sd4;
    input_22 = 8'sd5;
    input_23 = 8'sd6;
    input_24 = 8'sd7;
    input_25 = 8'sd8;
    input_26 = 8'sd9;

    weight_0 = 8'sd1;
    weight_1 = 8'sd0;
    weight_2 = 8'sd1;
    weight_3 = 8'sd0;
    weight_4 = 8'sd1;
    weight_5 = 8'sd0;
    weight_6 = 8'sd1;
    weight_7 = 8'sd0;
    weight_8 = 8'sd1;

    weight_9 = 8'sd1;
    weight_10 = 8'sd0;
    weight_11 = 8'sd1;
    weight_12 = 8'sd0;
    weight_13 = 8'sd1;
    weight_14 = 8'sd0;
    weight_15 = 8'sd1;
    weight_16 = 8'sd0;
    weight_17 = 8'sd1;

    weight_18 = 8'sd1;
    weight_19 = 8'sd0;
    weight_20 = 8'sd1;
    weight_21 = 8'sd0;
    weight_22 = 8'sd1;
    weight_23 = 8'sd0;
    weight_24 = 8'sd1;
    weight_25 = 8'sd0;
    weight_26 = 8'sd1;

    bias = 32'sd0;

    #10;

    $display("Test 1: RGB convolution output %0d", output_value);

    bias = 32'sd5;

    #10;

    $display("Test 2: RGB convolution output with bias %0d", output_value);

    $finish;
end

endmodule