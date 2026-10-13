
`timescale 1ns/1ps

module tb_int8_mac_accumulator;

logic clk = 1'b0;
logic reset = 1'b0;
logic start = 1'b0;
logic enable = 1'b0;
logic last = 1'b0;
logic signed [7:0] input_value = 0;
logic signed [7:0] weight_value = 0;
logic signed [31:0] bias = 0;
logic signed [31:0] accumulator;
logic done;

always #5 clk = ~clk;

int8_mac_accumulator dut (
    .clk(clk),
    .reset(reset),
    .start(start),
    .enable(enable),
    .last(last),
    .input_value(input_value),
    .weight_value(weight_value),
    .bias(bias),
    .accumulator(accumulator),
    .done(done)
);

initial begin
    reset = 1'b1;
    @(posedge clk);
    #1;
    reset = 1'b0;

    @(negedge clk);
    start = 1'b1;
    input_value = 8'sd2;
    weight_value = 8'sd3;
    bias = 32'sd10;

    @(posedge clk);
    #1;
    if (accumulator !== 32'sd16)
        $fatal(1, "First MAC result incorrect");

    @(negedge clk);
    start = 1'b0;
    enable = 1'b1;
    input_value = 8'sd4;
    weight_value = -8'sd1;

    @(posedge clk);
    #1;
    if (accumulator !== 32'sd12)
        $fatal(1, "Second MAC result incorrect");

    @(negedge clk);
    input_value = -8'sd2;
    weight_value = 8'sd5;
    last = 1'b1;

    @(posedge clk);
    #1;
    if (accumulator !== 32'sd2)
        $fatal(1, "Final MAC result incorrect");

    if (done !== 1'b1)
        $fatal(1, "Done signal incorrect");

    $display("INT8 MAC accumulator test passed");
    $finish;
end

endmodule
