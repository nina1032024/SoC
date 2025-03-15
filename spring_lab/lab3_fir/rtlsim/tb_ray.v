`timescale 1ns / 1ps
`define SDFFILE   "../syn/netlist/fir_syn.sdf"      // Modify your sdf file name
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
`define Data_Num0 300 //p0: 300 //p1: 600 //p2: 100 //p3: 15
`define Data_Num1 600
`define Data_Num2 100
`define Data_Num3 15
`define Coef_Num0 12  //p0: 12 //p1: 12(the same with p0) //p2: 32  //p3: 20
`define Coef_Num1 12
`define Coef_Num2 32
`define Coef_Num3 20

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
    // reg signed [(pDATA_WIDTH-1):0] Din_list0[0:(`Data_Num0-1)];
    // reg signed [(pDATA_WIDTH-1):0] golden_list0[0:(`Data_Num0-1)];
    // reg signed [(pDATA_WIDTH-1):0] coef0[0:(`Coef_Num0-1)]; // fill in coef 

    reg signed [(pDATA_WIDTH-1):0] Din_list1[0:(`Data_Num1-1)];
    reg signed [(pDATA_WIDTH-1):0] golden_list1[0:(`Data_Num1-1)];
    reg signed [(pDATA_WIDTH-1):0] coef1[0:(`Coef_Num1-1)]; // fill in coef 

    reg signed [(pDATA_WIDTH-1):0] Din_list2[0:(`Data_Num2-1)];
    reg signed [(pDATA_WIDTH-1):0] golden_list2[0:(`Data_Num2-1)];
    reg signed [(pDATA_WIDTH-1):0] coef2[0:(`Coef_Num2-1)]; // fill in coef 

    reg signed [(pDATA_WIDTH-1):0] Din_list3[0:(`Data_Num3-1)];
    reg signed [(pDATA_WIDTH-1):0] golden_list3[0:(`Data_Num3-1)];
    reg signed [(pDATA_WIDTH-1):0] coef3[0:(`Coef_Num3-1)]; // fill in coef 
    // `ifdef FSDB
    //     initial begin
    //         $fsdbDumpfile("fir.fsdb");
    //         $fsdbDumpvars("+mda");
    //     end
    // `elsif
        initial begin
            $dumpfile("fir.vcd");
            $dumpvars();
        end
    // `endif

    `ifdef SDF
    initial $sdf_annotate(`SDFFILE, fir_DUT);
    `endif

    initial begin
        axis_clk = 0;
        forever begin
            #5 axis_clk = (~axis_clk);
        end
    end

    initial begin
        axis_rst_n = 0;
        @(posedge axis_clk); 
        @(posedge axis_clk);
        axis_rst_n = 1;
    end

    reg [31:0] data_length0, data_length1, data_length2, data_length3;
    reg [31:0] coef_length0, coef_length1, coef_length2, coef_length3;
    integer Din0, Din1, Din2, Din3, golden0, golden1, golden2, golden3, coef_in, input_data, golden_data, m, n, coef_data0, coef_data1, coef_data2, coef_data3;
    initial begin
        data_length0 = 0;
        data_length1 = 0;
        data_length2 = 0;
        data_length3 = 0;

        coef_length0 = 0;
        coef_length1 = 0;
        coef_length2 = 0;
        coef_length3 = 0;

        Din1 = $fopen("x1.dat","r");
        golden1 = $fopen("y1.dat","r");
	    coef_data1 = $fopen("coef1.dat","r");

        Din2 = $fopen("x2.dat","r");
        golden2 = $fopen("y2.dat","r");
	    coef_data2 = $fopen("coef2.dat","r");

        Din3 = $fopen("x3.dat","r");
        golden3 = $fopen("y3.dat","r");
	    coef_data3 = $fopen("coef3.dat","r");


        for(m=0;m< `Data_Num1 ;m=m+1) begin
            input_data = $fscanf(Din1,"%d", Din_list1[m]);
            golden_data = $fscanf(golden1,"%d", golden_list1[m]);
            data_length1 = data_length1 + 1;
        end
        for(n=0;n< `Coef_Num1 ;n=n+1)  begin 
            coef_in=$fscanf(coef_data1,"%d", coef1[n]);
            coef_length1 = coef_length1 + 1;
        end

        for(m=0;m< `Data_Num2 ;m=m+1) begin
            input_data = $fscanf(Din2,"%d", Din_list2[m]);
            golden_data = $fscanf(golden2,"%d", golden_list2[m]);
            data_length2 = data_length2 + 1;
        end
        for(n=0;n< `Coef_Num2 ;n=n+1)  begin 
            coef_in=$fscanf(coef_data2,"%d", coef2[n]);
            coef_length2 = coef_length2 + 1;
        end

        for(m=0;m< `Data_Num3 ;m=m+1) begin
            input_data = $fscanf(Din3,"%d", Din_list3[m]);
            golden_data = $fscanf(golden3,"%d", golden_list3[m]);
            data_length3 = data_length3 + 1;
        end
        for(n=0;n< `Coef_Num3 ;n=n+1)  begin 
            coef_in=$fscanf(coef_data3,"%d", coef3[n]);
            coef_length3 = coef_length3 + 1;
        end
    end

    reg split;
    reg wait_axilite_finish;
    integer i;
    initial begin
        $display("------------Start simulation-----------");
        ss_tvalid = 0;
        ss_tlast = 0;
        ss_tdata=0;
        $display("----Start the data input(AXI-Stream)----");
        for(i=0;i<(data_length1 - 1);i=i+1) begin
            ss_tlast = 0; axi_stream_master0(Din_list1[i]);
            //config_write0(12'h10, 10); // write data_length
            //config_write0(12'h14, 10); // write tap_length
            //config_read_check0(12'h10, data_length0, 32'hffffffff); // check if data_length dont change
            //config_read_check0(12'h14, coef_length0, 32'hffffffff); // check if tap_length dont change
            //config_write0(12'h00, 32'h0000_0001); // write ap_start
            //config_read_check0(12'h00, 32'h00, 32'h0000_0001); // check ap_start = 0;
            //config_read_check0(12'h00, 32'h00, 32'h0000_0004); // check ap_idle = 0 (0x00 [bit 2])
            //config_read_check0(12'h00, 32'h00, 32'h0000_0002); // check done= 0
            //config_read_check0(12'h84, 32'hffffffff, 32'hffffffff); // check if read tap returns ffffffff
        end
        ss_tvalid = 0; //not here origin
	    config_read_check0(12'h00, 32'h00, 32'h0000_0002); // check done= 0
        ss_tlast = 1; 
        axi_stream_master0(Din_list0[(`Data_Num1 - 1)]);
        ss_tlast = 0; 
        $display("------End the data input(AXI-Stream)------");

        wait(split);

        $display("------------Start simulation-----------");
        ss_tvalid = 0;
        ss_tlast = 0;
        ss_tdata=0;
        $display("----Start the data input(AXI-Stream)----");
        for(i=0;i<(data_length2 - 6);i=i+1) begin
            ss_tlast = 0; axi_stream_master1(Din_list2[i]);
            config_write1(12'h10, 10); // write data_length
            config_write1(12'h14, 10); // write tap_length
            config_read_check2(12'h10, data_length2, 32'hffffffff); // check if data_length dont change
            config_read_check2(12'h14, coef_length2, 32'hffffffff); // check if tap_length dont change
            config_write1(12'h00, 32'h0000_0001); // write ap_start
            config_read_check2(12'h00, 32'h00, 32'h0000_0001); // check ap_start = 0;
            config_read_check2(12'h00, 32'h00, 32'h0000_0004); // check ap_idle = 0 (0x00 [bit 2])
            config_read_check2(12'h00, 32'h00, 32'h0000_0002); // check done= 0
            config_read_check2(12'h84, 32'hffffffff, 32'hffffffff); // check if read tap returns ffffffff
        end
        ss_tvalid = 0; //not here origin
	    config_read_check2(12'h00, 32'h00, 32'h0000_0002); // check done= 0
        ss_tlast = 1; 
        axi_stream_master1(Din_list2[(`Data_Num2 - 6)]);
        ss_tlast = 0; 
        $display("------End the data input(AXI-Stream)------");

        wait(split);

        $display("------------Start simulation-----------");
        ss_tvalid = 0;
        ss_tlast = 0;
        ss_tdata=0;
        $display("----Start the data input(AXI-Stream)----");
        for(i=0;i<(data_length2 - 1);i=i+1) begin
            ss_tlast = 0; axi_stream_master2(Din_list2[i]);
            config_write2(12'h10, 10); // write data_length
            config_write2(12'h14, 10); // write tap_length
            config_read_check1(12'h10, data_length2, 32'hffffffff); // check if data_length dont change
            config_read_check1(12'h14, coef_length2, 32'hffffffff); // check if tap_length dont change
            config_write2(12'h00, 32'h0000_0001); // write ap_start
            config_read_check1(12'h00, 32'h00, 32'h0000_0001); // check ap_start = 0;
            config_read_check1(12'h00, 32'h00, 32'h0000_0004); // check ap_idle = 0 (0x00 [bit 2])
            config_read_check1(12'h00, 32'h00, 32'h0000_0002); // check done= 0
            config_read_check1(12'h84, 32'hffffffff, 32'hffffffff); // check if read tap returns ffffffff
        end
        ss_tvalid = 0; //not here origin
	    config_read_check1(12'h00, 32'h00, 32'h0000_0002); // check done= 0
        ss_tlast = 1; 
        axi_stream_master2(Din_list2[(`Data_Num2 - 1)]);
        ss_tlast = 0; 

        wait(split);
        wait(wait_axilite_finish);
        
        $display("------------Start simulation-----------");
        ss_tvalid = 0;
        ss_tlast = 0;
        ss_tdata=0;
        $display("----Start the data input(AXI-Stream)----");
        for(i=0;i<(data_length3 - 1);i=i+1) begin
            ss_tlast = 0; axi_stream_master3(Din_list3[i]);
            config_write2(12'h10, 10); // write data_length
            config_write2(12'h14, 10); // write tap_length
            config_read_check2(12'h10, data_length3, 32'hffffffff); // check if data_length dont change
            config_read_check2(12'h14, coef_length3, 32'hffffffff); // check if tap_length dont change
            config_write2(12'h00, 32'h0000_0001); // write ap_start
            config_read_check2(12'h00, 32'h00, 32'h0000_0001); // check ap_start = 0;
            config_read_check2(12'h00, 32'h00, 32'h0000_0004); // check ap_idle = 0 (0x00 [bit 2])
            config_read_check2(12'h00, 32'h00, 32'h0000_0002); // check done= 0
            config_read_check2(12'h84, 32'hffffffff, 32'hffffffff); // check if read tap returns ffffffff
        end
        ss_tvalid = 0; //not here origin
	    config_read_check2(12'h00, 32'h00, 32'h0000_0002); // check done= 0
        ss_tlast = 1; 
        axi_stream_master3(Din_list3[(`Data_Num3 - 1)]);
        ss_tlast = 0; 
        $display("------End the data input(AXI-Stream)------");
    end

    reg error_coef;
    integer k,l;
     reg error;
    reg status_error;
    initial begin
        wait(axis_rst_n==0);
        wait(axis_rst_n==1);
        split = 0;
        error = 0; status_error = 0;
        sm_tready = 0;
        for(l=0;l < data_length0;l=l+1) begin
            sm1(golden_list0[l],l); //sm0
        end
        config_read_check0(12'h00, 32'h02, 32'h0000_0002); // check ap_done = 1 (0x00 [bit 1])
        config_read_check0(12'h00, 32'h04, 32'h0000_0004); // check ap_idle = 1 (0x00 [bit 2])
        split <= 1;

        @(posedge axis_clk);
        split <= 0;

        sm_tready = 0;
        for(l=0;l < data_length1 - 5;l=l+1) begin
            sm2(golden_list1[l],l);
        end
        config_read_check2(12'h00, 32'h02, 32'h0000_0002); // check ap_done = 1 (0x00 [bit 1])
        config_read_check2(12'h00, 32'h04, 32'h0000_0004); // check ap_idle = 1 (0x00 [bit 2])
        split <= 1;

        @(posedge axis_clk);
        split <= 0;

        sm_tready = 0;
        for(l=0;l < data_length2;l=l+1) begin
            sm1(golden_list2[l],l);
        end
        config_read_check1(12'h00, 32'h02, 32'h0000_0002); // check ap_done = 1 (0x00 [bit 1])
        config_read_check1(12'h00, 32'h04, 32'h0000_0004); // check ap_idle = 1 (0x00 [bit 2])
        split <= 1;

        @(posedge axis_clk); 
        split <= 0;

        sm_tready = 0;
        for(l=0;l < data_length3;l=l+1) begin
            sm2(golden_list3[l],l);
        end
        config_read_check2(12'h00, 32'h02, 32'h0000_0002); // check ap_done = 1 (0x00 [bit 1])
        config_read_check2(12'h00, 32'h04, 32'h0000_0004); // check ap_idle = 1 (0x00 [bit 2])

        if (error == 0 & error_coef == 0) begin
            $display("---------------------------------------------");
            $display("-----------Congratulations! Pass-------------");
        end
        else begin
            $display("--------Simulation Failed---------");
        end
        $finish;
    end

    //Prevent hang
    // integer timeout = (1000000);
    // initial begin
    //     while(timeout > 0) begin
    //         @(posedge axis_clk);
    //         timeout = timeout - 1;
    //     end
    //     $display($time, "Simualtion Hang ....");
    //     $finish;
    // end

    initial begin
        wait_axilite_finish = 0;
        arvalid=0;
        rready=0;
        error_coef = 0;
        $display("----Start the coefficient input(AXI-lite)----");
        config_write0(12'h10, data_length0);
        config_write0(12'h14, coef_length0);
        for(k=0; k< `Coef_Num0; k=k+1) begin
            config_write0(12'h80+4*k, coef0[k]);
            config_read_check0(12'h80+4*k, coef0[k], 32'hffffffff);
            config_read_check0(12'h00, 32'h04, 32'h0000_0004); // check ap_idle = 1 (0x00 [bit 2])
            config_read_check0(12'h00, 32'h00, 32'h0000_0002); // check done= 0
        end
        awvalid <= 0; wvalid <= 0;
        arvalid <= 0;
        // read-back and check
        $display(" Check Coefficient ...");
        $display(" Tape programming done ...");
        $display(" Start FIR");
        @(posedge axis_clk) config_write0(12'h00, 32'h0000_0001);    // ap_start = 1
        $display("----End the coefficient input(AXI-lite)----");
        
        wait(split);

        config_write1(12'h10, data_length1);
        config_write1(12'h14, coef_length1);
        for(k=0; k< `Coef_Num1; k=k+1) begin
            //config_write(12'h80+4*k, coef1[k]);
            config_read_check2(12'h80+4*k, coef1[k], 32'hffffffff);
            config_read_check2(12'h00, 32'h04, 32'h0000_0004); // check ap_idle = 1 (0x00 [bit 2])
            config_read_check2(12'h00, 32'h00, 32'h0000_0002); // check done= 0
        end
        awvalid <= 0; wvalid <= 0;
        arvalid <= 0;
        // read-back and check
        $display(" Check Coefficient ...");
        $display(" Tape programming done ...");
        $display(" Start FIR");
        @(posedge axis_clk) config_write1(12'h00, 32'h0000_0001);    // ap_start = 1
        $display("----End the coefficient input(AXI-lite)----");

        wait(split);

        config_write2(12'h10, data_length2);
        config_write2(12'h14, coef_length2);
        for(k=0; k< `Coef_Num2; k=k+1) begin
            config_write2(12'h80+4*k, coef2[k]);
            config_read_check1(12'h80+4*k, coef2[k], 32'hffffffff);
            config_read_check1(12'h00, 32'h04, 32'h0000_0004); // check ap_idle = 1 (0x00 [bit 2])
            config_read_check1(12'h00, 32'h00, 32'h0000_0002); // check done= 0
        end
        awvalid <= 0; wvalid <= 0;
        arvalid <= 0;
        // read-back and check
        $display(" Check Coefficient ...");
        $display(" Tape programming done ...");
        $display(" Start FIR");
        @(posedge axis_clk) config_write2(12'h00, 32'h0000_0001);    // ap_start = 1
        $display("----End the coefficient input(AXI-lite)----");
        
        wait(split);

        config_write2(12'h10, data_length3);
        config_write2(12'h14, coef_length3);
        for(k=0; k< `Coef_Num3; k=k+1) begin
            config_write2(12'h80+4*k, coef3[k]);
            config_read_check2(12'h80+4*k, coef3[k], 32'hffffffff);
            config_read_check2(12'h00, 32'h04, 32'h0000_0004); // check ap_idle = 1 (0x00 [bit 2])
            config_read_check2(12'h00, 32'h00, 32'h0000_0002); // check done= 0
        end
        awvalid <= 0; wvalid <= 0;
        arvalid <= 0;
        // read-back and check
        $display(" Check Coefficient ...");
        $display(" Tape programming done ...");
        $display(" Start FIR");
        @(posedge axis_clk) config_write2(12'h00, 32'h0000_0001);    // ap_start = 1
        wait_axilite_finish = 1;
        $display("----End the coefficient input(AXI-lite)----");
    end

    task config_write0;
        input [11:0]    addr;
        input [31:0]    data;
        begin
            @(posedge axis_clk);
            awvalid <= 1; awaddr <= addr;
            wvalid  <= 1; 
            wdata <= data;
            fork
                begin
                    @(posedge axis_clk);
                    while (!awready) @(posedge axis_clk);
                    awvalid<=0;
                    awaddr<=0;
                end
                begin
                    @(posedge axis_clk);
                    while (!wready) @(posedge axis_clk);
                    wvalid<=0;   
                    wdata<=0;                 
                end
            join 
        end
    endtask

    task config_write1;
        input [11:0]    addr;
        input [31:0]    data;
        begin
            @(posedge axis_clk);
            awvalid <= 1; awaddr <= addr;
            wdata <= data;
            repeat(4) @(posedge axis_clk);
            wvalid  <= 1;
            fork
                begin
                    @(posedge axis_clk);
                    while (!awready) @(posedge axis_clk);
                    awvalid<=0;
                    awaddr<=0;
                end
                begin
                    @(posedge axis_clk);
                    while (!wready) @(posedge axis_clk);
                    wvalid<=0;   
                    wdata<=0;                 
                
                end
            join 
        end
    endtask

    task config_write2;
        input [11:0]    addr;
        input [31:0]    data;
        begin
            @(posedge axis_clk);
            wvalid  <= 1;
            repeat(3) @(posedge axis_clk);
            awvalid <= 1; awaddr <= addr;
            wdata <= data;
            fork
                begin
                    @(posedge axis_clk);
                    while (!awready) @(posedge axis_clk);
                    awvalid<=0;
                    awaddr<=0;
                end
                begin
                    @(posedge axis_clk);
                    while (!wready) @(posedge axis_clk);
                    wvalid<=0;   
                    wdata<=0;                 
                
                end
            join 
        end
    endtask

    task config_read_check0;
        input [11:0]        addr;
        input signed [31:0] exp_data;
        input [31:0]        mask;
        begin
            //@(posedge axis_clk);
            arvalid <= 1; araddr <= addr;
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
                    while (!(rvalid && rready)) @(posedge axis_clk);
                    if( (rdata & mask) != (exp_data & mask)) begin
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

    task config_read_check1;
        input [11:0]        addr;
        input signed [31:0] exp_data;
        input [31:0]        mask;
        begin
            @(posedge axis_clk);
            arvalid <= 1; araddr <= addr;
            rready <= 0;
            fork 
                begin
                    @(posedge axis_clk);
                    while (!arready) @(posedge axis_clk);
                    arvalid<=0;
                    araddr<=0;
                end
                begin
                    while (!rvalid) @(posedge axis_clk);
                    rready <= 1;
                    while (!(rvalid && rready)) @(posedge axis_clk);
                    if( (rdata & mask) != (exp_data & mask)) begin
                        $display("ERROR: exp = %d, rdata = %d", exp_data, rdata);
                        error_coef <= 1;
                    end else begin
                        $display("OK: exp = %d, rdata = %d", exp_data, rdata);
                    end
                    @(posedge axis_clk);
                    rready<=0;                

                end
            join 
        end
    endtask

    task config_read_check2;
        input [11:0]        addr;
        input signed [31:0] exp_data;
        input [31:0]        mask;
        begin
            @(posedge axis_clk);
            arvalid <= 1; araddr <= addr;
            rready <= 0;
            fork 
                begin
                    @(posedge axis_clk);
                    while (!arready) @(posedge axis_clk);
                    arvalid<=0;
                    araddr<=0;
                end
                begin
                    while (!rvalid) @(posedge axis_clk);
                    repeat(3) @(posedge axis_clk); 
                    rready <= 1;
                    while (!(rvalid && rready)) @(posedge axis_clk);
                    if( (rdata & mask) != (exp_data & mask)) begin
                        $display("ERROR: exp = %d, rdata = %d", exp_data, rdata);
                        error_coef <= 1;
                    end else begin
                        $display("OK: exp = %d, rdata = %d", exp_data, rdata);
                    end
                    @(posedge axis_clk);
                    rready<=0;                

                end
            join 
        end
    endtask

    task axi_stream_master0;
        input  signed [31:0] in1;
        begin
            @(posedge axis_clk);
            ss_tvalid <= 1;
            ss_tdata  <= in1;
            @(posedge axis_clk);
            while (!ss_tready) @(posedge axis_clk);
            ss_tvalid <= 0;
            ss_tdata <=0;
        end
    endtask

    task axi_stream_master1;
        input  signed [31:0] in1;
        begin
            repeat(5) @(posedge axis_clk);
            ss_tvalid <= 1;
            ss_tdata  <= in1;
            @(posedge axis_clk);
            while (!ss_tready) @(posedge axis_clk);
            ss_tvalid <= 0;
            ss_tdata <=0;
        end
    endtask

    task axi_stream_master2;
        input  signed [31:0] in1;
        begin
            repeat(40) @(posedge axis_clk);
            ss_tvalid <= 1;
            ss_tdata  <= in1;
            @(posedge axis_clk);
            while (!ss_tready) @(posedge axis_clk);
            ss_tvalid <= 0;
            ss_tdata <=0;
        end
    endtask

    task axi_stream_master3;
        input  signed [31:0] in1;
        begin
            repeat(40) @(posedge axis_clk);
            ss_tvalid <= 1;
            ss_tdata  <= in1;
            @(posedge axis_clk);
            while (!ss_tready) @(posedge axis_clk);
            ss_tvalid <= 0;
            ss_tdata <=0;
        end
    endtask

    task sm0;
        input   signed [31:0] in2; // golden data
        input         [31:0] pcnt; // pattern count
        begin
            sm_tready <= 1;
            @(posedge axis_clk);
            while(!sm_tvalid) @(posedge axis_clk);
            sm_tready <=0;
            if (sm_tdata != in2) begin
                $display("[ERROR] [Pattern %d] Golden answer: %d, Your answer: %d", pcnt, in2, sm_tdata);
                error <= 1;
            end
            else begin
                $display("[PASS] [Pattern %d] Golden answer: %d, Your answer: %d", pcnt, in2, sm_tdata);
            end
        end
    endtask

    task sm1;
        input   signed [31:0] in2; // golden data
        input         [31:0] pcnt; // pattern count
        begin
            repeat(35)  @(posedge axis_clk);
            sm_tready <= 1;
            @(posedge axis_clk);
            while(!sm_tvalid) @(posedge axis_clk);
            sm_tready <=0;
            if (sm_tdata != in2) begin
                $display("[ERROR] [Pattern %d] Golden answer: %d, Your answer: %d", pcnt, in2, sm_tdata);
                error <= 1;
            end
            else begin
                $display("[PASS] [Pattern %d] Golden answer: %d, Your answer: %d", pcnt, in2, sm_tdata);
            end
        end
    endtask

    task sm2;
        input   signed [31:0] in2; // golden data
        input         [31:0] pcnt; // pattern count
        begin
            repeat(6) @(posedge axis_clk);
            sm_tready <= 1;
            @(posedge axis_clk);
            while(!sm_tvalid) @(posedge axis_clk);
            sm_tready <=0;
            if (sm_tdata != in2) begin
                $display("[ERROR] [Pattern %d] Golden answer: %d, Your answer: %d", pcnt, in2, sm_tdata);
                error <= 1;
            end
            else begin
                $display("[PASS] [Pattern %d] Golden answer: %d, Your answer: %d", pcnt, in2, sm_tdata);
            end
        end
    endtask
endmodule