/*
	$10 - RW 0000RPPP
	$11 - RW 0 | 0 | 0 | 0 | 0 | 0 |RDS|LCK
	$14 - RW IRQ address (24 bits)
	$17 - RW SWI address (24 bits)
	$1A - RW NMI address (24 bits)
	$1D - RW RESET address (24 bits)
	
	R   - RW Map ROM/RAM page
	PPP - RW Page number
	RDS - RW Disable BuiltIn RAM (disabled on reset/power on)
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
	reg [23:0] res_addr;
	reg [23:0] nmi_addr;
	reg [23:0] swi_addr;
	reg [23:0] irq_addr;

	always @ (posedge clk or posedge rst) begin
		if (rst) begin
			page <= 5'b00000;
			bram_disable <= 1;
		end else begin
			if (cs) begin
				if (rw) begin
					case (AD)
					5'b10000: DO <= {4'b0000, page[3:0]};
					5'b10001: DO <= { 6'b000000, bram_disable, page[4]};
					5'b10100: DO <= irq_addr[23:16];
					5'b10101: DO <= irq_addr[15:8];
					5'b10110: DO <= irq_addr[7:0];
					5'b10111: DO <= swi_addr[23:16];
					5'b11000: DO <= swi_addr[15:8];
					5'b11001: DO <= swi_addr[7:0];
					5'b11010: DO <= nmi_addr[23:16];
					5'b11011: DO <= nmi_addr[15:8];
					5'b11100: DO <= nmi_addr[7:0];
					5'b11101: DO <= res_addr[23:16];
					5'b11110: DO <= res_addr[15:8];
					5'b11111: DO <= res_addr[7:0];
					endcase
				end else begin
					case (AD)
					5'b10000: page[3:0] <= DI[3:0];
					5'b10001: begin
						page[4] <= DI[0];
						bram_disable <= DI[1];
						end
					5'b10100: irq_addr[23:16] <= DI;
					5'b10101: irq_addr[15:8]  <= DI;
					5'b10110: irq_addr[7:0]   <= DI;
					5'b10111: swi_addr[23:16] <= DI;
					5'b11000: swi_addr[15:8]  <= DI;
					5'b11001: swi_addr[7:0]   <= DI;
					5'b11010: nmi_addr[23:16] <= DI;
					5'b11011: nmi_addr[15:8]  <= DI;
					5'b11100: nmi_addr[7:0]   <= DI;
					5'b11101: res_addr[23:16] <= DI;
					5'b11110: res_addr[15:8]  <= DI;
					5'b11111: res_addr[7:0]   <= DI;
					endcase
				end
			end
		end
	end
endmodule
