`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2025/02/07 14:54:58
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
    integer data;
    reg start;
    reg baud_rate_signal;
    wire uart_tx;
    reg [9:0] d;
    wire answer;


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
    integer error_cnt;

    assign answer = (i >= 10) ? 1 : d[i-1];

    initial
    begin
        error_cnt = 0;
        for (data = 0; data < 256; data = data + 1)
        begin
            d= {1'b1, data[7:0], 1'b0};
            //initialized inputs
            clk = 0;
            rst = 1;
            start = 0;
            i= 0;
            baud_rate_signal = 0;

            //wait one cycle
            #`DELAY_5;
            #`DELAY_5;
            rst = 0;

            //start transmitting
            #`DELAY_5;
            #`DELAY_5;
            start = 1;
            baud_rate_signal = 0;

            //complete transmission
            for(i = 0; i < 20; i = i + 1)
            begin
                #`DELAY_5;
                #`DELAY_5;
                if((i>0) && (uart_tx !== answer))
                begin
                    error_cnt = error_cnt + 1;
                end
                start = 0;
                baud_rate_signal = 0;

                #`DELAY_5;
                #`DELAY_5;
                if((i>0) && (uart_tx !== answer))
                begin
                    error_cnt = error_cnt + 1;
                end
                start = 0;
                baud_rate_signal = 1;
            end
        end
        if (error_cnt > 0)
            $display("%d error", error_cnt);
        else
            $display("All testcases passed");
        $display("Testbench completed");
        $finish;

    end

endmodule

//baud_rate_signal = 1 increases the counter for autocheck
