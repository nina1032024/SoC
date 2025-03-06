module fir 
#(  parameter pADDR_WIDTH = 12,
    parameter pDATA_WIDTH = 32
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
    output  reg [(pDATA_WIDTH-1):0]  rdata,    // read  data    

    // AXI4-Stream slave for x input, SS bus
    input   wire                     ss_tvalid, 
    input   wire [(pDATA_WIDTH-1):0] ss_tdata, 
    input   wire                     ss_tlast, 
    output  reg                      ss_tready,
    
    // AXI4-Stream master for y output, SM bus
    input   wire                     sm_tready, 
    output  reg                      sm_tvalid, 
    output  wire [(pDATA_WIDTH-1):0] sm_tdata, 
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
    input   wire                     axis_rst_n
);

endmodule