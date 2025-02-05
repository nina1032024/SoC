`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2025/01/23 15:34:49
// Design Name:
// Module Name: binary2bcd_div
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


module binary2bcd_div(
        input wire[13:0] a,
        output [15:0] packed_bcd
    );

    reg [3:0] digit_1;
    reg [3:0] digit_2;
    reg [3:0] digit_3;
    reg [3:0] digit_4;

    reg [13:0] a_tmp;

    always @*
    begin
        digit_1 = a-10*(a/10);
        a_tmp = a/10;

        digit_2 = a_tmp-10*(a_tmp/10);
        a_tmp = a_tmp/10;

        digit_3 = a_tmp-10*(a_tmp/10);
        a_tmp = a_tmp/10;

        digit_4 = a_tmp-10*(a_tmp/10);
    end

    assign packed_bcd = {digit_4, digit_3, digit_2, digit_1};

endmodule
