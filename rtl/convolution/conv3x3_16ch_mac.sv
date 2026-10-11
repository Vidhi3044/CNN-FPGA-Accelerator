module conv3x3_16ch_mac (

    input logic signed [7:0] inputs [0:143],

    input logic signed [7:0] weights [0:143],

    input logic signed [31:0] bias,

    output logic signed [31:0] output_value

);

integer i;

logic signed [31:0] accumulator;

always_comb begin

    accumulator = bias;

    for (i = 0; i < 144; i = i + 1) begin

        accumulator = accumulator + inputs[i] * weights[i];

    end

    output_value = accumulator;

end

endmodule