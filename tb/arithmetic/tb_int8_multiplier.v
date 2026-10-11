`timescale 1ns/1ps

module tb_int8_multiplier;

reg signed [7:0] input_value;
reg signed [7:0] weight_value;
wire signed [15:0] product;

int8_multiplier uut (
    .input_value(input_value),
    .weight_value(weight_value),
    .product(product)
);

initial begin
    $dumpfile("simulations/arithmetic/int8_multiplier.vcd");
    $dumpvars(0, tb_int8_multiplier);
    input_value = 8'sd5;
    weight_value = 8'sd3;
    #10;

    $display("Test 1: input %0d, weight %0d, product %0d",
             input_value, weight_value, product);

    input_value = 8'sd5;
    weight_value = -8'sd3;
    #10;

    $display("Test 2: input %0d, weight %0d, product %0d",
             input_value, weight_value, product);

    input_value = -8'sd5;
    weight_value = 8'sd3;
    #10;

    $display("Test 3: input %0d, weight %0d, product %0d",
             input_value, weight_value, product);

    input_value = -8'sd5;
    weight_value = -8'sd3;
    #10;

    $display("Test 4: input %0d, weight %0d, product %0d",
             input_value, weight_value, product);

    input_value = 8'sd0;
    weight_value = 8'sd127;
    #10;

    $display("Test 5: input %0d, weight %0d, product %0d",
             input_value, weight_value, product);

    input_value = -8'sd128;
    weight_value = 8'sd127;
    #10;

    $display("Test 6: input %0d, weight %0d, product %0d",
             input_value, weight_value, product);

    $finish;
end

endmodule