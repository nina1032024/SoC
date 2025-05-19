`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/20/2023 10:38:55 AM
// Design Name: 
// Module Name: fir_tb
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
`define RAND_R
`define RAND_W
module fir_tb
#(  parameter pADDR_WIDTH = 12,
    parameter pDATA_WIDTH = 32
)();
    wire                        awready;
    wire                        wready;
    reg                         awvalid;
    reg   [(pADDR_WIDTH-1): 0]  awaddr;
    reg                         wvalid;
    reg signed [(pDATA_WIDTH-1) : 0] wdata;
    wire                        arready;
    reg                         rready;
    reg                         arvalid;
    reg         [(pADDR_WIDTH-1): 0] araddr;
    wire                        rvalid;
    wire signed [(pDATA_WIDTH-1): 0] rdata;
    reg                         ss_tvalid;
    reg signed [(pDATA_WIDTH-1) : 0] ss_tdata;
    reg                         ss_tlast;
    wire                        ss_tready;
    reg                         sm_tready;
    wire                        sm_tvalid;
    wire signed [(pDATA_WIDTH-1) : 0] sm_tdata;
    wire                        sm_tlast;
    reg                         axis_clk;
    reg                         axis_rst_n;

// ram for tap
    wire [3:0]               tap_WE;
    wire                     tap_EN;
    wire [(pDATA_WIDTH-1):0] tap_Di;
    wire [(pADDR_WIDTH-1):0] tap_A;
    wire [(pDATA_WIDTH-1):0] tap_Do;

// ram for data RAM
    wire [3:0]               data_WE;
    wire                     data_EN;
    wire [(pDATA_WIDTH-1):0] data_Di;
    wire [(pADDR_WIDTH-1):0] data_A;
    wire [(pDATA_WIDTH-1):0] data_Do;

    // wire [4:0] x_r_cnt;
    // wire [4:0] tap_cnt;
    // wire [4:0] x_w_cnt;
    // wire [(pDATA_WIDTH-1):0] y_cnt;
    // wire [(pDATA_WIDTH-1):0] x;
    // wire [(pDATA_WIDTH-1):0] h;
    // wire [(pDATA_WIDTH-1):0] mul;
    // wire [(pDATA_WIDTH-1):0] y;
    // wire [4:0] y_cyc_cnt;
    // wire [(pDATA_WIDTH-1):0] x_cnt;
    // wire [4:0] tap_proc_cnt;
    // wire [(pDATA_WIDTH-1):0] tap_num;
    // wire [(pDATA_WIDTH-1):0] ss_tdata_latch;
    // wire [(pDATA_WIDTH-1):0] sm_tdata_latch;
    // wire x_buffer_full;
    // wire y_buffer_full;
    // wire x_buffer_count_en;
    // wire [1:0] state;
    // wire [5:0] x_cyc_cnt;




    fir fir_DUT(
        .awready(awready),
        .wready(wready),
        .awvalid(awvalid),
        .awaddr(awaddr),
        .wvalid(wvalid),
        .wdata(wdata),
        .arready(arready),
        .rready(rready),
        .arvalid(arvalid),
        .araddr(araddr),
        .rvalid(rvalid),
        .rdata(rdata),
        .ss_tvalid(ss_tvalid),
        .ss_tdata(ss_tdata),
        .ss_tlast(ss_tlast),
        .ss_tready(ss_tready),
        .sm_tready(sm_tready),
        .sm_tvalid(sm_tvalid),
        .sm_tdata(sm_tdata),
        .sm_tlast(sm_tlast),

        // ram for tap
        .tap_WE(tap_WE),
        .tap_EN(tap_EN),
        .tap_Di(tap_Di),
        .tap_A(tap_A),
        .tap_Do(tap_Do),

        // ram for data
        .data_WE(data_WE),
        .data_EN(data_EN),
        .data_Di(data_Di),
        .data_A(data_A),
        .data_Do(data_Do),

        .axis_clk(axis_clk),
        .axis_rst_n(axis_rst_n)

        // .x_r_cnt(x_r_cnt),
        // .tap_cnt(tap_cnt),
        // .x_w_cnt(x_w_cnt),
        // .y_cnt(y_cnt),
        // .x(x),
        // .h(h),
        // .mul(mul),
        // .y(y),
        // .y_cyc_cnt(y_cyc_cnt),
        // .x_cnt(x_cnt),
        // .tap_proc_cnt(tap_proc_cnt),
        // .tap_num(tap_num),
        // .ss_tdata_latch(ss_tdata_latch),
        // .sm_tdata_latch(sm_tdata_latch),
        // .x_buffer_full(x_buffer_full),
        // .y_buffer_full(y_buffer_full),
        // .x_buffer_count_en(x_buffer_count_en),
        // .state(state),
        // .x_cyc_cnt(x_cyc_cnt)
    
        );
    
    // RAM for tap
    bram32 tap_RAM (
        .CLK(axis_clk),
        .WE(tap_WE),
        .EN(tap_EN),
        .Di(tap_Di),
        .A(tap_A),
        .Do(tap_Do)
    );

    // RAM for data: choose bram11 or bram12
    bram32 data_RAM(
        .CLK(axis_clk),
        .WE(data_WE),
        .EN(data_EN),
        .Di(data_Di),
        .A(data_A),
        .Do(data_Do)
    );

    `ifdef FSDB
        initial begin
            $fsdbDumpfile("fir.fsdb");
            $fsdbDumpvars("+mda");
        end
    `else
        initial begin
            $dumpfile("fir.vcd");
            $dumpvars();
        end
    `endif
