`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/01/23 15:35:05
// Design Name: 
// Module Name: test_binary2bcd_div
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

module test_binary2bcd_div();
    reg [13:0] a;
    wire [15:0] packed_bcd;
    reg clk;
    reg rst;

    integer i;
    integer error_cnt;
    integer total_cnt;
    reg [15:0] answer;

    binary2bcd_div u0(
        .a(a),
        .packed_bcd(packed_bcd)
    );

    always #`DELAY_1 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        a = 0;
        i = 0;
        error_cnt = 0;
        total_cnt = 0;
        answer = 0;

        #`DELAY_1;
        rst = 0;

        for(i = 0; i < 9999; i = i + 1) begin
            a = i;
            #`DELAY_1;
            //autocheck
            total_cnt = total_cnt + 1;
            answer = auto_check(.a(a));
            $display("in_binary = %b, bcd = %b",
                    a, packed_bcd);
            $display("ans: bcd = %b",
                    answer);
            if(packed_bcd !== answer) begin
                $display("wrong");
                error_cnt = error_cnt + 1;
            end else begin
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

    function [15:0]auto_check;
        input integer a;
        reg [3:0] digit_1;
        reg [3:0] digit_2;
        reg [3:0] digit_3;
        reg [3:0] digit_4;

        begin
            digit_1 = a-10*(a/10);
            a = a/10;

            digit_2 = a-10*(a/10);
            a = a/10;

            digit_3 = a-10*(a/10);
            a = a/10;

            digit_4 = a-10*(a/10); 

            auto_check[15:0] = {digit_4, digit_3, digit_2, digit_1};
        end
    endfunction
endmodule
