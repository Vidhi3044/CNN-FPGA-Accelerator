`timescale 1ns/1ps

module tb_relu;

reg signed [31:0] input_value;
wire signed [31:0] output_value;

relu uut (
    .input_value(input_value),
    .output_value(output_value)
);

initial begin
    $dumpfile("simulations/activation/relu.vcd");
    $dumpvars(0, tb_relu);

    input_value = 32'sd15;
    #10;
    $display("Test 1: input %0d, output %0d",
             input_value, output_value);

    input_value = -32'sd8;
    #10;
    $display("Test 2: input %0d, output %0d",
             input_value, output_value);

    input_value = 32'sd0;
    #10;
    $display("Test 3: input %0d, output %0d",
             input_value, output_value);

    input_value = -32'sd100;
    #10;
    $display("Test 4: input %0d, output %0d",
             input_value, output_value);

    input_value = 32'sd127;
    #10;
    $display("Test 5: input %0d, output %0d",
             input_value, output_value);

    input_value = -32'sd2147483648;
    #10;
    $display("Test 6: input %0d, output %0d",
             input_value, output_value);

    $finish;
end

endmodule