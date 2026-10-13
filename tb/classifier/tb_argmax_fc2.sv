
`timescale 1ns/1ps

module tb_argmax_fc2;

localparam CLASS_COUNT = 3;

reg signed [31:0] scores [0:CLASS_COUNT-1];
wire [1:0] class_index;

integer errors;

argmax #(
    .CLASS_COUNT(CLASS_COUNT)
) uut (
    .scores(scores),
    .class_index(class_index)
);

initial begin
    errors = 0;

    $dumpfile("simulations/classifier/argmax_fc2.vcd");
    $dumpvars(0, tb_argmax_fc2);

    scores[0] = 32'sd895459;
    scores[1] = -32'sd728125;
    scores[2] = 32'sd55921;

    #10;

    $display("Green score: %0d", scores[0]);
    $display("Red score: %0d", scores[1]);
    $display("Yellow score: %0d", scores[2]);
    $display("Predicted class index: %0d", class_index);

    if (class_index !== 2'd0)
        errors = errors + 1;

    $display("Total mismatches: %0d", errors);

    if (errors == 0)
        $display("FC2 ARGMAX TEST PASSED");
    else
        $display("FC2 ARGMAX TEST FAILED");

    $finish;
end

endmodule
