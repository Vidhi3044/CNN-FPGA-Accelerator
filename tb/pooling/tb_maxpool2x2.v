`timescale 1ns/1ps

module tb_maxpool2x2;

reg signed [31:0] input_a;
reg signed [31:0] input_b;
reg signed [31:0] input_c;
reg signed [31:0] input_d;

wire signed [31:0] output_value;

maxpool2x2 uut (
    .input_a(input_a),
    .input_b(input_b),
    .input_c(input_c),
    .input_d(input_d),
    .output_value(output_value)
);

initial begin
    $dumpfile("simulations/pooling/maxpool2x2.vcd");
    $dumpvars(0, tb_maxpool2x2);

    input_a = 32'sd4;
    input_b = 32'sd9;
    input_c = 32'sd2;
    input_d = 32'sd6;
    #10;

    $display("Test 1: inputs %0d %0d %0d %0d, output %0d",
             input_a, input_b, input_c, input_d, output_value);

    input_a = -32'sd4;
    input_b = -32'sd2;
    input_c = -32'sd8;
    input_d = -32'sd6;
    #10;

    $display("Test 2: inputs %0d %0d %0d %0d, output %0d",
             input_a, input_b, input_c, input_d, output_value);

    input_a = 32'sd20;
    input_b = 32'sd5;
    input_c = 32'sd12;
    input_d = 32'sd18;
    #10;

    $display("Test 3: inputs %0d %0d %0d %0d, output %0d",
             input_a, input_b, input_c, input_d, output_value);

    input_a = -32'sd10;
    input_b = -32'sd20;
    input_c = -32'sd5;
    input_d = -32'sd30;
    #10;

    $display("Test 4: inputs %0d %0d %0d %0d, output %0d",
             input_a, input_b, input_c, input_d, output_value);

    input_a = 32'sd0;
    input_b = 32'sd0;
    input_c = 32'sd0;
    input_d = 32'sd0;
    #10;

    $display("Test 5: inputs %0d %0d %0d %0d, output %0d",
             input_a, input_b, input_c, input_d, output_value);

    $finish;
end

endmodule