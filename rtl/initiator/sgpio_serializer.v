module sgpio_serializer #(
    parameter NUM_DRIVES = 4
) (
    input  wire                  rst_n,
    input  wire                  stream_active,  
    input  wire [2:0]            drive_idx,      
    input  wire [1:0]            bit_idx,        

    input  wire [NUM_DRIVES-1:0] act_data,
    input  wire [NUM_DRIVES-1:0] loc_data,      
    input  wire [NUM_DRIVES-1:0] err_data,

    output reg                   sdata_out
);

always @* begin
    // SDataOut is released high while idle, during reset, and in padding slots.
    sdata_out = 1'b1;

    if (rst_n && stream_active && (drive_idx < NUM_DRIVES)) begin
        case (bit_idx)
            2'd0: sdata_out = act_data[drive_idx];
            2'd1: sdata_out = loc_data[drive_idx];
            2'd2: sdata_out = err_data[drive_idx];
            default: sdata_out = 1'b1;
        endcase
    end
end

endmodule