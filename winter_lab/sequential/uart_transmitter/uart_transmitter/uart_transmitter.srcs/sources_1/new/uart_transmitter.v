`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2025/02/07 12:11:50
// Design Name:
// Module Name: uart_transmitter
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
`define TRANSMIT 1


module uart_transmitter(
        input clk,
        input rst,
        input [7:0] data,
        input baud_rate_signal,
        input start,
        output reg uart_tx
    );

    reg state, next_state;
    reg next_baud_rate_signal;
    reg [3:0] bit_counter;
    reg [3:0] next_bit_counter;
    reg uart_tx_local;
    reg [9:0] d;

    always @(*) begin
        d = {1'b1, data, 1'b0}; // Stop bit (1), Data (8 bits), Start bit (0)
    end

    always@* begin
        case(state)
            `IDLE: begin
                if(start == 1) begin
                    next_state = `TRANSMIT;
                    uart_tx_local = 0; //start bit
                    next_bit_counter = 0;
                end else begin
                    next_state = `IDLE;
                    uart_tx_local = 1;
                    next_bit_counter = 0;
                end
            end
            `TRANSMIT:begin
                if(baud_rate_signal == 1) begin
                    if(bit_counter == 9) begin
                        next_state = `IDLE;
                        uart_tx_local = 1; //stop bit
                        next_bit_counter = 0;
                    end else begin
                        next_state = `TRANSMIT;
                        uart_tx_local = d[bit_counter]; //sending current bits
                        next_bit_counter = bit_counter +1;
                    end
                end else begin
                    if(bit_counter == 0) begin
                        uart_tx_local = 1; 
                    end else begin
                        uart_tx_local = d[bit_counter - 1]; //transmit previous bit
                    end
                    next_state = `TRANSMIT;
                    next_bit_counter = bit_counter;
                end
            end
            default: begin
                next_state = `IDLE;
                uart_tx_local = 0;
                next_bit_counter = 0;
            end
        endcase
    end

    always@ (posedge clk or posedge rst) begin
        if(rst) begin
            state <= `IDLE;
            bit_counter <= 0;
            uart_tx <= 1;
        end else begin
            state <= next_state;
            bit_counter <= next_bit_counter;
            uart_tx <= uart_tx_local;
        end
    end
endmodule
