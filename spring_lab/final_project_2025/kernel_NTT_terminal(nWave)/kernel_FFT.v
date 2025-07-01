module kernel_FFT 
#(  
    parameter pDATA_WIDTH = 128 
)
(
    input  wire                     clk,
    input  wire                     clk_2x,     // for dataRAM (double-speed)
    input  wire                     rstn,

    input  wire                     ld_vld,
    output wire                     ld_rdy,
    input  wire [(pDATA_WIDTH-1):0] ld_dat,

    output wire                     sw_vld,
    input  wire                     sw_rdy,
    output wire [(pDATA_WIDTH-1):0] sw_dat,

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
    output reg  BPE1_i_vld,
    input  wire BPE1_i_rdy,
    input  wire BPE1_o_vld,
    output reg  BPE1_o_rdy,

    //============BPE2============//
    output reg  [(pDATA_WIDTH-1):0] BPE2_ain,
    output reg  [(pDATA_WIDTH-1):0] BPE2_bin,
    output reg  [(pDATA_WIDTH-1):0] BPE2_coef,
    input  wire [(pDATA_WIDTH-1):0] BPE2_aout,
    input  wire [(pDATA_WIDTH-1):0] BPE2_bout,
    output reg  BPE2_i_vld,
    input  wire BPE2_i_rdy,
    input  wire BPE2_o_vld,
    output reg  BPE2_o_rdy,

    //============BPE3============//
    output reg  [(pDATA_WIDTH-1):0] BPE3_ain,
    output reg  [(pDATA_WIDTH-1):0] BPE3_bin,
    output reg  [(pDATA_WIDTH-1):0] BPE3_coef,
    input  wire [(pDATA_WIDTH-1):0] BPE3_aout,
    input  wire [(pDATA_WIDTH-1):0] BPE3_bout,
    output reg  BPE3_i_vld,
    input  wire BPE3_i_rdy,
    input  wire BPE3_o_vld,
    output reg  BPE3_o_rdy,

    //============BPE4============//
    output reg  [(pDATA_WIDTH-1):0] BPE4_ain,
    output reg  [(pDATA_WIDTH-1):0] BPE4_bin,
    output reg  [(pDATA_WIDTH-1):0] BPE4_coef,
    input  wire [(pDATA_WIDTH-1):0] BPE4_aout,
    input  wire [(pDATA_WIDTH-1):0] BPE4_bout,
    output reg  BPE4_i_vld,
    input  wire BPE4_i_rdy,
    input  wire BPE4_o_vld,
    output reg  BPE4_o_rdy,

    //============BPE5============//
    output reg  [(pDATA_WIDTH-1):0] BPE5_ain,
    output reg  [(pDATA_WIDTH-1):0] BPE5_bin,
    output reg  [(pDATA_WIDTH-1):0] BPE5_coef,
    input  wire [(pDATA_WIDTH-1):0] BPE5_aout,
    input  wire [(pDATA_WIDTH-1):0] BPE5_bout,
    output reg  BPE5_i_vld,
    input  wire BPE5_i_rdy,
    input  wire BPE5_o_vld,
    output reg  BPE5_o_rdy,


    //============SRAM1 512x128============//
    output [3:0]   WE_512,
    output         sram_en_512,
    output [(pDATA_WIDTH-1):0] sram_din_512,
    input [(pDATA_WIDTH-1):0] sram_dout_512,
    input [8:0]   sram_addr_512,


    //============SRAM2 128x128============//
    output [3:0]   WE_128,
    output         sram_en_128,
    output [(pDATA_WIDTH-1):0] sram_din_128,
    input [(pDATA_WIDTH-1):0] sram_dout_128,
    input [6:0]   sram_addr_128,

    //============SRAM3 32x128============//
    output [3:0]   WE_32,
    output         sram_en_32,
    output [(pDATA_WIDTH-1):0] sram_din_32,
    input [(pDATA_WIDTH-1):0] sram_dout_32,
    input  [4:0]   sram_addr_32

);

endmodule