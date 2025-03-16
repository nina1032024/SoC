`timescale 1ns / 1ps
`define SDFFILE  "../syn/netlist/fir_syn.sdf"
`define Tape_Num_First 25
`define Tape_Num_Third 32
`define Data_Num 600
`define pADDR_WIDTH 12
`define pDATA_WIDTH 32
`define Cycle 10

module fir_tb ();

  wire                        awready;
  wire                        wready;
  reg                         awvalid;
  reg   [(`pADDR_WIDTH-1): 0]  awaddr;
  reg                         wvalid;
  reg signed [(`pDATA_WIDTH-1) : 0] wdata;
  wire                        arready;
  reg                         rready;
  reg                         arvalid;
  reg         [(`pADDR_WIDTH-1): 0] araddr;
  wire                        rvalid;
  wire signed [(`pDATA_WIDTH-1): 0] rdata;
  reg                         ss_tvalid;
  reg signed [(`pDATA_WIDTH-1) : 0] ss_tdata;
  reg                         ss_tlast;
  wire                        ss_tready;
  reg                         sm_tready;
  wire                        sm_tvalid;
  wire signed [(`pDATA_WIDTH-1) : 0] sm_tdata;
  wire                        sm_tlast;
  reg                         axis_clk;
  reg                         axis_rst_n;

