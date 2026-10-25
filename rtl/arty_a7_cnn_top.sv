`timescale 1ns/1ps

/**
 * Hardware Top-Level Board Wrapper for Digilent Arty A7-100T FPGA.
 * Board: Digilent Arty A7-100T (Xilinx Artix-7 XC7A100TCSG324-1)
 *
 * Board I/O Mapping:
 *   - clk:        100 MHz on-board oscillator (Pin E3)
 *   - btn[0]:     Active-high synchronous system reset (Pin D9)
 *   - btn[1]:     Active-high inference trigger start (Pin C9)
 *   - sw[1:0]:    Test image selector:
 *                   00: Real CARLA Traffic Light Image (Green, Class 0)
 *                   01: Red Traffic Light Image (Red, Class 1)
 *                   10: Yellow Traffic Light Image (Yellow, Class 2)
 *                   11: Bright Green Traffic Light Image (Green, Class 0)
 *   - led[0]:     Inference Busy indicator (Pin H5)
 *   - led[1]:     Inference Done indicator (Pin J5)
 *   - led[3:2]:   Predicted class binary encoding (Pins T9, T10)
 *   - led4_r:     RGB LED 4 Red channel (Pin G6)
 *   - led4_g:     RGB LED 4 Green channel (Pin F6)
 *   - led4_b:     RGB LED 4 Blue channel (Pin E1)
 */

module arty_a7_cnn_top #(
    parameter MEM_DIR = "FPGA_Parameters/mem_files"
)(
    input  logic       clk,
    input  logic [1:0] btn,
    input  logic [1:0] sw,

    output logic [3:0] led,
    output logic       led4_r,
    output logic       led4_g,
    output logic       led4_b
);

    // Synchronize inputs
    logic rst_sync, start_btn_sync;
    logic [1:0] btn_r1, btn_r2;
    logic [1:0] sw_sync;

    always_ff @(posedge clk) begin
        btn_r1 <= btn;
        btn_r2 <= btn_r1;
        sw_sync <= sw;
    end

    assign rst_sync = btn_r2[0];

    // Edge detect on start button
    logic start_btn_prev;
    logic start_pulse;
    always_ff @(posedge clk) begin
        if (rst_sync) begin
            start_btn_prev <= 1'b0;
            start_pulse    <= 1'b0;
        end else begin
            start_btn_prev <= btn_r2[1];
            start_pulse    <= btn_r2[1] && !start_btn_prev;
        end
    end

    // =========================================================================
    // Image Loader FSM for Hardware Demonstration
    // =========================================================================
    typedef enum logic [1:0] {
        LOAD_IDLE  = 2'd0,
        LOAD_WRITE = 2'd1,
        LOAD_START = 2'd2,
        LOAD_WAIT  = 2'd3
    } load_state_t;

    load_state_t load_state;

    logic        cnn_busy;
    logic        cnn_done;
    logic [1:0]  pred_class;
    logic signed [31:0] score_0, score_1, score_2;

    logic [11:0] load_addr;
    logic signed [7:0] load_data;
    logic        load_wr_en;
    logic        cnn_start;

    // Preloaded demonstration images in Block ROM / Memory
    logic signed [7:0] demo_img_0 [0:3071]; // Real CARLA image (Green)
    logic signed [7:0] demo_img_1 [0:3071]; // Red image
    logic signed [7:0] demo_img_2 [0:3071]; // Yellow image
    logic signed [7:0] demo_img_3 [0:3071]; // Bright Green image

    initial begin
        $readmemh("FPGA_Parameters/test_cases/case0_real_green/input_image.mem", demo_img_0);
        $readmemh("FPGA_Parameters/test_cases/case1_red/input_image.mem",        demo_img_1);
        $readmemh("FPGA_Parameters/test_cases/case2_yellow/input_image.mem",     demo_img_2);
        $readmemh("FPGA_Parameters/test_cases/case3_green/input_image.mem",      demo_img_3);
    end

    // Multiplex selected demo image byte
    always_comb begin
        case (sw_sync)
            2'b00: load_data = demo_img_0[load_addr];
            2'b01: load_data = demo_img_1[load_addr];
            2'b10: load_data = demo_img_2[load_addr];
            2'b11: load_data = demo_img_3[load_addr];
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst_sync) begin
            load_state <= LOAD_IDLE;
            load_addr  <= 12'd0;
            load_wr_en <= 1'b0;
            cnn_start  <= 1'b0;
        end else begin
            cnn_start  <= 1'b0;
            load_wr_en <= 1'b0;

            case (load_state)
                LOAD_IDLE: begin
                    if (start_pulse) begin
                        load_addr  <= 12'd0;
                        load_wr_en <= 1'b1;
                        load_state <= LOAD_WRITE;
                    end
                end

                LOAD_WRITE: begin
                    load_wr_en <= 1'b1;
                    if (load_addr == 12'd3071) begin
                        load_state <= LOAD_START;
                    end else begin
                        load_addr <= load_addr + 1'b1;
                    end
                end

                LOAD_START: begin
                    load_wr_en <= 1'b0;
                    cnn_start  <= 1'b1;
                    load_state <= LOAD_WAIT;
                end

                LOAD_WAIT: begin
                    if (cnn_done) begin
                        load_state <= LOAD_IDLE;
                    end
                end

                default: load_state <= LOAD_IDLE;
            endcase
        end
    end

    // =========================================================================
    // Core CNN Accelerator Instance
    // =========================================================================

    cnn_top #(
        .MEM_DIR(MEM_DIR)
    ) cnn_inst (
        .clk(clk),
        .rst(rst_sync),
        .start(cnn_start),
        .image_wr_en(load_wr_en),
        .image_wr_addr(load_addr),
        .image_wr_data(load_data),
        .busy(cnn_busy),
        .done(cnn_done),
        .predicted_class(pred_class),
        .score_0(score_0),
        .score_1(score_1),
        .score_2(score_2)
    );

    // =========================================================================
    // Physical Board LED Status Outputs
    // =========================================================================
    logic [1:0] latched_class;
    logic       latched_done;

    always_ff @(posedge clk) begin
        if (rst_sync) begin
            latched_class <= 2'b00;
            latched_done  <= 1'b0;
        end else if (cnn_done) begin
            latched_class <= pred_class;
            latched_done  <= 1'b1;
        end else if (cnn_start) begin
            latched_done  <= 1'b0;
        end
    end

    assign led[0] = cnn_busy || (load_state != LOAD_IDLE && load_state != LOAD_WAIT); // Busy
    assign led[1] = latched_done;                                                      // Done
    assign led[3:2] = latched_class;                                                   // Class bits

    // RGB LED 4 visual classification output
    always_comb begin
        led4_r = 1'b0;
        led4_g = 1'b0;
        led4_b = 1'b0;

        if (latched_done) begin
            case (latched_class)
                2'd0: begin // Green
                    led4_r = 1'b0;
                    led4_g = 1'b1;
                    led4_b = 1'b0;
                end
                2'd1: begin // Red
                    led4_r = 1'b1;
                    led4_g = 1'b0;
                    led4_b = 1'b0;
                end
                2'd2: begin // Yellow (Red + Green)
                    led4_r = 1'b1;
                    led4_g = 1'b1;
                    led4_b = 1'b0;
                end
                default: begin
                    led4_r = 1'b0;
                    led4_g = 1'b0;
                    led4_b = 1'b0;
                end
            endcase
        end
    end

endmodule
