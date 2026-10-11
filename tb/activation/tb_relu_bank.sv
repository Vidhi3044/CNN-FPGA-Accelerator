`timescale 1ns/1ps

module tb_relu_bank;

parameter FILTER_COUNT = 16;

logic signed [31:0] input_values [0:FILTER_COUNT-1];
logic signed [31:0] output_values [0:FILTER_COUNT-1];

integer i;

relu_bank #(
    .FILTER_COUNT(FILTER_COUNT)
) uut (
    .input_values(input_values),
    .output_values(output_values)
);

initial begin
    $dumpfile("simulations/activation/relu_bank.vcd");
    $dumpvars(0, tb_relu_bank);

    input_values[0] = 32'sd10;
    input_values[1] = -32'sd5;
    input_values[2] = 32'sd0;
    input_values[3] = 32'sd25;
    input_values[4] = -32'sd12;
    input_values[5] = 32'sd8;
    input_values[6] = -32'sd3;
    input_values[7] = 32'sd100;
    input_values[8] = -32'sd20;
    input_values[9] = 32'sd7;
    input_values[10] = -32'sd1;
    input_values[11] = 32'sd50;
    input_values[12] = -32'sd30;
    input_values[13] = 32'sd4;
    input_values[14] = -32'sd9;
    input_values[15] = 32'sd15;

    #10;

    $display("First ReLU test");

    for (i = 0; i < FILTER_COUNT; i = i + 1) begin
        $display("Filter %0d: input %0d, output %0d",
                 i, input_values[i], output_values[i]);
    end

    input_values[0] = -32'sd100;
    input_values[1] = -32'sd50;
    input_values[2] = 32'sd0;
    input_values[3] = 32'sd20;
    input_values[4] = -32'sd15;
    input_values[5] = 32'sd30;
    input_values[6] = -32'sd8;
    input_values[7] = 32'sd40;
    input_values[8] = -32'sd25;
    input_values[9] = 32'sd5;
    input_values[10] = -32'sd2;
    input_values[11] = 32'sd60;
    input_values[12] = -32'sd35;
    input_values[13] = 32'sd12;
    input_values[14] = -32'sd6;
    input_values[15] = 32'sd75;

    #10;

    $display("Second ReLU test");

    for (i = 0; i < FILTER_COUNT; i = i + 1) begin
        $display("Filter %0d: input %0d, output %0d",
                 i, input_values[i], output_values[i]);
    end

    $finish;
end

endmodule