module tvout (
	input pixel_clk,
	input rst,

	output reg [8:0] cntHS,
	output reg [8:0] cntVS,

	output wire vbl,
	output wire hsync,

	output wire out_sync
);
	wire screen_sync = (cntHS < 37) ? 1'b0 : 1'b1;
	wire in_vbl = ((cntVS >= 5) & (cntVS < 309)) ? 1'b0 : 1'b1;
	reg vbl_sync;

 	always @ (posedge pixel_clk) begin
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

	assign vbl = in_vbl;
	assign hsync = ~screen_sync;
	assign out_sync = in_vbl?vbl_sync:screen_sync;
endmodule
