
`timescale 1ns/1ps

module tb_conv_mac_stream;

logic clk = 1'b0;
logic reset = 1'b0;
logic start = 1'b0;
logic valid = 1'b0;
logic last = 1'b0;
logic signed [7:0] input_value = 0;
logic signed [7:0] weight_value = 0;
logic signed [31:0] bias = 0;
logic signed [31:0] output_value;
logic signed [31:0] accumulator;
logic busy;
logic done;

always #5 clk = ~clk;

conv_mac_stream dut (
    .clk(clk),
    .reset(reset),
    .start(start),
    .valid(valid),
    .last(last),
    .input_value(input_value),
    .weight_value(weight_value),
    .bias(bias),
    .output_value(output_value),
    .accumulator(accumulator),
    .busy(busy),
    .done(done)
);

initial begin
    reset = 1'b1;
    @(posedge clk);
    #1;
    reset = 1'b0;

    @(negedge clk);
    start = 1'b1;
    bias = 32'sd10;

    @(posedge clk);
    #1;

    @(negedge clk);
    start = 1'b0;
    valid = 1'b1;
    input_value = 8'sd2;
    weight_value = 8'sd3;

    @(posedge clk);
    #1;
    if (accumulator !== 32'sd16)
        $fatal(1, "First product failed");

    @(negedge clk);
    input_value = 8'sd4;
    weight_value = -8'sd1;

    @(posedge clk);
    #1;
    if (accumulator !== 32'sd12)
        $fatal(1, "Second product failed");

    @(negedge clk);
    input_value = -8'sd2;
    weight_value = 8'sd5;
    last = 1'b1;

    @(posedge clk);
    #1;
    if (output_value !== 32'sd2)
        $fatal(1, "Final result failed");

    if (done !== 1'b1 || busy !== 1'b0)
        $fatal(1, "Completion signals failed");

    $display("Convolution MAC stream test passed");
    $finish;
end

endmodule
