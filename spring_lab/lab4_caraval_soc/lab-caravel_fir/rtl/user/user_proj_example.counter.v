// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_proj_example
 *
 * This is an example of a (trivially simple) user project,
 * showing how the user project can connect to the logic
 * analyzer, the wishbone bus, and the I/O pads.
 *
 * This project generates an integer count, which is output
 * on the user area GPIO pads (digital output only).  The
 * wishbone connection allows the project to be controlled
 * (start and stop) from the management SoC program.
 *
 * See the testbenches in directory "mprj_counter" for the
 * example programs that drive this user project.  The three
 * testbenches are "io_ports", "la_test1", and "la_test2".
 *
 *-------------------------------------------------------------
 */

module user_proj_example #(
    parameter BITS = 32,
    parameter DELAYS=10,
    parameter pADDR_WIDTH = 12,
    parameter pDATA_WIDTH = 32
)(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // IRQ
    output [2:0] irq
);
    wire clk;
    wire rst;

    wire [`MPRJ_IO_PADS-1:0] io_in;
    wire [`MPRJ_IO_PADS-1:0] io_out;
    wire [`MPRJ_IO_PADS-1:0] io_oeb;

//-----wb interface(exmem-fir)-----//
    wire exmem_valid;
    wire [3:0] wb_we;
    wire sel_exmem; //address decode: 0x3800_0000
    wire sel_fir;   //address decode: 0x3000_0000
    wire [(BITS-1):0] exmem_rdata;
    wire [(BITS-1):0] fir_data;
    reg ready;
    wire fir_ack;
    reg [4:0] delay;//delay 10 cycle, need four bits.

//-----wb-axi & fir signal-----//
    wire fir_valid;

    wire                        awready;
    wire                        wready;
    wire                         awvalid;
    wire   [(pADDR_WIDTH-1): 0]  awaddr;
    wire                         wvalid;
    wire signed [(pDATA_WIDTH-1) : 0] wdata;
    wire                        arready;
    wire                         rready;
    wire                         arvalid;
    wire         [(pADDR_WIDTH-1): 0] araddr;
    wire                        rvalid;
    wire signed [(pDATA_WIDTH-1): 0] rdata;
    wire                         ss_tvalid;
    wire signed [(pDATA_WIDTH-1) : 0] ss_tdata;
    wire                         ss_tlast;
    wire                        ss_tready;
    wire                         sm_tready;
    wire                        sm_tvalid;
    wire signed [(pDATA_WIDTH-1) : 0] sm_tdata;
    wire                        sm_tlast;
    wire                         axis_clk;
    wire                         axis_rst_n;

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
//-----wb-axi & fir signal-----//


//if addr = 380xxxxx, fetch instruction from user bram. 
    assign sel_exmem = (wbs_adr_i[31:16] == 16'h3800)? 1'b1 : 1'b0; //把wb-decode邏輯在這邊實現(待做), 不在另外開module
    assign sel_fir = (wbs_adr_i[31:16] == 16'h3000)? 1'b1 : 1'b0;

    assign exmem_valid = wbs_cyc_i & wbs_stb_i & sel_exmem;
    assign fir_valid = wbs_cyc_i & wbs_stb_i & sel_fir;
    assign wb_we = wbs_sel_i & {4{wbs_we_i}};

    assign wbs_ack_o = sel_exmem ? ready : (sel_fir ? fir_ack : 1'b0);
    assign wbs_dat_o = sel_exmem ? exmem_rdata : (sel_fir ? fir_data : 32'b0);

    always @(posedge wb_clk_i) begin
        if (wb_rst_i) begin
            ready <= 0;
            delay <= 0;
        end else begin
            ready <= 0;
            if (exmem_valid && !ready) begin
                if (delay == DELAYS - 1) begin 
                    ready <= 1;
                    delay <= 0;
                end else begin
                    delay <= delay + 1;
                end
            end
        end
    end

    bram user_bram (
        .CLK(wb_clk_i),
        .WE0(wb_we),
        .EN0(exmem_valid),
        .Di0(wbs_dat_i),
        .Do0(exmem_rdata),
        .A0(wbs_adr_i)
    );
//-----wb interface(exmem-fir)-----//

//-----wb interface(WB-AXI)-----//

//input: awready, wready, arready, rvalid, rdata
//input: ss_tready, sm_tvalid, sm_tdata, sm_tlast
//output: awvalid, awaddr, wvalid, wdata
//output: rready, arvalid, araddr
//output: ss_tvalid, ss_tdata, ss_tlast, sm_tready, axis_clk, axis_rst_n
//-----wb interface(WB-AXI)-----//

//-----wb interface(verilog fir)-----//
// implement module:WB-AXI(要另外開module), connect to wishbone bus signal and module:fir

 

    wb_axi uut(
        .wb_rst_i(wb_rst_i),
        .wb_clk_i(wb_clk_i),
        .wb_valid(fir_valid),
        .wb_we(wb_we),
        .fir_data_i(wbs_dat_i),
        .fir_addr_i(wbs_adr_i),
        .fir_ack(fir_ack),
        .fir_data_o(fir_data),
        .axis_clk(axis_clk),
        .axis_rst_n(axis_rst_n),
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
        .sm_tlast(sm_tlast)
    );

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
//-----wb interface(verilog fir)-----//

endmodule



`default_nettype wire
