 
`timescale 1ns/1ps

module tb_conv_controller;

logic clk = 1'b0;
logic reset = 1'b0;
logic start = 1'b0;

logic write_enable = 1'b0;
logic [7:0] write_addr = 0;
logic signed [7:0] write_data = 0;

logic [7:0] read_addr;
logic signed [7:0] memory_data;

logic [3:0] weight_addr;
logic signed [7:0] weight_data = 8'sd1;
logic signed [31:0] bias = 32'sd0;

logic [7:0] output_addr;
logic signed [31:0] output_data;
logic result_valid;
logic busy;
logic done;

integer i;
integer count;
integer expected [0:5];

always #5 clk = ~clk;

feature_map_memory #(
    .DEPTH(20),
    .ADDR_WIDTH(8)
) input_memory (
    .clk(clk),
    .write_enable(write_enable),
    .write_addr(write_addr),
    .write_data(write_data),
    .read_addr(read_addr),
    .read_data(memory_data)
);

conv_controller #(
    .MAP_WIDTH(5),
    .MAP_HEIGHT(4),
    .INPUT_CHANNELS(1),
    .ADDR_WIDTH(8),
    .WEIGHT_ADDR_WIDTH(4)
) dut (
    .clk(clk),
    .reset(reset),
    .start(start),
    .memory_data(memory_data),
    .weight_data(weight_data),
    .bias(bias),
    .read_addr(read_addr),
    .weight_addr(weight_addr),
    .output_addr(output_addr),
    .output_data(output_data),
    .result_valid(result_valid),
    .busy(busy),
    .done(done)
);

initial begin
    expected[0] = 54;
    expected[1] = 63;
    expected[2] = 72;
    expected[3] = 99;
    expected[4] = 108;
    expected[5] = 117;

    count = 0;

    reset = 1'b1;
    repeat (2) @(negedge clk);
    reset = 1'b0;

    for (i = 0; i < 20; i = i + 1) begin
        write_enable = 1'b1;
        write_addr = i;
        write_data = i;
        @(negedge clk);
    end

    write_enable = 1'b0;
    start = 1'b1;

    @(negedge clk);
    start = 1'b0;

    while (count < 6) begin
        @(negedge clk);

        if (result_valid) begin
            if (output_addr !== count)
                $fatal(1, "Incorrect output address");

            if (output_data !== expected[count])
                $fatal(1, "Incorrect convolution result");

            count = count + 1;
        end
    end

    wait (done === 1'b1);
    #1;

    if (busy !== 1'b0)
        $fatal(1, "Busy signal should be low after completion");

    $display("Convolution controller test passed");
    $finish;
end

initial begin
    #100000;
    $fatal(1, "Testbench timeout");
end

endmodule