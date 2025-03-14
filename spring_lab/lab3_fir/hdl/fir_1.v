module fir
    #(  parameter pADDR_WIDTH = 12,
        parameter pDATA_WIDTH = 32
        // sram length
     )
     (
         // AXI4-Lite for configuration
         // write channel
         output  reg                      awready,  // write address ready
         output  reg                      wready,   // write data    ready
         input   wire                     awvalid,  // write address valid
         input   wire [(pADDR_WIDTH-1):0] awaddr,   // write address
         input   wire                     wvalid,   // write data    valid
         input   wire [(pDATA_WIDTH-1):0] wdata,    // write data
         //read channel
         output  reg                      arready,  // read  address ready
         input   wire                     rready,   // read  data    ready
         input   wire                     arvalid,  // read  address valid
         input   wire [(pADDR_WIDTH-1):0] araddr,   // read  address
         output  reg                      rvalid,   // read  data    valid
         output  reg [(pDATA_WIDTH-1):0]  rdata,   // read  data

         // AXI4-Stream slave for x input, SS bus
         input   wire                     ss_tvalid,
         input   wire [(pDATA_WIDTH-1):0] ss_tdata,
         input   wire                     ss_tlast,
         output  reg                      ss_tready,

         // AXI4-Stream master for y output, SM bus
         input   wire                     sm_tready,
         output  reg                      sm_tvalid,
         output  reg [(pDATA_WIDTH-1):0] sm_tdata,
         output  reg                      sm_tlast,

         // bram for tap RAM
         output  reg [3:0]                tap_WE,
         output  reg                      tap_EN,
         output  reg [(pDATA_WIDTH-1):0]  tap_Di,
         output  reg [(pADDR_WIDTH-1):0]  tap_A,
         input   wire [(pDATA_WIDTH-1):0] tap_Do,

         // bram for data RAM
         output  reg [3:0]                data_WE,
         output  reg                      data_EN,
         output  reg  [(pDATA_WIDTH-1):0] data_Di,
         output  reg  [(pADDR_WIDTH-1):0] data_A,
         input   wire [(pDATA_WIDTH-1):0] data_Do,

         input   wire                     axis_clk,
         input   wire                     axis_rst_n,

         output [(pADDR_WIDTH-1):0] araddr_latch
     );

    reg [2:0] ap_ctrl;

// FSM states
    localparam IDLE = 2'b00;
    localparam CALC = 2'b10;
    localparam DONE = 2'b11;

    localparam RIDLE  = 1'b0;
    localparam RVALID = 1'b1;

