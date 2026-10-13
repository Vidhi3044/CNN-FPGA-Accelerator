
`timescale 1ns/1ps

module tb_fc2_trained;

localparam INPUT_COUNT = 128;
localparam NEURON_COUNT = 3;

reg signed [31:0] inputs [0:INPUT_COUNT-1];
reg signed [7:0] weights [0:NEURON_COUNT-1][0:INPUT_COUNT-1];
reg signed [31:0] biases [0:NEURON_COUNT-1];
wire signed [31:0] outputs [0:NEURON_COUNT-1];
reg signed [31:0] expected [0:NEURON_COUNT-1];

integer i;
integer errors;

fc2_layer_bank #(
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

    $readmemh("FPGA_Parameters/mem_files/fc2_integer_test/fc2_input.mem", inputs);
    $readmemh("FPGA_Parameters/mem_files/weights/classifier_3_weight.mem", weights);
    $readmemh("FPGA_Parameters/mem_files/biases/classifier_3_bias.mem", biases);
    $readmemh("FPGA_Parameters/mem_files/fc2_integer_test/fc2_expected.mem", expected);

    #10;

    for (i = 0; i < NEURON_COUNT; i = i + 1) begin
        $display("Class %0d: actual=%0d expected=%0d",
                 i, outputs[i], expected[i]);

        if (outputs[i] !== expected[i])
            errors = errors + 1;
    end

    $display("FC2 outputs checked: %0d", NEURON_COUNT);
    $display("Total mismatches: %0d", errors);

    if (errors == 0)
        $display("FC2 TRAINED PARAMETER TEST PASSED");
    else
        $display("FC2 TRAINED PARAMETER TEST FAILED");

    $finish;
end

endmodule
