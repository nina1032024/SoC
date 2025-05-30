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
    parameter DELAYS = 10
)(
`ifdef USE_POWER_PINS
    inout vccd1,    // User area 1 1.8V supply
    inout vssd1,    // User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A-- Master Interface A)
    input wb_clk_i,              // Wishbone clock
    input wb_rst_i,              // Wishbone reset
    input wbs_stb_i,             // Strobe signal (transaction active)
    input wbs_cyc_i,             // Indicates a valid bus cycle
    input wbs_we_i,              // Write enable 
    input [3:0] wbs_sel_i,       // Byte enable (select which bytes are active)
    input [31:0] wbs_dat_i,      // Data input from CPU
    input [31:0] wbs_adr_i,      // Address from CPU
    output wbs_ack_o,            // Acknowledge signal back to bus
    output [31:0] wbs_dat_o,     // Data output to CPU

    // Logic Analyzer Signals
    input  [127:0] la_data_in,   // From management core → user project
    output [127:0] la_data_out,  // From user project → management core
    input  [127:0] la_oenb,      // Output enable (active-low), per bit

    // IOs      
    input  [`MPRJ_IO_PADS-1:0] io_in,   // Inputs from external 
    output [`MPRJ_IO_PADS-1:0] io_out,  // Outputs to external 
    output [`MPRJ_IO_PADS-1:0] io_oeb,  // Output enable for io_out (0 = output, 1 = input/high-Z)

    // IRQ
    output [2:0] irq
);
    wire clk;
    wire rst;

    wire [`MPRJ_IO_PADS-1:0] io_in;
    wire [`MPRJ_IO_PADS-1:0] io_out;
    wire [`MPRJ_IO_PADS-1:0] io_oeb;
    
    // bram signal
    wire bram_en;
    wire [3:0] bram_we;
    wire [(BITS-1):0] bram_Di;
    wire [(BITS-1):0] bram_Do;
    wire [(BITS-1):0] bram_Addr;
    
    bram user_bram (
        .CLK(wb_clk_i),
        .WE0(bram_we),
        .EN0(bram_en),
        .Di0(bram_Di),
        .Do0(bram_Do),
        .A0(bram_Addr)
    );


    assign bram_en   = wbs_stb_i && wbs_cyc_i && (wbs_adr_i[31:24] == 8'h38);    // exmem addr: 0x3800_xxxx
    assign bram_we   = wbs_we_i ? wbs_sel_i : 4'b0000;
    assign bram_Di   = wbs_dat_i;
    assign bram_Addr = (wbs_adr_i - 32'h38000000);
    

    // wb interface
    reg [3:0] counter;
    reg wbs_ack_o;
    reg [31:0] wbs_dat_o;

    always@(posedge wb_clk_i or posedge wb_rst_i) begin
        if(wb_rst_i) begin
            counter     <= 4'b0;
            wbs_ack_o   <= 1'b0;
            wbs_dat_o   <= 32'b0;
        end else begin
            counter     <= (counter == DELAYS) ? 0 : (bram_en == 1) ? counter + 1 : counter; 
            wbs_ack_o   <= (counter == DELAYS);
            wbs_dat_o   <= (counter == DELAYS) ? bram_Do : 0;
        end
    end
endmodule

`default_nettype wire