// clk generate
    initial begin
        axis_clk = 0;
        forever begin
            #5 axis_clk = (~axis_clk);
        end
    end

    initial begin
        axis_rst_n = 1;
        @(posedge axis_clk);
        axis_rst_n = 0; 
        @(posedge axis_clk);
        @(posedge axis_clk);
        axis_rst_n = 1;
    end
// set data //
    integer Din[0:2], golden[0:2], coef_in[0:2], input_data[0:2], golden_data[0:2], m, n,a , b ,coef_data[0:2];
    reg signed [(pDATA_WIDTH-1):0] Din_list[0:2][0:(400-1)];
    reg signed [(pDATA_WIDTH-1):0] golden_list[0:2][0:(400-1)];
    reg signed [(pDATA_WIDTH-1):0] coef[0:2][0:(32-1)]; // fill in coef 
    initial begin
        Din[0] = $fopen("x1.dat","r");
        Din[1] = $fopen("x2.dat","r");
        Din[2] = $fopen("x3.dat","r");
        golden[0] = $fopen("y1.dat","r");
        golden[1] = $fopen("y2.dat","r");
        golden[2] = $fopen("y3.dat","r");
	      coef_data[0]= $fopen("coef1.dat","r");
	      coef_data[1]= $fopen("coef2.dat","r");
	      coef_data[2]= $fopen("coef3.dat","r");
        for(m=0;m< 400 ;m=m+1) begin
            input_data[0] = $fscanf(Din[0],"%d", Din_list[0][m]);
            golden_data[0] = $fscanf(golden[0],"%d", golden_list[0][m]);
            input_data[1] = $fscanf(Din[1],"%d", Din_list[1][m]);
            golden_data[1] = $fscanf(golden[1],"%d", golden_list[1][m]);
        end
        for(n=0;n< 15 ;n=n+1)  begin 
            coef_in[0]=$fscanf(coef_data[0],"%d", coef[0][n]);
            coef_in[1]=$fscanf(coef_data[1],"%d", coef[1][n]);
        end
 
        for(a=0;a< 300 ;a=a+1) begin
            input_data[2] = $fscanf(Din[2],"%d", Din_list[2][a]);
            golden_data[2] = $fscanf(golden[2],"%d", golden_list[2][a]);
        end
        for(b=0;b< 31 ;b=b+1)  begin 
            coef_in[2]=$fscanf(coef_data[2],"%d", coef[2][b]);
        end
    end
// axi-stream master
reg second_end; // i.e second dataset done.
    integer i;
    initial begin
        ss_tvalid=0;
        ss_tlast=0;
        wait(axis_rst_n==0);
        wait(axis_rst_n==1);
        $display("----Start the first dataset input(AXI-Stream),(1delay cycle for input)----");
        for(i=0;i<399;i=i+1) begin
            axi_stream_master(Din_list[0][i],0,0);
        end
        axi_stream_master(Din_list[0][(400 - 1)],1,0);
        $display("-----End the first dataset input(AXI-Stream)-----");
        // delay 20 cycle to feed
        $display("-----Start the second dataset input(AXI-Stream),(20 delay cycle for input)----");
        for(i=0;i<399;i=i+1) begin
            axi_stream_master(Din_list[1][i],0,20);
        end
        axi_stream_master(Din_list[1][(400 - 1)],1,20);
        $display("-----End the second dataset input(AXI-Stream)----");
        wait(second_end==1);
        $display("-----Start the third dataset input(AXI-Stream),(0 delay cycle for input)----");        
        // always can transsion ss_tvalid =1 
        @(posedge axis_clk);
        for(i=0;i<299;i=i+1) begin
            ss_tvalid <= 1;
            ss_tdata  <= Din_list[2][i];
            ss_tlast<=0;
            @(posedge axis_clk);
            while (!ss_tready) @(posedge axis_clk);
        end  
        @(posedge axis_clk);
        ss_tvalid <= 1;
        ss_tdata  <= Din_list[2][299];
        ss_tlast<=1;
        @(posedge axis_clk);
        while (!ss_tready) @(posedge axis_clk);     
        ss_tvalid <= 0;
        ss_tdata <=0;
        ss_tlast <=0;  
        $display("-----End the third dataset input(AXI-Stream)----");        
    end
    reg error_coef;
    integer k,l , sm_l;
    reg error;
    reg status_error;
