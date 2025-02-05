`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2025/02/05 13:29:50
// Design Name:
// Module Name: test_binary2bcd_double_dabble
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

`define DELAY_1 1

module test_binary2bcd_double_dabble();
    reg [7:0] in_binary;
    wire [15:0] unpacked_bcd;
    wire [7:0] packed_bcd;
    reg clk;
    reg rst;

    integer i;
    integer error_cnt;
    integer total_cnt;
    reg [23:0] answer;

    binary2bcd_double_dabble uut (
                                 .in_binary(in_binary),
                                 .unpacked_bcd(unpacked_bcd),
                                 .packed_bcd(packed_bcd)
                             );

    always #`DELAY_1 clk = ~clk;

    initial
    begin
        clk = 0;
        rst = 1;
        i = 0;
        error_cnt = 0;
        total_cnt = 0;
        answer = 0;

        #`DELAY_1;
        rst = 0;

        for(i = 0; i <= 8'b11111111; i = i+1)
        begin
            in_binary = i;

            #`DELAY_1;
            //autocheck
            total_cnt = total_cnt+1;
            answer = auto_check(.in_binary(in_binary));
            $display("in_binary = %b, packed_bcd = %b, unpacked_bcd = %b",
                     in_binary, packed_bcd, unpacked_bcd);
            $display("ans: in_binary = %b, packed_bcd = %b, unpacked_bcd = %b",
                     in_binary, answer[23:16], answer[15:0]);
            if({packed_bcd, unpacked_bcd} !== answer)
            begin
                $display("wrong");
                error_cnt = error_cnt + 1;
            end
            else
            begin
                $display("correct");
            end
            #`DELAY_1;
        end

        if (error_cnt > 0)
            $display("%d / %d error", error_cnt, total_cnt);
        else
            $display("All testcases passed");
        $display("Testbench completed");
        $finish;
    end

    function [23:0]auto_check;
        input integer in_binary;
        reg [15:0] scratch_pad;

        begin
            scratch_pad = {8'b00000000, in_binary};
            for(integer i = 1; i < 8; i = i + 1)
            begin
                scratch_pad = scratch_pad << 1;
                if (scratch_pad[11:8] > 4'b0100)
                    scratch_pad[11:8] = scratch_pad[11:8] + 4'b0011;
            end
            scratch_pad = scratch_pad << 1;

            auto_check[23:16] = scratch_pad[15:8];
            auto_check[15:0] = {4'b0000, scratch_pad[15:12], 4'b0000, scratch_pad[11:8]};
        end
    endfunction

endmodule
