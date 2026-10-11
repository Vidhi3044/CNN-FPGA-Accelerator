`timescale 1ns/1ps

module fc_neuron #(
    parameter INPUT_COUNT = 4
)(
    input signed [7:0] inputs [0:INPUT_COUNT-1],
    input signed [7:0] weights [0:INPUT_COUNT-1],
    input signed [31:0] bias,
    output signed [31:0] output_value
);

integer i;
reg signed [31:0] sum;

always @(*) begin
    sum = bias;

    for (i = 0; i < INPUT_COUNT; i = i + 1) begin
        sum = sum + inputs[i] * weights[i];
    end
end

assign output_value = sum;

endmodule