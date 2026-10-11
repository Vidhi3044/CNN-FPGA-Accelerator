`timescale 1ns/1ps

module tb_conv3x3_mac;

reg signed [7:0] input_0;
reg signed [7:0] input_1;
reg signed [7:0] input_2;
reg signed [7:0] input_3;
reg signed [7:0] input_4;
reg signed [7:0] input_5;
reg signed [7:0] input_6;
reg signed [7:0] input_7;
reg signed [7:0] input_8;

reg signed [7:0] weight_0;
reg signed [7:0] weight_1;
reg signed [7:0] weight_2;
reg signed [7:0] weight_3;
reg signed [7:0] weight_4;
reg signed [7:0] weight_5;
reg signed [7:0] weight_6;
reg signed [7:0] weight_7;
reg signed [7:0] weight_8;

reg signed [31:0] bias;
wire signed [31:0] output_value;

conv3x3_mac uut (
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
    .bias(bias),
    .output_value(output_value)
);

initial begin
    $dumpfile("simulations/convolution/conv3x3_mac.vcd");
    $dumpvars(0, tb_conv3x3_mac);

    input_0 = 8'sd1;
    input_1 = 8'sd2;
    input_2 = 8'sd3;
    input_3 = 8'sd4;
    input_4 = 8'sd5;
    input_5 = 8'sd6;
    input_6 = 8'sd7;
    input_7 = 8'sd8;
    input_8 = 8'sd9;

    weight_0 = 8'sd1;
    weight_1 = 8'sd0;
    weight_2 = 8'sd1;
    weight_3 = 8'sd0;
    weight_4 = 8'sd1;
    weight_5 = 8'sd0;
    weight_6 = 8'sd1;
    weight_7 = 8'sd0;
    weight_8 = 8'sd1;

    bias = 32'sd0;

    #10;

    $display("Test 1: convolution output %0d", output_value);

    bias = 32'sd5;

    #10;

    $display("Test 2: convolution output with bias %0d", output_value);

    input_0 = -8'sd1;
    input_1 = -8'sd2;
    input_2 = -8'sd3;
    input_3 = -8'sd4;
    input_4 = -8'sd5;
    input_5 = -8'sd6;
    input_6 = -8'sd7;
    input_7 = -8'sd8;
    input_8 = -8'sd9;

    bias = 32'sd0;

    #10;

    $display("Test 3: negative input convolution output %0d", output_value);

    $finish;
end

endmodule