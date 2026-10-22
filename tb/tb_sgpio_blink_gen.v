`timescale 1ns / 1ps

module tb_sgpio_blink_gen;

    localparam BASE_DIV = 2;

    reg clk;
    reg rst_n;
    reg enable;
    reg [3:0] blink_rate_a;
    reg [3:0] blink_rate_b;

    wire blink_a;
    wire blink_b;

    integer errors;
    time transition_start;
    time transition_end;

    sgpio_blink_gen #(.BASE_DIV(BASE_DIV)) uut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .blink_rate_a(blink_rate_a),
        .blink_rate_b(blink_rate_b),
        .blink_a(blink_a),
        .blink_b(blink_b)
    );

    always #10 clk = ~clk;

    task check_a_half_period;
        input integer expected_cycles;
        begin
            @(posedge blink_a);
            transition_start = $time;
            @(negedge blink_a);
            transition_end = $time;
            if (transition_end - transition_start !== expected_cycles * 20) begin
                errors = errors + 1;
                $display("ERROR: Blink A half-period was %0t ns, expected %0t ns",
                         transition_end - transition_start, expected_cycles * 20);
            end
        end
    endtask

    task check_b_half_period;
        input integer expected_cycles;
        begin
            @(posedge blink_b);
            transition_start = $time;
            @(negedge blink_b);
            transition_end = $time;
            if (transition_end - transition_start !== expected_cycles * 20) begin
                errors = errors + 1;
                $display("ERROR: Blink B half-period was %0t ns, expected %0t ns",
                         transition_end - transition_start, expected_cycles * 20);
            end
        end
    endtask

    initial begin
        $dumpfile("sgpio_blink_gen.vcd");
        $dumpvars(0, uut);

        errors = 0;
        clk = 1'b0;
        rst_n = 1'b0;
        enable = 1'b0;
        blink_rate_a = 4'd0;
        blink_rate_b = 4'd1;

        #1;
        if (blink_a !== 1'b0 || blink_b !== 1'b0) begin
            errors = errors + 1;
            $display("ERROR: Outputs were not reset low");
        end

        #19 rst_n = 1'b1;
        #20 enable = 1'b1;

        fork
            check_a_half_period(2);
            check_b_half_period(4);
        join

        enable = 1'b0;
        #1;
        if (blink_a !== 1'b0 || blink_b !== 1'b0) begin
            errors = errors + 1;
            $display("ERROR: Outputs were not cleared when disabled");
        end

        if (errors == 0)
            $display("TEST PASSED");
        else
            $display("TEST FAILED with %0d errors", errors);

        $finish;
    end

endmodule