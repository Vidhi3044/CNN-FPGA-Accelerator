module maxpool2x2_bank #(
    parameter FILTER_COUNT = 16
)(
    input signed [31:0] input_values [0:3][0:FILTER_COUNT-1],
    output logic signed [31:0] output_values [0:FILTER_COUNT-1]
);

genvar filter_index;

generate
    for (filter_index = 0; filter_index < FILTER_COUNT; filter_index = filter_index + 1) begin : pool_instances

        maxpool2x2 pool_unit (
            .input_a(input_values[0][filter_index]),
            .input_b(input_values[1][filter_index]),
            .input_c(input_values[2][filter_index]),
            .input_d(input_values[3][filter_index]),
            .output_value(output_values[filter_index])
        );

    end
endgenerate

endmodule