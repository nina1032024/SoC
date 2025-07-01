`timescale 1ns/1ps
module divN #(
    parameter pDATA_WIDTH = 128 
) (
    input  wire [(pDATA_WIDTH-1):0] in_A,
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     in_valid,
    output reg  [(pDATA_WIDTH-1):0] result_int,
    output reg                      out_valid
);

    // Shift register for in_A (17-stage)
    reg [(pDATA_WIDTH-1):0] data_pipe [0:16];
    reg [16:0] valid_pipe;

    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid  <= 0;
            result_int <= 0;
            valid_pipe <= 0;
            for (i = 0; i < 17; i = i + 1) begin
                data_pipe[i] <= 0;
            end
        end else begin
            // shift valid bits
            valid_pipe <= {valid_pipe[15:0], in_valid};
            out_valid  <= valid_pipe[16];

            // shift data
            data_pipe[0] <= in_A;
            for (i = 1; i < 17; i = i + 1) begin
                data_pipe[i] <= data_pipe[i-1];
            end
            result_int <= data_pipe[16];
        end
    end

endmodule
