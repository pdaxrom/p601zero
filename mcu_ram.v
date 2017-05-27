module mcu_ram (
	input wire clk,
	input wire [15:0] AD,
	input wire [7:0] DI,
	output reg[7:0] DO,
	input wire rw,
	input wire cs
);
	reg [7:0] ram [4095:0];

	always @ (posedge clk) begin
		if ((rw == 0) && cs) ram[AD[11:0]] <= DI;
		else DO <= ram[AD[11:0]];
	end
endmodule
