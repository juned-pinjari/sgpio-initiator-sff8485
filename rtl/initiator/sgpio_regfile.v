module sgpio_regfile #(
    parameter NUM_DRIVES = 4          // Valid: 1 to 8 (default 4)
)(
    input  wire        clk,
    input  wire        rst_n,

    // Host processor bus interface
    input  wire [1:0]  addr,          // 2'b00: CFG[0], 2'b01: CFG[1], 2'b10: TX[0], 2'b11: TX[1]
    input  wire [31:0] wr_data,       // 32-bit write data
    input  wire        wr_en,         // Write enable strobe
    output reg  [31:0] rd_data,       // 32-bit read data

    // Control outputs to FSM and Clock Generator
    output wire        gpio_enable,   // CFG[0] bit 4
    output wire [3:0]  vendor_bits,   // CFG[0] bits 27:24

    // Timing configuration outputs to Blinkers & Activity Stretcher
    output wire [3:0]  blink_rate_a,
    output wire [3:0]  blink_rate_b,
    output wire [3:0]  max_act_on,
    output wire [3:0]  force_act_off,
    output wire [3:0]  stretch_act_on,
    output wire [3:0]  stretch_act_off,

    // Per-drive mode codes to LED generators (Drives 0 to 3)
    output wire [2:0]  drive0_act, drive0_err,
    output wire [1:0]  drive0_loc,
    output wire [2:0]  drive1_act, drive1_err,
    output wire [1:0]  drive1_loc,
    output wire [2:0]  drive2_act, drive2_err,
    output wire [1:0]  drive2_loc,
    output wire [2:0]  drive3_act, drive3_err,
    output wire [1:0]  drive3_loc
);

    reg        gpio_enable_reg;
    reg [3:0]  vendor_bits_reg;
    reg [3:0]  blink_rate_a_reg;
    reg [3:0]  blink_rate_b_reg;
    reg [3:0]  max_act_on_reg;
    reg [3:0]  force_act_off_reg;
    reg [3:0]  stretch_act_on_reg;
    reg [3:0]  stretch_act_off_reg;
    reg [31:0] tx0_reg;
    reg [31:0] tx1_reg;

    assign gpio_enable    = gpio_enable_reg;
    assign vendor_bits    = vendor_bits_reg;
    assign blink_rate_a  = blink_rate_a_reg;
    assign blink_rate_b  = blink_rate_b_reg;
    assign max_act_on    = max_act_on_reg;
    assign force_act_off = force_act_off_reg;
    assign stretch_act_on  = stretch_act_on_reg;
    assign stretch_act_off = stretch_act_off_reg;

    assign drive0_act = tx0_reg[31:29];
    assign drive0_loc = tx0_reg[28:27];
    assign drive0_err = tx0_reg[26:24];
    assign drive1_act = tx0_reg[23:21];
    assign drive1_loc = tx0_reg[20:19];
    assign drive1_err = tx0_reg[18:16];
    assign drive2_act = tx0_reg[15:13];
    assign drive2_loc = tx0_reg[12:11];
    assign drive2_err = tx0_reg[10:8];
    assign drive3_act = tx0_reg[7:5];
    assign drive3_loc = tx0_reg[4:3];
    assign drive3_err = tx0_reg[2:0];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gpio_enable_reg   <= 1'b0;
            vendor_bits_reg   <= 4'h0;
            blink_rate_a_reg  <= 4'h0;
            blink_rate_b_reg  <= 4'h0;
            max_act_on_reg    <= 4'h2;
            force_act_off_reg <= 4'h1;
            stretch_act_on_reg  <= 4'h0;
            stretch_act_off_reg <= 4'h0;
            tx0_reg           <= 32'hA0A0A0A0;
            tx1_reg           <= 32'hA0A0A0A0;
        end else if (wr_en) begin
            case (addr)
                2'b00: begin
                    gpio_enable_reg <= wr_data[4];
                    vendor_bits_reg <= wr_data[27:24];
                end

                2'b01: begin
                    blink_rate_a_reg    <= wr_data[3:0];
                    blink_rate_b_reg    <= wr_data[7:4];
                    max_act_on_reg      <= wr_data[11:8];
                    force_act_off_reg   <= wr_data[15:12];
                    stretch_act_on_reg <= wr_data[19:16];
                    stretch_act_off_reg <= wr_data[23:20];
                end

                2'b10: tx0_reg <= wr_data;
                2'b11: tx1_reg <= wr_data;
                default: begin
                end
            endcase
        end
    end

    always @* begin
        case (addr)
            2'b00: rd_data = {
                4'b0000, vendor_bits_reg, 4'b0000, NUM_DRIVES[7:0],
                4'b0000, 3'd2, gpio_enable_reg, 4'b0000
            };
            2'b01: rd_data = {
                8'b0000_0000, stretch_act_off_reg, stretch_act_on_reg,
                force_act_off_reg, max_act_on_reg,
                blink_rate_b_reg, blink_rate_a_reg
            };
            2'b10: rd_data = tx0_reg;
            2'b11: rd_data = tx1_reg;
            default: rd_data = 32'b0;
        endcase
    end

endmodule
