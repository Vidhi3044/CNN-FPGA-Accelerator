`timescale 1ns/1ps

/**
 * Top-Level Synthesizable CNN Accelerator for Traffic Light Classification.
 * Target: Digilent Arty A7-100T FPGA (Xilinx Artix-7 XC7A100TCSG324-1)
 *
 * Architecture:
 *   Input: 32x32x3 RGB image (INT8 in [0, 127])
 *   Conv1: 16 filters 3x3x3 -> ReLU -> MaxPool2x2 (15x15x16) -> Requant1 (MULT=110, SHIFT=16)
 *   Conv2: 32 filters 3x3x16 -> ReLU -> MaxPool2x2 (6x6x32) -> Requant2 (MULT=61, SHIFT=16)
 *   Conv3: 64 filters 3x3x32 -> ReLU -> Requant3 (MULT=61, SHIFT=16) -> Flatten (1024)
 *   FC1:   128 neurons (1024 inputs) -> ReLU -> 128 outputs (INT32)
 *   FC2:   3 neurons (128 inputs) -> 3 class scores (INT32)
 *   Argmax: Highest score -> predicted class (0=Green, 1=Red, 2=Yellow)
 */

module cnn_top #(
    parameter MEM_DIR = "FPGA_Parameters/mem_files"
)(
    input  logic        clk,
    input  logic        rst,
    input  logic        start,

    // External image loading interface
    input  logic        image_wr_en,
    input  logic [11:0] image_wr_addr,
    input  logic signed [7:0] image_wr_data,

    // Status and outputs
    output logic        busy,
    output logic        done,
    output logic [1:0]  predicted_class,
    output logic signed [31:0] score_0,
    output logic signed [31:0] score_1,
    output logic signed [31:0] score_2
);

    // =========================================================================
    // FSM State Encoding
    // =========================================================================
    typedef enum logic [3:0] {
        S_IDLE         = 4'd0,
        S_CONV1_LOAD   = 4'd1,
        S_CONV1_CALC   = 4'd2,
        S_CONV1_STORE  = 4'd3,
        S_CONV2_STEP   = 4'd4,
        S_CONV2_POOL   = 4'd5,
        S_CONV2_STORE  = 4'd6,
        S_CONV3_STEP   = 4'd7,
        S_CONV3_STORE  = 4'd8,
        S_FC1_STEP     = 4'd9,
        S_FC1_STORE    = 4'd10,
        S_FC2_STEP     = 4'd11,
        S_ARGMAX       = 4'd12,
        S_DONE         = 4'd13
    } state_t;

    state_t state;

    // =========================================================================
    // Internal Memories (Feature Buffers)
    // =========================================================================
    // Image Buffer: 32 * 32 * 3 = 3072 bytes
    logic signed [7:0] image_mem [0:3071];

    // Buffer 1 (Post-Conv1/Pool1/Requant): 16 channels * 15 * 15 = 3600 bytes
    logic signed [7:0] buf1_mem [0:3599];

    // Buffer 2 (Post-Conv2/Pool2/Requant): 32 channels * 6 * 6 = 1152 bytes
    logic signed [7:0] buf2_mem [0:1151];

    // Buffer 3 (Post-Conv3/Requant/Flatten): 64 channels * 4 * 4 = 1024 bytes
    logic signed [7:0] buf3_mem [0:1023];

    // Buffer 4 (Post-FC1/ReLU): 128 neurons * 32-bit = 128 words
    logic signed [31:0] buf4_mem [0:127];

    // =========================================================================
    // Weights and Biases Memories
    // =========================================================================
    // Conv1: 16 * 27 = 432 weights, 16 biases
    logic signed [7:0]  w1_rom [0:431];
    logic signed [31:0] b1_rom [0:15];

    // Conv2: 32 * 144 = 4608 weights, 32 biases
    logic signed [7:0]  w2_rom [0:4607];
    logic signed [31:0] b2_rom [0:31];

    // Conv3: 64 * 288 = 18432 weights, 64 biases
    logic signed [7:0]  w3_rom [0:18431];
    logic signed [31:0] b3_rom [0:63];

    // FC1: 128 * 1024 = 131072 weights, 128 biases
    logic signed [7:0]  w_fc1_rom [0:131071];
    logic signed [31:0] b_fc1_rom [0:127];

    // FC2: 3 * 128 = 384 weights, 3 biases
    logic signed [7:0]  w_fc2_rom [0:383];
    logic signed [31:0] b_fc2_rom [0:2];

    initial begin
        $readmemh({MEM_DIR, "/weights/features_0_weight.mem"}, w1_rom);
        $readmemh({MEM_DIR, "/biases/features_0_bias.mem"}, b1_rom);
        $readmemh({MEM_DIR, "/weights/features_3_weight.mem"}, w2_rom);
        $readmemh({MEM_DIR, "/biases/features_3_bias.mem"}, b2_rom);
        $readmemh({MEM_DIR, "/weights/features_6_weight.mem"}, w3_rom);
        $readmemh({MEM_DIR, "/biases/features_6_bias.mem"}, b3_rom);
        $readmemh({MEM_DIR, "/weights/classifier_1_weight.mem"}, w_fc1_rom);
        $readmemh({MEM_DIR, "/biases/classifier_1_bias_int32.mem"}, b_fc1_rom);
        $readmemh({MEM_DIR, "/weights/classifier_3_weight.mem"}, w_fc2_rom);
        $readmemh({MEM_DIR, "/biases/classifier_3_bias.mem"}, b_fc2_rom);
    end

    // Image memory external write port
    always_ff @(posedge clk) begin
        if (image_wr_en) begin
            image_mem[image_wr_addr] <= image_wr_data;
        end
    end

    // =========================================================================
    // Stage 1: Conv1 + ReLU1 + MaxPool1 + Requantize1
    // =========================================================================
    integer c1_py, c1_px, c1_quad, c1_k;
    logic signed [7:0]  c1_patch [0:26];
    logic signed [7:0]  c1_weights [0:15][0:26];
    logic signed [31:0] c1_biases [0:15];
    wire  signed [31:0] c1_conv_out [0:15];
    wire  signed [31:0] c1_relu_out [0:15];
    logic signed [31:0] c1_pool_max [0:15];

    genvar g1, g1_k;
    generate
        for (g1 = 0; g1 < 16; g1 = g1 + 1) begin : c1_bank_unpack
            assign c1_biases[g1] = b1_rom[g1];
            for (g1_k = 0; g1_k < 27; g1_k = g1_k + 1) begin : c1_w_unpack
                assign c1_weights[g1][g1_k] = w1_rom[g1*27 + g1_k];
            end
        end
    endgenerate

    conv1_filter_bank #(
        .FILTER_COUNT(16)
    ) conv1_bank_inst (
        .inputs(c1_patch),
        .weights(c1_weights),
        .biases(c1_biases),
        .outputs(c1_conv_out)
    );

    relu_bank #(
        .FILTER_COUNT(16)
    ) relu1_bank_inst (
        .input_values(c1_conv_out),
        .output_values(c1_relu_out)
    );

    wire signed [7:0] c1_requant_out [0:15];
    generate
        for (g1 = 0; g1 < 16; g1 = g1 + 1) begin : c1_requant_units
            requantize_int8 #(
                .SHIFT(16)
            ) req1_inst (
                .accumulator(c1_pool_max[g1]),
                .multiplier(32'sd110),
                .zero_point(8'sd0),
                .output_value(c1_requant_out[g1])
            );
        end
    endgenerate

    // =========================================================================
    // Stage 2: Conv2 + ReLU2 + MaxPool2 + Requantize2
    // =========================================================================
    integer c2_py, c2_px, c2_quad, c2_k;
    logic signed [31:0] c2_acc [0:31];
    logic signed [31:0] c2_pool_max [0:31];
    wire  signed [7:0]  c2_requant_out [0:31];

    genvar g2;
    generate
        for (g2 = 0; g2 < 32; g2 = g2 + 1) begin : c2_requant_units
            requantize_int8 #(
                .SHIFT(16)
            ) req2_inst (
                .accumulator(c2_pool_max[g2]),
                .multiplier(32'sd61),
                .zero_point(8'sd0),
                .output_value(c2_requant_out[g2])
            );
        end
    endgenerate

    // =========================================================================
    // Stage 3: Conv3 + ReLU3 + Requantize3
    // =========================================================================
    integer c3_y, c3_x, c3_k;
    logic signed [31:0] c3_acc [0:63];
    wire  signed [7:0]  c3_requant_out [0:63];

    genvar g3;
    generate
        for (g3 = 0; g3 < 64; g3 = g3 + 1) begin : c3_requant_units
            wire signed [31:0] r3_val = (c3_acc[g3] < 0) ? 32'sd0 : c3_acc[g3];
            requantize_int8 #(
                .SHIFT(16)
            ) req3_inst (
                .accumulator(r3_val),
                .multiplier(32'sd61),
                .zero_point(8'sd0),
                .output_value(c3_requant_out[g3])
            );
        end
    endgenerate

    // =========================================================================
    // Stage 4: FC1 + ReLU4 (32 neurons in parallel x 4 passes)
    // =========================================================================
    integer fc1_pass, fc1_k;
    logic signed [31:0] fc1_acc [0:31];

    // =========================================================================
    // Stage 5: FC2 (3 class scores)
    // =========================================================================
    integer fc2_k;
    logic signed [31:0] fc2_acc [0:2];

    // =========================================================================
    // Stage 6: Argmax
    // =========================================================================
    logic signed [31:0] final_scores [0:2];
    wire  [1:0] argmax_class;

    argmax #(
        .CLASS_COUNT(3)
    ) argmax_inst (
        .scores(fc2_acc),
        .class_index(argmax_class)
    );

    // =========================================================================
    // Output Registers
    // =========================================================================
    logic [1:0] pred_reg;
    logic       done_reg;
    logic       busy_reg;

    assign busy = (state != S_IDLE && state != S_DONE);
    assign done = done_reg;
    assign predicted_class = pred_reg;
    assign score_0 = final_scores[0];
    assign score_1 = final_scores[1];
    assign score_2 = final_scores[2];

    // =========================================================================
    // Sequential Control Finite State Machine
    // =========================================================================
    integer c, ky, kx;
    integer cur_y, cur_x;
    integer img_addr, buf1_addr, buf2_addr, buf3_addr;
    integer f, n;
    logic signed [7:0] in_val;

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            busy_reg <= 1'b0;
            done_reg <= 1'b0;
            pred_reg <= 2'b00;
            final_scores[0] <= 32'sd0;
            final_scores[1] <= 32'sd0;
            final_scores[2] <= 32'sd0;

            c1_py <= 0;
            c1_px <= 0;
            c1_quad <= 0;
            c1_k <= 0;

            c2_py <= 0;
            c2_px <= 0;
            c2_quad <= 0;
            c2_k <= 0;

            c3_y <= 0;
            c3_x <= 0;
            c3_k <= 0;

            fc1_pass <= 0;
            fc1_k <= 0;

            fc2_k <= 0;
        end else begin
            case (state)
                // -------------------------------------------------------------
                // S_IDLE: Wait for start signal
                // -------------------------------------------------------------
                S_IDLE: begin
                    done_reg <= 1'b0;
                    if (start) begin
                        busy_reg <= 1'b1;
                        state <= S_CONV1_LOAD;
                        c1_py <= 0;
                        c1_px <= 0;
                        c1_quad <= 0;
                        c1_k <= 0;
                    end else begin
                        busy_reg <= 1'b0;
                    end
                end

                // -------------------------------------------------------------
                // S_CONV1_LOAD: Load 3x3x3 patch into c1_patch registers
                // -------------------------------------------------------------
                S_CONV1_LOAD: begin
                    cur_y = c1_py * 2 + (c1_quad / 2);
                    cur_x = c1_px * 2 + (c1_quad % 2);

                    c  = c1_k / 9;
                    ky = (c1_k % 9) / 3;
                    kx = (c1_k % 9) % 3;

                    img_addr = c * 1024 + (cur_y + ky) * 32 + (cur_x + kx);
                    c1_patch[c1_k] <= image_mem[img_addr];

                    if (c1_k == 26) begin
                        c1_k <= 0;
                        state <= S_CONV1_CALC;
                    end else begin
                        c1_k <= c1_k + 1;
                    end
                end

                // -------------------------------------------------------------
                // S_CONV1_CALC: Evaluate Conv1 bank + ReLU bank + Update Pool Max
                // -------------------------------------------------------------
                S_CONV1_CALC: begin
                    for (f = 0; f < 16; f = f + 1) begin
                        if (c1_quad == 0) begin
                            c1_pool_max[f] <= c1_relu_out[f];
                        end else begin
                            if (c1_relu_out[f] > c1_pool_max[f])
                                c1_pool_max[f] <= c1_relu_out[f];
                        end
                    end

                    if (c1_quad == 3) begin
                        // All 4 quadrants computed; proceed to store state where pool_max is settled
                        state <= S_CONV1_STORE;
                    end else begin
                        c1_quad <= c1_quad + 1;
                        state <= S_CONV1_LOAD;
                    end
                end

                // -------------------------------------------------------------
                // S_CONV1_STORE: Store settled pooled and requantized outputs to Buffer 1
                // -------------------------------------------------------------
                S_CONV1_STORE: begin
                    for (f = 0; f < 16; f = f + 1) begin
                        buf1_addr = f * 225 + c1_py * 15 + c1_px;
                        buf1_mem[buf1_addr] <= c1_requant_out[f];
                    end

                    c1_quad <= 0;
                    if (c1_px == 14) begin
                        c1_px <= 0;
                        if (c1_py == 14) begin
                            // Conv1 complete -> transition to Conv2
                            state <= S_CONV2_STEP;
                            c2_py <= 0;
                            c2_px <= 0;
                            c2_quad <= 0;
                            c2_k <= 0;
                        end else begin
                            c1_py <= c1_py + 1;
                            state <= S_CONV1_LOAD;
                        end
                    end else begin
                        c1_px <= c1_px + 1;
                        state <= S_CONV1_LOAD;
                    end
                end

                // -------------------------------------------------------------
                // S_CONV2_STEP: Conv2 MAC streaming
                // -------------------------------------------------------------
                S_CONV2_STEP: begin
                    cur_y = c2_py * 2 + (c2_quad / 2);
                    cur_x = c2_px * 2 + (c2_quad % 2);

                    c  = c2_k / 9;
                    ky = (c2_k % 9) / 3;
                    kx = (c2_k % 9) % 3;

                    buf1_addr = c * 225 + (cur_y + ky) * 15 + (cur_x + kx);
                    in_val = buf1_mem[buf1_addr];

                    for (f = 0; f < 32; f = f + 1) begin
                        if (c2_k == 0) begin
                            c2_acc[f] <= b2_rom[f] + in_val * w2_rom[f*144 + c2_k];
                        end else begin
                            c2_acc[f] <= c2_acc[f] + in_val * w2_rom[f*144 + c2_k];
                        end
                    end

                    if (c2_k == 143) begin
                        c2_k <= 0;
                        state <= S_CONV2_POOL;
                    end else begin
                        c2_k <= c2_k + 1;
                    end
                end

                // -------------------------------------------------------------
                // S_CONV2_POOL: Update Pool2 Max from settled c2_acc
                // -------------------------------------------------------------
                S_CONV2_POOL: begin
                    for (f = 0; f < 32; f = f + 1) begin
                        logic signed [31:0] r2_val;
                        r2_val = (c2_acc[f] < 0) ? 32'sd0 : c2_acc[f];

                        if (c2_quad == 0) begin
                            c2_pool_max[f] <= r2_val;
                        end else begin
                            if (r2_val > c2_pool_max[f])
                                c2_pool_max[f] <= r2_val;
                        end
                    end

                    if (c2_quad == 3) begin
                        state <= S_CONV2_STORE;
                    end else begin
                        c2_quad <= c2_quad + 1;
                        state <= S_CONV2_STEP;
                    end
                end

                // -------------------------------------------------------------
                // S_CONV2_STORE: Store settled pooled and requantized outputs to Buffer 2
                // -------------------------------------------------------------
                S_CONV2_STORE: begin
                    for (f = 0; f < 32; f = f + 1) begin
                        buf2_addr = f * 36 + c2_py * 6 + c2_px;
                        buf2_mem[buf2_addr] <= c2_requant_out[f];
                    end

                    c2_quad <= 0;
                    if (c2_px == 5) begin
                        c2_px <= 0;
                        if (c2_py == 5) begin
                            // Conv2 complete -> transition to Conv3
                            state <= S_CONV3_STEP;
                            c3_y <= 0;
                            c3_x <= 0;
                            c3_k <= 0;
                        end else begin
                            c2_py <= c2_py + 1;
                            state <= S_CONV2_STEP;
                        end
                    end else begin
                        c2_px <= c2_px + 1;
                        state <= S_CONV2_STEP;
                    end
                end

                // -------------------------------------------------------------
                // S_CONV3_STEP: Conv3 MAC streaming
                // -------------------------------------------------------------
                S_CONV3_STEP: begin
                    c  = c3_k / 9;
                    ky = (c3_k % 9) / 3;
                    kx = (c3_k % 9) % 3;

                    buf2_addr = c * 36 + (c3_y + ky) * 6 + (c3_x + kx);
                    in_val = buf2_mem[buf2_addr];

                    for (f = 0; f < 64; f = f + 1) begin
                        if (c3_k == 0) begin
                            c3_acc[f] <= b3_rom[f] + in_val * w3_rom[f*288 + c3_k];
                        end else begin
                            c3_acc[f] <= c3_acc[f] + in_val * w3_rom[f*288 + c3_k];
                        end
                    end

                    if (c3_k == 287) begin
                        c3_k <= 0;
                        state <= S_CONV3_STORE;
                    end else begin
                        c3_k <= c3_k + 1;
                    end
                end

                // -------------------------------------------------------------
                // S_CONV3_STORE: Store settled Conv3 requant outputs in Flatten buffer
                // -------------------------------------------------------------
                S_CONV3_STORE: begin
                    for (f = 0; f < 64; f = f + 1) begin
                        buf3_addr = f * 16 + c3_y * 4 + c3_x;
                        buf3_mem[buf3_addr] <= c3_requant_out[f];
                    end

                    if (c3_x == 3) begin
                        c3_x <= 0;
                        if (c3_y == 3) begin
                            // Conv3 complete -> transition to FC1
                            state <= S_FC1_STEP;
                            fc1_pass <= 0;
                            fc1_k <= 0;
                        end else begin
                            c3_y <= c3_y + 1;
                            state <= S_CONV3_STEP;
                        end
                    end else begin
                        c3_x <= c3_x + 1;
                        state <= S_CONV3_STEP;
                    end
                end

                // -------------------------------------------------------------
                // S_FC1_STEP: FC1 MAC streaming (32 neurons in parallel x 4 passes)
                // -------------------------------------------------------------
                S_FC1_STEP: begin
                    in_val = buf3_mem[fc1_k];

                    for (n = 0; n < 32; n = n + 1) begin
                        integer neuron_idx;
                        neuron_idx = fc1_pass * 32 + n;

                        if (fc1_k == 0) begin
                            fc1_acc[n] <= b_fc1_rom[neuron_idx] + in_val * w_fc1_rom[neuron_idx * 1024 + fc1_k];
                        end else begin
                            fc1_acc[n] <= fc1_acc[n] + in_val * w_fc1_rom[neuron_idx * 1024 + fc1_k];
                        end
                    end

                    if (fc1_k == 1023) begin
                        fc1_k <= 0;
                        state <= S_FC1_STORE;
                    end else begin
                        fc1_k <= fc1_k + 1;
                    end
                end

                // -------------------------------------------------------------
                // S_FC1_STORE: Store settled FC1 ReLU outputs into Buffer 4
                // -------------------------------------------------------------
                S_FC1_STORE: begin
                    for (n = 0; n < 32; n = n + 1) begin
                        integer neuron_idx;
                        neuron_idx = fc1_pass * 32 + n;
                        buf4_mem[neuron_idx] <= (fc1_acc[n] < 0) ? 32'sd0 : fc1_acc[n];
                    end

                    if (fc1_pass == 3) begin
                        // FC1 complete -> transition to FC2
                        state <= S_FC2_STEP;
                        fc2_k <= 0;
                    end else begin
                        fc1_pass <= fc1_pass + 1;
                        state <= S_FC1_STEP;
                    end
                end

                // -------------------------------------------------------------
                // S_FC2_STEP: FC2 MAC streaming (3 neurons on 128 inputs)
                // -------------------------------------------------------------
                S_FC2_STEP: begin
                    logic signed [31:0] fc1_val;
                    fc1_val = buf4_mem[fc2_k];

                    for (c = 0; c < 3; c = c + 1) begin
                        if (fc2_k == 0) begin
                            fc2_acc[c] <= b_fc2_rom[c] + fc1_val * w_fc2_rom[c * 128 + fc2_k];
                        end else begin
                            fc2_acc[c] <= fc2_acc[c] + fc1_val * w_fc2_rom[c * 128 + fc2_k];
                        end
                    end

                    if (fc2_k == 127) begin
                        fc2_k <= 0;
                        state <= S_ARGMAX;
                    end else begin
                        fc2_k <= fc2_k + 1;
                    end
                end

                // -------------------------------------------------------------
                // S_ARGMAX: Capture Class Scores and Calculate Argmax
                // -------------------------------------------------------------
                S_ARGMAX: begin
                    final_scores[0] <= fc2_acc[0];
                    final_scores[1] <= fc2_acc[1];
                    final_scores[2] <= fc2_acc[2];
                    pred_reg <= argmax_class;
                    state <= S_DONE;
                end

                // -------------------------------------------------------------
                // S_DONE: Completion state
                // -------------------------------------------------------------
                S_DONE: begin
                    busy_reg <= 1'b0;
                    done_reg <= 1'b1;
                    if (start) begin
                        // Repeated inference requested
                        done_reg <= 1'b0;
                        busy_reg <= 1'b1;
                        state <= S_CONV1_LOAD;
                        c1_py <= 0;
                        c1_px <= 0;
                        c1_quad <= 0;
                        c1_k <= 0;
                    end
                end

                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

endmodule
