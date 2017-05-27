module pagesel (
	input wire clk,
	input wire rst,
	input wire [4:0] AD,
	input wire [7:0] DI,
	output reg [7:0] DO,
	input wire rw,
	input wire cs,

	output reg [4:0] page
);

	always @ (posedge clk or posedge rst) begin
		if (rst) begin
			page <= 5'b00000;
		end else begin
			if (cs) begin
				if (AD == 5'b10000) begin
					if (rw) DO <= {4'b0000, page[3:0]};
					else page[3:0] <= DI[3:0];
				end
				if (AD == 5'b10001) begin
					if (rw) DO <= { 7'b0000000, page[4]};
					else page[4] <= DI[0];
				end
			end
		end
	end
endmodule