// axi-lite interface : write channel, read channel
    wire awready_tmp;
    wire wready_tmp;
    wire arready_tmp;
    //reg [(pDATA_WIDTH-1):0] rdata_tmp;

    always @(posedge axis_clk or negedge axis_rst_n) begin
        if (!axis_rst_n) begin
            awready <= 1'b0;
            wready  <= 1'b0;
            arready <= 1'b0;
        end else begin
            awready <= awready_tmp;    
            wready  <= wready_tmp;     
            arready <= arready_tmp;      
        end
    end

    // axilite write
        // synchronization of address and data 
        // signal only last for one cycle
    assign awready_tmp = awvalid && wvalid  & (~wready); 
    assign wready_tmp  = awvalid && wvalid  & (~wready);

    // axilite read
        // first get address then return data
        // signal only last for one cycle
    assign arready_tmp = arvalid && (~arready);

    // latch rvalid till rready (use fsm)
    reg read_state, next_read_state;
    reg next_rvalid;
    always@* begin
        case(read_state)
            RIDLE: begin
                if(arvalid && arready) begin
                    next_read_state = RVALID;
                    next_rvalid = 1;
                end else begin
                    next_read_state = RIDLE;
                    next_rvalid = 0;
                end
            end
            RVALID: begin
                if(rready) begin
                    next_read_state = RIDLE;
                    next_rvalid = 0;
                end else begin
                    next_read_state = RVALID;
                    next_rvalid = 1;
                end
            end
        endcase
    end
    
    always@(posedge axis_clk or negedge axis_rst_n) begin
        if(!axis_rst_n) begin
            read_state <= RIDLE;
            rvalid <= 1'b0;
        end else begin
            read_state <= next_read_state;
            rvalid <= next_rvalid;
        end
    end

    // latch araddr
    wire [(pADDR_WIDTH-1):0] araddr_latch;
    assign araddr_latch = (arvalid && arready) ? araddr : araddr_latch;

    // read data contains read data_len, tap_num, coefficient, state
    always @* begin
        if(rvalid) begin
            if(araddr_latch == 12'h00) rdata = ap_ctrl;
            else if (araddr_latch == 12'h10) rdata = data_length;
            else if (araddr_latch == 12'h14) rdata = tap_num;
            else if (araddr_latch >=  12'h80 && araddr_latch <= 12'hFF) rdata = tap_Do;
            else rdata = 12'hFFFFFFFF;
        end else begin
            rdata = 12'hFFFFFFFF;
        end
    end

// configuration register
    // FSM for fir operation
    reg [1:0] state, next_state;

    always@* begin
        case(state)
            IDLE : begin
                if(awaddr == 12'h00 && wdata[0] == 1'b1 && awvalid && wvalid) begin    // ap_start = 1
                    next_state = CALC;
                end else begin
                    next_state = IDLE;
                end
            end
            CALC : begin
                if(sm_tvalid && sm_tlast) begin                                       // transfer last data of y
                    next_state = DONE;
                end else begin
                    next_state = CALC;
                end
            end
            DONE : begin
                if(araddr == 12'h00 && arvalid && rvalid && rready && arready) begin  // read address 0x00
                    next_state = IDLE;
                end else begin
                    next_state = DONE;
                end
            end
            default : begin
                if(awvalid && wvalid && (awaddr == 12'h10 || awaddr == 12'h14)) begin
                    next_state = CALC;
                end else begin
                    next_state = IDLE;
                end
            end
        endcase
    end

    always@(posedge axis_clk or negedge axis_rst_n) begin
        if(!axis_rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // 0x00: ap_ctrl = {ap_idle, ap_done, ap_start}

    // 要用sequential 
    always @(posedge axis_clk or negedge axis_rst_n) begin

        ap_ctrl[0] = (awaddr == 12'h00 && wdata [0] == 1'b1 && awvalid && wvalid && awready && wready) ? 1'b1 : 1'b0;
        ap_ctrl[1] = (state == DONE) ? 1'b1 : 1'b0;
        ap_ctrl[2] = (state == IDLE) ? 1'b1 : 1'b0;
    end

    // 0x10-14: data_length
    // 0x14-18: tap_num
    reg  [31:0] data_length;
    wire [31:0] data_length_tmp;
    reg  [31:0] tap_num;
    wire [31:0] tap_num_tmp;

    always@ (posedge axis_clk or negedge axis_rst_n) begin
        if(!axis_rst_n) begin
            data_length <= 0;
            tap_num     <= 0;
        end else begin
            data_length <= data_length_tmp;
            tap_num     <= tap_num_tmp;
        end
    end

    assign data_length_tmp = (awaddr == 12'h10 && awvalid && wvalid && awready && wready) ? wdata : data_length;
    assign tap_num_tmp     = (awaddr == 12'h14 && awvalid && wvalid && awready && wready) ? wdata : tap_num;

    // 0x80-FF: tap parameters
    // process tap parameters in tap_ram

// bram signal for tap RAM

    reg [(pADDR_WIDTH-1):0] tap_A_w_r;
    reg [4:0] tap_cnt;

    // address generator
    always@(posedge axis_clk or negedge axis_rst_n) begin
        if(!axis_rst_n) begin
            tap_cnt <= tap_num;
        end else if(state != CALC)begin
            tap_cnt <= tap_num;
        end else begin
            tap_cnt <= (tap_cnt + 1 < tap_num) ? tap_cnt + 1 : 0;
        end
    end

    // read or write tap parameters
    always@* begin
        if ((awaddr[11:0] >= 12'h80 && awaddr[11:0] <= 12'hFF) && (awvalid && wvalid && awready && wready)) begin
            tap_A_w_r = awaddr[6:0];
        end else if ((araddr_latch[11:0] >= 12'h80 && araddr_latch[11:0] <= 12'hFF)) begin
            tap_A_w_r = araddr_latch[6:0];
        end else begin
            tap_A_w_r = 12'hFFF;
        end
    end

    // bram signal
    always@* begin
        tap_EN = 1'b1;
        tap_WE = ((awvalid && wvalid && awready && wready) &&
                  (awaddr[11:0] >= 12'h80 && awaddr[11:0] <= 12'hFF)) ? 4'b1111 : 4'b0000;
        tap_Di = (awvalid && wvalid) ? wdata : 12'h00;
        tap_A = (state == CALC) ? 4 * tap_cnt : tap_A_w_r;
    end

// axi-stream for x input
    // ss bus
    wire ss_tready_tmp;

    always@(posedge axis_clk or negedge axis_rst_n) begin
        if(!axis_rst_n) begin
            ss_tready <= 1'b0;
        end else begin
            ss_tready <= ss_tready_tmp & (~ss_tready);
        end
    end    

    assign ss_tready_tmp = (state == CALC) && ss_tvalid && (tap_cnt == tap_num - 1);


// bram for data RAM
    // 可以把沒有用到的dataRAM 用來當作latch
    // 可以直接寫，不用先存再寫，但問題是要hold 住(費時)
    // 用latch hold 住(用面積換時間)

    // address generator for newly stored data (up Counter)
    reg  [4:0] x_w_cnt;
    wire [4:0] x_w_cnt_tmp;

    assign x_w_cnt_tmp = (tap_cnt == tap_num - 1) ? 
             ((x_w_cnt == tap_num - 1) ? 0 : (x_w_cnt + 1)) : 
             x_w_cnt;

    always@ (posedge axis_clk or negedge axis_rst_n) begin
        if(!axis_rst_n) begin
            x_w_cnt <= tap_num - 1;
        end else if (state == IDLE) begin
            x_w_cnt <= tap_num - 1;
        end else begin 
            x_w_cnt <= x_w_cnt_tmp;
        end
    end

    // address generator for reading out data (down Counter)
    reg  [4:0] x_r_cnt;
    wire [4:0] x_r_cnt_tmp;

    assign x_r_cnt_tmp = (tap_cnt == tap_num - 1) ? 
             (x_w_cnt + 1) : 
             ((x_r_cnt == 0) ? (tap_num - 1) : (x_r_cnt - 1));

    always@ (posedge axis_clk or negedge axis_rst_n) begin
        if(!axis_rst_n) begin
            x_r_cnt <= tap_num - 1;
        end else if(ap_ctrl[0] == 1) begin
            x_r_cnt <= 0;
        end else begin
            x_r_cnt <= x_r_cnt_tmp;
        end
    end

    // bram signal (Note : initialize before axi stream input)
    always@* begin
        data_EN = 1'b1;
        data_WE = (state == CALC && ss_tvalid && ss_tready || state == IDLE) ? 4'b1111 : 4'b0000; 
        data_Di = (state == CALC && ss_tvalid && ss_tready) ? ss_tdata : 32'h00;
        data_A =  (ss_tvalid && ss_tready) ? 4 * x_w_cnt : 4 * x_r_cnt;
    end

// core engine: convolution
    wire [(pDATA_WIDTH-1):0] x;
    wire [(pDATA_WIDTH-1):0] h;
    wire [(pDATA_WIDTH-1):0] mul_tmp;
    reg  [(pDATA_WIDTH-1):0] mul;
    reg  [(pDATA_WIDTH-1):0] y;
    

    // multipler
    assign x = data_Do;
    assign h = tap_Do;

    assign mul_tmp = x * h;

    always@ (posedge axis_clk or negedge axis_rst_n) begin
        if(!axis_rst_n) begin
            mul <= 0;
        end else if(state == IDLE) begin
            mul <= 0;
        end else begin
            mul <= mul_tmp;
        end
    end

    // adder
    always@ (posedge axis_clk or negedge axis_rst_n) begin
        if(!axis_rst_n) begin
            y <=  0;
        end else if(state == IDLE) begin
            y <= 0;
        end else if (tap_cnt == 2) begin
            y <= mul;
        end else begin
            y <= y + mul;
        end
    end

// axi-stream for y 
    // counter for y valid output
    reg  [8:0] y_cnt;
    wire [8:0] y_cnt_tmp;

    always @(posedge axis_clk or negedge axis_rst_n) begin
        if(!axis_rst_n) begin
            y_cnt <= 0;
        end else if(state == IDLE) begin
            y_cnt <= 0;
        end else if(tap_cnt == 2) begin
            y_cnt <= y_cnt + 1;
        end else begin
            y_cnt <= y_cnt;
        end
    end

    // tlast for y output transfer
    wire sm_tlast_tmp;

    assign sm_tlast_tmp = (y_cnt == data_length + 1) ? 1'b1 : 1'b0;

    always@(posedge axis_clk or negedge axis_rst_n) begin
        if(!axis_rst_n) begin
            sm_tlast <= 1'b0;
        end else if(state == IDLE) begin
            sm_tlast <= 1'b0;
        end else begin
            sm_tlast <= sm_tlast_tmp;
        end
    end

    // sm bus
    wire [(pDATA_WIDTH-1):0] sm_tdata_tmp;
    wire sm_tvalid_tmp;

    always@(posedge axis_clk or negedge axis_rst_n) begin
        if(!axis_rst_n) begin
            sm_tdata <= 32'h00;
            sm_tvalid <= 1'b0;
        end else if(state == IDLE) begin
            sm_tdata <= 32'h00;
            sm_tvalid <= 1'b0;
        end else begin
            sm_tdata  <= sm_tdata_tmp;
            sm_tvalid <= sm_tvalid_tmp && (~sm_tvalid) ;
        end
    end    

    assign sm_tdata_tmp = (sm_tready && ((tap_cnt == 2) && (y_cnt >= 2))) ? y : 32'h00;
    assign sm_tvalid_tmp = (sm_tready && ((tap_cnt == 2) && (y_cnt >= 2))) ? 1'b1 : 1'b0; //ignore first output y 
    
endmodule

// 用tap_cnt, data_cnt 去控制fsm
// state machine 去控制y 甚麼時候可以clear, 以及甚麼時候可以輸出
// 用state machine 去看出datapath
