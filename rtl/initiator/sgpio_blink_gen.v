module sgpio_blink_gen #(
    parameter BASE_DIV = 3_125_000   // Cycles for (1/16)s at 50 MHz (use 10 in TB)
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       enable,          // gpio_enable from CFG[0]
    input  wire [3:0] blink_rate_a,    // from CFG[1] bits 3:0
    input  wire [3:0] blink_rate_b,    // from CFG[1] bits 7:4
    output reg        blink_a,         // 50% duty cycle square wave A
    output reg        blink_b          // 50% duty cycle square wave B
);

    reg [25:0] count_a;
    reg [25:0] count_b;

    wire [25:0] limit_a = ({1'b0, blink_rate_a} + 5'd1) * BASE_DIV;
    wire [25:0] limit_b = ({1'b0, blink_rate_b} + 5'd1) * BASE_DIV;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_a <= 26'd0;
            blink_a <= 1'b0;
        end else if (!enable) begin
            count_a <= 26'd0;
            blink_a <= 1'b0;
        end else if (count_a >= limit_a - 1'b1) begin
            count_a <= 26'd0;
            blink_a <= ~blink_a;
        end else begin
            count_a <= count_a + 1'b1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_b <= 26'd0;
            blink_b <= 1'b0;
        end else if (!enable) begin
            count_b <= 26'd0;
            blink_b <= 1'b0;
        end else if (count_b >= limit_b - 1'b1) begin
            count_b <= 26'd0;
            blink_b <= ~blink_b;
        end else begin
            count_b <= count_b + 1'b1;
        end
    end

endmodule
