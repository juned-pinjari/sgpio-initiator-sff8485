module sgpio_clk_gen #(
    parameter CLK_DIV = 500           // Use even values for CLK_DIV
)(
    input  clk,
    input  rst_n,
    input  enable,
    output reg sclk_out,
    output reg sclk_rise,
    output reg sclk_fall
);

    localparam HALF_DIV = CLK_DIV / 2;
    reg [23:0] count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sclk_out  <= 1'b1;
            sclk_rise <= 1'b0;
            sclk_fall <= 1'b0;
            count     <= 0;
        end else if (enable || sclk_out) begin
            sclk_rise <= 1'b0;
            sclk_fall <= 1'b0;
            if (count == HALF_DIV - 1) begin
                count     <= 0;
                sclk_out  <= ~sclk_out;
                sclk_rise <= ~sclk_out;
                sclk_fall <=  sclk_out;
            end else begin
                count <= count + 1;
            end
        end else begin
            sclk_out  <= 1'b0;
            sclk_rise <= 1'b0;
            sclk_fall <= 1'b0;
            count     <= 0;
        end
    end

endmodule
