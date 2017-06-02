/*
	$0 - RW High address byte
	$1 - RW Low address byte
	$2 - RW Video data high byte
	$3 - RW Video data low byte
	$4 - R- HS counter high byte
	$5 - R- HS counter low byte
	$6 - R- VS counter hight byte
	$7 - R- VS counter low byte
	$8 - RW IRQ|IEN|XXX|XXX|XXX|XXX|VBL|HSN 
	--- DMA Engine ---
	$C - RW High external memory address byte
	$D - RW Low external memory address byte
	$E - RW Step
	$F - RW Counter/Length
	
	IRQ  R- Interrupt occured
	IEN  RW Enable interrupts
	VBL  R- Vertical blanking
	HSN  R- HSync
 */
module vpu (
	input wire clk,
	input wire rst,
	input wire [3:0] AD,
	input wire [7:0] DI,
	output reg [7:0] DO,
	input wire rw,
	input wire cs,
	output wire irq,
	input wire pixel_clk,
	
	output wire [15:0] VADDR,
	input wire [7:0] VDATA,
	output reg hold,
	
	output wire [1:0] tvout
);
	parameter CACHE_SIZE = 64;

	reg [7:0] vcache[CACHE_SIZE - 1:0];
	reg [15:0] vcache_cnt;
	reg [5:0] cfg_reg;

	wire [8:0] cntHS;
	wire [8:0] cntVS;
	wire vbl;
	wire hsync;
	wire out_sync;

	//--- DMA
	reg [15:0] DMA_ext_addr_reg;	reg [7:0] DMA_step_reg;
	reg [7:0] DMA_length_reg;
	reg [2:0] DMA_state;
	
	reg [7:0] DMA_counter;
	//---
	
	wire hstart = (cntHS < 8);
	wire vstart = (cntVS == 0) && (cntHS < 8);
	wire irq_request = hstart | vstart;

	assign irq = cfg_reg[5] & cfg_reg[4];

	assign VADDR = DMA_ext_addr_reg;

	always @ (posedge clk or posedge rst) begin
		if (rst) begin
			vcache_cnt <= 0;
			cfg_reg <= 0;
			
			DMA_ext_addr_reg <= 0;
			DMA_step_reg <= 1;
			DMA_length_reg <= 0;
			DMA_counter <= 0;
			DMA_state <= 0;
			hold <= 0;
		end else begin
			if (irq_request) cfg_reg[5] <= 1;
			if (DMA_counter == DMA_length_reg) begin
				case (DMA_state)
				2'b00: hold <= 0;
				default: DMA_state <= 2'b00;
				endcase
			end else begin
				case (DMA_state)
				2'b00: begin
					hold <= 1'b1;
					DMA_state <= 2'b01;
					end
				2'b01: begin
					// empty
					DMA_state <= 2'b10;
					end
				2'b10: begin
					vcache[vcache_cnt] <= VDATA;
					vcache_cnt <= vcache_cnt + 1'b1;
					DMA_state <= 2'b11;
					end
				2'b11: begin
					DMA_ext_addr_reg <= DMA_ext_addr_reg + DMA_step_reg;
					DMA_counter <= DMA_counter + 1'b1;
					DMA_state <= 2'b10;
					end
				endcase
			end

			if (cs && (!hold)) begin
				if (rw) begin
					case (AD)
					4'b0000: DO <= vcache_cnt[15:8];
					4'b0001: DO <= vcache_cnt[7:0];
					4'b0010: begin
						DO <= vcache[vcache_cnt];
						vcache_cnt <= vcache_cnt + 1'b1;
						end
					4'b0011: begin
						DO <= vcache[vcache_cnt];
						vcache_cnt <= vcache_cnt + 1'b1;
						end
					4'b0100: DO <= { 7'b0, cntHS[8]};
					4'b0101: DO <= cntHS[7:0];
					4'b0110: DO <= { 7'b0, cntVS[8]};
					4'b0111: DO <= cntVS[7:0];
					4'b1000: begin
						DO <= {cfg_reg[5:0], vbl, hsync};
						cfg_reg[5] <= 0;
						end
					4'b1100: DO <= DMA_ext_addr_reg[15:8];
					4'b1101: DO <= DMA_ext_addr_reg[7:0];
					4'b1110: DO <= DMA_step_reg;
					4'b1111: DO <= DMA_length_reg;
					endcase
				end else begin
					case (AD)
					4'b0000: vcache_cnt[15:8] <= DI;
					4'b0001: vcache_cnt[7:0] <= DI;
					4'b0010: begin
						vcache[vcache_cnt] <= DI;
						vcache_cnt <= vcache_cnt + 1'b1;
						end
					4'b0011: begin
						vcache[vcache_cnt] <= DI;
						vcache_cnt <= vcache_cnt + 1'b1;
						end
					4'b1000: cfg_reg[4:0] <= DI[6:2];
					4'b1100: DMA_ext_addr_reg[15:8] <= DI;
					4'b1101: DMA_ext_addr_reg[7:0] <= DI;
					4'b1110: DMA_step_reg <= DI;
					4'b1111: begin
						DMA_length_reg <= DI;
						DMA_counter <= 0;
						end
					endcase
				end
			end
		end
	end

	reg [7:0] vcache_out_cnt;
	reg [2:0] pixel_cnt;
	reg [7:0] shift_reg;
	
	always @ (posedge pixel_clk) begin
		if (hsync) begin
			vcache_out_cnt <= 0;
			pixel_cnt <= 0;
		end else begin
			if (pixel_cnt == 0) begin
				shift_reg <= vcache[vcache_out_cnt];
				vcache_out_cnt <= vcache_out_cnt + 1'b1;
			end else begin
				shift_reg <= shift_reg << 1;
			end
			pixel_cnt <= pixel_cnt + 1'b1;
		end
	end

	assign tvout[1] = vbl?1'b0:shift_reg[7];
	assign tvout[0] = out_sync;

	tvout tvout_impl (
		.pixel_clk(pixel_clk),
		.rst(rst),
		.cntHS(cntHS),
		.cntVS(cntVS),
		.vbl(vbl),
		.hsync(hsync),
		.out_sync(out_sync)
	);
	
endmodule
