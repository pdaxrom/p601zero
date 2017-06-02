/*
	$10 - RW 0000RPPP
	$11 - RW 0 | 0 | 0 | 0 | 0 | 0 |RDS|LCK
	
	R   - RW Map ROM/RAM page
	PPP - RW Page number
	RDS - RW BuiltIn RAM disable (1 - disabled by default)
	LCK - Disable to write to ROM pages
 */

module pagesel (
	input wire clk,
	input wire rst,
	input wire [4:0] AD,
	input wire [7:0] DI,
	output reg [7:0] DO,
	input wire rw,
	input wire cs,

	output reg [4:0] page,
	output reg bram_disable
);

	always @ (posedge clk or posedge rst) begin
		if (rst) begin
			page <= 5'b00000;
			bram_disable <= 1;
		end else begin
			if (cs) begin
				if (AD == 5'b10000) begin
					if (rw) DO <= {4'b0000, page[3:0]};
					else page[3:0] <= DI[3:0];
				end
				if (AD == 5'b10001) begin
					if (rw) DO <= { 6'b000000, bram_disable, page[4]};
					else begin
						page[4] <= DI[0];
						bram_disable <= DI[1];
					end
				end
			end
		end
	end
endmodule
