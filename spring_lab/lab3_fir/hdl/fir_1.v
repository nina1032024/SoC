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
         output  wire                     sm_tlast,

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
         input   wire                     axis_rst_n
     );

    reg [2:0] ap_ctrl;

// FSM states
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam DONE = 2'b10;

    localparam RIDLE  = 1'b0;
    localparam RVALID = 1'b1;

    localparam DT_WAIT = 2'b00;
    localparam DT_PROC = 2'b01;
    localparam DT_DONE = 2'b10;

    reg [1:0] state, next_state;
    reg  [31:0] data_length;
    wire [31:0] data_length_tmp;
    reg  [31:0] tap_num;
    wire [31:0] tap_num_tmp;

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
            else if (araddr_latch >=  12'h80 && araddr_latch <= 12'hFF) rdata = (state == IDLE) ? tap_Do : 32'hffffffff;
            else rdata = 32'hFFFFFFFF;
        end else begin
            rdata = 32'hFFFFFFFF;
        end
    end

// configuration register
    // FSM for fir operation
    

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
                if(sm_tlast) begin                                                     // transfer last data of y
                    next_state = DONE;
                end else begin
                    next_state = CALC;
                end
            end
            DONE : begin
                if(araddr == 12'h00 && rready && rvalid) begin                        // read address 0x00
                    next_state = IDLE;
                end else begin
                    next_state = DONE;
                end
            end
            default : begin
                if(awaddr == 12'h00 && wdata[0] == 1'b1 && awvalid && wvalid) begin    // ap_start = 1
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
    always @(posedge axis_clk or negedge axis_rst_n) begin

        ap_ctrl[0] = (awaddr == 12'h00 && wdata [0] == 1'b1 && awvalid && wvalid && awready && wready) ? 1'b1 : 1'b0;
        ap_ctrl[1] = (state == DONE) ? 1'b1 : 1'b0;
        ap_ctrl[2] = (state == IDLE) ? 1'b1 : 1'b0;
    end

    // 0x10-14: data_length
    // 0x14-18: tap_num
    

    always@ (posedge axis_clk or negedge axis_rst_n) begin
        if(!axis_rst_n) begin
            data_length <= 0;
            tap_num     <= 0;
        end else if (state == IDLE) begin
            data_length <= data_length_tmp;
            tap_num     <= tap_num_tmp;
        end
    end

    assign data_length_tmp = (state == IDLE && awaddr == 12'h10 && awvalid && wvalid && awready && wready) ? wdata : data_length;
    assign tap_num_tmp     = (state == IDLE && awaddr == 12'h14 && awvalid && wvalid && awready && wready) ? wdata : tap_num;

    // 0x80-FF: tap parameters
    // process tap parameters in tap_ram

// bram signal for tap RAM

    reg [(pADDR_WIDTH-1):0] tap_A_w_r;
    reg [8:0] tap_cnt;

    // address generator
    always@(posedge axis_clk or negedge axis_rst_n) begin
        if(!axis_rst_n) begin
            tap_cnt <= 0;
        end else if (state == IDLE) begin
            tap_cnt <= 0;
        end else if(ss_tvalid && ss_tready) begin
            tap_cnt <= 0;
        end else begin
            tap_cnt <=  tap_cnt + 1;
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
        tap_WE = ((state == IDLE && awvalid && wvalid && awready && wready) &&
                  (awaddr[11:0] >= 12'h80 && awaddr[11:0] <= 12'hFF)) ? 4'b1111 : 4'b0000;
        tap_Di = (awvalid && wvalid) ? wdata : 12'h00;
        tap_A = (state == CALC) ? 4 * tap_cnt : tap_A_w_r;
    end

// axi-stream for x input
    // ss bus
    
    // data transfer fsm : determine when to recieve data
    reg [1:0] data_state, next_data_state;
    reg next_ss_tready, next_sm_tvalid;
    reg [31:0] y_cnt;

    wire [8:0] tap_cnt_ready;
    assign tap_cnt_ready = (y_cnt < tap_num) ? (4 + (y_cnt - 1)) : (4 + (tap_num - 1)); 

    always@* begin
        case(data_state) 
            DT_WAIT: begin
                if(ss_tvalid) begin
                    next_data_state = DT_PROC;
                    next_sm_tvalid = 0;
                    next_ss_tready = 0;
                end else begin
                    next_data_state = DT_WAIT;
                    next_sm_tvalid = 0;
                    next_ss_tready = 1;
                end
            end
            DT_PROC: begin
                if(tap_cnt == (4 + (tap_num - 1))) begin
                    next_data_state = DT_DONE;
                    next_ss_tready = 0;
                    next_sm_tvalid = 1;
                end else begin
                    next_data_state = DT_PROC;
                    next_ss_tready = 0;
                    next_sm_tvalid = 0;
                end
            end
            DT_DONE: begin
                if(sm_tready) begin
                    next_data_state = DT_WAIT;
                    next_ss_tready = 1;
                    next_sm_tvalid = 0;
                end else begin
                    next_data_state = DT_DONE;
                    next_ss_tready = 0;
                    next_sm_tvalid = 1;
                end
            end
            default : begin
                next_data_state = DT_WAIT;
                next_sm_tvalid = 0;
                next_ss_tready = 0;
            end
        endcase
    end

    always@(posedge axis_clk or negedge axis_rst_n) begin
        if(!axis_rst_n) begin
            data_state <= DT_WAIT;
            sm_tvalid <= 0;
            ss_tready <= 0;
        end else if(state == IDLE) begin
            data_state <= DT_WAIT;
            sm_tvalid <= 0;
            ss_tready <= 0;
        end else if(ap_ctrl[0] == 1) begin
            data_state <= DT_WAIT;
            sm_tvalid <= 0;
            ss_tready <= 1;
        end else begin
            data_state <= next_data_state;
            sm_tvalid <= next_sm_tvalid;
            ss_tready <= next_ss_tready;
        end
    end 

// bram for data RAM

    // address generator for newly stored data (up Counter)
    reg  [4:0] x_w_cnt;
    wire [4:0] x_w_cnt_tmp;

    assign x_w_cnt_tmp = (ss_tready && ss_tvalid) ? 
             ((x_w_cnt == tap_num - 1) ? 0 : (x_w_cnt + 1)) : 
             x_w_cnt;

    always@ (posedge axis_clk or negedge axis_rst_n) begin
        if(!axis_rst_n) begin
            x_w_cnt <= tap_num - 1;
        end else if (state == IDLE) begin
            x_w_cnt <= tap_num - 1;
        end else if(ap_ctrl[0] == 1)begin
            x_w_cnt <= 0;
        end else begin 
            x_w_cnt <= x_w_cnt_tmp;
        end
    end

    // address generator for reading out data (down Counter)
    reg  [4:0] x_r_cnt;
    reg  [4:0] x_r_cnt_tmp;

    always @* begin
        if(ss_tready && ss_tvalid) begin
            x_r_cnt_tmp = x_w_cnt_tmp;
        end else if (data_state == DT_PROC) begin
            if(x_r_cnt == 0) begin
                x_r_cnt_tmp=  tap_num - 1;
            end else begin
                x_r_cnt_tmp=  x_r_cnt - 1;
            end
        end else begin
            x_r_cnt_tmp=  x_w_cnt + 1;
        end
    end

    always@ (posedge axis_clk or negedge axis_rst_n) begin
        if(!axis_rst_n) begin
            x_r_cnt <= 0;
        end else if(ap_ctrl[0] == 1) begin
            x_r_cnt <= 0;
        end else begin
            x_r_cnt <= x_r_cnt_tmp;
        end
    end

    // bram signal
    reg [(pDATA_WIDTH-1):0] ss_tdata_latch;

    always @(posedge axis_clk or negedge axis_rst_n) begin
        if(!axis_rst_n) begin
            ss_tdata_latch <= 0;
        end else if(state == DONE)begin
            ss_tdata_latch <= 0;
        end else begin
            ss_tdata_latch <= (ss_tvalid && ss_tready) ? ss_tdata : ss_tdata_latch;
        end
    end
    
    // initialize address
    reg [5:0] addr_cnt;
    always@(posedge axis_clk or negedge axis_rst_n) begin
        if(!axis_rst_n) begin
            addr_cnt <= 0;
        end else if(state == DONE)begin
            addr_cnt <= 0;
        end else begin
            addr_cnt <= (addr_cnt == 31) ? addr_cnt : addr_cnt + 1;
        end
    end


    always@* begin
        data_EN = 1'b1;
        if(state == CALC) begin
            data_WE = (ss_tvalid && ss_tready) ? 4'b1111 : 4'b0000; 
            data_Di = (ss_tvalid && ss_tready) ? ss_tdata_latch : 32'h00;
            data_A  = (ss_tvalid && ss_tready) ? 4 * x_w_cnt : 4 *x_r_cnt;
        end else if(state == IDLE || state == DONE) begin
            data_WE = 4'b1111;
            data_Di = 32'h00;
            data_A = 4 * addr_cnt;
        end else begin
            data_WE = 4'b0000;
            data_Di = 32'h00;
            data_A = 0;
        end
    end

// core engine: convolution
    wire [(pDATA_WIDTH-1):0] x_tmp;
    wire [(pDATA_WIDTH-1):0] h_tmp;
    reg  [(pDATA_WIDTH-1):0] x;
    reg  [(pDATA_WIDTH-1):0] h;
    wire [(pDATA_WIDTH-1):0] mul_tmp;
    reg  [(pDATA_WIDTH-1):0] mul;
    reg  [(pDATA_WIDTH-1):0] y;
    
    // multipler
    assign x_tmp = (tap_cnt == 1) ? ss_tdata_latch : data_Do;
    assign h_tmp = tap_Do;

    assign mul_tmp = x * h;

    always@ (posedge axis_clk or negedge axis_rst_n) begin
        if(!axis_rst_n) begin
            x <= 0;
            h<= 0;
            mul <= 0;
        end else if(state == IDLE) begin
            x <= 0;
            h<= 0;
            mul <= 0;
        end else begin
            x <= x_tmp;
            h<= h_tmp;
            mul <= mul_tmp;
        end
    end

    // adder
    always@ (posedge axis_clk or negedge axis_rst_n) begin
        if(!axis_rst_n) begin
            y <=  0;
        end else if(state == IDLE) begin
            y <= 0;
        end else if (tap_cnt == 3) begin
            y <= mul;
        end else begin
            y <= y + mul;
        end
    end

    // sm data
    wire [(pDATA_WIDTH-1):0] sm_tdata_tmp;

    always@(posedge axis_clk or negedge axis_rst_n) begin
        if(!axis_rst_n) begin
            sm_tdata <= 32'h00;
        end else if(state == IDLE) begin
            sm_tdata <= 32'h00;
        end else begin
            sm_tdata  <= sm_tdata_tmp;
        end
    end    

    assign sm_tdata_tmp = (tap_cnt == (4 + (tap_num - 1))) ? y : sm_tdata;

    // count the valid y output
    

    always@(posedge axis_clk or negedge axis_rst_n) begin
        if(!axis_rst_n) begin
            y_cnt <= 0;
        end else if(state == IDLE) begin
            y_cnt <= 0;
        end else if (sm_tvalid && sm_tready) begin
            y_cnt <= y_cnt + 1;
        end else begin
            y_cnt <= y_cnt;
        end
    end

    assign sm_tlast = (y_cnt == data_length);

endmodule