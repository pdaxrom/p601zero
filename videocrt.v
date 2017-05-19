module videocrt (
	input wire clk_in,
	input wire clk,
	input wire rst,
	input wire AD,
	input wire [7:0] DI,
	output reg [7:0] DO,
	input wire rw,
	input wire cs,

	output wire [15:0] VAD,
	input wire [7:0] VDI,
	
	// physical connection
	output wire [1:0] tvout
);
	wire pixel_clk;
	
	wire [8:0] cntHS;
	wire [8:0] cntVS;
	wire vbl;
	wire out_sync;

	reg [8:0] HS_start;
	reg [8:0] HS_end;
	reg [8:0] VS_start;
	reg [8:0] VS_end;

	reg [15:0] frame_addr;
	
	reg [4:0] address_reg;

	always @ (posedge clk or posedge rst) begin
		if (rst) begin
			HS_start <= 160; // 20chars * 8
			HS_end <= 480; // (20chars + 40chars) * 8
			VS_start <= 57;
			VS_end <= 257;
			frame_addr <= 16'h0000;
			address_reg <= 5'b00000;
		end else begin
			if (cs) begin
				if (rw) begin
					if (AD) begin
						case (address_reg[4:0])
						5'b01100: DO <= frame_addr[15:8];
						5'b01101: DO <= frame_addr[7:0];
						endcase
					end else DO <= {1'b0, 1'b0, 1'b0, address_reg};
				end else begin
					if (AD) begin
						case (address_reg[4:0])
						5'b01100: frame_addr[15:8] <= DI;
						5'b01101: frame_addr[7:0] <= DI;
						endcase
					end else address_reg <= DI[4:0];
				end
			end
		end
	end
	
	assign tvout[0] = out_sync;

	tvout tvout_impl (
		.clk_in(clk_in),
		.rst(rst),
		.cntHS(cntHS),
		.cntVS(cntVS),
		.pixel_clk(pixel_clk),
		.vbl(vbl),
		.out_sync(out_sync)
	);
endmodule
