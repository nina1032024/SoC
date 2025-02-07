`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/02/07 11:59:50
// Design Name: 
// Module Name: baud_rate_generator
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


`define ZERO 0
`define ONE 1

`define BAUD_RATE_NUMBER 20

module baud_rate_generator(
        input clk,
        input rst,
        output reg baud_rate_signal,
        output reg [13:0] counter
    );

    reg state, next_state;
    reg nxt_baud_rate_signal;
    //reg [13:0] counter;
    reg [13:0] next_counter;

    always@*
    case(state)
        `ZERO:
        begin
            if (counter == 1)
            begin
                next_counter = counter-1;
                next_state = `ONE;
            end
            else
            begin
                next_counter = counter-1;
                next_state = `ZERO;
            end
            nxt_baud_rate_signal = 0;
        end
        `ONE:
        begin
            next_counter = `BAUD_RATE_NUMBER-1;
            next_state = `ZERO;
            nxt_baud_rate_signal = 1;
        end
        default:
        begin
            next_counter = 0;
            next_state = `ZERO;
            nxt_baud_rate_signal = 0;
        end
    endcase

    always @(posedge clk or posedge rst)
        if(rst)
        begin
            state <= `ZERO;
            counter <= `BAUD_RATE_NUMBER - 1;
            baud_rate_signal <= 0;
        end else begin
            state <= next_state;
            counter <= next_counter;
            baud_rate_signal <= nxt_baud_rate_signal;
        end
endmodule
