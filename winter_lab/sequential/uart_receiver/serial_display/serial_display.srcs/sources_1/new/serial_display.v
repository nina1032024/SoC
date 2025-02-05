`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/01/08 16:49:26
// Design Name: 
// Module Name: serial_display
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

`define SS_0 8'b00000011
`define SS_1 8'b10011111
`define SS_2 8'b00100101
`define SS_3 8'b00001101
`define SS_4 8'b10011001
`define SS_5 8'b01001001
`define SS_6 8'b01000001
`define SS_7 8'b00011111
`define SS_8 8'b00000001
`define SS_9 8'b00001001
`define SS_A 8'b00010001
`define SS_B 8'b11000001
`define SS_C 8'b01100011
`define SS_D 8'b10000101
`define SS_E 8'b01100001
`define SS_F 8'b01110001

`define num_0 8'd48
`define num_9 8'd57
`define sym_A 8'd65
`define sym_F 8'd70

module serial_display(
    input wire [7:0] ascii_data,       
    input wire data_valid,           
    output reg [7:0] seven_segment_data, 
    output reg [3:0] seven_segment_enable
);
    reg [7:0] ascii_data_local;
  
    reg [4:0] data_index;
    always @(*) begin
        case (data_index)                      //ASCII 
            4'd0: seven_segment_data = `SS_0; //48 
            4'd1: seven_segment_data = `SS_1; //49 
            4'd2: seven_segment_data = `SS_2; //50
            4'd3: seven_segment_data = `SS_3; //51
            4'd4: seven_segment_data = `SS_4; //52
            4'd5: seven_segment_data = `SS_5; //53
            4'd6: seven_segment_data = `SS_6; //54
            4'd7: seven_segment_data = `SS_7; //55
            4'd8: seven_segment_data = `SS_8; //56
            4'd9: seven_segment_data = `SS_9; //57
            4'd10: seven_segment_data = `SS_A; //65
            4'd11: seven_segment_data = `SS_B; //66
            4'd12: seven_segment_data = `SS_C; //67
            4'd13: seven_segment_data = `SS_D; //68
            4'd14: seven_segment_data = `SS_E; //69
            4'd15: seven_segment_data = `SS_F; //70
            default: seven_segment_data = 8'b0000_0000; 
        endcase
    end

    always @(*) begin
        //0~9
        if (ascii_data_local >= `num_0 && ascii_data_local <= `num_9) begin //use symbol to define constant
            data_index = ascii_data_local - 8'd48; 
        //A~F
        end else if (ascii_data_local >= `sym_A && ascii_data_local <= `sym_F) begin
            data_index = ascii_data_local - 8'd55; 
        //others
        end else begin
            data_index = 4'd16; 
        end
    end

    always @(posedge data_valid) begin
        ascii_data_local <= ascii_data; 
        seven_segment_enable <= 4'b1110; 
    end

endmodule
