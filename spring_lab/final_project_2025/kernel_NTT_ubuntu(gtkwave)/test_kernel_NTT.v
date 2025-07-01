
`default_nettype none

`timescale 1ns/1ps
module test_kernel_NTT;

parameter pDATA_WIDTH = 128;

reg                     clk;
reg                     clk_2x;     // for dataRAM (double-speed)
reg                     rstn;

reg                     ld_vld;
wire                    ld_rdy;
reg [(pDATA_WIDTH-1):0] ld_dat;

wire                    sw_vld;
reg                     sw_rdy;
wire[(pDATA_WIDTH-1):0] sw_dat;

reg                     coef_vld;
wire                    coef_rdy;
reg [(pDATA_WIDTH-1):0] coef_dat; 

wire              [4:0] bpe_act;
reg               [7:0] mode;
reg                     decode;
wire                    sw_lst;   

// Instantiate DUT
kernel_top top (
    .clk(clk),
    .clk_2x(clk_2x),
    .rstn(rstn),
    .ld_vld(ld_vld),
    .ld_rdy(ld_rdy),
    .ld_dat(ld_dat),
    .sw_vld(sw_vld),
    .sw_rdy(sw_rdy),
    .sw_dat(sw_dat),
    .coef_vld(coef_vld),
    .coef_rdy(coef_rdy),
    .coef_dat(coef_dat),
    .bpe_act(bpe_act),
    .mode(mode),
    .decode(decode),
    .sw_lst(sw_lst)
);



// initial begin
//     $fsdbDumpfile("test_NTT.fsdb");  
//     $fsdbDumpvars(0, test_kernel_NTT);              
// end

// ubuntu
initial begin
  $dumpfile("test_kernel_NTT.vcd");    
  $dumpvars(0, test_kernel_NTT);  
end

// ================= CLOCKS ================= //
initial begin
    clk = 0;
    forever #20 clk = ~clk;
end

initial begin
    clk_2x = 0;
    forever #10 clk_2x = ~clk_2x;
end

// ================= STIMULUS ================= //
integer i, j, k, l;
reg [15:0] low_group [0:7];
reg [15:0] high_group [0:7];
reg [10:0] addr;
reg [15:0] coef [0:7];

initial begin
    $display("Start simulation...");
    rstn = 0; ld_vld = 0; coef_vld = 0; decode = 0;

    repeat (4) @(posedge clk);  

    rstn = 1;

    // decode NTT mode
    @(posedge clk)
    mode = 8'b00000010;
    @(posedge clk) decode = 1; mode = 8'b00001010;
    @(posedge clk) decode = 0;

    //coeffcient input
    @(posedge clk);
    for (l = 0; l < 64; l = l + 1) begin
        for (k = 0; k < 8; k = k + 1) begin
            coef[k] = l * 8 + k;
        end

        coef_dat = {coef[7], coef[6], coef[5], coef[4],
                    coef[3], coef[2], coef[1], coef[0]};
        
        wait (coef_rdy == 1);
        coef_vld <= 1;
        @(posedge clk);
        // coef_vld <= 0;
    end

    // s1 data    
    for (i = 0; i < 64; i = i + 1) begin
        // Low part
        for (j = 0; j < 8; j = j + 1)
            low_group[j] = i * 8 + j;

        ld_dat = {low_group[7], low_group[6], low_group[5], low_group[4],
                  low_group[3], low_group[2], low_group[1], low_group[0]};
        // @(posedge clk);
        ld_vld <= 1;
        addr <= i * 2;
        @(posedge clk);
        ld_vld <= 0;

        repeat (7) @(posedge clk);  

        // High part
        for (j = 0; j < 8; j = j + 1)
            high_group[j] = 512 + i * 8 + j;

        ld_dat = {high_group[7], high_group[6], high_group[5], high_group[4],
                  high_group[3], high_group[2], high_group[1], high_group[0]};
        // @(posedge clk);
        ld_vld <= 1;
        addr <= i * 2 + 1;
        @(posedge clk);
        ld_vld <= 0;

        repeat (7) @(posedge clk);  
    end
end

// ================= WAIT FOR RESULT + AUTOCHECK ================= //
reg done;
integer expected_val;
reg [15:0] expected_words[7:0];
reg [127:0] expected_dat;
integer idx;

initial begin
    done = 0;
    expected_val = 0;

    @(posedge rstn);  
    wait(sw_vld == 1);
    $display("Start receiving output from kernel...");

    
    while (!done) begin
        if (sw_vld) begin
            @(posedge clk);  
            sw_rdy <= 1;

            for (idx = 0; idx < 8; idx = idx + 1) begin
                expected_words[idx] = expected_val + idx;
            end
            expected_dat = {
                expected_words[7], expected_words[6],
                expected_words[5], expected_words[4],
                expected_words[3], expected_words[2],
                expected_words[1], expected_words[0]
            };

            $display("Received data : %h | Correct answer: %h ", sw_dat, expected_dat);

            if (sw_dat !== expected_dat) begin
                $display("Mismatch at %0d", expected_val);
                $fatal;
            end

            expected_val = expected_val + 8;

            if (sw_lst) begin
                $display("✅ Last data detected. Autocheck passed.");
                done = 1;
            end

            @(posedge clk);
            sw_rdy <= 0;

            repeat (7) @(posedge clk);
        end else begin
            @(posedge clk);
        end
    end

    $display("✅ All data received and verified.");
    $finish;
end





// ================= TIMEOUT CONTROL ================= //
initial begin
    #1_000_0_000000;

    $display("ERROR: Simulation hung or took too long.");
    $finish;
end

endmodule
