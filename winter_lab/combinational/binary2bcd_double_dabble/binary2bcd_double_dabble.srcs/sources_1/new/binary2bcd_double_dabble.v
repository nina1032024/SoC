`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2025/02/05 13:29:30
// Design Name:
// Module Name: binary2bcd_double_dabble
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


module binary2bcd_double_dabble(
    input wire[7:0] in_binary,
    output wire [15:0] unpacked_bcd,
    output wire [7:0] packed_bcd
);

reg [15:0] scratch_pad;

always @* begin
    scratch_pad = {8'b00000000, in_binary};
    for(integer i = 1; i < 8; i = i + 1) begin
        scratch_pad = scratch_pad << 1;
        if (scratch_pad[11:8] > 4'b0100)
		    scratch_pad[11:8] = scratch_pad[11:8] + 4'b0011;
    end
    scratch_pad = scratch_pad << 1;
end

assign packed_bcd =  scratch_pad[15:8];
assign unpacked_bcd = {4'b0000, scratch_pad[15:12], 4'b0000, scratch_pad[11:8]};

endmodule 

