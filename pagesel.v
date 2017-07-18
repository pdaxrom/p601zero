/*
	$10 - RW 0000RPPP
	$11 - RW 0 | 0 | 0 | 0 |ROD|RAD|BLK|RLK
	
	R   - RW RAM pages enable
	PPP - RW Page number
	ROD - RW Disable builtin ROM (enabled on reset/power on)
	RAD - RW Disable BuiltIn RAM (disabled on reset/power on)
	SLK - RW Disable write to sysboot aream (mapped external ram)
	RLK - RW Disable write to RAM pages
 */

module pagesel (
	input wire clk,
	input wire rst,
	input wire AD,
	input wire [7:0] DI,
	output reg [7:0] DO,
	input wire rw,
	input wire cs,

	output reg [3:0] page,
	output reg rampage_lock,
	output reg sysboot_lock,
	output reg bram_disable,
	output reg brom_disable
);
	always @ (posedge clk) begin
		if (rst) begin
			page <= 4'b0000;
			rampage_lock <= 0;
			sysboot_lock <= 0;
			bram_disable <= 1;
			brom_disable <= 0;
		end else begin
			if (cs) begin
				if (rw) begin
					if (AD) DO[3:0] <= {brom_disable, bram_disable, sysboot_lock, rampage_lock};
					else DO[3:0] <= page;
				end else begin
					if (AD) begin
						rampage_lock <= DI[0];
						sysboot_lock <= DI[1];
						bram_disable <= DI[2];
						brom_disable <= DI[3];
					end else page <= DI[3:0];
				end
			end
		end
	end
endmodule
