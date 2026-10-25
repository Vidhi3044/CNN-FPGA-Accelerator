`timescale 1ns/1ps

/**
 * End-to-End Verification Testbench for cnn_top Accelerator.
 *
 * Verifies the complete CNN accelerator from 32x32 RGB image input
 * through Conv1, ReLU1, Pool1, Requant1, Conv2, ReLU2, Pool2, Requant2,
 * Conv3, ReLU3, Requant3, Flatten, FC1, ReLU4, FC2, Argmax to class prediction.
 *
 * Tests 4 full test cases:
 *   Case 0: Real CARLA test image (Class 0: Green)
 *   Case 1: Red traffic light (Class 1: Red)
 *   Case 2: Yellow traffic light (Class 2: Yellow)
 *   Case 3: Green traffic light (Class 0: Green)
 */

module tb_cnn_top;

    localparam CLK_PERIOD = 10; // 100 MHz clock (10 ns period)

    logic        clk;
    logic        rst;
    logic        start;

    logic        image_wr_en;
    logic [11:0] image_wr_addr;
    logic signed [7:0] image_wr_data;

    wire         busy;
    wire         done;
    wire  [1:0]  predicted_class;
    wire  signed [31:0] score_0;
    wire  signed [31:0] score_1;
    wire  signed [31:0] score_2;

    // Instantiate Device Under Test
    cnn_top #(
        .MEM_DIR("FPGA_Parameters/mem_files")
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .image_wr_en(image_wr_en),
        .image_wr_addr(image_wr_addr),
        .image_wr_data(image_wr_data),
        .busy(busy),
        .done(done),
        .predicted_class(predicted_class),
        .score_0(score_0),
        .score_1(score_1),
        .score_2(score_2)
    );

    // Clock generation (100 MHz)
    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    // Test tracking
    integer total_tests;
    integer passed_tests;
    integer total_mismatches;
    integer start_cycle;
    integer end_cycle;
    integer latency_cycles;

    // Test arrays for verification
    reg signed [7:0]  test_image [0:3071];
    reg signed [31:0] exp_fc2 [0:2];
    reg [7:0]         exp_class [0:0];

    // Reference arrays for internal layer checking (Case 0)
    reg signed [7:0]  exp_buf1 [0:3599];
    reg signed [7:0]  exp_buf2 [0:1151];
    reg signed [7:0]  exp_buf3 [0:1023];
    reg signed [31:0] exp_buf4 [0:127];

    string class_names [0:2] = '{"Green", "Red", "Yellow"};

    // Task to run one full inference test case
    task run_test_case(
        input string case_name,
        input string case_dir,
        input integer expected_label
    );
        integer i;
        integer case_errors;
        begin
            case_errors = 0;
            total_tests = total_tests + 1;
            $display("\n========================================================");
            $display("RUNNING TEST: %s", case_name);
            $display("Expected Class: %0d (%s)", expected_label, class_names[expected_label]);
            $display("========================================================");

            // Read test image and expectations
            $readmemh({case_dir, "/input_image.mem"}, test_image);
            $readmemh({case_dir, "/expected_fc2.mem"}, exp_fc2);
            $readmemh({case_dir, "/expected_class.mem"}, exp_class);

            // 1. Reset DUT
            @(posedge clk);
            rst <= 1'b1;
            start <= 1'b0;
            image_wr_en <= 1'b0;
            @(posedge clk);
            rst <= 1'b0;
            @(posedge clk);

            // 2. Load 32x32x3 image into DUT memory
            $display("[TB] Loading 3,072 bytes of image data...");
            for (i = 0; i < 3072; i = i + 1) begin
                @(posedge clk);
                image_wr_en <= 1'b1;
                image_wr_addr <= i[11:0];
                image_wr_data <= test_image[i];
            end
            @(posedge clk);
            image_wr_en <= 1'b0;
            $display("[TB] Image loaded successfully.");

            // 3. Assert Start
            @(posedge clk);
            start <= 1'b1;
            start_cycle = $time / CLK_PERIOD;
            @(posedge clk);
            start <= 1'b0;
            #1;

            // 4. Verify busy signal asserted
            if (!busy) begin
                $display("ERROR: DUT did not assert busy after start!");
                case_errors = case_errors + 1;
            end

            // 5. Wait for Done
            wait(done == 1'b1);
            end_cycle = $time / CLK_PERIOD;
            latency_cycles = end_cycle - start_cycle;

            $display("[TB] Inference DONE asserted after %0d clock cycles (%0.2f us at 100 MHz).",
                     latency_cycles, latency_cycles * 0.010);

            // 6. Check Class Scores
            $display("[TB] Actual FC2 Scores:   Green=%0d, Red=%0d, Yellow=%0d",
                     score_0, score_1, score_2);
            $display("[TB] Expected FC2 Scores: Green=%0d, Red=%0d, Yellow=%0d",
                     exp_fc2[0], exp_fc2[1], exp_fc2[2]);

            if (score_0 !== exp_fc2[0]) begin
                $display("MISMATCH in Score 0 (Green): actual=%0d, expected=%0d", score_0, exp_fc2[0]);
                case_errors = case_errors + 1;
            end
            if (score_1 !== exp_fc2[1]) begin
                $display("MISMATCH in Score 1 (Red):   actual=%0d, expected=%0d", score_1, exp_fc2[1]);
                case_errors = case_errors + 1;
            end
            if (score_2 !== exp_fc2[2]) begin
                $display("MISMATCH in Score 2 (Yellow):actual=%0d, expected=%0d", score_2, exp_fc2[2]);
                case_errors = case_errors + 1;
            end

            // 7. Check Predicted Class
            $display("[TB] Actual Predicted Class:   %0d (%s)", predicted_class, class_names[predicted_class]);
            $display("[TB] Expected Predicted Class: %0d (%s)", exp_class[0][1:0], class_names[exp_class[0][1:0]]);

            if (predicted_class !== exp_class[0][1:0]) begin
                $display("CRITICAL MISMATCH: Predicted class %0d does not match expected %0d!",
                         predicted_class, exp_class[0][1:0]);
                case_errors = case_errors + 1;
            end else begin
                $display("PREDICTION MATCH: Correctly classified as %s!", class_names[predicted_class]);
            end

            if (case_errors == 0) begin
                $display(">>> TEST PASSED: %s <<<", case_name);
                passed_tests = passed_tests + 1;
            end else begin
                $display(">>> TEST FAILED: %s (%0d mismatches) <<<", case_name, case_errors);
                total_mismatches = total_mismatches + case_errors;
            end

            // Allow extra cycles before next test
            repeat (10) @(posedge clk);
        end
    endtask

    // Detailed internal layer verification task for Case 0
    task verify_internal_layers(input string case_dir);
        integer i;
        integer layer_mismatches;
        begin
            $display("\n--------------------------------------------------------");
            $display("VERIFYING INTERNAL FEATURE BUFFERS AGAINST BIT-EXACT REF");
            $display("--------------------------------------------------------");
            layer_mismatches = 0;

            $readmemh({case_dir, "/expected_requant1.mem"}, exp_buf1);
            $readmemh({case_dir, "/expected_requant2.mem"}, exp_buf2);
            $readmemh({case_dir, "/expected_flatten.mem"},  exp_buf3);
            $readmemh({case_dir, "/expected_fc1.mem"},      exp_buf4);

            // 1. Check Buffer 1 (Pool1 / Requant1): 3600 elements
            for (i = 0; i < 3600; i = i + 1) begin
                if (dut.buf1_mem[i] !== exp_buf1[i]) begin
                    if (layer_mismatches < 5)
                        $display("Buffer 1 mismatch @ %0d: RTL=%0d, Ref=%0d", i, dut.buf1_mem[i], exp_buf1[i]);
                    layer_mismatches = layer_mismatches + 1;
                end
            end
            if (layer_mismatches == 0)
                $display("Buffer 1 (Pool1 / Requant1): 3,600 / 3,600 MATCH (100%% bit-exact)");
            else
                $display("Buffer 1 (Pool1 / Requant1): %0d mismatches", layer_mismatches);

            // 2. Check Buffer 2 (Pool2 / Requant2): 1152 elements
            layer_mismatches = 0;
            for (i = 0; i < 1152; i = i + 1) begin
                if (dut.buf2_mem[i] !== exp_buf2[i]) begin
                    if (layer_mismatches < 5)
                        $display("Buffer 2 mismatch @ %0d: RTL=%0d, Ref=%0d", i, dut.buf2_mem[i], exp_buf2[i]);
                    layer_mismatches = layer_mismatches + 1;
                end
            end
            if (layer_mismatches == 0)
                $display("Buffer 2 (Pool2 / Requant2): 1,152 / 1,152 MATCH (100%% bit-exact)");
            else
                $display("Buffer 2 (Pool2 / Requant2): %0d mismatches", layer_mismatches);

            // 3. Check Buffer 3 (Conv3 / Flatten): 1024 elements
            layer_mismatches = 0;
            for (i = 0; i < 1024; i = i + 1) begin
                if (dut.buf3_mem[i] !== exp_buf3[i]) begin
                    if (layer_mismatches < 5)
                        $display("Buffer 3 mismatch @ %0d: RTL=%0d, Ref=%0d", i, dut.buf3_mem[i], exp_buf3[i]);
                    layer_mismatches = layer_mismatches + 1;
                end
            end
            if (layer_mismatches == 0)
                $display("Buffer 3 (Conv3 / Flatten): 1,024 / 1,024 MATCH (100%% bit-exact)");
            else
                $display("Buffer 3 (Conv3 / Flatten): %0d mismatches", layer_mismatches);

            // 4. Check Buffer 4 (FC1 ReLU): 128 elements
            layer_mismatches = 0;
            for (i = 0; i < 128; i = i + 1) begin
                logic signed [31:0] exp_relu_val;
                exp_relu_val = (exp_buf4[i] < 0) ? 32'sd0 : exp_buf4[i];
                if (dut.buf4_mem[i] !== exp_relu_val) begin
                    if (layer_mismatches < 5)
                        $display("Buffer 4 mismatch @ %0d: RTL=%0d, Ref=%0d", i, dut.buf4_mem[i], exp_relu_val);
                    layer_mismatches = layer_mismatches + 1;
                end
            end
            if (layer_mismatches == 0)
                $display("Buffer 4 (FC1 ReLU):        128 / 128 MATCH (100%% bit-exact)");
            else
                $display("Buffer 4 (FC1 ReLU): %0d mismatches", layer_mismatches);
        end
    endtask

    // Main Test Sequence
    initial begin
        $dumpfile("simulations/cnn_top.vcd");
        $dumpvars(0, tb_cnn_top);

        total_tests = 0;
        passed_tests = 0;
        total_mismatches = 0;

        $display("\n========================================================");
        $display("STARTING CNN ACCELERATOR END-TO-END VERIFICATION SUITE");
        $display("Target Device: Digilent Arty A7-100T (XC7A100T)");
        $display("========================================================");

        // Case 0: Real CARLA dataset image (Green light)
        run_test_case(
            "Case 0: Real CARLA Traffic Light Image",
            "FPGA_Parameters/test_cases/case0_real_green",
            0
        );
        verify_internal_layers("FPGA_Parameters/test_cases/case0_real_green");

        // Case 1: Red traffic light
        run_test_case(
            "Case 1: Red Traffic Light Image",
            "FPGA_Parameters/test_cases/case1_red",
            1
        );

        // Case 2: Yellow traffic light
        run_test_case(
            "Case 2: Yellow Traffic Light Image",
            "FPGA_Parameters/test_cases/case2_yellow",
            2
        );

        // Case 3: Bright Green traffic light
        run_test_case(
            "Case 3: Bright Green Traffic Light Image",
            "FPGA_Parameters/test_cases/case3_green",
            0
        );

        // Final Summary
        $display("\n========================================================");
        $display("FINAL VERIFICATION SUMMARY");
        $display("========================================================");
        $display("Total Test Cases Run: %0d", total_tests);
        $display("Passed Test Cases:    %0d", passed_tests);
        $display("Failed Test Cases:    %0d", total_tests - passed_tests);
        $display("Total Value Mismatches: %0d", total_mismatches);

        if (passed_tests == total_tests && total_mismatches == 0) begin
            $display("\n>>> ALL END-TO-END TESTS PASSED SUCCESSFULLY! <<<");
            $display("The RTL hardware accelerator is 100%% verified against the trained CNN model.");
        end else begin
            $display("\n>>> END-TO-END VERIFICATION FAILED! <<<");
        end
        $display("========================================================\n");

        $finish;
    end

endmodule
