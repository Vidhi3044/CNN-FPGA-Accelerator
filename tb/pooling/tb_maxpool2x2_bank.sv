`timescale 1ns/1ps

module tb_maxpool2x2_bank;

parameter FILTER_COUNT = 16;

reg signed [31:0] input_values [0:3][0:FILTER_COUNT-1];
wire signed [31:0] output_values [0:FILTER_COUNT-1];

integer i;

maxpool2x2_bank #(
    .FILTER_COUNT(FILTER_COUNT)
) uut (
    .input_values(input_values),
    .output_values(output_values)
);

initial begin
    $dumpfile("simulations/pooling/maxpool2x2_bank.vcd");
    $dumpvars(0, tb_maxpool2x2_bank);

    for (i = 0; i < FILTER_COUNT; i = i + 1) begin
        input_values[0][i] = i + 1;
        input_values[1][i] = i + 2;
        input_values[2][i] = i + 3;
        input_values[3][i] = i + 4;
    end

    #10;

    for (i = 0; i < FILTER_COUNT; i = i + 1) begin
        $display("Filter %0d output %0d", i, output_values[i]);
    end

    input_values[0][0] = -32'sd5;
    input_values[1][0] = -32'sd2;
    input_values[2][0] = -32'sd8;
    input_values[3][0] = -32'sd3;

    #10;

    $display("Negative test output %0d", output_values[0]);

    $finish;
end

endmodule