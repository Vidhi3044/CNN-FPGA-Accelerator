
`timescale 1ns/1ps

module tb_conv1_relu_pool;

localparam integer FILTER_COUNT = 16;

reg signed [31:0] relu_inputs [0:FILTER_COUNT-1];
wire signed [31:0] relu_outputs [0:FILTER_COUNT-1];

reg signed [31:0] pool_inputs [0:3][0:FILTER_COUNT-1];
wire signed [31:0] pool_outputs [0:FILTER_COUNT-1];

integer i;
integer errors;

generate
    genvar g;
    for (g = 0; g < FILTER_COUNT; g = g + 1) begin : relu_units
        relu relu_inst (
            .input_value(relu_inputs[g]),
            .output_value(relu_outputs[g])
        );
    end
endgenerate

maxpool2x2_bank #(
    .FILTER_COUNT(FILTER_COUNT)
) pool_bank (
    .input_values(pool_inputs),
    .output_values(pool_outputs)
);

initial begin
    errors = 0;

    for (i = 0; i < FILTER_COUNT; i = i + 1) begin
        relu_inputs[i] = (i % 2 == 0) ? -i - 1 : i + 1;

        pool_inputs[0][i] = i - 10;
        pool_inputs[1][i] = i + 2;
        pool_inputs[2][i] = i - 5;
        pool_inputs[3][i] = i + 1;
    end

    #10;

    for (i = 0; i < FILTER_COUNT; i = i + 1) begin
        if (relu_outputs[i] !== 32'sd0 && i % 2 == 0) begin
            $display("RELU FAIL channel=%0d output=%0d", i, relu_outputs[i]);
            errors = errors + 1;
        end

        if (relu_outputs[i] !== i + 1 && i % 2 != 0) begin
            $display("RELU FAIL channel=%0d output=%0d", i, relu_outputs[i]);
            errors = errors + 1;
        end

        if (pool_outputs[i] !== i + 2) begin
            $display("POOL FAIL channel=%0d output=%0d expected=%0d",
                i, pool_outputs[i], i + 2);
            errors = errors + 1;
        end
    end

    if (errors == 0)
        $display("CONV1 RELU AND POOL TEST PASSED");
    else
        $display("CONV1 RELU AND POOL TEST FAILED: %0d errors", errors);

    $finish;
end

endmodule
