/*
	$0 - RW High address byte
	$1 - RW Low address byte
	$2 - RW 00000NNN - Charset vertical address
	$3 - RW IRQ|IEN|GRF|XXX|EVL|SVL|VBL|HSN 
	$4 - R- HS counter high byte
	$5 - R- HS counter low byte
	$6 - R- VS counter hight byte
	$7 - R- VS counter low byte
	$8 - RW Start visible lines
	$A - RW End visible lines
	--- DMA Engine ---
	$C - RW High external memory address byte
	$D - RW Low external memory address byte
	$E - RW Step
	$F - RW Counter/Length
	$1C- RW User reg 0 (2bytes)
	$1D- RW User reg 1 (2bytes)
	
	IRQ  R- Interrupt occurred
	IEN  RW Enable interrupts
	GRF  RW Graphics/Charset(Text) mode
	EVL  R- End visible lines
	SVL  R- Start vibible lines
	VBL  R- Vertical blanking
	HSN  R- HSync
 */
module vpu (
	input wire clk,
	input wire rst,
	input wire [4:0] AD,
	input wire [7:0] DI,
	output reg [7:0] DO,
	input wire rw,
	input wire cs,
	output wire irq,
	input wire pixel_clk,
	
	output wire [15:0] VADDR,
	input wire [7:0] VDATA,
	output reg vramcs,
	output reg hold,
	input wire vrambusy,
	
	output wire [1:0] tvout
);
	parameter CACHE_SIZE = 64;

	reg [7:0] vcache[CACHE_SIZE - 1:0];
	reg [15:0] vcache_cnt_reg;
	reg [15:0] vcache_cnt;
	reg [5:0] cfg_reg;

	reg [2:0] char_line;

	reg [8:0] SVL_reg;
	reg [8:0] EVL_reg;

	reg [31:0] user_reg;

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
	
	wire svl_flag = (cntVS >= SVL_reg) && (cntVS <  EVL_reg);
	wire evl_flag = (cntVS >  SVL_reg) && (cntVS <= EVL_reg);
	
	wire irq_condition = (svl_flag || evl_flag) && (cntHS < 2);

	assign irq = cfg_reg[5] & cfg_reg[4];

	assign VADDR = DMA_ext_addr_reg;

/*
	reg irq_request;

	always @ (posedge pixel_clk) begin
		if (rst) irq_request <= 0;
		else begin
			if (irq_condition && (~cfg_reg[5])) begin
				irq_request <= 1;
			end else if (cfg_reg[5]) irq_request <= 0;
		end
	end
 */
 
	always @ (posedge clk) begin
		if (rst) begin
			vcache_cnt_reg <= 0;
			cfg_reg <= 0;
			SVL_reg <= 0;
			EVL_reg <= 0;
			char_line <= 0;

			DMA_ext_addr_reg <= 0;
			DMA_step_reg <= 1;
			DMA_length_reg <= 0;
			DMA_counter <= 0;
			DMA_state <= 0;
			hold <= 0;
			vramcs <= 0;
		end else begin
			if (irq_condition) cfg_reg[5] <= 1;
			if (DMA_counter == DMA_length_reg) begin
				case (DMA_state)
				3'b000:  hold <= 0;
				3'b001:  DMA_state <= 3'b000;
				default: begin
					vramcs <= 0;
					DMA_state <= 3'b001;
					end
				endcase
			end else begin
				case (DMA_state)
				3'b000: begin
//						if (vrambusy) DMA_state <= 3'b000;
//						else begin
							hold <= 1'b1;
							DMA_state <= 3'b001;
