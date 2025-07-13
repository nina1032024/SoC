

module kernel_top
#(  
    parameter pDATA_WIDTH = 128 
)
(
    input  wire                     clk,
    input  wire                     clk_2x,     // for dataRAM (double-speed)
    input  wire                     rstn,

    input  wire                     ld_vld,
    output                      ld_rdy,
    input  wire [(pDATA_WIDTH-1):0] ld_dat,

    output                      sw_vld,
    input  wire                     sw_rdy,
    output  [(pDATA_WIDTH-1):0] sw_dat,

    input  wire                     coef_vld,
    output                      coef_rdy,
    input  wire [(pDATA_WIDTH-1):0] coef_dat, 

    output                [4:0] bpe_act,     // for bpe1 to bpe5 activate

    input  wire               [7:0] mode,        // iNTT(11)/NTT(10)/iFFT(01)/FFT(00)
    input  wire                     decode,
    output                      sw_lst       // set when handshake
);


// =============== mode constants =============== //
    localparam MODE_FFT  = 2'b00;
    localparam MODE_IFFT = 2'b01;
    localparam MODE_NTT  = 2'b10;
    localparam MODE_INTT = 2'b11;

// =============== mode selection =============== //
    reg [7:0] mode_state;
    wire use_ntt, use_fft;

// ================= BPE Wires ================= //   
    // BPE1
    wire [127:0] BPE1_ain, BPE1_bin, BPE1_coef;
    wire [127:0] BPE1_ain_ntt, BPE1_bin_ntt, BPE1_coef_ntt;
    wire [127:0] BPE1_ain_fft, BPE1_bin_fft, BPE1_coef_fft;
    wire [127:0] BPE1_aout, BPE1_bout;
    wire [127:0] BPE1_aout_ntt, BPE1_bout_ntt;
    wire [127:0] BPE1_aout_fft, BPE1_bout_fft;
    wire BPE1_i_vld, BPE1_i_rdy, BPE1_o_vld, BPE1_o_rdy;
    wire BPE1_i_vld_ntt, BPE1_i_rdy_ntt, BPE1_o_vld_ntt, BPE1_o_rdy_ntt;
    wire BPE1_i_vld_fft, BPE1_i_rdy_fft, BPE1_o_vld_fft, BPE1_o_rdy_fft;
    

    // BPE2
    wire [127:0] BPE2_ain, BPE2_bin, BPE2_coef;
    wire [127:0] BPE2_ain_ntt, BPE2_bin_ntt, BPE2_coef_ntt;
    wire [127:0] BPE2_ain_fft, BPE2_bin_fft, BPE2_coef_fft;
    wire [127:0] BPE2_aout, BPE2_bout;
    wire [127:0] BPE2_aout_ntt, BPE2_bout_ntt;
    wire [127:0] BPE2_aout_fft, BPE2_bout_fft;
    wire BPE2_i_vld, BPE2_i_rdy, BPE2_o_vld, BPE2_o_rdy;
    wire BPE2_i_vld_ntt, BPE2_i_rdy_ntt, BPE2_o_vld_ntt, BPE2_o_rdy_ntt;
    wire BPE2_i_vld_fft, BPE2_i_rdy_fft, BPE2_o_vld_fft, BPE2_o_rdy_fft;


    // BPE3
    wire [127:0] BPE3_ain, BPE3_bin, BPE3_coef;
    wire [127:0] BPE3_ain_ntt, BPE3_bin_ntt, BPE3_coef_ntt;
    wire [127:0] BPE3_ain_fft, BPE3_bin_fft, BPE3_coef_fft;
    wire [127:0] BPE3_aout, BPE3_bout;
    wire [127:0] BPE3_aout_ntt, BPE3_bout_ntt;
    wire [127:0] BPE3_aout_fft, BPE3_bout_fft;
    wire BPE3_i_vld, BPE3_i_rdy, BPE3_o_vld, BPE3_o_rdy;
    wire BPE3_i_vld_ntt, BPE3_i_rdy_ntt, BPE3_o_vld_ntt, BPE3_o_rdy_ntt;
    wire BPE3_i_vld_fft, BPE3_i_rdy_fft, BPE3_o_vld_fft, BPE3_o_rdy_fft;

    // BPE4
    wire [127:0] BPE4_ain, BPE4_bin, BPE4_coef;
    wire [127:0] BPE4_ain_ntt, BPE4_bin_ntt, BPE4_coef_ntt;
    wire [127:0] BPE4_ain_fft, BPE4_bin_fft, BPE4_coef_fft;
    wire [127:0] BPE4_aout, BPE4_bout;
    wire [127:0] BPE4_aout_ntt, BPE4_bout_ntt;
    wire [127:0] BPE4_aout_fft, BPE4_bout_fft;
    wire BPE4_i_vld, BPE4_i_rdy, BPE4_o_vld, BPE4_o_rdy;
    wire BPE4_i_vld_ntt, BPE4_i_rdy_ntt, BPE4_o_vld_ntt, BPE4_o_rdy_ntt;
    wire BPE4_i_vld_fft, BPE4_i_rdy_fft, BPE4_o_vld_fft, BPE4_o_rdy_fft;

    // BPE5
    wire [127:0] BPE5_ain, BPE5_bin, BPE5_coef;
    wire [127:0] BPE5_ain_ntt, BPE5_bin_ntt, BPE5_coef_ntt;
    wire [127:0] BPE5_ain_fft, BPE5_bin_fft, BPE5_coef_fft;
    wire [127:0] BPE5_aout, BPE5_bout;
    wire [127:0] BPE5_aout_ntt, BPE5_bout_ntt;
    wire [127:0] BPE5_aout_fft, BPE5_bout_fft;
    wire BPE5_i_vld, BPE5_i_rdy, BPE5_o_vld, BPE5_o_rdy;
    wire BPE5_i_vld_ntt, BPE5_i_rdy_ntt, BPE5_o_vld_ntt, BPE5_o_rdy_ntt;
    wire BPE5_i_vld_fft, BPE5_i_rdy_fft, BPE5_o_vld_fft, BPE5_o_rdy_fft;

