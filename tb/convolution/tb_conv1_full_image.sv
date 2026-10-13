
`timescale 1ns/1ps

module tb_conv1_full_image;

localparam integer FILTER_COUNT = 16;
localparam integer IMAGE_SIZE = 32;
localparam integer INPUT_COUNT = IMAGE_SIZE * IMAGE_SIZE * 3;
localparam integer OUTPUT_COUNT = FILTER_COUNT * 30 * 30;

reg signed [7:0] image_data [0:INPUT_COUNT-1];
reg signed [7:0] flat_weights [0:FILTER_COUNT*27-1];
reg signed [7:0] weights [0:FILTER_COUNT-1][0:26];
reg signed [31:0] biases [0:FILTER_COUNT-1];
reg signed [31:0] expected [0:OUTPUT_COUNT-1];

reg signed [7:0] patch [0:26];
wire signed [31:0] patch_outputs [0:FILTER_COUNT-1];

integer i;
integer j;
integer c;
integer y;
integer x;
integer f;
integer errors;
integer output_index;

conv1_filter_bank #(
    .FILTER_COUNT(FILTER_COUNT)
) dut (
    .inputs(patch),
    .weights(weights),
    .biases(biases),
    .outputs(patch_outputs)
);

initial begin
    errors = 0;

    $readmemh("FPGA_Parameters/mem_files/conv1_full_test/conv1_input.mem", image_data);
    $readmemh("FPGA_Parameters/mem_files/conv1_full_test/conv1_weights.mem", flat_weights);
    $readmemh("FPGA_Parameters/mem_files/conv1_full_test/conv1_biases.mem", biases);
    $readmemh("FPGA_Parameters/mem_files/conv1_full_test/conv1_expected.mem", expected);

    for (i = 0; i < FILTER_COUNT; i = i + 1) begin
        for (j = 0; j < 27; j = j + 1) begin
            weights[i][j] = flat_weights[i*27+j];
        end
    end

    output_index = 0;

    for (y = 0; y < 30; y = y + 1) begin
        for (x = 0; x < 30; x = x + 1) begin
            for (c = 0; c < 3; c = c + 1) begin
                for (i = 0; i < 3; i = i + 1) begin
                    for (j = 0; j < 3; j = j + 1) begin
                        patch[c*9+i*3+j] =
                            image_data[c*1024+(y+i)*32+(x+j)];
                    end
                end
            end

            #1;

            for (f = 0; f < FILTER_COUNT; f = f + 1) begin
                output_index = f*900+y*30+x;

                if (patch_outputs[f] !== expected[output_index]) begin
                    if (errors < 20)
                        $display("MISMATCH filter=%0d y=%0d x=%0d RTL=%0d expected=%0d",
                            f, y, x, patch_outputs[f], expected[output_index]);
                    errors = errors + 1;
                end
            end
        end
    end

    $display("Total outputs checked: %0d", OUTPUT_COUNT);
    $display("Total mismatches: %0d", errors);

    if (errors == 0)
        $display("CONV1 FULL IMAGE TEST PASSED");
    else
        $display("CONV1 FULL IMAGE TEST FAILED");

    $finish;
end

endmodule
