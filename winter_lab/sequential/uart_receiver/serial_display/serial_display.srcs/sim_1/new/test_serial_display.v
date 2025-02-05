`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/01/08 16:49:49
// Design Name: 
// Module Name: test_serial_display
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


`timescale 1ns/1ps

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

module test_serial_display();
    parameter [127:0] SEVEN_SEG_CODE = {
        `SS_F, `SS_E, `SS_D, `SS_C, `SS_B, `SS_A, `SS_9, `SS_8,
        `SS_7, `SS_6, `SS_5, `SS_4, `SS_3, `SS_2, `SS_1, `SS_0
    };

    parameter DELAY = 5;

    reg [7:0] ascii_data;               
    reg data_valid;                     
    wire [7:0] seven_segment_data;      
    wire [3:0] seven_segment_enable;    

    serial_display uut (
        .ascii_data(ascii_data),
        .data_valid(data_valid),
        .seven_segment_data(seven_segment_data),
        .seven_segment_enable(seven_segment_enable)
    );

    integer i, error_count;
    initial begin
        ascii_data = 8'd0;
        #DELAY;
        data_valid = 1'b0;

        error_count = 0;

        $display("Starting Testbench...");
        $monitor("Time: %0t | ASCII Data: %h | Data Valid: %b | 7-Segment Data: %b | Enable: %b", 
                 $time, ascii_data, data_valid, seven_segment_data, seven_segment_enable);

        $display("Testing valid ASCII range: '0'-'9'");
        for (i = 48; i <= 57; i = i + 1) begin
            ascii_data = i;
            #DELAY;
            data_valid = 1'b1;
            #DELAY;

            if (seven_segment_data !== SEVEN_SEG_CODE[(i - 48) * 8 +: 8]) begin
                $display("ERROR: ASCII Data: %h | Expected 7-Segment Data: %b | Actual 7-Segment Data: %b", 
                         ascii_data, SEVEN_SEG_CODE[(i - 48) * 8 +: 8], seven_segment_data);
                error_count = error_count + 1;
            end

            #DELAY data_valid = 1'b0;
        end

        $display("Testing valid ASCII range: 'A'-'F'");
        for (i = 65; i <= 70; i = i + 1) begin
            ascii_data = i;
            #DELAY;
            data_valid = 1'b1;
            #DELAY;

            if (seven_segment_data !== SEVEN_SEG_CODE[(i - 55) * 8 +: 8]) begin
                $display("ERROR: ASCII Data: %h | Expected 7-Segment Data: %b | Actual 7-Segment Data: %b", 
                         ascii_data, SEVEN_SEG_CODE[(i - 55) * 8 +: 8], seven_segment_data);
                error_count = error_count + 1;
            end

            #DELAY data_valid = 1'b0;
        end

        #(2 * DELAY);
        if (error_count === 0) begin
            $display("All tests passed.");
        end else begin
            $display("ERROR: %d tests failed.", error_count);
        end
        $display("Testbench completed.");
        $stop;
    end

endmodule