// axi-stream slave
    initial begin
        sm_tready = 0;
        wait(axis_rst_n==0);
        wait(axis_rst_n==1);
        // delay 30 cycle to receive
        for(l=0;l <400;l=l+1) begin
            sm(golden_list[0][l],l,30);
        end
        // delay 1
        for(sm_l=0;sm_l <400;sm_l=sm_l+1) begin
            sm(golden_list[1][sm_l],sm_l,0);
        end
        // delay 0 always can receive
        @(posedge axis_clk);
        for (l=0;l<300;l=l+1)begin
            sm_tready <= 1;
            @(posedge axis_clk);
            while(!sm_tvalid) @(posedge axis_clk);
            if (sm_tdata !== golden_list[2][l]) begin
                $display("[ERROR] [Pattern %d] Golden answer: %d, Your answer: %d", l, golden_list[2][l], sm_tdata);
                error <= 1;
                $finish;
            end else begin
                if(sm_tlast) begin
                 $display("last data");
                end
                $display("[PASS] [Pattern %d] Golden answer: %d, Your answer: %d", l, golden_list[2][l], sm_tdata);
            end
        end
        sm_tready <=0;
    end

    //Prevent hang
    integer timeout = (100000);
    initial begin
        while(timeout > 0) begin
            @(posedge axis_clk);
            timeout = timeout - 1;
        end
        $display($time, "Simualtion Hang ....");
        $finish;
    end
