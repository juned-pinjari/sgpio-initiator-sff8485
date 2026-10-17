`timescale 1ns / 1ps

module tb_sgpio_clk_gen;

    reg clk;
    reg rst_n;
    reg enable;

    wire sclk_out;
    wire sclk_rise;
    wire sclk_fall;

    sgpio_clk_gen #(.CLK_DIV(8)) uut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .sclk_out(sclk_out),
        .sclk_rise(sclk_rise),
        .sclk_fall(sclk_fall)
    );

    // 50 MHz clock
    always #10 clk = ~clk;

    integer  errors = 0;

    // Procedural strobe checks
    always @(posedge clk) begin
        if (rst_n) begin
            // Strobes must be mutually exclusive
            if (sclk_rise && sclk_fall) begin
                errors = errors + 1;
                $display("ERROR: rise and fall strobes asserted together at time %0t", $time);
            end

            // sclk_rise occurs on transition to high
            if (sclk_rise && !sclk_out) begin
                errors = errors + 1;
                $display("ERROR: rise strobe not aligned with high SClock at time %0t", $time);
            end

            // sclk_fall occurs on transition to low
            if (sclk_fall && sclk_out) begin
                errors = errors + 1;
                $display("ERROR: fall strobe not aligned with low SClock at time %0t", $time);
            end
        end
    end

    initial begin

        $dumpfile("sgpio_clk_gen.vcd");
        $dumpvars(0, tb_sgpio_clk_gen);

        // Initialize signals
        clk = 0;
        rst_n = 0;
        enable = 0;

        // Release reset
        #40 rst_n = 1;

        // Turn on clock
        #20 enable = 1;

        // Let it run for a while
        #400;

        // Turn off clock
        enable = 0;
        #100;
        if (sclk_out !== 1'b0)
        begin
            errors = errors + 1;
            $display("TEST FAILED at %0t with %0d errors", $time, errors);
        end

        // Turn it back on
        enable = 1;
        @(posedge sclk_out);
        if (sclk_out !== 1'b1)
        begin
            errors = errors + 1;
            $display("TEST FAILED at %0t with %0d errors", $time, errors);
        end

        if (errors == 0) $display("TEST PASSED");
        else $display("TEST FAILED with %0d errors", errors);

        $finish;
    end

endmodule
