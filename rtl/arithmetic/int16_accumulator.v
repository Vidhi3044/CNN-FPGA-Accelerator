module int16_accumulator (
    input wire clk,
    input wire reset,
    input wire clear,
    input wire enable,
    input wire signed [15:0] product,
    output reg signed [31:0] accumulator
);

always @(posedge clk) begin
    if (reset) begin
        accumulator <= 32'sd0;
    end
    else if (clear) begin
        accumulator <= 32'sd0;
    end
    else if (enable) begin
        accumulator <= accumulator + {{16{product[15]}}, product};
    end
end

endmodule