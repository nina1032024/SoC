module wb_axi
#(  parameter pADDR_WIDTH = 12,
    parameter pDATA_WIDTH = 32,
    parameter Tape_Num    = 11
)(
//-----Wishbone bus signal-----//
    input wire wb_rst_i,
    input wire wb_clk_i,
    input wire wb_valid,
    input wire [3:0] wb_we,
    input wire [(pDATA_WIDTH-1):0] fir_data_i,
    input wire [(pADDR_WIDTH-1):0] fir_addr_i,
    output reg fir_ack,
    output reg [(pDATA_WIDTH-1):0]fir_data_o,
    output wire axis_clk,
    output wire axis_rst_n,
//-----AXI Lite write-----//
    input  wire                     awready,
    input  wire                     wready, 
    output   reg                     awvalid,
    output   wire [(pADDR_WIDTH-1):0] awaddr,
    output   reg                     wvalid,
    output   wire [(pDATA_WIDTH-1):0] wdata,
//-----AXI Lite read-----//
    input  wire                     arready,
    output   reg                     rready,
    output   reg                     arvalid,
    output   wire [(pADDR_WIDTH-1):0] araddr,
    input  wire                     rvalid,
    input  wire  [(pDATA_WIDTH-1):0] rdata,
//-----AXI Stream, input data Xn-----//
    output   reg                     ss_tvalid, 
    output   wire [(pDATA_WIDTH-1):0] ss_tdata, 
    output   wire                     ss_tlast, 
    input  wire                     ss_tready, 
    output   reg                     sm_tready, 
    input  wire                     sm_tvalid, 
    input  wire [(pDATA_WIDTH-1):0] sm_tdata, 
    input  wire                     sm_tlast
);
wire axi_sel; // 1: axi-stream, 0: axi-lite
reg [(pDATA_WIDTH-1):0] data_len; //storage register
reg [(pDATA_WIDTH-1):0] ss_counter; //count for ss_tlast generate
reg [(pDATA_WIDTH-1):0] ss_counter_next;

//-----clk, rst-----//
assign axis_clk = wb_clk_i;
assign axis_rst_n = ~wb_rst_i;

//-----configuration register map-----//
//0x30000040~0x30000047: AXI stream
//0x3000xxxx~0x3000yyyy: AXI Lite
assign axi_sel = (fir_addr_i[7:0] >= 8'h40 && fir_addr_i[7:0] <= 8'h47)? 1 : 0 ;

//-----AXI LIte Write-----//
always @(*) begin
    if (axi_sel == 0 && wb_we == 4'b1111) begin
      wvalid = wb_valid;
      awvalid = wb_valid;
    end else begin
      wvalid = 0;
      awvalid = 0;
    end
end
assign wdata = fir_data_i;
assign awaddr = fir_addr_i;
//-----AXI Lite read-----//
always @(*) begin
    if (axi_sel == 0 && wb_we == 4'b0000) begin
      rready = wb_valid;
      arvalid = wb_valid;
    end else begin
      rready = 0;
      arvalid = 0;
    end
end
assign araddr = fir_addr_i;
//-----AXI Stream write-----//
always @(*) begin
    if (axi_sel == 1 && wb_we == 4'b1111) begin
      ss_tvalid = wb_valid;
    end else begin
      ss_tvalid = 0;
    end
end
assign ss_tdata = fir_data_i;
//-----AXI Stream read-----//
always @(*) begin
    if (axi_sel == 1 && wb_we == 4'b0000) begin
      sm_tready = wb_valid;
    end else begin
      sm_tready = 0;
    end
end
//sm_tlast??
//-----MUX fir_ack-----//
always @(*) begin
    if (axi_sel == 0 && wb_we == 4'b1111) begin
      fir_ack = wready & awready;
    end else if (axi_sel == 0 && wb_we == 4'b0000) begin
      fir_ack = rvalid & arready;
    end else if (axi_sel == 1 && wb_we == 4'b1111) begin
      fir_ack = ss_tready;
    end else if (axi_sel == 1 && wb_we == 4'b0000) begin
      fir_ack = sm_tvalid;
    end else begin
      fir_ack = 0;
    end
end
//-----MUX fir_data_o-----//
always @(*) begin
    if (axi_sel == 0 && wb_we == 4'b0000) begin
      fir_data_o = rdata;
    end else if (axi_sel == 1 && wb_we == 4'b0000) begin
      fir_data_o = sm_tdata;
    end else begin
      fir_data_o = 0;
    end
end
//-----data length storage-----//
always @(posedge wb_clk_i) begin
    if (wb_rst_i) begin
      data_len = 0;
    end else if (axi_sel == 0 && wb_we == 4'b1111) begin
      if ((fir_addr_i[7:0] >= 8'h10) && (fir_addr_i[7:0] <= 8'h14)) begin
        data_len <= fir_data_i;
      end else begin
        data_len <= data_len;
      end
    end else begin
      data_len <= data_len;
    end
end
//-----ss_tlast generate-----//
always @(posedge wb_clk_i) begin
    if (wb_rst_i) begin
      ss_counter <= 0;
    end else begin
      ss_counter <= ss_counter_next;
    end
end
always @(*) begin
    if (fir_addr_i == 32'h3000_0000) begin
      ss_counter_next = 0;
    end else if (ss_tvalid & ss_tready) begin
      ss_counter_next = ss_counter + 1;
    end else begin
      ss_counter_next = ss_counter;
    end
end

assign ss_tlast = (ss_tvalid & ss_tready & (ss_counter_next == data_len))? 1:0;

endmodule