`timescale 1ns/1ps

module tb_sgpio_regfile;

    reg clk;
    reg rst_n;
    reg [1:0] addr;
    reg [31:0] wr_data;
    reg wr_en;
    wire [31:0] rd_data;
    wire gpio_enable;
    wire [3:0] vendor_bits;
    wire [3:0] blink_rate_a, blink_rate_b, max_act_on, force_act_off;
    wire [3:0] stretch_act_on, stretch_act_off;
    wire [2:0] drive0_act, drive0_err;
    wire [1:0] drive0_loc;
    wire [2:0] drive1_act, drive1_err;
    wire [1:0] drive1_loc;
    wire [2:0] drive2_act, drive2_err;
    wire [1:0] drive2_loc;
    wire [2:0] drive3_act, drive3_err;
    wire [1:0] drive3_loc;
    integer failures;

    sgpio_regfile dut (
        .clk(clk), .rst_n(rst_n), .addr(addr), .wr_data(wr_data),
        .wr_en(wr_en), .rd_data(rd_data),
        .gpio_enable(gpio_enable), .vendor_bits(vendor_bits),
        .blink_rate_a(blink_rate_a), .blink_rate_b(blink_rate_b),
        .max_act_on(max_act_on), .force_act_off(force_act_off),
        .stretch_act_on(stretch_act_on), .stretch_act_off(stretch_act_off),
        .drive0_act(drive0_act), .drive0_loc(drive0_loc), .drive0_err(drive0_err),
        .drive1_act(drive1_act), .drive1_loc(drive1_loc), .drive1_err(drive1_err),
        .drive2_act(drive2_act), .drive2_loc(drive2_loc), .drive2_err(drive2_err),
        .drive3_act(drive3_act), .drive3_loc(drive3_loc), .drive3_err(drive3_err)
    );

    always #5 clk = ~clk;

    task write_register;
        input [1:0] write_addr;
        input [31:0] write_data;
        begin
            @(negedge clk);
            addr = write_addr;
            wr_data = write_data;
            wr_en = 1'b1;
            @(negedge clk);
            wr_en = 1'b0;
        end
    endtask

    task check_read;
        input [1:0] read_addr;
        input [31:0] expected;
        begin
            addr = read_addr;
            #1;
            if (rd_data !== expected) begin
                $display("FAIL: addr=%0d expected=%h got=%h",
                         read_addr, expected, rd_data);
                failures = failures + 1;
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        addr = 2'b00;
        wr_data = 32'b0;
        wr_en = 1'b0;
        failures = 0;

        $dumpfile("sgpio_regfile.vcd");
        $dumpvars(0, tb_sgpio_regfile);

        #1;
        check_read(2'b00, 32'h00004040);
        check_read(2'b01, 32'h00001200);
        check_read(2'b10, 32'hA0A0A0A0);

        rst_n = 1'b1;
        write_register(2'b00, 32'h0F000010);
        check_read(2'b00, 32'h0F004050);
        write_register(2'b01, 32'h00654321);
        check_read(2'b01, 32'h00654321);
        write_register(2'b10, 32'h12345678);
        check_read(2'b10, 32'h12345678);

        if (drive0_act !== 3'b000 ||
            drive0_loc !== 2'b10  ||
            drive0_err !== 3'b010 ||
            drive1_act !== 3'b001 ||
            drive1_loc !== 2'b10  ||
            drive1_err !== 3'b100 ||
            drive2_act !== 3'b010 ||
            drive2_loc !== 2'b10  ||
            drive2_err !== 3'b110 ||
            drive3_act !== 3'b011 ||
            drive3_loc !== 2'b11  ||
            drive3_err !== 3'b000) begin
            $display("FAIL: TX drive byte mapping is incorrect");
            failures = failures + 1;
        end

        if (failures == 0)
            $display("PASS: sgpio_regfile");
        else
            $display("FAIL: sgpio_regfile (%0d failures)", failures);
        $finish;
    end

endmodule
