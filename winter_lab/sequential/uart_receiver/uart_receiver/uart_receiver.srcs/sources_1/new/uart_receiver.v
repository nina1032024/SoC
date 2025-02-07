`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/02/05 17:00:41
// Design Name: 
// Module Name: uart_receiver
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
`define IDLE 0
`define RECEIVE 1

module uart_receiver(
    input clk,
    input rst, //high active
    input uart_rx,
    input baud_rate_signal,
    output reg [7:0] data,
    output reg valid_data
    );

    reg state, next_state;
    reg [3:0] bit_counter;
    reg [3:0] next_bit_counter;
    reg stop_bit;
    reg next_valid_data;
    reg [7:0] d;

    always@*
        case(state) 
            `IDLE: begin
                if(baud_rate_signal == 1) begin
                    if(uart_rx == 0) begin
                        next_state = `RECEIVE;
                    end else begin
                        next_state = `IDLE;
                    end
                end else begin
                    next_state = `IDLE;
                end
                next_valid_data = 0;
                next_bit_coutner = 0;
            end
            `RECEIVE: begin
                if(baud_rate_signal == 1) begin
                    if(bit_counter == 8) begin
                        stop_bit = uart_rx;
                        if(stop_bit == 1) begin
                            next_valid_data = 1;
                        end else begin
                            next_valid_data = 0;
                        end
                        next_bit_coutner = 0;
                        next_state = `IDLE;
                    end else begin
                        d[bit_counter] = uart_rx;
                        next_bit_counter = bit_counter +1;
                        next_state = state;
                        next_valid_data = 0;
                    end
                end else begin
                    next_valid_data = 0;
                    next_state = `RECEIVE;
                    next_bit_coutner = bit_counter;
                end
            end
            default: begin
                next_state = `IDLE;
                next_valid_data = 0;
                next_bit_coutner = 0;
            end
        endcase
    
    always@(posedge clk or posedge rst) begin
        if(rst) begin
            state <= `IDLE;
            bit_counter <= 0;
            data <= 0;
            valid_data <= 0;
        end else begin
            state <= next_state;
            bit_counter <= next_bit_counter;
            data <= d;
            valid_data <= next_valid_data;
        end
    end

endmodule

