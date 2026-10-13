
`timescale 1ns/1ps

module conv_controller #(
    parameter integer MAP_WIDTH = 32,
    parameter integer MAP_HEIGHT = 32,
    parameter integer INPUT_CHANNELS = 3,
    parameter integer ADDR_WIDTH = 16,
    parameter integer WEIGHT_ADDR_WIDTH =
        (INPUT_CHANNELS * 9 <= 1) ? 1 : $clog2(INPUT_CHANNELS * 9)
)(
    input logic clk,
    input logic reset,
    input logic start,
    input logic signed [7:0] memory_data,
    input logic signed [7:0] weight_data,
    input logic signed [31:0] bias,
    output logic [ADDR_WIDTH-1:0] read_addr,
    output logic [WEIGHT_ADDR_WIDTH-1:0] weight_addr,
    output logic [ADDR_WIDTH-1:0] output_addr,
    output logic signed [31:0] output_data,
    output logic result_valid,
    output logic busy,
    output logic done
);

localparam integer TOTAL_TERMS = INPUT_CHANNELS * 9;

localparam IDLE = 4'd0;
localparam MAC_INIT = 4'd1;
localparam ISSUE = 4'd2;
localparam READ_WAIT = 4'd3;
localparam CAPTURE = 4'd4;
localparam WAIT_RESULT = 4'd5;
localparam STORE = 4'd6;
localparam ADVANCE = 4'd7;
localparam FINISH = 4'd8;

logic [3:0] state;

integer x_pos;
integer y_pos;
integer term_index;
integer channel_index;
integer kernel_index;
integer kernel_x;
integer kernel_y;
integer calculated_address;
integer calculated_output_address;

logic mac_start;
logic mac_valid;
logic mac_last;
logic signed [31:0] mac_result;
logic signed [31:0] mac_accumulator;
logic mac_busy;
logic mac_done;

always_comb begin
    channel_index = term_index / 9;
    kernel_index = term_index % 9;
    kernel_x = kernel_index % 3;
    kernel_y = kernel_index / 3;

    calculated_address =
        channel_index * MAP_WIDTH * MAP_HEIGHT +
        (y_pos + kernel_y) * MAP_WIDTH +
        x_pos + kernel_x;

    calculated_output_address =
        y_pos * (MAP_WIDTH - 2) + x_pos;

    read_addr = '0;
    weight_addr = term_index;
    output_addr = calculated_output_address;
    output_data = mac_result;

    mac_start = 1'b0;
    mac_valid = 1'b0;
    mac_last = 1'b0;
    result_valid = 1'b0;

    if (state == ISSUE ||
        state == READ_WAIT ||
        state == CAPTURE)
        read_addr = calculated_address;

    if (state == MAC_INIT)
        mac_start = 1'b1;

    if (state == CAPTURE) begin
        mac_valid = 1'b1;
        mac_last = (term_index == TOTAL_TERMS - 1);
    end

    if (state == STORE)
        result_valid = 1'b1;
end

assign busy = (state != IDLE && state != FINISH);
assign done = (state == FINISH);

conv_mac_stream mac_unit (
    .clk(clk),
    .reset(reset),
    .start(mac_start),
    .valid(mac_valid),
    .last(mac_last),
    .input_value(memory_data),
    .weight_value(weight_data),
    .bias(bias),
    .output_value(mac_result),
    .accumulator(mac_accumulator),
    .busy(mac_busy),
    .done(mac_done)
);

always_ff @(posedge clk) begin
    if (reset) begin
        state <= IDLE;
        x_pos <= 0;
        y_pos <= 0;
        term_index <= 0;
    end else begin
        case (state)
            IDLE: begin
                if (start) begin
                    x_pos <= 0;
                    y_pos <= 0;
                    term_index <= 0;
                    state <= MAC_INIT;
                end
            end

            MAC_INIT: begin
                state <= ISSUE;
            end

            ISSUE: begin
                state <= READ_WAIT;
            end

            READ_WAIT: begin
                state <= CAPTURE;
            end

            CAPTURE: begin
                if (term_index == TOTAL_TERMS - 1) begin
                    state <= WAIT_RESULT;
                end else begin
                    term_index <= term_index + 1;
                    state <= ISSUE;
                end
            end

            WAIT_RESULT: begin
                if (mac_done)
                    state <= STORE;
            end

            STORE: begin
                state <= ADVANCE;
            end

            ADVANCE: begin
                term_index <= 0;

                if (x_pos == MAP_WIDTH - 3) begin
                    x_pos <= 0;

                    if (y_pos == MAP_HEIGHT - 3) begin
                        state <= FINISH;
                    end else begin
                        y_pos <= y_pos + 1;
                        state <= MAC_INIT;
                    end
                end else begin
                    x_pos <= x_pos + 1;
                    state <= MAC_INIT;
                end
            end

            FINISH: begin
                state <= IDLE;
            end

            default: begin
                state <= IDLE;
                x_pos <= 0;
                y_pos <= 0;
                term_index <= 0;
            end
        endcase
    end
end

initial begin
    if (MAP_WIDTH < 3 || MAP_HEIGHT < 3 || INPUT_CHANNELS < 1)
        $error("Invalid convolution dimensions");
end

endmodule