// ================= SRAM Wires ================= //
    wire [127:0] sram_dout_512, sram_dout_512_fft, sram_dout_512_ntt;
    wire [127:0] sram_dout_128, sram_dout_128_fft, sram_dout_128_ntt;
    wire [127:0] sram_dout_32, sram_dout_32_fft, sram_dout_32_ntt;
    // SRAM1 512x128
    wire [3:0] WE_512, WE_512_ntt, WE_512_fft;
    wire sram_en_512, sram_en_512_ntt, sram_en_512_fft;
    wire [127:0] sram_din_512, sram_din_512_ntt, sram_din_512_fft;
    wire [12:0] sram_addr_512, sram_addr_512_ntt, sram_addr_512_fft;
    // SRAM2 128x128
    wire [3:0] WE_128, WE_128_ntt, WE_128_fft;
    wire sram_en_128, sram_en_128_ntt, sram_en_128_fft;
    wire [127:0] sram_din_128, sram_din_128_ntt, sram_din_128_fft;
    wire [12:0] sram_addr_128, sram_addr_128_ntt, sram_addr_128_fft;

    // SRAM3 32x128
    wire [3:0] WE_32, WE_32_ntt, WE_32_fft;
    wire sram_en_32, sram_en_32_ntt, sram_en_32_fft;
    wire [127:0] sram_din_32, sram_din_32_ntt, sram_din_32_fft;
    wire [12:0] sram_addr_32, sram_addr_32_ntt, sram_addr_32_fft;

// =============== I/O Between FFT / NTT =============== //
    wire ld_rdy_ntt, coef_rdy_ntt, sw_vld_ntt, sw_lst_ntt;
    wire ld_rdy_fft, coef_rdy_fft, sw_vld_fft, sw_lst_fft;
    wire [(pDATA_WIDTH-1):0] sw_dat_ntt, sw_dat_fft;
    wire [4:0] bpe_act_ntt, bpe_act_fft;

