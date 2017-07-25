/*
	$0 - RW HS start byte
	$1 - RW IRQ|IEN|GRF|XXX|CEN|CIN|EVL|SVL 
	$2 - R- HS counter high byte
	$3 - R- HS counter low byte
	$4 - R- VS counter hight byte
	$5 - R- VS counter low byte
	$6 - RW Start visible lines
	$7 - RW End visible lines
	--- DMA Engine ---
	$8 - RW High external memory address byte
	$9 - RW Low external memory address byte
	$A - RW Counter/Length
	$B - RW Cursor position on line
	$C - RW Cursor start line
	$D - RW Cursor end line
	
	IRQ  R- Interrupt occurred
	IEN  RW Enable interrupts
	GRF  RW Graphics/Charset(Text) mode
	CEN  RW Enable cursor
	CIN  RW Inverting
	EVL  R- End visible lines
	SVL  R- Start vibible lines
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
	output reg vramcs,
	output reg hold,
	
	output wire [1:0] tvout
);
	reg [7:0] vcache_cnt_reg;
	reg [7:0] vcache_cnt;
	reg vcache_we;

	reg [5:0] cfg_reg;

	reg [2:0] char_line;

	reg [8:0] SVL_reg;
	reg [8:0] EVL_reg;

	reg [7:0] cursor_pos;
	reg [8:0] cursor_sline;
	reg [8:0] cursor_eline;

	wire [8:0] cntHS;
	wire [8:0] cntVS;
	wire vbl;
	wire hsync;
	wire out_sync;

	//--- DMA
	reg [15:0] DMA_ext_addr_reg;	reg [15:0] DMA_ext_addr;
	reg [7:0]  DMA_length_reg;
	reg [7:0]  DMA_length;
	reg [2:0]  DMA_state;
	
	reg [7:0] DMA_counter;
	//---
	
	reg dma_trig;
	
	wire svl_flag = (cntVS >= SVL_reg) && (cntVS <  EVL_reg);
	wire evl_flag = (cntVS >  SVL_reg) && (cntVS <= EVL_reg);

	assign irq = cfg_reg[5] & cfg_reg[4];

	assign VADDR = DMA_ext_addr;
 
	always @ (posedge clk) begin
		if (rst) begin
			vcache_we <= 0;
			vcache_cnt_reg <= 0;
			cfg_reg <= 0;
			SVL_reg <= 0;
			EVL_reg <= 0;
			char_line <= 7;

			cursor_pos <= 0;
			cursor_sline <= 0;
			cursor_eline <= 0;

			DMA_ext_addr_reg <= 0;
			DMA_ext_addr <= 0;
			DMA_length_reg <= 0;
			DMA_length <= 0;
			DMA_counter <= 0;
			DMA_state <= 0;
			dma_trig <= 0;
			hold <= 0;
			vramcs <= 0;
		end else begin
			if (DMA_counter == DMA_length_reg) begin
				case (DMA_state)
				3'b000:  begin
						hold <= 0;
						if (hsync) begin
							if (cntVS > EVL_reg) begin
								char_line <= 7;
								DMA_ext_addr <= DMA_ext_addr_reg;
							end else if (cntVS == EVL_reg) begin
								cfg_reg[5] <= 1;
								DMA_state <= 3'b101;
							end else if (cntVS >= SVL_reg) begin
								char_line <= char_line + 1'b1;
								vcache_cnt <= vcache_cnt_reg;
								DMA_state <= 3'b010;
							end
						end
					end
				3'b001: DMA_state <= 3'b000;
				3'b010:	begin
						if (cfg_reg[3] || (char_line == 0)) begin
							DMA_counter <= 0;
							DMA_state <= 0;
						end else if (!hsync) DMA_state <= 3'b000;
					end
				3'b101: if (!hsync) DMA_state <= 3'b000;
				default: begin
						vramcs <= 0;
						DMA_state <= 3'b001;
					end
				endcase
			end else begin
				case (DMA_state)
				3'b000: begin
						hold <= 1'b1;
						DMA_state <= 3'b001;
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
						vcache_we <= 1;
						DMA_state <= 3'b100;
					end
				3'b100: begin
						vcache_we <= 0;
						vcache_cnt <= vcache_cnt + 1'b1;
						DMA_ext_addr <= DMA_ext_addr + 1'b1;
						DMA_counter <= DMA_counter + 1'b1;
						DMA_state <= 3'b011;
					end
				endcase
			end

			if (cs) begin
				if (rw) begin
					case (AD)
					4'b0000: DO <= vcache_cnt_reg[7:0];
					4'b0001: begin
						DO <= {cfg_reg[5:0], evl_flag, svl_flag};
						cfg_reg[5] <= 0;
						end
					4'b0010: DO <= { 7'b0, SVL_reg[8]};
					4'b0011: DO <= SVL_reg[7:0];
					4'b0100: DO <= { 7'b0, EVL_reg[8]};
					4'b0101: DO <= EVL_reg[7:0];
					4'b0110: DO <= DMA_ext_addr_reg[15:8];
					4'b0111: DO <= DMA_ext_addr_reg[7:0];
					4'b1000: DO <= DMA_length_reg;
					4'b1001: DO <= cursor_pos[7:0];
					4'b1010: DO <= { 7'b0, cursor_sline[8]};
					4'b1011: DO <= cursor_sline[7:0];
					4'b1100: DO <= { 7'b0, cursor_eline[8]};
					4'b1101: DO <= cursor_eline[7:0];
					endcase
				end else begin
					case (AD)
					4'b0000: vcache_cnt_reg[7:0] <= DI;
					4'b0001: cfg_reg[4:0] <= DI[6:2];
					4'b0010: SVL_reg[8] <= DI[0];
					4'b0011: SVL_reg[7:0] <= DI;
					4'b0100: EVL_reg[8] <= DI[0];
					4'b0101: EVL_reg[7:0] <= DI;
					4'b0110: DMA_ext_addr_reg[15:8] <= DI;
					4'b0111: DMA_ext_addr_reg[7:0] <= DI;
					4'b1000: DMA_length_reg <= DI;
					4'b1001: cursor_pos[7:0] <= DI;
					4'b1010: cursor_sline[8] <= DI[0];
					4'b1011: cursor_sline[7:0] <= DI;
					4'b1100: cursor_eline[8] <= DI[0];
					4'b1101: cursor_eline[7:0] <= DI;
					endcase
				end
			end
		end
	end

	reg [7:0] vcache_out_cnt;
	reg [2:0] pixel_cnt;
	reg [7:0] shift_reg;
	wire [7:0] vcache_data;
	wire [7:0] vrom_data;
	
	always @ (posedge pixel_clk) begin
		if (hsync) begin
			vcache_out_cnt <= 0;
			pixel_cnt <= 0;
		end else begin
			if (pixel_cnt == 0) begin
				shift_reg <= cfg_reg[3]?vcache_data:vrom_data;
				vcache_out_cnt <= vcache_out_cnt + 1'b1;
			end else begin
				shift_reg <= shift_reg << 1;
			end
			pixel_cnt <= pixel_cnt + 1'b1;
		end
	end

	wire cursor_dis = ~(cfg_reg[1] && (cntVS >= cursor_sline) && (cntVS <= cursor_eline) && (cursor_pos == vcache_out_cnt));

	assign tvout[1] = (vbl || ~svl_flag || (vcache_out_cnt <= vcache_cnt_reg) || (vcache_out_cnt > (vcache_cnt_reg + DMA_length_reg))) ? 1'b0:
					  (cursor_dis) ? shift_reg[7]:
					  (cfg_reg[0]) ? ~shift_reg[7]:
					  1'b1;
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
	
	vpu_cache vcache(
		.WrAddress(vcache_cnt[5:0]),
		.Data(VDATA),
		.WrClock(clk),
		.WE(vcache_we),
		.WrClockEn(1'b1),
		.RdAddress(vcache_out_cnt[5:0]),
		.Q(vcache_data)
	);
	
	vrom vrom_impl (
		.Address({vcache_data[6:0], vcache_data[7], char_line}),
		.OutClock(pixel_clk),
		.OutClockEn(1'b1),
		.Reset(rst),
		.Q(vrom_data)
	);
	
endmodule
