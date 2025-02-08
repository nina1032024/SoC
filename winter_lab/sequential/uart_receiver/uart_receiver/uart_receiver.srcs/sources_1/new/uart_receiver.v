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
// Description: UART Receiver Module
// 
// Dependencies: None
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
    input rst, // High active
    input uart_rx,
    input baud_rate_signal,
    output reg [7:0] data,
    output reg valid_data
    );

    reg state, next_state;
    reg [3:0] bit_counter, next_bit_counter;
    reg stop_bit;
    reg next_valid_data;
    reg [7:0] d, next_d;

    always @* begin
        next_state = state;
        next_valid_data = 0;
        next_bit_counter = bit_counter;
        next_d = d;

        case (state) 
            `IDLE: begin
                if (baud_rate_signal) begin
                    if (uart_rx == 0) begin  // Start bit detected
                        next_state = `RECEIVE;
                    end
                end
                next_bit_counter = 0;
                next_valid_data = 0;
            end

            `RECEIVE: begin
                if (baud_rate_signal) begin
                    if (bit_counter < 8) begin
                        next_d[bit_counter] = uart_rx;
                        next_bit_counter = bit_counter + 1;
                    end else begin
                        stop_bit = uart_rx;  // Capture stop bit
                        if (stop_bit == 1) begin
                            next_valid_data = 1;
                        end
                        next_state = `IDLE;
                    end
                end
            end
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= `IDLE;
            bit_counter <= 0;
            data <= 0;
            valid_data <= 0;
        end else begin
            state <= next_state;
            bit_counter <= next_bit_counter;
            d <= next_d;
            if (next_valid_data) begin
                data <= next_d;  // Update output data when valid
            end
            valid_data <= next_valid_data;
        end
    end

endmodule
