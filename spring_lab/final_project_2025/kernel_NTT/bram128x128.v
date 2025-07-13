module bram128x128
#(  
    parameter DW = 128,
    parameter WL = 128
)
(
    CLK,
    WE,
    EN,
    Di,
    Do,
    A
);

    input   wire            CLK;
    input   wire      [3:0]  WE;
    input   wire             EN;
    input   wire [(DW-1):0]  Di;
    output  wire [(DW-1):0]  Do;
    input   wire     [12:0]   A; 

	reg [(DW-1):0] RAM[0:(WL-1)];
    reg [31:0] r_A;

    always @(posedge CLK) begin
        r_A <= A;
    end

    assign Do = {DW{EN}} & RAM[r_A>>2];    // read

    always @(posedge CLK) begin
        if(EN) begin
	    if(WE[0] & WE[1] & WE[2] & WE[3]) RAM[A>>2] <= Di;
        end
    end

endmodule