// ram for tap
  wire [3:0]               tap_WE;
  wire                     tap_EN;
  wire [(`pDATA_WIDTH-1):0] tap_Di;
  wire [(`pADDR_WIDTH-1):0] tap_A;
  wire [(`pDATA_WIDTH-1):0] tap_Do;

// ram for data RAM
  wire [3:0]               data_WE;
  wire                     data_EN;
  wire [(`pDATA_WIDTH-1):0] data_Di;
  wire [(`pADDR_WIDTH-1):0] data_A;
  wire [(`pDATA_WIDTH-1):0] data_Do;

  wire [(`pADDR_WIDTH-1):0] araddr_latch;
  wire [8:0] tap_cnt;
  wire [4:0] x_w_cnt;
  wire [4:0] x_r_cnt;
  wire [(`pDATA_WIDTH-1):0] x;
  wire [(`pDATA_WIDTH-1):0] h;
  wire [(`pDATA_WIDTH-1):0] ss_tdata_latch;
  wire [(`pDATA_WIDTH-1):0] mul;
  wire [(`pDATA_WIDTH-1):0] y;
  wire [31:0] y_cnt;
  wire [1:0] data_state;
  wire [1:0] state;
  wire [2:0] ap_ctrl;


  fir #(
    .pADDR_WIDTH(`pADDR_WIDTH),
    .pDATA_WIDTH(`pDATA_WIDTH)
  ) fir_DUT (
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
    .axis_rst_n(axis_rst_n),
    .araddr_latch(araddr_latch),
    .tap_cnt(tap_cnt),
    .x_w_cnt(x_w_cnt),
    .x_r_cnt(x_r_cnt),
    .x(x),
    .h(h),
    .ss_tdata_latch(ss_tdata_latch),
    .mul(mul),
    .y(y),
    .y_cnt(y_cnt),
    .data_state(data_state),
    .state(state),
    .ap_ctrl(ap_ctrl)


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

  reg signed [(`pDATA_WIDTH-1):0] Din_list[0:(`Data_Num-1)];
  reg signed [(`pDATA_WIDTH-1):0] golden_list[0:(`Data_Num-1)];
  reg signed [(`pDATA_WIDTH-1):0] coef[0:(`Tape_Num_First-1)];
  reg signed [(`pDATA_WIDTH-1):0] Din_list_second[0:(`Data_Num-1)];
  reg signed [(`pDATA_WIDTH-1):0] golden_list_second[0:(`Data_Num-1)];
  reg signed [(`pDATA_WIDTH-1):0] coef_third[0:(`Tape_Num_Third-1)];
  reg signed [(`pDATA_WIDTH-1):0] Din_list_third[0:(`Data_Num-1)];
  reg signed [(`pDATA_WIDTH-1):0] golden_list_third[0:(`Data_Num-1)];
  `ifdef VCD
    initial begin
      $dumpfile("fir.vcd");
      $dumpvars();
    end
  `elsif
    initial begin
      $fsdbDumpfile("fir.fsdb");
      $fsdbDumpvars("+mda");
    end
  `endif

  `ifdef SDF
    initial $sdf_annotate(`SDFFILE, fir_DUT);
  `endif

  initial begin
    axis_clk = 0;
    forever begin
      #(`Cycle/2) axis_clk = (~axis_clk);
    end
  end

  reg [31:0]  data_length, data_length_second, data_length_third;
  reg [31:0] coef_length, coef_length_third;
  integer Din, golden, coef_in, input_data, golden_data, m, n, coef_data;
  integer Din_second, golden_second, input_data_second, golden_data_second, o, coef_data_second;
  integer Din_third, golden_third, coef_in_third, input_data_third, golden_data_third, p, q, coef_data_third;
  initial begin
    data_length = 0;
    coef_length = 0;
    data_length_second = 0;
    data_length_third = 0;
    coef_length_third = 0;
    Din = $fopen("x.dat","r");
    golden = $fopen("y.dat","r");
	  coef_data= $fopen("coef.dat","r");
    Din_second = $fopen("x2.dat", "r");
    golden_second = $fopen("y2.dat", "r");
    Din_third = $fopen("x3.dat", "r");
    golden_third = $fopen("y3.dat", "r");
    coef_data_third = $fopen("coef3.dat", "r");

    for (m = 0; m< `Data_Num; m = m + 1) begin
      input_data = $fscanf(Din,"%d", Din_list[m]);
      golden_data = $fscanf(golden,"%d", golden_list[m]);
      data_length = data_length + 1;
    end
    for (n = 0; n < `Tape_Num_First ; n = n + 1) begin 
      coef_in=$fscanf(coef_data,"%d", coef[n]);
      coef_length = coef_length + 1;
    end
    for (o=0;o< `Data_Num ;o=o+1) begin
      input_data_second = $fscanf(Din_second,"%d", Din_list_second[o]);
      golden_data_second = $fscanf(golden_second,"%d", golden_list_second[o]);
      data_length_second = data_length_second + 1;
    end
    for (p = 0;p < `Data_Num; p = p + 1) begin
      input_data_third = $fscanf(Din_third, "%d", Din_list_third[p]);
      golden_data_third = $fscanf(golden_third, "%d", golden_list_third[p]);
      data_length_third = data_length_third + 1;
    end
    for (q = 0; q < `Tape_Num_Third; q = q + 1) begin
      coef_in_third = $fscanf(coef_data_third, "%d", coef_third[q]);
      coef_length_third = coef_length_third + 1;
    end
  end

  initial begin
    axis_rst_n = 0;
    @(posedge axis_clk); 
    @(posedge axis_clk);
    axis_rst_n = 1;
  end
  
  //Prevent hang
  integer timeout = (1000000);
  initial begin
    while(timeout > 0) begin
        @(posedge axis_clk);
        timeout = timeout - 1;
    end
    $display($time, "Simualtion Hang ....");
    $finish;
  end


  integer k, round_over;
  reg error_coef, error;
  initial begin
    arvalid=0;
    rready=0;
    awvalid=0;
    wvalid=0;
    error_coef = 0;
    $display("----Start the coefficient input(AXI-lite)(First round)----");
    config_write(12'h10, data_length);
    config_write(12'h14, coef_length);
    for(k=0; k< `Tape_Num_First; k=k+1) begin
      config_write(12'h80+4*k, coef[k]);
    end
    awvalid <= 0; wvalid <= 0;
    $display(" Check Coefficient (First Round)...");
    for(k=0; k < `Tape_Num_First; k=k+1) begin
      config_read_check_first(12'h80+4*k, coef[k], 32'hffffffff);
    end
    arvalid <= 0;
    $display(" Tape programming done ...");
    $display(" Start FIR");
    @(posedge axis_clk) config_write(12'h00, 32'h0000_0001);    // ap_start = 1
    $display("----End the coefficient input(AXI-lite)(First round)----");
    
    wait(round_over == 1);
    @(posedge axis_clk);

    arvalid=0;
    rready=0;
    awvalid=0;
    wvalid=0;
    config_write(12'h10, data_length_second);
    config_write(12'h14, coef_length);
    $display("----Start the coefficient input(AXI-lite)(Second round)----");
    $display(" Check Coefficient (Same as First Round)...");
    for(k=0; k < `Tape_Num_First; k=k+1) begin
      config_read_check_second(12'h80+4*k, coef[k], 32'hffffffff);
    end
    arvalid <= 0;
    $display(" Tape programming done ...");
    $display(" Start FIR");
    @(posedge axis_clk) config_write(12'h00, 32'h0000_0001);
    $display("----End the coefficient input(AXI-lite)(Second round)----");

    wait(round_over == 1);
    @(posedge axis_clk);

    $display("----Start the coefficient input(AXI-lite)(Third round)----");
    arvalid=0;
    rready=0;
    awvalid=0;
    wvalid=0;
    config_write(12'h10, data_length_third);
    config_write(12'h14, coef_length_third);
    for(k=0; k< `Tape_Num_Third; k=k+1) begin
      config_write_third(12'h80+4*k, coef_third[k]);
    end
    awvalid <= 0; wvalid <= 0;
    $display(" Check Coefficient (Third Round)...");
    for(k=0; k< `Tape_Num_Third; k=k+1) begin
      config_read_check_third(12'h80+4*k, coef_third[k], 32'hffffffff);
    end
    arvalid <= 0;
    $display(" Tape programming done ...");
    $display(" Start FIR");
    @(posedge axis_clk) config_write(12'h00, 32'h0000_0001);
    $display("----End the coefficient input(AXI-lite)(Third round)----");

  end

  integer i;
    initial begin
    $display("------------Start simulation(First Round)-----------");
    ss_tvalid = 0;
    $display("----Start the data input(AXI-Stream)(First Round)----");
      for (i=0;i<(data_length-1);i=i+1) begin
        ss_tlast = 0; axi_stream_master_first(Din_list[i]);
        config_read_check_first(12'h00, 32'h00, 32'h0000_0002);
        config_write(12'h10, 10);
      end
      //config_read_check_first(12'h00, 32'h00, 32'h0000_0002); // check idle = 0
      ss_tlast = 1; axi_stream_master_first(Din_list[(`Data_Num - 1)]);
      ss_tlast = 0;
      $display("------End the data input(AXI-Stream)(First Round)------");

      wait(round_over == 1);
      @(posedge axis_clk);

      $display("------------Start simulation(Second Round)-----------");
      ss_tvalid = 0;
      $display("----Start the data input(AXI-Stream)(Second Round)----");
      for (i=0;i<(data_length_second-1);i=i+1) begin
        ss_tlast = 0; axi_stream_master_second(Din_list_second[i]);
        config_read_check_second(12'h00, 32'h00, 32'h0000_0002);
        config_write(12'h14, 10);
      end
      ss_tlast = 1; axi_stream_master_second(Din_list_second[(`Data_Num - 1)]);
      ss_tlast = 0;
      $display("------End the data input(AXI-Stream)(Second Round)------");

      wait(round_over == 1);
      @(posedge axis_clk);

      $display("------------Start simulation(Third Round)-----------");
      ss_tvalid = 0;
      $display("----Start the data input(AXI-Stream)(Third Round)----");
      for (i=0;i<(data_length_third-1);i=i+1) begin
        ss_tlast = 0; axi_stream_master_third(Din_list_third[i]);
        config_read_check_third(12'h00, 32'h00, 32'h0000_0002);
      end
      ss_tlast = 1; axi_stream_master_third(Din_list_third[(`Data_Num - 1)]);
      ss_tlast = 0;
      $display("------End the data input(AXI-Stream)(Third Round)------");
    end


  integer l;
  initial begin
    wait(axis_rst_n==0);
    wait(axis_rst_n==1);
    round_over = 0;
    error = 0;
    sm_tready = 0;
    for(l=0;l < data_length;l=l+1) begin
      sm(golden_list[l],l);
    end
    config_read_check_first(12'h00, 32'h02, 32'h0000_0002); // check ap_done = 1 (0x00 [bit 1])
    config_read_check_first(12'h00, 32'h04, 32'h0000_0004); // check ap_idle = 1 (0x00 [bit 2])
    round_over = 1;
    @(posedge axis_clk);
    round_over = 0;
    sm_tready = 0;
    for(l=0;l < data_length_second;l=l+1) begin
      sm_second(golden_list_second[l],l);
    end
    config_read_check_second(12'h00, 32'h02, 32'h0000_0002); // check ap_done = 1 (0x00 [bit 1])
    config_read_check_second(12'h00, 32'h04, 32'h0000_0004); // check ap_idle = 1 (0x00 [bit 2])
    
    round_over = 1;
    @(posedge axis_clk);
    round_over = 0;

    sm_tready = 0;
    for(l=0;l < data_length_third;l=l+1) begin
      sm_third(golden_list_third[l],l);
    end
    config_read_check_third(12'h00, 32'h02, 32'h0000_0002); // check ap_done = 1 (0x00 [bit 1])
    config_read_check_third(12'h00, 32'h04, 32'h0000_0004); // check ap_idle = 1 (0x00 [bit 2])

    if (error == 0 & error_coef == 0) begin
      $display("---------------------------------------------");
      $display("-----------Congratulations! Pass-------------");
    end else begin
      $display("--------Simulation Failed---------");
    end
    $finish;
  end

task config_write;
  input [11:0]    addr;
  input [31:0]    data;
  integer random_delay_aw, random_delay_w;
  begin
    random_delay_aw = ( $random % 10 + 10 ) % 10 + 1;;
    random_delay_w = ( $random % 10 + 10 ) % 10 + 1;;
    fork
      begin
        repeat (random_delay_aw) @(posedge axis_clk);
        awvalid <= 1; awaddr <= addr;
        @(posedge axis_clk);
        while (!awready) @(posedge axis_clk);
          awvalid <= 0;
		      awaddr <= 0;
      end
      begin
        repeat (random_delay_w) @(posedge axis_clk);
        wvalid <= 1; wdata <= data;
        @(posedge axis_clk);
        while (!wready) @(posedge axis_clk);
          wvalid <= 0;                    
          wdata <= 0;
      end
    join 
	  repeat (( $random % 10 + 10 ) % 10 + 1) @(posedge axis_clk);
    end
endtask

task config_write_third;
  input [11:0]    addr;
  input [31:0]    data;
  begin
    fork
      begin
        awvalid <= 1; awaddr <= addr;
        @(posedge axis_clk);
        while (!awready) @(posedge axis_clk);
        awvalid <= 0;
		    awaddr <= 0;
      end
      begin
        wvalid <= 1; wdata <= data;
        @(posedge axis_clk);
        while (!wready) @(posedge axis_clk);
        wvalid <= 0;                    
        wdata <= 0;
      end
    join 
	  @(posedge axis_clk);
    end
endtask



task config_read_check_first;
  input [11:0]        addr;
  input signed [31:0] exp_data;
  input [31:0]        mask;
  integer random_delay_ar, random_delay_r;
  begin
    random_delay_ar = ( $random % 10 + 10 ) % 10 + 1;
    random_delay_r = ( $random % 10 + 10 ) % 10 + 1;
    fork 
      begin
        repeat (random_delay_ar) @(posedge axis_clk);
        arvalid <= 1; araddr <= addr;
        @(posedge axis_clk);
        while (!arready) @(posedge axis_clk);
          arvalid<=0;
		      araddr<=0;
      end
      begin
        repeat (random_delay_r) @(posedge axis_clk);
        rready <= 1;
        @(posedge axis_clk);
        while (!rvalid) @(posedge axis_clk);
        //repeat (random_delay_r) @(posedge axis_clk);
        //rready <= 1;
        //@(posedge axis_clk);
        if( (rdata & mask) != (exp_data & mask)) begin
          $display("(Round 1) ERROR: exp = %d, rdata = %d", exp_data, rdata);
          error_coef <= 1;
        end else begin
          $display("(Round 1) OK: exp = %d, rdata = %d", exp_data, rdata);
        end
          rready<=0;                
      end
    join 
	  repeat (($random % 10 + 10) % 10 + 1) @(posedge axis_clk);
  end
endtask

task config_read_check_second;
  input [11:0]        addr;
  input signed [31:0] exp_data;
  input [31:0]        mask;
  begin
    fork
      begin
        repeat (30) @(posedge axis_clk);
        arvalid <= 1; araddr <= addr;
        @(posedge axis_clk);
        while (!arready) @(posedge axis_clk);
          arvalid<=0;
		      araddr<=0;
      end
      begin
        while (!rvalid) @(posedge axis_clk);
        repeat (5) @(posedge axis_clk);
        rready <= 1;
        @(posedge axis_clk);
        if( (rdata & mask) != (exp_data & mask)) begin
          $display("(Round 2) ERROR: exp = %d, rdata = %d", exp_data, rdata);
          error_coef <= 1;
        end else begin
          $display("(Round 2) OK: exp = %d, rdata = %d", exp_data, rdata);
        end
          rready<=0;                
      end
    join 
	  repeat (30) @(posedge axis_clk);
  end
endtask

task config_read_check_third;
  input [11:0]        addr;
  input signed [31:0] exp_data;
  input [31:0]        mask;
  integer random_delay_ar, random_delay_r;
  begin
    fork 
      begin
        arvalid <= 1; araddr <= addr;
        @(posedge axis_clk);
        while (!arready) @(posedge axis_clk);
          arvalid<=0;
		      araddr<=0;
      end
      begin
        rready <= 1;
        @(posedge axis_clk);
        while (!rvalid) @(posedge axis_clk);
        if( (rdata & mask) != (exp_data & mask)) begin
          $display("(Round 3) ERROR: exp = %d, rdata = %d", exp_data, rdata);
          error_coef <= 1;
        end else begin
          $display("(Round 3) OK: exp = %d, rdata = %d", exp_data, rdata);
        end
          rready<=0;                
      end
    join 
  end
endtask





task axi_stream_master_first;
  input  signed [31:0] in1;
  integer random_delay_ss;
  begin
    random_delay_ss = ( $random % 10 + 10 ) % 10 + 1;
    repeat (random_delay_ss) @(posedge axis_clk);
    ss_tvalid <= 1;
    ss_tdata  <= in1;
    @(posedge axis_clk);
    while (!ss_tready) @(posedge axis_clk);
    ss_tvalid <= 0;
  end
endtask

task axi_stream_master_second;
  input  signed [31:0] in1;
  integer random_delay_ss;
  begin
    repeat (40) @(posedge axis_clk);
    ss_tvalid <= 1;
    ss_tdata  <= in1;
    @(posedge axis_clk);
    while (!ss_tready) @(posedge axis_clk);
    ss_tvalid <= 0;
  end
endtask

task axi_stream_master_third;
  input  signed [31:0] in1;
  integer random_delay_ss;
  begin
    ss_tvalid <= 1;
    ss_tdata  <= in1;
    @(posedge axis_clk);
    while (!ss_tready) @(posedge axis_clk);
  end
endtask

task sm;
  input   signed [31:0] in2; // golden data
  input         [31:0] pcnt; // pattern count
  integer random_delay_sm;
  begin
    random_delay_sm = ( $random % 10 + 10 ) % 10 + 1;
    repeat (random_delay_sm) @(posedge axis_clk);
    sm_tready <= 1;
    @(posedge axis_clk);
    while(!sm_tvalid) @(posedge axis_clk);
    sm_tready <=0;
    if (sm_tdata != in2) begin
      $display("[ERROR] [Round 1] [Pattern %d] Golden answer: %d, Your answer: %d", pcnt, in2, sm_tdata);
      error <= 1;
    end else begin
      $display("[PASS] [Round 1] [Pattern %d] Golden answer: %d, Your answer: %d", pcnt, in2, sm_tdata);
    end
  end
endtask

task sm_second;
  input   signed [31:0] in2; // golden data
  input         [31:0] pcnt; // pattern count
  integer random_delay_sm;
  begin
    repeat (30) @(posedge axis_clk);
    sm_tready <= 1;
    @(posedge axis_clk);
    while(!sm_tvalid) @(posedge axis_clk);
    sm_tready <=0;
    if (sm_tdata != in2) begin
      $display("[ERROR] [Round 2] [Pattern %d] Golden answer: %d, Your answer: %d", pcnt, in2, sm_tdata);
      error <= 1;
    end else begin
      $display("[PASS] [Round 2] [Pattern %d] Golden answer: %d, Your answer: %d", pcnt, in2, sm_tdata);
    end
  end
endtask

task sm_third;
  input   signed [31:0] in2; // golden data
  input         [31:0] pcnt; // pattern count
  integer random_delay_sm;
  begin
    sm_tready <= 1;
    @(posedge axis_clk);
    while(!sm_tvalid) @(posedge axis_clk);
    if (sm_tdata != in2) begin
      $display("[ERROR] [Round 3] [Pattern %d] Golden answer: %d, Your answer: %d", pcnt, in2, sm_tdata);
      error <= 1;
    end else begin
      $display("[PASS] [Round 3] [Pattern %d] Golden answer: %d, Your answer: %d", pcnt, in2, sm_tdata);
    end
  end
endtask

endmodule