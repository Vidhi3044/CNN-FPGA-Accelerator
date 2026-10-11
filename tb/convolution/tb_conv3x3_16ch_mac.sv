`timescale 1ns/1ps

module tb_conv3x3_16ch_mac;

logic signed [7:0] inputs [0:143];

logic signed [7:0] weights [0:143];

logic signed [31:0] bias;

logic signed [31:0] output_value;

integer i;

conv3x3_16ch_mac uut (

    .inputs(inputs),

    .weights(weights),

    .bias(bias),

    .output_value(output_value)

);

initial begin

    $dumpfile("simulations/convolution/conv3x3_16ch_mac.vcd");

    $dumpvars(0, tb_conv3x3_16ch_mac);

    bias = 32'sd0;

    for (i = 0; i < 144; i = i + 1) begin

        inputs[i] = 8'sd1;

        weights[i] = 8'sd1;

    end

    #10;

    $display("Test 1 output %0d", output_value);

    bias = 32'sd5;

    #10;

    $display("Test 2 output with bias %0d", output_value);

    for (i = 0; i < 144; i = i + 1) begin

        inputs[i] = 8'sd2;

        weights[i] = 8'sd3;

    end

    bias = 32'sd0;

    #10;

    $display("Test 3 output %0d", output_value);

    for (i = 0; i < 144; i = i + 1) begin

        inputs[i] = -8'sd2;

        weights[i] = 8'sd3;

    end

    bias = 32'sd0;

    #10;

    $display("Test 4 negative input output %0d", output_value);

    $finish;

end

endmodule