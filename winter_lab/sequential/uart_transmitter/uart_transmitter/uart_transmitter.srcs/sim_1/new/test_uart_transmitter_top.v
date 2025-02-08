`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2025/02/08 11:03:12
// Design Name:
// Module Name: test_uart_transmitter_top
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
`define DELAY_2 2//half period
module test_uart_transmitter;

    reg clk;
    reg rst;
    integer data;
    reg start;
    wire baud_rate_signal;
    wire uart_tx;
    reg [9:0] d;
    wire answer;

    uart_transmitter ut(
                         .clk(clk),
                         .rst(rst),
                         .data(data),
                         .baud_rate_signal(baud_rate_signal),
                         .start(start),
                         .uart_tx(uart_tx)
                     );

    baud_rate_generator ub(
                            .clk(clk),
                            .rst(rst),
                            .baud_rate_signal(baud_rate_signal)
                        );

    always #`DELAY_2 clk = ~clk;

    integer i;
    integer error_cnt;

    assign answer = (i >= 10) ? 1 : d[i-1];

    initial
    begin
        error_cnt = 0;
        //test 256 data(0000_0000 to 1111_1111)
        for (data = 0; data < 256; data = data + 1)
        begin
            d = {1'b1, data[7:0], 1'b0};
            //initialize (first cycle)
            clk = 0;
            rst = 1;
            start = 0;
            i = 0;

            // active data (second cycle)
            #`DELAY_2;
            #`DELAY_2;
            rst = 0;

            //start transmission (third cycle)
            #`DELAY_2;
            #`DELAY_2;
            start = 1;

            #`DELAY_2;
            #`DELAY_2;
            start = 0;
            //complete transmission
            for(i = 0; i < 20; i = i + 1)
            begin
                @(posedge baud_rate_signal);
                if((i>0) && (uart_tx !== answer))
                begin
                    error_cnt = error_cnt + 1;
                end
            end
        end
        if (error_cnt > 0)
        begin
            $display("%d error", error_cnt);
        end
        else
        begin
            $display("All testcases passed");
        end
        $display("Testbench completed");
        $finish;
    end


endmodule

