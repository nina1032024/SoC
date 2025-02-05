`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2025/02/05 14:43:30
// Design Name:
// Module Name: test_baud_rate_generator
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
`define BAUD_RATE_NUMBER 20

module baud_rate_generator_tb;
    reg clk;
    reg rst;
    wire baud_rate_signal;
    wire [13:0] counter;

    baud_rate_generator uut (
                            .clk(clk),
                            .rst(rst),
                            .baud_rate_signal(baud_rate_signal),
                            .counter(counter)
                        );

    always #`DELAY_5 clk = ~clk;

    initial
    begin
        clk = 0;
        rst = 1;
        #`DELAY_5;
        #`DELAY_5;
        rst = 0;

        #(`BAUD_RATE_NUMBER * 100);

        $finish;
    end

    // Monitor values
    initial
    begin
        $monitor("Time=%0t | clk=%b | rst=%b | baud_rate_signal=%b | counter=%d",
                 $time, clk, rst, baud_rate_signal, counter);
    end
endmodule