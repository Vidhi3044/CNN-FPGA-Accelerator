
`timescale 1ns/1ps

module tb_conv1_real_data;

localparam integer FILTER_COUNT = 16;

reg signed [7:0] inputs [0:26];
reg signed [7:0] flat_weights [0:FILTER_COUNT*27-1];
reg signed [7:0] weights [0:FILTER_COUNT-1][0:26];
reg signed [31:0] biases [0:FILTER_COUNT-1];
reg signed [31:0] expected [0:FILTER_COUNT-1];

wire signed [31:0] outputs [0:FILTER_COUNT-1];

integer i;
integer j;
integer errors;

conv1_filter_bank #(
    .FILTER_COUNT(FILTER_COUNT)
) dut (
    .inputs(inputs),
    .weights(weights),
    .biases(biases),
    .outputs(outputs)
);

initial begin
    errors = 0;

    $readmemh("FPGA_Parameters/mem_files/conv1_test/conv1_input.mem", inputs);
    $readmemh("FPGA_Parameters/mem_files/conv1_test/conv1_weights.mem", flat_weights);
    $readmemh("FPGA_Parameters/mem_files/conv1_test/conv1_biases.mem", biases);
    $readmemh("FPGA_Parameters/mem_files/conv1_test/conv1_expected.mem", expected);

    for (i = 0; i < FILTER_COUNT; i = i + 1) begin
        for (j = 0; j < 27; j = j + 1) begin
            weights[i][j] = flat_weights[i*27+j];
        end
    end

    #10;

    for (i = 0; i < FILTER_COUNT; i = i + 1) begin
        if (outputs[i] !== expected[i]) begin
            $display("MISMATCH filter=%0d RTL=%0d expected=%0d",
                i, outputs[i], expected[i]);
            errors = errors + 1;
        end else begin
            $display("PASS filter=%0d output=%0d", i, outputs[i]);
        end
    end

    if (errors == 0)
        $display("CONV1 REAL-DATA TEST PASSED");
    else
        $display("CONV1 REAL-DATA TEST FAILED: %0d mismatches", errors);

    $finish;
end

endmodule
