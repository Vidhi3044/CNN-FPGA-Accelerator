module conv3x3_16ch_mac_array (

    input signed [7:0] inputs [0:143],

    input signed [7:0] weights [0:143],

    input signed [31:0] bias,

    output logic signed [31:0] output_value

);

integer i;

logic signed [31:0] sum;

always_comb begin

    sum = bias;

    for (i = 0; i < 144; i = i + 1) begin
        sum = sum + inputs[i] * weights[i];
    end

    output_value = sum;

end

endmodule