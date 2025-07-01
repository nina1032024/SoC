module kernel_NTT 
#(  
    parameter pDATA_WIDTH = 128,
    parameter pDATA_WIDTH_2x = 256 
)
(
    input  wire                     clk,
    input  wire                     clk_2x,     // for dataRAM (double-speed)
    input  wire                     rstn,

    input  wire                     ld_vld,
    output wire                     ld_rdy,
    input  wire [(pDATA_WIDTH-1):0] ld_dat,

    output reg                     sw_vld,
    input  wire                     sw_rdy,
    output reg [(pDATA_WIDTH-1):0] sw_dat,

    input  wire                     coef_vld,
    output wire                     coef_rdy,
    input  wire [(pDATA_WIDTH-1):0] coef_dat, 

    output wire               [4:0] bpe_act,     // for bpe1 to bpe5 activate

    input  wire               [7:0] mode,
    input  wire                     decode,
    output wire                     sw_lst,       // set when handshake
    
    //============BPE1============//
    output reg  [(pDATA_WIDTH-1):0] BPE1_ain,
    output reg  [(pDATA_WIDTH-1):0] BPE1_bin,
    output reg  [(pDATA_WIDTH-1):0] BPE1_coef,
    input  wire [(pDATA_WIDTH-1):0] BPE1_aout,
    input  wire [(pDATA_WIDTH-1):0] BPE1_bout,
    output   reg BPE1_i_vld,
    input  wire BPE1_i_rdy,
    input  wire BPE1_o_vld,
    output   wire BPE1_o_rdy,

    //============BPE2============//
    output reg  [(pDATA_WIDTH-1):0] BPE2_ain,
    output reg  [(pDATA_WIDTH-1):0] BPE2_bin,
    output reg  [(pDATA_WIDTH-1):0] BPE2_coef,
    input  wire [(pDATA_WIDTH-1):0] BPE2_aout,
    input  wire [(pDATA_WIDTH-1):0] BPE2_bout,
    output reg  BPE2_i_vld,
    input  wire BPE2_i_rdy,
    input  wire BPE2_o_vld,
    output wire  BPE2_o_rdy,

    //============BPE3============//
    output reg  [(pDATA_WIDTH-1):0] BPE3_ain,
    output reg  [(pDATA_WIDTH-1):0] BPE3_bin,
    output reg  [(pDATA_WIDTH-1):0] BPE3_coef,
    input  wire [(pDATA_WIDTH-1):0] BPE3_aout,
    input  wire [(pDATA_WIDTH-1):0] BPE3_bout,
    output reg  BPE3_i_vld,
    input  wire BPE3_i_rdy,
    input  wire BPE3_o_vld,
    output wire  BPE3_o_rdy,

    //============BPE4============//
    output reg  [(pDATA_WIDTH-1):0] BPE4_ain,
    output reg  [(pDATA_WIDTH-1):0] BPE4_bin,
    output reg  [(pDATA_WIDTH-1):0] BPE4_coef,
    input  wire [(pDATA_WIDTH-1):0] BPE4_aout,
    input  wire [(pDATA_WIDTH-1):0] BPE4_bout,
    output reg  BPE4_i_vld,
    input  wire BPE4_i_rdy,
    input  wire BPE4_o_vld,
    output wire  BPE4_o_rdy,

    //============BPE5============//
    output reg  [(pDATA_WIDTH-1):0] BPE5_ain,
    output reg  [(pDATA_WIDTH-1):0] BPE5_bin,
    output reg  [(pDATA_WIDTH-1):0] BPE5_coef,
    input  wire [(pDATA_WIDTH-1):0] BPE5_aout,
    input  wire [(pDATA_WIDTH-1):0] BPE5_bout,
    output reg  BPE5_i_vld,
    input  wire BPE5_i_rdy,
    input  wire BPE5_o_vld,
    output wire  BPE5_o_rdy,


    //============SRAM1 512x128============//
    output reg [3:0]    WE_512,
    output         reg sram_en_512,
    output reg[(pDATA_WIDTH-1):0] sram_din_512,
    input wire [(pDATA_WIDTH-1):0] sram_dout_512,
    output reg[12:0]   sram_addr_512,


    //============SRAM2 128x128============//
    output reg [3:0]   WE_128,
    output    reg     sram_en_128,
    output reg [(pDATA_WIDTH-1):0] sram_din_128,
    input wire [(pDATA_WIDTH-1):0] sram_dout_128,
    output reg [12:0]   sram_addr_128,

    //============SRAM3 32x128============//
    output [3:0]   WE_32,
    output         sram_en_32,
    output reg[(pDATA_WIDTH-1):0] sram_din_32,
    input wire [(pDATA_WIDTH-1):0] sram_dout_32,
    output  reg[12:0]   sram_addr_32

);
    localparam S1 = 4'b0000;
    localparam S2 = 4'b0001;
    localparam S3 = 4'b0010;
    localparam S4 = 4'b0011;
    localparam S5 = 4'b0100;
    localparam S6 = 4'b0101;
    localparam S7_to_10 = 4'b0110;
    localparam OUT = 4'b0111;
    localparam IDLE = 4'b1000;

    localparam NTT = 2'b10;
    localparam iNTT = 2'b11;

    reg [6:0] s1_o_cnt, s2_o_cnt, s3_o_cnt, s4_o_cnt, s5_o_cnt, s6_o_cnt, s7_o_cnt, s8_o_cnt, s9_o_cnt, s10_o_cnt; 
    reg [3:0] stage, next_stage;

//============shared resources mux signal============//
    reg [(pDATA_WIDTH-1):0] sram_dout_128_buf, sram_dout_512_buf;
    // s1 output : sram 128
    reg [(pDATA_WIDTH_2x-1):0] s1_o_sram_din_128_tmp;
    reg [25:0] s1_o_sram_addr_128_tmp;
    reg [3:0]s1_o_WE_128;
    reg s1_o_sram_en_128;
    wire [(pDATA_WIDTH-1):0] s1_o_sram_din_128;
    wire [12:0]  s1_o_sram_addr_128;

    // s2 input : sram 128
    reg [(pDATA_WIDTH_2x-1):0] s2_i_sram_din_128_tmp;
    reg [25:0] s2_i_sram_addr_128_tmp;
    reg [3:0]s2_i_WE_128;
    reg s2_i_sram_en_128;
    wire [(pDATA_WIDTH-1):0] s2_i_sram_din_128;
    wire [12:0]  s2_i_sram_addr_128;

    // s2 output : sram 512
    reg [(pDATA_WIDTH_2x-1):0] s2_o_sram_din_512_tmp;
    reg [25:0] s2_o_sram_addr_512_tmp;
    reg [3:0]s2_o_WE_512;
    reg s2_o_sram_en_512;
    wire [(pDATA_WIDTH-1):0] s2_o_sram_din_512;
    wire [12:0]  s2_o_sram_addr_512;

    // s3 input : sram 512
    reg [(pDATA_WIDTH_2x-1):0] s3_i_sram_din_512_tmp;
    reg [25:0] s3_i_sram_addr_512_tmp;
    reg [3:0]s3_i_WE_512;
    reg s3_i_sram_en_512;
    wire [(pDATA_WIDTH-1):0] s3_i_sram_din_512;
    wire [12:0]  s3_i_sram_addr_512;

    // s3 output : sram 128
    reg [(pDATA_WIDTH_2x-1):0] s3_o_sram_din_128_tmp;
    reg [25:0] s3_o_sram_addr_128_tmp;
    reg [3:0]s3_o_WE_128;
    reg s3_o_sram_en_128;
    wire [(pDATA_WIDTH-1):0] s3_o_sram_din_128;
    wire [12:0]  s3_o_sram_addr_128;

    // s4 input : sram 128
    reg [(pDATA_WIDTH_2x-1):0] s4_i_sram_din_128_tmp;
    reg [25:0] s4_i_sram_addr_128_tmp;
    reg [3:0]s4_i_WE_128;
    reg s4_i_sram_en_128;
    wire [(pDATA_WIDTH-1):0] s4_i_sram_din_128;
    wire [12:0]  s4_i_sram_addr_128;

    // s4 output : sram 512
    reg [(pDATA_WIDTH_2x-1):0] s4_o_sram_din_512_tmp;
    reg [25:0] s4_o_sram_addr_512_tmp;
    reg [3:0]s4_o_WE_512;
    reg s4_o_sram_en_512;
    wire [(pDATA_WIDTH-1):0] s4_o_sram_din_512;
    wire [12:0]  s4_o_sram_addr_512;

    // s5 input : sram 512
    reg [(pDATA_WIDTH_2x-1):0] s5_i_sram_din_512_tmp;
    reg [25:0] s5_i_sram_addr_512_tmp;
    reg [3:0]s5_i_WE_512;
    reg s5_i_sram_en_512;
    wire [(pDATA_WIDTH-1):0] s5_i_sram_din_512;
    wire [12:0]  s5_i_sram_addr_512;

    // s5 output : sram 128
    reg [(pDATA_WIDTH_2x-1):0] s5_o_sram_din_128_tmp;
    reg [25:0] s5_o_sram_addr_128_tmp;
    reg [3:0]s5_o_WE_128;
    reg s5_o_sram_en_128;
    wire [(pDATA_WIDTH-1):0] s5_o_sram_din_128;
    wire [12:0]  s5_o_sram_addr_128; 

    // s6 input : sram 128
    reg [(pDATA_WIDTH_2x-1):0] s6_i_sram_din_128_tmp;
    reg [25:0] s6_i_sram_addr_128_tmp;
    reg [3:0]s6_i_WE_128;
    reg s6_i_sram_en_128;
    wire [(pDATA_WIDTH-1):0] s6_i_sram_din_128;
    wire [12:0]  s6_i_sram_addr_128;

    // s6 output : sram 512
    reg [(pDATA_WIDTH_2x-1):0] s6_o_sram_din_512_tmp;
    reg [25:0] s6_o_sram_addr_512_tmp;
    reg [3:0]s6_o_WE_512;
    reg s6_o_sram_en_512;
    wire [(pDATA_WIDTH-1):0] s6_o_sram_din_512;
    wire [12:0]  s6_o_sram_addr_512;

    // s7 input : sram 512
    reg [(pDATA_WIDTH_2x-1):0] s7_i_sram_din_512_tmp;
    reg [25:0] s7_i_sram_addr_512_tmp;
    reg [3:0]s7_i_WE_512;
    reg s7_i_sram_en_512;
    wire [(pDATA_WIDTH-1):0] s7_i_sram_din_512;
    wire [12:0]  s7_i_sram_addr_512;

    // s7 output : buffer to BPE2
    reg [(pDATA_WIDTH_2x-1):0] s7_o_tmp;

    // s8 output : buffer to BPE3
    reg [(pDATA_WIDTH_2x-1):0] s8_o_tmp;

    // s9 output : buffer to BPE4
    reg [(pDATA_WIDTH_2x-1):0] s9_o_tmp;

    // s10 output : buffer to module
    reg [(pDATA_WIDTH-1):0] s10_o_tmp_a, s10_o_tmp_b; 

    // s10 output : sram 128
    reg [(pDATA_WIDTH_2x-1):0] s10_o_sram_din_128_tmp;
    reg [25:0] s10_o_sram_addr_128_tmp;
    reg [3:0]s10_o_WE_128;
    reg s10_o_sram_en_128;
    reg [(pDATA_WIDTH-1):0] s10_o_sram_din_128;
    reg [12:0]  s10_o_sram_addr_128; 

    // sm output : sram 128
    reg sm_o_sram_en_128;
    reg sm_o_WE_128;
    wire [(pDATA_WIDTH-1):0] sm_o_sram_addr_128;
    reg [(pDATA_WIDTH-1):0] sm_o_sram_din_128;

    // s1 : BPE1
    reg  [(pDATA_WIDTH-1):0] s1_BPE1_ain;
    reg  [(pDATA_WIDTH-1):0] s1_BPE1_bin;
    reg  [(pDATA_WIDTH-1):0] s1_BPE1_coef;
    reg s1_BPE1_i_vld;

    // s2 : BPE1
    reg  [(pDATA_WIDTH-1):0] s2_BPE1_ain;
    reg  [(pDATA_WIDTH-1):0] s2_BPE1_bin;
    reg  [(pDATA_WIDTH-1):0] s2_BPE1_coef;
    reg s2_BPE1_i_vld;

     // s3 : BPE1
    reg  [(pDATA_WIDTH-1):0] s3_BPE1_ain;
    reg  [(pDATA_WIDTH-1):0] s3_BPE1_bin;
    reg  [(pDATA_WIDTH-1):0] s3_BPE1_coef;
    reg s3_BPE1_i_vld;

    // s4 : BPE1
    reg  [(pDATA_WIDTH-1):0] s4_BPE1_ain;
    reg  [(pDATA_WIDTH-1):0] s4_BPE1_bin;
    reg  [(pDATA_WIDTH-1):0] s4_BPE1_coef;
    reg s4_BPE1_i_vld;

    // s5 : BPE1
    reg  [(pDATA_WIDTH-1):0] s5_BPE1_ain;
    reg  [(pDATA_WIDTH-1):0] s5_BPE1_bin;
    reg  [(pDATA_WIDTH-1):0] s5_BPE1_coef;
    reg s5_BPE1_i_vld;

    // s6 : BPE1
    reg  [(pDATA_WIDTH-1):0] s6_BPE1_ain;
    reg  [(pDATA_WIDTH-1):0] s6_BPE1_bin;
    reg  [(pDATA_WIDTH-1):0] s6_BPE1_coef;
    reg s6_BPE1_i_vld;

     // s7 : BPE1
    reg  [(pDATA_WIDTH-1):0] s7_BPE1_ain;
    reg  [(pDATA_WIDTH-1):0] s7_BPE1_bin;
    reg  [(pDATA_WIDTH-1):0] s7_BPE1_coef;
    reg s7_BPE1_i_vld;

     // s8 : BPE2
    reg  [(pDATA_WIDTH-1):0] s8_BPE2_ain;
    reg  [(pDATA_WIDTH-1):0] s8_BPE2_bin;
    reg  [(pDATA_WIDTH-1):0] s8_BPE2_coef;
    reg s8_BPE2_i_vld;

     // s9 : BPE3
    reg  [(pDATA_WIDTH-1):0] s9_BPE3_ain;
    reg  [(pDATA_WIDTH-1):0] s9_BPE3_bin;
    reg  [(pDATA_WIDTH-1):0] s9_BPE3_coef;
    reg s9_BPE3_i_vld;

     // s10 : BPE4
    reg  [(pDATA_WIDTH-1):0] s10_BPE4_ain;
    reg  [(pDATA_WIDTH-1):0] s10_BPE4_bin;
    reg  [(pDATA_WIDTH-1):0] s10_BPE4_coef;
    reg s10_BPE4_i_vld;

// =============coef=================//
    reg [127:0] W0, W1, W2, W3, W4, W5, W6, W7, W8, W9, W10, W11, W12, W13, W14, W15, W16, W17, W18, W19, W20, W21, W22, W23, W24, W25, W26, W27, W28, W29, W30, W31;
    reg [127:0] W32, W33, W34, W35, W36, W37, W38, W39, W40, W41, W42, W43, W44, W45, W46, W47, W48, W49, W50, W51, W52, W53, W54, W55, W56, W57, W58, W59, W60, W61, W62, W63;

//======================================== general declarations ======================================== // 
//============ kernel operation mode ============//
    reg [7:0] mode_state;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            mode_state <= 0;
        end else begin
            mode_state <= (decode) ? mode : mode_state;
        end
    end

//=============== kernel state ===============//
    localparam KER_IDLE = 1'b0;
    localparam KER_CAL  = 1'b1;
    reg kernel_state, nxt_kernel_state;

    always@* begin
        case(kernel_state)
            KER_IDLE: begin
                if(ld_vld) begin
                    nxt_kernel_state = KER_CAL;
                end else begin
                    nxt_kernel_state = KER_IDLE;
                end
            end
            KER_CAL: begin
                if(sw_lst) begin
                    nxt_kernel_state = KER_IDLE;
                end else begin
                    nxt_kernel_state = KER_CAL;
                end
            end
            default: begin     
                nxt_kernel_state = KER_IDLE;
            end
        endcase
    end

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            kernel_state <= KER_IDLE;
        end else begin
            kernel_state <= nxt_kernel_state;
        end
    end
//=========data, coefficient ready (IOP -> kernel)==========//
    assign ld_rdy = 1;
    assign coef_rdy = 1;
    assign BPE1_o_rdy = 1;
    assign BPE2_o_rdy = 1;
    assign BPE3_o_rdy = 1;
    assign BPE4_o_rdy = 1;

    
//==================clk_2x, two phase=======================//
    reg phase; 
    always @(posedge clk_2x or negedge rstn) begin
        if (!rstn) begin
          phase <= 0;
        end else begin
          phase <= ~phase;
        end
      end
