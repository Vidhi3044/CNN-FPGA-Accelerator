`timescale 1ns/1ps

module argmax #(
    parameter CLASS_COUNT = 3
)(
    input signed [31:0] scores [0:CLASS_COUNT-1],
    output logic [1:0] class_index
);

integer i;
logic signed [31:0] max_value;

always @* begin

    max_value = scores[0];
    class_index = 2'd0;

    for (i = 1; i < CLASS_COUNT; i = i + 1) begin
        if (scores[i] > max_value) begin
            max_value = scores[i];
            class_index = i[1:0];
        end
    end

end

endmodule