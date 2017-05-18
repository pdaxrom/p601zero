module tvout(
	input clk_in,
	input rst,

// physical connection
	output wire [1:0] tvout
	
);

	reg [1:0] cnt8;
	reg clk8;
	
	reg [3:0] cnt1;
	reg clk1;

	reg [8:0] cntHS;
	reg [8:0] cntVS;

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
				if (cntVS == 310) cntVS <= 0;
				else cntVS <= cntVS + 1'b1;
			end else cntHS <= cntHS + 1'b1;
		end
		
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

	wire outbit = ((cntHS > 116) && (cntHS < 436))?cntVS[1]:1'b0;

	assign tvout[0] = in_vbl?vbl_sync:screen_sync;
	assign tvout[1] = in_vbl?1'b0: outbit;

endmodule
