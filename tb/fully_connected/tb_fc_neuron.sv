`timescale 1ns/1ps

module tb_fc_neuron;

localparam INPUT_COUNT = 4;

reg signed [7:0] inputs [0:INPUT_COUNT-1];
reg signed [7:0] weights [0:INPUT_COUNT-1];
reg signed [31:0] bias;
wire signed [31:0] output_value;

fc_neuron #(
    .INPUT_COUNT(INPUT_COUNT)
) uut (
    .inputs(inputs),
    .weights(weights),
    .bias(bias),
    .output_value(output_value)
);

initial begin
    $dumpfile("simulations/fully_connected/fc_neuron.vcd");
    $dumpvars(0, tb_fc_neuron);

    inputs[0] = 8'sd2;
    inputs[1] = 8'sd3;
    inputs[2] = 8'sd4;
    inputs[3] = 8'sd5;

    weights[0] = 8'sd1;
    weights[1] = 8'sd2;
    weights[2] = 8'sd3;
    weights[3] = 8'sd4;

    bias = 32'sd10;

    #10;

    $display("FC neuron output %0d", output_value);

    inputs[0] = -8'sd2;
    inputs[1] = -8'sd3;
    inputs[2] = -8'sd4;
    inputs[3] = -8'sd5;

    bias = 32'sd0;

    #10;

    $display("FC neuron negative output %0d", output_value);

    $finish;
end

endmodule