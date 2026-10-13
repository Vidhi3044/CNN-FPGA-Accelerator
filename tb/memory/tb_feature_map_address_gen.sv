
`timescale 1ns/1ps

module tb_feature_map_address_gen;

logic clk = 1'b0;
logic reset = 1'b0;
logic start = 1'b0;

logic [15:0] addr0;
logic [15:0] addr1;
logic [15:0] addr2;
logic [15:0] addr3;
logic [15:0] addr4;
logic [15:0] addr5;
logic [15:0] addr6;
logic [15:0] addr7;
logic [15:0] addr8;

logic window_valid;
logic busy;
logic done;

integer count;
integer expected_base;

always #5 clk = ~clk;

feature_map_address_gen #(
    .MAP_WIDTH(5),
    .MAP_HEIGHT(4),
    .ADDR_WIDTH(16)
) dut (
    .clk(clk),
    .reset(reset),
    .start(start),
    .addr0(addr0),
    .addr1(addr1),
    .addr2(addr2),
    .addr3(addr3),
    .addr4(addr4),
    .addr5(addr5),
    .addr6(addr6),
    .addr7(addr7),
    .addr8(addr8),
    .window_valid(window_valid),
    .busy(busy),
    .done(done)
);

initial begin
    count = 0;

    reset = 1'b1;
    repeat (2) @(posedge clk);

    @(negedge clk);
    reset = 1'b0;
    start = 1'b1;

    @(posedge clk);
    #1;
    start = 1'b0;

    while (count < 6) begin
        if (window_valid !== 1'b1)
            $fatal(1, "Window valid signal incorrect");

        case (count)
            0: expected_base = 0;
            1: expected_base = 1;
            2: expected_base = 2;
            3: expected_base = 5;
            4: expected_base = 6;
            5: expected_base = 7;
        endcase

        if (addr0 !== expected_base ||
            addr1 !== expected_base + 1 ||
            addr2 !== expected_base + 2 ||
            addr3 !== expected_base + 5 ||
            addr4 !== expected_base + 6 ||
            addr5 !== expected_base + 7 ||
            addr6 !== expected_base + 10 ||
            addr7 !== expected_base + 11 ||
            addr8 !== expected_base + 12)
            $fatal(1, "Incorrect window addresses");

        count = count + 1;

        if (count < 6) begin
            @(posedge clk);
            #1;
        end
    end

    @(posedge clk);
    #1;

    if (busy !== 1'b0 || done !== 1'b1)
        $fatal(1, "Completion signals incorrect");

    $display("Feature map address generator test passed");
    $finish;
end

endmodule