// =============== kernel mode control=============== //
    
    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            mode_state <= 0;
        end else begin
            mode_state <= (decode) ? mode : mode_state;
        end
    end

    assign use_ntt = (mode_state[1:0] == MODE_NTT) || (mode_state[1:0] == MODE_INTT);
    assign use_fft = (mode_state[1:0] == MODE_FFT) || (mode_state[1:0]== MODE_IFFT);


// =============== Module Instantiation =============== //
    kernel_NTT NTT (
        .clk      (clk),
        .clk_2x   (clk_2x),
        .rstn     (rstn),
        .ld_vld   (ld_vld & use_ntt),
        .ld_rdy   (ld_rdy_ntt),
        .ld_dat   (ld_dat),
        .sw_vld   (sw_vld_ntt),
        .sw_rdy   (sw_rdy),
        .sw_dat   (sw_dat_ntt),
        .coef_vld (coef_vld & use_ntt),
        .coef_rdy (coef_rdy_ntt),
        .coef_dat (coef_dat),
        .bpe_act  (bpe_act_ntt),
        .mode     (mode),
        .decode   (decode),
        .sw_lst   (sw_lst_ntt),
        .BPE1_ain  (BPE1_ain_ntt),
        .BPE1_bin  (BPE1_bin_ntt),
        .BPE1_coef (BPE1_coef_ntt),
        .BPE1_aout (BPE1_aout_ntt),
        .BPE1_bout (BPE1_bout_ntt),
        .BPE1_i_vld(BPE1_i_vld_ntt),
        .BPE1_i_rdy(BPE1_i_rdy_ntt),
        .BPE1_o_vld(BPE1_o_vld_ntt),
        .BPE1_o_rdy(BPE1_o_rdy_ntt),
        .BPE2_ain  (BPE2_ain_ntt),
        .BPE2_bin  (BPE2_bin_ntt),
        .BPE2_coef (BPE2_coef_ntt),
        .BPE2_aout (BPE2_aout_ntt),
        .BPE2_bout (BPE2_bout_ntt),
        .BPE2_i_vld(BPE2_i_vld_ntt),
        .BPE2_i_rdy(BPE2_i_rdy_ntt),
        .BPE2_o_vld(BPE2_o_vld_ntt),
        .BPE2_o_rdy(BPE2_o_rdy_ntt),
        .BPE3_ain  (BPE3_ain_ntt),
        .BPE3_bin  (BPE3_bin_ntt),
        .BPE3_coef (BPE3_coef_ntt),
        .BPE3_aout (BPE3_aout_ntt),
        .BPE3_bout (BPE3_bout_ntt),
        .BPE3_i_vld(BPE3_i_vld_ntt),
        .BPE3_i_rdy(BPE3_i_rdy_ntt),
        .BPE3_o_vld(BPE3_o_vld_ntt),
        .BPE3_o_rdy(BPE3_o_rdy_ntt),
        .BPE4_ain  (BPE4_ain_ntt),
        .BPE4_bin  (BPE4_bin_ntt),
        .BPE4_coef (BPE4_coef_ntt),
        .BPE4_aout (BPE4_aout_ntt),
        .BPE4_bout (BPE4_bout_ntt),
        .BPE4_i_vld(BPE4_i_vld_ntt),
        .BPE4_i_rdy(BPE4_i_rdy_ntt),
        .BPE4_o_vld(BPE4_o_vld_ntt),
        .BPE4_o_rdy(BPE4_o_rdy_ntt),
        .BPE5_ain  (BPE5_ain_ntt),
        .BPE5_bin  (BPE5_bin_ntt),
        .BPE5_coef (BPE5_coef_ntt),
        .BPE5_aout (BPE5_aout_ntt),
        .BPE5_bout (BPE5_bout_ntt),
        .BPE5_i_vld(BPE5_i_vld_ntt),
        .BPE5_i_rdy(BPE5_i_rdy_ntt),
        .BPE5_o_vld(BPE5_o_vld_ntt),
        .BPE5_o_rdy(BPE5_o_rdy_ntt),
        .WE_512(WE_512_ntt),
        .sram_en_512(sram_en_512_ntt),
        .sram_din_512(sram_din_512_ntt),
        .sram_dout_512(sram_dout_512_ntt),
        .sram_addr_512(sram_addr_512_ntt),
        .WE_128(WE_128_ntt),
        .sram_en_128(sram_en_128_ntt),
        .sram_din_128(sram_din_128_ntt),
        .sram_dout_128(sram_dout_128_ntt),
        .sram_addr_128(sram_addr_128_ntt),
        .WE_32(WE_32_ntt),
        .sram_en_32(sram_en_32_ntt),
        .sram_din_32(sram_din_32_ntt),
        .sram_dout_32(sram_dout_32_ntt),
        .sram_addr_32(sram_addr_32_ntt)
        
    );

    kernel_FFT FFT (
        .clk      (clk),
        .clk_2x   (clk_2x),
        .rstn     (rstn),
        .ld_vld   (ld_vld & use_fft),
        .ld_rdy   (ld_rdy_fft),
        .ld_dat   (ld_dat),
        .sw_vld   (sw_vld_fft),
        .sw_rdy   (sw_rdy),
        .sw_dat   (sw_dat_fft),
        .coef_vld (coef_vld & use_fft),
        .coef_rdy (coef_rdy_fft),
        .coef_dat (coef_dat),
        .bpe_act  (bpe_act_fft),
        .mode     (mode),
        .decode   (decode),
        .sw_lst   (sw_lst_fft),
        .BPE1_ain  (BPE1_ain_fft),
        .BPE1_bin  (BPE1_bin_fft),
        .BPE1_coef (BPE1_coef_fft),
        .BPE1_aout (BPE1_aout_fft),
        .BPE1_bout (BPE1_bout_fft),
        .BPE1_i_vld(BPE1_i_vld_fft),
        .BPE1_i_rdy(BPE1_i_rdy_fft),
        .BPE1_o_vld(BPE1_o_vld_fft),
        .BPE1_o_rdy(BPE1_o_rdy_fft),
        .BPE2_ain  (BPE2_ain_fft),
        .BPE2_bin  (BPE2_bin_fft),
        .BPE2_coef (BPE2_coef_fft),
        .BPE2_aout (BPE2_aout_fft),
        .BPE2_bout (BPE2_bout_fft),
        .BPE2_i_vld(BPE2_i_vld_fft),
        .BPE2_i_rdy(BPE2_i_rdy_fft),
        .BPE2_o_vld(BPE2_o_vld_fft),
        .BPE2_o_rdy(BPE2_o_rdy_fft),
        .BPE3_ain  (BPE3_ain_fft),
        .BPE3_bin  (BPE3_bin_fft),
        .BPE3_coef (BPE3_coef_fft),
        .BPE3_aout (BPE3_aout_fft),
        .BPE3_bout (BPE3_bout_fft),
        .BPE3_i_vld(BPE3_i_vld_fft),
        .BPE3_i_rdy(BPE3_i_rdy_fft),
        .BPE3_o_vld(BPE3_o_vld_fft),
        .BPE3_o_rdy(BPE3_o_rdy_fft),
        .BPE4_ain  (BPE4_ain_fft),
        .BPE4_bin  (BPE4_bin_fft),
        .BPE4_coef (BPE4_coef_fft),
        .BPE4_aout (BPE4_aout_fft),
        .BPE4_bout (BPE4_bout_fft),
        .BPE4_i_vld(BPE4_i_vld_fft),
        .BPE4_i_rdy(BPE4_i_rdy_fft),
        .BPE4_o_vld(BPE4_o_vld_fft),
        .BPE4_o_rdy(BPE4_o_rdy_fft),
        .BPE5_ain  (BPE5_ain_fft),
        .BPE5_bin  (BPE5_bin_fft),
        .BPE5_coef (BPE5_coef_fft),
        .BPE5_aout (BPE5_aout_fft),
        .BPE5_bout (BPE5_bout_fft),
        .BPE5_i_vld(BPE5_i_vld_fft),
        .BPE5_i_rdy(BPE5_i_rdy_fft),
        .BPE5_o_vld(BPE5_o_vld_fft),
        .BPE5_o_rdy(BPE5_o_rdy_fft),
        .WE_512(WE_512_fft),
        .sram_en_512(sram_en_512_fft),
        .sram_din_512(sram_din_512_fft),
        .sram_dout_512(sram_dout_512_fft),
        .sram_addr_512(sram_addr_512_fft),
        .WE_128(WE_128_fft),
        .sram_en_128(sram_en_128_fft),
        .sram_din_128(sram_din_128_fft),
        .sram_dout_128(sram_dout_128_fft),
        .sram_addr_128(sram_addr_128_fft),
        .WE_32(WE_32_fft),
        .sram_en_32(sram_en_32_fft),
        .sram_din_32(sram_din_32_fft),
        .sram_dout_32(sram_dout_32_fft),
        .sram_addr_32(sram_addr_32_fft)
    );

