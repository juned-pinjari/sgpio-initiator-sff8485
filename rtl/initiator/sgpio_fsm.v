module sgpio_fsm #(
    parameter NUM_DRIVES = 4
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       enable,
    input  wire       sclk_rise,
    input  wire [3:0] vendor_bits,

    output reg        sload_out,
    output reg  [2:0] drive_idx,
    output reg  [1:0] bit_idx,
    output reg        stream_active,
    output reg        frame_done
);

    // Minimum 4 drives (12 bits) even if NUM_DRIVES < 4
    localparam integer TOTAL_DRIVES = (NUM_DRIVES < 4) ? 4 : NUM_DRIVES;

    localparam [1:0] STATE_RESET  = 2'd0;
    localparam [1:0] STATE_IDLE   = 2'd1;
    localparam [1:0] STATE_DATA   = 2'd2;
    localparam [1:0] STATE_VENDOR = 2'd3;

    reg [1:0] state;
    reg [1:0] vendor_idx;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= STATE_RESET;
            drive_idx  <= 3'd0;
            bit_idx    <= 2'd0;
            vendor_idx <= 2'd0;
            frame_done <= 1'b0;
        end else begin
            frame_done <= 1'b0;

            case (state)
                STATE_RESET: begin
                    state      <= STATE_IDLE;
                    drive_idx  <= 3'd0;
                    bit_idx    <= 2'd0;
                    vendor_idx <= 2'd0;
                end

                STATE_IDLE: begin
                    drive_idx  <= 3'd0;
                    bit_idx    <= 2'd0;
                    vendor_idx <= 2'd0;
                    if (enable && sclk_rise)
                        state <= STATE_DATA;
                end

                STATE_DATA: begin
                    if (sclk_rise) begin
                        if ((drive_idx == TOTAL_DRIVES - 1) && (bit_idx == 2)) begin
                            state      <= STATE_VENDOR;
                            vendor_idx <= 2'd0;
                        end else if (bit_idx == 2) begin
                            bit_idx   <= 2'd0;
                            drive_idx <= drive_idx + 1'b1;
                        end else begin
                            bit_idx <= bit_idx + 1'b1;
                        end
                    end
                end

                STATE_VENDOR: begin
                    if (sclk_rise) begin
                        if (vendor_idx == 2'd3) begin
                            frame_done <= 1'b1;
                            drive_idx  <= 3'd0;
                            bit_idx    <= 2'd0;
                            vendor_idx <= 2'd0;
                            if (enable)
                                state <= STATE_DATA;
                            else
                                state <= STATE_IDLE;
                        end else begin
                            vendor_idx <= vendor_idx + 1'b1;
                        end
                    end
                end

                default: begin
                    state      <= STATE_RESET;
                    drive_idx  <= 3'd0;
                    bit_idx    <= 2'd0;
                    vendor_idx <= 2'd0;
                end
            endcase
        end
    end

    always @* begin
        sload_out     = 1'b0;
        stream_active = 1'b0;

        if (!rst_n || (state == STATE_RESET)) begin
            sload_out = 1'b1;
        end else begin
            case (state)
                STATE_DATA: begin
                    stream_active = 1'b1;
                    if ((drive_idx == TOTAL_DRIVES - 1) && (bit_idx == 2))
                        sload_out = 1'b1;
                end

                STATE_VENDOR: begin
                    stream_active = 1'b1;
                    sload_out = vendor_bits[vendor_idx];
                end

                default: begin
                    sload_out = 1'b0;
                end
            endcase
        end
    end

endmodule