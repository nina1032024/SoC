`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2025/02/05 17:01:10
// Design Name:
// Module Name: test_uart_receiver
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

`define DELAY_1 1//half period

module test_uart_receiver_top();
    reg clk;
    reg rst;
    reg uart_rx;
    wire baud_rate_signal;
    wire [7:0] data;
    wire valid_data;
    integer data_tx;
    reg [9:0] d;
    reg [7:0] answer;
    //answer = {data[7:0], valid_data}
    //check data at the end of every cycle

    uart_receiver ur(
                      .clk(clk),
                      .rst(rst),
                      .uart_rx(uart_rx),
                      .baud_rate_signal(baud_rate_signal),
                      .data(data),
                      .valid_data(valid_data)
                  );

    baud_rate_generator ub(
                            .clk(clk),
                            .rst(rst),
                            .baud_rate_signal(baud_rate_signal)
                        );

    always #`DELAY_1 clk = ~clk;

    integer i;
    integer error_cnt;

    always @(i)
        answer = (i==10) ? data_tx[7:0] : 0;

    initial
    begin
        error_cnt = 0;
        //test 256 transmitted serial data(0000_0000~ 1111_1111)
        for(data_tx = 0; data_tx < 256; data_tx = data_tx + 1)
        begin
            d = {1'b1, data_tx[7:0], 1'b0};
            //initialize(first cycle)
            clk = 0;
            rst = 1;
            uart_rx = 1;
            i = 0;

            //active data(second cycle)
            #`DELAY_1;
            #`DELAY_1;
            rst = 0;

            //start receiving
            #`DELAY_1;
            #`DELAY_1;

            //complete receiving
            for(i = 0; i < 11; i = i + 1)
            begin
                @(posedge baud_rate_signal);
                uart_rx = (i<=9)? d[i]: 1;
                if(i == 10 && ({data[7:0]} !== answer[7:0]))
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
