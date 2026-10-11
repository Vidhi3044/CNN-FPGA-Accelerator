`timescale 1ns/1ps

module tb_int16_accumulator;

reg clk;
reg reset;
reg clear;
reg enable;
reg signed [15:0] product;
wire signed [31:0] accumulator;

int16_accumulator uut (
    .clk(clk),
    .reset(reset),
    .clear(clear),
    .enable(enable),
    .product(product),
    .accumulator(accumulator)
);

always #5 clk = ~clk;

initial begin
    $dumpfile("simulations/arithmetic/int16_accumulator.vcd");
    $dumpvars(0, tb_int16_accumulator);

    clk = 1'b0;
    reset = 1'b1;
    clear = 1'b0;
    enable = 1'b0;
    product = 16'sd0;

    #12;

    reset = 1'b0;
    enable = 1'b1;

    product = 16'sd6;
    #10;
    $display("Test 1: product %0d, accumulator %0d",
             product, accumulator);

    product = 16'sd20;
    #10;
    $display("Test 2: product %0d, accumulator %0d",
             product, accumulator);

    product = 16'sd6;
    #10;
    $display("Test 3: product %0d, accumulator %0d",
             product, accumulator);

    clear = 1'b1;
    #10;

    clear = 1'b0;
    product = 16'sd3;
    #10;
    $display("Test 4: product %0d, accumulator %0d",
             product, accumulator);

    product = -16'sd4;
    #10;
    $display("Test 5: product %0d, accumulator %0d",
             product, accumulator);

    enable = 1'b0;
    product = 16'sd100;
    #10;
    $display("Test 6: product %0d, accumulator %0d",
             product, accumulator);

    $finish;
end

endmodule