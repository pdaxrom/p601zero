module bootrom (
	input wire clk,
	input wire [15:0] Address,
	output reg[7:0] DO,
	input wire rw
);

wire [7:0] dout;

always @ (posedge clk)
begin
	if (rw) begin
		DO <= dout;
	end
end

mcu_rom rom(Address[7:0], dout);

endmodule
