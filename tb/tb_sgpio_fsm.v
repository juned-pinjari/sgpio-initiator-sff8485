`timescale 1ns/1ps

module tb_sgpio_fsm;

    reg         clk;
    reg         rst_n;
    reg         enable;
    reg  [3:0]  vendor_bits;

    wire        sclk_out;
    wire        sclk_rise;
    wire        sclk_fall;
    wire        sload_out;
    wire [2:0]  drive_idx;
    wire [1:0]  bit_idx;
    wire        stream_active;
    wire        frame_done;

    integer errors;
    integer i;

    sgpio_clk_gen #(
        .CLK_DIV(4)
    ) u_clk_gen (
        .clk      (clk),
        .rst_n    (rst_n),
        .enable   (enable),
        .sclk_out (sclk_out),
        .sclk_rise(sclk_rise),
        .sclk_fall(sclk_fall)
    );

    sgpio_fsm #(
        .NUM_DRIVES(4)
    ) u_fsm (
        .clk          (clk),
        .rst_n        (rst_n),
        .enable       (enable),
        .sclk_rise    (sclk_rise),
        .vendor_bits  (vendor_bits),
        .sload_out    (sload_out),
        .drive_idx    (drive_idx),
        .bit_idx      (bit_idx),
        .stream_active(stream_active),
        .frame_done   (frame_done)
    );

    always #5 clk = ~clk;

    task wait_sclk_rise;
        begin
            @(posedge sclk_rise);
            #1;
        end
    endtask

    task consume_sclk_rise;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    task check_value;
        input actual;
        input expected;
        input [8*48-1:0] message;
        begin
            if (actual !== expected) begin
                $display("ERROR: %0s (actual=%b expected=%b) time=%0t",
                         message, actual, expected, $time);
                errors = errors + 1;
            end
        end
    endtask

    task check_drive_index;
        input [2:0] actual;
        input integer expected;
        begin
            if (actual !== expected[2:0]) begin
                $display("ERROR: Unexpected drive index (actual=%0d expected=%0d) time=%0t",
                         actual, expected, $time);
                errors = errors + 1;
            end
        end
    endtask

    task check_bit_index;
        input [1:0] actual;
        input integer expected;
        begin
            if (actual !== expected[1:0]) begin
                $display("ERROR: Unexpected bit index (actual=%0d expected=%0d) time=%0t",
                         actual, expected, $time);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("sgpio_fsm.vcd");
        $dumpvars(0, tb_sgpio_fsm);

        clk         = 1'b0;
        rst_n       = 1'b0;
        enable      = 1'b0;
        vendor_bits = 4'b1010;
        errors      = 0;

        // Reset check
        repeat (2) @(posedge clk);
        #1;
        check_value(sload_out, 1'b1, "SLoad must be high during reset");
        check_value(stream_active, 1'b0, "stream_active must be low during reset");

        // Idle check
        rst_n = 1'b1;
        repeat (2) @(posedge clk);
        #1;
        check_value(sload_out, 1'b0, "SLoad must be low while idle");
        check_value(stream_active, 1'b0, "stream_active must be low while idle");

        // Start frame
        enable = 1'b1;
        wait_sclk_rise();
        consume_sclk_rise();
        check_value(stream_active, 1'b1, "stream_active must assert at frame start");

        // Data bits 0..10
        for (i = 0; i < 11; i = i + 1) begin
            wait_sclk_rise();
            check_value(sload_out, 1'b0, "SLoad must be low for data bits 0..10");
            check_drive_index(drive_idx, i / 3);
            check_bit_index(bit_idx, i % 3);
            consume_sclk_rise();
        end

        // Last bit of drive 3 (OD3.2): SLoad asserts
        wait_sclk_rise();
        check_value(sload_out, 1'b1, "SLoad must assert on OD3.2");
        check_drive_index(drive_idx, 3);
        check_bit_index(bit_idx, 2);
        consume_sclk_rise();

        // 4 vendor bits
        for (i = 0; i < 4; i = i + 1) begin
            wait_sclk_rise();
            check_value(sload_out, vendor_bits[i], "Unexpected vendor SLoad bit");
            consume_sclk_rise();
            if (i < 3)
                check_value(frame_done, 1'b0, "frame_done asserted too early");
            else
                check_value(frame_done, 1'b1, "frame_done must pulse after L3");
        end

        @(posedge clk);
        #1;
        check_value(frame_done, 1'b0, "frame_done must be one cycle wide");

        if (errors == 0)
            $display("PASS: sgpio_fsm framing checks completed successfully.");
        else
            $display("FAIL: sgpio_fsm completed with %0d error(s).", errors);

        $finish;
    end

endmodule
