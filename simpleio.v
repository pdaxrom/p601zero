module simpleio (
	input wire clk,
	input wire [3:0] Address,
	input wire [7:0] DI,
	output reg [7:0] DO,
	input wire rw,
	input wire cs,
	
	output reg [7:0] leds,
	output reg [2:0] rgb1,
	output reg [2:0] rgb2,
	input wire  [3:0] sw,
	input wire  [3:0] key
);

	always @ (posedge clk) begin
		if ((rw == 0) && cs) begin
			case (Address[2:0])
			3'b000: leds <= DI;
			3'b001: rgb1 <= DI[2:0];
			3'b010: rgb2 <= DI[2:0];
			endcase
		end else begin
			case (Address[2:0])
			3'b000: DO <= {sw, key};
			default: DO <= 8'b00000000;
			endcase
		end
	end

endmodule
