`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/02/17 11:10:34
// Design Name: 
// Module Name: fir
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

只能用32bit 的加法器

module fir 
#(  parameter pADDR_WIDTH = 12,
    parameter pDATA_WIDTH = 32,
    parameter Tape_Num    = 11
)
(
    // AXI4-Lite interface
    output  wire                     awready,  
    output  wire                     wready,   
    input   wire                     awvalid,  // write address valid (M->S)
    input   wire [(pADDR_WIDTH-1):0] awaddr,   // write address (M->S)
    input   wire                     wvalid,   
    input   wire [(pDATA_WIDTH-1):0] wdata,    // write data (M->S)
    output  wire                     arready,  // read  address ready (S->M)
    input   wire                     rready,   // read  data ready (M->S)
    input   wire                     arvalid,  // read  address valid (M->S)
    input   wire [(pADDR_WIDTH-1):0] araddr,   // read  address (M->S)
    output  wire                     rvalid,   // read  data valid (S->M)
    output  wire [(pDATA_WIDTH-1):0] rdata,    // read  data (S->M)
    
    // AXI4-Stream X[n] input -- SS bus
    input   wire                     ss_tvalid, 
    input   wire [(pDATA_WIDTH-1):0] ss_tdata, 
    input   wire                     ss_tlast, 
    output  wire                     ss_tready, 

    // AXI4-Stream Y[n] output -- SM bus
    input   wire                     sm_tready, 
    output  wire                     sm_tvalid, 
    output  wire [(pDATA_WIDTH-1):0] sm_tdata, 
    output  wire                     sm_tlast, 
    
    // bram for tap RAM 
    output  wire [3:0]               tap_WE,
    output  wire                     tap_EN,
    output  wire [(pDATA_WIDTH-1):0] tap_Di,
    output  wire [(pADDR_WIDTH-1):0] tap_A,
    input   wire [(pDATA_WIDTH-1):0] tap_Do,

    // bram for data RAM 
    output  wire [3:0]               data_WE,
    output  wire                     data_EN,
    output  wire [(pDATA_WIDTH-1):0] data_Di,
    output  wire [(pADDR_WIDTH-1):0] data_A,
    input   wire [(pDATA_WIDTH-1):0] data_Do,

    input   wire                     axis_clk,
    input   wire                     axis_rst_n
);

tap RAM 的 address 要從某個 東西轉成 0~44
address 只接受0~44
CPU 給進來40，要轉變00寫進去SRAM

    // Core engine : Pipeline FIR 
    wire [(pDATA_WIDTH-1):0] h_tmp;
    wire [(pDATA_WIDTH-1):0] x_tmp;
    wire [(pDATA_WIDTH-1):0] m_tmp;
    wire [(pDATA_WIDTH-1):0] y_tmp;

    reg [(pDATA_WIDTH-1):0] h;
    reg [(pDATA_WIDTH-1):0] x;
    reg [(pDATA_WIDTH-1):0] m;
    reg [(pDATA_WIDTH-1):0] y;

    always@* begin
        m_tmp = h * x;
        y_tmp = 

    end

endmodule
