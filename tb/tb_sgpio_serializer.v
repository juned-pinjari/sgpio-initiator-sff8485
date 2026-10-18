`timescale 1ns/1ps

module tb_sgpio_serializer;

    localparam NUM_DRIVES = 4;

    reg                   rst_n;
    reg                   stream_active;
    reg [2:0]             drive_idx;
    reg [1:0]             bit_idx;
    reg [NUM_DRIVES-1:0]  act_data;
    reg [NUM_DRIVES-1:0]  loc_data;
    reg [NUM_DRIVES-1:0]  err_data;
    wire                  sdata_out;
    integer               failures;

    sgpio_serializer #(
        .NUM_DRIVES(NUM_DRIVES)
    ) dut (
        .rst_n(rst_n),
        .stream_active(stream_active),
        .drive_idx(drive_idx),
        .bit_idx(bit_idx),
        .act_data(act_data),
        .loc_data(loc_data),
        .err_data(err_data),
        .sdata_out(sdata_out)
    );

    task check_output;
        input [2:0] expected_drive;
        input [1:0] expected_bit;
        input       expected_data;
        begin
            drive_idx = expected_drive;
            bit_idx = expected_bit;
            #1;
            if (sdata_out !== expected_data) begin
                $display("FAIL: drive=%0d bit=%0d expected=%b got=%b",
                         expected_drive, expected_bit, expected_data, sdata_out);
                failures = failures + 1;
            end
        end
    endtask

    initial begin
        failures = 0;
        rst_n = 1'b0;
        stream_active = 1'b0;
        drive_idx = 3'd0;
        bit_idx = 2'd0;
        act_data = 4'b0101;
        loc_data = 4'b1010;
        err_data = 4'b1100;
        #1;

        $dumpfile("sgpio_serializer.vcd");
        $dumpvars(0, tb_sgpio_serializer);

        if (sdata_out !== 1'b1) begin
            $display("FAIL: idle output expected=1 got=%b", sdata_out);
            failures = failures + 1;
        end

        rst_n = 1'b1;
        stream_active = 1'b1;
        check_output(3'd0, 2'd0, act_data[0]);
        check_output(3'd1, 2'd0, act_data[1]);
        check_output(3'd2, 2'd0, act_data[2]);
        check_output(3'd3, 2'd0, act_data[3]);
        check_output(3'd0, 2'd1, loc_data[0]);
        check_output(3'd1, 2'd1, loc_data[1]);
        check_output(3'd2, 2'd1, loc_data[2]);
        check_output(3'd3, 2'd1, loc_data[3]);
        check_output(3'd0, 2'd2, err_data[0]);
        check_output(3'd1, 2'd2, err_data[1]);
        check_output(3'd2, 2'd2, err_data[2]);
        check_output(3'd3, 2'd2, err_data[3]);

        check_output(3'd4, 2'd0, 1'b1);
        check_output(3'd7, 2'd2, 1'b1);
        check_output(3'd0, 2'd3, 1'b1);

        rst_n = 1'b0;
        check_output(3'd0, 2'd0, 1'b1);

        if (failures == 0)
            $display("PASS: sgpio_serializer");
        else
            $display("FAIL: sgpio_serializer (%0d failures)", failures);

        $finish;
    end

endmodule