integer third_start_time,third_end_time;
//axi-lite master
    initial begin
        arvalid=0;
        rready=0;
        error_coef = 0;
        error=0;
        second_end=0;
        awvalid = 0;
        wvalid = 0;
        $display("----Start the first dataset coefficient input(AXI-lite)----");
        config_write(12'h10, 400);
        config_read_check(12'h10, 400,32'hffffffff);
        config_write(12'h14, 15);
        config_read_check(12'h14, 15,32'hffffffff);
        for(k=0; k< 15; k=k+1) begin
            config_write(12'h80+4*k, coef[0][k]);
        end
        awvalid <= 0; wvalid <= 0;
        // read-back and check
        $display(" Check Coefficient ...");
        for(k=0; k < 15; k=k+1) begin
            config_read_check(12'h80+4*k, coef[0][k], 32'hffffffff);
        end
        arvalid <= 0;
        $display(" Start first dataset FIR");
        @(posedge axis_clk);
        config_write(12'h00, 32'h0000_0001);    // ap_start = 1
        // polling axi-done
        polling; 
        $display("----END the first dataset fir ----");   
        $display("----Start the second ap_start ----");     
        config_write(12'h00, 32'h0000_0001);    // ap_start = 1
        // ========== invalid write data_len;
        $display("----invalid write data_len ----");   
        //config_write(12'h10, 11);    

        // ========== valid read data_len ===========//
        // the gold read should same as above valid setting.
        $display("----valid read data_len, the gold read should same as above valid setting.  ----");   
        config_read_check(12'h10, 400, 32'hffffffff); 

        // =========== invalid read coef ============// 
        $display("----invalid read coef, don't check the answer.  ----");  
        config_read_check(12'h80,32'hffffffff , 32'h0); 
        // ==========================================//
        polling;
        second_end=1;
        // =========== valid write ==================//
        $display("----Start the third dataset coefficient input(AXI-lite)----");       
        for(k=0; k< 31; k=k+1) begin
            config_write(12'h80+4*k, coef[2][k]);
        end
        config_write(12'h10, 300);
        config_write(12'h14, 31);
        $display("----Start the third ap_start ----");    
        config_write(12'h00, 32'h0000_0001);
        third_start_time=$time;
        polling;
        third_end_time=$time;
        // check error result
        if (error == 0 & error_coef == 0) begin
            $display("---------------------------------------------");
            $display("-----------Congratulations! Pass-------------");
        end
        else begin
            $display("--------Simulation Failed---------");
        end
        $display("-------------------third dataset complete cycle count %d(to know best case throuput) ---------------------",(third_end_time-third_start_time)/10);
        $finish;
    end
reg done_state;
    task polling;
        begin
            done_state=0;
            while(~done_state) begin
                // can read data_length          
                @(posedge axis_clk);
                arvalid <= 1; araddr <= 0;
                rready <= 1;
                fork 
                    begin
                        @(posedge axis_clk);
                        while (!arready) @(posedge axis_clk);
                        arvalid<=0;
                        araddr<=0;
                    end
                    begin
                        @(posedge axis_clk);
                        while (!rvalid) @(posedge axis_clk);
                        if( rdata[1] == 1) begin
                            $display("-----------get ap_done------------");
                            done_state=1;
                        end
                        rready<=0;                
                    end
                join       
            end
            @(posedge axis_clk);
            // check ap_done clean //
            $display("-----------check ap_done clear------------");
            config_read_check(12'h00, 32'h00, 32'h0000_0002); 
        end
    endtask

    integer p, q;
    integer rand_num0, rand_num1;
    localparam cyc_max = 10;

    task config_write;
        input [11:0]    addr;
        input [31:0]    data;
        begin
            `ifdef RAND_W
                rand_num0 = ($random % cyc_max + cyc_max) % cyc_max;
            `else
                rand_num0=0;      
            `endif

            @(posedge axis_clk);
            fork
                begin
                    awvalid <= 1; awaddr <= addr;
                    @(posedge axis_clk);
                    while (!awready) @(posedge axis_clk);
                    awvalid<=0;
                    awaddr<=0;
                end
                begin // randomly delay wvalid and wdata
                    for (p = 0; p < rand_num0; p = p + 1) begin
                        @(posedge axis_clk);
                    end
                    wvalid  <= 1; wdata <= data;
                    @(posedge axis_clk);
                    while (!wready) @(posedge axis_clk);
                    wvalid<=0;   
                    wdata<=0;  
                end
            join 
        end
    endtask

    task config_read_check;
        input [11:0]        addr;
        input signed [31:0] exp_data;
        input [31:0]        mask;
        begin
            
            `ifdef RAND_R
                rand_num1 = ($random % cyc_max + cyc_max) % cyc_max;
            `else
                rand_num1=0;      
            `endif
            @(posedge axis_clk);
            fork 
                begin
                    arvalid <= 1; araddr <= addr;
                    @(posedge axis_clk);
                    while (!arready) @(posedge axis_clk);
                    arvalid<=0;
                    araddr<=0;
                end
                begin // randomly delay rready
                    for (p = 0; p < rand_num1; p = p + 1) begin
                        @(posedge axis_clk);
                    end
                    rready <= 1;
                end
                begin
                    @(posedge axis_clk);
                    while (!(rvalid & rready)) @(posedge axis_clk);
                    if( (rdata & mask) !== (exp_data & mask)) begin
                        $display("ERROR: exp = %d, rdata = %d", exp_data, rdata);
                        error_coef <= 1;
                    end else begin
                        $display("OK: exp = %d, rdata = %d", exp_data, rdata);
                    end
                    rready<=0;                
                end
            join 
        end
    endtask

integer ss_i,sm_i;

    task axi_stream_master;
        input  signed [31:0] in1;
        input last;
        input [31:0] delay_cycle;
        begin
            for( ss_i=0;ss_i<delay_cycle;ss_i=ss_i+1) begin
            @(posedge axis_clk);
            end
            @(posedge axis_clk);
            ss_tvalid <= 1;
            ss_tdata  <= in1;
            if(last) ss_tlast<=1;
            @(posedge axis_clk);
            while (!ss_tready) @(posedge axis_clk);
            ss_tvalid <= 0;
            ss_tdata <=0;
            ss_tlast <=0;
        end
    endtask

    task sm;
        input   signed [31:0] in2; // golden data
        input         [31:0] pcnt; // pattern count
        input [31:0] delay_cycle;
        begin
            for( sm_i=0;sm_i<delay_cycle;sm_i=sm_i+1) begin
            @(posedge axis_clk);
            end
            @(posedge axis_clk) 
            sm_tready <= 1;
            @(posedge axis_clk);
            while(!sm_tvalid) @(posedge axis_clk);
            sm_tready <=0;
            if (sm_tdata !== in2) begin
                $display("[ERROR] [Pattern %d] Golden answer: %d, Your answer: %d", pcnt, in2, sm_tdata);
                error <= 1;
                //$finish;
            end else begin
                if(sm_tlast) begin
                    $display("last data");
                end
                $display("[PASS] [Pattern %d] Golden answer: %d, Your answer: %d", pcnt, in2, sm_tdata);
            end
        end
    endtask
endmodule