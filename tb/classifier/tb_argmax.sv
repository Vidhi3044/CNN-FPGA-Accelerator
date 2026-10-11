`timescale 1ns/1ps

module tb_argmax;

localparam CLASS_COUNT = 3;

reg signed [31:0] scores [0:CLASS_COUNT-1];
wire [1:0] class_index;

argmax #(
    .CLASS_COUNT(CLASS_COUNT)
) uut (
    .scores(scores),
    .class_index(class_index)
);

initial begin

    $dumpfile("simulations/classifier/argmax.vcd");
    $dumpvars(0, tb_argmax);

    scores[0] = 32'sd120;
    scores[1] = 32'sd350;
    scores[2] = 32'sd80;

    #10;

    $display("Test 1: Green %0d, Red %0d, Yellow %0d, Class %0d",
             scores[0], scores[1], scores[2], class_index);

    scores[0] = 32'sd500;
    scores[1] = 32'sd100;
    scores[2] = 32'sd250;

    #10;

    $display("Test 2: Green %0d, Red %0d, Yellow %0d, Class %0d",
             scores[0], scores[1], scores[2], class_index);

    scores[0] = 32'sd50;
    scores[1] = 32'sd200;
    scores[2] = 32'sd700;

    #10;

    $display("Test 3: Green %0d, Red %0d, Yellow %0d, Class %0d",
             scores[0], scores[1], scores[2], class_index);

    scores[0] = -32'sd100;
    scores[1] = -32'sd50;
    scores[2] = -32'sd200;

    #10;

    $display("Test 4: Green %0d, Red %0d, Yellow %0d, Class %0d",
             scores[0], scores[1], scores[2], class_index);

    $finish;

end

endmodule