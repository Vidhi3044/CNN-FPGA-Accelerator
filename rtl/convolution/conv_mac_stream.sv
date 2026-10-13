
module conv_mac_stream (
    input logic clk,
    input logic reset,
    input logic start,
    input logic valid,
    input logic last,
    input logic signed [7:0] input_value,
    input logic signed [7:0] weight_value,
    input logic signed [31:0] bias,
    output logic signed [31:0] output_value,
    output logic signed [31:0] accumulator,
    output logic busy,
    output logic done
);

logic signed [15:0] product;
logic signed [31:0] extended_product;
logic signed [31:0] next_accumulator;

assign product = input_value * weight_value;
assign extended_product = {{16{product[15]}}, product};
assign next_accumulator = accumulator + extended_product;

always_ff @(posedge clk) begin
    if (reset) begin
        output_value <= 32'sd0;
        accumulator <= 32'sd0;
        busy <= 1'b0;
        done <= 1'b0;
    end else begin
        done <= 1'b0;

        if (start && !busy) begin
            accumulator <= bias;
            busy <= 1'b1;
        end else if (busy && valid) begin
            accumulator <= next_accumulator;

            if (last) begin
                output_value <= next_accumulator;
                busy <= 1'b0;
                done <= 1'b1;
            end
        end
    end
end

endmodule
