
`timescale 1ns/1ps

module tb_fc1_trained;

localparam INPUT_COUNT = 1024;
localparam NEURON_COUNT = 128;

reg signed [7:0] inputs [0:INPUT_COUNT-1];
reg signed [7:0] weights [0:NEURON_COUNT-1][0:INPUT_COUNT-1];
reg signed [31:0] biases [0:NEURON_COUNT-1];
wire signed [31:0] outputs [0:NEURON_COUNT-1];
reg signed [31:0] expected [0:NEURON_COUNT-1];

integer i;
integer j;
integer errors;

fc1_layer_bank #(
    .INPUT_COUNT(INPUT_COUNT),
    .NEURON_COUNT(NEURON_COUNT)
) uut (
    .inputs(inputs),
    .weights(weights),
    .biases(biases),
    .outputs(outputs)
);

initial begin
    errors = 0;

    $readmemh("FPGA_Parameters/mem_files/fc1_integer_test/fc1_input.mem", inputs);
    $readmemh("FPGA_Parameters/mem_files/weights/classifier_1_weight.mem", weights);
    $readmemh("FPGA_Parameters/mem_files/biases/classifier_1_bias_int32.mem", biases);
    $readmemh("FPGA_Parameters/mem_files/fc1_integer_test/fc1_expected.mem", expected);

    #10;

    for (j = 0; j < NEURON_COUNT; j = j + 1) begin
        if (outputs[j] !== expected[j]) begin
            if (errors < 10)
                $display("MISMATCH neuron=%0d actual=%0d expected=%0d", j, outputs[j], expected[j]);
            errors = errors + 1;
        end
    end

    $display("FC1 outputs checked: %0d", NEURON_COUNT);
    $display("Total mismatches: %0d", errors);

    if (errors == 0)
        $display("FC1 TRAINED PARAMETER TEST PASSED");
    else
        $display("FC1 TRAINED PARAMETER TEST FAILED");

    $finish;
end

endmodule
