
`timescale 1ns/1ps

module tb_feature_map_memory;

logic clk = 1'b0;
logic write_enable = 1'b0;
logic [9:0] write_addr = 0;
logic signed [7:0] write_data = 0;
logic [9:0] read_addr = 0;
logic signed [7:0] read_data;

always #5 clk = ~clk;

feature_map_memory #(
    .DEPTH(1024),
    .ADDR_WIDTH(10)
) dut (
    .clk(clk),
    .write_enable(write_enable),
    .write_addr(write_addr),
    .write_data(write_data),
    .read_addr(read_addr),
    .read_data(read_data)
);

initial begin
    @(negedge clk);
    write_enable = 1'b1;
    write_addr = 10'd5;
    write_data = 8'sd42;

    @(negedge clk);
    write_addr = 10'd12;
    write_data = -8'sd17;

    @(negedge clk);
    write_enable = 1'b0;
    read_addr = 10'd5;

    @(posedge clk);
    #1;
    if (read_data !== 8'sd42)
        $fatal(1, "Memory read failed at address 5");

    @(negedge clk);
    read_addr = 10'd12;

    @(posedge clk);
    #1;
    if (read_data !== -8'sd17)
        $fatal(1, "Memory read failed at address 12");

    $display("Feature map memory test passed");
    $finish;
end

endmodule
