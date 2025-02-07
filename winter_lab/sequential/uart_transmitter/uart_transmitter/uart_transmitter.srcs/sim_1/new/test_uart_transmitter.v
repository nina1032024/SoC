`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2025/02/07 12:13:10
// Design Name:
// Module Name: test_uart_transmitter
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

`timescale 1ns / 1ps
`define DELAY_5 5
module test_uart_transmitter;

    reg clk;
    reg rst;
    reg [7:0] data;
    reg start;
    reg baud_rate_signal;
    wire uart_tx;

    uart_transmitter u0(
                         .clk(clk),
                         .rst(rst),
                         .data(data),
                         .baud_rate_signal(baud_rate_signal),
                         .start(start),
                         .uart_tx(uart_tx)
                     );

    always #`DELAY_5 clk = ~clk;

    integer i;

    initial begin
        //initialized inputs
        clk = 0;
        rst = 1;
        data = 8'b0;
        start = 0;
        baud_rate_signal = 0;

        //wait one cycle
        #`DELAY_5;
        #`DELAY_5;
        rst = 0;

        //start transmitting
        #`DELAY_5;
        start = 1;
        data = 8'b01000001;
        baud_rate_signal = 0;

        //complete transmission
        for(i = 0; i < 20; i = i + 1) begin
            #`DELAY_5;
            start = 0;
            baud_rate_signal = 0;

            #`DELAY_5;
            start = 0;
		    baud_rate_signal = 1;
        end
        $finish;

    end
endmodule