// ====================================== twiddle stream in ======================================// 
    reg [5:0] coef_idx;
    wire [5:0] next_coef_idx;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            coef_idx <= 0;
        end else begin
            coef_idx <= next_coef_idx;
        end
    end

    assign next_coef_idx = (coef_vld && coef_rdy) ? ((coef_idx == 6'd63) ? coef_idx : coef_idx + 1) : coef_idx;

    always @* begin
        W0 = (coef_vld && coef_rdy && next_coef_idx == 0) ? coef_dat : W0;
    end

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            W0 <= 0;  W1 <= 0;  W2 <= 0;  W3 <= 0;  W4 <= 0;  W5 <= 0;  W6 <= 0;  W7 <= 0;
            W8 <= 0;  W9 <= 0;  W10 <= 0; W11 <= 0; W12 <= 0; W13 <= 0; W14 <= 0; W15 <= 0;
            W16 <= 0; W17 <= 0; W18 <= 0; W19 <= 0; W20 <= 0; W21 <= 0; W22 <= 0; W23 <= 0;
            W24 <= 0; W25 <= 0; W26 <= 0; W27 <= 0; W28 <= 0; W29 <= 0; W30 <= 0; W31 <= 0;
            W32 <= 0; W33 <= 0; W34 <= 0; W35 <= 0; W36 <= 0; W37 <= 0; W38 <= 0; W39 <= 0;
            W40 <= 0; W41 <= 0; W42 <= 0; W43 <= 0; W44 <= 0; W45 <= 0; W46 <= 0; W47 <= 0;
            W48 <= 0; W49 <= 0; W50 <= 0; W51 <= 0; W52 <= 0; W53 <= 0; W54 <= 0; W55 <= 0;
            W56 <= 0; W57 <= 0; W58 <= 0; W59 <= 0; W60 <= 0; W61 <= 0; W62 <= 0; W63 <= 0;
        end else begin
            W1 <=  (coef_vld && coef_rdy && coef_idx == 0) ? coef_dat : W1;
            W2 <=  (coef_vld && coef_rdy && coef_idx == 1) ? coef_dat : W2;
            W3 <=  (coef_vld && coef_rdy && coef_idx == 2) ? coef_dat : W3;
            W4 <=  (coef_vld && coef_rdy && coef_idx == 3) ? coef_dat : W4;
            W5 <=  (coef_vld && coef_rdy && coef_idx == 4) ? coef_dat : W5;
            W6 <=  (coef_vld && coef_rdy && coef_idx == 5) ? coef_dat : W6;
            W7 <=  (coef_vld && coef_rdy && coef_idx == 6) ? coef_dat : W7;
            W8 <=  (coef_vld && coef_rdy && coef_idx == 7) ? coef_dat : W8;
            W9 <=  (coef_vld && coef_rdy && coef_idx == 8) ? coef_dat : W9;
            W10 <= (coef_vld && coef_rdy && coef_idx == 9) ? coef_dat : W10;
            W11 <= (coef_vld && coef_rdy && coef_idx == 10) ? coef_dat : W11;
            W12 <= (coef_vld && coef_rdy && coef_idx == 11) ? coef_dat : W12;
            W13 <= (coef_vld && coef_rdy && coef_idx == 12) ? coef_dat : W13;
            W14 <= (coef_vld && coef_rdy && coef_idx == 13) ? coef_dat : W14;
            W15 <= (coef_vld && coef_rdy && coef_idx == 14) ? coef_dat : W15;
            W16 <= (coef_vld && coef_rdy && coef_idx == 15) ? coef_dat : W16;
            W17 <= (coef_vld && coef_rdy && coef_idx == 16) ? coef_dat : W17;
            W18 <= (coef_vld && coef_rdy && coef_idx == 17) ? coef_dat : W18;
            W19 <= (coef_vld && coef_rdy && coef_idx == 18) ? coef_dat : W19;
            W20 <= (coef_vld && coef_rdy && coef_idx == 19) ? coef_dat : W20;
            W21 <= (coef_vld && coef_rdy && coef_idx == 20) ? coef_dat : W21;
            W22 <= (coef_vld && coef_rdy && coef_idx == 21) ? coef_dat : W22;
            W23 <= (coef_vld && coef_rdy && coef_idx == 22) ? coef_dat : W23;
            W24 <= (coef_vld && coef_rdy && coef_idx == 23) ? coef_dat : W24;
            W25 <= (coef_vld && coef_rdy && coef_idx == 24) ? coef_dat : W25;
            W26 <= (coef_vld && coef_rdy && coef_idx == 25) ? coef_dat : W26;
            W27 <= (coef_vld && coef_rdy && coef_idx == 26) ? coef_dat : W27;
            W28 <= (coef_vld && coef_rdy && coef_idx == 27) ? coef_dat : W28;
            W29 <= (coef_vld && coef_rdy && coef_idx == 28) ? coef_dat : W29;
            W30 <= (coef_vld && coef_rdy && coef_idx == 29) ? coef_dat : W30;
            W31 <= (coef_vld && coef_rdy && coef_idx == 30) ? coef_dat : W31;
            W32 <= (coef_vld && coef_rdy && coef_idx == 31) ? coef_dat : W32;
            W33 <= (coef_vld && coef_rdy && coef_idx == 32) ? coef_dat : W33;
            W34 <= (coef_vld && coef_rdy && coef_idx == 33) ? coef_dat : W34;
            W35 <= (coef_vld && coef_rdy && coef_idx == 34) ? coef_dat : W35;
            W36 <= (coef_vld && coef_rdy && coef_idx == 35) ? coef_dat : W36;
            W37 <= (coef_vld && coef_rdy && coef_idx == 36) ? coef_dat : W37;
            W38 <= (coef_vld && coef_rdy && coef_idx == 37) ? coef_dat : W38;
            W39 <= (coef_vld && coef_rdy && coef_idx == 38) ? coef_dat : W39;
            W40 <= (coef_vld && coef_rdy && coef_idx == 39) ? coef_dat : W40;
            W41 <= (coef_vld && coef_rdy && coef_idx == 40) ? coef_dat : W41;
            W42 <= (coef_vld && coef_rdy && coef_idx == 41) ? coef_dat : W42;
            W43 <= (coef_vld && coef_rdy && coef_idx == 42) ? coef_dat : W43;
            W44 <= (coef_vld && coef_rdy && coef_idx == 43) ? coef_dat : W44;
            W45 <= (coef_vld && coef_rdy && coef_idx == 44) ? coef_dat : W45;
            W46 <= (coef_vld && coef_rdy && coef_idx == 45) ? coef_dat : W46;
            W47 <= (coef_vld && coef_rdy && coef_idx == 46) ? coef_dat : W47;
            W48 <= (coef_vld && coef_rdy && coef_idx == 47) ? coef_dat : W48;
            W49 <= (coef_vld && coef_rdy && coef_idx == 48) ? coef_dat : W49;
            W50 <= (coef_vld && coef_rdy && coef_idx == 49) ? coef_dat : W50;
            W51 <= (coef_vld && coef_rdy && coef_idx == 50) ? coef_dat : W51;
            W52 <= (coef_vld && coef_rdy && coef_idx == 51) ? coef_dat : W52;
            W53 <= (coef_vld && coef_rdy && coef_idx == 52) ? coef_dat : W53;
            W54 <= (coef_vld && coef_rdy && coef_idx == 53) ? coef_dat : W54;
            W55 <= (coef_vld && coef_rdy && coef_idx == 54) ? coef_dat : W55;
            W56 <= (coef_vld && coef_rdy && coef_idx == 55) ? coef_dat : W56;
            W57 <= (coef_vld && coef_rdy && coef_idx == 56) ? coef_dat : W57;
            W58 <= (coef_vld && coef_rdy && coef_idx == 57) ? coef_dat : W58;
            W59 <= (coef_vld && coef_rdy && coef_idx == 58) ? coef_dat : W59;
            W60 <= (coef_vld && coef_rdy && coef_idx == 59) ? coef_dat : W60;
            W61 <= (coef_vld && coef_rdy && coef_idx == 60) ? coef_dat : W61;
            W62 <= (coef_vld && coef_rdy && coef_idx == 61) ? coef_dat : W62;
            W63 <= (coef_vld && coef_rdy && coef_idx == 62) ? coef_dat : W63;
        end
    end                           

//====================================== butterfly stage 1 ======================================// 
//============= stage 1 =============// 
// Arithmetic unit: BPE1             // 
// Read: ld_dat                      // 
// Write: sram 128 * 128             // 
//============= stage 1 =============// 

//============= Get s1 input data ===========//
    reg [7:0] s1_i_cnt;             // 0~1023

    always@(posedge clk or negedge rstn) 
        if(!rstn) begin
            s1_i_cnt <= 0;
        end else begin
            s1_i_cnt <= (ld_vld && ld_rdy) ? 
                        ((s1_i_cnt == 8'd128) ? 0 : s1_i_cnt + 1) : s1_i_cnt;
        end 
    
//============= input to BPE1(data, coefficient) ===========//
    reg [(pDATA_WIDTH-1):0] s1_coef;   //W0 = {w7, w6, w5, w4, w3, w2, w1, w0}
    
    always@(posedge clk or negedge rstn) begin
        if(!rstn) begin
            s1_BPE1_ain <= 0;
            s1_BPE1_bin <= 0;
            s1_BPE1_coef <= 0;
            s1_BPE1_i_vld <= 0;
        end else begin
            s1_BPE1_ain <= (ld_vld && ld_rdy && s1_i_cnt[0] == 1'b0) ? ld_dat : s1_BPE1_ain;
            s1_BPE1_bin <= (ld_vld && ld_rdy && s1_i_cnt[0] == 1'b1) ? ld_dat : s1_BPE1_bin;
            s1_BPE1_coef <= (ld_vld && ld_rdy && s1_i_cnt[0] == 1'b1) ? {8{W0[15:0]}} : s1_BPE1_coef;
            s1_BPE1_i_vld <= (ld_vld && ld_rdy && s1_i_cnt[0] == 1'b1) ? 1 : 0;
        end 
    end

    always@(posedge clk or negedge rstn) begin
        if(!rstn) begin
            s1_coef <= 0;
        end else begin
            s1_coef <= (coef_vld && coef_rdy) ? coef_dat : s1_coef;
        end 
    end


//============= output to bram 128===========//
    reg [6:0] s1_addr; 
    wire [6:0] s1_current_addr;


    always@(posedge clk or negedge rstn) 
        if(!rstn) begin
            s1_o_cnt <= 0;
        end else begin
            s1_o_cnt <= (stage == S1 && BPE1_o_vld && BPE1_o_rdy) ? 
                        ((s1_o_cnt == 7'd64) ? 0 : s1_o_cnt + 1) : s1_o_cnt;
        end 
    
    always@ (posedge clk or negedge rstn) 
        if(!rstn) begin
            s1_o_sram_din_128_tmp <= 0;
            s1_o_sram_addr_128_tmp <= 0;
            s1_o_WE_128 <= 0;
            s1_o_sram_en_128 <= 0;
        end else begin
            s1_o_sram_din_128_tmp [255:128] <= (stage == S1 && BPE1_o_vld && BPE1_o_rdy) ? {BPE1_bout} : s1_o_sram_din_128_tmp;
            s1_o_sram_din_128_tmp [127:0] <= (stage == S1 && BPE1_o_vld && BPE1_o_rdy) ? {BPE1_aout} : s1_o_sram_din_128_tmp;
            s1_o_sram_addr_128_tmp [25:13] <= (stage == S1 && BPE1_o_vld && BPE1_o_rdy) ? {4 * (6'd32 + s1_current_addr)} : s1_o_sram_addr_128_tmp;
            s1_o_sram_addr_128_tmp [12:0] <= (stage == S1 && BPE1_o_vld && BPE1_o_rdy) ? {4 * s1_current_addr} : s1_o_sram_addr_128_tmp;
            s1_o_WE_128 <= {4{(stage == S1 && BPE1_o_vld && BPE1_o_rdy)}};
            s1_o_sram_en_128 <= (stage == S1 && BPE1_o_vld && BPE1_o_rdy);
        end 

    assign s1_o_sram_din_128 = (phase) ? s1_o_sram_din_128_tmp[255:128]: s1_o_sram_din_128_tmp[127:0];
    assign s1_o_sram_addr_128 = (phase) ? s1_o_sram_addr_128_tmp[25:13]: s1_o_sram_addr_128_tmp[12:0];

    

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            s1_addr <= 0;
        end else if (stage == S1 && BPE1_o_vld && BPE1_o_rdy) begin
            if (s1_addr == 31)
                s1_addr <= 64;       
            else if (s1_addr == 95)
                s1_addr <= 0;        
            else
                s1_addr <= s1_addr + 1; 
        end else begin
            s1_addr <= s1_addr;
        end
    end
    assign s1_current_addr = s1_addr;  

//====================================== butterfly stage 2 ======================================// 
//============= stage 2 =============// 
// Arithmetic unit: BPE2             // 
// Read: sram 128 * 128              // 
// Write: sram 512 * 128             // 
//============= stage 2 =============//  

//============= Get s2 input data ===========//
reg [6:0] s2_i_cnt;

always@(posedge clk or negedge rstn) begin
    if(!rstn) begin
        s2_i_cnt <= 0;
    end else begin
        s2_i_cnt <= (stage == S2) ? ((s2_i_cnt == 66) ? s2_i_cnt : s2_i_cnt + 1) : s2_i_cnt;
    end
end

//============= input to BPE1(data, coefficient) ===========//
    always@* begin
        s2_i_sram_addr_128_tmp [25:13] <= (stage == S2 && s2_i_cnt <= 64) ? {4 * (7'd64 + s2_i_cnt)} : s2_i_sram_addr_128_tmp;
        s2_i_sram_addr_128_tmp [12:0] <= (stage == S2 && s2_i_cnt <= 64) ? {4 * s2_i_cnt} : s2_i_sram_addr_128_tmp;
        s2_i_sram_en_128 = (stage == S2 && s2_i_cnt <= 64);
    end

    assign s2_i_sram_addr_128 = (phase) ? s2_i_sram_addr_128_tmp[25:13]: s2_i_sram_addr_128_tmp[12:0];
     
    always@(posedge clk_2x or negedge rstn) begin
        if(!rstn) begin
            s2_BPE1_ain <= 0;
            s2_BPE1_bin <= 0;
            s2_BPE1_i_vld <= 0;
        end else begin
            s2_BPE1_ain <= (!phase && s2_i_cnt >= 1 && s2_i_cnt <= 65) ? sram_dout_128_buf : s2_BPE1_ain;
            s2_BPE1_bin <= (phase && s2_i_cnt >= 1 && s2_i_cnt <= 65) ? sram_dout_128_buf : s2_BPE1_bin;
            s2_BPE1_i_vld <= (phase && s2_i_cnt >= 1 && s2_i_cnt <= 65) ? 1 : 0;
        end 
    end

    always @(posedge clk_2x or negedge rstn)
        if(!rstn) begin
            s2_BPE1_coef <= 0;
        end else begin
            if(phase) begin
                if((s2_i_cnt >= 1 && s2_i_cnt <= 32)) s2_BPE1_coef <=  {8{W0[15:0]}};
                else if((s2_i_cnt >= 33 && s2_i_cnt <= 65)) s2_BPE1_coef <=  {8{W1[15:0]}};
                else s2_BPE1_coef <= s2_BPE1_coef;
            end else begin
                s2_BPE1_coef <= s2_BPE1_coef;
            end
        end

//============= output to bram 512===========//
    reg [6:0] s2_addr; 
    wire [6:0] s2_current_addr;


    always@(posedge clk or negedge rstn) 
        if(!rstn) begin
            s2_o_cnt <= 0;
        end else begin
            s2_o_cnt <= (stage ==S2 && BPE1_o_vld && BPE1_o_rdy) ? 
                        ((s2_o_cnt == 7'd64) ? 0 : s2_o_cnt + 1) : s2_o_cnt;
        end 
    
    always@ (posedge clk or negedge rstn) 
        if(!rstn) begin
            s2_o_sram_din_512_tmp <= 0;
            s2_o_sram_addr_512_tmp <= 0;
            s2_o_WE_512 <= 0;
            s2_o_sram_en_512 <= 0;
        end else begin
            s2_o_sram_din_512_tmp [255:128] <= (stage == S2 && BPE1_o_vld && BPE1_o_rdy) ? {BPE1_bout} : s2_o_sram_din_512_tmp[255:128];
            s2_o_sram_din_512_tmp [127:0] <= (stage == S2 && BPE1_o_vld && BPE1_o_rdy) ? {BPE1_aout} : s2_o_sram_din_512_tmp[127:0];
            s2_o_sram_addr_512_tmp [25:13] <= (stage == S2 && BPE1_o_vld && BPE1_o_rdy) ? {4 * (5'd16 + s2_current_addr)} : s2_o_sram_addr_512_tmp[25:13];
            s2_o_sram_addr_512_tmp [12:0] <= (stage == S2 && BPE1_o_vld && BPE1_o_rdy) ? {4 * s2_current_addr} : s2_o_sram_addr_512_tmp[12:0];
            s2_o_WE_512 <= {4{(stage == S2 && BPE1_o_vld && BPE1_o_rdy)}};
            s2_o_sram_en_512 <= (stage == S2 && BPE1_o_vld && BPE1_o_rdy);
        end 

    assign s2_o_sram_din_512 = (phase) ? s2_o_sram_din_512_tmp[255:128]: s2_o_sram_din_512_tmp[127:0];
    assign s2_o_sram_addr_512 = (phase) ? s2_o_sram_addr_512_tmp[25:13]: s2_o_sram_addr_512_tmp[12:0];

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            s2_addr <= 0;
        end else if (stage == S2 && BPE1_o_vld && BPE1_o_rdy) begin
            case (s2_addr)
                15:  s2_addr <= 64;
                47:  s2_addr <= 96;
                79:  s2_addr <= 32;
                111: s2_addr <= 0;
                default: s2_addr <= s2_addr + 1;
            endcase
        end else begin
            s2_addr <= s2_addr;
        end
    end

    assign s2_current_addr = s2_addr;

//====================================== butterfly stage 3 ======================================// 
//============= stage 3 =============// 
// Arithmetic unit: BPE1             // 
// Read: sram 512 * 128              // 
// Write: sram 128 * 128             // 
//============= stage 3 =============//  

//============= Get s3 input data ===========//
reg [6:0] s3_i_cnt;

always@(posedge clk or negedge rstn) begin
    if(!rstn) begin
        s3_i_cnt <= 0;
    end else begin
        s3_i_cnt <= (stage == S3) ? ((s3_i_cnt == 7'd66) ? s3_i_cnt : s3_i_cnt + 1) : s3_i_cnt;
    end
end

//============= input to BPE1(data, coefficient) ===========//
    always@* begin
        s3_i_sram_addr_512_tmp [25:13] <= (stage == S3 && s3_i_cnt <= 64) ? {4 * (7'd64 + s3_i_cnt)} : s3_i_sram_addr_512_tmp;
        s3_i_sram_addr_512_tmp [12:0] <= (stage == S3 && s3_i_cnt <= 64) ? {4 * s3_i_cnt} : s3_i_sram_addr_512_tmp;
        s3_i_sram_en_512 = (stage == S3 && s3_i_cnt <= 64);
    end

    assign s3_i_sram_addr_512 = (phase) ? s3_i_sram_addr_512_tmp[25:13]: s3_i_sram_addr_512_tmp[12:0];
     
    always@(posedge clk_2x or negedge rstn) begin
        if(!rstn) begin
            s3_BPE1_ain <= 0;
            s3_BPE1_bin <= 0;
            s3_BPE1_i_vld <= 0;
        end else begin
            s3_BPE1_ain <= (!phase && s3_i_cnt >= 1 && s3_i_cnt <= 65) ? sram_dout_512_buf : s3_BPE1_ain;
            s3_BPE1_bin <= (phase && s3_i_cnt >= 1 && s3_i_cnt <= 65) ? sram_dout_512_buf : s3_BPE1_bin;
            s3_BPE1_i_vld <= (phase && s3_i_cnt >= 1 && s3_i_cnt <= 65) ? 1 : 0;
        end 
    end

    always @(posedge clk_2x or negedge rstn)
        if(!rstn) begin
            s3_BPE1_coef <= 0;
        end else begin
            if(phase) begin
                if((s3_i_cnt >= 1 && s3_i_cnt <= 16)) s3_BPE1_coef <=  {8{W0[15:0]}};
                else if((s3_i_cnt >= 17 && s3_i_cnt <= 32)) s3_BPE1_coef <=  {8{W1[15:0]}};
                else if((s3_i_cnt >= 33 && s3_i_cnt <= 48)) s3_BPE1_coef <=  {8{W2[15:0]}};
                else if((s3_i_cnt >= 49 && s3_i_cnt <= 65)) s3_BPE1_coef <=  {8{W3[15:0]}};
                else s3_BPE1_coef <= s3_BPE1_coef;
            end else begin
                s3_BPE1_coef <= s3_BPE1_coef;
            end
        end

//============= output to bram 512===========//
    reg [6:0] s3_addr; 
    wire [6:0] s3_current_addr;


    always@(posedge clk or negedge rstn) 
        if(!rstn) begin
            s3_o_cnt <= 0;
        end else begin
            s3_o_cnt <= (stage == S3 && BPE1_o_vld && BPE1_o_rdy) ? 
                        ((s3_o_cnt == 7'd64) ? 0 : s3_o_cnt + 1) : s3_o_cnt;
        end 
    
    always@ (posedge clk or negedge rstn) 
        if(!rstn) begin
            s3_o_sram_din_128_tmp <= 0;
            s3_o_sram_addr_128_tmp <= 0;
            s3_o_WE_128 <= 0;
            s3_o_sram_en_128 <= 0;
        end else begin
            s3_o_sram_din_128_tmp [255:128] <= (stage == S3 && BPE1_o_vld && BPE1_o_rdy) ? {BPE1_bout} : s3_o_sram_din_128_tmp[255:128];
            s3_o_sram_din_128_tmp [127:0] <= (stage == S3 && BPE1_o_vld && BPE1_o_rdy) ? {BPE1_aout} : s3_o_sram_din_128_tmp[127:0];
            s3_o_sram_addr_128_tmp [25:13] <= (stage == S3 && BPE1_o_vld && BPE1_o_rdy) ? {4 * (5'd8 + s3_current_addr)} : s3_o_sram_addr_128_tmp[25:13];
            s3_o_sram_addr_128_tmp [12:0] <= (stage == S3 && BPE1_o_vld && BPE1_o_rdy) ? {4 * s3_current_addr} : s3_o_sram_addr_128_tmp[12:0];
            s3_o_WE_128 <= {4{(stage == S3 && BPE1_o_vld && BPE1_o_rdy)}};
            s3_o_sram_en_128 <= (stage == S3 && BPE1_o_vld && BPE1_o_rdy);
        end 

    assign s3_o_sram_din_128 = (phase) ? s3_o_sram_din_128_tmp[255:128]: s3_o_sram_din_128_tmp[127:0];
    assign s3_o_sram_addr_128 = (phase) ? s3_o_sram_addr_128_tmp[25:13]: s3_o_sram_addr_128_tmp[12:0];

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            s3_addr <= 0;
        end else if (stage == S3 && BPE1_o_vld && BPE1_o_rdy) begin
            case (s3_addr)
                7:  s3_addr <= 64;
                71:  s3_addr <= 16;
                23:  s3_addr <= 80;
                87:  s3_addr <= 32;
                39:  s3_addr <= 96;
                103: s3_addr <= 48;
                55: s3_addr <= 112;
                119: s3_addr <= 0;
                default: s3_addr <= s3_addr + 1;
            endcase
        end else begin
            s3_addr <= s3_addr;
        end
    end

    assign s3_current_addr = s3_addr;


//====================================== butterfly stage 4 ======================================// 
//============= stage 4 =============// 
// Arithmetic unit: BPE1             // 
// Read: sram 128 * 128              // 
// Write: sram 512 * 128             // 
//============= stage 4 =============//  

//============= Get s3 input data ===========//
reg [6:0] s4_i_cnt;

always@(posedge clk or negedge rstn) begin
    if(!rstn) begin
        s4_i_cnt <= 0;
    end else begin
        s4_i_cnt <= (stage == S4) ? ((s4_i_cnt == 7'd66) ? s4_i_cnt : s4_i_cnt + 1) : s4_i_cnt;
    end
end

//============= input to BPE1(data, coefficient) ===========//
    always@* begin
        s4_i_sram_addr_128_tmp [25:13] <= (stage == S4 && s4_i_cnt <= 64) ? {4 * (7'd64 + s4_i_cnt)} : s4_i_sram_addr_128_tmp;
        s4_i_sram_addr_128_tmp [12:0] <= (stage == S4 && s4_i_cnt <= 64) ? {4 * s4_i_cnt} : s4_i_sram_addr_128_tmp;
        s4_i_sram_en_128 = (stage == S4 && s4_i_cnt <= 64);
    end

    assign s4_i_sram_addr_128 = (phase) ? s4_i_sram_addr_128_tmp[25:13]: s4_i_sram_addr_128_tmp[12:0];
     
    always@(posedge clk_2x or negedge rstn) begin
        if(!rstn) begin
            s4_BPE1_ain <= 0;
            s4_BPE1_bin <= 0;
            s4_BPE1_i_vld <= 0;
        end else begin
            s4_BPE1_ain <= (!phase && s4_i_cnt >= 1 && s4_i_cnt <= 65) ? sram_dout_128_buf : s4_BPE1_ain;
            s4_BPE1_bin <= (phase && s4_i_cnt >= 1 && s4_i_cnt <= 65) ? sram_dout_128_buf : s4_BPE1_bin;
            s4_BPE1_i_vld <= (phase && s4_i_cnt >= 1 && s4_i_cnt <= 65) ? 1 : 0;
        end 
    end

    always @(posedge clk_2x or negedge rstn)
        if(!rstn) begin
            s4_BPE1_coef <= 0;
        end else begin
            if(phase) begin
                if((s4_i_cnt >= 1 && s4_i_cnt <= 8)) s4_BPE1_coef <=  {8{W0[15:0]}};
                else if((s4_i_cnt >= 9 && s4_i_cnt <= 16)) s4_BPE1_coef <=  {8{W1[15:0]}};
                else if((s4_i_cnt >= 17 && s4_i_cnt <= 24)) s4_BPE1_coef <=  {8{W2[15:0]}};
                else if((s4_i_cnt >= 25 && s4_i_cnt <= 32)) s4_BPE1_coef <=  {8{W3[15:0]}};
                else if((s4_i_cnt >= 33 && s4_i_cnt <= 40)) s4_BPE1_coef <=  {8{W4[15:0]}};
                else if((s4_i_cnt >= 41 && s4_i_cnt <= 48)) s4_BPE1_coef <=  {8{W5[15:0]}};
                else if((s4_i_cnt >= 49 && s4_i_cnt <= 56)) s4_BPE1_coef <=  {8{W6[15:0]}};
                else if((s4_i_cnt >= 57 && s4_i_cnt <= 65)) s4_BPE1_coef <=  {8{W7[15:0]}};
                else s4_BPE1_coef <= s4_BPE1_coef;
            end else begin
                s4_BPE1_coef <= s4_BPE1_coef;
            end
        end

//============= output to bram 512===========//
    reg [6:0] s4_addr; 
    wire [6:0] s4_current_addr;


    always@(posedge clk or negedge rstn) 
        if(!rstn) begin
            s4_o_cnt <= 0;
        end else begin
            s4_o_cnt <= (stage == S4 && BPE1_o_vld && BPE1_o_rdy) ? 
                        ((s4_o_cnt == 7'd64) ? 0 : s4_o_cnt + 1) : s4_o_cnt;
        end 
    
    always@ (posedge clk or negedge rstn) 
        if(!rstn) begin
            s4_o_sram_din_512_tmp <= 0;
            s4_o_sram_addr_512_tmp <= 0;
            s4_o_WE_512 <= 0;
            s4_o_sram_en_512 <= 0;
        end else begin
            s4_o_sram_din_512_tmp [255:128] <= (stage == S4 && BPE1_o_vld && BPE1_o_rdy) ? {BPE1_bout} : s4_o_sram_din_512_tmp[255:128];
            s4_o_sram_din_512_tmp [127:0] <= (stage == S4 && BPE1_o_vld && BPE1_o_rdy) ? {BPE1_aout} : s4_o_sram_din_512_tmp[127:0];
            s4_o_sram_addr_512_tmp [25:13] <= (stage == S4 && BPE1_o_vld && BPE1_o_rdy) ? {4 * (5'd4 + s4_current_addr)} : s4_o_sram_addr_512_tmp[25:13];
            s4_o_sram_addr_512_tmp [12:0] <= (stage == S4 && BPE1_o_vld && BPE1_o_rdy) ? {4 * s4_current_addr} : s4_o_sram_addr_512_tmp[12:0];
            s4_o_WE_512 <= {4{(stage == S4 && BPE1_o_vld && BPE1_o_rdy)}};
            s4_o_sram_en_512 <= (stage == S4 && BPE1_o_vld && BPE1_o_rdy);
        end 

    assign s4_o_sram_din_512 = (phase) ? s4_o_sram_din_512_tmp[255:128]: s4_o_sram_din_512_tmp[127:0];
    assign s4_o_sram_addr_512 = (phase) ? s4_o_sram_addr_512_tmp[25:13]: s4_o_sram_addr_512_tmp[12:0];

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            s4_addr <= 0;
        end else if (stage == S4 && BPE1_o_vld && BPE1_o_rdy) begin
            case (s4_addr)
                3:   s4_addr <= 64;
                67:  s4_addr <= 8;
                11:  s4_addr <= 72;
                75:  s4_addr <= 16;
                19:  s4_addr <= 80;
                83:  s4_addr <= 24;
                27:  s4_addr <= 88;
                91:  s4_addr <= 32;
                35:  s4_addr <= 96;
                99:  s4_addr <= 40;
                43:  s4_addr <= 104;
                107: s4_addr <= 48;
                51:  s4_addr <= 112;
                115: s4_addr <= 56;
                59:  s4_addr <= 120;
                123: s4_addr <= 0;
                default: s4_addr <= s4_addr + 1;
            endcase
        end else begin
            s4_addr <= s4_addr;
        end
    end

    assign s4_current_addr = s4_addr;


//====================================== butterfly stage 5 ======================================// 
//============= stage 5 =============// 
// Arithmetic unit: BPE1             // 
// Read: sram 512 * 128              // 
// Write: sram 128* 128             // 
//============= stage 5 =============//  

//============= Get s5 input data ===========//
reg [6:0] s5_i_cnt;

always@(posedge clk or negedge rstn) begin
    if(!rstn) begin
        s5_i_cnt <= 0;
    end else begin
        s5_i_cnt <= (stage == S5) ? ((s5_i_cnt == 7'd66) ? s5_i_cnt : s5_i_cnt + 1) : s5_i_cnt;
    end
end

//============= input to BPE1(data, coefficient) ===========//
    always@* begin
        s5_i_sram_addr_512_tmp [25:13] <= (stage == S5 && s5_i_cnt <= 64) ? {4 * (7'd64 + s5_i_cnt)} : s5_i_sram_addr_512_tmp;
        s5_i_sram_addr_512_tmp [12:0] <= (stage == S5 && s5_i_cnt <= 64) ? {4 * s5_i_cnt} : s5_i_sram_addr_512_tmp;
        s5_i_sram_en_512 = (stage == S5 && s5_i_cnt <= 64);
    end

    assign s5_i_sram_addr_512 = (phase) ? s5_i_sram_addr_512_tmp[25:13]: s5_i_sram_addr_512_tmp[12:0];
     
    always@(posedge clk_2x or negedge rstn) begin
        if(!rstn) begin
            s5_BPE1_ain <= 0;
            s5_BPE1_bin <= 0;
            s5_BPE1_i_vld <= 0;
        end else begin
            s5_BPE1_ain <= (!phase && s5_i_cnt >= 1 && s5_i_cnt <= 65) ? sram_dout_512_buf : s5_BPE1_ain;
            s5_BPE1_bin <= (phase && s5_i_cnt >= 1 && s5_i_cnt <= 65) ? sram_dout_512_buf : s5_BPE1_bin;
            s5_BPE1_i_vld <= (phase && s5_i_cnt >= 1 && s5_i_cnt <= 65) ? 1 : 0;
        end 
    end

    always @(posedge clk_2x or negedge rstn)
        if(!rstn) begin
            s5_BPE1_coef <= 0;
        end else begin
            if(phase) begin
                if((s5_i_cnt >= 1 && s5_i_cnt <= 4)) s5_BPE1_coef <=  {8{W0[15:0]}};
                else if((s5_i_cnt >= 5 && s5_i_cnt <= 8)) s5_BPE1_coef <=  {8{W1[15:0]}};
                else if((s5_i_cnt >= 9 && s5_i_cnt <= 12)) s5_BPE1_coef <=  {8{W2[15:0]}};
                else if((s5_i_cnt >= 13 && s5_i_cnt <= 16)) s5_BPE1_coef <=  {8{W3[15:0]}};
                else if((s5_i_cnt >= 17 && s5_i_cnt <= 20)) s5_BPE1_coef <=  {8{W4[15:0]}};
                else if((s5_i_cnt >= 21 && s5_i_cnt <= 24)) s5_BPE1_coef <=  {8{W5[15:0]}};
                else if((s5_i_cnt >= 25 && s5_i_cnt <= 28)) s5_BPE1_coef <=  {8{W6[15:0]}};
                else if((s5_i_cnt >= 29 && s5_i_cnt <= 32)) s5_BPE1_coef <=  {8{W7[15:0]}};
                else if((s5_i_cnt >= 33 && s5_i_cnt <= 36)) s5_BPE1_coef <=  {8{W8[15:0]}};
                else if((s5_i_cnt >= 37 && s5_i_cnt <= 40)) s5_BPE1_coef <=  {8{W9[15:0]}};
                else if((s5_i_cnt >= 41 && s5_i_cnt <= 44)) s5_BPE1_coef <=  {8{W10[15:0]}};
                else if((s5_i_cnt >= 45 && s5_i_cnt <= 48)) s5_BPE1_coef <=  {8{W11[15:0]}};
                else if((s5_i_cnt >= 49 && s5_i_cnt <= 52)) s5_BPE1_coef <=  {8{W12[15:0]}};
                else if((s5_i_cnt >= 53 && s5_i_cnt <= 56)) s5_BPE1_coef <=  {8{W13[15:0]}};
                else if((s5_i_cnt >= 57 && s5_i_cnt <= 60)) s5_BPE1_coef <=  {8{W14[15:0]}};
                else if((s5_i_cnt >= 61 && s5_i_cnt <= 65)) s5_BPE1_coef <=  {8{W15[15:0]}};
                else s5_BPE1_coef <= s5_BPE1_coef;
            end else begin
                s5_BPE1_coef <= s5_BPE1_coef;
            end
        end

//============= output to bram 512===========//
    reg [6:0] s5_addr; 
    wire [6:0] s5_current_addr;

    always@(posedge clk or negedge rstn) 
        if(!rstn) begin
            s5_o_cnt <= 0;
        end else begin
            s5_o_cnt <= (stage == S5 && BPE1_o_vld && BPE1_o_rdy) ? 
                        ((s5_o_cnt == 7'd64) ? 0 : s5_o_cnt + 1) : s5_o_cnt;
        end 
    
    always@ (posedge clk or negedge rstn) 
        if(!rstn) begin
            s5_o_sram_din_128_tmp <= 0;
            s5_o_sram_addr_128_tmp <= 0;
            s5_o_WE_128 <= 0;
            s5_o_sram_en_128 <= 0;
        end else begin
            s5_o_sram_din_128_tmp [255:128] <= (stage == S5 && BPE1_o_vld && BPE1_o_rdy) ? {BPE1_bout} : s5_o_sram_din_128_tmp[255:128];
            s5_o_sram_din_128_tmp [127:0] <= (stage == S5 && BPE1_o_vld && BPE1_o_rdy) ? {BPE1_aout} : s5_o_sram_din_128_tmp[127:0];
            s5_o_sram_addr_128_tmp [25:13] <= (stage == S5 && BPE1_o_vld && BPE1_o_rdy) ? {4 * (2'd2 + s5_current_addr)} : s5_o_sram_addr_128_tmp[25:13];
            s5_o_sram_addr_128_tmp [12:0] <= (stage == S5 && BPE1_o_vld && BPE1_o_rdy) ? {4 * s5_current_addr} : s5_o_sram_addr_128_tmp[12:0];
            s5_o_WE_128 <= {4{(stage == S5 && BPE1_o_vld && BPE1_o_rdy)}};
            s5_o_sram_en_128 <= (stage == S5 && BPE1_o_vld && BPE1_o_rdy);
        end 

    assign s5_o_sram_din_128 = (phase) ? s5_o_sram_din_128_tmp[255:128]: s5_o_sram_din_128_tmp[127:0];
    assign s5_o_sram_addr_128 = (phase) ? s5_o_sram_addr_128_tmp[25:13]: s5_o_sram_addr_128_tmp[12:0];

    reg  [3:0] s5_group_idx;  // 0 ~ 15
    reg  [1:0] s5_inner_idx;  // 0 ~ 3

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            s5_group_idx <= 0;
            s5_inner_idx <= 0;
        end else if (stage == S5 && BPE1_o_vld && BPE1_o_rdy) begin
            if (s5_inner_idx == 3) begin
                s5_inner_idx <= 0;
                s5_group_idx <= (s5_group_idx == 15) ? 0 : s5_group_idx + 1;
            end else begin
                s5_inner_idx <= s5_inner_idx + 1;
            end
        end
    end

    always @(*) begin
        case (s5_inner_idx)
            2'd0: s5_addr = s5_group_idx * 4;
            2'd1: s5_addr = s5_group_idx * 4 + 1;
            2'd2: s5_addr = s5_group_idx * 4 + 64;
            2'd3: s5_addr = s5_group_idx * 4 + 65;
            default: s5_addr = 0;
        endcase
    end

    assign s5_current_addr = s5_addr;


//====================================== butterfly stage 6 ======================================// 
//============= stage 6 =============// 
// Arithmetic unit: BPE1             // 
// Read: sram 128 * 128              // 
// Write: sram 512* 128             // 
//============= stage 6 =============//  

//============= Get s6 input data ===========//
reg [6:0] s6_i_cnt;

always@(posedge clk or negedge rstn) begin
    if(!rstn) begin
        s6_i_cnt <= 0;
    end else begin
        s6_i_cnt <= (stage == S6) ? ((s6_i_cnt == 7'd66) ? s6_i_cnt : s6_i_cnt + 1) : s6_i_cnt;
    end
end

//============= input to BPE1(data, coefficient) ===========//
    always@* begin
        s6_i_sram_addr_128_tmp [25:13] <= (stage == S6 && s6_i_cnt <= 64) ? {4 * (7'd64 + s6_i_cnt)} : s6_i_sram_addr_128_tmp;
        s6_i_sram_addr_128_tmp [12:0] <= (stage == S6 && s6_i_cnt <= 64) ? {4 * s6_i_cnt} : s6_i_sram_addr_128_tmp;
        s6_i_sram_en_128 = (stage == S6 && s6_i_cnt <= 64);
    end

    assign s6_i_sram_addr_128 = (phase) ? s6_i_sram_addr_128_tmp[25:13]: s6_i_sram_addr_128_tmp[12:0];
     
    always@(posedge clk_2x or negedge rstn) begin
        if(!rstn) begin
            s6_BPE1_ain <= 0;
            s6_BPE1_bin <= 0;
            s6_BPE1_i_vld <= 0;
        end else begin
            s6_BPE1_ain <= (!phase && s6_i_cnt >= 1 && s6_i_cnt <= 65) ? sram_dout_128_buf : s6_BPE1_ain;
            s6_BPE1_bin <= (phase && s6_i_cnt >= 1 && s6_i_cnt <= 65) ? sram_dout_128_buf : s6_BPE1_bin;
            s6_BPE1_i_vld <= (phase && s6_i_cnt >= 1 && s6_i_cnt <= 65) ? 1 : 0;
        end 
    end

    always @(posedge clk_2x or negedge rstn)
        if(!rstn) begin
            s6_BPE1_coef <= 0;
        end else begin
            if(phase) begin
                if((s6_i_cnt >= 1  && s6_i_cnt <= 2))   s6_BPE1_coef <=  {8{W0[15:0]}};
                else if((s6_i_cnt >= 3  && s6_i_cnt <= 4))   s6_BPE1_coef <=  {8{W1[15:0]}};
                else if((s6_i_cnt >= 5  && s6_i_cnt <= 6))   s6_BPE1_coef <=  {8{W2[15:0]}};
                else if((s6_i_cnt >= 7  && s6_i_cnt <= 8))   s6_BPE1_coef <=  {8{W3[15:0]}};
                else if((s6_i_cnt >= 9  && s6_i_cnt <= 10))  s6_BPE1_coef <=  {8{W4[15:0]}};
                else if((s6_i_cnt >= 11 && s6_i_cnt <= 12))  s6_BPE1_coef <=  {8{W5[15:0]}};
                else if((s6_i_cnt >= 13 && s6_i_cnt <= 14))  s6_BPE1_coef <=  {8{W6[15:0]}};
                else if((s6_i_cnt >= 15 && s6_i_cnt <= 16))  s6_BPE1_coef <=  {8{W7[15:0]}};
                else if((s6_i_cnt >= 17 && s6_i_cnt <= 18))  s6_BPE1_coef <=  {8{W8[15:0]}};
                else if((s6_i_cnt >= 19 && s6_i_cnt <= 20))  s6_BPE1_coef <=  {8{W9[15:0]}};
                else if((s6_i_cnt >= 21 && s6_i_cnt <= 22))  s6_BPE1_coef <=  {8{W10[15:0]}};
                else if((s6_i_cnt >= 23 && s6_i_cnt <= 24))  s6_BPE1_coef <=  {8{W11[15:0]}};
                else if((s6_i_cnt >= 25 && s6_i_cnt <= 26))  s6_BPE1_coef <=  {8{W12[15:0]}};
                else if((s6_i_cnt >= 27 && s6_i_cnt <= 28))  s6_BPE1_coef <=  {8{W13[15:0]}};
                else if((s6_i_cnt >= 29 && s6_i_cnt <= 30))  s6_BPE1_coef <=  {8{W14[15:0]}};
                else if((s6_i_cnt >= 31 && s6_i_cnt <= 32))  s6_BPE1_coef <=  {8{W15[15:0]}};
                else if((s6_i_cnt >= 33 && s6_i_cnt <= 34))  s6_BPE1_coef <=  {8{W16[15:0]}};
                else if((s6_i_cnt >= 35 && s6_i_cnt <= 36))  s6_BPE1_coef <=  {8{W17[15:0]}};
                else if((s6_i_cnt >= 37 && s6_i_cnt <= 38))  s6_BPE1_coef <=  {8{W18[15:0]}};       
                else if((s6_i_cnt >= 39 && s6_i_cnt <= 40))  s6_BPE1_coef <=  {8{W19[15:0]}};
                else if((s6_i_cnt >= 41 && s6_i_cnt <= 42))  s6_BPE1_coef <=  {8{W20[15:0]}};
                else if((s6_i_cnt >= 43 && s6_i_cnt <= 44))  s6_BPE1_coef <=  {8{W21[15:0]}};
                else if((s6_i_cnt >= 45 && s6_i_cnt <= 46))  s6_BPE1_coef <=  {8{W22[15:0]}};
                else if((s6_i_cnt >= 47 && s6_i_cnt <= 48))  s6_BPE1_coef <=  {8{W23[15:0]}};
                else if((s6_i_cnt >= 49 && s6_i_cnt <= 50))  s6_BPE1_coef <=  {8{W24[15:0]}};
                else if((s6_i_cnt >= 51 && s6_i_cnt <= 52))  s6_BPE1_coef <=  {8{W25[15:0]}};
                else if((s6_i_cnt >= 53 && s6_i_cnt <= 54))  s6_BPE1_coef <=  {8{W26[15:0]}};
                else if((s6_i_cnt >= 55 && s6_i_cnt <= 56))  s6_BPE1_coef <=  {8{W27[15:0]}};
                else if((s6_i_cnt >= 57 && s6_i_cnt <= 58))  s6_BPE1_coef <=  {8{W28[15:0]}};
                else if((s6_i_cnt >= 59 && s6_i_cnt <= 60))  s6_BPE1_coef <=  {8{W29[15:0]}};
                else if((s6_i_cnt >= 61 && s6_i_cnt <= 62))  s6_BPE1_coef <=  {8{W30[15:0]}};
                else if((s6_i_cnt >= 63 && s6_i_cnt <= 65))  s6_BPE1_coef <=  {8{W31[15:0]}};   
                else s6_BPE1_coef <= s6_BPE1_coef;
            end else begin
                s6_BPE1_coef <= s6_BPE1_coef;
            end
        end


//============= output to bram 512===========//
    reg [6:0] s6_addr; 
    wire [6:0] s6_current_addr;

    always@(posedge clk or negedge rstn) 
        if(!rstn) begin
            s6_o_cnt <= 0;
        end else begin
            s6_o_cnt <= (stage == S6 && BPE1_o_vld && BPE1_o_rdy) ? 
                        ((s6_o_cnt == 7'd64) ? 0 : s6_o_cnt + 1) : s6_o_cnt;
        end 
    
    always@ (posedge clk or negedge rstn) 
        if(!rstn) begin
            s6_o_sram_din_512_tmp <= 0;
            s6_o_sram_addr_512_tmp <= 0;
            s6_o_WE_512 <= 0;
            s6_o_sram_en_512 <= 0;
        end else begin
            s6_o_sram_din_512_tmp [255:128] <= (stage == S6 && BPE1_o_vld && BPE1_o_rdy) ? {BPE1_bout} : s6_o_sram_din_512_tmp[255:128];
            s6_o_sram_din_512_tmp [127:0] <= (stage == S6 && BPE1_o_vld && BPE1_o_rdy) ? {BPE1_aout} : s6_o_sram_din_512_tmp[127:0];
            s6_o_sram_addr_512_tmp [25:13] <= (stage == S6 && BPE1_o_vld && BPE1_o_rdy) ? {4 * (1'd1 + s6_current_addr)} : s6_o_sram_addr_512_tmp[25:13];
            s6_o_sram_addr_512_tmp [12:0] <= (stage == S6 && BPE1_o_vld && BPE1_o_rdy) ? {4 * s6_current_addr} : s6_o_sram_addr_512_tmp[12:0];
            s6_o_WE_512 <= {4{(stage == S6 && BPE1_o_vld && BPE1_o_rdy)}};
            s6_o_sram_en_512 <= (stage == S6 && BPE1_o_vld && BPE1_o_rdy);
        end 

    assign s6_o_sram_din_512 = (phase) ? s6_o_sram_din_512_tmp[255:128]: s6_o_sram_din_512_tmp[127:0];
    assign s6_o_sram_addr_512 = (phase) ? s6_o_sram_addr_512_tmp[25:13]: s6_o_sram_addr_512_tmp[12:0];

    reg  [5:0] s6_group_idx;  // 0 ~ 31
    reg  [1:0] s6_inner_idx;  // 0 ~ 1  

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            s6_group_idx <= 0;
            s6_inner_idx <= 0;
        end else if (stage == S6 && BPE1_o_vld && BPE1_o_rdy) begin
            if (s6_inner_idx == 1) begin
                s6_inner_idx <= 0;
                s6_group_idx <= (s6_group_idx == 31) ? 0 : s6_group_idx + 1;
            end else begin
                s6_inner_idx <= s6_inner_idx + 1;
            end
        end
    end

    always @(*) begin
        s6_addr = (s6_group_idx << 1) + (s6_inner_idx ? 64 : 0);
    end

    assign s6_current_addr = s6_addr;


//====================================== butterfly stage 7 ======================================// 
//============= stage 7 =============// 
// Arithmetic unit: BPE1             // 
// Read: sram 512 * 128              // 
// Write: sram 128* 128             // 
//============= stage 7 =============//  

//============= Get s7 input data ===========//
reg [6:0] s7_i_cnt;

always@(posedge clk or negedge rstn) begin
    if(!rstn) begin
        s7_i_cnt <= 0;
    end else begin
        s7_i_cnt <= (stage == S7_to_10) ? ((s7_i_cnt == 7'd66) ? s7_i_cnt : s7_i_cnt + 1) : s7_i_cnt;
    end
end

//============= input to BPE1(data, coefficient) ===========//
    always@* begin
        s7_i_sram_addr_512_tmp [25:13] <= (stage == S7_to_10 && s7_i_cnt <= 64) ? {4 * (7'd64 + s7_i_cnt)} : s7_i_sram_addr_512_tmp;
        s7_i_sram_addr_512_tmp [12:0] <= (stage == S7_to_10 && s7_i_cnt <= 64) ? {4 * s7_i_cnt} : s7_i_sram_addr_512_tmp;
        s7_i_sram_en_512 = (stage == S7_to_10 && s7_i_cnt <= 64);
    end

    assign s7_i_sram_addr_512 = (phase) ? s7_i_sram_addr_512_tmp[25:13]: s7_i_sram_addr_512_tmp[12:0];
     
    always@(posedge clk_2x or negedge rstn) begin
        if(!rstn) begin
            s7_BPE1_ain <= 0;
            s7_BPE1_bin <= 0;
            s7_BPE1_i_vld <= 0;
        end else begin
            s7_BPE1_ain <= (!phase && s7_i_cnt >= 1 && s7_i_cnt <= 65) ? sram_dout_512_buf : s7_BPE1_ain;
            s7_BPE1_bin <= (phase && s7_i_cnt >= 1 && s7_i_cnt <= 65) ? sram_dout_512_buf : s7_BPE1_bin;
            s7_BPE1_i_vld <= (phase && s7_i_cnt >= 1 && s7_i_cnt <= 65) ? 1 : 0;
        end 
    end

    always @(posedge clk_2x or negedge rstn)
        if(!rstn) begin
            s7_BPE1_coef <= 0;
        end else begin
            if(phase) begin
                if(s7_i_cnt == 1)   s7_BPE1_coef <=  {8{W0[15:0]}};
                else if(s7_i_cnt == 2)   s7_BPE1_coef <=  {8{W1[15:0]}};
                else if(s7_i_cnt == 3)   s7_BPE1_coef <=  {8{W2[15:0]}};
                else if(s7_i_cnt == 4)   s7_BPE1_coef <=  {8{W3[15:0]}};
                else if(s7_i_cnt == 5)   s7_BPE1_coef <=  {8{W4[15:0]}};
                else if(s7_i_cnt == 6)   s7_BPE1_coef <=  {8{W5[15:0]}};
                else if(s7_i_cnt == 7)   s7_BPE1_coef <=  {8{W6[15:0]}};
                else if(s7_i_cnt == 8)   s7_BPE1_coef <=  {8{W7[15:0]}};
                else if(s7_i_cnt == 9)   s7_BPE1_coef <=  {8{W8[15:0]}};
                else if(s7_i_cnt == 10)  s7_BPE1_coef <=  {8{W9[15:0]}};
                else if(s7_i_cnt == 11)  s7_BPE1_coef <=  {8{W10[15:0]}};
                else if(s7_i_cnt == 12)  s7_BPE1_coef <=  {8{W11[15:0]}};
                else if(s7_i_cnt == 13)  s7_BPE1_coef <=  {8{W12[15:0]}};
                else if(s7_i_cnt == 14)  s7_BPE1_coef <=  {8{W13[15:0]}};
                else if(s7_i_cnt == 15)  s7_BPE1_coef <=  {8{W14[15:0]}};
                else if(s7_i_cnt == 16)  s7_BPE1_coef <=  {8{W15[15:0]}};
                else if(s7_i_cnt == 17)  s7_BPE1_coef <=  {8{W16[15:0]}};
                else if(s7_i_cnt == 18)  s7_BPE1_coef <=  {8{W17[15:0]}};
                else if(s7_i_cnt == 19)  s7_BPE1_coef <=  {8{W18[15:0]}};
                else if(s7_i_cnt == 20)  s7_BPE1_coef <=  {8{W19[15:0]}};
                else if(s7_i_cnt == 21)  s7_BPE1_coef <=  {8{W20[15:0]}};
                else if(s7_i_cnt == 22)  s7_BPE1_coef <=  {8{W21[15:0]}};
                else if(s7_i_cnt == 23)  s7_BPE1_coef <=  {8{W22[15:0]}};
                else if(s7_i_cnt == 24)  s7_BPE1_coef <=  {8{W23[15:0]}};
                else if(s7_i_cnt == 25)  s7_BPE1_coef <=  {8{W24[15:0]}};
                else if(s7_i_cnt == 26)  s7_BPE1_coef <=  {8{W25[15:0]}};
                else if(s7_i_cnt == 27)  s7_BPE1_coef <=  {8{W26[15:0]}};
                else if(s7_i_cnt == 28)  s7_BPE1_coef <=  {8{W27[15:0]}};
                else if(s7_i_cnt == 29)  s7_BPE1_coef <=  {8{W28[15:0]}};
                else if(s7_i_cnt == 30)  s7_BPE1_coef <=  {8{W29[15:0]}};
                else if(s7_i_cnt == 31)  s7_BPE1_coef <=  {8{W30[15:0]}};
                else if(s7_i_cnt == 32)  s7_BPE1_coef <=  {8{W31[15:0]}};
                else if(s7_i_cnt == 33)  s7_BPE1_coef <=  {8{W32[15:0]}};
                else if(s7_i_cnt == 34)  s7_BPE1_coef <=  {8{W33[15:0]}};
                else if(s7_i_cnt == 35)  s7_BPE1_coef <=  {8{W34[15:0]}};
                else if(s7_i_cnt == 36)  s7_BPE1_coef <=  {8{W35[15:0]}};
                else if(s7_i_cnt == 37)  s7_BPE1_coef <=  {8{W36[15:0]}};
                else if(s7_i_cnt == 38)  s7_BPE1_coef <=  {8{W37[15:0]}};
                else if(s7_i_cnt == 39)  s7_BPE1_coef <=  {8{W38[15:0]}};
                else if(s7_i_cnt == 40)  s7_BPE1_coef <=  {8{W39[15:0]}};
                else if(s7_i_cnt == 41)  s7_BPE1_coef <=  {8{W40[15:0]}};
                else if(s7_i_cnt == 42)  s7_BPE1_coef <=  {8{W41[15:0]}};
                else if(s7_i_cnt == 43)  s7_BPE1_coef <=  {8{W42[15:0]}};
                else if(s7_i_cnt == 44)  s7_BPE1_coef <=  {8{W43[15:0]}};
                else if(s7_i_cnt == 45)  s7_BPE1_coef <=  {8{W44[15:0]}};
                else if(s7_i_cnt == 46)  s7_BPE1_coef <=  {8{W45[15:0]}};
                else if(s7_i_cnt == 47)  s7_BPE1_coef <=  {8{W46[15:0]}};
                else if(s7_i_cnt == 48)  s7_BPE1_coef <=  {8{W47[15:0]}};
                else if(s7_i_cnt == 49)  s7_BPE1_coef <=  {8{W48[15:0]}};
                else if(s7_i_cnt == 50)  s7_BPE1_coef <=  {8{W49[15:0]}};
                else if(s7_i_cnt == 51)  s7_BPE1_coef <=  {8{W50[15:0]}};
                else if(s7_i_cnt == 52)  s7_BPE1_coef <=  {8{W51[15:0]}};
                else if(s7_i_cnt == 53)  s7_BPE1_coef <=  {8{W52[15:0]}};
                else if(s7_i_cnt == 54)  s7_BPE1_coef <=  {8{W53[15:0]}};
                else if(s7_i_cnt == 55)  s7_BPE1_coef <=  {8{W54[15:0]}};
                else if(s7_i_cnt == 56)  s7_BPE1_coef <=  {8{W55[15:0]}};
                else if(s7_i_cnt == 57)  s7_BPE1_coef <=  {8{W56[15:0]}};
                else if(s7_i_cnt == 58)  s7_BPE1_coef <=  {8{W57[15:0]}};
                else if(s7_i_cnt == 59)  s7_BPE1_coef <=  {8{W58[15:0]}};
                else if(s7_i_cnt == 60)  s7_BPE1_coef <=  {8{W59[15:0]}};
                else if(s7_i_cnt == 61)  s7_BPE1_coef <=  {8{W60[15:0]}};
                else if(s7_i_cnt == 62)  s7_BPE1_coef <=  {8{W61[15:0]}};
                else if(s7_i_cnt == 63)  s7_BPE1_coef <=  {8{W62[15:0]}};
                else if(s7_i_cnt >= 64 &&  s7_i_cnt <= 65)  s7_BPE1_coef <=  {8{W63[15:0]}};
                else s7_BPE1_coef <= s7_BPE1_coef;
            end else begin
                s7_BPE1_coef <= s7_BPE1_coef;
            end
        end

//============= output to buffer before BPE2===========//
    reg [6:0] s7_addr; 
    wire [6:0] s7_current_addr;

    always@(posedge clk or negedge rstn) 
        if(!rstn) begin
            s7_o_cnt <= 0;
        end else begin
            s7_o_cnt <= (stage == S7_to_10 && BPE1_o_vld && BPE1_o_rdy) ? 
                        ((s7_o_cnt == 7'd64) ? 0 : s7_o_cnt + 1) : s7_o_cnt;
        end 
    
    always@ (posedge clk or negedge rstn) 
        if(!rstn) begin
            s7_o_tmp <= 0;
        end else begin
            s7_o_tmp [255:192] <= (stage == S7_to_10 && s7_o_cnt <= 7'd64 && BPE1_o_vld && BPE1_o_rdy) ? {BPE1_bout[127:64]} : s7_o_tmp [255:192];
            s7_o_tmp [191:128] <= (stage == S7_to_10 && s7_o_cnt <= 7'd64 && BPE1_o_vld && BPE1_o_rdy) ? {BPE1_aout[127:64]} : s7_o_tmp [191:128];
            s7_o_tmp [127:64]  <= (stage == S7_to_10 && s7_o_cnt <= 7'd64 && BPE1_o_vld && BPE1_o_rdy) ? {BPE1_bout[63:0]}   : s7_o_tmp [127:64];
            s7_o_tmp [63:0]    <= (stage == S7_to_10 && s7_o_cnt <= 7'd64 && BPE1_o_vld && BPE1_o_rdy) ? {BPE1_aout[63:0]}   : s7_o_tmp [63:0];
        end 


//====================================== butterfly stage 8 ======================================// 
//============= stage 8 =============// 
// Arithmetic unit: BPE2             // 
// Read: s7_o_tmp                    // 
// Write: s8_o_tmp                   // 
//============= stage 8 =============//  

//============= input to BPE2(data, coefficient) ===========//
    always@(posedge clk or negedge rstn) begin
        if(!rstn) begin
            s8_BPE2_ain <= 0;
            s8_BPE2_bin <= 0;
            s8_BPE2_i_vld <= 0;
        end else begin
            s8_BPE2_ain <= (s7_o_cnt >= 1'd1 && s7_o_cnt <= 7'd64) ? s7_o_tmp[127:0] : s8_BPE2_ain;
            s8_BPE2_bin <= (s7_o_cnt >= 1'd1 && s7_o_cnt <= 7'd64) ? s7_o_tmp[255:128] : s8_BPE2_bin;
            s8_BPE2_i_vld <= (s7_o_cnt >= 1'd1 && s7_o_cnt <= 7'd64) ? 1 : 0;
        end 
    end

    always @(posedge clk or negedge rstn)
        if(!rstn) begin
            s8_BPE2_coef <= 0;
        end else begin
            if      (s7_o_cnt == 1)  s8_BPE2_coef <= {{4{W1[15:0]}},{4{W0[15:0]}}};
            else if (s7_o_cnt == 2)  s8_BPE2_coef <= {{4{W3[15:0]}},{4{W2[15:0]}}};
            else if (s7_o_cnt == 3)  s8_BPE2_coef  <= {{4{W5[15:0]}},{4{W4[15:0]}}};
            else if (s7_o_cnt == 4)  s8_BPE2_coef  <= {{4{W7[15:0]}},{4{W6[15:0]}}};
            else if (s7_o_cnt == 5)  s8_BPE2_coef  <= {{4{W9[15:0]}},{4{W8[15:0]}}};
            else if (s7_o_cnt == 6)  s8_BPE2_coef  <= {{4{W11[15:0]}},{4{W10[15:0]}}};
            else if (s7_o_cnt == 7)  s8_BPE2_coef  <= {{4{W13[15:0]}},{4{W12[15:0]}}};
            else if (s7_o_cnt == 8)  s8_BPE2_coef  <= {{4{W15[15:0]}},{4{W14[15:0]}}};
            else if (s7_o_cnt == 9)  s8_BPE2_coef  <= {{4{W17[15:0]}},{4{W16[15:0]}}};
            else if (s7_o_cnt == 10) s8_BPE2_coef  <= {{4{W19[15:0]}},{4{W18[15:0]}}};
            else if (s7_o_cnt == 11) s8_BPE2_coef  <= {{4{W21[15:0]}},{4{W20[15:0]}}};
            else if (s7_o_cnt == 12) s8_BPE2_coef  <= {{4{W23[15:0]}},{4{W22[15:0]}}};
            else if (s7_o_cnt == 13) s8_BPE2_coef  <= {{4{W25[15:0]}},{4{W24[15:0]}}};
            else if (s7_o_cnt == 14) s8_BPE2_coef  <= {{4{W27[15:0]}},{4{W26[15:0]}}};
            else if (s7_o_cnt == 15) s8_BPE2_coef  <= {{4{W29[15:0]}},{4{W28[15:0]}}};
            else if (s7_o_cnt == 16) s8_BPE2_coef  <= {{4{W31[15:0]}},{4{W30[15:0]}}};
            else if (s7_o_cnt == 17) s8_BPE2_coef  <= {{4{W33[15:0]}},{4{W32[15:0]}}};
            else if (s7_o_cnt == 18) s8_BPE2_coef  <= {{4{W35[15:0]}},{4{W34[15:0]}}};
            else if (s7_o_cnt == 19) s8_BPE2_coef  <= {{4{W37[15:0]}},{4{W36[15:0]}}};
            else if (s7_o_cnt == 20) s8_BPE2_coef  <= {{4{W39[15:0]}},{4{W38[15:0]}}};
            else if (s7_o_cnt == 21) s8_BPE2_coef  <= {{4{W41[15:0]}},{4{W40[15:0]}}};
            else if (s7_o_cnt == 22) s8_BPE2_coef  <= {{4{W43[15:0]}},{4{W42[15:0]}}};
            else if (s7_o_cnt == 23) s8_BPE2_coef  <= {{4{W45[15:0]}},{4{W44[15:0]}}};
            else if (s7_o_cnt == 24) s8_BPE2_coef  <= {{4{W47[15:0]}},{4{W46[15:0]}}};
            else if (s7_o_cnt == 25) s8_BPE2_coef  <= {{4{W49[15:0]}},{4{W48[15:0]}}};
            else if (s7_o_cnt == 26) s8_BPE2_coef  <= {{4{W51[15:0]}},{4{W50[15:0]}}};
            else if (s7_o_cnt == 27) s8_BPE2_coef  <= {{4{W53[15:0]}},{4{W52[15:0]}}};
            else if (s7_o_cnt == 28) s8_BPE2_coef  <= {{4{W55[15:0]}},{4{W54[15:0]}}};
            else if (s7_o_cnt == 29) s8_BPE2_coef  <= {{4{W57[15:0]}},{4{W56[15:0]}}};
            else if (s7_o_cnt == 30) s8_BPE2_coef  <= {{4{W59[15:0]}},{4{W58[15:0]}}};
            else if (s7_o_cnt == 31) s8_BPE2_coef  <= {{4{W61[15:0]}},{4{W60[15:0]}}};
            else if (s7_o_cnt == 32) s8_BPE2_coef  <= {{4{W63[15:0]}},{4{W62[15:0]}}};
            else if (s7_o_cnt == 33)  s8_BPE2_coef <= {{4{W1[79:64]}},{4{W0[79:64]}}};
            else if (s7_o_cnt == 34)  s8_BPE2_coef <= {{4{W3[79:64]}},{4{W2[79:64]}}};
            else if (s7_o_cnt == 35)  s8_BPE2_coef <= {{4{W5[79:64]}},{4{W4[79:64]}}};
            else if (s7_o_cnt == 36)  s8_BPE2_coef <= {{4{W7[79:64]}},{4{W6[79:64]}}};
            else if (s7_o_cnt == 37)  s8_BPE2_coef <= {{4{W9[79:64]}},{4{W8[79:64]}}};
            else if (s7_o_cnt == 38)  s8_BPE2_coef <= {{4{W11[79:64]}},{4{W10[79:64]}}};
            else if (s7_o_cnt == 39)  s8_BPE2_coef <= {{4{W13[79:64]}},{4{W12[79:64]}}};
            else if (s7_o_cnt == 40)  s8_BPE2_coef <= {{4{W15[79:64]}},{4{W14[79:64]}}};
            else if (s7_o_cnt == 41)  s8_BPE2_coef <= {{4{W17[79:64]}},{4{W16[79:64]}}};
            else if (s7_o_cnt == 42)  s8_BPE2_coef <= {{4{W19[79:64]}},{4{W18[79:64]}}};
            else if (s7_o_cnt == 43)  s8_BPE2_coef <= {{4{W21[79:64]}},{4{W20[79:64]}}};
            else if (s7_o_cnt == 44)  s8_BPE2_coef <= {{4{W23[79:64]}},{4{W22[79:64]}}};
            else if (s7_o_cnt == 45)  s8_BPE2_coef <= {{4{W25[79:64]}},{4{W24[79:64]}}};
            else if (s7_o_cnt == 46)  s8_BPE2_coef <= {{4{W27[79:64]}},{4{W26[79:64]}}};
            else if (s7_o_cnt == 47)  s8_BPE2_coef <= {{4{W29[79:64]}},{4{W28[79:64]}}};
            else if (s7_o_cnt == 48)  s8_BPE2_coef <= {{4{W31[79:64]}},{4{W30[79:64]}}};
            else if (s7_o_cnt == 49)  s8_BPE2_coef <= {{4{W33[79:64]}},{4{W32[79:64]}}};
            else if (s7_o_cnt == 50)  s8_BPE2_coef <= {{4{W35[79:64]}},{4{W34[79:64]}}};
            else if (s7_o_cnt == 51)  s8_BPE2_coef <= {{4{W37[79:64]}},{4{W36[79:64]}}};
            else if (s7_o_cnt == 52)  s8_BPE2_coef <= {{4{W39[79:64]}},{4{W38[79:64]}}};
            else if (s7_o_cnt == 53)  s8_BPE2_coef <= {{4{W41[79:64]}},{4{W40[79:64]}}};
            else if (s7_o_cnt == 54)  s8_BPE2_coef <= {{4{W43[79:64]}},{4{W42[79:64]}}};
            else if (s7_o_cnt == 55)  s8_BPE2_coef <= {{4{W45[79:64]}},{4{W44[79:64]}}};
            else if (s7_o_cnt == 56)  s8_BPE2_coef <= {{4{W47[79:64]}},{4{W46[79:64]}}};
            else if (s7_o_cnt == 57)  s8_BPE2_coef <= {{4{W49[79:64]}},{4{W48[79:64]}}};
            else if (s7_o_cnt == 58)  s8_BPE2_coef <= {{4{W51[79:64]}},{4{W50[79:64]}}};
            else if (s7_o_cnt == 59)  s8_BPE2_coef <= {{4{W53[79:64]}},{4{W52[79:64]}}};
            else if (s7_o_cnt == 60)  s8_BPE2_coef <= {{4{W55[79:64]}},{4{W54[79:64]}}};
            else if (s7_o_cnt == 61)  s8_BPE2_coef <= {{4{W57[79:64]}},{4{W56[79:64]}}};
            else if (s7_o_cnt == 62)  s8_BPE2_coef <= {{4{W59[79:64]}},{4{W58[79:64]}}};
            else if (s7_o_cnt == 63)  s8_BPE2_coef <= {{4{W61[79:64]}},{4{W60[79:64]}}};
            else if (s7_o_cnt == 64)  s8_BPE2_coef <= {{4{W63[79:64]}},{4{W62[79:64]}}};
            else s8_BPE2_coef <= s8_BPE2_coef;
        end 


//============= output to buffer before BPE3===========//
    always@(posedge clk or negedge rstn) 
        if(!rstn) begin
            s8_o_cnt <= 0;
        end else begin
            s8_o_cnt <= (s8_o_cnt == 7'd64) ? 0 : (stage == S7_to_10 && BPE2_o_vld && BPE2_o_rdy) ? s8_o_cnt + 1 :  s8_o_cnt;
        end 
    
    always@ (posedge clk or negedge rstn) 
        if(!rstn) begin
            s8_o_tmp <= 0;
        end else begin
            s8_o_tmp [255:224] <= (stage == S7_to_10 && s8_o_cnt <= 7'd64 && BPE2_o_vld && BPE2_o_rdy) ? {BPE2_bout[127:96]} : s8_o_tmp [255:224];
            s8_o_tmp [223:192] <= (stage == S7_to_10 && s8_o_cnt <= 7'd64 && BPE2_o_vld && BPE2_o_rdy) ? {BPE2_aout[127:96]} : s8_o_tmp [223:192];
            s8_o_tmp [191:160] <= (stage == S7_to_10 && s8_o_cnt <= 7'd64 && BPE2_o_vld && BPE2_o_rdy) ? {BPE2_bout[63:32]}  : s8_o_tmp [191:160];
            s8_o_tmp [159:128] <= (stage == S7_to_10 && s8_o_cnt <= 7'd64 && BPE2_o_vld && BPE2_o_rdy) ? {BPE2_aout[63:32]}  : s8_o_tmp [159:128];
            s8_o_tmp [127:96]  <= (stage == S7_to_10 && s8_o_cnt <= 7'd64 && BPE2_o_vld && BPE2_o_rdy) ? {BPE2_bout[95:64]}  : s8_o_tmp [127:96];
            s8_o_tmp [95:64]   <= (stage == S7_to_10 && s8_o_cnt <= 7'd64 && BPE2_o_vld && BPE2_o_rdy) ? {BPE2_aout[95:64]}  : s8_o_tmp [95:64];
            s8_o_tmp [63:32]   <= (stage == S7_to_10 && s8_o_cnt <= 7'd64 && BPE2_o_vld && BPE2_o_rdy) ? {BPE2_bout[31:0]}   : s8_o_tmp [63:32];
            s8_o_tmp [31:0]    <= (stage == S7_to_10 && s8_o_cnt <= 7'd64 && BPE2_o_vld && BPE2_o_rdy) ? {BPE2_aout[31:0]}   : s8_o_tmp [31:0];
        end 

//====================================== butterfly stage 9 ======================================// 
//============= stage 9 =============// 
// Arithmetic unit: BPE3             // 
// Read: s8_o_tmp                    // 
// Write: s9_o_tmp                   // 
//============= stage 9 =============//  

//============= input to BPE3(data, coefficient) ===========//
    always@(posedge clk or negedge rstn) begin
        if(!rstn) begin
            s9_BPE3_ain <= 0;
            s9_BPE3_bin <= 0;
            s9_BPE3_i_vld <= 0;
        end else begin
            s9_BPE3_ain <= (s8_o_cnt >= 1'd1 && s8_o_cnt <= 7'd64) ? s8_o_tmp[127:0] : s9_BPE3_ain;
            s9_BPE3_bin <= (s8_o_cnt >= 1'd1 && s8_o_cnt <= 7'd64) ? s8_o_tmp[255:128] : s9_BPE3_bin;
            s9_BPE3_i_vld <= (s8_o_cnt >= 1'd1 && s8_o_cnt <= 7'd64) ? 1 : 0;
        end 
    end

    always @(posedge clk or negedge rstn)
        if(!rstn) begin
            s9_BPE3_coef <= 0;
        end else begin
            if      (s8_o_cnt == 1)  s9_BPE3_coef <= {{2{W3[15:0]}},  {2{W2[15:0]}},  {2{W1[15:0]}},  {2{W0[15:0]}}};
            else if (s8_o_cnt == 2)  s9_BPE3_coef <= {{2{W7[15:0]}},  {2{W6[15:0]}},  {2{W5[15:0]}},  {2{W4[15:0]}}};
            else if (s8_o_cnt == 3)  s9_BPE3_coef <= {{2{W11[15:0]}}, {2{W10[15:0]}}, {2{W9[15:0]}},  {2{W8[15:0]}}};
            else if (s8_o_cnt == 4)  s9_BPE3_coef <= {{2{W15[15:0]}}, {2{W14[15:0]}}, {2{W13[15:0]}}, {2{W12[15:0]}}};
            else if (s8_o_cnt == 5)  s9_BPE3_coef <= {{2{W19[15:0]}}, {2{W18[15:0]}}, {2{W17[15:0]}}, {2{W16[15:0]}}};
            else if (s8_o_cnt == 6)  s9_BPE3_coef <= {{2{W23[15:0]}}, {2{W22[15:0]}}, {2{W21[15:0]}}, {2{W20[15:0]}}};
            else if (s8_o_cnt == 7)  s9_BPE3_coef <= {{2{W27[15:0]}}, {2{W26[15:0]}}, {2{W25[15:0]}}, {2{W24[15:0]}}};
            else if (s8_o_cnt == 8)  s9_BPE3_coef <= {{2{W31[15:0]}}, {2{W30[15:0]}}, {2{W29[15:0]}}, {2{W28[15:0]}}};
            else if (s8_o_cnt == 9)  s9_BPE3_coef <= {{2{W35[15:0]}}, {2{W34[15:0]}}, {2{W33[15:0]}}, {2{W32[15:0]}}};
            else if (s8_o_cnt == 10) s9_BPE3_coef <= {{2{W39[15:0]}}, {2{W38[15:0]}}, {2{W37[15:0]}}, {2{W36[15:0]}}};
            else if (s8_o_cnt == 11) s9_BPE3_coef <= {{2{W43[15:0]}}, {2{W42[15:0]}}, {2{W41[15:0]}}, {2{W40[15:0]}}};
            else if (s8_o_cnt == 12) s9_BPE3_coef <= {{2{W47[15:0]}}, {2{W46[15:0]}}, {2{W45[15:0]}}, {2{W44[15:0]}}};
            else if (s8_o_cnt == 13) s9_BPE3_coef <= {{2{W51[15:0]}}, {2{W50[15:0]}}, {2{W49[15:0]}}, {2{W48[15:0]}}};
            else if (s8_o_cnt == 14) s9_BPE3_coef <= {{2{W55[15:0]}}, {2{W54[15:0]}}, {2{W53[15:0]}}, {2{W52[15:0]}}};
            else if (s8_o_cnt == 15) s9_BPE3_coef <= {{2{W59[15:0]}}, {2{W58[15:0]}}, {2{W57[15:0]}}, {2{W56[15:0]}}};
            else if (s8_o_cnt == 16) s9_BPE3_coef <= {{2{W63[15:0]}}, {2{W62[15:0]}}, {2{W61[15:0]}}, {2{W60[15:0]}}};

            else if (s8_o_cnt == 17) s9_BPE3_coef <= {{2{W3[79:64]}},  {2{W2[79:64]}},  {2{W1[79:64]}},  {2{W0[79:64]}}};
            else if (s8_o_cnt == 18) s9_BPE3_coef <= {{2{W7[79:64]}},  {2{W6[79:64]}},  {2{W5[79:64]}},  {2{W4[79:64]}}};
            else if (s8_o_cnt == 19) s9_BPE3_coef <= {{2{W11[79:64]}}, {2{W10[79:64]}}, {2{W9[79:64]}},  {2{W8[79:64]}}};
            else if (s8_o_cnt == 20) s9_BPE3_coef <= {{2{W15[79:64]}}, {2{W14[79:64]}}, {2{W13[79:64]}}, {2{W12[79:64]}}};
            else if (s8_o_cnt == 21) s9_BPE3_coef <= {{2{W19[79:64]}}, {2{W18[79:64]}}, {2{W17[79:64]}}, {2{W16[79:64]}}};
            else if (s8_o_cnt == 22) s9_BPE3_coef <= {{2{W23[79:64]}}, {2{W22[79:64]}}, {2{W21[79:64]}}, {2{W20[79:64]}}};
            else if (s8_o_cnt == 23) s9_BPE3_coef <= {{2{W27[79:64]}}, {2{W26[79:64]}}, {2{W25[79:64]}}, {2{W24[79:64]}}};
            else if (s8_o_cnt == 24) s9_BPE3_coef <= {{2{W31[79:64]}}, {2{W30[79:64]}}, {2{W29[79:64]}}, {2{W28[79:64]}}};
            else if (s8_o_cnt == 25) s9_BPE3_coef <= {{2{W35[79:64]}}, {2{W34[79:64]}}, {2{W33[79:64]}}, {2{W32[79:64]}}};
            else if (s8_o_cnt == 26) s9_BPE3_coef <= {{2{W39[79:64]}}, {2{W38[79:64]}}, {2{W37[79:64]}}, {2{W36[79:64]}}};
            else if (s8_o_cnt == 27) s9_BPE3_coef <= {{2{W43[79:64]}}, {2{W42[79:64]}}, {2{W41[79:64]}}, {2{W40[79:64]}}};
            else if (s8_o_cnt == 28) s9_BPE3_coef <= {{2{W47[79:64]}}, {2{W46[79:64]}}, {2{W45[79:64]}}, {2{W44[79:64]}}};
            else if (s8_o_cnt == 29) s9_BPE3_coef <= {{2{W51[79:64]}}, {2{W50[79:64]}}, {2{W49[79:64]}}, {2{W48[79:64]}}};
            else if (s8_o_cnt == 30) s9_BPE3_coef <= {{2{W55[79:64]}}, {2{W54[79:64]}}, {2{W53[79:64]}}, {2{W52[79:64]}}};
            else if (s8_o_cnt == 31) s9_BPE3_coef <= {{2{W59[79:64]}}, {2{W58[79:64]}}, {2{W57[79:64]}}, {2{W56[79:64]}}};
            else if (s8_o_cnt == 32) s9_BPE3_coef <= {{2{W63[79:64]}}, {2{W62[79:64]}}, {2{W61[79:64]}}, {2{W60[79:64]}}};

            else if (s8_o_cnt == 33)  s9_BPE3_coef <= {{2{W3[47:32]}},  {2{W2[47:32]}},  {2{W1[47:32]}},  {2{W0[47:32]}}};
            else if (s8_o_cnt == 34)  s9_BPE3_coef <= {{2{W7[47:32]}},  {2{W6[47:32]}},  {2{W5[47:32]}},  {2{W4[47:32]}}};
            else if (s8_o_cnt == 35)  s9_BPE3_coef <= {{2{W11[47:32]}}, {2{W10[47:32]}}, {2{W9[47:32]}},  {2{W8[47:32]}}};
            else if (s8_o_cnt == 36)  s9_BPE3_coef <= {{2{W15[47:32]}}, {2{W14[47:32]}}, {2{W13[47:32]}}, {2{W12[47:32]}}};
            else if (s8_o_cnt == 37)  s9_BPE3_coef <= {{2{W19[47:32]}}, {2{W18[47:32]}}, {2{W17[47:32]}}, {2{W16[47:32]}}};
            else if (s8_o_cnt == 38)  s9_BPE3_coef <= {{2{W23[47:32]}}, {2{W22[47:32]}}, {2{W21[47:32]}}, {2{W20[47:32]}}};
            else if (s8_o_cnt == 39)  s9_BPE3_coef <= {{2{W27[47:32]}}, {2{W26[47:32]}}, {2{W25[47:32]}}, {2{W24[47:32]}}};
            else if (s8_o_cnt == 40)  s9_BPE3_coef <= {{2{W31[47:32]}}, {2{W30[47:32]}}, {2{W29[47:32]}}, {2{W28[47:32]}}};
            else if (s8_o_cnt == 41)  s9_BPE3_coef <= {{2{W35[47:32]}}, {2{W34[47:32]}}, {2{W33[47:32]}}, {2{W32[47:32]}}};
            else if (s8_o_cnt == 42)  s9_BPE3_coef <= {{2{W39[47:32]}}, {2{W38[47:32]}}, {2{W37[47:32]}}, {2{W36[47:32]}}};
            else if (s8_o_cnt == 43)  s9_BPE3_coef <= {{2{W43[47:32]}}, {2{W42[47:32]}}, {2{W41[47:32]}}, {2{W40[47:32]}}};
            else if (s8_o_cnt == 44)  s9_BPE3_coef <= {{2{W47[47:32]}}, {2{W46[47:32]}}, {2{W45[47:32]}}, {2{W44[47:32]}}};
            else if (s8_o_cnt == 45)  s9_BPE3_coef <= {{2{W51[47:32]}}, {2{W50[47:32]}}, {2{W49[47:32]}}, {2{W48[47:32]}}};
            else if (s8_o_cnt == 46)  s9_BPE3_coef <= {{2{W55[47:32]}}, {2{W54[47:32]}}, {2{W53[47:32]}}, {2{W52[47:32]}}};
            else if (s8_o_cnt == 47)  s9_BPE3_coef <= {{2{W59[47:32]}}, {2{W58[47:32]}}, {2{W57[47:32]}}, {2{W56[47:32]}}};
            else if (s8_o_cnt == 48)  s9_BPE3_coef <= {{2{W63[47:32]}}, {2{W62[47:32]}}, {2{W61[47:32]}}, {2{W60[47:32]}}};

            else if (s8_o_cnt == 49)  s9_BPE3_coef <= {{2{W3[111:96]}},  {2{W2[111:96]}},  {2{W1[111:96]}},  {2{W0[111:96]}}};
            else if (s8_o_cnt == 50)  s9_BPE3_coef <= {{2{W7[111:96]}},  {2{W6[111:96]}},  {2{W5[111:96]}},  {2{W4[111:96]}}};
            else if (s8_o_cnt == 51)  s9_BPE3_coef <= {{2{W11[111:96]}}, {2{W10[111:96]}}, {2{W9[111:96]}},  {2{W8[111:96]}}};
            else if (s8_o_cnt == 52)  s9_BPE3_coef <= {{2{W15[111:96]}}, {2{W14[111:96]}}, {2{W13[111:96]}}, {2{W12[111:96]}}};
            else if (s8_o_cnt == 53)  s9_BPE3_coef <= {{2{W19[111:96]}}, {2{W18[111:96]}}, {2{W17[111:96]}}, {2{W16[111:96]}}};
            else if (s8_o_cnt == 54)  s9_BPE3_coef <= {{2{W23[111:96]}}, {2{W22[111:96]}}, {2{W21[111:96]}}, {2{W20[111:96]}}};
            else if (s8_o_cnt == 55)  s9_BPE3_coef <= {{2{W27[111:96]}}, {2{W26[111:96]}}, {2{W25[111:96]}}, {2{W24[111:96]}}};
            else if (s8_o_cnt == 56)  s9_BPE3_coef <= {{2{W31[111:96]}}, {2{W30[111:96]}}, {2{W29[111:96]}}, {2{W28[111:96]}}};
            else if (s8_o_cnt == 57)  s9_BPE3_coef <= {{2{W35[111:96]}}, {2{W34[111:96]}}, {2{W33[111:96]}}, {2{W32[111:96]}}};
            else if (s8_o_cnt == 58)  s9_BPE3_coef <= {{2{W39[111:96]}}, {2{W38[111:96]}}, {2{W37[111:96]}}, {2{W36[111:96]}}};
            else if (s8_o_cnt == 59)  s9_BPE3_coef <= {{2{W43[111:96]}}, {2{W42[111:96]}}, {2{W41[111:96]}}, {2{W40[111:96]}}};
            else if (s8_o_cnt == 60)  s9_BPE3_coef <= {{2{W47[111:96]}}, {2{W46[111:96]}}, {2{W45[111:96]}}, {2{W44[111:96]}}};
            else if (s8_o_cnt == 61)  s9_BPE3_coef <= {{2{W51[111:96]}}, {2{W50[111:96]}}, {2{W49[111:96]}}, {2{W48[111:96]}}};
            else if (s8_o_cnt == 62)  s9_BPE3_coef <= {{2{W55[111:96]}}, {2{W54[111:96]}}, {2{W53[111:96]}}, {2{W52[111:96]}}};
            else if (s8_o_cnt == 63)  s9_BPE3_coef <= {{2{W59[111:96]}}, {2{W58[111:96]}}, {2{W57[111:96]}}, {2{W56[111:96]}}};
            else if (s8_o_cnt == 64)  s9_BPE3_coef <= {{2{W63[111:96]}}, {2{W62[111:96]}}, {2{W61[111:96]}}, {2{W60[111:96]}}};
            else s9_BPE3_coef <= s9_BPE3_coef;
        end 

//============= output to buffer before BPE3===========//
    always@(posedge clk or negedge rstn) 
        if(!rstn) begin
            s9_o_cnt <= 0;
        end else begin
            s9_o_cnt <= (s9_o_cnt == 7'd64) ? 0 : (stage == S7_to_10 && BPE3_o_vld && BPE3_o_rdy) ? s9_o_cnt + 1 :  s9_o_cnt;
        end 
    
    always@ (posedge clk or negedge rstn) 
        if(!rstn) begin
            s9_o_tmp <= 0;
        end else begin
            s9_o_tmp [255:240] <= (stage == S7_to_10 && s9_o_cnt <= 7'd64 && BPE3_o_vld && BPE3_o_rdy) ? {BPE3_bout[127:112]}: s9_o_tmp [255:240];
            s9_o_tmp [239:224] <= (stage == S7_to_10 && s9_o_cnt <= 7'd64 && BPE3_o_vld && BPE3_o_rdy) ? {BPE3_aout[127:112]}: s9_o_tmp [239:224];
            s9_o_tmp [223:208] <= (stage == S7_to_10 && s9_o_cnt <= 7'd64 && BPE3_o_vld && BPE3_o_rdy) ? {BPE3_bout[95:80]} : s9_o_tmp [223:208];
            s9_o_tmp [207:192] <= (stage == S7_to_10 && s9_o_cnt <= 7'd64 && BPE3_o_vld && BPE3_o_rdy) ? {BPE3_aout[95:80]} : s9_o_tmp [207:192];
            s9_o_tmp [191:176] <= (stage == S7_to_10 && s9_o_cnt <= 7'd64 && BPE3_o_vld && BPE3_o_rdy) ? {BPE3_bout[63:48]}  : s9_o_tmp [191:176];
            s9_o_tmp [175:160] <= (stage == S7_to_10 && s9_o_cnt <= 7'd64 && BPE3_o_vld && BPE3_o_rdy) ? {BPE3_aout[63:48]}  : s9_o_tmp [175:160];
            s9_o_tmp [159:144] <= (stage == S7_to_10 && s9_o_cnt <= 7'd64 && BPE3_o_vld && BPE3_o_rdy) ? {BPE3_bout[31:16]}  : s9_o_tmp [159:144];
            s9_o_tmp [143:128] <= (stage == S7_to_10 && s9_o_cnt <= 7'd64 && BPE3_o_vld && BPE3_o_rdy) ? {BPE3_aout[31:16]}  : s9_o_tmp [143:128];
            s9_o_tmp [127:112] <= (stage == S7_to_10 && s9_o_cnt <= 7'd64 && BPE3_o_vld && BPE3_o_rdy) ? {BPE3_bout[111:96]}  : s9_o_tmp [127:112];
            s9_o_tmp [111:96]  <= (stage == S7_to_10 && s9_o_cnt <= 7'd64 && BPE3_o_vld && BPE3_o_rdy) ? {BPE3_aout[111:96]}  : s9_o_tmp [111:96] ;
            s9_o_tmp [95:80]   <= (stage == S7_to_10 && s9_o_cnt <= 7'd64 && BPE3_o_vld && BPE3_o_rdy) ? {BPE3_bout[79:64]}  : s9_o_tmp [95:80]  ;
            s9_o_tmp [79:64]   <= (stage == S7_to_10 && s9_o_cnt <= 7'd64 && BPE3_o_vld && BPE3_o_rdy) ? {BPE3_aout[79:64]}  : s9_o_tmp [79:64]  ;
            s9_o_tmp [63:48]   <= (stage == S7_to_10 && s9_o_cnt <= 7'd64 && BPE3_o_vld && BPE3_o_rdy) ? {BPE3_bout[47:32]}  : s9_o_tmp [63:48]  ;
            s9_o_tmp [47:32]   <= (stage == S7_to_10 && s9_o_cnt <= 7'd64 && BPE3_o_vld && BPE3_o_rdy) ? {BPE3_aout[47:32]}  : s9_o_tmp [47:32]  ;
            s9_o_tmp [31:16]   <= (stage == S7_to_10 && s9_o_cnt <= 7'd64 && BPE3_o_vld && BPE3_o_rdy) ? {BPE3_bout[15:0]}   : s9_o_tmp [31:16]  ;
            s9_o_tmp [15:0]    <= (stage == S7_to_10 && s9_o_cnt <= 7'd64 && BPE3_o_vld && BPE3_o_rdy) ? {BPE3_aout[15:0]}   : s9_o_tmp [15:0]   ;
        
        end 

//====================================== butterfly stage 10======================================// 
//=================== stage 10 ===================// 
// Arithmetic unit: BPE4                          // 
// Read: s9_o_tmp                                 // 
// Write: sram 128*128 (NTT)、divN (iNTT)  // 
//=================== stage 10 ===================// 

//============= input to BPE4(data, coefficient) ===========//
    always@(posedge clk or negedge rstn) begin
        if(!rstn) begin
            s10_BPE4_ain <= 0;
            s10_BPE4_bin <= 0;
            s10_BPE4_i_vld <= 0;
        end else begin
            s10_BPE4_ain <= (s9_o_cnt >= 1'd1 && s9_o_cnt <= 7'd64) ? s9_o_tmp[127:0] : s10_BPE4_ain;
            s10_BPE4_bin <= (s9_o_cnt >= 1'd1 && s9_o_cnt <= 7'd64) ? s9_o_tmp[255:128] : s10_BPE4_bin;
            s10_BPE4_i_vld <= (s9_o_cnt >= 1'd1 && s9_o_cnt <= 7'd64) ? 1 : 0;
        end 
    end

    always @(posedge clk or negedge rstn)
        if(!rstn) begin
            s10_BPE4_coef <= 0;
        end else begin
            if      (s9_o_cnt == 1)  s10_BPE4_coef <= {W7[15:0], W6[15:0], W5[15:0], W4[15:0], W3[15:0], W2[15:0], W1[15:0], W0[15:0]};
            else if (s9_o_cnt == 2)  s10_BPE4_coef <= {W15[15:0], W14[15:0], W13[15:0], W12[15:0], W11[15:0], W10[15:0], W9[15:0], W8[15:0]};
            else if (s9_o_cnt == 3)  s10_BPE4_coef <= {W23[15:0], W22[15:0], W21[15:0], W20[15:0], W19[15:0], W18[15:0], W17[15:0], W16[15:0]};
            else if (s9_o_cnt == 4)  s10_BPE4_coef <= {W31[15:0], W30[15:0], W29[15:0], W28[15:0], W27[15:0], W26[15:0], W25[15:0], W24[15:0]};
            else if (s9_o_cnt == 5)  s10_BPE4_coef <= {W39[15:0], W38[15:0], W37[15:0], W36[15:0], W35[15:0], W34[15:0], W33[15:0], W32[15:0]};
            else if (s9_o_cnt == 6)  s10_BPE4_coef <= {W47[15:0], W46[15:0], W45[15:0], W44[15:0], W43[15:0], W42[15:0], W41[15:0], W40[15:0]};
            else if (s9_o_cnt == 7)  s10_BPE4_coef <= {W55[15:0], W54[15:0], W53[15:0], W52[15:0], W51[15:0], W50[15:0], W49[15:0], W48[15:0]};
            else if (s9_o_cnt == 8)  s10_BPE4_coef <= {W63[15:0], W62[15:0], W61[15:0], W60[15:0], W59[15:0], W58[15:0], W57[15:0], W56[15:0]};
            
            else if (s9_o_cnt == 9)  s10_BPE4_coef <= {W7[79:64], W6[79:64], W5[79:64], W4[79:64], W3[79:64], W2[79:64], W1[79:64], W0[79:64]};
            else if (s9_o_cnt == 10) s10_BPE4_coef <= {W15[79:64], W14[79:64], W13[79:64], W12[79:64], W11[79:64], W10[79:64], W9[79:64], W8[79:64]};
            else if (s9_o_cnt == 11) s10_BPE4_coef <= {W23[79:64], W22[79:64], W21[79:64], W20[79:64], W19[79:64], W18[79:64], W17[79:64], W16[79:64]};
            else if (s9_o_cnt == 12) s10_BPE4_coef <= {W31[79:64], W30[79:64], W29[79:64], W28[79:64], W27[79:64], W26[79:64], W25[79:64], W24[79:64]};
            else if (s9_o_cnt == 13) s10_BPE4_coef <= {W39[79:64], W38[79:64], W37[79:64], W36[79:64], W35[79:64], W34[79:64], W33[79:64], W32[79:64]};
            else if (s9_o_cnt == 14) s10_BPE4_coef <= {W47[79:64], W46[79:64], W45[79:64], W44[79:64], W43[79:64], W42[79:64], W41[79:64], W40[79:64]};
            else if (s9_o_cnt == 15) s10_BPE4_coef <= {W55[79:64], W54[79:64], W53[79:64], W52[79:64], W51[79:64], W50[79:64], W49[79:64], W48[79:64]};
            else if (s9_o_cnt == 16) s10_BPE4_coef <= {W63[79:64], W62[79:64], W61[79:64], W60[79:64], W59[79:64], W58[79:64], W57[79:64], W56[79:64]};

            else if (s9_o_cnt == 17) s10_BPE4_coef <= {W7[47:32], W6[47:32], W5[47:32], W4[47:32], W3[47:32], W2[47:32], W1[47:32], W0[47:32]};
            else if (s9_o_cnt == 18) s10_BPE4_coef <= {W15[47:32], W14[47:32], W13[47:32], W12[47:32], W11[47:32], W10[47:32], W9[47:32], W8[47:32]};
            else if (s9_o_cnt == 19) s10_BPE4_coef <= {W23[47:32], W22[47:32], W21[47:32], W20[47:32], W19[47:32], W18[47:32], W17[47:32], W16[47:32]};
            else if (s9_o_cnt == 20) s10_BPE4_coef <= {W31[47:32], W30[47:32], W29[47:32], W28[47:32], W27[47:32], W26[47:32], W25[47:32], W24[47:32]};
            else if (s9_o_cnt == 21) s10_BPE4_coef <= {W39[47:32], W38[47:32], W37[47:32], W36[47:32], W35[47:32], W34[47:32], W33[47:32], W32[47:32]};
            else if (s9_o_cnt == 22) s10_BPE4_coef <= {W47[47:32], W46[47:32], W45[47:32], W44[47:32], W43[47:32], W42[47:32], W41[47:32], W40[47:32]};
            else if (s9_o_cnt == 23) s10_BPE4_coef <= {W55[47:32], W54[47:32], W53[47:32], W52[47:32], W51[47:32], W50[47:32], W49[47:32], W48[47:32]};
            else if (s9_o_cnt == 24) s10_BPE4_coef <= {W63[47:32], W62[47:32], W61[47:32], W60[47:32], W59[47:32], W58[47:32], W57[47:32], W56[47:32]};
            
            else if (s9_o_cnt == 25) s10_BPE4_coef <= {W7[111:96], W6[111:96], W5[111:96], W4[111:96], W3[111:96], W2[111:96], W1[111:96], W0[111:96]};
            else if (s9_o_cnt == 26) s10_BPE4_coef <= {W15[111:96], W14[111:96], W13[111:96], W12[111:96], W11[111:96], W10[111:96], W9[111:96], W8[111:96]};
            else if (s9_o_cnt == 27) s10_BPE4_coef <= {W23[111:96], W22[111:96], W21[111:96], W20[111:96], W19[111:96], W18[111:96], W17[111:96], W16[111:96]};
            else if (s9_o_cnt == 28) s10_BPE4_coef <= {W31[111:96], W30[111:96], W29[111:96], W28[111:96], W27[111:96], W26[111:96], W25[111:96], W24[111:96]};
            else if (s9_o_cnt == 29) s10_BPE4_coef <= {W39[111:96], W38[111:96], W37[111:96], W36[111:96], W35[111:96], W34[111:96], W33[111:96], W32[111:96]};
            else if (s9_o_cnt == 30) s10_BPE4_coef <= {W47[111:96], W46[111:96], W45[111:96], W44[111:96], W43[111:96], W42[111:96], W41[111:96], W40[111:96]};
            else if (s9_o_cnt == 31) s10_BPE4_coef <= {W55[111:96], W54[111:96], W53[111:96], W52[111:96], W51[111:96], W50[111:96], W49[111:96], W48[111:96]};
            else if (s9_o_cnt == 32) s10_BPE4_coef <= {W63[111:96], W62[111:96], W61[111:96], W60[111:96], W59[111:96], W58[111:96], W57[111:96], W56[111:96]};

            else if (s9_o_cnt == 33)  s10_BPE4_coef <= {W7[31:16], W6[31:16], W5[31:16], W4[31:16], W3[31:16], W2[31:16], W1[31:16], W0[31:16]};
            else if (s9_o_cnt == 34)  s10_BPE4_coef <= {W15[31:16], W14[31:16], W13[31:16], W12[31:16], W11[31:16], W10[31:16], W9[31:16], W8[31:16]};
            else if (s9_o_cnt == 35)  s10_BPE4_coef <= {W23[31:16], W22[31:16], W21[31:16], W20[31:16], W19[31:16], W18[31:16], W17[31:16], W16[31:16]};
            else if (s9_o_cnt == 36)  s10_BPE4_coef <= {W31[31:16], W30[31:16], W29[31:16], W28[31:16], W27[31:16], W26[31:16], W25[31:16], W24[31:16]};
            else if (s9_o_cnt == 37)  s10_BPE4_coef <= {W39[31:16], W38[31:16], W37[31:16], W36[31:16], W35[31:16], W34[31:16], W33[31:16], W32[31:16]};
            else if (s9_o_cnt == 38)  s10_BPE4_coef <= {W47[31:16], W46[31:16], W45[31:16], W44[31:16], W43[31:16], W42[31:16], W41[31:16], W40[31:16]};
            else if (s9_o_cnt == 39)  s10_BPE4_coef <= {W55[31:16], W54[31:16], W53[31:16], W52[31:16], W51[31:16], W50[31:16], W49[31:16], W48[31:16]};
            else if (s9_o_cnt == 40)  s10_BPE4_coef <= {W63[31:16], W62[31:16], W61[31:16], W60[31:16], W59[31:16], W58[31:16], W57[31:16], W56[31:16]};
            
            else if (s9_o_cnt == 41)  s10_BPE4_coef <= {W7[95:80], W6[95:80], W5[95:80], W4[95:80], W3[95:80], W2[95:80], W1[95:80], W0[95:80]};
            else if (s9_o_cnt == 42)  s10_BPE4_coef <= {W15[95:80], W14[95:80], W13[95:80], W12[95:80], W11[95:80], W10[95:80], W9[95:80], W8[95:80]};
            else if (s9_o_cnt == 43)  s10_BPE4_coef <= {W23[95:80], W22[95:80], W21[95:80], W20[95:80], W19[95:80], W18[95:80], W17[95:80], W16[95:80]};
            else if (s9_o_cnt == 44)  s10_BPE4_coef <= {W31[95:80], W30[95:80], W29[95:80], W28[95:80], W27[95:80], W26[95:80], W25[95:80], W24[95:80]};
            else if (s9_o_cnt == 45)  s10_BPE4_coef <= {W39[95:80], W38[95:80], W37[95:80], W36[95:80], W35[95:80], W34[95:80], W33[95:80], W32[95:80]};
            else if (s9_o_cnt == 46)  s10_BPE4_coef <= {W47[95:80], W46[95:80], W45[95:80], W44[95:80], W43[95:80], W42[95:80], W41[95:80], W40[95:80]};
            else if (s9_o_cnt == 47)  s10_BPE4_coef <= {W55[95:80], W54[95:80], W53[95:80], W52[95:80], W51[95:80], W50[95:80], W49[95:80], W48[95:80]};
            else if (s9_o_cnt == 48)  s10_BPE4_coef <= {W63[95:80], W62[95:80], W61[95:80], W60[95:80], W59[95:80], W58[95:80], W57[95:80], W56[95:80]};

            else if (s9_o_cnt == 49)  s10_BPE4_coef <= {W7[63:48], W6[63:48], W5[63:48], W4[63:48], W3[63:48], W2[63:48], W1[63:48], W0[63:48]};
            else if (s9_o_cnt == 50)  s10_BPE4_coef <= {W15[63:48], W14[63:48], W13[63:48], W12[63:48], W11[63:48], W10[63:48], W9[63:48], W8[63:48]};
            else if (s9_o_cnt == 51)  s10_BPE4_coef <= {W23[63:48], W22[63:48], W21[63:48], W20[63:48], W19[63:48], W18[63:48], W17[63:48], W16[63:48]};
            else if (s9_o_cnt == 52)  s10_BPE4_coef <= {W31[63:48], W30[63:48], W29[63:48], W28[63:48], W27[63:48], W26[63:48], W25[63:48], W24[63:48]};
            else if (s9_o_cnt == 53)  s10_BPE4_coef <= {W39[63:48], W38[63:48], W37[63:48], W36[63:48], W35[63:48], W34[63:48], W33[63:48], W32[63:48]};
            else if (s9_o_cnt == 54)  s10_BPE4_coef <= {W47[63:48], W46[63:48], W45[63:48], W44[63:48], W43[63:48], W42[63:48], W41[63:48], W40[63:48]};
            else if (s9_o_cnt == 55)  s10_BPE4_coef <= {W55[63:48], W54[63:48], W53[63:48], W52[63:48], W51[63:48], W50[63:48], W49[63:48], W48[63:48]};
            else if (s9_o_cnt == 56)  s10_BPE4_coef <= {W63[63:48], W62[63:48], W61[63:48], W60[63:48], W59[63:48], W58[63:48], W57[63:48], W56[63:48]};
            
            else if (s9_o_cnt == 57)  s10_BPE4_coef <= {W7[127:112], W6[127:112], W5[127:112], W4[127:112], W3[127:112], W2[127:112], W1[127:112], W0[127:112]};
            else if (s9_o_cnt == 58)  s10_BPE4_coef <= {W15[127:112], W14[127:112], W13[127:112], W12[127:112], W11[127:112], W10[127:112], W9[127:112], W8[127:112]};
            else if (s9_o_cnt == 59)  s10_BPE4_coef <= {W23[127:112], W22[127:112], W21[127:112], W20[127:112], W19[127:112], W18[127:112], W17[127:112], W16[127:112]};
            else if (s9_o_cnt == 60)  s10_BPE4_coef <= {W31[127:112], W30[127:112], W29[127:112], W28[127:112], W27[127:112], W26[127:112], W25[127:112], W24[127:112]};
            else if (s9_o_cnt == 61)  s10_BPE4_coef <= {W39[127:112], W38[127:112], W37[127:112], W36[127:112], W35[127:112], W34[127:112], W33[127:112], W32[127:112]};
            else if (s9_o_cnt == 62)  s10_BPE4_coef <= {W47[127:112], W46[127:112], W45[127:112], W44[127:112], W43[127:112], W42[127:112], W41[127:112], W40[127:112]};
            else if (s9_o_cnt == 63)  s10_BPE4_coef <= {W55[127:112], W54[127:112], W53[127:112], W52[127:112], W51[127:112], W50[127:112], W49[127:112], W48[127:112]};
            else if (s9_o_cnt == 64)  s10_BPE4_coef <= {W63[127:112], W62[127:112], W61[127:112], W60[127:112], W59[127:112], W58[127:112], W57[127:112], W56[127:112]};
            else s10_BPE4_coef <= s10_BPE4_coef;
        end 

    
//============= output to buffer before module or output ram===========//
    wire [(pDATA_WIDTH-1):0] aout_iNTT, bout_iNTT;
    wire o_vld1_iNTT, o_vld2_iNTT;
    reg [6:0] s10_div_o_cnt;

    always@(posedge clk or negedge rstn) 
        if(!rstn) begin
            s10_o_cnt <= 0;
        end else begin
            s10_o_cnt <= (s10_o_cnt == 7'd64) ? 0 : (stage == S7_to_10 && BPE4_o_vld && BPE4_o_rdy) ? s10_o_cnt + 1 :  s10_o_cnt;   
        end 


    // NTT output to buffer before ram
    always@ (posedge clk or negedge rstn) 
        if(!rstn) begin
            s10_o_tmp_a <= 0;
            s10_o_tmp_b <= 0;
        end else begin
            case(mode_state[1:0])
            NTT: begin
                s10_o_tmp_a <= (stage == S7_to_10 && s10_o_cnt <= 7'd64 && BPE4_o_vld && BPE4_o_rdy) ?
                            {BPE4_bout[63:48], BPE4_aout[63:48], BPE4_bout[47:32], BPE4_aout[47:32], BPE4_bout[31:16], BPE4_aout[31:16], BPE4_bout[15:0], BPE4_aout[15:0]}: s10_o_tmp_a;
                s10_o_tmp_b <= (stage == S7_to_10 && s10_o_cnt <= 7'd64 && BPE4_o_vld && BPE4_o_rdy) ?
                            {BPE4_bout[127:112], BPE4_aout[127:112], BPE4_bout[111:96], BPE4_aout[111:96], BPE4_bout[95:80], BPE4_aout[95:80], BPE4_bout[79:64], BPE4_aout[79:64]}: s10_o_tmp_a;
            end
            iNTT: begin
                s10_o_tmp_a <= (stage == S7_to_10 && o_vld1_iNTT && o_vld2_iNTT) ?
                            {bout_iNTT[63:48], aout_iNTT[63:48], bout_iNTT[47:32], aout_iNTT[47:32], bout_iNTT[31:16], aout_iNTT[31:16], bout_iNTT[15:0], aout_iNTT[15:0]}: s10_o_tmp_a;
                s10_o_tmp_b <= (stage == S7_to_10 && o_vld1_iNTT && o_vld2_iNTT) ?
                            {bout_iNTT[127:112], aout_iNTT[127:112], bout_iNTT[111:96], aout_iNTT[111:96], bout_iNTT[95:80], aout_iNTT[95:80], bout_iNTT[79:64], aout_iNTT[79:64]}: s10_o_tmp_b;
            end
            endcase
        end

    always@(posedge clk or negedge rstn)
        if(!rstn) begin
            s10_div_o_cnt <= 0;
        end else begin
            s10_div_o_cnt <= (s10_div_o_cnt == 7'd64) ? 0 : (o_vld1_iNTT) ? s10_div_o_cnt + 1: s10_div_o_cnt;
        end

    // iNTT output to divN
    divN divN1(
        .in_A(BPE4_aout),
        .clk(clk),
        .rst_n(rstn),
        .in_valid(BPE4_o_vld && mode_state[1:0] == iNTT),
        .result_int(aout_iNTT),
        .out_valid(o_vld1_iNTT)
    );

    // iNTT output to divN
    divN divN2(
        .in_A(BPE4_bout),
        .clk(clk),
        .rst_n(rstn),
        .in_valid(BPE4_o_vld && mode_state[1:0] == iNTT),
        .result_int(bout_iNTT),
        .out_valid(o_vld2_iNTT)
    );

//============= output ram ===========//
    reg [6:0] s10_addr; 
    reg [6:0] s10_current_addr;

    always@* 
        case(mode_state[1:0]) 
            NTT:begin
                s10_o_sram_din_128_tmp [255:128] = (stage == S7_to_10 && s10_o_cnt >= 1'd1 && s10_o_cnt <= 7'd64) ? {s10_o_tmp_b[127:0]} : s10_o_sram_din_128_tmp[255:128];
                s10_o_sram_din_128_tmp [127:0] = (stage == S7_to_10  && s10_o_cnt >= 1'd1 && s10_o_cnt <= 7'd64) ? {s10_o_tmp_a[127:0]} : s10_o_sram_din_128_tmp[127:0];
                s10_o_sram_addr_128_tmp [25:13] = (stage == S7_to_10 &&  s10_o_cnt >= 1'd1 && s10_o_cnt <= 7'd64) ? {4 * (1'd1 + s10_current_addr)} : s10_o_sram_addr_128_tmp[25:13];
                s10_o_sram_addr_128_tmp [12:0] = (stage == S7_to_10 &&  s10_o_cnt >= 1'd1 && s10_o_cnt <= 7'd64) ? {4 * s10_current_addr} : s10_o_sram_addr_128_tmp[12:0];
                s10_o_WE_128 = {4{(stage == S7_to_10 && s10_o_cnt >= 1'd1 && s10_o_cnt <= 7'd64)}};
                s10_o_sram_en_128 = (stage == S7_to_10 && s10_o_cnt >= 1'd1 && s10_o_cnt <= 7'd64);
                s10_o_sram_din_128 = (phase) ? s10_o_sram_din_128_tmp[255:128]: s10_o_sram_din_128_tmp[127:0];
                s10_o_sram_addr_128 = (phase) ? s10_o_sram_addr_128_tmp[25:13]: s10_o_sram_addr_128_tmp[12:0];
                s10_current_addr = (stage == S7_to_10 && s10_o_cnt >= 1'd1 && s10_o_cnt <= 7'd64) ? ((s10_o_cnt-1) << 1): s10_current_addr;
            end
            iNTT:begin
                s10_o_sram_din_128_tmp [255:128] = (stage == S7_to_10 && s10_div_o_cnt >= 1'd1 && s10_div_o_cnt <= 7'd64) ? {s10_o_tmp_b[127:0]} : s10_o_sram_din_128_tmp[255:128];
                s10_o_sram_din_128_tmp [127:0] = (stage == S7_to_10  && s10_div_o_cnt >= 1'd1 && s10_div_o_cnt <= 7'd64) ? {s10_o_tmp_a[127:0]} : s10_o_sram_din_128_tmp[127:0];
                s10_o_sram_addr_128_tmp [25:13] = (stage == S7_to_10 &&  s10_div_o_cnt >= 1'd1 && s10_div_o_cnt <= 7'd64) ? {4 * (1'd1 + s10_current_addr)} : s10_o_sram_addr_128_tmp[25:13];
                s10_o_sram_addr_128_tmp [12:0] = (stage == S7_to_10 &&  s10_div_o_cnt >= 1'd1 && s10_div_o_cnt <= 7'd64) ? {4 * s10_current_addr} : s10_o_sram_addr_128_tmp[12:0];
                s10_o_WE_128 = {4{(stage == S7_to_10 && s10_div_o_cnt >= 1'd1 && s10_div_o_cnt <= 7'd64)}};
                s10_o_sram_en_128 = (stage == S7_to_10 && s10_div_o_cnt >= 1'd1 && s10_div_o_cnt <= 7'd64);
                s10_o_sram_din_128 = (phase) ? s10_o_sram_din_128_tmp[255:128]: s10_o_sram_din_128_tmp[127:0];
                s10_o_sram_addr_128 = (phase) ? s10_o_sram_addr_128_tmp[25:13]: s10_o_sram_addr_128_tmp[12:0];
                s10_current_addr = (stage == S7_to_10 && s10_div_o_cnt >= 1'd1 && s10_div_o_cnt <= 7'd64) ? ((s10_div_o_cnt-1) << 1): s10_current_addr;
            end
        endcase
    


//====================================== stream out======================================// 
//=================== stream out ===================// 
// Arithmetic unit:                                 // 
// Read: sram 128*128 (NTT)                         // 
// Write:                                           // 
//=================== stream out ===================// 
    localparam FETCH = 1'b0;
    localparam WAIT_OUT = 1'b1;
    reg sm_state, next_sm_state;
    reg next_sm_o_en, next_sw_vld;
    reg [12:0] sm_o_sram_addr_128_tmp;
    reg [12:0] next_sm_o_sram_addr_128_tmp;

    always@* begin
        case(sm_state)
            FETCH: begin
                next_sm_o_en = 0;
                next_sm_state = WAIT_OUT;
                next_sw_vld = 1;
                next_sm_o_sram_addr_128_tmp = sm_o_sram_addr_128_tmp;
            end
            WAIT_OUT: begin
                if(sw_rdy) begin
                    next_sm_o_en = 1;
                    next_sm_state = FETCH;
                    next_sw_vld = 0;
                    next_sm_o_sram_addr_128_tmp = sm_o_sram_addr_128_tmp + 1;
                end else begin
                    next_sm_o_en = 0;
                    next_sm_state = WAIT_OUT;
                    next_sw_vld = 1;
                    next_sm_o_sram_addr_128_tmp = sm_o_sram_addr_128_tmp;
                end
            end
            default: begin
                next_sm_o_en = 0;
                next_sm_state = FETCH;
                next_sw_vld = 0;
                next_sm_o_sram_addr_128_tmp = 0;
            end
        endcase
    end

    always@ (posedge clk or negedge rstn) begin
        if(!rstn) begin
            sm_o_sram_en_128 <= 1;
            sm_state <= FETCH;
            sw_vld <= 0;
            sm_o_sram_addr_128_tmp <= 0;
            sw_dat <= 0;
        end else begin
            sm_o_sram_en_128 <= (stage == OUT) ? next_sm_o_en : sm_o_sram_en_128;
            sm_state <= (stage == OUT) ? next_sm_state : sm_state;
            sw_vld <= (stage == OUT) ? next_sw_vld : sw_vld;
            sm_o_sram_addr_128_tmp <= (stage == OUT) ? next_sm_o_sram_addr_128_tmp : sm_o_sram_addr_128_tmp;
            sw_dat <= (sm_o_sram_en_128) ? sram_dout_128 : sw_dat;
        end
    end 

    // assign sw_dat = (sm_o_sram_en_128) ? sram_dout_128 : sw_dat;
    assign sm_o_sram_addr_128 = sm_o_sram_addr_128_tmp * 4;
    assign sw_lst = (sm_o_sram_addr_128_tmp == 127);
//====================================== sram signal controller ======================================// 

// ============ sram 512 * 128 ============ //
    
    always @(posedge clk_2x or negedge rstn) begin
        if(!rstn) begin
            sram_dout_128_buf <= 0;
            sram_dout_512_buf <= 0;
        end else begin
            sram_dout_128_buf <= sram_dout_128;
            sram_dout_512_buf <= sram_dout_512;
        end
    end

    always @(*) begin
        case (stage)
            S1: begin
                // sram 128*128 (write)
                sram_en_128   = s1_o_sram_en_128;
                WE_128        = s1_o_WE_128;
                sram_addr_128 = s1_o_sram_addr_128;
                sram_din_128  = s1_o_sram_din_128;
                next_stage = (s1_o_cnt == 7'd64 && s1_o_sram_en_128) ? S2 : S1;
                // BPE1
                BPE1_ain   = s1_BPE1_ain;
                BPE1_bin   = s1_BPE1_bin;
                BPE1_coef  = s1_BPE1_coef;
                BPE1_i_vld = s1_BPE1_i_vld;
            end
            S2: begin
                // sram 128*128 (read)
                sram_en_128   = s2_i_sram_en_128;
                WE_128        = s2_i_WE_128;
                sram_addr_128 = s2_i_sram_addr_128;
                sram_din_128  = s2_i_sram_din_128;


                // sram 512*128 (write)
                sram_en_512   = s2_o_sram_en_512;
                WE_512        = s2_o_WE_512;
                sram_addr_512 = s2_o_sram_addr_512;
                sram_din_512  = s2_o_sram_din_512;
                next_stage = (s2_o_cnt == 7'd64 && s2_o_sram_en_512) ? S3 : S2;

                // BPE1
                BPE1_ain   = s2_BPE1_ain;
                BPE1_bin   = s2_BPE1_bin;
                BPE1_coef  = s2_BPE1_coef;
                BPE1_i_vld = s2_BPE1_i_vld;
            end
            S3: begin
                // sram 512*128 (read)
                sram_en_512   = s3_i_sram_en_512;
                WE_512        = s3_i_WE_512;
                sram_addr_512 = s3_i_sram_addr_512;
                sram_din_512  = s3_i_sram_din_512;
                // sram 128*128 (write)
                sram_en_128   = s3_o_sram_en_128;
                WE_128        = s3_o_WE_128;
                sram_addr_128 = s3_o_sram_addr_128;
                sram_din_128  = s3_o_sram_din_128;
                next_stage = (s3_o_cnt == 7'd64 && s3_o_sram_en_128) ? S4 : S3;

                // BPE1
                BPE1_ain   = s3_BPE1_ain;
                BPE1_bin   = s3_BPE1_bin;
                BPE1_coef  = s3_BPE1_coef;
                BPE1_i_vld = s3_BPE1_i_vld;
            end
            S4: begin
                // sram 128*128 (read)
                sram_en_128   = s4_i_sram_en_128;
                WE_128        = s4_i_WE_128;
                sram_addr_128 = s4_i_sram_addr_128;
                sram_din_128  = s4_i_sram_din_128;
                // sram 512*128 (write)
                sram_en_512   = s4_o_sram_en_512;
                WE_512        = s4_o_WE_512;
                sram_addr_512 = s4_o_sram_addr_512;
                sram_din_512  = s4_o_sram_din_512;
                next_stage = (s4_o_cnt == 7'd64 && s4_o_sram_en_512) ? S5 : S4;
                // BPE1
                BPE1_ain   = s4_BPE1_ain;
                BPE1_bin   = s4_BPE1_bin;
                BPE1_coef  = s4_BPE1_coef;
                BPE1_i_vld = s4_BPE1_i_vld;
            end
            S5: begin
                // sram 512*128 (read)
                sram_en_512   = s5_i_sram_en_512;
                WE_512        = s5_i_WE_512;
                sram_addr_512 = s5_i_sram_addr_512;
                sram_din_512  = s5_i_sram_din_512;
                // sram 128*128 (write)
                sram_en_128   = s5_o_sram_en_128;
                WE_128        = s5_o_WE_128;
                sram_addr_128 = s5_o_sram_addr_128;
                sram_din_128  = s5_o_sram_din_128;
                next_stage = (s5_o_cnt == 7'd64 && s5_o_sram_en_128) ? S6 : S5;
                // BPE1
                BPE1_ain   = s5_BPE1_ain;
                BPE1_bin   = s5_BPE1_bin;
                BPE1_coef  = s5_BPE1_coef;
                BPE1_i_vld = s5_BPE1_i_vld;
            end
            S6: begin
                // sram 128*128 (read)
                sram_en_128   = s6_i_sram_en_128;
                WE_128        = s6_i_WE_128;
                sram_addr_128 = s6_i_sram_addr_128;
                sram_din_128  = s6_i_sram_din_128;
                // sram 512*128 (write)
                sram_en_512   = s6_o_sram_en_512;
                WE_512        = s6_o_WE_512;
                sram_addr_512 = s6_o_sram_addr_512;
                sram_din_512  = s6_o_sram_din_512;
                next_stage = (s6_o_cnt == 7'd64  && s6_o_sram_en_512) ? S7_to_10 : S6;
                // BPE1
                BPE1_ain   = s6_BPE1_ain;
                BPE1_bin   = s6_BPE1_bin;
                BPE1_coef  = s6_BPE1_coef;
                BPE1_i_vld = s6_BPE1_i_vld;
            end
            S7_to_10: begin
                // sram 512*128 (read)
                sram_en_512   = s7_i_sram_en_512;
                WE_512        = s7_i_WE_512;
                sram_addr_512 = s7_i_sram_addr_512;
                sram_din_512  = s7_i_sram_din_512;
                // sram 128*128 (write)
                sram_en_128   = s10_o_sram_en_128;
                WE_128        = s10_o_WE_128;
                sram_addr_128 = s10_o_sram_addr_128;
                sram_din_128  = s10_o_sram_din_128;
                
                // BPE1
                BPE1_ain   = s7_BPE1_ain;
                BPE1_bin   = s7_BPE1_bin;
                BPE1_coef  = s7_BPE1_coef;
                BPE1_i_vld = s7_BPE1_i_vld;
                // BPE2
                BPE2_ain   = s8_BPE2_ain;
                BPE2_bin   = s8_BPE2_bin;
                BPE2_coef  = s8_BPE2_coef;
                BPE2_i_vld = s8_BPE2_i_vld;
                // BPE3
                BPE3_ain   = s9_BPE3_ain;
                BPE3_bin   = s9_BPE3_bin;
                BPE3_coef  = s9_BPE3_coef;
                BPE3_i_vld = s9_BPE3_i_vld;

                // BPE4
                BPE4_ain   = s10_BPE4_ain;
                BPE4_bin   = s10_BPE4_bin;
                BPE4_coef  = s10_BPE4_coef;
                BPE4_i_vld = s10_BPE4_i_vld;

                next_stage = (mode_state[1:0] == NTT && s10_o_sram_en_128 && s10_o_cnt == 7'd64 || 
                              mode_state[1:0] == iNTT && s10_div_o_cnt == 7'd64) ? OUT : S7_to_10;
            end
            OUT: begin
                // sram 128*128 (read)
                sram_en_128   = sm_o_sram_en_128;
                WE_128        = sm_o_WE_128;
                sram_addr_128 = sm_o_sram_addr_128;
                sram_din_128  = sm_o_sram_din_128;
                next_stage = (sw_lst) ? IDLE : OUT;
            end
            IDLE:
                next_stage = IDLE;

            default: begin
                // sram 512*128 
                sram_en_512   = 0;
                WE_512        = 4'b0000;
                sram_addr_512 = 0;
                sram_din_512  = 0;
                // sram 128*128
                sram_en_128   = 0;
                WE_128        = 4'b0000;
                sram_addr_128 = 0;
                sram_din_128  = 0;
                next_stage = S1;
                // BPE1
                BPE1_ain   = 0; 
                BPE1_bin   = 0; 
                BPE1_coef  = 0; 
                BPE1_i_vld = 0; 
                // BPE2 
                BPE2_ain   = 0;
                BPE2_bin   = 0;
                BPE2_coef  = 0;
                BPE2_i_vld = 0;
                 // BPE3
                BPE3_ain   = 0;
                BPE3_bin   = 0;
                BPE3_coef  = 0;
                BPE3_i_vld = 0;

                // BPE4
                BPE4_ain   = 0;
                BPE4_bin   = 0;
                BPE4_coef  = 0;
                BPE4_i_vld = 0;
            end 
        endcase
    end

    always @ (posedge clk or negedge rstn) begin
        if(!rstn) begin
            stage <= S1;
        end else begin
            stage <= next_stage;
        end
    end

endmodule

