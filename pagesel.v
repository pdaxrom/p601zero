/*
	$10 - RW 0000RPPP
	$11 - RW 0 | 0 | 0 | 0 | 0 | 0 |RDS|LCK
	
	R   - RW Map ROM/RAM page
	PPP - RW Page number
	RDS - RW Disable BuiltIn RAM (disabled on reset/power on)
	LCK - Disable to write to ROM pages
 */

module pagesel (
	input wire clk,
	input wire rst,
	input wire AD,
	input wire [7:0] DI,
	output reg [7:0] DO,
	input wire rw,
	input wire cs,

	output reg [4:0] page,
	output reg bram_disable
);
	always @ (posedge clk) begin
		if (rst) begin
			page <= 5'b00000;
			bram_disable <= 1;
		end else begin
			if (cs) begin
				if (rw) begin
					if (AD) DO <= { 6'b000000, bram_disable, page[4]};
					else DO <= {4'b0000, page[3:0]};
				end else begin
					if (AD) begin
						page[4] <= DI[0];
						bram_disable <= DI[1];
					end else page[3:0] <= DI[3:0];
				end
			end
		end
	end
endmodule
