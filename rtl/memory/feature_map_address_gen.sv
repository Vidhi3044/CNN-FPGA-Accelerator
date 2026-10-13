
`timescale 1ns/1ps

module feature_map_address_gen #(
    parameter integer MAP_WIDTH = 32,
    parameter integer MAP_HEIGHT = 32,
    parameter integer ADDR_WIDTH = 16
)(
    input logic clk,
    input logic reset,
    input logic start,
    output logic [ADDR_WIDTH-1:0] addr0,
    output logic [ADDR_WIDTH-1:0] addr1,
    output logic [ADDR_WIDTH-1:0] addr2,
    output logic [ADDR_WIDTH-1:0] addr3,
    output logic [ADDR_WIDTH-1:0] addr4,
    output logic [ADDR_WIDTH-1:0] addr5,
    output logic [ADDR_WIDTH-1:0] addr6,
    output logic [ADDR_WIDTH-1:0] addr7,
    output logic [ADDR_WIDTH-1:0] addr8,
    output logic window_valid,
    output logic busy,
    output logic done
);

integer x_pos;
integer y_pos;
integer base_addr;

always_comb begin
    base_addr = y_pos * MAP_WIDTH + x_pos;

    addr0 = base_addr;
    addr1 = base_addr + 1;
    addr2 = base_addr + 2;
    addr3 = base_addr + MAP_WIDTH;
    addr4 = base_addr + MAP_WIDTH + 1;
    addr5 = base_addr + MAP_WIDTH + 2;
    addr6 = base_addr + 2 * MAP_WIDTH;
    addr7 = base_addr + 2 * MAP_WIDTH + 1;
    addr8 = base_addr + 2 * MAP_WIDTH + 2;
end

assign window_valid = busy;

always_ff @(posedge clk) begin
    if (reset) begin
        x_pos <= 0;
        y_pos <= 0;
        busy <= 1'b0;
        done <= 1'b0;
    end else begin
        done <= 1'b0;

        if (start && !busy) begin
            x_pos <= 0;
            y_pos <= 0;
            busy <= 1'b1;
        end else if (busy) begin
            if (x_pos == MAP_WIDTH - 3) begin
                x_pos <= 0;

                if (y_pos == MAP_HEIGHT - 3) begin
                    y_pos <= 0;
                    busy <= 1'b0;
                    done <= 1'b1;
                end else begin
                    y_pos <= y_pos + 1;
                end
            end else begin
                x_pos <= x_pos + 1;
            end
        end
    end
end

initial begin
    if (MAP_WIDTH < 3 || MAP_HEIGHT < 3)
        $error("Feature map dimensions must be at least 3 by 3");
end

endmodule
