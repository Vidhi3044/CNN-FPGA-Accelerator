module relu_bank #(
    parameter FILTER_COUNT = 16
)(
    input signed [31:0] input_values [0:FILTER_COUNT-1],
    output logic signed [31:0] output_values [0:FILTER_COUNT-1]
);

integer i;

always_comb begin
    for (i = 0; i < FILTER_COUNT; i = i + 1) begin
        if (input_values[i] < 0)
            output_values[i] = 32'sd0;
        else
            output_values[i] = input_values[i];
    end
end

endmodule