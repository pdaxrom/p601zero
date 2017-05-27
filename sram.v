module sram(
	input wire clk,
	input wire [15:0] AD,
	input wire [7:0] DI,
	output wire [7:0] DO,
	input wire rw,
	input wire cs,
	input wire [4:0] page,

// physical connection
	output wire[16:0] SRAM_AD,
	inout [7:0] SRAM_DQ,
	output wire SRAM_WE_n,
	output wire SRAM_OE_n,
	output wire SRAM_CS2

);
	wire wren = ((!rw) & cs);
	wire pageen = page[3] && (AD[15:13] == 3'b110) && (!(page[4] && (!rw)));

	assign SRAM_AD[16:0] = pageen ? {1'b1, page[2:0], AD[12:0]} : {1'b0, AD};
	assign SRAM_CS2 = cs;
	assign SRAM_OE_n = !rw;
	assign SRAM_WE_n = rw;

	assign SRAM_DQ = wren ? DI : 8'bZ;
	assign DO = SRAM_DQ;
endmodule
