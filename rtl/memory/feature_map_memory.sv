
`timescale 1ns/1ps

module feature_map_memory #(
    parameter integer DEPTH = 1024,
    parameter integer ADDR_WIDTH = 10
)(
    input logic clk,
    input logic write_enable,
    input logic [ADDR_WIDTH-1:0] write_addr,
    input logic signed [7:0] write_data,
    input logic [ADDR_WIDTH-1:0] read_addr,
    output logic signed [7:0] read_data
);

logic signed [7:0] memory [0:DEPTH-1];

always_ff @(posedge clk) begin
    if (write_enable)
        memory[write_addr] <= write_data;

    read_data <= memory[read_addr];
end

endmodule