//						end
					end
				3'b001: begin
					// empty
					DMA_state <= 3'b010;
					end
				3'b010: begin
					vramcs <= 1'b1;
					DMA_state <= 3'b011;
					end
				3'b011: begin
					vcache[vcache_cnt] <= VDATA;
					vcache_cnt <= vcache_cnt + 1'b1;
					DMA_state <= 3'b100;
					end
				3'b100: begin
					DMA_ext_addr_reg <= DMA_ext_addr_reg + DMA_step_reg;
					DMA_counter <= DMA_counter + 1'b1;
					DMA_state <= 3'b011;
					end
				endcase
			end

			if (cs) begin
				if (rw) begin
					case (AD)
					5'b00000: DO <= vcache_cnt_reg[15:8];
					5'b00001: DO <= vcache_cnt_reg[7:0];
					5'b00010: DO <= { 5'b0, char_line };
					5'b00011: begin
						DO <= {cfg_reg[5:2], evl_flag, svl_flag, vbl, hsync};
						cfg_reg[5] <= 0;
						end
					5'b00100: DO <= { 7'b0, cntHS[8]};
					5'b00101: DO <= cntHS[7:0];
					5'b00110: DO <= { 7'b0, cntVS[8]};
					5'b00111: DO <= cntVS[7:0];
					5'b01000: DO <= { 7'b0, SVL_reg[8]};
					5'b01001: DO <= SVL_reg[7:0];
					5'b01010: DO <= { 7'b0, EVL_reg[8]};
					5'b01011: DO <= EVL_reg[7:0];
					5'b01100: DO <= DMA_ext_addr_reg[15:8];
					5'b01101: DO <= DMA_ext_addr_reg[7:0];
					5'b01110: DO <= DMA_step_reg;
					5'b01111: DO <= DMA_length_reg;
					5'b11100: DO <= user_reg[7:0];
					5'b11101: DO <= user_reg[15:8];
					5'b11110: DO <= user_reg[23:16];
					5'b11111: DO <= user_reg[31:24];
					endcase
				end else begin
					case (AD)
					5'b00000: vcache_cnt_reg[15:8] <= DI;
					5'b00001: vcache_cnt_reg[7:0] <= DI;
					5'b00010: char_line <= DI[2:0];
					5'b00011: cfg_reg[4:2] <= DI[6:4];
					5'b01000: SVL_reg[8] <= DI[0];
					5'b01001: SVL_reg[7:0] <= DI;
					5'b01010: EVL_reg[8] <= DI[0];
					5'b01011: EVL_reg[7:0] <= DI;
					5'b01100: DMA_ext_addr_reg[15:8] <= DI;
					5'b01101: DMA_ext_addr_reg[7:0] <= DI;
					5'b01110: DMA_step_reg <= DI;
					5'b01111: begin
						DMA_length_reg <= DI;
						DMA_counter <= 0;
						vcache_cnt <= vcache_cnt_reg;
						end
					5'b11100: user_reg[7:0] <= DI;
					5'b11101: user_reg[15:8] <= DI;
					5'b11110: user_reg[23:16] <= DI;
					5'b11111: user_reg[31:24] <= DI;
					endcase
				end
			end
		end
	end

	reg [7:0] vcache_out_cnt;
	reg [2:0] pixel_cnt;
	reg [7:0] shift_reg;
	wire [7:0] vrom_data;
	
	always @ (posedge pixel_clk) begin
		if (hsync) begin
			vcache_out_cnt <= 0;
			pixel_cnt <= 0;
		end else begin
			if (pixel_cnt == 0) begin
				shift_reg <= cfg_reg[3]?vcache[vcache_out_cnt]:vrom_data;
				vcache_out_cnt <= vcache_out_cnt + 1'b1;
			end else begin
				shift_reg <= shift_reg << 1;
			end
			pixel_cnt <= pixel_cnt + 1'b1;
		end
	end

	assign tvout[1] = (vbl || ~svl_flag)?1'b0:shift_reg[7];
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
	
	wire [7:0] char_addr = vcache[vcache_out_cnt];
	
	vrom vrom_impl (
		.Address({char_addr[6:0], char_addr[7], char_line}),
		.Q(vrom_data)
	);
	
endmodule
