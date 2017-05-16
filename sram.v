module sram(
	input wire clk,
	input wire [15:0] AD,
	input wire [7:0] DI,
	output wire [7:0] DO,
	input wire rw,
	input wire cs,

// physical connection
	output wire[16:0] SRAM_AD,
	inout [7:0] SRAM_DQ,
	output wire SRAM_WE_n,
	output wire SRAM_OE_n,
	output wire SRAM_CS1_n,
	output wire SRAM_CS2

);
	wire wren = ((!rw) & cs);
 
	assign SRAM_AD[16] = 0;
	assign SRAM_AD[15:0] = AD;
	assign SRAM_CS1_n = !cs;
	assign SRAM_CS2 = cs;
	assign SRAM_OE_n = !rw;
	assign SRAM_WE_n = rw;

	assign SRAM_DQ = wren ? DI : 8'bZ;
	assign DO = SRAM_DQ;
endmodule