// =============== BPE Instance =============== //
    butterfly BPE1 (
        .clk   (clk),
        .rstn  (rstn),
        .mode  (mode_state),
        .i_vld (BPE1_i_vld),
        .i_rdy (BPE1_i_rdy),
        .o_vld (BPE1_o_vld),
        .o_rdy (BPE1_o_rdy),
        .ai    (BPE1_ain),
        .bi    (BPE1_bin),
        .gm    (BPE1_coef),
        .ao    (BPE1_aout),
        .bo    (BPE1_bout)
    );

    butterfly BPE2 (
        .clk   (clk),
        .rstn  (rstn),
        .mode  (mode_state),
        .i_vld (BPE2_i_vld),
        .i_rdy (BPE2_i_rdy),
        .o_vld (BPE2_o_vld),
        .o_rdy (BPE2_o_rdy),
        .ai    (BPE2_ain),
        .bi    (BPE2_bin),
        .gm    (BPE2_coef),
        .ao    (BPE2_aout),
        .bo    (BPE2_bout)
    );

    butterfly BPE3 (
        .clk   (clk),
        .rstn  (rstn),
        .mode  (mode_state),
        .i_vld (BPE3_i_vld),
        .i_rdy (BPE3_i_rdy),
        .o_vld (BPE3_o_vld),
        .o_rdy (BPE3_o_rdy),
        .ai    (BPE3_ain),
        .bi    (BPE3_bin),
        .gm    (BPE3_coef),
        .ao    (BPE3_aout),
        .bo    (BPE3_bout)
    );

    butterfly BPE4 (
        .clk   (clk),
        .rstn  (rstn),
        .mode  (mode_state),
        .i_vld (BPE4_i_vld),
        .i_rdy (BPE4_i_rdy),
        .o_vld (BPE4_o_vld),
        .o_rdy (BPE4_o_rdy),
        .ai    (BPE4_ain),
        .bi    (BPE4_bin),
        .gm    (BPE4_coef),
        .ao    (BPE4_aout),
        .bo    (BPE4_bout)
    );

    butterfly BPE5 (
        .clk   (clk),
        .rstn  (rstn),
        .mode  (mode_state),
        .i_vld (BPE5_i_vld),
        .i_rdy (BPE5_i_rdy),
        .o_vld (BPE5_o_vld),
        .o_rdy (BPE5_o_rdy),
        .ai    (BPE5_ain),
        .bi    (BPE5_bin),
        .gm    (BPE5_coef),
        .ao    (BPE5_aout),
        .bo    (BPE5_bout)
    );



