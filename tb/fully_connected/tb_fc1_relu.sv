
`timescale 1ns/1ps

module tb_fc1_relu;

localparam VALUE_COUNT = 128;

reg signed [31:0] input_values [0:VALUE_COUNT-1];
wire signed [31:0] output_values [0:VALUE_COUNT-1];
reg signed [31:0] expected [0:VALUE_COUNT-1];

integer i;
integer errors;

relu_bank #(
    .FILTER_COUNT(VALUE_COUNT)
) uut (
    .input_values(input_values),
    .output_values(output_values)
);

initial begin
    errors = 0;

    $readmemh("FPGA_Parameters/mem_files/fc1_integer_test/fc1_expected.mem", input_values);
    $readmemh("FPGA_Parameters/mem_files/fc1_integer_test/fc1_relu_expected.mem", expected);

    #10;

    for (i = 0; i < VALUE_COUNT; i = i + 1) begin
        if (output_values[i] !== expected[i]) begin
            if (errors < 10)
                $display("MISMATCH index=%0d input=%0d actual=%0d expected=%0d",
                         i, input_values[i], output_values[i], expected[i]);
            errors = errors + 1;
        end
    end

    $display("ReLU outputs checked: %0d", VALUE_COUNT);
    $display("Total mismatches: %0d", errors);

    if (errors == 0)
        $display("FC1 RELU TEST PASSED");
    else
        $display("FC1 RELU TEST FAILED");

    $finish;
end

endmodule
