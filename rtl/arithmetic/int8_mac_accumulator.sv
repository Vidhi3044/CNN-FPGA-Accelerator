
module int8_mac_accumulator (
    input logic clk,
    input logic reset,
    input logic start,
    input logic enable,
    input logic last,
    input logic signed [7:0] input_value,
    input logic signed [7:0] weight_value,
    input logic signed [31:0] bias,
    output logic signed [31:0] accumulator,
    output logic done
);

logic signed [15:0] product;
logic signed [31:0] extended_product;

always_comb begin
    product = input_value * weight_value;
    extended_product = {{16{product[15]}}, product};
end

always_ff @(posedge clk) begin
    if (reset) begin
        accumulator <= 32'sd0;
        done <= 1'b0;
    end else begin
        done <= 1'b0;

        if (start) begin
            accumulator <= bias + extended_product;
            if (last)
                done <= 1'b1;
        end else if (enable) begin
            accumulator <= accumulator + extended_product;
            if (last)
                done <= 1'b1;
        end
    end
end

endmodule
