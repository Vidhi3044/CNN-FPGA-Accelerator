module conv1_filter_bank #(
    parameter FILTER_COUNT = 16
)(
    input signed [7:0] inputs [0:26],
    input signed [7:0] weights [0:FILTER_COUNT-1][0:26],
    input signed [31:0] biases [0:FILTER_COUNT-1],
    output signed [31:0] outputs [0:FILTER_COUNT-1]
);

genvar filter_index;

generate
    for (filter_index = 0; filter_index < FILTER_COUNT; filter_index = filter_index + 1) begin : filter_instances

        conv3x3_rgb_mac filter_mac (
            .input_0(inputs[0]),
            .input_1(inputs[1]),
            .input_2(inputs[2]),
            .input_3(inputs[3]),
            .input_4(inputs[4]),
            .input_5(inputs[5]),
            .input_6(inputs[6]),
            .input_7(inputs[7]),
            .input_8(inputs[8]),

            .input_9(inputs[9]),
            .input_10(inputs[10]),
            .input_11(inputs[11]),
            .input_12(inputs[12]),
            .input_13(inputs[13]),
            .input_14(inputs[14]),
            .input_15(inputs[15]),
            .input_16(inputs[16]),
            .input_17(inputs[17]),

            .input_18(inputs[18]),
            .input_19(inputs[19]),
            .input_20(inputs[20]),
            .input_21(inputs[21]),
            .input_22(inputs[22]),
            .input_23(inputs[23]),
            .input_24(inputs[24]),
            .input_25(inputs[25]),
            .input_26(inputs[26]),

            .weight_0(weights[filter_index][0]),
            .weight_1(weights[filter_index][1]),
            .weight_2(weights[filter_index][2]),
            .weight_3(weights[filter_index][3]),
            .weight_4(weights[filter_index][4]),
            .weight_5(weights[filter_index][5]),
            .weight_6(weights[filter_index][6]),
            .weight_7(weights[filter_index][7]),
            .weight_8(weights[filter_index][8]),

            .weight_9(weights[filter_index][9]),
            .weight_10(weights[filter_index][10]),
            .weight_11(weights[filter_index][11]),
            .weight_12(weights[filter_index][12]),
            .weight_13(weights[filter_index][13]),
            .weight_14(weights[filter_index][14]),
            .weight_15(weights[filter_index][15]),
            .weight_16(weights[filter_index][16]),
            .weight_17(weights[filter_index][17]),

            .weight_18(weights[filter_index][18]),
            .weight_19(weights[filter_index][19]),
            .weight_20(weights[filter_index][20]),
            .weight_21(weights[filter_index][21]),
            .weight_22(weights[filter_index][22]),
            .weight_23(weights[filter_index][23]),
            .weight_24(weights[filter_index][24]),
            .weight_25(weights[filter_index][25]),
            .weight_26(weights[filter_index][26]),

            .bias(biases[filter_index]),
            .output_value(outputs[filter_index])
        );

    end
endgenerate

endmodule