// =============== SRAM Instance =============== //
    bram512x128 SRAM1 (
        .CLK(clk_2x),
        .WE(WE_512),
        .EN(sram_en_512),
        .Di(sram_din_512),
        .Do(sram_dout_512),
        .A(sram_addr_512)
    );

    bram128x128 SRAM2 (
        .CLK(clk_2x),
        .WE(WE_128),
        .EN(sram_en_128),
        .Di(sram_din_128),
        .Do(sram_dout_128),
        .A(sram_addr_128)
    );

    bram32x128 SRAM3 (
        .CLK(clk_2x),
        .WE(WE_32),
        .EN(sram_en_32),
        .Di(sram_din_32),
        .Do(sram_dout_32),
        .A(sram_addr_32)
    );


// =============== mux =============== //
    assign ld_rdy   = use_ntt ? ld_rdy_ntt   : use_fft ? ld_rdy_fft   : 1'b0;
    assign coef_rdy = use_ntt ? coef_rdy_ntt : use_fft ? coef_rdy_fft : 1'b0;
    assign sw_vld   = use_ntt ? sw_vld_ntt   : use_fft ? sw_vld_fft   : 1'b0;
    assign sw_dat   = use_ntt ? sw_dat_ntt   : use_fft ? sw_dat_fft   : {pDATA_WIDTH{1'b0}};
    assign sw_lst   = use_ntt ? sw_lst_ntt   : use_fft ? sw_lst_fft   : 1'b0;
    assign bpe_act  = use_ntt ? bpe_act_ntt  : use_fft ? bpe_act_fft  : 5'd0;

    assign sram_en_512   = use_ntt ? sram_en_512_ntt : sram_en_512_fft;
    assign WE_512        = use_ntt ? WE_512_ntt      : WE_512_fft;
    assign sram_addr_512 = use_ntt ? sram_addr_512_ntt    : sram_addr_512_fft;
    assign sram_din_512  = use_ntt ? sram_din_512_ntt     : sram_din_512_fft;

    assign sram_en_128   = use_ntt ? sram_en_128_ntt : sram_en_128_fft;
    assign WE_128        = use_ntt ? WE_128_ntt      : WE_128_fft;
    assign sram_addr_128 = use_ntt ? sram_addr_128_ntt    : sram_addr_128_fft;
    assign sram_din_128  = use_ntt ? sram_din_128_ntt     : sram_din_128_fft;

    assign sram_en_32   = use_ntt ? sram_en_32_ntt : sram_en_32_fft;
    assign WE_32        = use_ntt ? WE_32_ntt      : WE_32_fft;
    assign sram_addr_32 = use_ntt ? sram_addr_32_ntt    : sram_addr_32_fft;
    assign sram_din_32  = use_ntt ? sram_din_32_ntt     : sram_din_32_fft;

    assign sram_dout_512_ntt = sram_dout_512;
    assign sram_dout_512_fft = sram_dout_512;
    assign sram_dout_128_ntt = sram_dout_128;
    assign sram_dout_128_fft = sram_dout_128;
    assign sram_dout_32_ntt  = sram_dout_32;
    assign sram_dout_32_fft  = sram_dout_32;

    // BPE1
    assign BPE1_aout_ntt = BPE1_aout;
    assign BPE1_aout_fft = BPE1_aout;
    assign BPE1_bout_ntt = BPE1_bout;
    assign BPE1_bout_fft = BPE1_bout;
    assign BPE1_i_rdy_ntt  = BPE1_i_rdy;
    assign BPE1_i_rdy_fft  = BPE1_i_rdy;
    assign BPE1_o_vld_ntt  = BPE1_o_vld;
    assign BPE1_o_vld_fft  = BPE1_o_vld;
    assign BPE1_ain   = use_ntt ?  BPE1_ain_ntt  : BPE1_ain_fft;
    assign BPE1_bin   = use_ntt ?  BPE1_bin_ntt  : BPE1_bin_fft;
    assign BPE1_coef  = use_ntt ?  BPE1_coef_ntt : BPE1_coef_fft;
    assign BPE1_i_vld = use_ntt ?  BPE1_i_vld_ntt : BPE1_i_vld_fft;
    assign BPE1_o_rdy = use_ntt ?  BPE1_o_rdy_ntt : BPE1_o_rdy_fft;

    // BPE2
    assign BPE2_aout_ntt = BPE2_aout;
    assign BPE2_aout_fft = BPE2_aout;
    assign BPE2_bout_ntt = BPE2_bout;
    assign BPE2_bout_fft = BPE2_bout;
    assign BPE2_i_rdy_ntt  = BPE2_i_rdy;
    assign BPE2_i_rdy_fft  = BPE2_i_rdy;
    assign BPE2_o_vld_ntt  = BPE2_o_vld;
    assign BPE2_o_vld_fft  = BPE2_o_vld;
    assign BPE2_ain   = use_ntt ?  BPE2_ain_ntt  : BPE2_ain_fft;
    assign BPE2_bin   = use_ntt ?  BPE2_bin_ntt  : BPE2_bin_fft;
    assign BPE2_coef  = use_ntt ?  BPE2_coef_ntt : BPE2_coef_fft;
    assign BPE2_i_vld = use_ntt ?  BPE2_i_vld_ntt : BPE2_i_vld_fft;
    assign BPE2_o_rdy = use_ntt ?  BPE2_o_rdy_ntt : BPE2_o_rdy_fft;


    // BPE3
    assign BPE3_aout_ntt = BPE3_aout;
    assign BPE3_aout_fft = BPE3_aout;
    assign BPE3_bout_ntt = BPE3_bout;
    assign BPE3_bout_fft = BPE3_bout;
    assign BPE3_i_rdy_ntt  = BPE3_i_rdy;
    assign BPE3_i_rdy_fft  = BPE3_i_rdy;
    assign BPE3_o_vld_ntt  = BPE3_o_vld;
    assign BPE3_o_vld_fft  = BPE3_o_vld;
    assign BPE3_ain   = use_ntt ?  BPE3_ain_ntt  : BPE3_ain_fft;
    assign BPE3_bin   = use_ntt ?  BPE3_bin_ntt  : BPE3_bin_fft;
    assign BPE3_coef  = use_ntt ?  BPE3_coef_ntt : BPE3_coef_fft;
    assign BPE3_i_vld = use_ntt ?  BPE3_i_vld_ntt : BPE3_i_vld_fft;
    assign BPE3_o_rdy = use_ntt ?  BPE3_o_rdy_ntt : BPE3_o_rdy_fft;

    // BPE4
    assign BPE4_aout_ntt = BPE4_aout;
    assign BPE4_aout_fft = BPE4_aout;
    assign BPE4_bout_ntt = BPE4_bout;
    assign BPE4_bout_fft = BPE4_bout;
    assign BPE4_i_rdy_ntt  = BPE4_i_rdy;
    assign BPE4_i_rdy_fft  = BPE4_i_rdy;
    assign BPE4_o_vld_ntt  = BPE4_o_vld;
    assign BPE4_o_vld_fft  = BPE4_o_vld;
    assign BPE4_ain   = use_ntt ?  BPE4_ain_ntt  : BPE4_ain_fft;
    assign BPE4_bin   = use_ntt ?  BPE4_bin_ntt  : BPE4_bin_fft;
    assign BPE4_coef  = use_ntt ?  BPE4_coef_ntt : BPE4_coef_fft;
    assign BPE4_i_vld = use_ntt ?  BPE4_i_vld_ntt : BPE4_i_vld_fft;
    assign BPE4_o_rdy = use_ntt ?  BPE4_o_rdy_ntt : BPE4_o_rdy_fft;

    // BPE5
    assign BPE5_aout_ntt = BPE5_aout;
    assign BPE5_aout_fft = BPE5_aout;
    assign BPE5_bout_ntt = BPE5_bout;
    assign BPE5_bout_fft = BPE5_bout;
    assign BPE5_i_rdy_ntt  = BPE5_i_rdy;
    assign BPE5_i_rdy_fft  = BPE5_i_rdy;
    assign BPE5_o_vld_ntt  = BPE5_o_vld;
    assign BPE5_o_vld_fft  = BPE5_o_vld;
    assign BPE5_ain   = use_ntt ?  BPE5_ain_ntt  : BPE5_ain_fft;
    assign BPE5_bin   = use_ntt ?  BPE5_bin_ntt  : BPE5_bin_fft;
    assign BPE5_coef  = use_ntt ?  BPE5_coef_ntt : BPE5_coef_fft;
    assign BPE5_i_vld = use_ntt ?  BPE5_i_vld_ntt : BPE5_i_vld_fft;
    assign BPE5_o_rdy = use_ntt ?  BPE5_o_rdy_ntt : BPE5_o_rdy_fft;


endmodule