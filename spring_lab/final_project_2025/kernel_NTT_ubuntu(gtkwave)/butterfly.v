module butterfly (
    input  wire         clk, rstn,
    input  wire [7:0]   mode,
    input  wire         i_vld,
    output wire         i_rdy,
    output wire         o_vld,
    input  wire         o_rdy,
    input  wire [127:0] ai, bi, gm,
    output wire [127:0] ao, bo
);

    localparam LATENCY = 22;

    // FIFO-like shift register for data and valid signal
    reg [127:0] ai_pipe [0:LATENCY-1];
    reg [127:0] bi_pipe [0:LATENCY-1];
    reg         vld_pipe [0:LATENCY-1];

    integer i;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (i = 0; i < LATENCY; i = i + 1) begin
                ai_pipe[i] <= 0;
                bi_pipe[i] <= 0;
                vld_pipe[i] <= 0;
            end
        end else begin
            if (i_vld && i_rdy) begin
                ai_pipe[0] <= ai;
                bi_pipe[0] <= bi;
                vld_pipe[0] <= 1;
            end else begin
                vld_pipe[0] <= 0;
            end
            for (i = 1; i < LATENCY; i = i + 1) begin
                ai_pipe[i] <= ai_pipe[i-1];
                bi_pipe[i] <= bi_pipe[i-1];
                vld_pipe[i] <= vld_pipe[i-1];
            end
        end
    end

    // Always ready to accept input (can modify if needed)
    assign i_rdy = 1;

    // Valid signal delayed by 22 cycles
    assign o_vld = vld_pipe[LATENCY-1];

    // Output data delayed by 22 cycles
    assign ao = ai_pipe[LATENCY-1];
    assign bo = bi_pipe[LATENCY-1];

endmodule
