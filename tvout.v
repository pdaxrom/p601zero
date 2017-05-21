module tvout (
	input clk_in,
	input rst,

	output reg [8:0] cntHS,
	output reg [8:0] cntVS,

	output wire pixel_clk,
	output wire vbl,

	output wire out_sync
);

	reg [1:0] cnt8;
	reg clk8;
	
	reg [3:0] cnt1;
	reg clk1;

	reg[1:0] outregs;

	always @ (posedge clk_in) begin
		if (rst) begin
			cnt8 <= 0;
			clk8 <= 0;
		end else begin
			if (cnt8 == 2) begin
				cnt8 <= 0;
				clk8 <= 1;
			end else begin
				cnt8 <= cnt8 + 1'b1;
				clk8 <= 0;
			end
		end
	end
	wire screen_sync = (cntHS < 37) ? 1'b0 : 1'b1;
	wire in_vbl = ((cntVS >= 5) & (cntVS < 309)) ? 1'b0 : 1'b1;
	reg vbl_sync;

 	always @ (posedge clk8) begin
		if (rst) begin
			cntHS <= 0;
			cntVS <= 0;
		end else begin
			if (cntHS == 511) begin
				cntHS <= 0;
				if (cntVS == 311) cntVS <= 0;
				else cntVS <= cntVS + 1'b1;
			end else cntHS <= cntHS + 1'b1;

			if (cntVS < 2) begin
				if ((cntHS < 240) || ((cntHS >= 256) && (cntHS < 496))) vbl_sync <= 0;
				else vbl_sync <= 1;
			end else if (cntVS == 2) begin
				if ((cntHS < 240) || ((cntHS >= 256) && (cntHS < 272))) vbl_sync <= 0;
				else vbl_sync <= 1;
			end else begin
				if ((cntHS < 16) || ((cntHS >= 256) && (cntHS < 272))) vbl_sync <= 0;
				else vbl_sync <= 1;
			end			
		end
	end

	assign pixel_clk = clk8;
	assign vbl = in_vbl;
	assign out_sync = in_vbl?vbl_sync:screen_sync;
endmodule
